# TSC Core v4 — Generative Coherence Receipts

**Version:** 4.0.0
**Status:** Draft
**Artifact:** Normative measurement semantics

## Governing question

> When do observations warrant the claim that they belong to one lawful generative process under a declared methodology?

TSC answers with a proof-carrying receipt. The receipt preserves the observations, the relations among them, the joint generator-and-atlas realization candidates that explain them, and the tests of how those generators continue.

Coherence is relative to a declared Coherence Methodology (CM). It is not a context-free scalar and is not identified with visible order, low entropy, agreement among projections, or absence of articulation.

## 1 · Foundation contract

Import from C≡:

```text
P                         pole type
Rel : P × P → Set         dependent relation family
Art := Σ(s:P).Σ(o:P).Rel(s,o)
```

The canonical deterministic Set presentation is:

```text
SetPresentation := (X,I,c,x_0,path_contract)
c : X × I → Art × X
path_contract : C≡ PathContract
```

A CM that needs another transition structure declares:

```text
GeneralPresentation := (
  carrier category C,
  system functor F : C → C,
  state object X,
  structure map c : X → F(X),
  pointed-state witness x_0,
  typed articulation interface,
  intrinsic path contract or category-specific intrinsic succession witness
)
```

When `C` has a terminal object, `x_0` may be a generalized element `1_C → X`. Another category uses an equally explicit state witness.

The articulation interface states how one system step produces or predicts typed `Art` events under the CM's input and observation contract. A stochastic or nondeterministic presentation does not acquire the deterministic Set contract by notation alone.

Write:

```text
BehaviorPresentation := SetPresentation | GeneralPresentation
```

A measurement may use exact final behavior, a general final behavior, finite access, or an approximation. It retains the concrete presentation whenever complexity, mechanism, intervention, or standing depends on it.

## 2 · Measurement context

A CM defines one measurement context:

```text
M := (
  identity,
  carrier and behavior contract,
  generator class,
  query, observation, and path contract,
  relation-search contract,
  generator-search contract,
  equivalence contract,
  approximation contract,
  complexity contract,
  oracle contract,
  receipt schema
)
```

### 2.1 Identity

A CM declares:

```text
cm_id
cm_version
cm_digest
implementation_digest
```

Every receipt binds to these values.

### 2.2 Generator class

A CM declares a hypothesis class:

```text
H_M
```

Each `G ∈ H_M` is a `BehaviorPresentation` admitted by the CM's behavior contract. The class states the allowed:

```text
presentation kind
state spaces or objects
parameters
laws
resources
representations
system functor and articulation interface, when general
path mode and succession witness for every cross-step path claim
input adapter, when the presentation input differs from I_M
```

Every candidate exposes the CM's `Art` and `I_M` contracts directly or through a typed adapter retained in the receipt.

### 2.3 Query and intervention contract

Let `I_M*` be the finite histories over `I_M`, including the empty history.

A CM declares:

```text
I_M                         input/query/intervention space
query_mode                  exogenous | endogenous | mixed
J_passive ⊆ I_M*            passive histories
J_active  ⊆ I_M*            active intervention histories
```

The empty history may address the initial state before any transition. The boundary between generated and externally supplied queries is part of the claim.

### 2.4 Observation channels

Let `Q_M` be the set of observation channels. Each `q : Q_M` has an observation space `O_q`.

The observation contract states how a realization candidate predicts each channel under an input history. The prediction operator is defined with the realization candidate in §2.8 so an unknown correspondence cannot be hidden as fixed preprocessing.

### 2.5 Evidence item

An evidence item is:

```text
E := (
  evidence_id,
  input_history,
  channel,
  observed_value,
  uncertainty,
  provenance,
  holdout_role
)
```

`holdout_role` is:

```text
fit | calibration | held_out | intervention | post_hoc
```

A dataset `D` is a finite set of evidence items plus a completeness declaration.

### 2.6 Search claim

Use one vocabulary for every search surface:

```text
SearchClaim :=
  complete
  | complete_within_bound(bound)
  | heuristic
  | sampled(protocol)
```

A CM declares:

```text
generator_search_claim : SearchClaim
relation_search_claim  : SearchClaim
```

A failed search proves absence only when the corresponding search claim warrants it.

### 2.7 Relation-search contract

The β relation-search contract declares:

```text
relation constructor or solver family
implementation and solver digests
search claim and bounds
selection policy
parameters and seeds
pruning rules
uncertainty model
orchestration with generator search
```

The β receipt retains:

