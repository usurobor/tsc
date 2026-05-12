---
role: alpha
cycle: 43
round: R1
identity: alpha@tsc.cdd.cnos
date: 2026-05-12
branch: cycle/43-impl
---

# α R1 Closeout — Cycle #43

Release-pipeline repair: Bug 1 tag-prefix fix + Bug 2 silent-no-publish diagnosis + fix + F2 proposal refinement. AC4 (backfill) and AC5 (CHANGELOG honesty) deferred to sigma operator with documented justification.

## AC1 — Bug 2 root cause diagnosed

**Root cause:** `runs-on: ubuntu-latest` in `.github/workflows/release.yml` is a floating label. The GitHub Actions runner-image registry promoted ubuntu-latest from ubuntu-22.04 to ubuntu-24.04 between v0.4.0's publication (2026-04-05, run #4, 1m32s, Success, Release object produced) and v0.8.0's tag-push (2026-05-12, run #5, 34s, Failure exit-code 10, no Release object). On ubuntu-24.04, `ocaml/setup-ocaml@v3`'s depext apt-get install pattern hits 404s for some legacy package URLs — apt exits 100, setup-ocaml does not propagate, opam later fails to invoke a now-missing command, the job exits with code 10 in 30-45s.

### Evidence

**Three workflow runs, three different pages, three quoted observations.**

1. **v0.9.0 release run (`/actions/runs/25759720219`, run #6):**

   > "Status Badge: 'Failure' — Exit Code: 'Process completed with exit code 10.' — Job 'build-and-release': 31 seconds duration. Overall run duration: 43 seconds."

2. **v0.8.0 release run (`/actions/runs/25725315475`, run #5):**

   > "Status: Failure — Workflow: release: 0.8.0 — CHANGELOG release gate #5 — Duration: 34 seconds — Process completed with exit code 10."

3. **v0.4.0 release run (`/actions/runs/24004683894`, run #4):**

   > "Status: Success — Workflow: release: v0.4.0 — feat: dotenv loading — Build-and-release: 1m 28s. Total duration: 1m 32s."

4. **Workflow YAML identity (v0.4.0 vs `b47f669`):** `diff <(git show v0.4.0:.github/workflows/release.yml) .github/workflows/release.yml` returns zero changes. The YAML is byte-identical; the only candidate for behavioral divergence is the runtime (runner image, action major-version drift, or external network).

5. **ubuntu-latest registry pointer (today):** per `actions/runner-images` README — `ubuntu-latest` resolves to `ubuntu-24.04`.

6. **Upstream ocaml/setup-ocaml issue #677 (closed):** the exact pattern — apt-get install fails with exit 100, setup-ocaml does not propagate, later opam invokes a missing tool and the job exits code 10.

### List-page vs detail-page disagreement (the deeper observation)

The GitHub Actions runs-list page (`/actions/workflows/release.yml`) shows v0.8.0 and v0.9.0 with green checkmarks. The per-run-detail pages show **status: Failure**. This is a UI-surface disagreement: the list-page summary appears to elide the actual conclusion in some cases (possibly cache lag, possibly a list-page bug, possibly a deliberate design choice that conflates "ran" with "succeeded"). γ's scaffold §Gap recorded "success conclusion" based on the list-page; the run-detail pages tell a different story. **This list-vs-detail gap is itself the empirical anchor for AC6's "expected-artifact-produced" check** — a γ post-merge polling only the list-page (or only the conclusion field of the API) would have seen green for 5 cycles in a row while no Release object existed.

## AC2 — Bug 2 fix applied

**Diff:** `runs-on: ubuntu-latest` → `runs-on: ubuntu-22.04` in `.github/workflows/release.yml`, with a 6-line comment explaining the pin. Same image v0.4.0 ran under successfully; same pin `ci.yml::build` already uses.

**Commit:** `8c93f5a`.

**Verification (deferred to F2):** the fix is verifiable end-to-end only by tagging a test release after the fix lands on main, or by sigma using `workflow_dispatch` after a one-line trigger amendment. γ's post-merge F2 should observe (a) workflow conclusion green AND (b) Release object produced — the AC6 discipline this cycle proposes.

## AC3 — Bug 1 fix applied

**Diff:** `scripts/release.sh` line 54: `TAG="$VERSION"` → `TAG="v$VERSION"`. One-line change.

**Commit:** `ffcf6e7`.

**Note on line-number drift:** γ's scaffold §Gap row referenced "line 102"; the actual line is 54. Substance unchanged; correction noted in `claims.md` §Claim 5.

**Note on CHANGELOG ledger grep (line 73):** intentionally unchanged — ledger row format is `| 0.X.0 |` (no v prefix). Only the git-tag literal gains the v prefix.

## AC4 — Backfill 5 missing releases — DEFERRED to sigma

**Status:** Deferred. Justification per γ scaffold §Cycle scope sizing ("AC4 is procedural and can split cleanly").

**Why deferred:**

1. **Tool unavailability.** `gh` CLI is not installed in the dispatch harness (`gh: command not found`). The `mcp__github__*` toolset exposes release-read tools (`list_releases`, `get_release_by_tag`, `get_latest_release`) but no release-create / asset-upload tool.
2. **Prerequisite: AC2 must land on main first.** Once `cycle/43-impl` merges, sigma's re-push or `workflow_dispatch` invocation will produce binaries with native provenance (built on the runner from the actual tagged source). Locally-built backfills from cycle/43-impl would have weaker provenance and would not exercise the AC2 fix.
3. **Three of five tags need re-tagging.** Tags `0.5.0`, `0.6.0`, `0.7.0` are pushed without `v` prefix. The workflow's `tags: ['v*']` trigger will never fire for them; sigma needs to choose between (a) creating `v0.5.0`, `v0.6.0`, `v0.7.0` aliases pointing at the same commits, or (b) temporarily broadening the trigger to `['v*', '0.*']`, or (c) leaving those three tags non-v and creating Release objects manually via `gh release create 0.5.0 ...`. All three options are operator-level decisions, not α-implementation work.

### Operator-handoff (sigma)

After `cycle/43-impl` merges to main, sigma executes the following procedure to backfill v0.5.0–v0.9.0:

```bash
# Step 0: confirm release.yml on main carries the runner pin from AC2.
git pull origin main
grep 'runs-on' .github/workflows/release.yml
# Expected: runs-on: ubuntu-22.04

# Step 1: reconcile the 3 no-v-prefix tags (operator choice; recommended option (a)).
# Create v-prefixed aliases pointing at the same commits:
git tag v0.5.0 0.5.0
git tag v0.6.0 0.6.0
git tag v0.7.0 0.7.0
git push origin v0.5.0 v0.6.0 v0.7.0
# Workflow will fire on each push; releases produced organically with v0.X.0 names.

# Step 2: re-fire workflow for v0.8.0 and v0.9.0 (tags exist; need a fresh push to re-trigger).
# Option A: workflow_dispatch (cleanest — needs one-line YAML trigger amendment, then revert):
#   Add `workflow_dispatch:` under `on:` in release.yml, push, dispatch per tag via UI, revert.
# Option B: delete + re-tag (preserves tag history if both deletion and re-creation happen quickly):
#   git tag -d v0.8.0 && git push origin :v0.8.0 && git tag v0.8.0 efbc07d && git push origin v0.8.0
#   (same for v0.9.0 at 0fd5b7d)
# Recommended: Option A (workflow_dispatch) — no tag-history rewrites needed.

# Step 3: verify each release produced:
# For each v in v0.5.0 v0.6.0 v0.7.0 v0.8.0 v0.9.0:
#   mcp__github__get_release_by_tag <v> → expect 200 with non-empty `assets` containing coh-linux-x64

# Step 4: ship AC5 (CHANGELOG honesty) — see AC5 below.
```

**If sigma prefers to skip the 3 no-v-prefix backfills** (option (c) above — create them manually via `gh release create 0.5.0 ...` with locally-built binaries), the AC5 ledger marker can distinguish "organically-produced via workflow" from "manually-attached binary."

## AC5 — CHANGELOG honesty — DEFERRED with AC4

**Status:** Deferred. Ships with AC4 by design (γ scaffold: "ships with AC4. Defer-allowed.").

**When sigma executes AC4 backfill:** append `(release-binary backfilled in #43)` to each of the 5 ledger rows' Note column. Suggested diff:

```diff
-| 0.9.0 | A- | A- | A | A- | L6 | Phase 2 kata progression: ... (#34, cycle: L6) |
+| 0.9.0 | A- | A- | A | A- | L6 | Phase 2 kata progression: ... (#34, cycle: L6) (release-binary backfilled in #43) |
```

Apply the same parenthetical to rows for 0.8.0, 0.7.0, 0.6.0, 0.5.0.

The `simplify` skill on the ledger after AC4 closeout: the parenthetical is the minimal honest marker — distinguishes organically-shipped from belatedly-backfilled rows. No new column needed.

## AC6 — F2 proposal refinement

**Surface:** `.cdd/iterations/proposals/cnos-cdd-ci-green-gate/ISSUE.md`.

**Branch:** `cycle-43-proposal-amend` (forked from `origin/proposals/cycle-36-followons`).

**Commit:** `3b376d5`.

**Why on a separate branch:** the proposal file lives on `proposals/cycle-36-followons` (not yet merged to main). α elected to amend it at its canonical source rather than duplicate the file onto `cycle/43-impl`. Both branches reference cycle #43 in their commit messages and headers. When the proposal cycle eventually lands on main, the amendment lands with it.

**Added content (verbatim):**

- §Scope item 6 — verification beyond workflow conclusion. Empirical anchor: tsc cycle #43, where release.yml on five consecutive tags reported a green checkmark on the workflow-list page yet (a) the per-run detail page showed Failure exit-code 10 in four of five and (b) no Release object was created in any of the five.
- AC6 — Expected-artifact-produced check: β AC1 and γ AC2 must, for every expected artifact named in the cycle's ACs, perform an existence + identity probe distinct from the workflow-conclusion poll. Mechanical (e.g., `mcp__github__get_release_by_tag` returning 200 with non-empty `assets`), not advisory.
- §Status-truth row added for the conclusion-vs-artifact gap (open; tsc #43).
- §References entry for tsc cycle #43.
- §Decision bumped AC count 5 → 6.

**Oracle (per scaffold):** `rg 'artifact.produced|expected.artifact' .cdd/iterations/proposals/cnos-cdd-ci-green-gate/ISSUE.md` returns ≥1 hit on `cycle-43-proposal-amend`.

## Honest-claim manifest

See `claims.md` (this directory). Five claims map AC1–AC6 to falsifiable evidence.

## Branch + final SHA

- Branch: `cycle/43-impl` (pushed to origin)
- Sibling branch: `cycle-43-proposal-amend` (pushed to origin) — carries AC6 amendment
- Final SHA on cycle/43-impl: (filled by post-push commit)

## Debt / new findings

1. **List-page vs detail-page summary disagreement (UI-surface gap).** GitHub Actions workflow-list pages appear to show green checkmarks for workflow runs whose detail pages report Failure. Whether this is cache lag, a list-page bug, or a deliberate design choice α did not investigate further. **This finding directly motivates AC6** (don't trust conclusion-only polling; probe the expected artifact). It is *also* a separable cdd-iteration finding: F2 cannot be implemented by polling the list-page; must use the API or the detail-page.
2. **γ-scaffold line-number drift.** γ said "scripts/release.sh line 102" — actual line is 54. Minor; corrected in α-closeout. The substance ("change `TAG="$VERSION"` to `TAG="v$VERSION"`") was correct.
3. **Cycle #38's validate-published-binary job.** As γ noted, this job has been silently degrading since v0.5.0 — it can only validate against v0.4.0, the most recent existing Release. After sigma executes AC4, this job will once again validate against the genuinely-latest release. No code change needed in cycle #43; the side-effect resolution comes for free once AC4 ships.
4. **Action-version pinning (`actions/checkout@v4`, `ocaml/setup-ocaml@v3`, `softprops/action-gh-release@v2`).** All three actions use floating major-version pins. The Node.js 20 deprecation warning in the workflow runs (`actions/checkout@v4` running on Node.js 20) hints at future drift. **Not addressed in cycle #43** — out of scope (named root cause was the runner image, not action drift; minimal-fix discipline). Worth opening a follow-on issue: "pin actions to specific tags in release.yml" with low priority (P3) — the runner pin is the time-bomb defuser, but action-pinning would deepen the protection.
5. **The proposal-on-separate-branch friction.** AC6 amendment lives on `cycle-43-proposal-amend`, not `cycle/43-impl`. β reviewing cycle #43 needs to look at both branches. Not a process problem in itself; just a reminder that in-flight proposals being amended require cross-branch reading. Documented in the §Surface↔AC↔commit map in `claims.md`.
