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
  check (r1.c_sigma = r2.c_sigma)
    "AC5: determinism — c_sigma stable across two runs";
  check (r1.bottleneck_axis = r2.bottleneck_axis)
    "AC5: determinism — bottleneck_axis stable across two runs";
  (* Same config → same result *)
  let r3 = Mechanical_scoring.score_files
    ~config:Mechanical_scoring.default_config sample_files in
  check (r1.c_sigma = r3.c_sigma)
    "AC5: determinism — explicit default_config = implicit default"

(* ------------------------------------------------------------------ *)
(* AC5: Score range validity *)

let test_score_ranges () =
  let r = Mechanical_scoring.score_files sample_files in
  let in_range x = x >= 0.0 && x <= 1.0 in
  check (in_range r.alpha.score)   "AC5: alpha score in [0,1]";
  check (in_range r.beta.score)    "AC5: beta score in [0,1]";
  check (in_range r.gamma.score)   "AC5: gamma score in [0,1]";
  check (in_range r.c_sigma)       "AC5: c_sigma in [0,1]";
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
  check (in_range r.c_sigma)   "AC5: empty bundle c_sigma in [0,1]"

(* ------------------------------------------------------------------ *)
(* AC6: JSON schema shape for mechanical report *)

let test_mechanical_json_schema () =
  let r = Mechanical_scoring.score_files sample_files in
  let json = Mechanical_scoring.result_to_json r in
  (* Required fields per report.schema.json *)
  check (has_field "mode"            json) "AC6: mechanical JSON has 'mode'";
  check (has_field "alpha"           json) "AC6: mechanical JSON has 'alpha'";
  check (has_field "beta"            json) "AC6: mechanical JSON has 'beta'";
  check (has_field "gamma"           json) "AC6: mechanical JSON has 'gamma'";
  check (has_field "c_sigma"         json) "AC6: mechanical JSON has 'c_sigma'";
  check (has_field "bottleneck_axis" json) "AC6: mechanical JSON has 'bottleneck_axis'";
  check (has_field "evidence_kind"   json) "AC6: mechanical JSON has 'evidence_kind'";
  check (has_field "confidence"      json) "AC6: mechanical JSON has 'confidence'";
  (* Values *)
  let mode = get_string "mode" json in
  check (mode = "mechanical") "AC6: mode field = 'mechanical'";
  let ev = get_string "evidence_kind" json in
  check (ev = "structural-proxy") "AC6: evidence_kind = 'structural-proxy'";
  let alpha = get_float "alpha" json in
  check (alpha >= 0.0 && alpha <= 1.0) "AC6: alpha in [0,1]";
  let cs = get_float "c_sigma" json in
  check (cs >= 0.0 && cs <= 1.0) "AC6: c_sigma in [0,1]";
  let bn = get_string "bottleneck_axis" json in
  check (bn = "alpha" || bn = "beta" || bn = "gamma")
    "AC6: bottleneck_axis ∈ {alpha,beta,gamma}"

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
    result_alpha_evidence = { evidence_positive = ["good α"]; evidence_negative = []; evidence_reason = "test" };
    result_beta_evidence  = { evidence_positive = ["good β"]; evidence_negative = []; evidence_reason = "test" };
    result_gamma_evidence = { evidence_positive = ["good γ"]; evidence_negative = []; evidence_reason = "test" };
    result_unresolved_ambiguity = [];
    result_next_fixes = [];
  } in
  let mech_result = Mechanical_scoring.score_files sample_files in
  let hybrid = Hybrid_scoring.combine ~target:"test" mech_result llm_result in
  let json = Hybrid_scoring.to_json hybrid in
  (* Required top-level fields *)
  check (has_field "mode"            json) "AC6: hybrid JSON has 'mode'";
  check (has_field "alpha"           json) "AC6: hybrid JSON has 'alpha'";
  check (has_field "beta"            json) "AC6: hybrid JSON has 'beta'";
  check (has_field "gamma"           json) "AC6: hybrid JSON has 'gamma'";
  check (has_field "c_sigma"         json) "AC6: hybrid JSON has 'c_sigma'";
  check (has_field "bottleneck_axis" json) "AC6: hybrid JSON has 'bottleneck_axis'";
  check (has_field "mechanical"      json) "AC6: hybrid JSON has 'mechanical' sub-object";
  check (has_field "llm"             json) "AC6: hybrid JSON has 'llm' sub-object";
  check (has_field "final"           json) "AC6: hybrid JSON has 'final' sub-object";
  let mode = get_string "mode" json in
  check (mode = "hybrid") "AC6: hybrid mode = 'hybrid'";
  (* final sub-object has source *)
  let final_obj = match json with
    | `Assoc fields ->
      (match List.assoc_opt "final" fields with
       | Some o -> o
       | None -> fail "missing 'final'")
    | _ -> fail "expected object"
  in
  check (has_field "source"  final_obj) "AC6: final has 'source'";
  check (has_field "alpha"   final_obj) "AC6: final has 'alpha'";
  check (has_field "beta"    final_obj) "AC6: final has 'beta'";
  check (has_field "gamma"   final_obj) "AC6: final has 'gamma'";
  check (has_field "c_sigma" final_obj) "AC6: final has 'c_sigma'";
  let src = get_string "source" final_obj in
  check (src = "llm" || src = "mechanical" || src = "agreement")
    "AC6: final.source ∈ {llm, mechanical, agreement}"

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
  check (has_field "alpha" mech_obj && has_field "c_sigma" mech_obj)
    "AC12: mechanical sub-object preserved with alpha and c_sigma";
  check (has_field "alpha" llm_obj  && has_field "c_sigma" llm_obj)
    "AC12: llm sub-object preserved with alpha and c_sigma";
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
  test_auto_mode_fallback ();
  Printf.printf "=== All tests passed ===\n%!"
