# cdd/gamma: Add §γ-scaffold-time peer-enumeration invariant (prevent false-gap cycles)

**Labels:** `docs, P2, cdd`
**Priority:** P2 — closes a γ-side recon gap that mirrors α's rule 3.13(a) reproducibility constraint on the gap-side. Real-world cost demonstrated on tsc cycle #36 where the cycle shipped on a false-gap premise that 30 seconds of `grep` would have surfaced.
**Status:** Drafted; ready for cycle dispatch.
**Mode:** `docs-only, design-and-build` — adds one section to `cdd/gamma/SKILL.md`; references rule 3.13 in `cdd/review/SKILL.md`.
**Depends on:** none.

## Problem

**What exists:** `cdd/gamma/SKILL.md` prescribes scaffold-time responsibilities for γ — author `self-coherence.md` with §Gap, §Mode, §Cycle scope sizing, §ACs, §CDD Trace. The §Gap section is the cycle's first claim: "X does not exist / is not wired / is missing." Today there is no mechanical discipline requiring γ to *verify* that claim before authoring it. α has rule 3.13 (cnos #331 patch 1) for honest-claim verification on the *fix* side; γ has no equivalent on the *gap* side.

**What is expected:** Before authoring §Gap, γ must peer-enumerate every file in the directories named by the issue's impact graph and grep for the surface the cycle proposes to add or change. A §Gap that asserts "X does not exist" without grep-evidence is a γ-side honest-claim violation analogous to α rule 3.13(a). The discipline is symmetric: every claim subject to verification, whether it's a positive ("X is wired into Y") or a negative ("X is not wired into Y").

**Where they diverge:** Empirically observed on tsc cycle #36. The cycle's §Gap asserted "CI does not invoke `coh --kata` against shipped kata content." `.github/workflows/ci.yml` had a `kata-check` job (added in 344-c) invoking `bash scripts/run-katas.sh` which auto-discovers and runs every kata. The negation was empirically false from the moment it was written. β R1 caught it as binding finding B-1 (RC verdict). α R2 had to consolidate the parallel surface (Path A — delete the existing `kata-check`; keep the new dedicated workflow). The fix-round was avoidable if γ had grep'd `.github/workflows/` before scaffolding.

## Impact

- **Misframed cycles waste a review round.** tsc #36 cost one full β R1 + α R2 + β R2 sequence to land what could have been correctly framed at scaffold time. Same prevention shape as α's rule 3.13 — both rules are catch-it-early disciplines.
- **γ-grade discipline is currently uncalibrated.** The honest-grading rubric (§3.8) grades γ on coordination quality and recursive coherence, but does not name peer-enumeration as a γ-axis competency. Adding the invariant gives β a structural surface to grade against.
- **Recursive coherence.** α has rule 3.13 for honest-claim on the implementation side; γ should have its symmetric rule on the gap-claim side. Today's asymmetry is a protocol-coherence gap — the rule cdd applies to itself should match the rule cdd applies to α.
- **Cross-protocol propagation.** When cdw (writing protocol per `cnos:ROLES.md` §5) is implemented, its γ-equivalent inherits this gap unless it's named here at the generic-pattern level. Patching `cdd/gamma/SKILL.md` now is the cheapest place to fix it.

## Status truth

