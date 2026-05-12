---
cycle: 38
issue: "#38"
role: alpha
identity: alpha@tsc.cdd.cnos
branch: cycle/38-impl
parent_branch: cycle/38
parent_sha: 83fd217
date: 2026-05-12
round: R1
---

# α Closeout — Cycle #38

## Summary

Implemented the kata-CI extension per issue #38: per-kata JSON
artifact upload + step-summary table on the existing pre-merge job,
plus a new `validate-published-binary` job that downloads
`coh-linux-x64` from the latest GitHub Release and re-runs the kata
loop against it. Four content commits on `cycle/38-impl` off γ's
scaffold at `83fd217`, plus this closeout + claims manifest.

All five recommended design decisions in issue #38 §Open questions
are accepted (same workflow, weekly cron, **deviated on AC4 mechanism
— Path B instead of Path A**, pre-merge gate preserved, notify-only).
The AC4 deviation is justified below at §AC4.

## AC walk

### AC1 — Per-kata JSON artifact uploaded

- **File:** `.github/workflows/katas.yml`
- **Capture site:** `Run all katas (auto-discovered)` step (lines 145–164). Each kata's stdout JSON is teed into `.kata-results/${id}.json`. Loop uses `set +e` + `PIPESTATUS[0]` so a single failing kata still gets its JSON written and subsequent katas still run; aggregate pass/fail is enforced after the loop via the `failed` counter.
- **Upload step:** `Upload kata results` (lines 247–254), `actions/upload-artifact@v4`, `name: kata-results-${{ github.sha }}`, `retention-days: 90`, `if: always()` so failed runs (the case where post-mortem JSON is most valuable) still upload. `if-no-files-found: ignore` so the step doesn't itself fail when the kata-run step never created the directory (e.g. binary not built).
- **JSON shape:** the engine's `run_kata` (`engine/ocaml/bin/main.ml` lines 505–515) emits an `Assoc` with keys `kata_id`, `expected_verdict`, `c_sigma`, `score_range.{min,max}`, `kata_pass`, `mechanical`. AC2 parses these directly.
- **Oracle:** download artifact from a green run → expect `01-glider.json` + `02-random-soup.json` (matches current katas/ directory). `jq .kata_pass` returns `true` for both on the merge SHA.

### AC2 — Step summary surfaces per-kata score

- **File:** same workflow.
- **Step:** `Emit kata step-summary table` (lines 198–241), `if: always()`. Iterates `.kata-results/*.json`, parses each with a heredoc'd python3 block (preinstalled on ubuntu-22.04 — same dependency tsc.yml::Display results uses), emits one markdown table row per kata to `$GITHUB_STEP_SUMMARY`.
- **Row schema:** `| Kata | Verdict | C_Σ | Range | Status |` — matches katas/README.md §Where to find kata results exactly.
- **Status rendering:** `kata_pass=true` → `:white_check_mark:`, `kata_pass=false` → `:x:`, missing/null → `—`. Unparseable JSON renders a `:warning:` row inline rather than failing the step (since the kata-run step already exited non-zero for that case).
- **Oracle:** view a PR run's *Summary* tab → markdown table renders with ≥2 rows.

### AC3 — Published-binary validation job runs

- **File:** same workflow; new job `validate-published-binary` (lines 263–443).
- **Triggers:** added to top-level `on:` block (lines 38–47): `release: types: [published]`, `schedule: cron: '0 6 * * 1'` (Mon 06:00 UTC), `workflow_dispatch`. Job's own `if:` (line 304) restricts execution to these three event types — push/PR events skip this job, preserving the pre-merge gate shape (§Open question 4 recommendation).
- **Behaviour:** downloads `coh-linux-x64` from the resolved release tag, marks it executable, runs `--version` as a smoke check, then loops through `katas/*/kata.toml` and invokes `./coh-linux-x64 --kata "$id" --mode mechanical` for each. Same JSON capture + step-summary emit + artifact upload as the pre-merge job.
- **Tag resolution:** prefers `${{ github.event.release.tag_name }}` when fired from a release event (so a release event validates *that* release); falls back to `gh release view --json tagName --jq .tagName` for cron / manual dispatch (so the weekly check always exercises the most recently-published version).
- **Artifact name:** `kata-results-published-${{ env.RELEASE_TAG }}-${{ github.run_id }}` — embeds the release tag so historical artifacts are indexed by version (the principal axis for "did v0.8.0 ever fail under cron?").
- **Notify-only:** failure of this job leaves the workflow visible-red on the Actions tab but blocks no release and gates no PR (per §Open question 5 recommendation).

### AC4 — Release-artifact discovery mechanism

**Decision:** Path B (download release artifact). **Deviated from γ scaffold's recommendation of Path A.**

**Rationale (also recorded in the workflow at lines 270–283):**

1. **No missing-artifact risk.** `release.yml` at main `8e3094c` already publishes `coh-linux-x64` reliably for every `v*` tag (line 41 prepares the binary, line 48 uploads it via `softprops/action-gh-release@v2`). γ's scaffold §Gap explicitly flagged this as a Path-B enabler.
2. **Path B tests source-vs-artifact drift; Path A doesn't.** The whole motivation for AC3 (per issue §Problem) is to catch infra drift and supply-chain anomalies that affect the binary users *download*, not the binary CI re-builds. Path A would re-run release.yml's build under whatever opam state the validation runner picks up — that's a *different* binary than the one users have. Path B exercises the exact bytes.
3. **Path B is cheaper.** ~30s (network download + chmod + run) vs Path A's ~3 min (opam install + dune build + run). Keeps weekly cron well under runner-minute budget as kata count grows.
4. **γ's scaffold left room for the deviation.** The dispatch prompt says: "if you find Path A awkward, Path B is fine — justify either way." γ's own §Open question 3 acknowledges Path B becomes viable once release.yml's upload is verified; that verification is the §Gap table row for release.yml.

