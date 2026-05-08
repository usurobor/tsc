---
cycle: 24
issue: "Sub 1 (#23): Implement TSC spec v3.2.0 in the OCaml engine"
branch: cycle/24-v320-engine
phase: in-progress
role: alpha
---

# Cycle 24 — Self-Coherence

**Gap:** Engine v0.4.0 uses `runtime/SELF-MEASURE.md` to ask an LLM for α/β/γ in [0,1] and computes `C_Σ = (s_α·s_β·s_γ)^(1/3)` directly. No barrier transform (`φ(δ) = δ/(1−δ)`), no discrepancy energy `D`, no `Coh = exp(−D)`, no math/num aggregate split, no `L_link(λ)` case-split, no W2 ref+spread, no v3.2.0 provenance JSON. Every section of `spec/tsc-core.md` v3.2.0 §3.2, §5, §7.1, §9 P5 has no code analogue.

**Mode:** MCA — substantial implementation cycle (OCaml engine + SELF-MEASURE.md rewrite).

**Active Skills:**
- Tier 1: CDD.md, alpha/SKILL.md
- Tier 2: write/SKILL.md
- Tier 3: cdd/design, cdd/plan

## §ACs

| AC | Status | Evidence |
|----|--------|----------|
| AC1 — Barrier transform in code | Not started | |
| AC2 — L_link case-split | Not started | |
| AC3 — Math/num aggregate split | Not started | |
| AC4 — W2 ref+spread | Not started | |
| AC5 — Provenance JSON v3.2.0 | Not started | |
| AC6 — SELF-MEASURE.md rewritten for v3.2.0 | Not started | |
| AC7 — OOD cutover guard | Not started | |

## §Self-check

<!-- α fills this in before signaling review-readiness -->

## §Debt

<!-- α names any deferred items, known gaps, or explicit out-of-scope decisions here -->

## CDD Trace

| Step | Artifact | Skills loaded | Decision |
|------|----------|---------------|----------|
| 0 Observe | — | — | Gap: v3.2.0 spec shipped; engine still uses v3.1-era LLM-only scoring without barrier transform, math/num split, L_link, W2 ref+spread, or provenance JSON. |
| 1 Select | Issue #24 | — | Gap selected per CDD §3 (master #23 cannot close while Sub 1 open; P1). |
| 2 Branch | cycle/24-v320-engine | cdd | Branch created by γ from origin/main (52d0387), pre-flight passed: no prior origin/cycle/24* branch, no stalled .cdd/unreleased/24/ on main. |
| 3 Bootstrap | `.cdd/unreleased/24/self-coherence.md` scaffold | cdd | Scaffold committed by γ at branch creation. |

## Review-readiness | round 1

<!-- α fills this in when ready for β review -->