| Surface | Status | Notes |
|---|---|---|
| α rule 3.13 honest-claim (cnos #331 patch 1) | Shipped | Implementation-side discipline |
| γ peer-enumeration invariant at scaffold time | NOT NAMED | This proposal |
| §3.8 γ-axis grade rubric named against peer-enumeration | Implicit | γ-axis grading currently silent on this |
| Empirical evidence — false-gap cost | tsc cycle #36 cdd-iteration F1 | Shipped (`usurobor/tsc:.cdd/releases/docs/2026-05-12/36/cdd-iteration.md`) |
| `cdd/review/SKILL.md` rule 3.13 symmetry | Shipped (α side); proposal extends to γ side | Cross-reference needed |

## Source of truth

| Claim / surface | Canonical source | Status |
|---|---|---|
| α rule 3.13 | `cdd/review/SKILL.md` §3.13 (cnos #331 patch 1, commit `e794b4a`) | Shipped |
| γ scaffold responsibilities | `cdd/gamma/SKILL.md` §scaffold-time | Shipped |
| Empirical false-gap evidence | `usurobor/tsc:.cdd/releases/docs/2026-05-12/36/cdd-iteration.md` §F1 | Shipped |
| §3.8 honest-grading rubric | `cdd/release/SKILL.md` §3.8 (cnos #331 patch 5) | Shipped |
| Cycle #36 β R1 catch | `usurobor/tsc:.cdd/releases/docs/2026-05-12/36/beta-review.md` finding B-1 | Shipped |

## Cycle scope sizing (per cnos §1.6c heuristic)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | 0 — prose section in one skill file + cross-reference | no |
| (b) Cross-module breadth | `cdd/gamma/SKILL.md` primary + cross-ref insert in `cdd/review/SKILL.md` | low |
| (c) Lifecycle span | docs-only | no |
| (d) MCA preconditions | not MCA — design fixed in body | n/a |
| (e) Independent shippability | one cohesive invariant addition | no |

**Decision:** keep whole. 4 ACs, low-typical band. Small mechanical cycle.

## Scope

**In scope:**

1. **Add `cdd/gamma/SKILL.md §Peer enumeration at scaffold time`** (or §γ-scaffold-time invariants, named per Cycle A's preference). Contents:
   > Before authoring §Gap in `self-coherence.md`, γ MUST:
   > 1. List every file in the directories named by the issue's impact graph (`ls -la` or `find` per directory).
   > 2. Grep for the term / symbol / surface the cycle proposes to add or change (`rg <term> <directories>`).
   > 3. If any match is found, name it explicitly in §Gap:
   >    - "This gap is partially closed by X; this cycle completes it" (additive framing), OR
   >    - "X overlaps the proposed surface and must be reconciled in scope" (consolidation framing)
   >
   > A §Gap that asserts "X does not exist" without grep-evidence is a γ-side honest-claim violation analogous to α's rule 3.13(a) reproducibility constraint.

2. **Add cross-reference in `cdd/review/SKILL.md` §3.13** — name that γ peer-enumeration is the symmetric rule on the gap-side. When β finds an existing surface that the cycle's §Gap claimed didn't exist, the finding is binding (B-severity minimum) and attributes to γ axis, not α.

3. **Update `cdd/release/SKILL.md` §3.8 honest-grading rubric** — γ axis includes peer-enumeration discipline. A cycle that ships on a false-gap premise (regardless of whether β catches it) costs the γ axis grade at least one band.

4. **Self-application via worked example.** Reference tsc cycle #36 in the §Peer enumeration section as the empirical anchor — name the failure mode, the cost (1 wasted RC round), the fix (Path A consolidation), and the β-rescue.

**Out of scope:**

- Mechanical enforcement (linter / hook that runs grep against impact graph automatically). Out of scope; prose-only invariant.
- α-side gap claims (α doesn't author §Gap; this is purely γ-side).
- cdw / future c-d-X protocol extensions (separate cycles per `cnos:ROLES.md` §6).
- Pre-existing cycles' §Gap re-audit (forward-only; history immutable per the migration discipline).

## Acceptance Criteria

**AC1 — `cdd/gamma/SKILL.md` gains §Peer enumeration section.** New section present with the 3-step procedure and the explicit honest-claim framing.

- *Invariant:* section names ≥3 mechanical steps (list / grep / decide).
- *Oracle:* `rg '^## §Peer enumeration' cnos:cdd/gamma/SKILL.md` returns 1 hit.
- *Positive:* a γ reading the section knows exactly what commands to run before authoring §Gap.
- *Negative:* no soft "γ should consider" prose without mechanical steps.
- *Surface:* `cnos:cdd/gamma/SKILL.md`.

**AC2 — `cdd/review/SKILL.md` §3.13 cross-references γ peer-enumeration.** Rule 3.13 (or a new §3.13a / §3.14) names that gap-side claims are symmetric with α-side claims; β findings against §Gap framing attribute to γ axis.

- *Invariant:* cross-ref present; one β-grading rule emitted naming γ-axis attribution.
- *Oracle:* `rg 'peer.enumeration|gap.side.*claim' cnos:cdd/review/SKILL.md` returns ≥1 hit.
- *Positive:* β reviewers know to grade against §Gap framing as a γ-axis concern.
- *Negative:* §3.13 stays α-only-coded.
- *Surface:* `cnos:cdd/review/SKILL.md`.

**AC3 — `cdd/release/SKILL.md` §3.8 rubric names γ peer-enumeration competency.** γ-axis grading bands explicitly include peer-enumeration discipline as a downward signal.

- *Invariant:* one rubric clause names false-gap cycles as a γ-axis grade penalty.
- *Oracle:* `rg 'false.gap|peer.enumeration' cnos:cdd/release/SKILL.md` returns ≥1 hit in §3.8 vicinity.
- *Positive:* the rubric language matches tsc #36's γ B grade reasoning.
- *Negative:* §3.8 γ-axis stays purely subjective.
- *Surface:* `cnos:cdd/release/SKILL.md`.

**AC4 — Worked example references tsc #36.** §Peer enumeration carries a 1–3 sentence empirical anchor naming tsc cycle #36, the false-gap, the cost (1 RC round), the fix (Path A consolidation), and β's catch.

- *Invariant:* example present with named cycle + named cost.
- *Oracle:* `rg 'tsc.36|cycle.36' cnos:cdd/gamma/SKILL.md` returns ≥1 hit.
- *Positive:* future γ reading the example understands the failure pattern viscerally.
- *Negative:* abstract-only prescription with no real-world referent.
- *Surface:* `cnos:cdd/gamma/SKILL.md`.

## Proof plan

1. Draft §Peer enumeration section per AC1 prescription.
2. Add cross-reference in `cdd/review/SKILL.md` §3.13 per AC2.
3. Add §3.8 γ-axis rubric clause per AC3.
4. Self-apply: the patch-landing cycle's γ runs the new §Peer enumeration steps against its own scaffold; records the self-application in cycle close-out.
5. Close out; cdd-iteration captures whether the new rule caught any pre-existing false-gap framing in cnos.

## Risks

- **Bureaucratic creep.** Adding mechanical steps to γ's pre-scaffold flow could slow cycles. Mitigation: the steps are 3 commands and <1 minute of effort. Cost-benefit clearly positive given the 1-RC-round cost of false-gaps.
- **Grep coverage gaps.** Some gaps live in semantics, not text — a §Gap claim like "engine doesn't handle case X" can't be grep'd directly. Mitigation: the rule applies to surface/wiring/file-existence claims; semantic claims fall outside but are also caught by α rule 3.13 at implementation time.
- **Over-attribution to γ.** Not every false-gap is γ's fault — sometimes the issue body itself is wrong. Mitigation: the rule says γ MUST peer-enumerate before authoring §Gap; if the issue body was wrong, γ either fixes it or rejects the cycle. Final §Gap is γ's claim.

## Open questions

1. **Section name in `cdd/gamma/SKILL.md`.** `§Peer enumeration at scaffold time` / `§γ-scaffold-time invariants` / `§Gap verification`? — *Recommendation:* `§Peer enumeration at scaffold time` — descriptive and matches the language used in α rule 3.13 ("verification").
2. **Severity floor for false-gap finding in `cdd/review/SKILL.md`.** B-severity minimum (per tsc #36's β R1)? Or A if the cycle is mid-stream irrecoverable? — *Recommendation:* B-severity minimum; A only if the false-gap cannot be reconciled in fix-round (e.g., the cycle's core premise is wrong, not just a scope detail).
3. **Cycle migration.** Existing skills (`cdd/issue/SKILL.md` has a §scope template, `cdd/CDD.md` has a scaffold checklist) — should §Peer enumeration be cross-referenced from those? — *Recommendation:* yes, one-line cross-ref in `cdd/issue/SKILL.md` minimal-output template ("γ verifies before authoring") and `cdd/CDD.md` step list.
4. **Self-application discipline.** Should the patch-landing cycle's `self-coherence.md` carry an explicit "§Peer-enumeration run" subsection demonstrating the new discipline? — *Recommendation:* yes, as an AC; future cycles can drop the explicit subsection once it's habitual.

## References

- tsc cycle #36 cdd-iteration F1 — `usurobor/tsc:.cdd/releases/docs/2026-05-12/36/cdd-iteration.md`
- tsc #36 β R1 finding B-1 — `usurobor/tsc:.cdd/releases/docs/2026-05-12/36/beta-review.md`
- cnos rule 3.13 (α honest-claim) — `cdd/review/SKILL.md` (cnos #331 patch 1, commit `e794b4a`)
- §3.8 honest-grading rubric — `cdd/release/SKILL.md` (cnos #331 patch 5, commit `b27fc15`)
- `cnos:ROLES.md` — generic role pattern (γ/δ/ε shared across protocols)
