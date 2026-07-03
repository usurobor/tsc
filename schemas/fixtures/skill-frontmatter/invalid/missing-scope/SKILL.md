---
name: fixture-missing-scope
description: Frontmatter without the hard-gate scope field (negative fixture).
governing_question: Does a missing hard-gate field fail validation?
artifact_class: skill
kata_surface: none
triggers:
  - fixture
inputs:
  - none
outputs:
  - none
---

# Fixture

Negative fixture: `scope` is missing and must fail `cue vet`.
