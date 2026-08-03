// NEGATIVE FIXTURE 1 — Firewall A (invariant 2, #118): the semantic provider
// PROPOSES but never WARRANTS and never OWNS H_M.
//
// Every instance below is a #SemanticProvider that tries to smuggle a warrant or
// to set/own H_M. Each MUST be rejected by `cue vet`. Run in isolation:
//
//   cd research/cm-language/providers/ascent-0
//   cue vet contracts.cue negative/warrant_smuggle.cue     # -> exit 1
//
// This file is under negative/ so it is NOT part of the package's positive
// control (`cue vet contracts.cue suite.cue`).
package ascent0providers

// (a) A semantic PROPOSAL carrying a warrant-bearing field. #CompiledView is
// closed to exactly five proposal fields, so `result_class` (a warrant) is
// rejected: "field not allowed".
smuggle_warrant: #SemanticProvider & {
	id:          "bad.semantic.warrant"
	title:       "semantic call smuggling a warrant"
	description: "attempts to emit a result_class from the LLM"
	input: ["one_pov_behavior_primary_viewpoint", "training_traces", "public_methodology_contract"]
	capabilities: ["derive_polar_view"]
	failure: {on_failure: "REFUSAL"}
	output: {
		governing_question: "q"
		preserved_local_claims: ["a->0"]
		closure_assumption: "closed"
		polar_view:         "law-like"
		named_obstruction:  "underdetermined continuation"
		result_class:       "LIFT_VALIDATED" // <-- warrant: field not allowed
	}
}

// (b) A semantic PROPOSAL carrying a held-out prediction (a warrant-bearing
// consequence the mechanical Descent/Oracle providers own). Also rejected by the
// closed #CompiledView.
smuggle_prediction: #SemanticProvider & {
	id:          "bad.semantic.prediction"
	title:       "semantic call smuggling a held-out prediction"
	description: "attempts to emit a held-out prediction from the LLM"
	input: ["one_pov_behavior_primary_viewpoint", "training_traces", "public_methodology_contract"]
	capabilities: ["derive_polar_view"]
	failure: {on_failure: "REFUSAL"}
	output: {
		governing_question: "q"
		preserved_local_claims: ["a->0"]
		closure_assumption:      "closed"
		polar_view:              "law-like"
		named_obstruction:       "underdetermined continuation"
		heldout_prediction_on_q: "01" // <-- warrant-bearing consequence: field not allowed
	}
}

// (c) A semantic contract that claims to OWN H_M (flips the fixed-false face).
// Rejected: owns_H_M conflicting values true and false.
own_H_M: #SemanticProvider & {
	id:          "bad.semantic.owns_hm"
	title:       "semantic call owning H_M"
	description: "attempts to own/expand the model class"
	input: ["one_pov_behavior_primary_viewpoint", "training_traces", "public_methodology_contract"]
	capabilities: ["derive_polar_view"]
	failure: {on_failure: "REFUSAL"}
	owns_H_M: true // <-- conflicts with the fixed false
	output: {
		governing_question: "q"
		preserved_local_claims: ["a->0"]
		closure_assumption: "closed"
		polar_view:         "law-like"
		named_obstruction:  "underdetermined continuation"
	}
}

// (d) A semantic contract that tries to READ H_M as an input (so it could set or
// expand it). Rejected: "H_M_declaration" is not a #SemanticInputSurface — the
// LLM cannot even see the model class.
input_H_M: #SemanticProvider & {
	id:          "bad.semantic.input_hm"
	title:       "semantic call reading H_M as input"
	description: "attempts to take the frozen class as an input"
	input: ["one_pov_behavior_primary_viewpoint", "training_traces", "H_M_declaration"] // <-- not leak-free
	capabilities: ["derive_polar_view"]
	failure: {on_failure: "REFUSAL"}
	output: {
		governing_question: "q"
		preserved_local_claims: ["a->0"]
		closure_assumption: "closed"
		polar_view:         "law-like"
		named_obstruction:  "underdetermined continuation"
	}
}
