# TSC (Triadic Self-Coherence)

TSC is an upstream **theory, target corpus, and verifier** for triadic coherence.

It does three things:

1. **Defines** a formal account of coherence across three independent axes
2. **Names** explicit measurement targets, including self-targets
3. **Implements** a verifier that evaluates α / β / γ and aggregates them into `C_Σ`

TSC is not primarily a product surface.
It is the place where the theory is specified, the targets are made explicit, and the verifier is made honest.

---

## What this repo is

This repo has three layers:

- **Theory** — the formal ideas in `spec/`
- **Targets** — the named bundles measured by TSC, declared in `project.tsc` and `targets/`
- **Verifier** — the implementation that evaluates those targets

Self-measurement is one target among others.
It is not the repo's identity.

---

## What TSC asks

TSC asks a narrow question:

> Do three independent descriptions of the same system still describe one system?

It does **not** claim any one description is "the truth."
It checks whether they cohere.

The result is:

- **α** — pattern coherence
- **β** — relational coherence
- **γ** — generative / process coherence
- **`C_Σ`** — aggregate triadic coherence

---

## Current implementation status

- The **theory** is primary
- The current executable path is still the **Python reference implementation**
- The future **canonical engine** is intended to be OCaml
- Self-measurement exists, but it is only one declared target

---

## Quick orientation

If you want to understand the theory:
- start with `spec/`

If you want to understand the current implementation:
- read `QUICKSTART.md`
- then inspect `reference/python/`

If you want to understand what is being measured:
- read `project.tsc`
- then `targets/`

If you want to understand self-measurement:
- read `ARCHITECTURE.md`

---

## Quick start

### Current reference path

```bash
# run the current reference implementation
tsc examples/cellular-automata/glider.md --format text
```

### Named self-targets

```bash
# examples of the target model this repo is moving toward
tsc self --target spec
tsc self --target engine
tsc self --target repo
```

The named-target model matters because:
- the theory may be coherent before the engine is finished
- the engine may be incomplete without invalidating the theory
- the aggregate repo score should not smear those two together

---

## Repo map

```
/spec/              # canonical theory
/reference/         # current reference implementation(s)
/examples/          # runnable examples
/tests/             # conformance and implementation tests
/project.tsc        # target registry
/targets/           # named target manifests
/ARCHITECTURE.md    # self-measurement and target architecture
/QUICKSTART.md      # implementation-oriented usage guide
```

---

## Repo stance

TSC is the upstream source of truth for the theory and its verifier.

Downstream systems may consume released TSC concepts, targets, or engine behavior.
They should not depend on TSC's unfinished self-measurement state as if it were settled doctrine.

---

## Why self-measurement still matters

Self-measurement is useful because it forces TSC to test itself instead of only measuring external examples.

But it should be read correctly:
- a low spec score means the theory/docs need tightening
- a low engine score means the implementation is immature
- a low repo score means the whole repo surface is still not converged

Those are different failures.
They should not be collapsed into one ambiguous number.

---

## Next steps

1. Stabilize the target model
2. Keep Python as reference
3. Build the canonical OCaml engine
4. Only then decide whether the physical repo layout needs larger moves

---

## How It Works

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

- **α (Sequential):** Pattern stability — does structure repeat consistently?
- **β (Structural):** Relational alignment — do structure, relations, and process fit together?
- **γ (Generative):** Process stability — does the system evolve consistently?

**Mathematical guarantee:** The three evaluators are proven non-isomorphic (different idempotent profiles), so they can't collapse to measure the same thing.

---

## Foundation (v3.0.0 Reformulation)

TSC v3.0.0+ is built on **term algebra**, not category theory:

**Core primitive:** `e ~ tri(e,e,e)`

Wholeness (e) articulates itself as one-as-two held in three positions. Everything unfolds from this single equivalence.

**Three evaluators (monoid homomorphisms):**

- α: (ℕ, ⊕, 0) — sequential/additive
- β: (ℕ³, ⊔, 0³) — structural/lattice
- γ: (ℕ×ℕ, ⊗, (0,0)) — generative/multiplicative

**Independence proof (Theorem 2.3):** Distinct idempotent profiles guarantee no Eckmann-Hilton collapse.

[Full spec →](spec/c-equiv.md)

---

## Specification Stack

### Normative Documents

1. **[C≡ Kernel](spec/c-equiv.md)** — Term algebra foundation (start here)
2. **[Core v3.1.0](spec/tsc-core.md)** — Measurement calculus
3. **[Operational v3.1.0](spec/tsc-oper.md)** — Protocol and procedures
4. **[Observation Dynamics v1.0.13](spec/tsc-observation-dynamics.md)** — Observer construction and comparison

### Reference Documents

- **[Glossary v3.1.0](spec/tsc-glossary.md)** — Multi-audience terminology

---

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

---

## Contributing

### How to Contribute

1. **Implementations:** Build TSC in your language
2. **Observers:** Domain-specific observation functions
3. **Tooling:** CI/CD integrations, dashboards
4. **Documentation:** Tutorials, case studies

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

---

## License

CC-BY-4.0

---

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

---

## Contact

- **Issues:** [GitHub Issues](https://github.com/usurobor/tsc/issues)
- **Email:** usurobor@gmail.com

---

**End — TSC v3.1.0**
