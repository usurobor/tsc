---
cycle: 29
role: alpha
artifact: alpha-closeout
---

# Cycle 29 — α Close-out

## Cycle Summary

| Field | Value |
|-------|-------|
| Issue | Sub 6 (#29): Generate v3.2.0 self-coherence report |
| Branch | `cycle/29-self-coherence` |
| Base SHA (origin/main at dispatch) | `ee4a84d72a65b780e401b673f7ea10d27f375fb2` |
| Implementation SHA (doctrine path) | `ef833de` |
| Fix commit (engine-path removal) | `97f627a` |
| Branch head at merge | `b615a7f` |
| Merge commit | `e119aa6` |
| Review rounds | 2 (R1: REQUEST CHANGES; R2: APPROVED) |
| Issue closed | Closes #29 |

## Review Outcome

| Round | Verdict | Findings |
|-------|---------|----------|
| R1 | REQUEST CHANGES | F1–F4 (all derive from undeclared engine-path report; see below) |
| R2 | APPROVED | None |

## Friction Log

**Undeclared engine-path report (root cause of R1 F1–F4).**

During implementation α ran the v3.2.0 engine against the engine target using a different file-set scope (engine-path: `docs/alpha/engine/0.7.0/`) in addition to the declared doctrine-path report (`docs/alpha/doctrine/3.2.0/`). The engine-path report was committed (`docs/alpha/engine/0.7.0/SELF-COHERENCE.md`, `docs/alpha/engine/README.md` v0.7.0 row) but was never declared in `self-coherence.md` §ACs, CDD Trace step 6, or §Self-check.

Consequences:
- F1 (C): undeclared artifact in diff — violated CDD.md §5.5 one-source-of-truth rule
- F2 (C): engine/repo scores differed between the two reports because the engine-path run used a slightly different corpus (two runs ~8 minutes apart); doctrine-path report was consistent with provenance JSON
- F3 (C): engine-path report contained a fourth "direct" target with no provenance JSON
- F4 (B): engine-path W2 spread values reflected corpus instability between runs, not gauge invariance

**Resolution:** Option A (β-recommended). `97f627a` removed `docs/alpha/engine/0.7.0/SELF-COHERENCE.md` and reverted the `docs/alpha/engine/README.md` v0.7.0 row. Single-commit fix; all four findings closed.

## Process Observations

**Parallel path committed without CDD Trace declaration.** α produced a second measurement artifact (engine-path report) without adding it to `self-coherence.md` §ACs or CDD Trace step 6. The pre-review gate (row 7, peer enumeration) did not surface the undeclared parallel output because the gate only checked whether a declared peer family existed — it did not verify that all files in the diff were accounted for in the CDD Trace. β's contract-integrity check at R1 was the first surface to catch the gap.

**Score drift from corpus instability.** Running the engine twice against overlapping but non-identical file sets (files added to the working tree between runs) produced measurable γ divergence (engine: 0.687 vs 0.691; repo: 0.680 vs 0.682). This is an observation about measurement reproducibility in mechanical mode when the working tree is not fully committed between runs.

**Single-commit Option A was sufficient.** The doctrine-path report, provenance JSON, and README index were internally consistent throughout — no doctrine-path artifact required correction. The fix was a deletion, not a revision.

## Debt Forward (D1–D4, carried from self-coherence.md)

| ID | Description |
|----|-------------|
| D1 | Hybrid run deferred — no LLM credentials. Engine and repo β scores are structural-proxy-only; hybrid run would materially change them. |
| D2 | `engine.tsc` `_build/` exclusion missing. Engine β=0.225 is depressed by build artifact contamination; this is a target-definition issue. |
| D3 | Aggregate C_Σ formula (geometric mean of per-target C_Σ) not specified in tsc-oper.md. Used as judgment call in the report. |
| D4 | No CI on mechanical scores; bootstrap CI requires hybrid mode. |

## CDD Trace (α close-out step)

| Step | Artifact | Skills loaded | Decision |
|------|----------|---------------|----------|
| 10 α close-out | `.cdd/unreleased/29/alpha-closeout.md` | CDD.md, alpha/SKILL.md | Written post-merge via re-dispatch. β R2 APPROVED. F1–F4 resolved by 97f627a. Debt D1–D4 carried forward. |
