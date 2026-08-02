# Plane-conformance fixtures

The primary structural fixture. Structure is **policy-conformance**, so the
discriminating test is not a fresh-reader task but a classification of real paths
against [`repository-planes-v1.1`](../../../../docs/architecture/decisions/repository-planes.md).
Each row names a path, the expected verdict, the `STRUCT-*` it exercises, and the
evidence the CM must surface. All paths are real tracked paths at the measured
commit; the negatives are the ADR's own recorded deferrals and known debt, and the
surviving refusal is over a misplaced bundle's still-open destination.

## Positive fixtures — path in its canonical plane

| Path | Verdict | Exercises | Why it passes |
|---|---|---|---|
| `spec/` | `COHERENT_WITHIN_DECLARED_SCOPE` | `STRUCT-PLANE-001` · `STRUCT-RULE-001` · `STRUCT-CANON-001` | *Binds* implementations and methodologies → `spec/`; the ADR program-map names `spec/` as the specification home. Resolves to exactly one plane. |
| `src/engine/ocaml/` | `COHERENT_WITHIN_DECLARED_SCOPE` | `STRUCT-RULE-001` · `STRUCT-CANON-001` | *Runs* → `src/`; the program-map names `src/engine/ocaml/` as the engine home. Resolves to one plane, at its canonical path. |
| `conformance/foundation-v4/` | `COHERENT_WITHIN_DECLARED_SCOPE` | `STRUCT-CANON-001` | *Proves the spec* → `conformance/`; the program-map names `conformance/foundation-v4/` as the foundation conformance home. |
| `.cdd/` | `COHERENT_WITHIN_DECLARED_SCOPE` (excluded) | `STRUCT-EXCLUDE-001` | In the do-not-touch set — tooling/data, not content. The CM excludes it, never flags it as misplaced. |
| `_build/` (dune output) | `COHERENT_WITHIN_DECLARED_SCOPE` (derived) | `STRUCT-DERIVED-001` | Generated dune output, `.gitignore`d and excluded from tracked content (also excluded by `scripts/check-forbidden-wording.sh`). Distinguishable from hand-authored source by exclusion — exactly the v1.1 §2 signal ("excluded build directory"). |
| `docs/evidence/releases/0.12.0.md` | `COHERENT_WITHIN_DECLARED_SCOPE` (labelled) | `STRUCT-HISTLABEL-001` | Historical material on the live tree carrying a "**Historical.**" banner — the v1.1 §3 precedent. The label is present, so the lifecycle-label rule is satisfied. |

## Negative fixtures — real known debt (ADR-recorded)

| Path | Verdict | Exercises | Evidence the CM must surface |
|---|---|---|---|
| `QUICKSTART.md` (root) | `DEFECTS_FOUND` | `STRUCT-RULE-001` · `STRUCT-PLANE-001` | *Helps a person* → belongs under the docs reader-intent plane `quickstart`, not the root. The ADR records docs-portal population as deferred debt; the artifact sits above its plane (a root peer to the six planes). |
| `ARCHITECTURE.md` (root) | `DEFECTS_FOUND` | `STRUCT-RULE-001` · `STRUCT-PLANE-001` | *Helps a person* → belongs under the docs plane `architecture` (or `docs/architecture/`), not the root. Same recorded deferral; live root file as a peer to the planes. |
| `docs/beta/governance/` | `DEFECTS_FOUND` | `STRUCT-NAME-001` · `STRUCT-RULE-001` | `docs/beta/` files by α/β/γ role grammar, which the ADR explicitly bars as a docs filing taxonomy; the governance content belongs under a reader-intent plane, not a role-grammar folder. (Not bound to `STRUCT-MIXED-001`: `docs/beta/` is neither frozen nor a snapshot tree, so no live/history mixing applies here.) |
| `docs/design/foundation-contract-reconciliation/` | `DEFECTS_FOUND` | `STRUCT-DOCSET-001` | `docs/design/` is outside the closed reader-intent taxonomy (v1.1 §1 makes the eight folders exhaustive), so the bundle is a placement **defect to rehome**. Misplacement is now determined; the correct **destination** stays operator-undecided (the ADR Deferred note — see the refusal row below). One path, two verdicts: DEFECT on placement, refusal on destination. |
| `docs/design/polar-expression-recovery/` | `DEFECTS_FOUND` | `STRUCT-DOCSET-001` | Same closed-taxonomy defect: `docs/design/` is not one of the ratified eight, so the bundle is misplaced. A placement DEFECT under v1.1 §1 — no longer `UNDERDETERMINED`. |
| `docs/beta/governance/fixtures/factorized-beta-controls.json` | `DEFECTS_FOUND` (with consumers) | `STRUCT-CONSUMER-001` · `STRUCT-NAME-001` | The `docs/beta/` role-grammar placement is a defect, but any move finding MUST first enumerate this path's live consumers: `src/engine/ocaml/bin/main.ml:731,759`, the dune test `test/test_factorized_beta_gate.ml`, and the workflow `.github/workflows/factorized-beta-measure.yml`. A relocation is coherent only if it rehomes all three references. The near-miss this encodes: treating `docs/beta/governance/` as a deletable frozen tree would have broken exactly these three consumers — the missed-defect-becomes-test case. |

