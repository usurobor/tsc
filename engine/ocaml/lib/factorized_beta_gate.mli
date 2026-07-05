(** Factorized-β measurement gate (Sub-2 of #73, issue #75).

    Evaluates the FROZEN pre-registered A/B/C gate of
    docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md (rev 4) over
    the per-target factorized-β measurements the CI witness produces. Pure
    module — no I/O, no LLM call, no network.

    The cross-sample β consistency reuses the canonical barrier
    ({!Coherence.coherence_link} / {!Coherence.phi}); it is NOT
    re-implemented here. The deterministic inventory / adjudication /
    aggregation / validation are {!Factorized_beta}'s; this module only
    consumes them and computes the gate arithmetic + the terminal
    PASS | FAIL | NO-DECISION verdict. It does NOT touch the α/γ scalar
    path. *)

(** {1 β cross-sample consistency (A1), routed through the barrier} *)

val beta_spread : float list -> float
(** Max absolute pairwise difference over the per-sample [β_factorized]
    values — the same max-pairwise spread {!Witness_numeric.per_field_spread}
    computes for a single field. *)

val beta_coh_consistency : float list -> float
(** [Coh_consistency_max_pairwise] over the β field: the canonical link
    [Coh = exp(-phi(spread))] via {!Coherence.coherence_link} (lambda=1).
    Fewer than two samples -> spread 0 -> 1.0. *)

(** {1 A3 locus-level agreement} *)

val locus_agreement :
  eligible_ids:string list ->
  samples:(string * Factorized_beta.verdict) list list ->
  float
(** Mean over all unordered sample pairs and eligible loci of
    verdict-equality (prereg §A3). Each sample is a validated
    [(locus_id, verdict)] assoc covering the eligible loci. 0 loci or
    fewer than two samples -> 1.0 (vacuous; such targets are excluded by
    the sparsity rule upstream). *)

(** {1 Per-target measurement record} *)

type target_measure = {
  tm_target            : string;
  tm_beta_loci         : int;        (* N(T) *)
  tm_eligible_loci     : int;        (* E(T), pre-witness *)
  tm_locus_sparse      : bool;       (* E(T) < 5 *)
  tm_declared_samples  : int;        (* k = 3 *)
  tm_validated_samples : int;
  tm_refused_samples   : int;
  tm_sample_betas      : float list; (* β_factorized per validated sample *)
  tm_beta_coh          : float;      (* A1 statistic *)
  tm_agreement         : float;      (* A3 statistic *)
  tm_baseline_beta_coh : float;      (* B_β free-witness β Coh (A2) *)
  tm_baseline_present  : bool;
}

val target_measure_to_json : target_measure -> Yojson.Safe.t
val target_measure_of_json : Yojson.Safe.t -> (target_measure, string) result

(** {1 Gate evaluation} *)

type verdict_token = Pass | Fail | No_decision

val string_of_verdict_token : verdict_token -> string
(** ["PASS"] | ["FAIL"] | ["NO-DECISION"]. *)

val default_a1_floor : float   (** 0.90 *)
val default_a2_margin : float  (** 0.10 *)
val default_a3_floor : float   (** 0.90 *)

type gate_input = {
  gi_targets          : target_measure list;
  gi_kata_b1          : bool;   (* kata-01 pass & kata-02 fail *)
  gi_admissibility_b2 : bool;   (* cm-admissibility --self-test matrix held *)
  gi_b3               : bool;   (* β controls: typed + label agreement *)
  gi_a1_floor         : float;
  gi_a2_margin        : float;
  gi_a3_floor         : float;
  gi_declared         : int;    (* expected sample count (3) *)
}

type check = { chk_id : string; chk_passed : bool; chk_detail : string }

type gate_result = {
  gr_verdict      : verdict_token;
  gr_checks       : check list;
  gr_sparse_count : int;
  gr_scored       : string list;   (* non-sparse held-out targets scored *)
}

val evaluate_gate : gate_input -> gate_result
(** A0 yield · A1 ≥ floor · A2 ≥ baseline+margin · A3 ≥ floor on every
    non-[locus_sparse] target, plus B1/B2/B3. C4: more than one
    [locus_sparse] held-out target -> NO-DECISION. C5: any A/B miss ->
    FAILED. Otherwise PASS. *)

val gate_result_to_json : gate_result -> Yojson.Safe.t

(** {1 B3 discrimination controls — witness label agreement} *)

type b3_result = {
  b3_passed        : bool;
  b3_total         : int;                        (* llm_called controls *)
  b3_agreements    : int;
  b3_mismatches    : (string * string * string) list;  (* id, expected, got *)
  b3_evidence_fail : string list;
  b3_typed_ok      : bool;
  b3_typed_errors  : string list;
}

val controls_prompt : Yojson.Safe.t -> (string, string) result
(** The adjudication prompt over the LLM-called controls, built as
    synthetic resolved loci ([source_text]/[target_text] inline). *)

val controls_check :
  fixtures_json:Yojson.Safe.t ->
  responses_json:Yojson.Safe.t ->
  (b3_result, string) result
(** B3 gate: the typed-fixture half (via {!Factorized_beta.validate_controls})
    plus label agreement (n<20 -> every hard control matches its
    [expected_verdict]; n>=20 -> >=95%) and the evidence rule (every
    negative verdict cites both source and target). *)

val b3_result_to_json : b3_result -> Yojson.Safe.t
