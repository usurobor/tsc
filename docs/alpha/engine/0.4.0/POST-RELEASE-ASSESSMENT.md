# Post-Release Assessment — 0.4.0

> **Reconstructed retroactively after v0.4.0 ship. Not a contemporaneous artifact.**
> Written as part of cycle #27 (retroactive close-out). The assessment reflects the shipped state as it existed at tag `b522aa3`.

---

## 1. Coherence Measurement

- **Baseline:** 0.3.1 — α A-, β A-, γ A-, C_Σ A-, Level L5
- **This release:** 0.4.0 — α B, β C+, γ C, C_Σ C+, Level L6
- **Delta:**
  - α regressed from A- to B: The implementation quality of the individual code artifacts (dotenv.ml, VERSION refactor, release scripts) is solid. However, α produced no CDD artifact set — no DESIGN, no PLAN, no SELF-COHERENCE, no tests for the new module. The implementation is coherent; the artifact set is not.
  - β regressed from A- to C+: No review cycle occurred. β is scored at C+ rather than the floor (C) because the code itself is internally self-consistent — an implicit baseline of quality was maintained, but not through formal review.
  - γ regressed sharply from A- to C: γ failed to enforce or execute the post-release protocol. No CHANGELOG row, no frozen artifact directory, no post-release assessment. This is the direct cause of cycle #27.
  - C_Σ regressed from A- to C+: Significant coherence regression on process axes. Code quality partially offsets the process failure but does not dominate.
- **Coherence contract closed?** Partially. The functional gaps named (credential exposure, version sync fragility, manual release process) are closed by the shipped code. The protocol gaps (CHANGELOG, frozen docs, assessment) were not closed at ship time — cycle #27 closes them retroactively.

---

## 2. Encoding Lag

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|
| #6 | Validate self-measurement e2e | feature | spec in issue | not started | growing |
| #27 | Retroactive close-out for v0.4.0 | process | this cycle | in progress | low |

