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

	// Increment-2 extension S2 (corralled-open). Aspect CMs carry aspect-specific
	// TYPED fields beyond the shared ten (Structure: plane_classification,
	// canonical_path_map, policy_authority; per-finding extras ride the already-open
	// findings list). The shared ten fields above stay CLOSED, so the parent's
	// load-bearing interface keeps full field-name validation — a typo'd
	// `result_clas` or a stray top-level field is REJECTED by `cue vet`. Aspects
	// hang their extensions under this ONE designated open sub-region only. (A bare
	// `...` on the whole envelope was rejected in review precisely because it voided
	// that shape validation on the fields the parent composes.) The parent instance
	// sets no `aspect_ext`, so its exported IR is unchanged.
	aspect_ext?: {...}
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
//
// Increment 4A generalizes the boundary from a single `measure_only` flag to a
// typed authority declaration: a leaf may (or may not) compile, admit, authorize,
// or repair. The four `may_*` fields are OPTIONAL and default-free, so the three
// frozen aspect/parent instances — which set none of them — export byte-identical
// (an added `bool | *false` would have materialized four new keys in every IR).
// A measure-only leaf forbids all four; the constraint BITES — a boundary that
// sets `measure_only: true` alongside any `may_*: true` fails `cue vet`, which is
// the language-level enforcement of OPER-AUTH-001 ("CM0 cannot admit itself") and
// tsc-oper.md §1.4/§2 ("CM0 measures. It does not compile, admit, authorize, or
// decide a boundary action").
#Boundary: {
	measure_only: bool | *true
	note:         string | *"Parent and child CMs measure only; repair and independent review remain separate invocations."

	may_compile?:   bool
	may_admit?:     bool
	may_authorize?: bool
	may_repair?:    bool

	// measure-only ⇒ no action authority. Optional-false constraints: absent on the
	// frozen instances (no export change), conflicting with any `may_*: true`.
	if measure_only {
		may_compile?:   false
		may_admit?:     false
		may_authorize?: false
		may_repair?:    false
	}
}

// #Requirement is one stable RCM-* / STRUCT-* requirement.
#Requirement: {
	id:   =~"^[A-Z]+(-[A-Z]+)+-[0-9]+$"
	text: string
	// Increment-2 extensions (all optional, parent-safe). A leaf CM's requirements
	// each trace to a clause of their governing policy (the ADR), carry a checking
	// `class`, and a default `severity`; the composite's RCM-* requirements omit
	// them. `class` is load-bearing: the leaf Result rule's FAILED clause references
	// "a required MECHANICAL check", so which requirements are mechanical must be in
	// the IR. Absent on the parent → not emitted in its IR (stays byte-identical).
	adr_clause?: string
	class?:      "mechanical" | "semantic" | "mechanical + semantic" | "process"
	severity?:   string
}

// #Methodology is a composite (parent) CM: it composes aspect receipts on a
// shared commit and retains their conflicts — nothing more.
// #Methodology is the COMPOSITE authored form of a CM — one #CMSource role (see the
// increment-4A section below). It is related to #CMSource by DOCUMENTATION, not by
// `&`: embedding #CMSource reorders this struct's exported fields (CUE orders by
// declaration position) and breaks the parent IR's byte-identity, so the type is
// left untouched and the correspondence is recorded as finding G4.
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

// ───────────────────────────────────────────────────────────────────────────
// Leaf / aspect methodology (increment 2).
//
// #Methodology above is COMPOSITE: it derives its result by composing child
// receipts — #ResultComposition walks a precedence over the children's
// result_classes — and emits a #CompositeReceipt. A LEAF (aspect) CM composes no
// children: it runs a PROCEDURE over a repository + policy snapshot and derives
// its own result_class from a Result RULE evaluated on that procedure's output.
// None of `children`, #ResultComposition, #CompositeReceipt, or the parent
// α/β/γ manifestation fields apply to a leaf. #AspectMethodology is that leaf
// shape; it emits a #ChildReceiptEnvelope (the same generic receipt the parent
// composes), so a leaf plugs into a composite unchanged.

// #ProcedureInput is one named, typed input a leaf procedure consumes.
#ProcedureInput: {
	name: string
	role: string // what a fresh executor supplies for it
}

