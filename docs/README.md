# Documentation

This tree is organized by **reader intent**: each document answers one human need. Topics are navigated through this portal and through program maps, not by physical co-location. This follows the accepted [repository-planes decision](architecture/decisions/repository-planes.md): α/β/γ is TSC's measurement and role grammar — never a filing taxonomy.

## I want to…

| I want to… | Go to |
|---|---|
| Understand the idea in plain language | [`THESIS.md`](THESIS.md) |
| Know what TSC *is*, where it's going, and its current state | [`product/`](product/) — [`NORTH-STAR.md`](product/NORTH-STAR.md) · [`DIRECTION.md`](product/DIRECTION.md) · [`ADOPTION.md`](product/ADOPTION.md) · [`STATE.md`](product/STATE.md) |
| Try the current CLI | [`quickstart/README.md`](quickstart/README.md) |
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
| Why did the foundation change? | [`evidence/foundation-v4-reconciliation/DESIGN.md`](evidence/foundation-v4-reconciliation/DESIGN.md) |
| What is the current executable? | [`../src/engine/ocaml/CONTRACT.md`](../src/engine/ocaml/CONTRACT.md) |
| What is currently runnable? | [`quickstart/README.md`](quickstart/README.md) |
| What is the detailed project status? | [`../STATUS.md`](../STATUS.md) |

## Design records

| Bundle | Purpose |
|---|---|
| [`architecture/decisions/`](architecture/decisions/) | Accepted architecture decisions |
| [`evidence/foundation-v4-reconciliation/`](evidence/foundation-v4-reconciliation/) | Evidence for the ratified v4 foundation: design, archaeology, cutover receipt, and review responses |
| [`../research/foundation/polar-expression-recovery/`](../research/foundation/polar-expression-recovery/) | Pre-normative research for the 4.1 polar-language design and impact contract |

## A note on history

The project once filed documentation under `α/β/γ` role trees. Those snapshots were retired from the tree and remain in Git history; their still-live material was rehomed by reader intent (see the table above).

## Status boundary

The draft 4.1 specification and the current 0.12.0 proxy engine are different surfaces. Historical self-coherence reports and proxy scores retain the semantics of the instruments that produced them; they do not acquire v4 meaning retroactively.
