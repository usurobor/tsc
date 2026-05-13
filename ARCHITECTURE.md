# TSC Architecture

TSC has three layers:

- **theory**
- **targets**
- **verifier**

## Theory

The theory lives in `spec/`.

It defines:

- what TSC is
- what α / β / γ mean
- what witnesses and invariants are
- what a target is

Theory is canonical.

## Targets

A target is an explicit declaration of what TSC measures.

Current target surfaces are:

- `spec`
- `engine`
- `repo`

The target model lives in:

- `targets/registry.tsc` — target registry
- `targets/*.tsc` — target manifests

## Katas

Katas are pedagogical and regression inputs with declared expected outcomes.

**Katas** differ from **targets** in purpose and audience:

| | Targets | Katas |
|---|---|---|
| Purpose | Project-internal corpora (spec, engine, repo) | Pedagogical/regression inputs |
| Location | `targets/` | `katas/` |
| Audience | Continuous measurement of the project itself | New implementors; regression anchors |
| Runner flag | `--target <name>` | `--kata <id>` |
| Schema | `targets/*.tsc` (TOML manifests) | `katas/*/kata.toml` (TOML manifests) |
| Expected outcome | None declared | `expected.verdict + expected.score_range` in `kata.toml` |

Both targets and katas use the same engine bundle model and scoring pipeline.
The difference is that katas carry declared expectations, enabling pass/fail
verdicts against curated inputs.

The kata framework is documented in [katas/README.md](katas/README.md).

Kata runner invocation:

```bash
coh --kata 01-glider --mode mechanical   # exit 0 on match, 1 on mismatch
```

## Verifier

The verifier is the executable layer.

The canonical implementation is:

- `engine/ocaml/` — OCaml engine

The engine has one shared pipeline:

1. Resolve input (named target or direct file globs)
2. Build deterministic bundle (same model for both inputs)
3. Choose scoring backend based on `--mode`
4. Compute result
5. Validate and write report

### Scoring modes

| Mode | Backend | Credentials |
|------|---------|-------------|
| `mechanical` | `mechanical_scoring.ml` — deterministic structural proxies | None |
| `llm` | `prompt.ml` + LLM provider via `runtime/SELF-MEASURE.md` | Required |
| `hybrid` | Both backends; `hybrid_scoring.ml` combines results | Required |
| `auto` | Resolves to `hybrid` when credentials present, else `mechanical` | Optional |

**Mechanical mode** scores structural coherence proxies for α, β, γ across twelve signals. It does not call an LLM, perform network I/O, or parse Markdown into a semantic AST. Determinism guarantee: identical bundle + config → identical result.

**LLM mode** sends the bundle to the configured provider using the instruction in `runtime/SELF-MEASURE.md`. This is the semantic scoring path.

**Hybrid mode** runs both backends on the same bundle. Both results are preserved in the report. The `final` sub-object names which backend authored the final adjudication. LLM is semantic authority; `agreement` is reported when both backends agree within threshold.

### Direct file input

`--files <glob>` bypasses named targets. Both `--files` and `--target` produce the same `Bundle.t` shape — same content hashes, same ordering, same metadata. Direct file input restores offline/CI measurement without credentials.

### Report schema

Every report carries the canonical v3.2 fields:

```json
{
  "mode": "mechanical | llm | hybrid",
  "schema_version": "v3.2.0",
  "target": "spec | null",
  "alpha": 0.0,
  "beta":  0.0,
  "gamma": 0.0,
  "c_sigma_math": 0.0,
  "c_sigma_num":  0.0,
  "zero_component_present": false,
  "numeric_floor_applied":  false,
  "bottleneck_axis": "alpha | beta | gamma",
  "provenance": { /* canonical v3.2 provenance bundle */ }
}
```

`c_sigma_math` and `c_sigma_num` are the canonical geometric aggregates from spec [tsc-core.md](spec/tsc-core.md) §5. They coincide whenever every component is at least ε; otherwise `numeric_floor_applied` is true and `c_sigma_math` is dragged toward zero. `zero_component_present` is true when any component is exactly zero — in that case `c_sigma_math = 0` regardless of `c_sigma_num`.

Hybrid reports add `mechanical`, `llm`, and `final` sub-objects, each carrying the same canonical aggregate fields. The schema fixtures live at `engine/ocaml/test/fixtures/report.schema.json` and `provenance_v3_2_0.schema.json`.

The engine does not parse Markdown semantically. Files are raw text.

## Generated state

Generated measurement output belongs in `.tsc/`.

Canonical sources remain:

- `spec/`
- `targets/`
- `engine/ocaml/`
- `runtime/SELF-MEASURE.md`

Python is retired as a live engine. OCaml is the canonical implementation.

## Repo map

```text
/spec/                    canonical theory
/engine/ocaml/            canonical implementation
  lib/mechanical_scoring  deterministic structural backend
  lib/hybrid_scoring      backend combiner (pure)
  lib/bundle              shared bundle model
  lib/kata                kata manifest parser
  bin/main.ml             CLI entrypoint (--mode, --files, --target, --kata)
/runtime/                 scoring instruction (SELF-MEASURE.md)
/targets/                 named target declarations (project-internal corpora)
/katas/                   kata framework (pedagogical/regression inputs)
  README.md               framework docs + kata.toml schema
  01-glider/              positive control kata
  02-random-soup/         negative control kata
/docs/                    documentation tree (α/β/γ)
/examples/                runnable examples
/tests/                   conformance and implementation tests
/.tsc/                    generated measurement output
```
