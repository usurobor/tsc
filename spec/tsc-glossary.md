# TSC Glossary v4

**Version:** 4.0.0
**Status:** Informative

## Governing question

> What do the terms in the TSC specification mean?

The normative specifications govern when this glossary differs.

## Articulation

### Pole

A role-bearing endpoint in an articulation. A pole may be a state, context, observation, agent, boundary, pattern, or another domain-specific endpoint.

### Relation family

A dependent type:

```text
Rel : P × P → Set
```

For poles `s` and `o`, a value `φ : Rel(s,o)` is a well-typed relation from `s` to `o`.

### Articulation event

A typed source–relation–result event:

```text
Art := Σ(s:P).Σ(o:P).Rel(s,o)
art(s,φ,o)
```

### Coherer

The source role of an articulation event.

### Cohering

The dependent relation in an articulation event. Its type depends on both poles.

### Cohered

The result role of an articulation event. A cohered result may become a coherer in a later event.

### Unity

The wholeness of the complete typed event and its lawful continuation. Unity is not stored in one field.

### Mutual constitution

The static result that a well-formed articulation requires both poles and their relation. The signature does not derive the pole universe from relations.

### Role succession

The use of a result pole as the source pole of a later event through path composition. In an emitted stream this claim requires a declared `STATE_LINKED` path contract or another explicit diagram witness. Role succession is not free role permutation.

### Path

A finite composable sequence of typed articulation events. A path retains intermediate poles and relations.

### Diagram

A typed network of poles, relations, paths, alternatives, overlaps, and commutation conditions.

### Exact commutation

Equality of two composed paths with the same endpoints. Approximate comparison belongs to Core.

## Generative systems

### State space

The type or object `X` of concrete generator states.

### Input space

The type or object `I` of queries, conditions, or interventions supplied across the tested boundary.

### Open generator

For the deterministic Set kernel:

```text
c : X × I → Art × X
```

It emits one articulation and one successor state.

### Set presentation

A pointed deterministic presentation:

```text
(X,I,c,x_0,path_contract)
```

### General presentation

A category-specific presentation with a system functor, state object, structure map, pointed-state witness, and typed articulation interface.

### Path contract

A declaration of whether consecutive generator emissions are claimed to form a composable path:

```text
EVENTWISE
STATE_LINKED { pole_of : X → P }
```

`EVENTWISE` preserves each typed event but makes no succession claim. `STATE_LINKED` requires every transition `c(x,i)=(a,x')` to satisfy `src(a)=pole_of(x)` and `dst(a)=pole_of(x')`.

### Query mode

```text
exogenous | endogenous | mixed
```

It states where queries or interventions originate relative to the tested boundary.

### Unfolding

Repeated application of a generator along an input history.

### Reflexive generator

A generator whose emitted events or successor states alter the conditions of later articulation.

## Coalgebraic behavior

### System functor

For the deterministic Set kernel:

```text
F_I(Y) := (Art × Y)^I
```

with morphism action:

```text
F_I(h)(k)(i) := let (a,y)=k(i) in (a,h(y))
```

### Coalgebra

A state object with a structure map `c : X → F(X)`.

### Coalgebra morphism

A map `h : X → Y` satisfying:

```text
F(h) ∘ c = d ∘ h
```

### Input history

A finite sequence of inputs. `I*` includes the empty history; `I+` contains nonempty histories.

### Set-final behavior

For the deterministic Set functor:

```text
B_I := Art^(I+)
```

It records the output on the final transition of every nonempty finite input history.

### Behavior map

The unique coalgebra morphism from a concrete deterministic Set generator to `B_I`.

### State-linked behavior witness

For a `STATE_LINKED(pole_of)` presentation, the pair `(pole_of(x), beh_c(x))` proves that each first event begins at the current pole and each later event begins where the previous event ended. The ambient final behavior space also contains eventwise behaviors; the path witness remains presentation-sensitive evidence.

### Final coalgebra

A coalgebra receiving one unique coalgebra morphism from every coalgebra for the same functor.

### Lambek law

