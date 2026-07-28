# TSC 4.1 Conformance Fixtures

Conformance fixtures implement the proof obligations in `spec/tsc-conformance.md`.

The specification owns requirement IDs and proof meaning. Each fixture owns one reproducible domain instance, its generator, oracle, positive and negative cases, and raw evidence.

## Status

```text
specified
  contract and cases exist; no conformance result

implemented
  generator and oracle run; independent verification pending

verified
  evidence reproduced and independently reviewed
```

Only `verified` fixtures contribute conformance standing.

## Registry

`registry.toml` lists fixture packages. Every `fixture.toml` validates against `schemas/conformance-fixture.cue`.

## Initial fixtures

- `foundation-v4` — foundation, receipt, lifecycle, comparison, and lineage proof pairs.
- `gol-ascent-0` — exact Game of Life cases for underdetermination, refinement, lift, law violation, and lawful termination.
- `stochastic-law-v4` — law-relative stochastic compatibility and violation.

Domain fixtures live here so the normative theory does not hard-code B3/S23 or one stochastic law.

## Polar-expression fixtures

- `polar-syntax-v4-1` — parser, ordered AST, nesting, reversal, grounding, frame, and conservative-embedding proof pairs. This fixture is independent of the v4 runtime.
- `polar-realization-v4-1` — non-vacuity, candidate-fiber status, β receipt retention, runtime refusal, comparison, and lift proof pairs. This fixture depends on the v4 CM runtime.
