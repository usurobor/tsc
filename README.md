# TSC (Triadic Self-Coherence)

TSC is a theory, a target model, and a verifier for triadic coherence.

It evaluates one system through three independent scores:

- **α** — pattern coherence
- **β** — relational coherence
- **γ** — process coherence

These aggregate into `C_Σ`.

## Repo contents

- `spec/` — canonical theory
- `reference/python/` — current implementation
- `examples/` — runnable examples
- `tests/` — conformance and implementation tests
- `project.tsc` — live measurement config
- `targets/` — named target declarations

## What TSC measures

TSC asks one question:

> Do three independent descriptions of the same system still describe one system?

## Quick start

Install:

```bash
python3 -m pip install --upgrade pip
pip install -e ".[dev]"
```

Run an example:

```bash
tsc examples/cellular-automata/glider.md --format text
```

Run tests:

```bash
make test
```

Measure the repo with the current orchestrator:

```bash
make self-coherence
```

## Theory stack

Start with:

1. `spec/c-equiv.md`
2. `spec/tsc-core.md`
3. `spec/tsc-oper.md`
4. `spec/tsc-observation-dynamics.md`
5. `spec/tsc-glossary.md`

## Targets

TSC uses explicit targets. Current target surfaces are:

- `spec`
- `engine`
- `repo`

Read:

- `targets/README.md` for the target model
- `ARCHITECTURE.md` for how theory, targets, and verifier fit together

## Implementation

The current executable path is `reference/python/`.

## Contributing

Useful contributions fall into four areas:

1. theory
2. targets
3. verifier
4. tests

Keep them aligned.

## License

CC-BY-4.0

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

## Contact

- **Issues:** [GitHub Issues](https://github.com/usurobor/tsc/issues)
- **Email:** usurobor@gmail.com
