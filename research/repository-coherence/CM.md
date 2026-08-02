# Repository Coherence CM

**v0.1**

This file is the parent contract; the aspect registry is [`ASPECTS.md`](./ASPECTS.md);
the implemented aspects live in [`legibility/`](./legibility/CM.md) and
[`structure/`](./structure/CM.md).

## Governing question

At this exact repository snapshot, do the selected coherence aspects jointly
support treating the repository as one coherent system, and where do they
conflict or remain unmeasured?

## Signature

```text
RepositoryCoherenceCM(repository_snapshot, selected_aspects) → CompositeReceipt
```

The parent does **not** inspect files; the child aspect CMs do. It composes
aspects, never audiences.

## Generic child receipt envelope

Every child aspect CM returns a receipt satisfying this interface:

```text
aspect_id:            <e.g. structure>
cm_version:           <e.g. 0.2>
profile:              <e.g. repository-planes-v1.1>
repository_commit:    <sha>
result_class:         PASS | DEFECT | INCOMPLETE | FAILED
status:               <aspect-specific categorical status>
scope:                …
findings:             …
refusals:             …
unobserved_surfaces:  …
evidence_refs:        …
```

The envelope carries **two** result fields, and the distinction is load-bearing:

- `result_class` is the **generic interface the parent composes**. It is one of
  exactly four values — the only receipt field the composition algorithm reads to
  derive the parent result:
  - `PASS` — the aspect executed fully and found no in-scope defect.
  - `DEFECT` — the aspect executed and established at least one in-scope defect.
  - `INCOMPLETE` — the aspect executed but its observation is incomplete or
    underdetermined (e.g. inventory or consumer search incomplete, or policy
    leaves the actionable question unresolved).
  - `FAILED` — the aspect CM could not execute a required mechanical step at all.
    Boundary: `FAILED` = could not run; `INCOMPLETE` = ran but could not fully
    conclude.
- `status` preserves the **child CM's richer categorical vocabulary**. It is
  retained verbatim and never collapsed.

Each child CM declares its own `status → result_class` mapping. Example
mappings:

```text
result_class: DEFECT      ↔  status: DEFECTS_FOUND
result_class: INCOMPLETE  ↔  status: UNDERDETERMINED
result_class: PASS        ↔  status: COHERENT_WITHIN_DECLARED_SCOPE
```

Because the mapping lives in the child, the parent never needs to know any
child's private status vocabulary. Hard-coding a child's status names into the
parent would be dispatch, not composition.

## Deterministic composition algorithm

1. Resolve every selected aspect in the registry ([`ASPECTS.md`](./ASPECTS.md)).
2. For each selected aspect: (a) verify it is implemented; (b) execute it against
   the exact requested snapshot; (c) validate the common receipt envelope;
   (d) reject any receipt bound to a different commit.
3. Retain all child receipts unchanged.
4. Retain and surface cross-aspect relations — agreements, complementary
   findings, tensions — for the reader, per `RCM-CONFLICT-001` /
   `RCM-NO-AGGREGATE-001`. In v0.1 these relations are surfaced, not used to gate
   the parent result; cross-aspect defect/conflict detection that changes the
   result class is deferred to a later parent version.
5. Derive coverage: selected, executed, unavailable, failed,
   registered-but-unselected. At least one aspect must be selected; an empty
   selection derives `INCOMPLETE` (coverage: nothing measured).
6. Derive the parent result from `result_class` alone, in this precedence — no
   weighting, no averaging, no "mostly coherent":
   - any child `FAILED` → `CM_EXECUTION_FAILED`
   - else any selected child unavailable or `INCOMPLETE` → `INCOMPLETE`
   - else any child `DEFECT` → `DEFECTS_FOUND`
   - else → `COHERENT_WITHIN_MEASURED_ASPECTS`

## Parent statuses

Exactly four:

```text
COHERENT_WITHIN_MEASURED_ASPECTS
DEFECTS_FOUND
INCOMPLETE
CM_EXECUTION_FAILED
```

## Parent α / β / γ

The parent is a complete CM, not a receipt collector: it manifests, relates, and
continues.

- **α — execution manifestation.** Did every selected CM execute on the same
  snapshot and emit a valid envelope? Records selected / unimplemented /
  incomplete children and enforces same-snapshot binding — every retained
  receipt names the one requested `repository_commit`.
- **β — cross-aspect atlas.** How child receipts agree, complement, conflict, or
  leave gaps. Every finding is retained; none is averaged, overwritten, or
  reduced to a scalar. In v0.1 the atlas surfaces these relations for the reader;
  it does not gate the parent result (deferred as in step 4).
- **γ — continuation.** Relative to the prior composite run, which aspects
  improved, regressed, stayed defective, or exposed a new issue. On the first
  composite run: `γ.status = BASELINE — no prior composite receipt`.

## What the parent does not own

The parent introduces no artifact manifest, no shared schema registry, no
universal ontology, and no common inventory. It composes aspect receipts on a
shared commit and retains their conflicts — nothing more.

## Requirements

The seven stable `RCM-*` requirements are defined in
[`requirements.md`](./requirements.md).
