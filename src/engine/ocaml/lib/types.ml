(** Core types for the TSC engine.

    Field names are disambiguated at definition per ocaml skill §2.1:
    no two record types share a field name in the same module. *)

(** Target kind — theory, implementation, or aggregate. *)
type target_kind =
  | Theory
  | Implementation
  | Aggregate

(** A parsed target manifest from targets/*.tsc *)
type target_manifest = {
  manifest_name : string;
  manifest_kind : target_kind;
  manifest_description : string;
  manifest_include : string list;
  manifest_exclude : string list;
  manifest_optional : string list;
  manifest_include_targets : string list;
}

(** A parsed target registry from targets/registry.tsc *)
type target_registry = {
  registry_format : string;
  registry_default_target : string;
  registry_targets : (string * string) list;
  (** (name, manifest_path) pairs *)
}

(** One file in a resolved bundle. *)
type bundle_file = {
  file_path : string;
  file_content : string;
  file_hash : string;  (** SHA-256 hex digest *)
  file_size : int;
  file_target_kind : target_kind;
}

(** A complete target bundle ready for prompt construction. *)
type target_bundle = {
  bundle_target_name : string;
  bundle_target_kind : target_kind;
  bundle_files : bundle_file list;
}

(** Provider configuration — all from runtime env, never repo. *)
type provider_config = {
  provider_name : string;
  provider_model : string;
  provider_api_key : string;
  provider_base_url : string option;
}

(** One axis score with evidence.

    [evidence_checklist] is the v3.2.3 per-axis defect walk:
    (category, (count, severity)) per checklist category, in response
    order. Empty when the response carries no walk (pre-v3.2.3 shape);
    the witness funnel's checklist stage refuses that. *)
type axis_evidence = {
  evidence_positive : string list;
  evidence_negative : string list;
  evidence_reason : string;
  evidence_checklist : (string * (int * string)) list;
}

(** A structured defect card (SELF-MEASURE v3.2.4): the canonical
    machine-readable defect surface. Every defect is filed under
    EXACTLY ONE primary axis by the instruction's precedence rule;
    other plausible axes are secondary. axis_evidence.negative remains
    the human-readable projection. *)
type defect_card = {
  card_id : string;
  card_primary_axis : string;           (* alpha | beta | gamma *)
  card_category : string;               (* a category of that axis *)
  card_severity : string;               (* cosmetic|isolated|systemic *)
  card_evidence : string;               (* path:line or section citation *)
  card_summary : string;
  card_secondary_axes : string list;
}

(** A suggested fix. *)
type suggested_fix = {
  fix_axis : string;
  fix_description : string;
}

(** Validated model response. *)
type measure_result = {
  result_target : string;
  result_alpha : float;
  result_beta : float;
  result_gamma : float;
  result_bottleneck_axis : string;
  result_confidence : float;
  result_summary : string;
  result_alpha_evidence : axis_evidence;
  result_beta_evidence : axis_evidence;
  result_gamma_evidence : axis_evidence;
  result_unresolved_ambiguity : string list;
  result_next_fixes : suggested_fix list;
  result_defect_cards : defect_card list;
}

(** Run metadata for reproducibility. *)
type run_metadata = {
  meta_target : string;
  meta_file_hashes : (string * string) list;  (** (path, hash) pairs *)
  meta_prompt_version : string;
  meta_provider : string;
  meta_model : string;
  meta_timestamp : string;
}

(** The witness protocol version — the version of runtime/SELF-MEASURE.md
    the engine emits prompts for and validates responses against. ONE
    source: tests pin this constant to the instruction's own title and
    §3 header, so a protocol bump that misses either surface fails CI.
    Distinct from the REPORT schema version (report.ml, "v3.2.0"): that
    names the shape of emitted report JSON, which did not change across
    witness-protocol revisions. *)
let self_measure_protocol_version = "SELF-MEASURE/3.2.4"
