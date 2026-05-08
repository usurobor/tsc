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

## §Skills

**Tier 1:**
- `CDD.md` (v3.15.0) — canonical lifecycle and role contract
- `alpha/SKILL.md` — α role surface

**Tier 1b lifecycle:**
- `design/SKILL.md` — design artifact constraints (loaded; issue body serves as design)
- `plan/SKILL.md` — loaded; implementation order noted in §ACs evidence below

**Tier 2 (write):**
- `cnos.core/skills/write/SKILL.md`

**Tier 3 (issue-named):**
- `cdd/design` — interface design before implementation
- `cdd/plan` — implementation sequencing
