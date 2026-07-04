# TSC Operational v3.2.2

**Version:** 3.2.2\
**Status:** Normative\
**Foundation:** TSC Core v3.2.0\
**Changelog:** `CHANGELOG.md` § Spec releases

**Change from v3.2.0 (patch):** §7.4 added — canonicalizes the **cross-target aggregate** `C_Σ_cross` as the geometric mean of per-target C_Σ values for self-application across multiple target scopes (e.g. `spec`, `engine`, `repo`). Strictly additive; existing measurement and verdict logic unchanged.

**Change from v3.1.0:** Verdict logic reads C_Σ^num for threshold comparison and treats `zero_component_present = true` as a strict FAIL on the coherence threshold (since C_Σ^math = 0). Provenance bundle adds barrier-transform fields (δ, D, φ specification, clip parameter) and aggregate-form fields (C_Σ^math indicator, C_Σ^num value). See §5, §6.

______________________________________________________________________

## 0 · Scope

Core defines *what* to compute. Operational defines *when* to accept, *how* to validate, and *what* to record.

This document specifies:

- **Witnesses:** degeneracy guards
- **Floors:** acceptance thresholds
- **Controller:** verification state machine
- **Provenance:** required metadata
- **Self-Application:** TSC measuring itself

______________________________________________________________________

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

W2 has two complementary signals. Reporting only the best-permutation match (as pre-v3.2.0 specifications did) lets an implementation hide gauge dependence by selecting a favorable π; v3.2.0 requires both a reference match and a spread test.

**Signals:**

```
w_gauge_ref    = |C_Σ(labeled) − C_Σ(unlabeled, canonical-remap)|
w_gauge_spread = max_{π∈S₃} C_Σ(unlabeled remapped by π)
                 − min_{π∈S₃} C_Σ(unlabeled remapped by π)
```

The *canonical remap* is a deterministic, structure-derived axis assignment (e.g., lexicographic ordering of structural fingerprints) recorded in provenance.

**Pass conditions (both required):**

```
w_gauge_ref    ≤ τ_gauge
w_gauge_spread ≤ τ_gauge_spread     (default τ_gauge_spread = τ_gauge)
```

**Test:** Stripping role labels and applying the canonical remap matches the labeled measurement (`w_gauge_ref`); and no permutation of the unlabeled assignment shifts C_Σ beyond τ_gauge_spread (`w_gauge_spread`).

**Purpose:** Enforce that measurement procedure doesn't depend on which axis labels are used. The reference signal verifies label-blindness; the spread signal verifies *true* permutation insensitivity (no hiding behind a chosen π).

**Note:** W1 tests mathematical invariance (permute inputs to C_Σ); W2 tests computational invariance (implementation ignores labels). Both required.

### W3: Scale-Equivariance

**Signal:**

```
w_scale = |C_Σ(ψ(Oα), ψ(Oβ), ψ(Oγ)) - C_Σ(Oα, Oβ, Oγ)|
```

**Test:** Uniform scale transform ψ (e.g., all features × 2) preserves coherence. Note: ψ here denotes the W3 scale map, distinct from the barrier transform φ in Core §3.2.

**Purpose:** Enforce A3. Coherence is scale-free.

**Calibration:** If scale sensitivity detected, require 1-Lipschitz calibration map and record in provenance.

### W4: Variance/Lipschitz

**Variance signal:**

```
w_var = max{Varαβ, Varβγ, Varγα}
```

**Lipschitz signal:**

```
w_lip = κ = Lₛᵤₘ · Lₐₗᵢgₙ · max{L_link(λₐᵦ)}
```

where L_link is the link-Lipschitz constant for the barrier+exponential coherence map (Core §7.1). Implementations using a non-default barrier φ MUST recompute and record L_link.

**Test:**

- Variance: Ensemble agreement high (variance low)
- Lipschitz: Contraction margin satisfied (κ ≤ τ_lip; τ_lip < 1, so passing implies contraction)

**Purpose:** Detect unstable alignments (high variance) or non-contractive updates.

______________________________________________________________________

## 2 · Witness Floors

**Floor table:**

| Witness        | Symbol           | Default     | Units         |
| -------------- | ---------------- | ----------- | ------------- |
| S₃             | τ_S3             | 0.05        | absolute      |
| Gauge (ref)    | τ_gauge          | 0.05        | absolute      |
| Gauge (spread) | τ_gauge_spread   | τ_gauge     | absolute      |
| Scale          | τ_scale          | 0.10        | absolute      |
| Variance       | τ_var            | 0.15        | dimensionless |
| Lipschitz      | τ_lip            | 0.95        | dimensionless |

