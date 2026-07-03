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
// tsc's self-measurement is the 0th methodology: the tsc-repo CM applied
// to tsc itself. A more generic "software tool repo CM" would be another
// instance of this same definition with its own corpus and prompts.
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
		// Rendered command basename. The engine dispatches `coh self` to
		// this executable (git-style external subcommand).
		command: string & =~"^[a-z][a-z0-9-]*$"

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

		// Render targets (renderer writes these; both carry DO-NOT-EDIT
		// headers pointing back at this skill).
		render: {
			command_out:  !=""
			workflow_out: !=""
			...
		}

		// The per-release coherence ledger: one row per version increment,
		// appended by the rendered ledger workflow; commits between
		// releases do not write it. The skill owns the contract (path,
		// cadence, mode, script); the renderer owns the trigger and
		// commit mechanics.
		ledger: {
			path:    !=""
			cadence: "version-increments"
			// hybrid: a row is the hybrid (mechanical + LLM witness)
			// measurement whenever the witness credential is present;
			// mechanical is the explicit, labeled fallback — and the only
			// honest mode for historical backfill, where a semantic
			// judgment of an old tree would not be reproducible. Every
			// row names its mode.
			mode: "hybrid"
			script:       !=""
			workflow_out: !=""
			...
		}

		// CI intent. Mechanical runs ungated; the LLM witness is gated by
		// the PRESENCE of the named secret (llm_gate: secret-presence) —
		// no separate toggle to drift out of sync with the credential.
		// permission_intent uses logical names (contents.read) — the
		// renderer owns the substrate encoding.
		ci: {
			llm_secret: !=""
			llm_gate:   "secret-presence"
			permission_intent: [...string]
			...
		}

	// Open: methodology extensions pass through.
	...
}

// #SelfMeasure — the 0th coherence methodology: tsc's repo CM applied to
// tsc itself. The skill's frontmatter carries the methodology under the
// `self_measure:` key; its body is the human-readable authority. The
// renderer (scripts/render-self-measure.sh) consumes it and materializes
// the substrate artifacts (coh-self command, measurement workflow,
// ledger workflow).
#SelfMeasure: #Skill & {
	artifact_class: "measurement"
	scope:          "repo"
	self_measure:   #CoherenceMethodology
}
