// NEGATIVE FIXTURE 2 — Firewall B (invariant 3, #118): the oracle is SEALED from
// every non-oracle provider. Only Oracle.revealAndCompare may list an oracle
// surface in may_access.
//
// Each instance below is a NON-oracle provider whose may_access includes a sealed
// oracle surface. Each MUST be rejected by `cue vet`. Run in isolation:
//
//   cd research/cm-language/providers/ascent-0
//   cue vet contracts.cue negative/oracle_leak.cue     # -> exit 1
//
// The bite: for any provider whose class is not "oracle", may_access is narrowed
// to [...#RestrictedSurface] (oracle surfaces excluded), so an oracle surface in
// its may_access has no value in the disjunction — an empty-disjunction / matching
// conflict naming the sealed surface (the schema.cue negative-probe idiom).
package ascent0providers

// (a) The finite-search provider trying to read the hidden ground-truth machine.
leak_finite_search: #ProviderContract & {
	id:             "bad.finite.reads_hidden_machine"
	provider_class: "finite_model"
	kind:           "mechanical"
	title:          "finite search reading the oracle"
	description:    "a non-oracle provider granted oracle access"
	input: ["H_M_declaration", "search_bounds"]
	output: {}
	capabilities: []
	evidence: {core_fields: [], fixture_fields: []}
	failure: {on_failure: "UNRESOLVED"}
	search_strength: "complete_within_bound"
	determinism: {deterministic: true, repeatability: "exact"}
	may_access: ["hidden_machine"] // <-- sealed oracle surface on a non-oracle provider
	may_not_access: []
}

// (b) The semantic provider (class "semantic") reading the sealed held-out output
// before reveal. Rejected by the same narrowing.
leak_semantic: #ProviderContract & {
	id:             "bad.semantic.reads_heldout_output"
	provider_class: "semantic"
	kind:           "generative"
	title:          "semantic call reading the sealed held-out output"
	description:    "a non-oracle provider granted oracle access"
	input: ["one_pov_behavior_primary_viewpoint", "training_traces", "public_methodology_contract"]
	output: {}
	capabilities: []
	evidence: {core_fields: [], fixture_fields: []}
	failure: {on_failure: "REFUSAL"}
	search_strength: "sampled"
	determinism: {deterministic: false, repeatability: "distributional"}
	may_access: ["heldout_output_pre_reveal"] // <-- sealed oracle surface
	may_not_access: []
}

// (c) The descent provider escalating from the PUBLIC q* to the whole sealed
// reveal bundle. The public q* alone is fine (#RestrictedSurface); the reveal
// bundle is not.
leak_descent: #ProviderContract & {
	id:             "bad.descent.reads_reveal_bundle"
	provider_class: "descent"
	kind:           "mechanical"
	title:          "descent reading the reveal bundle"
	description:    "a non-oracle provider granted oracle access"
	input: ["fit_candidate_set", "heldout_input_query"]
	output: {}
	capabilities: []
	evidence: {core_fields: [], fixture_fields: []}
	failure: {on_failure: "UNRESOLVED"}
	search_strength: "exact"
	determinism: {deterministic: true, repeatability: "exact"}
	may_access: ["heldout_input_query", "oracle_reveal"] // q* ok; oracle_reveal sealed
	may_not_access: []
}
