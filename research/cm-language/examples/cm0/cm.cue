// CM0 — the coherence methodology whose TARGET is another coherence methodology.
// Encoded as an ORDINARY #LeafMethodology (schema.cue, increment-4A generic layer),
// NOT a CM0-specific root type. This is the reflective example that forces the
// generic leaf boundary: an aspect leaf measures a git repository; CM0 measures a
// candidate methodology as a measurement INSTRUMENT.
//
// Grounding: spec/tsc-oper.md (CM0 lifecycle CMSource→compile→CompiledCM→
// CalibrationReceipt→CM0→InstrumentAssessment; §1.4 "CM0 measures. It does not
// compile, admit, authorize, or decide a boundary action") and
// spec/tsc-conformance.md OPER-AUTH-001 ("CM0 cannot admit itself").
//
// 4A authors CM0's SOURCE only — NO assessment runs, NO InstrumentAssessment result
// computed, NO fixtures/calibration data (that is 4B/4C/4D). The procedure names the
// five subcontracts as typed, provider-bound CHECK STEPS; the boundary is
// measure-only and CUE-enforced; every subject artifact is a content-addressed
// #ArtifactRef slot.
package cm

// cm0 is authored as an explicit #CMSource & #LeafMethodology: the pre-normalization
// methodology PROGRAM. It unifies with #LeafMethodology (the gate: no #CM0Methodology
// root type exists) and is a #CMSource (the authored form). It is a PURE methodology
// — a reusable instrument spec, NOT fused to any concrete measurement run or receipt
// (contrast the three repository examples, which embed a run-0002/0003 receipt). Its
// normalized IR is `cm0_ir` below, exported to compiled/cm0.json.
cm0: #LeafMethodology & #CMSource & {
	id:      "tsc.cm0"
	version: "0.1"
	question: "Is this candidate coherence methodology fit, within its declared scope, to act as a measurement instrument?"

	// Target: a candidate coherence methodology (NOT a git repository). Expressed as
	// an ordinary #TargetContract — this is what the generic leaf boundary exists to
	// carry. CM0 measures the methodology; it never executes it on a downstream
	// target here.
	target_contract: #TargetContract & {
		kind:        "coherence_methodology"
		description: "a candidate coherence methodology, presented as CM source + its normalized IR (+ an optional later CompiledCM), assessed as a measurement instrument."
	}

	// Input: an #InstrumentSubject. Every artifact is a content-addressed #ArtifactRef
	// SLOT (AC7) — CM0 embeds no child receipts or IR copies. At declaration time (no
	// run) each slot is unbound (ref: null); a run binds it to an #ArtifactRef.
	//
	// NormalizedCMIR vs CompiledCM, honestly (AC5): `normalized_ir` is a REQUIRED
	// slot (the CUE export) and grounds language-level contract integrity; `compiled`
	// is NON-required, and with no CompiledCM bound `runtime_binding.status` is
	// INCOMPLETE — CM0 cannot assert runtime completeness from a normalized IR alone.
	input: #InstrumentSubject & {
		standing_scope: {
			declared: "the candidate methodology's own declared scope; CM0 asserts nothing beyond it, and a self-assessment is a hygiene check only, never sole standing (tsc-oper.md §4.4)."
		}
		runtime_binding: {status: "INCOMPLETE"}
	}

	// Procedure: the FIVE subcontracts as ordinary #TypedStep compositions — NOT
	// prose. Each step declares its #StepKind, the #ProviderRef that performs it, its
	// input, and the output/evidence CONTRACTS it must satisfy. This exercises the
	// instruction-set algebra across four provider kinds (mechanical, oracle,
	// invoke_cm, semantic_judgment). NO runs — no receipts are computed here; a step
	// of a kind that would compile/admit/authorize (not in #StepKind) fails `cue vet`.
	// Step `id` names the subcontract.
	procedure: {
		// CM0 uses the typed step algebra (the three settled examples keep #ProcedureStep).
		steps: [...#TypedStep]
		steps: [
			// contract_integrity — mechanical, over the normalized IR alone (language
			// level; assessable without a CompiledCM).
			{
				id:   "contract_integrity"
				kind: "mechanical"
				provider: {kind: "tool", id: "ir_contract_checker", digest: "sha256:ic0"}
				input: {reads: ["subject.normalized_ir", "subject.source"]}
				output_contract: {parts_present: "bool", relations_consistent: "bool", scope: "language_level"}
				evidence_contract: {ir_field_citations_required: true}
				failure: "FAILED"
			},
			// repeatability — an oracle over declared repeats.
			{
				id:   "repeatability"
				kind: "oracle"
				provider: {kind: "oracle", id: "determinism_oracle", digest: "sha256:rp0"}
				input: {reads: ["subject.normalized_ir", "subject.calibrations"], protocol: "repeat_same_input"}
				output_contract: {repeat_consistent: "bool", divergences: "list"}
				evidence_contract: {repeat_receipts_retained: true}
				failure: "INCOMPLETE"
			},
			// discrimination — invoke a child CM over positive/negative controls; its
			// output is a MeasurementReceipt-shaped contract (the type itself is deferred
			// to #112 slice 2, so it is declared here as a shape descriptor).
			{
				id:   "discrimination"
				kind: "invoke_cm"
				provider: {kind: "cm", id: "control_separation_cm", digest: "sha256:ds0"}
				input: {methodology: #MethodologyRef & {id: "candidate", digest: "sha256:cand"}, reads: ["subject.fixtures", "subject.calibrations"]}
				output_contract: {shape: "measurement_receipt", separates_positive_negative: "bool"}
				evidence_contract: {control_receipts_retained: true}
				failure: "INCOMPLETE"
			},
			// refusal — a semantic-integrity judgment: an LLM provider bound to a digested
			// skill #ArtifactRef, with an evidence contract requiring citations and
			// retained disagreement.
			{
				id:   "refusal"
				kind: "semantic_judgment"
				provider: {kind: "llm", id: "refusal_judge", digest: "sha256:rf0"}
				input: {
					skill: #ArtifactRef & {id: "refusal-rubric", kind: "skill", digest: "sha256:sk0", version: "0.1"}
					reads: ["subject.fixtures", "subject.normalized_ir"]
				}
				output_contract: {refuses_out_of_domain: "bool", refuses_malformed: "bool", false_pass_detected: "bool"}
				evidence_contract: {citations_required: true, disagreement_retained: true}
				failure: "INCOMPLETE"
			},
			// evolution — mechanical, over stable-id / migration / retirement rules.
			{
				id:   "evolution"
				kind: "mechanical"
				provider: {kind: "tool", id: "evolution_rule_checker", digest: "sha256:ev0"}
				input: {reads: ["subject.normalized_ir", "subject.lineage"]}
				output_contract: {stable_ids: "bool", migration_rules_present: "bool", retirement_rules_present: "bool"}
				evidence_contract: {lineage_citations_required: true}
				failure: "FAILED"
			},
		]
	}

	// Measure-only boundary, CUE-enforced. CM0 measures; it does NOT compile (that is
	// the compiler), admit (V), authorize (δ), or repair. Setting any may_* to true
	// alongside measure_only:true fails `cue vet` — the language-level face of
	// OPER-AUTH-001 and tsc-oper.md §1.4/§2.
	boundary: {
		measure_only:  true
		may_compile:   false
		may_admit:     false
		may_authorize: false
		may_repair:    false
		note: "CM0 measures a candidate methodology as an instrument and emits an InstrumentAssessment only. Compilation (compiler), admission (V), authorization (δ), boundary decisions (δ), and repair are distinct authorities; no surface assumes another's."
	}

	// Output: an #InstrumentAssessment (the SHAPE). NO result is computed (no runs):
	// the reported dimensions stay absent, and runtime_binding_status is INCOMPLETE
	// because no CompiledCM is bound. The assessment MEASURES only — it emits no
	// admission verdict and no authorization (enforced: CM0 cannot admit itself).
	output: #InstrumentAssessment & {
		subject:               input
		subcontracts_assessed: ["contract_integrity", "repeatability", "discrimination", "refusal", "evolution"]
	}
}

