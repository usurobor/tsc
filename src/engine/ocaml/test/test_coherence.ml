(** Tests for AC1–AC4 (coherence math) and AC7 (OOD cutover guard).

    Run via: opam exec -- dune runtest src/engine/ocaml/test/

    AC1 — Barrier transform: coh(0,1)=1, coh(1,1)=0, coh(0.5,1)=exp(-1), monotone.
    AC2 — L_link case-split: both branches, continuity at lambda=2.
    AC3 — Math/num aggregate split: coincide above epsilon; degenerate case.
    AC4 — W2 gauge witness: spread>0 for asymmetric c_sigma; ~0 for symmetric.
    AC7 — OOD cutover guard: v3.1-shaped window triggers diagnostic. *)

open Tsc_engine

(* ------------------------------------------------------------------ *)
(* Helpers *)

let fail msg =
  Printf.eprintf "FAIL: %s\n%!" msg;
  exit 1

let pass label =
  Printf.printf "PASS: %s\n%!" label

let check cond label =
  if not cond then fail label else pass label

let tol = 1e-10

let near expected actual label =
  check (abs_float (actual -. expected) < tol) label

let near_tol t expected actual label =
  check (abs_float (actual -. expected) < t) label

(* ------------------------------------------------------------------ *)
(* AC1: Barrier transform *)

let test_coherence_link () =
  (* coh(delta=0, lambda=1) = exp(-0) = 1.0 *)
  near 1.0 (Coherence.coherence_link ~lambda:1.0 ~delta:0.0)
    "AC1: coh(delta=0, lambda=1.0) = 1.0";
  (* coh(delta=1, lambda=1) = 0.0  (strict endpoint policy) *)
  near 0.0 (Coherence.coherence_link ~lambda:1.0 ~delta:1.0)
    "AC1: coh(delta=1, lambda=1.0) = 0.0 (strict endpoint)";
  (* coh(delta=0.5, lambda=1) = exp(-phi(0.5)) = exp(-1.0) *)
  let expected_half = exp (-. 1.0) in
  near expected_half (Coherence.coherence_link ~lambda:1.0 ~delta:0.5)
    "AC1: coh(delta=0.5, lambda=1.0) = exp(-1.0)";
  (* Monotone decreasing: coh at lower delta >= coh at higher delta *)
  let samples = [0.0; 0.1; 0.2; 0.3; 0.4; 0.5; 0.6; 0.7; 0.8; 0.9; 1.0] in
  let values = List.map (fun d -> Coherence.coherence_link ~lambda:1.0 ~delta:d) samples in
  let rec monotone_check = function
    | a :: b :: rest ->
      check (a >= b) (Printf.sprintf "AC1: monotone — coh[i]=%g >= coh[i+1]=%g" a b);
      monotone_check (b :: rest)
    | _ -> ()
  in
  monotone_check values;
  (* Also verify with lambda=2 *)
  near 1.0 (Coherence.coherence_link ~lambda:2.0 ~delta:0.0)
    "AC1: coh(delta=0, lambda=2.0) = 1.0";
  near 0.0 (Coherence.coherence_link ~lambda:2.0 ~delta:1.0)
    "AC1: coh(delta=1, lambda=2.0) = 0.0"

(* ------------------------------------------------------------------ *)
(* AC2: L_link case-split *)

let test_l_link () =
  (* Branch 1: lambda <= 2 -> (4/lambda) * exp(lambda - 2) *)
  let expected_1 = (4.0 /. 1.0) *. exp (1.0 -. 2.0) in
  near expected_1 (Lipschitz.l_link 1.0)
    "AC2: L_link(1.0) = (4/1)*exp(-1)";
  let expected_15 = (4.0 /. 1.5) *. exp (1.5 -. 2.0) in
  near expected_15 (Lipschitz.l_link 1.5)
    "AC2: L_link(1.5) = (4/1.5)*exp(-0.5)";
  (* Branch 2: lambda >= 2 -> lambda *)
  near 3.0 (Lipschitz.l_link 3.0)
    "AC2: L_link(3.0) = 3.0";
  near 10.0 (Lipschitz.l_link 10.0)
    "AC2: L_link(10.0) = 10.0";
  (* Continuity at lambda = 2: both branches must give 2.0 *)
  let branch1_at2 = (4.0 /. 2.0) *. exp (2.0 -. 2.0) in  (* = 2*1 = 2.0 *)
  let branch2_at2 = 2.0 in
  near branch1_at2 (Lipschitz.l_link 2.0)
    "AC2: L_link(2.0) via branch-1 formula = 2.0";
  near branch2_at2 (Lipschitz.l_link 2.0)
    "AC2: L_link(2.0) via branch-2 formula = 2.0";
  (* Near lambda=2: tolerance proportional to distance from boundary *)
  near_tol 5e-4 2.0 (Lipschitz.l_link 1.9999)
    "AC2: L_link(1.9999) ~= 2.0 (near continuity, tol 5e-4)";
  near_tol 5e-4 2.0 (Lipschitz.l_link 2.0001)
    "AC2: L_link(2.0001) ~= 2.0 (near continuity, tol 5e-4)"

