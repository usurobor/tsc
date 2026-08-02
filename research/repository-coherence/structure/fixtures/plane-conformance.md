# Plane-conformance fixtures

The primary structural fixture. Structure is **policy-conformance**, so the
discriminating test is a classification of real paths against
[`repository-planes-v1.1`](../../../../docs/architecture/decisions/repository-planes.md).
Every fixture is **immutable**: synthetic, or a real path pinned to an exact
`repository_commit`. Each row names a path, the commit it is pinned to, the
expected verdict, the `STRUCT-*` it exercises, and the evidence the CM must
surface. Expected consumer sets are pinned to the same commit — never a timeless
count.

Commits used:

```text
7514a21  = 7514a21b62472c54a6bd3d67d16de28c92ff0cd2   (pre-move main; root debt present)
a01fbb8  = a01fbb8f902f76c08b2e22d9c8af168747876d26   (root files moved into docs planes)
```

## Regression pairs — root-file move (F1/F2)

The moved root files are a permanent negative→positive regression pair: the same
artifact is a DEFECT before the move and a PASS after it.

| Path | `repository_commit` | Verdict | Exercises | Evidence |
|---|---|---|---|---|
| `QUICKSTART.md` (root) | `7514a21` | `DEFECTS_FOUND` | `STRUCT-PLANE-001` · `STRUCT-RULE-001` | *Helps a person* → `docs/quickstart`, not root; a root peer to the six planes. |
| `docs/quickstart/README.md` | `a01fbb8` | `COHERENT_WITHIN_DECLARED_SCOPE` | `STRUCT-PLANE-001` · `STRUCT-RULE-001` | Now sits under the `quickstart` reader-intent plane; resolves to exactly one plane at its home. |
| `ARCHITECTURE.md` (root) | `7514a21` | `DEFECTS_FOUND` | `STRUCT-PLANE-001` · `STRUCT-RULE-001` | *Helps a person* → `docs/architecture`, not root; a root peer to the planes. |
| `docs/architecture/README.md` | `a01fbb8` | `COHERENT_WITHIN_DECLARED_SCOPE` | `STRUCT-PLANE-001` · `STRUCT-RULE-001` | Now under the `architecture` reader-intent plane at its home. |

Repairability of the negatives: **MECHANICAL** — the ADR names the destination
plane and the consumer set is complete (below).

## Positive fixtures — path in its canonical plane (all @ `7514a21`)

| Path | Verdict | Exercises | Why it passes |
|---|---|---|---|
| `spec/` | `COHERENT_WITHIN_DECLARED_SCOPE` | `STRUCT-PLANE-001` · `STRUCT-RULE-001` · `STRUCT-CANON-001` | *Binds* → `spec/`; the program-map names `spec/` as the specification home. |
| `src/engine/ocaml/` | `COHERENT_WITHIN_DECLARED_SCOPE` | `STRUCT-RULE-001` · `STRUCT-CANON-001` | *Runs* → `src/`; program-map names `src/engine/ocaml/` as the engine home. |
| `conformance/foundation-v4/` | `COHERENT_WITHIN_DECLARED_SCOPE` | `STRUCT-CANON-001` | *Proves the spec* → `conformance/`; program-map names it the foundation conformance home. |
| `.cdd/` | `COHERENT_WITHIN_DECLARED_SCOPE` (excluded) | `STRUCT-EXCLUDE-001` | Do-not-touch set — tooling/data, never flagged as misplaced content. |
| `_build/` (dune output) | `COHERENT_WITHIN_DECLARED_SCOPE` (derived) | `STRUCT-DERIVED-001` | Generated dune output, `.gitignore`d and excluded — distinguishable from source (v1.1 §2). |
| `docs/evidence/releases/0.12.0.md` | `COHERENT_WITHIN_DECLARED_SCOPE` (labelled) | `STRUCT-HISTLABEL-001` | Historical material carrying a "**Historical.**" banner (v1.1 §3). |

## Negative fixtures — real known debt, ADR-recorded (all @ `7514a21`)

| Path | Verdict | Exercises | Repairability | Evidence the CM must surface |
|---|---|---|---|---|
| `docs/alpha/` | `DEFECTS_FOUND` | `STRUCT-NAME-001` · `STRUCT-DOCSET-001` | MECHANICAL | Files by α role grammar, outside the closed eight; the ADR bars α/β/γ as a filing taxonomy. |
| `docs/beta/` | `DEFECTS_FOUND` | `STRUCT-NAME-001` · `STRUCT-DOCSET-001` | POLICY_REQUIRED | Files by β role grammar, outside the eight; carries live governance consumers (below). |
| `docs/gamma/` | `DEFECTS_FOUND` | `STRUCT-NAME-001` · `STRUCT-DOCSET-001` | MECHANICAL | Files by γ role grammar, outside the closed eight. |
| `docs/design/foundation-contract-reconciliation/` | `DEFECTS_FOUND` | `STRUCT-DOCSET-001` | POLICY_REQUIRED | Outside the exhaustive eight (v1.1 §1) → placement defect; destination stays operator-open (refusal row). |
| `docs/design/polar-expression-recovery/` | `DEFECTS_FOUND` | `STRUCT-DOCSET-001` | POLICY_REQUIRED | Same closed-taxonomy defect; no longer `UNDERDETERMINED`. |
| `targets/` | `DEFECTS_FOUND` | `STRUCT-PLANE-001` · `STRUCT-FUNC-001` | DEFERRED | Root peer to the planes; ADR Iteration 3 folds it into the engine — a migration the ADR explicitly stages. |

## MIXED negative — live/history interleaved (@ `7514a21`)

The v0.1 fixture *declined* to bind `STRUCT-MIXED-001` to `docs/beta/`. Run 0001
established the flip: the tree's own labels declare `docs/beta/governance/`
frozen while it holds live engine/CI inputs, so it **is** a live/history mixing
defect.

