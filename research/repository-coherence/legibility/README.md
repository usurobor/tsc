# research/repository-coherence/legibility/ — Repository Legibility Coherence CM

A declared methodology that measures whether this repository presents one
truthful, navigable, operable whole to the reader it claims to serve. It applies
TSC to its own repository.

**Status:** pre-normative research. Not under `spec/` (not normative).

- methodology: v0.2
- latest run: 0003 — [`runs/0003-current-main.md`](./runs/0003-current-main.md)
- measured snapshot: `48b9a635c59ec6ba00dd80ee7a48d1160d1e0656` (`48b9a63`)
- result: `COHERENT_WITHIN_DECLARED_SCOPE → PASS` (fixture 6/6)
- prior v0.1 runs: 0001, 0002 (+0002-review) frozen

## What is here

- `CM.md` — the methodology: governing claim, reader profile, four subcontracts,
  v4 receipt mapping, categorical statuses, refusal, and the measure→repair→
  review boundary.
- `requirements.md` — the stable `REPO-*` requirement IDs.
- `fixtures/` — positive and negative fixtures; `newcomer-tasks.md` is the
  primary semantic fixture (six front-door questions).
- `runs/` — retained per-commit receipts. `0003` measures current `main`.
- `results/` — cross-run comparisons (e.g. before/after cleanup).

## The one rule that shapes everything

The CM **measures**; it does not repair. Repair is a downstream wave that
consumes the frozen defect receipt; an independent review verifies closure.
Measuring and repairing in one invocation would destroy the evidence boundary.

## Why this and not the shipped self-measure

The shipped `src/skills/self-measure/` CM scores the v3.2 structural proxy and is
blind to newcomer comprehension, navigation, and information-architecture
identity. This methodology asks a declared, audience-scoped question, retains a
structured repository model, emits evidence-bound defects, and refuses authority
when observation is incomplete — a better demonstration of the general CM
architecture than a historical scalar.

## Graduation

If it survives its fixtures and real runs, `src/skills/legibility-coherence/` can
own the executable procedure. A normative contract under `spec/` is a later
question.
