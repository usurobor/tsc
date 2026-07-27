# TSC Foundation Archaeology

**Status:** Design evidence
**Authority:** Informative; historical claims bind only through cited immutable commits
**Repository:** `usurobor/tsc`

## Governing question

> Which prior constructions, results, failures, and discarded decisions constrain the v4 foundation?

The repository moved through this arc:

```text
coalgebra
  → coalgebra plus braided algebra
  → term algebra
  → repository scalar meter
  → typed coalgebraic receipts
```

This record does not revive an earlier version. It preserves evidence that v4 must recover, reject, or explicitly dispose.

## 1 · Repository identity

The repository originally used `usurobor/CT`. GitHub redirects that name to `usurobor/tsc`; both names identify the same history.

Earliest visible merge reference:

- `d16c47d7f95b674b771de56bc1d176aa0a88835c` — “Merge branch 'main' of https://github.com/usurobor/CT”
  https://github.com/usurobor/tsc/commit/d16c47d7f95b674b771de56bc1d176aa0a88835c

## 2 · Timeline

| Date | Commit | Author | Event |
|---|---|---|---|
| 2025-10-28 | [`290bb37528f755e1b000f7182877a6ae353da628`](https://github.com/usurobor/tsc/commit/290bb37528f755e1b000f7182877a6ae353da628) | Lisovin | Operational level extracted; mathematics stabilized |
| 2025-10-28 | [`03997a542a69fc4dffc7fc7365469c19f20f509c`](https://github.com/usurobor/tsc/commit/03997a542a69fc4dffc7fc7365469c19f20f509c) | Lisovin | `core/` specification layout appears |
| 2025-10-28 | [`b462ac15316c975b1666a4f38bc6a78d16f703db`](https://github.com/usurobor/tsc/commit/b462ac15316c975b1666a4f38bc6a78d16f703db) | Lisovin | Reference controller reimplemented in functional style |
| 2025-10-29 | [`71a49532a6597811cecb6eb2e828e8b8587f00d6`](https://github.com/usurobor/tsc/commit/71a49532a6597811cecb6eb2e828e8b8587f00d6) | usurobor | Core v2.0.0 introduces aspectual coalgebra and finality sketch |
| 2025-10-30 | [`024e938c0810a30cef8e98317448ab322f167918`](https://github.com/usurobor/tsc/commit/024e938c0810a30cef8e98317448ab322f167918) | usurobor | Full v2 coalgebra section recoverable at `core/tsc-core.md` |
| 2025-10-30 | [`a034e346c198b7dadecfd4d85bd530efeddcbddb`](https://github.com/usurobor/tsc/commit/a034e346c198b7dadecfd4d85bd530efeddcbddb) | Lisovin | `core/` renamed to `spec/`; no conceptual deletion |
| 2025-10-31 | [`b4c53932d6ba7b8827741e97d826705d92fbfe05`](https://github.com/usurobor/tsc/commit/b4c53932d6ba7b8827741e97d826705d92fbfe05) | usurobor | Core v2.2.0 adds coalgebra fixed-point section |
| 2025-10-31 | [`1c87a8ec4787790280bfb5e37abdd6dc5cb66b8e`](https://github.com/usurobor/tsc/commit/1c87a8ec4787790280bfb5e37abdd6dc5cb66b8e) | usurobor | Constraint and clarity patches |
| 2025-10-31 | [`7885f6cf238a4304a9bd7c1a806aee439193b13b`](https://github.com/usurobor/tsc/commit/7885f6cf238a4304a9bd7c1a806aee439193b13b) | usurobor | Braided algebra integrated beside coalgebra |
| 2025-11-04 | [`1a71d6cd116440887c88c661f3682f1acc07bee3`](https://github.com/usurobor/tsc/commit/1a71d6cd116440887c88c661f3682f1acc07bee3) | Lisovin | v2.2 release correction |
| 2025-11-06 | [`d48e1b7ff19232011e8a34661293e68f59d0feff`](https://github.com/usurobor/tsc/commit/d48e1b7ff19232011e8a34661293e68f59d0feff) | Lisovin | Last commit with categorical and braided stack intact |
| 2025-11-09 | [`bfa894716a750c2e00c70b9ab5a270fe01c0119c`](https://github.com/usurobor/tsc/commit/bfa894716a750c2e00c70b9ab5a270fe01c0119c) | Lisovin | v3.0.0 term-algebra replacement deletes coalgebra and braiding |
| 2025-11-10 | [`ac5111cb8bbfd6898bc0afbdbf491aee12e3ca8a`](https://github.com/usurobor/tsc/commit/ac5111cb8bbfd6898bc0afbdbf491aee12e3ca8a) | Lisovin | v3.1.0 term algebra settles |
| 2026-04-03 | [`c55fbeec0fea3a29a104a47404a8846518ae5d07`](https://github.com/usurobor/tsc/commit/c55fbeec0fea3a29a104a47404a8846518ae5d07) | Claude | Archived copies removed; Git history designated archive |
| 2026-05-08 | [`06fb2dff52bea9e32c7a8dbcfb6b349526cde89f`](https://github.com/usurobor/tsc/commit/06fb2dff52bea9e32c7a8dbcfb6b349526cde89f) | gamma | Tests migrated from Python to OCaml |
| 2026-07-04 | [`7c51189111565b60088b93dc9279c0369d3d0276`](https://github.com/usurobor/tsc/commit/7c51189111565b60088b93dc9279c0369d3d0276) | Claude | Meter semantics consolidated in the OCaml engine |

The late-2025 foundation versions were not represented by the later `0.x` engine tag sequence. Git history is the durable source.

## 3 · The v2.3 braided result

Source:

- [`CHANGELOG` at `bfa8947`](https://github.com/usurobor/tsc/blob/bfa894716a750c2e00c70b9ab5a270fe01c0119c/CHANGELOG)

The baseline reported:

```text
C_Σ = 0.238
Verdict: FAIL
S₃ witness: PASS
Braided witness: FAIL — 92% equations did not normalize
```

It scheduled:

```text
v2.3.1: fix braided parser
```

The result was recorded when produced. It was not later resolved, invalidated, or formally disposed when the universal braided claim was removed.

The 92% result does not refute braided interchange as mathematics. It shows that the shipped witness did not discharge the axiom it claimed to test.

The diagnostic named surviving braid nodes and Yang–Baxter or braid-composition rules as likely missing:

- [`reference/python/braid_debug.py` at `d48e1b7`](https://github.com/usurobor/tsc/blob/d48e1b7ff19232011e8a34661293e68f59d0feff/reference/python/braid_debug.py)

## 4 · Recovered coalgebraic program

Source:

- [`core/tsc-core.md` at `024e938`](https://github.com/usurobor/tsc/blob/024e938c0810a30cef8e98317448ab322f167918/core/tsc-core.md)

The v2 Core introduced:

```text
an articulation functor
coalgebras and coalgebra morphisms
Lipschitz articulation assumptions
non-expansive discrepancy
bounded scale drift
a tolerant-finality theorem sketch
```

The sketch proposed a terminal-chain construction in a metric setting and approximate uniqueness through a tolerant fixed-point argument.

It did not fully define:

```text
the functor action on morphisms
the enriched category
the terminal chain
the precise convergence conditions
the approximate uniqueness theorem
```

The correct classification is:

> the first explicit tolerant-finality research program and intended proof shape in TSC.

It is prior art and a future proof obligation, not a construction v4 may inherit as complete.

## 5 · Recovered alignment program

The v2 Core and kernel treated alignments as weighted correspondences rather than strict bijections. They permitted partial and many-to-one maps, required an alignment ensemble, and recorded stability across alternative solvers.

Sources:

- [`core/tsc-core.md` at `024e938`](https://github.com/usurobor/tsc/blob/024e938c0810a30cef8e98317448ab322f167918/core/tsc-core.md)
- [`spec/c-equiv-kernel.md` at `d48e1b7`](https://github.com/usurobor/tsc/blob/d48e1b7ff19232011e8a34661293e68f59d0feff/spec/c-equiv-kernel.md)

The recovered requirement is:

```text
map search is declared
alternatives and uncertainty are retained
a selected residual cannot replace the maps that produced it
```

## 6 · Braided axioms

Source:

- [`spec/c-equiv.md` at `d48e1b7`](https://github.com/usurobor/tsc/blob/d48e1b7ff19232011e8a34661293e68f59d0feff/spec/c-equiv.md)

The braided foundation included:

```text
C1 self-application
C2 role rotation
C3 typed units
C4 associativity
C5 braided interchange and hexagon coherence
C6 adjointness and dual compatibility
```

v4 does not restore these as universal axioms.

What survives:

```text
typed identities
associative path composition
optional domain-declared higher commutation laws
optional domain dualities
```

What is rejected as universal:

```text
free role rotation
three universal monoids
universal braided interchange
universal adjointness
normalization that discards needed structure
```

## 7 · v3 replacement and omitted disposition

Sources:

- [`docs/migration-guide.md` at `bfa8947`](https://github.com/usurobor/tsc/blob/bfa894716a750c2e00c70b9ab5a270fe01c0119c/docs/migration-guide.md)
- [`spec/c-equiv.md` at `bfa8947`](https://github.com/usurobor/tsc/blob/bfa894716a750c2e00c70b9ab5a270fe01c0119c/spec/c-equiv.md)

The migration guide removed braided checking because algebraic independence was said to be proven directly.

The replacement proof established that three target monoids had different idempotent profiles. It did not establish evaluator-level informational independence. The later γ evaluator reduced to atom count and α factored through it.

The migration guide explained removal of braided machinery. It did not explain removal of coalgebraic semantics or formally dispose of the failed braided receipt.

## 8 · What v4 recovers

```text
typed relation and identity
open generative unfolding
complete deterministic Set functor
concrete presentation plus behavior semantics
map and alternative retention
input-indexed equivalence
path-sensitive approximation obligations
authority separation
failure-persistent lineage
```

## 9 · What v4 rejects

```text
context-free universal score
free semantic role permutation
shape claims from commutative leaf folds
pairwise residual as global relational evidence
final behavior as replacement for presentation
model lift without preregistration and held-out oracle
foundation replacement without failure disposition
```

## 10 · Open decisions

### 10.1 Tolerant finality

The first metric, measurable, probabilistic, or other non-Set CM that claims finality must provide a complete category-specific construction. The v2 sketch may guide that work but does not discharge it.

### 10.2 Relation priority

The static dependent relation formalizes mutual constitution, not derivation of poles from relations. The generator emits complete events and therefore produces the particular poles of each event. Stronger ontological priority remains an interpretation unless another formal construction proves it.

### 10.3 Higher coherence laws

Braids, hexagons, adjoints, and other higher laws may return as CM-declared structures only when their positive and negative conformance fixtures exist.

## 11 · Immutable source table

| Subject | Source |
|---|---|
| v2 coalgebra | https://github.com/usurobor/tsc/blob/024e938c0810a30cef8e98317448ab322f167918/core/tsc-core.md |
| braided foundation | https://github.com/usurobor/tsc/blob/d48e1b7ff19232011e8a34661293e68f59d0feff/spec/c-equiv.md |
| braided kernel | https://github.com/usurobor/tsc/blob/d48e1b7ff19232011e8a34661293e68f59d0feff/spec/c-equiv-kernel.md |
| witness code | https://github.com/usurobor/tsc/blob/d48e1b7ff19232011e8a34661293e68f59d0feff/reference/python/braid_debug.py |
| v2.3 result | https://github.com/usurobor/tsc/blob/bfa894716a750c2e00c70b9ab5a270fe01c0119c/CHANGELOG |
| v3 replacement | https://github.com/usurobor/tsc/commit/bfa894716a750c2e00c70b9ab5a270fe01c0119c |
| v3 migration guide | https://github.com/usurobor/tsc/blob/bfa894716a750c2e00c70b9ab5a270fe01c0119c/docs/migration-guide.md |

## 12 · Corrections to earlier archaeological claims

1. The 92% failure was recorded when produced. The defect was missing resolution and disposition, not missing initial recording.
2. Witness failure did not refute the braided axioms. It established that the implementation had not discharged them.
3. The tolerant-finality section was a theorem sketch and research program, not a complete construction available for direct reuse.
4. The `core/` to `spec/` move was a rename, not the death of coalgebra.
5. The coalgebraic program remained across v2.x for about eleven days and was removed in the v3.0.0 term-algebra rewrite.
6. The motivation file cited by the v2 commit, `philosophy/README.md`, is not present in the recoverable repository history.

This corrections section is part of the evidence. Archaeology cannot demand failure persistence while silently repairing its own claims.