| Path | `repository_commit` | Verdict | Exercises | Repairability | Evidence |
|---|---|---|---|---|---|
| `docs/beta/` | `7514a21` | `DEFECTS_FOUND` | `STRUCT-MIXED-001` | POLICY_REQUIRED | Frozen label at `docs/README.md:38` and `.github/workflows/ci.yml:67`; live content at `docs/beta/governance/**` per the consumer graph. Live-mutable content interleaved under a declared-frozen tree (v1.1 §3 precedent). |

## Consumer fixture — the 7-consumer graph (@ `7514a21`)

`docs/beta/governance/fixtures/factorized-beta-controls.json` is a role-grammar-placed
live fixture. Any move MUST enumerate its live consumers; the set at `7514a21` is
**seven**, not three:

```text
consumer_search (path: docs/beta/governance/fixtures/factorized-beta-controls.json @ 7514a21):
  surfaces_searched: [source code, tests, CI workflows, Markdown links, config literals]
  search_strength:   complete
  consumers:
    1. src/engine/ocaml/bin/main.ml:731,759                        (runtime CLI default path)
    2. src/engine/ocaml/test/test_factorized_beta_gate.ml:199,210,224,250
    3. src/engine/ocaml/test/test_factorized_beta.ml:324
    4. src/engine/ocaml/lib/factorized_beta.ml:712                 (doc comment)
    5. .github/workflows/factorized-beta-measure.yml:225,230
    6. docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md:17,327,334  (links)
    7. docs/evidence/releases/0.12.0.md:46                          (evidence cross-ref)
  unsearched_surfaces: []
```

| Path | `repository_commit` | Verdict | Exercises | Repairability |
|---|---|---|---|---|
| `docs/beta/governance/fixtures/factorized-beta-controls.json` | `7514a21` | `DEFECTS_FOUND` (with 7 consumers) | `STRUCT-CONSUMER-001` · `STRUCT-NAME-001` | POLICY_REQUIRED |

A move is coherent only if all seven references are rehomed.

## Near-miss FAIL — deletion without a consumer graph (@ `7514a21`)

The strongest regression case, grounding `STRUCT-CONSUMER-001`: an executor that
classifies the whole `docs/{alpha,beta,gamma}` role-grammar tree as frozen
history and recommends **deletion WITHOUT building the live consumer graph** must
**FAIL**, not pass. The α/β/γ trees carry live engine/CI inputs (the 7-consumer
graph above, plus the `docs/beta/governance/` folder-level consumers in run
0001); treating them as deletable inert history breaks exactly those runtime and
CI consumers.

| Scenario | `repository_commit` | Expected | Exercises | Why |
|---|---|---|---|---|
| Recommend deleting `docs/{alpha,beta,gamma}` as frozen, skipping consumer search | `7514a21` | `CM_EXECUTION_FAILED` (delete candidate emitted with no `consumer_search`) | `STRUCT-CONSUMER-001` | A move/delete finding without a `consumer_search` block is not repair-ready; emitting one is a required-step failure, not a PASS. The consumer graph must be built first. |

## The asymmetry rule

```text
explicit ADR bar (α/β/γ "never a filing taxonomy")      → DEFECT (STRUCT-NAME-001)
closed docs taxonomy (subfolder ∉ the exhaustive eight) → DEFECT (STRUCT-DOCSET-001)
open destination (correct home not yet decided)         → refuse (STRUCT-REFUSE-001)
```

A placement verdict and a destination question are separate; one path can carry
both.

## Destination-refusal fixture — placement decided, destination open (@ `7514a21`)

| Path | `repository_commit` | Verdict | Exercises | Why the CM refuses the destination |
|---|---|---|---|---|
| `docs/design/foundation-contract-reconciliation/` | `7514a21` | `DEFECTS_FOUND` (placement) + refuses destination | `STRUCT-DOCSET-001` · `STRUCT-REFUSE-001` | Placement is a defect (outside the eight); the ADR Deferred note leaves the *destination* operator-open, so the CM flags the misplacement and refuses to name a home. Repairability: **POLICY_REQUIRED**. |

## Coverage gaps (recorded honestly)

`STRUCT-FUNC-001` and `STRUCT-OWNER-001` have no negative fixture in the tree
(no single-occupant-plane example beyond `targets`/`runtime`, no duplicate-live-copy).
`STRUCT-DERIVED-001` and `STRUCT-HISTLABEL-001` have positives but no negative —
render byte-identity and the `_build/` exclusion hold, and all historical
material is labelled, so no negative path exists to pin. Seeding these is future
work, not silent coverage. Process IDs (`STRUCT-REPAIR-001`, `STRUCT-REVIEW-001`)
constrain the downstream wave, not the tree, so carry no tree fixture.

## Pass condition

The suite passes when: every positive classifies to its canonical plane
(`COHERENT_WITHIN_DECLARED_SCOPE`); every negative fires its named `STRUCT-*`
(`DEFECTS_FOUND`) with the stated evidence and repairability; the F1/F2 pairs
flip DEFECT→PASS across `7514a21`→`a01fbb8`; the consumer fixture enumerates all
**seven** references; the MIXED negative fires; the destination-refusal case
flags placement while refusing a destination; and the near-miss deletion scenario
**FAILs** for emitting a delete candidate with no consumer graph. A CM that
invents a destination for the foundation bundle fails by overreaching; one that
misses the root-file debt, the closed-taxonomy defects, a consumer of a proposed
move, or the missing consumer graph fails by under-firing.

## Control

Reproducible on the pinned repository and ADR commits. If the policy moves, the
verdicts may move with it — so each fixture pins its `repository_commit`.