**Verdict:** Witness w passes if w ≤ τ_w.

**Parameter provenance:** If floors tuned from data, record selection procedure and freeze before final measurement.

______________________________________________________________________

## 3 · Sampling Policy

**Observation counts:**

- Minimum per axis: N_min = 30
- Bootstrap resamples: N_boot = 1000
- Alignment ensemble: |𝒜ₐᵦ| ≥ 3 per pair

**Temporal:**

- Process window: Δt (axis-dependent, recorded)
- OOD reference: rolling 20 verifications

**Block bootstrap:** If observations temporally/spatially correlated, use block size Δn ≥ 10.

______________________________________________________________________

## 4 · Controller States

Verification proceeds through states:

### HANDSHAKE

**Entry:** New verification request\
**Action:** Validate inputs (contexts, articulations, parameters)\
**Exit:** All inputs well-formed → MEASURE

### MEASURE

**Entry:** Inputs validated\
**Action:**

1. Articulate: Aₐ(T) → Oₐ for all a
1. Summarize: Oₐ → Sₐ
1. Align: Apply ensemble 𝒜ₐᵦ
1. Score: Compute s_α, s_β, s_γ, C_Σ
1. Bootstrap: Generate CI

**Exit:** Scores computed → WITNESS

### WITNESS

**Entry:** Scores computed\
**Action:** Evaluate all witnesses W1-W4\
**Exit:**

- All pass → VERDICT
- Any fail → DIAGNOSE

### DIAGNOSE

**Entry:** Witness failure\
**Action:**

1. Identify failing witness
1. Compute dimensional leverage λₐ
1. Log diagnostic

**Exit:** Report failure → TERMINAL

### VERDICT

**Entry:** All witnesses pass\
**Action:**

1. Check C_Σ ≥ Θ (acceptance threshold)
1. Check CI width < tolerance
1. Check OOD: Zₜ < Zcᵣᵢₜ

**Exit:**

- All pass → ACCEPT
- Any fail → REJECT

### ACCEPT / REJECT

**Terminal states**

**Accept:** C_Σ ≥ Θ with all witnesses passing\
**Reject:** C_Σ < Θ or witness failure or OOD

______________________________________________________________________

## 5 · Verdict Logic

**Pass conditions (all must hold):**

```
1. C_Σ^num ≥ Θ AND zero_component_present = false   (coherence threshold; strict math degeneracy fails this)
2. w_S3 ≤ τ_S3                                       (mathematical symmetry)
3a. w_gauge_ref    ≤ τ_gauge                         (label-blind reference match)
3b. w_gauge_spread ≤ τ_gauge_spread                  (permutation-insensitive)
4. w_scale ≤ τ_scale                                 (scale equivariance)
5. w_var ≤ τ_var                                     (ensemble stability)
6. w_lip ≤ τ_lip                                     (contraction with margin; w_lip uses L_link)
7. CIₕᵢ - CIₗₒ ≤ δ_CI                                (precision)
8. Zₜ < Zcᵣᵢₜ                                        (distribution stability)
```

**Notes on condition 1:**

- The numerical aggregate C_Σ^num (Core §5.2) is the comparison value; the ε-floor prevents `log(0)` in the weighted form.
- When `zero_component_present = true`, the mathematical aggregate C_Σ^math = 0 (Core §5.4), so condition 1 fails by definition irrespective of the C_Σ^num value the floor produces.
- This is **FAIL** (system genuinely lost a coherence dimension), not **FAIL_DEGENERATE** (which is reserved for measurement-process failures via witnesses).

**Fail-fast:** Exit on first failure for efficiency.

**Default thresholds:**

- Θ = 0.75 (coherence)
- δ_CI = 0.20 (CI width)
- Zcᵣᵢₜ = 2.5 (OOD, ~95% quantile)

______________________________________________________________________

### Compatibility Note (Notation Migration)

**Historical (window closed with v3.1):** for one minor release cycle
(through v3.1), implementations were permitted to emit both canonical
keys (`s_alpha`, `s_beta`, `s_gamma`) and legacy keys (`alpha_c`,
`beta_c`, `gamma_c`). That window is closed: implementations MUST emit
canonical keys only (the canonical engine never emitted legacy keys).
Consumers reading pre-v3.2 reports MAY still fall back to legacy keys
when canonical keys are absent.

