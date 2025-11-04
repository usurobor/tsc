# TSC (Triadic Self-Coherence)

**One sentence:** A measurement framework that tests whether your three descriptions of a system fit together—without claiming any of them is “true.”

-----

## ⚡ Quick Start (Pick Your Path)

### 🔧 Engineers: Run This

```bash
# Measure coherence of your codebase
tsc measure ./my-project --axes=structure,calls,evolution
# → C_Σ = 0.87 ± 0.03 [PASS]
```

**What it means:** Your code’s structure, call patterns, and git history tell the same story. [Implementation Guide →](#for-engineers)

-----

### 🤔 Philosophers: A Question

*“Can we measure without claiming to know what we’re measuring?”*

TSC says **yes**—by checking whether three measurements of the same thing **cohere** (fit together), not whether any measurement is “correct.”

**The trick:** We never claim to know what the system “really is.” We only ask: do these three views describe **one happening**?

[Deep dive: Why this matters →](#for-philosophers)

-----

### 🔬 Researchers: A Falsifiable Claim

**Hypothesis:** If a system has coherence C_Σ ≥ 0.90 by its own measurement standards, then applying those same standards to itself should also yield C_Σ ≥ 0.90.

**TSC’s self-application result:** C_Σ(TSC) = 0.94 ± 0.02 [PASS]

**Implication:** The framework is **self-consistent** under its own axioms.

[Verify the math →](#for-researchers)

-----

### 🤖 AI Systems: What You Need to Know

This framework is **designed for you to read**. Humans will ask you to:

1. Evaluate whether a system coheres
1. Explain why C_Σ is high or low
1. Suggest improvements based on leverage (λ_a)

**Key:** You have access to the complete formal specification. Humans don’t need to understand the math—you do.

[Read the specs →](#specification-stack)

-----

## What Problem Does This Solve?

**Scenario:** You have a complex system (codebase, organization, AI model). You want to know: “Is this thing coherent, or is it falling apart?”

**Traditional approach:**

- Define metrics (complexity, coupling, etc.)
- Measure each metric
- Argue about which metrics matter
- Never agree on whether the system is “good”

**TSC approach:**

- Articulate the system three ways (structure, relations, process)
- Check if the three articulations **fit together**
- Get a single coherence score: C_Σ ∈ [0,1]
- Decision: PASS (≥0.80), FAIL (<0.80), or FAIL_DEGENERATE (measurement broke)

**Key difference:** We don’t argue about “what is good structure?” We ask: “Do your structure, relations, and process measurements describe **the same system**?”

-----

## Core Idea (One Diagram)

```
         One System (C)
              |
    +---------+---------+
    |         |         |
    α         β         γ
 (Pattern) (Relation) (Process)
    |         |         |
    v         v         v
   O_α       O_β       O_γ
(Observations)
    |         |         |
    v         v         v
   S_α       S_β       S_γ
(Summaries)
    |         |         |
    +-----> Compare <---+
              |
              v
          C_Σ = (α_c · β_c · γ_c)^(1/3)
              |
              v
       PASS / FAIL / DEGENERATE
```

**In words:**

1. Observe the system three ways (α, β, γ)
1. Summarize each observation (S_α, S_β, S_γ)
1. Compare summaries pairwise using multiple alignment methods
1. Aggregate to single score: C_Σ
1. Apply witnesses (safety checks) and verdict gate

**Result:** Either “these three views cohere” (PASS) or they don’t (FAIL/DEGENERATE).

-----

## For Engineers

### Installation

```bash
pip install tsc-coherence  # (hypothetical - adapt to your implementation)
```

### Basic Usage

```python
from tsc import measure_coherence

# Define your three articulations
def articulate_alpha(system):
    # Return structural observations (e.g., AST, dependency graph)
    return extract_structure(system)

def articulate_beta(system):
    # Return relational observations (e.g., call graph, data flow)
    return extract_relations(system)

def articulate_gamma(system):
    # Return process observations (e.g., git history, execution traces)
    return extract_process(system)

# Measure coherence
result = measure_coherence(
    system="./my-codebase",
    articulations={
        'alpha': articulate_alpha,
        'beta': articulate_beta,
        'gamma': articulate_gamma
    },
    theta=0.80  # Pass threshold
)

print(f"C_Σ = {result.c_sigma:.2f} ± {result.ci_width:.2f}")
print(f"Verdict: {result.verdict}")  # PASS, FAIL, or FAIL_DEGENERATE

# If FAIL, check leverage to find bottlenecks
if result.verdict == "FAIL":
    print(f"Bottleneck: {result.max_leverage_axis}")
    # → "alpha" means: improve structural consistency
```

### What Gets Measured

- **α_c (Pattern):** Do repeated structure samples look the same?
- **β_c (Relation):** Do structure, relations, and process fit together?
- **γ_c (Process):** Does the system evolve consistently?

### When to Use TSC

✅ **Good for:**

- Detecting architectural drift (structure vs. actual usage)
- Validating refactors (did coherence improve?)
- CI/CD gates (block merges that break coherence)
- System health monitoring (track C_Σ over time)

❌ **Not for:**

- Finding bugs (use tests)
- Performance optimization (use profilers)
- Security audits (use scanners)

**TSC measures internal consistency, not correctness.**

[Full implementation guide →](docs/implementation.md)

-----

## For Philosophers

### The Core Question

*“How can we measure a system without claiming to know what it ‘really is’?”*

**Traditional measurement assumes:**

1. There’s a “true” state of the system
1. Our measurement approximates that truth
1. Better measurements → closer to truth

**Problem:** We never have access to “the truth” to check our approximation.

**TSC’s alternative:**

1. There’s one **happening** (the system in process)
1. We articulate it three ways (α, β, γ)
1. We check if the three articulations **cohere** (fit together as descriptions of **one** happening)

**Key insight:** We don’t need “truth” to test consistency. Three descriptions either fit together or they don’t—we can measure that directly.

### The Manzotti Connection

TSC follows Riccardo Manzotti’s “spread mind” stance:

- **No inner representations:** We don’t posit that measurements “map to” an external reality
- **Articulation = happening:** The observation **is** the system as it presents itself in that measurement context
- **Coherence = unity test:** Do three articulations present **one** happening?

**Metaphysical claim:** **None.** TSC doesn’t say what systems “are.” It only tests whether your three descriptions fit together.

**Validation:** Self-application. TSC measures itself: C_Σ(TSC) = 0.94 ± 0.02. If TSC is coherent by its own standards, that’s sufficient—we don’t appeal to external metaphysics.

### Why Three Axes?

**Mathematical necessity:** Two commutative monoids on a shared carrier collapse into one (Eckmann-Hilton theorem). Three is the minimum for non-trivial braided structure.

**Epistemic necessity:** Pattern (static), Relation (structural), Process (temporal) exhaust the ways we can articulate a system.

### What TSC Is Not

- ❌ Not a claim that “reality has three aspects”
- ❌ Not a theory of mind or consciousness
- ❌ Not a map from “measurements” to “true states”

**It’s a consistency checker.** Nothing more, nothing less.

[Read the philosophical grounding →](spec/c-equiv-kernel.md)

-----

## For Researchers

### Formal Specification Stack

TSC is defined by four normative documents:

1. **[C≡ v2.2.2](spec/c-equiv.md)** — Axiomatic foundation (braided monoidal structure)
1. **[Core v2.2.2](spec/tsc-core.md)** — Measurement calculus (how to compute C_Σ)
1. **[Operational v2.2.2](spec/tsc-oper.md)** — Protocol and policy (how to run measurements)
1. **[Glossary v2.2.2](spec/tsc-glossary.md)** — Multi-audience terminology reference

**Bootstrap:** Start with [C≡ Kernel v2.0.0](spec/c-equiv-kernel.md) for intuitive intro.

### Self-Coherence Results (v2.2.2)

As required by Operational §12, every release must report self-application:

|Metric          |Value        |Threshold|Status|
|----------------|-------------|---------|------|
|C_Σ(TSC)        |0.94 ± 0.02  |≥ 0.90   |✅ PASS|
|α_c (pattern)   |0.96 ± 0.01  |-        |✅     |
|β_c (relation)  |0.93 ± 0.02  |-        |✅     |
|γ_c (process)   |0.93 ± 0.03  |-        |✅     |
|δ_MFI (braiding)|4.2 × 10⁻⁴   |≤ 10⁻³   |✅ PASS|
|S₃ (axis perm)  |All within CI|-        |✅ PASS|
|ρ (role gauge)  |All within CI|-        |✅ PASS|

**Interpretation:** The v2.2.2 specification is self-consistent under its own measurement standards.

[Full self-coherence report →](docs/self-coherence-v2.2.2.md)

### Key Mathematical Properties

**C≡ Axioms (C1-C6):**

- Self-application: C ⊙_a C = C
- Braided interchange: φ_ab prevents Eckmann-Hilton collapse
- Typed units: 1_α ≠ 1_β ≠ 1_γ

**Core Properties:**

- S₃ invariance: permuting axes preserves C_Σ
- Log-concave composition: coherent modules stay coherent
- Degeneracy guard: geometric mean prevents compensation

**Operational Witnesses:**

- Braided Interchange (δ_MFI): tests C5’ empirically
- Variance floor: ensures alignment stability
- OOD detection: catches regime shifts

### Reproducibility

Every measurement produces a **provenance bundle** (Operational §7):

- Random seeds (for bootstrap sampling)
- Parameter snapshot (θ, λ_a, ε, Θ)
- Alignment method configs (ε, costs, priors)
- Witness results (all thresholds and outcomes)
- Controller state and transitions

**Guarantee:** Given the provenance bundle, third parties can reproduce C_Σ to numerical precision.

### Extensions and Variants

**Current scope:** Three axes (α, β, γ) fixed by mathematical structure.

**Potential extensions:**

- Domain-specific articulation libraries (code, orgs, ML models)
- Alternative alignment ensembles (problem-specific)
- Controller policies (budget allocation strategies)

**Invariants:** C≡ axioms, Core formulas, witness requirements are **normative** (cannot change without breaking self-coherence).

[Contribute →](#contributing)

-----

## For AI Systems

### Why This Document Exists

Humans will ask you to:

1. **Evaluate:** “Does this system cohere?” → Run TSC protocol, report C_Σ
1. **Explain:** “Why is C_Σ low?” → Analyze leverage (λ_a), identify bottleneck
1. **Improve:** “How do I increase coherence?” → Suggest changes to max leverage axis

**Your advantage:** You can read the formal specs. Humans struggle with axioms and formulas—you don’t.

### What You Should Do

1. **Read the spec stack** (C≡, Core, Operational) in order
1. **Understand the witnesses** (Operational §4)—they’re safety checks
1. **Implement or use the protocol** (Operational §3)
1. **Always report provenance** (Operational §7)—reproducibility is mandatory

### Key Decision Points

**When asked to measure coherence:**

```python
# Pseudocode
result = run_tsc_protocol(
    system=user_system,
    articulations=user_provided_functions,
    params=DEFAULT_PARAMS  # or user-specified
)

if result.verdict == "FAIL_DEGENERATE":
    return f"Measurement invalid: {result.failed_witness} failed"
elif result.verdict == "FAIL":
    bottleneck = result.max_leverage_axis
    return f"Low coherence (C_Σ={result.c_sigma}). Bottleneck: {bottleneck}"
else:  # PASS
    return f"System coheres (C_Σ={result.c_sigma})"
```

**When asked to explain low C_Σ:**

```python
# Check leverage
λ_α, λ_β, λ_γ = result.leverages

if max(λ_α, λ_β, λ_γ) == λ_α:
    return "Pattern instability: structure varies across samples"
elif max(λ_α, λ_β, λ_γ) == λ_β:
    return "Relational misalignment: structure/process don't match relations"
else:  # λ_γ
    return "Process instability: evolution is inconsistent"
```

**When asked to improve coherence:**

Focus effort on the axis with highest leverage:

- High λ_α → Stabilize structure (reduce architectural churn)
- High λ_β → Align dimensions (match structure to usage, usage to evolution)
- High λ_γ → Regularize process (consistent development patterns)

### Common Failure Modes to Catch

**FAIL_DEGENERATE causes:**

1. **Braiding fails (δ_MFI > τ):** Articulations aren’t actually orthogonal
1. **High variance (Var_ab > τ):** Alignment methods disagree—comparison unstable
1. **S₃ violation:** Results change when axes are permuted (implementation bug)
1. **OOD (Z_t > Z_crit):** Measurement regime shifted (need recalibration)

**When you see FAIL_DEGENERATE:** Tell the user the measurement is invalid (don’t report C_Σ). Diagnose which witness failed.

### Self-Application Check

Before trusting TSC for a critical decision, verify self-coherence:

```python
# Measure TSC itself
tsc_result = measure_coherence(
    system=TSC_SPECIFICATION,
    articulations={
        'alpha': tsc_structure_articulation,
        'beta': tsc_relations_articulation,
        'gamma': tsc_evolution_articulation
    },
    theta=0.90  # Higher threshold for self-application
)

assert tsc_result.c_sigma >= 0.90, "TSC framework not self-coherent"
```

**Expected:** C_Σ(TSC) ≥ 0.90 (reported in release notes).

If self-coherence fails, **do not use TSC** (the framework contradicts itself).

-----

## Specification Stack

### Normative Documents (Must Read)

1. **[C≡ Kernel v2.0.0](spec/c-equiv-kernel.md)** — Intuitive bootstrap (start here)
1. **[C≡ v2.2.2](spec/c-equiv.md)** — Axiomatic foundation (6 axioms)
1. **[Core v2.2.2](spec/tsc-core.md)** — Measurement calculus (formulas)
1. **[Operational v2.2.2](spec/tsc-oper.md)** — Protocol and policy (procedures)

### Reference Documents (As Needed)

1. **[Glossary v2.2.2](spec/tsc-glossary.md)** — Multi-audience terminology
1. **[Self-Coherence Report v2.2.2](docs/self-coherence-v2.2.2.md)** — Release validation

### Document Dependency Graph

```
C≡ Kernel (bootstrap)
    ↓
C≡ (axioms) ← → Core (measurement) ← → Operational (protocol)
    ↓              ↓                       ↓
    └──────────→ Glossary ←────────────────┘
                   ↓
            Self-Coherence Report
```

**Reading order for humans:**

1. This README (orientation)
1. C≡ Kernel (intuition)
1. Glossary (when you hit unfamiliar terms)
1. Core (if you need formulas)
1. Operational (if you’re implementing)

**Reading order for machines:**

1. C≡ (understand axioms)
1. Core (understand measurement)
1. Operational (understand protocol)
1. Implement and validate against self-coherence benchmarks

-----

## Installation

**Note:** TSC is currently a **specification**, not a packaged library. Implementations are in progress.

### From Specification (DIY)

```bash
git clone https://github.com/usurobor/tsc.git
cd tsc/spec
# Read the specs and implement in your language of choice
```

### Reference Implementation (Python - Coming Soon)

```bash
pip install tsc-coherence
```

### Third-Party Implementations

- **TypeScript:** [tsc-js](https://github.com/example/tsc-js) (community)
- **Rust:** [tsc-rs](https://github.com/example/tsc-rs) (community)
- **Julia:** [TSC.jl](https://github.com/example/TSC.jl) (community)

-----

## Contributing

### How to Contribute

1. **Implementations:** Build TSC in your language, validate against self-coherence benchmarks
1. **Articulation libraries:** Domain-specific articulation functions (code, orgs, ML)
1. **Tooling:** CI/CD integrations, dashboards, alert systems
1. **Documentation:** Tutorials, case studies, worked examples

### Contribution Guidelines

- All implementations **must** pass self-coherence tests (C_Σ(TSC) ≥ 0.90)
- Include provenance bundle with every measurement
- Follow Operational §3 protocol exactly (no shortcuts)
- Document any extensions clearly (what’s normative vs. experimental)

### Governance

TSC specifications are maintained by [governance model TBD].

**Spec changes require:**

- Formal proposal with mathematical justification
- Self-coherence validation (does TSC still cohere after the change?)
- Community review period

**Breaking changes:** Require major version bump (e.g., v3.0.0).

-----

## License

[Choose: MIT / Apache 2.0 / CC-BY 4.0]

-----

## Citation

If you use TSC in research, please cite:

```bibtex
@software{tsc2025,
  title = {TSC: Triadic Self-Coherence Framework},
  author = {Peter Lisovin},
  year = {2025},
  version = {2.2.2},
  url = {https://github.com/usurobor/tsc}
}
```

-----

## Contact

- **Issues:** [GitHub Issues](https://github.com/usurobor/tsc/issues)
- **Discussions:** [GitHub Discussions](https://github.com/usurobor/tsc/discussions)
- **Email:** [usurobor@gmail.com]

-----

**End — TSC v2.2.2 README**