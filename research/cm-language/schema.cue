// Package cm is the abstract TSC CM model, encoded in CUE as its first concrete
// source language. Increment 1 types every load-bearing element of a composite
// (parent) methodology losslessly, and is general enough that child aspect
// receipts (Structure, Legibility) validate against #ChildReceiptEnvelope in the
// next increment.
//
// The design intent: the deterministic composition — step-6 precedence and the
// status mapping — is DATA (#Methodology.result.precedence + .mapping), not
// prose. A fresh reader can execute the parent result from the compiled JSON
// alone.
package cm

// #ResultClass is the generic composition interface: the only receipt field the
// parent composition algorithm reads to derive its own result. Exactly four
// values. Definitions are carried in #ResultClassDefinitions so the compiled IR
// retains their meaning without embedding prose in every receipt.
#ResultClass: "PASS" | "DEFECT" | "INCOMPLETE" | "FAILED"

// #ResultClassDefinitions carries the four load-bearing definitions, including
// the FAILED/INCOMPLETE boundary. Keyed by #ResultClass so the mapping is total.
#ResultClassDefinitions: {
	PASS:       "The aspect executed fully and found no in-scope defect."
	DEFECT:     "The aspect executed and established at least one in-scope defect."
	INCOMPLETE: "The aspect executed but its observation is incomplete or underdetermined (e.g. inventory or consumer search incomplete, or policy leaves the actionable question unresolved). Boundary: ran but could not fully conclude."
	FAILED:     "The aspect CM could not execute a required mechanical step at all. Boundary: could not run."
}

// #ChildReceiptEnvelope is the generic child receipt interface every aspect CM
// returns. It carries TWO result fields, and the distinction is load-bearing:
//   - result_class is the generic interface the parent composes (one of four).
//   - status preserves the child CM's richer categorical vocabulary, retained
//     verbatim and never collapsed.
// Each child declares its own status_mapping (status -> result_class); because
// the mapping lives in the child, the parent never learns any child's private
// status vocabulary.
#ChildReceiptEnvelope: {
	aspect_id:         string
	cm_version:        string
	profile:           string
	repository_commit: string

	// The generic interface the parent reads.
	result_class: #ResultClass

	// The child's own categorical status, retained verbatim.
	status: string

	// The child's declared status -> result_class mapping. The receipt's own
	// status MUST map to its own result_class: a child receipt whose status does
	// not resolve to its result_class is invalid.
	status_mapping: {[string]: #ResultClass}
	status_mapping: (status): result_class

	scope:               _
	findings:            [...] | {...}
	refusals:            [...] | {...}
	unobserved_surfaces: _
	evidence_refs:       _
}

// #AspectSource is how a parent references a child aspect CM: a registered
// aspect, the source path/package that implements it, and whether it is
// implemented. `selected` marks membership of the composite's selection.
#AspectSource: {
	aspect_id:   string
	source:      string // package/dir ref to the child CM, e.g. "./structure"
	implemented: bool
	selected:    bool | *true
	// A registered-but-unimplemented aspect may be selected to be reported as
	// unimplemented, or left unselected. Nothing else constrains it here.
}

// #Coverage names exactly which aspects a composite claim covers, partitioned so
// every composite claim can name its scope (RCM-COVERAGE-001).
#Coverage: {
	selected: [...string]
	executed: [...string]
	unavailable: [...string] // selected but unimplemented
	failed: [...string] // executed to FAILED
	registered_unselected: [...string]
}

// #CrossAspectRelation is one retained cross-aspect relation for the atlas.
// Retained and surfaced, never averaged (RCM-CONFLICT-001, RCM-NO-AGGREGATE-001).
#CrossAspectRelation: {
	kind: "agreement" | "complement" | "tension" | "gap"
	aspects: [...string]
	note: string
}

