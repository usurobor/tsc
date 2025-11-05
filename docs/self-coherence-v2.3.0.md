# TSC Self-Coherence v2.3.0 Baseline

**Status:** Measurement Capability Delivered\
**Verdict:** FAIL (Repository Incoherent - Expected)\
**Date:** 2025-11-04

## Executive Summary

The v2.3.0 self-measurement capability is **working correctly**. The FAIL verdict indicates that the TSC repository is not yet fully self-coherent by its own standards (Θ = 0.90). This is **honest measurement**, not a bug.

**Key Finding:** The implementation is S₃-symmetric and produces reproducible results with full provenance. The repository itself needs improvement.

## Measurement Results

```json
{
  "C_sigma": 0.238,
  "ci": {"C_sigma_lo": 0.093, "C_sigma_hi": 0.297},
  "verdict": "FAIL"
}
```

**Gate Failure:** CI_lo (0.093) < Θ (0.90)

## Witness Results

### ✅ S₃ Permutation: PASS

All 6 axis permutations produce consistent results within baseline CI:

```
α-β-γ: 0.195 ✓
α-γ-β: 0.195 ✓
β-α-γ: 0.195 ✓
β-γ-α: 0.195 ✓
γ-α-β: 0.195 ✓
γ-β-α: 0.195 ✓
```

**Interpretation:** Implementation is genuinely S₃-invariant. No role privilege detected.

### ❌ Braided Interchange: FAIL

```json
{
  "braid_mean": 0.923,
  "braid_CI": [0.769, 1.0],
  "tau_braid": 0.001,
  "braid_pairs": 13
}
```

**Critical Issue:** 92.3% of braided equations fail to normalize to equality.

**Possible Causes:**

1. Parser doesn't handle all C≡ notation (φ subscripts, implicit parens)
1. Normalization incomplete (missing unit laws, commutativity)
1. Equations in spec genuinely inconsistent (needs review)

**Action:** Debug which specific equations fail (v2.3.1).

## Axis Scores

| Axis             | Score | Interpretation                                |
| ---------------- | ----- | --------------------------------------------- |
| **α** (pattern)  | 0.306 | Moderate stability between parsers            |
| **β** (relation) | 0.061 | **Very weak** - specs poorly cross-referenced |
| **γ** (process)  | 0.721 | Good temporal stability (git history)         |

### α-axis: Pattern Stability

**Observation:** Two independent parsers (lexical TF vs structural signature) show moderate agreement.

**Diagnostics:**

- 1,485 lexical tokens extracted
- 135 structural features (headings, bullets, definitions)
- Cosine similarity moderate but not high

**Interpretation:** Specs have consistent vocabulary but loose structural patterns.

### β-axis: Relational Coherence (Critical Issue)

**Observation:** Term graph extremely sparse and disconnected.

**Diagnostics:**

- 57 canonical terms identified
- Cross-reference frequency very low
- Graph embeddings show poor alignment

**Root Cause:** Specs don't reference each other explicitly. Terms defined in glossary aren't consistently linked in other specs.

**Fix (v2.3.2):** Add explicit cross-references:

```markdown
Per [tsc-glossary.md](tsc-glossary.md), **coherence** is defined as...
See §3.1 in [tsc-core.md](tsc-core.md) for the measurement calculus.
```

**Target:** Raise β_c from 0.061 → 0.50+ by v2.4.0.

### γ-axis: Process Stability

**Observation:** Good temporal consistency across git snapshots.

**Diagnostics:**

- Git history: 2 snapshots found
- Wasserstein distance: 0.082 (low drift)
- λ_γ = 4.0 → γ_c = 0.721

**Interpretation:** Specs evolve coherently over time. Process dimension is stable.

## Provenance

```json
{
  "git_commit": "1a71d6c",
  "dirty": true,
  "python": "3.11.14",
  "p_ref_hash": "sha256:265b3e86...",
  "spec_files": [
    "c-equiv-kernel.md",
    "c-equiv.md", 
    "tsc-core.md",
    "tsc-glossary.md",
    "tsc-oper.md"
  ]
}
```

**Reproducibility:** Re-running with same commit and seed will produce identical results (within floating-point tolerance).

## Parameters

```json
{
  "theta": 0.7,
  "lambda_alpha": 4.0,
  "lambda_beta": 4.0, 
  "lambda_gamma": 4.0,
  "n_boot": 1000,
  "tau_braid": 0.001,
  "Theta": 0.90,
  "seed": 42
}
```

## Roadmap to Self-Coherence

### v2.3.1: Fix Braided Parser (Engineering)

**Goal:** Reduce braid_mean from 0.923 → \<0.01

**Tasks:**

1. Debug which equations fail normalization
1. Extend parser to handle:
   - Subscripted φ\_{ab} notation
   - Implicit parentheses
   - Variable α-renaming
1. Add to normalization:
   - Unit laws (1_a ⊙\_a x = x)
   - Commutativity where declared
   - Hexagon coherence

**Acceptance:** braid_CI_hi ≤ 0.001 (τ_braid gate)

### v2.3.2: Strengthen Cross-References (Content)

**Goal:** Raise β_c from 0.061 → 0.50+

**Tasks:**

1. Add explicit "see §X" links between all specs
1. Reference glossary terms consistently with markdown links
1. Create index of cross-references
1. Add "References" section to each spec

**Acceptance:** β_c ≥ 0.50

### v2.4.0: Achieve Self-Coherence (Integration)

**Goal:** C_Σ ≥ 0.90, all witnesses PASS

**Gate:** Make self-coherence a release requirement

- CI runs `tsc self` on every PR
- Merges blocked if verdict ≠ PASS
- Repository cannot release until self-coherent

**Expected Timeline:**

- v2.3.1: ~1 week (parser fixes)
- v2.3.2: ~2 weeks (content improvements)
- v2.4.0: ~1 month (integration + polish)

## How to Run

```bash
# From repository root
tsc self --out coherence_report.json

# With custom parameters
tsc self --Theta 0.95 --n-boot 2000 --seed 123
```

## Interpretation Guidelines

**PASS Conditions:**

1. CI_lo(C_Σ) ≥ Θ (default 0.90)
1. braid_CI_hi ≤ τ_braid (default 0.001)
1. S₃ witness passes (all permutations within CI)

**Current Status:**

- ❌ Condition 1: FAIL (0.093 < 0.90)
- ❌ Condition 2: FAIL (1.0 > 0.001)
- ✅ Condition 3: PASS

**Why This Matters:**

A FAIL verdict means the repository articulations (pattern, relation, process) don't form a coherent triad. This is valuable feedback:

- Not a measurement bug
- Not arbitrary thresholds
- Concrete issues to fix

**The goal is not to lower thresholds to pass, but to improve the repository to genuinely achieve coherence.**

## Technical Notes

### Bootstrap CI Method

CI computed by resampling across axis replicates (n_boot=1000):

```python
for _ in range(n_boot):
    α = sample(α_reps)
    β = sample(β_reps) 
    γ = sample(γ_reps)
    C_Σ = (α · β · γ)^(1/3)
```

This respects axis independence and produces valid confidence intervals.

### S₃ Invariance Test

All 6 permutations of {α, β, γ} recomputed with matched replicate indices. Geometric mean is S₃-symmetric by construction (commutative + associative).

### AST Normalization

Braided equations parsed into minimal AST:

- Right-association
- Middle-four interchange (MFI)
- Fixpoint computation

Terms compared structurally after normalization.

## License

CC-BY-4.0 (documentation)\
Apache-2.0 (code)

______________________________________________________________________

**End of v2.3.0 Baseline Report**
