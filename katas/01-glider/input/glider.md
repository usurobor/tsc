# Conway's Life Glider — Coherence Reference Document

## Purpose

This document is the **positive control** for TSC mechanical coherence measurement.
It pairs with `kata-02` (random-soup, negative control).
A correct TSC implementation scores this document high: **C_Σ ≈ 0.70 or above** on mechanical mode.

Terminology is consistent throughout this document. Cross-references are explicit.
Each section builds on the definitions established in prior sections.

## Definitions

**Glider**: a 5-cell motif in Conway's Game of Life (rule B3/S23) that translates
diagonally with period 4. The glider is the simplest non-trivial moving pattern.

**Coherence (C_Σ)**: the Triadic Self-Coherence score. Defined as the geometric mean
of the three axis scores: `C_Σ = (α · β · γ)^(1/3)`. See TSC spec §tsc-core.md.

**Mechanical mode**: deterministic structural-proxy scoring. No LLM calls required.
Identical input → identical output. See `src/engine/ocaml/lib/mechanical_scoring.ml`.

**Positive control**: an input designed to score high under C_Σ measurement.
The glider is a positive control because it exhibits maximal structural regularity.

**Negative control**: an input designed to score low under C_Σ measurement.
See `kata-02` (random-soup) for the negative control.

**Alpha axis (α)**: articulation — measures pattern consistency and terminology stability.

**Beta axis (β)**: registration — measures cross-reference consistency and source alignment.

**Gamma axis (γ)**: domain — measures version surface consistency and authority alignment.

## Conway's Life Rule (B3/S23)

The Birth/Survival rule B3/S23 governs glider evolution:

- **Birth**: a dead cell with exactly 3 live neighbors becomes alive.
- **Survival**: a live cell with 2 or 3 live neighbors survives.
- **Death**: all other live cells die.

This rule is the canonical reference for all glider frames below.
The glider pattern is stable under this rule: it translates (+1, +1) every 4 steps.

## Glider Pattern

The glider occupies a 5×5 bounding box. Its 4-step cycle is:

### Frame 0 (t=0)

```
.....
..#..
...#.
.###.
.....
```

### Frame 1 (t=1)

```
.....
.....
.#.#.
..##.
..#..
```

### Frame 2 (t=2)

```
.....
.....
...#.
.#.#.
..##.
```

### Frame 3 (t=3)

```
.....
.....
..#..
...##
..##.
```

After Frame 3, the glider has translated (+1, +1) from Frame 0. The cycle repeats.

## Coherence Properties

The glider exhibits maximal coherence under TSC mechanical scoring because:

1. **Terminology consistency (α)**: each term is defined once and used consistently.
   "Glider", "coherence", "mechanical mode", "positive control", "negative control",
   "alpha axis", "beta axis", "gamma axis" — each appears first as a definition,
   then as a reference. No synonyms, no drift.

2. **Cross-reference consistency (β)**: the document references `kata-02` (negative control),
   `src/engine/ocaml/lib/mechanical_scoring.ml` (implementation), and `spec/tsc-core.md` (theory).
   These references are consistent: each named artifact has a single canonical path.

3. **Version surface consistency (γ)**: this document carries no version number of its own,
   which is correct — it is a kata input, not a versioned artifact. Version references
   (e.g., "B3/S23") are stable and not in conflict with any other version surface in the document.

## Expected Mechanical Score

Under TSC mechanical mode, this document is expected to score:

| Axis | Expected score | Rationale |
|------|---------------|-----------|
| α (articulation) | ≥ 0.65 | Consistent terminology; defined terms used uniformly |
| β (registration) | ≥ 0.60 | Cross-references are explicit and internally consistent |
| γ (domain) | ≥ 0.60 | Version surface is minimal and non-contradictory |
| C_Σ | ≥ 0.60 | Geometric mean of α, β, γ |

The mechanical scorer measures structural proxies, not semantic content.
A structured document with consistent terminology, explicit cross-references,
and minimal version-surface conflict scores high regardless of its subject matter.

## Relationship to Kata Framework

This document is `katas/01-glider/input/glider.md`. It is the input file for
kata-01 in the TSC kata framework. The kata framework is described in `katas/README.md`.

The kata runner (`coh --kata 01-glider --mode mechanical`) loads this document,
scores it, and compares the result against `kata.toml`'s `expected.score_range`.

To run this kata:

```bash
coh --kata 01-glider --mode mechanical
```

## See Also

- `katas/README.md` — kata framework documentation and `kata.toml` schema
- `katas/02-random-soup/` — negative control kata (low coherence, expected fail)
- `src/engine/ocaml/lib/mechanical_scoring.ml` — mechanical scoring implementation
- `spec/tsc-core.md` — TSC theory (α, β, γ axes and C_Σ definition)

## License

CC0-1.0 / Public Domain.
