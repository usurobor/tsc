# cdd/operator: Add §5 — Dispatch configurations (single-session δ-as-γ via Agent tool, Claude Code activation)

**Labels:** `docs, P2, cdd`
**Priority:** P2 — recurring configuration not named in spec; valid in practice but ungoverned. Single-session δ-as-γ ran the cnos-tsc supercycle (4 cycles) plus tsc cycle #32 end-to-end. cdd doesn't currently acknowledge or constrain it.
**Status:** Drafted; ready for cycle dispatch.
**Mode:** `design-and-build` — design lives in this issue body; patch lands in `operator/SKILL.md` (new §5) + `release/SKILL.md` §3.8 (grading-floor amendment).
**Depends on:** cnos #338 (dispatch sizing — sister rule for sub-agent budgets) and cnos #339 (mechanical pre-merge gate — informs the §5.2 grading-floor reasoning).

## Problem

**What exists:** `cdd/operator/SKILL.md` describes a canonical dispatch model where δ uses `claude -p` to spawn γ, α, and β as separate Claude processes with independent auth contexts. The protocol's role-separation guarantees rest on this multi-session topology.

**What is expected:** cdd names a second valid dispatch configuration — **single-session δ-as-γ via the Claude Code Agent tool** — in which one parent Claude session acts as both δ and γ, dispatching α and β as sub-agents (fresh context, shared filesystem and MCP scope). This configuration is in use today (cnos-tsc supercycle ran this way, plus tsc cycle #32). cdd does not currently:

- Acknowledge that the Agent tool is functionally equivalent to `claude -p` for role-separation purposes (independent reasoning context)
- Name what's preserved and what's lost when sub-agents replace separate sessions
- Describe the γ/δ collapse this configuration entails
- Surface honest-grading implications (§3.8 currently treats all cycles uniformly)
- Document the harness push-restriction workaround pattern that emerges (branch-name churn under fix-rounds)
- Provide escalation criteria back to multi-session

**Where they diverge:** Operators running under Claude Code activation today have no canonical text to anchor their practice. They either default to claiming multi-session shape they don't have, or improvise the role-separation handling — both reduce protocol coherence.

## Impact

- **Configuration silence creates dishonest grading.** A cycle run under δ=γ collapse currently scores against the same §3.8 rubric as a cycle with full γ/δ separation. The latter is a stricter protocol; treating them as identical is grade inflation.
- **Branch sprawl is unexplained.** tsc cycle #32 produced 5 branches (`cycle/32` → `cycle/32-impl` → `cycle/32-impl-r2` → `cycle/32-merged` → `cycle/32-final`) because the harness blocked updates to existing branches. With no canonical pattern, this looks like operator error rather than environmental constraint.
- **Escalation criteria absent.** Operators don't know when to switch from single-session sub-agent dispatch to multi-session `claude -p`. The supercycle ran 5 cycles under single-session (3 with retro close-outs needed) before the pattern became visible.
- **Recursive coherence weakens.** When the cycle that introduces a rule runs under a degraded configuration not named in the rule, the rule's own grading discipline is suspect from the start.

## Status truth

| Surface | Status | Notes |
|---|---|---|
| `cdd/operator/SKILL.md` canonical multi-session δ | Shipped | §1 — `claude -p` per role; separate auth contexts |
| `cdd/operator/SKILL.md` sub-agent / Agent tool dispatch | NOT NAMED | This proposal |
| `cdd/operator/SKILL.md` δ=γ collapse acknowledgment | NOT NAMED | This proposal |
| `cdd/operator/SKILL.md` harness push-restriction workaround | NOT NAMED | This proposal |
| `cdd/release/SKILL.md` §3.8 honest-grading rubric | Shipped (cnos #331 patch 5) | Currently uniform; needs configuration-floor amendment |
| Cnos `cdd/post-release/SKILL.md` Step 5.6b cdd-iteration | Shipped (cnos #331 patch 6) | This proposal's findings would be tracked there per spec |

## Source of truth

| Claim / surface | Canonical source | Status |
|---|---|---|
| Canonical multi-session model | `cdd/operator/SKILL.md` §1 | Shipped |
| Agent tool semantics | Claude Code Agent tool documentation (in-harness) | External |
| `claude -p` semantics | cnos `cdd/operator/SKILL.md` §1.2 | Shipped |
| Empirical evidence — cnos-tsc supercycle | `usurobor/tsc:.cdd/releases/{0.5.0,0.6.0,0.7.0}/{24,25,26}/`, `.cdd/releases/docs/2026-05-08/{27,29}/`, `.cdd/releases/docs/2026-05-09/32/` | Shipped |
| Empirical evidence — δ=γ collapse | cnos-tsc cycle 26 γ-closeout explicit "operator (δ = γ in this two-agent configuration)"; tsc cycle #32 gamma-closeout TSC Grades section | Shipped |
| Empirical evidence — branch sprawl | tsc cycle #32 (5 branches); cnos cycles #331/#333/#335 (cycle/N+impl/r2/final pattern) | Shipped |
| §3.8 honest-grading rubric | `cdd/release/SKILL.md` §3.8 (cnos #331 patch 5, commit `b27fc15`) | Shipped |
| Mechanical pre-merge gate (informs §5.2 limitations) | `cdd/release/SKILL.md` / `cdd/gamma/SKILL.md` (cnos #339, merged) | Shipped |
| Dispatch sizing (sister rule) | `cdd/CDD.md` §1.6c (cnos #338, merged) | Shipped |

## Cycle scope sizing (per cnos #334 heuristic)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | 0 — prose-only changes to 2 skill files | no |
| (b) Cross-module breadth | 2 files (`cdd/operator/SKILL.md` + `cdd/release/SKILL.md` §3.8 amendment) | low |
| (c) Lifecycle span | docs-only | no |
| (d) MCA preconditions | not MCA — design in body | n/a |
| (e) Independent shippability | §5 (new section) and §3.8 (grading-floor amendment) cohere as one feedback loop; the §3.8 amendment references the §5 configuration vocabulary | no |

**Decision:** keep whole. 6 ACs, mid-typical band (5–7). One file primary; one cross-reference amendment.

## Scope

**In scope:**

1. Add `cdd/operator/SKILL.md` **§5 Dispatch configurations** with three sub-sections:
   - **§5.1 Canonical multi-session dispatch.** Restate the existing model — `claude -p` per role, separate auth contexts, full γ/δ separation. Reference back to operator §1.2.
   - **§5.2 Single-session δ-as-γ via Agent tool (Claude Code activation).** Define when the operator is a Claude Code agent (one parent session). Sub-agents via the Agent tool are functionally equivalent to `claude -p` for role-isolation purposes (fresh context per sub-agent) but inherit MCP scope and filesystem from the parent. Name three structural consequences:
     - γ/δ separation collapses to δ=γ (one session selects, scaffolds, AND holds gates).
     - Sub-agent returns are summaries, not full transcripts; δ-as-γ verifies committed artifacts (β's `beta-review.md`) rather than the agent's return message.
     - Harness push restrictions surface as branch-name churn under fix-rounds; fresh-branch chains (`cycle/{N}` → `cycle/{N}-impl` → `cycle/{N}-impl-r2` → ...) are an acceptable workaround. Final main fast-forward becomes an external operator action.
   - **§5.3 Escalation criteria.** When to switch from §5.2 to §5.1: cycle is substantial (≥7 ACs OR new contract surface OR cross-repo deliverables); multiple γ judgment calls expected mid-cycle; β rounds likely >2; work spans repos with distinct auth scopes.

2. Amend `cdd/release/SKILL.md` **§3.8** (honest-grading rubric, cnos #331 patch 5) with a configuration-floor clause: cycles run under §5.2 (single-session δ-as-γ) cap the γ axis at **A−** regardless of execution quality, because γ/δ separation is structurally absent. Record the configuration explicitly in `gamma-closeout.md`.

3. Cross-references:
   - §5.1 / §5.2 / §5.3 mutually consistent
   - §5.2 references cnos #338 (sub-agent dispatch sizing per §1.6c)
   - §5.2 references cnos #339 (mechanical pre-merge gate — informs why operator-override on β R2 is sometimes the only path under §5.2)
   - §3.8 amendment references §5.2 by section number

**Out of scope:**

- Building tooling to detect which configuration a cycle ran under. Operator self-reports in `gamma-closeout.md`.
- Replacing §1.2 `claude -p` discussion. §5.2 is additive, not a replacement.
- Auto-grading enforcement of the §3.8 floor. The floor is operator-honest discipline.
- Cross-repo bundle conventions (already covered by cnos #331 patch 6 cross-repo trace structure).
- Backfilling §5.2 grading-floor application to cycles before this patch lands. Forward-only.
- Changes to the Agent tool semantics themselves (those are Claude Code's surface, not cdd's).

**Deferred:**

- Quantitative analysis of §5.2 vs §5.1 cycle outcomes (round counts, finding rates). Needs ≥10 cycles in each configuration with the round-count metrics from cnos #338. Filed separately when data accumulates.

## Acceptance criteria

### AC1: `cdd/operator/SKILL.md` §5 section added with three sub-sections

**Invariant:** `cdd/operator/SKILL.md` contains a level-2 heading `## 5 Dispatch configurations` with three sub-sections (`§5.1`, `§5.2`, `§5.3`). §5.1 restates the canonical multi-session model. §5.2 names the single-session δ-as-γ configuration with the three structural consequences (γ/δ collapse, summary-not-transcript returns, branch-name churn). §5.3 lists escalation criteria.
**Oracle:** `grep -nE "^## 5\.|^### 5\.[123]" src/packages/cnos.cdd/skills/cdd/operator/SKILL.md` returns 4 matches in correct ordering.
**Positive:** Section present; three sub-sections present; ordering correct.
**Negative:** Section missing OR sub-sections collapsed OR placed in wrong file.
**Surface:** `src/packages/cnos.cdd/skills/cdd/operator/SKILL.md`.

### AC2: §5.2 names three structural consequences explicitly

**Invariant:** §5.2 body explicitly names (a) γ/δ separation collapse, (b) sub-agent returns as summaries with artifact-canonical verification, (c) branch-name churn under harness push restrictions with fresh-branch fix-round chain as the workaround pattern.
**Oracle:** `grep -nE "γ/δ separation collapse|γ=δ collapse|δ=γ collapse|sub-agent return|branch-name churn|fresh-branch chain" src/packages/cnos.cdd/skills/cdd/operator/SKILL.md` matches 3+ items.
**Positive:** All three consequences explicit and discoverable by grep.
**Negative:** Any consequence absent OR named only in narrative without a flag-term grep can find.
**Surface:** `cdd/operator/SKILL.md` §5.2 body.

### AC3: §3.8 amended with configuration-floor clause

**Invariant:** `cdd/release/SKILL.md` §3.8 (honest-grading rubric) gains a clause: "Cycles run under `operator/SKILL.md` §5.2 (single-session δ-as-γ) cap the γ axis at A− regardless of execution quality, because γ/δ separation is structurally absent. The configuration must be recorded explicitly in `gamma-closeout.md`."
**Oracle:** `grep -nE "§5\.2|A− γ floor|cap.*A−" src/packages/cnos.cdd/skills/cdd/release/SKILL.md` matches in or near §3.8.
**Positive:** Clause present; section reference correct; rationale clear.
**Negative:** §3.8 unchanged OR clause buried so vaguely that the cap isn't operator-checkable.
**Surface:** `cdd/release/SKILL.md` §3.8.

### AC4: §5.3 escalation criteria are operator-actionable

**Invariant:** §5.3 lists 4 escalation triggers as bullet points, each phrased as a checkable condition (e.g., "≥7 ACs", "≥2 β rounds expected", "cross-repo deliverables", "≥3 γ judgment calls mid-cycle"). Operator can apply at γ scaffold time.
**Oracle:** §5.3 contains ≥4 bullet items, each starting with a quantifiable condition.
**Positive:** Triggers are concrete (numeric or boolean), not aspirational ("when it feels right").
**Negative:** Triggers are vague or fewer than 4.
**Surface:** `cdd/operator/SKILL.md` §5.3.

### AC5: Empirical anchor cited

**Invariant:** §5.2 cites the cnos-tsc supercycle and tsc cycle #32 as the empirical evidence for the configuration. Cites at least one specific branch trail (e.g., `cycle/32 → cycle/32-impl → cycle/32-impl-r2 → cycle/32-merged → cycle/32-final`) and at least one γ-closeout (e.g., tsc cycle #26 "operator (δ = γ in this two-agent configuration)").
**Oracle:** `grep -E "usurobor/tsc|cycle/32-impl|cycle 26 γ-closeout|δ.{0,3}=.{0,3}γ" src/packages/cnos.cdd/skills/cdd/operator/SKILL.md` matches.
**Positive:** Anchors present with reproducible references (commit SHAs, branch names, or close-out paths).
**Negative:** Configuration asserted without empirical citation.
**Surface:** `cdd/operator/SKILL.md` §5.2.

### AC6: Recursive coherence — this cycle's own configuration documented

**Invariant:** This very cycle's `gamma-closeout.md` declares which configuration (§5.1 or §5.2) the cycle ran under, applies the §3.8 floor accordingly to its own γ grade, and cites this issue's §5 as the canonical reference.
**Oracle:** Cycle's `gamma-closeout.md` contains a "Dispatch configuration" line naming §5.1 or §5.2; γ-axis grade respects the cap per §3.8 amendment.
**Positive:** Self-declaration present; grade compliant with the floor it introduces.
**Negative:** Configuration not declared OR γ grade above the cap with no override-rationale.
**Surface:** This cycle's `.cdd/releases/.../gamma-closeout.md` (post-merge).

## Proof plan

**Invariant:** cdd names the Claude Code single-session configuration explicitly; γ-axis grading floor reflects the structural difference; operators have a clear escalation path back to multi-session.
**Surface:** `src/packages/cnos.cdd/skills/cdd/operator/SKILL.md` (new §5); `src/packages/cnos.cdd/skills/cdd/release/SKILL.md` §3.8 (amendment).
**Oracle:** β reviews against AC1–AC6 oracles; β additionally applies rule 3.13 to this PR's own diff (recursive coherence — every claim about the §5.2 configuration must trace to an artifact in cnos-tsc supercycle or tsc cycle #32 close-outs).
**Positive case:** All six ACs pass; β confirms recursive-coherence check on the cycle's own configuration declaration.
**Negative case:** Any AC fails; OR the cycle introducing §5.2 itself fails to declare its configuration (recursive incoherence).
**Operator-visible projection:** Future cnos `gamma-closeout.md` files include a "Dispatch configuration" line. PRAs and INDEX.md rows can be filtered/grouped by configuration. Empirical comparison of §5.1 vs §5.2 cycle outcomes becomes possible after enough cycles accumulate.
**Known gap:** §5.2's three structural consequences are observational generalizations from N≈5 cycles. Quantitative validation (e.g., does δ=γ collapse correlate with higher review-round counts?) requires more data and is explicitly deferred.

## Skills to load

**Tier 3:**
- `cnos.core/skills/skill` — for skill-program/frontmatter coherence on the two modified SKILL.md files
- `cnos.eng/skills/eng/writing` — for prose patches

**Why:**
- Two prose-only files; no code, no runtime.

## Active design constraints

- **No frontmatter changes** to either modified SKILL.md file.
- **§5.2 is additive.** §5.1 (canonical multi-session) is unchanged; §5.2 is a parallel configuration option, not a replacement.
- **§3.8 amendment is forward-only.** Cycles before this patch lands keep their original grades; the floor applies from this cycle's merge forward.
- **Cite empirical anchors with reproducible references** — commit SHAs, branch names, close-out paths from cnos-tsc supercycle or tsc cycle #32.
- **Recursive coherence non-negotiable.** This cycle's own `gamma-closeout.md` MUST declare which configuration it ran under and apply the floor honestly to its own γ grade. β verifies as AC6.
- **Sub-agent return semantics:** §5.2 must clarify that the artifact β commits (`beta-review.md`) is canonical, not the sub-agent's return-message summary. This is the protocol invariant that makes §5.2 valid despite the summary-not-transcript limitation.

## Related artifacts

- `cdd/operator/SKILL.md` §1.2 (canonical `claude -p` dispatch) — what §5.1 restates
- `cdd/release/SKILL.md` §3.8 (cnos #331 patch 5) — target for amendment
- `cdd/post-release/SKILL.md` Step 5.6b (cnos #331 patch 6) — cdd-iteration.md schema; this cycle's findings track here
- `cdd/CDD.md` §1.6c (cnos #338) — dispatch sizing for sub-agents; sister rule
- `cdd/release/SKILL.md` mechanical pre-merge gate (cnos #339) — gate behavior informs §5.2 escalation triggers
- `usurobor/tsc:.cdd/releases/{0.5.0,0.6.0,0.7.0}/{24,25,26}/gamma-closeout.md` — empirical anchor for δ=γ pattern across the supercycle
- `usurobor/tsc:.cdd/releases/docs/2026-05-09/32/gamma-closeout.md` — empirical anchor for branch sprawl + δ=γ collapse
- `usurobor/tsc:.cdd/releases/docs/2026-05-09/32/cdd-iteration.md` F4 — environmental harness-403 finding; informs the branch-churn workaround narrative

## Non-goals

- Tooling to enforce the §3.8 floor automatically.
- Backfilling grades for cycles before this patch lands.
- Replacing `claude -p` semantics with Agent-tool semantics universally.
- Changes to Claude Code's Agent tool behavior or sub-agent context handling.
- Spec changes outside `src/packages/cnos.cdd/`.
- Cross-repo bundle conventions (already in cnos #331 patch 6).

## Success / closure condition

This issue is closeable when:
- AC1–AC6 each map to evidence in the branch diff.
- β applies rule 3.13 to this PR's own body and confirms every empirical claim traces to a reproducible source (commit SHA, branch trail, close-out path).
- This cycle's own `gamma-closeout.md` declares its dispatch configuration explicitly and applies the §3.8 floor to its own γ grade.
- The two cross-file references (§5.2 ↔ §3.8 amendment) are mutually consistent.
- Mode = `design-and-build`; disconnect via §2.5b at `.cdd/releases/docs/{ISO-date}/{N}/`.
- This cycle's own close-out follows full protocol (recursive coherence — does NOT repeat the partial-protocol pattern of cnos #331/#333/#334).
