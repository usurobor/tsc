// The Repository Legibility Coherence CM (leaf/aspect, v0.2) encoded against
// schema.cue's #AspectMethodology — the SETTLED increment-2 leaf shape. Source of
// truth remains research/repository-coherence/legibility/CM.md (v0.2) +
// requirements.md + runs/0003-current-main.md; this is a parallel CUE encoding
// built to test whether the increment-2 leaf shape encodes a SECOND, differently-
// shaped leaf CM with ZERO new schema construct.
//
// Legibility is a genuinely different leaf from Structure:
//   - it emits PASS (COHERENT_WITHIN_DECLARED_SCOPE) from a passing newcomer
//     fixture (6/6), not DEFECT from policy violations;
//   - its profile is a human newcomer (technical-newcomer-human), not a policy
//     version;
//   - it carries a BOUNDED refusal (RUN-EXEC-01): the coh/kata command exit codes
//     were not executed. That refusal is INCOMPLETE_OBSERVATION *scoped to a single
//     check*, not the inventory — a declared scope boundary, NOT a defect and NOT
//     an execution failure. Faithfully encoded below, the bounded scope is the
//     typed reason it does NOT flip the categorical status.
//
// Its check shape (per-requirement REPO-* verdicts + a blind newcomer fixture) is
// NOT Structure's (move/split/delete findings + consumer_search). So none of
// Structure's move_candidate / consumer_search / destination_resolved fields are
// forced on. Legibility's own typed fields ride the ONE corralled-open region
// (aspect_ext) + the already-open findings/refusals lists — exactly what S2 is
// for. No top-level definition and no field on a closed shared shape is added:
// this encoding makes ZERO change to schema.cue (see README, finding S6).
package cm

// ── Legibility-specific receipt vocabulary (leaf-private, not part of the generic
//    model — lives with the leaf, unified onto #ChildReceiptEnvelope's corralled
//    aspect_ext region + its already-open findings/refusals lists).

// A per-requirement check verdict (the run's Findings table). A leaf-private
// vocabulary; PASS carries a scope/face qualifier in `evidence` (e.g. "PASS
// (structural)" for REPO-RUN-001, "PASS (reader scope)" for REPO-STRUCTURE-001)
// without inventing a new verdict token.
#CheckVerdict: "PASS" | "FAIL" | "PARTIAL"

#RequirementCheck: {
	requirement: string // REPO-* id
	verdict:     #CheckVerdict
	evidence:    string
}

// One blind newcomer-task fixture question (fixtures/newcomer-tasks.md). Answered
// FIRST from README.md only, in ≤1 documented hop, then checked against its
// authority source. The fixture as a whole passes only when all six pass.
#NewcomerQuestion: {
	q:         string // "Q1".."Q6"
	question:  string
	verdict:   #CheckVerdict
	authority: string // the authority source the answer is checked against
	answer:    string // the ≤1-hop answer + hop taken
}

// One refusal. UNLIKE Structure's refusal (a silent-policy destination refusal),
// a Legibility refusal names WHICH categorical refusal kind it is AND its SCOPE.
// `scope` is load-bearing and is the crux of this increment: an
// INCOMPLETE_OBSERVATION/UNDERDETERMINED refusal flips the run to INCOMPLETE ONLY
// when it is inventory-scoped (the inventory could not be completed, a claimed
// authority is missing, or a defect could not be confirmed). A `single_check`
// refusal is honest, bounded incompleteness of ONE check and does NOT flip the
// categorical status (CM.md · Refusal; run-0003 · RUN-EXEC-01 "Bounds one check,
// not the inventory; does not flip the categorical status"). The Result rule reads
// `kind` and `scope` — the bounded reading is TYPED DATA, not an inference.
#LegibilityRefusal: {
	id:      string
	kind:    "INCOMPLETE_OBSERVATION" | "UNDERDETERMINED" | "CM_EXECUTION_FAILED"
	scope:   "single_check" | "inventory"
	surface: string
	reason:  string
}

