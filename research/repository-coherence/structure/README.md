# research/repository-coherence/structure/ — Repository Structural Coherence CM

A declared methodology that measures whether every tracked artifact has one
clear place, name, owner, lifecycle, and relationship to the rest of the
repository — judged against the ratified planes policy, not against the CM's own
taste. It applies TSC to its own repository.

**Status:** pre-normative research, v0.1 — authored, not yet run. Not under
`spec/` (not normative) and not yet executable.

## What is here

- `CM.md` — the methodology: governing claim, the `repository-planes-v1`
  profile, four subcontracts, the parent-envelope receipt mapping, categorical
  statuses, refusal, and the measure→repair→review boundary.
- `requirements.md` — the stable `STRUCT-*` requirement IDs, each tied to the
  ADR clause it derives from.
- `fixtures/` — the plane-conformance fixture: canonical positives, negatives
  drawn from the ADR's recorded deferrals, and one `UNDERDETERMINED` case.

No `runs/` yet — there are no runs. Measurement is a later, separate invocation
that follows convergence; `runs/` appears then, mirroring the sibling legibility
layout (which has `runs/` because it has runs).

## The one rule that shapes everything

The CM **measures**; it does not repair. Repair is a downstream wave that
consumes the frozen defect receipt; an independent review verifies closure.
Measuring and relocating files in one invocation would destroy the evidence
boundary.

## Why this aspect

Placement, naming, ownership, and lifecycle are a distinct property from whether
a reader can navigate the repository (legibility) or an actor can run its
procedures (operability). Structure is largely audience-independent: its profile
is a **policy** — the ratified
[planes ADR](../../../docs/architecture/decisions/repository-planes.md) — and the
CM's job is to check the tree against that policy and refuse where the policy is
silent, not to invent what "clean" means.

## Graduation

If it survives its fixtures and real runs, `src/skills/structural-coherence/`
can own the executable procedure. A normative contract under `spec/` is a later
question.
