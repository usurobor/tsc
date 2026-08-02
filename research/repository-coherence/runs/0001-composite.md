# Composite run 0001 — Repository Coherence

The first same-snapshot composite. The parent
([`../CM.md`](../CM.md)) executes each selected aspect CM on one exact commit,
validates the generic child receipt envelope, retains both child receipts
unchanged, and derives one composite result from `result_class` alone. It
inspects no files itself.

```text
run:                0001 (composite)
cm:                 Repository Coherence CM · v0.1
repository_commit:  48b9a635c59ec6ba00dd80ee7a48d1160d1e0656  (main HEAD)
selected_aspects:   [legibility, structure]
date:               2026-08-02 (author's date; not machine-stamped)
```

## α — execution manifestation

Every selected aspect executed on the one requested snapshot and emitted a valid
envelope; `operability` is registered but not implemented, so it is reported, not
run. No child receipt binds a different commit (algorithm step 2(d)); no child
`FAILED`.

```text
aspect_id    cm_version  profile                    repository_commit  result_class  receipt
------------------------------------------------------------------------------------------------
legibility   0.2         technical-newcomer-human   48b9a63            PASS          legibility/runs/0003-current-main.md
structure    0.2         repository-planes-v1.1     48b9a63            DEFECT        structure/runs/0002-current-main.md
operability  —           —                          —                  —             NOT_IMPLEMENTED (registered, not scaffolded)
```

Same-snapshot enforcement (`RCM-SNAPSHOT-001`): both executed receipts name
`48b9a635c59ec6ba00dd80ee7a48d1160d1e0656`. Verified equal before composition.

## β — cross-aspect atlas

The two child receipts are retained side by side; relations are surfaced, not
averaged and (in parent v0.1) not used to gate the result (`RCM-CONFLICT-001` /
`RCM-NO-AGGREGATE-001`).

```text
AGREEMENTS
  · both bind 48b9a63 and read the same tree.
  · the front-door move is seen from both aspects and agrees:
      legibility R7 CLOSED  ↔  structure F1/F2 CLOSED
      (root QUICKSTART.md/ARCHITECTURE.md → docs/quickstart|architecture/README.md).
  · docs/beta/governance/ is a live machine input inside an otherwise-frozen tree:
      legibility N1 CLOSED (label now truthful)  ↔  structure F4/F8 (mixed live/frozen).

COMPLEMENTARY (different properties of the same tree, not disagreement)
  · legibility PASS is reader-facing coherence; structure DEFECT is physical
    plane placement. A path can be legible to a newcomer AND misplaced against
    the plane policy — these do not contradict.
  · legibility explicitly assigns the residual plane-placement debt
    (docs/design/ rehome, targets/, katas/) to the STRUCTURE aspect
    (repository-planes.md §1, §4) rather than scoring it — so structure's F3–F12
    are not double-counted by legibility.

FACTUAL CONFLICTS
  · none. No path carries contradictory factual claims across the two receipts.

UNRESOLVED RELATIONS
  · none.
```

## γ — continuation

```text
γ.status: BASELINE — no prior composite receipt.
```

## Coverage (`RCM-COVERAGE-001`)

```text
selected:                 [legibility, structure]
executed:                 [legibility, structure]
unavailable:              []
failed:                   []
registered-but-unselected/unimplemented: [operability]
profiles covered:         legibility · technical-newcomer-human
                          structure  · repository-planes-v1.1
```

## Composite result

Derived from child `result_class` by the parent's deterministic precedence
(`CM.md` step 6) — no weighting, no averaging:

```text
any FAILED?                         no
any unavailable / INCOMPLETE?       no  (legibility PASS, structure DEFECT)
any DEFECT?                         yes (structure → DEFECT)
------------------------------------------------------------------------
composite_status:  DEFECTS_FOUND
```

```text
composite_status:  DEFECTS_FOUND
warrant:           At 48b9a63, within the measured aspects and profiles,
                   legibility is coherent for the declared newcomer
                   (PASS, fixture 6/6) while structure has established plane
                   placement defects (DEFECT — F3–F12; R1 destination refused).
                   Both truths are retained; neither is collapsed into the other.
not covered:       operability (NOT_IMPLEMENTED); full-tree structural closure
                   (structure repair wave not yet run); operability-by-execution
                   of coh/kata exit codes (legibility refusal RUN-EXEC-01).
```

## Retained child receipts

Frozen, unchanged, and immutable — the parent composes them, it does not edit
them:

- **legibility** — [`../legibility/runs/0003-current-main.md`](../legibility/runs/0003-current-main.md)
  · `COHERENT_WITHIN_DECLARED_SCOPE` → `PASS` · newcomer fixture 6/6 · R7 + N1 closed
  · one bounded refusal (`RUN-EXEC-01`, coh exit codes not executed here).
- **structure** — [`../structure/runs/0002-current-main.md`](../structure/runs/0002-current-main.md)
  · `DEFECTS_FOUND` (+ `UNDERDETERMINED` R1) → `DEFECT` · F1/F2 closed; F3–F12 open,
  each typed `MECHANICAL | POLICY_REQUIRED | DEFERRED`; R1 destination refused.

## Standing

This is a **measurement composition**, not a repair and not a conformance claim.
Per `RCM-BOUNDARY-001`, repair and independent review are separate invocations.
The composite is reproducible on `48b9a63` and immutable once written. A future
`COHERENT_WITHIN_MEASURED_ASPECTS` composite requires the structure repair wave
to close F3–F12 (where policy decides the destination) and the operator to decide
the `POLICY_REQUIRED` homes, then a fresh composite on the repaired commit.
