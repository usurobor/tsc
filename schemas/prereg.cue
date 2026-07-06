// schemas/prereg.cue — CUE schema for a pre-registration as a
// first-class compile object (a typed β contract).
//
// A prereg is NOT experiment notes. It types the claim: "for THIS axis,
// using THIS evidence and THIS factorization, this experiment counts as
// success/failure." If a prereg cannot be expressed by #Prereg it is not
// yet executable — that is the point of the schema (Sub-2, master #77,
// this sub #79).
//
// Precedent: engine/ocaml/lib/factorized_beta.mli (bounded adjudication —
// the engine enumerates + aggregates; the LLM gives a bounded verdict).
// Style imported from schemas/skill.cue: schemas are open (`...`) so
// package-local extension keys pass through; hard-gate fields fail
// validation if missing.
//
// Validate a fixture:  cue vet -d '#Prereg' schemas/prereg.cue <file>.yaml
//
// Two structural gates are enforced beyond field presence:
//   1. judgment_contract.allowed_labels must match the KEYS of
//      aggregation.label_weights exactly (both directions).
//   2. the three factorization owners (inventory / judgment / aggregation)
//      must be declared and non-empty.

package prereg

import "list"

#Prereg: {
	// ---- Identity ---------------------------------------------------
	// Hard gate: must be present.
	id:    string & =~"^[a-z][a-z0-9-]*$"
	title: !=""

	// The axis this prereg contracts over. A prereg with no declared
	// axis is not executable — an experiment must say WHAT it measures.
	axis: "alpha" | "beta" | "gamma"

	// Lifecycle of the contract. A prereg is drafted `proposed`, gated to
	// `approved`, run to `executed`, and lands on a terminal verdict
	// (`failed` | `passed` | `no_decision`).
	status: "proposed" | "approved" | "executed" | "failed" | "passed" | "no_decision"

	// ---- Human intent: why a person wants this run ------------------
	human_intent: {
		claim:          !=""
		why_it_matters: !=""
		...
	}

	// ---- Hypothesis: the variance and the intervention on it --------
	hypothesis: {
		// The named source of variance the experiment acts on. The
		// re-entry rule requires it be a source NOT already falsified.
		variance_source: !=""
		// What the experiment changes to act on that source.
		intervention: !=""
		...
	}

	// ---- Factorization: who owns each stage of the seam -------------
	// The anti-freedom core. Selection/counting/aggregation are made
	// deterministic (engine-owned); only local judgment stays with the
	// LLM. All three owners MUST be declared.
	factorization: {
		inventory_owner:   !=""
		judgment_owner:    !=""
		aggregation_owner: !=""

		// The fixed locus set the experiment adjudicates. Each locus kind
		// binds to a deterministic enumerator over named source/target
		// spans; the implementer cannot choose the locus set after seeing
		// behaviour.
		loci: [...#Locus]
		...
	}

	// ---- Judgment contract: the bounded verdict the LLM may emit ----
	judgment_contract: {
		// The exact label vocabulary. Must be non-empty AND must match the
		// keys of aggregation.label_weights (enforced below).
		allowed_labels: [...string] & [_, ...]

		// What evidence a valid verdict must carry. Absent/empty evidence
		// requirement means the judgment is not anchored — not executable.
		evidence_required: !=""

		// What happens to a malformed / missing / duplicate answer. The
		// precedent (factorized_beta.mli) refuses the sample, does not
		// repair it.
		refusal: !=""
		...
	}

	// ---- Aggregation: engine mapping from verdicts to the scalar ----
	aggregation: {
		formula: !=""
		// Per-label defect weight. KEYS must equal allowed_labels exactly.
		label_weights: {[string]: number}
		// Per-kind weight.
		kind_weights: {[string]: number}
		...
	}

	// ---- Consistency gate: the pass condition on agreement ----------
	consistency_gate: {
		// Repeats per target. A gate that cannot be sampled is not
		// executable; the barrier needs >= 2 samples to have a spread.
		samples: int & >=2
		// The numeric floor the gate compares against. Without a threshold
		// the gate is not executable by a command / numeric comparison.
		agreement_floor: float & >=0 & <=1
		// What standing a pass earns / a miss withholds. A consistency
		// result with no standing effect is a number with no contract.
		standing_effect: !=""
		...
	}

	// ---- Discrimination gate: the guard against a blind proxy -------
	discrimination_gate: {
		// The labeled controls whose expected verdicts are the reviewable
		// oracle (e.g. the frozen B3 fixture manifest).
		controls: !=""
		...
	}

	// ---- Terminal-verdict contract ----------------------------------
	// The NO-DECISION condition: when the experiment cannot be scored
	// (insufficient surface), it records neither pass nor fail.
	no_decision: {
		condition:   !=""
		consequence: !=""
		...
	}

	// success = the conjunction (all-of) that must hold to pass.
	success: {
		all_of: [...string] & [_, ...]
		...
	}

	// failure = the disjunction (any-of) that records a FAIL.
	failure: {
		any_of: [...string] & [_, ...]
		...
	}

	// What the verdict binds after the fact. on_failure and forbidden are
	// mandatory: a prereg that does not say what a failure means, or what
	// it forecloses, is not a contract.
	post_result_rule: {
		on_failure: !=""
		on_success: !=""
		forbidden: [...string]
		...
	}

	// ---- Structural gate 1: allowed_labels == label_weights keys ----
	// forward: every allowed label has a weight (presence, concreteness).
	for _l in judgment_contract.allowed_labels {
		aggregation: label_weights: (_l): number
	}
	// reverse: no weight key is outside allowed_labels. A non-empty
	// _extra_labels unifies with [] and fails validation.
	_extra_labels: [ for _k, _ in aggregation.label_weights if !list.Contains(judgment_contract.allowed_labels, _k) {_k} ]
	_extra_labels: []

	// Open: package-local extension keys pass through.
	...
}

// #Locus — one deterministic adjudication site. kind binds to a named
// enumerator; the spans are the two-sided surface the judgment reads.
#Locus: {
	kind:        !=""
	enumerator:  !=""
	source_span: !=""
	target_span: !=""
	...
}
