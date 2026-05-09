# cdd: Add §1.6c — dispatch sizing, prompt scope, and commit checkpoints

**Labels:** `docs, P2, cdd`
**Priority:** P2 — observed pattern across N≥4 dispatch failures (cycle #335 + 3 of 5 α close-out re-dispatches in TSC supercycle); not blocking but recurs across cycles. Codifying it converts an empirical pattern into operator-checkable mechanics.
**Status:** Drafted; ready for cycle dispatch.
**Mode:** `design-and-build` — design lives in this issue body; the patch lands in the same cycle. Three skill files modified.
**Depends on:** #335 (this proposal cites §1.6b which lands via cycle #333; cycle #335 is the recursive-coherence retro that finalizes its merge state).

## Problem

**What exists:** CDD.md §1.6 covers sequential bounded dispatch. §1.6a covers re-dispatch prompts. §1.6b (just landed via cycle #333, merged at `30c02d1`) notes that re-dispatch prompts should be lighter than initial dispatch. There is **no rule for the initial dispatch** that:
- scales the timeout budget with the work,
- sets prompt scope to match task complexity,
- or requires commit checkpoints inside the dispatch budget.

**What is expected:** A new §1.6c covering all three concerns at the *initial* dispatch (sister of §1.6b which covers the re-dispatch case). Plus a companion `operator/SKILL.md` section on timeout recovery (operator-side execution detail). Plus telemetry hooks in `post-release/SKILL.md` §4 to validate the heuristic against future cycles.

**Where they diverge:**
- Cycle #335 budget = 600s; actual need ≈ 1380s (per heuristic below). Agent wrote 18 of 22 expected files but committed zero before SIGTERM. Operator recovered work from worktree (luck — no protocol-level guarantee).
- TSC supercycle: 3 of 5 α close-out re-dispatches failed under full α skill load. Lightweight task drowned in heavyweight prompt context. §1.6b addresses re-dispatch case; initial dispatches still load full skill stacks even for known-light tasks.
- Flag-incompatibility class (`--output-format stream-json` requires `--verbose` with `-p`) was caught and mechanically fixed via the operator skill (cycle #333 patch). Documents the *symptom* but not the *family* — context-load vs task-complexity mismatch is the family; flag-mismatch is one instance.

## Impact

- **Failed dispatches cost a cycle of operator time.** The #335 timeout required: detect death → check worktree → recover files → finish ACs → commit → push. Operator-σ override per `operator/SKILL.md` §4 is documented but inflates close-out grades (per the §3.8 rubric, a cycle with operator override has γ < A).
- **Information loss.** When agents die without committing, evidence-of-progress disappears unless operator does explicit recovery. The recovery procedure isn't named in any skill file, so it depends on operator memory.
- **No closed feedback loop.** The 120s/180s heuristic in this proposal is informed by N=4 instances; no mechanism currently records actual-vs-budget timing per cycle, so future cycles can't tighten it.
- **Cross-repo drift.** The TSC supercycle's α close-out re-dispatch failures and cnos's #335 timeout share the same root family (context-load mismatch). Codifying once in cnos cdd applies to both repos via the cdd skill bundle.

## Status truth

| Surface | Status | Notes |
|---|---|---|
| `cdd/CDD.md` §1.6 (sequential bounded dispatch) | Shipped | Pre-#283, baseline polling/dispatch model |
| `cdd/CDD.md` §1.6a (re-dispatch prompts) | Shipped | Per cycle #287 |
| `cdd/CDD.md` §1.6b (re-dispatch complexity note) | Shipped | Cycle #333 (merged at `30c02d1`) — sister rule for re-dispatch case |
| `cdd/CDD.md` §1.6c (initial dispatch sizing/scope/checkpoints) | NOT PRESENT | This proposal |
| `cdd/operator/SKILL.md` §timeout-recovery | NOT PRESENT | This proposal |
| `cdd/post-release/SKILL.md` §4 dispatch telemetry fields | NOT PRESENT | This proposal |
| `cdd/operator/SKILL.md` `--output-format stream-json` + `--verbose` | Shipped | Cycle #333 (`c48d5a9`) — addresses one symptom |

## Source of truth

| Claim / surface | Canonical source | Status |
|---|---|---|
| Sister rule §1.6b | `cdd/CDD.md` §1.6b (cycle #333, commit `30c02d1`) | Shipped |
| Re-dispatch protocol | `cdd/CDD.md` §1.6a | Shipped |
| Operator-side override | `cdd/operator/SKILL.md` §4 | Shipped |
| PRA telemetry home | `cdd/post-release/SKILL.md` §4 (post-#331 patch 4) | Shipped |
| Empirical anchors | cnos cycle #335 (PR #337 close-out artifacts at `.cdd/releases/docs/2026-05-09/335/`); TSC supercycle close-outs `.cdd/releases/{0.5.0,0.6.0,0.7.0}/{N}/`; operator skill `--verbose` patch at commit `c48d5a9` | Shipped |
| §3.8 honest-grading rubric | `cdd/release/SKILL.md` §3.8 (cycle #331 patch 5, commit `b27fc15`) | Shipped |

## Cycle scope sizing (per proposed `cnos-cdd-cycle-scope-sizing` heuristic)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | 0 new modules | no |
| (b) Cross-module breadth | 3 files in `cnos.cdd` package (`CDD.md`, `operator/SKILL.md`, `post-release/SKILL.md`) | moderate |
| (c) Lifecycle span | docs only; `design-and-build` mode | no |
| (d) MCA preconditions | n/a — `design-and-build` | n/a |
| (e) Independent shippability | three changes are tightly coupled (heuristic, recovery, telemetry are one feedback loop); splitting would orphan the heuristic without telemetry | no |

**Decision:** keep whole. AC count (5) is well within the 5–7 typical band. Three changes form one coherent feedback loop.

## Scope

**In scope:**

1. Add `cdd/CDD.md` §1.6c with three sub-sections:
   - **(a) Timeout heuristic.** `budget = max(300s, 120 × ac_count)` for docs cycles; `max(400s, 180 × ac_count)` for code cycles. Marked "initial; refine with telemetry."
   - **(b) Prompt scope.** Lightweight tasks (close-out re-dispatch, PRA, single-section skill patches) load only the role-skill subsection relevant; substantial tasks load full Tier 1a/1b/1c. When in doubt, load more. Cross-references §1.6b.
   - **(c) Commit checkpoints.** Dispatch prompt MUST include: "Commit after each AC's evidence is in place. For multi-cycle work, commit after each cycle's artifact set. First commit MUST land within the first 25% of budget."

2. Add `cdd/operator/SKILL.md` §timeout-recovery (or extend an existing operator section) with the executable recovery procedure: `git status --short`, `find . -newer $session_start`, `git stash list`, `git diff`. Decision tree for "commit under agent identity vs operator identity vs re-dispatch."

3. Add `cdd/post-release/SKILL.md` §4 dispatch telemetry fields:
   - `dispatch_seconds_budget`
   - `dispatch_seconds_actual`
   - `commit_count_at_termination`
   These accumulate per-cycle data so the heuristic in §1.6c(a) can be tightened from informed-guess to empirically-validated after ~10 cycles.

4. Cite empirical anchors in §1.6c body: cnos cycle #335 (9 ACs, 600s budget, 0 commits at termination, 18 files recovered from worktree); TSC supercycle's 3-of-5 α close-out re-dispatch failures under full α skill load.

5. Cross-reference §1.6c ↔ §1.6b ↔ operator §timeout-recovery ↔ post-release §4 telemetry so the discipline is end-to-end visible.

**Out of scope:**

- Auto-tooling that selects budget at dispatch time. The heuristic stays operator-evaluated.
- Replacing the SIGTERM/timeout model itself. The cycle's only contract is to add scaling + checkpoints to the existing model.
- Schema changes to `cn.json` or any package manifest.
- Spec changes outside `src/packages/cnos.cdd/`.
- Changes to existing §1.6a / §1.6b text (only adding §1.6c).
- Validation of the 120s/180s constants — they are explicitly marked "initial heuristic; refine with telemetry."

**Deferred:**

- Quantitative validation of the heuristic — needs ≥10 cycles of telemetry from the new fields. Validation cycle to file separately once data accumulates.
- Auto-checkpoint enforcement (e.g., a watchdog that kills the agent if first-commit doesn't land within 25% of budget). The §1.6c rule is operator-checked initially; auto-enforcement is deferred to a later mechanical-reinforcement cycle.

## Acceptance criteria

### AC1: §1.6c added to `cdd/CDD.md` with three sub-rules

**Invariant:** `cdd/CDD.md` contains a `§1.6c` heading after `§1.6b`. The section names three sub-rules (a/b/c) covering timeout heuristic, prompt scope, and commit checkpoints. Each sub-rule has explicit guidance, not just narrative.
**Oracle:** `grep -nE "^### §1.6c|^#### \(a\)|^#### \(b\)|^#### \(c\)" src/packages/cnos.cdd/skills/cdd/CDD.md` returns ≥4 matches in correct order.
**Positive:** Section present; three sub-rules present; numerical heuristic in (a) is explicit; prompt-scope guidance in (b) cites §1.6b; commit-checkpoint instruction in (c) is quotable text.
**Negative:** Section absent, sub-rules collapsed into one paragraph, or numerical guidance left as TBD.
**Surface:** `src/packages/cnos.cdd/skills/cdd/CDD.md`.

### AC2: Operator/SKILL.md gains timeout-recovery section

**Invariant:** `cdd/operator/SKILL.md` contains a section (`§X — Timeout recovery` or equivalent) describing: (i) the worktree-inspection commands; (ii) the decision tree for agent-identity vs operator-identity commit; (iii) the override declaration cross-reference to §4.
**Oracle:** `grep -nE "Timeout recovery|timeout recovery" src/packages/cnos.cdd/skills/cdd/operator/SKILL.md` returns ≥1 match; section content includes `git status --short` and `git stash list`.
**Positive:** Section present; commands cited; decision tree explicit.
**Negative:** Section absent, commands missing, or recovery delegated implicitly to operator memory.
**Surface:** `src/packages/cnos.cdd/skills/cdd/operator/SKILL.md`.

### AC3: PRA telemetry fields added to post-release/SKILL.md §4

**Invariant:** `cdd/post-release/SKILL.md` §4 (Review Quality) lists `dispatch_seconds_budget`, `dispatch_seconds_actual`, `commit_count_at_termination` as recordable per-cycle fields (alongside the existing per-cycle round-counts table from cycle #331 patch 4).
**Oracle:** `grep -nE "dispatch_seconds_budget|dispatch_seconds_actual|commit_count_at_termination" src/packages/cnos.cdd/skills/cdd/post-release/SKILL.md` returns 3 matches in or near §4.
**Positive:** All three field names present; framing is "optional initially, mandatory after telemetry maturity" or similar honest framing.
**Negative:** Any field name missing; or fields presented as immediately-mandatory without acknowledging the data accumulation period.
**Surface:** `src/packages/cnos.cdd/skills/cdd/post-release/SKILL.md` §4.

### AC4: Cross-references between §1.6c, §1.6b, operator §timeout-recovery, post-release §4 are intact

**Invariant:** §1.6c body cites §1.6b (sister rule); §1.6c (a) cites post-release §4 telemetry as the validation home; §1.6c (c) commit-checkpoint rule cites operator §timeout-recovery as the failure-mode handler.
**Oracle:** Manual review — three explicit cross-refs in §1.6c body.
**Positive:** All three cross-refs present, each citing the correct file and section.
**Negative:** Any cross-ref missing or pointing at a non-existent section.
**Surface:** `cdd/CDD.md` §1.6c body.

### AC5: Empirical anchor cited in §1.6c body

**Invariant:** §1.6c body names cnos cycle #335 (9 ACs, 600s budget, 0 commits at termination) and TSC supercycle's α close-out re-dispatch failures as the empirical anchors for the heuristic. Both citations are reproducible — anyone reading can find the cited artifacts.
**Oracle:** `grep -E "cycle #335|tsc-supercycle|usurobor/tsc|600s.*0 commits|18 files" src/packages/cnos.cdd/skills/cdd/CDD.md` returns matches in §1.6c.
**Positive:** Anchors present with reproducible references (commit SHAs or close-out paths).
**Negative:** Heuristic asserted without empirical citation.
**Surface:** `cdd/CDD.md` §1.6c body.

## Proof plan

**Invariant:** Initial-dispatch failure modes (timeout-before-commit, full-skill-load on lightweight tasks, no recovery procedure) have explicit cdd-skill rules that an agent can mechanically follow.
**Surface:** `src/packages/cnos.cdd/skills/cdd/{CDD.md,operator/SKILL.md,post-release/SKILL.md}`.
**Oracle:** β reviews the diff against AC1–AC5 oracles; β additionally applies rule 3.13 to *this PR's own cycle* — does this cycle's own dispatch budget match the heuristic it proposes? (5 ACs × 120s + 300s floor = 900s; if α dispatched at < 900s, that's a recursive-coherence finding.)
**Positive case:** All five ACs pass; cross-refs verified; β confirms recursive-coherence check.
**Negative case:** Any AC fails; or the heuristic is asserted without citation; or this cycle's own dispatch contradicts the heuristic.
**Operator-visible projection:** Future cnos PRAs gain `dispatch_seconds_*` and `commit_count_at_termination` fields. After ~10 cycles record telemetry, the constants in §1.6c (a) can be empirically tightened.
**Known gap:** The 120s/180s constants are guess-then-codify. Validation requires accumulated telemetry from cycles after this lands — explicit deferred follow-on per Scope §Deferred.

## Skills to load

**Tier 3:**
- `cnos.core/skills/skill` — for skill-program/frontmatter coherence on the three modified files
- `cnos.eng/skills/eng/writing` — for prose patches to skill files

**Why:**
- All work is structured prose modifications across three skill files; no code, no platform changes.

## Active design constraints

- **No frontmatter changes** to any of the three modified SKILL.md files.
- **No new sub-skills** — the §timeout-recovery lives inline in operator/SKILL.md, not as a sub-skill.
- **Heuristic constants are explicitly "initial."** The 300/400 floors and 120/180 multipliers are informed guesses anchored in N=4 failures. The §1.6c body MUST mark them as "refine with telemetry" rather than presenting as final.
- **Cross-refs are normative.** §1.6c, §1.6b, operator §timeout-recovery, and post-release §4 dispatch fields are one feedback loop. Any cross-ref drift is a binding finding.
- **Empirical citations must be reproducible.** Cite commit SHAs or close-out paths so future readers can find the evidence.
- **No retroactive changes** to §1.6a or §1.6b. Only adding §1.6c.
- **The cycle that ships this rule should validate it against itself.** Per the proof-plan recursive-coherence check, this cycle's dispatch budget should match its own heuristic. β verifies.

## Related artifacts

- `cdd/CDD.md` §1.6 / §1.6a / §1.6b — siblings of the proposed §1.6c
- `cdd/operator/SKILL.md` §4 (override) — operator-side companion
- `cdd/post-release/SKILL.md` §4 (Review Quality) — telemetry home (post-#331 patch 4)
- `cdd/release/SKILL.md` §3.8 — honest-grading rubric (cycle #331 patch 5); operator-override has grade implications
- `cnos:.cdd/releases/docs/2026-05-09/335/{alpha-closeout,gamma-closeout}.md` — empirical anchor for the timeout case (cycle #335 friction log)
- `usurobor/tsc:.cdd/releases/{0.5.0,0.6.0,0.7.0}/{25,24,26}/` — TSC supercycle close-outs documenting α re-dispatch failures
- `usurobor/cnos#330` PR `#333` (cycle #333 commit `c48d5a9`) — the `--verbose` symptom-class fix

## Non-goals

- Auto-tooling for budget selection at dispatch time.
- Changes to the SIGTERM / timeout model itself.
- Watchdog enforcement of the 25%-first-commit rule.
- Validation of the 120s/180s constants in this cycle (deferred).
- Schema changes outside `src/packages/cnos.cdd/`.
- Backfilling telemetry on cycles before this lands.
- Cross-repo deployment of the rule (it lands in cnos cdd; tsc and other repos pick it up via the canonical skill bundle they consume).

## Success / closure condition

This issue is closeable when:
- AC1–AC5 each map to evidence in the branch diff.
- β applies the proposed §1.6c heuristic recursively to this very cycle's dispatch budget — was this cycle's α dispatched per the heuristic? If not, the artifact records the discrepancy honestly per rule 3.13.
- All three cross-refs (between §1.6c, §1.6b, operator §timeout-recovery, post-release §4) are verified intact.
- Empirical anchors cited in §1.6c body are reproducible.
- This cycle's own close-out follows the full protocol (recursive coherence — `cdd-iteration.md` for this cycle records `F1: cdd-protocol-gap — initial dispatch had no sizing rule, fixed by §1.6c, disposition: patch-landed`; INDEX.md gains a row; PRA + CHANGELOG row authored; §2.5b disconnect path used).
- Mode = `design-and-build`; disconnect via §2.5b at `.cdd/releases/docs/{ISO-date}/{N}/`.
