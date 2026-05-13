---
cycle: 50
issue: #50 
title: "S1: canonical aggregate + report schema replacement"
parent: #49 (master v0.10.0 canonical v3.2 scoring cutover)
role: gamma
---

# γ Scaffold — Cycle 50

## Scope

Foundation sub-issue for v0.10.0 cutover. Cuts engine from arithmetic aggregate reporting to canonical v3.2 geometric aggregate reporting. Core aggregate/report contract for downstream cycles #51-#54.

**Gap selected under**: CDD §3.1 (P1 foundation + blocking dependency for sibling sub-issues).

## AC Mapping

| AC | Core surface | Evidence gate |
|---|---|---|
| AC1 | Public JSON schema — no flat `c_sigma` | Schema fixture + JSON writer tests |
| AC2 | Production routing to `Coherence.aggregate` | Code inspection + geometric vs arithmetic test |
| AC3 | Comparison deltas by form (`delta_c_sigma_num`) | Mechanical JSON + schema |
| AC4 | Gauge witness canonical aggregate | Production call site grep + W2 test |
| AC5 | Text + kata canonical names | `Report.to_text` + kata runner |

## Active Skills (Tier 3)

- `cnos.eng/skills/eng/ocaml` — multi-module type/interface changes, JSON fixture discipline

## Dispatch Decision

**Shape**: Design-and-build (per §2 cycle scope sizing — no stable plan artifact; breadth signal present but splitting would create incompatible intermediate schemas)

**Role sequencing**: α implementation → β review → γ close-out + merge
**Blocking for**: #51 (LLM validation), #52 (OOD), #53 (cross-target), #54 (cleanup) — all require settled aggregate contract

**Risk**: Proxy push-block encountered during implementation; recovery via sibling branch pattern applied