# TSC Status

**Software release:** 0.12.0
**Specification:** 4.1.0 Draft
**Last ratified specification:** 4.0.0 Normative ([readable at commit `4da1122`](https://github.com/usurobor/tsc/tree/4da1122/spec))
**4.1 conformance standing:** none

TSC 4.1.0 is a Draft candidate: it extends the ratified 4.0.0 Normative foundation with polar-expression recovery. 4.0.0 remains the last ratified contract until 4.1 passes foundation and repository review and a ratification-only commit is independently reviewed. No engine or methodology conforms to 4.1 yet.

The ratified foundation is the current normative warrant infrastructure.

## Theory

`spec/` contains the draft TSC 4.1 specification. It defines typed articulation, open generators, candidate-fiber measurement, proof-carrying receipts, methodology authority, observation lineage, and conformance obligations.

The 4.1 specification is not normative until the ratification gate in `spec/tsc-conformance.md` §8 closes. The polar-expression fixtures are specified but unimplemented.

## Current engine

`src/engine/ocaml/` is the canonical executable of the existing repository-proxy methodology.

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

No current implementation has emitted a passing TSC 4.1 conformance receipt.

## Read next

- [`spec/README.md`](spec/README.md) — authority and reading order
- [`docs/design/foundation-contract-reconciliation/DESIGN.md`](docs/design/foundation-contract-reconciliation/DESIGN.md) — revision motivation
- [`docs/design/foundation-contract-reconciliation/ARCHAEOLOGY.md`](docs/design/foundation-contract-reconciliation/ARCHAEOLOGY.md) — historical evidence
- [`spec/tsc-conformance.md`](spec/tsc-conformance.md) — proof obligations

## Program priority

Articulation Ascent is the primary program for the current bounded sprint. It lives in [`research/ascent/`](research/ascent/), which defines its program vocabulary; the TSC terms below (candidate fibers, warrant classes, refusal, evidence lineage) are defined in the [glossary](spec/tsc-glossary.md).

C≡ will provide its expression language. Articulation Ascent will perform
autonomous frame compilation, closure inversion, and polar lift. TSC
provides the warrant infrastructure: candidate fibers, comparison,
warrant classes, refusal, and evidence lineage.

Body Space is retained as a candidate empirical domain after the method
demonstrates basic discrimination, calibrated refusal, and non-decorative
lift generation. Existing TSC conformance work and the Body Space
registered report are preserved, but they are not on the critical path
for this sprint.
