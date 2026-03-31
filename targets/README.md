# Targets

Each `.tsc` file in this directory declares a measurement target — what files belong to it, what kind of surface it represents, and what to exclude.

`registry.tsc` maps target names to their manifests.

## Status

These manifests are draft declarations. The current orchestrator reads `project.tsc` in the repo root. When the orchestrator supports `tsc-target-registry/0.1`, `registry.tsc` replaces `project.tsc`.
