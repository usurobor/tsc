# Post-Release Assessment — 0.6.0

**Release:** TSC Engine v0.6.0
**Issue:** #24 — Sub 1 (#23): Implement TSC spec v3.2.0 in the OCaml engine
**Merge commit:** 36d0fe5125b12d1e03a20fef52c6512b7d819627
**Date:** 2026-05-08
**Assessed by:** γ

---

## 1. Coherence Measurement

- **Baseline:** 0.5.0 — α A, β A, γ A · C_Σ A · Level L6
- **This release:** 0.6.0 — α B+, β A, γ B+ · C_Σ B+ · Level L6

**Delta:**
- **α (artifact integrity):** Held / slight regression from 0.5.0 A to B+. Seven ACs implemented correctly; all spec sections covered. Integration-wiring gaps (F1, F2) required two fix rounds and were not caught at pre-review. Known debt: AC6 end-to-end integration (LLM_API_KEY not available). The implementation quality is high; the process execution dropped slightly.
- **β (surface agreement):** Held at A. Three-round review with clear narrowing pattern. F5 catch (write-before-verify) is substantive — β identified a contract claim that the implementation did not back. Merge evidence clean. β surface agrees with implementation post-merge.
- **γ (cycle economics):** Slight regression from 0.5.0 A to B+. Three review rounds vs. target ≤2. Issue quality was good (7 concrete ACs, clear scope, clean dispatch). The friction was in the α pre-review phase; γ coordination was clean. MCI filed for process improvement.

**Coherence contract closed?** Yes. All seven ACs are evidenced in the merged diff. The v3.2.0 transformation chain (`δ → φ(δ) → D → Coh`) is now implemented deterministically in the engine. Spec authority drift is resolved for Sub 1.

**What remains:** AC6 integration test (live LLM path) is declared debt. Engine does not yet derive `s_beta` from δ values (Option B deferred). Master #23 remains open.

---

## 2. Encoding Lag

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|
| #23 | Master: TSC v3.2.0 full implementation | feature | converged (v3.2.0 spec shipped) | Sub 1 done; Sub 2 done; Sub 3 open | low |
| #24 | Sub 1: OCaml engine v3.2.0 | feature | converged | shipped (this release) | none |
| #22 | Sub 3: test migration | feature | design converged | not started | growing |

**MCI/MCA balance:** Balanced. One sub-issue ships this release; one remains. No freeze threshold reached (< 3 items at "growing" lag, no 3:1 design-to-implementation ratio).
**Rationale:** The v3.2.0 spec was the design commitment; two of three subs have shipped. Sub 3 (test migration) is growing lag but does not trigger freeze.

---

## 3. Process Learning

**What went wrong:**
1. Integration wiring gaps reached β review (R1 F1 + F2). Both α-side functions were implemented, unit-tested, and declared "done" in self-coherence AC tables — but were not wired into the runtime entry path. The pre-review gate passed CI green but did not catch the integration gap.
2. Write-before-verify produced a false contract claim (R2 F5). The R1→R2 fix for F3 replaced the known-wrong behavior with a doc claim that the engine did not implement. Self-coherence peer enumeration in the same commit declared both surfaces "corrected" without verifying the behavioral claim against the code.

**What went right:**
1. β narrowing was effective: R1 (4 findings) → R2 (1 finding) → R3 (0). The cascade was identified and closed.
2. β caught F5 on R2 — a subtle write-before-verify pattern that would have produced functional regression for all LLM-driven measurements (LLM following the false instruction `beta=0.0` → all reports showing `C_sigma_math = 0.0`).
3. Alpha's Option A choice (doc truthfulness over scope expansion) was correct: it closed F5 without introducing new scope.
4. The mathematical structure (φ, D, Coh; math/num split; L_link case-split) was implemented cleanly and separates well into distinct functions.

**Skill patches:** None landed in this session. Patch target (`alpha/SKILL.md` §2.6) is in the `cnos` repo; requires a CDD cycle there. Deferred as project MCI (see §7).

**Active skill re-evaluation:**