## 6 · Provenance Bundle

**Required metadata:**

**Parameters:**

- θ (discrepancy weight)
- λ_α, λ_β, λ_γ (dimensional sensitivities)
- λₐᵦ (pairwise sensitivities)
- ε (numerical floor)
- Θ (acceptance threshold)
- All witness floors τ\_\* (including τ_gauge_spread)
- φ specification (default `delta_over_one_minus_delta`)
- η_φ (barrier clip, if applied)
- Canonical-remap procedure for W2 (deterministic axis assignment)

**Computation:**

- Alignment ensemble specs: types, parameters
- Summary schemas: (d, p, ℋ, ℐ) construction
- Bootstrap: seed, N_boot, block size Δn
- CI level (default 95%)

**Results:**

- s_α, s_β, s_γ
- C_Σ^num (numerical aggregate, used for verdict and CI)
- `numeric_floor_applied`, `zero_component_present` (mathematical-aggregate flags)
- [CIₗₒ, CIₕᵢ] over C_Σ^num
- Per-pair δ values (normalized discrepancy)
- Per-pair D values (discrepancy energy)
- Per-pair L_link(λₐᵦ) values
- Coh̄αβ, Coh̄βγ, Coh̄γα
- Varαβ, Varβγ, Varγα
- λ_α, λ_β, λ_γ, λ_Σ
- All witness signals: w_S3, w_gauge_ref, w_gauge_spread, w_scale, w_var, w_lip
- OOD: Zₜ, reference window (note: reference window must be reset on barrier-transform cutover)

**Calibration:**

- Lₛᵤₘ, Lₐₗᵢgₙ (Lipschitz constants for summary and summary→δ alignment, over bounded δ space)
- L_link(λₐᵦ) per pair (link-Lipschitz from barrier+exponential, Core §7.1)
- κ (contraction scalar; uses L_link, not bare λₐᵦ)
- Scale calibration maps (if any)
- Ground metrics for W₁ distances

**Verdict:**

- State sequence: HANDSHAKE → MEASURE → ...
- Pass/fail per witness
- Final verdict: ACCEPT/REJECT
- Timestamp, version

**Format:** JSON or equivalent structured format. Must be machine-readable.

**Canonical v3.2.0 JSON additions (minimal set).** These fields MUST appear in the provenance bundle alongside the v3.1.0 fields. They make the discrepancy → energy → coherence chain typed and provenance-visible:

```json
{
  "discrepancy_symbol": "delta",
  "discrepancy_range": "[0,1]",
  "coherence_link": "barrier_exponential",
  "barrier_phi": "delta/(1-delta)",
  "barrier_clip_eta_phi": null,
  "endpoint_policy": "delta=1 -> D=infinity -> Coh=0",
  "energy_variable": "D_ab",
  "link_lipschitz_constants": {
    "alpha_beta": null,
    "beta_gamma": null,
    "gamma_alpha": null
  },
  "aggregate_math": {
    "C_sigma_math": null,
    "zero_component_present": false
  },
  "aggregate_numeric": {
    "C_sigma_num": null,
    "epsilon": null,
    "numeric_floor_applied": false
  },
  "gauge_witness": {
    "w_gauge_ref": null,
    "w_gauge_spread": null,
    "tau_gauge_spread": null,
    "canonical_remap_procedure": null
  }
}
```

This composes with the existing Observation Dynamics provenance (typed calibration bases, grounding records, grounding witness, no-ungrounded-inflation): the barrier link is the typed transformation step the chain previously lacked.

______________________________________________________________________

## 7 · Self-Application Protocol

TSC measures itself by treating the TSC specification corpus as phenomenon P.

### 7.1 Corpus

**Documents:**

- C≡ foundation (spec/c-equiv.md)
- TSC Core (spec/tsc-core.md)
- TSC Operational (spec/tsc-oper.md)
- Observation Dynamics (spec/tsc-observation-dynamics.md)
- Glossary (spec/tsc-glossary.md)

**Articulation:**

- α: Pattern analysis (structure, sections, definitions)
- β: Cross-references (citations, dependencies)
- γ: Version evolution (commits, diffs, temporal)

### 7.2 Measurement

**Protocol:**

1. Extract terms: Parse markdown → tri(·,·,·) structure
1. Articulate: Aₐ(corpus) → Oₐ
1. Apply Core: Compute C_Σ(TSC)
1. Apply Operational: Run all witnesses

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