The structure map of a final coalgebra is an isomorphism. The law applies to the final behavior object, not automatically to a concrete generator.

### Finality basis

```text
SET_FINAL | GENERAL_FINAL | NO_FINALITY_CLAIM
```

It states what universal behavior claim, if any, the CM makes.

### SET_FINAL

The canonical deterministic Set finality construction from C≡.

### GENERAL_FINAL

A category-specific finality claim carrying a complete functor and finality witness.

### Behavior access

```text
COMPLETE_SYMBOLIC | FINITE | APPROXIMATE
```

It states what part of behavior an execution can compute or observe. It is independent of the finality basis.

## Equivalence and approximation

### Presentation equivalence

Equivalence preserving concrete generator structure, initial state, and typed behavior.

### Behavioral equivalence

Equivalence induced by observable behavior.

### Input-indexed equivalence

Equivalence relative to a declared passive or active input-history family.

### No premature quotient

The rule that structured evidence remains normative until a reduction is proved sufficient for the downstream decision.

### Commutative-fold blindness

The theorem that an associative commutative fold over leaf values cannot distinguish internal tree shape, depth, grouping, path, or order.

### Approximation contract

The Core-owned contract relating local error budgets, path accumulation, behavioral distance, and grounding.

### Tolerance monoid

```text
(E, ⊕, 0, ≤)
```

A structure for accumulating local error budgets along a path.

### Behavioral metric

A metric or pseudometric used to compare observed and predicted behavior under the approximation contract.

### Grounding basis

The evidence or derivation supporting an uncertainty or tolerance term.

## Coherence methodologies

### Coherence Methodology (CM)

A versioned instrument that declares how a domain is observed, modeled, searched, tested, compared, and receipted.

### Generator class

The declared class `H_M` of candidate behavior presentations before an observation atlas is attached.

### Observation channel

A declared way of observing a target or realization candidate, with an observation type, constructor, uncertainty rule, and provenance.

### Atlas-candidate class

For generator `G` and evidence `D`, `A_M(G,D)` is the declared class of admissible correspondence and transformation atlases considered by relation search.

### Realization candidate

A joint explanation:

```text
R = (G,A)
```

containing a concrete generator presentation and the atlas through which it accounts for the observation episodes. Candidate fibers range over realization candidates, not bare generators.

### Evidence item

A grounded observation with input history, channel, value, uncertainty, provenance, and holdout role.

### Search claim

```text
complete
complete_within_bound
heuristic
sampled
```

It states what absence or completeness conclusions a search can support.

### Relation-search contract

The declaration and receipt for correspondence-map search, including alternatives, pruning, uncertainty, and orchestration with generator search.

### Fit

The CM-defined relation or loss between joint realization-candidate predictions and training evidence.

### Complexity

A representation-, prior-, or resource-relative cost on the complete realization candidate, including nontrivial atlas choices.

### Oracle

The preregistered rule judging held-out or interventional evidence without refitting.

### Calibration

Bounded execution over repeats, controls, malformed inputs, refusals, and anchors to characterize a methodology.

### CM0

A methodology that assesses candidate CMs as instruments. CM0 does not compile, admit, authorize, or perform the boundary decision by itself.

## Candidate reasoning

### Fit candidate set

`C_M^fit`: joint realization candidates satisfying the fit bound before the complexity filter.

### Bounded training set

`C_M^train`: fitting realization candidates satisfying the complexity bound.

### Oracle outcome partition

The fixed bounded realization candidates separated into `C_M^pass`, `C_M^fail`, and `C_M^unresolved` by preregistered oracle outcomes without refitting.

### Tested candidate set

`C_M^test := C_M^pass`: the passing realization candidates used to form the tested fiber.

### Candidate fiber

An equivalence-class quotient of a realization-candidate set under the declared input-indexed equivalence.

### Refinement map

The map from finer tested classes to coarser training classes when the evaluation input family widens.

### Training candidate classification

The product of realization, budget, and training-identification statuses for the fit and bounded training regime.

### Test candidate classification