| Finding | Would loaded α/SKILL.md §2.6 pre-review gate have prevented it? | Verdict |
|---------|------------------------------------------------------------------|---------|
| F1 (extract_deltas not wired in main.ml) | No — gate requires AC evidence but not caller-path trace for new modules | Skill underspecified → patch needed |
| F2 (gauge_witness not called from provenance_v320) | No — same root as F1 | Skill underspecified → patch needed (consolidate with F1) |
| F3 (LLM asked for beta_preview approximation) | Partial — "no witness theater" check in gate should have caught this; self-coherence §2.3 peer enumeration requires cross-surface check | Application gap (check existed but wasn't applied deeply enough) |
| F4 (test label) | Yes — the gate requires "test references ACs" but this is mechanical; would have been caught with a deeper audit | Application gap |
| F5 (false engine-derivation claim) | No — peer enumeration requires cross-surface verification but does not explicitly require verifying behavioral claims trace to an implemented code path | Skill underspecified → same patch as F1/F2 variant |

**CDD improvement disposition:** Patch needed for `alpha/SKILL.md` §2.6. Cannot land here (different repo). Filed as project MCI — see §7 Deferred Outputs. This is not a "no patch needed" disposition; it is a deferred patch with a concrete target.

---

## 4. Review Quality

**Cycles this release:** 1 (cycle #24)
**Review rounds:** 3 (R1 RC, R2 RC, R3 A) — target: ≤2 for code cycles. **Target missed.**
**Superseded cycles:** 0 — target: 0. ✓
**Finding breakdown:** 1 mechanical (F4: test label) / 4 judgment (F1, F2, F3, F5) / 5 total
**Mechanical ratio:** 20% (1/5) — threshold: >20% AND ≥10 findings. Not triggered (< 10 total findings).
**Action:** None filed (below threshold). Noted for pattern tracking.

---

## 4a. CDD Self-Coherence

- **CDD α:** 3/4 — All ACs delivered; clean math implementation; tests comprehensive. Integration-wiring gaps (F1, F2) and write-before-verify (F5) reached review; pre-review gate was followed but underspecified for these patterns. Provisional close-out correctly declared.
- **CDD β:** 4/4 — Narrowing pattern confirmed across 3 rounds. F5 catch demonstrates surface-agreement depth. Merge evidence complete. Factual observations only in close-out (no dispositions).
- **CDD γ:** 3/4 — Issue quality was tight (7 concrete ACs, explicit scope, clear non-goals). Three review rounds vs. target ≤2. Dispatch was clean; no unblocking needed. MCI filed for skill gap. Hub memory deferred (no hub repo in environment).
- **Weakest axis:** α (process execution, not implementation quality)
- **Action:** Patch `alpha/SKILL.md` §2.6 — deferred MCI in cnos repo.

---

## 4b. Cycle Iteration

- **Triggered by:** review rounds > 2 (actual: 3)
- **Root cause:** Integration wiring gaps (F1/F2) and write-before-verify (F5) not caught by α pre-review gate. Pre-review gate in `alpha/SKILL.md` §2.6 does not require (a) caller-path trace for new module wiring or (b) verification that behavioral doc claims trace to implemented code paths.
- **Disposition:** Project MCI → file improvement issue in cnos repo for `alpha/SKILL.md` §2.6 patch. Cross-repo; cannot land in this commit.
- **Evidence:** Deferred Outputs table in gamma-closeout.md; this assessment §7.

---

## 5. Production Verification

**Scenario:** Engine emits v3.2.0-conformant provenance JSON on a real `coh` run.

**Before this release:** Engine (v0.5.0) called `Report.to_json` without `delta_*` args; provenance fields (`discrepancy_symbol`, `coherence_link`, `barrier_phi`, etc.) were absent or null in output.

**After this release:** `coh --target spec --mode llm` with a valid `LLM_API_KEY` should return a JSON report containing `discrepancy_symbol`, `coherence_link`, `aggregate_math` (with `C_sigma_math`, `zero_component_present`), `aggregate_numeric`, `gauge_witness` (with `w_gauge_ref`, `w_gauge_spread`), and all other v3.2.0 provenance keys.

**How to verify:**
```bash
cd src/engine/ocaml
dune build
LLM_API_KEY=<key> ./_build/default/bin/main.exe --target spec --mode llm | python3 -m json.tool | grep -E "discrepancy_symbol|coherence_link|aggregate_math|gauge_witness"
```
Or run the fixture schema validator against a generated report:
```bash
dune runtest  # verifies schema structure via fixture
```

**Result:** Deferred for live-LLM path (LLM_API_KEY not available in this environment). `dune runtest` passes (69 assertions in `test_coherence.ml`). Schema structure verified via fixture. Full integration test is AC6 declared debt.

---

## 6. CDD Closeout

| Step | Artifact | Skills loaded | Decision |
|------|----------|--------------|----------|
| 11 Observe | `.cdd/unreleased/24/` close-outs + beta-review.md | post-release | Runtime/design alignment confirmed post-merge; F1/F2/F5 all closed before merge |
| 12 Assess | `docs/gamma/cdd/0.6.0/POST-RELEASE-ASSESSMENT.md` | post-release | Assessment completed; §9.1 trigger documented; MCI filed as deferred |
| 13 Close | gamma-closeout.md + RELEASE.md + CHANGELOG.md + VERSION + cycle-dir move | post-release | Cycle closed; deferred outputs committed; immediate outputs: none possible cross-repo |

### 6a. Invariants Check

No architectural invariants document found in this repo. Section omitted per post-release/SKILL.md §6a.

---

## 7. Next Move

**Next MCA:** Next open sub-issue under master #23 — Sub 3 (test migration, #22 backlog) or the next γ-filed sub-issue.
**Owner:** α / δ per γ selection at next cycle start
**Branch:** `cycle/{N}` from `origin/main` — created by γ before dispatch
**First AC:** As specified in the next issue pack under #23
**MCI frozen until shipped?** No — not at freeze threshold
**Rationale:** Sub 1 of #23 closed (v0.6.0). Sub 2 of #23 closed (v0.5.0). Sub 3 is growing lag; next selection follows CDD §3 rule order. No P0, no ops override. Assessment-commitment default (CDD §3.3) nominates Sub 3.

**Closure evidence (CDD §10):**

- Immediate outputs executed: yes (none were possible in-repo; cross-repo skill patch explicitly deferred with rationale)
- Deferred outputs committed: yes
  - project MCI: file `alpha/SKILL.md` §2.6 improvement issue in cnos repo / owner: γ / first AC: add caller-path trace row to pre-review gate
  - technical debt: AC6 live-LLM integration test / owner: α / first AC: run integration path with LLM_API_KEY in CI

**Immediate fixes executed this session:** None (only cross-repo fix applies; explicitly noted as deferred MCI).

---

## 8. Hub Memory

- **Daily reflection:** No hub repo configured in this environment. State to record at next available session: cycle 24 closed as v0.6.0; §9.1 trigger fired (review churn); MCI for `alpha/SKILL.md` §2.6 patch deferred to cnos; next MCA is Sub 3 of #23.
- **Adhoc thread(s) updated:** Deferred — same constraint. Thread to update: `#23 master implementation arc` — note Sub 1 closed, Sub 2 closed, Sub 3 outstanding.
