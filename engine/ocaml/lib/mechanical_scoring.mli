(** Mechanical scoring for TSC.

    This module computes deterministic structural scores over a resolved
    bundle.

    It does not:
    - call an LLM
    - perform network I/O
    - infer hidden semantics
    - parse Markdown into a semantic AST

    It does:
    - score structural coherence proxies for alpha, beta, and gamma
    - preserve evidence for each score
    - return stable results for identical input bundle + config

    Mechanical scoring is a structural backend. It is useful for:
    - local iteration
    - CI
    - no-credential environments
    - baseline comparison against semantic scoring *)

type axis = [ `Alpha | `Beta | `Gamma ]

type evidence_kind = [ `Structural_proxy ]

type signal = {
  code : string;
  label : string;
  weight : float;
  score : float;
  evidence : string list;
}
(** One scored structural signal contributing to an axis result. *)

type diagnostic_level = [ `Info | `Warning | `Error ]

type diagnostic = {
  level : diagnostic_level;
  code : string;
  message : string;
  paths : string list;
}
(** Diagnostics produced during scoring. Use diagnostics for:
    - malformed bundles
    - missing expected surfaces
    - suspicious but non-fatal structural conditions *)

type axis_result = {
  axis : axis;
  score : float;
  evidence_kind : evidence_kind;
  signals : signal list;
  summary : string;
  unresolved_ambiguity : string list;
}
(** Result for one axis. *)

type aggregate = {
  c_sigma_math : float;
  c_sigma_num : float;
  epsilon : float;
  zero_component_present : bool;
  numeric_floor_applied : bool;
}
(** Canonical v3.2 aggregate record sourced from [Coherence.aggregate].

    [c_sigma_math] is the strict geometric mean (collapses to 0 on any
    zero component).  [c_sigma_num] is the ε-floored geometric mean
    (well-defined under degenerate inputs).  The two coincide when every
    axis score is >= [epsilon].

    No flat aggregate field is exposed in public JSON; aggregate facts
    live only under the [provenance] sub-object emitted by
    [result_to_json]. *)

type result = {
  mode : [ `Mechanical ];
  target : string option;
  alpha : axis_result;
  beta : axis_result;
  gamma : axis_result;
  aggregate : aggregate;
  bottleneck_axis : axis;
  confidence : float;
  diagnostics : diagnostic list;
}
(** Full mechanical scoring result.

    [aggregate] carries both canonical aggregate forms (math and num)
    plus degeneracy flags; it is derived from [alpha], [beta], [gamma]
    via [Coherence.aggregate].

    [confidence] expresses sufficiency of structural evidence, not
    semantic certainty. *)

type weights = {
  alpha : float;
  beta : float;
  gamma : float;
}
(** Per-axis weights for axis-internal signal scoring.

    These weights are NOT applied to the cross-axis aggregate — the
    canonical v3.2 aggregate is S3-invariant and uses an unweighted
    geometric mean per [Coherence.aggregate]. *)

type alpha_config = {
  terminology_consistency : float;
  repeated_structure : float;
  duplicate_definition_tension : float;
  naming_drift : float;
}
(** Weights for structural alpha signals. *)

type beta_config = {
  cross_reference_consistency : float;
  authority_alignment : float;
  source_of_truth_alignment : float;
  target_file_fit : float;
}
(** Weights for structural beta signals. *)

type gamma_config = {
  canonical_generated_distinction : float;
  version_surface_consistency : float;
  traceability_presence : float;
  authority_evolution_consistency : float;
}
(** Weights for structural gamma signals. *)

type config = {
  weights : weights;
  alpha : alpha_config;
  beta : beta_config;
  gamma : gamma_config;
  min_confidence_files : int;
  max_excerpt_chars : int;
}
(** Mechanical scoring configuration.

    [min_confidence_files] controls when confidence should be reduced
    due to a very small bundle.

    [max_excerpt_chars] bounds evidence excerpts in diagnostics/signals. *)

val default_config : config
(** Canonical default config. *)

val score_bundle : ?config:config -> Bundle.t -> result
(** Score a resolved bundle structurally.

    Determinism guarantee: for identical [Bundle.t] content and
    identical [config], this function returns the same [result].

    This function must not perform network I/O or consult ambient
    provider state. *)

val score_files : ?config:config -> Bundle.file list -> result
(** Convenience scoring entrypoint for direct file input that has
    already been read into bundle-file form.

    The caller remains responsible for deterministic ordering if order
    matters upstream. *)

type comparison = {
  old_result : result;
  new_result : result;
  delta_alpha : float;
  delta_beta : float;
  delta_gamma : float;
  delta_c_sigma_math : float;
  delta_c_sigma_num : float;
  changed_bottleneck : bool;
  summary : string;
}
(** Structural comparison between two scored bundles.

    Aggregate deltas are emitted under canonical form-suffixed names
    ([delta_c_sigma_math] / [delta_c_sigma_num]); the unsuffixed
    [delta_c_sigma] from v0.9.x has been removed (v0.10.0 cutover). *)

val compare : ?config:config -> old_:Bundle.t -> new_:Bundle.t -> comparison
(** Compare two bundles through the mechanical backend.

    Intended use:
    - local iteration
    - regression checks
    - tracking whether the bottleneck axis moved *)

val result_to_json : result -> Yojson.Safe.t
(** Canonical machine-readable encoding for the mechanical result. *)

val comparison_to_json : comparison -> Yojson.Safe.t
(** Canonical machine-readable encoding for the comparison result. *)

val summarize_signal : signal -> string
(** Human-readable one-line summary for a signal. *)

val summarize_result : result -> string
(** Human-readable summary for logs or text reports. *)

(** {1 Scoring intent by axis}

    {b Alpha:}
    - repeated structure
    - terminology consistency
    - naming stability
    - tension from duplicated or conflicting definitions

    {b Beta:}
    - agreement across files
    - authority consistency
    - source-of-truth alignment
    - fit between declared target and included files

    {b Gamma:}
    - clarity of what is canonical vs generated
    - consistency of version/evolution surfaces
    - presence of traceability/closeout surfaces
    - consistency of how future change is meant to happen

    Mechanical scoring is structural, not semantic. It should catch
    obvious incoherence cheaply and deterministically. *)