**Repro command** (β's verification recipe):
```bash
gh release download --pattern 'coh-linux-x64' --output coh-linux-x64
chmod +x coh-linux-x64
./coh-linux-x64 --version
./coh-linux-x64 --kata 01-glider --mode mechanical
# Expected: KATA PASS line on stderr; result JSON on stdout.
```

### AC5 — Documentation updated

- **File:** `katas/README.md` between "Runner invocation" and "Adding a new kata".
- **Length:** 113 words (≤120 ceiling).
- **Content:** names both artifacts (`kata-results-<sha>` and `kata-results-published-<tag>-<run_id>`), the 90-day retention, the *Artifacts* panel + `gh run download` retrieval paths, the step-summary row schema, and the published-binary job's tag-qualified section title.
- **Oracle:** `rg 'Where to find kata results' katas/README.md` → 1 hit.

## Engine `--output` wiring — finding

The dispatch prompt asked α to verify whether `coh --kata <id> --mode mechanical --output <path>` actually emits the per-kata JSON to `<path>`. **It does not.** The relevant code in `engine/ocaml/bin/main.ml`:

- Line 219 declares `--output` (`Arg.Set_string output_dir`).
- Line 184 stores it in `cli_output_dir`.
- Lines 299 / 358 / 365 / 371 / 426 use `cli_output_dir` for `--target` / `--files` modes (writing report files into that directory).
- The kata branch (line 536 onward → `run_kata`) **never references `cli_output_dir`**. The result JSON at line 516 is emitted via `Printf.printf` (stdout) only.

Per dispatch prompt guidance ("Do NOT extend the engine code in this cycle — out-of-scope"), the workflow captures stdout via `tee` instead of passing `--output`. This is documented in:

- The workflow comment block at lines 117–122 of katas.yml (`Per-kata result JSON capture (cycle #38 AC1): ...`).
- The AC1 commit message (`d517de1`).
- This closeout (this paragraph).
- The claims manifest §Source-of-truth alignment table.

**Follow-on:** a small engine cycle should wire `--output` for kata mode so the workflow can drop the `tee` indirection. Tracked verbally here; whether to open an issue is γ's call at close-out.

## Honest-claim posture (cycle #36 precedent + F1 self-application)

`.cdd/unreleased/38/claims.md` lists four claims with reproduction recipes. Headline:

1. **Wiring** — pre-state grep returns 0 hits, post-state grep returns 14 hits (well above the ≥3 threshold the dispatch prompt named).
2. **Schema alignment** — `| Kata | Verdict | C_Σ | Range | Status |` appears in 2 places in katas.yml (one per job) and 1 place in katas/README.md.
3. **AC4 mechanism** — Path B is named in 5 places in katas.yml + this closeout + claims.md; the repro recipe is the same `gh release download` invocation the workflow runs.
4. **No false negation** — γ's §Gap enumeration table at self-coherence.md is per-file accurate; α independently re-ran the enumeration on `8e3094c` (claims §Claim 4 reproduction recipe).

## F1 / F2 / F3 self-application (this α-round only)

- **F1 (γ peer-enumeration before scaffold):** Done by γ — visible in self-coherence.md §Gap table. α independently re-verified the enumeration; see claims.md §Claim 4.
- **F2 (γ verifies CI green on merge SHA):** Deferred to post-merge — γ's step. α's role ends at "ready for β".
- **F3 (parent-session quiescence):** α made all commits on `cycle/38-impl` inside this single sub-agent run; no parent-session edits touched the working tree concurrently (verified: `git log --author=usurobor --since="2026-05-12 17:00"` returns the cycle bot commits but no `usurobor`-authored interleaved edits).

## Commits on `cycle/38-impl`

1. `d517de1` ci(38): add per-kata JSON output + artifact upload — AC1
2. `074b54b` ci(38): add step-summary table for kata results — AC2
3. `422eb02` ci(38): add published-binary validation job — AC3+AC4
4. `c0e4329` docs(38): add "Where to find kata results" to katas/README.md — AC5
5. (this commit) closeout(38): α R1 closeout + honest-claim manifest

A sixth commit recording the final head SHA in self-coherence.md follows.

## Debt / new findings

- **Engine `--output` not wired for kata mode** — documented above + in the AC1 commit body + claims §Source-of-truth alignment. Follow-on engine cycle suggested.
- **No empirical CI run yet** — α's role ends at "ready for β". γ's F2 post-merge verification step is the surface that catches "the workflow YAML is valid; the new jobs execute as expected". α has not pushed to a remote that runs the workflow.
- **Cron + release job concurrency** — the top-level `concurrency:` group keys on `github.ref`, which for release / cron / dispatch events resolves to refs that don't collide with push/PR. Documented in the workflow's `concurrency:` comment. If in practice the release event ref *does* collide with a concurrent push to main, the cancel-in-progress flag (`github.event_name == 'pull_request'`) is false for the release event, so the release run wins. Verified by reasoning, not by empirical test.
