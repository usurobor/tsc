# Trace 001 — Hard/soft flickering versus simultaneous decomposition

**Status:** Hand trace
**Purpose:** Test whether the proposed ascent kernel produces a
non-decorative result on live external material.

## Input viewpoint

Hard and soft are pure phases of one system that flicker or alternate.

## Context

The viewpoint was offered in a discussion of an FCC graph and invoked
both Helmholtz/Hodge decomposition and a harmonic component associated
with mass or global topology.

The inquiry is stuck because the language of pure temporal phases appears
to conflict with a mathematical decomposition whose components coexist.

## CompilePOV

### Candidate frame F1 — Helmholtz reading

**Q — governing question**

How can one field exhibit hard-like stability and soft-like flow?

**Γ — locally warranted commitments**

- hard-like/stable behavior is observed;
- soft-like/flowing behavior is observed;
- their relative prominence may vary in time.

**Ξ — closure assumptions**

- hard and soft are mutually exclusive temporal phases;
- only one component exists at a given instant;
- the binary hard/soft distinction exhausts the state.

**Σ — available distinctions and operators**

- field;
- gradient component;
- solenoidal component;
- time;
- switching;
- phase;
- relative weight.

**R — permitted in-frame moves**

- explain change through switching between phases;
- assign each observation to one phase;
- vary the duration or frequency of each phase.

### Candidate frame F2 — Hodge reading

**Q — governing question**

How does one edge flow or 1-form on a declared complex carry stable,
circulating, and global/topological behavior?

**Γ — locally warranted commitments**

- gradient/exact behavior is present;
- coexact/curl behavior is present;
- a harmonic/global component may be present;
- topology of the chosen complex matters;
- component weights may vary with time.

**Ξ — closure assumptions**

- the components are pure temporal phases rather than simultaneous terms;
- hard and soft exhaust the state despite the separately named harmonic term.

**Σ — available distinctions and operators**

- edge flow / 1-form;
- boundary and coboundary operators;
- exact component;
- coexact component;
- harmonic component;
- temporal coefficient dynamics;
- topology / independent cycles.

**R — permitted in-frame moves**

- decompose the form into declared components;
- vary component coefficients through time;
- inspect topology through the harmonic sector.

### Compilation result

    FRAME_UNDERDETERMINED

Frame-fiber size:

    2

The Hodge branch is selected for the principal trace because the source
explicitly invokes a graph/complex and separately names the harmonic term.
The Helmholtz branch remains in the receipt.

## Support deficit

### Demanded continuation

Represent stable, flowing, and harmonic/topological behavior when the
declared decomposition contains simultaneously defined components.

### Why the current closure cannot carry it

A pure-phase account has only one active component at a time.

The decomposition requires one state to admit several component
projections simultaneously.

The separately named harmonic component also contradicts the claim that
hard and soft exhaust the state.

## Closure core ξ*

The minimal load-bearing closure is compound:

1. **Temporal exclusivity**
   — exactly one component exists at a time.

2. **Binary exhaustiveness**
   — hard and soft exhaust the decomposition.

Kinds:

    temporal order
    exclusive partition

## Polar closure

The closure core is compound and admits two partial inversions:

1. Invert temporal exclusivity:
   > Hard-like and soft-like components coexist; their relative coefficients,
   > dominance, or observability may vary through time.
2. Invert binary exhaustiveness:
   > Hard and soft do not exhaust the state; a harmonic/global component
   > may remain.

These inversions are distinct in general. In this trace they are jointly
required because the invoked Hodge decomposition both defines components
simultaneously and explicitly contains a third harmonic term.

The selected polar closure is therefore:

> Hard-like, soft-like, and harmonic behavior are simultaneous components
> of one state. Their coefficients, dominance, or observability may vary
> through time.

Status:

    POLAR_CLOSURE_FOUND

Alternative partial inversions remain recorded in the trace rather than
being silently discarded.

## Overlap

### Preserved from Γ

- hard-like stability remains real;
- soft-like flow remains real;
- changing phenomenological dominance remains possible;
- the historical observations are not discarded.

### Provisionally held from the polar frame

- component existence is simultaneous;
- temporal change applies to coefficients or projections;
- a harmonic/global sector is retained explicitly.

The old and polar frames remain active while the larger model is formed.

## Candidate wholes

### W1 — Typed Hodge state

One time-dependent edge flow or 1-form on a declared cell complex:

    ω(t) = dα(t) + δβ(t) + h(t)

with:

- exact/gradient projection;
- coexact/curl projection;
- harmonic projection;
- declared incidence structure and boundary conditions;
- temporal dynamics over the component coefficients.

### W2 — Generic coupled-mode field

One field carrying several stable and flowing modes whose simultaneous
existence is declared, but without the full Hodge typing or topological
interpretation.

### Ascent fiber

    {W1, W2}

W1 receives the stronger warrant under the declared Hodge assumptions.
W2 remains an underdetermined explanatory alternative.

## Result

For the formal decomposition claim:

    ASCENT_COMMITTED

For the broader physical interpretation:

    ASCENT_UNDERDETERMINED

### Warrant

**Class:** FORMAL_PROOF

**Warranted proposition:**

Under the declared Hodge setting, the state decomposes into exact,
coexact, and harmonic components that are defined simultaneously.

**Not warranted by that theorem alone:**

- that hard maps uniquely to the exact component;
- that soft maps uniquely to the coexact component;
- that physical mass is identical to the harmonic component;
- that any particular temporal coefficient law is correct.

Those require separate bridges or empirical evidence.

## Migration audit

If “flickering” is revised to mean:

> changing relative coefficient, dominance, or observed salience of
> simultaneously defined components,

then:

    MIGRATED

If it continues to mean:

> the field becomes purely hard and then purely soft,

without a separately warranted dynamics producing those pure phases, then:

    CONTRADICTORY_RESIDUE

## Support expansion

The recovered frame can now carry questions the original frame could not:

- simultaneous component existence;
- varying relative weights;
- a third harmonic/topological sector;
- topology-sensitive predictions;
- explicit separation between decomposition and coefficient dynamics.

## Open question for kernel review

The F2 closure statement names components as "pure temporal phases
rather than simultaneous terms." The word *simultaneous* may have
entered CompilePOV from prior knowledge of the Hodge decomposition
rather than from the source viewpoint.

Test before writing KERNEL.md: restate the F2 closure using only
what the source material asserts, without importing decomposition
vocabulary, and check whether the inversion still lands on
simultaneity. If the closure cannot be stated without the target
vocabulary, the correction was produced by the compiler, not by
the ascent.

## Honest read

This trace produces a concrete correction that was unavailable inside the
original closure:

> decomposition does not imply flickering; pure-phase alternation requires
> an additional dynamical law.

The result is not decorative.

The strongest formal claim is narrower than the larger physical
interpretation, and the trace preserves that distinction.
