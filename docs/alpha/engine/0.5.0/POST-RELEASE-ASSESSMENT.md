# Post-Release Assessment — 0.5.0

> **ARCHIVAL — pre-v3.2 scoring.** This assessment records the v0.5.0
> release, in which `c_sigma` was the arithmetic mean of α, β, γ.
> v0.10.0 cut the engine over to the canonical v3.2 geometric aggregate
> (`c_sigma_math` / `c_sigma_num`). Historical instructions and example
> JSON in this document reflect the pre-cutover shape.

**Author:** γ
**Date:** 2026-05-08
**Issue:** #25 (Sub 2 of #23)
**Merge commit:** 597e87d

---

## 1. Coherence Measurement

- **Baseline:** 0.4.0 — α B, β C+, γ C, C_Σ C+, Level L6 (retroactive)
- **This release:** 0.5.0 — α A, β A, γ A, C_Σ A, Level L6
- **Delta:**
  - α improved B → A: Complete CDD artifact set (design and plan already committed at `docs/design/0.5.0/`; self-coherence, 12-AC implementation, 61-assertion test suite, all shipped). The one partial AC (AC8) is correctly scoped and disclosed. Artifact integrity is high.
  - β improved C+ → A: Full CDD review cycle with two rounds. F1 (correctness) caught and resolved; F2 (documentation accuracy) caught and resolved. Pre-merge gate executed. Review quality is high.
  - γ improved C → A: Full protocol followed from issue dispatch through close-out. Branch created, triage complete, RELEASE.md authored, cycle directory moved, PRA written. No protocol gaps.
  - C_Σ improved C+ → A: All three axes performed at A level. The coherence regression at 0.4.0 (partial-protocol release) is fully corrected.
- **Coherence contract closed?** Yes. The hybrid scoring gap (LLM-only engine, no `--mode`, no `--files`, `.mli` without `.ml`) is closed. `coh --mode mechanical --files <paths>` works without credentials. All 12 ACs from #22 map to evidence.

---

## 2. Encoding Lag

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|
| #23 Sub 1 | v3.2.0 provenance fields in report sub-objects | feature | Spec v3.2.0 shipped; report container defined | Not started | growing |
| #23 Sub 3 | Python test migration, OCaml integration tests, AC8 closure | feature | Implicit in master #23 scope | Partial (scaffolding in this cycle) | low |
| #23 Sub 5 | Claude CLI provider | feature | Mentioned in master #23 | Not started | growing |
| #6 | Validate self-measurement end-to-end | feature | Spec in issue | Not started | growing |
| alpha/SKILL.md §2.6 row 9 patch | Test-assertion count check in pre-review gate | process | Gap named in γ close-out | Not started | growing |

**MCI/MCA balance:** Balanced — three growing-lag feature items but none exceed the 3:1 design-to-implementation ratio that would trigger a freeze. Sub 3 is the selected next MCA (implementation catchup). No new design commitments introduced this cycle.
**Rationale:** v0.5.0 implements the mechanical foundation that Sub 3 needs. Selecting Sub 3 next continues the implementation-priority push. Sub 1 (v3.2.0 provenance) and Sub 5 (Claude CLI) are growing but not yet blocking.

---

## 3. Process Learning

**What went wrong:**
- F2 (assertion count 58 vs. 61): α authored the self-coherence count from code inspection rather than test output. Running the test suite and reading its output line would have closed this before β's first pass. The polyglot re-audit gate (alpha/SKILL.md §2.6 row 9) does not explicitly name test-assertion count verification as a step. This is a skill gap.

**What went right:**
- β caught both R1 findings independently without prompting. F1 was a semantic correctness bug (keyword-list inversion) that had no test catching it; β's manual signal-semantics audit was the only gate that could catch it. The review-as-quality-gate worked as intended.
- Single fix round: both R1 findings resolved in one commit set (45b16bf + 2ef36ce). No additional rounds required.
- The fix-round commit shape was clean: code change and CDD artifact update in separate commits, distinct concerns, clean trace.
- Branch CI state (local dune build + 61/61 tests) was verified by both α and β before merge. The absence of remote CI is pre-existing and disclosed.

