# TSC Core v4.0.0-alpha.1 — Generative Coherence Receipts

**Version:** 4.0.0-alpha.1
**Date:** July 2026
**Status:** Draft; depends on C≡ v4 alpha
**Foundation:** `spec/v4/c-equiv.md`

---

## 0. Purpose

TSC Core v4 defines when a set of observations, transformations, and continuations warrants the claim that they are manifestations of **one lawful generative presentation** under a declared Coherence Methodology (CM).

The primary output is a proof-carrying receipt.

Core does not assume:

- that different views resemble one another;
- that a hidden material object is the only valid generative explanation;
- that every phenomenon has exactly three views;
- that every CM uses the same carrier category, metric, or generator language;
- that one scalar is sufficient to distinguish realizability, identification, lawful change, model insufficiency, and standing;
- that randomness is incoherence.

### 0.1 Core question

> Under this declared CM, do the observations, their relational atlas, the concrete generator presentation, and its continuation remain one lawful process—and what exactly has and has not been identified?

---

## 1. Coherence Methodology contract

A CM instantiating Core MUST declare the following.

### 1.1 Identity

```text
cm_id
cm_version
cm_digest
spec_version
implementation_digest
```

### 1.2 Carrier and generator class

```text
carrier_category_or_approximation
generator_language_or_hypothesis_class H
concrete presentation schema P
system functor or finite-horizon unfolding
finality/existence or approximation witness
```

### 1.3 Inputs and observations

```text
input_schema
query_mode = exogenous | endogenous | mixed
exogenous input/intervention channel I
observation schema
observation constructor
coverage/completeness rule
noise and missingness model
```

### 1.4 Relation and behavior

```text
articulation event schema Art
correspondence/transformation family
composition/globalization rule
presentation equivalence ≃P
behavioral equivalence ≃B or metric d_B
identity and lawful-termination rule
```

### 1.5 Approximation

```text
path-tolerance monoid (E,⊕,0,≤)
local error assignment ε
behavioral metric/pseudometric d_B
compatibility rule between accumulated path budget and d_B
```

### 1.6 Non-vacuity and severity

```text
complexity coding language or prior
complexity functional K
fit/loss functional L
search-completeness claim
held-out query, future-state, or intervention oracle
lift preregistration rule
```

### 1.7 Authority

```text
sandbox and permissions
consistency protocol
calibration/discrimination controls
standing scope
verdict authorization policy
```

A missing load-bearing declaration produces `CM_NOT_APPLICABLE` or `CM_NOT_EXECUTABLE`, not a guessed score.

---

## 2. Evidence and observational atlas

### 2.1 Observation episode

An observation episode is:

```text
E_j := {
  initial presentation reference or declared unknown,
  input/query history h_j,
  observed articulation projection y_j,
  timestamp or ordering,
  uncertainty,
  provenance,
  coverage status
}
```

The exact representation is CM-defined.

### 2.2 Relational atlas

The β-side relational evidence is not a residual scalar. It is an atlas:

```text
Atlas := {
  observation nodes,
  typed correspondences and transformation maps,
  map endpoints and roles,
  alternatives,
  uncertainty and confidence sets,
  unresolved correspondences,
  local residuals,
  path/cycle composition checks,
  globalization result,
  provenance
}
```

A correspondence or alignment map that supports the common-generator claim is part of the normative receipt.

### 2.3 Approximate composition

For a path:

```text
p = u_n ∘ ... ∘ u_1
```

the CM assigns:

```text
B(p) = ε(u_1) ⊕ ... ⊕ ε(u_n)
```

and tests the path against its compatible metric or residual rule.

A fixed epsilon independent of path length is admissible only when the CM proves that it remains a valid bound.

---

## 3. Candidate generative presentations

### 3.1 Presentation

A candidate presentation `P` contains at least:

```text
state/presentation space X_P
input channel I_P
articulation type Art_P
concrete generator c_P
initial/current state or state distribution z_P
parameters θ_P
observation projection(s)
complexity representation
```

When final semantics exists, it also carries:

```text
νF_P
ζ_P
beh_P
commuting witness
```

Otherwise it carries a declared finite-horizon or approximate behavior object.

### 3.2 Presentation and behavior are both normative

The behavior point does not replace the presentation.

Core retains:

```text
(P, behavior(P), semantic witness P→behavior(P))
```

because:

- complexity `K(P)` is presentation-sensitive;
- interventions may distinguish behaviorally equivalent passive presentations;
- mechanism and implementation claims are presentation-sensitive;
- model migration requires a lineage of presentations.

### 3.3 Fit

The CM defines a fit functional:

```text
L_M(P; D, Atlas)
```

which MUST account for the declared observation and relational obligations.

It MAY combine:

- observation error;
- correspondence error;
- path composition error;
- distributional error;
- intervention response error;
- identity/termination-law error.

Core does not prescribe one universal arithmetic combination.

---

## 4. Candidate fiber and identifiability

### 4.1 Candidate fiber

For evidence `D`, relational atlas `A`, fit tolerance `τ`, and complexity bound `κ`, define:

