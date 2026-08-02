# TSC v4 Round 2 Review Response

**Status:** Author response
**Target:** Round 1 `REQUEST CHANGES`

## Governing question

> How does the revised document set resolve every accepted review finding without reintroducing history into the normative foundation?

## Disposition

| Finding | Resolution |
|---|---|
| F1 Draft status | Kept `Draft`; ratification is an explicit final gate |
| F2 consumer drift | README, STATUS, Architecture, Quickstart, Thesis, docs indexes, engine contract, katas, illustrations, and citation updated |
| F3 obligation drift | Added one normative `spec/tsc-conformance.md` with stable IDs |
| F4 missing negatives | Added positive/negative obligations and external fixture cases for every requirement |
| F5 fiber notation | Standardized `L_M`, `K_M`, `τ_M`, `κ_M`, `C_M`, and `F_M` notation |
| F6 design authority | DESIGN owns revision ACs; Conformance owns enduring proof law |
| F7 behavior fallback | Added `FinalityBasis`, `BehaviorAccess`, compiler checks, and refusal codes |
| F8 engine/spec mismatch | Added immutable engine contract; engine explicitly has no v4 conformance |
| F9 GoL lift | Split evidence refinement from true model lift and declared `H_0`, `H_1`, class relation, complexity, margin, and oracle |
| F10 tolerance duplication | Core is sole approximation owner; Observation Dynamics binds by digest |
| F11 foundation approximation | C≡ defines exact commutation only |
| F12 symbol history | Migration table lives in DESIGN; spec index points to it |
| F13 incomplete functor | Defined `F_I` on morphisms, proved functor laws, and constructed exact Set final behavior |
| F14 non-interchangeability | Replaced independence language with typed asymmetric non-substitutability and blocking fixtures |
| Internal F15 joint realization | Candidate fibers now range over `(generator, atlas)` so map alternatives cannot disappear before identification |

## Additional closures

The revision also:

- separates finality basis from behavior access;
- allows continuous deterministic carriers under `SET_FINAL`;
- requires a pointed-state and articulation interface for general presentations;
- permits empty input history for initial-state observations;
- distinguishes fit, bounded, and tested joint realization-candidate sets before quotienting;
- retains a refinement map between test and training fibers;
- distinguishes over-budget realization from no realization;
- treats all-grounded-held-out failure as model refutation;
- records candidate-level continuation outcomes and avoids claiming universal termination from one alternative;
- permits relation and generator search to interleave only under a declared schedule;
- separates refinement within an existing input contract from a lift that changes the input language or boundary;
- makes failed evidence persistent across theory, methodology, and runtime replacement.

## Proof plan

`spec/tsc-conformance.md` owns the abstract requirements. The registered fixtures under `conformance/` implement them without importing domain law into Core.

All fixtures remain `specified`; they carry no implementation result or standing. That does not prevent specification ratification once the semantics, requirement contracts, consumer truth, and independent document review close. No engine or methodology may claim v4 conformance until its applicable fixtures are implemented, executed, reproducible, and verified.
