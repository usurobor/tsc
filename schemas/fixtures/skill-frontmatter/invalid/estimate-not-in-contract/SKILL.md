---
name: fixture-estimate-not-in-contract
description: >-
  Measurement skill declaring an estimate field that appears in the
  instruction's prose but not in its JSON output contract (negative
  fixture for the estimate-in-contract exact-set check).
governing_question: Does a prose-only field mention fail the contract check?
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
  instruction: schemas/fixtures/skill-frontmatter/invalid/estimate-not-in-contract/instruction.md
  output_root: .tsc/self
  default_mode: mechanical
  consistency:
    mechanical: identical
    llm_repeats: 3
    llm_spread: max abs pairwise diff over numeric contract fields, barrier-mapped
  mechanical:
    backend: src/engine/ocaml/lib/mechanical_scoring.ml
    determinism: fixture
    signals:
      alpha:
        - alpha.terminology_consistency
      beta: []
      gamma: []
  llm:
    estimates:
      - target
      - confidence
      - summary
      - made_up_field
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

Negative fixture: `made_up_field` is mentioned in the instruction's prose
but absent from its JSON output contract; the exact-set check must fail it.
