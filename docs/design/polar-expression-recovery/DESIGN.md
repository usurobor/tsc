# TSC 4.1 — Polar Expression Recovery

**Version:** 1.0.0
**Status:** Draft design
**Target specification:** TSC 4.1.0

## Governing question

> How can TSC express `a ≡ b` as a recursively nestable dimension with two poles without reintroducing free role permutation, vacuous realizations, structural collapse, or scalar-first measurement?

## 1 · Pressure

TSC 4.0 repaired the measurement stack by replacing free three-position terms with typed articulation events, retaining maps and candidate alternatives, separating realization from identification, and making receipts primary. The repair was mathematically necessary.

It also removed a foundational expressive capability. Earlier C≡ could write:

```text
≡
≡ ≡ ≡
(I ≡ AM) ≡ (lim ≡ ∞) ≡ (1 ≡ 0)
```

The intended reading was not arithmetic or propositional equality. `a ≡ b` named one dimension through two distinguishable poles, and the resulting dimension could itself become a pole of another dimension.

TSC 4.0 can represent typed events among already available poles. It cannot state the polar expression that asks for those poles to be held as one dimension. The language of articulation and the semantics of measurement became clean but disconnected.

## 2 · Constraint

The recovery must preserve every load-bearing v4 result:

```text
dependent source/relation/result typing
no free S₃ role permutation
path and presentation retention
joint generator-plus-atlas realization candidates
zero / one / many realization outcomes
search, complexity, held-out, and standing discipline
receipt primacy
```

It must not restore:

```text
tri(T,T,T) as three free peers
commutative leaf folds as shape or depth measures
term count as coherence
an automatic universal scalar
a rewrite that erases nonempty structure
a claim that raw cone existence establishes realization
```

## 3 · Selected move

TSC 4.1 adds a conservative polar source language before the existing typed articulation semantics.

```text
polar expression
  → methodology-relative typed realization problem
  → β atlas retains candidate realizations and maps
  → Core filters, quotients, tests, and receipts them
```

The existing v4.0 model remains valid when no polar source is declared.

## 4 · Polar syntax

### 4.1 Abstract syntax

```text
PolarTerm ::= Whole
            | Label(name)
            | Dim(PolarTerm, PolarTerm)

PolarFrame ::= Frame {
  coherer : PolarTerm,
  cohering : PolarTerm,
  cohered : PolarTerm
}

PolarSource ::= TermSource(PolarTerm)
              | FrameSource(PolarFrame)
```

`Dim(x,y)` is one dimension with two ordered poles. It is not equality and it is not a directed event from `x` to `y`.

### 4.2 Human notation

```text
≡                    Whole
1 ≡ 0                Dim(Label("1"), Label("0")) at the source root
(1 ≡ 0)              the same term when nested or used as a frame operand
A ≡ B ≡ C            Frame(A,B,C)
≡ ≡ ≡                reserved literal for Frame(Whole,Whole,Whole)
```

A two-operand root chain is one dimension; a three-operand root chain is one frame. Parentheses are mandatory around a dimension used as an operand of another dimension or frame. Longer or ambiguously grouped chains are invalid.

The foundational expression therefore parses as:

```text
Whole

Frame(Whole, Whole, Whole)

Frame(
  Dim(I, AM),
  Dim(lim, ∞),
  Dim(1, 0)
)
```

The labels receive no built-in metaphysical or arithmetic interpretation. A CM declares their domain meaning.

The three lines are an ordered progressive presentation rather than an equality rewrite: the second exposes the role frame, and the third refines each role with a polar term. Common grounding does not collapse the three source structures.

### 4.3 Shape laws

Polar syntax is a free ordered tree:

```text
Dim(x,y) ≠ Dim(y,x)                 by default
Dim(Dim(a,b),c) ≠ Dim(a,Dim(b,c))
```

No associativity, commutativity, idempotence, flattening, or cancellation is built in.

An explicit reversal operation may be declared:

```text
reverse(Dim(x,y)) = Dim(y,x)
reverse(reverse(d)) = d
```

