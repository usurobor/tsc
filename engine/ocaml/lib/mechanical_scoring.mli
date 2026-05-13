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

type result = {
  mode : [ `Mechanical ];
  target : string option;
  alpha : axis_result;
  beta : axis_result;
  gamma : axis_result;
  c_sigma_math : float;
  c_sigma_num : float;
  epsilon : float;
  zero_component_present : bool;
  numeric_floor_applied : bool;
  bottleneck_axis : axis;
  confidence : float;
  diagnostics : diagnostic list;
}
(** Full mechanical scoring result.

    Canonical v3.2 aggregate: the cross-axis composite is the geometric
    mean of [alpha.score], [beta.score], [gamma.score]. Spec
    [spec/tsc-core.md] §5 defines two forms which coincide whenever
    every component is at least [epsilon]:

    - [c_sigma_math]: strict geometric mean; collapses to 0 if any
      component is exactly 0 ([zero_component_present = true]).
    - [c_sigma_num]: epsilon-floored numeric form used for thresholding,
      bootstrap CI, and OOD comparison; [numeric_floor_applied] is true
      when at least one component fell below [epsilon].

    [confidence] expresses sufficiency of structural evidence, not
    semantic certainty. *)

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
  alpha : alpha_config;
  beta : beta_config;
  gamma : gamma_config;
  epsilon : float;
  min_confidence_files : int;
  max_excerpt_chars : int;
}
(** Mechanical scoring configuration.

    Cross-axis aggregation is the canonical v3.2 geometric mean — it
    takes no weights (it is S3-symmetric over α/β/γ by construction).
    Intra-axis signal weights are configured per axis.

    [epsilon] is the numeric floor used in the [c_sigma_num] form.

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
  delta_c_sigma_num : float;
  delta_c_sigma_math : float;
  changed_bottleneck : bool;
  summary : string;
}
(** Structural comparison between two scored bundles.

    [delta_c_sigma_num] is the canonical comparison signal (numeric
    aggregate, per spec/tsc-oper.md §5). [delta_c_sigma_math] reports
    the strict geometric-mean delta and is informational. *)

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
