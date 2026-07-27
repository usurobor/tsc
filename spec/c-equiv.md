# C≡ v4 — Typed Articulation and Generative Unfolding

**Version:** 4.0.0
**Status:** Draft
**Artifact:** Normative foundation

## Governing question

> What is the smallest formal structure that represents one process articulating as distinguishable poles through a relation, and continuing to articulate?

C≡ answers with a typed articulation event and an open generator. It defines exact articulation, composition, unfolding, behavior, and equivalence. It does not define a universal coherence score.

## 1 · Universe and typed articulation

### 1.1 Set universe

Fix a set universe `U` closed under:

```text
finite products
dependent sums
finite sequences
nonempty finite sequences
function spaces between members of U
```

Unless another carrier category is declared, every type below is an object of `U`.

### 1.2 Pole category

Let `P : U` be a type of poles. A pole is a role-bearing endpoint in an articulation. It may represent a state, context, observation, agent, pattern, boundary, or another domain-specific endpoint.

Let:

```text
Rel : P × P → U
```

be a dependent relation family. For `s,o : P`, an inhabitant:

```text
φ : Rel(s,o)
```

is a cohering relation from `s` to `o`.

For every `s : P`, there is an identity relation:

```text
id_s : Rel(s,s)
```

For:

```text
φ : Rel(s,o)
ψ : Rel(o,u)
```

there is a composite:

```text
ψ ∘ φ : Rel(s,u)
```

satisfying:

```text
id_o ∘ φ = φ
φ ∘ id_s = φ
χ ∘ (ψ ∘ φ) = (χ ∘ ψ) ∘ φ
```

`P` with `Rel`, identities, and composition is a small category of articulations.

### 1.3 Articulation event

Define:

```text
Art := Σ(s : P). Σ(o : P). Rel(s,o)
```

Write an event as:

```text
art(s, φ, o)
```

or:

```text
s --φ→ o
```

The event has three dependent roles:

```text
s                coherer / source pole
φ : Rel(s,o)     cohering relation
o                cohered / result pole
```

The relation is not a third peer beside two poles. Its type depends on both endpoints. Free permutation of source, relation, and result is ill typed.

Unity belongs to the complete event. No component stores unity by itself.

### 1.4 Event projections

Every `a : Art` has projections:

```text
src(a) : P
dst(a) : P
rel(a) : Rel(src(a), dst(a))
```

and:

```text
a = art(src(a), rel(a), dst(a))
```

The dependent-sum representation is lossless.

### 1.5 Scope of relational priority

The static signature requires poles and relation together for a well-formed event. It does not derive the pole universe from relations and does not assign ontological priority among the dependent roles.

The generator below emits complete articulation events. The particular poles of an emitted event are outputs of an unfolding, not independent inputs to that event.

## 2 · Paths and diagrams

### 2.1 Path

A path is a finite composable sequence:

```text
s_0 --φ_0→ s_1 --φ_1→ ... --φ_(n-1)→ s_n
```

Its composite is:

```text
φ_(n-1) ∘ ... ∘ φ_1 ∘ φ_0 : Rel(s_0,s_n)
```

A path retains its intermediate poles and relations. The composite alone cannot replace the path when a later claim depends on order, mechanism, complexity, local error, or provenance.

### 2.2 Diagram

A diagram is a typed collection of poles, relations, and composable paths. It may contain:

```text
several observations of one process
alternative correspondences
temporal transitions
interventions and responses
nested or concurrent articulations
unresolved relations
```

The number of observations is not fixed. Triadicity belongs to each typed event, not to the cardinality of a diagram.

### 2.3 Exact commutation

Two paths with the same endpoints commute when their composites are equal:

```text
compose(p) = compose(q)
```

C≡ defines exact commutation only. Empirical approximation, tolerance, and behavioral distance belong to Core. Approximate measurement still retains the compared paths.

## 3 · Open generators

### 3.1 State and input

Let:

```text
X : U
I : U
```

`X` is the concrete generator state. `I` is the query, condition, or intervention supplied across the declared generator boundary.

### 3.2 Generator

A deterministic open generator is:

```text
c : X × I → Art × X
```

For:

```text
c(x,i) = (a,x')
```

one application of `c`:

