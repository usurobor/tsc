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

The target model is more important than the current parser syntax.
If the engine evolves, these files define the semantics it should preserve.
