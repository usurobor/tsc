# TSC (Triadic Self-Coherence)

See [docs/THESIS.md](docs/THESIS.md) for what TSC is.

## Repo contents

- `spec/` — canonical theory
- `engine/ocaml/` — canonical implementation
- `runtime/SELF-MEASURE.md` — canonical LLM scoring instruction
- `targets/` — named target declarations
- `docs/` — [documentation tree](docs/README.md) (operator manual, design, governance)
- `examples/` — runnable examples
- `tests/` — conformance and implementation tests

## Quick start

See the [operator manual](docs/beta/guides/OPERATOR-MANUAL.md) for build, configuration, and run instructions.

## Theory stack

Start with `spec/c-equiv.md`, then `tsc-core.md`, `tsc-oper.md`, `tsc-observation-dynamics.md`, `tsc-glossary.md`. See the [doctrine bundle](docs/alpha/doctrine/) for reading order.

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for how theory, targets, and verifier fit together.

## Contributing

Useful contributions fall into four areas: theory, targets, verifier, tests. Keep them aligned.

## License

CC-BY-4.0

## Citation

```bibtex
@software{tsc2026,
  title   = {TSC: Triadic Self-Coherence Framework},
  author  = {Peter Lisovin},
  year    = {2026},
  version = {v0.1.1},
  url     = {https://github.com/usurobor/tsc}
}
```

## Contact

- **Issues:** [GitHub Issues](https://github.com/usurobor/tsc/issues)
- **Email:** usurobor@gmail.com
