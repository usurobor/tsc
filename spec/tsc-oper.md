# TSC Operational v3.0.0

**Version:** 3.0.0  
**Status:** Normative  
**Foundation:** TSC Core v3.0.0

---

## 0 · Scope

Core defines *what* to compute. Operational defines *when* to accept, *how* to validate, and *what* to record.

This document specifies:
- **Witnesses:** degeneracy guards
- **Floors:** acceptance thresholds
- **Controller:** verification state machine
- **Provenance:** required metadata
- **Self-Application:** TSC measuring itself

---

## 1 · Witnesses

Witnesses are observable signals detecting measurement validity. Each produces w ∈ ℝ≥0. Lower is better (zero = perfect).

### W1: Axis-Permutation (Mathematical S₃)

**Signal:**
```
w_S3 = max{π∈S₃} |C_Σ(Oα, Oβ, Oγ) - C_Σ(Oπ(α), Oπ(β), Oπ(γ))|
```

**Test:** All 6 explicit permutations of {α, β, γ} yield same C_Σ within tolerance.

**Purpose:** Enforce P1 (S₃-symmetry) at mathematical level—permuting observations doesn't change coherence.

### W2: Role-Gauge (Implementation Independence)

**Signal:**
```
w_gauge = |C_Σ(labeled) - max{π∈S₃} C_Σ(unlabeled remapped by π)|
```

**Test:** Stripping role labels and auto-discovering best axis assignment yields same C_Σ.

**Purpose:** Enforce that measurement procedure doesn't depend on which axis labels are used—role is presentation gauge, not intrinsic property.

**Note:** W1 tests mathematical invariance (permute inputs); W2 tests computational invariance (implementation ignores labels). Both required.

### W3: Scale-Equivariance

**Signal:**
```
w_scale = |C_Σ(φ(Oα), φ(Oβ), φ(Oγ)) - C_Σ(Oα, Oβ, Oγ)|
```

**Test:** Uniform scale transform φ (e.g., all features × 2) preserves coherence.

**Purpose:** Enforce A3. Coherence is scale-free.

**Calibration:** If scale sensitivity detected, require 1-Lipschitz calibration map and record in provenance.

### W4: Variance/Lipschitz

**Variance signal:**
```
w_var = max{Varαβ, Varβγ, Varγα}
```

**Lipschitz signal:**
```
w_lip = κ = Lₛᵤₘ · Lₐₗᵢgₙ · max{λₐᵦ}
```

**Test:** 
- Variance: Ensemble agreement high (variance low)
- Lipschitz: Contraction condition satisfied (κ < 1)

**Purpose:** Detect unstable alignments (high variance) or non-contractive updates.

---

## 2 · Witness Floors

**Floor table:**

| Witness | Symbol | Default | Units |
|---------|--------|---------|-------|
| S₃ | τ_S3 | 0.05 | absolute |
| Gauge | τ_gauge | 0.05 | absolute |
| Scale | τ_scale | 0.10 | absolute |
| Variance | τ_var | 0.15 | dimensionless |
| Lipschitz | τ_lip | 0.95 | dimensionless |

**Verdict:** Witness w passes if w ≤ τ_w.

**Parameter provenance:** If floors tuned from data, record selection procedure and freeze before final measurement.

---

## 3 · Sampling Policy

**Observation counts:**
- Minimum per axis: N_min = 30
- Bootstrap resamples: N_boot = 1000
- Alignment ensemble: |𝒜ₐᵦ| ≥ 3 per pair

**Temporal:**
- Process window: Δt (axis-dependent, recorded)
- OOD reference: rolling 20 verifications

**Block bootstrap:** If observations temporally/spatially correlated, use block size Δn ≥ 10.

---

## 4 · Controller States

Verification proceeds through states:

### HANDSHAKE
**Entry:** New verification request  
**Action:** Validate inputs (contexts, articulations, parameters)  
**Exit:** All inputs well-formed → MEASURE

### MEASURE
**Entry:** Inputs validated  
**Action:** 
1. Articulate: Aₐ(T) → Oₐ for all a
2. Summarize: Oₐ → Sₐ
3. Align: Apply ensemble 𝒜ₐᵦ
4. Score: Compute αc, βc, γc, C_Σ
5. Bootstrap: Generate CI

**Exit:** Scores computed → WITNESS

### WITNESS
**Entry:** Scores computed  
**Action:** Evaluate all witnesses W1-W4  
**Exit:**
- All pass → VERDICT
- Any fail → DIAGNOSE

### DIAGNOSE
**Entry:** Witness failure  
**Action:**
1. Identify failing witness
2. Compute dimensional leverage λₐ
3. Log diagnostic

**Exit:** Report failure → TERMINAL

### VERDICT
**Entry:** All witnesses pass  
**Action:**
1. Check C_Σ ≥ Θ (acceptance threshold)
2. Check CI width < tolerance
3. Check OOD: Zₜ < Zcᵣᵢₜ

**Exit:**
- All pass → ACCEPT
- Any fail → REJECT

### ACCEPT / REJECT
**Terminal states**

**Accept:** C_Σ ≥ Θ with all witnesses passing  
**Reject:** C_Σ < Θ or witness failure or OOD

---

## 5 · Verdict Logic