**Skill patches:** Not patched in this session (patch requires cnos repo access). Committed as next MCA: patch alpha/SKILL.md §2.6 row 9 to add test-assertion count check.

**Active skill re-evaluation:**

| Finding | Active skill referenced | Would skill have prevented it? | Assessment |
|---------|------------------------|-------------------------------|------------|
| F1: bare `"#"` in `trace_kws` | alpha/SKILL.md §2.6 row 9 (polyglot re-audit) | Partially — row 9 specifies full-language OCaml re-audit but doesn't name semantic review of keyword-list entries | Application gap: the skill was right; α didn't apply deep semantic review to keyword lists. No skill patch for F1. |
| F2: assertion count drift | alpha/SKILL.md §2.6 row 9 (polyglot re-audit) | No — row 9 doesn't name test-assertion count verification | Skill gap: row 9 underspecified for this pattern. Skill patch committed as next MCA. |

**CDD improvement disposition:** Skill patch committed as next MCA (cnos: alpha/SKILL.md §2.6 row 9 — add test-assertion count check). Cannot land in this session without cnos repo access. Owner: γ. First AC: row 9 names running the test suite and verifying its output count against the self-coherence claim as a required pre-review step.

---

## 4. Review Quality

**Cycles this release:** 1 (cycle/25)
**Avg review rounds:** 2.0 (target: ≤2 for code cycles — at target)
**Superseded cycles:** 0 (target: 0 — met)
**Finding breakdown:** 2 mechanical / 0 judgment / 2 total
**Mechanical ratio:** 100% (N=2, below ≥10 threshold — ratio is noise at this N; no process issue filing required)
**Action:** none — both findings were low-N mechanical; below the 10-finding threshold for process issue filing. Skill gap noted and committed as next MCA.

### 4a. CDD Self-Coherence

- **CDD α:** 4/4 — All required artifacts present: `self-coherence.md` with full CDD Trace through step 7, AC-by-AC evidence, known debt explicit, pre-review gate rows completed. Implementation matches `.mli` contract. Test suite present and passing.
- **CDD β:** 4/4 — Round-by-round verdicts in `beta-review.md`; AC verification table complete; pre-merge gate executed (identity, skill freshness, merge-tree test 61/61). `beta-closeout.md` with merge evidence complete.
- **CDD γ:** 4/4 — Full protocol: issue dispatched, branch created, close-out triage table complete, §9.1 triggers assessed, RELEASE.md authored, cycle directory moved, PRA written. No protocol gaps vs. 0.4.0's complete miss.
- **Weakest axis:** none — all at 4/4 this cycle.
- **Action:** none.

### 4b. Cycle Iteration

- **Triggered by:** Loaded-skill miss — F2 (test count drift) catchable by a check not in alpha/SKILL.md §2.6 row 9.
- **Root cause:** alpha/SKILL.md §2.6 row 9 (polyglot re-audit) specifies language-toolchain verification but not test-assertion count verification against self-coherence claims.
- **Disposition:** Next MCA committed — patch alpha/SKILL.md §2.6 row 9 in cnos repo. Owner: γ. First AC: row 9 names running test suite and verifying output count against self-coherence claim.
- **Evidence:** α O1: "running the test and reading the output line before writing the count would have closed this"; γ close-out triage table skill-gap row.

---

## 5. Production Verification

**Scenario:** Offline mechanical scoring — run `coh --mode mechanical --files spec/` without any LLM credentials.
**Before this release:** Engine was LLM-only. `coh` required `LLM_API_KEY`; running without credentials would fail or hang on network.
**After this release:** `coh --mode mechanical --files <paths>` computes structural signals locally and produces a valid JSON report without network or credentials.
**How to verify:**
1. Unset `LLM_API_KEY` from the environment.
2. Run `coh --mode mechanical --files spec/`.
3. Check that exit code is 0 and the JSON output contains `"mode": "mechanical"` and a `mechanical` sub-object with `c_sigma`, signal scores for α, β, γ axes.
4. Confirm no network request was made (no credential error, no HTTP attempt).

