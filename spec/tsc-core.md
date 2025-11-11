# TSC Core v3.1.0

**Version:** v3.1.0\
**Status:** Normative\
**Foundation:** C≡ v3.1.0 (Term Algebra)

______________________________________________________________________

## 0 · Scope

TSC measures dimensional consistency across three evaluators: α (sequential), β (structural), γ (generative).

**Claims:**

- Coherence is measurable via triadic articulation
- Framework self-coheres by its own standards

**Non-claims:**

- Reality is fundamentally triadic (metaphysical)
- Triadic structure is uniquely necessary (exclusivity)

**S₃ Invariance (Normative):** All constructions symmetric under permutations of {α, β, γ}. No axis privilege.

______________________________________________________________________

## 1 · Objects

**Carrier:** C≡ terms T (finite trees with tri(·,·,·) and e)

**Axes:** 𝒜 = {α, β, γ}

**Context:** For each axis a∈𝒜, space Ωₐ where observations live

**Articulation:** Aₐ: T → 𝒫(Ωₐ) projects terms to observable sets Oₐ ⊂ Ωₐ

**Summary:** Sₐ = (dₐ, pₐ, ℋₐ, ℐₐ) where:

- dₐ: representative dimension
- pₐ: probability distribution over features
- ℋₐ: entropy of pₐ
- ℐₐ: invariants (symmetries, conserved quantities)

**Alignment:** σ between Sₐ and Sᵦ with cost Δ(Sₐ, Sᵦ; σ)

**Coherence Predicate:** Coh(Sₐ, Sᵦ; σ) ∈ [0,1] measures consistency

**Ensemble:** 𝒜ₐᵦ is set of alignment methods (|𝒜ₐᵦ| ≥ 3)

**Parameters:** θ∈[0,1], λₐ>0 (a∈𝒜), λₐᵦ>0 (pairs), ε>0, Θ∈(0,1\]

______________________________________________________________________

## 2 · Axioms

**A1 (Completeness):** Every phenomenon admits articulation into (Ωα, Ωβ, Ωγ) with non-empty observations and well-defined summaries.

**A2 (Commensurability):** For any pair (a,b), there exists 𝒜ₐᵦ such that Coh(Sₐ, Sᵦ; σ) is well-defined and symmetric.

**A3 (Scale-Equivariance):** Coherence stable under uniform scale transformations.

**A4 (Self-Articulation Stability):** Aₐ ∘ Aₐ ≅ Aₐ (idempotent up to noise).

**Note:** Formal noise model deferred to implementation guidance (§12).

______________________________________________________________________

## 3 · Pairwise Coherence

### 3.1 Discrepancy

For summaries Sₐ and Sᵦ with alignment σ:

```
Δ(Sₐ, Sᵦ; σ) = θ · Δ_struct(dₐ, dᵦ, ℐₐ, ℐᵦ; σ) 
              + (1-θ) · Δ_dist(pₐ, pᵦ; σ)
```

**Normalization (required):** Δ_struct, Δ_dist ∈ [0,1] after internal scaling. θ ∈ [0,1].

where:

- Δ_struct: structural misalignment
- Δ_dist: distributional divergence
- θ: weighting parameter (default 0.7)

### 3.2 Coherence Function

```
Coh(Sₐ, Sᵦ; σ) = exp(-λₐᵦ · Δ(Sₐ, Sᵦ; σ))
```

Maps discrepancy to [0,1] with Coh → 1 as Δ → 0.

### 3.3 Ensemble Aggregation

For each pair (a,b):

```
Coh̄ₐᵦ = (1/|𝒜ₐᵦ|) Σ{σ∈𝒜ₐᵦ} Coh(Sₐ, Sᵦ; σ)

Varₐᵦ = (1/|𝒜ₐᵦ|) Σ{σ} (Cohₐᵦ⁽σ⁾ - Coh̄ₐᵦ)²
```

Mean Coh̄ₐᵦ is best estimate; Varₐᵦ is witness signal.

______________________________________________________________________

## 4 · Dimensional Scores

### 4.1 Pattern (s_α)

Stability under perturbation:

```
s_α = exp(-λ_α · dα(Sα, S'α))
```

where S'α is from perturbed/resampled Oα.

### 4.2 Process (s_γ)

Temporal stability:

```
s_γ = exp(-λ_γ · W₁(pγ⁽ᵗ⁾, pγ⁽ᵗ⁺Δᵗ⁾))
```

where W₁ is 1-Wasserstein distance.

### 4.3 Relation (s_β)

Geometric mean of pairwise coherences:

```
s_β = (Coh̄αβ · Coh̄βγ · Coh̄γα)^(1/3)
```

**Symmetry requirement:** All three pairs use same:

- Ensemble cardinality: |𝒜αβ| = |𝒜βγ| = |𝒜γα|
- Sensitivity: λₐᵦ = λ_β for all pairs
- Bootstrap depth (for CI estimation)

______________________________________________________________________

## 5 · Aggregate Coherence

```
C_Σ = (s_α · s_β · s_γ)^(1/3)
```

**Properties:**

- **Degeneracy:** Any component = 0 ⟹ C_Σ = 0
- **S₃-Symmetry:** Invariant under axis permutation
- **Homogeneity:** Compatible with exponential form

**Floor:** All scores bounded below by ε before aggregation.

**Weighted form:** For weights w_α, w_β, w_γ > 0 with Σw = 3:

