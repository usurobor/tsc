# Migration Guide: v2.x → v3.0

**For users of TSC v2.x**

______________________________________________________________________

## Conceptual Changes

### What v2.x Called Them vs. v3.0

| v2.x Concept        | v3.0 Equivalent                | Changed?     |
| ------------------- | ------------------------------ | ------------ |
| α-axis (pattern)    | α evaluator to (ℕ, ⊕, 0)       | Formalized   |
| β-axis (relation)   | β evaluator to (ℕ³, ⊔, 0³)     | Formalized   |
| γ-axis (process)    | γ evaluator to (ℕ×ℕ, ⊗, (0,0)) | Formalized   |
| C≡ axioms (C1-C6)   | Term algebra + evaluators      | **Replaced** |
| Braided interchange | (removed)                      | **Removed**  |
| S₃ symmetry         | S₃ gauge action                | Refined      |
| C_Σ = geo3(α,β,γ)   | C_Σ = (s_α·s_β·s_γ)^(1/3)      | Unchanged    |

______________________________________________________________________

## Code Changes

### Old (v2.x) Measurement

```python
# This no longer works
from tsc import measure_coherence

score = measure_coherence(
    specs={'alpha': text_a, 'beta': text_b, 'gamma': text_c},
    check_braided=True  # ← No longer exists
)
```

### New (v3.0) Measurement

```python
from tsc import tri, Atom, Empty
from tsc.measure import eval_alpha, eval_beta, eval_gamma, coherence

# 1. Build term representation
term = build_term_from_system(system)

# 2. Evaluate
alpha_val = eval_alpha(term)
beta_val = eval_beta(term)
gamma_val = eval_gamma(term)

# 3. Score (requires operational definitions)
score = coherence(term, spec)
```

______________________________________________________________________

## What You Don't Need Anymore

### Removed Components

**Parser infrastructure:**

- ❌ `braid_parser.py` (400+ lines of LaTeX handling)
- ❌ `normalize_latex()` function
- ❌ Function notation transformer
- ❌ Braided witness checker

**Axiom checking:**

- ❌ C1-C6 verification
- ❌ Hexagon coherence tests
- ❌ Braided interchange normalization

**Why removed?** Not necessary—algebraic independence proven directly.

______________________________________________________________________

## What You Still Need

### Kept Components

**Measurement structure:**

- ✅ Three-axis evaluation (now α, β, γ evaluators)
- ✅ Geometric mean aggregation
- ✅ S₃ symmetry checking
- ✅ Bootstrap confidence intervals

**Witnesses:**

- ✅ S₃ permutation test
- ✅ Variance floor
- ✅ OOD detection (when implemented)

______________________________________________________________________

## Implementation Path

### Phase 1: Term Extraction

**Old approach:** Parse markdown → extract features → compute vectors

**New approach:** Parse markdown → build tri(·,·,·) term → normalize

```python
def extract_term(markdown_text):
    """Convert markdown to term algebra."""
    # Parse structure
    sections = parse_markdown(markdown_text)
    
    # Build term recursively
    children = [extract_term(sec) for sec in sections]
    
    if len(children) == 0:
        return Empty
    elif len(children) == 1:
        return Atom(children[0])
    elif len(children) == 3:
        return tri(children[0], children[1], children[2])
    else:
        # Pad or chunk to triads
        return chunk_to_triads(children)
```

### Phase 2: Evaluation

```python
# These are now deterministic algorithms, not heuristics
alpha_val = eval_alpha(term)  # Returns int
beta_val = eval_beta(term)    # Returns (int, int, int)
gamma_val = eval_gamma(term)  # Returns (int, int)
```

### Phase 3: Scoring

```python
# Need operational definitions (work in progress)
s_alpha = score_alpha(term, spec)  # ∈ [0,1]
s_beta = score_beta(term, spec)    # ∈ [0,1]
s_gamma = score_gamma(term, spec)  # ∈ [0,1]

C_sigma = (s_alpha * s_beta * s_gamma) ** (1/3)
```

______________________________________________________________________

## Benefits of v3.0

### For Practitioners

**Simpler:**

- No category theory required
- No LaTeX syntax hell
- Clear algorithmic definitions

**More Rigorous:**

- Proven independence (Theorem 2.3)
- Decidable equivalence (nf algorithm)
- Proof-assistant ready

### For Theorists

**Cleaner Foundation:**

- Elementary proofs (no Mac Lane)
- Term algebra (standard PL theory)
- Clear connection to monoid theory

**Research Questions:**

- Other evaluators with distinct profiles?
- Completeness/universality theorems?
- Extension to binding/variables?

______________________________________________________________________

## Timeline

**Now:** v3.0.0 specification released

**Q1 2025:** Reference implementation (Python)

**Q2 2025:** Self-coherence achieved (C_Σ ≥ 0.75)

**Q3 2025:** Applications (GitHub badge, blockchain oracle)

______________________________________________________________________

## Questions?

Open issue on GitHub: https://github.com/usurobor/tsc/issues
