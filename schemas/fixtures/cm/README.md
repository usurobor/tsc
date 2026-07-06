# CM-document fixtures

Positive/negative suite for `schemas/cm.cue` `#CMDocument` — the typed
contract for a CM authored in the α-Parts / β-Fit / γ-Evolve grammar
(canonical exemplar: `docs/beta/governance/CM0.md`).

## Layout

- `valid/cm0.yaml` — the machine-extraction of the typed H2 blocks in
  `docs/beta/governance/CM0.md`. Vets clean; it is the AC2 positive case.
  Kept faithful to CM0.md (CM0.md is canonical; this is its data
  projection).
- `invalid/missing-organ.yaml` — a stub missing required organs; must fail
  vet (the AC2 negative oracle). `missing-organ.expect` names the expected
  diagnostic substring.

## Vet commands (deferred to CI where `cue` is available)

```bash
# positive — must pass
cue vet -d '#CMDocument' schemas/cm.cue schemas/fixtures/cm/valid/cm0.yaml

# negative — must fail, matching invalid/missing-organ.expect
cue vet -d '#CMDocument' schemas/cm.cue schemas/fixtures/cm/invalid/missing-organ.yaml
```

`cue` is not on PATH in the authoring environment for Sub-1 (#78); these
run in CI. A structural self-check (organ/relation/clause presence over
`cm0.yaml` and `CM0.md`) is recorded in `.cdd/unreleased/78/self-coherence.md`.
