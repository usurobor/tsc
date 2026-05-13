(** Cross-target aggregate report (Operational §7.4).

    Reporting-only surface introduced by sub-issue #53. Given two or more
    per-target mechanical results, produce a single cross-target report
    whose top-level aggregate is the geometric mean of per-target
    coherence aggregates:

      C_sigma_cross_num  = exp((1/n) * sum_i ln(C_sigma_num_i))
      C_sigma_cross_math = 0 if any target has zero_component_present=true
                           otherwise (prod_i C_sigma_math_i)^(1/n)

    No new threshold or verdict is introduced. The cross-target surface is
    mechanical-only for this cycle; the engine CLI rejects LLM/hybrid/auto
    multi-target requests with an explicit message.

    Strategy: this module does NOT depend on the shape of
    [Mechanical_scoring.result] gaining new aggregate fields (that is the
    job of sub-issue #50). Instead, given a [Mechanical_scoring.result]
    we derive [C_sigma_num] / [C_sigma_math] / degeneracy flags inline by
    calling [Coherence.aggregate] over the (alpha, beta, gamma) axes of
    each per-target result. When #50 lands, this module's per-target
    derivation will route through the canonical result fields; the
    cross-target math and emitted JSON shape do not change. *)

(* ------------------------------------------------------------------ *)
(* Per-target inline derivation (Option (b) — see self-coherence) *)

(** Per-target row in the cross-target report. Carries the four canonical
    fields demanded by AC4 plus the target id. *)
type target_row = {
  tr_id                     : string;
  tr_c_sigma_num            : float;
  tr_c_sigma_math           : float;
  tr_zero_component_present : bool;
  tr_numeric_floor_applied  : bool;
}

(** Canonical epsilon for the numeric aggregate floor. Matches
    [Coherence.aggregate]'s default and the v3.2.0 provenance contract. *)
let default_epsilon = 1e-5

(** Derive a [target_row] from a mechanical scoring result.

    [target_id] is the registry name the operator asked for (e.g. "spec",
    "engine", "repo"). It is used unchanged in the row so that the report
    constituency reflects the operator request even if the underlying
    result carries a different internal target name. *)
let row_of_mechanical ?(epsilon = default_epsilon) ~target_id
    (r : Mechanical_scoring.result) : target_row =
  let agg =
    Coherence.aggregate
      ~epsilon
      ~s_alpha:r.alpha.score
      ~s_beta:r.beta.score
      ~s_gamma:r.gamma.score
      ()
  in
  { tr_id                     = target_id;
    tr_c_sigma_num            = agg.c_sigma_num;
    tr_c_sigma_math           = agg.c_sigma_math;
    tr_zero_component_present = agg.zero_component_present;
    tr_numeric_floor_applied  = agg.numeric_floor_applied }

(* ------------------------------------------------------------------ *)
(* Cross-target geometric mean (Operational §7.4 / AC3) *)

(** Cross-target aggregate result. *)
type aggregate = {
  c_sigma_cross_num   : float;
  c_sigma_cross_math  : float;
  constituent_targets : string list;
}

(** Geometric mean of per-target numerical aggregates.

      C_sigma_cross_num = exp((1/n) * sum_i ln(C_sigma_num_i))

    Inputs are expected to be in (0, 1] after the epsilon floor applied
    inside [Coherence.aggregate]; this function does not re-floor. An
    empty list yields 0.0 (caller is responsible for rejecting empty
    constituency upstream — see AC2 negative case). *)
let geometric_mean_num (rows : target_row list) : float =
  match rows with
  | [] -> 0.0
  | _  ->
    let n = float_of_int (List.length rows) in
    let sum_ln =
      List.fold_left (fun acc r -> acc +. log r.tr_c_sigma_num) 0.0 rows
    in
    exp (sum_ln /. n)

(** Geometric mean of per-target mathematical aggregates with strict
    zero-degeneracy propagation:

      C_sigma_cross_math = 0 if any row has zero_component_present
                           otherwise (prod_i C_sigma_math_i)^(1/n)

    This matches Operational §7.4 / Core §5.4: a single math-degenerate
    target makes the cross-target math aggregate strictly zero, the
    numerical aggregate is still computed and reported separately. *)
let geometric_mean_math (rows : target_row list) : float =
  if List.exists (fun r -> r.tr_zero_component_present) rows then 0.0
  else
    match rows with
    | [] -> 0.0
    | _  ->
      let n = float_of_int (List.length rows) in
      let sum_ln =
        List.fold_left (fun acc r -> acc +. log r.tr_c_sigma_math) 0.0 rows
      in
      exp (sum_ln /. n)

(** Compute the cross-target aggregate from per-target rows. *)
let aggregate_of_rows (rows : target_row list) : aggregate =
  { c_sigma_cross_num   = geometric_mean_num rows;
    c_sigma_cross_math  = geometric_mean_math rows;
    constituent_targets = List.map (fun r -> r.tr_id) rows }

(* ------------------------------------------------------------------ *)
(* JSON emission (AC4) *)

(** Schema version for the cross-target report. Tied to the v3.2.0 series
    so the Operational §7.4 contract is reproducible. *)
let schema_version = "v3.2.0"

(** Emit a per-target row as Yojson. Carries exactly the four canonical
    fields required by AC4 + the id. *)
let row_to_json (r : target_row) : Yojson.Safe.t =
  `Assoc [
    ("id",                     `String r.tr_id);
    ("C_sigma_num",            `Float  r.tr_c_sigma_num);
    ("C_sigma_math",           `Float  r.tr_c_sigma_math);
    ("zero_component_present", `Bool   r.tr_zero_component_present);
    ("numeric_floor_applied",  `Bool   r.tr_numeric_floor_applied);
  ]

(** Build the cross-target aggregate provenance sub-object. *)
let aggregate_to_json (a : aggregate) : Yojson.Safe.t =
  `Assoc [
    ("C_sigma_cross_num",   `Float  a.c_sigma_cross_num);
    ("C_sigma_cross_math",  `Float  a.c_sigma_cross_math);
    ("constituent_targets", `List   (List.map (fun s -> `String s)
                                       a.constituent_targets));
  ]

(** Build the full cross-target report JSON.

    Shape contract (AC4):
      {
        "kind": "cross_target_report",
        "schema_version": "v3.2.0",
        "mode": "mechanical",
        "targets": [ row, ... ],
        "provenance": {
          "cross_target_aggregate": { ... }
        }
      }
*)
let report_to_json ~rows ~aggregate : Yojson.Safe.t =
  `Assoc [
    ("kind",           `String "cross_target_report");
    ("schema_version", `String schema_version);
    ("mode",           `String "mechanical");
    ("targets",        `List (List.map row_to_json rows));
    ("provenance",     `Assoc [
       ("cross_target_aggregate", aggregate_to_json aggregate);
     ]);
  ]

(** Convenience: produce the full report JSON string from a list of
    (target_id, mechanical result) pairs. Caller is responsible for
    rejecting empty / duplicate constituency before reaching this point
    (AC2 negative case). *)
let report_from_results ?(epsilon = default_epsilon)
    (results : (string * Mechanical_scoring.result) list) : Yojson.Safe.t =
  let rows =
    List.map (fun (id, r) -> row_of_mechanical ~epsilon ~target_id:id r) results
  in
  let agg = aggregate_of_rows rows in
  report_to_json ~rows ~aggregate:agg
