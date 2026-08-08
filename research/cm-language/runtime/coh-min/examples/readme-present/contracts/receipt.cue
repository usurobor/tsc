// The MeasurementReceipt contract for the coh-min ordinary-CM runtime.
//
// This is the ordinary-CM projection of the shared receipt shape that M1 will
// unify with the Ascent-0 MeasurementReceipt. Every receipt coh-min emits must
// validate against #MeasurementReceipt:
//
//   cue vet receipt.json contracts/receipt.cue -d '#MeasurementReceipt'

#PlanStep: {
	order:           int & >=0
	step_id:         string
	provider_class:  string
	provider_kind:   string
	kind:            string
	reads: [...string]
	produces:        string
	may_access: [...string]
	search_strength: string
}

#Plan: {
	cm_id:         string
	cm_version:    string
	source_digest: string
	steps: [...#PlanStep]
}

#Observation: {
	provider_class: string
	relative_path:  string
	checked_path:   string
	exists:         bool
	is_directory:   bool
	size_bytes:     int
}

#Evidence: {
	step_id:     string
	observation: #Observation
}

#Result: {
	result_class: "README_PRESENT" | "README_ABSENT" | "INCOMPLETE"
	computed:     bool
	complete:     bool
	rule:         string
	derived_from: [...string]
}

#MeasurementReceipt: {
	format:        "tsc-measurement-receipt/0.1"
	cm_id:         string
	cm_version:    string
	source_digest: string
	run_request: {
		target_root: string
		ir_path:     string
	}
	plan_digest:            string
	sandbox_execution_plan: #Plan
	execution_trace: [...{order: int, step_id: string}]
	skipped_steps: [...{step_id: string, missing_surfaces: [...string]}]
	evidence: [...#Evidence]
	result: #Result
}
