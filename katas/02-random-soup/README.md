# Kata 02 — Random Soup (Negative Control)

## Intent

This kata is the **negative control** for TSC mechanical coherence measurement.
A correct implementation must score `input/random-soup.md` **at or below C_Σ = 0.74**
in mechanical mode. The kata "passes" (exit 0) when the engine correctly assigns a
low coherence score to this deliberately incoherent document.

If this kata fails — i.e., the engine scores the random soup document above 0.74 — it
indicates a regression in threshold discrimination: the scorer cannot distinguish
between structured and unstructured input.

## What It Tests

- **Threshold discrimination**: does the engine score a deliberately incoherent
  document measurably lower than the positive control (kata-01)?
- **Beta axis sensitivity**: does the scorer penalize broken internal links?
- **Gamma axis sensitivity**: does the scorer penalize conflicting version strings?
- **Alpha axis sensitivity**: does the scorer penalize heading case drift?

## Why This Document Scores Low

`input/random-soup.md` intentionally exhibits structural anti-patterns:

| Anti-pattern | What the scorer detects | Score impact |
|---|---|---|
| Broken internal links | 15+ links to non-existent files (β axis) | β ≈ 0.43 |
| Version drift | Multiple conflicting X.Y.Z strings | γ penalized |
| Heading case drift | Same concept named with different casing | α slight penalty |

**C_Σ^num ≈ 0.69** (pre-cutover arithmetic baseline; the canonical v3.2 geometric aggregate is ≤ that value by AM–GM).

The beta axis is the primary bottleneck: the document contains many internal links
that do not resolve within the single-file bundle. The mechanical scorer counts
broken link rate and penalizes accordingly.

## How To Run

```bash
# Run this kata (from repo root)
coh --kata 02-random-soup --mode mechanical

# Expected output: exit 0, JSON with c_sigma_num <= 0.74 and verdict = "fail"
# The runner exits 0 when the kata expectation is met (i.e., the document
# correctly scores in the "fail" range, confirming threshold discrimination).
```

## Score Range Justification

The `expected.score_range` in `kata.toml` is set to `[0.0, 0.74]` against the canonical v3.2 numeric aggregate `C_Σ^num` (geometric mean; spec/tsc-core.md §5). Justification:

- Pre-cutover arithmetic measurement: **0.689**. Canonical geometric aggregate ≤ arithmetic mean by AM–GM, so the negative-control upper bound continues to bracket a stricter fail.
- The lower bound is 0.0 (unconstrained — a lower score is always acceptable).
- The bottleneck axis is **beta** (broken link resolution rate drives the penalty).

## Kata Pass/Fail Semantics for Negative Controls

For `expected.verdict = "fail"` katas, the runner logic is inverted:

- The kata **passes** (exit 0) when `c_sigma_num <= score_range.max`.
  This means the engine correctly identified the document as incoherent.
- The kata **fails** (exit 1) when `c_sigma_num > score_range.max`.
  This means the engine incorrectly scored the incoherent document as coherent —
  a threshold discrimination regression.

## See Also

- `katas/README.md` — kata framework documentation
- `katas/01-glider/` — positive control kata (expected pass, C_Σ^num ≥ 0.80)
- `engine/ocaml/lib/mechanical_scoring.ml` — mechanical scoring implementation