Θ is the self-application acceptance gate. Reader-facing documents additionally quote a rough `C_Σ^num ≥ 0.80` "holds together" band; that band is a stricter descriptive quality bar, not the verdict gate — a measurement can clear Θ while sitting below the band.

**Reporting:** Frozen self-coherence snapshots are published under `docs/alpha/doctrine/{version}/SELF-COHERENCE.md`; current measurements are generated into `.tsc/self/` by the self-measurement surface (`coh self`).

### 7.4 Cross-Target Aggregate

Self-application of TSC routinely measures more than one target scope (e.g. `spec`, `engine`, `repo`). Each target is measured independently per §7.1–§7.3 and yields a per-target coherence aggregate `C_Σ_i` (numerical form, Core §5.2). The **cross-target aggregate** is the geometric mean of these per-target values:

```
C_Σ_cross = (∏_{i=1}^{n} C_Σ_i)^(1/n)
```

where `i` ranges over the `n` targets in scope. This rule's consumer is the multi-target self-application surface (in the canonical engine: the cross-target report emitted when two or more targets are measured in one run).

**Properties:**

- **Same shape as per-target aggregate.** The per-target `C_Σ` is itself a geometric mean over `s_α, s_β, s_γ` (Core §5.2); the cross-target form generalizes that construction to the target axis. No new operator is introduced.
- **Worst-component dominance.** A single low-scoring target pulls `C_Σ_cross` down disproportionately, matching the `min`-leaning behavior of the per-target aggregate over its components.
- **Strict zero on math-degeneracy.** If any target reports `zero_component_present = true` (so its `C_Σ_i^math = 0`, Core §5.4), then `C_Σ_cross^math = 0`. The math/num split (Core §5.2, §5.4) propagates: a `C_Σ_cross^num` value computed from numerically floored per-target `C_Σ_i^num` values is reported separately and is not a substitute for the math-zero outcome.
- **Verdict logic does not change.** §5 conditions apply per target; the cross-target aggregate is a reporting quantity, not a new threshold gate.

**Provenance:** When `C_Σ_cross` is published, the provenance bundle for the cross-target report MUST list the constituent targets (target id and scope) and their per-target `C_Σ_i^num` (and `C_Σ_i^math` flag where relevant) so the geometric mean is reproducible.

**Self-application example.** A v3.2.x self-coherence run (Core-foundation series) that scores `spec`, `engine`, and `repo` targets reports three per-target `C_Σ_i` values and one `C_Σ_cross = (C_Σ_spec · C_Σ_engine · C_Σ_repo)^(1/3)` in the cross-target summary.

______________________________________________________________________

## 8 · Release Criteria

**Version release requires:**

1. **Self-coherence:** C_Σ(TSC) ≥ Θ with all witnesses passing
1. **Dimensional floors:** Each s_α, s_β, s_γ ≥ 0.60 (no degenerate dimensions)
1. **CI precision:** CI width ≤ 0.20
1. **OOD stability:** Zₜ < Zcᵣᵢₜ for last 5 measurements
1. **Provenance complete:** All parameters, witnesses, calibrations recorded
1. **Witness pass rate:** Each witness ≥ 95% pass rate across corpus

**Release artifacts:**

- Updated spec files
- Self-coherence report (docs/self-coherence-v3.0.1.md)
- Provenance bundle (coherence_report.json)
- Implementation reference (if updated)

**Version increment:**

- Major (3.x → 4.x): Foundation change (C≡ version)
- Minor (3.0 → 3.1): Measurement protocol change
- Patch (3.0.0 → 3.0.1): Witness floor adjustment

______________________________________________________________________

## 9 · Implementation Guidance

**Witness evaluation order:**

1. W1 (S₃): Fast, fails often → check first
1. W2 (Gauge): Fast, rarely fails
1. W3 (Scale): Moderate cost
1. W4 (Variance/Lipschitz): Requires full ensemble → check last

**Performance:**

- Cache summary computations (Sₐ)
- Parallelize alignment ensemble
- Early exit on first witness failure
- Reuse bootstrap samples across witnesses where possible

**Debugging:**

- Log dimensional leverage λₐ to identify bottlenecks
- Track witness signals over time to detect drift
- Compare CI widths across axes to find measurement noise

______________________________________________________________________

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

______________________________________________________________________

**End — TSC Operational v3.2.2**