1. emits articulation event `a`;
2. continues as state `x'`.

A pointed generator presentation is:

```text
G := (X, I, c, x_0, path_contract)
```

where `x_0 : X` is the initial or current state under examination and `path_contract` declares whether successive emissions are claimed to form a path.

### 3.3 Path contract

Every generator presentation declares exactly one:

```text
PathContract :=
  EVENTWISE
  | STATE_LINKED {
      pole_of : X → P
    }
```

`EVENTWISE` means that each emitted value is a well-typed articulation event, but no claim is made that consecutive emissions compose as one path.

`STATE_LINKED` means that the concrete state carries the pole at which the next articulation begins. It requires, for every transition:

```text
c(x,i) = (a,x')

src(a) = pole_of(x)
dst(a) = pole_of(x')
```

Under `STATE_LINKED`, every finite unfolding emits a composable path. A methodology may establish another path relation among emitted events through an explicit diagram or category-specific witness, but it may not describe consecutive emissions as role succession without such a contract.

### 3.4 Query ownership

Every generator presentation declares:

```text
query_mode = exogenous | endogenous | mixed
```

- `exogenous` — the relevant query enters through `I`;
- `endogenous` — the query is generated within `X` or emitted in `Art`;
- `mixed` — both occur and their boundary is explicit.

A query generated by the candidate process is not an independent intervention merely because its answer was not recorded in advance.

### 3.5 Finite unfolding

Let `I* : U` be the set of finite input histories, including the empty history `[]`. Let `I+ : U` be the set of nonempty finite histories supplied directly by the universe closure in §1.1.

Given:

```text
i_0, i_1, ..., i_(n-1)
```

repeated application yields:

```text
x_0 --i_0/a_0→ x_1 --i_1/a_1→ ... --i_(n-1)/a_(n-1)→ x_n
```

Define:

```text
run_n(G, i_0...i_(n-1))
  = (a_0...a_(n-1), x_0...x_n)
```

The empty history denotes the initial state before any input. The unfolding retains emitted events and concrete states unless a declared quotient is proved sufficient for the downstream claim.

When `path_contract = STATE_LINKED(pole_of)`, the same unfolding carries the composable articulation path:

```text
pole_of(x_0) --rel(a_0)→ pole_of(x_1)
             --rel(a_1)→ ...
             --rel(a_(n-1))→ pole_of(x_n)
```

For `EVENTWISE`, the trace remains an ordered sequence of typed events and states but does not acquire a path-composition claim by implication.

### 3.6 Reflexivity

A generator is reflexive when emitted events or successor states alter the conditions of later articulation. Reflexivity is represented by recurrence through `X`; it does not require the generator to be closed to external input.

## 4 · The deterministic Set functor

### 4.1 Object action

For fixed `Art` and `I`, define:

```text
F_I(Y) := (Art × Y)^I
```

An element `k : F_I(Y)` maps each input `i : I` to one articulation and one continuation in `Y`.

### 4.2 Morphism action

For `h : Y → Z`, define:

```text
F_I(h) : F_I(Y) → F_I(Z)

F_I(h)(k)(i) :=
  let (a,y) = k(i)
  in (a, h(y))
```

### 4.3 Functor laws

For every `Y`:

```text
F_I(id_Y) = id_(F_I(Y))
```

For `h : Y → Z` and `g : Z → W`:

```text
F_I(g ∘ h) = F_I(g) ∘ F_I(h)
```

Both laws follow pointwise from function extensionality and the product action above.

### 4.4 Coalgebra form

Currying identifies the open generator with an `F_I`-coalgebra:

```text
c : X → F_I(X)
```

A coalgebra morphism from `c : X → F_I(X)` to `d : Y → F_I(Y)` is a map `h : X → Y` satisfying:

```text
F_I(h) ∘ c = d ∘ h
```

## 5 · Exact final behavior in Set

### 5.1 Behavior object

Define:

```text
B_I := Art^(I+)
```

A behavior `b : B_I` assigns the articulation emitted on the final transition of every nonempty finite input history. `B_I` is complete for the transition-output functor `F_I`; it does not by itself encode an additional observation of the pointed state at the empty history.

### 5.2 Final structure