```text
Fiber_M(D,A;τ,κ,I)
  := { [P]_{≃P or declared observational equivalence}
       | P ∈ H_M,
         L_M(P;D,A) ≤ τ,
         K_M(P) ≤ κ }
```

The fiber is explicitly indexed by the declared query/intervention family `I`.

### 4.2 Search-completeness qualifier

A runtime MUST distinguish:

```text
COMPLETE_SEARCH
SOUND_INCOMPLETE_SEARCH
HEURISTIC_SEARCH
UNKNOWN_SEARCH_STATUS
```

Absence of a discovered candidate under an incomplete search does not prove an empty fiber.

### 4.3 Realizability status

```text
REALIZED
NO_REALIZATION_IN_MODEL
UNRESOLVED_REALIZABILITY
```

`NO_REALIZATION_IN_MODEL` requires a CM-defined proof or complete-enough oracle. Otherwise use `UNRESOLVED_REALIZABILITY`.

### 4.4 Identifiability status

```text
IDENTIFIED_IN_MODEL
UNDERDETERMINED
UNRESOLVED_IDENTIFIABILITY
NOT_APPLICABLE
```

- `IDENTIFIED_IN_MODEL`: one candidate equivalence class remains under the declared `I`, tolerance, complexity, and search contract.
- `UNDERDETERMINED`: at least two inequivalent candidates remain.
- `UNRESOLVED_IDENTIFIABILITY`: evidence or search cannot classify the fiber.

Identification is never absolute; it is always relative to the CM and intervention/query regime.

---

## 5. Structured α / β / γ receipts

The names α, β, and γ are retained provisionally as verification roles. They are not observation identities and are not freely permutable.

### 5.1 α — manifestation validity

The α receipt answers:

> Are the observations themselves valid, stable, sufficiently covered, and robust under the perturbations declared by the CM?

It contains:

```text
observation inventory
coverage/completeness certificate
local invariants
repeat/perturbation results
noise and missingness evidence
invalid or unstable observation diagnostics
provenance
```

### 5.2 β — relational atlas and realization

The β receipt answers:

> Do the observations and transformations form a globally compatible atlas of at least one declared generative presentation, and how many inequivalent candidates remain?

It contains:

```text
Atlas
candidate presentations or bounded references to them
candidate fiber description
realizability status
identifiability status
search-completeness status
complexity accounting
unresolved relations
provenance
```

### 5.3 γ — lawful continuation

The γ receipt answers:

> Does the candidate presentation transport identity lawfully through time, viewpoint, scale, migration, or intervention, and does it predict evidence not used to fit it?

It contains:

```text
continuation paths
identity invariants
future/held-out predictions
intervention responses
composition/path budgets
birth/merge/split/termination events
law violations
provenance
```

### 5.4 No axis-interchangeability claim

The three receipts have different types and different failure modes.

Core claims neither statistical independence nor `S₃_axis` symmetry.

A common verdict policy may treat a failure in any required receipt as blocking. That bottleneck rule does not make the receipt types interchangeable.

---

## 6. Categorical status vocabulary

A complete Core result is a product of statuses rather than one flattened verdict.

### 6.1 Observation

```text
VALID
INVALID
INCOMPLETE
```

### 6.2 Realizability

```text
REALIZED
NO_REALIZATION_IN_MODEL
UNRESOLVED_REALIZABILITY
```

### 6.3 Identifiability

```text
IDENTIFIED_IN_MODEL
UNDERDETERMINED
UNRESOLVED_IDENTIFIABILITY
NOT_APPLICABLE
```

### 6.4 Continuation

```text
LAWFUL
LAW_VIOLATION
LAWFUL_TERMINATION
INSUFFICIENT_HISTORY
UNRESOLVED_CONTINUATION
```

### 6.5 Model adequacy

```text
ADEQUATE_FOR_CLAIM
CURRENT_MODEL_INSUFFICIENT
UNRESOLVED_MODEL_ADEQUACY
```

### 6.6 Lift

```text
NO_LIFT
LIFT_PROPOSED
LIFT_VALIDATED
LIFT_REJECTED
```

### 6.7 Standing

```text
NONE
EXPERIMENTAL
EARNED
FAILED
```

The CM or consuming policy may derive a compact operator verdict, but it MUST preserve the full status product in the receipt.

---

## 7. Core axioms

### C1 — Scopedness

Every result is relative to a named CM, generator class, observation construction, input/intervention family, equivalence, tolerance, complexity rule, and oracle.

### C2 — Typed common-generator realizability

Different observations need not resemble one another. They cohere in the declared model when a typed generative presentation lawfully accounts for them and the retained transformations among them.

### C3 — Map retention

Every correspondence, projection, alignment, or transport map used to establish the result remains in the normative receipt or is digest-linked to it.

### C4 — Presentation–behavior dual retention

Core retains the concrete presentation, its behavior semantics or approximation, and their compatibility witness.

### C5 — No premature quotient

No scalar, behavior quotient, or equivalence class replaces presentation-sensitive evidence when the downstream claim depends on presentation, complexity, intervention, or mechanism.

