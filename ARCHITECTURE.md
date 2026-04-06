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

## Verifier

The verifier is the executable layer.

The canonical implementation is:

- `engine/ocaml/` — OCaml engine

The engine resolves named targets from `targets/registry.tsc` (or accepts direct file paths via `--files`), builds deterministic file bundles, and scores them using one of three backends:

- **mechanical** — deterministic structural scoring (no network, no credentials)
- **llm** — semantic scoring via `runtime/SELF-MEASURE.md`
- **hybrid** — both backends, preserving both results

Default mode is **auto**: hybrid if LLM credentials are present, mechanical otherwise.

The engine does not parse Markdown semantically. Files are raw text.

## Generated state

Generated measurement output belongs in `.tsc/`.

Canonical sources remain:

- `spec/`
- `targets/`
- `engine/ocaml/`
- `runtime/SELF-MEASURE.md`

## Repo map

```text
/spec/              canonical theory
/engine/ocaml/      canonical implementation (mechanical + LLM + hybrid backends)
/runtime/           LLM scoring instruction
/scripts/           release automation (stamp, check, release)
/targets/           named target declarations
/docs/              documentation tree (α/β/γ)
/examples/          runnable examples
/tests/             conformance and implementation tests
/.tsc/              generated measurement output
```
