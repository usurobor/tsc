# QUICKSTART

This guide explains the current runnable path for TSC.

Today, that path is the Python implementation in `reference/python/`.

If you want to understand the repo before running it, read:

1. `README.md`
2. `ARCHITECTURE.md`

If you want to run TSC now, continue here.

---

## 1. Install

```bash
python3 -m pip install --upgrade pip
pip install -e ".[dev]"
```

This exposes the current `tsc` CLI.

---

## 2. Run an example

```bash
tsc examples/cellular-automata/glider.md --format text
```

This exercises the current parser and controller path.

---

## 3. Run the test suite

```bash
make test
```

This runs the current implementation and conformance tests.

---

## 4. Measure the repo with the current orchestrator

```bash
make self-coherence
```

The current orchestrator reads `project.tsc`.

---

## 5. Current measurement surfaces

TSC currently works with these repo surfaces:

- `spec/` — canonical theory
- `reference/python/` — current implementation
- `examples/` — runnable example inputs
- `tests/` — implementation and conformance tests
- `project.tsc` — live measurement config
- `targets/` — named target declarations

The named targets in `targets/` define the model the repo is moving toward:

- `spec`
- `engine`
- `repo`

---

## 6. Current implementation status

The current executable implementation is the Python path under `reference/python/`.

The next implementation track is an OCaml engine. The theory and target model stay stable across that change.

---

## 7. What to read next

- `README.md` — repo charter
- `ARCHITECTURE.md` — theory, targets, verifier
- `project.tsc` — live config
- `targets/` — named target declarations
- `spec/` — canonical theory
