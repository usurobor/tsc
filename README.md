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

# Measure files locally — no credentials required (mechanical mode)
git clone https://github.com/usurobor/tsc.git && cd tsc
coh --mode mechanical --files spec/ --output .tsc/

# Measure with LLM (semantic + structural, requires credentials)
export LLM_PROVIDER=anthropic
export LLM_MODEL=claude-sonnet-4-20250514
export LLM_API_KEY=sk-ant-your-key
coh --mode hybrid --target spec --registry targets/registry.tsc

# Auto mode: picks hybrid if credentials present, mechanical otherwise
coh --target spec --registry targets/registry.tsc
```

See the [full quick start guide](QUICKSTART.md) for all modes and options.

See the [operator manual](docs/beta/guides/OPERATOR-MANUAL.md) for configuration and usage.

## Scoring modes

| Mode | Credentials needed | What it does |
|------|--------------------|--------------|
| `mechanical` | No | Deterministic structural-proxy scoring. Works offline and in CI. |
| `llm` | Yes | Semantic scoring via `runtime/SELF-MEASURE.md`. |
| `hybrid` | Yes | Runs both backends; report contains `mechanical`, `llm`, and `final` sub-objects. |
| `auto` | Optional | `hybrid` when credentials are present; `mechanical` otherwise. (Default.) |

Direct file input (`--files <glob>`) works with any mode. Named targets (`--target`) require `--registry`.

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
