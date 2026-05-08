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
