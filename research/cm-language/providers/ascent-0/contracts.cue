// Package ascent0providers types the GENERATIVE PROVIDER CONTRACTS for the
// Ascent-0 slice (#120, under #118 -> #117): the seam between the compiled CM
// and the runtime (Sub 3). It is TYPED CONTRACTS ONLY — no provider is
// implemented here, no IR is executed. It references the Sub-1 frozen fixture
// (research/ascent/fixtures/ascent-0/) by naming the Core (#116) fields each
// provider produces; it does not read or edit that fixture, the frozen engine,
// or research/cm-language/schema.cue (whose #Boundary / enum / closed-struct /
// negative-probe idioms it mirrors so its own negative fixtures bite via
// `cue vet`).
//
// TWO FIREWALLS ARE TYPE-ENFORCED HERE, not merely documented:
//
//   Firewall A (invariant 2, #118 — frozen H_M / LLM never warrants).
//     The one semantic/generative provider returns a PROPOSAL (#CompiledView) and
//     nothing else. #CompiledView is a CLOSED struct of exactly five fields, so a
//     semantic instance carrying any warrant-bearing field (a result_class /
//     LIFT_VALIDATED / held-out prediction / equivalence) or any field that
//     sets/expands H_M, alphabets, bounds, equivalence, search-completeness, or
//     the held-out boundary is rejected by `cue vet` (field not allowed). Its
//     declared inputs are narrowed to the three leak-free surfaces, so it cannot
//     even name H_M as an input.
//
//   Firewall B (invariant 3, #118 — no-oracle-leak / sealed oracle).
//     The sealed oracle surfaces are a typed set (#OracleSurface). Every provider
//     declares may_access / may_not_access over #HiddenSurface. For every provider
//     whose class is not "oracle", the may_access element type is narrowed to
//     #RestrictedSurface (oracle surfaces excluded), so a semantic or FiniteModel
//     provider that lists an oracle surface in may_access is rejected by `cue vet`.
//     Only Oracle.revealAndCompare is cleared to reach oracle surfaces.
//
// The mechanical providers OWN THE WARRANT: each names the Core (#116) field it
// produces, and a warrant claim (LIFT_VALIDATED / NO_REALIZATION_IN_MODEL / ...)
// is a type error unless the provider can source its backing evidence — so a
// Descent.predict output claiming "validated" without the oracle outcome fails.
package ascent0providers

// ───────────────────────────────────────────────────────────────────────────
// Core (#116) vocabulary — the frozen result classes and the IR obligations
// each mechanical provider must name. These mirror the Sub-1 fixture's
// generated/**/public.json `core_ir` block and README §3 result rule; they are
// referenced, never redefined against, the fixture.

// #ResultClass — the Core-faithful result vocabulary (#118, README §3). NOT to
// be collapsed: empty-fiber-after-complete-search (NO_REALIZATION_IN_MODEL) is
// distinct from uncertainty (UNRESOLVED, incomplete search).
#ResultClass:
	"LIFT_VALIDATED" |
	"ASCENT_UNDERDETERMINED" |
	"NO_REALIZATION_IN_MODEL" |
	"IDENTIFIED_IN_MODEL" |
	"DECORATIVE_LIFT" |
	"UNRESOLVED"

// #CoreField — the #116 IR obligations a mechanical provider's output/evidence
// must name (the Sub-1 `core_ir` keys). A mechanical provider maps each Core
// field it produces to the concrete public.json field that carries it.
#CoreField:
	"H_M" |
	"SearchClaim" |
	"joint_realization" |
	"equivalence" |
	"L_M" |
	"K_M" |
	"J_train" |
	"J_eval" |
	"oracle" |
	"candidate_fiber" |
	"empty_or_unresolved_set"

// ───────────────────────────────────────────────────────────────────────────
// Hidden surfaces (Firewall B). The sealed oracle surfaces are a typed set;
// only Oracle.revealAndCompare may list them in may_access.

