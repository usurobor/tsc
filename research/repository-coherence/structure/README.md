# research/repository-coherence/structure/ — Repository Structural Coherence CM

A declared methodology that measures whether every tracked artifact has one
clear place, name, owner, lifecycle, and relationship to the rest of the
repository — judged against the ratified planes policy, not against the CM's own
taste. It applies TSC to its own repository.

**Status:** pre-normative research, v0.2. Not under `spec/` (not normative). The
methodology is a timeless contract; what has been measured against it is the
execution state below and in [`../ASPECTS.md`](../ASPECTS.md).

## What is here

- `CM.md` — the methodology: governing claim, the `repository-planes-v1.1`
  profile, four subcontracts, the consumer-search contract, the parent-envelope
  receipt mapping, categorical statuses, refusal, and the measure→repair→review
  boundary.
- `requirements.md` — the stable `STRUCT-*` requirement IDs, each tied to the
  ADR clause it derives from.
- `fixtures/` — the plane-conformance fixture: commit-pinned positives, negatives
  drawn from the ADR's recorded deferrals, the F1/F2 regression pair, the
  commit-pinned consumer graph, and the surviving destination-refusal case.
- `runs/` — retained per-commit receipts.

## Latest run

```text
run 0001   structure aspect · cm_version 0.1 · profile repository-planes-v1.1
           measured commit 7514a21 (frozen receipt, immutable)
           status DEFECTS_FOUND (+ UNDERDETERMINED, R1)
           → runs/0001-current-main.md
```

Run 0001 is frozen at commit `7514a21`. Acting on that receipt, the first repair
wave landed at commit `a01fbb8`: it closed findings F1 and F2 by moving
`QUICKSTART.md` → `docs/quickstart/README.md` and `ARCHITECTURE.md` →
`docs/architecture/README.md`. The frozen run and the repaired tree together form
the F1/F2 regression pair pinned in [`fixtures/plane-conformance.md`](./fixtures/plane-conformance.md).

## v0.1 → v0.2 delta

v0.2 is execution discipline authored from run 0001's escaped defects; it keeps
all fifteen `STRUCT-*` requirements and the ADR unchanged. Each change closes a
specific escaped defect:

```text
1  commit-pinned fixtures       every fixture now carries a repository_commit;
                                the F1/F2 QUICKSTART/ARCHITECTURE before/after is a
                                frozen regression pair (7514a21 → a01fbb8), no
                                longer a fixture that goes stale on repair.
2  consumer-search contract     CM.md fixes the search surfaces and the receipt
                                fields (search_surfaces, search_strength,
                                consumer_set, consumer_set_digest,
                                unsearched_surfaces). The factorized-beta consumer
                                fixture is repinned to the real 7-consumer graph
                                run 0001 found @ 7514a21, replacing the stale
                                "three consumers."
3  STRUCT-MIXED-001 resolved    docs/beta/ is now the NEGATIVE fixture for
                                STRUCT-MIXED-001 (frozen snapshot + live engine/CI
                                governance under one role-grammar tree) @ 7514a21;
                                v0.1 had wrongly declined MIXED there. Requirement
                                wording unchanged — only the fixture flips.
4  near-miss regression case    a fixture that FAILS a methodology which classifies
                                the whole α/β/γ tree as frozen and recommends
                                deletion WITHOUT building the live consumer graph
                                (STRUCT-CONSUMER-001) @ 7514a21 — the repository's
                                strongest structural regression test.
```

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
