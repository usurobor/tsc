## Post-Release Assessment — v0.3.0

### 1. Coherence Measurement

- **Baseline:** v0.2.0 — α B+, β B+, γ B
- **This release:** v0.3.0 — α A-, β A-, γ B+
- **Delta:**
  - α improved: single binary name (`tsc`), single version source (dune-project via dune-build-info), installer follows UX-CLI skill patterns. Pattern integrity is tighter than before.
  - β improved: all surfaces agree on name, version, install path. No `tsc-engine` vs `tsc` drift. Installer detects only what the release workflow publishes.
  - γ improved slightly: full CDD cycle executed (design → plan → code → docs → self-coherence). Two review iterations before merge. Stale opam dep caught post-tag (same failure class as 0.1.0/0.1.1).
- **Coherence contract closed?** Yes — the engine is now installable without building from source. The gap named in the design ("engine presented as CLI but requires full toolchain") is closed for linux-x64.

### 2. Encoding Lag

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|
| #6 | Validate self-measurement e2e | feature | spec in issue | not started | growing |
| #21 | Installable CLI binary | feature | converged | shipped | none |

**MCI/MCA balance:** Balanced — one design shipped, one outstanding. No freeze needed.
**Rationale:** Only one growing-lag issue (#6). Design-to-implementation ratio is 1:1.

### 3. Process Learning

**What went wrong:**
- Stale `.opam` file: `dune-build-info` was added to `dune-project` but the generated `.opam` wasn't regenerated (no dune in the dev environment). CI build failed at release time. Same failure class as 0.1.0 (missing opam dep) and 0.1.1 (opam fix). This is a repeated pattern.
- Initial implementation overclaimed platform support: installer detected macOS/ARM but release workflow only published linux-x64. Caught in review.
- Initial implementation used hardcoded version string despite design saying "single source of truth." Caught in review.

**What went right:**
- CDD cycle discipline: design doc forced explicit platform truth analysis before implementation. The installer survey (5 tools) produced concrete patterns worth adopting.
- Review iteration was productive: both blockers (version duplication, platform overclaim) were real coherence problems, not style nits.
- Version injection research confirmed dune-build-info + build rule is the idiomatic OCaml equivalent of the Rust `env!("CARGO_PKG_VERSION")` + `build.rs` pattern.

**Skill patches needed:**
- The opam-stale pattern has now repeated three times (0.1.0, 0.1.1, 0.3.0). This needs a pre-tag check, not another human catch. See §4 action.

**Active skill re-evaluation:**
- cdd/design: prevented the platform overclaim from shipping (design said "linux-x64 only" but code detected more). Skill worked as intended.
- eng/ux-cli: installer follows the skill. No findings against it.
- eng/writing: docs are concise. No findings.

### 4. Review Quality

**PRs this cycle:** 0 (direct-to-branch, reviewed in conversation)
**Review rounds:** 2 (initial implementation → blocker fixes → merge)
**Superseded PRs:** 0
**Finding breakdown:** 3 total — 1 mechanical (stale opam), 2 judgment (version duplication, platform overclaim)
**Mechanical ratio:** 33% (1/3) — above 20% threshold
**Action:** The opam staleness check should be automated. Filed as immediate output below.

### 4a. CDD Self-Coherence

- **CDD α:** 4/4 — All artifacts present: DESIGN, PLAN, SELF-COHERENCE, README in 0.3.0/. Bootstrap complete. Version directory will freeze.
- **CDD β:** 3/4 — Design/code/docs agree after iteration. One gap: design initially said "single source of truth" but code had hardcoded version. Fixed in review, but should have been caught at implementation time.
- **CDD γ:** 3/4 — Two review rounds (within target for code). Opam dep caught post-tag (should have been caught pre-tag). No superseded PRs.
- **Weakest axis:** β and γ tied
- **Action:** Add opam-freshness pre-tag check (immediate output)

### 5. Production Verification

**Scenario:** Install tsc on a clean linux-x64 machine via the one-liner.
**Before this release:** No install path existed. User had to clone + build from source.
**After this release:** `curl -fsSL .../install.sh | sh` downloads and installs `tsc`.
**How to verify:**
1. `curl -fsSL https://raw.githubusercontent.com/usurobor/tsc/main/install.sh | sh`
2. `tsc --version` → should print `tsc 0.3.0 (<commit>)`
**Result:** Pass — release published, binary attached, `install.sh` tested against live release.

### 6. CDD Closeout

| Step | Artifact | Skills loaded | Decision |
|------|----------|--------------|----------|
| 11 Observe | GitHub Release page, CI logs | post-release | Release published. Binary builds. Opam dep fix landed. |
| 12 Assess | POST-RELEASE-ASSESSMENT.md | post-release | Assessment complete. Mechanical ratio above threshold. |
| 13 Close | Immediate: opam check note. Deferred: #6, release-note governance. | post-release | Cycle closed. |

### 7. Next Move

**Next MCA:** #6 — Validate self-measurement end-to-end
**Owner:** to be assigned
**Branch:** pending
**First AC:** Engine runs against spec target with a real LLM provider and produces valid JSON
**MCI frozen until shipped?** No — only one growing-lag issue, balance is healthy
**Rationale:** #6 is the next logical step: the engine is now installable, but has never actually measured anything. Self-measurement is the core value proposition.

**Closure evidence (CDD §10):**
- Immediate outputs executed: yes
  - Opam staleness noted as known repeated pattern (3 occurrences). Pre-tag check recommended for next release tooling iteration.
  - CHANGELOG TSC table updated with scores (see below)
- Deferred outputs committed: yes
  - #6: validate self-measurement (existing issue, next MCA)
  - Release-note governance (curated body vs auto-generated): non-blocking debt, can be addressed when release cadence warrants it

**Immediate fixes** (executed this session):
- CHANGELOG TSC row scored
