# cdd/issue: Add cycle scope sizing — split-decision heuristic + master+subs pattern

**Labels:** `docs, P2, cdd`
**Priority:** P2 — improvement to issue-authoring discipline; not blocking but reduces α/β failure modes that currently surface as "issue too big" only after dispatch.
**Status:** Drafted; depends on #331 patch 2 landing (MCA preconditions).
**Mode:** `design-and-build` — the design lives in this issue body (a single new section in `cdd/issue/SKILL.md`); no separate design doc warranted at this scale.
**Depends on:** #331 (esp. patch 2 / MCA preconditions and patch 4 / round-count + finding-class metrics).

## Problem

**What exists:** `cdd/issue/SKILL.md` defines an issue's contract (problem, impact, scope, ACs, proof plan, etc.) and (as of #331 patch 2) the mode taxonomy with MCA preconditions. There is no guidance on how γ decides cycle *size* — whether an issue should run as a single cycle or be split into a master + sub-issues.

**What is expected:** γ has an explicit, multi-factor heuristic for sizing a cycle at scoping time. The heuristic produces a visible decision artifact in the issue body (kept-whole vs split-into-subs), with named factors and a justification field for at-edge cases. The master+subs pattern that cnos-tsc `usurobor/tsc#23` used successfully is codified as a first-class shape with explicit independent-shippability requirements for subs.

**Where they diverge:** γ today sizes by intuition. The cnos-tsc supercycle produced direct evidence that AC count alone is not the predictor (cycle 26 with 6 ACs ran clean in 1 round; cycle 29 with 6 ACs took 2). The actual predictor is multi-factor: new code surface, cross-module breadth, lifecycle span, MCA-precondition stability, independent-shippability of AC groups. Cycle 25 (12 ACs, 2 rounds) was at the edge — α reading for 20+ minutes before the first commit was a side effect of issue size that the operator initially mis-read as "α stuck." That ambiguity is itself a cost the heuristic should reduce.

## Impact

- **α loads too much context** when issues exceed 10 ACs. The supercycle's cycle 25 ran but produced a 20-minute reading phase that was operator-ambiguous (stuck vs thinking). Smaller issues converge faster.
- **β review pressure spikes** on big issues — when RC happens, the rework surface is large, and findings can compound across modules.
- **Operator can't predict cycle cost** without a sizing artifact. There's no signal at scoping time that says "this is a big one — expect 3 rounds" or "this should be split into 4."
- **Master+subs pattern works but is ad-hoc.** `usurobor/tsc#23` succeeded with this shape — 6 sub-issues, 5 closed, 1 deferred — but cdd doesn't name it, so the next γ has to rediscover the pattern.

## Status truth

| Surface | Status | Notes |
|---|---|---|
| `cdd/issue/SKILL.md` mode declaration | Shipping in #331 patch 2 | Names MCA / explore / design-and-build / docs-only modes; sets MCA preconditions. |
| `cdd/issue/SKILL.md` cycle-size guidance | Not present | No AC-count cap, no split-decision heuristic, no master+subs pattern. |
| Master+subs in practice | Used successfully | `usurobor/tsc#23` (closed) + 6 sub-issues; ad-hoc shape, not codified. |
| Round-count metric | Shipping in #331 patch 4 | Per-cycle round counts visible in PRA + ledger; required to validate sizing-heuristic predictions over time. |

## Source of truth

