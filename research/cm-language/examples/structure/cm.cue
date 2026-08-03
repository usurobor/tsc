// The Repository Structural Coherence CM (leaf/aspect, v0.2) encoded against
// schema.cue's #AspectMethodology. Source of truth remains
// research/repository-coherence/structure/CM.md (v0.2) + requirements.md; this is
// a parallel CUE encoding built to validate the model on a LEAF CM.
//
// This is a FAITHFUL, LOSSLESS encoding of Structure CM v0.2 as it exists — a
// v1.1-bodied CM (its requirement adr_clauses cite "(v1.1) §1/§2/§3",
// STRUCT-REFUSE-001 is still open, and the R1 refusal is live). ADR
// repository-planes v1.2 is now on main and would close R1 and make F3–F8
// mechanical, but reconciling the CM body to v1.2 is a separate methodology cell,
// out of scope for this language encoding (see README, S5). So `profile` is
// repository-planes-v1.1, matching CM.md / requirements.md / fixtures / run 0002.
package cm

// ── Structure-specific receipt vocabulary (leaf-private, not part of the
//    generic model — lives with the leaf, unified onto #ChildReceiptEnvelope's
//    corralled aspect_ext region + its already-open findings/refusals lists).

// Typed repairability (CM.md · Repairability typing).
#Repairability: "MECHANICAL" | "POLICY_REQUIRED" | "DEFERRED"

// The consumer-search contract (CM.md · Consumer-search contract). Every
// move/split/delete candidate MUST carry this block.
#ConsumerSearch: {
	surfaces_searched: [...string]
	search_strength: "complete" | "complete_within_bound" | "heuristic"
	consumers: [...string]
	digest: string
	unsearched_surfaces: [...string] | *[]
}

// One structural finding. The typed fields the Result rule walks:
//   - move_candidate : is this a repair-ready move/split/delete PROPOSAL at this
//     snapshot? (Naming/taxonomy violations that establish a defect but propose no
//     move — e.g. an α/β/γ role tree, unratified docs/design — are NOT candidates.)
//   - consumer_search: a block, or null. A non-move-candidate carries null; a
//     move_candidate SHOULD carry a block, but the type deliberately ALLOWS null so
//     that a malformed emission (move proposal without its consumer graph) is
//     REPRESENTABLE and caught by the Result rule's FAILED arm (→ CM_EXECUTION_FAILED,
//     per the near-miss fixture), rather than being a compile error. So
//     "move_candidate ∧ consumer_search == null" is a live, typed, checkable
//     condition — not an inference, and not dead code.
//   - destination_resolved: does policy name/decide the destination? Derived
//     mechanically: true unless repairability is POLICY_REQUIRED.
#StructureFinding: {
	id:          string
	requirement: [...string] // STRUCT-* ids
	adr_clause:  string
	severity:    string
	claim:       string
	repairability: #Repairability

	move_candidate:  bool
	consumer_search: #ConsumerSearch | null
	// A non-candidate carries no consumer graph. (A move_candidate is NOT forced to
	// carry one — see above; the Result rule detects a missing block as FAILED.)
	if !move_candidate {consumer_search: null}

	destination_resolved: bool
	destination_resolved: repairability != "POLICY_REQUIRED"

	evidence: string
}

// One refusal (STRUCT-REFUSE-001): the ADR is silent on this path's destination.
#StructureRefusal: {
	id:          string
	requirement: string
	path:        string
	reason:      string
}

