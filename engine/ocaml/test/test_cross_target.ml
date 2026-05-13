(** Tests for sub-issue #53 — cross-target report surface (Operational §7.4).

    Run via: opam exec -- dune runtest engine/ocaml/test/

    AC2 — Each constituent target uses the existing mechanical scoring
          path. The cross-target [target_row] derived from a result
          carries the per-target aggregate fields that match what
          [Coherence.aggregate] yields over that result's (α, β, γ).

    AC3 — Cross-target aggregate math:
            C_sigma_cross_num  = exp((1/n) * Σ ln(C_sigma_num_i))
            C_sigma_cross_math = 0 if any zero_component_present
                                 else geometric mean of C_sigma_math_i
          Reference fixture [0.8, 0.9, 0.7] -> ≈ 0.7958.

    AC4 — Emitted JSON shape:
            { kind = "cross_target_report",
              schema_version = "v3.2.0",
              mode = "mechanical",
              targets[],
              provenance.cross_target_aggregate{
                C_sigma_cross_num,
                C_sigma_cross_math,
                formula = "geometric_mean",
                constituent_targets
              } } *)

open Tsc_engine

(* ------------------------------------------------------------------ *)
(* Helpers (mirroring test_coherence.ml style) *)

let fail msg =
  Printf.eprintf "FAIL: %s\n%!" msg;
  exit 1

let pass label =
  Printf.printf "PASS: %s\n%!" label

let check cond label =
  if not cond then fail label else pass label

let near_tol t expected actual label =
  check (abs_float (actual -. expected) < t)
    (Printf.sprintf "%s (|%.6f - %.6f| < %.0e)" label actual expected t)

(* ------------------------------------------------------------------ *)
(* Synthesize a Mechanical_scoring.result with specific (α, β, γ) so we
   can exercise Cross_target without running the full scoring pipeline. *)

let mk_axis_result axis score : Mechanical_scoring.axis_result =
  { axis;
    score;
    evidence_kind         = `Structural_proxy;
    signals               = [];
    summary               = "synthetic test fixture";
    unresolved_ambiguity  = [] }

let mk_result ~target ~alpha ~beta ~gamma : Mechanical_scoring.result =
  { mode            = `Mechanical;
    target          = Some target;
    alpha           = mk_axis_result `Alpha alpha;
    beta            = mk_axis_result `Beta  beta;
    gamma           = mk_axis_result `Gamma gamma;
    c_sigma         = (alpha +. beta +. gamma) /. 3.0;
    bottleneck_axis = `Alpha;
    confidence      = 1.0;
    diagnostics     = [] }

(* ------------------------------------------------------------------ *)
(* AC2: per-target row derivation matches Coherence.aggregate inline *)

let test_ac2_row_matches_coherence_aggregate () =
  let r = mk_result ~target:"spec" ~alpha:0.8 ~beta:0.7 ~gamma:0.6 in
  let row = Cross_target.row_of_mechanical ~target_id:"spec" r in
  let agg =
    Coherence.aggregate ~epsilon:1e-5
      ~s_alpha:0.8 ~s_beta:0.7 ~s_gamma:0.6 ()
  in
  check (row.tr_id = "spec") "AC2: row carries operator-requested id";
  near_tol 1e-12 agg.c_sigma_num  row.tr_c_sigma_num
    "AC2: row.tr_c_sigma_num = Coherence.aggregate c_sigma_num";
  near_tol 1e-12 agg.c_sigma_math row.tr_c_sigma_math
    "AC2: row.tr_c_sigma_math = Coherence.aggregate c_sigma_math";
  check (row.tr_zero_component_present = agg.zero_component_present)
    "AC2: row.tr_zero_component_present = aggregate flag";
  check (row.tr_numeric_floor_applied = agg.numeric_floor_applied)
    "AC2: row.tr_numeric_floor_applied = aggregate flag";
  (* Degenerate case — zero component propagates *)
  let r0 = mk_result ~target:"engine" ~alpha:0.0 ~beta:0.5 ~gamma:0.5 in
  let row0 = Cross_target.row_of_mechanical ~target_id:"engine" r0 in
  check row0.tr_zero_component_present
    "AC2: zero α propagates zero_component_present to row";
  check (row0.tr_c_sigma_math = 0.0)
    "AC2: zero α propagates c_sigma_math = 0 to row";
  check (row0.tr_c_sigma_num > 0.0)
    "AC2: numeric floor keeps c_sigma_num > 0 in degenerate row";
  check row0.tr_numeric_floor_applied
    "AC2: numeric_floor_applied = true in degenerate row"

