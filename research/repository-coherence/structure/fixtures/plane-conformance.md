# Plane-conformance fixtures

The primary structural fixture. Structure is **policy-conformance**, so the
discriminating test is not a fresh-reader task but a classification of real paths
against [`repository-planes-v1`](../../../../docs/architecture/decisions/repository-planes.md).
Each row names a path, the expected verdict, the `STRUCT-*` it exercises, and the
evidence the CM must surface. All paths are real tracked paths at the measured
commit; the negatives and the underdetermined case are the ADR's own recorded
deferrals.

## Positive fixtures — path in its canonical plane

| Path | Verdict | Exercises | Why it passes |
|---|---|---|---|
| `spec/` | `COHERENT_WITHIN_DECLARED_SCOPE` | `STRUCT-PLANE-001` · `STRUCT-RULE-001` · `STRUCT-CANON-001` | *Binds* implementations and methodologies → `spec/`; the ADR program-map names `spec/` as the specification home. Resolves to exactly one plane. |
| `src/engine/ocaml/` | `COHERENT_WITHIN_DECLARED_SCOPE` | `STRUCT-RULE-001` · `STRUCT-CANON-001` | *Runs* → `src/`; the program-map names `src/engine/ocaml/` as the engine home. Resolves to one plane, at its canonical path. |
| `conformance/foundation-v4/` | `COHERENT_WITHIN_DECLARED_SCOPE` | `STRUCT-CANON-001` | *Proves the spec* → `conformance/`; the program-map names `conformance/foundation-v4/` as the foundation conformance home. |
| `.cdd/` | `COHERENT_WITHIN_DECLARED_SCOPE` (excluded) | `STRUCT-EXCLUDE-001` | In the do-not-touch set — tooling/data, not content. The CM excludes it, never flags it as misplaced. |

## Negative fixtures — real known debt (ADR-recorded)

| Path | Verdict | Exercises | Evidence the CM must surface |
|---|---|---|---|
| `QUICKSTART.md` (root) | `DEFECTS_FOUND` | `STRUCT-RULE-001` · `STRUCT-PLANE-001` | *Helps a person* → belongs under the docs reader-intent plane `quickstart`, not the root. The ADR records docs-portal population as deferred debt; the artifact sits above its plane (a root peer to the six planes). |
| `ARCHITECTURE.md` (root) | `DEFECTS_FOUND` | `STRUCT-RULE-001` · `STRUCT-PLANE-001` | *Helps a person* → belongs under the docs plane `architecture` (or `docs/architecture/`), not the root. Same recorded deferral; live root file as a peer to the planes. |
| `docs/beta/governance/` | `DEFECTS_FOUND` | `STRUCT-NAME-001` · `STRUCT-RULE-001` | `docs/beta/` files by α/β/γ role grammar, which the ADR explicitly bars as a docs filing taxonomy; the governance content belongs under a reader-intent plane, not a role-grammar folder. (Not bound to `STRUCT-MIXED-001`: `docs/beta/` is neither frozen nor a snapshot tree, so no live/history mixing applies here.) |

Seed-stage coverage gap: `STRUCT-MIXED-001`, `STRUCT-FUNC-001`, and
`STRUCT-OWNER-001` have **no negative fixture yet** — the current tree offers no
clean live-inside-a-frozen-tree, single-occupant-plane, or duplicate-live-copy
example. Recorded honestly here and in [`../requirements.md`](../requirements.md);
seeding them is future work, not silent coverage.

## Underdetermined fixture — the ADR leaves the home open

| Path | Verdict | Exercises | Why the CM refuses |
|---|---|---|---|
| `docs/design/foundation-contract-reconciliation/` | `UNDERDETERMINED` | `STRUCT-REFUSE-001` | The ADR deferral records this as one cross-referenced review thread that a by-file split would orphan, sitting in a genuinely open plane (design *history* of something now authoritative — neither `research/` nor a live-reference plane), and states its coherent home *"is a decision to take with the operator's frame, not to force here."* The CM records the open question and the ADR clause; it assigns no plane. Inventing one would be the CM legislating policy it does not own. |
| `docs/design/polar-expression-recovery/` | `UNDERDETERMINED` | `STRUCT-REFUSE-001` | `docs/design/` is not in the ratified reader-intent taxonomy, and the ADR states no *closed prohibition* on other docs directories — the reader-intent list is named, not fenced. The ADR is simply silent on `docs/design/`'s correctness, so the CM refuses rather than defect-flags. (Unlike the foundation bundle, the ADR does not single this path out; it falls under the same silence.) |

## The asymmetry rule

The two `docs/design/` refusals and the `docs/beta/governance/` defect turn on
one principle, stated so the suite reads as principled and not ad hoc:

```text
explicit ADR bar (α/β/γ "never a filing taxonomy")   → DEFECT
ADR silence      (docs/design/ not in the list,      → UNDERDETERMINED
                  but the list is not a closed bar)     per STRUCT-REFUSE-001
```

A named-but-not-fenced taxonomy does not license the CM to treat every
unlisted directory as wrong; only an explicit "never" does.

## Pass condition

The fixture suite passes when: every positive classifies to its canonical plane
(`COHERENT_WITHIN_DECLARED_SCOPE`), every negative fires the named `STRUCT-*`
with the stated evidence (`DEFECTS_FOUND`), and each underdetermined case returns
`UNDERDETERMINED` — **not** a defect and **not** a forced placement. A CM that
guesses a home for a `docs/design/` bundle fails the suite by overreaching its
authority, exactly as a CM that misses the root-file debt fails by under-firing.

## Control

The suite is reproducible on a fixed repository commit against a fixed ADR
commit; unlike the legibility newcomer fixture it needs no fresh reader, because
the authority is the ratified policy, not a mental model. It does require the ADR
commit to be pinned in the receipt `scope`: if the policy moves, the verdicts may
move with it.
