# Consciousness — a TSC (Triadic Self‑Coherence) exemplar

> **Status: non-normative illustration.** The observations, expected values, and historical scores below teach a framing only. They are not a TSC v4 conformance result, calibration anchor, or measurement verdict.


*Version:* examples v2.1.1 • aligns with **spec/tsc-core.md v2.0.0** and **spec/tsc-oper.md v2.0.0**

> **What this file is.** A **didactic, philosophy‑first** demonstration that treats a conscious event as one phenomenon ≡ articulated triadically as **H (pattern)**, **V (relation)**, **D (process)** and then asks a single question: *do these three articulations describe one coherent event?*\
> **What this file is not.** Not a theory that "explains consciousness," not a replacement for empirical science, not a commitment to internal representations. It is a **consistency check** across three inseparable dimensions of one event.

______________________________________________________________________

## 0) Coherence‑first stance (recognition, not assumption)

- **Given:** There is cohering (≡). Any event we care about already articulates as **H/V/D**.
- **Task:** Recognize that triadic articulation and **measure** whether the articulations **cohere** (no privileged dimension; full S₃ role symmetry).
- **Outcome:** A single score **C_Σ ∈ [0,1]** summarizing dimensional consistency, plus diagnostics showing where and why coherence is lost.

______________________________________________________________________

## 1) Phenomenon and articulation

**Phenomenon:** brief masked letter perception with report (toy paradigm). Each *trial* is a conscious event candidate.

- **H (pattern / cohered):** compact neural features per trial (stable pattern in measurement space).
- **V (relation / coherer):** phenomenal distinctions per trial (clarity, location, confidence) as *relational structure* among trials (similar/different).
- **D (process / cohering):** the task protocol as unfolding process (masking, SOA, prompt, report), including dispositions to act (button press, reaction time).

> **S₃ note.** We pick this articulation for pedagogy. Any **permutation of {H,V,D}** is an *equally valid* articulation of the same event; **C_Σ** must be invariant to relabeling (§4).

______________________________________________________________________

## 2) TSC block (YAML) — toy observations, ensemble, expectations

