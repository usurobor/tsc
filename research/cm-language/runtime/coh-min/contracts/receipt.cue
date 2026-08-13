// contracts/receipt.cue — `tsc-measurement-receipt/0.2`.
//
//   cue vet <receipt.json> contracts/*.cue -d '#MeasurementReceipt'
//
// ONE CLOSED CORE PLUS ONE CLOSED, DISCRIMINATED FAMILY EXTENSION — not a bag
// of optional blocks. Every core block is required. Family-specific evidence
// lives in exactly one `extension`, whose `family` selects a closed schema; a
// core full of optional blocks would make "is this receipt complete?"
// unanswerable, because absence would never be distinguishable from
// inapplicability.
//
// The version is `0.2`, not `0.1`. `tsc-measurement-receipt/0.1` is owned on
// `main` by the shipped coh-min receipt, whose core (`cm_id` / `source_digest` /
// `plan_digest` / `sandbox_execution_plan` / `execution_trace` /
// `skipped_steps`) is structurally incompatible with the one below. Reusing the
// string would assert a false compatibility and destroy `format` as a verifier
// discriminator.
//
// TWO DISCRIMINATIONS DO REAL WORK HERE:
//
//   1. A trace entry's `status` selects its shape. ONLY `success` may populate
//      output ports or withhold them; `skipped` MUST name the unpublished port
//      that caused it and MUST publish nothing. So "a skipped step reported a
//      fact" and "a skip with no stated cause" are both unrepresentable.
//   2. `available` selects whether a fact reference or a report carries a value.
//      An unavailable fact carries no `value` field at all, so a reader can
//      never mistake a defaulted zero for a measured one.
package cohmin

#ProviderRef: close({
	id!:     string
	digest!: #Digest
})

#PublishedPort: close({
	port!:   string
	value!:  #Value
	digest!: #Digest
})

// A checker that SUCCEEDED: it may publish declared ports, and may lawfully
// withhold the ones its capability does not promise.
#TraceSuccess: close({
	order!:       int & >=0
	step_id!:     string
	status!:      "success"
	provider!:    #ProviderRef
	published!:   [...#PublishedPort]
	withheld!:    [...string]
	diagnostics!: [...string]
})

// A checker that ran and did not establish its fact. Nothing is published, and
// nothing was WITHHELD either: the status is the whole story.
#TraceUnproductive: close({
	order!:       int & >=0
	step_id!:     string
	status!:      "incomplete" | "refused" | "failed"
	provider!:    #ProviderRef
	published!:   []
	withheld!:    []
	diagnostics!: [...string]
})

// A step that never became ready. `skipped_because` is REQUIRED: a principled
// skip that does not name the unpublished port it waited on is not principled.
#TraceSkipped: close({
	order!:           int & >=0
	step_id!:         string
	status!:          "skipped"
	provider!:        #ProviderRef
	published!:       []
	withheld!:        []
	diagnostics!:     []
	skipped_because!: string
})

#TraceEntry: #TraceSuccess | #TraceUnproductive | #TraceSkipped

#EvidencePredicate: close({
	name!:   string
	value!:  #Value
	digest!: #Digest
})

#EvidenceRecord: close({
	step_id!:    string
	schema!:     string
	digest!:     #Digest
	predicates!: [_, ...#EvidencePredicate] & [...#EvidencePredicate]
})

// One reference the evaluator read, with what it resolved to. This is the
// derivation witness: a verifier replays the rule from these alone.
#FactRef:
	close({
		ref!:       string
		kind!:      #ReferenceKind
		available!: true
		value!:     #Value
		digest!:    #Digest
	}) |
	close({
		ref!:       string
		kind!:      #ReferenceKind
		available!: false
	})

#ResultBlock: close({
	class!:      string
	rule_id!:    string
	fact_refs!:  [...#FactRef]
})

#ObligationRecord: close({
	class!:       string
	requirement!: string
	discharged!:  bool
	note!:        string
})

#Report:
	close({
		ref!:       string
		kind!:      #ReferenceKind
		available!: true
		value!:     #Value
		digest!:    #Digest
	}) |
	close({
		ref!:       string
		kind!:      #ReferenceKind
		available!: false
		reason!:    string
	})

#SubjectRecord: close({
	name!:            string
	kind!:            "directory_snapshot"
	scheme!:          #SnapshotScheme
	digest!:          #Digest
	manifest_digest!: #Digest
})

// The one receipt family v0 defines. `family` and `schema` are pinned together,
// so an extension cannot claim a family while carrying another family's schema.
#RepositoryMeasurement: close({
	family!: "repository_measurement"
	schema!: "tsc://receipt/repository-measurement/0.1"
	value!: close({
		question!:     string
		measure_only!: bool
		subject!:      [_, ...#SubjectRecord] & [...#SubjectRecord]
		reports!:      [...#Report]
	})
})

#Extension: #RepositoryMeasurement

#MeasurementReceipt: close({
	format!:       "tsc-measurement-receipt/0.2"
	execution_id!: =~"^exec:[0-9a-f]{64}$"
	request!:      close({digest!: #Digest})
	cm_ir!:        close({digest!: #Digest})
	plan!:         close({digest!: #Digest})
	runtime!: close({
		id!:      string
		version!: string
		digest!:  #Digest
	})
	// A receipt that records no step outcome witnesses nothing.
	trace!:       [_, ...#TraceEntry] & [...#TraceEntry]
	evidence!:    [...#EvidenceRecord]
	result!:      #ResultBlock
	obligations!: [...#ObligationRecord]
	extension!:   #Extension
})
