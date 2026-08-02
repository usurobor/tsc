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
permanent; wording may sharpen. All fifteen IDs are unchanged at v0.2 — the v0.2
bump is execution discipline (commit-pinned fixtures, an explicit consumer-search
contract), not a new requirement (see [v0.2 execution discipline](#v02-execution-discipline)).
Fixture coverage is still seed-stage — not every ID has both a positive and a
negative fixture yet (see [Fixtures](#fixtures)).

| ID | Requirement | Class | Severity | ADR clause |
|---|---|---|---|---|
| `STRUCT-PLANE-001` | Every tracked path resolves to exactly one root plane; no path is a peer to the six planes or spans two. | mechanical | P0 | Target planes (root) |
| `STRUCT-RULE-001` | Each path's plane is the one the decision rule selects (*bind*→spec, *run*→src, *prove*→conformance, *still change*→research, *help a person*→docs, *automate*→scripts). | mechanical + semantic | P0 | Decision rule |
| `STRUCT-CANON-001` | Every artifact the ADR program-maps give a canonical home sits at that home. | mechanical | P0 | Program maps |
| `STRUCT-NAME-001` | Documentation is filed by reader intent; the α/β/γ role grammar is never used as a filing taxonomy. | mechanical + semantic | P1 | Docs reader-intent taxonomy ("α/β/γ … never a filing taxonomy") |
| `STRUCT-DOCSET-001` | The eight reader-intent folders are the exhaustive set of `docs/` subfolders; a `docs/` subfolder outside them is a defect to rehome. | mechanical + semantic | P1 | Amendments (v1.1) §1 ("the eight reader-intent folders … are the **exhaustive** set of `docs/` subfolders. A `docs/` subfolder outside them is a structural **defect to rehome**") |
| `STRUCT-FUNC-001` | No plane is a single-occupant or premature catch-all standing in for a real home. | semantic | P1 | Iteration 3 ("…not a single-occupant `config/` plane") |
| `STRUCT-OWNER-001` | Each artifact has one authoritative home; no duplicate live copies. | mechanical | P0 | Decision ("organize by plane") + Program maps ("navigated through indexes / program-maps, not physical co-location") |
| `STRUCT-CONSUMER-001` | Each placement/ownership finding enumerates the artifact's live consumers (code refs, CI, `targets/`, tests, links); a relocation that breaks a consumer without rehoming its reference is not coherent. | mechanical + semantic | P0 | Invariants any move commit must preserve ("targets resolve; conformance validator exits 0 …; no document's meaning changes") |
| `STRUCT-MIXED-001` | No live directory mixes live-mutable content with frozen, snapshot, or archived content. | mechanical + semantic | P0 | Migration state (frozen snapshots preserved intact) |
| `STRUCT-HISTLABEL-001` | Historical/archived/frozen material retained on the live tree carries a lifecycle label (banner or marker). | mechanical + semantic | P1 | Amendments (v1.1) §3 ("Historical, archived, or frozen material retained on the live tree must carry a lifecycle label — a banner or a marker") |
| `STRUCT-DERIVED-001` | Derived/generated output is distinguishable from hand-authored source (excluded build dir, generated marker, or clearly-derived path). | mechanical + semantic | P1 | Amendments (v1.1) §2 ("Derived or generated artifacts must be distinguishable from hand-authored source") + Invariants (render byte-identity) |
| `STRUCT-EXCLUDE-001` | The do-not-touch set (`.cdd/`, `.cn-sigma/`, `heldout/`) is excluded from content classification, never flagged as misplaced content. | mechanical | P0 | Do NOT touch |
| `STRUCT-REFUSE-001` | When the ADR does not decide a path's home, the CM returns `UNDERDETERMINED` for that path and does not assign a plane. | process | P0 | Deferred — foundation bundle ("a decision to take with the operator's frame, not to force here") |
| `STRUCT-REPAIR-001` | A repair run changes only findings in scope and preserves meaning; a move commit changes no document's meaning (evidence-boundary rule). | process | P0 | Invariants ("No meaning change, not no edits") |
| `STRUCT-REVIEW-001` | A `COHERENT_WITHIN_DECLARED_SCOPE` claim requires an independent full-scope review, separate from the repair actor. | process | P0 | Parent `RCM-BOUNDARY-001` |

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

The target is a **positive** fixture (a path that satisfies the ID in its
canonical plane) and a **negative** fixture (a state that violates it, with the
exact evidence the CM should surface) for each ID. Every fixture is pinned to an
exact `repository_commit` (v0.2). Coverage is honest seed-stage, not complete:

- Grounded by both a positive and a negative: `STRUCT-PLANE-001`,
  `STRUCT-RULE-001` (positive: the F1/F2 repaired homes `docs/quickstart/README.md`
  and `docs/architecture/README.md` @ `a01fbb8`; negative: root `QUICKSTART.md` /
  `ARCHITECTURE.md` @ `7514a21` — the frozen F1/F2 **regression pair**),
  `STRUCT-NAME-001`, `STRUCT-DOCSET-001` (positive: the eight ratified folders;
  negatives: the two `docs/design/` bundles @ `7514a21`).
- Grounded by both (new at v0.2): `STRUCT-MIXED-001` — negative `docs/beta/`
  @ `7514a21` (frozen snapshot + live engine/CI/test governance under one live
  tree). v0.1 wrongly declined MIXED here; v0.2 flips the fixture. Requirement
  wording unchanged.
- Positive + described negative: `STRUCT-DERIVED-001` (positive: `_build/`
  @ `7514a21`, generated-and-excluded; the mislabeled-generated negative is
  described, the tree offers none).
- Positive only: `STRUCT-CANON-001` (spec / engine / foundation-conformance in
  their canonical homes @ `7514a21`), `STRUCT-EXCLUDE-001` (the do-not-touch set
  excluded), and `STRUCT-HISTLABEL-001` (`docs/evidence/releases/0.12.0.md`
  "Historical" banner @ `7514a21`; no unlabelled-history negative in the tree —
  recorded honestly).
- Consumer case: `STRUCT-CONSUMER-001` (`docs/beta/governance/fixtures/…json`
  with its **seven** enumerated consumers pinned @ `7514a21` — v0.1 pinned only
  three; run 0001 found the richer graph). The scoring surfaces are fixed by the
  consumer-search contract in [`CM.md`](./CM.md). This ID also carries the
  **near-miss regression fixture**: a methodology that reads the whole α/β/γ tree
  as deletable frozen history without building the consumer graph must FAIL
  @ `7514a21` — the repository's strongest structural regression test.
- Refusal case: `STRUCT-REFUSE-001` (the foundation bundle's *destination* stays
  open even though its placement is now a defect, @ `7514a21`).
- **No fixture yet:** `STRUCT-FUNC-001` and `STRUCT-OWNER-001` — the current tree
  offers no duplicate-live-copy negative for `STRUCT-OWNER-001` and no
  single-occupant-plane example for `STRUCT-FUNC-001`. Seeding these is future
  work.
- Process IDs (`STRUCT-REPAIR-001`, `STRUCT-REVIEW-001`) constrain the downstream
  wave, not the tree, so they carry no tree fixture.

Fixtures are drawn from this repository's own tree at pinned commits and the ADR's
recorded deferrals, so the CM demonstrably fires on real known debt (root
`QUICKSTART.md` / `ARCHITECTURE.md` @ `7514a21`, repaired @ `a01fbb8`;
`docs/beta/governance/` filing by α/β/γ role grammar; the two `docs/design/`
bundles outside the closed docs taxonomy) while still refusing to name a
*destination* the ADR leaves open. See [`fixtures/`](./fixtures/).

## v0.2 execution discipline

No new `STRUCT-*`; no new ADR policy.

The v0.2 bump adds **no** requirement ID and changes **no** ADR policy. It is
execution discipline authored from run 0001's escaped defects. Each change and the
escaped defect it closes:

```text
1  Commit-pinned fixtures        Every fixture carries a repository_commit. The
   closes: fixture staleness      F1/F2 QUICKSTART/ARCHITECTURE before/after is a
                                  frozen regression pair (defect @ 7514a21 → pass
                                  @ a01fbb8); the first repair no longer makes the
                                  fixture stale, it completes the pair.
2  Consumer-search contract      CM.md fixes the search surfaces and receipt
   closes: under-searched graph   fields; the factorized-beta consumer fixture is
                                  repinned to the real 7-consumer graph @ 7514a21,
                                  replacing the stale "three."
3  STRUCT-MIXED-001 fixture flip  docs/beta/ becomes the MIXED negative @ 7514a21;
   closes: false MIXED decline    v0.1 wrongly said docs/beta/ was "neither frozen
                                  nor a snapshot tree." Wording unchanged.
4  Near-miss regression fixture   A methodology that calls the α/β/γ tree deletable
   closes: consumer-graph bypass  frozen history without a consumer graph must
                                  FAIL @ 7514a21 (STRUCT-CONSUMER-001).
```
