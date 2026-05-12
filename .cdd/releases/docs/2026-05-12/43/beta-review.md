---
role: beta
cycle: 43
round: R1
identity: beta@tsc.cdd.cnos
date: 2026-05-12
review_head: 006b185
parent_main: b47f669
gamma_scaffold: 87a9bd3
sibling_branch_head: 3b376d5
---

# β R1 Review — Cycle #43

Release-pipeline repair: Bug 1 tag-prefix + Bug 2 silent-no-publish + F2 proposal refinement (AC4/AC5 deferred to sigma).

## Verdict

**APPROVED.**

Severity breakdown: **0 A, 0 B, 5 C (advisory)**.

The two-line fix (release.yml runner pin + release.sh v-prefix) is minimal, targeted, and verifiably addresses the named bugs. AC1's root-cause statement is defensible — independently verified at the v0.4.0/v0.8.0/v0.9.0 run-detail pages and at the Releases API. The AC4/AC5 deferral is honest, not punted: gh-CLI absence and MCP create-release-tool absence both verified by β. The AC6 sibling-branch placement is appropriate given the proposal's canonical home is `proposals/cycle-36-followons`.

## Phase 1 — Contract integrity

α's diff matches γ's impact graph:

| γ impact-graph row | α delivery | β check |
|---|---|---|
| `scripts/release.sh` line 102 | `scripts/release.sh` line 54 (γ's line number wrong; substance unchanged) | OK; line-number drift is a γ-scaffold documentation drift, not a substantive miss (C-finding 1) |
| `.github/workflows/release.yml` INVESTIGATE; FIX if needed | runner pin `ubuntu-latest → ubuntu-22.04` + 6-line explanatory comment | OK; minimal targeted YAML fix |
| GitHub Releases BACKFILL 5 | deferred to sigma with operator-handoff procedure | OK; γ scaffold §Cycle-scope-sizing explicitly allows this deferral (line 62, 118) |
| CHANGELOG.md UPDATE 5 rows | deferred with AC4 (γ scaffold: "ships with AC4. Defer-allowed.") | OK |
| `.cdd/iterations/proposals/cnos-cdd-ci-green-gate/ISSUE.md` AMEND | amended on sibling branch `cycle-43-proposal-amend` at `3b376d5` | OK; β agrees with the rationale (proposal is on `proposals/cycle-36-followons`, not yet on main — amending at the canonical source is cleaner than duplicating onto cycle/43-impl) |
| `.cdd/iterations/INDEX.md` APPEND | deferred to γ close-out (per scaffold convention) | OK |

**Files touched on cycle/43-impl (5 total):**
- `.cdd/unreleased/43/alpha-closeout.md` (new)
- `.cdd/unreleased/43/claims.md` (new)
- `.cdd/unreleased/43/self-coherence.md` (extended with §Head SHA)
- `.github/workflows/release.yml` (+7 / -1)
- `scripts/release.sh` (+1 / -1)

No scope creep. Sibling branch `cycle-43-proposal-amend` carries a single, focused 14-insert/1-delete amendment to the proposal file. Acceptable pattern.

## Phase 2 — AC walk

### AC1 — Bug 2 root cause diagnosed — **PASS**

α names: `runs-on: ubuntu-latest` floated 22.04 → 24.04 between Apr 5 (v0.4.0 publication) and May 12 (v0.8.0/v0.9.0 tags) → `ocaml/setup-ocaml@v3` depext apt-get install hits 404s on 24.04 (ref ocaml/setup-ocaml#677) → apt exits 100, setup-ocaml doesn't propagate, opam fails downstream, job exits code 10 in 30–45s.

**β independent verification:**

| α evidence claim | β verification | Result |
|---|---|---|
| v0.9.0 run #6 — Failure, exit code 10, 31s job / 43s total | WebFetch of `/actions/runs/25759720219` — "Status: Failure", "Exit Code: Process completed with exit code 10", "31 seconds / 43 seconds total" | **Matches** |
| v0.8.0 run #5 — Failure, exit code 10, 29s job / 34s total | WebFetch of `/actions/runs/25725315475` — "Status: Failure", "Process completed with exit code 10", "29 seconds / 34 seconds total" | **Matches** |
| v0.4.0 run #4 — Success, 1m32s total | WebFetch of `/actions/runs/24004683894` — "Status: Success", "Duration: 1 minute 32 seconds" | **Matches** |
| Workflow YAML byte-identical between v0.4.0 and `b47f669` | `git show v0.4.0:.github/workflows/release.yml` vs current file — identical apart from line 9 (`ubuntu-latest` in both) | **Matches** |
| Released set on main = 5 entries (v0.4.0, v0.3.1, v0.3.0, 0.1.1, 0.1.0) | `mcp__github__list_releases` returns exactly those 5 entries | **Matches** |
| ubuntu-latest currently resolves to ubuntu-24.04 | Not directly verifiable from β tools; trusted via α's reference to `actions/runner-images` README | **External; trusted** |
| ocaml/setup-ocaml#677 — apt-100 → exit-10 pattern | Not fetched by β (would require WebFetch on github.com/ocaml/setup-ocaml/issues/677); however the **empirical** anchor (v0.4.0 on 22.04 worked, v0.9.0 on 24.04 didn't, YAML byte-identical) is sufficient to ground the root cause | **Empirically grounded even without #677** |

**Assessment:** **DEFENSIBLE.** The named root cause is supported by four converging facts that β verified independently: (a) workflow YAML byte-identical between known-working v0.4.0 and known-failing v0.9.0, (b) the only runtime variable that changed is the ubuntu-latest registry pointer (well-known external behavior), (c) the failure signature is consistent (30–45s, exit 10) across v0.8.0 and v0.9.0, ruling out transient infra issues, and (d) v0.4.0 was published Apr 5 and v0.8.0/v0.9.0 ran May 12 — straddling the ubuntu-24.04 promotion window. The ocaml/setup-ocaml#677 cite adds upstream specificity but the empirical claim stands without it. A skeptical reader could reach the same conclusion from the same evidence.

### AC1 — list-page vs detail-page UI inconsistency — **PARTIALLY VERIFIED**

α's "deeper observation" claim: the runs-list page (`/actions/workflows/release.yml`) shows v0.8.0 and v0.9.0 with green checkmarks while the per-run detail pages show Failure.

**β verification attempts:**

1. **Detail pages — Failure status:** unambiguous. Both runs show Status: Failure with exit code 10. **Verified.**
2. **List page — green checkmarks:** **partially verified.** β's WebFetch of the list page returned text consistent with the runs "appear successful" reading (the model's first pass said "appears successful" for v0.8.0 and v0.9.0), but on closer inspection the page returned "Uh oh! There was an error while loading" messages where status badges should render — β cannot definitively confirm the green-icon claim from HTML scraping alone. The first-pass reading is consistent with α's claim, but β notes that a more rigorous verification would use the GitHub Actions REST API to inspect the `conclusion` field directly.
3. **Releases-API:** 0 of 5 expected Releases (v0.5.0–v0.9.0) exist. **Verified** via `mcp__github__list_releases` (returns exactly 5 entries: v0.4.0, v0.3.1, v0.3.0, 0.1.1, 0.1.0). This is the **harder empirical anchor** for AC6 regardless of how the list page renders — even if the list page accurately shows red, the conclusion-vs-artifact gap (workflow exit 0 + no Release object) is the deeper false-positive class.

**β finding (C-2):** the list-page-vs-detail-page claim is presented with stronger confidence than β can independently corroborate. The more rigorous claim — "the GitHub Actions `conclusion=success` field can diverge from artifact-produced" — is fully supported by the Releases-API check alone. β recommends future references to this finding either (a) cite the API `conclusion` field rather than the list-page UI, or (b) include a verification step using the API. **Does not change AC6's scope or AC2's fix** — both are independently grounded.

### AC2 — Bug 2 fix applied — **PASS**

**Diff (β read directly):**

```
- runs-on: ubuntu-latest
+ # Pinned to ubuntu-22.04 — mirrors ci.yml and the runtime under which
+ # v0.4.0 last published successfully. The floating `ubuntu-latest`
+ # promoted to ubuntu-24.04 between April and May 2026, after which
+ # ocaml/setup-ocaml@v3's depext apt-get install hits 404s for legacy
+ # package URLs (issue ocaml/setup-ocaml#677) and the workflow fails at
+ # exit code 10 in 30–45s, well short of a real build. See cycle #43.
+ runs-on: ubuntu-22.04
```

Single `runs-on:` value change + 6 lines of explanatory comment. No other diff lines in the file. **Minimal and targeted.**

**Wiring (β check):** the fix is the exact runtime variable named in AC1. Pinning to 22.04 takes the runner image back to the runtime under which v0.4.0 ran for 1m32s with `conclusion=success` and a Release object. `ci.yml::build` line 10 already uses `ubuntu-22.04` — verified by β. The pin is consistent with the project's existing pinning posture and is the smallest possible change that addresses the root cause.

**Note on pinning vs tracking-latest debate:** the pin regresses to an older image, which some would argue is bad hygiene. β disagrees in this context: (a) ci.yml::build is already pinned to 22.04 — the release pipeline now mirrors it; (b) v0.4.0 (last successful release) ran on 22.04; (c) pinning is trivially reversible whereas the current bug shipped silently for 5 cycles. The pin is the correct localized fix; a separate cycle could explore upgrade-to-24.04-with-explicit-apt-config later. **No β finding** on this axis.

### AC3 — Bug 1 fix applied — **PASS**

**Diff (β read directly):**

```
- TAG="$VERSION"
+ TAG="v$VERSION"
```

One-line change at line 54. **β verified line 54** (γ scaffold said "line 102"; α corrected to 54; β confirms 54 is correct on the current file).

**Source-of-truth check (β):**
- `grep -n 'TAG=' scripts/release.sh` → `54:TAG="v$VERSION"`. ✓
- `grep -n 'v-prefix' scripts/release.sh` → `13:#   6. Tag (v-prefixed) + push tag`. Header comment and code now agree.
- Line 73's `grep -q "^| $VERSION |"` (CHANGELOG ledger grep) intentionally unchanged. β confirmed via `grep -n '^| 0\.' CHANGELOG.md` that ledger rows use `| 0.X.0 |` format (no v prefix) — α's reasoning is correct.

**No other changes** in release.sh. Minimal.

### AC4 — Backfill 5 releases — **DEFERRED (HONEST)**

α's four justifications:

1. **`gh` CLI absent.** β verified: `command -v gh` returns empty; `gh --version` errors "command not found". **True.**
2. **No MCP release-create tool.** β verified via ToolSearch: `mcp__github__list_releases`, `mcp__github__get_release_by_tag`, `mcp__github__get_latest_release` exist; no `mcp__github__create_release` or `mcp__github__upload_release_asset`. **True.**
3. **Prerequisite AC2 must land on main first** for native-provenance binaries. **Sound argument** — re-pushing tags after AC2 lands produces binaries built from the actual runner on the actual tagged source, whereas locally-built binaries from this harness would carry weaker provenance and would not exercise the AC2 fix.
4. **3 tags need re-tagging** (0.5.0, 0.6.0, 0.7.0 are pushed without v prefix) — operator decision among 3 options. β verified via `git ls-remote --tags origin` that these tags exist without v prefix. **True.**

**Assessment:** **HONEST, not punt.** All four justifications are empirically grounded. β notes that point #2 alone (no MCP create-release tool) is **sufficient** — α cannot create Release objects from the dispatch harness; the other three reasons add depth but the first one is dispositive.

α's operator-handoff procedure (§AC4 Operator-handoff in α-closeout.md) is well-structured: Step 0 (verify AC2 landed), Step 1 (reconcile no-v tags), Step 2 (re-fire workflow for v0.8.0/v0.9.0), Step 3 (verify), Step 4 (AC5). Sigma has actionable instructions.

**γ scaffold's §Cycle-scope-sizing line 64 explicit guidance:** "If α deferred AC4 with strong justification, that's also good. If α attempted AC4 but didn't complete it, that's a B-finding." β reads α's claim as "α did not attempt AC4 because the harness tools required are absent" — this is the strong-justification path, not a partial-attempt punt. **No B-finding.**

### AC5 — CHANGELOG honesty — **DEFERRED with AC4 (PASS)**

γ scaffold explicitly says AC5 "ships with AC4. Defer-allowed." α defers with AC4 and provides the suggested ledger-row diff in α-closeout §AC5. **PASS.**

### AC6 — F2 proposal refinement — **PASS (with one C-finding on prose precision)**

**β read sibling branch:** `git show origin/cycle-43-proposal-amend:.cdd/iterations/proposals/cnos-cdd-ci-green-gate/ISSUE.md` and `git diff origin/proposals/cycle-36-followons origin/cycle-43-proposal-amend -- <ISSUE.md>`.

The amendment adds:
1. **§Status-truth table row** — "Empirical anchor (conclusion-vs-artifact gap) | tsc cycle #43 | Open — release.yml reported green on the workflow-list page for v0.5.0–v0.9.0 yet produced no Release object in any of the five cases". ✓
2. **§Decision** — "5 ACs" → "6 ACs, mid-typical band (was 5 pre-tsc-#43 refinement; tsc cycle #43 added AC6 'expected-artifact-produced')". ✓
3. **§Scope item 6** — "Verification beyond workflow conclusion" with empirical anchor + mechanical-not-advisory framing. ✓
4. **AC6 block** — full AC6 clause with invariant, oracle (`rg 'expected.artifact|artifact.produced'` returns ≥1 hit), empirical-anchor, positive/negative cases, and surface. ✓
5. **§References entry** — "tsc cycle #43 — empirical anchor for AC6 (workflow-list page green vs detail-page Failure + no Release object across v0.5.0–v0.9.0)". ✓

**Required clauses from γ scaffold AC6 invariant** ("one new clause; references this cycle (#43) as the empirical anchor"):
- (a) names artifact-existence check beyond conclusion — **YES**, explicitly: "existence + identity probe distinct from the workflow-conclusion poll" + concrete probe call (`mcp__github__get_release_by_tag` returning 200 + non-empty `assets`).
- (b) cites cycle #43 as empirical anchor — **YES**, in §Status-truth row, §Scope item 6, AC6 block, and §References.
- (c) consistent with existing proposal tone/format — **YES**, mirrors existing AC blocks (Invariant / Oracle / Empirical anchor / Positive / Negative / Surface).

Oracle check: `rg 'artifact.produced|expected.artifact'` against the amended ISSUE.md returns multiple hits. ✓

**β finding (C-3):** the prose says "release.yml on five consecutive tags reported a green checkmark on the workflow-list page yet (a) the per-run detail page actually showed Failure exit-code 10 in four of five and (b) no Release object was created in any of the five cases." This conflates Bug 1 (no workflow run at all for 0.5.0/0.6.0/0.7.0 because of the missing v prefix) with Bug 2 (workflow ran but failed silently for v0.8.0/v0.9.0). Only 2 of the 5 tags actually triggered workflow runs at all. The "green checkmark on the workflow-list page" claim is well-formed only for the 2 runs that did execute (v0.8.0 and v0.9.0). For the 3 no-v-prefix tags (0.5.0, 0.6.0, 0.7.0), no workflow ran and no list-page entry exists. The commit-message version correctly says "four of five" (recognizing only 2 of 5 actually triggered, with 2 of those failing); the prose body is imprecise. **C-severity** because the underlying claim (conclusion-vs-artifact gap is real for v0.8.0 and v0.9.0) is true and AC6's scope (artifact-existence beyond conclusion) is correctly motivated; the count-collation in the body is a clarity issue, not a soundness issue. **Recommendation:** before this proposal is merged (separate cycle), refine the prose to distinguish "2 of 5 ran-and-failed-silently (Bug 2)" from "3 of 5 never ran (Bug 1)". Both classes motivate F2-refinement, but the conclusion-vs-artifact false-positive specifically attaches to Bug 2.

## Phase 3 — rule 3.13 honest-claim verification

Walk through α's `claims.md`:

| Claim | Surface | Falsifiable? | β verdict |
|---|---|---|---|
| 1 — AC1 root cause | run-detail pages + YAML diff + ubuntu-latest pointer | YES — "if reading the same logs reaches different conclusion or different exit code, falsified" | **Verified** against all three run pages |
| 2 — AC2 fix wires to root cause | release.yml diff | YES — "if sigma re-pushes v0.9.0 on 22.04 and it still fails exit-10, root cause is elsewhere" | **Sound; pending end-to-end witness from sigma** |
| 3 — AC3 source-of-truth | release.sh diff + header comment + ledger format | YES — "if release.sh produces tag `0.10.0` (no v), falsified" | **Verified** by grep |
| 4 — AC4 deferral | tool-availability claim | YES — "if `gh` CLI is installed/authenticated in this harness, defer is suboptimal" | **Verified** (`gh: command not found`); MCP create-release also absent |
| 5 — γ §Gap verifiable on `b47f669` | γ scaffold | YES — "if any §Gap-table row is non-reproducible on `b47f669`, falsified" | **Verified** (β re-ran the table) |

**Rule 3.13 honest-claim discipline:** α's claims.md treats each AC as a falsifiable proposition and names the evidence that would refute each. No claim hides behind hedging or "verification deferred"; every claim either has direct evidence or names a precise mechanical witness sigma can run. **Rule 3.13 compliance: strong.**

## Special-attention areas

### γ-scaffold line-number drift (C-1)
γ scaffold §Gap row 2 says "scripts/release.sh line 102". Actual line is 54 (β verified on both `b47f669` pre-fix and current post-fix). α correctly identified and documented the drift in α-closeout §AC3 Note. **C-severity** — documentation hygiene in γ scaffold, not a substantive bug. Recommendation for γ: when authoring future scaffolds, copy the actual line number from `grep -n` output rather than from memory.

### Self-coherence §Head SHA self-reference (C-4)
`.cdd/unreleased/43/self-coherence.md` line 163 says "α R1 head SHA (cycle/43-impl): `8b8f716`" but the actual head is `006b185` (a meta commit on top of 8b8f716 that records the SHA). This is a single-bootstrap-step circular reference: the commit that records the head SHA is itself the head SHA. Common pattern; α-closeout commit (8b8f716) is the **substantive** R1 head; the meta commit (006b185) updates the recorded value. **C-severity** — could be tightened by either (a) computing the SHA after the meta commit ahead of time (impossible in git), or (b) accepting the one-step circularity. β notes the circularity but does not consider it a finding worth fixing.

### Pin to older image — design defensibility (no finding)
The runner-pin regresses `ubuntu-latest` to `ubuntu-22.04`. β considered whether this is technical debt. **Conclusion: no.** Three reasons: (a) ci.yml::build already pinned to 22.04 — the release pipeline now matches; (b) v0.4.0 (last working release) was on 22.04 — the pin restores the known-good runtime; (c) the pin is trivially reversible by a future cycle once 24.04's depext path is fixed upstream. The pin is the correct localized fix for the named root cause; expanding scope to "upgrade to 24.04 with explicit apt-config" would be scope creep here.

### Phase 1 backward-compat (no finding)
v0.5.0/v0.6.0/v0.7.0 release.yml runs never fired (Bug 1 — tag-prefix mismatch). AC3's fix prevents future drops of the v-prefix. v0.8.0/v0.9.0 runs did fire but failed silently (Bug 2 — runner-image drift). AC2's fix restores the working runtime. Together AC2 + AC3 protect future releases against both classes. **Composed fix is coherent.**

### Sibling-branch placement (no finding)
AC6 amendment lives on `cycle-43-proposal-amend` (off `proposals/cycle-36-followons`), not on `cycle/43-impl`. The proposal file's canonical location is `proposals/cycle-36-followons` (not yet on main). β agrees with α's rationale: amending at the canonical source is cleaner than duplicating onto cycle/43-impl, which would create a divergence when the proposal eventually merges. The cross-branch reading load for β is real but acceptable — α flagged it in α-closeout debt-item #5. **Acceptable pattern; documented.**

### AC4 deferral — punt-disguised-as-defer test (no B-finding)
γ scaffold line 64 frame: "If α deferred AC4 with strong justification, that's also good. If α attempted AC4 but didn't complete it, that's a B-finding." β tests α's claim that no attempt was made because tools were absent: (a) `gh: command not found` — β verified by running it; (b) `mcp__github__*` lacks create-release / upload-asset — β verified by ToolSearch query. α did not attempt AC4 because the harness genuinely cannot execute it. The deferral is honest. **No B-finding.**

### List-page-vs-detail-page UI inconsistency (C-2, listed above)
β's WebFetch readings of the list page were inconclusive (badges failed to render). The first-pass reading suggested "appears successful" for v0.8.0 and v0.9.0 (consistent with α's claim) but a definitive check would require either (a) the GitHub Actions REST API's `conclusion` field, or (b) a screenshot. β recommends future references to this finding either cite the API `conclusion` field (the API-level claim) or include a screenshot (the UI-level claim). The deeper claim (conclusion-vs-artifact false-positive gap) is fully supported by the Releases-API check alone. **C-severity** on the UI-inconsistency framing; **no impact** on AC2's fix or AC6's scope.

