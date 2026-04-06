# Quick Start

Measure the coherence of any text corpus in under 2 minutes.

## 1. Install

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/tsc/main/install.sh | sh
```

## 2. Measure something

### Offline — no credentials needed

```bash
git clone https://github.com/usurobor/tsc.git && cd tsc

# Measure this repo's theory surface
coh --mode mechanical --target spec

# Or measure specific files directly
coh --mode mechanical --files docs/*.md README.md
```

### With an LLM — semantic scoring

```bash
export LLM_PROVIDER=anthropic
export LLM_MODEL=claude-sonnet-4-20250514
export LLM_API_KEY=sk-ant-your-key

# Auto mode: hybrid (mechanical + LLM) when credentials present
coh --target spec
```

Or store credentials in `.tsc/.env` (chmod 600):

```bash
mkdir -p .tsc && cat > .tsc/.env <<'EOF'
LLM_PROVIDER=anthropic
LLM_MODEL=claude-sonnet-4-20250514
LLM_API_KEY=sk-ant-your-key
EOF
chmod 600 .tsc/.env
coh --target spec
```

<details>
<summary>Using OpenAI instead?</summary>

```bash
export LLM_PROVIDER=openai
export LLM_MODEL=gpt-4o
export LLM_API_KEY=sk-your-key
```
</details>

## 3. Scoring modes

| Mode | What it does | Needs credentials? |
|------|-------------|-------------------|
| `mechanical` | Deterministic structural scoring | No |
| `llm` | Semantic scoring via LLM | Yes |
| `hybrid` | Both backends, one report | Yes |
| `auto` | Hybrid if credentials present, else mechanical | Optional |

```bash
coh --mode mechanical --target spec   # fast, offline, deterministic
coh --mode llm --target spec          # semantic judgment
coh --mode hybrid --target spec       # both
coh --target spec                     # auto (default)
```

## 4. Create your own target

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
coh --target my-project --registry my-registry.tsc
```

## 5. Read the output

The report contains triadic scores:

| Axis | What it measures |
|------|-----------------|
| **α** (pattern) | Internal structural consistency — does repeated sampling yield stable structure? |
| **β** (relation) | Alignment between parts — do the pieces fit together? |
| **γ** (process) | Evolution stability — does the system change consistently? |

**C_Σ** is the aggregate: `(s_α · s_β · s_γ)^(1/3)`. A score ≥ 0.80 means the corpus holds together as one coherent system.

Reports are written to `.tsc/`:

```bash
cat .tsc/tsc-spec-*-mechanical.json | python3 -m json.tool
```

## What's next

- [Operator manual](docs/beta/guides/OPERATOR-MANUAL.md) — configuration, targets, troubleshooting
- [Theory](spec/) — the formal triadic coherence model
- [Architecture](ARCHITECTURE.md) — how the engine works
