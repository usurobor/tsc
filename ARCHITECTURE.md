# TSC Architecture

## Purpose

This document describes the current architecture of the TSC repo.

TSC is organized around three layers:

- **theory**
- **targets**
- **verifier**

These three layers define the repo.

---

## 1. Theory

The theory lives in `spec/`.

This is the canonical definition layer:

- what TSC is
- what α / β / γ mean
- what witnesses and invariants are
- what a target means

If implementation and theory disagree, the theory defines the intended semantics.

---

## 2. Targets

A target is an explicit declaration of what TSC measures.

Current target surfaces are:

- `spec` — canonical theory documents
- `engine` — implementation surfaces
- `repo` — aggregate repository surface

The target model lives in:

- `project.tsc` — live measurement config for the current orchestrator
- `targets/` — named target manifests

`project.tsc` is the live config today. `targets/` defines the target model the repo is converging toward.

---

## 3. Verifier

The verifier is the executable layer.

The current executable path is:

- `reference/python/`

That path exercises the theory, runs examples, and provides the current CLI.

The next implementation track is:

- a canonical OCaml engine

The theory remains independent of implementation language.

---

## 4. Self-measurement

Self-measurement is one target surface inside the repo.

It exists to answer three separate questions:

- is the theory coherent as theory
- is the implementation coherent as implementation
- is the repo coherent as a whole

Those are different measurements. They should stay separated as different targets.

---

## 5. Generated state

Generated measurement output belongs in `.tsc/`.

`.tsc/` holds:

- local measurement output
- reports
- generated history

Canonical sources remain:

- `spec/` for theory
- `project.tsc` for live measurement config
- `targets/` for named target declarations

---

## 6. Current development direction

The current architectural direction is:

1. keep the repo charter explicit
2. keep targets explicit
3. keep the Python path usable as the current implementation
4. add the OCaml engine as the next canonical implementation track
5. keep file moves secondary to semantic clarity

That keeps the repo stable while the target model and verifier mature.

---

## 7. Repo map

```text
/spec/              canonical theory
/reference/python/  current implementation
/examples/          runnable examples
/tests/             conformance and implementation tests
/project.tsc        live measurement config
/targets/           named target declarations
/.tsc/              generated measurement output
```