(* ------------------------------------------------------------------ *)
(* AC3: geometric mean over per-target rows                           *)
(*                                                                    *)
(* Reference fixture from sub-issue #53 AC3 oracle:                   *)
(*   inputs   = [0.8, 0.9, 0.7]                                       *)
(*   expected = (0.8 * 0.9 * 0.7)^(1/3) ≈ 0.7958114...                *)

let mk_row_direct ~id ~num ~math ~zero ~floor : Cross_target.target_row =
  { tr_id                     = id;
    tr_c_sigma_num            = num;
    tr_c_sigma_math           = math;
    tr_zero_component_present = zero;
    tr_numeric_floor_applied  = floor }

let test_ac3_geometric_mean_reference () =
  let rows = [
    mk_row_direct ~id:"spec"   ~num:0.8 ~math:0.8 ~zero:false ~floor:false;
    mk_row_direct ~id:"engine" ~num:0.9 ~math:0.9 ~zero:false ~floor:false;
    mk_row_direct ~id:"repo"   ~num:0.7 ~math:0.7 ~zero:false ~floor:false;
  ] in
  let agg = Cross_target.aggregate_of_rows rows in
  let expected = (0.8 *. 0.9 *. 0.7) ** (1.0 /. 3.0) in
  near_tol 1e-4 0.7958 agg.c_sigma_cross_num
    "AC3: C_sigma_cross_num ≈ 0.7958 for [0.8, 0.9, 0.7] (issue oracle, tol 1e-4)";
  near_tol 1e-12 expected agg.c_sigma_cross_num
    "AC3: C_sigma_cross_num = analytical geometric mean";
  near_tol 1e-12 expected agg.c_sigma_cross_math
    "AC3: C_sigma_cross_math = analytical geometric mean (non-degenerate)";
  (* Negative: arithmetic mean fails the same fixture *)
  let arith = (0.8 +. 0.9 +. 0.7) /. 3.0 in
  check (abs_float (arith -. 0.7958) > 1e-3)
    "AC3: arithmetic mean (~0.800) differs from geometric mean (~0.7958)";
  check (agg.constituent_targets = ["spec"; "engine"; "repo"])
    "AC3: constituent_targets preserves operator-requested order"

let test_ac3_degenerate_math_propagation () =
  let rows = [
    mk_row_direct ~id:"spec"   ~num:0.5      ~math:0.5 ~zero:false ~floor:false;
    mk_row_direct ~id:"engine" ~num:1e-5     ~math:0.0 ~zero:true  ~floor:true;
    mk_row_direct ~id:"repo"   ~num:0.7      ~math:0.7 ~zero:false ~floor:false;
  ] in
  let agg = Cross_target.aggregate_of_rows rows in
  check (agg.c_sigma_cross_math = 0.0)
    "AC3: any zero_component_present forces C_sigma_cross_math = 0";
  check (agg.c_sigma_cross_num > 0.0)
    "AC3: C_sigma_cross_num > 0 even when one target is math-degenerate"

(* ------------------------------------------------------------------ *)
(* AC4: emitted JSON shape contract                                   *)

let assert_field key json =
  match json with
  | `Assoc fields ->
    if not (List.mem_assoc key fields) then
      fail (Printf.sprintf "AC4: missing required field '%s'" key)
    else pass (Printf.sprintf "AC4: field '%s' present" key)
  | _ -> fail "AC4: expected JSON object"

let get_field key = function
  | `Assoc fields ->
    (match List.assoc_opt key fields with
     | Some v -> v
     | None -> fail (Printf.sprintf "AC4: missing field '%s'" key))
  | _ -> fail "AC4: expected JSON object"

let get_string_field key j =
  match get_field key j with
  | `String s -> s
  | _ -> fail (Printf.sprintf "AC4: field '%s' is not a string" key)

let test_ac4_report_shape () =
  let results = [
    ("spec",   mk_result ~target:"spec"   ~alpha:0.8 ~beta:0.7 ~gamma:0.6);
    ("engine", mk_result ~target:"engine" ~alpha:0.9 ~beta:0.8 ~gamma:0.7);
    ("repo",   mk_result ~target:"repo"   ~alpha:0.7 ~beta:0.6 ~gamma:0.5);
  ] in
  let report = Cross_target.report_from_results results in
  (* Top-level required fields *)
  List.iter (fun k -> assert_field k report)
    ["kind"; "schema_version"; "mode"; "targets"; "provenance"];
  check (get_string_field "kind" report = "cross_target_report")
    "AC4: kind = 'cross_target_report'";
  check (get_string_field "schema_version" report = "v3.2.0")
    "AC4: schema_version = 'v3.2.0'";
  check (get_string_field "mode" report = "mechanical")
    "AC4: mode = 'mechanical'";
  (* targets[] structure *)
  (match get_field "targets" report with
   | `List items ->
     check (List.length items = 3)
       "AC4: targets[] has one entry per constituent";
     List.iter (fun item ->
       List.iter (fun k -> assert_field k item)
         ["id"; "C_sigma_num"; "C_sigma_math";
          "zero_component_present"; "numeric_floor_applied"]
     ) items
   | _ -> fail "AC4: targets is not a list");
  (* provenance.cross_target_aggregate structure *)
  let prov = get_field "provenance" report in
  assert_field "cross_target_aggregate" prov;
  let cta = get_field "cross_target_aggregate" prov in
  List.iter (fun k -> assert_field k cta)
    ["C_sigma_cross_num"; "C_sigma_cross_math";
     "formula"; "constituent_targets"];
  check (get_string_field "formula" cta = "geometric_mean")
    "AC4: provenance.cross_target_aggregate.formula = 'geometric_mean'";
  (match get_field "constituent_targets" cta with
   | `List ids ->
     let names = List.map (function
         | `String s -> s
         | _ -> fail "AC4: constituent_targets entry not a string"
       ) ids
     in
     check (names = ["spec"; "engine"; "repo"])
       "AC4: constituent_targets = ['spec';'engine';'repo'] in requested order"
   | _ -> fail "AC4: constituent_targets not a list")

