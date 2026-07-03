// schemas/skill.cue — CUE schema for SKILL.md frontmatter (tsc).
//
// Validated by scripts/ci/validate-skill-frontmatter.sh as the
// skill-validate CI job. Field shape, type, and enum constraints live
// here; file discovery, frontmatter extraction, and cross-file
// consistency checks (signal codes vs engine source, estimates vs the
// scoring-instruction contract) are owned by the script.
//
// Convention imported from cnos (schemas/skill.cue there): schemas are
// open (`...` at the end) so package-local extension keys pass through —
// loaders MUST ignore unknown keys. Hard-gate fields fail validation if
// missing; there is no exception ledger in tsc (one skill today — add a
// ledger only when debt actually exists).

package skill

#Skill: {
	// Hard gate: must be present, no exception.
	name:               string & =~"^[a-z][a-z0-9_/-]*$"
	description:        !=""
	governing_question: !=""
	triggers: [...string]

	// tsc scope enum: `repo` — the skill is about this repository itself;
	// `task-local` — scoped to one invocation; `global` — applies anywhere.
	scope: "repo" | "task-local" | "global"

	// `measurement` marks a skill whose body is the canonical, human-readable
	// declaration of a measurement procedure (mechanical/LLM split included).
	artifact_class: "skill" | "measurement" | "reference" | "deprecated"

	kata_surface: "embedded" | "external" | "none"
	inputs: [...string]
	outputs: [...string]

	visibility?: "internal" | "public"
	requires?: [...string]

	// Open: package-local extension keys pass through.
	...
}

