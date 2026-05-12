---
cycle: 38
issue: "#38"
role: beta
identity: beta@tsc.cdd.cnos
branch: cycle/38-impl
parent_branch: cycle/38
date: 2026-05-12
round: R1
reviewed_head: 040204b
parent_main_sha: 8e3094c
gamma_scaffold_sha: 83fd217
---

# β Review — Cycle #38 (R1)

## Phase 1 — Contract integrity

**Files changed vs γ's impact graph.**

γ scaffold §Impact graph names:
- `.github/workflows/katas.yml` (MODIFY — artifact upload + step summary + new published-binary job)
- `katas/README.md` (MODIFY — §Where to find kata results)

`git diff origin/main origin/cycle/38-impl --name-only` returns exactly five files:
- `.cdd/unreleased/38/alpha-closeout.md`   (α-closeout — required artifact)
- `.cdd/unreleased/38/claims.md`           (honest-claim manifest — required artifact)
- `.cdd/unreleased/38/self-coherence.md`   (γ scaffold + α head-SHA meta line — pre-existing surface)
- `.github/workflows/katas.yml`            (in graph)
- `katas/README.md`                        (in graph)

No files outside the impact graph were touched. **No scope creep.** Verified `git diff origin/main origin/cycle/38-impl -- engine/**` returns empty — the "no engine code changes" dispatch-prompt constraint is honoured.

`+738 / -6` lines, all within the workflow YAML, the README section, and the cycle's `.cdd/unreleased/38/` documents. Contract integrity: **clean**.

## Phase 2 — AC walk

### AC1 — Per-kata JSON artifact uploaded

**Requirements:** one JSON per kata directory in `.kata-results/`; uploaded via `actions/upload-artifact@v4`; `if: always()`.

**Verification:**
- `.github/workflows/katas.yml` lines 247–254: `actions/upload-artifact@v4`, `name: kata-results-${{ github.sha }}`, `path: .kata-results/`, `retention-days: 90`, `if-no-files-found: ignore`, `if: always()`. ✓
- Capture site at lines 145–183 (Run all katas step): `mkdir -p .kata-results`; per-kata `"$COH" --kata "$id" --mode mechanical | tee ".kata-results/${id}.json"`. ✓
- The mirror in the `validate-published-binary` job at lines 432–439 uses `name: kata-results-published-${{ env.RELEASE_TAG }}-${{ github.run_id }}` (version-indexed) — same upload mechanism, distinct artifact name. ✓
- `set +e` + `PIPESTATUS[0]` (line 165, 359) ensures (a) one failing kata does not short-circuit the loop, (b) the engine's exit code (not `tee`'s) drives pass/fail. This is the correct non-obvious bash detail. ✓
- The engine's JSON shape matches what AC2's parser reads — confirmed by reading `engine/ocaml/bin/main.ml` lines 505–515: `kata_id`, `expected_verdict`, `c_sigma`, `score_range.{min,max}`, `kata_pass`, `mechanical`. ✓

**Status:** AC1 satisfied.

### AC2 — Step summary surfaces per-kata score

**Requirements:** `$GITHUB_STEP_SUMMARY` markdown table; rows for each kata (Verdict / C_Σ / Range / Status).

**Verification:**
- `.github/workflows/katas.yml` lines 198–241: `Emit kata step-summary table` step, `if: always()`.
- Line 209: `echo "| Kata | Verdict | C_Σ | Range | Status |" >> "$GITHUB_STEP_SUMMARY"` — five-column schema matches the AC's named columns plus a leading `Kata` column (consistent with `katas/README.md` line 93). ✓
- Lines 213–238 — python3 heredoc parses each `.kata-results/*.json`, emits one row per kata; unparseable JSON renders a `:warning:` row in-line rather than failing the step. ✓
- Mirror in the published-binary job at lines 383–426 emits the same schema under a tag-qualified section title (line 386 — `## Kata Results — Published Binary ($RELEASE_TAG)`). ✓
- The python3 dependency is sound: ubuntu-22.04 runners pre-install python3, and `tsc.yml::Display results` (line 98) already relies on this exact assumption. Pattern parity holds. ✓
- Step-summary pattern matches `tsc.yml` lines 85–112 in shape — same `>> $GITHUB_STEP_SUMMARY` write pattern, same `if: always()` guard. ✓

