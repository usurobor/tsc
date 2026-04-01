# QUICKSTART

This guide explains how to build and run the TSC engine.

The canonical implementation is `engine/ocaml/`.

## 1. Prerequisites

```bash
opam switch create tsc 4.14.1
opam install dune ppx_expect
```

## 2. Build

```bash
cd engine/ocaml
dune build
```

## 3. Run a measurement

Set provider credentials:

```bash
export TSC_PROVIDER=anthropic
export TSC_MODEL=claude-sonnet-4-20250514
export TSC_API_KEY=your-key-here
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
