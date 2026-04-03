# Documentation

TSC documentation follows the triadic structure it measures.

## Navigating by axis

### α — Pattern (articulation)

What TSC is. The theory, the scoring model, the glossary.

| Document | Location |
|----------|----------|
| C-equivalence | [spec/c-equiv.md](../spec/c-equiv.md) |
| Core axioms | [spec/tsc-core.md](../spec/tsc-core.md) |
| Operational rules | [spec/tsc-oper.md](../spec/tsc-oper.md) |
| Observation dynamics | [spec/tsc-observation-dynamics.md](../spec/tsc-observation-dynamics.md) |
| Glossary | [spec/tsc-glossary.md](../spec/tsc-glossary.md) |
| Scoring instruction | [runtime/SELF-MEASURE.md](../runtime/SELF-MEASURE.md) |

### β — Relation (coherence)

How the system fits together. Architecture, operations, configuration.

| Document | Location |
|----------|----------|
| Architecture | [ARCHITECTURE.md](../ARCHITECTURE.md) |
| Operator manual | [beta/guides/OPERATOR-MANUAL.md](beta/guides/OPERATOR-MANUAL.md) |
| Target model | [targets/README.md](../targets/README.md) |

### γ — Process (evolution)

How the system changes. Releases, design decisions, coherence tracking.

| Document | Location |
|----------|----------|
| Changelog | [CHANGELOG.md](../CHANGELOG.md) |
| Engine 0.1.0 design | [engine/0.1.0/DESIGN.md](engine/0.1.0/DESIGN.md) |
| Engine 0.1.0 plan | [engine/0.1.0/PLAN.md](engine/0.1.0/PLAN.md) |
| Engine 0.1.0 self-coherence | [engine/0.1.0/SELF-COHERENCE.md](engine/0.1.0/SELF-COHERENCE.md) |

## Pathways

**Understand TSC theory** — start with α: read `spec/c-equiv.md` → `tsc-core.md` → `tsc-oper.md`.

**Run the engine** — start with β: read the [operator manual](beta/guides/OPERATOR-MANUAL.md).

**Contribute** — start with γ: read the [architecture](../ARCHITECTURE.md), then the [engine design](engine/0.1.0/DESIGN.md).
