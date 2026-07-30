# Targets

This directory defines the named TSC targets.

A target is an explicit declaration of:
- what is being measured
- which files belong to that surface
- which files do not
- what kind of target it is

Current targets:

- `spec` — theory surface
- `engine` — current repository-proxy implementation surface (includes
  `src/engine/ocaml/CONTRACT.md`, the immutable v3.2.2 semantic pin)
- `repo` — aggregate repository surface, spanning theory, implementation,
  and integration (status, conformance fixtures, schemas, illustrations)
- `methodology` — the 1st coherence methodology (self-measurement) as a
  measurable corpus
- `cm-of-cms` — the 0th coherence methodology (the CM of CMs) as a
  measurable corpus, including the calibration commons

## Authority

- `targets/registry.tsc` is the target registry
- `targets/*.tsc` define the target manifests

The target model matters because theory, implementation, and aggregate repo state should not collapse into one ambiguous self-score.
