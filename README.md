# TSC (Triadic Self-Coherence)

**One sentence:** A measurement framework that tests whether your three descriptions of a system fit together—without claiming any of them is "true."

______________________________________________________________________

## ⚡ Quick Start (Pick Your Path)

### 🔧 Engineers: Run This

```bash
# Measure coherence of your codebase
tsc compute examples/cellular-automata/glider.md
# → C_Σ = 0.996 ± 0.001 [PASS]

# Measure TSC itself
tsc self --out coherence_report.json
# → C_Σ = 0.238 [FAIL - working on it!]
```

**What it means:** Three independent measurements of your system either describe the same thing (high C_Σ) or they don't (low C_Σ). No arguments about which metric is "right."

[Implementation Guide →](#for-engineers)

______________________________________________________________________

## Self-Measurement

TSC v3.1.0 measures its own coherence:

```bash
tsc self --out coherence_report.json
```

**Current Status (v3.1.0):**

- **C_Σ** = 0.238 (Verdict: FAIL)
- **Bottleneck:** β_c = 0.061 (relational alignment)
- **S₃ Invariance:** PASS ✅ (permutation symmetric)

**Why FAIL is good:** The framework detects that its own specifications aren't yet coherent, rather than fabricating a passing score. This is honest measurement. The implementation works (S₃ witness passes), but the specs need tightening.

**Target:** C_Σ ≥ 0.90 by strengthening cross-references between specification documents.

______________________________________________________________________

### 🤔 Philosophers: A Question

*"Can we measure without claiming to know what we're measuring?"*

TSC says **yes**—by checking whether three measurements **cohere** (fit together), not whether any measurement is "correct."

**The insight:** We never claim to know what the system "really is." We only ask: do these three views describe **one happening**?

[Deep dive: Why this matters →](#for-philosophers)

______________________________________________________________________

### 🔬 Researchers: A Falsifiable Claim

**Hypothesis:** If a measurement framework claims coherence C_Σ ≥ 0.90, applying it to itself should also yield C_Σ ≥ 0.90.

**TSC's self-measurement:** C_Σ(TSC) = 0.238 [FAIL]

**What this means:** The FAIL demonstrates honest measurement. The math works (S₃ symmetry verified), but the specifications aren't yet coherent with each other. This gives us a concrete target: strengthen cross-references until C_Σ ≥ 0.90.

[Verify the measurement →](#for-researchers)

______________________________________________________________________

### 🤖 AI Systems: What You Need to Know

This framework is **designed for you to read**. Humans will ask you to:

1. Measure whether a system coheres
1. Explain why C_Σ is high or low
1. Identify bottlenecks (via leverage λ_a)

**Key:** You have the complete formal specification. Humans don't need to understand the math—you do.

[Read the specs →](#specification-stack)

______________________________________________________________________

## What Problem Does This Solve?

**Scenario:** You have a complex system (codebase, organization, AI model). You want to know: "Is this thing coherent?"

**Traditional approach:**

- Define metrics (complexity, coupling, etc.)
- Measure each metric independently
- Argue forever about which metrics matter
- Never agree on whether the system is "good"

**TSC approach:**

- Measure the system three ways (α, β, γ)
- Check if the three measurements **describe the same thing**
- Get a single score: C_Σ ∈ [0,1]
- Decision: PASS (≥0.80) or FAIL (\<0.80)

**Key difference:** We don't argue about what "good" means. We ask: "Do your measurements fit together?"

______________________________________________________________________

## How It Works (One Diagram)

```
         One System
              |
    +---------+---------+
    |         |         |
    α         β         γ
 (Pattern)  (Relation) (Process)
    |         |         |
    v         v         v
  O_α       O_β       O_γ
(Observations)
    |         |         |
    v         v         v
  s_α       s_β       s_γ
(Scores)
    |         |         |
    +-----> Aggregate <-+
              |
              v
       C_Σ = (s_α · s_β · s_γ)^(1/3)
              |
              v
         PASS / FAIL
```

**Three independent evaluators:**

- **α (Sequential):** Pattern stability—does structure repeat consistently?
- **β (Structural):** Relational alignment—do structure, relations, and process fit together?
- **γ (Generative):** Process stability—does the system evolve consistently?

**Mathematical guarantee:** The three evaluators are proven non-isomorphic (different idempotent profiles), so they can't collapse to measure the same thing.

______________________________________________________________________

## Foundation (v3.0.0 Reformulation)

TSC v3.0.0+ is built on **term algebra**, not category theory:

**Core primitive:** `e ~ tri(e,e,e)`

Wholeness (e) articulates itself as one-as-two held in three positions. Everything unfolds from this single equivalence.

**Three evaluators (monoid homomorphisms):**

- α: (ℕ, ⊕, 0) — sequential/additive
- β: (ℕ³, ⊔, 0³) — structural/lattice
- γ: (ℕ×ℕ, ⊗, (0,0)) — generative/multiplicative

**Independence proof (Theorem 2.3):** Distinct idempotent profiles guarantee no Eckmann-Hilton collapse.

This is simpler and more rigorous than the v2.x braided monoidal category approach.

[Full spec →](spec/c-equiv.md)

______________________________________________________________________

## For Engineers

### Basic Usage

```python
from tsc import compute_coherence

# Define three ways to observe your system
def observe_alpha(system):
    """Pattern: Extract structural features"""
    return extract_ast(system)

def observe_beta(system):
    """Relation: Extract call graph"""
    return extract_calls(system)

def observe_gamma(system):
    """Process: Extract git history"""
    return extract_commits(system)

# Measure coherence
result = compute_coherence(
    system="./my-codebase",
    observers={'alpha': observe_alpha, 'beta': observe_beta, 'gamma': observe_gamma}
)

print(f"C_Σ = {result.c_sigma:.3f} [{result.verdict}]")

# If FAIL, check leverage to find bottleneck
if result.verdict == "FAIL":
    print(f"Bottleneck: {result.bottleneck_axis}")
    # → "beta" means: structure and behavior don't match
```

### What Gets Measured

- **s_α (Pattern):** Does repeated sampling yield similar structure?
- **s_β (Relation):** Do pattern, relation, and process describe the same thing?
- **s_γ (Process):** Does the system evolve consistently over time?

**Aggregate:** C_Σ = (s_α · s_β · s_γ)^(1/3)

### When to Use TSC

✅ **Good for:**

- Detecting architectural drift (structure vs actual usage)
- Validating refactors (did coherence improve?)
- CI/CD gates (block merges that break coherence)
- Tracking system health over time

❌ **Not for:**

- Finding bugs (use tests)
- Performance optimization (use profilers)
- Security audits (use scanners)

**TSC measures internal consistency, not correctness.**

Full implementation guide (coming soon)

______________________________________________________________________

## For Philosophers

### The Core Question

*"How can we measure a system without claiming to know what it 'really is'?"*

**Traditional measurement assumes:**

1. There's a "true" state of the system
1. Our measurement approximates that truth
1. Better measurements → closer to truth

**Problem:** We never have access to "the truth" to check our approximation.

**TSC's alternative:**

1. There's one **happening** (the system in process)
1. We observe it three ways (α, β, γ)
1. We check if the three observations **cohere** (describe **one** happening)

**Insight:** We don't need "truth" to test consistency. Three descriptions either fit together or they don't.

### The Manzotti Connection

TSC follows Riccardo Manzotti's "spread mind" stance:

- **No representations:** Observations don't "map to" an external reality
- **Articulation = happening:** The observation **is** the system presenting itself
- **Coherence = unity test:** Do three articulations present **one** happening?

**Metaphysical claim:** **None.** TSC doesn't say what systems "are." It only tests whether your descriptions fit together.

**Validation:** Self-application. TSC measures itself: C_Σ(TSC) = 0.238 (FAIL). The FAIL demonstrates honest measurement—it detects incoherence rather than fabricating success.

### Why Three Axes?

**Why not one?** A single measurement can't check itself for consistency.

**Why not two?** Two measurements can agree by accident (overfitting). No way to detect if they're both wrong.

**Why three?** Three measurements can triangulate. If all three independently agree, that's evidence of real coherence. If only two agree, the third flags the problem.

**Mathematical guarantee:** The three evaluators are proven non-isomorphic—they literally can't measure the same thing. So their agreement (if achieved) is meaningful.

______________________________________________________________________

## For Researchers

### Reproducibility

Every TSC measurement includes a **provenance bundle**:

```json
{
  "C_sigma": 0.238,
  "scores": {"alpha_c": 0.306, "beta_c": 0.061, "gamma_c": 0.721},
  "witnesses": {"S3_passed": true},
  "params": {"theta": 0.7, "lambda_alpha": 4.0, ...},
  "provenance": {
    "git_commit": "c7a9c4f",
    "python": "3.11.14",
    "timestamp": "2025-11-11T..."
  }
}
```

Includes: parameters, git hash, Python version, witness results. Enough to reproduce exactly.

### Validation Method

**Self-application test:**

```python
# Measure TSC using TSC
result = compute_coherence(
    system=TSC_REPO,
    observers={
        'alpha': measure_spec_structure,
        'beta': measure_spec_relations,
        'gamma': measure_spec_evolution
    }
)

# v3.1.0: C_Σ = 0.238 (FAIL)
# Target: C_Σ ≥ 0.90
```

**The FAIL is the point:** It demonstrates that:

1. The measurement works (S₃ witness passes)
1. The framework is honest (doesn't fabricate success)
1. We have a concrete target (fix specs until C_Σ ≥ 0.90)

### Key Theorems

**Theorem 2.3 (Non-Collapse):** The three evaluators α, β, γ have distinct idempotent profiles, proving they're pairwise non-isomorphic. No Eckmann-Hilton collapse.

**Corollary:** Dimensional independence is guaranteed algebraically, not just assumed.

[Full proofs →](spec/c-equiv.md#3-evaluators)

______________________________________________________________________

## Specification Stack

### Normative Documents (Read These)

1. **[C≡ Kernel](spec/c-equiv.md)** — Intuitive bootstrap (start here)
1. **[C≡ v3.1.0](spec/c-equiv.md)** — Term algebra foundation
1. **[Core v3.1.0](spec/tsc-core.md)** — Measurement calculus
1. **[Operational v3.1.0](spec/tsc-oper.md)** — Protocol and procedures

### Reference Documents (As Needed)

- **[Glossary v3.1.0](spec/tsc-glossary.md)** — Multi-audience terminology
- **[Self-Coherence Report v3.1.0](.tsc/measurements/README.md)** — Current measurement

### Reading Order

**For humans:**

1. This README (orientation)
1. C≡ Kernel (intuition)
1. Glossary (when stuck on terms)
1. Core (for formulas)
1. Operational (for implementation)

**For machines:**

1. C≡ (understand foundation)
1. Core (understand measurement)
1. Operational (understand protocol)
1. Implement and validate

______________________________________________________________________

## Installation

**Current status:** TSC is a **specification**. Reference implementation in progress.

### From Source

```bash
git clone https://github.com/usurobor/tsc.git
cd tsc
pip install -e ".[dev]"

# Run tests
make test

# Measure TSC itself
make self-coherence
```

### Requirements

- Python 3.10+
- NumPy (optional, for faster computation)

______________________________________________________________________

## Contributing

### How to Contribute

1. **Implementations:** Build TSC in your language
1. **Observers:** Domain-specific observation functions
1. **Tooling:** CI/CD integrations, dashboards
1. **Documentation:** Tutorials, case studies

### Contribution Guidelines

- All implementations **must** pass self-coherence validation
- Include provenance bundle with every measurement
- Follow Operational protocol exactly
- Document extensions clearly (normative vs experimental)

### Governance

**Spec changes require:**

- Mathematical justification
- Self-coherence validation (does TSC still cohere?)
- Community review

**Breaking changes** require major version bump (e.g., v4.0.0).

______________________________________________________________________

## What's Next

**v3.1.0 roadmap (achieve self-coherence):**

1. **Fix β_c bottleneck** (currently 0.061)

   - Strengthen cross-references between specs
   - Add semantic links between definitions
   - Target: β_c ≥ 0.85

1. **Stabilize α_c** (currently 0.306)

   - Ensure structural consistency across specs
   - Target: α_c ≥ 0.85

1. **Maintain γ_c** (currently 0.721 - already good)

   - Keep commit patterns consistent
   - Target: γ_c ≥ 0.85

**Target:** C_Σ(TSC) ≥ 0.90 (self-coherent framework)

______________________________________________________________________

## License

CC-BY-4.0

______________________________________________________________________

## Citation

```bibtex
@software{tsc2025,
  title = {TSC: Triadic Self-Coherence Framework},
  author = {Peter Lisovin},
  year = {2025},
  version = {v3.1.0},
  url = {https://github.com/usurobor/tsc}
}
```

______________________________________________________________________

## Contact

- **Issues:** [GitHub Issues](https://github.com/usurobor/tsc/issues)
- **Email:** usurobor@gmail.com

______________________________________________________________________

**End — TSC v3.1.0**
