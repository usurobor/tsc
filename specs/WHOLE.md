# The Whole

A theory of wholes. It introduces one primitive, fixes what must hold of it,
and derives what follows.

## Method

The primitives of this theory are **not defined**. The axioms fix what holds of
them, and anything satisfying the axioms is a whole. This is definition by
axiom in Hilbert's sense: *point* and *line* are never said to be anything, and
the geometry is complete without it.

The question *but what is a whole, really* is therefore declined. Not because
it is a bad question, but because taking it is what turns a theory into a
worldview. Nothing here asserts what wholes are made of, whether they are
fundamental in nature, or what exists.

A theory of this kind is contentful in proportion to what it **forbids**. Every
axiom below is stated with what it rules out. An axiom that refuses nothing is
a slot with better typography, and slots are always satisfiable.

**This document contains no examples.** The reason is not austerity. A reader
given a case will generalize from the case, and will then recognize new
situations by their resemblance to it rather than by derivation from the
axioms. Recognition by resemblance is precisely the failure this theory has to
avoid, since its use is to catch situations nobody has written down. Instances
belong to application and are kept elsewhere.

## Vocabulary

One constraint governs the terms of this theory: **a term is admissible only if
it can be said intransitively of a whole.** Transitive vocabulary imports an
agent, and an agent is not among the primitives.

The constraint is not decorative. It excludes *projection*, which requires a
projector; *integration*, which requires an integrator and presupposes
separates to be integrated; *vantage*, which requires someone to occupy it; and
the pair *coherer / cohered*, which is agent-and-patient grammar for what this
theory takes to be intransitive.

*Differentiates*, *modulates*, and *articulates* pass. **Modulation** is used
throughout in its musical and intransitive sense — a passage modulates, and
nothing modulates it — and never in the engineering sense, in which a carrier
is modulated by a signal.

## Primitives

- **W** — a whole.
- **articulation** — a structure map out of a whole.
- **perturbation** — an operation on a whole.
- **rhythm** — undefined; see A5.

## Axioms

### A1 — Priority

Articulations are maps *from* a whole. There is no operation `⊕` such that
`W = a ⊕ b` for articulations `a`, `b` of `W`.

A whole is not the value of a constructor applied to its distinctions. Its
distinctions are articulations of it.

> **Refuses:** any account in which a whole is produced, composed, assembled, or
> constituted from what it distinguishes. Any account supplying a constructor.

### A2 — Duality

A whole that changes admits exactly two articulations, `δ` and `μ`.

- Under **δ** — *differentiation* — identity attaches to distinguishable
  participants and the relations among them. The one becomes distinguishable
  within itself.
- Under **μ** — *modulation* — identity attaches to persisting formation. The
  whole varies as itself through changing distinctions.

Neither is beneath the other, neither produces the other, and neither is the
whole.

> **Refuses:** a third articulation. A changing whole articulated only once.

*Exactness is posited here, not shown. See Open.*

### A3 — Cross-cutting

The identity relations `~δ` and `~μ` induced by the two articulations do not
coincide, and fail to coincide in both directions:

    ∃ x, y :  x ~δ y  ∧  ¬(x ~μ y)
    ∃ x, y :  x ~μ y  ∧  ¬(x ~δ y)

> **Refuses:** any structure whose two identity relations coincide. That is one
> articulation under two names, and the second is decoration.

### A4 — Covariance

For any perturbation `p` of `W`, the induced changes in `δ` and in `μ` both
**factor through `W`**.

The two do not correspond because a correspondence has been arranged between
them. They correspond because there is one thing they are both articulations
of, and nothing else for them to do.

> **Refuses:** two descriptions whose agreement is established between the
> descriptions rather than through what they articulate. Any correspondence
> that survives replacing the whole.

### A5 — Rhythm

**Rhythm** is left undefined. It is whatever the factorization in A4 consists
in.

Three constraints hold of whatever fills it:

- it is not itself an articulation;
- it is what the covariance consists in, not something the covariance indicates
  to anyone;
