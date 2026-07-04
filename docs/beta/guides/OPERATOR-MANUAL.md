# Operator Manual

This manual covers building, configuring, and running the TSC engine.

---

## 1. What the engine does

The engine measures triadic self-coherence of a target in one of four
modes — `mechanical` | `llm` | `hybrid` | `auto` (the default: `hybrid`
when the full provider configuration — `LLM_PROVIDER`, `LLM_MODEL`, `LLM_API_KEY` — is present, `mechanical` otherwise; a partial set warns with the missing variable names and falls back). It:

1. Resolves input — a named target from the registry, direct file globs
   (`--files`), or a kata (`--kata`)
2. Builds a file bundle (raw text + SHA-256 hashes)
3. Scores the bundle:
   - **mechanical** — deterministic structural signals; no credentials,
     no network, works offline and in CI
   - **llm / hybrid** — constructs a prompt from the bundle and the
     scoring instruction, sends it to the provider, and validates the
     structured response through the witness funnel (`hybrid` also runs
     the mechanical backend and combines both results)
4. Writes JSON (and text) reports; every report's `mode` field states
   which backend produced it

The mechanical backend interprets file structure only, never semantics;
the LLM path is the semantic judgment. In every mode the engine owns
validation, the barrier transform, and aggregation.

---

## 2. Install

### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/tsc/main/install.sh | sh
```

This detects your platform, downloads the latest release binary, and installs
to `/usr/local/bin/coh`. Override the install directory with `BIN_DIR`:

```bash
BIN_DIR=$HOME/.local/bin curl -fsSL https://raw.githubusercontent.com/usurobor/tsc/main/install.sh | sh
```

If `/usr/local/bin` requires root:

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/tsc/main/install.sh | sudo sh
```

Verify:

```bash
coh --version
```

### From source

Prerequisites: OCaml >= 4.14 (5.2 recommended), opam, libcurl (for ezcurl).

```bash
opam switch create tsc 5.2.0
cd engine/ocaml
opam install . --deps-only -y
dune build
```

Or from the repo root:

```bash
make setup
make build
```

The binary is `engine/ocaml/_build/default/bin/main.exe`.

---

## 3. Configuration

The engine reads all configuration from environment variables. Nothing is hardcoded; nothing is stored in the repository.

Mechanical mode (and `auto` without credentials) needs **no configuration
at all**. The variables below matter only for the `llm` and `hybrid`
semantic paths.

### Credentials (llm / hybrid modes only)

| Variable | Purpose | Example |
|----------|---------|---------|
| `LLM_PROVIDER` | LLM provider name. Determines API URL and auth scheme. | `anthropic`, `openai` |
| `LLM_MODEL` | Model identifier sent to the provider. | `claude-sonnet-4-20250514`, `gpt-4o` |
| `LLM_API_KEY` | API key for authentication. | `sk-ant-...`, `sk-...` |

In CI, the rendered self-measurement workflow uses no raw API key: the
witness runs via the Claude CLI, gated by the presence of the
`CLAUDE_CODE_OAUTH_TOKEN` secret (see
[skills/self-measure/SKILL.md](../../../skills/self-measure/SKILL.md) §5–6).

### Optional variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `LLM_BASE_URL` | Override the API endpoint. Use for proxies, local models, or custom deployments. | Provider default (see below) |

### Provider defaults

When `LLM_BASE_URL` is not set, the engine resolves the URL from `LLM_PROVIDER`:

| Provider | Default URL |
|----------|-------------|
| `anthropic` | `https://api.anthropic.com/v1/messages` |
| `openai` | `https://api.openai.com/v1/chat/completions` |
| Other | `https://api.{provider}.com/v1/messages` |

### Authentication

- **Anthropic**: sends `x-api-key` header + `anthropic-version: 2023-06-01`
- **OpenAI and others**: sends `Authorization: Bearer {key}` header

### Example setup