```text
candidate maps considered
maps retained
maps pruned and why
alternative maps
map-level uncertainty
sensitivity to selection policy
search schedule or fixed-point protocol
```

Relation search and generator search may interleave. The schedule is declared and receipted. A heuristic relation search may propose an atlas; it may not prove that no valid map exists or that the atlas is unique.

### 2.8 Realization candidates

For `G ∈ H_M` and dataset `D`, let:

```text
A_M(G,D)
```

be the CM-declared class of admissible atlas candidates produced by the relation contract. An atlas candidate contains the maps and transformation structure needed to relate the concrete generator presentation to the observation episodes.

Define the joint realization-candidate class:

```text
R_M(D) := {
  R = (G,A) |
  G ∈ H_M,
  A ∈ A_M(G,D)
}
```

A realization candidate retains both the generator and the atlas. The CM may derive a unique atlas mechanically from `G`; when it does, that derivation and its sufficiency proof remain in the receipt.

The prediction operator is:

```text
predict_M(R, u, q) : Pred(O_q)
```

where `u ∈ I_M*`. A CM may project `R` to `G` internally only when the atlas is irrelevant to that prediction by a declared proof.

The identification target is explicit:

```text
identification_target = generator | atlas | joint_realization | another_declared_target
```

The equivalence contract in §2.10 determines which differences matter for that target.

### 2.9 Fit and complexity

A CM declares:

```text
L_M(R,D)       fit or loss for a joint realization candidate
K_M(R)         complexity or prior cost for generator plus atlas
τ_M            admissible fit bound
κ_M            admissible complexity bound
```

`K_M` accounts for every presentation choice used to explain the evidence, including a nontrivial atlas or relation-selection rule. The representation language, prior, or resource model that gives `K_M` meaning is part of the CM.

### 2.10 Input-indexed equivalence

A CM declares an equivalence family over realization candidates:

```text
R ≃_M^J R'
```

for every input family `J` used by the claim.

The family states which generator and atlas differences are unobservable or irrelevant under `J` and the declared identification target. It may be based on:

```text
presentation isomorphism
atlas isomorphism or gauge
behavior over J
active/interventional behavior over J
another explicit criterion
```

It satisfies refinement monotonicity as relation inclusion:

```text
J_1 ⊆ J_2
⇒ (≃_M^J_2) ⊆ (≃_M^J_1)
```

Equivalently:

```text
J_1 ⊆ J_2
and R ≃_M^J_2 R'
⇒ R ≃_M^J_1 R'
```

Wider input families may distinguish realization candidates that a narrower family identifies; they may not merge classes that the narrower family separated.

Prediction, fit, complexity, and oracle contracts are congruent with the equivalence used for their evidence regime. If equivalent realizations can receive different outcomes, the CM refines the equivalence or reports the class relation as unresolved.

Identification is always relative to the declared target, equivalence family, and input regime.

## 3 · Behavior contract

Behavioral semantics and empirical access are separate declarations.

### 3.1 Finality basis

```text
FinalityBasis :=
  SET_FINAL {
    applicability_evidence
  }

  | GENERAL_FINAL {
    carrier_category,
    object_action,
    morphism_action,
    functor_laws,
    pointed_state_contract,
    articulation_interface,
    behavior_object,
    finality_witness
  }

  | NO_FINALITY_CLAIM
```

The mathematical applicability conditions for `SET_FINAL` are owned solely by C≡ §6. Core records `applicability_evidence` against that contract; it does not restate or weaken the conditions. The permanent conformance requirement `FND-FINAL-002` tests this evidence but is not part of the semantic data type.

Category-specific measurable, topological, metric-enriched, stochastic, or nondeterministic claims still declare whatever additional structure their claim requires; satisfaction of the underlying Set construction does not grant those stronger claims.

`GENERAL_FINAL` asserts an actual final coalgebra in the declared category. An approximate commuting property or tolerant fixed-point sketch is not a finality witness.

### 3.2 Behavior access

```text
BehaviorAccess :=
  COMPLETE_SYMBOLIC {
    representation,
    decision procedures,
    supported claims
  }

  | FINITE {
    horizon,
    retained structure,
    induced equivalence,
    supported claims
  }

  | APPROXIMATE {
    construction,
    approximation_contract_digest,
    supported claims
  }
```

A CM may declare:

```text
finality_basis = SET_FINAL
behavior_access = FINITE(...)
```

Exact transition-behavior existence does not imply complete computational or observational access. Empty-history state observations belong to the CM observation contract and may refine the canonical Set behavioral equivalence.