// #OracleSurface — the SEALED surfaces (invariant 3): the hidden ground-truth
// generator, the whole reveal bundle, and the held-out output BEFORE reveal.
// Reachable only by the oracle provider.
// - "oracle_reveal": the whole reveal/<case>.json bundle.
// - "hidden_machine": the sealed ground-truth generator W.
// - "heldout_output_pre_reveal": W(q*) before every candidate prediction is frozen.
#OracleSurface:
	"oracle_reveal" |
	"hidden_machine" |
	"heldout_output_pre_reveal"

// #RestrictedSurface — non-oracle restricted surfaces. The held-out INPUT query
// is public once prediction begins (invariant 3), so a prediction provider may
// access it; it is not sealed. Kept as a distinct, non-empty set so the
// may_access narrowing for non-oracle providers bites against oracle surfaces.
// - "heldout_input_query": q* — public at prediction time, NOT sealed.
#RestrictedSurface:
	"heldout_input_query"

// #HiddenSurface — every restricted/sealed surface the runtime knows about.
#HiddenSurface: #OracleSurface | #RestrictedSurface

// ───────────────────────────────────────────────────────────────────────────
// Warrant algebra (mechanical providers OWN the warrant).

// #Backing — the evidence a warrant rests on. Closed, all-false by default; a
// provider sets true only what it can source. Keyed so a warrant that requires a
// backing the provider cannot source conflicts (true vs false).
#Backing: close({
	complete_search:     bool | *false // FiniteModel.enumerate SearchClaim = complete_within_bound
	exact_fit_partition: bool | *false // Realization.fit — L_M exact-fit partition
	equivalence_fiber:   bool | *false // Realization.quotient — F_id over the equivalence
	heldout_prediction:  bool | *false // Descent.predict — frozen predictions on q*
	oracle_outcome:      bool | *false // Oracle.revealAndCompare — reveal/verify/partition
})

// #Warrant — a warrant-bearing result and the backing it REQUIRES. The required
// backing is DATA per result class; a warrant whose provider cannot source that
// backing fails `cue vet` (see #MechanicalOutput). DECORATIVE_LIFT and UNRESOLVED
// carry no positive backing requirement (a refusal / an incomplete search).
#Warrant: {
	result_class: #ResultClass
	backed_by:    #Backing

	if result_class == "LIFT_VALIDATED" {
		// held-out prediction survived the sealed oracle and the tested fiber
		// collapsed under the declared equivalence (README §3).
		backed_by: {heldout_prediction: true, oracle_outcome: true, equivalence_fiber: true}
	}
	if result_class == "NO_REALIZATION_IN_MODEL" {
		// complete bounded search + empty exact-fit set (never uncertainty).
		backed_by: {complete_search: true, exact_fit_partition: true}
	}
	if result_class == "ASCENT_UNDERDETERMINED" {
		// complete search retains >= 2 inequivalent classes.
		backed_by: {complete_search: true, equivalence_fiber: true}
	}
	if result_class == "IDENTIFIED_IN_MODEL" {
		// complete search collapses to a single equivalence class.
		backed_by: {complete_search: true, equivalence_fiber: true}
	}
}

// ───────────────────────────────────────────────────────────────────────────
// Declared-input surfaces.

// #InputSurface — everything a provider may declare as input. The semantic
// provider is narrowed to #SemanticInputSurface below. Legend:
//   one_pov_behavior_primary_viewpoint  the single behavior-primary POV
//   training_traces                     the observed input/response pairs
//   public_methodology_contract         H_M/bounds/equivalence AS CONTRACT (read-only, not owned)
//   H_M_declaration                     the frozen enumerable class declaration
//   search_bounds                       (N, |Sigma|, |Gamma|)
//   enumerated_class                    FiniteModel.enumerate output
//   fit_candidate_set                   Realization.fit output (C_train)
//   equivalence_relation                the declared behavioral equivalence
//   heldout_input_query                 q* (public at prediction time)
//   candidate_predictions               Descent.predict output
//   oracle_commitment                   the public commit digest
//   oracle_reveal_bundle                the sealed reveal (oracle only)
//   descent_evidence                    folded (q*, W(q*)) for round-trip
#InputSurface:
	"one_pov_behavior_primary_viewpoint" |
	"training_traces" |
	"public_methodology_contract" |
	"H_M_declaration" |
	"search_bounds" |
	"enumerated_class" |
	"fit_candidate_set" |
	"equivalence_relation" |
	"heldout_input_query" |
	"candidate_predictions" |
	"oracle_commitment" |
	"oracle_reveal_bundle" |
	"descent_evidence"

