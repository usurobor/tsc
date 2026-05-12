---
role: alpha
cycle: 43
round: R1
identity: alpha@tsc.cdd.cnos
date: 2026-05-12
---

# α R1 Honest-Claim Manifest — Cycle #43

Per γ scaffold §Honest-claim manifest. Each claim names its surface, asserts a falsifiable invariant, and points to the evidence that supports it.

## Claim 1 — Reproducibility (AC1, root cause)

**Surface:** Bug 2 root cause analysis.

**Claim:** Another engineer reading the v0.9.0 and v0.8.0 release.yml run-detail pages alongside the v0.4.0 page can reach the same root-cause conclusion that α did, by observing four converging facts:

1. **Run-list page vs run-detail page disagree.** The runs-list page (`/actions/workflows/release.yml`) shows green checkmarks for v0.8.0 and v0.9.0. The per-run-detail pages (`/actions/runs/25725315475` for v0.8.0 and `/actions/runs/25759720219` for v0.9.0) show **status: Failure** with annotation `"Process completed with exit code 10."` and duration 34s / 31s respectively (with overall run duration 34s / 43s).
2. **The v0.4.0 run-detail page** (`/actions/runs/24004683894`) shows **status: Success** with duration 1m32s.
3. **The workflow YAML is byte-identical** between v0.4.0 and v0.9.0 (verified via `git show v0.4.0:.github/workflows/release.yml` diff against `.github/workflows/release.yml` on `b47f669`).
4. **`runs-on: ubuntu-latest`** in release.yml is a floating label. The GitHub Actions runner-image registry promoted ubuntu-latest from ubuntu-22.04 to ubuntu-24.04 between v0.4.0's publication (2026-04-05) and v0.8.0's tag-push (2026-05-12). On ubuntu-24.04, `ocaml/setup-ocaml@v3`'s depext apt-get install pattern hits 404s for legacy package URLs (cf. `ocaml/setup-ocaml#677` — apt exits 100, setup-ocaml does not propagate, opam later fails to invoke a missing tool, exit code 10).

The 34s / 43s durations are far shorter than the ~1m20s+ a real OCaml build needs — consistent with early-stage failure in the opam-install phase, not late-stage failure in the release-creation step.

**Evidence quoted:**

- WebFetch of `/actions/runs/25759720219`: `"Status Badge: 'Failure'" — "Exit Code: 'Process completed with exit code 10.'"`
- WebFetch of `/actions/runs/25725315475`: `"Status: Failure" — "Process completed with exit code 10." — "Duration: 34 seconds"`
- WebFetch of `/actions/runs/24004683894`: `"Status: Success" — "Duration: 1m 32s"`
- ocaml/setup-ocaml issue #677 (closed): `"[ERROR] System package install failed with exit code 100" → "[ERROR] Command not found: curl-config" (exit code 10)`

