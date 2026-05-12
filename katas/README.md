# Katas — tsc

[![katas](https://github.com/usurobor/tsc/actions/workflows/katas.yml/badge.svg?branch=main)](https://github.com/usurobor/tsc/actions/workflows/katas.yml)

This directory holds kata definitions for the tsc engine. Each kata lives in its own subdirectory with a `kata.toml` manifest.

The kata runner (`coh --kata`) is provided by tsc #33 (kata framework issue). This directory and `scripts/run-katas.sh` are infrastructure for that runner — C.AC3 of cnos #344 Cycle C satisfies tsc #33 AC1/AC2 by providing the directory layout and CI wiring.

## Directory layout

```
katas/
  {kata-id}/
    kata.toml          — manifest (schema below)
    input/             — input files (referenced by kata.toml [input].files)
    expected/          — expected output files (if applicable)
```

Ordering convention: kata IDs are short lowercase hyphen-separated names. Dependency ordering is declared in `prerequisites` rather than by directory name sort order.

## kata.toml schema

```toml
# Required fields
id           = "string"    # unique kata identifier (matches directory name)
difficulty   = 3           # integer 1–5: 1=basic, 5=advanced
mode         = "mechanical" # mechanical | llm | hybrid | auto
description  = "string"    # one-line kata purpose

# Optional fields
prerequisites = ["other-kata-id"]  # kata IDs that must pass before this one runs

[input]
files = ["input/file.txt"]  # input file paths relative to kata directory

[expected]
verdict       = "pass"           # "pass" | "fail"

[expected.score_range]
min = 0.7                        # minimum C_Σ score (for pass verdicts)
max = 0.4                        # maximum C_Σ score (for fail verdicts)

bottleneck_axis = "coherence"    # optional; which axis limits the score
```

### Field reference

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Unique kata identifier; must match the containing directory name |
| `difficulty` | integer 1–5 | yes | 1=basic, 5=advanced; used for ordering and CI skip thresholds |
| `prerequisites` | string[] | no | Kata IDs that must pass before this kata is attempted |
| `mode` | string | yes | `mechanical` — deterministic grading; `llm` — LLM-evaluated; `hybrid` — both; `auto` — runner chooses |
| `description` | string | yes | One-line purpose statement for CI output and documentation |
| `[input].files` | string[] | no | Input file paths relative to the kata directory |
| `[expected].verdict` | string | yes | Expected outcome: `"pass"` or `"fail"` |
| `[expected.score_range].min` | float | for pass | Minimum acceptable C_Σ score (0.0–1.0) |
| `[expected.score_range].max` | float | for fail | Maximum C_Σ score for a fail verdict |
| `bottleneck_axis` | string | no | Axis that most limits the score; used for diagnostic output |

### Field index (schema oracle)

Quick reference for the 10 `kata.toml` fields, each with type and example:

- `id` — string; example: `"01-glider"`. Unique kata identifier; matches directory name.
- `difficulty` — integer 1–5; example: `1`. Ordering key; 1=basic, 5=advanced.
- `prerequisites` — string[]; example: `["01-glider"]`. Kata IDs that must pass first.
- `tests` — string[]; example: `["mechanical_basic", "threshold_discrimination"]`. Surfaces exercised.
- `mode` — string; example: `"mechanical"`. Engine mode for this kata.
- `description` — string; example: `"Positive control..."`. One-line purpose statement.
- `input.files` — string[]; example: `["input/glider.md"]`. Input files relative to kata dir.
- `expected.verdict` — string; example: `"pass"`. Expected outcome: `pass` or `fail`.
- `expected.score_range` — object; example: `{ min = 0.87, max = 1.0 }`. C_Σ bounds.
- `expected.bottleneck_axis` — string; example: `"gamma"`. Optional axis diagnostic.

## Runner invocation

```bash
# Run a single kata
coh --kata {kata-id} --mode mechanical

# Run all katas via CI script
bash scripts/run-katas.sh
```

The CI script (`scripts/run-katas.sh`) iterates all `katas/*/kata.toml` files, runs each kata, and exits non-zero if any kata fails. It exits 0 gracefully when no katas are defined.

## Adding a new kata

1. Create `katas/{kata-id}/kata.toml` using the schema above.
2. Add input files under `katas/{kata-id}/input/`.
3. Push to a `cycle/**` branch — CI will pick up the new kata automatically.
4. Check kata-check job output in GitHub Actions for pass/fail.

## Relationship to tsc #33

tsc #33 (kata framework) provides the `coh --kata` runner implementation. This directory layout and CI wiring (C.AC3, cnos #344) is the infrastructure side; #33 is the engine side. Once #33 ships, katas added here will run automatically in CI.
