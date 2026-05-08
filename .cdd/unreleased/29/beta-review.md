---
cycle: 29
role: beta
round: 1
---

# Cycle 29 — Beta Review

**Verdict:** REQUEST CHANGES

**Round:** 1
**Branch:** `cycle/29-self-coherence`
**β origin/main base SHA:** `ee4a84d72a65b780e401b673f7ea10d27f375fb2` (fetched synchronously before diff)
**Branch head SHA:** `2ae029c59743332f53193bd9eb960898f7a507fc`
**Branch CI state:** docs-only change; no OCaml code modified; local build+tests green per α pre-review gate (2026-05-08T21:51Z)

---

## §2.0.0 Contract Integrity

| Check | Result | Notes |
|---|---|---|
| Status truth preserved | yes | Doctrine-path report honestly states what is measured; debt declared explicitly |
| Canonical sources/paths verified | no | Two self-coherence reports in the diff with divergent scores — engine-path report not declared in self-coherence.md and contradicts path decision. See F1, F2. |
| Scope/non-goals consistent | yes | Doctrine-path artifacts stay within scope; engine-path report adds scope beyond declared path decision |
| Constraint strata consistent | yes | No constraint strata violations in doctrine-path artifacts |
| Exceptions field-specific/reasoned | n/a | No exception-backed fields in this change |
| Path resolution base explicit | yes | All doc paths are repo-root-relative and verified |
| Proof shape adequate | yes | AC oracles (file existence, manual review) are appropriate for measurement/docs cycle |
| Cross-surface projections updated | partial | Doctrine README updated (AC6 ✓); engine README updated for undeclared engine-path report — creates an undeclared projection not in self-coherence.md. See F1. |
| No witness theater / false closure | yes | Scores backed by provenance JSON; honest debt declarations; engine-path report is superfluous, not fabricated |
| PR body matches branch files | n/a | No PR in triadic CDD; self-coherence.md is the branch summary |

**Contract integrity gate:** "Canonical sources/paths verified" = no → F1 finding blocks approval. Review proceeds; verdict accounts for contract findings.

---

## §2.0 Issue Contract

### AC Coverage

| # | AC | In diff? | Status | Notes |
|---|----|----------|--------|-------|
| AC1 — Report exists at canonical path | yes | **Met** | `docs/alpha/doctrine/3.2.0/SELF-COHERENCE.md` present. Path decision (doctrine) recorded in report §Path Decision. |
| AC2 — Per-target scores recorded | yes | **Met** | All three targets (spec, engine, repo); α/β/γ/C_Σ + confidence note per target in doctrine report. |
| AC3 — v3.2.0 provenance attached | yes | **Met (doctrine path)** | `docs/alpha/doctrine/3.2.0/provenance/{spec,engine,repo}.json` present; all required v3.2.0 fields from `spec/tsc-oper.md §6` present; mechanical-mode-null fields recorded as `null` with explanation. Schema validates visually. |
| AC4 — W2 ref+spread reported | yes | **Met (doctrine path)** | Provenance JSON: `w_gauge_ref=0.0`, `w_gauge_spread=0.0` per target (S₃-symmetry argument in mechanical mode); τ=0.05; pass condition documented. |
| AC5 — Honest grading | yes | **Met** | Engine β=0.225 with root cause (\_build/ contamination); aggregate C_Σ=0.675 grade C+; bottleneck named. Not everything A+. |
| AC6 — Referenced in index | yes | **Met** | `docs/alpha/doctrine/README.md` §Self-coherence reports table updated with link to `3.2.0/SELF-COHERENCE.md`, engine version, mode. |

### Named Doc Updates

