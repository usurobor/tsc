# TSC Glossary v4

**Version:** 4.0.0
**Status:** Informative

## Governing question

> What do the terms in the TSC specification mean?

This glossary explains the normative vocabulary. The specifications govern when this guide and a specification differ.

---

## Articulation

### Pole

A role-bearing endpoint in an articulation.

A pole may be a state, context, observation, agent, boundary, pattern, or another domain-specific endpoint. A pole is not assumed to be a material object.

### Relation family

A dependent type:

```text
Rel : P × P → Set
```

For poles `s` and `o`, a value:

```text
φ : Rel(s,o)
```

is a well-typed relation from `s` to `o`.

### Articulation event

A typed source–relation–result event:

```text
Art := Σ(s : P). Σ(o : P). Rel(s,o)
```

Write:

```text
art(s, φ, o)
```

or:

```text
s --φ→ o
```

The event is one occurrence with three dependent roles. The relation is typed by both poles.

### Coherer

The source role of an articulation event.

The coherer supplies the state, condition, constraint, or context from which the event proceeds.

### Cohering

The dependent relation in an articulation event.

Cohering is not a third independent object. Its type depends on the coherer and cohered poles that it relates.

### Cohered

The result role of an articulation event.

A cohered result may become a coherer in a later event.

### Unity

The wholeness of the typed articulation event and its lawful continuation.

Unity is not stored in one field. Removing the relation or either pole destroys the event's type.

### Path

A composable sequence of articulation events:

```text
s_0 --φ_1→ s_1 --φ_2→ ... --φ_n→ s_n
```

The composite relation is:

```text
φ_n ∘ ... ∘ φ_1 : Rel(s_0,s_n)
```

### Diagram

A finite or generated network of poles and typed relations.

A diagram records more than its endpoints. Its paths, overlaps, alternatives, and commutation conditions carry relational evidence.

### Commutation

Agreement between two paths with the same source and target, under the declared exact or approximate equality.

Commutation is a global compatibility condition. Pairwise fit alone does not imply it.

---

## Generative systems

### State space

The type `X` of concrete generator states.

A state may contain latent variables, parameters, memory, current configuration, or other information needed for continuation.

### Input space

The type `I` of queries, conditions, or interventions supplied at the tested boundary.

An input is exogenous only relative to the declared model boundary.

### Open generator

A transition-and-output map:

```text
c : X × I → Art × X
```

For state `x` and input `i`, the generator emits one typed articulation event and a successor state.

### Pointed generator

A generator together with an initial state:

```text
G = (X, I, c, x_0)
```

The law without its state need not determine a particular behavior.

### Query mode

How a methodology treats the source of queries:

```text
exogenous
endogenous
mixed
```

An endogenous query is generated inside the system. An exogenous input is supplied across the tested boundary. A mixed system uses both.

### Unfolding

Repeated application of a generator along an input history.

An unfolding retains the emitted events and successor states. It is not reduced to a final score.

### Coalgebra

A system whose structure map exposes one observation step and continuation.

For:

```text
F_I(Y) := (Art × Y)^I
```

an open generator is equivalently a coalgebra:

```text
c : X → F_I(X)
```

### Final behavior

A final coalgebra:

```text
ζ : νF_I → F_I(νF_I)
```

when it exists in the declared category.

`νF_I` is a universal space of complete input-conditioned behavior. A concrete generator is not presumed to be final.

### Behavior map

The unique coalgebra morphism:

```text
beh_c : X → νF_I
```

when final behavior exists.

It satisfies:

```text
ζ ∘ beh_c = F_I(beh_c) ∘ c
```

The equation states that concrete unfolding and behavioral interpretation agree step by step.

### Lambek law

The structure map of a final coalgebra is an isomorphism:

```text
ζ : νF_I ≅ F_I(νF_I)
```

At final behavior, complete behavior and one articulation plus continuation are mutually recoverable. The law does not imply that every concrete generator is final.

### Finite behavior

A bounded unfolding used when final behavior is unavailable, unnecessary, or not established.

A methodology must state the horizon and what claims the finite approximation supports.

---

## Equivalence and approximation

### Presentation equivalence

Equivalence between two concrete generator presentations under declared state, pole, relation, and input transports.

Presentation equivalence preserves implementation-sensitive structure.

### Behavioral equivalence

Equivalence between states that produce the same declared behavior under the tested input family.

Behavioral equivalence can identify different concrete presentations.

### Input-indexed equivalence

Behavioral equivalence relative to a particular passive or active input family.

Widening the input family can separate generators that were equivalent under a narrower family.

### Behavioral metric

A distance on behavior that replaces exact equality in empirical settings.

A methodology declares the metric, its domain, and the relation between distance zero and its equivalence notion.

### Tolerance monoid

A structure for composing local error budgets along a path:

```text
(E, ⊕, 0, ≤)
```

The operation `⊕` may be addition, maximum, root-sum-square, probabilistic convolution, or another declared and justified law.

### Path budget

The composed tolerance allowed for a path.

A path budget and a behavioral metric must be compatible. A budget without an endpoint comparison rule has no operational meaning.

### No premature quotient