```bash
export LLM_PROVIDER=anthropic
export LLM_MODEL=claude-sonnet-4-20250514
export LLM_API_KEY=sk-ant-your-key-here
```

For a local model via Ollama:

```bash
export LLM_PROVIDER=openai
export LLM_MODEL=llama3
export LLM_API_KEY=unused
export LLM_BASE_URL=http://localhost:11434/v1/chat/completions
```

---

## 4. Running measurements

### Basic usage

```bash
coh --target repo                       # auto mode, defaults for everything else
coh --mode mechanical --files spec/     # direct file input, no credentials
```

### CLI arguments

Exactly one input selector is required: `--target`, `--files`, or
`--kata`. Everything else has a default.

| Argument | Required | Purpose |
|----------|----------|---------|
| `--target` | one selector | Target name to measure (`spec`, `engine`, `repo`); repeatable — two or more produce the mechanical cross-target report |
| `--files` | one selector | Direct file/glob input (repeatable); same bundle model as named targets |
| `--kata` | one selector | Run a kata from `katas/` against its declared expectation |
| `--mode` | No (default `auto`) | `mechanical` \| `llm` \| `hybrid` \| `auto` |
| `--registry` | No (default `targets/registry.tsc`) | Path to the target registry |
| `--instruction` | No (default `runtime/SELF-MEASURE.md`) | Path to the scoring instruction |
| `--output` | No (default `.tsc`) | Output directory for reports |
| `--emit-prompt` | No | Write the exact LLM prompt content (instruction + hashed bundle) to the given path and exit; no provider call |
| `--llm-response` | No | Read the LLM response from the given path instead of calling the provider (llm/hybrid; the external witness route) |

### Self-measurement (`coh self`)

`coh self` measures this repository against its own targets. The engine
dispatches it (git-style external subcommand) to the `coh-self` command,
which is rendered from [skills/self-measure/SKILL.md](../../../skills/self-measure/SKILL.md) —
read that skill for the full procedure, including exactly which steps are
mechanical and which single step is delegated to an LLM.

```bash
coh self --mode mechanical   # deterministic, no credentials
coh self                     # auto: hybrid with credentials, mechanical without
coh-self --emit-prompt spec  # external witness route, deterministic half
coh-self --ingest spec       # validate + ingest a witness response
```

### Available targets

| Target | Kind | What it measures |
|--------|------|------------------|
| `spec` | theory | Canonical theory surface (`spec/**/*.md`) |
| `engine` | implementation | OCaml engine (`engine/ocaml/**/*.ml`, build files) |
| `repo` | aggregate | Full repository: includes `spec` + `engine` targets plus integration surfaces |
| `methodology` | aggregate | The self-measurement methodology as a corpus: skill declaration, schema, validators, renderer, rendered surfaces, scoring instruction |
| `cm-of-cms` | aggregate | The 0th coherence methodology as a corpus: CM-of-CMs declaration, comparable schema, instruments, calibration-commons contract |

Targets are declared in `targets/*.tsc` and registered in `targets/registry.tsc`.
The default self-measurement run (`coh self`, CI) drives `spec`, `engine`,
and `repo`; `methodology` and `cm-of-cms` are measured on demand
(`coh --target methodology ...`).

### Using make

```bash
make measure    # coh self: all targets + cross-target, into .tsc/self/
```

Runs in auto mode: hybrid when `LLM_PROVIDER`, `LLM_MODEL`, and
`LLM_API_KEY` are set, mechanical otherwise.

---

## 5. Reading reports

The engine writes two files per run:

- **JSON report** (at the `--output` path) — structured scores, evidence, and fixes
- **Text report** (same path with `.txt` extension) — human-readable summary

### Report fields