The product of `TestStatus` and tested-identification status for fixed realization candidates under held-out or interventional evidence. A passing candidate can support the model while unresolved alternatives keep tested identification `NOT_ESTABLISHED`.

### Identification target

What one-class identification refers to: the generator, the atlas, the joint realization, or another CM-declared target.

### No realization in model

A complete applicable search proves `C_M^fit` empty.

### Realizable over budget

At least one joint realization candidate fits, but none satisfies the complexity bound.

### Underdetermined

More than one inequivalent realization class remains in the named regime.

### Identified in model

Exactly one realization class remains for the named identification target and regime under the declared CM, input family, equivalence, bounds, and search claims.

### Unresolved

The evidence, search, equivalence, approximation, or prerequisites cannot establish another status.

### Compatible in model

At least one bounded realization candidate accounts for training evidence. Compatibility is not held-out support.

### Supported in model

At least one fixed bounded realization candidate survives every required held-out or intervention oracle and continues lawfully.

### Refuted in model

The declared class or claim fails under complete, grounded evidence and the stated test regime.

### Current-model insufficiency

The declared class cannot realize, globalize, or answer a preregistered question, while evidence and search are adequate to localize the failure to the model.

### Evidence refinement

New evidence removes fixed realization candidates or splits equivalence classes without changing the model contract or refitting.

### Model lift

A preregistered change to the generator class, representation, relation family, declared input language, or tested boundary.

### Validated lift

A lift that reproduces the baseline failure, survives complexity control, meets its acceptance margin, and predicts held-out or interventional evidence.

## Verification receipts

### Receipt evaluation

```text
COMPLETED | BLOCKED_BY(requirement_id) | NOT_REQUIRED
```

It distinguishes a role status from whether the role was authorized to issue that status.

### α — Manifestation receipt

Evidence that observations are valid, complete enough, repeatable, and uncertainty-bounded.

### β — Relational atlas

The record of relation search, maps, alternatives, global compatibility, joint realization-candidate sets, fibers, and identification.

### γ — Continuation receipt

Candidate-level and aggregate evidence of lawful continuation, violation, intervention response, and termination.

### Non-substitutability

No receipt may discharge the proof obligation owned by another. The dependency is asymmetric; it is not statistical independence.

### Receipt

The proof-carrying result of a measurement.

### Scalar summary

An optional CM-local projection of a complete receipt. It cannot override structured status or grant authority.

## Observation Dynamics

### Observation episode

A value together with the boundary, methodology, input history, channel, uncertainty, provenance, time, and holdout role that produced it.

### Lineage

The content-addressed parent relation among evidence, transformations, candidates, receipts, comparisons, refinements, lifts, and dispositions.

### Dependence graph

The record of shared sources, parameters, prompts, time windows, calibration anchors, and preprocessing.

### Comparison compatibility

The condition that two receipts share or validly transport every load-bearing measurement contract.

### Failure disposition

```text
RESOLVED | CLAIM_WITHDRAWN | SUPERSEDED | INVALIDATED | UNRESOLVED
```

### Failure persistence

The rule that a failed receipt cannot disappear when a later theory, methodology, or runtime changes the claim.

## Runtime authority

### Compilation

Normalization and validation of CM source into a runtime descriptor. Compilation grants structural executability only.

### Instrument assessment

CM0 measurement of a compiled candidate methodology.

### Admission verdict

`V`'s pass/fail judgment against an admission contract.

### Boundary decision

`δ`'s action following the evidence and verdict.

### Standing

The scope-bounded epistemic authority earned by a methodology or result.

### Verdict authorization

Whether a receipt may drive the declared boundary use.

## Conformance

### Conformance requirement

A stable normative proof obligation with an owner, positive oracle, and negative oracle.

### Conformance fixture

A reproducible domain package implementing requirement IDs with a generator, independent oracle, and positive/negative cases.

### Illustration

A conceptual example with no normative expected result.

### Regression fixture

An artifact pinning implementation behavior without establishing general truth.

### Calibration anchor

A labeled case with provenance and standing scope used to characterize a methodology.

### Experiment

A preregistered claim test with retained result and lineage.
