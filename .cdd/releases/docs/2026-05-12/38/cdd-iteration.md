---
cycle: 38
type: cdd-iteration
date: "2026-05-12"
dispatch_configuration: "§5.2 single-session δ-as-γ via Claude Code Agent tool"
finding_count: { skill-gap: 1, protocol-gap: 1, tooling-gap: 0, metric-gap: 0, positive: 3 }
---

# cdd-iteration — Cycle #38

Cycle #38 produced **two findings** and **three positive-signal observations**. The cycle's deliberate purpose included dogfooding the three cycle #36 follow-on protocol patches (F1 / F2 / F3); all three self-applied successfully.

## F1 — cdd-tooling-gap: stale-badge polling failure mode

**Source:** γ's F2 verification round. The first F2 poll (Monitor `bn9e09iue`) emitted "passing" almost immediately after merge — but at that point the post-merge katas run on `1f38731` was still queued/in-progress. The badge reflected the previous successful run on `8e3094c`, not the new merge SHA's run.

**Root cause:** GitHub's workflow badge endpoint (`/actions/workflows/<name>/badge.svg?branch=<X>`) returns the conclusion of the *most recently completed terminal run on branch X*. When a new push triggers a new run, the badge keeps showing the previous terminal state until the new run finishes. Polling "until terminal" without anchoring to a specific SHA reads as stale.

**Discoverability:** the failure produced no error — just a confidently-wrong "passing" signal that would have caused γ to ship a close-out claiming CI was verified, when actually the run hadn't yet started.

**Trigger class:** cdd-tooling-gap. Affects every cycle that uses badge-polling for F2 self-application verification.

**Disposition (this cycle):** γ caught the stale signal by cross-checking the actions-list page for runs on the specific merge SHA. Re-armed Monitor `b8d0lsl17` with a SHA-pinned check (grep the actions-list page for the merge SHA + status proximity). That monitor timed out without observing terminal state in its grep alternation — but a direct WebFetch confirmed the run completed (1m 59s) and badge transitioned cleanly. Close-out's frontmatter records `post_merge_ci_conclusion: "success"` and `post_merge_ci_run: "5"`.