// #SemanticInputSurface — the ONLY inputs the one semantic call may declare
// (invariant 1 & 2): the one-POV behavior-primary viewpoint + training traces +
// the PUBLIC methodology contract. It may NOT declare H_M_declaration,
// search_bounds, the equivalence relation, or any oracle surface as input, so it
// cannot see (let alone own) H_M.
#SemanticInputSurface:
	"one_pov_behavior_primary_viewpoint" |
	"training_traces" |
	"public_methodology_contract"

// ───────────────────────────────────────────────────────────────────────────
// Per-provider declared fields shared by all contracts.

#ProviderClass:
	"semantic" |
	"finite_model" |
	"realization_fit" |
	"realization_quotient" |
	"descent" |
	"oracle" |
	"roundtrip"

#ProviderKind: "generative" | "mechanical"

// #SearchStrength — first-class (AC6). FiniteModel declares complete_within_bound;
// the semantic provider declares sampled (and its repeatability, below). Legend:
//   complete_within_bound  exhaustive bounded enumeration over H_M
//   exact                  a deterministic mechanical computation
//   sampled                a stochastic generative draw (the LLM)
//   none                   no search performed
#SearchStrength:
	"complete_within_bound" |
	"exact" |
	"sampled" |
	"none"

// #Determinism — determinism / repeatability, first-class (AC6). The semantic
// provider MUST declare its sampling so CM0 can later assess it.
#Determinism: {
	deterministic: bool
	repeatability: "exact" | "distributional" | "single_shot"
	sampling?: {
		temperature?: number
		n_samples?:   int & >0
		selection?:   string
		...
	}
}

// #FailureBehavior — what a provider failure maps to. A mechanical failure maps
// to a #ResultClass (e.g. an incomplete search -> UNRESOLVED); a semantic refusal
// is a REFUSAL (never a warrant).
#FailureBehavior: {
	on_failure: #ResultClass | "REFUSAL"
	note?:      string
}

// #Evidence — the evidence a provider emits: the Core (#116) fields it produces
// AND the concrete Sub-1 public.json field(s) that carry each (AC4 fixture
// binding). For the semantic provider this is empty — a proposal carries no
// warrant evidence.
#Evidence: {
	core_fields: [...#CoreField]
	fixture_fields: [...string]
}

// #MechanicalOutput — a warrant-bearing output. `core_fields_produced` names the
// #116 fields (AC4). `warrant` is OPTIONAL; when present it may only rely on
// backing this provider can source (`_can_back`), so a warrant requiring a
// backing outside `_can_back` fails `cue vet` (true vs false). This is why
// Descent.predict cannot emit LIFT_VALIDATED (no oracle_outcome) and why the
// semantic provider — which has no #MechanicalOutput at all — cannot emit any
// warrant.
#MechanicalOutput: {
	// Which backings this provider is CAPABLE of sourcing. Set per provider.
	_can_back: #Backing

	core_fields_produced: [...#CoreField]

	warrant?: #Warrant & {
		backed_by: {
			for k, v in _can_back if !v {(k): false}
		}
	}

	// The produced object (fiber / partition / predictions). Opaque at the
	// contract layer — the Sub-3 runtime fills it; typed as a proposal-free
	// mechanical payload here.
	payload?: {...}
}