Write `[i]` for a one-input history and `i · w` for `i` prepended to nonempty history `w`.

Define:

```text
ζ : B_I → F_I(B_I)

ζ(b)(i) = (b([i]), b_i)
b_i(w) = b(i · w)
```

### 5.3 Behavior map

For any coalgebra `c : X → F_I(X)`, define:

```text
beh_c : X → B_I
```

recursively. For every `i : I`, every nonempty `w : I+`, and:

```text
c(x)(i) = (a,x')
```

set:

```text
beh_c(x)([i])  := a
beh_c(x)(i·w)  := beh_c(x')(w)
```

These equations define the articulation emitted on the final transition of every nonempty input history.

### 5.4 State-linked behavior witness

For `p : P` and `b : B_I`, define `Path_I(p,b)` by:

```text
for every i : I:
  src(b([i])) = p

for every u : I+ and i : I:
  dst(b(u)) = src(b(u ⧺ [i]))
```

where `u ⧺ [i]` appends `i` to history `u`.

If `c` carries `STATE_LINKED(pole_of)`, then for every `x : X`:

```text
Path_I(pole_of(x), beh_c(x))
```

The proof follows directly from the two endpoint equations in §3.3. Thus the categorical path structure constrains the image of a state-linked behavior map even though the ambient final coalgebra `B_I` also contains eventwise behaviors. The presentation retains `pole_of(x)`; C≡ does not silently quotient this witness away or claim a separate finality theorem for the state-linked subcategory.

### 5.5 Finality theorem

`(B_I,ζ)` is a final `F_I`-coalgebra in `Set`.

For every `c : X → F_I(X)`:

```text
ζ ∘ beh_c = F_I(beh_c) ∘ c
```

and `beh_c` is the unique map satisfying this equation.

**Proof.** For `c(x)(i)=(a,x')`, both sides at input `i` have first component `a`. Their continuation components agree because:

```text
beh_c(x)_i(w) = beh_c(x)(i · w) = beh_c(x')(w)
```

for every nonempty `w`. Uniqueness follows by induction on history length: the commuting equation fixes every one-step output and recursively fixes every longer output through the continuation component. ∎

### 5.6 Lambek law

Because `(B_I,ζ)` is final, the structure map is an isomorphism:

```text
ζ : B_I ≅ F_I(B_I)
```

Complete deterministic Set behavior is mutually recoverable with one input-indexed articulation and its continuation.

A concrete generator is not presumed final or invertible.

## 6 · Other behavior foundations

The exact construction above applies when:

```text
P, I, X, and every Rel(s,o) are objects of one declared Set universe;
Art is their dependent sum;
the generator is the deterministic map X × I → Art × X;
the canonical F_I action is used.
```

A continuous state or input space may satisfy this contract as an underlying set.

A methodology that requires another carrier category or another system functor declares:

```text
carrier category
object action
morphism action
functor laws
pointed-state contract
behavior object
finality witness, when finality is claimed
typed articulation interface
```

When the category has a terminal object, the pointed-state contract may be a generalized element `x_0 : 1 → X`. Another category may use a different explicit state witness.

Stochastic, nondeterministic, measurable, topological, metric-enriched, or other structures do not inherit the deterministic Set construction by notation alone.

A methodology may make no finality claim and use a finite or approximate behavior construction. It states the retained information and supported claims.

## 7 · Equivalence

### 7.1 Presentation equivalence

Two deterministic Set presentations:

```text
G  = (X, I, c, x_0)
G' = (X', I, c', x'_0)
```

are presentation-isomorphic when there is a declared isomorphism:

```text
h : X ≅ X'
```

such that:

```text
h(x_0) = x'_0
(id_Art × h) ∘ c = c' ∘ (h × id_I)
```

with any required transports of poles, relations, or inputs stated explicitly.

Path contracts are also preserved:

```text
EVENTWISE maps only to EVENTWISE;

STATE_LINKED(pole_of) maps to STATE_LINKED(pole_of') only when
pole_of' ∘ h = pole_of.
```

A change of path mode requires a separately declared semantic transport; it is not presentation isomorphism by default.

### 7.2 Behavioral equivalence

Under exact Set behavior:

```text
x ~_beh y  iff  beh_c(x) = beh_c(y)
```

