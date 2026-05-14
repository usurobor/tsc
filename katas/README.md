# Katas — tsc

[![katas](https://github.com/usurobor/tsc/actions/workflows/katas.yml/badge.svg?branch=main)](https://github.com/usurobor/tsc/actions/workflows/katas.yml)

This directory holds kata definitions for the tsc engine. Each kata lives in its own subdirectory with a `kata.toml` manifest.

The kata runner (`coh --kata`) is provided by tsc #33 (kata framework issue). This directory and `scripts/run-katas.sh` are infrastructure for that runner — C.AC3 of cnos #344 Cycle C satisfies tsc #33 AC1/AC2 by providing the directory layout and CI wiring.

## Directory layout

```
katas/
  {kata-id}/
    kata.toml          — manifest (schema below)
    input/             — input files (referenced by kata.toml [input].files
                         or by per-component [[components]].files entries)
    expected/          — expected output files (if applicable)
```

Ordering convention: kata IDs are short lowercase hyphen-separated names. Dependency ordering is declared in `prerequisites` rather than by directory name sort order.

### Current katas

| ID | Phase | Difficulty | Mode | Verdict | Purpose |
|---|---|---|---|---|---|
| `01-glider` | 1 | 1 | mechanical | pass | Positive control — well-structured cellular-automata document |
| `02-random-soup` | 1 | 1 | mechanical | fail | Negative control — incoherent document, broken links, version drift |
| `03-comparative` | 2 | 2 | mechanical | pass (ranking) | Comparative — verifies glider ranks above random-soup |
| `04-philosophical` | 2 | 3 | mechanical | fail | Cross-domain — natural-language philosophical text; documents the limit of mechanical scoring |
| `05-adversarial` | 2 | 4 | mechanical | fail | Adversarial — multi-file high-surface-regularity / low-semantic-coherence trap |

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
# Bounds apply to provenance.aggregate_numeric.C_sigma_num (geometric,
# canonical v3.2 — see katas/*/kata.toml [baseline] for v0.10.0 cutover
# provenance). There is no flat c_sigma field.
min = 0.7                        # minimum C_sigma_num (for pass verdicts)
max = 0.4                        # maximum C_sigma_num (for fail verdicts)

bottleneck_axis = "coherence"    # optional; which axis limits the score

# v0.10.0 (cycle #54) extension — per-kata baseline provenance.
# Each kata records a [baseline] block (or per-component baselines for
# comparative katas) with: baseline_engine_commit, baseline_engine_version,
# baseline_command, mode, config_hash, input_file_hashes, α, β, γ,
# c_sigma_math, c_sigma_num, zero_component_present, numeric_floor_applied,
# rationale_category. See any of katas/*/kata.toml for the schema in use.
# This block is informational only — the runner does not consult it.

# Phase 2 (cycle #34) extension — comparative katas.
# A kata with [[components]] is scored once per component. The pass-criterion
# switches from a single-bundle score_range to expected.ranking ordering.
# Phase 1 katas omit this section and continue to work unchanged.

[[components]]
id    = "glider"
files = ["input/glider/glider.md"]

[[components]]
id    = "random-soup"
files = ["input/random-soup/random-soup.md"]

[expected]
verdict = "pass"
# Component ids ordered by expected C_Σ, highest first. Comparative-kata
# pass-criterion = (observed-ranking == ranking). The runner emits
# ranking_correct: true/false in the result JSON.
ranking = ["glider", "random-soup"]
```

### Field reference

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Unique kata identifier; must match the containing directory name |
| `difficulty` | integer 1–5 | yes | 1=basic, 5=advanced; used for ordering and CI skip thresholds |
| `prerequisites` | string[] | no | Kata IDs that must pass before this kata is attempted |
| `mode` | string | yes | `mechanical` — deterministic grading; `llm` — LLM-evaluated; `hybrid` — both; `auto` — runner chooses |
| `description` | string | yes | One-line purpose statement for CI output and documentation |
| `[input].files` | string[] | no | Input file paths relative to the kata directory (single-bundle katas) |
| `[[components]]` | array of tables | no | Phase 2 — per-component sub-bundles for comparative katas (cycle #34) |
| `[[components]].id` | string | yes inside component | Component identifier (referenced from `[expected].ranking`) |
| `[[components]].files` | string[] | yes inside component | Component input file paths relative to the kata directory |
| `[expected].verdict` | string | yes | Expected outcome: `"pass"` or `"fail"` |
| `[expected].ranking` | string[] | for comparative katas | Component ids ordered highest `C_sigma_num` first; runner asserts observed ranking matches |
| `[expected.score_range].min` | float | for pass | Minimum acceptable `C_sigma_num` (0.0–1.0; geometric, canonical v3.2) |
| `[expected.score_range].max` | float | for fail | Maximum `C_sigma_num` for a fail verdict (0.0–1.0; geometric) |
| `bottleneck_axis` | string | no | Axis that most limits the score; used for diagnostic output |
| `[baseline]` | table | no | v0.10.0 (cycle #54) baseline provenance block — `baseline_engine_commit`, `baseline_engine_version`, `baseline_command`, `mode`, `config_hash`, `input_file_hashes`, α, β, γ, `c_sigma_math`, `c_sigma_num`, `zero_component_present`, `numeric_floor_applied`, `rationale_category` (`aggregate-correction`/`scorer-improvement`/`frontier-tightening`). Informational; runner does not consult it. |

### Comparative katas (Phase 2)

A kata is *comparative* iff its `kata.toml` declares one or more
`[[components]]` entries. The runner switches behavior:

- **Single-bundle (Phase 1):** scores `[input].files` as one bundle; pass-criterion is `provenance.aggregate_numeric.C_sigma_num` within `[expected.score_range]` (modulated by `verdict`).
- **Comparative (Phase 2):** scores each `[[components]]` entry as its own bundle; pass-criterion is the *observed ranking* of per-component `C_sigma_num` matching `[expected].ranking` (highest → lowest). The runner emits `ranking_correct: bool` in the result JSON in place of `kata_pass`.

Single-bundle katas (`01-glider`, `02-random-soup`, `04-philosophical`, `05-adversarial`) omit `[[components]]` and use the Phase 1 path. Only `03-comparative` uses the new comparative path in cycle #34.

### Field index (schema oracle)

Quick reference for the `kata.toml` fields, each with type and example:

- `id` — string; example: `"01-glider"`. Unique kata identifier; matches directory name.
- `difficulty` — integer 1–5; example: `1`. Ordering key; 1=basic, 5=advanced.
- `prerequisites` — string[]; example: `["01-glider"]`. Kata IDs that must pass first.
- `tests` — string[]; example: `["mechanical_basic", "threshold_discrimination"]`. Surfaces exercised.
- `mode` — string; example: `"mechanical"`. Engine mode for this kata.
- `description` — string; example: `"Positive control..."`. One-line purpose statement.
- `input.files` — string[]; example: `["input/glider.md"]`. Input files relative to kata dir (single-bundle katas).
- `components` — array of tables; example: `[{ id = "glider", files = ["input/glider/glider.md"] }, ...]`. Per-component sub-bundles for comparative katas (Phase 2; see §"Comparative katas").
- `expected.verdict` — string; example: `"pass"`. Expected outcome: `pass` or `fail`.
- `expected.ranking` — string[]; example: `["glider", "random-soup"]`. Comparative-kata ranking, highest C_Σ first (Phase 2).
- `expected.score_range` — object; example: `{ min = 0.87, max = 1.0 }`. C_Σ bounds (single-bundle katas).
- `expected.bottleneck_axis` — string; example: `"gamma"`. Optional axis diagnostic.

## Runner invocation

```bash
# Run a single kata
coh --kata {kata-id} --mode mechanical

# Run all katas via CI script
bash scripts/run-katas.sh
```

The CI script (`scripts/run-katas.sh`) iterates all `katas/*/kata.toml` files, runs each kata, and exits non-zero if any kata fails. It exits 0 gracefully when no katas are defined.

## Where to find kata results

Two surfaces from `.github/workflows/katas.yml` (cycle #38):

- **Per-run JSON artifact.** Every run uploads `.kata-results/<id>.json` (one file per kata; engine's full `--kata` output) as the artifact `kata-results-<sha>` (pre-merge build-from-HEAD job) or `kata-results-published-<tag>-<run_id>` (published-binary job). Retention: 90 days. Download via the run page's *Artifacts* panel or the `gh run download` CLI.
- **Step-summary table.** Each run's *Summary* tab renders a markdown table with one row per kata: `| Kata | Verdict | C_Σ | Range | Status |`. Visible inline on PR check pages without click-through.

The published-binary job (release / weekly cron / manual dispatch) writes the same row schema under a section titled with the release tag.

## Adding a new kata

1. Create `katas/{kata-id}/kata.toml` using the schema above.
2. Add input files under `katas/{kata-id}/input/`.
3. Push to a `cycle/**` branch — CI will pick up the new kata automatically.
4. Check kata-check job output in GitHub Actions for pass/fail.

## Relationship to tsc #33

tsc #33 (kata framework) provides the `coh --kata` runner implementation. This directory layout and CI wiring (C.AC3, cnos #344) is the infrastructure side; #33 is the engine side. Once #33 ships, katas added here will run automatically in CI.