// #Continuation (parent γ) compares this composite run to the prior one.
// First composite run carries the BASELINE sentinel.
#Continuation: {
	status: string // "BASELINE — no prior composite receipt" on first run
	improved: [...string]
	regressed: [...string]
	stayed_defective: [...string]
	new_issue: [...string]
}

// #CompositeReceipt is the parent's output shape.
#CompositeReceipt: {
	repository_commit: string
	coverage:          #Coverage

	// Retained child receipts, unchanged, keyed by aspect name.
	child_receipts: {[string]: #ChildReceiptEnvelope}

	// The parent's own categorical status (one of #Methodology.result.statuses).
	composite_status: string

	// γ — continuation.
	continuation: #Continuation

	// β — cross-aspect atlas. In v0.1 surfaced, not gating.
	atlas: [...#CrossAspectRelation]
}

// #ResultComposition makes the deterministic step-6 derivation DATA.
//   - precedence orders #ResultClass from highest-priority to lowest; the parent
//     result is derived from the first precedence class present among children.
//   - mapping projects each #ResultClass onto the parent's own status vocabulary.
//   - statuses is the closed parent status enum.
// A fresh reader executes: walk `precedence`; the first class present among the
// (child result_classes ∪ unavailable→INCOMPLETE ∪ empty-selection→INCOMPLETE)
// yields composite_status = mapping[thatClass].
#ResultComposition: {
	statuses: [...string]
	precedence: [...#ResultClass]
	mapping: {[#ResultClass]: string}
	// mapping is total over the classes named in precedence, and every mapped
	// status is a declared parent status.
	for c in precedence {
		mapping: (c): or(statuses)
	}
}

// #Manifestation (parent α) — execution manifestation and same-snapshot binding.
#Manifestation: {
	same_snapshot_binding: bool | *true // every retained receipt names the one commit
	records: string | *"selected / unimplemented / incomplete children"
}

// #Atlas (parent β) — cross-aspect atlas configuration. In v0.1 non-gating.
#Atlas: {
	gating: bool | *false // v0.1: surfaced, does not gate the parent result
	note:   string | *"Cross-aspect relations surfaced for the reader; not used to gate the parent result in v0.1."
}

// #Invariants carried by a composite methodology.
#Invariants: {
	same_snapshot:         bool | *true
	retain_child_receipts: bool | *true
	allow_scalar_aggregation: bool | *false
}

// #Boundary — measure-only boundary (RCM-BOUNDARY-001).
#Boundary: {
	measure_only: bool | *true
	note:         string | *"Parent and child CMs measure only; repair and independent review remain separate invocations."
}

// #Requirement is one stable RCM-* requirement.
#Requirement: {
	id:   =~"^[A-Z]+(-[A-Z]+)+-[0-9]+$"
	text: string
}

// #Methodology is a composite (parent) CM: it composes aspect receipts on a
// shared commit and retains their conflicts — nothing more.
#Methodology: {
	id:       string
	version:  string
	question: string

	// Typed input signature.
	input: {
		repository_snapshot: string | *"repository_snapshot"
		selected_aspects:    string | *"selected_aspects"
	}

	// Children: map of name -> source ref. General enough that the next increment
	// attaches the actual child #Methodology / receipts here.
	children: {[string]: #AspectSource}

	invariants: #Invariants

	// The generic composition interface's definitions, carried once.
	result_class_definitions: #ResultClassDefinitions

	// Deterministic derivation as DATA.
	result: #ResultComposition

	// Parent α / β / γ.
	manifestation: #Manifestation // α
	atlas:         #Atlas         // β
	// γ is instance data on each receipt; the methodology declares the first-run
	// sentinel it must emit.
	continuation_baseline: string | *"BASELINE — no prior composite receipt"

	boundary: #Boundary

	// The output receipt shape this methodology emits.
	receipt: #CompositeReceipt

	// Reference to the stable RCM-* requirement set.
	requirements: [...#Requirement]

	// What the parent explicitly does not own.
	does_not_own: [...string]
}
