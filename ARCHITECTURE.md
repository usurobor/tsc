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

The engine resolves named targets from `targets/registry.tsc`, builds raw file bundles, sends them to an LLM with the scoring instruction in `runtime/SELF-MEASURE.md`, validates structured output, and writes reports.

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
/engine/ocaml/      canonical implementation
/runtime/           scoring instruction
/examples/          runnable examples
/tests/             conformance and implementation tests
/targets/           named target declarations
/.tsc/              generated measurement output
```
