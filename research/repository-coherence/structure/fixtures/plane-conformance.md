# Plane-conformance fixtures

The primary structural fixture. Structure is **policy-conformance**, so the
discriminating test is not a fresh-reader task but a classification of real paths
against [`repository-planes-v1.1`](../../../../docs/architecture/decisions/repository-planes.md).
Each row names a path, an **exact `repository_commit`**, the expected verdict, the
`STRUCT-*` it exercises, and the evidence the CM must surface.

## Commit-pinned fixtures (v0.2)

Every fixture describes **either** a synthetic minimal tree **or** a real
repository state pinned to an exact commit — never an unpinned "current tree,"
which goes stale the moment a repair lands. All fixtures below are real repository
states, each pinned to its `repository_commit`. Pinning turns the first repair
(F1/F2, landed at `a01fbb8`) from a source of fixture staleness into a permanent
**regression pair**: the pre-repair defect at `7514a21` and the post-repair pass
at `a01fbb8` are both frozen, both true, and together prove the CM fires before
the move and clears after it.

```text
7514a21   run 0001's measured commit — the pre-repair tree (defects live here)
a01fbb8   first repair wave — QUICKSTART/ARCHITECTURE moved into docs/ planes
```

A verdict is a property of a `(path, repository_commit)` pair, not of a bare path.

## Positive fixtures — path in its canonical plane

| Path | `repository_commit` | Verdict | Exercises | Why it passes |
|---|---|---|---|---|
| `spec/` | `7514a21` | `COHERENT_WITHIN_DECLARED_SCOPE` | `STRUCT-PLANE-001` · `STRUCT-RULE-001` · `STRUCT-CANON-001` | *Binds* implementations and methodologies → `spec/`; the ADR program-map names `spec/` as the specification home. Resolves to exactly one plane. |
| `src/engine/ocaml/` | `7514a21` | `COHERENT_WITHIN_DECLARED_SCOPE` | `STRUCT-RULE-001` · `STRUCT-CANON-001` | *Runs* → `src/`; the program-map names `src/engine/ocaml/` as the engine home. Resolves to one plane, at its canonical path. |
| `conformance/foundation-v4/` | `7514a21` | `COHERENT_WITHIN_DECLARED_SCOPE` | `STRUCT-CANON-001` | *Proves the spec* → `conformance/`; the program-map names `conformance/foundation-v4/` as the foundation conformance home. |
| `.cdd/` | `7514a21` | `COHERENT_WITHIN_DECLARED_SCOPE` (excluded) | `STRUCT-EXCLUDE-001` | In the do-not-touch set — tooling/data, not content. The CM excludes it, never flags it as misplaced. |
| `_build/` (dune output) | `7514a21` | `COHERENT_WITHIN_DECLARED_SCOPE` (derived) | `STRUCT-DERIVED-001` | Generated dune output, `.gitignore`d and excluded from tracked content. Distinguishable from hand-authored source by exclusion — exactly the v1.1 §2 signal ("excluded build directory"). |
| `docs/evidence/releases/0.12.0.md` | `7514a21` | `COHERENT_WITHIN_DECLARED_SCOPE` (labelled) | `STRUCT-HISTLABEL-001` | Historical material on the live tree carrying a "**Historical.**" banner — the v1.1 §3 precedent. The label is present, so the lifecycle-label rule is satisfied. |
| `docs/quickstart/README.md` | `a01fbb8` | `COHERENT_WITHIN_DECLARED_SCOPE` | `STRUCT-PLANE-001` · `STRUCT-RULE-001` | *Helps a person* → the `quickstart` reader-intent plane. After the F1 repair the artifact sits at its canonical docs home, no longer a root peer. Positive half of the F1 regression pair. |
| `docs/architecture/README.md` | `a01fbb8` | `COHERENT_WITHIN_DECLARED_SCOPE` | `STRUCT-PLANE-001` · `STRUCT-RULE-001` | *Helps a person* → the `architecture` reader-intent plane. After the F2 repair the artifact sits at its canonical docs home. Positive half of the F2 regression pair. |

## Negative fixtures — real known debt, pinned pre-repair