// #ProcedureStep is one ordered, numbered step a fresh executor applies.
// `checks` names the requirement ids the step enforces (may be empty).
#ProcedureStep: {
	n:      int & >0
	action: string
	checks: [...string] | *[]
}

// #ResultRuleClause is one guarded outcome: if `when` holds over the procedure
// output, result_class = `class`. Clauses are ordered highest-precedence first.
#ResultRuleClause: {
	when:  string
	class: #ResultClass
}

// #ResultRule makes a leaf's result derivation DATA — the leaf analog of the
// composite's #ResultComposition. Where the composite walks a precedence over
// CHILD result_classes, a leaf walks guarded CLAUSES over its own procedure
// output. A fresh reader evaluates `clauses` top-to-bottom; the first clause
// whose `when` holds yields result_class = clause.class; if none fires,
// result_class = `otherwise`.
#ResultRule: {
	clauses: [...#ResultRuleClause]
	otherwise: #ResultClass
}

// #Procedure is the executable core of a leaf CM: typed inputs, ordered steps,
// and the result rule — all DATA, so a fresh executor applies it from the
// compiled IR alone.
#Procedure: {
	inputs: [...#ProcedureInput]
	steps: [...#ProcedureStep]
	result: #ResultRule
}

// #RetiredRequirement records a permanently retired requirement id (ids are
// stable and never reused).
#RetiredRequirement: {
	id:   =~"^[A-Z]+(-[A-Z]+)+-[0-9]+$"
	note: string
}

// #AspectMethodology is a leaf (aspect) CM — now a SPECIALIZATION of the generic
// #LeafMethodology (defined in the increment-4A section below): an aspect leaf is
// an ordinary leaf whose target is a git repository and which emits the
// repository-shaped #ChildReceiptEnvelope. Increment 4A adds NO field to the three
// frozen aspect/parent IRs (verified byte-identical); the only additions here are
//   - the git-repository target contract, bound as a HIDDEN field `_target_contract`
//     (a regular `target_contract` would add a key to structure.json / legibility.json
//     — see README finding G2), and
//   - `aspect_id?` (optional; the three instances carry aspect_id on the receipt,
//     not at the top level, so it stays absent from their exports).
// #LeafMethodology is an OPEN base (specializations add their own vocabulary), so
// this specialization keeps every aspect-specific field it had before, unchanged.
#AspectMethodology: #LeafMethodology & {
	// Aspect target: a git repository (finding G2 — hidden to preserve byte-identity).
	_target_contract: #TargetContract & {kind: "git_repository"}

	id:         string
	version:    string
	question:   string // governing claim
	aspect_id?: string
	profile:    string

	// The leaf's own closed status vocabulary and its declared status ->
	// result_class mapping. The status is retained verbatim on every receipt; the
	// parent composition reads only the derived result_class.
	statuses: [...string]
	status_mapping: {[string]: #ResultClass}

	// The generic composition interface's definitions, carried once.
	result_class_definitions: #ResultClassDefinitions

	// The executable procedure + result rule (DATA).
	procedure: #Procedure

	// Measure-only boundary (shared with the composite).
	boundary: #Boundary

	// The stable requirement set this leaf checks (id · claim · adr_clause).
	requirements: [...#Requirement]

	// Permanently retired requirement ids, if any.
	retired_requirements: [...#RetiredRequirement] | *[]

	// The output receipt shape this leaf emits: the generic child envelope,
	// optionally carrying aspect-specific typed extensions.
	receipt: #ChildReceiptEnvelope

	// What the leaf explicitly does not own.
	does_not_own: [...string] | *[]
}

// ───────────────────────────────────────────────────────────────────────────
// GENERIC LEAF BOUNDARY (increment 4A)
//
// Everything ABOVE this line is the repository-coherence specialization settled in
// increments 1–3: #Methodology (composite over git-repository aspects),
// #AspectMethodology (an aspect leaf), #ChildReceiptEnvelope (aspect_id / profile /
// repository_commit). Everything BELOW is the smallest GENERIC leaf abstraction
// beneath it, so a methodology whose target is ANOTHER methodology — CM0 — is an
// ordinary #LeafMethodology, not a special case. The generalization forces nothing
// on the settled layer: it adds only OPTIONAL or HIDDEN fields to the shared/aspect
// shapes, and the three frozen IRs re-export byte-for-byte (the "beneath" proof).
// There is deliberately NO CM0-specific root type — CM0 is `#LeafMethodology & {…}`.

// #ArtifactRef — a content-addressed reference to an artifact. Never an embedded
// copy: a subject names its parts by (id, kind, digest), so CM0 carries references,
// not duplicated child receipts / IRs (AC7).
#ArtifactRef: {
	id:       string
	kind:     string
	digest:   string
	version?: string
}

// #TargetRef — a content-addressed reference to a specific target instance.
#TargetRef: {
	kind:     string
	id:       string
	digest:   string
	version?: string
}