### 3.3 Behavior contract

```text
BehaviorContract := (FinalityBasis, BehaviorAccess)
```

Every behavior-dependent claim names this contract and its digest.

## 4 · Approximation contract

Core is the sole normative owner of empirical approximation.

```text
ApproximationContract := (
  tolerance monoid,
  local budget rule,
  path accumulation,
  behavioral metric,
  budget-to-distance interpretation,
  grounding rules
)
```

Every approximate claim binds to one immutable contract digest.

### 4.1 Tolerance monoid

An approximate CM declares:

```text
(E, ⊕, 0, ≤)
```

and a local budget:

```text
ε(edge) : E
```

For path:

```text
p = e_n ∘ ... ∘ e_1
```

define:

```text
B(p) = ε(e_1) ⊕ ... ⊕ ε(e_n)
```

### 4.2 Behavioral metric

The CM declares a metric or pseudometric:

```text
d_B
```

and an interpretation function:

```text
interpret : E → DistanceBound
```

The compatibility law is:

```text
d_B(observed_endpoint, predicted_endpoint) ≤ interpret(B(p))
```

The domains, units, dependence assumptions, and relation between distance zero and the CM's equivalence are explicit.

A fixed global epsilon without a path law is not a compositional contract.

### 4.3 Grounding

Every nonzero tolerance, inflation, or uncertainty term identifies its basis:

```text
EMPIRICAL_MEASUREMENT
ANALYTIC_BOUND
PRIOR_CALIBRATION
CONSERVATIVE_POLICY
UNGROUNDED
```

`UNGROUNDED` values may be reported. They cannot support a standing-bearing verdict.

## 5 · Realization candidates and fibers

Partition evidence by role:

```text
D_train := D_fit ∪ D_calibration
D_test  := D_held_out ∪ D_intervention
```

Let `J_train` be the histories represented by the fitting and calibration regime. Let `J_eval` contain `J_train` plus every held-out or intervention history used for evaluation.

### 5.1 Fit and bounded candidate sets

Filter joint realization candidates before quotienting.

```text
C_M^fit(D) := {
  R ∈ R_M(D_train) |
  L_M(R,D_train) ≤ τ_M
}
```

```text
C_M^train(D) := {
  R ∈ C_M^fit(D) |
  K_M(R) ≤ κ_M
}
```

```text
F_M^train(D) := C_M^train(D) / ≃_M^J_train
```

Filtering before quotienting keeps generator-, atlas-, complexity-, and resource-sensitive claims well defined. Separating `C_M^fit` from `C_M^train` distinguishes failure to realize the evidence from realization only through candidates that exceed the declared budget.

### 5.2 Tested candidate set

Let:

```text
OracleResult := PASS | FAIL | UNRESOLVED | NOT_RUN
```

Evaluate every fixed bounded realization candidate without refitting:

```text
oracle_outcome_M(R,D_test) : OracleResult
```

Retain the outcome partition:

```text
C_M^pass(D) := {
  R ∈ C_M^train(D) |
  oracle_outcome_M(R,D_test) = PASS
}

C_M^fail(D) := {
  R ∈ C_M^train(D) |
  oracle_outcome_M(R,D_test) = FAIL
}

C_M^unresolved(D) := {
  R ∈ C_M^train(D) |
  oracle_outcome_M(R,D_test) ∈ {UNRESOLVED, NOT_RUN}
}
```

The tested candidate set is the passing set:

```text
C_M^test(D) := C_M^pass(D)
F_M^test(D) := C_M^test(D) / ≃_M^J_eval
```

When the oracle contract does not require held-out or intervention evidence, every candidate outcome is `NOT_RUN`, aggregate `TestStatus = NOT_RUN`, and the training fiber is not represented as held-out support.

### 5.3 Refinement map

Because `J_train ⊆ J_eval`, every tested equivalence class lies inside one training equivalence class. The receipt records:

```text
r_test→train : F_M^test(D) → F_M^train(D)
```

Evaluation may:

```text
remove realization candidates;
split a coarse training class into finer tested classes.
```

Therefore `F_M^test` is not generally a literal subset of `F_M^train`. The realization-candidate set satisfies:

```text
C_M^test(D) ⊆ C_M^train(D)
```

while the quotient fibers are related by `r_test→train`.

Test evidence does not silently alter fitted parameters, generator class, equivalence family, or complexity contract.

### 5.4 Index and provenance