(* AC4 negative: missing fields fail the schema test (built-in: helpers
   call [fail] which exits non-zero, so any drop would be caught). We
   additionally check that a flat top-level "c_sigma" field is NOT
   present — the report must use the nested provenance shape. *)

let test_ac4_no_flat_c_sigma () =
  let results = [
    ("spec",   mk_result ~target:"spec"   ~alpha:0.8 ~beta:0.7 ~gamma:0.6);
    ("engine", mk_result ~target:"engine" ~alpha:0.9 ~beta:0.8 ~gamma:0.7);
  ] in
  let report = Cross_target.report_from_results results in
  match report with
  | `Assoc fields ->
    check (not (List.mem_assoc "c_sigma" fields))
      "AC4: report has no flat top-level 'c_sigma' (must go via provenance)";
    check (not (List.mem_assoc "C_sigma" fields))
      "AC4: report has no flat top-level 'C_sigma' either"
  | _ -> fail "AC4: report is not a JSON object"

(* ------------------------------------------------------------------ *)
(* Runner *)

let () =
  Printf.printf "=== TSC cross-target tests (AC2, AC3, AC4) ===\n%!";
  test_ac2_row_matches_coherence_aggregate ();
  test_ac3_geometric_mean_reference ();
  test_ac3_degenerate_math_propagation ();
  test_ac4_report_shape ();
  test_ac4_no_flat_c_sigma ();
  Printf.printf "=== All cross-target tests passed ===\n%!"
