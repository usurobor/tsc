// contracts/sandbox-plan.cue — `tsc-sandbox-plan/0.1`.
//
//   cue vet <plan.json> contracts/*.cue -d '#SandboxExecutionPlan'
//
// The plan is the linker's closed, concrete answer for ONE request: which
// provider was selected, pinned by version and digest; what each input slot was
// bound to; which grants were issued; which limits were imposed; and which
// obligations were discharged before execution was permitted.
//
// Every `discharge` flag is pinned to `true`, not merely typed `bool`. An
// unproved linker obligation refuses linking, so a plan carrying `false` is not
// a plan that ran under weaker proof — it is a document that must never
// execute, and the schema says so rather than leaving it to a reader.
package cohmin

#PlanLimits: close({
	wall_time_ms!: int & >0
	output_bytes!: int & >0
})

#Adapter: close({
	kind!:   "readonly_directory" | "step_output"
	handle!: string
})

#Discharge: close({
	checker_interface!:     true
	input_schemas!:         true
	output_schemas!:        true
	evidence_schema!:       true
	config_schema!:         true
	capability_subset!:     true
	bounds_within_request!: true
})

#PlanStep: close({
	step_id!: string
	provider!: close({
		id!:      string
		version!: string
		digest!:  #Digest
	})
	adapters!:  {[string]: #Adapter}
	grants!:    [...string]
	limits!:    #PlanLimits
	discharge!: #Discharge
})

#SandboxExecutionPlan: close({
	format!:         "tsc-sandbox-plan/0.1"
	request_digest!: #Digest
	cm_ir_digest!:   #Digest
	steps!:          [_, ...#PlanStep] & [...#PlanStep]
})
