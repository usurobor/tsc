# Skills

Typed Markdown modules: YAML frontmatter (the machine contract, validated
by `schemas/skill.cue`) + a body (the human-readable authority). Pattern
imported from cnos (`src/packages/*/skills/` there).

A skill here is not documentation *about* behavior — it is the
declaration behavior is rendered from. Rendered artifacts carry
DO-NOT-EDIT headers pointing back at their skill, and CI re-renders and
diffs so the two cannot drift.

## Index

- `cm-of-cms/` — the 0th coherence methodology: how coherence
  methodologies themselves are measured, this one included. Declares the
  consistency protocol (`scripts/cm-consistency.sh`), the admissibility
  instrument (`scripts/cm-admissibility.sh`, whose CI self-test proves a
  perfect self-score wins nothing), what measuring a CM means per axis,
  and the adversarial-CM doctrine (symmetric displacement, maximin
  standing, the commons as the real anchor).
- `self-measure/` — the 1st coherence methodology: how TSC measures
  itself — the targets, the fully mechanical pipeline, and the one
  narrowly scoped cognitive task delegated to an LLM. Rendered into the
  `coh self` command (`scripts/coh-self`) and the `tsc-self-measure` +
  `tsc-coherence-ledger` workflows by `scripts/render-self-measure.sh`.
  Includes the witness-response fixtures used by the CI smoke.

## Editing a skill

1. Edit the `SKILL.md`.
2. `scripts/ci/validate-skill-frontmatter.sh` — shape + cross-file checks.
3. `scripts/render-self-measure.sh` — re-render the substrate artifacts.
4. Commit the skill and the rendered artifacts together.
