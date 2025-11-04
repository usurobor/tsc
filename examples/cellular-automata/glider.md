______________________________________________________________________

## name: glider role: positive_control target: high_coherence metric: C_Σ expected_value: "~0.996" expected_outcome: PASS grid: "variable" frames: 8 symbols: ["#", "."] license: CC0-1.0

# Conway's Life Glider (Positive Control for Coherence)

**Why this exists:** This is the *success case* to pair with `random-soup.md` (low coherence, C_Σ ≈ 0.24; FAIL).\
Your TSC implementation should report **high coherence** on this file: **C_Σ ≈ 0.996 → PASS**.

**What it is:** A glider in Conway's Game of Life—a stable pattern that translates diagonally with period 4.\
Each frame shows one step in the 4-step cycle, demonstrating perfect H/V/D coherence.

**How to use:** Run the exact same pipeline you used for `random-soup.md` on these frames.
You should observe:

- `glider.md` → **high** C_Σ (~0.996), **PASS**
- `random-soup.md` → **low** C_Σ (~0.25), FAIL

If `glider.md` scores low, your implementation likely has issues with pattern recognition, symmetry detection, or temporal coherence measurement.

______________________________________________________________________

## Reference parameters

- Frames: 8 (two complete cycles)
- Grid: Variable size (centered on glider)
- Rule: B3/S23 (Conway's Life)
- Symbols: `#` (live cell), `.` (dead cell)
- Expected C_Σ: ~0.996 (tolerate ~±0.003 depending on implementation details)
- Status: **PASS** (positive control)

______________________________________________________________________

## 1. Articulation

- **H (pattern):** 5-cell motif class, identified up to translation/rotation.
- **V (relation):** neighbor relation; translational symmetry group `G = Z²`.
- **D (process):** Life update rule (B3/S23); one step `U_D`.

______________________________________________________________________

## 2. Witnesses & Registrations

- **w_H:** extract motif class ID from grid snapshots; `μ_H` = class code.
- **w_V:** register symmetry signature and neighbor constraints; `μ_V` = `(G, neighborhood vector)` descriptor.
- **w_D:** apply `U_D`; track orbit length and displacement vector.

Independence: `w_*` run on separate pipelines with distinct preprocessing seeds.

______________________________________________________________________

## 3. Ensemble Checks

### 3.1 Commutation

- Run: `μ_H ∘ U_D` vs `U_D ∘ μ_H` (with `μ_V` contextualization).
- Expectation: equivalence up to known displacement; `E_comm ≈ 1`.

### 3.2 Conservation

- V-invariants: cell count modulo translation; glider's displacement per 4 steps.
- Check: invariants visible in H and preserved by D; `E_cons ≈ 1`.

### 3.3 Symmetry

- `G = Z²` translations. Verify D-equivariance: `U_D(g·x) = g·U_D(x)`, ∀g ∈ G
- Score: near 1 across runs (violations ≈ 0).

### 3.4 Scale

- Coarse-grain: group 2×2 blocks; Fine-grain: sub-cell sampling (super-resolution sim).
- `C_Σ^(s)` stable within τ = 0.02; `E_scale ≈ 1`.

______________________________________________________________________

## 4. Frames

Below are the 8 frames showing two complete glider cycles. Trailing spaces are significant: there are none.

### Frame 1 (t=0)

.....
..#..
...#.
.###.
.....

### Frame 2 (t=1)

.....
.....
.#.#.
..##.
..#..

### Frame 3 (t=2)

.....
.....
...#.
.#.#.
..##.

### Frame 4 (t=3)

.....
.....
..#..
...##
..##.

### Frame 5 (t=4, cycle repeats)

.....
.....
...#.
....#
..###

### Frame 6 (t=5)

.....
.....
.....
..#.#
...##
...#.

### Frame 7 (t=6)

.....
.....
.....
....#
..#.#
...##

### Frame 8 (t=7)

.....
.....
.....
..#..
....#
...##

______________________________________________________________________

## 5. Expected Scores

- `H_c = 0.995` (pattern stability across frames)
- `V_c = 0.996` (relational consistency)
- `D_c = 0.997` (process stability)
- `C_Σ = (0.995·0.996·0.997)^(1/3) ≈ 0.996`

Permutation test (random role relabeling): `ΔC_Σ < 1e-4`.

______________________________________________________________________

## Reproducibility

- Rule: Conway's Life B3/S23
- Initial pattern: Standard glider orientation
- Period: 4 steps
- Translation: (+1, +1) per cycle

## Troubleshooting checklist

- **Low score here?** Check that you are:
  - Detecting the 5-cell motif correctly across translations/rotations
  - Measuring translational symmetry (Z² group)
  - Tracking temporal coherence across the 4-step cycle
  - Using pattern-invariant features (not raw pixel correlation)
  - Computing ensemble checks (commutation, conservation, symmetry, scale)

## License

CC0-1.0 / Public Domain.