```
C_Σ = exp((1/3)(w_α ln s_α + w_β ln s_β + w_γ ln s_γ))
```

Default: w_α = w_β = w_γ = 1.

______________________________________________________________________

## 6 · Confidence Intervals

All coherence scores report with confidence bounds [CIₗₒ, CIₕᵢ] at declared level (default 95%).

**Bootstrap:** Resample observation indices and ensemble members.

**Out-of-Distribution (OOD):** Maintain reference distribution of historical C_Σ values. Compute stability statistic Zₜ (z-score, KL, Wasserstein). Flag if Zₜ ≥ Zcᵣᵢₜ.

**Note:** Core produces CI and OOD artifacts; Operational consumes them as witnesses.

______________________________________________________________________

## 7 · Stability

### 7.1 Contraction Property

Let 𝒮³ be space of summary triples (Sα, Sβ, Sγ) with metric d𝒮.

Define update operator:

```
T: 𝒮³ → 𝒮³
T(Sα, Sβ, Sγ) = (Tα(Sβ, Sγ), Tβ(Sγ, Sα), Tγ(Sα, Sβ))
```

**Interpretation:** Each summary Tₐ is refined based on pairwise coherences with the other two (Jacobi-style parallel update). Fixed point T(S\*) = S\* represents mutually coherent summaries.

**Contraction test:** Define

```
κ := Lₛᵤₘ · Lₐₗᵢgₙ · max{λₐᵦ}
```

where Lₛᵤₘ, Lₐₗᵢgₙ are Lipschitz constants for summary and alignment operations.

If κ < 1, then T is contraction on 𝒮³ with unique fixed point (S*α, S*β, S\*γ).

### 7.2 Independence

C≡ v3.1.0 §3.4 proves three evaluators are pairwise non-isomorphic via distinct idempotent profiles:

- α: idempotents exactly {0, M}
- β: fully idempotent (all elements)
- γ: idempotent only at (0,0)

This algebraic independence guarantees dimensional distinction—no Eckmann-Hilton collapse.

______________________________________________________________________

## 8 · Verification Interface

**Input:**

- Contexts: Ωα, Ωβ, Ωγ (with declared structure)
- Articulations: Aα, Aβ, Aγ
- Alignment ensembles: 𝒜αβ, 𝒜βγ, 𝒜γα (each |𝒜ₐᵦ| ≥ 3)
- Parameters: θ, λ_α, λ_β, λ_γ, λₐᵦ, ε, Θ

**Output:**

- Dimensional scores: s_α, s_β, s_γ ∈ [0,1]
- Aggregate: C_Σ ∈ [0,1]
- Confidence intervals: [CIₗₒ, CIₕᵢ]
- Pairwise coherences: Coh̄αβ, Coh̄βγ, Coh̄γα
- Variances: Varαβ, Varβγ, Varγα
- Leverage: λ_α, λ_β, λ_γ, λ_Σ
- Stability: Lₛᵤₘ, Lₐₗᵢgₙ, κ
- OOD statistic: Zₜ
- Provenance: complete parameter record

______________________________________________________________________

## 9 · Properties

**P1 (S₃-Invariance):** For any π∈S₃:

```
C_Σ(Oα, Oβ, Oγ) = C_Σ(Oπ(α), Oπ(β), Oπ(γ))
```

**P2 (Normalization):** Perfect alignment (Δ=0) ⟹ C_Σ=1. Complete incoherence (Δ→∞) ⟹ C_Σ→0.

**P3 (Monotonicity):** Improving any dimension (holding others fixed) cannot decrease C_Σ.

**P4 (Degeneracy):** Any component = 0 ⟹ C_Σ = 0.

**P5 (Lipschitz):** C_Σ is Lipschitz continuous with constant L\_{C_Σ} ≤ κ.

______________________________________________________________________

## 10 · Composition

Phenomenon P decomposes into P₁,...,Pₙ, each with C_Σ(Pᵢ).

**Composition bound:**

```
C_Σ(P) ≥ exp((1/n) Σᵢ ln C_Σ(Pᵢ)) - εcₒₘₚ
```

where εcₒₘₚ is coupling penalty.

**Modularity:** Coherent modules remain coherently articulable under composition.

______________________________________________________________________

## 11 · Diagnostics

**Dimensional leverage:**

```
λₐ = -ln(max(s_a, ε))  for a ∈ {α, β, γ}
```

**Aggregate leverage:**

```
λ_Σ = (1/Σw) Σ{a∈𝒜} wₐ λₐ
```

**Coherence-Energy Duality:**

```
E_Σ = -(1/3)(ln s_α + ln s_β + ln s_γ) = λ_Σ
```

Minimizing E_Σ ⟺ maximizing C_Σ.

Higher λₐ indicates dimension a contributes more to incoherence.

______________________________________________________________________

## 12 · Implementation Notes

**Summary construction:**

- dₐ: intrinsic dimension (PCA, manifold learning)
- pₐ: empirical distribution over features
- ℋₐ: Shannon entropy
- ℐₐ: detected symmetries, conserved quantities

**Alignment ensemble:**

- Entropic optimal transport (varied regularization)
- Gromov-Wasserstein (metric contexts)
- Structural matching (graph/relational contexts)

**Bootstrap CI:** Resample indices with replacement; compute C_Σ percentiles.

**OOD tracking:** Rolling window (e.g., 20 verifications); robust z-score.

______________________________________________________________________

**End — TSC Core v3.1.0**
