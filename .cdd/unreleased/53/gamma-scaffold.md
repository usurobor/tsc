---
cycle: 53  
issue: #53
title: "S4: cross-target report surface (Operational §7.4)"
parent: #49 (master v0.10.0 canonical v3.2 scoring cutover)
role: gamma
---

# γ Scaffold — Cycle 53

## Scope

Cross-target report surface per Operational §7.4. Adds mechanical-first multi-target reporting with geometric aggregate calculation. Reporting-only surface without verdict changes.

**Gap selected under**: CDD §3.1 (master sub-issue dependency after #50 canonical aggregate).

## AC Mapping

| AC | Core surface | Evidence gate |
|---|---|---|  
| AC1 | Repeatable `--target` CLI + mechanical dispatch | CLI parser + help text + mode rejection tests |
| AC2 | Per-target mechanical path reuse | Target equality with single-target + duplicate rejection |
| AC3 | Geometric mean per Operational §7.4 | Unit test with fixture values + degeneracy handling |  
| AC4 | Cross-target JSON schema + provenance | Structural test + required fields enumeration |

## Active Skills (Tier 3)

- `cnos.eng/skills/eng/ocaml` — CLI parsing, target orchestration, aggregate helpers, JSON tests

## Dispatch Decision

**Shape**: Design-and-build (per §2 cycle scope sizing — requires #50 merged first, additive surface, no cross-target verdict gate)

**Blocking dependency**: #50 must land first for canonical aggregate fields (`C_Σ^num`, `C_Σ^math`) 
**Role sequencing**: α implementation → β review → γ close-out + merge
**Mode restriction**: Mechanical-only for this cycle; LLM/hybrid multi-target explicitly rejected with guidance

**Architecture leverage**: Reuses existing `Mechanical_scoring.score_bundle` + target registry; additive report surface only