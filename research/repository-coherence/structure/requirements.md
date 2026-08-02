# Repository Structural Coherence — requirements

Stable requirement IDs the CM checks against
[`repository-planes-v1.1`](../../../docs/architecture/decisions/repository-planes.md).
Each carries a class (mechanical or semantic), a default severity, and the ADR
clause it derives from. Every ID traces to a real ADR clause: where the governing
proposal's owned-concerns list goes beyond the ratified policy, the CM declines
(records it, see [`CM.md`](./CM.md), *Policy notes*) rather than inventing a rule.
The v1.1 amendment ratified the docs-taxonomy-closure, generated-vs-source, and
historical-labelling concerns — now `STRUCT-DOCSET-001`, `STRUCT-DERIVED-001`, and
`STRUCT-HISTLABEL-001`; cross-plane name-predictiveness stays declined. IDs are
permanent; wording may sharpen. Fixture coverage is seed-stage — not every ID has
both a positive and a negative fixture yet (see [Fixtures](#fixtures)).

| ID | Requirement | Class | Severity | ADR clause |
|---|---|---|---|---|
| `STRUCT-PLANE-001` | Every tracked path resolves to exactly one root plane; no path is a peer to the six planes or spans two. | mechanical | P0 | Target planes (root) |
| `STRUCT-RULE-001` | Each path's plane is the one the decision rule selects (*bind*→spec, *run*→src, *prove*→conformance, *still change*→research, *help a person*→docs, *automate*→scripts). | mechanical + semantic | P0 | Decision rule |
| `STRUCT-CANON-001` | Every artifact the ADR program-maps give a canonical home sits at that home. | mechanical | P0 | Program maps |
| `STRUCT-NAME-001` | Documentation is filed by reader intent; the α/β/γ role grammar is never used as a filing taxonomy. | mechanical + semantic | P1 | Docs reader-intent taxonomy ("α/β/γ … never a filing taxonomy") |
| `STRUCT-DOCSET-001` | The eight reader-intent folders are the exhaustive set of `docs/` subfolders; a `docs/` subfolder outside them is a defect to rehome. | mechanical + semantic | P1 | Amendments (v1.1) §1 ("the eight reader-intent folders … are the **exhaustive** set of `docs/` subfolders. A `docs/` subfolder outside them is a structural **defect to rehome**") |
| `STRUCT-FUNC-001` | No plane is a single-occupant or premature catch-all standing in for a real home. | semantic | P1 | Iteration 3 ("…not a single-occupant `config/` plane") |
| `STRUCT-OWNER-001` | Each artifact has one authoritative home; no duplicate live copies. | mechanical | P0 | Decision ("organize by plane") + Program maps ("navigated through indexes / program-maps, not physical co-location") |
| `STRUCT-CONSUMER-001` | Each move/split/delete finding enumerates the artifact's live consumers via the consumer-search contract ([`CM.md`](./CM.md)) — surfaces searched, search strength, consumer set, digest, unsearched surfaces; a relocation that breaks a consumer without rehoming its reference is not coherent. | mechanical + semantic | P0 | Invariants any move commit must preserve ("targets resolve; conformance validator exits 0 …; no document's meaning changes") |
| `STRUCT-MIXED-001` | No live directory mixes live-mutable content with frozen, snapshot, or archived content. | mechanical + semantic | P0 | Migration state (frozen snapshots preserved intact) |
| `STRUCT-HISTLABEL-001` | Historical/archived/frozen material retained on the live tree carries a lifecycle label (banner or marker). | mechanical + semantic | P1 | Amendments (v1.1) §3 ("Historical, archived, or frozen material retained on the live tree must carry a lifecycle label — a banner or a marker") |
| `STRUCT-DERIVED-001` | Derived/generated output is distinguishable from hand-authored source (excluded build dir, generated marker, or clearly-derived path). | mechanical + semantic | P1 | Amendments (v1.1) §2 ("Derived or generated artifacts must be distinguishable from hand-authored source") + Invariants (render byte-identity) |
| `STRUCT-EXCLUDE-001` | The do-not-touch set (`.cdd/`, `.cn-sigma/`, `heldout/`) is excluded from content classification, never flagged as misplaced content. | mechanical | P0 | Do NOT touch |
| `STRUCT-REFUSE-001` | When the ADR does not decide a path's home, the CM returns `UNDERDETERMINED` for that path and does not assign a plane. | process | P0 | Deferred — foundation bundle ("a decision to take with the operator's frame, not to force here") |
| `STRUCT-REPAIR-001` | A repair run changes only findings in scope and preserves meaning; a move commit changes no document's meaning (evidence-boundary rule). | process | P0 | Invariants ("No meaning change, not no edits") |
| `STRUCT-REVIEW-001` | A `COHERENT_WITHIN_DECLARED_SCOPE` claim requires an independent full-scope review, separate from the repair actor. | process | P0 | Parent `RCM-BOUNDARY-001` |

## v0.2 receipt obligations

v0.2 adds two receipt obligations on existing IDs: `STRUCT-CONSUMER-001` → the
`consumer_search` block; `STRUCT-REPAIR-001` → a `repairability` value; both
specified in [`CM.md`](./CM.md).

## Subcontract → requirement map

```text
Placement            STRUCT-PLANE-001 · STRUCT-RULE-001 · STRUCT-CANON-001 · STRUCT-EXCLUDE-001
Naming               STRUCT-NAME-001 · STRUCT-DOCSET-001
Ownership & function STRUCT-FUNC-001 · STRUCT-OWNER-001 · STRUCT-CONSUMER-001
Lifecycle            STRUCT-MIXED-001 · STRUCT-HISTLABEL-001 · STRUCT-DERIVED-001
Refusal (crosscut)   STRUCT-REFUSE-001
Process (boundary)   STRUCT-REPAIR-001 · STRUCT-REVIEW-001
```

## Removed in review (v0.1), now ratified under fresh IDs (v1.1)

`STRUCT-LIFECYCLE-001` was removed at v0.1: its content — "historical and
generated artifacts are labelled," "generated output does not read as
hand-authored source" — had no ratifying ADR clause at the time, and its lone
grounded rule (no mixed live/history) was already `STRUCT-MIXED-001`. The ID stays
**retired** — IDs are permanent, so `STRUCT-LIFECYCLE-001` is never reused.

`repository-planes-v1.1` (2026-08-02) ratified both dimensions the retired ID had
reached for. They return as **fresh** IDs, not the retired one: generated-vs-source
→ `STRUCT-DERIVED-001` (v1.1 Amendment 2), historical-labelling →
`STRUCT-HISTLABEL-001` (v1.1 Amendment 3). Cross-plane name-predictiveness remains
declined ([`CM.md`](./CM.md), *Policy notes*).

## Notes on the three process requirements

`STRUCT-REFUSE-001`, `STRUCT-REPAIR-001`, and `STRUCT-REVIEW-001` do not score a
path. `STRUCT-REFUSE-001` binds the CM to policy authority — it may not invent a
home the ADR withholds. `STRUCT-REPAIR-001` and `STRUCT-REVIEW-001` constrain how
the downstream repair wave and its closure run; the CM records whether a closure
satisfied them, but it does not itself move files or close.

## Fixtures

The concrete positive/negative cases, their commit pins, and honest coverage
gaps live in [`fixtures/`](./fixtures/) — not restated here. Each is immutable
(synthetic or a real path pinned to an exact `repository_commit`); every
move/split/delete case carries the consumer-search block and a `repairability`
value. Process IDs (`STRUCT-REPAIR-001`, `STRUCT-REVIEW-001`) constrain the
downstream wave, not the tree, so carry no tree fixture.
