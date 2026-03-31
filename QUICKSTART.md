# QUICKSTART

This guide explains the current runnable path for TSC.

The current implementation is `reference/python/`.

## 1. Install

```bash
python3 -m pip install --upgrade pip
pip install -e ".[dev]"
```

## 2. Run an example

```bash
tsc examples/cellular-automata/glider.md --format text
```

## 3. Run tests

```bash
make test
```

## 4. Measure the repo

```bash
make self-coherence
```

The current orchestrator reads `project.tsc`.

## 5. Read next

- `README.md` — repo overview
- `ARCHITECTURE.md` — theory, targets, verifier
- `project.tsc` — live config
- `targets/` — named target declarations
- `spec/` — canonical theory