```yaml
tsc:
  version: "2.1.1"
  phenomenon: "Masked letter perception with report (toy)"
  identity: "consciousness/toy/masked-letter-v1"
  
  window:
    N: 12
  
  state: OPTIMIZE
  
  articulation:
    H:
      description: "Neural-pattern summary per trial (unitless, normalized)"
      features: ["feat1", "feat2", "feat3"]
      metric: "cosine"
    V:
      description: "Phenomenal distinctions per trial (reportable structure)"
      features: ["clarity", "locationL", "confidence"]
      metric: "euclidean"
    D:
      description: "Process features per trial (protocol & dispositions)"
      features: ["mask", "soa_ms", "rt_ms", "reported"]
      metric: "scaled-euclidean"
  
  observations:
    O_H:
      - {id: t01, feat1: 0.78, feat2: 0.64, feat3: 0.70}
      - {id: t02, feat1: 0.12, feat2: 0.18, feat3: 0.20}
      - {id: t03, feat1: 0.81, feat2: 0.66, feat3: 0.73}
      - {id: t04, feat1: 0.32, feat2: 0.28, feat3: 0.30}
      - {id: t05, feat1: 0.75, feat2: 0.61, feat3: 0.68}
      - {id: t06, feat1: 0.15, feat2: 0.22, feat3: 0.21}
      - {id: t07, feat1: 0.70, feat2: 0.58, feat3: 0.63}
      - {id: t08, feat1: 0.18, feat2: 0.20, feat3: 0.19}
      - {id: t09, feat1: 0.73, feat2: 0.59, feat3: 0.66}
      - {id: t10, feat1: 0.28, feat2: 0.25, feat3: 0.27}
      - {id: t11, feat1: 0.69, feat2: 0.55, feat3: 0.61}
      - {id: t12, feat1: 0.24, feat2: 0.23, feat3: 0.25}
    O_V:
      - {id: t01, clarity: 0.84, locationL: 0.0, confidence: 0.82}
      - {id: t02, clarity: 0.18, locationL: 0.0, confidence: 0.22}
      - {id: t03, clarity: 0.86, locationL: 0.0, confidence: 0.85}
      - {id: t04, clarity: 0.32, locationL: 0.0, confidence: 0.35}
      - {id: t05, clarity: 0.80, locationL: 0.0, confidence: 0.78}
      - {id: t06, clarity: 0.22, locationL: 0.0, confidence: 0.24}
      - {id: t07, clarity: 0.76, locationL: 0.0, confidence: 0.74}
      - {id: t08, clarity: 0.20, locationL: 0.0, confidence: 0.21}
      - {id: t09, clarity: 0.79, locationL: 0.0, confidence: 0.77}
      - {id: t10, clarity: 0.28, locationL: 0.0, confidence: 0.29}
      - {id: t11, clarity: 0.72, locationL: 0.0, confidence: 0.70}
      - {id: t12, clarity: 0.26, locationL: 0.0, confidence: 0.27}
    O_D:
      - {id: t01, mask: 0, soa_ms: 80,  rt_ms: 410, reported: 1}
      - {id: t02, mask: 1, soa_ms: 20,  rt_ms: 720, reported: 0}
      - {id: t03, mask: 0, soa_ms: 80,  rt_ms: 395, reported: 1}
      - {id: t04, mask: 1, soa_ms: 30,  rt_ms: 640, reported: 0}
      - {id: t05, mask: 0, soa_ms: 70,  rt_ms: 420, reported: 1}
      - {id: t06, mask: 1, soa_ms: 20,  rt_ms: 690, reported: 0}
      - {id: t07, mask: 0, soa_ms: 60,  rt_ms: 455, reported: 1}
      - {id: t08, mask: 1, soa_ms: 20,  rt_ms: 710, reported: 0}
      - {id: t09, mask: 0, soa_ms: 60,  rt_ms: 430, reported: 1}
      - {id: t10, mask: 1, soa_ms: 30,  rt_ms: 620, reported: 0}
      - {id: t11, mask: 0, soa_ms: 60,  rt_ms: 470, reported: 1}
      - {id: t12, mask: 1, soa_ms: 25,  rt_ms: 650, reported: 0}
  
  summaries:
    H: ["pairwise-distance-matrix", "stability-index"]
    V: ["pairwise-distance-matrix"]
    D: ["transition-coherence", "rt-distribution"]
  
  aligners:
    HV:
      family: "entropic-ot"
      epsilon: [0.01, 0.05, 0.10]
      costs: ["cosine", "euclidean"]
      seeds: [0, 1, 2]
    HD:
      family: "entropic-ot"
      epsilon: [0.05]
      costs: ["cosine"]
      seeds: [0, 1]
    VD:
      family: "entropic-ot"
      epsilon: [0.05]
      costs: ["euclidean"]
      seeds: [0, 1]
  
  floors:
    nu_min: 1.0e-3
    H_min: 0.10
    L_min: 1.0e-3
    nu_min_D: 1.0e-4
    H_min_D: 0.05
  
  cfg:
    Theta: 0.80
  
  illustrative_non_normative:
    H_c: 0.92
    V_c: 0.91
    D_c: 0.94
    C_sigma: 0.923
  
  ood:
    Z_t: 0.10
    Z_crit: 0.95
```


______________________________________________________________________

## 3) Negative control (break coherence)

Two ways to fail intentionally:

### 3.1 Shuffle phenomenal structure (V)