- it is an organization of change, not of states.

> **Refuses:** rhythm as a third articulation. Rhythm as an invariant quantity —
> many quantities are invariant across the two and are trivial.

*This is the open term of the theory and is not filled here. See Open.*

## Consequences

### T1 — A whole is a happening, not a configuration

Suppose `δ` is complete at every instant, so that the differentiated state at
one instant fixes it at the next, with nothing left over.

By A3 there are `x ~μ y` with `¬(x ~δ y)`: a sameness carried by `μ` which no
`δ`-fact holds. Since `x` and `y` are at different instants, that sameness is
identity through change. It is therefore not contained in any instantaneous
description, however complete.

So exhausting the state does not exhaust the whole, and the whole must be taken
as its changing rather than as its states.

### T2 — The test

By A3 and A4, a proposed second articulation is non-decorative when:

1. its identity criteria cross-cut those of the first, in both directions; and
2. their transformations covary under perturbation of the whole.

A third clause — *neither articulation exhausts the whole* — is not independent.
Given T1 it is contained in the first, and it is in any case not checkable,
there being no access to a whole apart from its articulations.

### T3 — No production relation obtains between the articulations

By A1, `δ` and `μ` are both maps out of `W`. Neither lies in the domain of the
other. A production relation would require `μ` to be a value of a function of
`δ`, and A1 supplies no such map; were one to exist and preserve identity, the
two relations would coincide, which A3 forbids.

This holds **even where `δ` determines the state at every instant**.
Determination of state is not production of an articulation: by T1, what `μ`
carries is not in `δ`'s image regardless of how complete `δ` is.

> **Therefore: any demand for a production relation between two articulations of
> one whole is malformed.** It asks after a relation that does not obtain, and no
> answer to it can be correct.

The well-posed replacement is a question about **affordance** — whether, and in
virtue of what organization, a given whole admits a second articulation at all.
Most do not.

### T4 — Two orders

Ontologically the whole grounds both articulations:

    W ⟶ (δ, μ)

Epistemically the direction is reversed. Two cross-cutting but covarying
articulations license the whole:

    (δ, μ) ⟶ W

The orders are inverse, which is ordinary. But it follows that **a whole cannot
be checked by inspection.** There is nothing to inspect prior to the test in T2;
the whole is what one becomes licensed to posit when the test passes.

Declaring a whole and then deriving two articulations for it inverts the
epistemic order. It produces structures with slots, and slots are satisfied by
anything.

## A formal reading

The axioms have a standard home, offered as a reading and not as a dependency.
Nothing above requires it.

An **algebra** is a map `F(X) → X` — constructors, assembly. A **coalgebra** is
a map `X → F(X)` — observers, structure pointing outward from a carrier.

- A1 is the statement that a whole is given coalgebraically: the defining data
  is what can be observed of it, not what it is built from.
- `δ` and `μ` are two coalgebra structures on one carrier.
- `~δ` and `~μ` are their **bisimulations**. A3 says the two bisimulations do
  not coincide. Coalgebraic identity is behavioural — sameness under continued
  observation, not sameness of construction history — which is what T1 requires.
- Greatest fixed points carve down from what is consistent with observation;
  least fixed points build up from nothing. A1 is the former.

Coinduction supplies definition-by-observation and identity-by-bisimulation. It
does **not** supply dynamics, and it does not fill A5. Streams are coinductive;
which streams are rhythmic is not a question it answers.

## Open

- **A2 is posited.** That a changing whole admits exactly two articulations is
  assumed. The argument that `δ` and `μ` exhaust the ways of fixing identity
  through change is sketched, not made, and until it is made *exactly two* is a
  convenience.
- **A5 is undefined.** Rhythm has three constraints and no structure. Candidate
  fillings are candidates; the surrounding precision must not be allowed to make
  the centre look furnished.
- **A4's factoring wants sharpening.** *Factors through `W`* is stated but not
  given in full generality, and a perturbation is currently primitive.
