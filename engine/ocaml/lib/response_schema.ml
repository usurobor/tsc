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
    them (pre-v3.2.0 response format).

    This helper is kept for callers that tolerate absent delta (e.g. legacy
    provenance back-fill). v3.2 strict validation goes through
    {!validate_v32_deltas} instead. *)
let extract_deltas json =
  match
    get_float_opt "delta_alpha_beta"  json,
    get_float_opt "delta_beta_gamma"  json,
    get_float_opt "delta_gamma_alpha" json
  with
  | Ok d_ab, Ok d_bg, Ok d_ga -> Ok (d_ab, d_bg, d_ga)
  | Error e, _, _ | _, Error e, _ | _, _, Error e -> Error e

(* ------------------------------------------------------------------ *)
(* v3.2 strict delta validation (cycle/51 AC1)                        *)
(* ------------------------------------------------------------------ *)

(** Structured v3.2 delta validation error.
    - [missing_fields]: required delta fields absent from the response.
    - [invalid_fields]: present but non-numeric or out of [0, 1].
      Each entry is (field_name, observed_value_as_string).

    The error is always populated when at least one field is missing or
    invalid; both lists may be non-empty simultaneously. *)
type v32_validation_error = {
  missing_fields : string list;
  invalid_fields : (string * string) list;
}

let v32_required_delta_fields =
  ["delta_alpha_beta"; "delta_beta_gamma"; "delta_gamma_alpha"]

(** Classify a single required delta field as
    - [`Missing]            absent from the object
    - [`Invalid of string]  present but not a number, or out of [0, 1]
    - [`Valid of float]     present, numeric, and in [0, 1]. *)
let classify_v32_delta key = function
  | `Assoc fields ->
    (match List.assoc_opt key fields with
     | None -> `Missing
     | Some (`Float f) ->
       if f >= 0.0 && f <= 1.0 then `Valid f
       else `Invalid (Printf.sprintf "%.6g" f)
     | Some (`Int i) ->
       let f = Float.of_int i in
       if f >= 0.0 && f <= 1.0 then `Valid f
       else `Invalid (Printf.sprintf "%d" i)
     | Some (`Bool b) -> `Invalid (if b then "true" else "false")
     | Some `Null -> `Invalid "null"
     | Some (`String s) -> `Invalid (Printf.sprintf "\"%s\"" s)
     | Some other -> `Invalid (Yojson.Safe.to_string other))
  | _ -> `Invalid "<not an object>"

(** Strict v3.2 delta validation entry point.

    Requires [delta_alpha_beta], [delta_beta_gamma], and [delta_gamma_alpha]
    to all be present as numbers in [0, 1]. Returns
    - [Ok (d_ab, d_bg, d_ga)] when all three are present and valid.
    - [Error err] otherwise; [err.missing_fields] names every absent field,
      and [err.invalid_fields] names every present-but-bad field together
      with its observed value rendered as a string.

    This function does not short-circuit: callers receive the full list of
    offending fields so the validation-failure artifact can name them all
    at once. *)
let validate_v32_deltas json =
  let missing = ref [] in
  let invalid = ref [] in
  let values  = ref [] in
  List.iter (fun key ->
    match classify_v32_delta key json with
    | `Missing -> missing := key :: !missing
    | `Invalid v -> invalid := (key, v) :: !invalid
    | `Valid f -> values := (key, f) :: !values
  ) v32_required_delta_fields;
  if !missing = [] && !invalid = [] then
    let lookup k = List.assoc k !values in
    Ok (lookup "delta_alpha_beta",
        lookup "delta_beta_gamma",
        lookup "delta_gamma_alpha")
  else
    Error {
      missing_fields = List.rev !missing;
      invalid_fields = List.rev !invalid;
    }

(* ------------------------------------------------------------------ *)
(* Witness-validation funnel                                          *)
(* ------------------------------------------------------------------ *)

(** Every way a witness (LLM) response can be refused, as one classification
    so callers write one validation-failure artifact shape for all stages
    (skills/self-measure/SKILL.md §4: "a refused witness is a recorded fact").

    Stages, in checking order:
    - [`Parse]             raw text is not a JSON object (includes fenced
                           ```json blocks and prose around the object)
    - [`Base_schema]       JSON object missing/mistyping a base contract
                           field (target, scores, evidence, ...)
    - [`Prohibited_fields] response carries computed coherence — the witness
                           estimates deltas; the engine computes Coh/C_sigma
    - [`Target_mismatch]   response's [target] is not the measured target
    - [`V32_delta]         strict v3.2 delta validation failed *)