// #ProviderContract — the shared shape EVERY Ascent-0 provider declares:
// input · output · capabilities · evidence · failure · search_strength ·
// determinism/repeatability · may_access / may_not_access.
//
// Firewall B lives here: `_oracle_cleared` is true iff the provider class is
// "oracle"; for every other provider the may_access element type is narrowed to
// #RestrictedSurface, so an oracle surface in a non-oracle may_access is
// rejected by `cue vet`.
#ProviderContract: {
	id:             string
	provider_class: #ProviderClass
	kind:           #ProviderKind
	title:          string
	description:    string

	input: [...#InputSurface]
	output: _
	capabilities: [...string]
	evidence:        #Evidence
	failure:         #FailureBehavior
	search_strength: #SearchStrength
	determinism:     #Determinism

	may_access: [...#HiddenSurface]
	may_not_access: [...#HiddenSurface]

	// Firewall A face (semantic-only): fixed FALSE by #SemanticProvider. Optional
	// here so the shared base stays closed for every other field; a semantic
	// contract that flips either to true fails `cue vet`.
	owns_H_M?:      bool
	emits_warrant?: bool

	// Firewall B (invariant 3): only the oracle provider is cleared for oracle
	// surfaces. For everyone else, may_access is narrowed to exclude them.
	_oracle_cleared: bool
	_oracle_cleared: provider_class == "oracle"
	if !_oracle_cleared {
		may_access: [...#RestrictedSurface]
	}
}

// ───────────────────────────────────────────────────────────────────────────
// THE SEMANTIC / GENERATIVE PROVIDER (one call, not four).

// #CompiledView — the single typed result of the one semantic judgment. CLOSED
// to exactly these five fields (Firewall A): it is a PROPOSAL — a governing
// question, the local claims it preserves, the closure assumption it withdraws,
// the polar view it derives, and the obstruction it names. It carries NO
// result_class, NO held-out prediction, NO equivalence verdict, NO H_M / bounds /
// alphabet / search-completeness / held-out-boundary field. Any such field is
// rejected by `cue vet` as "field not allowed".
#CompiledView: close({
	governing_question: string
	preserved_local_claims: [...string]
	closure_assumption: string
	polar_view:         string
	named_obstruction:  string
})

// #SemanticProvider — the ONE generative invocation. compileView / unclose /
// polarize / nameObstruction are conceptual PHASES of this single judgment, NOT
// four calls (AC1). Its inputs are exactly the three leak-free surfaces; its
// output is exactly a #CompiledView proposal; it owns no H_M and emits no
// warrant, and both facts are fixed here (owns_H_M / emits_warrant : false), so a
// contract claiming otherwise fails `cue vet`.
#SemanticProvider: #ProviderContract & {
	provider_class: "semantic"
	kind:           "generative"

	// Firewall A, structural: inputs narrowed to the three leak-free surfaces.
	input: [...#SemanticInputSurface]

	// Firewall A, structural: the output is exactly a closed proposal.
	output: #CompiledView

	// A proposal carries no warrant evidence.
	evidence: {core_fields: [], fixture_fields: []}

	// Firewall A, declared: fixed FALSE — a semantic contract that flips either
	// to true fails `cue vet` (mirrors schema.cue #InstrumentAssessment's fixed
	// emits_admission_verdict:false).
	owns_H_M:      false
	emits_warrant: false

	// The generative draw is stochastic; it MUST declare its repeatability (AC6)
	// so CM0 can later assess sampling stability.
	search_strength: "sampled"
	determinism: {
		deterministic: false
		repeatability: "distributional"
	}

	// It reaches NO hidden surface at all (not even the public q*): it works from
	// the leak-free POV + traces + public contract.
	may_access: []
}

// ───────────────────────────────────────────────────────────────────────────
// THE SIX MECHANICAL PROVIDERS (own the warrant). Each maps its output/evidence
// to the Sub-1 `core_ir` fields it produces.

// #FiniteModelEnumerate — complete bounded enumeration over H_M. Declares
// search_strength complete_within_bound (AC6). Produces H_M + SearchClaim. Reads
// only H_M + bounds; NEVER the oracle (Firewall B).
#FiniteModelEnumerate: #ProviderContract & {
	provider_class: "finite_model"
	kind:           "mechanical"
	input: ["H_M_declaration", "search_bounds"]
	search_strength: "complete_within_bound"
	determinism: {deterministic: true, repeatability: "exact"}
	output: #MechanicalOutput & {
		_can_back: {complete_search: true}
		core_fields_produced: ["H_M", "SearchClaim"]
	}
	evidence: {
		core_fields: ["H_M", "SearchClaim"]
		fixture_fields: ["class.json", "complete_candidate_set_size", "core_ir.SearchClaim"]
	}
	failure: {on_failure: "UNRESOLVED", note: "enumeration exceeded the declared bound -> incomplete search"}
	may_access: []
	may_not_access: ["oracle_reveal", "hidden_machine", "heldout_output_pre_reveal"]
}

