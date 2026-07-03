---
name: fixture-bad-signal
description: >-
  Measurement skill declaring a signal code the engine does not compute
  (negative fixture for the signal-in-engine cross-check).
governing_question: Does a declared-but-nonexistent signal code fail validation?
artifact_class: measurement
scope: repo
kata_surface: none
triggers:
  - fixture
inputs:
  - none
outputs:
  - none
self_measure:
  command: coh-self
  registry: targets/registry.tsc
  targets:
    - spec
  cross_target: false
  instruction: runtime/SELF-MEASURE.md
  output_root: .tsc/self
  default_mode: mechanical
  consistency:
    mechanical: identical
    llm_repeats: 3
    llm_spread: max abs pairwise diff over numeric contract fields, barrier-mapped
  mechanical:
    backend: engine/ocaml/lib/mechanical_scoring.ml
    determinism: fixture
    signals:
      alpha:
        - alpha.nonexistent_signal
      beta: []
      gamma: []
  llm:
    estimates:
      - delta_alpha_beta
    must_not:
      - fixture
    validation: fixture
    providers:
      local: fixture
      ci: fixture
    ci_prompt: fixture
  render:
    command_out: scripts/coh-self
    workflow_out: .github/workflows/tsc-self-measure.yml
  ledger:
    path: .tsc/COHERENCE.md
    cadence: version-increments
    mode: hybrid
    script: scripts/coherence-ledger.sh
    workflow_out: .github/workflows/tsc-coherence-ledger.yml
  ci:
    llm_secret: CLAUDE_CODE_OAUTH_TOKEN
    llm_gate: secret-presence
    permission_intent:
      - contents.read
---

# Fixture

Negative fixture: `alpha.nonexistent_signal` is not computed by the engine
and must fail the `signal-in-engine` cross-check.
