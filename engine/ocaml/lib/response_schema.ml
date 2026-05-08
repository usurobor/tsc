(** Response schema: validate structured JSON output from the LLM.

    Pure module — no I/O. Receives raw JSON string, returns validated result.
    Uses Yojson.Safe for JSON parsing. *)

open Types

(** Extract a string field from a JSON object. *)
let get_string key = function
  | `Assoc fields ->
    (match List.assoc_opt key fields with
     | Some (`String s) -> Ok s
     | Some _ -> Error (Printf.sprintf "field '%s' is not a string" key)
     | None -> Error (Printf.sprintf "missing field '%s'" key))
  | _ -> Error "expected JSON object"

(** Extract a float field from a JSON object. *)
let get_float key = function
  | `Assoc fields ->
    (match List.assoc_opt key fields with
     | Some (`Float f) -> Ok f
     | Some (`Int i) -> Ok (Float.of_int i)
     | Some _ -> Error (Printf.sprintf "field '%s' is not a number" key)
     | None -> Error (Printf.sprintf "missing field '%s'" key))
  | _ -> Error "expected JSON object"

(** Extract a string list field from a JSON object. *)
let get_string_list key = function
  | `Assoc fields ->
    (match List.assoc_opt key fields with
     | Some (`List items) ->
       let rec collect acc = function
         | [] -> Ok (List.rev acc)
         | `String s :: rest -> collect (s :: acc) rest
         | _ :: _ -> Error (Printf.sprintf "field '%s' contains non-string items" key)
       in
       collect [] items
     | Some _ -> Error (Printf.sprintf "field '%s' is not an array" key)
     | None -> Ok [])
  | _ -> Error "expected JSON object"

(** Extract axis_evidence from a JSON sub-object. *)
let get_axis_evidence key json =
  match json with
  | `Assoc fields ->
    (match List.assoc_opt key fields with
     | Some (`Assoc _ as sub) ->
       (match get_string_list "positive" sub,
              get_string_list "negative" sub,
              get_string "reason" sub with
        | Ok pos, Ok neg, Ok reason ->
          Ok { evidence_positive = pos;
               evidence_negative = neg;
               evidence_reason = reason }
        | Error e, _, _ | _, Error e, _ | _, _, Error e ->
          Error (Printf.sprintf "in %s: %s" key e))
     | _ -> Error (Printf.sprintf "missing or invalid '%s' object" key))
  | _ -> Error "expected JSON object"

(** Extract a list of suggested fixes. *)
let get_fixes key json =
  match json with
  | `Assoc fields ->
    (match List.assoc_opt key fields with
     | Some (`List items) ->
       let rec collect acc = function
         | [] -> Ok (List.rev acc)
         | `Assoc _ as fix :: rest ->
           (match get_string "axis" fix, get_string "fix" fix with
            | Ok axis, Ok desc ->
              collect ({ fix_axis = axis; fix_description = desc } :: acc) rest
            | Error e, _ | _, Error e ->
              Error (Printf.sprintf "in fix: %s" e))
         | _ :: _ -> Error "fix items must be objects"
       in
       collect [] items
     | Some _ -> Error (Printf.sprintf "field '%s' is not an array" key)
     | None -> Ok [])
  | _ -> Error "expected JSON object"

(** Validate a score is in [0.0, 1.0]. *)
let validate_score name value =
  if value >= 0.0 && value <= 1.0 then Ok value
  else Error (Printf.sprintf "%s score %.3f is out of range [0.0, 1.0]" name value)

(** Parse raw JSON string into Yojson value. *)
let parse_json raw =
  try Ok (Yojson.Safe.from_string raw)
  with Yojson.Json_error msg -> Error (Printf.sprintf "JSON parse error: %s" msg)

(** Extract an optional float field (Ok None when absent). *)
let get_float_opt key json =
  match json with
  | `Assoc fields ->
    (match List.assoc_opt key fields with
     | None -> Ok None
     | Some (`Float f) -> Ok (Some f)
     | Some (`Int i) -> Ok (Some (Float.of_int i))
     | Some _ -> Error (Printf.sprintf "field '%s' is not a number" key))
  | _ -> Error "expected JSON object"