**Pass conditions (all must hold):**
```
1. C_Σ ≥ Θ                    (coherence threshold)
2. w_S3 ≤ τ_S3                (mathematical symmetry)
3. w_gauge ≤ τ_gauge          (computational independence)
4. w_scale ≤ τ_scale          (scale equivariance)
5. w_var ≤ τ_var              (ensemble stability)
6. w_lip < 1                  (contraction)
7. CIₕᵢ - CIₗₒ ≤ δ_CI         (precision)
8. Zₜ < Zcᵣᵢₜ                 (distribution stability)
```

**Fail-fast:** Exit on first failure for efficiency.

**Default thresholds:**
- Θ = 0.75 (coherence)
- δ_CI = 0.20 (CI width)
- Zcᵣᵢₜ = 2.5 (OOD, ~95% quantile)

---

## 6 · Provenance Bundle

**Required metadata:**

**Parameters:**
- θ (discrepancy weight)
- λα, λβ, λγ (dimensional sensitivities)
- λₐᵦ (pairwise sensitivities)
- ε (numerical floor)
- Θ (acceptance threshold)
- All witness floors τ_*

**Computation:**
- Alignment ensemble specs: types, parameters
- Summary schemas: (d, p, ℋ, ℐ) construction
- Bootstrap: seed, N_boot, block size Δn
- CI level (default 95%)

**Results:**
- αc, βc, γc, C_Σ
- [CIₗₒ, CIₕᵢ]
- Coh̄αβ, Coh̄βγ, Coh̄γα
- Varαβ, Varβγ, Varγα
- λα, λβ, λγ, λ_Σ
- All witness signals: w_S3, w_gauge, w_scale, w_var, w_lip
- OOD: Zₜ, reference window

**Calibration:**
- Lₛᵤₘ, Lₐₗᵢgₙ (Lipschitz constants)
- κ (contraction scalar)
- Scale calibration maps (if any)
- Ground metrics for W₁ distances

**Verdict:**
- State sequence: HANDSHAKE → MEASURE → ...
- Pass/fail per witness
- Final verdict: ACCEPT/REJECT
- Timestamp, version

**Format:** JSON or equivalent structured format. Must be machine-readable.

---

## 7 · Self-Application Protocol

TSC measures itself by treating the TSC specification corpus as phenomenon P.

### 7.1 Corpus

**Documents:**
- C≡ foundation (spec/c-equiv.md)
- TSC Core (spec/tsc-core.md)
- TSC Operational (spec/tsc-oper.md)
- Glossary (spec/tsc-glossary.md)

**Articulation:**
- α: Pattern analysis (structure, sections, definitions)
- β: Cross-references (citations, dependencies)
- γ: Version evolution (commits, diffs, temporal)

### 7.2 Measurement

**Protocol:**
1. Extract terms: Parse markdown → tri(·,·,·) structure
2. Articulate: Aₐ(corpus) → Oₐ
3. Apply Core: Compute C_Σ(TSC)
4. Apply Operational: Run all witnesses

**Note:** Parsing procedure is implementation-dependent. Must preserve structural/relational/temporal distinctions for α/β/γ axes.

**Witnesses tested:**
- W1 (S₃): Permute axis assignments
- W2 (Gauge): Strip/restore role labels
- W3 (Scale): Uniform feature scaling
- W4 (Variance/Lipschitz): Check ensemble/contraction

### 7.3 Acceptance

**Self-coherence achieved if:**
```
C_Σ(TSC) ≥ Θ
All witnesses pass
OOD stable
```

**Current target:** Θ = 0.75

**Reporting:** Self-coherence score published in docs/self-coherence-v3.0.0.md

---

## 8 · Release Criteria

**Version release requires:**

1. **Self-coherence:** C_Σ(TSC) ≥ Θ with all witnesses passing
2. **Dimensional floors:** Each αc, βc, γc ≥ 0.60 (no degenerate dimensions)
3. **CI precision:** CI width ≤ 0.20
4. **OOD stability:** Zₜ < Zcᵣᵢₜ for last 5 measurements
5. **Provenance complete:** All parameters, witnesses, calibrations recorded
6. **Witness pass rate:** Each witness ≥ 95% pass rate across corpus

**Release artifacts:**
- Updated spec files
- Self-coherence report (docs/self-coherence-v3.0.0.md)
- Provenance bundle (coherence_report.json)
- Implementation reference (if updated)

**Version increment:**
- Major (3.x → 4.x): Foundation change (C≡ version)
- Minor (3.0 → 3.1): Measurement protocol change
- Patch (3.0.0 → 3.0.1): Witness floor adjustment

---

## 9 · Implementation Guidance

**Witness evaluation order:**
1. W1 (S₃): Fast, fails often → check first
2. W2 (Gauge): Fast, rarely fails
3. W3 (Scale): Moderate cost
4. W4 (Variance/Lipschitz): Requires full ensemble → check last

**Performance:**
- Cache summary computations (Sₐ)
- Parallelize alignment ensemble
- Early exit on first witness failure
- Reuse bootstrap samples across witnesses where possible

**Debugging:**
- Log dimensional leverage λₐ to identify bottlenecks
- Track witness signals over time to detect drift
- Compare CI widths across axes to find measurement noise

---

## 10 · Policy Boundaries

**What Operational defines:**
- When to accept/reject (thresholds)
- What to validate (witnesses)
- What to record (provenance)

**What Operational does NOT define:**
- Which alignment algorithms (implementation choice)
- Summary construction details (domain-dependent)
- Exact threshold values (tunable parameters with provenance)

**Principle:** Operational is policy layer. Core is math. Implementation is solver.

---

**End — TSC Operational v3.0.0**