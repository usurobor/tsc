# Operator Manual

This manual covers building, configuring, and running the TSC engine.

---

## 1. What the engine does

The engine measures triadic self-coherence of a target. It:

1. Resolves a named target from the registry
2. Builds a file bundle (raw text + SHA-256 hashes)
3. Constructs a prompt from the bundle and a scoring instruction
4. Sends the prompt to an LLM provider
5. Validates the structured response
6. Writes JSON and text reports

The engine does not interpret file contents. The LLM scores coherence; the engine ensures the process is deterministic and the output is valid.

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

### Required variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `LLM_PROVIDER` | LLM provider name. Determines API URL and auth scheme. | `anthropic`, `openai` |
| `LLM_MODEL` | Model identifier sent to the provider. | `claude-sonnet-4-20250514`, `gpt-4o` |
| `LLM_API_KEY` | API key for authentication. | `sk-ant-...`, `sk-...` |

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
coh \
  --target repo \
  --registry targets/registry.tsc \
  --instruction runtime/SELF-MEASURE.md \
  --output .tsc/repo-report.json
```

### CLI arguments

| Argument | Required | Purpose |
|----------|----------|---------|
| `--target` | Yes | Target name to measure (`spec`, `engine`, `repo`) |
| `--registry` | Yes | Path to `targets/registry.tsc` |
| `--instruction` | Yes | Path to the scoring instruction (`runtime/SELF-MEASURE.md`) |
| `--output` | Yes | Path for the JSON report |

### Available targets

| Target | Kind | What it measures |
|--------|------|------------------|
| `spec` | theory | Canonical theory surface (`spec/**/*.md`) |
| `engine` | implementation | OCaml engine (`engine/ocaml/**/*.ml`, build files) |
| `repo` | aggregate | Full repository: includes `spec` + `engine` targets plus integration surfaces |

Targets are declared in `targets/*.tsc` and registered in `targets/registry.tsc`.

### Using make

```bash
make measure    # runs the repo target, writes to .tsc/repo-report.json
```

Requires `LLM_PROVIDER`, `LLM_MODEL`, and `LLM_API_KEY` to be set.

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

The canonical v3.2 aggregate is the geometric mean (spec [tsc-core.md](../../../spec/tsc-core.md) §5). Reports carry two forms:

- `c_sigma_math = (α · β · γ)^(1/3)` — strict mathematical form; collapses to 0 when any component is 0 (`zero_component_present: true`).
- `c_sigma_num  = exp((1/3) · Σ ln(max(sᵢ, ε)))` — ε-floored numerical form; this is the threshold-comparison value per spec/tsc-oper.md §5. `numeric_floor_applied` flags when ε truncated a component.

Grade against `c_sigma_num`; a `zero_component_present: true` result is a strict FAIL irrespective of the numerical value.

| Grade | Range (over `c_sigma_num`) |
|-------|----------------------------|
| A     | >= 0.90 |
| B     | >= 0.80 |
| C     | >= 0.70 |
| F     | < 0.70  *or* `zero_component_present: true` |

The geometric mean penalizes imbalance — one collapsed axis drags the composite disproportionately. The report names the lowest-scoring axis as the bottleneck.

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

The `TSC Measurement` workflow (`.github/workflows/tsc.yml`) runs when files in `spec/`, `engine/ocaml/`, `targets/`, or `runtime/` change.

It requires three **repository secrets** and one **repository variable**:

**Secrets** (Settings > Secrets and variables > Actions > Secrets):

| Secret | Value |
|--------|-------|
| `LLM_PROVIDER` | e.g. `anthropic` |
| `LLM_MODEL` | e.g. `claude-sonnet-4-20250514` |
| `LLM_API_KEY` | your API key |

**Variable** (Settings > Secrets and variables > Actions > Variables):

| Variable | Value |
|----------|-------|
| `TSC_ENABLED` | `true` |

When configured, the workflow measures all three targets (spec, engine, repo) and uploads JSON reports as artifacts.

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
