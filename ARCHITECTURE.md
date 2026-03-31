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

- `project.tsc` — live config for the current orchestrator
- `targets/` — named target declarations

## Verifier

The verifier is the executable layer.

The current implementation lives in:

- `reference/python/`

## Generated state

Generated measurement output belongs in `.tsc/`.

Canonical sources remain:

- `spec/`
- `project.tsc`
- `targets/`

## Repo map

```text
/spec/              canonical theory
/reference/python/  current implementation
/examples/          runnable examples
/tests/             conformance and implementation tests
/project.tsc        live measurement config
/targets/           named target declarations
/.tsc/              generated measurement output
```