| Doc / File | In diff? | Status | Notes |
|------------|----------|--------|-------|
| `docs/alpha/doctrine/3.2.0/SELF-COHERENCE.md` | yes | Present | Canonical doctrine-path report |
| `docs/alpha/doctrine/3.2.0/provenance/spec.json` | yes | Present | v3.2.0 provenance schema |
| `docs/alpha/doctrine/3.2.0/provenance/engine.json` | yes | Present | v3.2.0 provenance schema |
| `docs/alpha/doctrine/3.2.0/provenance/repo.json` | yes | Present | v3.2.0 provenance schema |
| `docs/alpha/doctrine/README.md` | yes | Present | §Self-coherence reports table added |
| `docs/alpha/engine/0.7.0/SELF-COHERENCE.md` | yes | **Undeclared** | Not in self-coherence.md §ACs, CDD Trace, or §Self-check. Divergent scores from provenance JSON. See F1, F2. |
| `docs/alpha/engine/README.md` | yes | **Undeclared** | Version-history row for v0.7.0 added; not declared in self-coherence.md. |

### CDD Artifact Contract

| Artifact | Required? | Present? | Notes |
|----------|-----------|----------|-------|
| `.cdd/unreleased/29/self-coherence.md` | yes | yes | Review-readiness signal present; ACs evidenced; debt explicit |
| `.cdd/unreleased/29/beta-review.md` | yes | yes (this file) | Written incrementally per large-file authoring rule |
| `.cdd/unreleased/29/alpha-closeout.md` | yes (post-merge) | not yet | Expected after merge via re-dispatch |
| `.cdd/unreleased/29/beta-closeout.md` | yes (post-merge) | not yet | β writes after merge |

### Active Skill Consistency

| Skill | Required by | Loaded? | Applied? | Notes |
|-------|-------------|---------|----------|-------|
| `CDD.md` | Tier 1a | yes | yes | Lifecycle structure followed; triadic protocol applied |
| `alpha/SKILL.md` | Tier 1a | yes | yes | Pre-review gate passed; incremental commits; debt explicit |
| `cdd/post-release` | Issue §Skills, Tier 3 | yes (declared) | yes | Report structured as post-release measurement |
| `cnos.core/skills/write` | Issue §Skills, Tier 3 | yes (declared) | yes | Report prose is clear, non-redundant |

---

## Findings

