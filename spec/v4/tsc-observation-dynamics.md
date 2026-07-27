# TSC Observation Dynamics v2.0.0-alpha.1 — Receipt Lineage, Comparison, and Lift

**Version:** 2.0.0-alpha.1
**Date:** July 2026
**Status:** Draft
**Depends on:** C≡ v4 alpha; TSC Core v4 alpha; TSC Operational v4 alpha

---

## 0. Purpose

Observation Dynamics v2 governs relations **between** proof-carrying TSC receipts.

It answers:

- when two measurements are semantically comparable;
- what changed in the concrete presentation, behavior, evidence, or methodology;
- whether a candidate fiber narrowed, widened, disappeared, or merely became harder to search;
- whether a model lift was validated;
- how interventions, uncertainty, dependence, and grounding survive comparison.

It does not treat subtraction of two scalar summaries as a complete comparison.

---

## 1. Receipt identity

A receipt identity includes:

```text
receipt schema/version
CM identity/version/digest
compiled CM digest
input and coverage digests
query/intervention regime
carrier/finality or approximation regime
generator class and complexity representation
equivalence and behavioral metric
tolerance calculus
standing
```

Changing any load-bearing member creates a new measurement regime unless an explicit migration map proves compatibility.

---

## 2. Comparison admissibility

Two receipts are directly comparable only when all required relations are available:

```text
CM semantic compatibility
input-scope compatibility
observation-construction compatibility
generator-class relation
query/intervention relation
equivalence/metric relation
tolerance relation
standing relation
coverage and provenance availability
```

Result:

```text
COMPARABLE
COMPARABLE_WITH_MIGRATION
INCOMPARABLE
UNRESOLVED_COMPARABILITY
```

A comparison refusal explains the first missing or incompatible obligation and retains all additional diagnostics.

---

## 3. Presentation and behavior lineage

A comparison retains two lineages:

### 3.1 Presentation lineage

```text
state/model schema changes
generator implementation changes
parameter/state changes
complexity-code changes
sandbox/provider changes
```

### 3.2 Behavioral lineage

```text
behavior/final-semantics digest
finite-horizon changes
observational equivalence changes
behavioral metric changes
```

Equal behavioral outputs do not imply equal presentations. Equal presentations under different input families do not imply equal identification claims.

---

## 4. Candidate-fiber dynamics

For compatible receipts, compare candidate fibers by declared equivalence and intervention regime.

Possible relations include:

```text
UNCHANGED
NARROWED
WIDENED
DISJOINT
BECAME_NONEMPTY
BECAME_EMPTY
UNKNOWN_DUE_TO_SEARCH
NOT_COMPARABLE
```

### 4.1 Interpretation guardrails

- `NARROWED` may indicate increased identifiability, stronger assumptions, new interventions, or accidental exclusion; the receipt states which.
- `BECAME_EMPTY` under a richer evidence set may show model contradiction or a bad migration; it is not automatically “less coherent.”
- a heuristic search returning fewer candidates does not prove fiber narrowing.

---

## 5. Dependence and intervention provenance

Each compared observation or intervention carries:

```text
producer
detector
randomizer/query selector
shared-state dependence
shared-model dependence
apparatus boundary
ordering and timing
```

A query is held out only relative to a declared information boundary.

When the candidate generator also produces the vantage/query, Observation Dynamics marks the query endogenous and requires a separate exogenous channel for claims that depend on production–detection separation.

---

## 6. Approximate composition lineage

Comparison of atlas/path results requires compatible:

```text
tolerance monoids
local error assignments
path normalization
behavioral metrics
grounding bases
```

If a migration changes the tolerance law, old and new path residuals are not numerically compared without a certified conversion.

Every nonzero inflation or uncertainty entry used in comparison carries:

```text
calibration basis
grounding record
composition rule
dominant grounding quality
```

Ungrounded inflation cannot manufacture comparability or erase a contradiction.

---

## 7. Lift comparison

### 7.1 Lift package

A lift package relates:

```text
H₀ receipt
measured insufficiency under H₀
preregistered H₁
complexity rule commonization or migration
held-out oracle commitment
H₁ receipt
```

### 7.2 Lift validation

`LIFT_VALIDATED` requires:

1. the pre-lift result was not merely a failed heuristic search;
2. the richer class was registered before oracle reveal;
3. the new presentation reduces the declared insufficiency;
4. the improvement survives complexity accounting;
5. held-out prediction/intervention succeeds;
6. maps, alternatives, uncertainty, and unresolved debt remain available;
7. standing is sufficient for the claim.

### 7.3 Underdetermination is not obstruction

A non-singleton candidate fiber means multiple global realizations exist.

It is not evidence that no global realization exists.

Observation Dynamics records separately:

```text
realization existence
fiber multiplicity
globalization obstruction, if the CM defines one
```

A cohomological, logical, or other obstruction may be supplied by a CM, but Core does not identify every underdetermination or cycle residual with one universal obstruction class.

---

## 8. Score comparison

Optional scalar summaries may be compared only when:

```text
same or migrated CM scale
same categorical status class
same generator-class semantics
same standing level or declared policy
same admissible transformation/calibration regime
```

A scalar delta never overrides a categorical relation.

Examples:

```text
UNDERDETERMINED → IDENTIFIED_IN_MODEL
```

is primarily an identifiability change, not a score increase.

```text
LAWFUL → LAWFUL_TERMINATION
```

is not a coherence decline.

---

## 9. Comparison receipt

```json
{
  "schema": "tsc-comparison/2.0.0-alpha.1",
  "left_receipt": "digest",
  "right_receipt": "digest",
  "admissibility": "COMPARABLE_WITH_MIGRATION",
  "migration": {},
  "presentation_relation": {},
  "behavior_relation": {},
  "fiber_relation": "NARROWED",
  "status_changes": {},
  "intervention_provenance": {},
  "tolerance_grounding": {},
  "lift": "LIFT_VALIDATED",
  "optional_scalar_delta": null,
  "standing": "...",
  "explanation": "..."
}
```

---

## 10. Observation Dynamics axioms

### O1 — Comparison is licensed, not presumed

Two valid receipts may still be incomparable.

### O2 — Lineage is two-sided

Presentation and behavioral lineages are both retained.

### O3 — Interventions are boundary-relative

Exogeneity is always stated relative to the tested model boundary.

### O4 — Search behavior is not fiber truth

Algorithmic yield does not substitute for a completeness claim.

### O5 — Underidentification is not incoherence

Multiple lawful generators are a real epistemic result.

### O6 — Lift requires severity

A larger model must predict evidence not used to select it and pay its declared complexity cost.

### O7 — Categorical changes dominate scalar deltas

A summary score cannot reverse or hide the receipt’s status relation.

### O8 — Grounding survives composition

Uncertainty and tolerance adjustments remain evidence-bound through every comparison.
