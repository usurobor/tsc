# TSC v4 Specifications

**Version:** 4.0.0
**Status:** Draft

TSC v4 defines coherence as a warranted relation among a concrete generator, its typed articulations, and evidence that tests how the generator continues under declared observations and interventions.

## Authority

The specification tree has four normative layers:

1. [`c-equiv.md`](c-equiv.md) defines typed articulation and generative unfolding.
2. [`tsc-core.md`](tsc-core.md) defines coherence receipts, candidate fibers, and result classes.
3. [`tsc-oper.md`](tsc-oper.md) defines compilation, assessment, admission, execution, and authority.
4. [`tsc-observation-dynamics.md`](tsc-observation-dynamics.md) defines lineage, uncertainty, comparison, intervention, and validated lift.

[`tsc-glossary.md`](tsc-glossary.md) is informative. It explains the shared vocabulary without adding rules.

## Reading order

Read the files in authority order. Each document states its own primitives and obligations; later layers use the contracts established by earlier layers.

## Core shape

```text
source CM
  → compiled methodology
  → bounded calibration
  → instrument assessment
  → admission decision
  → authorized execution
  → proof-carrying coherence receipt
```

A receipt retains the generator presentation, the relational atlas, candidate alternatives, continuation evidence, uncertainty, and standing. A scalar may summarize a receipt only after those distinctions have been preserved.

## Conformance

A v4 implementation is conforming only when it can:

- reject ill-typed articulation events;
- preserve relations and paths through execution;
- distinguish no realization from underdetermination and unresolved search;
- test lawful continuation with held-out observation or intervention;
- refuse incomplete or out-of-domain input;
- keep compilation, assessment, admission, and execution as separate authority surfaces;
- emit a reproducible receipt whose claims trace to evidence.
