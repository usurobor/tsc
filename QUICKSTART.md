# QUICKSTART

This guide explains the **current executable path** for TSC.

Today that means:
- the theory is canonical
- the Python implementation under `reference/python/` is the active reference path
- the future canonical engine is intended to be OCaml

This guide is therefore about the current reference implementation, not the final implementation identity of the repo.

---

## 1) Install

```bash
python3 -m pip install --upgrade pip
pip install -e ".[dev]"
```

This exposes a `tsc` CLI through the current reference implementation.

---

## 2) Run an example

```bash
tsc examples/cellular-automata/glider.md --format text
```

This exercises the current parser/controller path.

---

## 3) Understand the implementation status

The current implementation should be read as:
- usable
- reference-grade
- not the final canonical engine

Its purpose is to:
- exercise the theory
- validate example handling
- provide a working CLI while the canonical engine direction stabilizes

---

## 4) Target model

TSC is moving toward named targets.

Examples:

```bash
tsc self --target spec
tsc self --target engine
tsc self --target repo
```

These commands do not exist yet in the current CLI. They represent the intended target model that `targets/` is defining. Today, `project.tsc` is still the live measurement config.

---

## 5) Current file structure

```
/spec/              # canonical theory
/reference/python/  # current reference implementation
/examples/          # runnable example inputs
/tests/             # implementation and conformance tests
/runtime/           # runtime adapters (tsc-instructions.md)
/project.tsc        # live measurement config (current orchestrator)
/targets/           # named target manifests (draft, not yet consumed)
```

---

## 6) What to read next

- `README.md` — repo charter
- `ARCHITECTURE.md` — theory + target + verifier architecture
- `project.tsc` — live measurement config
- `targets/` — named target manifests (draft, defines intended model)
