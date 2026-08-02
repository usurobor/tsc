# Repository Coherence CM

**Status:** pre-normative research · v0.1
**Owns:** composition of coherence aspects. Not the file inspection, not repair,
not review.

## Governing question

At this exact repository snapshot, do the selected coherence aspects jointly
support treating the repository as one coherent system, and where do they
conflict or remain unmeasured?

## Signature

```text
RepositoryCoherenceCM(repository_snapshot, selected_aspects) → CompositeReceipt
```

The parent does **not** inspect files itself — the child aspect CMs do. The
parent composes aspects, never audiences.

## What the parent owns

Only these:

```text
exact repository commit
selected aspect CMs
child CM versions and profiles
same-snapshot enforcement
receipt collection
cross-aspect conflict retention
coverage
composite categorical result
measure / repair / review separation
```

It owns no file inventory, no schema, no shared ontology. Those belong to the
children (see "What the parent does not own").

## Common child receipt envelope

Every nested aspect CM returns at least:

```text
aspect: structure | legibility | operability
cm_version: …
profile: …
repository_commit: …
scope: …
status: …
findings: …
unobserved_surfaces: …
evidence: …
```

An aspect may add richer fields; the parent needs only this envelope.

## Parent statuses

Exactly four:

```text
COHERENT_WITHIN_MEASURED_ASPECTS
DEFECTS_FOUND
INCOMPLETE
CM_EXECUTION_FAILED
```

## Coverage

Coverage is a **required field**, not a status. Every composite receipt names
what it covered:

```text
measured_aspects:     [legibility]
unmeasured_aspects:   [structure]
unimplemented_aspects: [operability]
status: COHERENT_WITHIN_MEASURED_ASPECTS
```

No child receipt overwrites another. Example: legibility
`COHERENT_WITHIN_DECLARED_SCOPE` while structure `DEFECTS_FOUND` → parent
`DEFECTS_FOUND`; both findings are retained. This is exactly what this repository
already surfaced — newcomer legibility 6/6 PASS while the physical structural
migration (R7) stays open — and the parent must say both.

## Aspect · Profile · Fixture

Three distinct things, kept distinct:

```text
Aspect    what property is measured
Profile   under whose assumptions
Fixture   the concrete task
```

## Requirements

Stable parent requirement IDs. Verbatim.

| ID | Requirement |
|---|---|
| `RCM-SNAPSHOT-001` | Every child receipt binds the same exact repository commit. |
| `RCM-SELECTION-001` | Every requested aspect either executes or is explicitly reported as unimplemented/incomplete. |
| `RCM-RECEIPT-001` | Every executed aspect returns an evidence-bound categorical receipt. |
| `RCM-COVERAGE-001` | Every composite claim names exactly which aspects and profiles it covers. |
| `RCM-CONFLICT-001` | Cross-aspect disagreement is retained and surfaced, never averaged away. |
| `RCM-NO-AGGREGATE-001` | No scalar or parent verdict may erase a child finding. |
| `RCM-BOUNDARY-001` | Parent and child CMs measure only; repair and independent review remain separate invocations. |

## What the parent does not own

The parent introduces no artifact manifest, no shared schema registry, no
universal ontology, and no common inventory. It owns none of that yet. It
composes aspect receipts on a shared commit and retains their conflicts — nothing
more.

Registered aspects and the decomposition rule live in `ASPECTS.md`. The one
implemented aspect lives under `legibility/`.
