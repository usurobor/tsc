// schemas/cm.cue — CUE contract for a CM authored as a typed DOCUMENT
// (the α-Parts / β-Fit / γ-Evolve grammar), not for SKILL.md frontmatter.
//
// ─────────────────────────────────────────────────────────────────────
// Relationship to schemas/skill.cue #CoherenceMethodology — EXTENDS,
// does NOT supersede.
// ─────────────────────────────────────────────────────────────────────
//
//   - #CoherenceMethodology (schemas/skill.cue) remains the canonical
//     COMPARABLE CONTRACT for a CM's SKILL.md FRONTMATTER: registry,
//     targets, instruction, the mechanical signal inventory, the LLM
//     estimate contract, consistency block, standing scope. It is
//     unchanged and still governs deployed skills (#SelfMeasure,
//     #CMOfCMs). Nothing here weakens or replaces it.
//   - #CMDocument (this file) is a NEW, ADDITIONAL surface: the typed
//     shape of the CM0 DOCUMENT (docs/beta/governance/CM0.md) and of any
//     candidate CM authored in the same grammar. It types the required
//     organ set, relation set, evolution-clause set, and the H2-clause
//     shape that Sub-3's `coh cm-compile` will typecheck against.
//
// Why EXTENDS and not import: CUE-level `import` needs a module
// (cue.mod), and this repo vets by passing files directly to `cue vet`
// (see scripts/ci/validate-skill-frontmatter.sh). So #CMDocument is a
// self-contained package `cm` with no cross-file CUE import. The linkage
// to #CoherenceMethodology is SEMANTIC and kept explicit here so the two
// contracts cannot diverge silently:
//
//   frontmatter `consistency` block  ⟷  the `consistency` α-organ +
//                                        the `consistency-standing`
//                                        β-relation of this document
//   frontmatter `standing` block     ⟷  the `standing-discipline`
//                                        γ-clause of this document
//   frontmatter mechanical.signals   ⟷  the `evidence` α-organ's
//                                        mechanical_checks
//
// A CM that is BOTH deployed and authored in this grammar must satisfy
// #CoherenceMethodology (its frontmatter) AND #CMDocument (its body);
// the shared vocabulary above is the seam that keeps them one system.
//
// Surface boundary (same discipline as skill.cue): this file owns SHAPE,
// TYPE, and REQUIRED-SET constraints only. Extracting the typed blocks
// from CM0.md into data, section-presence over the rendered Markdown, and
// cross-file checks are the validator's job, not CUE's.

package cm

// The four axes of the migrated CM0 decomposition:
//   alpha  — Parts        (the organs a methodology must HAVE)
//   beta   — Fit          (the relations its parts must satisfy)
//   gamma  — Evolve       (how it changes without lying about old readings)
//   consistency — standing (the cross-cutting standing axis pulled OUT of
//                 the old α; measured, not authored as a document section)
//
// NOTE on the `consistency` organ vs the `consistency` axis: the document
// is authored under THREE H1s (α/β/γ). The `consistency` α-organ is the
// PART that declares the consistency protocol; the `consistency` AXIS is
// the standing dimension that organ feeds. They are linked by the
// `consistency-standing` β-relation. So the organ's `axis` is "alpha"
// (it is an α-Part), while "consistency" as an `axis` value tags a clause
// that lives on the standing axis itself.
#Axis: "alpha" | "beta" | "gamma" | "consistency"

// #Clause — the shape every H2 in a CM document compiles to. A clause is
// a MEASURABLE unit, not prose: it names its evidence and the mechanical
// and semantic checks that decide it, the ways it fails, and the actions
// a failure triggers.
#Clause: {
	// Stable slug; equals the organ/relation/clause key it is filed under.
	id:   string & =~"^[a-z][a-z0-9-]*$"
	axis: #Axis

	// What is inspected to decide this clause (must be concrete, non-empty).
	evidence: !=""

	// Deterministic checks (may be empty for an irreducibly-semantic
	// clause) and semantic/witness checks (may be empty for a purely
	// mechanical clause) — but a clause with NEITHER is unmeasurable and
	// rejected by #NonEmptyChecks below.
	mechanical_checks: [...(string & !="")]
	semantic_checks: [...(string & !="")]

	// A clause must name at least one way it fails and at least one action
	// a failure triggers — otherwise it is decoration, not an instrument.
	failure_modes: [string & !="", ...(string & !="")]
	actions: [string & !="", ...(string & !="")]

	// Every clause is measurable: at least one check of either kind.
	#NonEmptyChecks
	...
}

