# TSC Core v4 — Generative Coherence Receipts

**Version:** 4.0.0
**Status:** Draft
**Artifact:** Normative measurement semantics

## 0 · Governing question

> When do observations warrant the claim that they belong to one lawful generative process under a declared methodology?

TSC answers with a proof-carrying receipt. The receipt preserves the observations, the relations among them, the candidate generators that explain them, and the tests of how those generators continue.

Coherence is always relative to a declared Coherence Methodology (CM). It is not a context-free property and it is not identified with visible order, low entropy, agreement among projections, or the absence of articulation.

---

## Primitive contract

Let `P` be a type of poles and:

```text
Rel : P × P → Set
Art := Σ(s : P). Σ(o : P). Rel(s,o)
```

A concrete pointed generator is:

```text
G = (X, I, c, x_0)
c : X × I → Art × X
```

`X` is a state space, `I` is the input/query/intervention space relative to the tested boundary, and `c` emits one typed articulation event and one successor state.

A measurement may use final behavior, finite unfolding, or another declared approximation. It must retain the concrete presentation whenever complexity, mechanism, intervention, or standing depends on it.

---

## 1 · Measurement context

A CM defines one measurement context:

```text
M := (
  identity,
  carrier,
  generator class,
  input and observation contract,
  relation and equivalence contract,
  approximation contract,
  complexity contract,
  oracle contract,
  receipt schema
)
```

### 1.1 Identity

A CM declares:

```text
cm_id
cm_version
cm_digest
implementation_digest
```

Every receipt binds to these values.

### 1.2 Generator class

A CM declares a hypothesis class:

```text
H_M
```

Each candidate `G ∈ H_M` is a pointed open generator:

```text
G = (X, I, c, x_0)
c : X × I → Art × X
```

The class declares the allowed state spaces, parameters, laws, resources, and representations.

### 1.3 Query and intervention contract

A CM declares:

```text
I_M                         input/query/intervention space
query_mode                  exogenous | endogenous | mixed
J_passive ⊆ I_M*            passive observation histories
J_active  ⊆ I_M*            active intervention histories
```

The boundary between generated and externally supplied queries is part of the measurement contract.

### 1.4 Observation channels

Let `Q_M` be the set of observation channels. Each channel `q : Q_M` has an observation space:

```text
O_q
```

The CM defines a prediction operator:

```text
predict_M(G, u, q) : Pred(O_q)
```

where:

- `G ∈ H_M`;
- `u ∈ I_M*` is an input history;
- `Pred(O_q)` is a value, set, interval, or probability distribution appropriate to the channel.

### 1.5 Evidence item

An evidence item is:

```text
E := (
  evidence_id,
  input_history u,
  channel q,
  observed value o,
  uncertainty,
  provenance,
  holdout_role
)
```

`holdout_role` is one of:

```text
fit | calibration | held_out | intervention
```

A dataset `D` is a finite set of evidence items plus a completeness declaration.

### 1.6 Fit and complexity

A CM declares:

```text
L_M(G,D)       fit or loss
K_M(G)         complexity or prior cost
τ_M            admissible fit bound
κ_M            admissible complexity bound
```

The representation language or prior that gives `K_M` meaning is part of the CM.

### 1.7 Equivalence

A CM declares an equivalence relation:

```text
G ≃_M G'
```

The relation states which presentation differences do not matter for the claim being made.

The CM also declares whether equivalence is based on:

- concrete presentation isomorphism;
- passive behavior;
- active/interventional behavior;
- another explicit criterion.

### 1.8 Search claim

A CM declares the strength of its candidate search:

```text
search_claim = complete | complete_within_bound | heuristic | sampled
```

A failed search proves an empty candidate class only when the declared search claim warrants that conclusion.

---

## 2 · Candidate fiber

### 2.1 Definition

Partition the evidence by role:

```text
D_train := D_fit ∪ D_calibration
D_test  := D_held_out ∪ D_intervention
```

The fitted candidate fiber is:

```text
F_M^train(D) := {
  [G]_≃M |
  G ∈ H_M,
  L_M(G,D_train) ≤ τ_M,
  K_M(G) ≤ κ_M
}
```

The **fit-only fiber** drops the complexity bound, so that *no generator fits* is distinguishable from *a generator fits but exceeds the budget*:

```text
F_M^fit(D) := { [G]_≃M | G ∈ H_M, L_M(G,D_train) ≤ τ_M }
```

The tested candidate fiber is the subset that also satisfies the preregistered oracle without refitting:

```text
F_M^test(D) := {
  [G]_≃M ∈ F_M^train(D) |
  oracle_M(G,D_test) = PASS
}
```

When the oracle contract does not require held-out or intervention evidence, the receipt sets:

```text
test_status = NOT_RUN
```

and does not treat the training fiber as held-out support.

**Independence of the oracle (I11).** `oracle_M(G,D_test)` carries weight only if `D_test` was not produced, selected, or leaked by the candidate `G` under test. When `query_mode` is endogenous or mixed (C≡ §3.2), a held-out or intervention claim requires an explicitly modeled exogenous channel; a candidate that authors its own oracle has not been tested.

