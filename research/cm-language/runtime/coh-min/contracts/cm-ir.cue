// contracts/cm-ir.cue — `tsc-cm-ir/0.2`, the NormalizedCMIR contract.
//
//   cue vet <ir.json> contracts/*.cue -d '#NormalizedCMIR'
//
// Every canonical top-level block is `field!:`, so an IR missing one is refused
// rather than silently unifying to an empty value. The rule-table AST is written
// out in full — the `0.1` schema left the derivation as prose, so there was
// nothing to check; in `0.2` the derivation IS the artifact, and an expression
// naming an operator outside the v0 algebra is rejected here as well as by the
// runtime.
package cohmin

#IRBounds: close({
	wall_time_ms!: int & >0
	output_bytes!: int & >0
})

// Where a step input comes from: a CM subject input, or one named output port
// of another step. These two shapes are the graph's edge set.
#Binding: close({input!: string}) | close({step!: string, output!: string})

#StepInput: close({
	from!:   #Binding
	schema!: string
})

// `required` defaults to true when omitted — withholding must be DECLARED, and
// the safe reading of an unannotated port is that the checker promises it.
#StepOutput: close({
	schema!:   string
	required?: bool
})

// A failure policy maps a checker outcome to fact availability or run status.
// It deliberately cannot name a result class: the `0.1` `failure -> ResultClass`
// shortcut gave one node hidden authority over the CM's verdict.
#Disposition: "fact_unavailable" | "run_failed"

#FailurePolicy: close({
	incomplete!: #Disposition
	refused!:    #Disposition
	failed!:     #Disposition
})

#IRStep: close({
	id!:   string
	// FLAT execution: every step terminates at a primitive provider. The other
	// kinds the design names are not executable here and are refused, not
	// accepted-and-mis-run.
	kind!: "mechanical"
	checker!: close({
		capability!: string
		interface!:  string
	})
	inputs!:  {[string]: #StepInput}
	outputs!: {[string]: #StepOutput}
	// Checker configuration is methodology-owned and portable, and SCALAR-valued
	// in v0. Its per-capability shape is owned by the capability contract and is
	// validated at link time (gate 11) — deliberately not here, because a schema
	// that knew each capability's config would move that ownership into the CM.
	config!: {[string]: #Value}
	evidence!: close({
		schema!:     string
		required!:   bool
		predicates!: [...string]
	})
	capabilities!: close({
		request!: [...string]
	})
	bounds!:         #IRBounds
	failure_policy!: #FailurePolicy
})

// ── the v0 result algebra ────────────────────────────────────────────────
// An operand is a reference object or a scalar literal. An expression carries
// exactly one operator; anything else is refused.

#Operand: #Reference | #Value

#Expr:
	close({and!: [_, ...#Expr] & [...#Expr]}) |
	close({or!: [_, ...#Expr] & [...#Expr]}) |
	close({not!: #Expr}) |
	close({eq!: [#Operand, #Operand]}) |
	close({ne!: [#Operand, #Operand]}) |
	close({lt!: [#Operand, #Operand]}) |
	close({le!: [#Operand, #Operand]}) |
	close({gt!: [#Operand, #Operand]}) |
	close({ge!: [#Operand, #Operand]}) |
	close({present!: #Reference}) |
	close({step_status!: [string, #StepStatus]})

#StepStatus: "success" | "incomplete" | "refused" | "failed" | "skipped"

#ResultRule: close({
	id!:   string
	when!: #Expr
	emit!: string
})

// The terminal clause. It has an id — so a receipt's `rule_id` always names a
// real declared rule, including when the default fires — and no guard, because
// a default that could fail to match would not be a default.
#ResultDefault: close({
	id!:   string
	emit!: string
})

#Obligation: close({
	class!:    string
	requires!: [_, ...string] & [...string]
})

#Result: close({
	classes!:     [_, ...string] & [...string]
	rules!:       [...#ResultRule]
	default!:     #ResultDefault
	obligations!: [...#Obligation]
})

#ReceiptContract: close({
	family!:       string
	schema!:       string
	reports!:      [...string]
	measure_only!: bool
})

#Permissions: close({
	capabilities!: [...string]
	bounds!:       #IRBounds
})

#CMInput: close({
	kind!:     string
	schema!:   string
	required!: bool
})

#NormalizedCMIR: close({
	format!: "tsc-cm-ir/0.2"
	cm!: close({
		id!:            string
		version!:       string
		source_digest!: #Digest
	})
	question!: string
	inputs!:   {[string]: #CMInput}
	// An IR declaring no work and no vocabulary must not validate.
	steps!:       [_, ...#IRStep] & [...#IRStep]
	result!:      #Result
	receipt!:     #ReceiptContract
	permissions!: #Permissions
})
