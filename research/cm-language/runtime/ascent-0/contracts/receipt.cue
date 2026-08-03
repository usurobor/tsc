// #MeasurementReceipt — the receipt contract for the Ascent-0 Sub-3 runtime.
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
// The struct is CLOSED at the top level and on the load-bearing sub-objects, so
// a stray or misspelled field is rejected — the constraint bites.
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

#MeasurementReceipt: close({
	format:        "tsc-ascent0-receipt/0.1"
	cm_id:         string
	cm_version:    string
	source_digest: string

	run_request: close({
		case:             string
		arm:              "deterministic_conformance"
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

	execution_trace: [...close({order: int, step_id: string})]
	event_log: [...close({tick: int, step_id: string, event: string})]

	derivation: close({
		enumerated_class_size: int & >0
		search_claim:          string
		fit_candidate_count:   int & >=0
		identification_fiber_size: int & >=0
		heldout_query:         string
		heldout_distinct_predictions: [...string]
		heldout_is_separating: bool
		oracle: close({
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
		roundtrip: close({
			augmented_fit_count:    int & >=0
			fiber_over_J_eval_size: int & >=0
			contains_hidden_machine: bool
		})
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
		// The executor must not collapse a multi-candidate fiber before the rule.
		retained_before_result_rule: int & >=2
	})

	oracle_seal: close({
		predictions_frozen_tick: int & >0
		reveal_opened_tick:      int & >0
		// The reveal must strictly follow the frozen predictions.
		ordering_ok: true
		reveal_access_log: [...close({provider_class: string, surface: string})]
		// No non-oracle provider may have touched the reveal.
		non_oracle_reveal_accesses: 0
		note: string
	})

	result: close({
		result_class: #ResultClass
		computed:     true
		admissible:   bool
		oracle_run:   bool
		rule:         string
		derived_from: [...string]
	})
})
