# Quick Start

Measure the coherence of any text corpus in under 2 minutes.

## 1. Install

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/tsc/main/install.sh | sh
```

## 2. Choose a mode

TSC has four scoring modes:

| Mode | Credentials | What it does |
|------|-------------|--------------|
| `mechanical` | None | Deterministic structural-proxy scoring. Works offline and in CI. |
| `llm` | Required | Semantic scoring via `runtime/SELF-MEASURE.md`. |
| `hybrid` | Required | Runs both backends; report contains `mechanical`, `llm`, and `final`. |
| `auto` | Optional | `hybrid` with credentials, `mechanical` without. **(Default.)** |

## 3. Measure without credentials (mechanical mode)

No API key needed.

```bash
git clone https://github.com/usurobor/tsc.git && cd tsc

# Score files directly
coh --mode mechanical --files spec/ --output .tsc/

# Score a named target
coh --mode mechanical --target spec --registry targets/registry.tsc
```

## 4. Measure with LLM credentials

```bash
export LLM_PROVIDER=anthropic          # or: openai
export LLM_MODEL=claude-sonnet-4-20250514       # or: gpt-4o
export LLM_API_KEY=sk-ant-your-key

# Hybrid (structural + semantic — recommended when credentials available)
coh --mode hybrid --target spec --registry targets/registry.tsc

# LLM-only
coh --mode llm --target spec --registry targets/registry.tsc

# Auto (default — picks hybrid or mechanical based on credential presence)
coh --target spec --registry targets/registry.tsc
```

<details>
<summary>Using OpenAI instead?</summary>

```bash
export LLM_PROVIDER=openai
export LLM_MODEL=gpt-4o
export LLM_API_KEY=sk-your-key
```
</details>

## 5. Direct file input

Use `--files` to measure arbitrary file sets without a target manifest:

```bash
coh --mode mechanical --files docs/**/*.md --files README.md
coh --mode mechanical --files spec/
```

`--files` and `--target` use the same bundle model. Both produce the same
content hashes and report shape.

## 6. Measure your own files (named target)

Create a target manifest (`my-target.tsc`):

```toml
format = "tsc-target/0.1"
name = "my-project"
kind = "aggregate"
description = "My project's documentation surface."

include = [
  "docs/**/*.md",
  "README.md"
]

exclude = [
  "node_modules/**"
]
```

Add it to a registry (`my-registry.tsc`):

```toml
format = "tsc-target-registry/0.1"
default_target = "my-project"

[target.my-project]
manifest = "my-target.tsc"
```

Run it:

```bash
coh \
  --mode auto \
  --target my-project \
  --registry my-registry.tsc
```

## 7. Read the output

Every report contains triadic scores:

| Axis | What it measures |
|------|-----------------|
| **α** (pattern) | Internal structural consistency — does repeated sampling yield stable structure? |
| **β** (relation) | Alignment between parts — do the pieces fit together? |
| **γ** (process) | Evolution stability — does the system change consistently? |

**C_Σ** is the aggregate, computed as the geometric mean of the three axes. Reports emit two canonical forms under `provenance`:

- `provenance.aggregate_math.C_sigma_math = (s_α · s_β · s_γ)^(1/3)` — the mathematical aggregate; zero if any component is zero.
- `provenance.aggregate_numeric.C_sigma_num = (max(s_α, ε) · max(s_β, ε) · max(s_γ, ε))^(1/3)` — the numerical aggregate used for verdicts; floors each component at `ε = 10⁻⁵`. Equals `C_sigma_math` whenever every component is at or above `ε`.

There is no flat top-level `c_sigma` field — the aggregate facts live only under `provenance`. A `C_sigma_num ≥ 0.80` is the rough "holds together as one coherent system" band.

Every report includes a `mode` field. Hybrid reports add `mechanical`, `llm`, and `final` sub-objects:

```json
{
  "mode": "hybrid",
  "schema_version": "v3.2.0",
  "alpha": 0.85,
  "beta":  0.78,
  "gamma": 0.72,
  "bottleneck_axis": "gamma",
  "provenance": {
    "aggregate_math":    { "C_sigma_math": 0.7807, "zero_component_present": false },
    "aggregate_numeric": { "C_sigma_num":  0.7807, "epsilon": 1e-5, "numeric_floor_applied": false }
  },
  "mechanical": { "alpha": 0.81, "evidence_kind": "structural-proxy", "...": "..." },
  "llm":        { "alpha": 0.85, "evidence_kind": "semantic-judgment", "...": "..." },
  "final":      { "source": "llm", "alpha": 0.85, "...": "..." }
}
```

Read the aggregate from `provenance.aggregate_numeric.C_sigma_num`:

```bash
cat .tsc/tsc-spec-*.json | python3 -c 'import json,sys; r=json.load(sys.stdin); print(r["provenance"]["aggregate_numeric"]["C_sigma_num"])'
```

Pretty-print a full report:

```bash
cat .tsc/tsc-spec-*.json | python3 -m json.tool
```

## 8. Run katas (smoke test / regression anchors)

Katas are curated inputs with known expected outcomes. Use them to verify your
engine installation or detect regressions after changes.

```bash
# Phase 1 — positive control (well-structured doc, C_sigma_num ≥ 0.87)
coh --kata 01-glider --mode mechanical

# Phase 1 — negative control (incoherent doc, C_sigma_num ≤ 0.74)
coh --kata 02-random-soup --mode mechanical

# Phase 2 — comparative (verifies glider ranks above random-soup)
coh --kata 03-comparative --mode mechanical

# Phase 2 — cross-domain philosophical (mechanical mode; documents the
# upper limit — mech scorer over-rates well-formatted prose)
coh --kata 04-philosophical --mode mechanical

# Phase 2 — multi-file adversarial (high surface regularity, contradictory
# semantics; mech scorer should correctly fail)
coh --kata 05-adversarial --mode mechanical

# Run all katas via CI script
bash scripts/run-katas.sh
```

Each command exits 0 when the engine correctly meets the kata's expected outcome,
non-zero otherwise. See [katas/README.md](katas/README.md) for the framework
and `kata.toml` schema (including the Phase 2 `[[components]]` / `ranking`
extension exercised by kata-03).

## What's next

- [Operator manual](docs/beta/guides/OPERATOR-MANUAL.md) — configuration, targets, troubleshooting
- [Kata framework](katas/README.md) — pedagogical / regression inputs with known expected outcomes
- [Theory](spec/) — the formal triadic coherence model
- [Architecture](ARCHITECTURE.md) — how the engine works
