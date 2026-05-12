---
cycle: 43
issue: "#43"
branch: "cycle/43"
mode: "design-and-build"
disconnect: "engine release path — if AC2 fix is non-trivial, may bump VERSION 0.9.0 → 0.9.1 (patch release). If AC2 is a workflow-config-only fix with no engine semantics change, §2.5b docs-only is acceptable. γ-at-α-completion decides based on actual fix size."
date: "2026-05-12"
dispatch_configuration: "§5.2 single-session δ-as-γ via Claude Code Agent tool. γ axis grade capped at A− per §3.8 amendment."
self_application: "Dogfoods cycle #36 follow-on patches: F1 (peer-enumeration before scaffold — see §Gap), F2 (CI green AND artifact-produced verification on merge SHA; this cycle refines F2 itself), F3 (parent-session quiescence)."
---

# Self-Coherence — Cycle #43

## Gap (peer-enumerated per F1 discipline)

Peer-enumeration of release pipeline on main `b47f669` (run before authoring this §Gap):

| Surface | State | Notes |
|---|---|---|
| `.github/workflows/release.yml` triggers | `on: push: tags: ['v*']` | Requires `v` prefix to match |
| `scripts/release.sh` line 102 | `TAG="$VERSION"` (no `v` prefix) | **Bug — header comment claims "Tag (v-prefixed)" but code drops the v.** |
| Origin tags WITHOUT `v` prefix | `0.5.0`, `0.6.0`, `0.7.0` | Workflow never triggered for these (pattern mismatch) |
| Origin tags WITH `v` prefix | `v0.3.0`, `v0.3.1`, `v0.4.0`, `v0.8.0`, `v0.9.0` | Workflow triggered |
| release.yml runs that **published** releases | v0.3.0 (1m17s), v0.3.0 (1m19s), v0.3.1 (1m20s), v0.4.0 (1m32s) | All ≥1m+ duration |
| release.yml runs that **didn't publish** | v0.8.0 (34s), v0.9.0 (43s) | All <1m; **root cause TBD; needs log inspection** |
| Published GitHub Releases | v0.4.0, v0.3.1, v0.3.0, 0.1.1, 0.1.0 | Latest user-installable = v0.4.0 (April 5) |
| Missing Releases | v0.5.0, v0.6.0, v0.7.0, v0.8.0, v0.9.0 | Five releases need backfill |
| `release.yml` `runs-on:` | `ubuntu-latest` | Likely ubuntu-24.04 today; was ubuntu-22.04 when v0.4.0 shipped (April) — possible runner-image divergence |
| `ci.yml::build` (for comparison) | `runs-on: ubuntu-22.04` (pinned) | Pinned, hasn't drifted |
| `proposals/cnos-cdd-ci-green-gate/ISSUE.md` (F2 proposal) | Checks "workflow conclusion = success" only | **Insufficient — this cycle exposes the false-positive class.** |
| Cycle #38 `validate-published-binary` job | Downloads "latest release" for kata-validation | **Silently degraded since v0.5.0 — only sees v0.4.0** |
| Empirical anchor for cycle gap | Cycle #34 γ close-out F2-part-B deferred to sigma → sigma tagged → workflow Success → no Release object exists | Recorded in `.cdd/releases/0.9.0/34/cdd-iteration.md` F1 |

**Gap reality (informed by enumeration):**

