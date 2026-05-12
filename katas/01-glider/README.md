# Kata 01 — Glider (Positive Control)

## Intent

This kata is the **positive control** for TSC mechanical coherence measurement.
A correct implementation must score `input/glider.md` **at or above C_Σ = 0.87** in
mechanical mode. If this kata fails, there is likely a regression in the mechanical
scoring pipeline.

## What It Tests

- **Mechanical scoring baseline**: does the engine correctly score a well-structured
  document high?
- **Threshold discrimination**: is the engine able to distinguish between a
  well-structured document (kata-01) and a deliberately incoherent one (kata-02)?
- **Runner integration** (`coh --kata`): does the `--kata` flag load, run, and
  compare correctly?

## Why This Document Scores High

`input/glider.md` exhibits the structural properties that mechanical scoring rewards:

| Signal | What the scorer measures | Score |
|--------|--------------------------|-------|
| Terminology consistency (α) | Heading phrase casing is uniform | ~1.0 |
| Repeated structure (α) | Has an H1; consistent heading hierarchy | ~1.0 |
| Cross-reference consistency (β) | Internal links resolve within bundle | ~0.99 |
| Target-file fit (β) | H1 title words match filename | ~1.0 |
| Version surface consistency (γ) | Minimal, non-conflicting version strings | ~0.7 |

**C_Σ = (α · β · γ)^(1/3) ≈ 0.92** (actual score determined at calibration time).

The gamma axis score is below 1.0 because the document has no version strings
(γ defaults to 0.7 for that signal) and no traceability markers (γ defaults to 0.5).
This is expected for a kata input file — it is not a versioned release artifact.

## How To Run

```bash
# Run this kata (from repo root)
coh --kata 01-glider --mode mechanical

# Expected output: exit 0, JSON with c_sigma >= 0.87 and verdict = "pass"
```

## Score Range Justification

The `expected.score_range` in `kata.toml` is set to `[0.87, 1.0]`. Justification:

- The actual measured C_Σ is **0.923** under mechanical mode (calibrated on 2026-05-12).
- The tolerance is ±0.05 on the lower bound, giving `min = 0.87`.
- The upper bound is 1.0 (unconstrained — a higher score is always acceptable).
- The bottleneck axis is **gamma** (version surface consistency signals default to
  penalized values when absent). This is expected for a kata input.

## Relationship to Kata-02

Kata-01 (this kata) is the positive control. Kata-02 (`katas/02-random-soup/`) is
the negative control. Together they test whether the engine correctly discriminates
between structured and unstructured input. The gap should be ≥ 0.2 C_Σ units.

## See Also

- `katas/README.md` — kata framework documentation
- `katas/02-random-soup/` — negative control kata
- `engine/ocaml/lib/mechanical_scoring.ml` — mechanical scoring implementation
