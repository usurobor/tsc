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
what it covered — schematically:

```text
measured_aspects:      [ …the aspects that executed on this snapshot… ]
unmeasured_aspects:    [ …implemented aspects not run this composite… ]
unimplemented_aspects: [ …registered but unauthored aspects… ]
status: COHERENT_WITHIN_MEASURED_ASPECTS | DEFECTS_FOUND | INCOMPLETE | …
```

No child receipt overwrites another. When one aspect returns
`COHERENT_WITHIN_DECLARED_SCOPE` while another returns `DEFECTS_FOUND`, the parent
is `DEFECTS_FOUND` and **both** findings are retained — a clean reader-legibility
pass never erases an open structural defect, nor the reverse
(`RCM-CONFLICT-001`, `RCM-NO-AGGREGATE-001`). Which aspects hold which verdict at
any commit is execution state, recorded in `ASPECTS.md` and the aspect runs, not
here.

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

## Parent receipt shape — α / β / γ

The parent is not only a receipt collector; it emits its own three-role receipt.
These roles compose child receipts — they never re-inspect files, and they add no
shared ontology, manifest, or inventory.

- **α — selection & same-snapshot manifestation.** What the parent gathered:
  the selected child CMs; each child's version and profile; the same-snapshot
  evidence that every child receipt binds one identical commit
  (`RCM-SNAPSHOT-001`); and the children that are missing, unimplemented, or
  incomplete (`RCM-SELECTION-001`). A composite whose children do not share one
  commit is `CM_EXECUTION_FAILED`, not composed.
- **β — cross-aspect relation.** The child receipts placed side by side:
  cross-aspect agreements, cross-aspect tensions, and every retained finding.
  Findings are never averaged into a scalar and never overwrite one another
  (`RCM-CONFLICT-001`, `RCM-NO-AGGREGATE-001`); a tension between two aspects is
  surfaced as a tension, not resolved by the parent.
- **γ — continuation from the prior composite.** The change since the last
  composite receipt on this repository: aspect regressions, aspect improvements,
  and defects newly exposed by composing this snapshot's children. For a first
  composite run with no predecessor: `γ: BASELINE — no prior composite receipt`.

This gives the parent a complete receipt form. It adds no requirement and no
policy beyond the `RCM-*` IDs already stated above.

## What the parent does not own

The parent introduces no artifact manifest, no shared schema registry, no
universal ontology, and no common inventory. It owns none of that yet. It
composes aspect receipts on a shared commit and retains their conflicts — nothing
more.

Registered aspects, their methodology-versus-execution state, and the
decomposition rule live in `ASPECTS.md`. Each implemented aspect lives under its
own directory (`legibility/`, `structure/`), and each aspect's runs live under
that directory's `runs/`.
