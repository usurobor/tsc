(** Tests for strict v3.2 delta validation (cycle/51 AC1).

    Covered:
    - validate_v32_deltas Ok when all three required delta fields are present
      and in [0, 1].
    - validate_v32_deltas Error when a required field is missing, naming
      that field in missing_fields.
    - validate_v32_deltas Error when a present field is out of [0, 1],
      naming that field in invalid_fields with the observed value
      rendered as a string. *)

open Tsc_engine

let fail msg =
  Printf.eprintf "FAIL: %s\n%!" msg;
  exit 1

let pass label =
  Printf.printf "PASS: %s\n%!" label

let check cond label =
  if not cond then fail label else pass label

let parse raw =
  match Response_schema.parse_json raw with
  | Ok j -> j
  | Error e -> fail (Printf.sprintf "parse setup failed: %s" e)

(* ------------------------------------------------------------------ *)
(* AC1 positive: all three delta fields present and in range.          *)

let test_valid_v32_deltas () =
  let label = "AC1 positive: validate_v32_deltas accepts all three deltas in [0, 1]" in
  let j = parse {|{
    "delta_alpha_beta":  0.3,
    "delta_beta_gamma":  0.7,
    "delta_gamma_alpha": 0.2
  }|} in
  match Response_schema.validate_v32_deltas j with
  | Ok (d_ab, d_bg, d_ga) ->
    check (abs_float (d_ab -. 0.3) < 1e-9
        && abs_float (d_bg -. 0.7) < 1e-9
        && abs_float (d_ga -. 0.2) < 1e-9) label
  | Error _ ->
    fail (label ^ " — got Error instead of Ok")

(* AC1 positive: integer-valued deltas (0 and 1) are accepted. *)
let test_valid_v32_deltas_integers () =
  let label = "AC1 positive: integer deltas at boundaries (0, 1) accepted" in
  let j = parse {|{
    "delta_alpha_beta":  0,
    "delta_beta_gamma":  1,
    "delta_gamma_alpha": 0
  }|} in
  match Response_schema.validate_v32_deltas j with
  | Ok (d_ab, d_bg, d_ga) ->
    check (d_ab = 0.0 && d_bg = 1.0 && d_ga = 0.0) label
  | Error _ -> fail (label ^ " — got Error instead of Ok")

(* ------------------------------------------------------------------ *)
(* AC1 negative: missing delta_beta_gamma must be named.               *)

let test_missing_delta_beta_gamma () =
  let label = "AC1 negative: missing delta_beta_gamma is named in missing_fields" in
  let j = parse {|{
    "delta_alpha_beta":  0.3,
    "delta_gamma_alpha": 0.2
  }|} in
  match Response_schema.validate_v32_deltas j with
  | Ok _ ->
    fail (label ^ " — got Ok despite missing field")
  | Error err ->
    let names_field = List.mem "delta_beta_gamma" err.missing_fields in
    let no_invalids = err.invalid_fields = [] in
    let only_one_missing = List.length err.missing_fields = 1 in
    check (names_field && no_invalids && only_one_missing) label

(* AC1 negative: all three missing -> all three listed. *)
let test_missing_all_deltas () =
  let label = "AC1 negative: all three deltas missing yields full missing_fields list" in
  let j = parse {|{}|} in
  match Response_schema.validate_v32_deltas j with
  | Ok _ -> fail (label ^ " — got Ok on empty object")
  | Error err ->
    let s = err.missing_fields in
    check (List.mem "delta_alpha_beta" s
        && List.mem "delta_beta_gamma" s
        && List.mem "delta_gamma_alpha" s
        && List.length s = 3
        && err.invalid_fields = []) label

(* ------------------------------------------------------------------ *)
(* AC1 negative: out-of-range delta_alpha_beta = 1.5.                  *)

let test_out_of_range_delta () =
  let label = "AC1 negative: out-of-range delta is named with observed value" in
  let j = parse {|{
    "delta_alpha_beta":  1.5,
    "delta_beta_gamma":  0.7,
    "delta_gamma_alpha": 0.2
  }|} in
  match Response_schema.validate_v32_deltas j with
  | Ok _ -> fail (label ^ " — got Ok on out-of-range delta")
  | Error err ->
    let observed =
      List.assoc_opt "delta_alpha_beta" err.invalid_fields
    in
    let mentions_value =
      match observed with
      | None -> false
      | Some v -> String.length v > 0
    in
    check (err.missing_fields = []
        && List.length err.invalid_fields = 1
        && observed <> None
        && mentions_value) label

(* AC1 negative: negative delta value also rejected. *)
let test_negative_delta () =
  let label = "AC1 negative: negative delta rejected as out of [0, 1]" in
  let j = parse {|{
    "delta_alpha_beta":  -0.01,
    "delta_beta_gamma":  0.5,
    "delta_gamma_alpha": 0.5
  }|} in
  match Response_schema.validate_v32_deltas j with
  | Ok _ -> fail (label ^ " — got Ok on negative delta")
  | Error err ->
    check (List.mem_assoc "delta_alpha_beta" err.invalid_fields
        && err.missing_fields = []) label

(* AC1 negative: non-numeric delta (string) rejected. *)
let test_string_delta () =
  let label = "AC1 negative: string-valued delta rejected" in
  let j = parse {|{
    "delta_alpha_beta":  "not-a-number",
    "delta_beta_gamma":  0.5,
    "delta_gamma_alpha": 0.5
  }|} in
  match Response_schema.validate_v32_deltas j with
  | Ok _ -> fail (label ^ " — got Ok on string delta")
  | Error err ->
    check (List.mem_assoc "delta_alpha_beta" err.invalid_fields) label

