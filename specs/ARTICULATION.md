# Articulation

*Identity in a changing whole.*

The foundation. Every other file depends on this one and may not reach a
conclusion it does not contain.

## Conventions

- Every term is defined before it is used. `tools/lint.py` checks this.
- Every item has a stable ID: **P** primitive, **A** assumption, **D**
  definition, **R** result, **O** open. Other files cite IDs, not wording.
- Each definition gives its rationale (*Why*) and the reading it shuts out
  (*Excludes*).
- An item marked *proposed* is under review. Nothing unproposed depends on it.
- An item marked *declared* has a name and a type but no content yet. Whatever
  depends on it is partial until its open item closes.

## Statement

The kernel in one breath. The sections below govern; this summarizes them.

> A whole differs within itself without division.
>
> In a changing whole, identity can persist in two cross-cutting ways: through
> what changes; through the change across what changes. Each can hold where the
> other does not.
>
> The whole differs without division; its changing differs without division.
> One change carries both continuities. That change is cohering. Its order is
> rhythm.

## Nomenclature

| Term | ID | Avoid | Because the avoided word |
|---|---|---|---|
| whole | P1 | system, totality | suggests an assembly of given pieces |
| changing | P2 | process, dynamics | suggests a law, which is a separate axis (R1) |
| occurrence | P3 | event-of-X, cell-at-t | builds a criterion of identity into the index |
| continuity | D1 | level, scale, dimension | stacks what cross-cuts |
| persistence | D2 | part, entity, constituent | implies it existed before a criterion picked it out |
| footprint | D3 | configuration, state | is the persisting thing frozen |
| refines | D4 | reduces to | implies ranking |
| carried | D8 | real, objective | asserts what O2 has not shown |
| articulation | D9 | perspective, view, description | implies an articulator other than the whole |
| cohering | D12 | emergence, causation between levels | names a second process |

## 1. Primitives

**P1 — Whole.** Not defined. Written `X`. Everything below is defined in some
`X`.

*Why.* ≡ is never a bare relation. The whole is part of every claim (D11).
*Excludes.* A whole assembled from pieces given beforehand. A whole differs
within itself without division.

**P2 — Changing.** A whole may change. Its changing is one change.

*Why.* Identity *across* change is the subject. Without changing there is
nothing to persist through.
*Excludes.* Static aspects. A cone's triangle and circle are untyped (§6).

**P3 — Occurrence.** `Occ(X)` is the set of occurrences in `X`'s changing.
Every relation below is a relation on this one set.

*Why.* Cross-cutting quantifies over occurrences shared by both relations
(D7). Separate sets would leave nothing to quantify over.
*Excludes.* Orthogonal dimensions: two unrelated structures, not one whole
articulated twice (D9).

**P4 — Order.** The changing orders occurrences as earlier, later or
simultaneous. An *instant* is a class of simultaneous occurrences.

*Why.* A footprint (D3) needs an instant. Telling change from logical sequence
needs order.
*Excludes.* A proof's sequence of steps treated as a changing.

## 2. Continuity

**D1 — Continuity.** An equivalence relation `~` on `Occ(X)`. Read `x ~ y` as
*x and y are occurrences of the same one*.

*Why equivalence.* Sameness is reflexive, symmetric and transitive, and only
equivalences have quotients (D2).
*Excludes.* Resemblance, which is not transitive.

**D2 — Persistence.** An element of `Occ(X)/~`: one thing, as `~` traces it.

*Why.* The thing is fixed by the criterion. It is not found first and then
described.
*Excludes.* Treating the persistences of one continuity as the material of
another's. Both are quotients of `Occ(X)`. Neither is `Occ(X)`.

**D3 — Footprint.** A persistence restricted to one instant (P4).

*Why.* A frozen frame holds footprints only, never a persistence.
*Excludes.* Taking a footprint for the thing whose footprint it is, under
either continuity.

**D4 — Refines.** `~₁` refines `~₂` when `x ~₁ y` implies `x ~₂ y` for all
`x, y`.

**D5 — Coincide.** Each refines the other. One continuity under two names.

**D6 — Nested.** One refines the other and not conversely.

**D7 — Cross-cut.** Neither refines the other:

    ∃ x, y :   x ~₁ y   ∧   ¬(x ~₂ y)
    ∃ x, y :   x ~₂ y   ∧   ¬(x ~₁ y)

Each can hold where the other does not.

