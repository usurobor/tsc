(** Factorized β: deterministic locus enumeration + mechanical aggregation.

    Implements docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md
    (rev 4). Pure module — no I/O, no LLM call, no network. Identical
    bundle -> identical inventory and identical locus ids.

    The engine enumerates the β loci (kills selection freedom); the LLM
    adjudicates each RESOLVED locus with a bounded verdict (it never emits
    a scalar); the engine aggregates the verdicts into [β_factorized] by
    the pre-registered formula (kills counting/aggregation freedom). The
    α/γ scalar path is untouched; the cross-sample consistency barrier
    stays {!Coherence.phi} via the existing [Consistency] report. *)

(** The three allowed β locus kinds. No [repeated_fact], no γ/version kind. *)
type kind =
  | Citation_bears_claim
  | Authority_claim
  | Target_file_fit

(** Two-valued: a link resolving to a non-document is not enumerated. *)
type mechanical_status =
  | Resolved
  | Unresolved

(** The bounded LLM verdict for a resolved locus. *)
type verdict =
  | Supports
  | Contradicts
  | Insufficient

(** One enumerated β locus. *)
type locus = {
  locus_id          : string;
  kind              : kind;
  source_path       : string;
  source_span       : string;
  target_path       : string;
  target_span       : string;
  question          : string;
  mechanical_status : mechanical_status;
}

(** {1 Conversions and weights} *)

val string_of_kind : kind -> string
val kind_of_string : string -> kind option
val string_of_status : mechanical_status -> string
val string_of_verdict : verdict -> string
val verdict_of_string : string -> verdict option

val kind_weight : kind -> float
(** Per-kind weight [w]: citation=1.0, authority=1.0, target_file_fit=0.5. *)

val defect_weight_of_verdict : verdict -> float
(** Per-locus defect weight [d]: supports=0.0, insufficient=0.5,
    contradicts=1.0. (Unresolved loci carry d=1.0 without a verdict.) *)

val question_for : kind -> string
(** The bounded adjudication question per kind. *)

(** {1 Deterministic pre-witness inventory} *)

val inventory : Bundle.file list -> locus list
(** The deterministic β locus inventory in canonical order (bundle file
    order -> source line -> kind order -> column). [locus_id] is assigned
    by that order, so the set is reproducible. Built BEFORE any LLM call. *)

(** {1 Aggregation: β_factorized} *)

type beta_aggregate = {
  beta_factorized     : float;
  n_loci              : int;   (* N(T): all enumerated loci *)
  eligible_loci       : int;   (* E(T): LLM-eligible (resolved) loci *)
  locus_sparse        : bool;  (* E(T) < 5 *)
  sum_weight          : float;
  sum_weighted_defect : float;
}

val compute_beta : locus list -> verdict_of:(locus -> verdict) -> beta_aggregate
(** [β_factorized = 1 - Σ(w·d)/Σ(w)] clamped to [0,1], over ALL loci
    (unresolved included as real β defects, d=1.0). [verdict_of] supplies
    each resolved locus's verdict and is never consulted for an unresolved
    locus. N(T)=0 -> β=1.0. Sparsity is on the eligible (resolved) count. *)

val beta_of_verdicts : locus list -> (string * verdict) list -> beta_aggregate
(** [compute_beta] with verdicts as the [(locus_id, verdict)] assoc that
    {!validate_sample} returns on success. *)

(** {1 Locus-response schema and sample validation} *)

type locus_response = {
  lr_locus_id      : string;
  lr_verdict       : verdict;
  lr_confidence    : float;
  lr_evidence_sides: string list;
  lr_evidence      : string;
  lr_rationale     : string;
}

val parse_locus_response : Yojson.Safe.t -> (locus_response, string) result
val parse_locus_responses : Yojson.Safe.t -> (locus_response list, string) result
(** Parse a JSON array (or an object with a [responses] array). *)

(** Why a sample is refused. A refused sample counts against A0 yield. *)
type refusal =
  | Missing_response of string
  | Duplicate_response of string
  | Extraneous_response of string
  | Incomplete_evidence of string

val refusal_to_string : refusal -> string

val validate_sample :
  loci:locus list ->
  responses:locus_response list ->
  ((string * verdict) list, refusal list) result
(** Exactly one response per resolved locus_id — no more, no less — and
    every contradicts verdict carries both evidence sides. [Ok verdicts]
    or [Error refusals] (the sample is refused, not repaired). *)

(** {1 JSON serialization} *)

val locus_to_json : ?target:string -> locus -> Yojson.Safe.t
(** One locus as JSON, optionally tagged with its target (AC2 fields). *)

val inventory_to_json : target:string -> locus list -> Yojson.Safe.t
(** The pre-witness inventory artifact (AC2 fields: target, locus_id, kind,
    source_path, source_span, target_path, target_span, mechanical_status,
    llm_called). *)

val aggregate_to_json : beta_aggregate -> Yojson.Safe.t

(** {1 Adjudication prompt surface} *)

val locus_prompt_block : locus -> string
val adjudication_instruction : locus list -> string
(** The bounded per-locus adjudication instruction over the resolved loci;
    the witness never emits a scalar. Separate from the α/γ scalar path. *)

(** {1 B3 discrimination-gate fixture (typed rules)} *)

type control = {
  c_id                      : string;
  c_kind                    : string;
  c_hard                    : bool;
  c_llm_called              : bool;
  c_mechanical_status       : string;
  c_expected_verdict        : string;
  c_required_evidence_sides : string list;
}

val parse_controls : Yojson.Safe.t -> (control list, string) result
val typed_rule_errors : control -> string list
val validate_controls : Yojson.Safe.t -> (int, string list) result
(** The B3 typed-fixture gate: [Ok n] when every control is well-typed;
    [Error errs] otherwise. The label-agreement half needs a witness run
    (deferred to the credentialed CI witness). *)