// A clause must carry at least one mechanical OR semantic check.
#NonEmptyChecks: {
	mechanical_checks: [...]
	semantic_checks: [...]
	_total: len(mechanical_checks) + len(semantic_checks)
	_total: >=1
}

// #MigrationRule — one row of the ## Migration Rules ledger. Old readings
// must remain interpretable (the γ discipline the 0th methodology demands
// of everyone, itself included).
#MigrationRule: {
	from:          !="" // the old surface (e.g. "α = instrument self-agreement / consistency")
	to:            !="" // where it maps in the new decomposition
	interpretable: bool  // old readings still have a defined reading?
	note?:         string
	...
}

// #CMDocument — a CM authored in the α-Parts / β-Fit / γ-Evolve grammar.
// The required-organ closure is enforced by naming each required key as a
// REGULAR (non-optional) field: a document missing an organ leaves that
// field non-concrete and `cue vet` fails — that is the negative oracle.
#CMDocument: {
	// SemVer of the CM DOCUMENT (distinct from the repo VERSION). An
	// axis rename bumps this — the migration is a versioned event.
	version: string & =~"^[0-9]+\\.[0-9]+\\.[0-9]+$"

	// γ history status. A brand-new CM is "provisional"/"insufficient-
	// history" and MUST still be an admissible candidate — the contract
	// never rejects a document for lacking evolution history.
	gamma_status: *"provisional" | "established" | "insufficient-history"

	// ── α — Parts: the twelve required organs ────────────────────────
	// Each is a regular field ⇒ absence fails vet (the AC2 negative case).
	alpha_parts: {
		purpose:        #Clause & {axis: "alpha", id: "purpose"}
		scope:          #Clause & {axis: "alpha", id: "scope"}
		axes:           #Clause & {axis: "alpha", id: "axes"}
		evidence:       #Clause & {axis: "alpha", id: "evidence"}
		preregs:        #Clause & {axis: "alpha", id: "preregs"}
		factorization:  #Clause & {axis: "alpha", id: "factorization"}
		judgment:       #Clause & {axis: "alpha", id: "judgment"}
		aggregation:    #Clause & {axis: "alpha", id: "aggregation"}
		consistency:    #Clause & {axis: "alpha", id: "consistency"}
		discrimination: #Clause & {axis: "alpha", id: "discrimination"}
		refusal:        #Clause & {axis: "alpha", id: "refusal"}
		report:         #Clause & {axis: "alpha", id: "report"}
	}

	// ── β — Fit: the eight required relations ─────────────────────────
	beta_fit: {
		"purpose-axes":           #Clause & {axis: "beta", id: "purpose-axes"}
		"axes-evidence":          #Clause & {axis: "beta", id: "axes-evidence"}
		"evidence-factorization": #Clause & {axis: "beta", id: "evidence-factorization"}
		"prereg-axis":            #Clause & {axis: "beta", id: "prereg-axis"}
		"prereg-success-gate":    #Clause & {axis: "beta", id: "prereg-success-gate"}
		"judgment-aggregation":   #Clause & {axis: "beta", id: "judgment-aggregation"}
		"consistency-standing":   #Clause & {axis: "beta", id: "consistency-standing"}
		"findings-actions":       #Clause & {axis: "beta", id: "findings-actions"}
	}

	// ── γ — Evolve: the seven required evolution clauses ──────────────
	gamma_evolve: {
		versioning:               #Clause & {axis: "gamma", id: "versioning"}
		"experiment-failed-memory": #Clause & {axis: "gamma", id: "experiment-failed-memory"}
		migration:                #Clause & {axis: "gamma", id: "migration"}
		"standing-discipline":    #Clause & {axis: "gamma", id: "standing-discipline"}
		"change-isolation":       #Clause & {axis: "gamma", id: "change-isolation"}
		governance:               #Clause & {axis: "gamma", id: "governance"}
		"re-entry":               #Clause & {axis: "gamma", id: "re-entry"}
	}

	// ── ## Migration Rules — at least one row (a CM that changes an axis
	// MUST record the mapping; the migration γ-clause self-references it).
	migration_rules: [#MigrationRule, ...#MigrationRule]

	// Open: candidate CMs may carry extension keys.
	...
}
