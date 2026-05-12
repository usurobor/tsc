---
cycle: 43
role: gamma
type: gamma-closeout
date: "2026-05-12"
merge_sha: "9ad9d68"
post_merge_katas_run: "13"
post_merge_katas_conclusion: "success"
post_merge_katas_duration_seconds: 112
release_yml_verification: "deferred — release.yml fix only triggers on v* tag push (harness 403); sigma to verify by next release OR by workflow_dispatch trigger if available"
---

# γ Close-out — Cycle #43

**Issue:** tsc #43 — release.yml silently not publishing GitHub Releases (investigate + backfill v0.5.0–v0.9.0)
**Mode:** docs-only-plus-CI per §2.5b (no version bump; release-pipeline-only change)
**Branch trail:** `cycle/43` (γ scaffold `87a9bd3`) → `cycle/43-impl` (α R1 `006b185`) → `cycle/43-impl-review` (β R1 APPROVED `fa10186`) → main merge `9ad9d68` (PR #44) → `cycle/43-closeout` (this branch)
**Review rounds:** 1 (β R1 APPROVED, 0A/0B/5C advisories)
**ACs:** 4/6 (AC4 + AC5 honestly deferred to sigma per γ scaffold's defer-allowed clause)
**Dispatch configuration:** §5.2 single-session δ-as-γ via Claude Code Agent tool
**Cycle #36 follow-on patches self-applied:** F1 ✓ / F2 ✓ (expanded) / F3 ✓

## Cycle trail

| SHA | Role | Subject |
|---|---|---|
| `87a9bd3` | γ | cycle(43): γ scaffold — Bug 1 + Bug 2 identified at scaffold (F1) |
| `ffcf6e7` | α | fix(release-script): scripts/release.sh tag — v-prefix (AC3) |
| `8c93f5a` | α | fix(ci): release.yml pin runs-on: ubuntu-22.04 (AC2) |
| `8b8f716` | α | closeout(43): α R1 closeout + claims + AC1 root-cause statement |
| `006b185` | α | meta(43): record α R1 head SHA in self-coherence |
| `3b376d5` | α | proposals(cnos-cdd-ci-green-gate): expected-artifact-produced (AC6) [on sibling branch] |
| `7753821` | β | review(43): β R1 review — APPROVED (0A, 0B, 5C advisories) |
| `fa10186` | β | meta(43): record β R1 head SHA in review + closeout |
| `9ad9d68` | γ | merge(43): cycle/43-impl-review → main (PR #44) |

## Close-out triage

| Finding | Source | Severity | Disposition |
|---|---|---|---|
| C-1 γ scaffold line-number drift (said "line 102" for release.sh; actual line 54) | β R1 | C (advisory) | Documented in α-closeout §AC3; pre-α γ-side documentation error only |
| C-2 List-page UI claim corroboration gap | β R1 | C (advisory) | The deeper conclusion-vs-artifact gap is independently verified by `mcp__github__list_releases` (0 of 5 expected releases). UI rendering specifics inconclusive but the underlying claim stands |
| C-3 AC6 prose count-conflation (Bug 1 + Bug 2 share "5 missing releases" but cause different missing classes) | β R1 | C (advisory) | Cosmetic; refine in proposal during sigma's filing pass |
| C-4 self-coherence head-SHA self-reference | β R1 | C (advisory) | Conventional drift — closeout-time meta-commit recording its own SHA |
| C-5 Floating-major action-version pins remain (`actions/checkout@v4`, `ocaml/setup-ocaml@v3`, `softprops/action-gh-release@v2`) | β R1 + α §Debt #4 | C (advisory) | Same drift class as the one this cycle fixed (just for runner image). Follow-on cycle worth filing |
| AC4 + AC5 backfill deferral | γ scaffold defer-clause + α reasoning | n/a | β verified honest: `gh: command not found` empirically + ToolSearch confirmed no MCP create-release tool |

## §9.1 Triggers

| Trigger | Fired? | Disposition |
|---|---|---|
| Coherence regression on merge | No | β R1 APPROVED clean; F2 katas verification green |
| Avoidable tooling failure | **Yes — historical** | The 5-cycle release-pipeline drift is itself an avoidable-tooling-failure that went undetected for ~6 weeks. This cycle is the §9.1 follow-on for the trigger fired by cycle #34's γ-discovery. cdd-iteration F1 below captures it. |
| Honest-claim violation | No | All α claims verified by β; F1 §Gap claims verified pre-α-state |
| Branch sprawl | Yes (pre-named) | 4 cycle branches + 1 sibling branch (cycle-43-proposal-amend). Sibling-branch pattern is new — captured in cdd-iteration F2 |
| Mode-mismatch | No | Workflow-only fix; §2.5b correctly invoked |
| Floating-version-pin drift | **Yes — class** | Same class as Bug 2's runner pin. Three remaining floating pins are the same risk. cdd-iteration F3 |

## TSC Grades (honest, per §3.8)

| Axis | Grade | Reasoning |
|---|---|---|
| **α** | **A−** | 0 binding findings; 5 C-severity advisories (all minor). Bug 2 root-cause analysis substantive and defensible (β verified 4 converging facts independently). Bug 1 fix one-line + clean. AC4+AC5 deferral honest (β verified `gh` absence and MCP-tool absence). AC6 amendment clean. Novel finding: list-page-vs-detail-page UI inconsistency — the empirical anchor for F2 refinement is stronger than γ scaffold's framing. |
| **β** | **A** | Independent verification of α's root-cause claim (4 converging facts cross-checked); empirically tested AC4 deferral by running `gh: command not found` and ToolSearching for MCP create-release; honest about list-page claim's corroboration gap; thoroughness without false-RC inflation. |
| **γ** | **A−** (§5.2 cap) | F1 ✓ peer-enumeration before scaffold (caught Bug 1 + identified Bug 2 candidate causes). F2 ✓ **expanded** — applied the cycle's own AC6 refinement: SHA-anchored verification on merge SHA rather than badge-blind polling. Caught the stale-badge false-positive at apply-time. F3 ✓ parent-session quiescent. §5.2 cap A− binding; γ work earned the cap. |
| **C_Σ** | **A−** | (3.7 · 4.0 · 3.7)^(1/3) ≈ 3.79 |

**Level:** L6 (CI / release-pipeline fix; no engine semantics change).

## What shipped

- **`scripts/release.sh:54`** — `TAG="v$VERSION"` (was `TAG="$VERSION"`). Future releases get the `v` prefix; matches the script's own header comment.
- **`.github/workflows/release.yml:11`** — `runs-on: ubuntu-22.04` (was `ubuntu-latest`). Pinned to the runner image v0.4.0 (last working) used. Mirrors `ci.yml::build`'s already-pinned setting.
- **AC6 amendment on `cycle-43-proposal-amend`** (sibling branch off `proposals/cycle-36-followons`): `proposals/cnos-cdd-ci-green-gate/ISSUE.md` gains a clause + AC requiring "expected-artifact-produced" verification beyond workflow-conclusion check. Cites cycle #43 as the empirical anchor. **Awaits sigma's proposal-bundle filing to land on cnos.**

## F2 self-application (expanded)

This cycle applied the F2 refinement it's amending into the in-flight proposal:

**Step 1 — Badge poll** returned "passing" near-instantly post-merge. **False positive** — reflected the prior cycle #34 successful run, not cycle #43's in-progress run.

**Step 2 — SHA-anchored verification.** Directly probed the actions page for a katas run on `9ad9d68` specifically:
- Run #13 on `9ad9d68`: conclusion = success
- Duration: 1m 52s (within healthy band; >1m+ baseline)
- No false-positive UI surface

**Result:** F2 verification (refined) confirms cycle #43's primary fix doesn't regress katas. The release.yml fix itself only triggers on `v*` tag push and is therefore harness-deferred (same pattern as cycle #34).

## Closure gate (per `cdd/gamma/SKILL.md` §2.10)

| Row | Condition | Status |
|---|---|---|
| 1 | alpha-closeout.md present | ✅ `.cdd/releases/docs/2026-05-12/43/alpha-closeout.md` |
| 2 | beta-review.md present | ✅ |
| 3 | beta-closeout.md present | ✅ |
| 4 | claims.md (honest-claim manifest) | ✅ |
| 5 | Merge commit recorded | ✅ `9ad9d68` |
| 6 | §2.5b docs-only path followed | ✅ artifacts moved to `.cdd/releases/docs/2026-05-12/43/`; no tag |
| 7 | CHANGELOG ledger row | N/A — no version bump |
| 8 | cdd-iteration.md authored | ✅ |
| 9 | F2 katas verification on merge SHA | ✅ **SHA-anchored** (expanded F2 per AC6) |
| 10 | F2 release.yml verification on tag | **deferred** to sigma (harness 403 on tag push; same pattern as cycle #34) |
| 11 | Issue close comment | Operator action — sigma comments on tsc #43 with merge SHA + handoff status |

## Deferred outputs (operator handoff to sigma)

**Primary deferral — Cycle B (backfill 5 missing releases):**

```bash
# After this cycle's fixes land (already merged at 9ad9d68):
for tag in v0.5.0 v0.6.0 v0.7.0 v0.8.0 v0.9.0; do
  git checkout "$tag"  # for v0.5.0/v0.6.0/v0.7.0 use bare "0.5.0" etc. — those tags lack v prefix
  cd engine/ocaml
  opam install . --deps-only -y && opam exec -- dune build
  cp _build/default/bin/main.exe ../../coh-linux-x64
  cd ../..
  chmod +x coh-linux-x64
  gh release create "$tag" coh-linux-x64 \
    --title "v$(cat VERSION)" \
    --notes "Backfilled in cycle #43. See CHANGELOG.md for release details."
done
git checkout main
```

**Note on tag-name inconsistency:** 0.5.0, 0.6.0, 0.7.0 tags lack the `v` prefix on origin (caused by the now-fixed Bug 1). Two options for sigma:
- Backfill releases under existing tag names (`gh release create 0.5.0 ...`) — preserves historical inconsistency but ships
- Re-tag (`git tag v0.5.0 0.5.0 && git push origin v0.5.0 :refs/tags/0.5.0`) before backfilling — clean but destructive

γ recommends Option A (preserve history); the inconsistency itself becomes a CHANGELOG footnote.

**Secondary deferral — release.yml empirical verification:**

After backfills land, sigma should verify the release.yml fix end-to-end. Two paths:
- Wait for the next legitimate release (v0.9.1 hotfix or v0.10.0)
- Add a `workflow_dispatch:` trigger temporarily to release.yml + invoke manually

**Tertiary — AC6 sibling-branch landing:**

The AC6 amendment lives on `cycle-43-proposal-amend` (off `proposals/cycle-36-followons`). When sigma files the cycle-36-followons proposal bundle as cnos issues, the AC6 clause should land along with the F2 proposal.

## Cycle #43 closed cdd-wise.

Implementation merged at `9ad9d68`. F2 (expanded) verification: katas green. Backfills + release.yml empirical validation pending sigma.

**Next on sigma's queue: AC4 backfill of v0.5.0–v0.9.0 releases.** This unblocks cycle #38's `validate-published-binary` job (which has been silently degraded by the missing releases since cycle #38 shipped).
