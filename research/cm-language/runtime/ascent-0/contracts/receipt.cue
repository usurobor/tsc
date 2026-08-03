// #MeasurementReceipt — the receipt contract for the Ascent-0 runtime.
//
// This is a RUNTIME-LOCAL contract, deliberately NOT added to
// research/cm-language/schema.cue: that schema explicitly DEFERS the full
// #RunRequest / #MeasurementReceipt separation ("still FUTURE, #112"), so this
// slice carries its own receipt contract here and does not touch schema.cue.
//
// It MIRRORS (does not import) the Sub-2 result vocabulary (#ResultClass) and
// the closed five-field #CompiledView proposal shape, so the receipt's embedded
// semantic view is re-checked for Firewall A (a warrant-bearing field on the
// view is rejected as "field not allowed"), and result_class is pinned to the
// Core-faithful vocabulary.
//
// Sub 4 (#122) generalizes the contract to ALL FIVE categories via a
// DISCRIMINATED UNION on result.result_class: the common shape is stated once,
// then each category TIGHTENS the receipt so the constraint bites per outcome —
// a LIFT_VALIDATED receipt without a verified oracle and a collapsed tested
// fiber fails; an ASCENT_UNDERDETERMINED that collapsed its fiber fails; a
// NO_REALIZATION_IN_MODEL with a non-empty fit fails; a DECORATIVE_LIFT that ran
// the search (or was admissible) fails. The struct is CLOSED at the top level
// and on the load-bearing sub-objects, so a stray or misspelled field is
// rejected — the constraint bites.
package ascent0receipt

// Mirror of ascent0providers.#ResultClass (Core-faithful; never collapsed).
#ResultClass:
	"LIFT_VALIDATED" |
	"ASCENT_UNDERDETERMINED" |
	"NO_REALIZATION_IN_MODEL" |
	"IDENTIFIED_IN_MODEL" |
	"DECORATIVE_LIFT" |
	"UNRESOLVED"

// Mirror of ascent0providers.#CompiledView — closed to exactly five proposal
// fields (Firewall A). A warrant-bearing field on the embedded view fails vet.
// Holds for EVERY case, including the decorative one (the decorative proposal is
// still a well-formed five-field view; it is refused by the admissibility gate,
// not by shape).
#CompiledView: close({
	governing_question: string
	preserved_local_claims: [...string]
	closure_assumption: string
	polar_view:         string
	named_obstruction:  string
})

#ProviderClass:
	"semantic" | "finite_model" | "realization_fit" |
	"realization_quotient" | "descent" | "oracle" | "roundtrip"

#SearchStrength: "complete_within_bound" | "exact" | "sampled" | "none"

#PlanStep: close({
	order:           int & >=0
	step_id:         string
	provider_class:  #ProviderClass
	provider_kind:   "llm" | "tool" | "oracle" | "cm"
	kind:            "semantic_judgment" | "mechanical" | "oracle" | "invoke_cm" | "transform"
	reads: [...string]
	produces: [...string]
	may_access: [...string]
	search_strength: #SearchStrength
})

#OracleDerivation: close({
	reveal_path:              string
	public_commitment_sha256: =~"^[0-9a-f]{64}$"
	recomputed_reveal_sha256: =~"^[0-9a-f]{64}$"
	commitment_verified:      bool
	revealed_output:          string
	hidden_machine_canonical_id: string
	pass_count:               int & >=0
	fail_count:               int & >=0
	tested_fiber_size:        int & >=0
	recovered_class_contains_hidden_machine: bool
})

#RoundtripDerivation: close({
	augmented_fit_count:    int & >=0
	fiber_over_J_eval_size: int & >=0
	contains_hidden_machine: bool
	// AC5: the claim is scoped to bounded-equivalence identification, not identity.
	equivalence_scope: string
})

#OracleSeal: close({
	predictions_frozen_tick: int & >0
	reveal_opened_tick:      int & >0
	// The reveal must strictly follow the frozen predictions.
	ordering_ok: true
	reveal_access_log: [...close({provider_class: string, surface: string})]
	// No non-oracle provider may have touched the reveal.
	non_oracle_reveal_accesses: 0
	note: string
})

