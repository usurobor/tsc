# Free Will (Toy: Two-Stage Reasons-Responsive Agent)

> **Status: non-normative illustration.** The observations, expected values, and historical scores below teach a framing only. They are not a TSC v4 conformance result, calibration anchor, or measurement verdict.


**Phenomenon:** Choices that are **reasons-responsive** yet not strictly deterministic, via a two-stage model: (1) generate candidates with noise; (2) select by reasons.

**Scope:** Minimal table with contexts and reason scores for two actions (A, B). **H** captures reasons-responsiveness and replay-stability; **V** constrains how noise interacts with reasons; **D** specifies the decision procedure.

______________________________________________________________________

## TSC Specification

```yaml
tsc:
  version: 1
  id: philosophical/free-will/two-stage-reasons
  title: "Two-stage reasons-responsive choice"
  tags: [agency, free-will, compatibilism, toy]
  
  roles:
    H: "Reasons-responsiveness pattern (observables)"
    V: "Noise×Reasons interaction (constraints)"
    D: "Two-stage procedure (generator)"
  
  assumptions:
    - Reasons scores are normalized utilities in [0,1].
    - Micro-noise ε ~ N(0, σ=0.02) applied only at selection stage.
  
  s3_equivalences:
    - perm: [H,V,D]
      rationale: "Default: choice pattern / interaction law / two-stage procedure"
    - perm: [V,D,H]
      rationale: "Highlights interaction structure as primary observable"
    - perm: [D,H,V]
      rationale: "Highlights procedure as generating the interaction"
  
  witnesses:
    H:
      claims:
        - id: h1
          statement: "Agent usually picks the higher-scoring option."
          test: "Accuracy(chosen == argmax{A,B}) >= 0.85"
        - id: h2
          statement: "Thin re-run preserves choices when reasons-gap is large."
          test: "For |A-B| >= 0.20, P(replay==choice) >= 0.95"
    
    V:
      constraints:
        - id: v1
          statement: "Probability of choosing A increases with (A-B)."
          test: "Logit(A-B)->P(A), slope>0, AUC>=0.85"
        - id: v2
          statement: "Flips (replay≠choice) occur only when |A-B| ≤ 0.05."
          test: "max_gap_among_flips <= 0.05"
    
    D:
      procedure:
        - "Stage 1 (Generate): form candidate set {A,B}. (In richer tasks: sample K ideas; here fixed.)"
        - "Stage 2 (Select): choose argmax(score + ε)."
        - "Thin re-run: resample ε; keep reasons fixed; recompute choice."
  
  datasets:
    - name: contexts
      type: table
      header: [ctx, A, B, choice, replay]
      rows:
        - [c1, 0.90, 0.20, A, A]
        - [c2, 0.30, 0.80, B, B]
        - [c3, 0.60, 0.50, A, A]
        - [c4, 0.51, 0.49, A, B]  # close call ⇒ allowed flip
        - [c5, 0.20, 0.90, B, B]
        - [c6, 0.70, 0.10, A, A]
        - [c7, 0.55, 0.40, A, A]
        - [c8, 0.40, 0.60, B, B]
  
  illustrative_non_normative:
    c_sigma: 0.76
    tolerance: 0.07
    rationale: "Strong reasons-responsiveness with small, principled replay flips near ties."
  
  unit_tests:
    - name: "S3-invariance"
      fn: "permute_and_compare"
      args:
        perms: [[H,V,D],[V,D,H],[D,H,V]]
        tol: 1e-6
      expect: "max_delta_CΣ <= tol"
```

______________________________________________________________________

## Alternative Framings (S₃-Equivalent)

**Gauge choice.** In this example we *choose*:

- **H**: Reasons-responsiveness in choices (observable policy)
- **V**: Noise×Reasons interaction (how indeterminism relates to deliberation)
- **D**: Two-stage generate-then-filter procedure

This is a **pedagogical gauge**, not an essence claim. Any permutation of ⟨H,V,D⟩ is admissible. For example:

- **(H,V,D) → (V,D,H)**: Now H = interaction signature (e.g., slope of choice odds vs. reasons under variance regimes); V = two-stage constraint (stage-1 must be noisy, stage-2 must respect reasons); D = reasons-responsiveness curve as generator (used to simulate contexts).

- **(H,V,D) → (D,H,V)**: Now H = protocol traces across contexts (what stages were executed); V = reasons↔choice elasticity (lawlike linking); D = interaction model (stochastic choice function generating outcomes).

**Invariant.** By design, **C_Σ is permutation-invariant**: relabeling roles does not change coherence, up to numerical tolerance.

______________________________________________________________________

## Paradigm Crosswalk

### Compatibilist Guidance Control (Fischer & Ravizza)

Put "guidance/mesh to reasons" into **V** (the constraint that choices track reasons appropriately); **H** is the observed policy across contexts; **D** is the deliberative procedure (how the agent generates and selects).

TSC reframes guidance control not as a *definition* of free will, but as a **dimensional consistency claim**: does the agent's process (D) produce patterns (H) that satisfy the guidance constraint (V)? Low C_Σ indicates poor mesh; high C_Σ indicates coherent reasons-responsiveness.

### Dennett Two-Stage Model

Stage-1 variation sits in **D** (generator of candidate considerations); selection pressure (valuation, deliberation) sits in **V** (constraint determining which candidates survive); **H** is the realized profile of choices across contexts.

TSC doesn't adjudicate "true free will" — it measures whether the two-stage structure articulates coherently as a triad.

______________________________________________________________________

## Adapter Table: Toy → Real Decision Tasks

| Toy field        | Real-task analogue                                        |
| ---------------- | --------------------------------------------------------- |
| `A, B` (options) | Gambles, actions, career choices with utilities/values    |
| `choice`         | Observed decision (behavioral data)                       |
| `replay`         | Counterfactual choice under same reasons, resampled noise |
| `stage_1`        | Brainstorm, candidate generation, spontaneous ideation    |
| `stage_2`        | Deliberation, evaluation, selection by valuation          |

______________________________________________________________________

## What Would Break This?

**Break H (reasons-responsiveness):**

- Force stage-2 to ignore reasons scores (choose randomly or anti-reason)
- **Expected**: h1 fails (accuracy drops to ~50%), C_Σ < 0.4

**Break V (noise-reasons interaction):**

- Make stage-1 variance overwhelm reasons (σ >> 1)
- Or remove noise entirely (deterministic selection)
- **Expected**: v1 fails (no smooth logit curve), or v2 fails (flips everywhere), C_Σ drops

**Break D (procedure):**

- Invert the reasons signal (anti-guidance)
- Scramble stage order
- **Expected**: All dimensions collapse, C_Σ → 0.2

______________________________________________________________________

## Notes for Implementers

**Expected C_Σ:** This example has inherent stochasticity (noise in stage-2), so expect C_Σ ≈ 0.70-0.80 rather than 0.95+. The tolerance band accounts for principled indeterminism.

**Replay flips:** Context c4 shows a flip (A→B on replay). This is **not a failure** — it's expected when |A-B| ≈ 0.02 and noise σ = 0.02. The constraint v2 verifies that flips only occur in these edge cases.

**Dimensional leverage:** If C_Σ is lower than expected, check λ_V first (noise-reasons interaction is hardest to capture with sparse contexts).

______________________________________________________________________

## License

CC BY 4.0 (example content)