// #MethodologyRef — a reference to a methodology (a target whose kind is a
// methodology, e.g. the candidate CM0 measures).
#MethodologyRef: #ArtifactRef & {kind: "methodology"}

// #TargetContract — the CONTRACT of acceptable targets a leaf measures (distinct
// from #TargetRef, which points at one concrete target). An aspect leaf's is
// {kind: "git_repository"}; CM0's is {kind: "coherence_methodology"}.
#TargetContract: {
	kind: string
	...
}

// #ReceiptEnvelope — the GENERIC receipt interface a leaf emits: the measuring
// methodology, the target measured, the four-value result_class, the leaf's own
// status + status→result_class mapping (self-unified), scope, findings, refusals,
// and evidence references. #ChildReceiptEnvelope (above) is the repository
// SPECIALIZATION of this shape — it carries aspect_id / profile / repository_commit
// in place of methodology / target. The two are related by DOCUMENTATION, not by
// subtyping: `#ChildReceiptEnvelope: #ReceiptEnvelope & {…}` would add methodology /
// target keys to the three frozen child receipts and break byte-identity (finding
// G3), so #ChildReceiptEnvelope is kept as-is and the correspondence is recorded.
#ReceiptEnvelope: {
	methodology:    #MethodologyRef
	target:         #TargetRef
	result_class:   #ResultClass
	status:         string
	status_mapping: {[string]: #ResultClass}
	status_mapping: (status): result_class
	scope:         _
	findings:      [...] | {...}
	refusals:      [...] | {...}
	evidence_refs: _
	...
}

// #ArtifactSlot — one artifact ROLE in an instrument subject. A methodology
// DECLARES its subject contract without a run: at declaration time a slot is
// unbound (`ref: null`); a run binds it to a content-addressed #ArtifactRef. The
// type admits only #ArtifactRef or null, so an embedded copy (a whole child /
// receipt object in place of a ref) fails `cue vet` (AC7). This is the honest
// reconciliation of "each artifact is an #ArtifactRef" with "CM0 has no run": a
// declaration cannot carry a real digest for a target it has not measured, so it
// declares the slot (kind · required) and leaves the ref unbound.
#ArtifactSlot: {
	kind:     string
	required: bool | *true
	ref:      #ArtifactRef | *null
}