Behavioral equivalence intentionally forgets presentation differences that do not alter emitted transition behavior. A CM that observes the pointed state at `[]` refines this equivalence through its input-indexed observation contract.

### 7.3 Input-indexed equivalence

For a declared input family `J ⊆ I*`, two pointed presentations are `J`-equivalent when the methodology's observation rule cannot distinguish them on any history in `J` under its declared tolerance.

`J` may contain `[]`, allowing the methodology to compare observations of the initial state before a transition. Identifiability is always indexed by the declared passive and active input family. It is never absolute.

### 7.4 Presentation retention

A behavior point cannot replace its concrete presentation when a claim depends on:

```text
mechanism
implementation
complexity or code length
resource cost
causal response
intervention boundary
migration
provenance
```

The normative evidence retains both presentation and behavior relation.

## 8 · Quotients and structural sufficiency

### 8.1 No premature quotient

A quotient may replace structured evidence only when the methodology proves it sufficient for the exact downstream decision.

Without that proof, the quotient is a summary and the structured source remains normative.

### 8.2 Commutative-fold blindness

Let `T(A)` be a finite rooted tree algebra with leaves labeled by `A`. Let:

```text
E(leaf(a)) = w_a
E(node(t_1,...,t_k)) = E(t_1) ⊗ ... ⊗ E(t_k)
```

where `(M,⊗,1)` is an associative commutative monoid.

Then `E` factors through the finite multiset of leaf labels. It cannot distinguish:

```text
sibling order
grouping
path shape
depth
internal-node identity
```

An evaluator claiming shape, depth, order, or path sensitivity retains internal-node structure or uses another construction whose sufficiency is proved.

### 8.3 Scalar summaries

A scalar may summarize structured evidence after the downstream categorical status is established. A scalar cannot by itself distinguish:

```text
no realization
several realizations
one identified realization
search incomplete
lawful termination
law violation
```

## 9 · Symmetry

### 9.1 Presentation gauge

A serialization may reorder stored fields when role labels, endpoints, and relation typing move with them and the decoded event is unchanged.

This is presentation gauge.

### 9.2 Semantic roles

Source, relation, and result are not freely permutable semantic peers.

A semantic transport is valid only when a declared isomorphism preserves:

```text
pole roles
relation types
composition
generator behavior
observation meaning
```

No unrestricted semantic `S₃` action is assumed.

### 9.3 Role succession

Role succession is a typed path claim, not an automatic property of every emission stream.

For a `STATE_LINKED(pole_of)` generator, consecutive emissions satisfy:

```text
src(a_k)     = pole_of(x_k)
dst(a_k)     = pole_of(x_(k+1))
src(a_(k+1)) = pole_of(x_(k+1))
```

and therefore form:

```text
pole_of(x_k) --rel(a_k)→ pole_of(x_(k+1))
             --rel(a_(k+1))→ pole_of(x_(k+2))
```

The cohered pole of one event is thereby the coherer pole of the next. An `EVENTWISE` generator makes no such cross-step claim unless a separate diagram witness establishes it. Role succession across events never implies role permutation within one event.

## 10 · Conformance

The normative proof obligations for this foundation are defined in [`tsc-conformance.md`](tsc-conformance.md) under the `FND-*` requirement IDs.

C≡ supplies semantics. Conformance supplies the permanent positive and negative tests that prevent an implementation from weakening those semantics.

## Canonical kernel

```text
U                         declared Set universe
P : U                     pole type
Rel : P × P → U           dependent relation family
Art := Σ(s:P).Σ(o:P).Rel(s,o)

X, I : U
c : X × I → Art × X
G := (X,I,c,x_0,path_contract)
PathContract := EVENTWISE | STATE_LINKED { pole_of : X → P }

F_I(Y) := (Art × Y)^I
F_I(h)(k)(i) := let (a,y)=k(i) in (a,h(y))

I*                        finite input histories, including []
I+                        nonempty finite input histories
B_I := Art^(I+)
ζ(b)(i) := (b([i]), w ↦ b(i·w))
beh_c : X → B_I
Path_I(p,b)              state-linked path witness

ζ ∘ beh_c = F_I(beh_c) ∘ c
```