**Status:** AC2 satisfied.

### AC3 — Published-binary validation job runs

**Requirements:** new job; triggers `release: types: [published]` + weekly cron + manual; runs kata loop against released binary; independent pass/fail.

**Verification:**
- New job `validate-published-binary` at lines 294–439. ✓
- Top-level `on:` block at lines 47–51 adds `release: types: [published]`, `schedule: cron: '0 6 * * 1'` (Mon 06:00 UTC — matches issue §Open question 2 weekly recommendation), `workflow_dispatch`. ✓
- Job-level `if:` at line 299 restricts execution to those three event types — push/PR runs skip this job, preserving the pre-merge gate as additive-not-replacement (per §Open question 4 recommendation). ✓
- Kata loop at lines 342–377 mirrors `run-katas`'s loop but invokes `./coh-linux-x64`. JSON capture via `tee`, PIPESTATUS-based exit code preservation, aggregate pass/fail enforcement — identical shape. ✓
- Tag resolution at lines 320–325: prefers `${{ github.event.release.tag_name }}` for release events; falls back to `gh release view --json tagName --jq .tagName` for cron / dispatch. Stored in `$GITHUB_ENV` as `RELEASE_TAG` so downstream steps see it. ✓
- Failure mode is notify-only (per §Open question 5 recommendation) — non-zero kata exit fails the job, workflow renders red, but no release is blocked and no PR is gated. The workflow does not invoke `gh release delete` or similar. ✓

**Status:** AC3 satisfied. Oracle (trigger via workflow_dispatch / wait for cron) requires post-merge runtime confirmation, which is γ's F2 step.

### AC4 — Release-artifact discovery mechanism documented

**Requirements:** Path A or Path B; choice justified in `alpha-closeout.md`.

**Verification:**
- `.cdd/unreleased/38/alpha-closeout.md` §AC4 (lines 56–74) names Path B explicitly, marks the deviation from γ scaffold's Path A recommendation, gives four justifications. ✓
- Workflow inline comment at lines 270–283 enumerates the same three core rationale points (no missing-artifact risk; source-vs-artifact drift coverage; cheaper runtime). ✓
- The job actually implements Path B: `gh release download "$tag" --pattern 'coh-linux-x64' --output coh-linux-x64` at line 328. Not a build-from-tag opam pathway. ✓
- Re-run oracle: same released binary + same kata corpus = same pass/fail (modulo infra drift, which is precisely what the cron exists to catch). ✓

**Deviation assessment** — see dedicated §AC4 deviation assessment below.

**Status:** AC4 satisfied with documented deviation.

### AC5 — Documentation updated

**Requirements:** `katas/README.md` §Where to find kata results subsection, ≤120 words.

**Verification:**
- `katas/README.md` lines 88–95 contain `## Where to find kata results` between "Runner invocation" and "Adding a new kata" — correct positioning per α-closeout §AC5.
- Word count: 113 words (verified `awk` between section heading and next `## `). Under 120-word ceiling. ✓
- Content names: both artifact names (`kata-results-<sha>` and `kata-results-published-<tag>-<run_id>`), 90-day retention, Artifacts panel + `gh run download` retrieval paths, row schema, and the published-binary section title. All AC5 invariants present. ✓
- `rg 'Where to find kata results' katas/README.md` → 1 hit (oracle satisfied). ✓

**Status:** AC5 satisfied.

## Phase 3 — Rule 3.13 honest-claim verification

### Claim 1 — Wiring: artifact-upload + step-summary patterns now exist in `katas.yml`

- **(a) Reproducibility.** Pre-state probe: `git show 8e3094c:.github/workflows/katas.yml | grep -nE 'upload-artifact|GITHUB_STEP_SUMMARY'` → exit 1, zero output (confirmed). Post-state probe: `grep -nE 'upload-artifact|GITHUB_STEP_SUMMARY' .github/workflows/katas.yml | wc -l` → **16 hits**. α's manifest says "14 hits"; the actual count is 16. The discrepancy is α undercounting their own work (the 2 extra hits are the two header-comment references at lines 23 and 185 — both legitimate). Above the ≥3 threshold by a wide margin. The miscount is C-severity advisory at most. ✓
- **(b) Source-of-truth alignment.** Both patterns trace to canonical `tsc.yml` (lines 85–112), per γ's §Read-only/model-on list. ✓
- **(c) Wiring grep-verified.** Two `upload-artifact@v4` steps (lines 249, 434); seven `$GITHUB_STEP_SUMMARY` `echo` writes; one `if: always()` per upload + one per summary-emit step. ✓

