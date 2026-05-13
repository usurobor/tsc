(** OCaml test scaffolding for hybrid scoring — AC4, AC5, AC6.

    Tests run via: opam exec -- dune runtest engine/ocaml/test/

    Covered:
    AC4 — Bundle parity: direct-file and named-target paths produce Bundle.t with
           the same shape (same content hash for identical file content).
    AC5 — Mechanical determinism: identical bundle + config → identical result.
    AC6 — JSON schema shape: mechanical report contains all required fields. *)

open Tsc_engine
open Tsc_engine.Types

(* ------------------------------------------------------------------ *)
(* Helpers *)

let fail msg =
  Printf.eprintf "FAIL: %s\n%!" msg;
  exit 1

let pass label =
  Printf.printf "PASS: %s\n%!" label

let check cond label =
  if not cond then fail label else pass label

let get_string key = function
  | `Assoc fields ->
    (match List.assoc_opt key fields with
     | Some (`String s) -> s
     | _ -> fail (Printf.sprintf "field '%s' missing or not a string" key))
  | _ -> fail "expected JSON object"

let get_float key = function
  | `Assoc fields ->
    (match List.assoc_opt key fields with
     | Some (`Float f) -> f
     | Some (`Int i)   -> Float.of_int i
     | _ -> fail (Printf.sprintf "field '%s' missing or not a number" key))
  | _ -> fail "expected JSON object"

let has_field key = function
  | `Assoc fields -> List.mem_assoc key fields
  | _ -> false

(* ------------------------------------------------------------------ *)
(* Test fixtures *)

let make_file ~path ~content : bundle_file =
  { file_path    = path;
    file_content = content;
    file_hash    = Digestif.SHA256.(digest_string content |> to_hex);
    file_size    = String.length content;
    file_target_kind = Aggregate }

let sample_content_a =
  "# Alpha Document\n\
   \n\
   This is the canonical source for alpha.\n\
   \n\
   ## Section One\n\
   \n\
   Some content here.\n\
   \n\
   ## Section Two\n\
   \n\
   More content. See ARCHITECTURE.md for structure.\n"

let sample_content_b =
  "# Beta Document\n\
   \n\
   This is authoritative for beta.\n\
   \n\
   ## Overview\n\
   \n\
   Content for beta overview. Version: 0.5.0\n\
   \n\
   ## Details\n\
   \n\
   Cross-reference to [alpha](alpha.md).\n"

let sample_files = [
  make_file ~path:"alpha.md" ~content:sample_content_a;
  make_file ~path:"beta.md"  ~content:sample_content_b;
]

(* ------------------------------------------------------------------ *)
(* AC4: Bundle parity *)

let test_bundle_parity () =
  (* Direct files and named-target both use Bundle.build_bundle.
     Check that identical content produces identical hash. *)
  let files_from_pairs = [
    ("alpha.md", sample_content_a);
    ("beta.md",  sample_content_b);
  ] in
  let bundle_a =
    Bundle.build_bundle
      ~target_name:"direct"
      ~target_kind:Aggregate
      ~files:files_from_pairs
  in
  let bundle_b =
    Bundle.build_bundle
      ~target_name:"named"
      ~target_kind:Aggregate
      ~files:(List.rev files_from_pairs)  (* different order — should sort *)
  in
  (* Both bundles should have the same files after sorting (bundle sorts by path) *)
  let hashes_a = List.map (fun f -> (f.file_path, f.file_hash)) bundle_a.bundle_files in
  let hashes_b = List.map (fun f -> (f.file_path, f.file_hash)) bundle_b.bundle_files in
  check (hashes_a = hashes_b)
    "AC4: bundle parity — identical content + sorted paths → identical hashes";
  check (List.length bundle_a.bundle_files = List.length bundle_b.bundle_files)
    "AC4: bundle parity — same file count"

(* ------------------------------------------------------------------ *)
(* AC5: Mechanical determinism *)

let test_mechanical_determinism () =
  let r1 = Mechanical_scoring.score_files sample_files in
  let r2 = Mechanical_scoring.score_files sample_files in
  check (r1.alpha.score = r2.alpha.score)
    "AC5: determinism — alpha score stable across two runs";
  check (r1.beta.score = r2.beta.score)
    "AC5: determinism — beta score stable across two runs";
  check (r1.gamma.score = r2.gamma.score)
    "AC5: determinism — gamma score stable across two runs";
  check (r1.aggregate.c_sigma_math = r2.aggregate.c_sigma_math)
    "AC5: determinism — c_sigma_math stable across two runs";
  check (r1.aggregate.c_sigma_num = r2.aggregate.c_sigma_num)
    "AC5: determinism — c_sigma_num stable across two runs";
  check (r1.bottleneck_axis = r2.bottleneck_axis)
    "AC5: determinism — bottleneck_axis stable across two runs";
  (* Same config → same result *)
  let r3 = Mechanical_scoring.score_files
    ~config:Mechanical_scoring.default_config sample_files in
  check (r1.aggregate.c_sigma_num = r3.aggregate.c_sigma_num)
    "AC5: determinism — explicit default_config = implicit default"

(* ------------------------------------------------------------------ *)
(* AC5: Score range validity *)

let test_score_ranges () =
  let r = Mechanical_scoring.score_files sample_files in
  let in_range x = x >= 0.0 && x <= 1.0 in
  check (in_range r.alpha.score)   "AC5: alpha score in [0,1]";
  check (in_range r.beta.score)    "AC5: beta score in [0,1]";
  check (in_range r.gamma.score)   "AC5: gamma score in [0,1]";
  check (in_range r.aggregate.c_sigma_math)
    "AC5: c_sigma_math in [0,1]";
  check (in_range r.aggregate.c_sigma_num)
    "AC5: c_sigma_num in [0,1]";
  check (in_range r.confidence)    "AC5: confidence in [0,1]";
  List.iter (fun (sig_ : Mechanical_scoring.signal) ->
    check (in_range sig_.score)
      (Printf.sprintf "AC5: signal '%s' score in [0,1]" sig_.code)
  ) (r.alpha.signals @ r.beta.signals @ r.gamma.signals)

(* ------------------------------------------------------------------ *)
(* AC5: Empty bundle *)

let test_empty_bundle () =
  let r = Mechanical_scoring.score_files [] in
  check (r.mode = `Mechanical) "AC5: empty bundle mode = Mechanical";
  check (r.confidence = 0.0)   "AC5: empty bundle confidence = 0.0";
  let in_range x = x >= 0.0 && x <= 1.0 in
  check (in_range r.aggregate.c_sigma_math)
    "AC5: empty bundle c_sigma_math in [0,1]";
  check (in_range r.aggregate.c_sigma_num)
    "AC5: empty bundle c_sigma_num in [0,1]"

(* ------------------------------------------------------------------ *)
(* AC6: JSON schema shape for mechanical report *)

let test_mechanical_json_schema () =
  let r = Mechanical_scoring.score_files sample_files in
  let json = Mechanical_scoring.result_to_json r in
  (* Required fields per report.schema.json (v0.10.0 canonical-v3.2). *)
  check (has_field "mode"            json) "AC1: mechanical JSON has 'mode'";
  check (has_field "alpha"           json) "AC1: mechanical JSON has 'alpha'";
  check (has_field "beta"            json) "AC1: mechanical JSON has 'beta'";
  check (has_field "gamma"           json) "AC1: mechanical JSON has 'gamma'";
  check (has_field "bottleneck_axis" json) "AC1: mechanical JSON has 'bottleneck_axis'";
  check (has_field "evidence_kind"   json) "AC1: mechanical JSON has 'evidence_kind'";
  check (has_field "confidence"      json) "AC1: mechanical JSON has 'confidence'";
  check (has_field "provenance"      json) "AC1: mechanical JSON has 'provenance'";
  (* FORBIDDEN top-level fields per AC1. *)
  check (not (has_field "c_sigma"               json)) "AC1: mechanical JSON has NO flat 'c_sigma'";
  check (not (has_field "c_sigma_math"          json)) "AC1: mechanical JSON has NO flat 'c_sigma_math'";
  check (not (has_field "c_sigma_num"           json)) "AC1: mechanical JSON has NO flat 'c_sigma_num'";
  check (not (has_field "zero_component_present" json)) "AC1: mechanical JSON has NO flat 'zero_component_present'";
  check (not (has_field "numeric_floor_applied" json)) "AC1: mechanical JSON has NO flat 'numeric_floor_applied'";
  check (not (has_field "epsilon"               json)) "AC1: mechanical JSON has NO flat 'epsilon'";
  (* Values *)
  let mode = get_string "mode" json in
  check (mode = "mechanical") "AC1: mode field = 'mechanical'";
  let ev = get_string "evidence_kind" json in
  check (ev = "structural-proxy") "AC1: evidence_kind = 'structural-proxy'";
  let alpha = get_float "alpha" json in
  check (alpha >= 0.0 && alpha <= 1.0) "AC1: alpha in [0,1]";
  let bn = get_string "bottleneck_axis" json in
  check (bn = "alpha" || bn = "beta" || bn = "gamma")
    "AC1: bottleneck_axis in {alpha,beta,gamma}";
  (* Provenance carries aggregate facts in the canonical v3.2 sub-objects. *)
  let prov = match json with
    | `Assoc fields ->
      (match List.assoc_opt "provenance" fields with
       | Some o -> o
       | None -> fail "AC1: provenance missing")
    | _ -> fail "expected JSON object"
  in
  check (has_field "aggregate_math"  prov) "AC1: provenance has 'aggregate_math'";
  check (has_field "aggregate_numeric" prov) "AC1: provenance has 'aggregate_numeric'";
  check (has_field "gauge_witness"   prov) "AC1: provenance has 'gauge_witness'";
  (* AC4: the production gauge_witness call site emits actual W2 values
     (not nulls) — i.e. it was invoked with a real c_sigma_fn built from
     Coherence.aggregate. *)
  let gw = match prov with
    | `Assoc fields ->
      (match List.assoc_opt "gauge_witness" fields with
       | Some o -> o
       | None -> fail "AC4: gauge_witness sub-object missing")
    | _ -> fail "AC4: provenance not an object"
  in
  let gw_ref = match gw with
    | `Assoc fields -> List.assoc_opt "w_gauge_ref" fields
    | _ -> None
  in
  check (match gw_ref with Some (`Float _) -> true | _ -> false)
    "AC4: mechanical provenance.gauge_witness.w_gauge_ref is a number (canonical c_sigma_fn ran)"

(* ------------------------------------------------------------------ *)
(* AC6: JSON schema shape for hybrid report *)

let test_hybrid_json_schema () =
  (* Build a fake LLM result matching the Types.measure_result contract *)
  let llm_result : measure_result = {
    result_target = "test";
    result_alpha  = 0.85;
    result_beta   = 0.78;
    result_gamma  = 0.72;
    result_bottleneck_axis  = "gamma";
    result_confidence       = 0.90;
    result_summary = "Test hybrid result";
    result_alpha_evidence = { evidence_positive = ["good a"]; evidence_negative = []; evidence_reason = "test" };
    result_beta_evidence  = { evidence_positive = ["good b"]; evidence_negative = []; evidence_reason = "test" };
    result_gamma_evidence = { evidence_positive = ["good g"]; evidence_negative = []; evidence_reason = "test" };
    result_unresolved_ambiguity = [];
    result_next_fixes = [];
  } in
  let mech_result = Mechanical_scoring.score_files sample_files in
  let hybrid = Hybrid_scoring.combine ~target:"test" mech_result llm_result in
  let json = Hybrid_scoring.to_json hybrid in
  (* Required top-level fields (canonical v3.2). *)
  check (has_field "mode"            json) "AC1: hybrid JSON has 'mode'";
  check (has_field "alpha"           json) "AC1: hybrid JSON has 'alpha'";
  check (has_field "beta"            json) "AC1: hybrid JSON has 'beta'";
  check (has_field "gamma"           json) "AC1: hybrid JSON has 'gamma'";
  check (has_field "bottleneck_axis" json) "AC1: hybrid JSON has 'bottleneck_axis'";
  check (has_field "mechanical"      json) "AC1: hybrid JSON has 'mechanical' sub-object";
  check (has_field "llm"             json) "AC1: hybrid JSON has 'llm' sub-object";
  check (has_field "final"           json) "AC1: hybrid JSON has 'final' sub-object";
  check (has_field "provenance"      json) "AC1: hybrid JSON has 'provenance'";
  (* FORBIDDEN top-level c_sigma family (AC1). *)
  check (not (has_field "c_sigma"      json)) "AC1: hybrid JSON has NO flat 'c_sigma'";
  check (not (has_field "c_sigma_math" json)) "AC1: hybrid JSON has NO flat 'c_sigma_math'";
  check (not (has_field "c_sigma_num"  json)) "AC1: hybrid JSON has NO flat 'c_sigma_num'";
  let mode = get_string "mode" json in
  check (mode = "hybrid") "AC1: hybrid mode = 'hybrid'";
  (* final sub-object has source, no flat c_sigma *)
  let final_obj = match json with
    | `Assoc fields ->
      (match List.assoc_opt "final" fields with
       | Some o -> o
       | None -> fail "missing 'final'")
    | _ -> fail "expected object"
  in
  check (has_field "source"  final_obj) "AC1: final has 'source'";
  check (has_field "alpha"   final_obj) "AC1: final has 'alpha'";
  check (has_field "beta"    final_obj) "AC1: final has 'beta'";
  check (has_field "gamma"   final_obj) "AC1: final has 'gamma'";
  check (not (has_field "c_sigma" final_obj))
    "AC1: final sub-object has NO flat 'c_sigma'";
  let src = get_string "source" final_obj in
  check (src = "llm" || src = "mechanical" || src = "agreement")
    "AC1: final.source in {llm, mechanical, agreement}"

(* ------------------------------------------------------------------ *)
(* AC12: Hybrid preserves both backend results *)

let test_hybrid_preserves_both () =
  let llm_result : measure_result = {
    result_target = "test";
    result_alpha  = 0.80; result_beta = 0.70; result_gamma = 0.60;
    result_bottleneck_axis = "gamma"; result_confidence = 0.85;
    result_summary = "Test"; result_alpha_evidence = { evidence_positive = []; evidence_negative = []; evidence_reason = "" };
    result_beta_evidence  = { evidence_positive = []; evidence_negative = []; evidence_reason = "" };
    result_gamma_evidence = { evidence_positive = []; evidence_negative = []; evidence_reason = "" };
    result_unresolved_ambiguity = []; result_next_fixes = [];
  } in
  let mech_result = Mechanical_scoring.score_files sample_files in
  let hybrid = Hybrid_scoring.combine ~target:"test" mech_result llm_result in
  let json = Hybrid_scoring.to_json hybrid in
  (* Both sub-objects must survive *)
  let get_subobj key =
    match json with
    | `Assoc fields ->
      (match List.assoc_opt key fields with Some o -> o | None -> fail ("missing " ^ key))
    | _ -> fail "not an object"
  in
  let mech_obj = get_subobj "mechanical" in
  let llm_obj  = get_subobj "llm" in
  check (has_field "alpha" mech_obj && has_field "provenance" mech_obj)
    "AC1+AC12: mechanical sub-object preserved with alpha and nested provenance";
  check (has_field "alpha" llm_obj  && has_field "provenance" llm_obj)
    "AC1+AC12: llm sub-object preserved with alpha and nested provenance";
  check (not (has_field "c_sigma" mech_obj))
    "AC1: mechanical sub-object has NO flat 'c_sigma'";
  check (not (has_field "c_sigma" llm_obj))
    "AC1: llm sub-object has NO flat 'c_sigma'";
  let mech_ev = get_string "evidence_kind" mech_obj in
  let llm_ev  = get_string "evidence_kind" llm_obj  in
  check (mech_ev = "structural-proxy")   "AC12: mechanical evidence_kind = structural-proxy";
  check (llm_ev  = "semantic-judgment")  "AC12: llm evidence_kind = semantic-judgment"

(* ------------------------------------------------------------------ *)
(* Runner *)

(* ------------------------------------------------------------------ *)
(* AC8: Auto-mode fallback (Sub 2 AC11) *)

let test_auto_mode_fallback () =
  let saved = Sys.getenv_opt "LLM_API_KEY" in
  let restore () =
    match saved with
    | Some v -> Unix.putenv "LLM_API_KEY" v
    | None   -> Unix.putenv "LLM_API_KEY" ""
  in
  (* No credentials: credential check must return false *)
  Unix.putenv "LLM_API_KEY" "";
  check (not (Tsc_engine.Credentials.has_llm_credentials ()))
    "AC8: empty LLM_API_KEY → no credentials (auto falls back to mechanical)";
  (* With a non-empty key: credential check must return true *)
  Unix.putenv "LLM_API_KEY" "test-key-abc";
  check (Tsc_engine.Credentials.has_llm_credentials ())
    "AC8: non-empty LLM_API_KEY → credentials present (auto takes hybrid path)";
  restore ();
  (* Mechanical scorer always returns Mechanical mode regardless of env *)
  let r = Mechanical_scoring.score_files sample_files in
  check (r.mode = `Mechanical)
    "AC8: score_files always returns Mechanical mode (auto fallback path produces this)"

(* ------------------------------------------------------------------ *)
(* AC2: canonical aggregate routing — mechanical and hybrid path *)

(** Build a Mechanical_scoring.result with hand-chosen axis scores. The
    aggregate must equal [Coherence.aggregate]'s output, not (α+β+γ)/3. *)
let test_aggregate_uses_coherence_helper () =
  (* Unequal axis scores: arithmetic mean and geometric mean differ. *)
  let r = Mechanical_scoring.score_files sample_files in
  let expected = Tsc_engine.Coherence.aggregate
    ~epsilon:1e-5
    ~s_alpha:r.alpha.score
    ~s_beta:r.beta.score
    ~s_gamma:r.gamma.score
    ()
  in
  (* AC2 positive: aggregate facts equal Coherence.aggregate's output. *)
  check (r.aggregate.c_sigma_math = expected.c_sigma_math)
    "AC2: mechanical aggregate.c_sigma_math equals Coherence.aggregate output";
  check (r.aggregate.c_sigma_num = expected.c_sigma_num)
    "AC2: mechanical aggregate.c_sigma_num equals Coherence.aggregate output";
  check (r.aggregate.zero_component_present = expected.zero_component_present)
    "AC2: zero_component_present routed through Coherence.aggregate";
  check (r.aggregate.numeric_floor_applied = expected.numeric_floor_applied)
    "AC2: numeric_floor_applied routed through Coherence.aggregate";
  (* AC2 negative: with at least one unequal triple, geometric is NOT the
     arithmetic mean, so the engine cannot be silently using (α+β+γ)/3. *)
  let sa = r.alpha.score and sb = r.beta.score and sg = r.gamma.score in
  let arith = (sa +. sb +. sg) /. 3.0 in
  let max_axis = Float.max sa (Float.max sb sg) in
  let min_axis = Float.min sa (Float.min sb sg) in
  if max_axis -. min_axis > 0.01 then
    check (abs_float (r.aggregate.c_sigma_num -. arith) > 1e-12)
      "AC2: aggregate differs from arithmetic mean for unequal axis scores"

let test_hybrid_aggregate_uses_coherence_helper () =
  let llm_result : measure_result = {
    result_target = "test";
    result_alpha = 0.9; result_beta = 0.4; result_gamma = 0.2;
    result_bottleneck_axis = "gamma"; result_confidence = 0.85;
    result_summary = "test";
    result_alpha_evidence = { evidence_positive = []; evidence_negative = []; evidence_reason = "" };
    result_beta_evidence  = { evidence_positive = []; evidence_negative = []; evidence_reason = "" };
    result_gamma_evidence = { evidence_positive = []; evidence_negative = []; evidence_reason = "" };
    result_unresolved_ambiguity = []; result_next_fixes = [];
  } in
  let mech_result = Mechanical_scoring.score_files sample_files in
  let hybrid = Hybrid_scoring.combine ~target:"test" mech_result llm_result in
  let expected = Tsc_engine.Coherence.aggregate
    ~epsilon:1e-5
    ~s_alpha:hybrid.hyb_final_alpha
    ~s_beta:hybrid.hyb_final_beta
    ~s_gamma:hybrid.hyb_final_gamma
    ()
  in
  check (hybrid.hyb_final_aggregate.c_sigma_math = expected.c_sigma_math)
    "AC2: hybrid final aggregate.c_sigma_math equals Coherence.aggregate";
  check (hybrid.hyb_final_aggregate.c_sigma_num = expected.c_sigma_num)
    "AC2: hybrid final aggregate.c_sigma_num equals Coherence.aggregate";
  (* AC2 negative: unequal triple (0.9, 0.4, 0.2) ⇒ geometric != arithmetic. *)
  let arith =
    (hybrid.hyb_final_alpha +. hybrid.hyb_final_beta +. hybrid.hyb_final_gamma)
    /. 3.0
  in
  check (abs_float (hybrid.hyb_final_aggregate.c_sigma_num -. arith) > 1e-9)
    "AC2: hybrid aggregate differs from arithmetic mean for unequal triple"

(* ------------------------------------------------------------------ *)
(* AC3: comparison output names aggregate deltas by form *)

let test_comparison_delta_rename () =
  let bundle_a = Bundle.build_bundle
    ~target_name:"a" ~target_kind:Aggregate
    ~files:[("alpha.md", sample_content_a)]
  in
  let bundle_b = Bundle.build_bundle
    ~target_name:"b" ~target_kind:Aggregate
    ~files:[("alpha.md", sample_content_a); ("beta.md", sample_content_b)]
  in
  let cmp = Mechanical_scoring.compare ~old_:bundle_a ~new_:bundle_b in
  let json = Mechanical_scoring.comparison_to_json cmp in
  (* AC3 positive: form-suffixed delta fields are present. *)
  check (has_field "delta_c_sigma_num" json)
    "AC3: comparison JSON has 'delta_c_sigma_num'";
  check (has_field "delta_c_sigma_math" json)
    "AC3: comparison JSON has 'delta_c_sigma_math'";
  (* AC3 negative: unsuffixed delta is removed. *)
  check (not (has_field "delta_c_sigma" json))
    "AC3: comparison JSON has NO unsuffixed 'delta_c_sigma'";
  (* And the value matches the canonical aggregate delta. *)
  let expected_num =
    cmp.new_result.aggregate.c_sigma_num -. cmp.old_result.aggregate.c_sigma_num
  in
  let got_num = get_float "delta_c_sigma_num" json in
  check (abs_float (got_num -. expected_num) < 1e-12)
    "AC3: delta_c_sigma_num equals difference of canonical c_sigma_num"

(* ------------------------------------------------------------------ *)
(* AC5: degeneracy case — zero component => math = 0 < num *)

let test_aggregate_degeneracy () =
  let r = Tsc_engine.Coherence.aggregate
    ~epsilon:1e-5
    ~s_alpha:0.0 ~s_beta:0.6 ~s_gamma:0.5 ()
  in
  check (r.c_sigma_math = 0.0)
    "AC5: degeneracy — c_sigma_math = 0 when s_alpha = 0";
  check (r.c_sigma_num > 0.0)
    "AC5: degeneracy — c_sigma_num > 0 under epsilon floor";
  check r.zero_component_present
    "AC5: degeneracy — zero_component_present = true";
  check r.numeric_floor_applied
    "AC5: degeneracy — numeric_floor_applied = true"

(* ------------------------------------------------------------------ *)
(* Runner *)

let () =
  Printf.printf "=== TSC OCaml mechanical/hybrid tests ===\n%!";
  test_bundle_parity ();
  test_mechanical_determinism ();
  test_score_ranges ();
  test_empty_bundle ();
  test_mechanical_json_schema ();
  test_hybrid_json_schema ();
  test_hybrid_preserves_both ();
  test_aggregate_uses_coherence_helper ();
  test_hybrid_aggregate_uses_coherence_helper ();
  test_comparison_delta_rename ();
  test_aggregate_degeneracy ();
  test_auto_mode_fallback ();
  Printf.printf "=== All tests passed ===\n%!"
