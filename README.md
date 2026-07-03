# TSC (Triadic Self-Coherence)

See [docs/THESIS.md](docs/THESIS.md) for what TSC is.

## Repo contents

- `spec/` — canonical theory
- `engine/ocaml/` — canonical implementation
- `runtime/SELF-MEASURE.md` — canonical LLM scoring instruction
- `targets/` — named target declarations
- `skills/` — [typed skill modules](skills/README.md) (self-measurement declaration)
- `schemas/` — [CUE schemas](schemas/README.md) validating skill frontmatter
- `katas/` — [kata framework](katas/README.md) (pedagogical/regression inputs with expected outcomes)
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

## Self-measurement

TSC measures itself:

```bash
coh self --mode mechanical   # deterministic, offline, no credentials
coh self                     # auto: hybrid when LLM credentials are present
```

The whole procedure — which steps are fully mechanical and exactly what
cognitive work is delegated to an LLM, under what constraints — is declared
in [skills/self-measure/SKILL.md](skills/self-measure/SKILL.md). That skill
is the authority: its frontmatter is validated by [schemas/skill.cue](schemas/skill.cue),
cross-checked against the engine source, and rendered into the `coh-self`
command and the [`tsc-self-measure`](.github/workflows/tsc-self-measure.yml)
workflow (mechanical job always on; the LLM witness runs via the Claude CLI,
gated by the `TSC_LLM_ENABLED` repo variable). CI proves the rendered
artifacts match the skill byte-for-byte.

## Theory stack

Start with `spec/c-equiv.md`, then `tsc-core.md`, `tsc-oper.md`, `tsc-observation-dynamics.md`, `tsc-glossary.md`. See the [doctrine bundle](docs/alpha/doctrine/) for reading order.

## Kata framework

Run the engine against curated inputs with known expected outcomes:

```bash
# Smoke-test: kata-01 is the positive control (should always pass)
coh --kata 01-glider --mode mechanical

# Negative control: kata-02 should score low (expected fail)
coh --kata 02-random-soup --mode mechanical
```

See [katas/README.md](katas/README.md) for the framework, `kata.toml` schema, and how to add katas.

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for how theory, targets, katas, and verifier fit together.

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