**Verdict:** Claim 1 holds. **C-finding** noted: α's claim says "14 hits"; actual is 16 (α's manifest also says "well above the ≥3 threshold" — no false positive, just inexact).

### Claim 2 — Source-of-truth alignment: step-summary row schema matches docs

- **(a) Reproducibility.** Re-ran `grep -nE '\| Kata \| Verdict \| C_.{1,3} \| Range \| Status \|' .github/workflows/katas.yml katas/README.md` → 2 hits in `katas.yml` (lines 209, 394, both the `echo "...|" >> $GITHUB_STEP_SUMMARY` statements; plus a comment-anchor at line 189) + 1 hit in `katas/README.md` line 93. The total grep returns 4 lines because line 189 of katas.yml is a comment that contains the same schema fragment — this is *additional* corroboration, not drift. ✓
- **(b) Source-of-truth alignment.** Engine JSON keys (`kata_id`, `expected_verdict`, `c_sigma`, `score_range.{min,max}`, `kata_pass`) confirmed at `engine/ocaml/bin/main.ml` lines 506–513. The python3 parser at workflow lines 213–238 reads exactly those keys; no key invented, no key silently dropped. ✓
- **(c) Wiring grep-verified.** Schema appears in 4 distinct surfaces: workflow comment, workflow run-katas summary-emit, workflow validate-published-binary summary-emit, README docs. ✓

**Verdict:** Claim 2 holds.

### Claim 3 — Reproducibility: AC4 Path B is documented + verifiable from CLI

