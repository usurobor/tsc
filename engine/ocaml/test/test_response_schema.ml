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
   delta_alpha_beta value, an optional extra top-level field, and the
   per-axis checklists (v3.2.3 walk). The default checklists are the
   clean walk: every category present, count 0, severity "none". *)
let clean_checklist cats =
  "{" ^ String.concat ", "
    (List.map (fun c ->
      Printf.sprintf {|"%s": {"count": 0, "severity": "none"}|} c) cats)
  ^ "}"

let alpha_cats =
  ["naming-drift"; "duplicate-definition";
   "internal-contradiction"; "unstable-boundary"]
let beta_cats =
  ["broken-reference"; "authority-conflict";
   "fact-drift"; "undeclared-relationship"]
let gamma_cats =
  ["unowned-change-path"; "generated-canonical-confusion";
   "missing-migration-rule"; "stale-transitional-marker"]

let witness_raw ?(delta_ab = "0.1") ?(extra = "")
    ?(alpha_checklist = clean_checklist alpha_cats)
    ?(beta_checklist = clean_checklist beta_cats)
    ?(gamma_checklist = clean_checklist gamma_cats)
    ?(defect_cards = "[]")
    () = Printf.sprintf {|{
  "target": "spec",
  "alpha": 0.9, "beta": 0.8, "gamma": 0.7,
  "delta_alpha_beta": %s, "delta_beta_gamma": 0.2, "delta_gamma_alpha": 0.15,
  "bottleneck_axis": "gamma",
  "confidence": 0.8,
  "summary": "funnel fixture",
  "axis_evidence": {
    "alpha": {"positive": ["p"], "negative": ["n"], "reason": "r", "checklist": %s},
    "beta":  {"positive": ["p"], "negative": ["n"], "reason": "r", "checklist": %s},
    "gamma": {"positive": ["p"], "negative": ["n"], "reason": "r", "checklist": %s}
  },
  "unresolved_ambiguity": [],
  "next_fixes": [],
  "defect_cards": %s%s
}|} delta_ab alpha_checklist beta_checklist gamma_checklist defect_cards extra

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

(* v3.2.3 checklist stage: the forced walk is required and shape-checked
   AFTER the delta stage — a response valid to v3.2.2 but without the
   walk is refused at "checklist", never silently accepted. *)

let test_funnel_missing_checklist () =
  expect_stage "funnel negative: missing checklist refused (v3.2.3 walk)"
    ~expected_target:"spec"
    (witness_raw ~alpha_checklist:"{}" ())
    "checklist"

let test_funnel_absent_checklist_object () =
  (* No checklist key at all on one axis: base schema tolerates it
     (parse-level), the checklist stage refuses it. *)
  let raw = Printf.sprintf {|{
  "target": "spec",
  "alpha": 0.9, "beta": 0.8, "gamma": 0.7,
  "delta_alpha_beta": 0.1, "delta_beta_gamma": 0.2, "delta_gamma_alpha": 0.15,
  "bottleneck_axis": "gamma",
  "confidence": 0.8,
  "summary": "funnel fixture",
  "axis_evidence": {
    "alpha": {"positive": ["p"], "negative": ["n"], "reason": "r"},
    "beta":  {"positive": ["p"], "negative": ["n"], "reason": "r", "checklist": %s},
    "gamma": {"positive": ["p"], "negative": ["n"], "reason": "r", "checklist": %s}
  },
  "unresolved_ambiguity": [],
  "next_fixes": []
}|} (clean_checklist beta_cats) (clean_checklist gamma_cats) in
  expect_stage "funnel negative: axis without checklist key refused"
    ~expected_target:"spec" raw "checklist"

let test_funnel_unknown_category () =
  expect_stage "funnel negative: unknown checklist category refused"
    ~expected_target:"spec"
    (witness_raw
       ~alpha_checklist:(clean_checklist
         ["naming-drift"; "duplicate-definition";
          "internal-contradiction"; "vibes"]) ())
    "checklist"

let test_funnel_severity_count_mismatch () =
  expect_stage "funnel negative: count 0 with non-none severity refused"
    ~expected_target:"spec"
    (witness_raw
       ~alpha_checklist:{|{"naming-drift": {"count": 0, "severity": "systemic"},
         "duplicate-definition": {"count": 0, "severity": "none"},
         "internal-contradiction": {"count": 0, "severity": "none"},
         "unstable-boundary": {"count": 0, "severity": "none"}}|} ())
    "checklist"

