---
cycle: 38
issue: "#38"
branch: "cycle/38"
mode: "design-and-build"
disconnect: "§2.5b docs-only — no version bump (workflow YAML extensions only)"
date: "2026-05-12"
dispatch_configuration: "§5.2 single-session δ-as-γ via Claude Code Agent tool. γ axis grade capped at A− per the proposed §3.8 amendment (cnos #344 / cycle-36 F2 follow-on)."
self_application: "This cycle dogfoods the three protocol patches from cycle #36's follow-ons: F1 (γ peer-enumeration before scaffold), F2 (γ verifies CI green on merge SHA before close-out), F3 (parent-session quiescence during sub-agent runs)."
---

# Self-Coherence — Cycle #38

## Gap (peer-enumerated per F1 discipline)

Peer-enumeration of `.github/workflows/` on main `8e3094c` (run before authoring this §Gap):

| File | Has `upload-artifact`? | Has `$GITHUB_STEP_SUMMARY`? | Has scheduled / release triggers? |
|---|---|---|---|
| `ci.yml` | ✓ (`coh-linux-x64`) | ✗ | ✗ |
| `tsc.yml` | ✓ (`tsc-reports-${{ github.sha }}`) | ✓ | ✗ (push/PR on paths) |
| `release.yml` | publishes `coh-linux-x64` to GitHub Releases via `softprops/action-gh-release@v2` on `v*` tag push | ✗ | ✓ (tag-triggered) |
| `cdd-notify.yml` | ✗ | ✗ | ✗ |
| `katas.yml` | ✗ | ✗ | ✗ |

**Gap reality (informed by enumeration):**

