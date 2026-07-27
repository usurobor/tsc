# Current Proxy Katas

Katas are executable regression fixtures for the current `coh` repository-proxy engine.

They pin software release `0.12.0`. They are not TSC v4 conformance fixtures and do not establish the general coherence construct.

## Current set

| ID | Current proxy purpose |
|---|---|
| `01-glider` | A well-structured cellular-automata document receives the expected mechanical proxy result |
| `02-random-soup` | A deliberately inconsistent document receives the expected mechanical proxy result |
| `03-comparative` | The proxy ranks the structured document above the inconsistent document |
| `04-philosophical` | Characterizes a known false-positive boundary |
| `05-adversarial` | Tests contradictory multi-file material with high surface regularity |

The Game of Life names are subject matter for the regression documents. The runner does not execute B3/S23 or test cellular dynamics.

## Layout

```text
katas/<id>/
  kata.toml
  input/
  expected/
```

Score ranges apply only to the frozen proxy contract named by the kata baseline. They are not portable v4 thresholds.

## Run

```bash
coh --kata 01-glider --mode mechanical
bash scripts/run-katas.sh
```

## v4 conformance

Normative proof obligations live in [`../spec/tsc-conformance.md`](../spec/tsc-conformance.md). Domain conformance fixtures live in [`../conformance/`](../conformance/README.md).

A v4 fixture provides a generated model, independent oracle, positive and negative cases, declared search strength, and expected categorical result. A kata does not acquire that role by being renamed.