**Result:** Deferred — no live build environment available in this γ session. The code path is correct by code review and by the 61-assertion test suite passing. Operator should verify as part of post-tag validation.

---

## 6. CDD Closeout

| Step | Artifact | Skills loaded | Decision |
|------|----------|--------------|----------|
| 11 Observe | alpha-closeout.md, beta-closeout.md, beta-review.md, self-coherence.md | post-release | Reviewed all four cycle artifacts. 2 findings (F1 correctness, F2 doc accuracy), both resolved. AC8 partial by design. |
| 12 Assess | POST-RELEASE-ASSESSMENT.md (this file) | post-release | Assessment complete. Grades: A/A/A/A. Coherence recovery from 0.4.0 C+ complete. |
| 13 Close | gamma-closeout.md, RELEASE.md, CHANGELOG.md, VERSION 0.5.0, cycle dir moved to releases/0.5.0/25/ | post-release, gamma | Cycle closed. Loaded-skill miss committed as next MCA. AC8 + Sub 1 + Sub 5 deferred. |

### 6a. Invariants Check

No formal architectural invariants document exists for this project.

---

## 7. Next Move

**Next MCA:** #23 Sub 3 — Python test migration, `tests/conformance/` cleanup, `--mode auto` integration test.
**Owner:** to be assigned via γ dispatch.
**Branch:** pending — γ creates `cycle/<N>` from `origin/main` before dispatch.
**First AC:** `git ls-files '*.py'` returns empty.
**MCI frozen until shipped?** No — lag table is balanced; implementing Sub 3 is catchup, not new design.
**Rationale:** AC8 (no Python) is the most concrete open AC across the system. Sub 3's OCaml test infrastructure now has the mechanical scoring foundation it needs (shipped this cycle). The `--mode auto` integration test deferred from this cycle is also Sub 3 scope.

**Closure evidence (CDD §10):**
- Immediate outputs executed: yes
  - `gamma-closeout.md` authored and committed
  - `RELEASE.md` authored (v0.5.0) and committed
  - `CHANGELOG.md` 0.5.0 ledger row + section committed
  - `VERSION` updated to 0.5.0
  - `docs/alpha/engine/README.md` version table updated
  - Cycle directory moved from `.cdd/unreleased/25/` to `.cdd/releases/0.5.0/25/`
  - POST-RELEASE-ASSESSMENT.md authored (this file)
- Deferred outputs committed: yes
  - Sub 3 (AC8, integration tests): master #23 Sub 3 — pending γ dispatch
  - Sub 1 (v3.2.0 provenance): master #23 Sub 1 — pending γ dispatch
  - alpha/SKILL.md §2.6 row 9 patch: cnos repo — owner γ, first AC defined in γ close-out

**Immediate fixes** (executed this session):
- `RELEASE.md` authored for v0.5.0 (replacing spec v3.2.0 release notes)
- `CHANGELOG.md` v0.5.0 ledger row + section added
- `VERSION` bumped to 0.5.0
- `docs/alpha/engine/README.md` version table updated
- `gamma-closeout.md` authored with triage table + §9.1 assessment + deferred outputs
- `POST-RELEASE-ASSESSMENT.md` authored (this file)
- Cycle directory moved: `.cdd/unreleased/25/` → `.cdd/releases/0.5.0/25/`

---

## 8. Hub Memory

- **Daily reflection:** Not updated — γ operating in tsc workspace without hub repo access. Next γ session with hub access should write a daily reflection recording: v0.5.0 shipped (hybrid scoring, 3 modes, A/A/A), loaded-skill miss in alpha/SKILL.md §2.6 row 9 committed as next MCA, next MCA is #23 Sub 3.
- **Adhoc thread(s) updated:** Not updated in this session. The master #23 thread should be updated with: Sub 2 (#25) closed, Sub 3 is the selected next.
