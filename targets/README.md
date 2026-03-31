# Targets

This directory contains named TSC measurement targets.

A target is an explicit declaration of:
- what is being measured
- which files belong to that surface
- which files do not
- what kind of target it is

These manifests exist to prevent one repo-wide self-score from blurring distinct questions.

Current targets:

- `spec` — theory only
- `engine` — implementation only
- `repo` — aggregate repository target

## Status

These target manifests and `registry.tsc` are **draft declarations**. They define the intended semantics of the named-target model but are not yet consumed by the current Python orchestrator.

The live measurement config is still `project.tsc` in the repo root (repeated `[markdown]` sections). When the orchestrator is updated to support `tsc-target-registry/0.1`, `registry.tsc` will replace `project.tsc` as the authoritative config surface.

The target model is more important than the current parser syntax. If the engine evolves, these files define the semantics it should preserve.
