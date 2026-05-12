# cdd/operator §5.2: Parent-session quiescence during sub-agent runs (no shared-WT writes)

**Labels:** `docs, P2, cdd`
**Priority:** P2 — §5.2-specific failure mode that produces real branch corruption and repeated fix-rounds. Named explicitly so future single-session δ-as-γ operators don't repeat the pattern. Cheap to document; expensive when violated.
**Status:** Drafted; ready for cycle dispatch.
**Mode:** `docs-only, design-and-build` — adds one subsection to whatever cnos surface carries §5.2 (likely `cdd/operator/SKILL.md` per the claude-code-dispatch proposal — fold here if both land together).
**Depends on:** `proposals/cnos-cdd-claude-code-dispatch` (§5.2 single-session δ-as-γ dispatch configuration). This proposal is an amendment / sub-section to that one.

## Problem

**What exists:** The claude-code-dispatch proposal names §5.2 single-session δ-as-γ via Agent tool as a valid dispatch configuration. It documents γ/δ collapse, harness push restrictions (branch sprawl), and grading-floor implications. It does **not** yet name the **shared-working-tree invariant**: parent session and Agent-tool sub-agents share the same filesystem; concurrent writes to the working tree corrupt state.

**What is expected:** A new subsection (§5.2.x — Parent-session quiescence) naming the invariant explicitly. When a sub-agent is running in the background, the parent session must enter quiescent mode: no file edits, no commits, no branch switches. Reads (status, log, file inspection) are fine. The parent's role during sub-agent runs is dispatch coordination and waiting — not concurrent work.

**Where they diverge:** Empirically observed during tsc cycle #36 dispatch. While α R1 was running in the background, the parent session (operator-as-γ) made a manual edit to the working tree. When α attempted to commit, the working-tree state was unexpected; the commit picked up parent's uncommitted changes, leading to a corrupted commit that had to be amended. The fix required parent to revert + re-dispatch a fix-round. Same shared-WT pattern produces concurrent branch-switch races (parent switches branch while sub-agent expects a different HEAD) and concurrent index races (sub-agent's `git add` sees a stale index from parent's prior staging).

## Impact

- **Repeated fix-rounds with no protocol fault.** The root cause is operator-induced, not α/β/γ-induced. β cannot grade against it; α cannot defend against it; γ produces the failure unknowingly. The protocol's role-separation has no defense against operator concurrency.
- **Branch-sprawl correlated.** Cycle #36 hit 5 cycle branches partly because of harness 403 restrictions (already named in §5.2) and partly because of shared-WT corruption forcing re-pushes. Naming the invariant lowers branch sprawl independently of the harness fix.
- **Recursive coherence — protocol applies to its own operator.** §5.2 currently names what sub-agents experience (fresh context, MCP scope, push restrictions). It should also name what the parent operator must do — which is "wait." Operator constraints are symmetric with sub-agent guarantees.
- **Cross-protocol propagation.** cdw and future c-d-X protocols inheriting §5.2 dispatch inherit this invariant. Naming it once at the dispatch-configuration level avoids re-discovery.

## Status truth

| Surface | Status | Notes |
|---|---|---|
| §5.2 single-session δ-as-γ via Agent tool | Drafted (`proposals/cnos-cdd-claude-code-dispatch`) | Configuration named; sub-agent semantics covered |
| §5.2 harness push restrictions / branch sprawl | Drafted (sibling proposal) | Sub-agent / branch-naming surface covered |
| §5.2 parent-session quiescence invariant | NOT NAMED | This proposal |
| Empirical evidence | tsc cycle #36 dispatch log + α R1 corrupted commit + reset | Inferable from cycle artifacts; not yet codified |

## Source of truth