(** Validate a complete measure result from parsed JSON.
    Returns Ok measure_result or Error string.

    v3.2.0: also accepts optional per-pair delta fields
    (delta_alpha_beta, delta_beta_gamma, delta_gamma_alpha) as provenance
    data. The three top-level scores (alpha, beta, gamma) are LLM-provided
    values in [0, 1]; the delta fields carry per-pair discrepancy estimates
    used in provenance JSON. *)
let validate_result json =
  let axis_evidence_obj =
    match json with
    | `Assoc fields ->
      (match List.assoc_opt "axis_evidence" fields with
       | Some x -> x
       | None -> `Null)
    | _ -> `Null
  in
  match
    get_string "target" json,
    get_float "alpha" json,
    get_float "beta" json,
    get_float "gamma" json,
    get_string "bottleneck_axis" json,
    get_float "confidence" json,
    get_string "summary" json,
    get_axis_evidence "alpha" axis_evidence_obj,
    get_axis_evidence "beta" axis_evidence_obj,
    get_axis_evidence "gamma" axis_evidence_obj,
    get_string_list "unresolved_ambiguity" json,
    get_fixes "next_fixes" json
  with
  | Ok target, Ok alpha, Ok beta, Ok gamma,
    Ok bottleneck, Ok confidence, Ok summary,
    Ok alpha_ev, Ok beta_ev, Ok gamma_ev,
    Ok ambiguity, Ok fixes ->
    (match validate_score "alpha" alpha,
           validate_score "beta" beta,
           validate_score "gamma" gamma,
           validate_score "confidence" confidence with
     | Ok _, Ok _, Ok _, Ok _ ->
       Ok {
         result_target = target;
         result_alpha = alpha;
         result_beta = beta;
         result_gamma = gamma;
         result_bottleneck_axis = bottleneck;
         result_confidence = confidence;
         result_summary = summary;
         result_alpha_evidence = alpha_ev;
         result_beta_evidence = beta_ev;
         result_gamma_evidence = gamma_ev;
         result_unresolved_ambiguity = ambiguity;
         result_next_fixes = fixes;
       }
     | Error e, _, _, _ | _, Error e, _, _
     | _, _, Error e, _ | _, _, _, Error e -> Error e)
  | Error e, _, _, _, _, _, _, _, _, _, _, _
  | _, Error e, _, _, _, _, _, _, _, _, _, _
  | _, _, Error e, _, _, _, _, _, _, _, _, _
  | _, _, _, Error e, _, _, _, _, _, _, _, _
  | _, _, _, _, Error e, _, _, _, _, _, _, _
  | _, _, _, _, _, Error e, _, _, _, _, _, _
  | _, _, _, _, _, _, Error e, _, _, _, _, _
  | _, _, _, _, _, _, _, Error e, _, _, _, _
  | _, _, _, _, _, _, _, _, Error e, _, _, _
  | _, _, _, _, _, _, _, _, _, Error e, _, _
  | _, _, _, _, _, _, _, _, _, _, Error e, _
  | _, _, _, _, _, _, _, _, _, _, _, Error e -> Error e

(** Extract per-pair delta values from a v3.2.0 LLM response.
    Returns (delta_alpha_beta, delta_beta_gamma, delta_gamma_alpha) — each
    float option.  All fields are optional; absent means the LLM did not emit
    them (pre-v3.2.0 response format). *)
let extract_deltas json =
  match
    get_float_opt "delta_alpha_beta"  json,
    get_float_opt "delta_beta_gamma"  json,
    get_float_opt "delta_gamma_alpha" json
  with
  | Ok d_ab, Ok d_bg, Ok d_ga -> Ok (d_ab, d_bg, d_ga)
  | Error e, _, _ | _, Error e, _ | _, _, Error e -> Error e