let nonzero_beta_cards = {|[
  {"id": "D1", "primary_axis": "beta", "category": "broken-reference",
   "severity": "isolated", "evidence": "f:1", "summary": "ref one"},
  {"id": "D2", "primary_axis": "beta", "category": "broken-reference",
   "severity": "cosmetic", "evidence": "f:2", "summary": "ref two"},
  {"id": "D3", "primary_axis": "beta", "category": "fact-drift",
   "severity": "cosmetic", "evidence": "f:3", "summary": "drift one",
   "secondary_axes": ["gamma"]}
]|}

let test_funnel_accepts_nonzero_walk () =
  let raw = witness_raw
    ~defect_cards:nonzero_beta_cards
    ~beta_checklist:{|{"broken-reference": {"count": 2, "severity": "isolated"},
      "authority-conflict": {"count": 0, "severity": "none"},
      "fact-drift": {"count": 1, "severity": "cosmetic"},
      "undeclared-relationship": {"count": 0, "severity": "none"}}|} () in
  match Response_schema.validate_witness_response ~expected_target:"spec" raw with
  | Ok (result, _) ->
    let bl = result.Tsc_engine.Types.result_beta_evidence.evidence_checklist in
    check (List.assoc "broken-reference" bl = (2, "isolated"))
      "funnel positive: non-zero walk accepted and parsed"
  | Error wf ->
    fail ("funnel positive: non-zero walk refused: "
          ^ Response_schema.format_witness_failure wf)

(* v3.2.4 defect-card stage: cards are required when the walk counts
   defects, and must reconcile with the checklist. *)

let nonzero_beta_checklist =
  {|{"broken-reference": {"count": 2, "severity": "isolated"},
    "authority-conflict": {"count": 0, "severity": "none"},
    "fact-drift": {"count": 1, "severity": "cosmetic"},
    "undeclared-relationship": {"count": 0, "severity": "none"}}|}

let test_funnel_cards_missing_with_defects () =
  expect_stage "funnel negative: walk counts defects but no cards"
    ~expected_target:"spec"
    (witness_raw ~beta_checklist:nonzero_beta_checklist ())
    "defect_cards"

let test_funnel_cards_duplicate_id () =
  let cards = {|[
    {"id": "D1", "primary_axis": "beta", "category": "broken-reference",
     "severity": "isolated", "evidence": "f:1", "summary": "ref one"},
    {"id": "D1", "primary_axis": "beta", "category": "broken-reference",
     "severity": "cosmetic", "evidence": "f:2", "summary": "ref two"},
    {"id": "D3", "primary_axis": "beta", "category": "fact-drift",
     "severity": "cosmetic", "evidence": "f:3", "summary": "drift"}
  ]|} in
  expect_stage "funnel negative: duplicate card id"
    ~expected_target:"spec"
    (witness_raw ~defect_cards:cards
       ~beta_checklist:nonzero_beta_checklist ())
    "defect_cards"

let test_funnel_cards_two_primary_axes () =
  (* identical evidence+summary filed under two primary axes *)
  let cards = {|[
    {"id": "D1", "primary_axis": "beta", "category": "broken-reference",
     "severity": "isolated", "evidence": "same", "summary": "same defect"},
    {"id": "D2", "primary_axis": "beta", "category": "broken-reference",
     "severity": "cosmetic", "evidence": "f:2", "summary": "ref two"},
    {"id": "D3", "primary_axis": "beta", "category": "fact-drift",
     "severity": "cosmetic", "evidence": "f:3", "summary": "drift"},
    {"id": "D4", "primary_axis": "alpha", "category": "internal-contradiction",
     "severity": "isolated", "evidence": "same", "summary": "same defect"}
  ]|} in
  let alpha = {|{"naming-drift": {"count": 0, "severity": "none"},
    "duplicate-definition": {"count": 0, "severity": "none"},
    "internal-contradiction": {"count": 1, "severity": "isolated"},
    "unstable-boundary": {"count": 0, "severity": "none"}}|} in
  expect_stage "funnel negative: one defect under two primary axes"
    ~expected_target:"spec"
    (witness_raw ~defect_cards:cards ~alpha_checklist:alpha
       ~beta_checklist:nonzero_beta_checklist ())
    "defect_cards"

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
(* Funnel-valid medoid election (post-loop stabilization Issue 1).
   A sample can be NUMERICALLY complete yet funnel-invalid (e.g. a
   duplicate defect-card id): Witness_medoid.choose_valid must never
   elect it, and zero funnel-valid samples must be an explicit Error,
   never a fallback to an invalid sample. *)

