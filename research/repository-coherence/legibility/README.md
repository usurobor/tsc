# research/repository-coherence/legibility/ — Repository Legibility Coherence CM

A declared methodology that measures whether this repository presents one
truthful, navigable, operable whole to the reader it claims to serve. It applies
TSC to its own repository.

**Status:** pre-normative research, v0.1. Not under `spec/` (not normative) and
not yet executable. Review-run for now.

## What is here

- `CM.md` — the methodology: governing claim, reader profile, four subcontracts,
  v4 receipt mapping, categorical statuses, refusal, and the measure→repair→
  review boundary.
- `requirements.md` — the stable `REPO-*` requirement IDs.
- `fixtures/` — positive and negative fixtures; `newcomer-tasks.md` is the
  primary semantic fixture (six front-door questions).
- `runs/` — retained per-commit receipts. `0001` measures current `main`.
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