// One legibility DEFECT finding (CM.md · Receipt envelope `findings` shape). Empty
// at run-0003 (no in-scope defect), but the type must exist so a defective run is
// REPRESENTABLE and the Result rule's DEFECT arm is not dead code (see the
// two-executor derivation and the negative probe in README).
#LegibilityFinding: {
	id:             string
	class:          "mechanical" | "semantic"
	severity:       string
	affected_paths: [...string]
	claim:          string
	evidence:       string
	violated_requirement: [...string] // REPO-* ids
	repair_class:   string
	confidence:     string
	status:         string
}

// The Legibility receipt: the generic child envelope, with typed findings/refusals
// (the envelope's already-open lists) and Legibility's typed extensions under the
// ONE corralled-open region aspect_ext (S2). The shared ten envelope fields stay
// closed, so a typo'd top-level field is rejected by cue vet.
#LegibilityReceipt: #ChildReceiptEnvelope & {
	findings: [...#LegibilityFinding]
	refusals: [...#LegibilityRefusal]

	aspect_ext: {
		// α — manifestation summary (the run observed the repository it claims to
		// assess): a one-line commit/inventory attestation. Full inventory digest and
		// unread surfaces ride the envelope's evidence_refs / unobserved_surfaces.
		manifestation: string

		// β — the retained authority / relational atlas (run-0003 §β). Graph edges as
		// data, never a "well organized" scalar.
		authority_atlas: [...string]

		// Lifecycle status matrix (run-0003 §Status matrix): each stable fact → its
		// declared lifecycle label and where it is authoritative.
		status_matrix: {[string]: string}

		// γ — continuation vs the prior run (run-0003 §γ). BASELINE-style prose note.
		continuation: string

		// The per-requirement REPO-* check verdicts (run-0003 §Findings table). Filled
		// in the instance; the derivation walks these for the DEFECT arm.
		requirement_checks: [...#RequirementCheck]

		// The blind newcomer-task fixture result (run-0003 §Newcomer-task results).
		newcomer_fixture: {
			questions: [...#NewcomerQuestion]
			// Computed pass count / total — a fresh executor reads these directly.
			total:  len(questions)
			passed: len([for q in questions if q.verdict == "PASS" {q.q}])
			// The fixture as a whole passes only when all six pass.
			all_pass: passed == total
		}

		// The Result-rule derivation, COMPUTED by CUE from the typed check / refusal /
		// finding fields, so the compiled IR is mechanically evaluable and the verdict
		// is compiler-checked (break a check and derived_result_class conflicts with the
		// declared result_class → cue vet fails). See README §Two-executor.
		derivation: {
			// Mechanical requirement ids (grounds the FAILED "a required mechanical check"
			// arm via the per-requirement class) — computed from `requirements` in the
			// instance below.
			mechanical_requirements: [...string]

			// Refusal-scope policy: ONLY inventory-scoped observation refusals flip the
			// run. A bounded single-check refusal (RUN-EXEC-01) is honest incompleteness
			// that does NOT flip the categorical status. This is the typed reason the
			// bounded refusal does not trip INCOMPLETE.
			status_flipping_refusal_scopes: ["inventory"]

			// Derived fact sets over receipt.refusals, receipt.findings, and the checks.
			//   - execution_failed_refusals: a mechanical check could not run at all.
			//   - inventory_incomplete_refusals: an observation refusal at inventory scope.
			//   - bounded_refusals: recorded, NON-flipping single-check refusals.
			execution_failed_refusals: [for r in refusals if r.kind == "CM_EXECUTION_FAILED" {r.id}]
			inventory_incomplete_refusals: [for r in refusals if r.kind == "INCOMPLETE_OBSERVATION" || r.kind == "UNDERDETERMINED" if r.scope == "inventory" {r.id}]
			bounded_refusals: [for r in refusals if r.scope == "single_check" {r.id}]

			// Confirmed defects: an explicit defect finding, a FAILED REPO-* check, or a
			// newcomer question that did not PASS.
			defect_findings: [for f in findings {f.id}]
			failed_requirement_checks: [for c in requirement_checks if c.verdict == "FAIL" {c.requirement}]
			failed_newcomer_questions: [for q in newcomer_fixture.questions if q.verdict != "PASS" {q.q}]

			// Clause guards, highest precedence first (FAILED > INCOMPLETE > DEFECT, else
			// PASS).
			failed_guard:     len(execution_failed_refusals) > 0
			incomplete_guard: len(inventory_incomplete_refusals) > 0
			defect_guard: len(defect_findings) > 0 ||
				len(failed_requirement_checks) > 0 ||
				len(failed_newcomer_questions) > 0

			// The derived result_class: first guard true wins; else PASS. Exactly one
			// branch emits, so this resolves to a single #ResultClass.
			derived_result_class: #ResultClass
			if failed_guard {derived_result_class: "FAILED"}
			if !failed_guard && incomplete_guard {derived_result_class: "INCOMPLETE"}
			if !failed_guard && !incomplete_guard && defect_guard {derived_result_class: "DEFECT"}
			if !failed_guard && !incomplete_guard && !defect_guard {derived_result_class: "PASS"}
		}
	}

	// The declared result_class MUST equal the derivation (compiler-enforced) AND
	// the status→result_class mapping of the status (envelope self-unify).
	result_class: aspect_ext.derivation.derived_result_class
}

legibility: #AspectMethodology & {
	id:       "tsc.repository-coherence.legibility"
	version:  "0.2"
	question: "At a given commit, can a first-time technical reader reconstruct what the project is, what is authoritative, what is runnable, what is experimental, and what to do next — without hitting contradictory status, stale paths, mixed artifact roles, or avoidable noise?"
	profile:  "technical-newcomer-human"

	// The leaf's own five-value status vocabulary and its declared mapping onto the
	// generic four-value result_class interface (CM.md · Receipt). Same five statuses
	// as Structure, but this run lands on COHERENT_WITHIN_DECLARED_SCOPE → PASS.
	statuses: [
		"COHERENT_WITHIN_DECLARED_SCOPE",
		"DEFECTS_FOUND",
		"UNDERDETERMINED",
		"INCOMPLETE_OBSERVATION",
		"CM_EXECUTION_FAILED",
	]
	status_mapping: {
		COHERENT_WITHIN_DECLARED_SCOPE: "PASS"
		DEFECTS_FOUND:                  "DEFECT"
		UNDERDETERMINED:                "INCOMPLETE"
		INCOMPLETE_OBSERVATION:         "INCOMPLETE"
		CM_EXECUTION_FAILED:            "FAILED"
	}

	// The executable core (CM.md · four subcontracts + newcomer fixture + α/β/γ
	// receipt roles): typed inputs, ordered steps, result rule.
	procedure: {
		inputs: [
			{name: "repository_snapshot", role: "the tracked tree at one exact commit (git ls-files)"},
			{name: "reader_profile", role: "the declared reader: technically experienced, understands software repositories, unfamiliar with TSC, no TSC vocabulary"},
			{name: "live_surface_policy", role: "the reader-navigable front door + everything reachable in ≤1 documented hop + the authority sources the fixture checks against"},
			{name: "exclusions", role: "excluded paths with reasons (.cdd .cn-sigma .cell .tsc heldout, .claude/worktrees/**, docs/{alpha,beta,gamma} except docs/beta/governance/, katas/*/input, _build)"},
		]
		steps: [
			{n: 1, action: "Manifest the live reader surface (α): commit SHA, inventory over the live-surface policy, excluded paths + reasons, reader profile, generated/frozen classification, any surface left unread. An incomplete/uninventoried surface is INCOMPLETE_OBSERVATION, never 'coherent'.", checks: ["REPO-ENTRY-001"]},
			{n: 2, action: "Run the blind newcomer-task fixture FIRST, from README.md only: the six questions, each answered in ≤1 documented hop (no Git history, no glossary for basic identity), then verified against its authority source.", checks: ["REPO-ENTRY-001", "REPO-DOC-001"]},
			{n: 3, action: "Local clarity per live document: one governing question; purpose + authority visible immediately; no stale future tense; no historical-as-current; no removable repetition.", checks: ["REPO-DOC-001", "REPO-NOISE-001"]},
			{n: 4, action: "Relational & authority atlas (β): one authoritative home per stable fact; README↔STATUS agree; portal matches the tree; every Markdown link and canonical path on the live surface resolves; implementation claims match code.", checks: ["REPO-AUTH-001", "REPO-PATH-001", "REPO-STRUCTURE-001", "REPO-STATUS-001"]},
			{n: 5, action: "Lifecycle & lineage: distinguish current/draft/normative/experimental/generated/historical/frozen/superseded; no draft-as-normative, no historical plan as current work, no generated artifact reading as authoritative, no stale current entry point after a move.", checks: ["REPO-HISTORY-001", "REPO-STATUS-001"]},
			{n: 6, action: "Operability: documented commands run; targets/links/schemas resolve; rendered artifacts match sources. Where a mechanical check cannot execute in the declared environment, record a BOUNDED single-check refusal (not a whole-run incompleteness).", checks: ["REPO-RUN-001", "REPO-PATH-001"]},
			{n: 7, action: "Continuation (γ) + emit: compare to the prior run; emit the α inventory, β atlas, findings with warrant, refusals, and the categorical status + result_class via the Result rule.", checks: []},
		]
		// Result rule, as data. Clauses highest-precedence first (FAILED > INCOMPLETE >
		// DEFECT, else PASS); each `when` names the typed IR fields (in
		// receipt.aspect_ext.derivation) an executor evaluates — no appeal to CM.md or
		// domain knowledge is needed. The INCOMPLETE arm names the bounded-refusal
		// exclusion explicitly.
		result: {
			clauses: [
				{when: "FAILED — derivation.execution_failed_refusals is non-empty (a required mechanical check could not run at all; a refusal of kind CM_EXECUTION_FAILED).", class: "FAILED"},
				{when: "INCOMPLETE — derivation.inventory_incomplete_refusals is non-empty (a refusal of kind INCOMPLETE_OBSERVATION or UNDERDETERMINED whose scope is 'inventory' — the inventory could not be completed, a claimed authority is missing, or a defect could not be confirmed from evidence). A BOUNDED single-check refusal (scope not in derivation.status_flipping_refusal_scopes, i.e. 'single_check') does NOT trip this arm — it is honest incompleteness of one check that does not flip the categorical status.", class: "INCOMPLETE"},
				{when: "DEFECT — a confirmed in-scope defect: derivation.defect_findings is non-empty, OR derivation.failed_requirement_checks is non-empty (some REPO-* check verdict is FAIL), OR derivation.failed_newcomer_questions is non-empty (some newcomer-fixture question did not PASS).", class: "DEFECT"},
			]
			otherwise: "PASS"
		}
	}

	boundary: {
		measure_only: true
		note:         "The CM observes, checks, and emits defects with warrant; it changes no files. Measure commit A → freeze the receipt → repair on commit B → re-run → compare A and B → an independent reviewer closes (REPO-REPAIR-001, REPO-REVIEW-001, parent RCM-BOUNDARY-001). A single invocation that edits files while observing them destroys its own evidence."
	}

	// The 11 stable REPO-* requirements (id · claim · class · severity), read from
	// requirements.md. `class` is load-bearing: the FAILED clause references "a
	// required mechanical check", so mechanical vs semantic vs process is in the IR
	// (derivation.mechanical_requirements is computed from it). No adr_clause: unlike
	// Structure, Legibility's requirements trace to its own fixtures/newcomer tasks,
	// not to an external ADR — adr_clause is optional and correctly omitted here.
	requirements: [
		{id: "REPO-ENTRY-001", text: "The front door identifies the project, the runnable surface, the active research, and the next paths — in one screen.", class: "semantic", severity: "P0"},
		{id: "REPO-DOC-001", text: "Every live document answers one governing question, with purpose and authority visible immediately.", class: "semantic", severity: "P1"},
		{id: "REPO-AUTH-001", text: "Every stable fact has one authoritative home; no two documents claim incompatible authority.", class: "mechanical + semantic", severity: "P0"},
		{id: "REPO-STATUS-001", text: "Every status projection agrees with its authority source (spec version, software version, ratification, conformance standing).", class: "mechanical", severity: "P1"},
		{id: "REPO-PATH-001", text: "Every current path and Markdown link on the live surface resolves.", class: "mechanical", severity: "P0"},
		{id: "REPO-STRUCTURE-001", text: "Directory placement matches the declared repository-plane contract; no two documentation systems are presented as authoritative at once.", class: "mechanical + semantic", severity: "P0"},
		{id: "REPO-HISTORY-001", text: "Historical, superseded, or generated artifacts cannot be read as current instructions.", class: "semantic", severity: "P1"},
		{id: "REPO-RUN-001", text: "Documented runnable commands execute under the declared environment.", class: "mechanical", severity: "P0"},
		{id: "REPO-NOISE-001", text: "Repetition, stale wrappers, and obsolete navigation do not obscure current project truth.", class: "semantic", severity: "P2"},
		{id: "REPO-REPAIR-001", text: "A repair run changes only findings in scope and preserves meaning (evidence-boundary rule).", class: "process", severity: "P0"},
		{id: "REPO-REVIEW-001", text: "A COHERENT_WITHIN_DECLARED_SCOPE claim requires an independent full-scope review, separate from the repair actor.", class: "process", severity: "P0"},
	]

	does_not_own: [
		"repair (changing files to close defects)",
		"independent review closure",
		"structure/full-tree plane completeness (owned by the structure aspect; assigned away by repository-planes §4)",
	]

	// The frozen run-0003 receipt @ 48b9a63, encoded VERBATIM as the concrete
	// instance: status COHERENT_WITHIN_DECLARED_SCOPE → result_class PASS (DERIVED
	// below). Newcomer fixture 6/6; one bounded refusal RUN-EXEC-01.
	receipt: #LegibilityReceipt & {
		aspect_id:         "legibility"
		cm_version:        "0.2"
		profile:           "technical-newcomer-human"
		repository_commit: "48b9a635c59ec6ba00dd80ee7a48d1160d1e0656"

		// result_class is DERIVED (aspect_ext.derivation.derived_result_class) and
		// self-unified with status_mapping[status]; both resolve to PASS.
		status: "COHERENT_WITHIN_DECLARED_SCOPE"

		status_mapping: {
			COHERENT_WITHIN_DECLARED_SCOPE: "PASS"
			DEFECTS_FOUND:                  "DEFECT"
			UNDERDETERMINED:                "INCOMPLETE"
			INCOMPLETE_OBSERVATION:         "INCOMPLETE"
			CM_EXECUTION_FAILED:            "FAILED"
		}

		scope:               "Declared reader: technically experienced, understands software repositories, unfamiliar with TSC, no TSC vocabulary. Live-surface policy: the reader-navigable front door + everything reachable in ≤1 documented hop + the authority sources the fixture checks against. Excluded (with reason): .cdd .cn-sigma .cell .tsc heldout (vendored / agent state / generated / CM self-test data); .claude/worktrees/** (agent worktree copies); docs/{alpha,beta,gamma} (declared frozen prior-cycle snapshots — except docs/beta/governance/, a live machine input); katas/*/input (negative-control corpora); _build (build output)."
		unobserved_surfaces: "docs/{alpha,gamma} + most of docs/beta — declared frozen prior-cycle snapshots, non-entry, read only enough to confirm non-entry framing. docs/beta/governance/ runtime behavior — a declared live machine input (α); its engine/CI consumption not re-executed here. coh / kata command exit codes — see refusal RUN-EXEC-01."
		evidence_refs:       "authority graph (β atlas, 13-file front-door link set all resolve) · status matrix (spec 4.1.0 Draft / last ratified 4.0.0 Normative / engine 0.12.0 non-v4 / conformance none) · newcomer-task results (6/6 PASS) · inventory digest (live reader surface @ 48b9a63)"

		aspect_ext: {
			manifestation: "Commit 48b9a635c59ec6ba00dd80ee7a48d1160d1e0656 observed, verified equal to origin/main at measurement time. Live reader surface inventoried complete; no inaccessible reader-navigable surface — NOT INCOMPLETE_OBSERVATION. Front-door migration since 0002 verified on disk (root QUICKSTART.md/ARCHITECTURE.md absent; docs/quickstart/README.md + docs/architecture/README.md present and portal-linked)."

			// Computed here where `requirements` is in scope (the derivation shape is
			// declared in #LegibilityReceipt; this fills its mechanical-requirement set).
			derivation: mechanical_requirements: [for r in requirements if r.class == "mechanical" || r.class == "mechanical + semantic" {r.id}]

			// β — retained authority / relational atlas (run-0003 §β).
			authority_atlas: [
				"README → STATUS: AGREE on version / ratification / standing (README.md:9–16 ↔ STATUS.md:3–6; VERSION = 0.12.0)",
				"README → docs/README (portal): one reader-intent system",
				"docs/README → repository-planes ADR: 'α/β/γ is TSC's measurement and role grammar — never a filing taxonomy' (docs/README.md:3 ↔ repository-planes.md §Decision/§4)",
				"docs/README → THESIS, quickstart/README, spec/README, research/ascent/README, architecture/decisions/, concepts/illustrations/README, CONTRIBUTING — all resolve",
				"docs/README 'authority by question' → src/engine/ocaml/CONTRACT.md, STATUS.md, spec/tsc-conformance.md — all resolve",
				"spec/README → conformance IDs / four-layer authority: coherent",
				"STATUS → spec/README, conformance obligations, research/ascent: coherent",
				"src/engine/ocaml/README → CONTRACT.md, STATUS: coherent (proxy ≠ v4 explicit; README.md:1–5, CONTRACT.md:1–9, STATUS.md:20–22)",
				"docs/architecture/README → STATUS (../../STATUS.md): resolves",
				"13-file front-door Markdown link set: ALL resolve (REPO-PATH-001); no two live documents claim incompatible identity/navigation/status authority (REPO-AUTH-001)",
			]

			// Lifecycle status matrix (run-0003 §Status matrix).
			status_matrix: {
				specification:      "4.1.0 Draft — correctly labeled (README.md:11, spec/README.md:2–4)"
				last_ratified_spec: "4.0.0 Normative — locatable via commit 4da1122 (STATUS.md:5)"
				software_engine:    "0.12.0 proxy, not v4 — correctly labeled (VERSION; STATUS.md:3; CONTRACT.md:2)"
				conformance_standing: "none — correctly labeled (STATUS.md:6)"
				front_door_pages:   "docs/quickstart/, docs/architecture/ — moved from root; portal-linked (README.md:23; docs/README.md:10)"
				historical_release: "docs/evidence/releases/ — banner-labeled historical"
				frozen_doc_snapshots: "docs/{alpha,gamma}, most of docs/beta — declared frozen, non-entry (docs/README.md:36–38)"
				live_infra_in_frozen: "docs/beta/governance/ — declared LIVE on both surfaces (docs/README.md:38; ci.yml:66–69) — 0002 N1 closed"
				plane_migration:    "partial migration in progress — ADR self-labeled; residuals assigned to structure aspect (repository-planes.md:3,74–79,98–105)"
			}

			// γ — continuation vs run 0002 (run-0003 §γ).
			continuation: "Between 0002 (bb0d095) and HEAD (48b9a63) the repository continued lawfully at the reader level; both residuals 0002 recorded are now CLOSED. R7 (physical migration tail): root QUICKSTART.md/ARCHITECTURE.md moved into docs/ reader-intent planes; front door + portal route to the new paths; no stale live-surface path. N1 (imprecise 'frozen' label over a mixed tree): both surfaces now carve out the live docs/beta/governance/ exception (docs/README.md:38; ci.yml:66–69)."

			// Per-requirement REPO-* check verdicts (run-0003 §Findings table). The nine
			// scored requirements; the two process requirements (REPO-REPAIR-001,
			// REPO-REVIEW-001) are not scored on a measurement run and are omitted here.
			requirement_checks: [
				{requirement: "REPO-ENTRY-001", verdict: "PASS", evidence: "README.md:3–5 states one identity; README.md:9–40 answers what-is / authoritative / runnable / experimental / next in one screen (status table, 'Start here', run section)."},
				{requirement: "REPO-DOC-001", verdict: "PASS", evidence: "docs/THESIS.md:3–16 opens plain-language; the formal abstract is relocated under §'The formal account' (THESIS.md:19–24). Each front-door doc states purpose + authority immediately."},
				{requirement: "REPO-AUTH-001", verdict: "PASS", evidence: "Single authoritative home per fact; README.md:16 cedes status detail to STATUS.md; portal↔ADR agree on navigation (docs/README.md:3 ↔ repository-planes.md:98–105). No incompatible authority."},
				{requirement: "REPO-STATUS-001", verdict: "PASS", evidence: "README.md:9–16 ↔ STATUS.md:3–6 ↔ VERSION(0.12.0) ↔ CONTRACT.md:1–9: spec 4.1.0 Draft, last ratified 4.0.0 Normative, engine 0.12.0 non-v4, 4.1 standing none — all agree."},
				{requirement: "REPO-PATH-001", verdict: "PASS", evidence: "All Markdown links on the 13-file front-door set resolve (mechanical check). No stale link to the moved root QUICKSTART.md/ARCHITECTURE.md."},
				{requirement: "REPO-STRUCTURE-001", verdict: "PASS", evidence: "PASS (reader scope). Portal presents one reader-intent system (docs/README.md:3); α/β/γ demoted to declared-frozen non-entry with the governance exception named (:36–38). Residual plane-placement debt (docs/design/, targets/, katas/) is declared and assigned to the STRUCTURE aspect (repository-planes.md:74–79,98–105), not reader-facing."},
				{requirement: "REPO-HISTORY-001", verdict: "PASS", evidence: "Frozen snapshots labelled non-entry (docs/README.md:36–38); historical release banner-labelled (docs/evidence/releases/); ADR self-labelled 'partial migration in progress' (repository-planes.md:3). No historical material reads as current instruction."},
				{requirement: "REPO-RUN-001", verdict: "PASS", evidence: "PASS (structural) / see refusal RUN-EXEC-01. Documented commands are path-consistent; referenced binary/scripts/targets all exist. Live exit codes not executed here (no opam/network) — recorded as a BOUNDED single-check refusal, per 0001/0002 precedent; the structural face passes."},
				{requirement: "REPO-NOISE-001", verdict: "PASS", evidence: "Status narrative single-homed to STATUS.md; other files carry a short projection + pointer (README.md:16, THESIS.md:83–87, quickstart/README.md:5, architecture/README.md:56). No obsolete navigation on the front door."},
			]

			// The blind newcomer-task fixture (run-0003 §Newcomer-task results): 6/6 PASS.
			newcomer_fixture: {
				questions: [
					{q: "Q1", question: "What is TSC?", verdict: "PASS", authority: "README.md first screen · docs/THESIS.md", answer: "README.md:3–5: a framework for deciding whether several observations are explained by one lawful process, returning a proof-carrying receipt (not a score). 1 hop docs/THESIS.md:3–16 confirms in plain language; no glossary needed for identity; uncontradicted."},
					{q: "Q2", question: "Which specification is authoritative?", verdict: "PASS", authority: "STATUS.md · spec/README.md", answer: "1 hop STATUS.md:3–8: 4.0.0 Normative is the last ratified / current normative warrant; 4.1.0 Draft is the in-progress spec. spec/README.md:1–8,75 agrees. Which spec is authoritative is answerable without reading the ratified 4.0.0 text (commit 4da1122)."},
					{q: "Q3", question: "What can be executed today?", verdict: "PASS", authority: "README.md run section · docs/quickstart/", answer: "README.md:29–40 + 1 hop docs/quickstart/README.md:1–5: coh 0.12.0 repository proxy (v3.2-era), modes mechanical/llm/hybrid/auto, katas — explicitly not v4, no v4 receipt. Authority agrees."},
					{q: "Q4", question: "What does the current coh engine actually implement?", verdict: "PASS", authority: "src/engine/ocaml/README.md · CONTRACT.md", answer: "Front door (README.md:13,31) + 1 hop STATUS.md:20–22: the v3.2-era repository-proxy scoring/witness contract; explicitly NOT TSC v4 Core/Operational/Conformance. Deeper engine authority is 2 hops but the identity answer needs no such hop. Uncontradicted."},
					{q: "Q5", question: "What is the active research program?", verdict: "PASS", authority: "STATUS.md program priority · research/ascent/", answer: "README.md:9–16 ('Current research: Articulation Ascent') + 1 hop research/ascent/README.md:1–9; STATUS.md:51–53 names it the primary program for the current bounded sprint. Uncontradicted."},
					{q: "Q6", question: "What should a newcomer read or run next?", verdict: "PASS", authority: "README.md 'start here'", answer: "README.md:18–27 'Start here' table: all six destinations resolve and each is a lawful entry (plain-language THESIS, single-system portal, indexed ascent, quickstart, spec, contributing). No routing into a dense abstract or a legacy tree."},
				]
			}
		}

		// No in-scope legibility defect at the declared reader profile: the DEFECT
		// finding list is EMPTY. (The positive per-requirement verdicts and the 6/6
		// newcomer fixture live under aspect_ext; a defect would appear here.)
		findings: []

		// One BOUNDED refusal (run-0003 §Refusals). kind INCOMPLETE_OBSERVATION but
		// scope single_check — it bounds ONE check (REPO-RUN-001's execution face),
		// NOT the inventory, and does NOT flip the categorical status. This is the
		// typed encoding of the CM's declared scope boundary.
		refusals: [
			{
				id:      "RUN-EXEC-01"
				kind:    "INCOMPLETE_OBSERVATION"
				scope:   "single_check"
				surface: "operability-by-execution — exit codes of the documented coh and scripts/run-katas.sh commands"
				reason:  "no opam build / no network in this measurement environment. Referenced binary, scripts, targets, and install path all exist and are path-consistent, but their runtime exit codes were not observed. Prior runs 0001/0002 also did not execute them. Bounds one check, not the inventory; does not flip the categorical status."
			},
		]
	}
}

// Methodology-only projection (issue #115 leaf spike): the aspect methodology
// PROGRAM = legibility minus its concrete run (`receipt`). Additive — does NOT
// touch the `legibility` expr above, whose export stays byte-identical to
// compiled/legibility.json. This is the `.cm` leaf byte-identity target
// (cue export -e legibility_source).
legibility_source: {
	for k, v in legibility if k != "receipt" {(k): v}
}