*Why D4–D7.* Exactly four relations are possible between two continuities:
coincide, nested either way, or cross-cut. The test sorts every pair.

**A1 — Indexing is not identity.** *Proposed.* Occurrences may be labelled by
coordinates that one continuity also uses, such as a grid. A label is not a
criterion of identity, so no continuity is privileged by being the one the
labels resemble.

*Why.* Without A1, the continuity closest to the coordinates would serve as the
reference for "the same whole", and its symmetry with the other would fail by
the back door.

## 3. Carrying

**D8 — Carried.** *Declared.* A predicate on a continuity with respect to
`X`'s changing: the changing sustains the continuity rather than having it laid
across it.

*Type.* A predicate on relations, not a further relation among occurrences. A
carrying relation would need its own carrying, and that regresses.
*Candidates.* The changing preserves the continuity's classes forward. The
continuity is generated by the changing rather than imposed on it.
*Content.* None yet. See O2.

## 4. Articulation

**D9 — Articulation.** A continuity carried (D8) by `X`'s changing. Write
*X articulates itself as `~`*.

*Why the word.* An articulation fixes what counts as one in `X`, what keeps it
the same one, and which differences are changes in it rather than its
replacement. That is a criterion of identity which the whole bears.
*Reflexive.* Nothing articulates `X` but `X`. There is no articulator.
*Excludes.* Articulation as an observer's act: the inventory changes with the
articulation, `Occ(X)` does not. Articulation as description: an uncarried
continuity is a sorting, not an articulation.

**D10 — Elemental and pattern.** *Informal.* The two ways of persisting that
the Statement names:

- *elemental*: sameness of what changes (parcel, cell, site);
- *pattern*: sameness of the change across what changes (wave, glider,
  excitation).

*Why informal.* Nothing yet defines the two kinds except by example. Whether
they are the only kinds is O1.

## 5. Equivalence of articulations

**D11 — ≡.** `A ≡_X B` holds when `A` and `B` are articulations of `X` (D9)
and cross-cut (D7). Read: *X articulates itself as A and as B*.

The subscript is required. ≡ is never a bare relation between `A` and `B`.
Applications abbreviate by naming the persistences: `cell ≡_field glider`.

**D12 — Cohering.** The one change (P2) that carries both articulations when
`A ≡_X B`. *Rhythm* is the order of cohering. *Declared*: both names wait on
O2 and O3.

## 6. Verdicts

Putting a candidate `(A, B, X)` to the test returns exactly one verdict. The
checks run in order, and each verdict corresponds to one check.

| Order | Check | If it fails | Verdict |
|---|---|---|---|
| 1 | `X` has a changing (P2) | nothing to relate | **untyped**: not false, not a claim |
| 2 | `A`, `B` do not coincide (D5) | one continuity, two names | **coincident** |
| 3 | neither refines the other (D6) | one refines the other | **nested** |
| 4 | both are carried (D8) | carrying not shown | **uncarried**: undecided while O2 is open |
| — | all pass | — | **holds**: `A ≡_X B` |

These labels are under-resolved: some cover several distinct checks
(FINDINGS).

## 7. Results

**R1 — Identity is not determination.** D1–D11 mention no law by which the
changing is generated. So ≡ comes out the same whether the history is
generated forward from an instant, constrained as a whole, or neither.

*Proof.* By inspection: no definition refers to generation.

**R2 — Cross-cutting does not imply non-derivability.** One articulation may be
computed from a description given in the other. The glider is calculable from
the cell rule and its initial states. Derivability and a different criterion of
identity are compatible facts.

**R3 — Nesting privileges neither.** Refinement (D4) relates continuities. No
definition ranks them. Microstate refines temperature, and temperature is not
a fiction.

**R4 — Composition holds only within an articulation.** *Proposed.* Where
`A ≡_X B`, the identity-fixing reading of "B consists of As" has no referent
for a persisting `B`, only for its footprint (D3). Derivation, corrections and
limits are in FINDINGS.

**R5 — No second change.** *Proposed.* Where `A ≡_X B`, there is one change
(P2, D12). A causal claim across the two articulations is a claim about that
change, read through two criteria. It can be true. It cannot name a further
process running between them.

## 8. Open

- **O1.** Whether elemental and pattern (D10) are the only two kinds.
- **O2.** What carrying is (D8). Until it is answered, ≡ can be refused for
  coincidence, nesting and type, and cannot be refused for arbitrariness.
- **O3.** The structure of rhythm (D12).