Reversal swaps only the root boundaries; it does not silently reverse the internal orientation of nested poles. A recursive mirror is a separate declared transformation. Reversal does not establish equivalence unless a methodology supplies a symmetry witness.

## 5 · Raw typed elaboration

A raw elaboration assigns one typed pole to every syntax node. Dimension nodes therefore nest without requiring terms themselves to be poles.

For term `t`, let `Node(t)` be its syntax nodes. A raw node assignment is:

```text
p : Node(t) → P
```

A label interpretation fixes the poles of label nodes. A declared Whole-interpretation policy determines whether Whole nodes share one pole, receive context-indexed poles, or obey another explicit rule.

For each node `n = Dim(l,r)`, elaboration uses one of two distinct constructors.

### 5.1 Projective dimension

```text
ProjectiveNode(n) := (
  p_n,
  left  : Rel(p_n, p_l),
  right : Rel(p_n, p_r)
)
```

The dimension whole articulates outward as its two poles.

### 5.2 Inclusive dimension

```text
InclusiveNode(n) := (
  p_n,
  left  : Rel(p_l, p_n),
  right : Rel(p_r, p_n)
)
```

The two poles articulate inward into the dimension whole.

These are separate constructions with separate degeneracies. They are not one construction plus an informal orientation flag.

### 5.3 Nesting

For:

```text
Dim(Dim(1,0), Dim(lim,∞))
```

elaboration assigns poles to all seven syntax nodes and two typed boundary legs to each of the three dimension nodes. The syntax tree remains present in the receipt.

## 6 · Raw cones are not admissible elaborations

A category may supply vacuous raw cones or cocones. In `Set`, the initial object maps to every pair, the terminal object receives a map from every pair, and singleton carriers can satisfy several purely structural predicates. Mere existence of legs therefore cannot establish a dimension.

Joint monicity alone does not fix the problem: the empty map is monic in `Set`. Complexity alone also does not fix it: trivial carriers are often cheapest.

The polar source must first declare a foundation-level admissibility contract:

```text
PolarAdmissibilityContract := (
  label interpretation,
  Whole-interpretation policy,
  allowed node constructors,
  structural candidate class,
  nondegeneracy predicate,
  boundary-faithfulness rule,
  structural equivalence
)
```

A raw node assignment becomes structurally admissible only when this complete contract holds. The contract must include at least one reproducible negative case. Initial, terminal, empty, singleton, or lookup elaborations receive no exemption.

Standard nondegeneracy strategies may include inhabited-and-separating maps, observation separation, domain-specific coverage, intervention discrimination, or another declared predicate. No one strategy is universal.

Core then adds the measurement obligations that do not belong in the foundation: a polar candidate class, search claim and bound, complexity contribution, fit, and held-out or interventional oracle. Only the combined contract may support a measurement realization status.

## 7 · Frame elaboration

A `PolarFrame` is a role-labeled source expression. It is not automatically one `Art` event.

The middle term is a polar term. It cannot be silently coerced into:

```text
Rel(root(coherer), root(cohered))
```

A frame source first declares a structural frame-elaboration contract:

```text
FrameElaborationContract := (
  one admissible elaboration for each role term,
  a typed frame witness,
  role-to-witness bridges,
  structural nondegeneracy,
  structural equivalence
)
```

Core later adds globalization, search, fit, complexity, and oracle obligations when the frame is load-bearing in a measurement.

The frame witness may be one typed event, a typed diagram, a generator step, or another declared construction. When the witness is one event, the CM must provide an explicit bridge from the realized cohering term to the event relation. The bridge is evidence; it is not a syntax coercion.

This keeps the foundational line writable while allowing zero, one, or many typed realizations.

## 8 · Grounding

Define the forgetful grounding map:

```text
ground : PolarTerm → 1
```

and render its unique value as `≡`.

The map is vacuous by design. It records only that every polar expression is presented as an articulation of one unnamed ground. It carries no shape, orientation, equality, substitution, realization, or standing evidence.

Therefore:

```text
ground(x) = ground(y)
```

does not imply:

```text
x = y
x may substitute for y
x and y have the same realization
```

