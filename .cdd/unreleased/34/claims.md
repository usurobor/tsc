# Honest-claim manifest — Cycle #34 α R1

Per γ's scaffold §"Honest-claim manifest claims (R1 must produce)" — α must
produce evidence-grounded claims for each of the five surfaces below.

## Claim 1 — Wiring

**Claim.** Every new kata directory's `kata.toml` is loadable by
`engine/ocaml/lib/kata.ml::load`. Every new kata is also runnable end-to-end
via `coh --kata <id> --mode mechanical`.

**Evidence.**

| Kata | `Kata.load` (test) | `coh --kata` exit | Observed C_Σ |
|---|---|---|---|
| `03-comparative` | PASS (test_kata.ml: kata-03 load + 6 field checks) | 0 (ranking_correct=true) | glider=0.9233, random-soup=0.6889 |
| `04-philosophical` | PASS (test_kata.ml: kata-04 load + 6 field checks) | 0 | 0.9333 |
| `05-adversarial` | PASS (test_kata.ml: kata-05 load + 6 field checks) | 0 | 0.7466 |

Reproduction: `cd engine/ocaml && dune runtest --force 2>&1 | grep -E "kata-0[345]"` (12 PASS lines).

## Claim 2 — Source-of-truth alignment

**Claim.** New schema fields are documented in `katas/README.md §kata.toml
schema` AND `kata.toml` for each new kata uses only fields present in the
documented schema.

**New schema fields added.** In cycle #34, two new fields:

| Field | Location in schema | Type | Where consumed |
|---|---|---|---|
| `[[components]]` (array of tables, each with `id` + `files`) | `katas/README.md §"kata.toml schema"` + `§Field reference` + `§Field index` + `§"Comparative katas (Phase 2)"` | array of tables | `engine/ocaml/lib/kata.ml` parser + `engine/ocaml/bin/main.ml::run_kata` comparative branch |
| `[expected].ranking` (string array) | `katas/README.md §"kata.toml schema"` + `§Field reference` + `§Field index` + `§"Comparative katas (Phase 2)"` | string[] | same |

**Evidence.** `grep -nE "components|ranking" katas/README.md` shows 9 hits across all four section types.

**Field usage check.** `kata.toml` files for kata-03/04/05:

- kata-03: `id`, `difficulty`, `mode`, `description`, `prerequisites`, `[[components]]`, `[[components]].id`, `[[components]].files`, `[expected].verdict`, `[expected].ranking` — all documented.
- kata-04: `id`, `difficulty`, `mode`, `description`, `prerequisites`, `[input].files`, `[expected].verdict`, `[expected.score_range].min`, `[expected.score_range].max`, `bottleneck_axis` — all documented.
- kata-05: `id`, `difficulty`, `mode`, `description`, `prerequisites`, `[input].files`, `[expected].verdict`, `[expected.score_range].min`, `[expected.score_range].max`, `bottleneck_axis` — all documented.

No undocumented fields used.

## Claim 3 — Reproducibility

**Claim.** Every kata's `expected.score_range` is a defensible empirical claim — the actual c_sigma observed at α-R1 time is recorded in the kata's README *and* documented in `kata.toml` comments adjacent to the `[expected.score_range]` block.

**Evidence.**

| Kata | README "Observed C_Σ" section | kata.toml comment | Match against expected.score_range |
|---|---|---|---|
| kata-03 | "Observed C_Σ (calibration)" section: glider 0.9233, random-soup 0.6889 | n/a (comparative — uses ranking not score_range) | actual ranking == expected ranking ✓ |
| kata-04 | "Observed C_Σ (calibration)" section: 0.9333 (α=1.000, β=1.000, γ=0.800) | comment in `[expected.score_range]` block records observed value | 0.9333 ≤ max=0.95 ✓ |
| kata-05 | "Observed C_Σ (calibration)" section: 0.7466 (α=0.969, β=0.470, γ=0.801) | comment in `[expected.score_range]` block records observed value | 0.7466 ≤ max=0.78 ✓ |

**Reproduction.** From repo root, with built binary:

```
engine/ocaml/_build/default/bin/main.exe --kata 03-comparative --mode mechanical --root .
engine/ocaml/_build/default/bin/main.exe --kata 04-philosophical --mode mechanical --root .
engine/ocaml/_build/default/bin/main.exe --kata 05-adversarial --mode mechanical --root .
```

Each exits 0 on cycle/34-impl HEAD.

## Claim 4 — No false negation

**Claim.** γ's §Gap claim that `engine/ocaml/lib/kata.ml` is "Phase 1 scope: mechanical-mode only. No LLM calls." is grep-verifiable on `d3a1e21` (pre-cycle main).

**Evidence.** On main `d3a1e21`:

```
git show d3a1e21:engine/ocaml/lib/kata.ml | grep -n "Phase 1 scope: mechanical-mode only"
```

returns:

```
6:    Phase 1 scope: mechanical-mode only. No LLM calls. *)
```

The claim is exact. (Confirmed by direct verification at α R1 time; recorded here for β's audit trail.)

## Claim 5 — kata-04 mode justification

**Claim.** The README for kata-04 contains explicit justification for the mechanical-mode choice — γ-decided at scaffold time, α records the reasoning.

**Evidence.** `katas/04-philosophical/README.md` contains a §"Mode justification (required per cycle #34 active design constraint)" section with **four numbered points**:

1. **Documents a real limitation.** Mechanical scorer claims cross-domain applicability; kata-04 exercises the claim on natural-language input and produces a record of what mechanical actually says (≈ 0.93, same band as kata-01 glider 0.92).
2. **Hermetic-by-default** is a project-wide constraint inherited from Phase 1.
3. **AC6 deferred** — LLM-mode runner extension is out of scope for v0.9.0.
4. **`expected.verdict = "fail"` is the load-bearing claim** — semantic judgement disagrees with mechanical reading; the disagreement is the lesson.

The test `kata-04 README OK` in `test_kata.ml` exercises this surface: it asserts the README contains "Mode justification", "mechanical", and one of {"hermetic", "credentials"}. All three assertions pass.

## Summary

All five claims verifiable from the branch diff and `dune runtest --force` output. The honest-claim manifest is the source of truth for β's pre-review gate (cdd/SKILL rule 3.13).