// #InstrumentSubject — the subject CM0 measures: a candidate methodology presented
// as content-addressed artifacts. NormalizedCMIR vs CompiledCM is distinguished
// HONESTLY (AC5): `normalized_ir` (this CUE export) is a required slot and grounds
// LANGUAGE-LEVEL contract integrity; `compiled` (the later runtime CompiledCM) is a
// NON-required slot, and until it is bound `runtime_binding.status` is INCOMPLETE.
// The COMPLETE claim is CUE-ENFORCED to require a bound compiled ref, so CM0 cannot
// fabricate runtime completeness from a normalized IR alone.
#InstrumentSubject: {
	source:        #ArtifactSlot & {kind: "cm_source"}
	normalized_ir: #ArtifactSlot & {kind: "normalized_cm_ir"}
	compiled:      #ArtifactSlot & {kind: "compiled_cm", required: false}

	implementation_refs: [...#ArtifactRef] | *[]
	calibrations: [...#ArtifactRef] | *[]
	fixtures: [...#ArtifactRef] | *[]
	lineage: [...#ArtifactRef] | *[]

	standing_scope: {
		declared: string
		...
	}

	// Language-level contract integrity is assessable from the normalized IR alone.
	contract_integrity: "assessable_from_normalized_ir"

	// Runtime binding / execution-plan integrity: INCOMPLETE until a CompiledCM is
	// bound.
	runtime_binding: {
		status: *"INCOMPLETE" | "COMPLETE"
	}

	// Honesty guard (hidden, not exported). `_compiled_bound` tracks whether the
	// compiled slot actually holds a ref; a COMPLETE claim forces it true. So a
	// subject claiming runtime_binding.status "COMPLETE" while its compiled slot is
	// unbound (ref: null) fails `cue vet` (false conflicts with true) — CM0 cannot
	// assert runtime completeness from a normalized IR alone.
	_compiled_bound: compiled.ref != null
	if runtime_binding.status == "COMPLETE" {
		_compiled_bound: true
	}
}

// ── Typed step / provider algebra (increment 4A centerpiece).
//
// The settled leaf's #ProcedureStep (above) carries a free-form `action: string` —
// adequate to DESCRIBE an aspect leaf's six steps, but not an instruction SET a
// second executor could bind and run. CM0 forces the missing algebra: a methodology
// that measures another methodology composes typed, provider-bound steps rather than
// prose. #TypedStep COEXISTS with #ProcedureStep — the three settled examples keep
// #ProcedureStep unchanged (byte-identical), and only #LeafMethodology-family leaves
// (CM0) use #TypedStep. Migrating the settled examples to typed steps is deferred
// (#113 slice E).

// #StepKind — the instruction set. Each kind is a MEASUREMENT move; NONE compiles,
// admits, authorizes, or repairs, so a step of kind "compile"/"authorize" (not in
// this enum) fails `cue vet` (boundary bite).
#StepKind: "mechanical" | "semantic_judgment" | "invoke_cm" | "oracle" | "transform"

// #ProviderRef — a reference to the provider that executes a step (a tool, an LLM,
// a child CM, an oracle). Content-addressable via optional digest.
#ProviderRef: {
	kind:    string
	id:      string
	digest?: string
}

// #TypedStep — one typed, provider-bound step: what KIND of move it is, WHICH
// provider performs it, its input, and the CONTRACTS its output and evidence must
// satisfy. `failure` names the #ResultClass a provider failure maps to. It is a
// step/contract only — NO run, no receipt computed here (4A).
#TypedStep: {
	id:                string
	kind:              #StepKind
	provider:          #ProviderRef
	input:             _
	output_contract:   _
	evidence_contract: _
	failure?:          #ResultClass
}

// #InstrumentAssessment — the OUTPUT shape a methodology-measuring leaf emits
// (tsc-oper.md §1.4). It reports parts present, relations fit, evolution rules,
// repeat consistency, discrimination, refusal behavior, calibration evidence,
// defects, and uncertainty — all OPTIONAL, because 4A computes NO results (no
// runs). It inherits the subject's runtime-binding completeness (AC5). And it
// MEASURES only: `emits_admission_verdict` / `emits_authorization` /
// `emits_boundary_decision` are fixed false, so an assessment claiming to admit or
// authorize fails `cue vet` — the language-level face of OPER-AUTH-001 (CM0 cannot
// admit itself).
#InstrumentAssessment: {
	subject:               #InstrumentSubject
	subcontracts_assessed: [...string]

	parts_present?:        _
	relations_fit?:        _
	evolution_rules?:      _
	repeat_consistency?:   _
	discrimination?:       _
	refusal_behavior?:     _
	calibration_evidence?: _
	defects?: [...]
	uncertainty?: _
	result_class?: #ResultClass
	status?:       string

	runtime_binding_status: subject.runtime_binding.status

	emits_admission_verdict: false
	emits_authorization:     false
	emits_boundary_decision: false
}

