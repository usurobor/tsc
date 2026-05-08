---
cycle: 26
issue: "Sub 3 (#23): Migrate tests Python → OCaml; remove all .py"
branch: cycle/26-test-migration
phase: scaffold
role: alpha
---

# Cycle 26 — Self-Coherence

**Gap:** <!-- α fills: named incoherence — what exists vs. what is expected -->

**Mode:** <!-- α fills: MCA / small-change / immediate-output -->

## §Skills

<!-- α fills: Tier 1 / Tier 2 / Tier 3 active skills -->

## §ACs

<!-- α fills: AC-by-AC check with evidence -->

| AC | Status | Evidence |
|----|--------|----------|
| AC1 — No Python in tracked content | | |
| AC2 — pyproject.toml removed if no Python remains | | |
| AC3 — dune runtest non-empty, exits 0 | | |
| AC4 — Test coverage of v3.2.0 chain (8 surfaces) | | |
| AC5 — CI runs dune runtest | | |
| AC6 — Decisions about legacy tests recorded | | |

## §Self-check

<!-- α fills: did α push ambiguity onto β? Is every claim backed by evidence in the diff? -->

## §Debt

<!-- α fills: known debt, deferred items -->

## CDD Trace

| Step | Artifact | Skills loaded | Decision |
|------|----------|---------------|----------|
| 0 Observe | — | — | <!-- α fills: gap observation --> |
| 1 Select | Issue #26 | — | Selected per CDD §3 (P1; master #23 cannot close while Sub 3 open). Policy drift: CHANGELOG v0.1.0 declares OCaml-only; Python test files remain tracked. |
| 2 Branch | `cycle/26-test-migration` | cdd | Branch created by γ from `origin/main` (be6c098), pre-flight passed. |
| 3 Bootstrap | `.cdd/unreleased/26/self-coherence.md` scaffold | cdd | Scaffold committed by γ at branch creation. |
| 4 Gap | `.cdd/unreleased/26/self-coherence.md` §Gap | — | <!-- α fills --> |
| 5 Mode | `.cdd/unreleased/26/self-coherence.md` §Mode | cdd, plan, review | <!-- α fills → MCA (P1 substantial: delete Python tests, create OCaml test suite, wire CI) --> |
| 6 Artifacts | <!-- α fills: list all artifact surfaces touched --> | | |
| 7 Self-coherence | `.cdd/unreleased/26/self-coherence.md` | cdd | <!-- α fills: AC-by-AC check completed --> |
| 7a Pre-review | `.cdd/unreleased/26/self-coherence.md` | cdd | <!-- α fills: pre-review gate rows --> |