type witness_failure_stage =
  [ `Parse | `Base_schema | `Prohibited_fields | `Target_mismatch | `V32_delta ]

type witness_failure = {
  wf_stage : witness_failure_stage;
  wf_errors : string list;
  (* Populated for the [`V32_delta] stage; empty otherwise. *)
  wf_missing_fields : string list;
  wf_invalid_fields : (string * string) list;
}

let witness_stage_to_string = function
  | `Parse             -> "parse"
  | `Base_schema       -> "base_schema"
  | `Prohibited_fields -> "prohibited_fields"
  | `Target_mismatch   -> "target_mismatch"
  | `V32_delta         -> "v3_2_delta"

(** Top-level fields the witness must never emit: computed coherence.
    The scoring instruction (§3) reserves the barrier transform and
    aggregation for the engine. Explicit key list — no substring matching,
    so legitimate fields can never be caught by accident. *)
let prohibited_top_level_fields =
  [ "coh"; "Coh";
    "c_sigma"; "C_sigma";
    "c_sigma_num"; "C_sigma_num";
    "c_sigma_math"; "C_sigma_math";
    "coherence" ]

let find_prohibited_fields = function
  | `Assoc fields ->
    List.filter (fun k -> List.mem_assoc k fields) prohibited_top_level_fields
  | _ -> []

let witness_failure ?(missing = []) ?(invalid = []) stage errors =
  { wf_stage = stage;
    wf_errors = errors;
    wf_missing_fields = missing;
    wf_invalid_fields = invalid }

(** Validate a raw witness response end to end.

    [expected_target] is the measured target's kind string
    ("spec" | "engine" | "repo") — the same value the prompt metadata
    carried, and the value the output contract requires in [target].

    Returns [Ok (result, (d_ab, d_bg, d_ga))] only when every stage passes;
    otherwise the first failing stage, classified. No stage falls back. *)
let validate_witness_response ~expected_target raw =
  match parse_json raw with
  | Error e -> Error (witness_failure `Parse [e])
  | Ok json ->
    match validate_result json with
    | Error e -> Error (witness_failure `Base_schema [e])
    | Ok result ->
      match find_prohibited_fields json with
      | _ :: _ as keys ->
        Error (witness_failure `Prohibited_fields
                 (List.map
                    (Printf.sprintf
                       "field '%s' carries computed coherence; the engine \
                        applies the barrier transform and aggregation")
                    keys))
      | [] ->
        if result.result_target <> expected_target then
          Error (witness_failure `Target_mismatch
                   [Printf.sprintf
                      "response target '%s' does not match measured target '%s'"
                      result.result_target expected_target])
        else
          match validate_v32_deltas json with
          | Error err ->
            Error (witness_failure `V32_delta
                     ~missing:err.missing_fields
                     ~invalid:err.invalid_fields
                     [])
          | Ok deltas -> Ok (result, deltas)

(** Render a witness failure as a single-line human string (stderr). *)
let format_witness_failure wf =
  let stage = witness_stage_to_string wf.wf_stage in
  let details =
    match wf.wf_stage with
    | `V32_delta ->
      let parts = ref [] in
      if wf.wf_missing_fields <> [] then
        parts := Printf.sprintf "missing: %s"
            (String.concat ", " wf.wf_missing_fields) :: !parts;
      if wf.wf_invalid_fields <> [] then
        parts := Printf.sprintf "invalid: %s"
            (String.concat ", "
               (List.map (fun (k, v) -> k ^ "=" ^ v) wf.wf_invalid_fields))
          :: !parts;
      String.concat "; " (List.rev !parts)
    | _ -> String.concat "; " wf.wf_errors
  in
  Printf.sprintf "stage=%s: %s" stage details

(** Render a v3.2 delta validation error as a single-line human string.
    Used for stderr; the durable artifact uses the structured shape. *)
let format_v32_validation_error err =
  let parts = ref [] in
  if err.missing_fields <> [] then
    parts :=
      Printf.sprintf "missing required delta field(s): %s"
        (String.concat ", " err.missing_fields) :: !parts;
  if err.invalid_fields <> [] then
    parts :=
      Printf.sprintf "invalid delta field(s): %s"
        (String.concat ", "
           (List.map
              (fun (k, v) -> Printf.sprintf "%s=%s (expected number in [0, 1])" k v)
              err.invalid_fields)) :: !parts;
  String.concat "; " (List.rev !parts)