// #LeafMethodology — the generic leaf CM: identity, a governing question, the
// accepted-target contract, an input contract, an executable procedure of typed
// steps, a measure-only boundary, and a declared output shape. It is an OPEN base:
// a leaf FAMILY specializes it with its own vocabulary — #AspectMethodology adds
// the status vocabulary / #Procedure / #ChildReceiptEnvelope of a repository
// aspect; CM0 adds an #InstrumentSubject input, provider-bound #CheckSteps, and an
// #InstrumentAssessment output. The base carries no default-valued regular field,
// so specializing it onto the three frozen instances changes no exported byte
// (finding G1). `target_contract`, `input`, `output`, and `receipt` are optional
// at the base: an aspect leaf declares its output via `receipt`; CM0 via `output`.
//
// #LeafMethodology is one AUTHORED FORM of a #CMSource (below) — the pre-normalization
// methodology PROGRAM. It is related to #CMSource by DOCUMENTATION (finding G4): a
// leaf CM PLAYS the #CMSource role, but embedding #CMSource here would reorder the
// aspect leaves' exported fields and break byte-identity, so the settled types stay
// untouched. CM0 — the new artifact with no byte baseline — is authored as an
// explicit `#CMSource & #LeafMethodology`, so the source contract is exercised where
// it costs nothing.
#LeafMethodology: {
	id:       string
	version:  string
	question: string

	// The accepted-target contract (what kind of target this leaf measures).
	target_contract?: #TargetContract

	// The input contract the leaf consumes (CM0: an #InstrumentSubject).
	input?: _

	// The executable procedure. Open: an aspect narrows this to #Procedure
	// (inputs · steps · #ResultRule); CM0 uses provider-bound #CheckSteps.
	procedure: {
		steps: [...]
		...
	}

	// Measure-only boundary.
	boundary: #Boundary

	// The declared OUTPUT shape (CM0: an #InstrumentAssessment).
	output?: _

	// A concrete emitted receipt instance, when the leaf has a frozen run (aspect
	// leaves carry one; CM0 has no run in 4A, so it declares `output` only).
	receipt?: _

	// Open base — specializations add their own fields.
	...
}