| Claim / surface | Canonical source | Status |
|---|---|---|
| Claude Code Agent tool semantics | Claude Code in-harness docs | External |
| §5.2 dispatch configuration | `proposals/cnos-cdd-claude-code-dispatch/ISSUE.md` | Drafted |
| Shared filesystem semantics | Operating-system-level invariants (no isolation between parent and Agent tool sub-agents) | External |
| Branch-sprawl empirical anchor | tsc cycles #32 + #36 | Shipped |

## Cycle scope sizing (per cnos §1.6c)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | 0 — one prose subsection | no |
| (b) Cross-module breadth | one section in `cdd/operator/SKILL.md` §5.2 | no |
| (c) Lifecycle span | docs-only | no |
| (d) MCA preconditions | not MCA | n/a |
| (e) Independent shippability | one cohesive invariant | no |

**Decision:** keep whole. 3 ACs, low-typical band. **Fold into `proposals/cnos-cdd-claude-code-dispatch` if both ship in one cycle** — same surface, related invariant.

## Scope

**In scope:**

1. **Add `cdd/operator/SKILL.md` §5.2.x — Parent-session quiescence during sub-agent runs.** Contents:
   > **§5.2.x Parent-session quiescence.** When a sub-agent dispatch is in flight (via the Agent tool), the parent session MUST enter quiescent mode:
   > - **No file edits** in the working tree.
   > - **No commits** from the parent session.
   > - **No branch switches** (`git checkout`, `git switch`).
   > - **No `git add` / `git restore --staged`** (index state must remain stable for the sub-agent's view).
   > - **No `git pull` / `git fetch` that updates the current branch HEAD.**
   >
   > **Permitted during sub-agent runs:**
   > - Reads: `git status`, `git log`, `git diff`, file reads via Read tool, web fetches, GitHub MCP queries.
   > - Coordination: dispatching additional sub-agents (each gets its own context; isolation is by sub-agent), reading existing branches via `git fetch <branch>` (does not update HEAD).
   > - **Filesystem operations on paths outside the repo** (e.g., `/tmp`, drafts).
   >
   > **When the parent must edit:** dispatch a sub-agent to do the edit, or wait for current sub-agents to complete. The parent is the coordinator, not a fourth concurrent writer.

2. **Document the failure mode.** Sub-section "What goes wrong when this is violated" with worked example:
   - Sub-agent A is running α R1, has read the working tree, is about to `git add` and `git commit`.
   - Parent session edits file X concurrently.
   - Sub-agent's `git add .` picks up parent's edits accidentally.
   - Sub-agent's commit message describes only its intended change but the diff includes parent's edits.
   - Result: corrupted commit, branch must be reset, fix-round required.

3. **Sub-agent isolation note.** Multiple sub-agents launched in parallel (via `Agent` tool calls in one parent message) have **isolated contexts** from each other but **share the working tree with the parent and with each other**. Concurrent file edits by parallel sub-agents are also a corruption risk and should be avoided — multi-sub-agent parallelism is for independent reads, not concurrent writes.

**Out of scope:**

- Filesystem-level isolation (`isolation: "worktree"` mode) — that's a different dispatch configuration; this proposal is for the default shared-WT mode.
- Multi-session δ (§5.1 multi-`claude -p`) — separate processes, separate working trees, no shared-WT concern. Mention briefly as the contrast.
- Implementing automated quiescence enforcement — out of scope; prose-only invariant.

## Acceptance Criteria

**AC1 — §5.2.x subsection authored.** `cdd/operator/SKILL.md` (or wherever §5.2 lives) gains the Parent-session quiescence subsection with the prescriptive list and the failure-mode example.

- *Invariant:* subsection enumerates ≥5 prohibited actions and ≥3 permitted actions during sub-agent runs.
- *Oracle:* `rg 'Parent.session quiescence|quiescent' cnos:cdd/operator/SKILL.md` returns ≥1 hit.
- *Positive:* a §5.2 operator reading the subsection knows exactly what they can / cannot do mid-dispatch.
- *Negative:* soft "operator should avoid concurrent edits" prose — must be a concrete list.
- *Surface:* `cnos:cdd/operator/SKILL.md`.

**AC2 — Failure-mode worked example present.** A 3–5 sentence example showing the corruption pattern (sub-agent's commit picks up parent's uncommitted change).

- *Invariant:* example present; names ≥2 specific git operations (`git add`, `git commit`) in the corruption sequence.
- *Oracle:* `rg 'worked example|when this is violated' cnos:cdd/operator/SKILL.md` returns ≥1 hit.
- *Positive:* future operators reading the example understand the failure mode without having to experience it.
- *Negative:* abstract-only prescription.
- *Surface:* same as AC1.

**AC3 — Sub-agent parallelism note.** Subsection covers parallel sub-agents (multi-Agent-call in one parent message) — share WT with each other and with parent.

- *Invariant:* one paragraph naming the parallel-sub-agent shared-WT case.
- *Oracle:* `rg 'parallel sub.agent|concurrent.*sub.agent' cnos:cdd/operator/SKILL.md` returns ≥1 hit.
- *Positive:* operators don't dispatch concurrent-write sub-agents.
- *Negative:* the parallelism note is absent or omits the WT-sharing detail.
- *Surface:* same as AC1.

## Proof plan

1. Author §5.2.x prose per AC1–AC3.
2. Self-apply on the patch-landing cycle: γ records "parent-session quiescence honored during α / β dispatches" in `gamma-closeout.md`.
3. cdd-iteration captures whether the new rule prevented any near-miss (positive signal).

## Risks

- **Quiescence is slow.** Operators may want to do "small" things during sub-agent runs. Mitigation: the rule's cost (5–10 minutes of waiting per dispatch) is much less than the cost of one corrupted-commit fix-round (30+ minutes). Net-positive.
- **Multi-session ambiguity.** Operators reading this in a §5.1 multi-session context may apply it unnecessarily. Mitigation: subsection explicitly scopes to §5.2; §5.1 has separate working trees and no concurrency concern.
- **`isolation: "worktree"` Agent mode.** When Agent tool runs in worktree-isolation mode, the shared-WT concern goes away. Mitigation: the subsection should note worktree-mode as the exception — if used, quiescence is unnecessary.

## Open questions

1. **Worktree-isolation mode coverage.** Should the subsection name `isolation: "worktree"` as a way to relax quiescence? — *Recommendation:* yes, one sentence: "When the Agent tool runs with `isolation: \"worktree\"`, parent-session quiescence is unnecessary (the sub-agent operates on a copy of the repo). Default mode requires quiescence."
2. **Parallel sub-agents — can one read while another writes?** — *Recommendation:* yes for reads, no for writes. Multi-sub-agent parallelism is for read parallelism (e.g., three Explore agents searching different parts of the codebase simultaneously). Concurrent writes are corruption risks regardless of which agent is the writer.
3. **Failure-mode example specificity.** Should the example name `git add .` (catches parent's edits) vs `git add <specific files>` (might be safer)? — *Recommendation:* name `git add .` as the failure-prone pattern; `git add <specific files>` is a partial mitigant but doesn't eliminate the race.
4. **Quiescence during long sub-agent runs.** Operators may legitimately need to file unrelated issues / draft proposals / read docs during a 5-minute sub-agent run. Are those allowed? — *Recommendation:* yes — anything outside the cycle's working tree is fine. The quiescence applies to the *cycle's* working tree only. Filing a tsc issue via MCP while α runs on tsc working tree is permitted (no WT writes from parent).

## References

- `proposals/cnos-cdd-claude-code-dispatch/ISSUE.md` — §5.2 dispatch configuration (parent proposal)
- tsc cycle #36 — empirical anchor (operator concurrent edit during α R1 caused branch-state corruption + re-dispatch)
- Claude Code Agent tool documentation — external (in-harness)
- `git add` / index semantics — external (git docs)
