# TSC Status

**Software release:** 0.12.0
**Specification:** 4.0.0 Normative
**v4 conformance standing:** none

TSC's foundational measurement construct is under revision.

## Theory

`spec/` contains the normative TSC v4 specification. It defines typed articulation, open generators, candidate-fiber measurement, proof-carrying receipts, methodology authority, observation lineage, and conformance obligations.

The specification is normative as of the independently reviewed ratification-only commit; the ratification gate is defined in `spec/tsc-conformance.md` §8.

## Current engine

`engine/ocaml/` is the canonical executable of the existing repository-proxy methodology.

It implements the v3.2-era scoring and witness contract. It does **not** implement TSC v4 Core, Operational, or Conformance.

Current outputs are:

```text
structural-proxy and semantic-judgment regression results
```

They are not v4 coherence receipts.

## Current illustrations and katas

Katas test the current proxy engine. They do not establish the v4 measurement construct.

Philosophical examples are illustrations. They carry no normative v4 expected score.

The first v4 conformance fixtures are specified under `conformance/`. A specified fixture contributes no standing until its generator, oracle, evidence, and negative cases are implemented and verified.

## Evidence status

No current implementation has emitted a passing v4 conformance receipt.

A historical v2.3 braided witness emitted a failed receipt. The failure is retained and explicitly disposed in:

```text
docs/design/foundation-contract-reconciliation/CUTOVER-RECEIPT.md
```

## Read next

- [`spec/README.md`](spec/README.md) — authority and reading order
- [`docs/design/foundation-contract-reconciliation/DESIGN.md`](docs/design/foundation-contract-reconciliation/DESIGN.md) — revision motivation
- [`docs/design/foundation-contract-reconciliation/ARCHAEOLOGY.md`](docs/design/foundation-contract-reconciliation/ARCHAEOLOGY.md) — historical evidence
- [`spec/tsc-conformance.md`](spec/tsc-conformance.md) — proof obligations
