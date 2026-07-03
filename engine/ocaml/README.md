# TSC engine (OCaml)

The canonical implementation of the TSC verifier. The binary is `coh`.
Theory lives in `spec/` (canonical); this directory implements it.

## Pipeline

One shared pipeline for every input:

1. Resolve input — named target (`--target` + `--registry`), direct
   globs (`--files`), or kata (`--kata`)
2. Build a deterministic bundle: ordered files, raw text, SHA-256 per file
3. Choose the scoring backend from `--mode`
   (`mechanical` | `llm` | `hybrid` | `auto`)
4. Compute the result
5. Validate and write reports

`coh self` dispatches to the rendered `coh-self` command
(git-style external subcommand); the self-measurement procedure is
declared in `skills/self-measure/SKILL.md`, not here.

## Module map

| Module | Role |
|--------|------|
| [lib/coherence.ml](lib/coherence.ml) | Aggregate math: barrier transform φ, `C_sigma_math` / `C_sigma_num`, gauge witness. The one source of aggregate truth. |
| [lib/mechanical_scoring.ml](lib/mechanical_scoring.ml) | Deterministic structural backend — twelve signals across α/β/γ; no LLM, no network. |
| [lib/response_schema.ml](lib/response_schema.ml) | Witness (LLM) response validation — one funnel for every refusal stage. |
| [lib/hybrid_scoring.ml](lib/hybrid_scoring.ml) | Pure combiner of mechanical + LLM results. |
| [lib/prompt.ml](lib/prompt.ml) | Prompt assembly: scoring instruction + target metadata + bundle. |
| [lib/bundle.ml](lib/bundle.ml) | Shared bundle model (hashing, ordering). |
| [lib/target_registry.ml](lib/target_registry.ml) | `targets/registry.tsc` + manifest parsing, glob expansion. |
| [lib/kata.ml](lib/kata.ml) | `kata.toml` parsing for the kata framework. |
| [lib/cross_target.ml](lib/cross_target.ml) | Cross-target aggregate report (Operational §7.4). |
| [lib/ood.ml](lib/ood.ml) | Out-of-distribution tracking over rolling aggregates. |
| [lib/lipschitz.ml](lib/lipschitz.ml) | Link-Lipschitz constant (Operational §7.1). |
| [lib/report.ml](lib/report.ml) | JSON + text report emission. |
| [lib/types.ml](lib/types.ml) | Shared result types. |
| [bin/main.ml](bin/main.ml) | CLI entrypoint: mode dispatch, external witness route (`--emit-prompt`, `--llm-response`), `coh self` dispatch. |
| [bin/provider.ml](bin/provider.ml) | HTTP provider transport (Anthropic / OpenAI-compatible). |
| [bin/dotenv.ml](bin/dotenv.ml) | `.tsc/.env` credential loading. |

Tests live in [test/](test/); run with `dune runtest`. Fixture schemas:
[test/fixtures/report.schema.json](test/fixtures/report.schema.json),
[test/fixtures/provenance_v3_2_0.schema.json](test/fixtures/provenance_v3_2_0.schema.json).

## Build

```bash
opam install . --deps-only --with-test -y
dune build      # binary: _build/default/bin/main.exe
dune runtest
```

Current engine version: 0.10.0 (see `VERSION` at the repo root — the
single version source; `dune-project` must agree, enforced by
`scripts/check-version-consistency.sh`).

## Change discipline

Release history lives in `CHANGELOG.md` at the repo root; engine releases
are cut by `scripts/release.sh`, which gates on a changelog entry.
Behavioral anchors live in `katas/` — any change to scoring must keep
every kata's declared expectation (`coh --kata <id> --mode mechanical`).

## Known debt

Explicit and bounded; tracked here until closed:

- **Interface coverage.** Only `mechanical_scoring` has a `.mli`; the
  other lib modules expose their internals, so their public surfaces are
  convention rather than compiler-checked. Target: an interface per lib
  module to the standard `mechanical_scoring` sets.
- **Hybrid cross-target.** The engine's cross-target report is
  mechanical-only this cycle; the coherence ledger computes the hybrid
  cross aggregate script-side (same §7.4 geometric mean). Target: extend
  `cross_target` to accept hybrid per-target reports so the engine owns
  that aggregation everywhere.
- **Witness-contract version constant.** The SELF-MEASURE protocol
  version appears as a literal in `bin/main.ml` metadata and as prose in
  the instruction; bumping the protocol requires coordinated edits with
  no compiler error if one is missed. Target: one shared constant
  consumed by prompt metadata and the response validator.
