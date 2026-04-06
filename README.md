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

```bash
# Install
curl -fsSL https://raw.githubusercontent.com/usurobor/tsc/main/install.sh | sh

# Mechanical scoring — no credentials, no network
git clone https://github.com/usurobor/tsc.git && cd tsc
coh --mode mechanical --target spec

# LLM scoring — needs an API key
export LLM_PROVIDER=anthropic
export LLM_MODEL=claude-sonnet-4-20250514
export LLM_API_KEY=sk-ant-your-key
coh --target spec   # auto mode: hybrid if credentials present, else mechanical

# Direct file input
coh --mode mechanical --files docs/*.md README.md
```

### Scoring modes

| Mode | What it does | Needs credentials? |
|------|-------------|-------------------|
| `mechanical` | Deterministic structural scoring | No |
| `llm` | Semantic scoring via LLM | Yes |
| `hybrid` | Both backends, preserves both results | Yes |
| `auto` | Hybrid if credentials present, else mechanical | Optional |

See the [full quick start guide](QUICKSTART.md) and the [operator manual](docs/beta/guides/OPERATOR-MANUAL.md).

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
  version = {v0.3.1},
  url     = {https://github.com/usurobor/tsc}
}
```

## Contact

- **Issues:** [GitHub Issues](https://github.com/usurobor/tsc/issues)
- **Email:** usurobor@gmail.com