1. **Two distinct bugs share the same impact** (missing releases for 0.5.0+).
2. **Bug 1 (tag-prefix drift):** `scripts/release.sh` line 102 sets `TAG="$VERSION"` — should be `TAG="v$VERSION"` per the script's own header comment ("Tag (v-prefixed)"). Affects 0.5.0/0.6.0/0.7.0 — those tags exist on origin without `v` prefix; release.yml's `tags: ['v*']` trigger never fires for them.
3. **Bug 2 (workflow silent-no-publish):** v0.8.0 and v0.9.0 DO have `v` prefix and DO trigger release.yml, but the workflow completes in 34s / 43s respectively (vs v0.4.0's 1m32s) without producing a Release object. Root cause TBD — needs log inspection. Likely candidates: ubuntu-latest runner-image drift, opam install behavior change, `softprops/action-gh-release@v2` permissions or version-pin issue.
4. **Five releases need backfill:** v0.5.0–v0.9.0. Existing tags + CHANGELOG content + RELEASE.md files supply the metadata; the binaries need to be built (from current sources or per-tag) and attached.
5. **Cdd F2 rule needs refinement.** Cycle #36's F2 proposal (`proposals/cnos-cdd-ci-green-gate/`) checks workflow conclusion only. This cycle exposes the false-positive class: workflow succeeds, expected artifact (Release object) is not produced, F2 currently considers this verified-green. F2 needs an "expected-artifact-produced" check beyond the conclusion field.

## Mode

`design-and-build`. Design surfaces:

- **Bug 2 root cause** — read actual v0.9.0 workflow logs, compare to v0.4.0 logs, identify divergence. May require non-trivial investigation.
- **Backfill mechanism** — `gh release create` per tag with binary built from current sources (best-effort match to historical binary) vs re-triggering workflow per tag (requires temporary `workflow_dispatch` trigger). γ recommends `gh release create` — simpler, doesn't require workflow modification.
- **F2 refinement scope** — minimal amendment to in-flight proposal: one new bullet adding "expected-artifact-produced" verification.

Not MCA — design fits in this scaffold.

## Cycle scope sizing (per cnos §1.6c heuristic)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | One-line fix to scripts/release.sh + possibly small release.yml fix + 5 release-create operations + 1 proposal-amendment | moderate |
| (b) Cross-module breadth | `scripts/release.sh` + `.github/workflows/release.yml` (maybe) + GitHub Releases UI (5 backfills) + `CHANGELOG.md` (5 row updates) + `proposals/cnos-cdd-ci-green-gate/` | moderate |
| (c) Lifecycle span | investigate → fix → backfill → verify → proposal refinement | moderate-long |
| (d) MCA preconditions | not MCA — design fixed | n/a |
| (e) Independent shippability | Bug 1 fix, Bug 2 fix, backfills, F2 refinement — all shippable independently. Backfills depend on Bug 2 being fixed. | YES (split signal) |

**Decision: keep whole BUT allow split.** **6 ACs**, upper-typical band. γ allows α to defer backfills (AC4) to a follow-on cycle if Bug 2 diagnosis turns out non-trivial. AC1+AC2+AC3+AC5+AC6 are tightly cohering; AC4 is procedural and can split cleanly.

**At-edge acknowledgment:** 6 ACs is upper-typical. β should grade scope realism — if α came back with all 6 done in a tight cycle, that's good. If α deferred AC4 with strong justification, that's also good. If α attempted AC4 but didn't complete it, that's a B-finding.

## Active Skills

**Tier 1a:**
- `cdd/CDD.md`, `cdd/SKILL.md`, `cdd/gamma/SKILL.md`

**Tier 1b:**
- `cdd/issue/SKILL.md`, `cdd/alpha/SKILL.md`, `cdd/beta/SKILL.md`
- `cdd/review/SKILL.md` (rule 3.13 + peer-enumeration)
- `cdd/release/SKILL.md` (release path discipline)
- `cdd/post-release/SKILL.md`

**Tier 2 (engineering, for α):**
- `cnos.eng/skills/eng/ci` (GitHub Actions debugging)
- `cnos.eng/skills/eng/release` (release pipeline conventions)

## Impact graph

```
scripts/release.sh                  FIX (line 102) — TAG="$VERSION" → TAG="v$VERSION"
.github/workflows/release.yml       INVESTIGATE; FIX if needed (probably runner-image pin or step debug)
GitHub Releases                     BACKFILL 5 releases (v0.5.0–v0.9.0) with built binaries
CHANGELOG.md                        UPDATE 5 ledger rows with "(release-binary backfilled in cycle #43)" parenthetical
.cdd/iterations/proposals/cnos-cdd-ci-green-gate/ISSUE.md
                                    AMEND with "expected-artifact-produced" check
.cdd/iterations/INDEX.md            APPEND cycle #43 row at close-out
```

## ACs

**AC1 — Bug 2 root cause diagnosed.** Workflow log of v0.9.0 release.yml run #6 read; divergence from v0.4.0 run #4 (last-working) identified; cause named with evidence quoted from logs.

- *Invariant:* root cause stated in `alpha-closeout.md` with log excerpts.
- *Oracle:* falsifiable claim — a reader could read the same logs and reach the same conclusion.
- *Surface:* `alpha-closeout.md`.

**AC2 — Bug 2 fix applied.** Minimal change to whatever surface (release.yml, repo settings, etc.) addresses the root cause; no unrelated changes.

- *Invariant:* diff is minimal and targeted; if the fix is "operator UI action only" (e.g., repository settings), this is documented in α-closeout with the exact UI path for sigma.
- *Oracle:* `git diff main` shows the workflow fix (if YAML-based) or close-out documents operator-handoff (if settings-based).
- *Surface:* `.github/workflows/release.yml` OR α-closeout §Operator-handoff.

**AC3 — Bug 1 fix applied.** `scripts/release.sh` line 102 changed from `TAG="$VERSION"` to `TAG="v$VERSION"`. Script header comment + behavior now agree.

- *Invariant:* one-line change; no other script modifications.
- *Oracle:* `grep -n 'TAG=' scripts/release.sh` shows `TAG="v$VERSION"`.
- *Surface:* `scripts/release.sh`.

**AC4 — Backfill 5 missing releases.** GitHub Release objects created for v0.5.0, v0.6.0, v0.7.0, v0.8.0, v0.9.0, each with a `coh-linux-x64` (or `coh-*`) binary asset.

- *Invariant:* `mcp__github__list_releases` returns 10 entries (5 prior + 5 backfilled).
- *Oracle:* `mcp__github__get_release_by_tag` for each backfilled version returns 200 with non-empty `assets`.
- *Surface:* GitHub Releases (operator action OR α via `gh release create`).
- **Defer-allowed:** if AC1+AC2 turn out non-trivial, α may defer AC4 to a follow-on cycle and document the deferral in α-closeout.

**AC5 — CHANGELOG honesty.** Each of the 5 backfilled ledger rows gains a parenthetical "(release-binary backfilled in #43)" or equivalent suffix in the Note column.

- *Invariant:* 5 rows updated; format consistent.
- *Oracle:* `grep -E '^\| 0\.[56789]\.0 \|' CHANGELOG.md` returns 5 rows each containing "backfilled" or similar marker.
- *Surface:* `CHANGELOG.md`.
- **Defer-allowed:** ships with AC4.

**AC6 — F2 proposal refinement.** `proposals/cnos-cdd-ci-green-gate/ISSUE.md` gains a bullet/clause adding "expected-artifact-produced" verification beyond workflow-conclusion check.

- *Invariant:* one new clause; references this cycle (#43) as the empirical anchor.
- *Oracle:* `rg 'artifact.produced|expected.artifact' .cdd/iterations/proposals/cnos-cdd-ci-green-gate/ISSUE.md` returns ≥1 hit.
- *Surface:* the proposal file.

## Honest-claim manifest (R1 must produce)

α R1 must produce `claims.md` with:

1. **Reproducibility (AC1):** the root cause is named with sufficient detail that another engineer could read the same logs and confirm. Log excerpts (≤20 lines each) quoted with line refs to run-page URLs.
2. **Wiring (AC2):** the fix demonstrably addresses the named root cause. If YAML fix: pre-fix vs post-fix step output reasoning. If operator-handoff: exact UI path + permission setting documented.
3. **Source-of-truth (AC3):** `scripts/release.sh` header comment + line 102 now agree on v-prefix.
4. **Reproducibility (AC4):** if backfills shipped — for each tag, the binary was built from a known source point (named in α-closeout) and its `--version` output matches the tag.
5. **No false negation (γ-side):** §Gap claims verifiable on pre-cycle main `b47f669`.

## CDD Trace

1. **Receive** — γ peer-enumerated (F1) AND identified Bug 1 + Bug 2 BEFORE authoring §Gap.
2. **Dispatch α** — Agent tool, fresh context. α verifies γ's peer-enumeration, investigates Bug 2 (read actual logs), fixes both bugs, attempts backfill.
3. **α self-coherence + claims.md + readiness signal.**
4. **Dispatch β** — Agent tool, fresh context. β grades root-cause claim's defensibility, peer-enumerates the release surface, applies rule 3.13.
5. **Fix rounds if any.**
6. **Merge** — `cycle/43-impl` → main via PR.
7. **γ F2 verification (refined — see AC6 motivation):** verify BOTH (a) post-merge workflow conclusion green AND (b) expected artifact produced. For this cycle: verify the script fix passes `scripts/check-version-consistency.sh`; if AC2 shipped a release.yml change, verify by triggering on a test tag OR via `workflow_dispatch`. If AC4 shipped, verify 5 Release objects exist.
8. **γ close-out** — only after F2 confirms both conclusions.
9. **cdd-iteration** — capture F2-refinement self-application + any new findings.

## Dispatch configuration

- **Operator δ = γ** (single-session via Agent tool — §5.2)
- **Identities:** `{alpha,beta,gamma}@tsc.cdd.cnos`
- **γ axis grade cap:** A− (§5.2)

## Head SHA

(α R1 readiness signal fills this)
