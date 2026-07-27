# TSC (Triadic Self-Coherence)

> **Specification v4.0.0 (normative, unimplemented). The shipping engine implements v3.2.2.**
> The `spec/` tree describes v4, which has **no implementation yet**; the `coh` binary and
> everything under "Quick start" is the **v3.2.2 engine**. A "spec 4.0.0" on `main` does not
> mean "TSC 4.0.0 works." See [STATUS.md](STATUS.md).

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

These commands drive the **v3.2.2 engine** (the shipping binary), not the v4
specification — v4 is unimplemented (see [STATUS.md](STATUS.md)).

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
| `auto` | Optional | `hybrid` when the full provider configuration (`LLM_PROVIDER`, `LLM_MODEL`, `LLM_API_KEY`) is present; `mechanical` otherwise — a partial set warns with the missing names and falls back. (Default.) |

Direct file input (`--files <glob>`) works with any mode. Named targets (`--target`) require `--registry`.

## Self-measurement

TSC measures itself:

```bash
coh self --mode mechanical   # deterministic, offline, no credentials
coh self                     # auto: hybrid when the full LLM provider config is present
```

The whole procedure — which steps are fully mechanical and exactly what
cognitive work is delegated to an LLM, under what constraints — is declared
in [skills/self-measure/SKILL.md](skills/self-measure/SKILL.md). That skill
is the authority: its frontmatter is validated by [schemas/skill.cue](schemas/skill.cue),
cross-checked against the engine source, and rendered into the `coh-self`
command and the [`tsc-self-measure`](.github/workflows/tsc-self-measure.yml)
workflow (mechanical job always on; the LLM witness runs via a pinned
Claude CLI, gated by the presence of the `CLAUDE_CODE_OAUTH_TOKEN`
secret — no separate toggle to drift out of sync with it). CI proves the
rendered artifacts match the skill byte-for-byte.

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
  year         = {2026},
  version      = {0.12.0},
  spec-version = {4.0.0},
  url          = {https://github.com/usurobor/tsc}
}
```

## Contact

- **Issues:** [GitHub Issues](https://github.com/usurobor/tsc/issues)
- **Email:** usurobor@gmail.com
