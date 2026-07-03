# Targets

This directory defines the named TSC targets.

A target is an explicit declaration of:
- what is being measured
- which files belong to that surface
- which files do not
- what kind of target it is

Current targets:

- `spec` — theory surface
- `engine` — implementation surface
- `repo` — aggregate repository surface
- `methodology` — the 1st coherence methodology (self-measurement) as a
  measurable corpus
- `cm-of-cms` — the 0th coherence methodology (the CM of CMs) as a
  measurable corpus, including the calibration commons

## Authority

- `targets/registry.tsc` is the target registry
- `targets/*.tsc` define the target manifests

The target model matters because theory, implementation, and aggregate repo state should not collapse into one ambiguous self-score.