(* ------------------------------------------------------------------ *)
(* AC3: Math/num aggregate split *)

let test_aggregate () =
  let eps = 1e-5 in
  (* All components above epsilon: math == num within tolerance *)
  let r = Coherence.aggregate ~epsilon:eps ~s_alpha:0.8 ~s_beta:0.7 ~s_gamma:0.6 () in
  check (not r.zero_component_present)
    "AC3: no zero component for all-positive scores";
  check (not r.numeric_floor_applied)
    "AC3: no floor applied when all si >= epsilon";
  let expected_math = (0.8 *. 0.7 *. 0.6) ** (1.0 /. 3.0) in
  near_tol 1e-10 expected_math r.c_sigma_math
    "AC3: c_sigma_math = geometric mean";
  near_tol 1e-10 r.c_sigma_math r.c_sigma_num
    "AC3: math == num when all si >= epsilon";
  (* Random in [0.1, 1.0]: math == num *)
  let r2 = Coherence.aggregate ~epsilon:eps ~s_alpha:0.45 ~s_beta:0.93 ~s_gamma:0.71 () in
  near_tol 1e-10 r2.c_sigma_math r2.c_sigma_num
    "AC3: math == num for second random triple";
  (* Degenerate: s_alpha = 0 -> math = 0, num > 0, zero_component_present = true *)
  let rd = Coherence.aggregate ~epsilon:eps ~s_alpha:0.0 ~s_beta:0.5 ~s_gamma:0.5 () in
  check rd.zero_component_present
    "AC3: zero_component_present = true when s_alpha = 0";
  near 0.0 rd.c_sigma_math
    "AC3: c_sigma_math = 0 when s_alpha = 0 (strict degeneracy)";
  check (rd.c_sigma_num > 0.0)
    "AC3: c_sigma_num > 0 even when s_alpha = 0 (epsilon floor)";
  check rd.numeric_floor_applied
    "AC3: numeric_floor_applied = true when s_alpha < epsilon"

(* ------------------------------------------------------------------ *)
(* AC4: W2 gauge witness *)

(** Asymmetric c_sigma: uses weighted form w_alpha=2, w_beta=1, w_gamma=1.
    This is NOT S3-symmetric, so permuting labels changes the result. *)
let asymmetric_c_sigma sa sb sg =
  let w_a = 2.0 and w_b = 1.0 and w_g = 1.0 in
  let eps = 1e-5 in
  let fa = Float.max sa eps
  and fb = Float.max sb eps
  and fg = Float.max sg eps in
  exp ((w_a *. log fa +. w_b *. log fb +. w_g *. log fg) /. (w_a +. w_b +. w_g))

(** Symmetric c_sigma: standard geometric mean (S3-invariant). *)
let symmetric_c_sigma sa sb sg =
  let eps = 1e-5 in
  let r = Coherence.aggregate ~epsilon:eps ~s_alpha:sa ~s_beta:sb ~s_gamma:sg () in
  r.c_sigma_math