// The Structure receipt: the generic child envelope, with typed findings/refusals
// (the envelope's already-open lists) and Structure's typed extensions under the
// ONE corralled-open region aspect_ext (S2). The shared ten envelope fields stay
// closed, so a typo'd top-level field is rejected by cue vet.
#StructureReceipt: #ChildReceiptEnvelope & {
	findings: [...#StructureFinding]
	refusals: [...#StructureRefusal]

	aspect_ext: {
		// + envelope extensions (run 0002 records these as `+ field` additions).
		plane_classification: {[string]: {files: int, resolved_plane: string, verdict: string}}
		canonical_path_map: {[string]: "satisfied" | "violated" | "N/A"}
		policy_authority: string

		// The Result-rule derivation, COMPUTED by CUE from the typed finding fields
		// so the compiled IR is mechanically evaluable (and the verdict is
		// compiler-checked: break a finding and derived_result_class conflicts with
		// the declared result_class → cue vet fails). See README §Two-executor.
		derivation: {
			// Completeness policy: only "heuristic" search counts as INCOMPLETE;
			// "complete" and "complete_within_bound" both count as COMPLETE.
			incomplete_search_strengths: ["heuristic"]

			// Mechanical requirement ids (grounds the FAILED "required mechanical
			// check" arm via the per-requirement class, Fix 4) — computed from
			// requirements in the instance below. failed_mechanical_checks is the
			// subset that could NOT execute this run — empty at 48b9a63: inventory
			// (git ls-files) and every mechanical classification executed.
			mechanical_requirements: [...string]
			failed_mechanical_checks: [...string]
			failed_mechanical_checks: []

			// Derived fact sets over receipt.findings.
			move_candidates_missing_search: [for f in findings if f.move_candidate if f.consumer_search == null {f.id}]
			heuristic_searches: [for f in findings if f.consumer_search != null if f.consumer_search.search_strength == "heuristic" {f.id}]
			unresolved_destinations: [for f in findings if !f.destination_resolved {f.id}]
			findings_establishing_defect: [for f in findings {f.id}]

			// Clause guards, highest precedence first.
			failed_guard: len(move_candidates_missing_search) > 0 || len(failed_mechanical_checks) > 0
			incomplete_guard: len(heuristic_searches) > 0 ||
				(len(unresolved_destinations) == len(findings_establishing_defect) && len(findings_establishing_defect) > 0)
			defect_guard: len(findings_establishing_defect) > 0

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

structure: #AspectMethodology & {
	id:       "tsc.repository-coherence.structure"
	version:  "0.2"
	question: "At a given commit, does every tracked artifact have exactly one clear place, name, owner, lifecycle, and relationship to the rest of the repository — judged against repository-planes, never against the CM's own taste."
	profile:  "repository-planes-v1.1"

	// The leaf's own five-value status vocabulary and its declared mapping onto
	// the generic four-value result_class interface (CM.md · Receipt envelope and
	// status mapping).
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

	// The executable core (CM.md · Executable core): inputs, six steps, result rule.
	procedure: {
		inputs: [
			{name: "repository_snapshot", role: "the tracked tree at one exact commit (git ls-files)"},
			{name: "policy_snapshot", role: "repository-planes ADR pinned at a commit (the sole placement/naming/function/lifecycle authority)"},
			{name: "exclusions", role: "the do-not-touch set (.cdd/ .cn-sigma/ heldout/) + build/agent/infra paths, not content-classified"},
		]
		steps: [
			{n: 1, action: "Enumerate all tracked paths in scope (git ls-files, minus exclusions).", checks: ["STRUCT-EXCLUDE-001"]},
			{n: 2, action: "Classify each path against the policy (plane, canonical home, docs reader-intent taxonomy, ownership, lifecycle).", checks: ["STRUCT-PLANE-001", "STRUCT-RULE-001", "STRUCT-CANON-001", "STRUCT-NAME-001", "STRUCT-DOCSET-001", "STRUCT-FUNC-001", "STRUCT-OWNER-001", "STRUCT-MIXED-001", "STRUCT-HISTLABEL-001", "STRUCT-DERIVED-001"]},
			{n: 3, action: "Record violations where policy decides.", checks: []},
			{n: 4, action: "Refuse (UNDERDETERMINED) where policy is silent.", checks: ["STRUCT-REFUSE-001"]},
			{n: 5, action: "For every move/split/delete candidate, enumerate all live consumers (consumer-search contract).", checks: ["STRUCT-CONSUMER-001"]},
			{n: 6, action: "Emit the plane manifest, findings, refusals, and consumer graph.", checks: []},
		]
		// Result rule, as data. Clauses are highest-precedence first
		// (FAILED > INCOMPLETE > DEFECT, else PASS); each `when` names the typed IR
		// fields (in receipt.aspect_ext.derivation) an executor evaluates — no appeal
		// to CM.md or domain knowledge is needed.
		result: {
			clauses: [
				{when: "FAILED — derivation.failed_mechanical_checks is non-empty (a required mechanical check could not execute), OR derivation.move_candidates_missing_search is non-empty (some finding has move_candidate==true and consumer_search==null).", class: "FAILED"},
				{when: "INCOMPLETE — derivation.heuristic_searches is non-empty (some consumer_search.search_strength is in derivation.incomplete_search_strengths, i.e. 'heuristic'; 'complete' and 'complete_within_bound' both count as COMPLETE), OR every finding has destination_resolved==false (derivation.unresolved_destinations == all findings).", class: "INCOMPLETE"},
				{when: "DEFECT — at least one finding establishes a policy violation (findings non-empty; derivation.findings_establishing_defect non-empty).", class: "DEFECT"},
			]
			otherwise: "PASS"
		}
	}

	boundary: {
		measure_only: true
		note:         "The CM observes, classifies, and emits findings; it moves, renames, and deletes nothing. Measure → freeze the receipt → repair on a later commit → re-run → independent full-scope review closes (STRUCT-REPAIR-001, STRUCT-REVIEW-001, parent RCM-BOUNDARY-001)."
	}

	// The 15 stable STRUCT-* requirements (id · claim · ADR clause · class · severity).
	// `class` is load-bearing: the FAILED clause references "a required mechanical
	// check", so mechanical vs semantic vs process is in the IR (requirements.md).
	requirements: [
		{id: "STRUCT-PLANE-001", text: "Every tracked path resolves to exactly one root plane; no path is a peer to the six planes or spans two.", adr_clause: "Target planes (root)", class: "mechanical", severity: "P0"},
		{id: "STRUCT-RULE-001", text: "Each path's plane is the one the decision rule selects (bind→spec, run→src, prove→conformance, still change→research, help a person→docs, automate→scripts).", adr_clause: "Decision rule", class: "mechanical + semantic", severity: "P0"},
		{id: "STRUCT-CANON-001", text: "Every artifact the ADR program-maps give a canonical home sits at that home.", adr_clause: "Program maps", class: "mechanical", severity: "P0"},
		{id: "STRUCT-NAME-001", text: "Documentation is filed by reader intent; the α/β/γ role grammar is never used as a filing taxonomy.", adr_clause: "Docs reader-intent taxonomy (\"α/β/γ … never a filing taxonomy\")", class: "mechanical + semantic", severity: "P1"},
		{id: "STRUCT-DOCSET-001", text: "The eight reader-intent folders are the exhaustive set of docs/ subfolders; a docs/ subfolder outside them is a defect to rehome.", adr_clause: "Amendments (v1.1) §1", class: "mechanical + semantic", severity: "P1"},
		{id: "STRUCT-FUNC-001", text: "No plane is a single-occupant or premature catch-all standing in for a real home.", adr_clause: "Iteration 3 (\"…not a single-occupant config/ plane\")", class: "semantic", severity: "P1"},
		{id: "STRUCT-OWNER-001", text: "Each artifact has one authoritative home; no duplicate live copies.", adr_clause: "Decision (organize by plane) + Program maps", class: "mechanical", severity: "P0"},
		{id: "STRUCT-CONSUMER-001", text: "Each move/split/delete finding enumerates the artifact's live consumers via the consumer-search contract — surfaces searched, search strength, consumer set, digest, unsearched surfaces; a relocation that breaks a consumer without rehoming its reference is not coherent.", adr_clause: "Invariants any move commit must preserve (\"targets resolve; conformance validator exits 0 …; no document's meaning changes\")", class: "mechanical + semantic", severity: "P0"},
		{id: "STRUCT-MIXED-001", text: "No live directory mixes live-mutable content with frozen, snapshot, or archived content.", adr_clause: "Migration state (frozen snapshots preserved intact)", class: "mechanical + semantic", severity: "P0"},
		{id: "STRUCT-HISTLABEL-001", text: "Historical/archived/frozen material retained on the live tree carries a lifecycle label (banner or marker).", adr_clause: "Amendments (v1.1) §3", class: "mechanical + semantic", severity: "P1"},
		{id: "STRUCT-DERIVED-001", text: "Derived/generated output is distinguishable from hand-authored source (excluded build dir, generated marker, or clearly-derived path).", adr_clause: "Amendments (v1.1) §2 + Invariants (render byte-identity)", class: "mechanical + semantic", severity: "P1"},
		{id: "STRUCT-EXCLUDE-001", text: "The do-not-touch set (.cdd/, .cn-sigma/, heldout/) is excluded from content classification, never flagged as misplaced content.", adr_clause: "Do NOT touch", class: "mechanical", severity: "P0"},
		{id: "STRUCT-REFUSE-001", text: "When the ADR does not decide a path's home, the CM returns UNDERDETERMINED for that path and does not assign a plane.", adr_clause: "Deferred — foundation bundle", class: "process", severity: "P0"},
		{id: "STRUCT-REPAIR-001", text: "A repair run changes only findings in scope and preserves meaning; a move commit changes no document's meaning (evidence-boundary rule).", adr_clause: "Invariants (\"No meaning change, not no edits\")", class: "process", severity: "P0"},
		{id: "STRUCT-REVIEW-001", text: "A COHERENT_WITHIN_DECLARED_SCOPE claim requires an independent full-scope review, separate from the repair actor.", adr_clause: "Parent RCM-BOUNDARY-001", class: "process", severity: "P0"},
	]

	// STRUCT-LIFECYCLE-001 was retired at v0.1 (no ratifying ADR clause; its lone
	// grounded rule was already STRUCT-MIXED-001). IDs are permanent — never reused.
	// v1.1 ratified the two dimensions it reached for as FRESH ids
	// (STRUCT-DERIVED-001, STRUCT-HISTLABEL-001).
	retired_requirements: [
		{id: "STRUCT-LIFECYCLE-001", note: "Retired at v0.1; never reused. Its dimensions returned under fresh ids STRUCT-DERIVED-001 (v1.1 §2) and STRUCT-HISTLABEL-001 (v1.1 §3); cross-plane name-predictiveness remains declined."},
	]

	does_not_own: [
		"policy (the ADR is the sole authority on placement, naming, function, lifecycle)",
		"repair (moves, renames, deletes)",
		"independent review closure",
	]

	// The frozen run-0002 receipt @ 48b9a63, encoded VERBATIM as the concrete
	// instance: status DEFECTS_FOUND → result_class DEFECT (DERIVED below).
	receipt: #StructureReceipt & {
		aspect_id:         "structure"
		cm_version:        "0.2"
		profile:           "repository-planes-v1.1"
		repository_commit: "48b9a635c59ec6ba00dd80ee7a48d1160d1e0656"

		// result_class is DERIVED (aspect_ext.derivation.derived_result_class) and
		// self-unified with status_mapping[status]; both resolve to DEFECT.
		status: "DEFECTS_FOUND"

		status_mapping: {
			COHERENT_WITHIN_DECLARED_SCOPE: "PASS"
			DEFECTS_FOUND:                  "DEFECT"
			UNDERDETERMINED:                "INCOMPLETE"
			INCOMPLETE_OBSERVATION:         "INCOMPLETE"
			CM_EXECUTION_FAILED:            "FAILED"
		}

		scope:               "six ADR planes + root peers + root files; excluded .cdd/ .cn-sigma/ heldout/ (STRUCT-EXCLUDE-001) + _build .cell/ .tsc/ .github/ (infra); policy pinned @ 48b9a63. 475 tracked, 255 classified."
		unobserved_surfaces: "none inaccessible. Root metadata files (README, STATUS, CHANGELOG, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, LICENSE, CITATION.cff, Makefile, install.sh, VERSION) recorded UNDERDETERMINED — the ADR is silent on root-convention metadata (STRUCT-REFUSE-001). Excluded sets not classified by design (STRUCT-EXCLUDE-001)."
		evidence_refs:       "plane_manifest_digest planes/9b220e4362cb · consumer graphs fb-json/427512531063 · beta-gov/2888e713ec59 · targets/7d556a62610e · katas/10eb412b3544 · schemas/b96c22a5e279 · runtime/abd4e1f0ef0a · f1f2-rehome/e19f39eaedee"

		aspect_ext: {
			policy_authority: "docs/architecture/decisions/repository-planes.md @ 48b9a63 (v1.1)"

			// Computed here where `requirements` is in scope (the derivation shape is
			// declared in #StructureReceipt; this fills its mechanical-requirement set).
			derivation: mechanical_requirements: [for r in requirements if r.class == "mechanical" || r.class == "mechanical + semantic" {r.id}]

			// α — plane classification (top-level tracked areas → resolved plane).
			plane_classification: {
				"spec/": {files:        7, resolved_plane:  "spec (bind)", verdict:            "clean — canonical"}
				"src/": {files:         80, resolved_plane: "src (run)", verdict:              "clean — engine + skills canonical"}
				"conformance/": {files: 12, resolved_plane: "conformance (prove)", verdict:    "clean — foundation-v4 canonical"}
				"research/": {files:    26, resolved_plane: "research (still change)", verdict: "clean — incl. this CM tree, legibility, ascent"}
				"docs/": {files:        54, resolved_plane: "docs (help person)", verdict:      "MIXED — 4 of 8 present subfolders defective"}
				"scripts/": {files:     24, resolved_plane: "scripts (automate)", verdict:      "clean"}
				"targets/": {files:     7, resolved_plane:  "→ src/engine (ADR Iter 3)", verdict:    "DEFECT (STRUCT-PLANE-001, deferred) F9"}
				"katas/": {files:       19, resolved_plane: "→ a tests plane (ADR)", verdict:        "DEFECT (STRUCT-PLANE-001, deferred) F10"}
				"schemas/": {files:     14, resolved_plane: "→ co-located w/ owners", verdict:       "DEFECT (STRUCT-PLANE-001, deferred) F11"}
				"runtime/": {files:     1, resolved_plane:  "→ co-located w/ skill", verdict:        "DEFECT (STRUCT-PLANE-001 + FUNC-001) F12"}
				"root files": {files:   11, resolved_plane: "ADR silent", verdict:                   "UNDERDETERMINED (convention)"}
			}

			// canonical_path_map (ADR program-mapped homes).
			canonical_path_map: {
				"spec/":                          "satisfied"
				"src/engine/ocaml/":              "satisfied"
				"conformance/foundation-v4/":     "satisfied"
				"research/ascent/":               "satisfied"
				"research/repository-coherence/": "satisfied"
				"research/foundation/":           "N/A"
				"docs/quickstart/README.md":      "satisfied"
				"docs/architecture/README.md":    "satisfied"
				"targets/":                       "violated"
				"katas/":                         "violated"
				"schemas/":                       "violated"
				"runtime/SELF-MEASURE.md":        "violated"
				"docs/alpha/":                    "violated"
				"docs/beta/":                     "violated"
				"docs/gamma/":                    "violated"
				"docs/design/":                   "violated"
			}
		}

		// Findings F3–F12 (F1/F2 CLOSED since run 0001, not re-listed as active).
		// move_candidate marks repair-ready move/split/delete proposals — F4, F7,
		// F8, F9–F12 (each carries a consumer_search block); F3/F5/F6 are
		// naming/taxonomy violations that establish a defect but propose no move at
		// this snapshot (consumer_search: null). destination_resolved is derived
		// from repairability (¬POLICY_REQUIRED).
		findings: [
			{
				id: "F3", requirement: ["STRUCT-NAME-001", "STRUCT-DOCSET-001"], adr_clause: "ADR §Docs taxonomy + v1.1 §1", severity: "P1"
				claim:           "docs/alpha/ files by α role grammar and is outside the closed eight."
				repairability:   "MECHANICAL"
				move_candidate:  false
				consumer_search: null
				evidence:        "docs/alpha/README.md:1 \"Alpha (α) — Pattern coherence\"."
			},
			{
				id: "F4", requirement: ["STRUCT-NAME-001", "STRUCT-DOCSET-001", "STRUCT-CONSUMER-001"], adr_clause: "ADR §Docs taxonomy + v1.1 §1; Invariants", severity: "P1"
				claim:          "docs/beta/ files by β role grammar, outside the eight; its governance/ subtree carries live consumers."
				repairability:  "POLICY_REQUIRED"
				move_candidate: true
				evidence:       "docs/beta/README.md:1 \"Beta (β) — Relational coherence\"; β consumer graph."
				consumer_search: {
					surfaces_searched: ["source code", "CI workflows", "scripts", "Markdown links"]
					search_strength:   "complete_within_bound"
					consumers: [
						"src/engine/ocaml/lib/factorized_beta_gate.ml:242 (provenance emitted in engine output)",
						"factorized_beta.ml:4 · factorized_beta_gate.ml:4",
						".github/workflows/factorized-beta-measure.yml:3 · scripts/factorized-beta-measure.sh:3",
						"runtime/SELF-MEASURE.md:313 (METER-LOOP-DECISION.md)",
						"CHANGELOG.md:61,78 · docs/evidence/releases/0.12.0.md:46",
						".github/workflows/ci.yml:67 (names docs/beta/governance/ a LIVE machine-dependency)",
					]
					digest: "beta-gov/2888e713ec59"
				}
			},
			{
				id: "F5", requirement: ["STRUCT-NAME-001", "STRUCT-DOCSET-001"], adr_clause: "ADR §Docs taxonomy + v1.1 §1", severity: "P1"
				claim:           "docs/gamma/ files by γ role grammar and is outside the closed eight."
				repairability:   "MECHANICAL"
				move_candidate:  false
				consumer_search: null
				evidence:        "docs/gamma/README.md:1 \"Gamma (γ) — Process coherence\"."
			},
			{
				id: "F6", requirement: ["STRUCT-DOCSET-001"], adr_clause: "ADR v1.1 §1 (\"docs/design/ is not a ratified plane\")", severity: "P1"
				claim:           "docs/design/ is not one of the ratified eight; both bundles are placement defects to rehome. Destination refused → R1."
				repairability:   "POLICY_REQUIRED"
				move_candidate:  false
				consumer_search: null
				evidence:        "docs/design/foundation-contract-reconciliation/** (6 files), docs/design/polar-expression-recovery/DESIGN.md."
			},
			{
				id: "F7", requirement: ["STRUCT-CONSUMER-001", "STRUCT-NAME-001"], adr_clause: "Invariants (targets resolve; validator exits 0; no meaning change)", severity: "P0"
				claim:          "factorized-beta-controls.json is a role-grammar-placed live fixture; a move MUST rehome its seven enumerated consumers."
				repairability:  "POLICY_REQUIRED"
				move_candidate: true
				evidence:       "β consumer_search (digest fb-json/427512531063)."
				consumer_search: {
					surfaces_searched: ["source code", "tests", "CI workflows", "Markdown links", "config literals"]
					search_strength:   "complete"
					consumers: [
						"src/engine/ocaml/bin/main.ml:731,759 (runtime CLI default path)",
						"src/engine/ocaml/test/test_factorized_beta_gate.ml:199,210,224,250",
						"src/engine/ocaml/test/test_factorized_beta.ml:324",
						"src/engine/ocaml/lib/factorized_beta.ml:712 (doc comment)",
						".github/workflows/factorized-beta-measure.yml:225,230 (indirect — resolves the main.ml default)",
						"docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md:17,327,334 (links)",
						"docs/evidence/releases/0.12.0.md:46 (evidence cross-ref)",
					]
					digest:              "fb-json/427512531063"
					unsearched_surfaces: ["targets/schemas literals searched, none reference the json"]
				}
			},
			{
				id: "F8", requirement: ["STRUCT-MIXED-001"], adr_clause: "ADR v1.1 §3 precedent", severity: "P1"
				claim:          "docs/beta/ interleaves declared-frozen snapshot content with live engine/CI-consumed governance under one tree."
				repairability:  "POLICY_REQUIRED"
				move_candidate: true
				evidence:       "Frozen label docs/README.md:38; live content docs/beta/governance/** per β graph; ci.yml:67."
				consumer_search: {
					surfaces_searched: ["source code", "CI workflows", "scripts", "Markdown links"]
					search_strength:   "complete_within_bound"
					consumers: ["docs/beta/governance/** live inputs per the β graph (digest beta-gov/2888e713ec59)"]
					digest: "beta-gov/2888e713ec59"
				}
			},
			{
				id: "F9", requirement: ["STRUCT-PLANE-001", "STRUCT-RULE-001"], adr_clause: "ADR Iter 3 + Migration (\"Remaining src/ moves\")", severity: "P1"
				claim:          "targets/ is a root peer to the six planes; ADR Iteration 3 folds it into the engine (src/)."
				repairability:  "DEFERRED"
				move_candidate: true
				evidence:       "root targets/ (7 files); ADR-staged."
				consumer_search: {
					surfaces_searched: ["source code", "tests", "scripts", "CI workflows"]
					search_strength:   "complete_within_bound"
					consumers: [
						"src/engine/ocaml/bin/main.ml:87,356,373,500,546 · lib/types.ml:12,23 (main.ml:356,500 runtime default registry)",
						"src/engine/ocaml/test/{test_target_registry,test_consistency,test_factorized_beta*}.ml",
						"scripts/{coherence-ledger,cm-consistency,factorized-beta-measure,render-self-measure}.sh",
						".github/workflows/{tsc-coherence-ledger,tsc-self-measure}.yml (coh resolves targets at runtime)",
					]
					digest: "targets/7d556a62610e"
				}
			},
			{
				id: "F10", requirement: ["STRUCT-PLANE-001"], adr_clause: "ADR Migration (\"katas/ to a tests plane\")", severity: "P1"
				claim:          "katas/ is a root peer to the six planes; ADR stages it to a tests plane."
				repairability:  "DEFERRED"
				move_candidate: true
				evidence:       "root katas/ (19 files); ADR-staged."
				consumer_search: {
					surfaces_searched: ["source code", "scripts", "CI workflows"]
					search_strength:   "complete_within_bound"
					consumers: [
						"src/engine/ocaml/{lib/kata.ml,bin/main.ml,test/test_kata.ml}",
						"scripts/{run-katas,cm-admissibility}.sh · .github/workflows/{ci,katas}.yml",
					]
					digest: "katas/10eb412b3544"
				}
			},
			{
				id: "F11", requirement: ["STRUCT-PLANE-001"], adr_clause: "ADR Migration (\"schemas co-located with owners\")", severity: "P1"
				claim:          "schemas/ is a root peer to the six planes; ADR stages it co-located with owners."
				repairability:  "DEFERRED"
				move_candidate: true
				evidence:       "root schemas/ (14 files); ADR-staged."
				consumer_search: {
					surfaces_searched: ["scripts", "CI workflows"]
					search_strength:   "complete_within_bound"
					consumers: [
						"scripts/ci/{validate-skill-frontmatter,validate-v4-conformance}.sh · scripts/render-self-measure.sh",
						".github/workflows/{ci,tsc-coherence-ledger,tsc-self-measure}.yml",
					]
					digest: "schemas/b96c22a5e279"
				}
			},
			{
				id: "F12", requirement: ["STRUCT-PLANE-001", "STRUCT-FUNC-001"], adr_clause: "ADR Migration + Iter 3 (\"not a single-occupant plane\")", severity: "P1"
				claim:          "runtime/ is a single-occupant root plane (one file); ADR co-locates SELF-MEASURE.md with its skill."
				repairability:  "DEFERRED"
				move_candidate: true
				evidence:       "git ls-files runtime/ → runtime/SELF-MEASURE.md only; ADR-staged."
				consumer_search: {
					surfaces_searched: ["source code", "scripts", "CI workflows", "Markdown links"]
					search_strength:   "complete_within_bound"
					consumers: [
						"src/engine/ocaml/{bin/main.ml,lib/(report,prompt,types,response_schema,factorized_beta,…)}",
						"src/skills/{self-measure,cm-of-cms}/SKILL.md",
						"scripts/{render-self-measure.sh,coh-self} · .github/workflows/{tsc-coherence-ledger,tsc-self-measure}.yml",
						"docs/quickstart/README.md:25 (the run-0001 QUICKSTART.md:25 consumer moved with F1)",
					]
					digest: "runtime/abd4e1f0ef0a"
				}
			},
		]

		// R1 — refusal (STRUCT-REFUSE-001): placement is a defect (F6), destination refused.
		refusals: [
			{
				id: "R1", requirement: "STRUCT-REFUSE-001"
				path:   "docs/design/foundation-contract-reconciliation/"
				reason: "The correct destination is not decided by the ADR (Migration/Deferred note leaves it operator-open); the CM flags the misplacement (F6) and refuses to name a home."
			},
		]
	}
}

// Methodology-only projection (issue #115 leaf spike): the aspect methodology
// PROGRAM = structure minus its concrete run (`receipt`). Additive — does NOT
// touch the `structure` expr above, whose export stays byte-identical to
// compiled/structure.json. This is the `.cm` leaf byte-identity target
// (cue export -e structure_source).
structure_source: {
	for k, v in structure if k != "receipt" {(k): v}
}