| Path | `repository_commit` | Verdict | Exercises | Evidence the CM must surface |
|---|---|---|---|---|
| `QUICKSTART.md` (root) | `7514a21` | `DEFECTS_FOUND` | `STRUCT-RULE-001` · `STRUCT-PLANE-001` | *Helps a person* → belongs under the docs `quickstart` plane, not the root. At `7514a21` it sits at root as a peer to the six planes (was run 0001's F1). Consumers to rehome: `README.md:23,40`; `docs/README.md:10,25`. Negative half of the F1 regression pair; repaired at `a01fbb8` (positive above). |
| `ARCHITECTURE.md` (root) | `7514a21` | `DEFECTS_FOUND` | `STRUCT-RULE-001` · `STRUCT-PLANE-001` | *Helps a person* → belongs under the docs `architecture` plane, not the root. At `7514a21` it is a live root file peer to the planes (run 0001's F2). Consumer to rehome: `src/skills/self-measure/SKILL.md:247`. Negative half of the F2 regression pair; repaired at `a01fbb8` (positive above). |
| `docs/beta/governance/` | `7514a21` | `DEFECTS_FOUND` | `STRUCT-NAME-001` · `STRUCT-RULE-001` | `docs/beta/` files by α/β/γ role grammar, which the ADR explicitly bars as a docs filing taxonomy; the governance content belongs under a reader-intent plane, not a role-grammar folder. (For the live/frozen mixing at this same path see the `STRUCT-MIXED-001` fixture below — v0.2 no longer declines MIXED here.) |
| `docs/design/foundation-contract-reconciliation/` | `7514a21` | `DEFECTS_FOUND` | `STRUCT-DOCSET-001` | `docs/design/` is outside the closed reader-intent taxonomy (v1.1 §1 makes the eight folders exhaustive), so the bundle is a placement **defect to rehome**. Misplacement is determined; the correct **destination** stays operator-undecided (refusal row below). One path, two verdicts: DEFECT on placement, refusal on destination. |
| `docs/design/polar-expression-recovery/` | `7514a21` | `DEFECTS_FOUND` | `STRUCT-DOCSET-001` | Same closed-taxonomy defect: `docs/design/` is not one of the ratified eight, so the bundle is misplaced. A placement DEFECT under v1.1 §1 — no longer `UNDERDETERMINED`. |

## Consumer fixture — the real graph, pinned (v0.2)

`STRUCT-CONSUMER-001` is scored by the [consumer-search contract](../CM.md#consumer-search-contract).
The consumer set is a property of an exact commit, so it is pinned — not asserted
as a timeless count. v0.1 pinned only **three** consumers; run 0001, searching the
full surface list, found **seven** at `7514a21`. v0.2 repins the richer graph:

| Path | `repository_commit` | Verdict | Exercises | Enumerated consumers the move MUST rehome |
|---|---|---|---|---|
| `docs/beta/governance/fixtures/factorized-beta-controls.json` | `7514a21` | `DEFECTS_FOUND` (with consumers) | `STRUCT-CONSUMER-001` · `STRUCT-NAME-001` | **7 consumers at `7514a21`:** `src/engine/ocaml/bin/main.ml:731,759` (runtime CLI default path); `src/engine/ocaml/test/test_factorized_beta_gate.ml` (dune test); `src/engine/ocaml/test/test_factorized_beta.ml:324` (dune test); `src/engine/ocaml/lib/factorized_beta.ml:712` (doc comment); `.github/workflows/factorized-beta-measure.yml:225,230` (CI workflow); `docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md` (Markdown links); `docs/evidence/releases/0.12.0.md:46` (evidence cross-ref). |

```text
search_surfaces:       source code · tests · CI workflows · Markdown links ·
                       evidence cross-refs (docs)  [see consumer-search contract]
consumer_set_digest:   pinned over the 7 sorted consumers above @ 7514a21
```

The `docs/beta/` role-grammar placement is the defect; but a move finding is
coherent only if it enumerates and rehomes **all seven** references. A fixture
that hard-codes "three consumers" as timeless is wrong — the graph is pinned to
`7514a21`, and a different commit may carry a different set.

## Lifecycle fixture — MIXED resolved (v0.2)

v0.1 declined to bind `STRUCT-MIXED-001` at `docs/beta/`, asserting it was
"neither frozen nor a snapshot tree." Run 0001 showed this was wrong: under one
role-grammar directory, `docs/beta/` carries frozen/snapshot material **and** live
engine/test/CI-consumed governance. v0.2 makes `docs/beta/` the **negative
fixture** for `STRUCT-MIXED-001`. The requirement wording is unchanged; only the
fixture flips.

| Path | `repository_commit` | Verdict | Exercises | Evidence the CM must surface |
|---|---|---|---|---|
| `docs/beta/` | `7514a21` | `DEFECTS_FOUND` | `STRUCT-MIXED-001` | One live tree interleaves frozen snapshot material with live-mutable content. **Frozen signal:** `docs/README.md:38` demotes `docs/{alpha,beta,gamma}` to retained snapshots; `.github/workflows/ci.yml:67` names `docs/beta/governance/` a live machine-dependency exception to the frozen-tree linkcheck exclusion. **Live signal:** `docs/beta/governance/**` holds the engine/CI/test consumers of the consumer fixture above. Frozen + live under one directory is exactly the live/history mixing v1.1 §3 precedent addresses — so MIXED binds here. |

## Near-miss regression fixture — the strongest structural test (v0.2)

The repository's strongest structural regression case, drawn from the exact
learning run 0001 preserved: a methodology that classifies the **entire α/β/γ
tree as frozen** and recommends **deletion** WITHOUT constructing the live
consumer graph must **FAIL**. Grounded in `STRUCT-CONSUMER-001`, pinned to
`7514a21`, where `docs/beta/governance/` holds live consumers.

| Fixture | `repository_commit` | Verdict | Exercises | Why it must FAIL |
|---|---|---|---|---|
| A run that reads `docs/{alpha,beta,gamma}/` as inert frozen history and recommends deleting the tree, having built no consumer graph | `7514a21` | **FAIL** (the methodology fails, not passes) | `STRUCT-CONSUMER-001` | At `7514a21`, `docs/beta/governance/` holds live consumers — `src/engine/ocaml/bin/main.ml:731,759`, the dune tests, `.github/workflows/factorized-beta-measure.yml`, `ci.yml:67`. A deletion recommendation issued without enumerating these breaks runtime and CI. `STRUCT-CONSUMER-001` requires every placement/deletion finding to first enumerate live consumers; a run that skips the consumer graph and calls the tree deletable has under-fired on the load-bearing check and fails the fixture. The near-miss the whole suite guards: "frozen-looking" is not "inert." |

## Destination-refusal fixture — placement decided, destination open

Post-v1.1 the two `docs/design/` bundles are placement **defects** (rows above,
`STRUCT-DOCSET-001`), not `UNDERDETERMINED`. The refusal that survives is over
their correct **destination**, not their misplacement:

| Path | `repository_commit` | Verdict | Exercises | Why the CM refuses the destination |
|---|---|---|---|---|
| `docs/design/foundation-contract-reconciliation/` | `7514a21` | `DEFECTS_FOUND` (placement) + refuses destination | `STRUCT-DOCSET-001` · `STRUCT-REFUSE-001` | The bundle is one cross-referenced review thread that a by-file split would orphan, and is design *history* of something now authoritative (neither `research/` nor a live-reference plane). The ADR Deferred note still states its coherent home *"is a decision to take with the operator's frame, not to force here."* The CM flags the `docs/design/` misplacement and **refuses to name the destination** — misplacement decided, destination open. |

## The asymmetry rule

The `docs/design/` defects, the `docs/beta/governance/` defect, and the surviving
destination-refusal turn on one principle, stated so the suite reads as principled
and not ad hoc:

```text
explicit ADR bar (α/β/γ "never a filing taxonomy")      → DEFECT (STRUCT-NAME-001)
closed docs taxonomy (subfolder ∉ the exhaustive eight) → DEFECT (STRUCT-DOCSET-001)
live/frozen mixing under one live tree                  → DEFECT (STRUCT-MIXED-001)
open destination (correct home not yet decided)         → refuse (STRUCT-REFUSE-001)
```

v1 left the docs list named-but-not-fenced, so an unlisted directory was
`UNDERDETERMINED`; v1.1 §1 closed it, so an unlisted directory is now a defect.
What stays refusable is the *destination* of a misplaced bundle — a placement
verdict and a destination question are separate, and one path can carry both.

## Pass condition

The fixture suite passes when, **at the pinned commit for each row**: every
positive classifies to its canonical plane (`COHERENT_WITHIN_DECLARED_SCOPE`) —
including the F1/F2 repaired positives at `a01fbb8`; every negative fires the
named `STRUCT-*` with the stated evidence (`DEFECTS_FOUND`) at `7514a21` —
including the `docs/design/` bundles, the `docs/beta/` MIXED negative, and the
consumer fixture with all **seven** references enumerated; the destination-refusal
case flags the placement defect while **refusing to name a destination**; and the
near-miss deletion methodology **fails** for skipping the consumer graph. A CM
that invents a destination for the foundation bundle fails by overreaching; a CM
that misses the root-file debt, the closed-taxonomy defects, the live/frozen
mixing, or a consumer of a proposed move fails by under-firing.

## Control

The suite is reproducible on a fixed repository commit against a fixed ADR
commit; unlike the legibility newcomer fixture it needs no fresh reader, because
the authority is the ratified policy, not a mental model. Every fixture pins its
own `repository_commit`, and the receipt `scope` pins the ADR commit: if either
moves, the verdicts may move with it — which is why the F1/F2 pair is expressed as
two frozen commits, not one drifting "current tree."