// #RealizationFit — training-evidence partition (L_M): the exact-fit set C_train
// over the enumerated class. Produces L_M + candidate_fiber + empty/unresolved
// set; carries the completeness it fit over, so it alone may emit
// NO_REALIZATION_IN_MODEL (complete search + empty fit).
#RealizationFit: #ProviderContract & {
	provider_class: "realization_fit"
	kind:           "mechanical"
	input: ["enumerated_class", "training_traces"]
	search_strength: "exact"
	determinism: {deterministic: true, repeatability: "exact"}
	output: #MechanicalOutput & {
		_can_back: {complete_search: true, exact_fit_partition: true}
		core_fields_produced: ["L_M", "J_train", "candidate_fiber", "empty_or_unresolved_set"]
	}
	evidence: {
		core_fields: ["L_M", "J_train", "candidate_fiber", "empty_or_unresolved_set"]
		fixture_fields: ["core_ir.L_M", "core_ir.J_train", "candidate_fiber_over_U", "core_ir.empty_or_unresolved_set"]
	}
	failure: {on_failure: "UNRESOLVED"}
	may_access: []
	may_not_access: ["oracle_reveal", "hidden_machine", "heldout_output_pre_reveal"]
}

// #RealizationQuotient — the equivalence-class fiber F_id = C_train / ~ (K_M-aware).
// Produces equivalence + K_M + candidate_fiber; may emit ASCENT_UNDERDETERMINED
// (>= 2 classes) or IDENTIFIED_IN_MODEL (1 class).
#RealizationQuotient: #ProviderContract & {
	provider_class: "realization_quotient"
	kind:           "mechanical"
	input: ["fit_candidate_set", "equivalence_relation"]
	search_strength: "exact"
	determinism: {deterministic: true, repeatability: "exact"}
	output: #MechanicalOutput & {
		_can_back: {complete_search: true, exact_fit_partition: true, equivalence_fiber: true}
		core_fields_produced: ["equivalence", "K_M", "candidate_fiber", "J_eval"]
	}
	evidence: {
		core_fields: ["equivalence", "K_M", "candidate_fiber", "J_eval"]
		fixture_fields: ["core_ir.equivalence", "core_ir.K_M", "training_identification_fiber_over_U", "core_ir.J_eval"]
	}
	failure: {on_failure: "UNRESOLVED"}
	may_access: []
	may_not_access: ["oracle_reveal", "hidden_machine", "heldout_output_pre_reveal"]
}

// #DescentPredict — candidate predictions on q*. Produces the frozen predictions
// + separation over the fiber. MAY read the PUBLIC held-out input query
// (heldout_input_query, a #RestrictedSurface) but NEVER the sealed output or the
// hidden machine (Firewall B). It CANNOT emit LIFT_VALIDATED: it cannot source
// oracle_outcome, so a "validated" warrant here is a type error (AC3/AC4).
#DescentPredict: #ProviderContract & {
	provider_class: "descent"
	kind:           "mechanical"
	input: ["fit_candidate_set", "heldout_input_query"]
	search_strength: "exact"
	determinism: {deterministic: true, repeatability: "exact"}
	output: #MechanicalOutput & {
		_can_back: {equivalence_fiber: true, heldout_prediction: true}
		core_fields_produced: ["candidate_fiber", "equivalence"]
	}
	evidence: {
		core_fields: ["candidate_fiber", "equivalence"]
		fixture_fields: ["heldout_distinct_predictions", "heldout_is_separating", "frozen_prediction_on_heldout"]
	}
	failure: {on_failure: "UNRESOLVED"}
	// May read the public q*; may NOT read the sealed output or hidden machine.
	may_access: ["heldout_input_query"]
	may_not_access: ["oracle_reveal", "hidden_machine", "heldout_output_pre_reveal"]
}

