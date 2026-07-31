# Documentation

This tree is organized by **reader intent**: each document answers one human need. Topics are navigated through this portal and through program maps, not by physical co-location. This follows the accepted [repository-planes decision](architecture/decisions/repository-planes.md): α/β/γ is TSC's measurement and role grammar — never a filing taxonomy.

## I want to…

| I want to… | Go to |
|---|---|
| Understand the idea in plain language | [`THESIS.md`](THESIS.md) |
| Try the current CLI | [`../QUICKSTART.md`](../QUICKSTART.md) |
| Read the specification | [`../spec/README.md`](../spec/README.md) |
| Follow the current research program | [`../research/ascent/README.md`](../research/ascent/README.md) |
| See how architecture decisions were made | [`architecture/decisions/`](architecture/decisions/) |
| Work through worked concepts and examples | [`concepts/illustrations/README.md`](concepts/illustrations/README.md) |
| Contribute | [`../CONTRIBUTING.md`](../CONTRIBUTING.md) |

## Authority by question

| Question | Source |
|---|---|
| What does TSC 4.1 mean? | [`../spec/README.md`](../spec/README.md) |
| What must a 4.1 implementation prove? | [`../spec/tsc-conformance.md`](../spec/tsc-conformance.md) |
| Why did the foundation change? | [`design/foundation-contract-reconciliation/DESIGN.md`](design/foundation-contract-reconciliation/DESIGN.md) |
| What is the current executable? | [`../src/engine/ocaml/CONTRACT.md`](../src/engine/ocaml/CONTRACT.md) |
| What is currently runnable? | [`../QUICKSTART.md`](../QUICKSTART.md) |
| What is the detailed project status? | [`../STATUS.md`](../STATUS.md) |

## Design records

| Bundle | Purpose |
|---|---|
| [`architecture/decisions/`](architecture/decisions/) | Accepted architecture decisions |
| [`design/foundation-contract-reconciliation/`](design/foundation-contract-reconciliation/) | v4 foundation design, archaeology, cutover receipt, and review responses |
| [`design/polar-expression-recovery/`](design/polar-expression-recovery/) | 4.1 polar-language design and impact contract |

## A note on history

Earlier α/β/γ documentation snapshots are retained under `docs/alpha/`, `docs/beta/`, and `docs/gamma/`, and in git history. They record how the project once filed its documents. They are retained prior-cycle snapshots, and none are entry points for a newcomer — start from the intent table above instead. One exception is `docs/beta/governance/`, which is not frozen history but a live input the engine and CI still consume.

## Status boundary

The draft 4.1 specification and the current 0.12.0 proxy engine are different surfaces. Historical self-coherence reports and proxy scores retain the semantics of the instruments that produced them; they do not acquire v4 meaning retroactively.