| # | Finding | Evidence | Severity | Type |
|---|---------|----------|----------|------|
| F1 | Two self-coherence reports in diff; engine-path report undeclared in self-coherence.md | `git diff --stat` shows `docs/alpha/engine/0.7.0/SELF-COHERENCE.md` and `docs/alpha/engine/README.md`. Neither appears in self-coherence.md §ACs, CDD Trace step 6, or §Self-check. Path decision declared in self-coherence.md §Path Decision: "Keyed to spec version (docs/alpha/doctrine/3.2.0/)." CDD.md §5.5: "one source of truth per fact." | C | judgment + contract |
| F2 | Score discrepancy between the two reports for engine and repo targets | Provenance JSON (authoritative engine output): engine γ=0.6870376→0.687, engine c_sigma_mechanical=0.5206792→0.521, repo γ=0.6800543→0.680, repo c_sigma_mechanical=0.6598163→0.660. Engine-path report §1.2: engine γ=0.691, C_Σ=0.522; §1.3: repo γ=0.682, C_Σ=0.661. Doctrine report is consistent with provenance JSON. Engine-path deviates because its W2 table mixes two runs with different input file sets (~8 min apart per report's own note). | C | mechanical |
| F3 | Engine-path report contains "direct" 4th target (C_Σ=0.921) with no provenance JSON | Engine-path §1.4 reports `direct` target (tsc-core.md + runtime/SELF-MEASURE.md). No `provenance/direct.json` in diff. Issue scope declares three targets: spec, engine, repo. AC3 oracle requires provenance per target. Applies only if engine-path report is retained. | C | judgment |
| F4 | Engine-path W2 spread values (engine 0.0013, repo 0.0007) derive from corpus instability between runs, not from gauge-invariance testing | Engine-path §2 note: "Tiny gamma variation in engine/repo between runs reflects files added to the working tree between the two runs (~8 minutes apart)." W2 gauge spread measures invariance to the canonical remap procedure (axis-label permutation), not corpus change. Doctrine report's w_gauge_spread=0.000 based on S₃-symmetry argument is correct for the W2 definition. Applies only if engine-path report is retained. | B | judgment |

### Resolution paths

F1 + F2 + F3 + F4 share a single root cause: the engine-path report was produced but not declared, and its data is inconsistent with the authoritative provenance JSON. Two options:

**Option A (recommended — single commit):** Remove `docs/alpha/engine/0.7.0/SELF-COHERENCE.md` from the branch. Revert the `docs/alpha/engine/README.md` v0.7.0 version-history row. The doctrine-path report is the canonical output as declared by the path decision. The engine README retains the 0.3.0 precedent. Eliminates F1, F2, F3, F4.

**Option B (if engine-path continuity is required):** Declare the engine-path report in self-coherence.md §ACs (AC6 extended or new AC), CDD Trace step 6, and §Self-check; state its relationship to the doctrine canonical. Reconcile engine/repo scores using provenance JSON values (not run-2 values). Add `provenance/direct.json` or remove §1.4 "direct" from the engine-path report. Reframe the W2 table: clarify spread reflects corpus instability, not gauge stability, or replace with the S₃-symmetry argument matching the doctrine report. Requires ~4 fix commits.

---

## Notes

**D3 (α declared debt):** "Aggregate C_Σ formula not specified in spec. The report uses geometric mean of per-target C_Σ values." β assessment: the formula is internally consistent (geometric mean of per-target arithmetic means, `(0.898 × 0.521 × 0.660)^(1/3) = 0.675`). Explicit declaration as debt is correct; no additional finding required. γ should assess whether this formula should be canonicalized in tsc-oper.md.

**W2 interpretation in doctrine report:** The doctrine report's w_gauge_spread=0.000 is correctly grounded in the S₃-symmetry argument for mechanical mode. The `canonical_remap_procedure` field in provenance JSON is present. AC4 is met at the doctrine path.

**Provenance JSON schema:** All required v3.2.0 fields from tsc-oper.md §6 are present across all three provenance files. Mechanical-mode null fields (barrier_clip_eta_phi, link_lipschitz_constants) are recorded as null with explanatory notes field. AC3 is met.

**CI state:** Docs-only change; no OCaml code modified. Local build+tests green per α's gate. Provisional CI state is acceptable for this change shape.

---

## Verdict — Round 1

**REQUEST CHANGES.** Four findings (F1–F4) must be resolved before merge. F1 is the root cause; F2, F3, F4 all derive from the undeclared engine-path report.

**Blocker summary:**
- F1 (C): `docs/alpha/engine/0.7.0/SELF-COHERENCE.md` is in the diff but not declared in self-coherence.md. Path decision was doctrine path. CDD.md §5.5 requires one source of truth per fact. **Block until resolved.**
- F2 (C): Engine/repo scores differ between the two reports. Provenance JSON is authoritative; engine-path deviates. **Block until resolved.**
- F3 (C): "direct" target in engine-path report has no provenance JSON. **Block if engine-path report is retained.**
- F4 (B): W2 spread in engine-path report reflects corpus instability, not gauge invariance. **Block if engine-path report is retained.**

**Recommended fix (Option A):** Remove `docs/alpha/engine/0.7.0/SELF-COHERENCE.md`. Revert the `docs/alpha/engine/README.md` v0.7.0 version-history row. Single commit, branch remains docs-only. Eliminates all four findings.

**On α fix-round:** Append a fix-round section to `.cdd/unreleased/29/self-coherence.md` with the resolution approach and the fixing commit SHA. β will re-review the affected surfaces (diff stat + both README files + self-coherence.md) and write round 2 of this file.

**Search space:** No remaining blocker found in the doctrine-path report, provenance JSON, AC coverage, or CDD Trace rows — those surfaces are coherent. The sole blocker set is the undeclared engine-path report and its downstream consequences.

---

## Verdict — Round 2

**Verdict:** APPROVED

**Round:** 2
**Fixed this round:** `97f627a` (remove engine-path report + revert engine README — closes F1, F2, F3, F4), `635cabb` (fix-round documentation in self-coherence.md)
**origin/main SHA:** `ee4a84d72a65b780e401b673f7ea10d27f375fb2` (re-fetched synchronously; unchanged from R1)
**Branch head SHA:** `635cabb1a7e426eb4bafa7ab7e903773a03305cf`
**Branch CI state:** docs-only change; no OCaml code modified; local build+tests green per α pre-review gate
**Merge instruction:** `git merge --no-ff cycle/29-self-coherence` into main with `Closes #29`

---

### §2.0.0 Contract Integrity — Round 2

| Check | Result | Notes |
|---|---|---|
| Status truth preserved | yes | Mechanical mode honest; debt D1–D4 explicit |
| Canonical sources/paths verified | yes | Single doctrine-path report; engine-path report removed from diff |
| Scope/non-goals consistent | yes | Three declared targets; no undeclared surfaces remain |
| Constraint strata consistent | yes | No violations |
| Exceptions field-specific/reasoned | n/a | No exception-backed fields |
| Path resolution base explicit | yes | All paths repo-root-relative and verified |
| Proof shape adequate | yes | AC oracles (file existence + provenance JSON) appropriate |
| Cross-surface projections updated | yes | Doctrine README updated (AC6 ✓); engine README reverted to pre-cycle state ✓ |
| No witness theater / false closure | yes | Scores backed by provenance JSON; no competing report |
| PR body matches branch files | n/a | No PR in triadic CDD |

**Contract integrity gate:** All rows yes or n/a. Gate passes.

---

### §2.0 Issue Contract — Round 2 (verification of affected surfaces)

**AC Coverage:** All six ACs remain met. Unchanged from R1 except that the undeclared engine-path report is no longer in the diff — no competing scores, no path conflict.

Score cross-check (provenance JSON vs. doctrine-path report):

| Target | Axis | Provenance JSON | Report (3dp) | Match |
|--------|------|----------------|--------------|-------|
| spec | α | 0.9681 | 0.968 | ✓ |
| spec | β | 0.9100 | 0.910 | ✓ |
| spec | γ | 0.8148 | 0.815 | ✓ |
| spec | C_Σ_mech | 0.8976 | 0.898 | ✓ |
| engine | α | 0.6500 | 0.650 | ✓ |
| engine | β | 0.2250 | 0.225 | ✓ |
| engine | γ | 0.6870 | 0.687 | ✓ |
| engine | C_Σ_mech | 0.5207 | 0.521 | ✓ |
| repo | α | 0.9147 | 0.915 | ✓ |
| repo | β | 0.3847 | 0.385 | ✓ |
| repo | γ | 0.6801 | 0.680 | ✓ |
| repo | C_Σ_mech | 0.6598 | 0.660 | ✓ |

**Named Doc Updates:** `docs/alpha/engine/0.7.0/SELF-COHERENCE.md` — absent from `git diff main...HEAD --stat` ✓. `docs/alpha/engine/README.md` — absent from `git diff main...HEAD --stat` ✓ (reverted in 97f627a, net-zero relative to main).

**CDD Artifact Contract:** self-coherence.md has fix-round section documenting 97f627a resolution; round-2 review-readiness signal present. beta-review.md (this file) updated.

### Findings — Round 2

| # | Finding | Evidence | Severity | Type |
|---|---------|----------|----------|------|
| — | No findings | — | — | — |

All R1 findings (F1–F4) resolved by removal of the undeclared engine-path report (97f627a). No new findings. No remaining blocker.

---

### Pre-merge Gate — Round 2

| Row | Check | Result |
|-----|-------|--------|
| 1 | Identity: `git config user.email` = `beta@cdd.tsc` | ✓ |
| 2 | `git fetch origin main` → origin/main = `ee4a84d` (unchanged from R1) | ✓ |
| 3 | Docs-only cycle; no new contract surface shipped → collapsed per β/SKILL.md | ✓ |

Gate passes. Proceeding to merge.
