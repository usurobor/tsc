# Kata 03 — Comparative ranking (glider > random-soup)

**Difficulty:** 2 · **Mode:** mechanical · **Verdict:** pass-if-ranking-correct

Phase 2 kata. Verifies that the mechanical scorer ranks a **well-structured**
input (the kata-01 glider document) **above** an **incoherent** input (the
kata-02 random-soup document) by C_Σ. This is a *comparative* invariant: not
the absolute score of either bundle, but their relative ordering.

## How to run

```bash
coh --kata 03-comparative --mode mechanical
```

Exits 0 when the actual ranking matches `expected.ranking` in
[`kata.toml`](kata.toml); non-zero otherwise.

## Schema extension

This kata exercises the Phase 2 `[[components]]` extension to `kata.toml`. A
kata with components is scored per-component (each component becomes its own
`Bundle.t`), and the pass-criterion is the `expected.ranking` ordering rather
than a single-bundle `score_range`.

Phase 1 katas (kata-01, kata-02) continue to use the flat `[input].files`
schema unchanged. See [`katas/README.md` §kata.toml schema](../README.md).

## Input shape

The inputs are physical copies of the kata-01 and kata-02 input files, placed
under per-component subdirectories of this kata's `input/` directory:

- `input/glider/glider.md` — copy of `katas/01-glider/input/glider.md`
- `input/random-soup/random-soup.md` — copy of `katas/02-random-soup/input/random-soup.md`

**Why copies instead of relative-path references.** The Phase 1 file resolver
joins each `files` entry to the kata's own directory; relative-path escapes
(`../01-glider/input/glider.md`) would break the bundle's
"path-relative-to-root" canonicalisation used by `Bundle.build_bundle`.
Copying the inputs in keeps the bundle paths unambiguous and the kata
self-contained. The copies are small (≈8 KB total) and the canonical Phase 1
inputs remain the source of truth — if those change, this kata's copies
update in the same cycle.

## Observed C_Σ (calibration)

On `cycle/34-impl` HEAD:

- `glider` component: **C_Σ = 0.9233**
- `random-soup` component: **C_Σ = 0.6889**
- Ranking margin: ≈0.234

These match the standalone kata-01 and kata-02 scores (Phase 1 sanity:
component-scoring uses the same `Mechanical_scoring.score_bundle` path as the
single-bundle runner). If the mechanical scorer ever drifts such that the
random-soup margin closes below ≈0.05, this kata will start producing
ambiguous rankings and the calibration should be revisited.

## Why this kata matters

kata-01 and kata-02 each pin one side of the mechanical-scorer band (positive
control near 1.0; negative control well below 0.75). Neither, alone, asserts
the **monotonicity** of the scorer across the band. kata-03 closes that gap:
if a regression flips the mechanical scorer's sense (e.g. swaps a min/max in
one of the structural signals), kata-01 and kata-02 might still pass their
individual ranges, but kata-03 will fail because the ranking inverts.
