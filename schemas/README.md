# Schemas

CUE schemas for typed Markdown modules in tsc. Convention imported from
cnos (`schemas/` there); adapted to tsc's single-skill scale.

## Layout

- `skill.cue` — schema for `SKILL.md` frontmatter: `#Skill` (base),
  `#CoherenceMethodology` (the comparable contract for a coherence
  methodology — supply your own CM by conforming to it), and
  `#SelfMeasure` (the 1st methodology: tsc's repo CM applied to itself,
  deployed) and `#CMOfCMs` (the 0th: the methodology that measures
  methodologies, itself included).
- `conformance-fixture.cue` — schema for `conformance/**/fixture.toml`:
  `#Fixture` (a v4 conformance fixture) and `#Case` (a single
  positive/negative proof case). It types the fixture id/version/status,
  the requirement IDs, the claim contract, the generator/oracle/
  reproducibility surfaces, and the evidence/verification blocks — with
  status-conditional constraints: a `specified` fixture declares
  `planned_source`/`planned_command` and carries no evidence, an
  `implemented`/`verified` fixture names actual sources and evidence, and
  a `verified` fixture additionally requires a PASS review.
- `fixtures/skill-frontmatter/{valid,invalid}/` — positive/negative
  regression suite for the validator. Each invalid fixture carries a
  `SKILL.expect` sidecar naming the expected diagnostic substring.

## Surface boundary

The CUE schema owns **shape, type, and enum constraints**. Pure; no
filesystem I/O.

The validator script (`scripts/ci/validate-skill-frontmatter.sh`) owns
everything outside that: file discovery, frontmatter extraction, and the
cross-file consistency checks that pin a `measurement` skill to its
sources of truth:

- declared mechanical signal codes must exist in the declared engine
  backend source;
- declared LLM estimate fields must appear in the declared scoring
  instruction;
- declared paths (registry, instruction, backend, render outputs) must
  exist;
- declared targets must resolve in the target registry.

Do not move shape/type/enum rules into the shell, and do not move
discovery/cross-file checks into CUE.

## CI wiring

The `skill-validate` job in `.github/workflows/ci.yml` runs the fixture
self-test, validates every `skills/**/SKILL.md`, and re-renders the
self-measurement artifacts (`scripts/render-self-measure.sh --check`) to
prove the committed rendered surfaces match the skill byte-for-byte.

The `conformance-validate` job in `.github/workflows/ci.yml` runs
`scripts/ci/validate-v4-conformance.sh`, the conformance analogue of the
skill validator. The CUE schema owns shape/type/enum/status-conditional
constraints (`cue vet` of every `conformance/**/fixture.toml`, run when
`cue` is installed); the script owns the cross-file closure the schema
cannot see — registry ↔ manifest closure, that every requirement ID a
fixture references is defined in `spec/tsc-conformance.md`, that every
covered requirement carries both a positive and a negative case, and the
evidence rules (a `specified` fixture carries no execution evidence; a
`verified` fixture carries replayable PASS evidence and an independent
PASS review). When `cue` is absent the schema step is skipped with a
clear message and the closure checks still run.

## Failure classes these schemas guard

- A skill declaring measurement behavior the engine does not implement
  (or silently no longer implements) — caught by the cross-file checks.
- Rendered artifacts drifting from the skill declaration — caught by the
  render byte-identity check.
- Malformed or under-specified skill frontmatter — caught by `cue vet`.
