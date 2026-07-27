# TSC Foundation Cutover Receipt

**Status:** Design evidence
**Target:** TSC specification 4.0.0
**Purpose:** Dispose of prior failed claims without transferring standing to successor claims

## Governing question

> What is the explicit lineage relation between failed or invalidated claims inherited from earlier foundations and the new claims made by v4?

This receipt applies the failure-persistence contract before v4 requests authority.

## 1 · v2 braided-interchange claim

```text
prior_claim_id: tsc-v2/c-equiv/C5-braided-interchange
prior_receipt: v2.3 braided witness baseline
result: FAIL
observed: 92% of extracted equations did not normalize
```

### Disposition

```text
disposition: CLAIM_WITHDRAWN
```

v4 does not make braided interchange a universal foundation law.

The failed receipt remains evidence that the v2 implementation did not discharge the axiom it claimed to witness. This disposition does not assert that braided interchange is mathematically false.

Any later CM declaring a braided or hexagon law creates a new claim with new conformance evidence.

## 2 · v3 evaluator-independence claim

```text
prior_claim_id: tsc-v3/c-equiv/evaluator-independence
prior_evidence: target-monoid non-isomorphism by idempotent profile
```

### Disposition

```text
disposition: INVALIDATED
```

The proof established target-monoid non-isomorphism. It did not establish evaluator-level informational independence.

The v3 γ evaluator reduced to atom count, and α factored through γ. The stated evidence therefore did not prove the stated evaluator claim.

## 3 · v4 receipt non-substitutability

```text
new_claim_id: tsc-v4/core/receipt-non-substitutability
inherited_standing: none
```

v4 does not inherit authority from the invalidated v3 claim.

The new claim is narrower:

> α, β, and γ are differently typed proof obligations. No receipt can discharge another receipt's obligation.

It must be established by:

```text
distinct receipt schemas
dependency envelopes
positive dependency path
α-blocking negative case
β-globalization negative case
γ-law-violation negative case
```

The canonical requirement is `CORE-RECEIPT-001`.

## 4 · v2 tolerant-finality theorem sketch

```text
prior_claim_id: tsc-v2/core/tolerant-finality
prior_status: theorem sketch
```

### Disposition

```text
disposition: UNRESOLVED
```

v4 does not treat the sketch as a completed construction or as evidence for the exact Set theorem.

The deterministic Set kernel now carries a separate exact final-coalgebra construction. The metric tolerant-finality research program remains unresolved. A future non-Set or tolerant claim supplies its own complete functor, category, convergence assumptions, universal-property statement, and conformance evidence.

## 5 · Authority and standing

This cutover receipt grants no implementation or methodology standing to v4.

```text
v4 specification status: Draft pending ratification review
v4 implementation conformance: none
v4 methodology standing: none
```

Specification authority may begin through the document-ratification gate. Implementation conformance and methodology standing begin only when the applicable requirements are implemented, executed, reproducible, and independently reviewed.