## 9 · Integration with Core

Polar syntax is optional CM source. The β atlas owns its typed realization evidence because it already owns correspondence maps and joint realization structure. C≡ owns only syntax and structural elaboration; Core owns measurement admissibility and status.

For dataset `D` and generator `G`, the atlas class becomes:

```text
A_M(G,D,S)
```

where `S` is an optional polar source. When `S` is present, an atlas candidate retains:

```text
canonical polar AST and digest
node-to-pole assignment
projective or inclusive boundary legs
raw candidates considered
admissible candidates retained
rejections and reasons
frame witness and bridges, when applicable
polar search claim and bounds
```

The joint Core candidate remains:

```text
R = (G,A)
```

Fit and complexity apply to the whole candidate, including its polar realization. Zero admissible candidates can therefore yield `NO_REALIZATION_IN_MODEL`; several inequivalent candidates yield `UNDERDETERMINED`; one class may yield `IDENTIFIED_IN_MODEL` under the declared search and evidence regime.

## 10 · Conservative extension

The embedding of v4.0 into v4.1 is:

```text
polar_source = none
polar_admissibility_contract = none
```

All existing generator, atlas, behavior, receipt, standing, and authority semantics remain unchanged.

No v4.0 receipt acquires polar meaning retroactively.

## 11 · Alternatives rejected

### 11.1 Revert to `tri(T,T,T)`

Rejected because free peer positions reintroduce role permutation, shape-blind folds, and ambiguous unity placement.

### 11.2 Interpret `a ≡ b` as `art(a,φ,b)`

Rejected because this turns a dimension into a directed event and presupposes a relation that the expression is meant to ask a methodology to realize.

### 11.3 Define dimension as a bare cone or cocone

Rejected because initial and terminal objects make raw existence vacuous in common categories.

### 11.4 Require joint monicity universally

Rejected because it excludes legitimate lossy projections, does not exclude the empty carrier in `Set`, and confuses one possible domain criterion with the foundation.

### 11.5 Make the cohering frame operand a relation expression

Rejected for the original surface language. It would prevent `(lim ≡ ∞)` from occupying the cohering role. The selected frame keeps all three role expressions polar and requires an explicit realization witness.

## 12 · Impact graph

Direct changes:

```text
spec/c-equiv.md
spec/tsc-core.md
spec/tsc-oper.md
spec/tsc-observation-dynamics.md
spec/tsc-conformance.md
spec/tsc-glossary.md
spec/README.md
```

New fixture families:

```text
polar-syntax-v4.1
  parser, AST, shape, reversal, grounding, frame elaboration

polar-realization-v4.1
  zero / one / many measurement realizations and Core statuses
```

The syntax fixture does not depend on a v4 runtime. The realization fixture does.

## 13 · Acceptance criteria

### AC1 — Exact surface language

The three-line foundational expression parses to the specified AST without equality or binary-chain ambiguity.

### AC2 — Nesting retained

`Dim(Dim(1,0),Dim(lim,∞))` retains three distinct dimension nodes after parsing, canonicalization, and elaboration.

### AC3 — No vacuous realization

Raw initial/terminal cones and cocones do not count as admissible dimensions without the declared nondegeneracy and boundary contract.

### AC4 — Frame honesty

A frame has no implicit coercion from its cohering polar term to an event relation. Every realization carries an explicit frame witness and bridges.

### AC5 — Orientation honesty

Projective and inclusive realizations are separately typed and separately tested.

### AC6 — Grounding is forgetful only

Grounding cannot justify equality, substitution, or realization.

### AC7 — Core statuses

Zero, one, and several Core measurement-realization classes surviving structural admissibility, search, fit, and complexity produce the corresponding scoped Core statuses.

### AC8 — Conservative extension

Every v4.0 presentation and receipt remains valid with no polar source and retains identical semantics.

### AC9 — Receipt retention

The polar AST, candidate realizations, maps, rejected alternatives, and witnesses remain in the β receipt or content-addressed references.

### AC10 — Independent review

The exact 4.1 specification SHA receives mathematical, document, and conformance review before ratification.