| Field | Type | Meaning |
|-------|------|---------|
| `target` | string | Target name |
| `alpha` | float | α score (0.0–1.0): pattern coherence |
| `beta` | float | β score (0.0–1.0): relational coherence |
| `gamma` | float | γ score (0.0–1.0): process coherence |
| `bottleneck_axis` | string | Lowest-scoring axis |
| `confidence` | float | LLM's confidence in its own assessment |
| `summary` | string | One-paragraph overall assessment |
| `axis_evidence` | object | Per-axis evidence with observations and scores |
| `unresolved_ambiguity` | string | What the LLM could not determine from the bundle |
| `next_fixes` | array | Suggested improvements, ordered by impact |

### Scoring thresholds

The aggregate is the geometric mean of the three axes. Two canonical forms are emitted under `provenance`:

- `provenance.aggregate_math.C_sigma_math = (α · β · γ)^(1/3)` — strict mathematical aggregate; zero whenever any component is zero.
- `provenance.aggregate_numeric.C_sigma_num = (max(α, ε) · max(β, ε) · max(γ, ε))^(1/3)` — verdict-bearing numerical aggregate; floors components at `ε = 10⁻⁵` so the score stays well-defined at the boundary. Equals `C_sigma_math` whenever every component is at or above `ε`.

There is no flat top-level `c_sigma` field — readers consult `provenance` for the aggregate facts.

| Grade | `C_sigma_num` range |
|-------|--------------------|
| A | >= 0.90 |
| B | >= 0.80 |
| C | >= 0.70 |
| F | < 0.70 |

Grades are a descriptive quality band. The spec's acceptance gate for self-application verdicts is Θ (Operational §5/§7; currently 0.75) — related but deliberately distinct.

The geometric mean naturally penalizes imbalance — one collapsed axis drags the aggregate disproportionately. The report names the lowest-scoring axis as the bottleneck.

---

## 6. CI integration

### Build and test

The `ci` workflow (`.github/workflows/ci.yml`) runs on every push to main and every PR:

1. Sets up OCaml 5.2 via `ocaml/setup-ocaml@v3`
2. Installs dependencies via opam
3. Runs `dune build` and `dune runtest`
4. Uploads the binary as an artifact
5. Runs Markdown link checking

### Self-measurement

The `tsc-self-measure` workflow (`.github/workflows/tsc-self-measure.yml`,
rendered from `skills/self-measure/SKILL.md` — edit the skill, never the
YAML) runs on any branch push or PR touching `spec/`, `engine/ocaml/`,
`targets/`, `runtime/`, or `skills/`:

- **mechanical job** — always on; no secrets, no gate. Measures every
  target deterministically and uploads the reports.
- **llm-witness job** — one matrix job per target, gated by the
  **presence** of one repository secret; there is no separate enable
  variable to drift out of sync with it:

| Secret | Value |
|--------|-------|
| `CLAUDE_CODE_OAUTH_TOKEN` | output of `claude setup-token` |

The witness runs a version-pinned Claude CLI against the engine-emitted
prompt, may only read that prompt and write its single response JSON,
and the engine validates the response through the witness funnel before
rendering the hybrid report. A refused response produces a durable
validation-failure artifact and no report.

The `tsc-coherence-ledger` workflow appends one row per version
increment to `.tsc/COHERENCE.md` (hybrid when the same secret is
present; labeled mechanical fallback otherwise).

The HTTP provider route (`LLM_PROVIDER` / `LLM_MODEL` / `LLM_API_KEY`,
section 3) is the **local** route only; CI never carries a raw API key.
---

## 7. Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `LLM_PROVIDER is not set` | Missing env var | Export `LLM_PROVIDER`, `LLM_MODEL`, `LLM_API_KEY` |
| `HTTP 401` | Bad API key | Check `LLM_API_KEY` value |
| `HTTP 400` | Wrong model name or provider mismatch | Verify `LLM_MODEL` is valid for `LLM_PROVIDER` |
| CI build fails with exit 127 | Missing `tsc_engine.opam` | Run `dune build` locally to regenerate, then commit |
| Empty report | LLM returned non-JSON | Check raw response in `.tsc/` directory |
| `opam install` finds no package | `.opam` file missing or `dune-project` out of sync | Run `dune build` to regenerate `tsc_engine.opam` |