| Claim / surface | Canonical source | Status |
|---|---|---|
| Mode declaration + MCA preconditions | `cdd/issue/SKILL.md` (post-#331 patch 2) | Pending merge |
| AC-count + round-count empirical evidence | `usurobor/tsc#23` cycles 24/25/26/27/29 close-out artifacts (`.cdd/releases/{0.5.0,0.6.0,0.7.0}/{N}/`, `.cdd/unreleased/{27,29}/`) | Shipped |
| Master+subs pattern in practice | `usurobor/tsc#23` master + #24 #25 #26 #27 #28 #29 sub-issues | Shipped |
| Round-count + finding-class metrics format | `cdd/post-release/SKILL.md` Step 5.5 + §4 (post-#331 patch 4) | Pending merge |

## Cycle scope sizing (recursive)

This issue itself uses the very heuristic it proposes:

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | 0 new modules; 1 new section in 1 file (`cdd/issue/SKILL.md`) | no |
| (b) Cross-module breadth | 1 file touched | no |
| (c) Lifecycle span | design (in issue body) + docs change in same cycle | no — small enough |
| (d) MCA preconditions | not MCA — design lives in issue; mode = `design-and-build` | n/a |
| (e) Independent shippability of AC groups | 4 ACs; tightly bound to one section | n/a — keep whole |

**Decision:** keep whole. Cycle scope is small (1 file, 1 section, ~5 ACs).

## Scope

**In scope:**
- Add a new section `## Cycle scope sizing` to `cdd/issue/SKILL.md` between the existing `## Mode declaration and MCA preconditions` and `## When to load each subskill`.
- Define the soft AC-count guideline (1–4 small / 5–7 typical / 8–10 at-edge / ≥11 split-or-justify).
- Define the five-factor split-decision heuristic (new code surface / cross-module breadth / lifecycle span / MCA preconditions / independent shippability).
- Define the master+subs pattern: each sub independently shippable; master cites subs via repo's native sub-issue mechanism; master closes when all subs closed or explicitly tracked as named debt.
- Add a *Cycle scope sizing* row template to the existing `## Minimal output pattern`.
- Add to the existing handoff checklist: "Cycle scope-sizing decision recorded; if at-edge, justification present."
- Cite empirical anchor in the new section (cnos-tsc `usurobor/tsc#23` cycle 25's 12-AC at-edge case; cycle 24's multi-module new-contract surface as the higher-difficulty signal).

**Out of scope:**
- Hard caps on AC count. The guideline is soft — γ may override with justification.
- Tooling that auto-splits issues. The decision stays with γ.
- Changes to how master+subs link mechanically (cnos-side `sub-issue` vs cnos-tsc `mcp__github__sub_issue_write` are repo-specific).
- Splitting `usurobor/tsc#23` retroactively or other historical cycles. The heuristic applies forward.
- Changes to MCA preconditions (those land in #331 patch 2).

**Deferred:**
- Quantitative validation of the heuristic — needs ≥10 cycles' worth of round-count data (collected automatically once #331 patch 4 lands and per-cycle round counts accrue in the ledger). The validation cycle would file a separate issue once data accumulates.

## Acceptance criteria

### AC1: New `## Cycle scope sizing` section in `cdd/issue/SKILL.md`

**Invariant:** `cdd/issue/SKILL.md` contains a level-2 header `## Cycle scope sizing` between `## Mode declaration and MCA preconditions` and `## When to load each subskill`.
**Oracle:** `grep -n "^## Cycle scope sizing" src/packages/cnos.cdd/skills/cdd/issue/SKILL.md` returns one match; section ordering verified by line-number ordering of the three headers.
**Positive:** Section exists; ordering correct.
**Negative:** Section missing OR placed in wrong order OR placed in a different file.
**Surface:** `src/packages/cnos.cdd/skills/cdd/issue/SKILL.md`.

### AC2: Three rules present (AC-count cap + five-factor heuristic + master+subs pattern)

**Invariant:** The new section names:
1. The soft AC-count guideline with the four bands (1–4, 5–7, 8–10, ≥11) and explicit "must split or justify" trigger at ≥11.
2. The five split-decision factors (a–e) named explicitly.
3. The master+subs pattern with three explicit requirements: independent shippability of subs; master cites subs via repo-native sub-issue mechanism; master closes when subs closed or named-debt.

**Oracle:** Manual review against the AC text plus `grep -E "(1.4|5.7|8.10|\\b11)\b" ...` and `grep -E "\(a\)|\(b\)|\(c\)|\(d\)|\(e\)"` and `grep -E "master \\+ subs|independently shippable"` all match.
**Positive:** All three rules present with all named sub-points.
**Negative:** Any rule missing OR factor (a–e) collapsed to fewer points OR master+subs pattern stated without the three explicit requirements.
**Surface:** `cdd/issue/SKILL.md` new section body.

### AC3: Scope-sizing template added to minimal output pattern

**Invariant:** The existing `## Minimal output pattern` template gains a `## Cycle scope sizing` block between `## Status truth` (or wherever placement most cleanly fits the contract flow) and `## Acceptance criteria`, with a 5-row factor table and a Decision field.
**Oracle:** `grep -nE "## Cycle scope sizing|Decision: keep whole / split" src/packages/cnos.cdd/skills/cdd/issue/SKILL.md` matches the template region.
**Positive:** Template block present; matches the recursive form this issue itself uses.
**Negative:** Template block missing OR factor table has ≠5 rows.
**Surface:** `cdd/issue/SKILL.md` minimal output pattern.

### AC4: Handoff checklist gains scope-sizing row

**Invariant:** The existing handoff checklist (around the bottom of `cdd/issue/SKILL.md`) gains one new row: "Cycle scope-sizing decision recorded; if at-edge (8–10) or above (≥11), justification or master+subs pointer present."
**Oracle:** `grep -E "^- \\[ \\] Cycle scope-sizing" src/packages/cnos.cdd/skills/cdd/issue/SKILL.md` matches.
**Positive:** Row present, language explicit about at-edge justification or split pointer.
**Negative:** Row missing OR language ambiguous (no at-edge condition).
**Surface:** `cdd/issue/SKILL.md` handoff checklist.

### AC5: Empirical anchor cited

**Invariant:** The new section names the cnos-tsc supercycle as evidence: cycle 25 at 12 ACs as the at-edge case; cycle 24 (7 ACs, 3 rounds) as the demonstration that AC count alone isn't the predictor; cycle 26 (6 ACs, 1 round) and cycle 29 (6 ACs, 2 rounds) as the same-AC-count, different-difficulty datum.
**Oracle:** `grep -E "tsc#23|cycle 24|cycle 25|cycle 26|cycle 29" src/packages/cnos.cdd/skills/cdd/issue/SKILL.md` matches in the new section.
**Positive:** Anchors present; numbers reproducible from `usurobor/tsc#23` close-out artifacts.
**Negative:** Section asserts the heuristic without empirical citation.
**Surface:** `cdd/issue/SKILL.md` new section.

## Proof plan

**Invariant:** γ has a documented, recursive heuristic for sizing cycles at scoping time, with the master+subs pattern formalized.
**Surface:** `src/packages/cnos.cdd/skills/cdd/issue/SKILL.md`.
**Oracle:** β reviews the diff for AC1–AC5 above; β additionally applies the heuristic to *this issue's own body* and verifies the recursive scope-sizing block matches the proposed template (recursive coherence — same pattern as #331's PR-on-its-own-rules).
**Positive case:** β confirms all five ACs and the recursive check; one round to merge.
**Negative case:** β finds the heuristic over-prescriptive (γ judgment displaced) or under-specified (no testable oracle on splitting decisions).
**Operator-visible projection:** Future cnos issues — and tsc cycles — will carry the *Cycle scope sizing* block in their bodies. Future PRAs will be able to retrospectively check whether the sizing decision predicted the round count.
**Known gap:** Quantitative validation of the heuristic — does the five-factor score actually predict review-round count? — requires accumulated data from #331 patch 4 once that lands. This issue ships the heuristic without yet validating its predictive power; validation is a deferred follow-on.

## Skills to load

**Tier 3:**
- `cnos.core/skills/skill` — for skill-program/frontmatter coherence on `cdd/issue/SKILL.md`
- `cnos.eng/skills/eng/writing` — for prose patches to skill files

**Why:**
- One file, one section, prose-only patch — no code, no runtime, no platform changes.

## Active design constraints

- **No frontmatter changes** to `cdd/issue/SKILL.md` (preserve existing `name` / `description` / `triggers` / `calls`).
- **No new sub-skills.** The section lives inline; if it grows substantially after data accumulates, a sub-skill `cdd/issue/sizing/` becomes an option but is out of scope for this cycle.
- **Cite the empirical anchor.** Without `usurobor/tsc#23` round-count data backing the heuristic, the rule is taste rather than evidence.
- **Soft cap, not hard cap.** AC-count guidance is a flag, not a gate. γ's judgment governs; the heuristic forces the judgment to be visible.
- **Master+subs pattern requires independent shippability.** A "split" that creates a chain (sub B can't run until sub A merges) is an anti-pattern; the section must call this out.

## Related artifacts

- `usurobor/tsc#23` (master, closed) — empirical anchor for the heuristic
- `usurobor/tsc#24, #25, #26, #27, #28, #29` (sub-issues) — pattern instances
- `usurobor/cnos#331` (this issue's parent dependency) — patch 2 (MCA preconditions cited in factor d) and patch 4 (round metrics needed for retrospective validation)
- `cdd/CDD.md` §1.2 (small-change artifact collapse) — coordinates with the 1–4-AC band
- `cdd/post-release/SKILL.md` §4 / Step 5.5 — round-count target (`≤1 docs, ≤2 code`); this issue's heuristic is the upstream half of the same loop

## Non-goals

- Hard caps on AC count.
- Auto-splitting tools.
- Changes to how master+subs link mechanically.
- Validation of the heuristic's predictive power (deferred).
- Retroactively re-sizing closed cycles.
- Spec changes to TSC, c-equiv, or any non-cdd package.
- New finding-class taxonomy (lives in #331 patch 4).

## Success / closure condition

This issue is closeable when:
- AC1–AC5 each map to evidence in the branch diff.
- β applies the proposed heuristic to *this issue's own body* (recursive check) and confirms the scope-sizing block matches the proposed template.
- The new section cites the cnos-tsc supercycle as empirical anchor with reproducible numbers.
- #331 has merged (or this PR rebases on top of it cleanly to avoid factor (d) drift).
- Mode = `design-and-build`; disconnect via the §2.5b path (post-#331 merge) at `.cdd/releases/docs/{ISO-date}/{N}/`.