**Recommended cnos patch:** amend `proposals/cnos-cdd-ci-green-gate/ISSUE.md` (F2 from cycle #36) with a §Verification recipe subsection that prescribes:

> Use a SHA-anchored poll, not a branch-anchored badge poll. Either:
> - Poll the actions API for runs on the specific merge SHA (`gh run list --branch main --json head_sha,status,conclusion --jq '.[] | select(.head_sha == "<merge-sha>")'`); OR
> - Compare the badge state's `Last-Modified` header against the push timestamp; only trust the badge after it's been observed terminal AFTER push-time + typical-run-duration.

**Affected cnos cdd skill section:** `proposals/cnos-cdd-ci-green-gate/ISSUE.md` §Proof plan + §Risks. This is a refinement of an in-flight proposal, not a new proposal.

## F2 — cdd-protocol-gap: stop-hook interaction with §5.2 parent-session quiescence

**Source:** γ during α R1 dispatch. While α was running in the background editing `katas.yml`, the harness stop-hook fired with: `[~/.claude/stop-hook-git-check.sh]: There are uncommitted changes in the repository. Please commit and push these changes to the remote branch.`

**Root cause:** the stop-hook surveys the working tree's git state and prompts the parent operator (γ) to commit + push when it detects uncommitted changes. But under §5.2 single-session δ-as-γ, those uncommitted changes are α's in-flight work — committing them from the parent would:
- Steal α's commit identity (the commit would be attributed to `gamma@` instead of `alpha@`)
- Potentially corrupt α's index state if α was mid-`git add`
- Violate F3 parent-session quiescence (the very patch this cycle dogfooded)

**Discoverability:** the hook fires reliably and conspicuously. The discipline is to *resist* the prompt, not to act on it.

**Trigger class:** cdd-protocol-gap. The F3 proposal (`proposals/cnos-cdd-parent-session-quiescence/`) names the shared-WT invariant but does not yet name this specific stop-hook interaction.

**Disposition (this cycle):** γ correctly resisted the stop-hook prompt during α R1 and again during β R1. No spurious parent commit landed. F3 self-application held.

**Recommended cnos patch:** amend `proposals/cnos-cdd-parent-session-quiescence/ISSUE.md` §5.2.x with a subsection:

> **§5.2.x.2 Stop-hook interaction.** Harness stop-hooks (or any periodic "uncommitted changes" prompt the harness emits) MUST be ignored by the parent operator while sub-agents are running. The prompt's premise — "commit your changes" — is exactly the action F3 prohibits. Resisting the prompt IS the F3 discipline; complying with it is the violation.
>
> Verification: a §5.2 cycle that produced no parent-attributed commits between α-dispatch and β-completion has honored the discipline. `git log --pretty='%h %ae' <γ-scaffold-sha>..<merge-sha> | grep '^[^ ]* gamma@'` should show only the scaffold + merge commits, never anything between α/β rounds.

**Affected cnos cdd skill section:** `proposals/cnos-cdd-parent-session-quiescence/ISSUE.md` §Scope item 1 (the §5.2.x prescription block). Refinement; not a new proposal.

## P1 — positive: F1 self-application caught the false-gap class

This cycle's §Gap was empirically grounded (peer-enumeration table at top of `self-coherence.md`). β R1 independently re-ran the enumeration and confirmed accuracy. No false-gap framing.

**Contrast with cycle #36:** that cycle's §Gap asserted "CI does not invoke `coh --kata`" while `ci.yml::kata-check` did exactly that. The false-gap survived γ scaffold + α implementation and was caught by β R1 as binding finding B-1, costing 1 review round.

**Result:** F1 (γ peer-enumeration before scaffold) is operationally validated. The discipline saved this cycle one review round + the avoidable-tooling-failure §9.1 trigger that would have fired otherwise.

## P2 — positive: F2 self-application caught the deferred-verification class

Cycle #36 closed with "Post-merge verification: operator action — verify run is green" as a row in its closure gate. The verification was performed post-close-out and revealed the workflow was red. This cycle's F2 self-application kept close-out *blocked* on the verification result, eliminating the deferred-verification class entirely.

**Contrast with cycle #36:** that cycle's `gamma-closeout.md` recorded the close-out artifacts and reviewer grades before CI ran. Post-merge addendum added later to capture the red CI result + hotfix. Two-step archive.

**Result:** F2 (γ verifies CI green on merge SHA) is operationally validated. The discipline forced honest grading — γ-axis grade is now grounded in *verified* CI state at close-out time, not deferred to "operator action."

## P3 — positive: F3 self-application caught the shared-WT concurrency class

No parent-attributed commits landed between α dispatch and β R1 completion. Stop-hook resistance documented as F2 above. F3 (parent-session quiescence) operationally validated.

**Contrast with cycle #36 R1:** that cycle's parent session edited the WT while α was running, causing α's commit to include parent's uncommitted edits — a corruption pattern requiring re-dispatch.

**Result:** F3 is operationally validated. Discipline cost: ~10 minutes of parent waiting per sub-agent dispatch. Discipline benefit: zero re-dispatches due to shared-WT corruption.

## Branch sprawl (pre-named)

4 branches on origin: `cycle/38`, `cycle/38-impl`, `cycle/38-impl-review`, `cycle/38-closeout`. Same pattern as cycle #32 and #36. Already named in `proposals/cnos-cdd-claude-code-dispatch` §5.2. No new disposition.

## Outputs to file

| Output | Target | Status |
|---|---|---|
| F1 — stale-badge polling failure | Amend `proposals/cnos-cdd-ci-green-gate/ISSUE.md` (in-flight proposal); sigma to file when ready | drafted in this iteration; refinement, not separate proposal |
| F2 — stop-hook interaction with §5.2 | Amend `proposals/cnos-cdd-parent-session-quiescence/ISSUE.md` (in-flight proposal); sigma to file when ready | drafted in this iteration; refinement, not separate proposal |
| P1 — F1 working signal | This file | ✅ recorded |
| P2 — F2 working signal | This file | ✅ recorded |
| P3 — F3 working signal | This file | ✅ recorded |
| Engine `--output` for kata mode (engine-side, tsc-internal) | Future tsc engine cycle | noted in γ close-out §Deferred outputs |

## INDEX

To be appended to `.cdd/iterations/INDEX.md`:

| Cycle | Date | Findings | Patches | MCAs | No-Patch |
|---|---|---|---|---|---|
| 38 | 2026-05-12 | 1 (tooling-gap) + 1 (protocol-gap) + 3 (positive) | 2 (amendments to in-flight cycle-36 proposals) | 0 | 1 (branch sprawl, pre-named) |

## Cycle health

Three protocol patches dogfooded; all three self-applied successfully; zero binding findings from β; CI green on merge SHA before close-out. C_Σ A−. This is the shape a clean §5.2 single-session δ-as-γ cycle takes when the operator honors F1+F2+F3 discipline.
