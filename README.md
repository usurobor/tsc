# TSC (Triadic Self-Coherence)

TSC is a theory, a target model, and a verifier for triadic coherence.

It measures one system through three independent evaluators:

- **α** — pattern coherence
- **β** — relational coherence
- **γ** — process coherence

Those three scores aggregate into `C_Σ`.

---

## What this repo contains

- `spec/` — canonical theory
- `reference/python/` — current executable implementation
- `examples/` — runnable example inputs
- `tests/` — implementation and conformance tests
- `project.tsc` — live measurement config for the current orchestrator
- `targets/` — named target declarations
- `ARCHITECTURE.md` — repo architecture
- `QUICKSTART.md` — implementation-oriented usage guide

---

## What TSC measures

TSC asks one question:

> Do three independent descriptions of the same system still describe one system?

The result is:

- α for pattern
- β for relation
- γ for process
- `C_Σ` for aggregate coherence

---

## Quick start

### Install

```bash
python3 -m pip install --upgrade pip
pip install -e ".[dev]"
```

### Run an example

```bash
tsc examples/cellular-automata/glider.md --format text
```

### Run tests

```bash
make test
```

### Measure the repo with the current orchestrator

```bash
make self-coherence
```

---

## How TSC works

TSC evaluates one target through three independent views.

```
         One System
             |
      +------+------+
      |      |      |
      α      β      γ
      |      |      |
      v      v      v
     sα     sβ     sγ
      \      |      /
       \     |     /
          C_Σ
```

The evaluators are intentionally different:

- α checks repeating structure
- β checks alignment across relations
- γ checks stability through change

---

## Theory stack

Start here:

1. **[C≡ Kernel](spec/c-equiv.md)** — foundational equivalence
2. **[Core](spec/tsc-core.md)** — coherence calculus
3. **[Operational](spec/tsc-oper.md)** — protocol and procedure
4. **[Observation Dynamics](spec/tsc-observation-dynamics.md)** — observer construction and comparison
5. **[Glossary](spec/tsc-glossary.md)** — terminology

---

## Target model

TSC works with explicit targets. Current target surfaces are declared in:

- `project.tsc` — live config for the current orchestrator
- `targets/` — named target declarations

The named targets are:

- **spec** — theory surface
- **engine** — implementation surface
- **repo** — aggregate repository surface

Read:

- `targets/README.md` for the target model
- `ARCHITECTURE.md` for how theory, targets, and verifier fit together

---

## Implementation status

The current executable path is the Python implementation in `reference/python/`.

The repo architecture also defines an OCaml direction for the canonical engine. `ARCHITECTURE.md` describes that direction. `QUICKSTART.md` covers the current Python path.

---

## Repo map

```
/spec/              canonical theory
/reference/python/  current implementation
/examples/          runnable examples
/tests/             conformance and implementation tests
/project.tsc        live orchestrator config
/targets/           named target declarations
/ARCHITECTURE.md    architecture
/QUICKSTART.md      usage
```

---

## Contributing

Contributions are useful in four areas:

1. **Theory** — tighten definitions, proofs, and terminology
2. **Targets** — add clearer target declarations and examples
3. **Verifier** — improve implementation and execution paths
4. **Tests** — strengthen conformance and invariance checks

When you change the theory, targets, or verifier, keep them aligned.

---

## License

CC-BY-4.0

---

## Citation

```bibtex
@software{tsc2025,
  title   = {TSC: Triadic Self-Coherence Framework},
  author  = {Peter Lisovin},
  year    = {2025},
  version = {v3.1.0},
  url     = {https://github.com/usurobor/tsc}
}
```

---

## Contact

- **Issues:** [GitHub Issues](https://github.com/usurobor/tsc/issues)
- **Email:** usurobor@gmail.com
