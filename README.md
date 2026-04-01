# TSC (Triadic Self-Coherence)

TSC is a theory, a target model, and a verifier for triadic coherence.

It evaluates one system through three independent scores:

- **α** — pattern coherence
- **β** — relational coherence
- **γ** — process coherence

These aggregate into `C_Σ`.

## Repo contents

- `spec/` — canonical theory
- `engine/ocaml/` — canonical implementation
- `runtime/SELF-MEASURE.md` — canonical LLM scoring instruction
- `examples/` — runnable examples
- `tests/` — conformance and implementation tests
- `targets/` — named target declarations

## What TSC measures

TSC asks one question:

> Do three independent descriptions of the same system still describe one system?

## Quick start

See `QUICKSTART.md` for build and run instructions.

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

The canonical implementation is the OCaml engine in `engine/ocaml/`.

The engine resolves named targets, builds raw file bundles, and sends them to an LLM with a canonical scoring instruction (`runtime/SELF-MEASURE.md`). It does not parse Markdown semantically.

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