// cm0_ir — CM0's NORMALIZED IR: the concrete, content-addressed normalization of the
// cm0 #CMSource above. This is what `cue export` of a methodology PROGRAM produces,
// and it validates against #NormalizedCMIR (a closed, fully-concrete contract). It is
// a methodology program ONLY — input_contract / procedure / result_contract /
// receipt_contract — and carries NO measurement receipt (CM0 has no run in 4A). It is
// explicitly NOT a normative #CompiledCM: there is no resolved provider binding, no
// execution plan, and no sandbox policy here (those are the compiler's, deferred).
// compiled/cm0.json is the export of THIS expression.
cm0_ir: #NormalizedCMIR & {
	format:        "tsc-cm-ir/0.1"
	cm_id:         cm0.id
	cm_version:    cm0.version
	// Content address of the cm0 #CMSource (sha256 of its canonical `-e cm0` export).
	source_digest: "sha256:a1b45680fcca5f254ba4d3e204d75fc32d6feef9a7a735d697882da48e9da3dc"

	// The subject contract CM0 consumes: every artifact is a content-addressed
	// #ArtifactRef; normalized_ir is required, compiled is not, and with no compiled
	// bound the runtime binding is INCOMPLETE (NormalizedCMIR ≠ CompiledCM, honestly).
	input_contract: {
		kind: "instrument_subject"
		required_artifacts: [
			{role: "source", kind: "cm_source", required: cm0.input.source.required},
			{role: "normalized_ir", kind: "normalized_cm_ir", required: cm0.input.normalized_ir.required},
			{role: "compiled", kind: "compiled_cm", required: cm0.input.compiled.required},
		]
		artifact_lists: ["implementation_refs", "calibrations", "fixtures", "lineage"]
		runtime_binding: cm0.input.runtime_binding.status
	}

	// The five typed subcontract steps, normalized to (id · kind · provider_kind ·
	// failure). No runs — no results.
	procedure: {
		steps: [for s in cm0.procedure.steps {id: s.id, kind: s.kind, provider_kind: s.provider.kind, failure: s.failure}]
	}

	// Result derivation: declared, deferred to a run (4C). The IR states what the
	// output WILL be and that it emits no admission/authorization/boundary decision.
	result_contract: {
		kind:         "instrument_assessment"
		subcontracts: cm0.output.subcontracts_assessed
		runtime_binding: cm0.output.runtime_binding_status
		emits: {
			admission_verdict: cm0.output.emits_admission_verdict
			authorization:     cm0.output.emits_authorization
			boundary_decision: cm0.output.emits_boundary_decision
		}
		derivation: "deferred to a measurement run (increment 4C); no result computed in the source/IR"
	}

	// The output receipt contract (an InstrumentAssessment shape), measure-only.
	receipt_contract: {
		kind: "instrument_assessment"
		reports: ["parts_present", "relations_fit", "evolution_rules", "repeat_consistency", "discrimination", "refusal_behavior", "calibration_evidence", "defects", "uncertainty"]
		measure_only: cm0.boundary.measure_only
	}
}
