# Targets

A target declares what TSC measures: which files, what kind of surface, what to exclude.

Current targets:

- `spec` — theory
- `engine` — implementation
- `repo` — aggregate

`registry.tsc` maps target names to manifests.

## Authority

The current orchestrator reads `project.tsc` in the repo root. These manifests and `registry.tsc` are draft declarations. When the orchestrator supports `tsc-target-registry/0.1`, `registry.tsc` replaces `project.tsc`.