**Falsifiability:** if another engineer reading the same three run-detail pages observes status=Success on v0.8.0/v0.9.0 (contra α's reading), or observes exit-code other than 10, this claim is falsified.

## Claim 2 — Wiring (AC2, fix demonstrably addresses root cause)

**Surface:** `.github/workflows/release.yml` diff vs main.

**Claim:** Changing `runs-on: ubuntu-latest` to `runs-on: ubuntu-22.04` demonstrably addresses the named root cause. Pre-fix: floating label resolves to ubuntu-24.04 today and ocaml/setup-ocaml depext fails. Post-fix: pinned label resolves to ubuntu-22.04 — the same image v0.4.0 ran under successfully (1m32s, full build, Release object produced) — and is the same pin `ci.yml::build` has used continuously without drift.

**Pre-fix vs post-fix step-output reasoning:** at the `Set up OCaml` step, `ocaml/setup-ocaml@v3` invokes its depext logic which runs `sudo apt-get update && sudo apt-get install <system-deps-for-engine>`. On ubuntu-24.04 some package URLs return 404 (issue #677). On ubuntu-22.04 those URLs are still valid (v0.4.0's 1m32s green is the witness). With the runner pinned to 22.04, the depext install succeeds, opam install proceeds, `dune build` runs, `softprops/action-gh-release@v2` is reached, and a Release object is produced.

**No unrelated changes:** the diff is one `runs-on:` line + 6 lines of comment explaining the pin. No action versions changed, no compiler version changed, no step added/removed, no permission block touched.

**Falsifiability:** if sigma re-pushes v0.9.0 (after this fix lands on main) and the workflow on ubuntu-22.04 still fails with exit code 10, this claim is falsified — root cause is elsewhere.

## Claim 3 — Source-of-truth (AC3, header comment + behavior agree)

**Surface:** `scripts/release.sh`.

**Claim:** Post-fix, the script's header comment (line 13: `"Tag (v-prefixed)"`) and behavior (line 54: `TAG="v$VERSION"`) agree. Pre-fix, the comment claimed v-prefix and the code dropped the v.

**Evidence:**
- `grep -n 'TAG=' scripts/release.sh` returns `54:TAG="v$VERSION"` (post-fix).
- `grep -n 'v-prefixed' scripts/release.sh` returns `13:#   6. Tag (v-prefixed) + push tag`.
- The CHANGELOG ledger row grep at line 73 (`grep -q "^| $VERSION |"`) is intentionally unchanged — ledger row format is `| 0.X.0 |` (no v prefix), confirmed by `grep -n '^| 0\.' CHANGELOG.md`.

**Falsifiability:** if a future release.sh invocation with `$VERSION="0.10.0"` produces a tag named `0.10.0` (no v), this claim is falsified.

## Claim 4 — Reproducibility (AC4, backfills — deferred)

**Surface:** GitHub Releases.

**Claim:** AC4 (backfill 5 missing releases for v0.5.0–v0.9.0) is **deferred to sigma operator** rather than executed by α R1. Reasoning:

1. **No release-creation tool available in the dispatch harness.** `gh` CLI is not installed (`command not found`). `mcp__github__*` exposes `list_releases`, `get_release_by_tag`, `get_latest_release` (read-only) but no `create_release` / `upload_asset`. There is no `mcp__github__create_or_update_file`-equivalent for release objects.
2. **Building 5 historical binaries locally in this harness is unwarranted** when (a) AC2's runner-pin fix makes the workflow path organically operable once it lands on main, (b) sigma can re-push tags or use `workflow_dispatch` (after a one-line trigger-amendment) to produce binaries with native provenance (built on the actual runner from the actual tagged source), and (c) older tags (v0.5.0–v0.7.0) without v-prefix would need to be re-tagged with v-prefix first — also an operator action.
3. **The backfill mechanism named in γ's scaffold** (`gh release create <tag> coh-linux-x64 --notes ...` per-tag, with locally-built binary) is exactly what sigma will execute once AC2 lands and the no-v-prefix tags are reconciled. α's contribution is the *unblocker* (AC2 + AC3); sigma executes the procedural follow-on.

**This deferral is the strong-justification path** named in γ's scaffold §Cycle scope sizing — "α may defer backfills (AC4) to a follow-on cycle if Bug 2 diagnosis turns out non-trivial. AC4 is procedural and can split cleanly." Bug 2 diagnosis required reconciling a WebFetch list-page/detail-page disagreement (the runs-list shows green; the run-detail shows Failure) and tracing the conclusion-vs-artifact gap that motivates AC6 itself — non-trivial work that justifies the AC4 defer.

**Operator-handoff for sigma documented in `alpha-closeout.md` §AC4 Operator-handoff.**

**Falsifiability:** if `gh release create` from this harness would have succeeded (i.e., `gh` were installed and authenticated), this defer is suboptimal. α verified `gh: command not found` directly.

## Claim 5 — No false negation (γ-side; α confirms)

**Surface:** γ's §Gap on `b47f669`.

**Claim:** γ's peer-enumeration table in `.cdd/unreleased/43/self-coherence.md` is verifiable on pre-cycle main `b47f669`. α confirms by independent observation:

- `git show v0.4.0:.github/workflows/release.yml` byte-matches current `.github/workflows/release.yml` — γ's claim "release.yml unchanged since v0.4.0" verified.
- `git tag -l | grep -E '^v?0\.[5-9]\.0'` shows tags `0.5.0`, `0.6.0`, `0.7.0`, `v0.8.0`, `v0.9.0` — γ's bug-1 affected set (no v: 0.5.0–0.7.0) and bug-2 affected set (with v: v0.8.0, v0.9.0) verified.
- `mcp__github__list_releases` returns 5 entries (v0.4.0, v0.3.1, v0.3.0, 0.1.1, 0.1.0) — γ's "missing 5 releases" verified.
- `scripts/release.sh` line 54 reads `TAG="$VERSION"` on `b47f669` — γ's bug-1 surface verified (note: γ's scaffold said "line 102" but the actual line is 54; γ-side documentation drift, not a substantive false claim).

**Adjustment surfaced:** γ's scaffold §Gap row "release.yml runs that didn't publish — v0.8.0 (34s), v0.9.0 (43s) — success conclusion" — α's evidence shows these are Failure-conclusion at the run-detail surface (Success only at the runs-list summary surface, which is the false-positive class AC6 names). γ's "success conclusion" statement traces to the list-page summary; the deeper truth (detail-page Failure) reframes Bug 2 from "silent no-publish under green workflow" to "Failure-with-misleading-green-summary." The root cause is unchanged (ubuntu-latest drift); the verification gap (list-vs-detail surface disagreement) is itself part of why F2 missed it for 5 cycles.

**Falsifiability:** if any of γ's §Gap-table rows is non-reproducible on `b47f669`, this claim is falsified. α verified each.

## Surface ↔ AC ↔ commit map

| AC | Surface | Commit |
|---|---|---|
| AC1 | `alpha-closeout.md` §AC1 + this manifest §Claim 1 | (in `closeout(43)` commit) |
| AC2 | `.github/workflows/release.yml` | `8c93f5a` |
| AC3 | `scripts/release.sh` | `ffcf6e7` |
| AC4 | deferred to sigma (operator-handoff in α-closeout) | n/a |
| AC5 | ships with AC4 (deferred) | n/a |
| AC6 | `.cdd/iterations/proposals/cnos-cdd-ci-green-gate/ISSUE.md` (on branch `cycle-43-proposal-amend`, commit `3b376d5`) | `3b376d5` (sibling branch) |