Both fibers are indexed by:

- the CM;
- the evidence roles and digests;
- the passive and active input families;
- the fit and oracle tolerances;
- the complexity bound;
- the declared equivalence.

The receipt retains both fibers or verifiable references to them. Test evidence may remove candidates. It must not silently alter their fitted parameters or generator class.

### 2.2 Fiber status

The receipt classifies each applicable fiber as:

```text
NO_REALIZATION_IN_MODEL
  the fit-only fiber F_M^fit is empty under a complete search
  (no generator fits at any complexity)

REALIZABLE_OVER_BUDGET
  F_M^fit is nonempty but F_M^train is empty (some generator fits;
  every fit exceeds κ_M) — a signal to raise κ_M or revise the
  coding, never a refutation

UNDERDETERMINED
  two or more inequivalent candidates remain within budget

IDENTIFIED_IN_MODEL
  exactly one equivalence class remains within budget

UNRESOLVED
  evidence, search, or approximation cannot establish another status
```

`UNDERDETERMINED` is not incoherence. It means the evidence is compatible with more than one lawful generator.

`IDENTIFIED_IN_MODEL` is not absolute truth. It is identification within the declared CM, class, equivalence, bounds, and intervention family.

### 2.3 Widening the input family

Adding independent queries or interventions may refine a fixed fitted fiber:

```text
J_1 ⊆ J_2  ⇒  F_M^test(D | J_2) ⊆ F_M^test(D | J_1)
```

A CM must not claim this monotonic refinement unless its observation and equivalence contracts make it valid.

---

## 3 · Three verification receipts

TSC verifies a claim through three non-interchangeable receipts.

### 3.1 α — Manifestation receipt

The α receipt answers:

> Are the observations valid, complete enough for the stated claim, and stable under the declared local checks?

It contains:

```text
observation ids and digests
channel and constructor identities
coverage and missingness
repeat or perturbation results
noise and uncertainty
invalid or out-of-domain evidence
```

Its status is:

```text
VALID | INCOMPLETE | INVALID
```

A missing observation is not positive evidence. An empty dataset does not receive a coherence judgment unless the CM explicitly defines an empty-input question.

### 3.2 β — Relational atlas

The β receipt answers:

> Do the observations, correspondences, and transformations form one globally compatible relational structure under the declared model?

It contains:

```text
source-to-observation maps
observation-to-observation correspondences
alternative maps
map uncertainty
local residuals
path compositions
cycle or globalization checks
training and tested candidate fibers
identifiability status
oracle and test status
unresolved correspondences
```

The maps are primary evidence. A residual or scalar may summarize them but cannot replace them.

Pairwise compatibility does not establish a global realization. The CM must define and execute a full-diagram criterion.

### 3.3 γ — Continuation receipt

The γ receipt answers:

> Does the candidate generator continue lawfully under time, viewpoint, scale, intervention, or another declared transformation?

It contains:

```text
input and intervention histories
predictions made before observation
held-out outcomes
state and identity transport
composition across paths
law violations
birth, merge, split, and termination events
```

Its status is:

```text
LAWFUL
LAW_VIOLATION
LAWFUL_TERMINATION
INSUFFICIENT_EVIDENCE
```

A lawful ending is not degraded coherence. Raw stasis is not process coherence. The CM states what identity means and how it may change or end.

---

## 4 · Core axioms

### A1 — Scopedness

Every coherence claim names its CM, evidence, generator class, equivalence, tolerance, complexity bound, and input/intervention family.

### A2 — Realizability

Distinct observations support one process when at least one declared generator produces them within the fit and complexity contract.

Similarity among observations is neither necessary nor sufficient.

### A3 — Relation retention

Every correspondence, transformation, and path used to support realizability remains in the β receipt.

### A4 — Globality

Pairwise fits support a common process only when they satisfy the CM’s full-diagram globalization rule.

### A5 — Non-vacuity

The generator class and complexity contract are declared before fitting. A lookup table or tuple of observations does not establish generativity unless it passes the same complexity and held-out obligations as any other candidate.

### A6 — Identifiability separation

Realizability, uniqueness, and search completeness are different facts and receive different statuses.

### A7 — Law-relative continuation

Randomness is not incoherence. A stochastic process may be lawful under a stochastic CM. A negative control violates a declared law; it need not look disordered.

### A8 — Receipt primacy

Structured evidence remains normative until a quotient is proved sufficient for the exact decision. Incomplete search produces `UNRESOLVED`, not a fabricated negative result.

---

## 5 · Coherence disposition

### 5.1 Compatible in model

Evidence is `COMPATIBLE_IN_MODEL` when:

```text
α = VALID
F_M^train(D) is nonempty
γ ≠ LAW_VIOLATION
```

Compatibility means that at least one bounded candidate accounts for the evidence used to construct it. It is not held-out support and does not establish identification.

### 5.2 Supported in model

Evidence is `SUPPORTED_IN_MODEL` when:

```text
α = VALID
F_M^test(D) is nonempty
test_status = PASSED
γ ∈ {LAWFUL, LAWFUL_TERMINATION}
```

