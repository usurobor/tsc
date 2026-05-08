# RELEASE.md

**Release:** TSC Spec v3.2.0 — Barrier-Coherence Patch
**Type:** Spec release (independent lineage from engine 0.x.x)
**Branch:** `claude/barrier-transform-coherence-XT6gF`

## Outcome

Coherence delta: C_Σ A- (`α A`, `β A`, `γ A-`) · **Level:** `L7`

The discrepancy → coherence link is now mathematically clean. A bounded normalized discrepancy δ ∈ [0,1] is mapped through a monotone barrier φ to an unbounded discrepancy energy D ∈ [0,∞], and Coh = exp(−D) reaches a strict zero at δ = 1 — without giving up the bounded observations the rest of the framework depends on. Sensitivity λ is no longer doing double duty as an ontological floor. The aggregate is split into a mathematical form C_Σ^math (carrying the Degeneracy Axiom for proofs) and a numerical form C_Σ^num (used for bootstrap, OOD, and verdict comparison) — they coincide whenever min sᵢ ≥ ε, and provenance flags the cases when they would diverge.

## Why it matters

v3.1.0 carried three latent contradictions in the same surface:

1. **P2 was unreachable.** Core §9 P2 promised "Δ → ∞ ⟹ C_Σ → 0", but Core §3.1 normalized Δ to [0,1]. The strict zero was an asymptote nothing in the system could reach. Coh had a floor of `exp(−λ)` whether the spec admitted it or not.
2. **λ was semantically overloaded.** Because Δ was bounded, λ acted simultaneously as a sensitivity-curve parameter (how fast coherence decays) and as an artificial ontological floor (the achievable minimum). This entangled two concerns that belong on different layers.
3. **The Degeneracy Axiom was only honest at the math level.** C≡ §5.4 requires `s_i = 0 ⟹ C_Σ = 0`. Operational implementation needed an ε-floor to prevent `log(0) = −∞`. The spec mixed both into one formula and asked the reader to tolerate the contradiction.

Three structural problems, one structural fix: introduce a typed transformation chain — `δ → φ(δ) → D → Coh` — and split the aggregate cleanly into a normative mathematical object and a computational numerical object that agree on the non-pathological regime and differ only where provenance can record the difference. This is what makes v3.2.0 an L7 change rather than an L6 patch: future spec work no longer has to navigate the bounded/unbounded contradiction every time it touches §3 or §5.

## Changed

### TSC Core v3.1.0 → v3.2.0

- **§1 Objects:** Parameter list now declares δ, D, φ; `Δ(Sₐ, Sᵦ; σ)` cost replaced with normalized discrepancy δ and discrepancy energy D.
- **§3.1 Normalized Discrepancy:** Renamed from "Discrepancy"; Δ → δ throughout. Bounded δ ∈ [0,1] motivated explicitly (W3 scale-equivariance, ensemble comparability, observation-dynamics ledgers).
- **§3.2 Coherence Function (Barrier Transform):** New formulation. φ: [0,1] → [0,∞] with canonical default `φ(δ) = δ/(1−δ)`, `φ(1) = ∞`. D := λₐᵦ · φ(δ). Coh := exp(−D), with `exp(−∞) = 0` convention. Endpoint policy explicit: `δ = 0 ⟹ Coh = 1`; `δ → 1⁻ ⟹ Coh → 0` (limit); `δ = 1 ⟹ Coh = 0` (strict equality). λₐᵦ stated as pure sensitivity. Energy-space numerical guidance with η_φ clip parameter.
- **§5 Aggregate Coherence:** Split into 5.1 mathematical (C_Σ^math = (sα·sβ·sγ)^(1/3)) / 5.2 numerical (C_Σ^num via ε-floored log-mean) / 5.3 equivalence regime / 5.4 properties / 5.5 provenance flags (`numeric_floor_applied`, `zero_component_present`).
- **§7.1 Contraction:** κ now uses `max{L_link(λₐᵦ)}` instead of `max{λₐᵦ}`. L_link derived in closed form: `L_link(λ) = (4/λ)·exp(λ−2)` for `0 < λ ≤ 2` (attained at δ\* = 1 − λ/2), and `L_link(λ) = λ` for `λ ≥ 2`. Continuous at λ = 2. Pre-v3.2.0 specs underestimated the link envelope when λ < 2.
- **§9 P2 Normalization:** Reformulated against δ → 1 / D → ∞.
- **§9 P5 Lipschitz:** Scoped — C_Σ^num Lipschitz on the nondegenerate domain (sᵢ ≥ ε); C_Σ^math preserves the strict-zero endpoint without a global Lipschitz claim (geometric mean has unbounded derivative at 0).
- **§12 Implementation Notes:** Energy-space computation guidance, η_φ clip recommendation, OOD reference distribution reset on cutover, W4 framing (L_align is over summary→δ).