### C6 — Model non-vacuity

The hypothesis class and complexity representation are declared before final evaluation. A tuple/lookup-table presentation does not establish explanatory coherence merely because it reproduces the fitted observations.

### C7 — Realizability and identification differ

Existence of a candidate, uniqueness of a candidate class, and evidence sufficient to establish either are distinct claims.

### C8 — Law-relative coherence

Randomness is not incoherence. A stochastic trace may be compatible with a stochastic generator. A negative control violates a declared law or warranted relation.

### C9 — Intervention-indexed identification

Identification is indexed by the declared input/query/intervention channel. Active interventions may refine an observational equivalence class.

### C10 — Tolerance compatibility

Path accumulation and endpoint behavioral comparison use declared, compatible structures. Approximate functoriality without a tolerance calculus is undefined.

### C11 — Severe lift validation

A richer generator class earns `LIFT_VALIDATED` only when:

1. the expansion, complexity rule, and test were preregistered;
2. it reduces a previously measured insufficiency by the declared margin;
3. the improvement survives complexity accounting;
4. it predicts a held-out query, future state, or intervention;
5. the receipt retains alternatives, maps, and unresolved uncertainty.

### C12 — Receipt primacy

The primary output is the structured receipt. A scalar is an optional, CM-local projection.

### C13 — Honest incompleteness

Unknown search completeness or insufficient evidence yields an unresolved status, not a fabricated negative or positive conclusion.

### C14 — Lawful termination

A declared identity may end lawfully. Absence after lawful termination is not automatically process incoherence.

### C15 — Conditional finality

A final behavior object is used only with an existence or approximation witness appropriate to the declared category.

---

## 8. Optional scalar summaries

A CM MAY emit scalar diagnostics after categorical classification.

A scalar summary MUST declare:

```text
source receipt digest
CM identity/version
status class over which the number is meaningful
scale type
admissible transformations
calibration basis
aggregation rule
standing
```

It MUST NOT:

- erase `UNDERDETERMINED` versus `NO_REALIZATION_IN_MODEL`;
- authorize a verdict absent standing;
- be compared across incompatible CMs, generator classes, or semantic versions;
- be named `C_Σ` as though v3 and v4 quantities were continuous by default.

---

## 9. Cone illustration

Observed silhouettes:

```text
triangle at query q₁
circle at query q₂
```

Under a broad class of arbitrary solids, many generative presentations may fit:

```text
realizability      = REALIZED
identifiability    = UNDERDETERMINED
```

Under a preregistered right-circular-cone rendering class with known geometry and declared scale assumptions, one candidate class may remain.

A held-out oblique query `q₃` tests the generator:

```text
matching prediction  → LIFT_VALIDATED or IDENTIFIED_IN_MODEL, per preregistration
failed prediction    → LIFT_REJECTED or CURRENT_MODEL_INSUFFICIENT
```

The triangle and circle are outputs. The maps, query geometry, candidate generator, and held-out prediction carry the coherence claim.

---

## 10. Game of Life illustration

A CM declares:

```text
generator class: B3/S23 over a finite grid
state: grid configuration
inputs/queries: time steps and selected observation surfaces
observations: full frames or row/column margins
identity rule: glider equivalence up to phase and translation
```

### Static margins

Two grids may share the same row and column sums:

```text
REALIZED + UNDERDETERMINED
```

### Dynamic continuation

The two candidates predict different next margins under B3/S23. A held-out next observation may reduce the fiber to one:

```text
IDENTIFIED_IN_MODEL
LIFT_VALIDATED, if dynamics was the preregistered richer class
```

### Illegal transition

A successor preserving superficial margins and live-cell count but violating B3/S23 yields:

```text
LAW_VIOLATION
```

not merely a lower visual-order score.

### Stochastic law

An i.i.d. Bernoulli sequence is not a universal negative. Under an i.i.d. Bernoulli CM it may be compatible yet underdetermined.

---

## 11. Core receipt skeleton

```json
{
  "schema": "tsc-receipt/4.0.0-alpha.1",
  "cm": {
    "id": "...",
    "version": "...",
    "digest": "..."
  },
  "input": {
    "digest": "...",
    "query_mode": "exogenous|endogenous|mixed",
    "intervention_scope": "..."
  },
  "alpha": { "...": "manifestation receipt" },
  "beta":  { "...": "atlas and candidate-fiber receipt" },
  "gamma": { "...": "continuation and held-out receipt" },
  "status": {
    "observation": "VALID",
    "realizability": "REALIZED",
    "identifiability": "UNDERDETERMINED",
    "continuation": "LAWFUL",
    "model": "ADEQUATE_FOR_CLAIM",
    "lift": "NO_LIFT",
    "standing": "EXPERIMENTAL"
  },
  "presentation": { "digest": "...", "complexity": "..." },
  "behavior": { "kind": "final|finite-horizon|approximate", "digest": "..." },
  "semantic_witness": { "digest": "..." },
  "optional_summary": null,
  "provenance": { "...": "..." }
}
```