// #CoherenceMethodology — the COMPARABLE contract for a coherence
// methodology (CM): a CUE-typed skill block describing how to measure
// the coherence of a presented thing. Anyone can supply their own CM —
// a skill whose typed block satisfies this definition — and a conforming
// consumer (`coh` with a methodology input; the renderer) can execute it.
// tsc's self-measurement is the 1st methodology: the tsc-repo CM applied
// to tsc itself (the 0th is the CM of CMs, #CMOfCMs below). A more
// generic "software tool repo CM" would be another instance of this same
// definition with its own corpus and prompts.
//
// Authority split (mirrors cnos wake-provider §3):
// - Methodology authority: what the measurement IS — targets, registry,
//   scoring instruction, the mechanical signal inventory, the LLM
//   estimate contract and its prohibitions, output conventions, ledger
//   cadence, CI gating intent.
// - Renderer authority: substrate encoding — YAML structure, action
//   versions, runner image, secret-name bindings, tool allowlists,
//   step layout, commit mechanics.
#CoherenceMethodology: {
	// ---- Measurement essence (required for every CM) ----------------

		// Named-target model inputs (existing engine surfaces).
		registry: !=""
		targets: [...string]
		cross_target: bool

		// Canonical LLM scoring instruction (the semantic contract).
		instruction: !=""

		// Where generated measurement state lands. Must stay inside .tsc/
		// (generated state is never canonical — ARCHITECTURE.md).
		output_root: string & =~"^\\.tsc(/|$)"

		default_mode: "mechanical" | "llm" | "hybrid" | "auto"

		// Consistency protocol: a methodology must be tested against the
		// same input repeatedly and the agreement of its outputs measured
		// and reported. The mechanical arm must be exactly reproducible
		// (identical bundle -> identical scores). The LLM arm's repeat
		// spread maps through the canonical barrier: delta_consistency =
		// max absolute pairwise difference over the response contract's
		// numeric fields; Coh_consistency = exp(-lambda * phi(delta))
		// (tsc-core §3.2). An instrument that cannot agree with itself is
		// incoherent as an instrument — this is alpha applied to the meter.
		consistency: {
			mechanical: "identical"
			llm_repeats: int & >=2
			llm_spread:  !=""
			// The executor of this protocol (optional: a supplied CM may name
			// its own instrument; tsc's methodologies name
			// scripts/cm-consistency.sh so the declared protocol has an
			// in-corpus owner).
			script?: !=""
			...
		}

		// Admissibility instrument (optional): the executable check that a
		// scorer reproduces the calibration commons before its readings of
		// anything else carry standing. Its self-test must reject the
		// trivial flatterer (all-1.0, perfect self-score).
		admissibility?: !=""

		// Standing scope (optional): how far standing earned under this
		// methodology reaches — declared, never inferred, so the fixed
		// point cannot sound stronger than its anchor base. The scope
		// promotes only when the mechanics change (registered challengers,
		// revealed held-out anchors), never by prose.
		standing?: {
			scope:                 "house-authored-public-commons" | "blind-external-anchors"
			admissibility:         "public-only" | "public-plus-heldout"
			heldout_status:        "none" | "registered-and-revealed"
			external_anchor_count: int & >=0
			llm_consistency_gate:  "reported-not-gating" | "passed" | "failed"
			llm_consistency_floor: float & >=0 & <=1
			...
		}

		// Mechanical contract: the deterministic backend and its full
		// signal inventory. The validation script cross-checks every
		// declared signal code against the engine source, so this block
		// cannot drift from what the engine actually computes.
		mechanical: {
			backend:     !=""
			determinism: !=""
			signals: {
				alpha: [...string]
				beta: [...string]
				gamma: [...string]
			}
		}

		// LLM contract: exactly what cognitive work is delegated, what the
		// model must never do, and how its output is validated. The
		// validation script cross-checks every declared estimate field
		// against the scoring instruction's output contract.
		llm: {
			estimates: [...string]
			must_not: [...string]
			validation: !=""
			providers: {
				local: !=""
				ci:    !=""
				...
			}
			// The delegation prompt for the CI witness step. Skill authority:
			// the renderer inlines it verbatim (with {target} substituted)
			// into the workflow's Claude CLI step.
			ci_prompt: !=""
			...
		}

	// ---- Deployment bindings (optional: a supplied CM is comparable
	// on the essence alone; a DEPLOYED CM binds command/render/ledger/ci
	// surfaces the way #SelfMeasure does) ------------------------------

		// Rendered command basename (deployed CMs).
		command?: string & =~"^[a-z][a-z0-9-]*$"

		// Render targets (renderer writes these; each carries a
		// DO-NOT-EDIT header pointing back at its skill).
		render?: {
			command_out:  !=""
			workflow_out: !=""
			...
		}

		// The per-release coherence ledger: one row per version increment,
		// appended by the rendered ledger workflow; commits between
		// releases do not write it. The skill owns the contract (path,
		// cadence, mode, script); the renderer owns the trigger and
		// commit mechanics.
		ledger?: {
			path:    !=""
			cadence: "version-increments"
			// hybrid: a row is the hybrid (mechanical + LLM witness)
			// measurement whenever the witness credential is present;
			// mechanical is the explicit, labeled fallback — and the only
			// honest mode for historical backfill, where a semantic
			// judgment of an old tree would not be reproducible. Every
			// row names its mode.
			mode: "hybrid"
			// A release row is never a single-sample semantic reading: the
			// ledger route samples the witness this many times per target
			// and the row records the sample count, the worst per-target
			// Coh_consistency, and the standing that reading carries. A
			// row with one sample carries NO standing.
			semantic_samples?: int & >=1
			script:       !=""
			workflow_out: !=""
			...
		}

		// CI intent. Mechanical runs ungated; the LLM witness is gated by
		// the PRESENCE of the named secret (llm_gate: secret-presence) —
		// no separate toggle to drift out of sync with the credential.
		// permission_intent uses logical names (contents.read) — the
		// renderer owns the substrate encoding.
		ci?: {
			llm_secret: !=""
			llm_gate:   "secret-presence"
			permission_intent: [...string]
			...
		}

	// Open: methodology extensions pass through.
	...
}

// #SelfMeasure — the 1st coherence methodology: tsc's repo CM applied to
// tsc itself, DEPLOYED (command + render + ledger + ci bindings are
// required here, optional in the core contract). The 0th methodology is
// the CM of CMs (skills/cm-of-cms/SKILL.md): the methodology that
// measures methodologies, including itself. The renderer
// (scripts/render-self-measure.sh) consumes this skill and materializes
// the substrate artifacts (coh-self command, measurement workflow,
// ledger workflow).
#SelfMeasure: #Skill & {
	artifact_class: "measurement"
	scope:          "repo"
	self_measure:   #CoherenceMethodology & {
		command!: _
		render!:  _
		ledger!:  _
		ci!:      _
	}
}

// #CMOfCMs — the 0th coherence methodology: measures coherence
// methodologies, itself included. Essence-only (no deployment bindings
// required): its mechanical arm is the object-CM's own executable
// verification battery plus the standard structural scorer over the
// CM's bundle; its LLM arm judges whether the CM's declaration,
// implementation, and instrument behavior still describe one system.
#CMOfCMs: #Skill & {
	artifact_class: "measurement"
	scope:          "repo"
	cm_of_cms:      #CoherenceMethodology
}
