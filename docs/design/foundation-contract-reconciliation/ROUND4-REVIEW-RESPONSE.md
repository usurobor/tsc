# Round 4 Review Response — F24–F26

**Target:** TSC v4 specification set after Round 3
**Disposition:** F24 fixed · F25 fixed by boundary clarification · F26 withdrawn as a stale-base read

## F24 — presentation tuple arity

Accepted. `path_contract` is a component of `G`, so presentation equivalence now quantifies over:

```text
G  = (X,I,c,x_0,path_contract)
G' = (X',I,c',x'_0,path_contract')
```

The existing preservation conditions now constrain components actually present in the quantified presentations.

## F25 — diagram witness and PathContract

The ambiguity is real, but a third deterministic-Set constructor would collapse two layers:

- `PathContract` states intrinsic generator succession;
- the β atlas may relate emitted observations in a larger diagram.

The foundation now states that `EVENTWISE` and `STATE_LINKED` are the only generator-level contracts for deterministic Set presentations. A β diagram may relate `EVENTWISE` emissions, but it does not reclassify the generator as path-coherent or license an intrinsic role-succession claim. A non-Set `GeneralPresentation` may declare a category-specific intrinsic witness under its own carrier contract.

The distinction is now repeated in Core, Operational, the glossary, conformance, and the foundation fixture.

## F26 — Observation Dynamics compatibility key

Withdrawn. The reviewed SHA already contains:

```text
path-contract digest and succession semantics
```

in `tsc-observation-dynamics.md` §5.1. The file changed by one line between the Round 2 and Round 3 SHAs. Reading the earlier blob under the assumption that the file was unchanged produced the finding. No normative edit is required.

## Durable checks

The validator now requires:

- five-component presentation tuples in equivalence;
- the generator/atlas succession boundary;
- path-contract compatibility in Observation Dynamics;
- Core and Operational statements that β relations do not mutate intrinsic path semantics.