## Findings summary

| ID | Severity | AC | Finding | Recommendation |
|---|---|---|---|---|
| C-1 | C | AC3 | γ scaffold §Gap said "scripts/release.sh line 102"; actual is line 54 | Update γ-scaffold authoring discipline to copy line numbers from `grep -n` output rather than memory |
| C-2 | C | AC1 | "list-page shows green while detail-page shows Failure" is presented with stronger confidence than β can independently verify from HTML scraping | Future cites of this finding either invoke the GitHub Actions REST API `conclusion` field or include a screenshot |
| C-3 | C | AC6 | Proposal-amendment prose says "release.yml on five consecutive tags reported a green checkmark on the workflow-list page" — conflates Bug 1 (3 tags never ran) with Bug 2 (2 tags ran-and-failed-silently) | Before the proposal merges (separate cycle), refine the prose to distinguish "2 of 5 ran-and-failed-silently" from "3 of 5 never ran" |
| C-4 | C | meta | `.cdd/unreleased/43/self-coherence.md` §Head SHA records `8b8f716` while actual head is `006b185` (meta commit on top) | Accept one-step circularity; no fix needed |
| C-5 | C | AC2 | Action-version pinning (`actions/checkout@v4`, `ocaml/setup-ocaml@v3`, `softprops/action-gh-release@v2`) all use floating major-version pins — same time-bomb class as the runner pin α just defused | Open a follow-on issue "pin actions to specific tags in release.yml" with P3. Already documented in α-closeout debt #4 |