#MeasurementReceipt: close({
	format:        "tsc-ascent0-receipt/0.1"
	cm_id:         string
	cm_version:    string
	source_digest: string

	run_request: close({
		case:             string
		// Both arms carry the SAME mechanical backend; the arm names the
		// provenance of the semantic proposal (canned vs blind live-LLM).
		arm:              "deterministic_conformance" | "blind_live_llm"
		heldout_query:    string
		fixture_case_dir: string
	})

	plan_digest: =~"^sha256:[0-9a-f]{64}$"

	sandbox_execution_plan: close({
		cm_id:         string
		cm_version:    string
		source_digest: string
		steps: [...#PlanStep]
	})

	// Firewall A: the embedded semantic proposal is a closed five-field view.
	compiled_view: #CompiledView

	// The pre-realization admissibility gate on the semantic proposal.
	admissibility: close({
		admissible: bool
		gate:       string
		witnesses: [...close({witness: string, present: bool})]
	})

	execution_trace: [...close({order: int, step_id: string})]
	// Steps not run because a case surface was absent (no held-out / no oracle /
	// a withheld admissible_proposal). Each records the surfaces it was missing,
	// so a reviewer can confirm every skip is principled, not a wiring bug.
	skipped_steps: [...close({step_id: string, missing_surfaces: [...string]})]
	event_log: [...close({tick: int, step_id: string, event: string})]

	derivation: close({
		enumerated_class_size: int & >=0
		search_claim:          string
		search_ran:            bool
		fit_candidate_count:   int & >=0
		identification_fiber_size: int & >=0
		heldout_query:         string
		heldout_distinct_predictions: [...string]
		heldout_is_separating: bool
		// present ONLY when the oracle ran (LIFT_VALIDATED cases).
		oracle?:    #OracleDerivation
		roundtrip?: #RoundtripDerivation
	})

	retained_alternatives: close({
		policy: string
		identification_fiber: [...close({
			representative:       string
			predicted_on_heldout: string
			member_count:         int & >0
		})]
		pass_partition: [...string]
		fail_partition: [...string]
		retained_before_result_rule: int & >=0
	})

	// present ONLY when the oracle ran.
	oracle_seal?: #OracleSeal

	result: close({
		result_class: #ResultClass
		computed:     true
		admissible:   bool
		oracle_run:   bool
		search_ran:   bool
		rule:         string
		derived_from: [...string]
	})

	// ── DISCRIMINATED UNION: each category tightens the receipt so it bites ──

	if result.result_class == "LIFT_VALIDATED" {
		// A genuine held-out generation, sealed-oracle-verified, with the tested
		// fiber collapsed to one class and >=2 alternatives retained before the
		// rule (no premature collapse). Requires the oracle + seal present.
		admissibility: admissible: true
		result: {admissible: true, oracle_run: true, search_ran: true}
		derivation: {
			enumerated_class_size: >0
			search_ran:            true
			heldout_is_separating: true
			oracle: {commitment_verified: true, pass_count: >=1, tested_fiber_size: 1}
			// AC7: a LIFT_VALIDATED without held-out generativity + round-trip
			// support fails — the round-trip must return the single J_eval class
			// that contains the hidden machine.
			roundtrip: {fiber_over_J_eval_size: 1, contains_hidden_machine: true}
		}
		oracle_seal: {ordering_ok: true, non_oracle_reveal_accesses: 0}
		retained_alternatives: retained_before_result_rule: >=2
	}

	if result.result_class == "ASCENT_UNDERDETERMINED" {
		// Complete search retains >=2 inequivalent classes; no oracle collapses it.
		admissibility: admissible: true
		result: {admissible: true, oracle_run: false, search_ran: true}
		derivation: {
			enumerated_class_size:     >0
			search_ran:                true
			identification_fiber_size: >=2
		}
		retained_alternatives: retained_before_result_rule: >=2
	}

	if result.result_class == "NO_REALIZATION_IN_MODEL" {
		// Complete bounded search + EMPTY exact-fit set — never uncertainty.
		admissibility: admissible: true
		result: {admissible: true, oracle_run: false, search_ran: true}
		derivation: {
			enumerated_class_size: >0
			search_ran:            true
			fit_candidate_count:   0
		}
	}

	if result.result_class == "DECORATIVE_LIFT" {
		// Refused BEFORE realization: the admissibility gate withheld the
		// admissible_proposal capability, so no search ran.
		admissibility: admissible: false
		result: {admissible: false, oracle_run: false, search_ran: false}
		derivation: {
			search_ran:            false
			enumerated_class_size: 0
			fit_candidate_count:   0
		}
	}
})
