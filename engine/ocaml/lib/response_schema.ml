(** Response schema: validate structured JSON output from the LLM.

    Pure module — no I/O. Receives raw JSON string, returns validated result. *)

open Types

(** Minimal JSON value type for validation.
    Production should use a JSON library (yojson). *)
type json =
  | String of string
  | Number of float
  | Array of json list
  | Object of (string * json) list
  | Null

(** Extract a string field from a JSON object. *)
let get_string key = function
  | Object fields ->
    (match List.assoc_opt key fields with
     | Some (String s) -> Ok s
     | Some _ -> Error (Printf.sprintf "field '%s' is not a string" key)
     | None -> Error (Printf.sprintf "missing field '%s'" key))
  | _ -> Error "expected JSON object"

(** Extract a float field from a JSON object. *)
let get_float key = function
  | Object fields ->
    (match List.assoc_opt key fields with
     | Some (Number f) -> Ok f
     | Some _ -> Error (Printf.sprintf "field '%s' is not a number" key)
     | None -> Error (Printf.sprintf "missing field '%s'" key))
  | _ -> Error "expected JSON object"

(** Extract a string list field from a JSON object. *)
let get_string_list key = function
  | Object fields ->
    (match List.assoc_opt key fields with
     | Some (Array items) ->
       let rec collect acc = function
         | [] -> Ok (List.rev acc)
         | String s :: rest -> collect (s :: acc) rest
         | _ :: _ -> Error (Printf.sprintf "field '%s' contains non-string items" key)
       in
       collect [] items
     | Some _ -> Error (Printf.sprintf "field '%s' is not an array" key)
     | None -> Ok [])
  | _ -> Error "expected JSON object"

(** Extract axis_evidence from a JSON sub-object. *)
let get_axis_evidence key json =
  match json with
  | Object fields ->
    (match List.assoc_opt key fields with
     | Some (Object _ as sub) ->
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
  | Object fields ->
    (match List.assoc_opt key fields with
     | Some (Array items) ->
       let rec collect acc = function
         | [] -> Ok (List.rev acc)
         | Object _ as fix :: rest ->
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

(** Validate a complete measure result from parsed JSON.
    Returns Ok measure_result or Error string. *)
let validate_result json =
  match
    get_string "target" json,
    get_float "alpha" json,
    get_float "beta" json,
    get_float "gamma" json,
    get_string "bottleneck_axis" json,
    get_float "confidence" json,
    get_string "summary" json,
    get_axis_evidence "alpha" (match json with
      | Object fields ->
        (match List.assoc_opt "axis_evidence" fields with
         | Some x -> x | None -> Null)
      | _ -> Null),
    get_axis_evidence "beta" (match json with
      | Object fields ->
        (match List.assoc_opt "axis_evidence" fields with
         | Some x -> x | None -> Null)
      | _ -> Null),
    get_axis_evidence "gamma" (match json with
      | Object fields ->
        (match List.assoc_opt "axis_evidence" fields with
         | Some x -> x | None -> Null)
      | _ -> Null),
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