1. `katas.yml` (shipped cycle #36, fixed via PR #37 at `8e3094c`) runs every kata under `katas/*/` on push to main + PR via `dune build` + direct binary invocation. Pass/fail is the only signal. Per-kata `c_sigma` scores, verdicts, and metrics are emitted to stdout under `::group::kata $id` markers but discarded at end-of-run beyond the 90-day step-log retention.
2. `katas.yml` has neither artifact upload nor step-summary — even though `tsc.yml` already establishes both patterns canonically (lines 85–112 of tsc.yml). The work is mostly: port tsc.yml's pattern onto katas.yml.
3. `katas.yml` only validates *build-from-HEAD* (whatever's on the cycle branch). The actual published binary at the `v*` tag — already uploaded to GitHub Releases by `release.yml` (`coh-linux-x64`) — is never re-validated. A release-validation surface is missing.
4. Empirical anchor: cycle #36 itself shipped a CI gate that went red on its first main run; the JSON output of that failed run was not persisted (only the step log). Re-running locally was the only debug path. AC1's artifact upload would have made that mechanical.

## Mode

`design-and-build`. Design surfaces: AC3's published-binary validation has a Path-A (build-from-tag) vs Path-B (download release-artifact) decision — empirical anchor: release.yml *does* upload `coh-linux-x64` to GitHub Releases, so Path B is materially possible (not blocked by absent artifact). Build surface: YAML modifications + maybe a small kata-summary helper. Mode-declaration is consistent with `cdd/issue/SKILL.md` MCA preconditions: no separate design artifact; design lives in issue #38 body, this self-coherence document, and α's choice on AC4. Not MCA.

## Cycle scope sizing (per cnos §1.6c heuristic)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | YAML edits to `katas.yml` (~30 lines added); possibly one tiny helper script; possibly a new sibling workflow | low |
| (b) Cross-module breadth | `katas.yml` (modify) + `katas/README.md` (docs) ± a new workflow file for AC3 | low–moderate |
| (c) Lifecycle span | mechanical | no |
| (d) MCA preconditions | not MCA — design fixed | n/a |
| (e) Independent shippability | AC1+AC2 ship cleanly together; AC3+AC4 (published-binary) is independently shippable | yes — AC3 could split |

**Decision:** keep whole. **5 ACs**, mid-typical band. Matches #36 cycle shape but with cleaner γ recon (F1 self-applied) so less drift expected.

## Active Skills

**Tier 1a (always loaded):**
- `cdd/CDD.md`
- `cdd/SKILL.md`
- `cdd/gamma/SKILL.md`

**Tier 1b (lifecycle phase skills):**
- `cdd/issue/SKILL.md`
- `cdd/alpha/SKILL.md`
- `cdd/beta/SKILL.md`
- `cdd/review/SKILL.md` (rule 3.13 honest-claim; this cycle's β should peer-enumerate `.github/workflows/` to verify no duplication)
- `cdd/release/SKILL.md` (§2.5b docs-only)
- `cdd/post-release/SKILL.md` (Step 5.6b cdd-iteration)

**Tier 2 (engineering, for α):** `cnos.eng/skills/eng/ci`, `cnos.eng/skills/eng/writing`.

## Impact graph

```
.github/workflows/katas.yml         MODIFY — add artifact upload + step summary
                                    add published-binary validation job (same file per §Open question 1 recommendation)
katas/README.md                     MODIFY — add §Where to find kata results section
                                    (no impact on existing katas.yml triggers or kata content)
```

**Read-only / model-on:**
- `.github/workflows/tsc.yml` (lines 85–112) — canonical pattern for artifact + step summary
- `.github/workflows/release.yml` (lines 38–48) — release-artifact mechanics for AC4 Path B option

## ACs (verbatim from issue #38)

**AC1 — Per-kata JSON artifact uploaded.**
- *Invariant:* one JSON per kata directory in `.kata-results/`; uploaded via `actions/upload-artifact@v4`; `if: always()`.
- *Oracle:* download artifact from a known-good run; expect `01-glider.json` + `02-random-soup.json`, valid JSON.
- *Surface:* `.github/workflows/katas.yml`.

**AC2 — Step summary surfaces per-kata score.**
- *Invariant:* `$GITHUB_STEP_SUMMARY` markdown table with rows for each kata (Verdict / C_Σ / Range / Status).
- *Oracle:* PR run's summary tab shows the table.
- *Surface:* same workflow file.

**AC3 — Published-binary validation job runs.**
- *Invariant:* new job exists; triggers on `release: types: [published]` + weekly `schedule.cron`; runs kata loop against the released binary; reports independent pass/fail.
- *Oracle:* trigger via `workflow_dispatch` (manual) or wait for cron; observe job completing against the released binary.
- *Surface:* same workflow file (per §Open question 1 recommendation in issue).

**AC4 — Release-artifact discovery mechanism documented.**
- *Invariant:* AC3 picks Path A (build-from-tag) or Path B (download release-artifact via `softprops/action-gh-release`-published `coh-linux-x64`); choice justified in `alpha-closeout.md`.
- *Oracle:* re-run AC3 on same version produces identical pass/fail.

**AC5 — Documentation updated.**
- *Invariant:* `katas/README.md` gains §Where to find kata results subsection ≤120 words.
- *Oracle:* `rg 'Where to find kata results' katas/README.md` returns 1 hit.
- *Surface:* `katas/README.md`.

## Honest-claim manifest claims (R1 must produce)

α R1 must produce `claims.md` with at minimum:

1. **Wiring claim:** `actions/upload-artifact@v4` is the only artifact upload mechanism added (grep-verifiable in diff).
2. **Source-of-truth claim:** Step-summary pattern matches `tsc.yml` lines 85–102 verbatim shape — re-uses canonical pattern.
3. **Reproducibility claim:** AC4 mechanism choice (Path A or B) is documented in alpha-closeout with a worked-example verification command.
4. **No false negation:** Per F1 discipline, §Gap's claim "katas.yml has neither artifact upload nor step summary" is grep-verifiable: `rg -nE 'upload-artifact|GITHUB_STEP_SUMMARY' .github/workflows/katas.yml` returns zero on `8e3094c` (head before α touches it).

## CDD Trace

1. **Receive** — γ peer-enumerated `.github/workflows/` BEFORE authoring §Gap (F1 self-application). Result: enumerated table at §Gap.
2. **Dispatch α** — Agent tool, fresh context. α reads issue #38, peer-enumerates again to verify γ's table, implements ACs.
3. **α self-coherence + claims.md + readiness signal.**
4. **Dispatch β** — Agent tool, fresh context. β applies rule 3.13 to claims + verifies new workflow doesn't duplicate `tsc.yml` patterns inappropriately.
5. **Fix rounds if any.**
6. **Merge** — `cycle/38-impl` → `main`.
7. **γ verifies CI green on merge SHA (F2 self-application).** Poll the post-merge `katas` workflow run on the merge commit. Don't author close-out until run is green. If red → fix-cycle, NOT close-out.
8. **γ close-out** — only after F2 verification confirms green.
9. **cdd-iteration** — capture F1/F2/F3 self-application as evidence; record any new findings.

## Dispatch configuration & self-application

- **Operator δ = γ** (single-session via Agent tool — Claude Code activation per cnos #344 §5.2)
- **α / β / γ identities:** `{alpha,beta,gamma}@tsc.cdd.cnos`
- **γ axis grade cap:** A− (per §5.2 proposal)

**F1/F2/F3 self-application gate (cdd-iteration evidence):**

| Patch | Self-application | Pass/fail criterion |
|---|---|---|
| F1 — γ peer-enumeration before scaffold | Done at top of this §Gap | ✓ if §Gap cites peer-enumeration table |
| F2 — γ verifies CI green on merge SHA | Step 7 above | ✓ if close-out is delayed until merge-SHA run is green |
| F3 — parent-session quiescence | This session refrains from WT edits during α/β runs | ✓ if no parent-session commits land while sub-agents are active |

If any of F1/F2/F3 self-application fails, the cycle's cdd-iteration must record the failure — same honest-claim discipline as cycle #36's recon failure surfacing.

## Head SHA

(to be filled in α R1 readiness signal)
