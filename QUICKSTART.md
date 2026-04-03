# QUICKSTART

This guide explains how to build and run the TSC engine.

The canonical implementation is `engine/ocaml/`.

## 1. Prerequisites

```bash
opam switch create tsc 5.2.0
```

## 2. Build

```bash
cd engine/ocaml
opam install . --deps-only --with-test -y
dune build
```

## 3. Run a measurement

Set provider credentials:

```bash
export LLM_PROVIDER=anthropic
export LLM_MODEL=claude-sonnet-4-20250514
export LLM_API_KEY=your-key-here
```

Run:

```bash
tsc-engine measure --target spec --root ../..
```

## 4. Available targets

- `spec` — theory surface
- `engine` — implementation surface
- `repo` — aggregate repository surface

## 5. Read next

- `README.md` — repo charter
- `ARCHITECTURE.md` — theory, targets, verifier
- `targets/` — named target declarations
- `runtime/SELF-MEASURE.md` — scoring instruction
- `spec/` — canonical theory