(* AC1 negative: mixed missing + invalid -> both lists populated. *)
let test_mixed_missing_and_invalid () =
  let label = "AC1 negative: mixed missing + invalid populates both lists" in
  let j = parse {|{
    "delta_alpha_beta":  2.0
  }|} in
  match Response_schema.validate_v32_deltas j with
  | Ok _ -> fail (label ^ " — got Ok on mixed bad input")
  | Error err ->
    check (List.mem_assoc "delta_alpha_beta" err.invalid_fields
        && List.mem "delta_beta_gamma" err.missing_fields
        && List.mem "delta_gamma_alpha" err.missing_fields) label

(* ------------------------------------------------------------------ *)
(* Witness-validation funnel (review round 2)                          *)
(*
   Every refusal stage is classified; no stage falls through to another
   or silently accepts. Fixtures mirror the failure shapes a live Claude
   CLI witness is most likely to produce: prose, fenced JSON, missing
   base fields, computed coherence, wrong target, bad deltas. *)

(* A base-valid witness response for target "spec", parameterized on the
   delta_alpha_beta value and an optional extra top-level field. *)
let witness_raw ?(delta_ab = "0.1") ?(extra = "") () = Printf.sprintf {|{
  "target": "spec",
  "alpha": 0.9, "beta": 0.8, "gamma": 0.7,
  "delta_alpha_beta": %s, "delta_beta_gamma": 0.2, "delta_gamma_alpha": 0.15,
  "bottleneck_axis": "gamma",
  "confidence": 0.8,
  "summary": "funnel fixture",
  "axis_evidence": {
    "alpha": {"positive": ["p"], "negative": ["n"], "reason": "r"},
    "beta":  {"positive": ["p"], "negative": ["n"], "reason": "r"},
    "gamma": {"positive": ["p"], "negative": ["n"], "reason": "r"}
  },
  "unresolved_ambiguity": [],
  "next_fixes": []%s
}|} delta_ab extra

let valid_witness_raw = witness_raw ()

let expect_stage label raw ~expected_target stage =
  match Response_schema.validate_witness_response ~expected_target raw with
  | Ok _ -> fail (label ^ " — accepted instead of refused")
  | Error wf ->
    check (Response_schema.witness_stage_to_string wf.wf_stage = stage)
      (Printf.sprintf "%s (stage=%s)" label stage)

let test_funnel_accepts_valid () =
  let label = "funnel positive: fully valid witness response accepted" in
  match
    Response_schema.validate_witness_response
      ~expected_target:"spec" valid_witness_raw
  with
  | Ok (result, (d_ab, _, _)) ->
    check (result.Tsc_engine.Types.result_target = "spec"
        && abs_float (d_ab -. 0.1) < 1e-9) label
  | Error wf ->
    fail (label ^ " — refused: " ^ Response_schema.format_witness_failure wf)

let test_funnel_prose () =
  expect_stage "funnel negative: prose refused" ~expected_target:"spec"
    "The coherence of this bundle seems quite high overall."
    "parse"

let test_funnel_fenced_json () =
  expect_stage "funnel negative: fenced ```json refused" ~expected_target:"spec"
    ("```json\n" ^ valid_witness_raw ^ "\n```")
    "parse"

let test_funnel_missing_base_field () =
  (* Valid JSON, but no summary / axis_evidence / etc. *)
  expect_stage "funnel negative: missing base contract fields refused"
    ~expected_target:"spec"
    {|{"target": "spec", "alpha": 0.9, "beta": 0.8, "gamma": 0.7}|}
    "base_schema"

let test_funnel_prohibited_coherence () =
  (* Structurally valid response that also computes C_sigma — the witness
     must not compute coherence; the engine owns the transform. *)
  expect_stage "funnel negative: computed C_sigma field refused"
    ~expected_target:"spec"
    (witness_raw ~extra:",\n  \"C_sigma\": 0.82" ())
    "prohibited_fields"

let test_funnel_target_mismatch () =
  expect_stage "funnel negative: wrong target refused"
    ~expected_target:"engine" valid_witness_raw "target_mismatch"

let test_funnel_delta_failure_classified () =
  (* Base-valid response with one delta out of range: must be classified as
     the v3.2 delta stage, and name the offending field. *)
  let raw = witness_raw ~delta_ab:"1.5" () in
  match Response_schema.validate_witness_response ~expected_target:"spec" raw with
  | Ok _ -> fail "funnel negative: out-of-range delta accepted"
  | Error wf ->
    check (Response_schema.witness_stage_to_string wf.wf_stage = "v3_2_delta"
        && List.mem_assoc "delta_alpha_beta" wf.wf_invalid_fields)
      "funnel negative: out-of-range delta classified as v3_2_delta with field named"

(* ------------------------------------------------------------------ *)

let () =
  test_valid_v32_deltas ();
  test_valid_v32_deltas_integers ();
  test_missing_delta_beta_gamma ();
  test_missing_all_deltas ();
  test_out_of_range_delta ();
  test_negative_delta ();
  test_string_delta ();
  test_mixed_missing_and_invalid ();
  test_funnel_accepts_valid ();
  test_funnel_prose ();
  test_funnel_fenced_json ();
  test_funnel_missing_base_field ();
  test_funnel_prohibited_coherence ();
  test_funnel_target_mismatch ();
  test_funnel_delta_failure_classified ();
  Printf.printf "All response_schema v3.2 strict validation tests passed.\n%!"
