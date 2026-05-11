---
cycle: 32
issue: "#32"
branch: "cycle/32-impl"
reviewer: "beta"
date: "2026-05-09"
---

# Beta Review — Cycle #32

## Round 1

**Verdict:** APPROVED
**Round:** 1
**Branch CI state:** provisional — α's libcurl fix (`libcurl4-openssl-dev` pre-install + `ubuntu-22.04` runner pin in `.github/workflows/ci.yml` lines 10, 19–20) is principled but unverified from this review context; β did not run the workflow against `cycle/32-impl` HEAD.
**Merge instruction (on APPROVE):** `git merge cycle/32-impl` into main with `Closes #32`.

## §2.0.0 Contract Integrity

| Check | Result | Notes |
|---|---|---|
| Status truth preserved | yes | self-coherence §Gap distinguishes shipped findings (#29 D2/D3 — shipped cycles producing carry-over) from MCI items (cycle #26 γ doc-debt; #27/#29 protocol-skip residual) cleanly; no draft/planned/shipped conflation. |
| Canonical sources/paths verified | yes | `.cdd/releases/docs/2026-05-08/{27,29}/` matches `.cdd/release/SKILL.md §2.5b` docs-only target. `.cdd/iterations/INDEX.md` matches `cdd/post-release/SKILL.md` Step 5.6b. Spec patch path consistent (`spec/tsc-oper.md` v3.2.1 with glossary Corresponds-to line bumped). |
| Scope/non-goals consistent | yes | Non-goals from issue body (#28 P3, D1 hybrid run, D4 CI on scores, cnos upstream) preserved as known-debt in self-coherence; no scope creep observed. |
| Mode declaration justified | yes | `design-and-build` justification names the single design judgment (cross-target C_Σ formula + placement at §7.4 + patch-bump scope) and explicitly excludes MCA via §Mode-declaration criteria (no separate design+plan at stable path). |
| Cycle scope sizing block present + justified | yes | Sizing table present in self-coherence §Cycle scope sizing; keep-whole-with-justification chosen at-edge with AC8 acknowledged as recursive-coherence requirement. Justification is tight: cleanup bundles disparate hygiene by design, splitting D3 would multiply close-out artifacts for a single-section addition. |
| Proof shape adequate | yes | Per-AC commit (one AC per commit), oracle-runnable invariants in each AC block, friction log + CDD trace populated at readiness. |
| Cross-surface projections updated | yes | Spec header (v3.2.1 lines 1, 3), end-marker, CHANGELOG row (Spec v3.2.1 2026-05-09 entry, CHANGELOG.md:7), glossary Corresponds-to (`spec/tsc-glossary.md:5`) all consistent. No stale "TSC Operational v3.2.0" cross-references remain after the bump. |

## §2.0 Issue Contract

### AC Coverage

| # | AC | In diff? | Status | Notes |
|---|----|----------|--------|-------|
| AC1 | engine.tsc excludes `_build` | yes (9ff9450) | MET | `targets/engine.tsc:20` shows `"engine/ocaml/_build/**"` in `exclude` block. |
| AC2 | spec/tsc-oper.md canonicalizes cross-target C_Σ | yes (dd7bd8c) | MET | §7.4 added (`spec/tsc-oper.md:397–416`); formula `C_Σ_cross = (∏ C_Σ_i)^(1/n)` present; properties block covers worst-component dominance, math/num split propagation, verdict invariance; provenance requirement stated; cross-target example included. Header bumped to v3.2.1 with change-note line. End-marker bumped. |
| AC3 | CONTRIBUTING.md + PR template no Python refs | yes (b29526e) | MET | Oracle `grep -iE "pip install\|pytest\|requirements\.txt\|setup\.py\|pyproject\.toml"` returns nothing in either file. Support Matrix replaced with OCaml/opam/dune; install steps rewritten to `opam install`/`dune build`/`dune runtest`. |
| AC4 | `.cdd/unreleased/{27,29}/` moved per §2.5b | yes (14ad74e) | MET | `find .cdd/releases/docs -path '*27*' -name '*.md' \| wc -l` = 5; same for 29. `find .cdd/unreleased -name '*.md'` returns only `.cdd/unreleased/32/self-coherence.md` (plus this beta-review.md). ISO-date `2026-05-08` matches each cycle's original merge date per α's justification. |
| AC5 | CI fix replaces broken `libcurl4-gnutls-dev` | yes (8e303cf) | MET (artifact) / provisional (runner) | `.github/workflows/ci.yml:14–20` adds explicit `apt-get install -y libcurl4-openssl-dev pkg-config` step; runner pinned to `ubuntu-22.04` (line 10). α's own framing of "provisional — runner verification not possible from dispatch" is honest. Artifact matches the claim. |
| AC6 | Issues #6 and #22 closed via verify-and-close | yes (GitHub-side) | MET | `mcp__github__issue_read` returns `state: closed`, `state_reason: completed` for both #6 (closed 2026-05-11T04:01:27Z) and #22 (closed 2026-05-11T04:01:29Z). |
| AC7 | `.cdd/iterations/INDEX.md` + `cross-repo/` initialized | yes (35bc685) | MET | `.cdd/iterations/INDEX.md` present with header per Step 5.6b template, 1 row (cycle #32). `.cdd/iterations/cross-repo/README.md` present documenting layout convention. |
| AC8 | Recursive coherence — this cycle's own close-out follows protocol | partial (impl side) | DEFERRED — post-merge | Per AC8's own definition, the full artifact set (`alpha-closeout.md`, `beta-closeout.md`, `gamma-closeout.md`, `cdd-iteration.md` at `.cdd/releases/docs/2026-05-09/32/`) is post-merge. Implementation-side prerequisites that ARE checkable now: `self-coherence.md` populated through Step 7a with friction log, CDD trace, readiness signal (Head SHA 35bc685 = last implementation commit, distinct from readiness commit's own 1ca3b81 SHA per dispatch §3.13 directive). |

### CDD Artifact Contract

| Artifact | Required? | Present? | Notes |
|----------|-----------|----------|-------|
| `.cdd/unreleased/32/self-coherence.md` | yes (γ scaffold + α appends) | yes | §Gap, §Mode, §Cycle scope sizing, §Active skills, §Impact graph, §ACs (8 numbered, oracle-bearing), §Self-check, §Known debt, §CDD trace (through step 7a), §Friction log, §Review-readiness signal all present. |
| `.cdd/unreleased/32/beta-review.md` | yes (this file) | yes (this round) | Round 1 written. |
| `alpha-closeout.md`, `beta-closeout.md`, `gamma-closeout.md`, `cdd-iteration.md` | post-merge | not yet | AC8 — produced after disconnect at `.cdd/releases/docs/2026-05-09/32/`. |
| CHANGELOG ledger row | yes (D3 patch bumps spec) | yes | `CHANGELOG.md:7–13` Spec v3.2.1 (2026-05-09) row present, names affected files (`spec/tsc-oper.md` §7.4; `spec/tsc-glossary.md` corresponds-to), cites cycle #29 D3, and clarifies `spec/tsc-core.md` unchanged. |

## Findings

| # | Finding | Evidence | Severity | Type |
|---|---------|----------|----------|------|
| F1 | `SECURITY.md:59` contains live instruction `Run pip install --upgrade tsc-framework regularly` — a stale Python install instruction outside the two surfaces named in AC3 but identical in nature to the doc debt AC3 closes. AC3 was scoped to `CONTRIBUTING.md` + `.github/pull_request_template.md`, so this is NOT a missed AC; per dispatch "AC3 was scoped to two files but a thorough cleanup checks all docs", filed as observation. | `grep -n "pip install" SECURITY.md` → line 59 | B | scope-edge / out-of-AC observation |
| F2 | `spec/tsc-oper.md:416` example text reads "A v3.2.0 self-coherence run". The "v3.2.0" here refers to the engine implementing Core v3.2.0 (the foundation), not to the Operational spec (now v3.2.1). The reference is technically consistent with the unchanged Foundation declaration at line 5 ("Foundation: TSC Core v3.2.0"), but readers scanning for "v3.2.0/v3.2.1" inside §7.4 may parse this as a version label for the section itself. Cosmetic only; no behavioural ambiguity. | `spec/tsc-oper.md:416` | A | polish |
| F3 | `RELEASE.md:30` and `docs/gamma/cdd/0.7.0/POST-RELEASE-ASSESSMENT.md:145` reference the AC3-resolved doc debt as still-pending MCI. These are post-release artifacts of v0.7.0 (point-in-time release notes / assessment), not live instructional content. AC3 closes the live surfaces; back-references in dated release artifacts remain factually true about that release's state. No action expected; filed as observation. | `grep -n "doc-cleanup MCI" RELEASE.md docs/gamma/cdd/0.7.0/*.md` | A | historical-artifact observation |
| F4 | self-coherence §Review-readiness signal Branch CI state mentions "commits exist locally at HEAD 9e71ebc but are not yet published" while the actual published HEAD on `cycle/32-impl` (the branch β reviewed) is `1ca3b81` (readiness commit) with last implementation commit `35bc685`. The "9e71ebc" SHA does not match any commit on `cycle/32-impl` between `origin/main..HEAD`. Interpretation: a stale local SHA from an earlier α dispatch attempt that did not survive the rebase/republish to `cycle/32-impl`. The Head SHA field on the line above correctly reports `35bc685`. | `git log --oneline origin/main..HEAD` shows: 1ca3b81, 35bc685, 8e303cf, dd7bd8c, 14ad74e, b29526e, 9ff9450, 5fef886. No `9e71ebc`. | C | provenance / honest-claim hygiene |
| F5 | self-coherence §CDD trace row "6 Implement" lists six commit SHAs in narrative form but the actual implementation work spans six commits matching one-AC-per-commit discipline (9ff9450, b29526e, 14ad74e, dd7bd8c, 8e303cf, 35bc685) — all six are present in the git log and each commit message names its AC. Per-AC commit boundary is clean. No mixed-AC commits observed. | `git log --oneline origin/main..HEAD` | n/a | verification-pass note |

## Rule 3.13 Honest-Claim Findings

| # | Pass | Subject | Detail |
|---|------|---------|--------|
| 3.13(a) | yes (with one caveat) | Reproducibility | All AC oracles reproduce against the diff. α's framing of AC5 as "provisional — runner verification not possible from dispatch" is honest and matches the artifact (the workflow edit is real; only runner outcome is unverified). AC1–AC4, AC6, AC7 fully reproduce. **Caveat (F4):** "HEAD 9e71ebc" claim in the CI-state narrative is a stale SHA that doesn't trace to the branch; severity C above. |
| 3.13(b) | yes | Source-of-truth alignment | §7.4 terminology (`C_Σ_cross`, `C_Σ_i`, `C_Σ^math`, `C_Σ^num`, `zero_component_present`) consistent with Core §5.2, §5.4 and the existing `C_Σ` definition. No new term introduced that would require a glossary entry — the cross-target form is constructed from existing glossed terms ("target" is already glossed as a scope, "geometric mean" already in use in Core §5.2). |
| 3.13(c) | yes | Wiring claims | Spec v3.2.0 → v3.2.1 bump propagates as α claimed: `spec/tsc-oper.md` header (line 1), Version line (line 3), end-marker (line 478), CHANGELOG row (CHANGELOG.md:7), glossary Corresponds-to (spec/tsc-glossary.md:5) all updated. `spec/tsc-core.md` v3.2.0 references untouched (correct — Core is the foundation of Operational v3.2.1, no Core bump needed). The "Pre-v3.2.0" / "v3.2.0 provenance fields" mentions in `spec/tsc-oper.md` lines 45, 307, 416 and in `spec/tsc-glossary.md` lines 705, 744 are historical / foundation-version references, not stale operational version markers. |

## Notes

- AC3 oracle (per dispatch): `grep -iE "pip install\|pytest\|requirements\.txt\|setup\.py\|pyproject\.toml" CONTRIBUTING.md .github/pull_request_template.md` returns NOTHING — confirmed.
- Repo-wide oracle (per dispatch broader sweep): one live-instruction Python ref found at `SECURITY.md:59` (F1, severity B, out-of-AC). README.md, QUICKSTART.md, ARCHITECTURE.md clean.
- `tests/` directory: does not exist (Python tests retired in cycle #26; cycle #32 does not introduce a new `tests/` dir at repo root — engine tests live under `engine/ocaml/test/`). Confirmed via `find /home/user/tsc/tests`.
- `.cdd/unreleased/` post-AC4 contains only `32/` (this cycle's working dir, plus this beta-review.md). Confirmed.
- AC6 GitHub-side verification: #6 closed 2026-05-11T04:01:27Z, #22 closed 2026-05-11T04:01:29Z, both `state_reason: completed`. Both are within the cycle window.
- Head SHA in readiness signal = `35bc685` (last implementation commit, distinct from readiness commit's own `1ca3b81`). Matches dispatch directive.
- Branch name on origin is `cycle/32-impl` (harness-imposed; α's self-coherence §Friction-log explains the original `cycle/32` branch could not be force-updated). Merge target remains `main` per dispatch.
