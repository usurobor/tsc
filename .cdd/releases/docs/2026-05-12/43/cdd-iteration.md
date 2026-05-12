---
cycle: 43
type: cdd-iteration
date: "2026-05-12"
dispatch_configuration: "§5.2 single-session δ-as-γ via Claude Code Agent tool"
finding_count: { skill-gap: 0, protocol-gap: 1, tooling-gap: 2, metric-gap: 0, positive: 3 }
---

# cdd-iteration — Cycle #43

Cycle #43 produced **3 findings (1 protocol-gap + 2 tooling-gap) + 3 positive signals**. The protocol-gap was self-shipped as AC6 (F2 refinement amendment). Two new tooling-gap classes surfaced.

## F1 — cdd-tooling-gap: floating-major action-version pins are a latent drift class

**Source:** α §Debt #4 + β R1 finding C-5.

`release.yml` still has three floating-major pins after this cycle's runner pin:
- `actions/checkout@v4`
- `ocaml/setup-ocaml@v3`
- `softprops/action-gh-release@v2`

The runner-image drift this cycle fixed (`ubuntu-latest` → `ubuntu-22.04`) is the same class. Major-version pins float across minor/patch releases of the action. If any of these actions changes behavior subtly (as `ocaml/setup-ocaml@v3` did on ubuntu-24.04), the workflow can silently start failing.

Additional context: Node.js 20 deprecation warning surfaced in the v0.9.0 workflow logs — `actions/checkout@v4` currently uses Node 20, which GitHub will deprecate June 2, 2026. When the action transparently bumps to Node 24 (or whatever the migration is), behavior may shift again.

**Trigger class:** cdd-tooling-gap. Affects ANY repo using GitHub Actions with floating-major pins, not just tsc.

**Recommended cnos patch:** add to `cdd/release/SKILL.md` (or a CI-conventions sibling skill): "GitHub Actions pins should be commit-SHA or full-tag (`@v4.1.2`), never floating-major (`@v4`). Acceptable exceptions: actions explicitly marked stable-floating by their maintainers (e.g., `actions/checkout@v4` is officially supported as a floating tag per upstream README — but the workflow must document the acceptance)."

**Disposition (this cycle):** out-of-scope. γ filed as cdd-iteration F1 for follow-on. Recommended: tsc-side issue "audit and pin all GitHub Actions versions" — small mechanical cycle.

## F2 — cdd-tooling-gap: list-page UI surface lies about workflow conclusions

**Source:** α R1 new finding #1, β R1 partially verified (list-page rendering was inconclusive in WebFetch readings; detail page consistently showed Failure).

GitHub Actions has two surfaces for run status:
- **List page** (`/actions/workflows/<name>.yml` or `/actions`): renders a green checkmark for runs where the job's "conclusion" field is success
- **Detail page** (`/actions/runs/<run_id>`): shows the step-level breakdown including failures even when conclusion = success

For v0.8.0 and v0.9.0 release.yml runs, α observed (and β partially corroborated) that the list page showed green while the detail page showed Failure with exit code 10. This is the false-positive class cdd F2 verification needs to catch.