let test_gauge_witness () =
  (* Asymmetric: scores differ, w_alpha > w_beta = w_gamma -> spread > 0 *)
  let labeled_asym = (0.9, 0.5, 0.3) in
  let gw_asym = Coherence.gauge_witness
    ~labeled:labeled_asym
    ~c_sigma_fn:asymmetric_c_sigma
    ~tau_gauge_spread:0.05
  in
  check (gw_asym.w_gauge_spread > 0.0)
    "AC4: spread > 0 for asymmetric c_sigma with unequal scores";
  (* Also verify ref is non-negative *)
  check (gw_asym.w_gauge_ref >= 0.0)
    "AC4: w_gauge_ref >= 0 for asymmetric case";
  (* Symmetric: standard geometric mean is S3-invariant -> spread ~= 0 *)
  let labeled_sym = (0.8, 0.6, 0.7) in
  let gw_sym = Coherence.gauge_witness
    ~labeled:labeled_sym
    ~c_sigma_fn:symmetric_c_sigma
    ~tau_gauge_spread:0.05
  in
  near_tol 1e-10 0.0 gw_sym.w_gauge_spread
    "AC4: spread ~= 0 for symmetric (geometric mean) c_sigma";
  (* Symmetric case: canonical remap also gives same result -> ref ~= 0 *)
  near_tol 1e-10 0.0 gw_sym.w_gauge_ref
    "AC4: w_gauge_ref ~= 0 for symmetric c_sigma (canonical remap same)";
  (* Verify canonical_remap_procedure is non-empty *)
  check (String.length gw_asym.canonical_remap_procedure > 0)
    "AC4: canonical_remap_procedure is non-empty"

(* ------------------------------------------------------------------ *)
(* AC7: OOD cutover guard *)

