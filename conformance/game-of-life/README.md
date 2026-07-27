# Game of Life Ascent 0

**Fixture ID:** `gol-ascent-0`
**Status:** Specified

This package preregisters the first exact-domain TSC v4 ascent. It contributes no result until its generator, oracle, generated artifacts, and negative controls are implemented and independently verified.

## Domain

```text
state
  finite binary grid

law
  Conway B3/S23

observations
  full frames and selected row/column margins

oracle
  exact generated successor and exact margin projection
```

## Refinement

B3/S23 is in the model from the beginning.

```text
initial margins
  → exactly two joint grid-plus-projection realizations
  → training UNDERDETERMINED

held-out next margins
  → one fixed realization candidate survives
  → tested IDENTIFIED_IN_MODEL
```

This proves evidence refinement. It does not claim a model lift.

## Lift

```text
H_0
  static binary grids observed through margins

baseline failure
  a preregistered next-state question is not answerable in H_0

H_1
  pointed B3/S23 generators

class relation
  forget the trajectory and retain the initial grid

complexity rule
  fixed B3/S23 law cost plus initial-state representation cost

acceptance margin
  tested joint-realization fiber contracts from two classes to one

held-out oracle
  next margins fixed before H_1 fitting
```

Only this case may produce `LIFT_VALIDATED`.

## Other cases

- an illegal successor preserving selected surface statistics produces `LAW_VIOLATION`;
- a preregistered collision may produce `LAWFUL_TERMINATION` rather than degraded coherence.

All frames, margins, realization candidates, transitions, and expected categorical relations are generated from code. No transcribed frame and no hand-selected scalar is an oracle.
