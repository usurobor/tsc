// The Repository Coherence CM (parent, v0.1) encoded against schema.cue.
// Source of truth remains research/repository-coherence/CM.md; this is a
// parallel CUE encoding built to validate the model.
package cm

repository_coherence: #Methodology & {
	id:      "repository-coherence"
	version: "0.1"
	question: "At this exact repository snapshot, do the selected coherence aspects jointly support treating the repository as one coherent system, and where do they conflict or remain unmeasured?"

	input: {
		repository_snapshot: "repository_snapshot"
		selected_aspects:    "selected_aspects"
	}

	// The parent composes aspects, never audiences. Children are source refs.
	children: {
		legibility: {aspect_id: "legibility", source: "./legibility", implemented: true, selected: true}
		structure: {aspect_id: "structure", source: "./structure", implemented: true, selected: true}
		// Operability is registered but not implemented (ASPECTS.md).
		operability: {aspect_id: "operability", source: "./operability", implemented: false, selected: false}
	}

	invariants: {
		same_snapshot:            true
		retain_child_receipts:    true
		allow_scalar_aggregation: false
	}

	// Deterministic step-6 derivation, as DATA.
	result: {
		statuses: [
			"COHERENT_WITHIN_MEASURED_ASPECTS",
			"DEFECTS_FOUND",
			"INCOMPLETE",
			"CM_EXECUTION_FAILED",
		]
		precedence: ["FAILED", "INCOMPLETE", "DEFECT", "PASS"]
		mapping: {
			FAILED:     "CM_EXECUTION_FAILED"
			INCOMPLETE: "INCOMPLETE"
			DEFECT:     "DEFECTS_FOUND"
			PASS:       "COHERENT_WITHIN_MEASURED_ASPECTS"
		}
	}

	// α — execution manifestation with same-snapshot binding.
	manifestation: {
		same_snapshot_binding: true
		records:               "selected / unimplemented / incomplete children"
	}

	// β — cross-aspect atlas, non-gating in v0.1.
	atlas: {
		gating: false
	}

	continuation_baseline: "BASELINE — no prior composite receipt"

	boundary: {
		measure_only: true
	}

	// The seven stable RCM-* requirements.
	requirements: [
		{id: "RCM-SNAPSHOT-001", text: "Every child receipt binds the same exact repository commit."},
		{id: "RCM-SELECTION-001", text: "Every requested aspect either executes or is explicitly reported as unimplemented/incomplete."},
		{id: "RCM-RECEIPT-001", text: "Every executed aspect returns an evidence-bound categorical receipt satisfying the generic envelope, including a result_class in {PASS, DEFECT, INCOMPLETE, FAILED} mapped from the child's own status."},
		{id: "RCM-COVERAGE-001", text: "Every composite claim names exactly which aspects and profiles it covers."},
		{id: "RCM-CONFLICT-001", text: "Cross-aspect disagreement is retained and surfaced, never averaged away."},
		{id: "RCM-NO-AGGREGATE-001", text: "No scalar or parent verdict may erase a child finding."},
		{id: "RCM-BOUNDARY-001", text: "Parent and child CMs measure only; repair and independent review remain separate invocations."},
	]

	does_not_own: [
		"artifact manifest",
		"shared schema registry",
		"universal ontology",
		"common inventory",
	]

	// A concrete first composite run at commit 48b9a63 (ASPECTS.md latest
	// executions): legibility PASS, structure DEFECT. Derivation: no FAILED,
	// no INCOMPLETE/unavailable among executed -> DEFECT present ->
	// composite_status = DEFECTS_FOUND.
	receipt: {
		repository_commit: "48b9a63"

		coverage: {
			selected:              ["legibility", "structure"]
			executed:              ["legibility", "structure"]
			unavailable:           []
			failed:                []
			registered_unselected: ["operability"]
		}

		child_receipts: {
			legibility: {
				aspect_id:         "legibility"
				cm_version:        "0.2"
				profile:           "technical-newcomer-human"
				repository_commit: "48b9a63"
				result_class:      "PASS"
				status:            "COHERENT_WITHIN_DECLARED_SCOPE"
				status_mapping: {
					COHERENT_WITHIN_DECLARED_SCOPE: "PASS"
					DEFECTS_FOUND:                  "DEFECT"
					UNDERDETERMINED:                "INCOMPLETE"
					INCOMPLETE_OBSERVATION:         "INCOMPLETE"
					CM_EXECUTION_FAILED:            "FAILED"
				}
				scope:               "declared reader set"
				findings:            []
				refusals:            []
				unobserved_surfaces: "none recorded"
				evidence_refs:       "run 0003 @ 48b9a63 · fixture 6/6"
			}
			structure: {
				aspect_id:         "structure"
				cm_version:        "0.2"
				profile:           "repository-planes-v1.1"
				repository_commit: "48b9a63"
				result_class:      "DEFECT"
				status:            "DEFECTS_FOUND"
				status_mapping: {
					COHERENT_WITHIN_DECLARED_SCOPE: "PASS"
					DEFECTS_FOUND:                  "DEFECT"
					UNDERDETERMINED:                "INCOMPLETE"
					INCOMPLETE_OBSERVATION:         "INCOMPLETE"
					CM_EXECUTION_FAILED:            "FAILED"
				}
				scope:               "declared plane set · excluded paths · policy commit"
				findings:            ["at least one policy violation established"]
				refusals:            []
				unobserved_surfaces: "paths not classified, with reason"
				evidence_refs:       "run 0002 @ 48b9a63 · plane_manifest_digest · consumer graph"
			}
		}

		composite_status: "DEFECTS_FOUND"

		continuation: {
			status: "BASELINE — no prior composite receipt"
			improved:         []
			regressed:        []
			stayed_defective: []
			new_issue:        []
		}

		// β atlas: relations retained and surfaced, not gating in v0.1.
		atlas: [
			{kind: "complement", aspects: ["legibility", "structure"], note: "Legibility passes within its declared reader set while structure establishes a placement defect at the same commit; retained without averaging."},
		]
	}
}

// Methodology-only projection (issue #115 composite spike): the composition
// PROGRAM = repository_coherence minus its concrete run (`receipt`). Additive —
// does NOT touch the `repository_coherence` expr above, whose export stays
// byte-identical to compiled/repository-coherence.json. This is the `.cm`
// composite byte-identity target (cue export -e repository_coherence_source).
repository_coherence_source: {
	for k, v in repository_coherence if k != "receipt" {(k): v}
}
