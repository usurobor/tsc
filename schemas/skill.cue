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

// #SelfMeasure — typed self-measurement module schema.
//
// The self-measurement skill is a typed SKILL.md whose frontmatter carries a
// `self_measure:` block and whose body is the canonical human-readable
// account of how tsc measures itself. The `#SelfMeasure` definition
// validates the block's shape; the renderer (scripts/render-self-measure.sh)
// consumes it and materializes the substrate artifacts (the `coh-self`
// command and the tsc-self-measure workflow).
//
// Authority split (mirrors cnos wake-provider §3):
// - Skill authority: what self-measurement IS — targets, registry, scoring
//   instruction, the mechanical signal inventory, the LLM estimate contract
//   and its prohibitions, output conventions, CI gating intent.
// - Renderer authority: substrate encoding — YAML structure, action
//   versions, runner image, secret-name bindings, tool allowlists,
//   step layout.
#SelfMeasure: #Skill & {
	artifact_class: "measurement"
	scope:          "repo"

	self_measure: {
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

		// CI intent. Mechanical runs ungated; the LLM witness is gated by
		// a repo variable + secret. permission_intent uses logical names
		// (contents.read) — the renderer owns the substrate encoding.
		ci: {
			llm_gate_variable: !=""
			llm_secret:        !=""
			permission_intent: [...string]
			...
		}

		// Open: renderer fields not yet in #SelfMeasure pass through.
		...
	}
}