### TSC Operational v3.1.0 → v3.2.0

- **§1 W2 Role-Gauge split.** Pre-v3.2.0 W2 took `max_{π∈S₃}` of the unlabeled C_Σ — that lets an implementation hide gauge dependence by selecting a favorable permutation. v3.2.0 requires both `w_gauge_ref = |C_Σ(labeled) − C_Σ(canonical-remap)|` and `w_gauge_spread = max_π C_Σ − min_π C_Σ` to pass. Default `τ_gauge_spread = τ_gauge`. Canonical remap procedure recorded in provenance.
- **§1 W3 scale transform renamed φ → ψ** to remove name collision with the Core barrier transform.
- **§1 W4 Lipschitz signal:** κ formula updated to use `max{L_link(λₐᵦ)}`.
- **§2 Floor table:** Adds `τ_gauge_spread` row.
- **§5 Verdict logic:** Condition 1 reads `C_Σ^num ≥ Θ AND zero_component_present = false`. W2 row split into 3a (ref) and 3b (spread). Strict-math degeneracy is FAIL on threshold (not FAIL_DEGENERATE — measurement isn't broken; the system genuinely lost a leg of the stool).
- **§6 Provenance bundle:** Canonical v3.2.0 JSON skeleton added (`discrepancy_symbol`, `coherence_link`, `barrier_phi`, `endpoint_policy`, `link_lipschitz_constants` per pair, `aggregate_math` with `zero_component_present`, `aggregate_numeric` with `numeric_floor_applied`/`epsilon`, `gauge_witness` ref + spread + canonical_remap_procedure). Composes with Observation Dynamics typed-calibration provenance.

### TSC Glossary v3.1.0 → v3.2.0

- *Alignment* section rewritten to introduce the barrier transform with the duality / unity-collapse intuition (bounded δ carries the discernible mismatch; D → ∞ carries the unity-carrier collapse).
- *Aggregate Coherence* explains the math/num bifurcation in plain language.
- *W2 Gauge Independence* mirrors the ref + spread split.
- *W4 Lipschitz test* explains L_link with the case-split formula.
- *W3 Scale Equivariance* renames φ → ψ to track the Operational rename.
- Quick Reference table adds `φ`, `η_φ`, `τ_gauge_spread`.

### TSC Observation Dynamics v1.0.13

- Normative dependencies uplifted to TSC Core v3.2.0 / TSC Operational v3.2.0. Forward-compatibility note added: the barrier link is now the typed discrepancy → energy step the calibration-grounding ledgers always required.

## Added

- **Barrier transform `φ`** (Core §3.2) — canonical default `δ/(1−δ)`; alternates allowed if monotone with the limit conditions and recorded in provenance.
- **Discrepancy energy `D`** (Core §3.2) — typed intermediate carrying the unbounded incoherence.
- **Mathematical aggregate `C_Σ^math`** (Core §5.1) — strict-degeneracy form for proofs.
- **Numerical aggregate `C_Σ^num`** (Core §5.2) — ε-floored form for computation.
- **Link-Lipschitz constant `L_link(λ)`** (Core §7.1) — closed form for the canonical barrier; required input for κ.
- **Gauge-spread witness `w_gauge_spread`** (Operational §1) — closes the best-π loophole in W2.
- **Provenance JSON v3.2.0 skeleton** (Operational §6) — typed transformation chain visible from observation through verdict.

## Removed

- Pre-v3.2.0 contradiction in P2: "Δ → ∞" claim against bounded Δ ∈ [0,1].
- Conflated semantics of λ as both sensitivity and floor.
- Implicit conflation of mathematical and numerical aggregates in §5.
- W2 best-π loophole.
- Underspecified link-Lipschitz envelope (`max{λₐᵦ}` was a lower bound on the true `max{L_link(λₐᵦ)}` when λ < 2).

## Validation

- **L_link derivation reproduced.** For f_λ(δ) = exp(−λ·δ/(1−δ)), `|f_λ'(δ)| = λ/(1−δ)² · exp(−λ·δ/(1−δ))`. Setting d/dδ ln|f_λ'| = 0 gives δ\* = 1 − λ/2, valid in [0,1) only for λ ≤ 2. At δ\*: |f_λ'(δ\*)| = (4/λ)·exp(λ−2). For λ ≥ 2, |f_λ'| is monotone decreasing; max at δ = 0 gives λ. Continuous at λ = 2 (both branches give 2).
- **All Δ usages in spec audited.** Only `Δt` (time delta in §4.2 process score) and `Δn` (block bootstrap size) remain — both unrelated to discrepancy.
- **φ overload audited.** W3 scale transform renamed to ψ across Operational §1 and Glossary; barrier φ is the sole `φ` symbol in v3.2.0.
- **Math/num split traced through §5, §6 (CI), §9 (P2, P4, P5), §11 (leverage).** Internally consistent: bootstrap, OOD, verdict all read C_Σ^num; proofs read C_Σ^math; provenance flags handle the divergence regime.
- **Proves what it set out to prove.**
  - C≡ §5.4 Degeneracy Axiom: preserved by C_Σ^math, never erased by ε-floor (zero_component_present provenance).
  - Endpoint reachability: δ = 1 → D = ∞ → Coh = 0 strictly.
  - λ semantic: now a pure sensitivity scale; `Coh_min = 0` is independent of λ.
- **Cross-spec consistency.** ObsDyn dependency note bridges to the typed-calibration layer; no contradictions introduced with C≡ v3.1.0 (foundation untouched, §5.4 already states the strict-math degeneracy).

This release is theory work. There is no binary deployment to validate. Validation here is mathematical reproduction, audit of all referenced sections, and cross-spec consistency check.

## Known Issues

- **Engine implementation not yet updated.** `engine/ocaml/` still computes coherence under the v3.1.0 direct-exponential formulation. A follow-on engine release must implement `D = λ · φ(δ)`, `Coh = exp(−D)`, the `C_Σ^math` / `C_Σ^num` split, the W2 ref+spread split, and the v3.2.0 provenance schema.
- **OOD reference distributions must be reset** on the barrier-transform cutover. Historical C_Σ values from the v3.1.0 formula are not directly comparable to v3.2.0 outputs. This is documented in Core §12 and the ObsDyn dependency note but is operator-driven, not yet automated.
- **No CI gate yet enforces v3.2.0 provenance schema.** `targets/registry.tsc` and the self-measurement workflow consume the older bundle. A schema validator and registry update are deferred to the engine release.
- **C≡ left at v3.1.0.** Foundation unchanged; its §5.4 already states the strict-math degeneracy axiom that C_Σ^math now carries forward. No diff was needed.
- **Self-coherence report not regenerated.** `docs/alpha/engine/0.3.0/SELF-COHERENCE.md` reflects pre-v3.2.0 measurement; the next post-release assessment should produce a v3.2.0 self-coherence report.

## Cycle Trace

- Initial proposal: `Path A'` Barrier-Transform with bifurcation of C_Σ^math / C_Σ^num.
- RC1 (commit `130dbb3`): introduced δ, φ, D, the math/num split, P2 reformulation, and provenance flags. Identified gradient-near-1 numerical concern.
- RC2 (commit `48f7894`): refinements after critical re-review — derived L_link in closed form and threaded it through κ in Core §7.1, Operational W4, and Glossary; scoped P5 Lipschitz to the nondegenerate domain; split W2 into ref + spread to close the best-π loophole; renamed W3's φ → ψ to remove the name collision; added the canonical v3.2.0 provenance JSON skeleton; uplifted ObsDyn dependency.
- 2 RC rounds, 2 commits, 4 files touched (`spec/tsc-core.md`, `spec/tsc-oper.md`, `spec/tsc-glossary.md`, `spec/tsc-observation-dynamics.md`), +302 / −94 net.