- **(a) Reproducibility.** The repro recipe (`gh release download --pattern 'coh-linux-x64' …`) is exactly what the workflow runs at line 328 (modulo: workflow passes the tag explicitly via `gh release download "$tag" …`, while the manifest's CLI recipe omits the tag — which `gh release download` interprets as "latest", equivalent for verification purposes). Path-B precondition (release `coh-linux-x64` asset published) verified: `mcp__github__list_releases` for `usurobor/tsc` returns five releases including v0.4.0; `release.yml` line 41/48 confirms each v* tag uploads `coh-linux-x64`. ✓
- **(b) Source-of-truth alignment.** `coh-linux-x64` traces to `release.yml` line 41 (rename step) + 48 (`softprops/action-gh-release@v2` files arg). ✓
- **(c) Wiring grep-verified.** `grep -n 'Path B' .github/workflows/katas.yml .cdd/unreleased/38/alpha-closeout.md` returns 4 hits in workflow + 5 hits in closeout. ✓

**Verdict:** Claim 3 holds. **B-finding declined** for the no-released-asset edge case (see §AC4 deviation below) — `gh release download` exits non-zero on missing pattern, and `set -euo pipefail` (workflow line 319) causes the step to fail cleanly, not hang.

### Claim 4 — No false negation: γ's §Gap was correct

- **(a) Reproducibility.** Re-ran the F1 enumeration script (`for f in .github/workflows/*.yml; do git show 8e3094c:"$f" | grep -c …; done`):
  - `cdd-notify.yml`: upload=0, summary=0
  - `ci.yml`: upload=1, summary=0
  - `katas.yml`: upload=0, summary=0
  - `release.yml`: upload=0, summary=0 (uses `softprops/action-gh-release@v2`, not `actions/upload-artifact`)
  - `tsc.yml`: upload=1, summary=7
  Matches γ's §Gap table at `.cdd/unreleased/38/self-coherence.md` lines 18–24 exactly. ✓
- **(b) Source-of-truth alignment.** Every row in γ's §Gap table cross-checks against the file's content at `8e3094c`. `release.yml` row's nuance (uses softprops instead of upload-artifact) is explicit in the table. ✓
- **(c) Wiring grep-verified.** The enumeration recipe is bash-mechanical; β reran it; results match. ✓

**Verdict:** Claim 4 holds. **F1 self-application verified** (see §F1 self-application verification below).

## AC4 deviation assessment

γ scaffold's §Read-only/model-on at self-coherence.md line 77 names "release-artifact mechanics for AC4 Path B option" — γ explicitly held Path B open. Issue #38 §AC4 names both options as valid and asks α to "Justify the choice in alpha-closeout." Issue §Open question 3 recommends Path A but acknowledges Path B as the better choice if release.yml's upload is verified — and γ's §Gap table did verify it.

**Each of α's four justifications evaluated:**

1. **No missing-artifact risk.** Verified empirically — `mcp__github__list_releases` shows 5 published releases with `coh-linux-x64`; `release.yml` lines 41/48 confirm the upload mechanism. ✓
2. **Source-vs-artifact drift coverage.** Load-bearing and correct: issue §Problem explicitly frames AC3's motivation as catching "what users *download* still passes katas, not just what main builds." Path A defeats this purpose — Path B does not. ✓
3. **Cheaper (~30s vs ~3 min).** Plausible: release.yml's build job is dominated by `opam install . --deps-only -y` (~2–3 min cold cache, ~30–60s warm) + `dune build` (~20–40s). Download + chmod + run is unambiguously faster. Specific numbers are estimates, not measured, but the order-of-magnitude framing is sound. ✓
4. **γ's scaffold left room for the deviation.** Confirmed by self-coherence.md line 35 ("AC3's published-binary validation has a Path-A vs Path-B decision — empirical anchor: release.yml *does* upload `coh-linux-x64`, so Path B is materially possible (not blocked by absent artifact)"). γ pre-licensed the deviation. ✓

**Edge case: no published release yet.** If `gh release view --json tagName` runs against a repo with zero releases, gh CLI exits non-zero. The workflow uses `set -euo pipefail` at line 319, so the step fails cleanly with the gh error message visible. **Not a hang.** For this repo (v0.4.0 already shipped), the edge case is not currently reachable. For a future scenario where the repo is force-reset, the failure mode is observably-red, not silently-broken.

**Verdict:** Deviation **accepted**. Path B's runtime + drift-coverage advantages outweigh the simplicity of Path A; γ's scaffold pre-licensed the choice; the issue body framed both as valid.

## Forward-compat header verification

Dispatch prompt asked α to update the INTERIM header so the new published-binary job is also named as scope-of-future-canonical-template replacement.

`.github/workflows/katas.yml` lines 1–13:

```
# katas.yml — engine kata regression gate
#
# INTERIM workflow (tsc cycles #36 + #38).
# This file is the v1 local implementation of the katas-in-CI gate.
# It will be replaced by canonical templates landed by:
#   - cnos #344 Cycle B (template authoring)
#   - tsc cycle C-2 (template adoption)
# Until then, this is the source of truth for kata CI. Both the
# build-from-HEAD pre-merge gate (`run-katas`) AND the published-binary
# validation job (`validate-published-binary`, added cycle #38 AC3+AC4)
# will be replaced by canonical cnos #344 Cycle B templates once those
# land.
```

Lines 8–12 explicitly name both jobs as part of the interim surface that will be replaced by cnos #344 Cycle B templates. **Compliant.** ✓

## F1 self-application verification

γ's §Gap peer-enumeration table (self-coherence.md lines 18–24) claims `katas.yml` had no `upload-artifact` and no `$GITHUB_STEP_SUMMARY` on `8e3094c`.

`git show 8e3094c:.github/workflows/katas.yml | grep -nE 'upload-artifact|GITHUB_STEP_SUMMARY'` → exit 1, zero hits. **Confirmed.**

Full enumeration table reproducibility shown under Claim 4 above — all five rows match γ's table.

**F1 self-application: PASS.** γ peer-enumerated before authoring §Gap; α independently re-verified; β re-verified again. The discipline gate held.

## Concurrency-group debt

α flagged at end of closeout: "Cron + release job concurrency — the top-level `concurrency:` group keys on `github.ref`. … Verified by reasoning, not by empirical test."

Assessment: this is a **no-finding / note-only**.

Reasoning: the top-level `concurrency:` group at line 60 is `group: katas-${{ github.ref }}` with `cancel-in-progress: ${{ github.event_name == 'pull_request' }}`. For release events `github.ref` resolves to `refs/tags/v*` — does not collide with `refs/heads/main` (push events) or `refs/pull/N/merge` (PR events). For schedule events `github.ref` resolves to `refs/heads/main`. So scheduled cron *could* in principle share the group with a push-to-main, but `cancel-in-progress` is `false` for `schedule` events (since `github.event_name != 'pull_request'`), so the in-flight job is preserved, not cancelled. The protective property (PR-trigger cancellation) operates correctly; non-PR triggers are never cancelled. α's analysis is correct on paper. Empirical confirmation requires waiting for a real cron-vs-push collision, which is γ's F2 step territory if it ever fires.

**No β finding.**

## Engine `--output` finding — verification

α discovered the engine's `--output` flag is not wired for kata mode and adapted via `tee`. Verified:

- `engine/ocaml/bin/main.ml` line 219: `("--output", Arg.Set_string output_dir, …)` — declared. ✓
- Lines 299, 358, 365, 371, 426: `Filename.concat args.cli_output_dir …` — used for `--target` / `--files` mode report-file paths. ✓
- Line 516: `Printf.printf "%s\n" (Yojson.Safe.pretty_to_string result_json)` — `run_kata` emits to stdout, never references `cli_output_dir`. ✓

α's `tee` workaround captures stdout correctly because the engine's JSON is on stdout (Printf.printf), and `tee` writes to both stdout (preserved for step log under `::group::`) and `.kata-results/${id}.json`. `PIPESTATUS[0]` (line 165, 359) preserves the engine's exit code, not `tee`'s. **The bash idiom is correct.** ✓

The dispatch-prompt constraint "no engine code changes" is honoured. The follow-on (wire `--output` for kata mode in a future engine cycle) is correctly tracked in `.cdd/unreleased/38/alpha-closeout.md` §"Engine `--output` wiring — finding" and at workflow comment lines 133–140.

## Identity convention

All 6 cycle/38-impl commits authored by `alpha@tsc.cdd.cnos`:

```
040204b alpha@tsc.cdd.cnos meta(38): record α R1 head SHA in self-coherence
ad8ab93 alpha@tsc.cdd.cnos closeout(38): α R1 closeout + honest-claim manifest
c0e4329 alpha@tsc.cdd.cnos docs(38): add "Where to find kata results" — AC5
422eb02 alpha@tsc.cdd.cnos ci(38): add published-binary validation job — AC3+AC4
074b54b alpha@tsc.cdd.cnos ci(38): add step-summary table for kata results — AC2
d517de1 alpha@tsc.cdd.cnos ci(38): add per-kata JSON output + artifact upload — AC1
```

Plus parent γ scaffold `83fd217 gamma@tsc.cdd.cnos`. **Convention: clean.**

## Findings

| Severity | Title | Surface | Evidence | Recommended action |
|---|---|---|---|---|
| C | Honest-claim count mismatch (14 vs 16) | `.cdd/unreleased/38/claims.md` line 33 | α claims "14 hits"; actual `grep -c` is 16 — undercount, not overcount; both above the ≥3 threshold | No fix required — could note in α R2 if cycle re-opens; otherwise close as cycle-iteration micro-finding |
| C | Workflow YAML not yet exercised by CI | `.github/workflows/katas.yml` | `cycle/38-impl` is a non-`main`/non-PR ref; the workflow's `push: branches: [main]` + `pull_request` triggers haven't fired yet | F2 step — γ verifies CI green on merge SHA before closing the cycle (already in self-coherence §CDD Trace step 7) |
| C (note) | AC3 oracle requires post-merge runtime trigger | published-binary job | Per the issue's "Success/closure condition," published-binary job needs ≥1 trigger (release / cron / dispatch); cron schedule fires Mon 06:00 UTC | Either fire `workflow_dispatch` post-merge or wait for first Mon-after-merge — γ's call at close-out |

**No A-severity findings. No B-severity findings.**

## Verdict

**APPROVED.**

Rationale: All five ACs verified. All four claims in the honest-claim manifest survive rule-3.13 scrutiny (reproducibility recipes ran, source-of-truth alignment held, wiring grep-verified). Contract integrity is clean — five files changed, all in the impact graph, no engine code touched. The AC4 Path B deviation is well-justified, pre-licensed by γ's scaffold and the issue body, and structurally correct. F1 self-application held. Forward-compat header updated to name the new job. The `tee` + `PIPESTATUS[0]` bash idiom for the engine's stdout-only kata JSON is correct. The only findings are three C-severity items, none of which compromise the cycle's claim.

Per §3.3: C-only → APPROVED.
