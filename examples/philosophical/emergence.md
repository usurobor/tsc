# Emergence (Toy: Boids → Global Alignment)

**Phenomenon:** Global flock polarization emerging from local heading alignment.

**Scope:** Aggregate summary over 10 steps; no full simulation here. **H** states the macroscopic pattern, **V** ties local alignment to global order, **D** gives a minimal Boids-like update rule.

______________________________________________________________________

## TSC Specification

```yaml
tsc:
  version: 1
  id: philosophical/emergence/boids-alignment
  title: "Local alignment → global polarization"
  tags: [emergence, complexity, toy]
  
  roles:
    H: "Macro flocking metrics (observable patterns)"
    V: "Micro→Macro correlations (constraint structure)"
    D: "Local update rules (generator)"
  
  assumptions:
    - Fixed agent count; periodic boundary conditions.
    - Order parameters normalized to [0,1].
  
  s3_equivalences:
    - perm: [H,V,D]
      rationale: "Default: macro observables / micro-macro law / update dynamics"
    - perm: [V,D,H]
      rationale: "Highlights correlation structure as primary pattern"
    - perm: [D,H,V]
      rationale: "Highlights update rules as observable traces"
  
  witnesses:
    H:
      claims:
        - id: h1
          statement: "Polarization exceeds 0.80 by t≥7 and stays high."
          test: "min(Pol[t>=7]) >= 0.80"
        - id: h2
          statement: "Cluster count drops to 1 by t≥7."
          test: "min(Clusters[t>=7]) = 1"
    
    V:
      constraints:
        - id: v1
          statement: "Local alignment predicts polarization with short lag."
          test: "CrossCorr(Align, Pol, lag∈{0,1}) >= 0.80"
        - id: v2
          statement: "As alignment rises, cluster count weakly decreases."
          test: "Spearman(Align, -Clusters) >= 0.70"
    
    D:
      steps:
        - "Each step: steer to average neighbor heading (radius r), add mild cohesion & separation."
        - "Compute Align = fraction with neighbor-angle ≤ 15°."
        - "Compute Pol = |mean unit velocity|."
        - "Compute Clusters via single-linkage with threshold d."
      controls:
        negative: "Randomize headings each step → alignment stays low, Pol≈0.2, Clusters>3."
  
  datasets:
    - name: summary_over_time
      type: table
      header: [t, Align, Pol, Clusters]
      rows:
        - [0, 0.20, 0.15, 5]
        - [1, 0.30, 0.25, 4]
        - [2, 0.45, 0.40, 3]
        - [3, 0.60, 0.55, 3]
        - [4, 0.72, 0.66, 2]
        - [5, 0.80, 0.72, 2]
        - [6, 0.86, 0.78, 2]
        - [7, 0.89, 0.81, 1]
        - [8, 0.91, 0.84, 1]
        - [9, 0.93, 0.86, 1]
  
  expected:
    c_sigma_num: 0.88
    tolerance: 0.05
    rationale: "Clear macro pattern driven by micro rules; minor slack from finite-size noise."
  
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

- **H**: Macro flocking metrics (polarization, cluster count) — what emerges
- **V**: Micro→Macro correlation structure — how local relates to global
- **D**: Local update rules — how agents behave

This is a **pedagogical gauge**, not an essence claim. Any permutation of ⟨H,V,D⟩ is admissible. For example:

- **(H,V,D) → (V,D,H)**: Now H = constraint signatures (e.g., correlation length vs. density); V = update-rule↔macro map (how rules produce specific order parameters); D = macro metric as generator (used to simulate micro revisions).

- **(H,V,D) → (D,H,V)**: Now H = rule traces (neighborhood statistics over time); V = macro law (order parameter dynamics, conservation); D = macro pattern model (mean-field approximation generating trajectories).

**Invariant.** By design, **C_Σ is permutation-invariant**: relabeling roles does not change coherence, up to numerical tolerance. The choice of frame is positional, not ontological.

______________________________________________________________________

## Paradigm Crosswalk

### Statistical Mechanics / Critical Phenomena

TSC reframes "emergence" not as macro "popping out" from micro, but as **dimensional consistency across scales**. In phase transitions:

- **H** = order parameter trajectory (magnetization, polarization)
- **V** = fluctuation-dissipation relations, scaling laws
- **D** = quench/drive protocol, microscopic dynamics

Low C_Σ signals that the articulation is **scale-inconsistent** (e.g., wrong order parameter for the dynamics). High C_Σ confirms the triad captures genuine multi-scale coherence.

### Complex Systems

Boids, Ising models, cellular automata all share the structure: local rules (D) produce macro patterns (H) via statistical constraints (V). TSC doesn't claim "emergence is illusory" — it claims emergence is **dimensional articulation across scales**, measurable via triadic consistency.

______________________________________________________________________

## Adapter Table: Toy → Real Systems

| Toy field       | Real-system analogue                                        |
| --------------- | ----------------------------------------------------------- |
| `Align` (local) | Neighbor correlation, spin alignment, local order parameter |
| `Pol` (macro)   | Magnetization, flock velocity, global order parameter       |
| `Clusters`      | Domain count, percolation clusters, topological defects     |
| `update_rule`   | Hamiltonian, Vicsek dynamics, Ising/Potts rules             |

______________________________________________________________________

## What Would Break This?

**Break V (micro-macro correlation):**

- Reduce neighbor radius to zero (no alignment mechanism)
- Inject strong per-step noise that swamps correlation
- **Expected**: v1 fails (Align no longer predicts Pol), C_Σ drops

**Break D (dynamics):**

- Replace update rule with random walk
- Remove cohesion/separation forces
- **Expected**: Macro pattern collapses, h1/h2 fail, C_Σ < 0.4

**Break H (macro pattern):**

- Force agents into fixed clusters (no dynamics)
- **Expected**: Time evolution ceases, D becomes trivial, C_Σ drops

______________________________________________________________________

## Notes for Implementers

**Finite-size effects:** With O(10²) agents, expect C_Σ ≈ 0.85-0.90. With O(10⁴) agents and longer runs, expect C_Σ → 0.95+ as fluctuations decrease.

**Scale invariance:** Running the same analysis at different time windows or spatial coarse-grainings should preserve C_Σ within tolerance (scale-equivariance axiom).

______________________________________________________________________

## License

CC BY 4.0 (example content)