and every oracle obligation required by the CM has passed.

Support means that at least one candidate survived evidence not used to fit it. It remains scoped to the declared CM, class, equivalence, bounds, and intervention family.

### 5.3 Refuted in model

Evidence is `REFUTED_IN_MODEL` when:

```text
α = VALID
```

and either:

```text
an applicable fiber is proved NO_REALIZATION_IN_MODEL
```

or:

```text
γ = LAW_VIOLATION
```

The refutation is scoped to the declared model class and test regime.

### 5.4 Unresolved

Evidence is `UNRESOLVED` when:

- α is incomplete;
- candidate search is not strong enough to classify the applicable fiber;
- required relations are missing;
- uncertainty exceeds the declared bound;
- a required held-out or intervention test has not been run;
- γ is `INSUFFICIENT_EVIDENCE` for a continuation claim;
- the CM cannot ground a load-bearing transformation.

### 5.5 Identification status

Identification remains a separate field:

```text
IDENTIFIED_IN_MODEL | UNDERDETERMINED | NOT_ESTABLISHED
```

A compatible or supported receipt may remain underdetermined.

---

## 6 · Model insufficiency and lift

### 6.1 Current-model insufficiency

A receipt may classify:

```text
CURRENT_MODEL_INSUFFICIENT
```

when:

- α observations are stable and valid;
- the declared class cannot realize them or cannot globalize their relations;
- the result is not explained by missing evidence, ungrounded transforms, or search incompleteness.

This status does not yet authorize a richer model.

### 6.2 Lift proposal

A lift proposal declares before testing:

```text
baseline class H_0
lifted class H_1
new degrees of freedom
complexity rule
baseline failure or obstruction
acceptance margin
held-out query, future state, or intervention
```

### 6.3 Lift validation

A lift is `LIFT_VALIDATED` only when:

1. the baseline failure is reproduced;
2. the lifted class reduces the declared failure by the preregistered margin;
3. the gain survives the complexity cost;
4. the lifted generator predicts held-out evidence not used to fit it;
5. the result remains stable under the declared uncertainty checks;
6. the full maps and alternatives remain in the receipt.

Otherwise the lift is `LIFT_REJECTED` or `LIFT_UNRESOLVED`.

---

## 7 · Approximation

### 7.1 Path-tolerance monoid

An approximate CM declares:

```text
(E, ⊕, 0, ≤)
```

and a local error budget:

```text
ε(edge) : E
```

For path:

```text
p = e_n ∘ ... ∘ e_1
```

its budget is:

```text
B(p) = ε(e_1) ⊕ ... ⊕ ε(e_n)
```

### 7.2 Behavioral metric

The CM declares a metric or pseudometric:

```text
d_B
```

for endpoint or behavior comparison.

It also declares the compatibility law connecting `B(p)` to `d_B`.

A fixed global epsilon with no path law is not a conformance contract for compositional evidence.

### 7.3 Grounding

Every nonzero tolerance, inflation, or uncertainty term identifies its basis:

```text
empirical measurement
analytic bound
prior calibration
conservative policy
ungrounded declaration
```

Ungrounded values may be reported. They cannot support a standing-bearing verdict.

---

## 8 · Optional scalar summaries

A CM may define scalar summaries for ranking or monitoring within one compatible context.

Every scalar summary must declare:

```text
source receipt fields
scale type
admissible transformations
aggregation rule
calibration
status domain
```

A scalar cannot change the receipt’s categorical status. In particular, it cannot:

- turn `UNDERDETERMINED` into `IDENTIFIED_IN_MODEL`;
- turn `UNRESOLVED` into `NO_REALIZATION_IN_MODEL`;
- turn `LAW_VIOLATION` into lawful continuation;
- grant standing;
- authorize a boundary action.

---

## 9 · Core receipt

A Core receipt contains at least:

```text
receipt_id
cm identity and digests
input and evidence digests
query/intervention boundary
α manifestation receipt
β relational atlas
γ continuation receipt
training and tested candidate fibers or verifiable references
search claim
test status and oracle evidence
fit and complexity accounting
equivalence and tolerance contract
coherence disposition
identification status
model and lift status
uncertainty and grounding
provenance
```

Every conclusion points to the receipt fields that support it.

---

## 10 · Core conformance

A Core implementation is conforming when it can prove the following positive and negative cases.

### Positive

- valid evidence with several lawful candidates produces `SUPPORTED_IN_MODEL + UNDERDETERMINED`;
- independent held-out evidence can reduce the fiber to `IDENTIFIED_IN_MODEL`;
- a lawful stochastic trace is supported under its stochastic CM;
- a lawful ending produces `LAWFUL_TERMINATION`.

### Negative

- incomplete evidence does not produce a verdict;
- pairwise fits with no global realization do not produce support;
- a failed heuristic search does not produce `NO_REALIZATION_IN_MODEL`;
- a larger model that only memorizes fit does not validate a lift;
- a scalar cannot override a structured status;
- an illegal transition produces `LAW_VIOLATION` even when superficial statistics remain unchanged.