**0 A. 0 B. 5 C.** Per cdd/review §3.3: A/B count = 0 → **APPROVED**.

## Surface ↔ AC ↔ commit map (β verification)

| AC | Surface | Commit | β verified |
|---|---|---|---|
| AC1 | alpha-closeout.md §AC1 + claims.md §Claim 1 | `8b8f716` (closeout) | ✓ run-detail pages, YAML diff, Releases API |
| AC2 | `.github/workflows/release.yml` | `8c93f5a` | ✓ diff is minimal and targeted |
| AC3 | `scripts/release.sh` line 54 | `ffcf6e7` | ✓ grep + header-comment alignment |
| AC4 | deferred to sigma (operator-handoff documented) | n/a | ✓ tool-absence claims verified |
| AC5 | ships with AC4 | n/a | ✓ |
| AC6 | `.cdd/iterations/proposals/cnos-cdd-ci-green-gate/ISSUE.md` (sibling branch) | `3b376d5` | ✓ all 5 required additions present |

## Recommendations to γ

1. Land cycle/43-impl on main. AC1+AC2+AC3 are coherent and complete. AC4+AC5 are properly deferred. AC6 lives on a sibling branch that will land when the proposal cycle merges.
2. γ post-merge F2 verification: run AC6-style discipline immediately — verify (a) workflow conclusion on a test tag (sigma's choice) AND (b) Release object produced.
3. cdd-iteration finding for this cycle: self-applied AC6 motivation (β verified that 0 of 5 expected Release objects exist via `mcp__github__list_releases` — a conclusion-only F2 check would have missed this for 5 consecutive cycles).

## β R1 final SHA

`7753821` (β R1 review commit on `cycle/43-impl`).
