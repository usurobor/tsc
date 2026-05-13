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

**C_Σ** is the canonical v3.2 geometric aggregate (spec [tsc-core.md](spec/tsc-core.md) §5). Reports carry two forms:

- `c_sigma_math = (s_α · s_β · s_γ)^(1/3)` — strict; collapses to 0 if any component is exactly 0 (`zero_component_present: true`).
- `c_sigma_num  = exp((1/3) · Σ ln(max(sᵢ, ε)))` — ε-floored; used for thresholding (`numeric_floor_applied` flags when the floor was active).

The two coincide whenever every component is ≥ ε. A `c_sigma_num ≥ 0.80` means the corpus holds together as one coherent system.

Every report includes `mode` and `schema_version: "v3.2.0"`. Hybrid reports add `mechanical`, `llm`, and `final` sub-objects, and every report embeds the full canonical v3.2 `provenance` bundle (δ, φ, D, link-Lipschitz constants, gauge witness):

```json
{
  "mode": "hybrid",
  "schema_version": "v3.2.0",
  "alpha": 0.85,
  "beta": 0.78,
  "gamma": 0.72,
  "c_sigma_math": 0.781,
  "c_sigma_num":  0.781,
  "zero_component_present": false,
  "numeric_floor_applied":  false,
  "bottleneck_axis": "gamma",
  "mechanical": { "alpha": 0.81, "c_sigma_num": 0.79, "evidence_kind": "structural-proxy", ... },
  "llm":        { "alpha": 0.85, "c_sigma_num": 0.78, "evidence_kind": "semantic-judgment", ... },
  "final":      { "source": "llm", "alpha": 0.85, "c_sigma_num": 0.78, ... },
  "provenance": { "discrepancy_symbol": "delta", ... }
}
```

```bash
cat .tsc/tsc-spec-*.json | python3 -m json.tool   # pretty-print
```

## 8. Run katas (smoke test / regression anchors)

Katas are curated inputs with known expected outcomes. Use them to verify your
engine installation or detect regressions after changes.

```bash
# Phase 1 — positive control (well-structured doc, C_Σ^num ≥ 0.80)
coh --kata 01-glider --mode mechanical

# Phase 1 — negative control (incoherent doc, C_Σ^num ≤ 0.74)
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
