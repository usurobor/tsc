# TSC v4.1 Specifications

**Version:** 4.1.0
**Status:** Draft

TSC defines coherence as a warranted relation among an optional polar source, a concrete generator, its typed articulations, and evidence that tests how the generator continues under declared observations and interventions.

## Authority

The semantic specification has four layers.

1. [`c-equiv.md`](c-equiv.md) defines the polar expression calculus, typed articulation, open generators, and exact deterministic Set behavior.
2. [`tsc-core.md`](tsc-core.md) defines measurement contexts, behavior contracts, joint realization fibers, structured receipts, and result classes.
3. [`tsc-oper.md`](tsc-oper.md) defines methodology compilation, assessment, admission, authorization, execution, and refusal.
4. [`tsc-observation-dynamics.md`](tsc-observation-dynamics.md) defines lineage, dependence, comparison, intervention, refinement, lift, and failure persistence.

[`tsc-conformance.md`](tsc-conformance.md) is the normative proof authority. It assigns requirement IDs and states what an implementation or fixture must prove. It does not redefine the semantic layers.

[`tsc-glossary.md`](tsc-glossary.md) is informative. The normative specifications govern when the glossary differs.

## Reading order

```text
C≡ foundation
  → Core measurement semantics
  → Operational lifecycle
  → Observation Dynamics
  → Conformance obligations
```

Each document defines its primitives before using them. Later layers depend on earlier contracts; earlier layers do not depend on later measurement policy.

## Core shape

```text
CM source
  → compiled methodology
  → bounded calibration
  → instrument assessment
  → admission verdict
  → boundary authorization
  → target execution
  → proof-carrying coherence receipt
```

A receipt retains the polar source and realization evidence when present, concrete generator presentation, behavior contract, observations, relational atlas, candidate alternatives, continuation evidence, uncertainty, lineage, and standing. A scalar may summarize a receipt only after categorical status has been preserved.

## Version domains

TSC keeps separate version lineages for:

```text
specification
software / engine
methodology
receipt schema
```

A change in one lineage does not imply a change in another.

## Design evidence

The motivation, symbol migration, and impact graph live in [`../docs/design/foundation-contract-reconciliation/DESIGN.md`](../docs/design/foundation-contract-reconciliation/DESIGN.md).

The verified project archaeology lives in [`../docs/design/foundation-contract-reconciliation/ARCHAEOLOGY.md`](../docs/design/foundation-contract-reconciliation/ARCHAEOLOGY.md).

The first explicit dispositions of prior failed claims live in [`../docs/design/foundation-contract-reconciliation/CUTOVER-RECEIPT.md`](../docs/design/foundation-contract-reconciliation/CUTOVER-RECEIPT.md).

The polar-expression recovery rationale and impact graph live in [`../docs/design/polar-expression-recovery/DESIGN.md`](../docs/design/polar-expression-recovery/DESIGN.md).

These documents explain the revision. They do not override the normative definitions.

## Ratification

`Status: Draft` remains binding until:

1. every semantic layer is internally complete and cross-referenced;
2. every enduring conformance requirement has an owner and specified positive/negative oracle;
3. registered fixture contracts cover the requirements without claiming unrun results;
4. consumer and implementation-status surfaces are truthful;
5. independent mathematical and document review reports no unresolved findings;
6. a ratification-only commit changes normative headers to `Status: Normative`;
7. that final commit is reviewed before merge.

Specification ratification does not imply that an engine or methodology conforms. Implementation conformance begins only when applicable fixtures are implemented, executed, reproducible, and verified against the reviewed implementation digest.