let test_ood_guard () =
  (* v3.1.0 reference window -> error with reset diagnostic *)
  let v31_window = `Assoc [
    ("schema_version", `String "v3.1.0");
    ("c_sigma_values", `List [`Float 0.82; `Float 0.79]);
  ] in
  (match Ood.check_schema_version v31_window with
   | Error msg ->
     check (String.length msg > 0)
       "AC7: v3.1.0 window -> non-empty error message";
     check (let lower = String.lowercase_ascii msg in
            String.length lower > 0 &&
            (let find sub s =
               let nl = String.length sub and hl = String.length s in
               let found = ref false in
               for i = 0 to hl - nl do
                 if String.sub s i nl = sub then found := true
               done;
               !found
             in find "reset" lower || find "cutover" lower || find "3.2" lower))
       "AC7: error message references reset/cutover/3.2"
   | Ok () ->
     fail "AC7: expected Error for v3.1.0 reference window, got Ok");
  (* v3.2.0 reference window with canonical aggregate semantics -> Ok.
     Per #52, the reference window must declare aggregate_semantics =
     "canonical-v3.2-geometric-num" in addition to a v3.2.0 schema. *)
  let v32_window = `Assoc [
    ("schema_version", `String "v3.2.0");
    ("aggregate_semantics", `String "canonical-v3.2-geometric-num");
    ("c_sigma_values", `List [`Float 0.82]);
  ] in
  (match Ood.check_schema_version v32_window with
   | Ok () -> pass "AC7: v3.2.0 window + canonical sentinel -> Ok (compatible)"
   | Error msg -> fail (Printf.sprintf "AC7: v3.2.0 window unexpectedly failed: %s" msg));
  (* v4.0.0 reference window with canonical aggregate semantics
     -> Ok (newer than cutover, sentinel present). *)
  let v40_window = `Assoc [
    ("schema_version", `String "v4.0.0");
    ("aggregate_semantics", `String "canonical-v3.2-geometric-num");
  ] in
  (match Ood.check_schema_version v40_window with
   | Ok () -> pass "AC7: v4.0.0 window + canonical sentinel -> Ok (newer than cutover)"
   | Error msg -> fail (Printf.sprintf "AC7: v4.0.0 window unexpectedly failed: %s" msg));
  (* Missing schema_version field -> Error *)
  let no_version = `Assoc [("data", `String "foo")] in
  (match Ood.check_schema_version no_version with
   | Error _ -> pass "AC7: missing schema_version -> Error"
   | Ok () -> fail "AC7: expected Error for missing schema_version");
  (* v3.0.0 also predates cutover -> Error *)
  let v30_window = `Assoc [("schema_version", `String "v3.0.0")] in
  (match Ood.check_schema_version v30_window with
   | Error _ -> pass "AC7: v3.0.0 window -> Error (predates cutover)"
   | Ok () -> fail "AC7: expected Error for v3.0.0 reference window")

(* ------------------------------------------------------------------ *)
(* AC5: Provenance JSON v3.2.0 shape *)

let has_field key = function
  | `Assoc fields -> List.mem_assoc key fields
  | _ -> false

let get_subobj key = function
  | `Assoc fields ->
    (match List.assoc_opt key fields with
     | Some (`Assoc _ as o) -> o
     | _ -> fail (Printf.sprintf "AC5: missing or non-object field '%s'" key))
  | _ -> fail "AC5: expected JSON object"

let test_provenance_shape () =
  (* Build a provenance JSON via coherence.provenance_json (the canonical builder) *)
  let prov = Coherence.provenance_json
    ~l_link_alpha_beta:(Some 1.47)
    ~l_link_beta_gamma:(Some 2.0)
    ~l_link_gamma_alpha:(Some 3.5)
    ~c_sigma_math:(Some 0.72)
    ~zero_component_present:false
    ~c_sigma_num:(Some 0.73)
    ~epsilon:(Some 1e-5)
    ~numeric_floor_applied:false
    ~w_gauge_ref:(Some 0.01)
    ~w_gauge_spread:(Some 0.02)
    ~tau_gauge_spread:(Some 0.05)
    ~canonical_remap_procedure:(Some "lexicographic ascending by score value")
    ()
  in
  (* Required top-level keys per spec/tsc-oper.md §6 + provenance_v3_2_0.schema.json *)
  let required_keys = [
    "discrepancy_symbol"; "discrepancy_range"; "coherence_link";
    "barrier_phi"; "barrier_clip_eta_phi"; "endpoint_policy";
    "energy_variable"; "link_lipschitz_constants";
    "aggregate_math"; "aggregate_numeric"; "gauge_witness";
  ] in
  List.iter (fun k ->
    check (has_field k prov)
      (Printf.sprintf "AC5: provenance has required key '%s'" k)
  ) required_keys;
  (* link_lipschitz_constants sub-keys *)
  let llc = get_subobj "link_lipschitz_constants" prov in
  List.iter (fun k ->
    check (has_field k llc)
      (Printf.sprintf "AC5: link_lipschitz_constants has '%s'" k)
  ) ["alpha_beta"; "beta_gamma"; "gamma_alpha"];
  (* aggregate_math sub-keys *)
  let am = get_subobj "aggregate_math" prov in
  check (has_field "C_sigma_math" am) "AC5: aggregate_math has 'C_sigma_math'";
  check (has_field "zero_component_present" am) "AC5: aggregate_math has 'zero_component_present'";
  (* aggregate_numeric sub-keys *)
  let an = get_subobj "aggregate_numeric" prov in
  check (has_field "C_sigma_num" an) "AC5: aggregate_numeric has 'C_sigma_num'";
  check (has_field "epsilon" an) "AC5: aggregate_numeric has 'epsilon'";
  check (has_field "numeric_floor_applied" an) "AC5: aggregate_numeric has 'numeric_floor_applied'";
  (* gauge_witness sub-keys *)
  let gw = get_subobj "gauge_witness" prov in
  List.iter (fun k ->
    check (has_field k gw)
      (Printf.sprintf "AC5: gauge_witness has '%s'" k)
  ) ["w_gauge_ref"; "w_gauge_spread"; "tau_gauge_spread"; "canonical_remap_procedure"];
  (* Verify canonical string values *)
  (match prov with
   | `Assoc fields ->
     (match List.assoc_opt "discrepancy_symbol" fields with
      | Some (`String s) -> check (s = "delta") "AC5: discrepancy_symbol = 'delta'"
      | _ -> fail "AC5: discrepancy_symbol not a string");
     (match List.assoc_opt "barrier_phi" fields with
      | Some (`String s) ->
        check (s = "delta/(1-delta)") "AC5: barrier_phi = 'delta/(1-delta)'"
      | _ -> fail "AC5: barrier_phi not a string");
     (match List.assoc_opt "coherence_link" fields with
      | Some (`String s) ->
        check (s = "barrier_exponential") "AC5: coherence_link = 'barrier_exponential'"
      | _ -> fail "AC5: coherence_link not a string")
   | _ -> fail "AC5: provenance not an object")

(* ------------------------------------------------------------------ *)
(* Runner *)

let () =
  Printf.printf "=== TSC coherence + OOD tests (AC1-AC4, AC5, AC7) ===\n%!";
  test_coherence_link ();
  test_l_link ();
  test_aggregate ();
  test_gauge_witness ();
  test_provenance_shape ();
  test_ood_guard ();
  Printf.printf "=== All coherence tests passed ===\n%!"