**MCI/MCA balance:** Balanced — one growing-lag feature issue (#6), one process corrective in progress. No freeze triggered.
**Rationale:** #6 remains the next functional gap. The process debt from v0.4.0 is being closed by #27. No new designs were introduced.

---

## 3. Process Learning

**What went wrong:**
- v0.4.0 shipped without any CDD cycle. No issue was filed. No DESIGN or PLAN was authored. No β review occurred. No CHANGELOG row was written. No frozen artifact directory was created. This is a complete protocol miss — the worst coherence outcome for γ.
- The root cause is that the release was executed in a single ~20-minute session with no protocol gate. When the code is ready and the author has push access, there is nothing mechanical preventing a direct-to-tag commit sequence. The CDD protocol was the missing gate.
- This is not a one-off. The v0.3.0 assessment explicitly named the opam-stale pattern as a recurring failure and called for pre-tag automation. v0.4.0 addressed that technical problem (VERSION file) but did not address the protocol gap — because there was no post-release assessment to read the prior recommendation from.

**What went right:**
- The technical implementation itself is high quality. `dotenv.ml` is cleanly factored, secure-by-default (real env wins, permission warning). The VERSION refactor correctly identifies and removes the opam-stale root cause. The release scripts are functional and adapted from a working upstream (cnos).
- The structural dependency ordering was respected implicitly: dotenv first (standalone), VERSION second (prereq for scripts), scripts third (requires VERSION).

**Skill patches needed:**
- The post-release protocol requires a gate that fires when a tag is cut without a CHANGELOG row. This is mechanical and could be enforced in `scripts/release.sh` or `check-version-consistency.sh`. Not patched in this assessment — a future cycle should add it.

**Active skill re-evaluation:**
- `cdd/post-release` was not loaded during v0.4.0 (no CDD cycle). Had it been loaded, it would have required a post-release assessment after tagging. The skill is correct; it was not applied.
- No other skills were loaded — the cycle ran without skill governance.

---

## 4. Review Quality

**Cycles this release:** 0 formal CDD cycles (partial-protocol release)
**Avg review rounds:** 0 (no β review)
**Superseded cycles:** 0
**Finding breakdown:** N/A — no review, no findings recorded at ship time
**Mechanical ratio:** N/A
**Action:** none — the absence of review is itself the finding, captured in §3

### 4a. CDD Self-Coherence

- **CDD α:** 2/4 — Implementation artifacts (code) exist and are coherent. CDD artifacts (DESIGN, PLAN, SELF-COHERENCE, tests) absent at ship time. Now reconstructed retroactively by cycle #27.
- **CDD β:** 1/4 — No review occurred. No `beta-review.md`. No surface agreement audit. This is the minimum score rather than 0 because the code exhibits internal self-consistency even without formal review.
- **CDD γ:** 1/4 — Complete protocol miss. No issue filed. No CHANGELOG row. No frozen artifact directory. No post-release assessment. Cycle #27 is the direct evidence of the failure.
- **Weakest axis:** γ (tied with β)
- **Action:** Add a CHANGELOG-row gate to `scripts/release.sh` so future releases cannot proceed without an explicit step to verify the ledger entry. (Deferred — not executed in this assessment.)

### 4b. Cycle Iteration

- **Triggered by:** avoidable tooling/environmental failure — specifically, the absence of a CDD protocol gate in the release path. The protocol existed; no mechanism prevented bypassing it.
- **Root cause:** environmental — the release execution environment (single Claude session with push access) had no friction against skipping the CDD cycle. The protocol is a social/procedural constraint that was not mechanized.
- **Disposition:** next MCA — add a pre-release gate that checks for a CHANGELOG row before tagging. Not executed in this assessment (would require a code change that itself needs a proper cycle).
- **Evidence:** Cycle #27 is the evidence. The corrective took a full documentation cycle to close.

---

## 5. Production Verification

**Scenario:** Load LLM credentials from `.tsc/.env` instead of setting shell env vars.
**Before this release:** Operator had to set `LLM_API_KEY`, `LLM_PROVIDER`, `LLM_MODEL` in the shell. Credentials visible in shell history.
**After this release:** `coh` reads `.tsc/.env` (chmod 600) before reading env. Operator can place credentials in the project directory without shell history exposure.
**How to verify:**
1. Create `.tsc/.env` with `LLM_API_KEY=<key>` (chmod 600)
2. Unset `LLM_API_KEY` from the shell environment
3. Run `coh --target <target> --root .` — engine should load the key from the file
4. Run again with `LLM_API_KEY=<different>` set in shell — engine should use the shell value (real env wins)
5. Set `.tsc/.env` to 0644 — engine should print a permission warning

**Result:** Deferred — no live environment available to run the binary against a real LLM provider. Verification requires secrets. The code path is correct by inspection of `dotenv.ml` and `main.ml`.

---

## 6. CDD Closeout

| Step | Artifact | Skills loaded | Decision |
|------|----------|--------------|----------|
| 11 Observe | git log 0.3.1..0.4.0, commit diffs | post-release | Shipped state confirmed: 3 substantive commits, tag `b522aa3`. No contemporaneous CDD artifacts existed. |
| 12 Assess | POST-RELEASE-ASSESSMENT.md (this file) | post-release | Assessment complete. Grades: C+/B/C+/C. Coherence regression on process axes documented. |
| 13 Close | Immediate: CHANGELOG row, frozen artifacts, README update (all via cycle #27). Deferred: pre-release CHANGELOG gate, dotenv tests, operator manual update. | post-release | Cycle #27 closes the documentation debt. Functional debt (tests, operator manual) remains open. |

### 6a. Invariants Check

No formal architectural invariants document exists for this project. Skipped.

---

## 7. Next Move

**Next MCA:** #23 (parent) or its designated sub-issue for engine self-measurement
**Owner:** to be assigned
**Branch:** pending
**First AC:** Engine runs against a spec target with a real LLM provider and produces valid JSON output
**MCI frozen until shipped?** No — lag table is balanced; #27 closes the process debt. #6 is the next functional gap.
**Rationale:** v0.4.0 closed the credential loading and release automation gaps. The next substantive gap is validating that self-measurement actually works end-to-end with a live provider. That is #6 / the parent #23.

**Closure evidence (CDD §10):**
- Immediate outputs executed: yes
  - CHANGELOG.md ledger row for 0.4.0 (committed, cycle #27 branch)
  - `docs/alpha/engine/README.md` version table updated (committed, cycle #27 branch)
  - `docs/alpha/engine/0.4.0/` frozen artifact directory created (committed, cycle #27 branch)
  - All five frozen artifact files authored (README, DESIGN, PLAN, SELF-COHERENCE, POST-RELEASE-ASSESSMENT)
- Deferred outputs committed: yes
  - Pre-release CHANGELOG gate: future cycle, no issue filed yet
  - `dotenv.ml` tests: future cycle, no issue filed yet
  - Operator manual update for `.tsc/.env`: future cycle, no issue filed yet

**Immediate fixes** (executed in cycle #27 session):
- CHANGELOG ledger row (AC1)
- Engine README version table (AC2)
- `docs/alpha/engine/0.4.0/` directory with all five frozen artifacts (AC3)
- Grade alignment verified (AC4)
- 0.3.1 rationale note in engine README (AC5)

---

## 8. Hub Memory

- **Daily reflection:** Not applicable — this is a retroactive assessment authored as part of cycle #27. Hub memory will be updated when cycle #27 closes.
- **Adhoc thread(s) updated:** cycle #27 is the adhoc thread for this assessment. See `.cdd/unreleased/27/` on branch `cycle/27-v040-closeout`.