// #CMSource — the AUTHORED methodology PROGRAM, before normalization: identity,
// imports / defaults / profiles, symbolic provider and child references,
// requirements, a procedure declaration, a result derivation, a receipt contract,
// and permissions. This is the role #Methodology (composite), #LeafMethodology, and
// #AspectMethodology already play; #CMSource is the explicit NAME for it. It is an
// OPEN base — every field but id/version is optional. The settled types are related
// to it by DOCUMENTATION rather than by `&` (finding G4): embedding #CMSource into
// them reorders their exported fields (CUE orders by declaration position) and
// breaks the byte-identity gate, so they stay untouched, while CM0 is authored as an
// explicit `#CMSource & #LeafMethodology`. #CMSource is DISTINCT from #NormalizedCMIR
// below: source is authored (may carry symbols/expressions/defaults); the IR is the
// concrete, content-addressed normalized form.
#CMSource: {
	id:      string
	version: string

	question?: string
	imports?: [...string]
	defaults?: {...}
	profiles?: [...string]

	// Symbolic references (resolved at normalization).
	provider_refs?: [...(#MethodologyRef | #ArtifactRef | string)]
	child_refs?: [...(#MethodologyRef | string)]

	requirements?: [...#Requirement]

	// Declarations the compiler later normalizes.
	procedure?: {...}
	result?: {...}
	receipt_contract?: {...}

	// Declared permissions / resource envelope.
	permissions?: {...}

	// Open — an authored CM carries its family's own vocabulary.
	...
}

// #NormalizedCMIR — the CONCRETE contract for the normalized JSON emitted from a
// #CMSource (what `cue export` of a methodology PROGRAM produces). It is closed and
// every required value is concrete and content-addressed: NOT a CUE expression, NOT
// an unresolved symbol. It is a methodology PROGRAM only — input_contract /
// procedure / result_contract / receipt_contract — and carries NO measurement
// receipt. This names what the CUE export IS: a normalized IR, explicitly NOT a
// normative `#CompiledCM` (the later runtime descriptor with resolved provider
// bindings, execution plan, and sandbox policy — absent here). CM0, which has no run
// in 4A, is the first clean carrier of this source→IR separation: `compiled/cm0.json`
// validates against #NormalizedCMIR (finding G5).
#NormalizedCMIR: close({
	format:        "tsc-cm-ir/0.1"
	cm_id:         string
	cm_version:    string
	source_digest: string

	input_contract: {
		kind: string
		...
	}
	procedure: {
		steps: [...]
		...
	}
	result_contract: {
		...
	}
	receipt_contract: {
		kind: string
		...
	}

	// A normalized IR MAY declare the permissions/resource envelope it was normalized
	// with; still no runtime bindings (those are #CompiledCM's, deferred).
	permissions?: {...}
})

// ───────────────────────────────────────────────────────────────────────────
// METHODOLOGY-SOURCE CONTRACTS (#112 slice 2 — minimal kernel)
//
// #Methodology and #AspectMethodology each mandate a CONCRETE `receipt` — the
// composed/run contract, satisfied only AFTER a measurement run produces a
// receipt. But the `.cm` surface today emits a methodology-ONLY projection (the
// authored program, no run, no receipt). Vetting that projection against the full
// #Methodology / #AspectMethodology therefore reports the receipt fields
// incomplete — not an emitter defect, just projection-vs-composed-contract.
//
// #MethodologySource / #AspectMethodologySource are the DIRECT contract for that
// methodology-only projection: the SAME load-bearing fields, with `receipt` made
// OPTIONAL so a projection that omits it vets directly (`cue vet <projection>
// schema.cue -d '#MethodologySource'` → 0). They are STANDALONE ADDITIVE
// definitions — never exported, so they touch no `compiled/*.json` byte — and they
// are DELIBERATELY NOT built by embedding/refactoring #Methodology /
// #AspectMethodology, because embedding a shared base reorders those structs'
// exported fields and breaks the four IRs' byte-identity (finding G4). They mirror
// the composed contracts field-for-field and stay CLOSED, so a typo'd or stray
// field is still rejected — the constraint bites, it is not a bare `{...}` escape.
//
// This is the KERNEL of slice 2 only: it does NOT introduce the full
// #RunRequest / #MeasurementReceipt separation (still FUTURE, #112). The full
// #Methodology / #AspectMethodology remain the composed/run contract, satisfied
// once a run binds a concrete receipt.

// #MethodologySource — the composite (parent) methodology-only projection: every
// #Methodology field, with `receipt` OPTIONAL. Closed: the composite projection
// carries exactly these fields (minus its absent, run-only receipt).
#MethodologySource: {
	id:       string
	version:  string
	question: string

	// Typed input signature (mirrors #Methodology).
	input: {
		repository_snapshot: string | *"repository_snapshot"
		selected_aspects:    string | *"selected_aspects"
	}

	// Children: map of name -> source ref.
	children: {[string]: #AspectSource}

	invariants: #Invariants

	// The generic composition interface's definitions, carried once.
	result_class_definitions: #ResultClassDefinitions

	// Deterministic derivation as DATA.
	result: #ResultComposition

	// Parent α / β / γ.
	manifestation:         #Manifestation
	atlas:                 #Atlas
	continuation_baseline: string | *"BASELINE — no prior composite receipt"

	boundary: #Boundary

	// The composed/run output receipt — OPTIONAL here (a methodology-only
	// projection omits it; a run binds it, satisfying the full #Methodology).
	receipt?: #CompositeReceipt

	// Reference to the stable RCM-* requirement set.
	requirements: [...#Requirement]

	// What the parent explicitly does not own.
	does_not_own: [...string]
}

// #AspectMethodologySource — the aspect (leaf) methodology-only projection: every
// #AspectMethodology field, with `receipt` (and the top-level `aspect_id`, which
// the frozen aspects carry on the receipt, not here) OPTIONAL. Closed: the aspect
// projection carries exactly these fields (minus its absent, run-only receipt).
#AspectMethodologySource: {
	// Aspect target: a git repository (hidden, mirrors #AspectMethodology's
	// finding-G2 field; never exported, never required of the projection JSON).
	_target_contract: #TargetContract & {kind: "git_repository"}

	id:         string
	version:    string
	question:   string // governing claim
	aspect_id?: string
	profile:    string

	// The leaf's own closed status vocabulary and its status -> result_class mapping.
	statuses: [...string]
	status_mapping: {[string]: #ResultClass}

	// The generic composition interface's definitions, carried once.
	result_class_definitions: #ResultClassDefinitions

	// The executable procedure + result rule (DATA).
	procedure: #Procedure

	// Measure-only boundary.
	boundary: #Boundary

	// The stable requirement set this leaf checks.
	requirements: [...#Requirement]

	// Permanently retired requirement ids, if any.
	retired_requirements: [...#RetiredRequirement] | *[]

	// The composed/run child receipt — OPTIONAL here (a methodology-only
	// projection omits it; a run binds it, satisfying the full #AspectMethodology).
	receipt?: #ChildReceiptEnvelope

	// What the leaf explicitly does not own.
	does_not_own: [...string] | *[]
}