Candidate sets, fibers, and the refinement map are indexed by:

```text
CM identity and digest
evidence roles and digests
J_train and J_eval
fit and oracle tolerances
complexity bound
equivalence-family digest
behavior contract
search claims
```

The receipt retains fit, bounded, passing, failing, and unresolved realization candidates—including their generator and atlas components—or verifiable references, in addition to equivalence classes.

### 5.5 Candidate classification

Training and test regimes are classified separately.

```text
RealizationStatus :=
  NO_REALIZATION_IN_MODEL
  | REALIZABLE_IN_MODEL
  | UNRESOLVED

BudgetStatus :=
  WITHIN_BUDGET
  | REALIZABLE_OVER_BUDGET
  | NOT_ESTABLISHED

IdentificationStatus :=
  IDENTIFIED_IN_MODEL
  | UNDERDETERMINED
  | NOT_ESTABLISHED

TestStatus :=
  NOT_RUN
  | PASSED
  | FAILED
  | UNRESOLVED
```

The receipt contains:

```text
TrainingCandidateClassification := (
  realization_status,
  budget_status,
  training_identification_status
)

TestCandidateClassification := (
  test_status,
  tested_identification_status
)
```

Classification rules:

```text
complete applicable fit search and C_M^fit empty
  → NO_REALIZATION_IN_MODEL

C_M^fit nonempty and C_M^train empty
  → REALIZABLE_IN_MODEL + REALIZABLE_OVER_BUDGET

C_M^train nonempty within a sufficiently strong search/equivalence contract
  → REALIZABLE_IN_MODEL + WITHIN_BUDGET
    + IDENTIFIED_IN_MODEL or UNDERDETERMINED

no required held-out/intervention oracle
  → TestStatus.NOT_RUN

required oracle incomplete, ungrounded, or search-limited
  → TestStatus.UNRESOLVED

at least one fixed bounded realization candidate passes every required test
  → TestStatus.PASSED

TestStatus.PASSED and C_M^unresolved empty
  → tested identification from F_M^test

TestStatus.PASSED and C_M^unresolved nonempty
  → tested identification NOT_ESTABLISHED

every required test is complete and grounded, C_M^pass is empty,
and every fixed bounded realization candidate is in C_M^fail
  → TestStatus.FAILED
    + tested identification NOT_ESTABLISHED

C_M^pass empty and C_M^unresolved nonempty
  → TestStatus.UNRESOLVED
    + tested identification NOT_ESTABLISHED
```

`UNDERDETERMINED` is not incoherence. `IDENTIFIED_IN_MODEL` is not absolute truth. A test failure is not relabeled `NO_REALIZATION_IN_MODEL`: the candidates realized the training evidence and failed the declared test.

### 5.6 Input refinement

Widening an independently chosen input family can remove realization candidates or split equivalence classes. A CM may claim refinement only when:

```text
the wider histories were permitted by the existing input contract;
the equivalence family satisfies refinement monotonicity;
fit, complexity, and oracle contracts remain fixed;
no realization candidate is refitted;
the refinement map is retained.
```

Changing the declared input language, intervention boundary, or model class is a lift, not refinement.

## 6 · Receipt evaluation envelope

Each verification receipt carries:

```text
ReceiptEvaluation :=
  COMPLETED
  | BLOCKED_BY(requirement_id)
  | NOT_REQUIRED
```

A role may produce local artifacts before its prerequisites are satisfied. Those artifacts cannot become an authoritative role status until evaluation is `COMPLETED`.

## 7 · Three non-substitutable receipts

TSC uses three differently typed proof obligations.

### 7.1 α — Manifestation receipt

The α receipt asks:

> Are the observations valid, complete enough for the stated claim, and stable under the declared local checks?

```text
ManifestationReceipt := (
  evaluation,
  observation ids and digests,
  channel and constructor identities,
  coverage and missingness,
  repeat or perturbation results,
  noise and uncertainty,
  invalid or out-of-domain evidence,
  status
)
```

Status:

```text
VALID | INCOMPLETE | INVALID
```

A missing observation is not positive evidence. An empty dataset receives no coherence disposition unless the CM explicitly defines an empty-input question.

### 7.2 β — Relational atlas

The β receipt asks:

> Do the observations, correspondences, and transformations form one globally compatible relational structure under the declared model?