\`\`\`yaml
tsc_negative:
description: "Shuffle V across trials (destroys HV relational consistency)"
perturbation: "permute(O_V.id)"
expectation:
H_c: "~0.92" # unchanged (H stability is internal)
V_c: "~0.91" # unchanged individually
D_c: "~0.94" # unchanged individually
\# But cross-dimension consistency collapses; aggregate coherence drops
C_sigma: "≈ 0.35–0.45"
diagnostic_signature:
permutation_test: "FAIL (HV)"
ensemble_variance: "↑ (instability across aligners)"
\`\`\`

### 3.2 Flip report labels in D for high‑clarity trials

\`\`\`yaml
tsc_negative_2:
description: "Invert D.report for the 6 highest V.clarity trials"
expectation:
C_sigma: "≈ 0.40–0.55" # D contradicts HV; verdict should fail if Θ=0.80
diagnostic_signature:
conservation_check: "violated (disposition mis‑conserves V‑implied quantity)"
\`\`\`

> **Reading failures.** Low **C_Σ** means *either* incoherent articulation *or* ill‑posed measurement. Use witness swap, scale sweep, permutation, and ensemble ablation to separate these cases.

______________________________________________________________________

## 4) S₃‑equivalent framings (make symmetry visible)

**Identity (used above):** H=neural pattern, V=phenomenal structure, D=protocol/process.

**120° rotation:** H←V, V←D, D←H

- H: phenomenal distinctions as the *pattern we compare*,
- V: process relations (who‑follows‑whom in the trial dynamics) as *coherer*,
- D: neural updates as the *unfolding process*.
  **Claim:** **C_Σ** remains within the tolerance band (numerical differences only from change of metric families).

**240° rotation:** H←D, V←H, D←V

- H: protocol‑level regularities as pattern,
- V: neural constraints as coherer,
- D: phenomenal unfolding (clarity → confidence) as process.
  **Claim:** same verdict; different **diagnostic leverage** (which subscore dominates) depending on summaries/metrics.

> **Purpose of this section:** prevent reification of any one assignment as "the essence" of consciousness. Roles are **positional**, not essential; the phenomenon is the **triad**.

______________________________________________________________________

## 5) Paradigm crosswalk (orientation, not endorsement)

This exemplar is intentionally **minimal**. Here is how common paradigms can be *reframed* triadically without competition:

- **Global Neuronal Workspace (GNW):** "Ignition/broadcast" is a **D**‑level process; broadcast constraints are **V**‑like; the widespread pattern is **H**. TSC asks whether these articulations **cohere** for an event, not which is ontologically fundamental.
- **Integrated Information Theory (IIT):** structural/causal organization (Φ, cause–effect repertoires) is **V**‑like; candidate phenomenal distinctions are **V**; observed macro‑pattern **H**; system dynamics **D**. TSC treats these as three co‑dimensions of one event and tests S₃‑invariant **C_Σ** rather than privileging any single measure.
- **Predictive Processing (PP):** model constraints and precisions are **V**; prediction‑error fields and activations as **H**; inference/update flow as **D**. Again, TSC compares for **dimensional consistency**.

> **Manzotti‑compatible reading:** no inner "pictures." **H and V are co‑dimensions of D** (the happening), not maps between separate spaces. TSC compares **structures** across dimensions; it does not translate **contents**.

______________________________________________________________________

## 6) How to read the outcomes (philosophy → math → engineering)

- **Philosophy (stance):** There is one event articulated triadically.
- **Math (invariants):** S₃‑invariant aggregation, geometric mean **C_Σ**, degenerate‑guard (any 0 collapses C_Σ), refinement‑monotonicity.
- **Engineering (practice):** pick summaries and an alignment **ensemble** *before* observation; log ensemble variance; report **C_Σ** plus witness floors; run permutation/scale/ablation diagnostics.

______________________________________________________________________

## 7) Appendix — minimal CTB sketch (illustrative)

> **Note:** CTB (c≡) is a tiny notation that normalizes all syntax to **≡**. This snippet is illustrative; the formal CTB spec lives elsewhere.

\`\`\`ctb

# One triadic event with named articulations

E := ≡{ H: reportability_pattern
, V: phenomenal_structure
, D: protocol_process }

# Coherence predicate (Θ from thresholds)

coherent(E, Θ) := (CΣ(E.H, E.V, E.D) ≥ Θ)

# S₃ invariance law (schematic)

∀π ∈ S3. CΣ(E.H, E.V, E.D) = CΣ(E.π(H), E.π(V), E.π(D))
\`\`\`

______________________________________________________________________

## 8) FAQ (micro)

- **Is this reductionist or dualist?** Neither. It is **triadic** and **co‑inductive**: three inseparable dimensions of one phenomenon.
- **What if reports are unreliable?** Then **D** undermines coherence; diagnostics should flag instability and suggest better instrumentation.
- **Can C_Σ be high while one subscore is low?** The geometric mean penalizes imbalance; sustained low H_c/V_c/D_c lowers **C_Σ** and focuses investigation via **λ_X = −log X_c**.

______________________________________________________________________

## 9) Checklist (for maintainers)

- The **tsc** block uses only neutral names; no commitments to "inner images."
- **S₃ section** present with two non‑trivial permutations.
- **Negative controls** included and interpreted.
- **Crosswalk** frames, not competes; **Manzotti‑compatible** note explicit.
- Numbers are **illustrative**; update bands if reference implementation produces tighter estimates.

______________________________________________________________________

**Notes (source memory):** The reframing of consciousness as a **coherence question** across H/V/D and the emphasis that low alignment is a *measurement property* rather than a metaphysical chasm, plus the advice to increase measurement bandwidth to test the gap, were articulated earlier in our shared notes. The triadic, S₃‑invariant treatment and philosophy anchors were also part of that converged direction.

## Mechanical-proxy limitation

This illustration is also used by the current philosophical kata. The repository proxy may reward its regular structure even though the text supplies no v4 generator, candidate fiber, held-out oracle, or standing-bearing receipt. That mismatch is the lesson, not a positive measurement result.