**Why this matters for cdd:** all my prior F2 verifications in this session (cycles #36, #38, #34) used badge polling or list-page WebFetch as the verification mechanism. Each of those cycles' kata workflows did genuinely produce expected artifacts (verified separately by uploads + run timing), so the false-positive class didn't fire — but it could have. The F2 rule as currently written is fragile against this UI inconsistency.

**Trigger class:** cdd-tooling-gap. Affects every cycle's F2 verification step.

**Disposition (this cycle):** **shipped as AC6.** The F2 proposal (`proposals/cnos-cdd-ci-green-gate/`) gains a new clause + AC requiring artifact-existence verification beyond conclusion-field check. Lives on sibling branch `cycle-43-proposal-amend`, awaiting sigma's filing pass.

**Self-application this cycle:** γ used SHA-anchored direct-page inspection rather than badge-blind polling for the F2 verification step. Caught the stale-badge state immediately (cycle's own merge run was in-progress while badge showed prior-cycle's success).

## F3 — cdd-protocol-gap: sibling-branch pattern for cross-proposal amendments

**Source:** α implementation choice.

The AC6 amendment to `proposals/cnos-cdd-ci-green-gate/ISSUE.md` lives on `cycle-43-proposal-amend` (off the existing `proposals/cycle-36-followons` branch which hasn't been filed on cnos yet), not on `cycle/43-impl` (the primary impl branch).

**Why sibling:** the proposal file lives on a different branch namespace (`proposals/`) than the cycle's primary work (`cycle/43-impl`). Putting the amendment on `cycle/43-impl` would merge it into main, where the proposal file doesn't structurally belong (proposals are pre-filing drafts that live on `proposals/` branches until sigma files them on cnos). The sibling pattern keeps the cycle's primary work clean while threading the amendment to the right home.

**But:** β raised this as a verification concern — is the sibling-branch pattern an acceptable practice or scope creep? β found it acceptable for this case (clean separation, clear handoff). Worth codifying.

**Trigger class:** cdd-protocol-gap. The sibling-branch pattern isn't named in any cdd skill currently.

**Recommended cnos patch:** `cdd/CDD.md` or `cdd/issue/SKILL.md` could gain a brief note: "When a cycle's primary impl ships on `cycle/{N}-impl` but the cycle also amends a pre-filing proposal on `proposals/{slug}`, the amendment may ship on a sibling branch `cycle-{N}-proposal-amend` off `proposals/{slug}`. Acceptable when (a) the amendment is small (≤200 lines), (b) the amendment is cited in α-closeout and β-review, (c) it doesn't merge into main."

**Disposition (this cycle):** drafted as cdd-iteration F3. γ does not file a separate proposal yet — folding into the eventual cnos cdd workflow patch bundle is cleaner.

## P1 — positive: F1 caught both bugs pre-scaffold

γ's peer-enumeration table at §Gap identified Bug 1 (tag-prefix drift in scripts/release.sh line ~102, actual 54) AND placed Bug 2 candidate causes in the open question. α confirmed both. F1 discipline saved at least one diagnosis round.

## P2 — positive: F2 (refined) caught its own false-positive at apply-time

γ's first F2 poll (badge-blind) read "passing" near-instantly — a stale signal. γ recognized the pattern from cycles #34 and #38 and re-armed with SHA-anchored verification. Found the actual run in-progress, then waited for terminal state. The F2 refinement this cycle ships was self-applied within the cycle itself. Recursive coherence.

## P3 — positive: 5-week-old silent-failure surfaced + closed

The release-pipeline drift went undetected for ~6 weeks (April 5 v0.4.0 → May 12 cycle #34's γ-discovery → this cycle's repair). Without cycle #34's γ-curiosity probing `get_release_by_tag v0.9.0` and getting 404, the gap could have persisted indefinitely. The whole F2 refinement (AC6) flows from that single γ-curiosity probe being preserved as an empirical anchor.

## Branch trail (pre-named in cnos `proposals/cnos-cdd-claude-code-dispatch §5.2`)

5 branches: `cycle/43`, `cycle/43-impl`, `cycle/43-impl-review`, `cycle-43-proposal-amend` (sibling), `cycle/43-closeout`. New: sibling-branch pattern (F3).

## Dispatch configuration result

§5.2 single-session δ-as-γ. F1+F2-expanded+F3 self-application all held. γ-axis cap A− earned. Larger investigation surface than #36/#38 (real diagnosis work + 5-tag backfill consideration + UI inconsistency finding), but pattern remains workable.

## Outputs

| Output | Target | Status |
|---|---|---|
| F1 — floating-major action-version pin class | Future cnos `cdd/release/SKILL.md` patch + tsc-side audit cycle | Drafted in this iteration |
| F2 — list-page-vs-conclusion-field UI surface inconsistency | **SHIPPED as AC6** on sibling branch `cycle-43-proposal-amend` awaiting sigma filing | Operative |
| F3 — sibling-branch pattern naming | Future cnos `cdd/CDD.md` or `cdd/issue/SKILL.md` patch | Drafted in this iteration |
| P1/P2/P3 | This file | ✅ recorded |
| **Operator handoff: 5 backfills (AC4) + release.yml empirical validation** | sigma | Detailed in `gamma-closeout.md §Deferred outputs` |

## INDEX

To be appended to `.cdd/iterations/INDEX.md`:

| Cycle | Date | Findings | Patches | MCAs | No-Patch |
|---|---|---|---|---|---|
| 43 | 2026-05-12 | 1 (protocol-gap) + 2 (tooling-gap) + 3 (positive) | 1 shipped (AC6) + 2 drafted | 0 | 1 (branch sprawl, pre-named) |

## Cycle health

5-week-old silent failure root-caused + fixed + self-shipped F2 refinement. C_Σ A−. Pattern continues to validate that §5.2 single-session δ-as-γ + F1+F2+F3 disciplines produce clean, honest cycles even on diagnosis-heavy work.