let write_tmp name content =
  let path = Filename.concat (Filename.get_temp_dir_name ()) name in
  let oc = open_out path in
  output_string oc content; close_out oc; path

let numerically_complete_invalid_raw =
  (* duplicate card id — refused at the defect_cards stage, but every
     numeric contract field is present and parseable *)
  witness_raw
    ~defect_cards:{|[
      {"id": "D1", "primary_axis": "beta", "category": "broken-reference",
       "severity": "isolated", "evidence": "f:1", "summary": "ref one"},
      {"id": "D1", "primary_axis": "beta", "category": "broken-reference",
       "severity": "cosmetic", "evidence": "f:2", "summary": "ref two"},
      {"id": "D3", "primary_axis": "beta", "category": "fact-drift",
       "severity": "cosmetic", "evidence": "f:3", "summary": "drift"}
    ]|}
    ~beta_checklist:nonzero_beta_checklist ()

let test_medoid_choose_valid_excludes_funnel_invalid () =
  let invalid = write_tmp "cv_invalid.json" numerically_complete_invalid_raw in
  (* Sanity: the invalid sample IS numerically complete — the legacy
     numeric election alone would consider it. *)
  (match Witness_numeric.of_json_file invalid with
   | Ok _ -> pass "choose_valid setup: invalid sample is numerically complete"
   | Error e -> fail ("choose_valid setup: invalid sample not numeric: " ^ e));
  let valid1 = write_tmp "cv_valid1.json" (witness_raw ()) in
  let valid2 = write_tmp "cv_valid2.json" (witness_raw ~delta_ab:"0.12" ()) in
  (* Positive: election runs over the funnel-valid pair only; the
     invalid sample is listed first and must never win. *)
  (match Witness_medoid.choose_valid ~expected_target:"spec"
           [ invalid; valid1; valid2 ] with
   | Ok p ->
     check (p = valid1 || p = valid2)
       "choose_valid: funnel-invalid sample never elected";
     check (p <> invalid)
       "choose_valid: canonical response is a funnel-valid sample"
   | Error e -> fail ("choose_valid: valid pair errored: " ^ e));
  (* Negative: zero funnel-valid samples -> explicit Error, no
     first-argument fallback (the legacy numeric mode would have
     returned the invalid sample here). *)
  (match Witness_medoid.choose_valid ~expected_target:"spec" [ invalid ] with
   | Error _ -> pass "choose_valid: zero valid samples is an explicit Error"
   | Ok p -> fail ("choose_valid: zero-valid case elected " ^ p));
  (* Contrast pin: the legacy numeric election DOES admit the invalid
     sample — the two modes must stay distinguishable. *)
  (match Witness_medoid.choose [ invalid ] with
   | Ok p ->
     check (p = invalid)
       "choose (legacy numeric): still admits numerically complete samples"
   | Error e -> fail ("choose legacy contrast errored: " ^ e));
  (* Empty input refused in valid mode too. *)
  (match Witness_medoid.choose_valid ~expected_target:"spec" [] with
   | Error _ -> pass "choose_valid: empty input refused"
   | Ok _ -> fail "choose_valid: empty input accepted")

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
  test_funnel_missing_checklist ();
  test_funnel_absent_checklist_object ();
  test_funnel_unknown_category ();
  test_funnel_severity_count_mismatch ();
  test_funnel_accepts_nonzero_walk ();
  test_funnel_cards_missing_with_defects ();
  test_funnel_cards_duplicate_id ();
  test_funnel_cards_two_primary_axes ();
  test_medoid_choose_valid_excludes_funnel_invalid ();
  Printf.printf "All response_schema v3.2 strict validation tests passed.\n%!"