// #OracleRevealAndCompare — the ONLY provider cleared for oracle surfaces
// (Firewall B). Commit/reveal verification + outcome partition (pass/fail,
// tested fiber). Produces the oracle Core field; may emit LIFT_VALIDATED (it can
// source oracle_outcome, and carries the held-out prediction + equivalence fiber
// it verifies over).
#OracleRevealAndCompare: #ProviderContract & {
	provider_class: "oracle"
	kind:           "mechanical"
	input: ["candidate_predictions", "oracle_commitment", "oracle_reveal_bundle", "heldout_input_query"]
	search_strength: "exact"
	determinism: {deterministic: true, repeatability: "exact"}
	output: #MechanicalOutput & {
		_can_back: {equivalence_fiber: true, heldout_prediction: true, oracle_outcome: true}
		core_fields_produced: ["oracle", "candidate_fiber", "empty_or_unresolved_set"]
	}
	evidence: {
		core_fields: ["oracle", "candidate_fiber", "empty_or_unresolved_set"]
		fixture_fields: ["oracle_commitment_sha256", "expected_pass_count", "expected_fail_count", "expected_tested_fiber_size_after_reveal"]
	}
	failure: {on_failure: "UNRESOLVED", note: "commitment does not bind the reveal, or the reveal is unavailable"}
	// The one provider allowed to reach the sealed surfaces.
	may_access: ["oracle_reveal", "hidden_machine", "heldout_output_pre_reveal", "heldout_input_query"]
	may_not_access: []
}

// #RoundTripCheck — post-descent fiber + equivalence: fold (q*, W(q*)) back in,
// re-ascend, and check the round-trip class over J_eval'. Produces equivalence +
// candidate_fiber; may emit LIFT_VALIDATED as a validated CONTINUATION (it sees
// the descent/oracle outcome it folds).
#RoundTripCheck: #ProviderContract & {
	provider_class: "roundtrip"
	kind:           "mechanical"
	input: ["fit_candidate_set", "descent_evidence", "equivalence_relation"]
	search_strength: "exact"
	determinism: {deterministic: true, repeatability: "exact"}
	output: #MechanicalOutput & {
		_can_back: {equivalence_fiber: true, heldout_prediction: true, oracle_outcome: true}
		core_fields_produced: ["equivalence", "candidate_fiber", "J_eval"]
	}
	evidence: {
		core_fields: ["equivalence", "candidate_fiber", "J_eval"]
		fixture_fields: ["roundtrip_class_over_J_eval_after_fold", "roundtrip_class_contains_hidden_machine"]
	}
	failure: {on_failure: "UNRESOLVED"}
	may_access: []
	may_not_access: ["oracle_reveal", "hidden_machine", "heldout_output_pre_reveal"]
}

// ───────────────────────────────────────────────────────────────────────────
// #Ascent0ProviderSuite — the seven contracts as one bundle: the single seam the
// Sub-3 runtime binds. One semantic call + six mechanical providers.
#Ascent0ProviderSuite: {
	semantic:               #SemanticProvider
	finite_model_enumerate: #FiniteModelEnumerate
	realization_fit:        #RealizationFit
	realization_quotient:   #RealizationQuotient
	descent_predict:        #DescentPredict
	oracle_reveal_compare:  #OracleRevealAndCompare
	roundtrip_check:        #RoundTripCheck
}
