# Quick Start

Measure the coherence of any text corpus in under 2 minutes.

## 1. Install

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/tsc/main/install.sh | sh
```

## 2. Configure

TSC uses an LLM to score coherence. Set your provider credentials:

```bash
export LLM_PROVIDER=anthropic          # or: openai
export LLM_MODEL=claude-sonnet-4-20250514       # or: gpt-4o
export LLM_API_KEY=sk-ant-your-key     # your API key
```

<details>
<summary>Using OpenAI instead?</summary>

```bash
export LLM_PROVIDER=openai
export LLM_MODEL=gpt-4o
export LLM_API_KEY=sk-your-key
```
</details>

## 3. Measure something

### Measure this repo's theory surface

```bash
git clone https://github.com/usurobor/tsc.git && cd tsc

tsc \
  --target spec \
  --registry targets/registry.tsc \
  --instruction runtime/SELF-MEASURE.md \
  --output report.json
```

### Measure your own files

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
tsc \
  --target my-project \
  --registry my-registry.tsc \
  --instruction runtime/SELF-MEASURE.md \
  --output report.json
```

> **Note:** The `--instruction` file tells the LLM how to score. You can use `runtime/SELF-MEASURE.md` from this repo as a starting point, or write your own.

## 4. Read the output

The report contains triadic scores:

| Axis | What it measures |
|------|-----------------|
| **α** (pattern) | Internal structural consistency — does repeated sampling yield stable structure? |
| **β** (relation) | Alignment between parts — do the pieces fit together? |
| **γ** (process) | Evolution stability — does the system change consistently? |

**C_Σ** is the aggregate: `(s_α · s_β · s_γ)^(1/3)`. A score ≥ 0.80 means the corpus holds together as one coherent system.

```bash
cat report.json | python3 -m json.tool   # pretty-print
```

## What's next

- [Operator manual](docs/beta/guides/OPERATOR-MANUAL.md) — configuration, targets, troubleshooting
- [Theory](spec/) — the formal triadic coherence model
- [Architecture](ARCHITECTURE.md) — how the engine works
