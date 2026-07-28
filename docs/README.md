# Docs

Start with [`THESIS.md`](THESIS.md), then read [`../spec/README.md`](../spec/README.md).

The documentation tree follows the system in [`beta/governance/DOCUMENTATION-SYSTEM.md`](beta/governance/DOCUMENTATION-SYSTEM.md).

## Current authority

| Question | Source |
|---|---|
| What does TSC 4.1 mean? | [`../spec/README.md`](../spec/README.md) |
| What must a 4.1 implementation prove? | [`../spec/tsc-conformance.md`](../spec/tsc-conformance.md) |
| Why did the foundation change? | [`design/foundation-contract-reconciliation/DESIGN.md`](design/foundation-contract-reconciliation/DESIGN.md) |
| What is the current executable? | [`../engine/ocaml/CONTRACT.md`](../engine/ocaml/CONTRACT.md) |
| What is currently runnable? | [`../QUICKSTART.md`](../QUICKSTART.md) |

## Bundles

| Bundle | Purpose |
|---|---|
| [`alpha/doctrine/`](alpha/doctrine/) | Specification reading map and frozen historical theory records |
| [`alpha/engine/`](alpha/engine/) | Current repository-proxy engine records |
| [`beta/guides/`](beta/guides/) | Current operator guides |
| [`design/foundation-contract-reconciliation/`](design/foundation-contract-reconciliation/) | v4 foundation design, archaeology, cutover receipt, and review response |
| [`design/polar-expression-recovery/`](design/polar-expression-recovery/) | 4.1 polar-language design and impact contract |

## Status boundary

The draft 4.1 specification and the current 0.12.0 proxy engine are different surfaces. Historical self-coherence reports and proxy scores retain the semantics of the instruments that produced them; they do not acquire v4 meaning retroactively.
