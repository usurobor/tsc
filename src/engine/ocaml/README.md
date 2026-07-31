# TSC Repository-Proxy Engine

`src/engine/ocaml/` builds the `coh` binary for software release `0.12.0`.

It is the canonical executable of the current repository-proxy methodology. It is **not** an implementation of TSC v4.

The exact engine status and immutable semantic pin live in [`CONTRACT.md`](CONTRACT.md); repository-wide version and specification status live in [`STATUS.md`](../../../STATUS.md).

## Current pipeline

1. Resolve a named target, direct file glob, or kata.
2. Build a deterministic content-addressed text bundle.
3. Run `mechanical`, `llm`, `hybrid`, or `auto` mode.
4. Validate provider output when present.
5. Emit the current proxy report.

## Modules

| Module | Current role |
|---|---|
| `lib/coherence.ml` | v3.2-era barrier transform, scalar aggregates, gauge proxy |
| `lib/mechanical_scoring.ml` | Deterministic structural proxies |
| `lib/response_schema.ml` | LLM response validation |
| `lib/hybrid_scoring.ml` | Current proxy-route combination |
| `lib/prompt.ml` | Proxy prompt assembly |
| `lib/bundle.ml` | Bundle hashing and ordering |
| `lib/target_registry.ml` | Target registry and manifest resolution |
| `lib/kata.ml` | Current regression-kata manifests |
| `lib/cross_target.ml` | Current scalar cross-target aggregation |
| `lib/consistency.ml` | Current witness-repeat spread |
| `lib/factorized_beta.ml` | Experimental bounded β adjudication infrastructure |
| `lib/report.ml` | Current JSON and text reports |
| `bin/main.ml` | CLI and current mode dispatch |

## Not implemented

```text
CMSource → CompiledCM
BehaviorContract validation
SET_FINAL / GENERAL_FINAL enforcement
relation-search atlas
candidate sets and fibers
ManifestationReceipt / RelationalAtlas / ContinuationReceipt
failure-persistent lineage
v4 standing and authorization
```

Current scalar outputs do not become v4 receipts by renaming fields.

## Build and test

```bash
opam install . --deps-only --with-test -y
dune build
dune runtest
```

`VERSION` is the software release source. Specification versions are independent.

## Change discipline

Changes preserve the current proxy regression contract unless they explicitly revise that contract and its katas.

A future v4 engine enters through the v4 CM lifecycle and passes [`spec/tsc-conformance.md`](../../../spec/tsc-conformance.md). It must not reinterpret existing proxy reports as v4 evidence.