The rule that structured evidence must be retained until a reduction is proved sufficient for the downstream decision.

Counts, residuals, final behaviors, and scalar scores are all quotients. Each may erase information that later claims require.

---

## Coherence methodologies

### Coherence Methodology (CM)

A versioned instrument that declares how a domain is observed, modeled, compared, tested, and receipted.

A CM defines:

```text
input and observation contract
generator class
relation and equivalence contract
fit and approximation contract
complexity contract
oracle contract
receipt schema
execution and permission bindings
```

### Generator class

The declared class `H_M` of candidate generator presentations that a CM may consider.

The class bounds what may count as an explanation.

### Observation channel

A declared way of observing a target or generator.

Each channel has an observation type, production rule, uncertainty rule, and provenance.

### Evidence item

A grounded observation together with its channel, role, uncertainty, provenance, and holdout status.

### Fit

The CM-defined relation or loss between candidate predictions and evidence.

Fit is not coherence by itself. A flexible or unbounded candidate can fit without explaining.

### Complexity

A declared cost or bound on a candidate presentation.

Complexity is relative to a coding language, prior, architecture, or resource model. It is not representation-free.

### Oracle

The rule that decides whether a held-out prediction, intervention, or control succeeded.

The oracle is declared before the result it judges.

### Calibration

Bounded execution of a CM over repeats, controls, malformed inputs, and held-out anchors to characterize the instrument.

Calibration may produce evidence for admission or standing. It does not by itself authorize target verdicts.

### CM0

A methodology that assesses candidate CMs as instruments.

CM0 measures instrument coherence. It does not compile, admit, authorize, or execute a candidate on target data by itself.

---

## Candidate reasoning

### Candidate fiber

The set of candidate generator equivalence classes compatible with the evidence under one CM:

```text
F_M(D)
```

The fiber is indexed by the methodology, input family, equivalence, tolerances, complexity bound, and evidence.

### No realization in model

The candidate fiber is proved empty within the declared class and search claim.

Failure to find a candidate is not a proof of emptiness.

### Underdetermined

The candidate fiber contains more than one inequivalent candidate.

Underdetermination is not incoherence. It means the evidence does not identify one generator under the declared model.

### Identified in model

The candidate fiber contains one equivalence class under the declared evidence and input family.

Identification is always model-relative and input-relative.

### Unresolved

The available evidence or search cannot establish whether the fiber is empty, multiple, or identified.

### Compatible in model

At least one bounded candidate accounts for the evidence used to construct it, with no observed law violation.

Compatibility is a training- or fit-regime result. It is not held-out support.

### Supported in model

At least one candidate survives the CM's required held-out or intervention oracle without refitting and continues lawfully.

Support remains scoped to the declared methodology and evidence regime.

### Refuted in model

The declared model is contradicted by a proved empty applicable fiber or a law violation under valid evidence.

Refutation applies to the declared generator class and test regime, not to every possible model of the phenomenon.

### Current-model insufficiency

Stable evidence defeats the declared generator class or leaves a preregistered question unanswerable, without warranting a claim that the phenomenon itself is incoherent.

### Model lift

A preregistered expansion of the generator class, representation, inputs, or relations intended to resolve a measured insufficiency.

### Validated lift

A lift that reduces the preregistered insufficiency by the declared margin, survives complexity control, and predicts held-out observation or intervention results.

A richer model fitting the training evidence is not enough.

---

## Verification receipts

### α — Manifestation receipt

Evidence that observations are valid, complete enough, repeatable, and uncertainty-bounded.

α asks whether the manifestations themselves can bear the later inference.

### β — Relational atlas

The normative record of correspondences, transformations, alternatives, uncertainties, path checks, global compatibility, and the candidate fiber.

β asks whether distinct manifestations can belong to one lawful generator under the declared model.

### γ — Continuation receipt

Evidence of lawful continuation through time, viewpoint, scale, migration, or intervention.

γ retains predictions, identity transport, law violations, and lawful termination.

### Receipt

The proof-carrying result of a measurement.

A receipt retains the generator presentation, behavior reference, evidence, atlas, candidate alternatives, continuation tests, uncertainty, standing, and provenance.

### Scalar summary

An optional numerical projection of a receipt.

A scalar is local to a declared CM and categorical status. It cannot replace the receipt or override no-realization, underdetermination, unresolved search, law violation, or standing.

---

## Runtime authority

### Compilation

Normalization and validation of authored CM source into a runtime descriptor.

Compilation establishes structural executability. It does not establish instrument quality or epistemic authority.

### Instrument assessment

CM0 measurement of a compiled candidate methodology using calibration evidence.

### Admission

A validator decision that assessment evidence satisfies an admission contract.

### Authorization

A boundary decision that grants a specific permitted use and standing scope.

### Sandbox execution

Bounded pre-admission execution used to gather calibration and discrimination evidence.

### Target execution

Application of an authorized CM to compatible target input.

### Standing

The scope of epistemic authority earned by a methodology or receipt.

Standing does not follow from compilation, self-assessment, or publication alone.

### Verdict authorization

Whether a receipt may cross the declared decision boundary.

A measurement may contain useful findings while lacking verdict authority.
