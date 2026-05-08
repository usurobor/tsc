# TSC Core v3.2.0

**Version:** v3.2.0\
**Status:** Normative\
**Foundation:** C≡ v3.1.0 (Term Algebra)

**Change from v3.1.0:** Pairwise coherence is now computed via a **barrier transform** φ on a normalized discrepancy δ ∈ [0,1], producing an unbounded **discrepancy energy** D ∈ [0,∞]. The aggregate C_Σ is split into a mathematical form C_Σ^math (carrying the strict Degeneracy Axiom) and a numerical form C_Σ^num (used for bootstrap, OOD, and verdict comparison). Sensitivity λ no longer sets a coherence floor. See §3.2, §5.

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

**Alignment:** σ between Sₐ and Sᵦ with normalized discrepancy δ(Sₐ, Sᵦ; σ) ∈ [0,1] and discrepancy energy D(Sₐ, Sᵦ; σ) ∈ [0, ∞]

**Coherence Predicate:** Coh(Sₐ, Sᵦ; σ) ∈ [0,1] measures consistency

**Ensemble:** 𝒜ₐᵦ is set of alignment methods (|𝒜ₐᵦ| ≥ 3)

**Parameters:** θ∈[0,1], λₐ>0 (a∈𝒜), λₐᵦ>0 (pairs), ε>0, Θ∈(0,1], barrier transform φ: [0,1] → [0,∞] (default φ(δ) = δ/(1−δ))

______________________________________________________________________

## 2 · Axioms

**A1 (Completeness):** Every phenomenon admits articulation into (Ωα, Ωβ, Ωγ) with non-empty observations and well-defined summaries.

**A2 (Commensurability):** For any pair (a,b), there exists 𝒜ₐᵦ such that Coh(Sₐ, Sᵦ; σ) is well-defined and symmetric.

**A3 (Scale-Equivariance):** Coherence stable under uniform scale transformations.

**A4 (Self-Articulation Stability):** Aₐ ∘ Aₐ ≅ Aₐ (idempotent up to noise).

**Note:** Formal noise model deferred to implementation guidance (§12).

______________________________________________________________________

## 3 · Pairwise Coherence

### 3.1 Normalized Discrepancy

For summaries Sₐ and Sᵦ with alignment σ:

```
δ(Sₐ, Sᵦ; σ) = θ · δ_struct(dₐ, dᵦ, ℐₐ, ℐᵦ; σ)
              + (1-θ) · δ_dist(pₐ, pᵦ; σ)
```

**Normalization (required):** δ_struct, δ_dist ∈ [0,1] after internal scaling. θ ∈ [0,1]. Therefore δ ∈ [0,1].

where:

- δ_struct: structural misalignment
- δ_dist: distributional divergence
- θ: weighting parameter (default 0.7)

**Why bounded?** Bounded δ is required for scale-equivariance (Witness W3), comparability across heterogeneous alignment methods, and the dependence-aware bookkeeping in tsc-observation-dynamics.

### 3.2 Coherence Function (Barrier Transform)

The bounded discrepancy δ is mapped through a monotone barrier function φ to an unbounded **discrepancy energy** D, then to coherence via exponential decay.

**Barrier function.** φ: [0,1] → [0,∞] is monotone increasing with:

```
φ(0) = 0
lim{δ → 1⁻} φ(δ) = +∞
```

**Canonical default:**

```
φ(δ) = δ / (1 − δ)    for 0 ≤ δ < 1
φ(1) = +∞
```

Implementations MAY substitute another φ satisfying these limit conditions (e.g., −ln(1−δ)), provided the choice is recorded in provenance.

**Discrepancy energy:**

```
D(Sₐ, Sᵦ; σ) := λₐᵦ · φ(δ(Sₐ, Sᵦ; σ))     D ∈ [0, ∞]
```

**Coherence:**

```
Coh(Sₐ, Sᵦ; σ) := exp(−D(Sₐ, Sᵦ; σ))     (convention: exp(−∞) = 0)
```

**Limits:**

- δ = 0 ⟹ D = 0 ⟹ Coh = 1 (perfect match)
- δ → 1 ⟹ D → ∞ ⟹ Coh → 0 (complete mismatch; strict zero)

**Role of λₐᵦ.** λₐᵦ > 0 is purely a *sensitivity* parameter — it scales the energy curve. It does **not** establish a coherence floor; the floor (Coh = 0) arises strictly from δ = 1.

**Numerical guidance.** Compute in energy space (form D first, then Coh = exp(−D)). Implementations MAY clip δ to [0, 1 − η_φ] with η_φ ≈ 10⁻¹² when finite-precision arithmetic requires it; record η_φ in provenance.

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

The aggregate has two compatible forms — a **mathematical** form that carries the strict Degeneracy Axiom, and a **numerical** form used for computation.

### 5.1 Mathematical aggregate (normative)

```
C_Σ^math = (s_α · s_β · s_γ)^(1/3)
```

The geometric mean of true component scores. Used for proofs and properties (P1–P5, §9).

### 5.2 Numerical aggregate (operational)

```
C_Σ^num = exp((1/3)(w_α ln(max(s_α, ε)) + w_β ln(max(s_β, ε)) + w_γ ln(max(s_γ, ε))))
```

with weights w_α, w_β, w_γ > 0 and Σw = 3. Default: w_α = w_β = w_γ = 1.

Used for: bootstrap CI estimation (§6), OOD reference distributions (§6), and verdict comparison against Θ (Operational §5).

### 5.3 Equivalence regime

When all sᵢ ≥ ε (and wᵢ = 1), C_Σ^num = C_Σ^math exactly. The forms diverge only when at least one sᵢ < ε.

### 5.4 Properties

- **Degeneracy (P4, mathematical):** Any sᵢ = 0 ⟹ C_Σ^math = 0
- **S₃-Symmetry:** Both forms invariant under axis permutation
- **Homogeneity:** Compatible with exponential form

### 5.5 Provenance

Whenever any sᵢ < ε, implementations MUST record:

- `numeric_floor_applied: true`
- `epsilon: <ε value>`
- `zero_component_present: <true if any sᵢ = 0 strictly, else false>`

When `zero_component_present = true`, the mathematical interpretation is C_Σ^math = 0; the operational verdict treats this as failure of the coherence threshold (Operational §5), independent of the C_Σ^num value.

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

**P2 (Normalization):** Perfect alignment (δ = 0, equivalently D = 0) ⟹ C_Σ = 1. Complete mismatch (δ → 1, equivalently D → ∞) ⟹ C_Σ^math → 0 (strict).

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

**Bootstrap CI:** Resample indices with replacement; compute C_Σ^num percentiles.

**OOD tracking:** Rolling window (e.g., 20 verifications) of C_Σ^num; robust z-score. **Note:** When migrating from coherence formulations prior to v3.2.0, reset the OOD reference distribution — historical C_Σ values are not directly comparable across the barrier-transform cutover.

**Barrier transform numerical stability:**

- Compute in energy space: D = λ · φ(δ), then Coh = exp(−D).
- For φ(δ) = δ/(1−δ), clip δ to [0, 1 − η_φ] with η_φ ≈ 10⁻¹² when finite-precision overflow is a concern. Record η_φ in provenance.

**Lipschitz analysis (W4):** L_align is the Lipschitz constant of the *summary → δ* map (over bounded δ space). φ is a fixed transform external to the iteration map T (§7), so the existing contraction analysis on summary space carries over unchanged.

______________________________________________________________________

**End — TSC Core v3.2.0**
