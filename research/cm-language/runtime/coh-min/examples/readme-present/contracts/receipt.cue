// The MeasurementReceipt contract for the coh-min ordinary-CM runtime.
//
// This is the ordinary-CM projection of the shared receipt shape that M1 will
// unify with the Ascent-0 MeasurementReceipt (a separate step; NOT this slice).
// Every receipt coh-min emits must validate against #MeasurementReceipt:
//
//   cue vet receipt.json contracts/receipt.cue -d '#MeasurementReceipt'
//
// The top-level struct and its load-bearing sub-objects are CLOSED, so a stray
// or misspelled field is rejected — the constraint bites. result_class is
// pinned to the CM's closed vocabulary.
package cohminreceipt

#PlanStep: close({
	order:           int & >=0
	step_id:         string
	provider_class:  string
	provider_kind:   string
	kind:            string
	reads: [...string]
	produces:        string
	may_access: [...string]
	search_strength: string
})

#Plan: close({
	cm_id:         string
	cm_version:    string
	source_digest: string
	steps: [...#PlanStep]
})

// What the `file.exists` provider actually observed on disk. This is the proof
// that a REAL provider read the subject: the observation changes with it.
#Observation: close({
	provider_class: string
	relative_path:  string
	checked_path:   string
	exists:         bool
	is_directory:   bool
	size_bytes:     int
})

#Evidence: close({
	step_id:     string
	observation: #Observation
})

#Result: close({
	result_class: "README_PRESENT" | "README_ABSENT" | "INCOMPLETE"
	computed:     bool
	complete:     bool
	rule:         string
	derived_from: [...string]
})

#MeasurementReceipt: close({
	format:        "tsc-measurement-receipt/0.1"
	cm_id:         string
	cm_version:    string
	source_digest: string

	run_request: close({
		target_root: string
		ir_path:     string
	})

	plan_digest:            =~"^sha256:[0-9a-f]{64}$"
	sandbox_execution_plan: #Plan

	execution_trace: [...close({order: int & >=0, step_id: string})]
	skipped_steps: [...close({step_id: string, missing_surfaces: [...string]})]
	evidence: [...#Evidence]

	result: #Result

	// A computed receipt for this CM carries exactly one evidence observation
	// (the single `file.exists` step) and no principled skips; and its class is
	// the concrete outcome, never INCOMPLETE.
	if result.complete {
		result: result_class: "README_PRESENT" | "README_ABSENT"
		skipped_steps: []
		evidence: [#Evidence]
	}
})