Seed-stage coverage gap: `STRUCT-MIXED-001`, `STRUCT-FUNC-001`, and
`STRUCT-OWNER-001` have **no negative fixture yet** — the current tree offers no
clean live-inside-a-frozen-tree, single-occupant-plane, or duplicate-live-copy
example. `STRUCT-DERIVED-001` has a positive (`_build/`, above) but **no negative
in the tree**: a mislabeled-generated negative would be a generated artifact
committed as tracked content with no exclusion, no generated marker, and no
render/build binding — indistinguishable from hand-authored source. Render
byte-identity and the `_build/` exclusion hold, so no such path exists to fixture;
recorded honestly. `STRUCT-HISTLABEL-001` likewise has a positive (the `0.12.0.md`
banner) but no negative — the tree's historical material (`0.12.0.md`,
`docs/{alpha,beta,gamma}`) is all labelled; a negative would be an archived doc on
the live tree carrying no banner or marker. Recorded honestly here and in
[`../requirements.md`](../requirements.md); seeding these is future work, not
silent coverage.

## Destination-refusal fixture — placement decided, destination open

Post-v1.1 the two `docs/design/` bundles are placement **defects** (rows above,
`STRUCT-DOCSET-001`), not `UNDERDETERMINED`. The refusal that survives is over
their correct **destination**, not their misplacement:

| Path | Verdict | Exercises | Why the CM refuses the destination |
|---|---|---|---|
| `docs/design/foundation-contract-reconciliation/` | `DEFECTS_FOUND` (placement) + refuses destination | `STRUCT-DOCSET-001` · `STRUCT-REFUSE-001` | The bundle is one cross-referenced review thread that a by-file split would orphan, and is design *history* of something now authoritative (neither `research/` nor a live-reference plane). The ADR Deferred note still states its coherent home *"is a decision to take with the operator's frame, not to force here."* The CM flags the `docs/design/` misplacement and **refuses to name the destination** — misplacement decided, destination open. |

## The asymmetry rule

The `docs/design/` defects, the `docs/beta/governance/` defect, and the surviving
destination-refusal turn on one principle, stated so the suite reads as principled
and not ad hoc:

```text
explicit ADR bar (α/β/γ "never a filing taxonomy")      → DEFECT (STRUCT-NAME-001)
closed docs taxonomy (subfolder ∉ the exhaustive eight) → DEFECT (STRUCT-DOCSET-001)
open destination (correct home not yet decided)         → refuse (STRUCT-REFUSE-001)
```

v1 left the docs list named-but-not-fenced, so an unlisted directory was
`UNDERDETERMINED`; v1.1 §1 closed it, so an unlisted directory is now a defect.
What stays refusable is the *destination* of a misplaced bundle — a placement
verdict and a destination question are separate, and one path can carry both.

## Pass condition

The fixture suite passes when: every positive classifies to its canonical plane
(`COHERENT_WITHIN_DECLARED_SCOPE`), every negative fires the named `STRUCT-*` with
the stated evidence (`DEFECTS_FOUND`) — including the `docs/design/` bundles as
closed-taxonomy defects and the consumer fixture with all three references
enumerated — and the destination-refusal case flags the placement defect while
**refusing to name a destination**. A CM that invents a destination for the
foundation bundle fails by overreaching its authority; a CM that misses the
root-file debt, the closed-taxonomy defects, or a consumer of a proposed move
fails by under-firing.

## Control

The suite is reproducible on a fixed repository commit against a fixed ADR
commit; unlike the legibility newcomer fixture it needs no fresh reader, because
the authority is the ratified policy, not a mental model. It does require the ADR
commit to be pinned in the receipt `scope`: if the policy moves, the verdicts may
move with it.
