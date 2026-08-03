// Positive control (AC / proof plan): a well-formed instance of the whole
// Ascent-0 provider suite. `cue vet contracts.cue suite.cue` exits 0.
//
// The seven contracts are instantiated with their declared fields and a valid
// semantic PROPOSAL bound to Sub-1 fixture case1 (case1_lift_validated). The
// semantic instance carries ONLY a #CompiledView proposal — no warrant, no H_M;
// the mechanical instances name the Core (#116) fields and the concrete Sub-1
// public.json fields they produce, and the one warrant present (LIFT_VALIDATED,
// on the oracle provider) is fully backed.
package ascent0providers

suite: #Ascent0ProviderSuite & {
	semantic: {
		id:          "ascent0.semantic.compileView"
		title:       "one-POV semantic judgment -> CompiledView proposal"
		description: "One generative call. compileView/unclose/polarize/nameObstruction are phases of this single judgment, not four calls."
		input: ["one_pov_behavior_primary_viewpoint", "training_traces", "public_methodology_contract"]
		capabilities: ["derive_polar_view", "derive_closure_assumption", "name_obstruction", "propose_candidate_interpretation"]
		failure: {on_failure: "REFUSAL", note: "declines to produce a CompiledView; never emits a warrant"}
		determinism: {
			deterministic: false
			repeatability: "distributional"
			sampling: {temperature: 0.7, n_samples: 8, selection: "retain_all_samples_for_downstream_mechanical_fit"}
		}
		may_not_access: ["oracle_reveal", "hidden_machine", "heldout_output_pre_reveal", "heldout_input_query"]

		// The PROPOSAL, bound to fixture case1's leak-free semantic_input.txt.
		// Note: no `source`/`Mealy`/`hidden generator` vocabulary (invariant 1);
		// the polar view is DERIVED, not supplied.
		output: {
			governing_question: "What is the component, given only its finite observed replies, and what does it reply to an unattempted input?"
			preserved_local_claims: ["reply to \"a\" is \"0\"", "reply to \"aa\" is \"01\"", "reply to \"b\" is \"0\"", "reply to \"ba\" is \"00\""]
			closure_assumption: "the given observations exhaust what the component is"
			polar_view:         "the component is a rule that continues to unattempted inputs, of which the observations are a finite sample"
			named_obstruction:  "a finite observed sample does not fix the reply on an unattempted input and may be continued in several inequivalent ways"
		}
	}

	finite_model_enumerate: {
		id:          "ascent0.finiteModel.enumerate"
		title:       "complete bounded enumeration over H_M"
		description: "Exhaustive enumeration of the frozen class within (N,|Sigma|,|Gamma|)."
		capabilities: ["enumerate_bounded_class", "assert_complete_within_bound"]
	}

	realization_fit: {
		id:          "ascent0.realization.fit"
		title:       "training-evidence partition (L_M)"
		description: "Exact-fit partition of the enumerated class against the training traces."
		capabilities: ["compute_L_M", "partition_exact_fit", "retain_empty_fit_set"]
	}

	realization_quotient: {
		id:          "ascent0.realization.quotient"
		title:       "equivalence-class fiber (K_M-aware)"
		description: "Quotient the fit set by the declared behavioral equivalence."
		capabilities: ["quotient_by_equivalence", "count_inequivalent_classes"]
	}

	descent_predict: {
		id:          "ascent0.descent.predict"
		title:       "candidate predictions on q*"
		description: "Frozen per-class predictions on the public held-out query; separation over the fiber."
		capabilities: ["predict_on_heldout", "check_separation", "freeze_predictions"]
	}

	oracle_reveal_compare: {
		id:          "ascent0.oracle.revealAndCompare"
		title:       "commit/reveal verification + outcome partition"
		description: "Verify the commitment binds the reveal, then partition candidates by the revealed output."
		capabilities: ["verify_commitment", "reveal_after_freeze", "partition_pass_fail", "compute_tested_fiber"]
		// The one fully-backed warrant in the suite (case1 -> LIFT_VALIDATED).
		output: {
			warrant: {
				result_class: "LIFT_VALIDATED"
				backed_by: {heldout_prediction: true, oracle_outcome: true, equivalence_fiber: true}
			}
		}
	}

	roundtrip_check: {
		id:          "ascent0.roundTrip.check"
		title:       "post-descent fiber + equivalence (round-trip)"
		description: "Fold (q*, W(q*)) back in, re-ascend, and check the round-trip class over J_eval'."
		capabilities: ["fold_descent_evidence", "re_ascend", "check_roundtrip_equivalence"]
	}
}