```text
RelationalAtlas := (
  evaluation,
  relation-search contract and evidence,
  path contract and cross-step path checks,
  source-to-observation maps,
  observation-to-observation correspondences,
  alternative maps,
  map uncertainty,
  local residuals,
  path compositions,
  exact or approximate globalization checks,
  fit, bounded, and tested realization-candidate references,
  training and tested fibers,
  training and test candidate classifications,
  identification target and statuses,
  unresolved correspondences,
  status
)
```

The maps are primary evidence. A residual or scalar cannot replace them. Pairwise compatibility does not establish a global realization. A β diagram may relate `EVENTWISE` emissions, but it does not alter the generator's path contract or turn atlas-level connectivity into intrinsic generator succession.

An authoritative β result requires:

```text
α.status = VALID
α.evaluation = COMPLETED
```

Otherwise β is `BLOCKED_BY(α-validity)` even if local maps have been computed.

### 7.3 γ — Continuation receipt

The γ receipt asks:

> Does the generator in an applicable realization candidate continue lawfully under time, viewpoint, scale, intervention, or another declared transformation?

```text
CandidateContinuation :=
  LAWFUL_CONTINUATION
  | LAWFUL_TERMINATION
  | LAW_VIOLATION
  | INSUFFICIENT_EVIDENCE
```

```text
ContinuationReceipt := (
  evaluation,
  realization-candidate references,
  path contract and succession evidence,
  candidate-level continuation outcomes,
  input and intervention histories,
  predictions fixed before observation,
  held-out outcomes,
  state and identity transport,
  composition across paths,
  law violations,
  birth, merge, split, and termination events,
  status
)
```

Candidate-level outcomes remove or retain joint realization candidates in `C_M^test`.

Aggregate status:

```text
LAWFUL
  at least one realization candidate survives every required continuation test;
  mixed lawful-continuation and lawful-termination alternatives remain explicit

LAWFUL_TERMINATION
  the identified realization candidate, or every surviving realization candidate in a complete
  applicable set, predicts and matches a declared termination

LAW_VIOLATION
  the identified realization candidate, or every realization candidate in a complete applicable set,
  violates the declared law

INSUFFICIENT_EVIDENCE
  coverage, search, or continuation evidence cannot establish another status
```

When some realization candidates fail and others survive, failure refines the candidate set; it does not refute the entire model class.

An authoritative γ result requires:

```text
α.status = VALID
β establishes at least one applicable realization candidate
```

Otherwise γ is blocked by the missing prerequisite.

A lawful ending is not degraded coherence. Raw stasis is not process coherence.

### 7.4 Non-substitutability

The receipts are non-substitutable:

```text
β cannot validate missing or invalid observations;
α cannot establish a global relational realization;
α and β cannot erase a held-out law violation;
γ cannot create a realization candidate that β failed to establish.
```

This is a dependency claim, not statistical independence, algebraic non-isomorphism, or axis symmetry.

## 8 · Core axioms

### A1 — Scopedness

Every coherence claim names its CM, evidence, generator class, path contract, equivalence, behavior contract, approximation contract, complexity bound, search claims, and input/intervention family.

### A2 — Realizability

Distinct observations support one process only when at least one declared generator produces them within the fit and complexity contract.

Similarity among observations is neither necessary nor sufficient.

### A3 — Relation retention

Every correspondence, transformation, alternative, and path used to support realizability remains in the β receipt.

### A4 — Globality

Pairwise fits support a common process only when they satisfy the CM's full-diagram globalization rule.

### A5 — Non-vacuity

The generator class, representation language, and complexity contract are declared before fitting. A lookup table or tuple of observations receives no exemption from complexity and held-out obligations.

### A6 — Identifiability separation

Realizability, uniqueness, search completeness, input-family scope, and held-out support are separate facts.

### A7 — Law-relative continuation

Randomness is not incoherence. A stochastic process may be lawful under a stochastic CM. A negative control violates a declared law; it need not look disordered.

### A8 — Receipt primacy

Structured evidence remains normative until a quotient is proved sufficient for the exact decision. Incomplete search produces `UNRESOLVED`, not a fabricated negative result.

### A9 — Authority neutrality

Core classifies evidence. Its normative receipt schema contains no standing grant, admission verdict, or boundary decision. Operational may envelope a Core receipt with those later authorities; Core cannot issue them.

## 9 · Coherence disposition

### 9.1 Compatible in model

```text
COMPATIBLE_IN_MODEL
```

when:

```text
α = VALID
training realization_status = REALIZABLE_IN_MODEL
budget_status = WITHIN_BUDGET
at least one bounded realization candidate remains compatible with observed training evidence
```

Compatibility is a fit-regime result, not held-out support.

