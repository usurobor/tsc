# LINEAGE — cnos cdd supercycle PR bundle

This document traces each of the 6 patches in this bundle to the source cycles in `usurobor/tsc` master #23 that surfaced the corresponding finding. Required by `cdd/post-release/SKILL.md` Step 5.6b for cross-repo cdd-iteration traces.

## Source

- **Source repo:** `usurobor/tsc`
- **Source master:** [#23 — Bring TSC to coherent state](https://github.com/usurobor/tsc/issues/23) (closed 2026-05-08, completed)
- **Source cycles:** 24, 25, 26, 27, 29 (cycle 28 deferred)
- **Source releases:** v0.5.0, v0.6.0, v0.7.0 (engine), spec v3.2.0

## Target

- **Target repo:** `usurobor/cnos`
- **Target package:** `src/packages/cnos.cdd/skills/cdd/`
- **Target issue:** TBD (filed by sigma; this LINEAGE.md should be updated with the issue number once known)
- **Target PR:** TBD (this LINEAGE.md should be updated with the PR number once opened)

## Per-patch lineage

### Patch 1 — `docs(cdd/review): add honest-claim verification rule (3.13)`

| Source cycle | Finding | Connection |
|---|---|---|
| tsc cycle 24 | β R2 F5: SELF-MEASURE.md §3.3 falsely claims engine derives β | doc claim not backed by code |
| tsc cycle 29 | β R1 F1: undeclared engine-path report cited as artifact | report claim not backed by attached artifact |
| tsc cycle 29 | β R1 F2: score discrepancy between quoted scores and actual engine output | measurement claim not reproducible from artifacts |
| tsc cycle 29 | β R1 F3: missing provenance attachment | claim made; backing data absent |
| tsc cycle 29 | β R1 F4: W2 framing inconsistent with spec | term used inconsistently with canonical source |

**Root finding class:** `cdd-skill-gap` — the review skill was catching the right pattern but the rule was implicit.

### Patch 2 — `docs(cdd/issue): add mode declaration + MCA preconditions`

| Source cycle | Finding | Connection |
|---|---|---|
| tsc cycle 25 | α reading phase ran ~20 minutes before first commit | MCA mis-applied: design existed (`docs/design/0.5.0/`) but issue body did not cite it as MCA precondition |
| tsc cycle 24 | 3 review rounds (β R1 RC F1+F2 → α fix → β R2 RC F5 → α fix → β R3 APPROVE) | non-MCA work; the review-round count correlates with whether design + plan were stable |
| tsc cycle 26 | 1 review round, no findings | clean MCA: design + plan were tight, α executed deterministically |

**Root finding class:** `cdd-skill-gap` — `cdd/issue/SKILL.md` named MCA but did not enforce preconditions.

### Patch 3 — `docs(cdd/release): add docs-only disconnect (§2.5b)`

| Source cycle | Finding | Connection |
|---|---|---|
| tsc cycle 27 | retroactive v0.4.0 close-out shipped; `.cdd/unreleased/27/` still on tsc:main | `release/SKILL.md` §2.5a silent on no-tag case |
| tsc cycle 29 | self-coherence report shipped; `.cdd/unreleased/29/` still on tsc:main | second occurrence of the same gap |

**Root finding class:** `cdd-protocol-gap` — release protocol assumed every cycle tags.

### Patch 4 — `docs(cdd): add review-rounds + finding-class metrics`

| Source cycle | Round count | Connection |
|---|---|---|
| tsc cycle 27 | 1 round | trivial cycle (docs-only retroactive) |
| tsc cycle 25 | 2 rounds | MCA cycle, α tight after observation phase |
| tsc cycle 24 | 3 rounds | new code surface (mathematical contracts), 3 binding F findings |
| tsc cycle 26 | 1 round | clean MCA, follow-on, accumulated context |
| tsc cycle 29 | 2 rounds | docs cycle but β rigor warranted (4 honest-claim findings) |

The 1 → 2 → 3 → 1 → 2 trace is real signal; without surfacing it in the ledger, the next supercycle re-discovers it from prose.

**Root finding class:** `cdd-metric-gap` — review-quality data existed in PRA prose but not in the ledger.

### Patch 5 — `docs(cdd/release): add honest-grading rubric (§3.8)`

| Source cycle | Finding | Connection |
|---|---|---|
| tsc cycle 27 | v0.4.0 retroactive grading: α B / β C+ / γ C / C_Σ C+ | grades were defensible but unanchored — no rubric |

**Root finding class:** `cdd-skill-gap` — §3.8 was qualitative; reproducibility across reviewers low.

### Patch 6 — `docs(cdd): cdd-iteration.md as canonical home for self-iteration findings`

| Source cycle | Finding | Connection |
|---|---|---|
| **Meta-finding** from authoring this very bundle | the supercycle's 5 cdd-improvement findings had no canonical home under `.cdd/`; reconstructing them required reading 5 separate `gamma-closeout.md` files; cross-repo work (tsc → cnos) had no place to land its bundle | observed during the cross-repo bundle authoring session itself; surfaced in the operator dialogue and resolved by adding the structure |

**Root finding class:** `cdd-protocol-gap` — cdd had triggers and dispositions but no canonical artifact for self-iteration findings.

This is the patch that makes the structure used by this very LINEAGE.md normative. Recursive coherence: the patch defines the structure that this PR's cross-repo bundle uses to record its own lineage.

## Cycle → patch matrix

| Cycle | Closes via patch(es) |
|-------|---------------------|
| 24 | 1 (F5), 2, 4 |
| 25 | 2, 4 |
| 26 | 4 |
| 27 | 3, 4, 5 |
| 29 | 1 (F1–F4), 3, 4 |
| (meta — this bundle) | 6 |

## Traceability requirements (per Step 5.6b)

When sigma files the cnos issue:
1. Update this `LINEAGE.md` with the cnos issue number in *Target* above.
2. After the cnos PR opens, update with the PR number.
3. After the cnos PR merges, the lineage should be preserved in the target repo's own `cdd-iteration.md` for that cycle, citing this `LINEAGE.md` by commit SHA.
4. After the cnos PR merges, this cross-repo trace directory may be deleted from `usurobor/tsc:.cdd/iterations/cross-repo/cnos/cdd-supercycle/` — its purpose is fulfilled.

## Checksum

Patches and bundle integrity:

```
0001  honest-claim verification (3.13)        review/SKILL.md
0002  mode declaration + MCA preconditions    issue/SKILL.md
0003  docs-only disconnect (§2.5b)            release/SKILL.md
0004  review-rounds + finding-class metrics   post-release/SKILL.md + release/SKILL.md
0005  honest-grading rubric (§3.8)            release/SKILL.md
0006  cdd-iteration.md self-iteration home    CDD.md + post-release/SKILL.md + gamma/SKILL.md
```

6 commits, 6 files touched in cnos, +202/−11 net. Verified to apply cleanly to a fresh `usurobor/cnos` clone via `git am`.
