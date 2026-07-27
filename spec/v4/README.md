# TSC v4 Alpha Specification Tree

**Version:** 4.0.0-alpha.1
**Status:** Parallel draft; does not supersede the live v3 specification
**Design authority for this draft:** `docs/design/foundation-contract-reconciliation/SEMANTIC-IDENTITY.md`

## Purpose

This tree begins a foundation-level revision after the v3 stack was found to reuse the words *articulation*, *α/β/γ*, *coherence*, and `C_Σ` for different constructs.

The v4 alpha moves the normative object from a scalar score to a proof-carrying receipt over a typed generative presentation.

## Reading order

1. [`c-equiv.md`](c-equiv.md) — typed articulation and coalgebraic unfolding.
2. [`tsc-core.md`](tsc-core.md) — coherence receipts and candidate fibers.
3. [`tsc-oper.md`](tsc-oper.md) — runtime lifecycle, standing, and refusal.
4. [`tsc-observation-dynamics.md`](tsc-observation-dynamics.md) — receipt comparison, lineage, and validated lifts.
5. [`tsc-glossary.md`](tsc-glossary.md) — accessible terms and migration map.

## Load-bearing changes

- `tri(T,T,T)` is no longer the semantic primitive.
- An articulation is a dependent event `art(s, φ, o)` where `φ : Rel(s,o)`.
- A concrete generator is an open coalgebra `c : X × I → Art × X`.
- Final coalgebra semantics is conditional; concrete generators are not presumed final.
- The normative receipt retains the concrete presentation, behavioral semantics, and their commuting witness.
- The number of observations is methodology-dependent; triadicity is the role structure of an event.
- `e` is not maximally coherent by definition.
- Articulation, source-proximity, and coherence are different constructs.
- Realizability, identifiability, lawful continuation, model insufficiency, lift, and standing are separate statuses.
- Scalars are optional summaries after the receipt, not substitutes for it.

## Alpha obligations before promotion

- generated Game of Life conformance ascent;
- exact counterexamples for commutative-fold shape blindness;
- proof or explicit finite approximation for every final-semantics claim;
- second-domain conformance;
- schema and engine design derived from the final reviewed receipt;
- explicit migration status for every v3 result and example.