### 9.2 Supported in model

```text
SUPPORTED_IN_MODEL
```

when:

```text
α = VALID
TestStatus = PASSED
C_M^test(D) is nonempty
γ ∈ {LAWFUL, LAWFUL_TERMINATION}
all required oracle obligations pass for at least one fixed realization candidate
```

Support remains scoped to the declared CM and evidence regime.

### 9.3 Refuted in model

```text
REFUTED_IN_MODEL
```

when valid evidence establishes at least one of:

```text
training realization_status = NO_REALIZATION_IN_MODEL under a complete applicable search;

training realization_status = REALIZABLE_IN_MODEL,
TestStatus = FAILED, and C_M^test(D) is empty;

γ.evaluation = COMPLETED and γ.status = LAW_VIOLATION.
```

A violation by one member of an underdetermined realization-candidate set removes that member. It does not refute surviving candidates or the entire model class.

Refutation is scoped to the declared model class and test regime. A separate model-adequacy field may also report `CURRENT_MODEL_INSUFFICIENT` when a wider phenomenon claim remains open.

### 9.4 Unresolved

```text
UNRESOLVED
```

when any load-bearing obligation is incomplete, blocked, ungrounded, or search-limited.

### 9.5 Identification status

Identification is reported separately for the training and tested regimes:

```text
training_identification_status : IdentificationStatus
tested_identification_status   : IdentificationStatus
identification_target
identification_basis = training | tested
```

A compatible receipt may be underdetermined in training. A supported receipt may remain underdetermined after testing. A held-out refinement may change training `UNDERDETERMINED` into tested `IDENTIFIED_IN_MODEL`; both facts remain visible.

## 10 · Refinement, insufficiency, and lift

### 10.1 Evidence refinement

A refinement adds evidence, narrows uncertainty, or exercises more histories within an already declared input contract without changing:

```text
generator class
representation language
relation family
equivalence contract
complexity contract
```

It records the fixed prior realization-candidate set, the refinement map, and every realization candidate removed or class split. Generators and atlases are not refitted.

### 10.2 Current-model insufficiency

```text
CURRENT_MODEL_INSUFFICIENT
```

may be reported when:

```text
α observations are stable and valid;
the declared class cannot realize or globalize them,
or cannot answer a preregistered question;
the result is not explained by missing evidence,
ungrounded transforms, or search incompleteness.
```

### 10.3 Lift proposal

A lift changes the generator class, representation language, relation family, declared input language, or tested boundary. Before testing it declares:

```text
baseline class H_0
lifted class H_1
embedding or relation between classes
new degrees of freedom
complexity rule
preregistered baseline failure
acceptance margin
held-out query, future state, or intervention
```

### 10.4 Lift validation

```text
LIFT_VALIDATED
```

requires:

1. the baseline failure is reproduced;
2. the lifted class reduces that failure by the declared margin;
3. the gain survives the complexity cost;
4. the lifted realization candidate predicts held-out evidence without refitting;
5. uncertainty and dependence remain within contract;
6. maps and remaining alternatives remain in the receipt.

Otherwise the lift is `LIFT_REJECTED` or `LIFT_UNRESOLVED`.

## 11 · Optional scalar summaries

A CM may define a scalar for ranking or monitoring within one compatible context.

Every scalar declares:

```text
source receipt fields
scale type
admissible transformations
aggregation rule
calibration
status domain
```

A scalar cannot:

```text
turn UNDERDETERMINED into IDENTIFIED_IN_MODEL
turn UNRESOLVED into NO_REALIZATION_IN_MODEL
override LAW_VIOLATION
grant standing
authorize a boundary action
```

## 12 · Core receipt

A Core receipt contains at least:

```text
receipt_id
CM identity and digests
input and evidence digests
query/intervention boundary
path-contract digest and succession evidence
behavior contract
approximation-contract digest
α ManifestationReceipt
β RelationalAtlas
γ ContinuationReceipt
fit, bounded, passing, failing, and unresolved realization-candidate sets
training and tested fibers and refinement map
training and test candidate classifications
generator and relation search claims
test status and oracle evidence
fit and complexity accounting
equivalence contract
coherence disposition
training and tested identification statuses and target
model and lift status
uncertainty and grounding
provenance
```

Every conclusion points to the fields that support it.

## 13 · Conformance

The normative proof obligations for Core are defined in [`tsc-conformance.md`](tsc-conformance.md) under the `CORE-*` and `BETA-*` requirement IDs.
