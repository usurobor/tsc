# RELEASE.md

**Release:** TSC Engine v0.9.0 — Phase 2 kata progression (comparative + philosophical + adversarial)
**Issue:** #34 — Engine katas: Phase 2
**Branch merged:** cycle/34 → cycle/34-impl → cycle/34-impl-review → main
**Merge commit:** filled by operator post-PR-merge
**Date:** 2026-05-12

## Outcome

Coherence delta: C_Σ A− (`α A−`, `β A`, `γ A−`) · **Level:** L6

α A− earned: 0 binding findings (0A, 0B), 4 C-severity advisories, all 5 ACs satisfied,
calibration data documented in-kata.

β A earned: independent peer-enumeration, rule 3.13 verbatim on all 5 honest-claim manifest
claims, kata-04 verdict-semantics dug into and flagged as load-bearing (C-2), kata-05
thin-margin acknowledged as intentional ("moving frontier"), Phase 1 backward-compat
empirically verified.

γ A− capped at §5.2 ceiling: F1+F2+F3 self-application all honored — peer-enumeration
table at §Gap before scaffold; CI verified green before close-out; parent-session
quiescent during α/β runs.

Phase 2 of the kata progression. Extends the Phase 1 framework (positive +
negative controls) with three new katas across three previously-uncovered
axes:

- **Comparative ordering** (kata-03) — asserts the engine's *ranking* of two
  inputs, not just their individual scores. Closes the
  threshold-discrimination gap.
- **Cross-domain** (kata-04) — first natural-language philosophical-text
  kata; documents the upper limit of mechanical scoring on well-formatted
  prose (mechanical C_Σ ≈ 0.93, comparable to the well-structured
  cellular-automata kata-01 ≈ 0.92).
- **Adversarial** (kata-05) — multi-file input with high surface regularity
  and cross-file semantic contradictions; the β bottleneck correctly
  identifies it as adversarially incoherent (mechanical C_Σ ≈ 0.75 vs
  glider ≈ 0.92).

Engine runner gains `[[components]]` + `expected.ranking` support for
comparative katas; Phase 1 single-bundle katas continue to work unchanged.

## What shipped

- **`katas/03-comparative/`** — comparative kata with copies of kata-01 +
  kata-02 inputs as named `[[components]]`. Observed ranking on
  cycle/34-impl HEAD: `glider (0.9233) > random-soup (0.6889)`. Margin ≈
  0.234, well above any plausible measurement noise.
- **`katas/04-philosophical/`** — kata-04 input: copy of
  `examples/philosophical/consciousness.md`. Mode = **mechanical**
  (γ-decided per cycle #34 active design constraint; AC6 LLM-mode runner
  support deferred to Phase 3). README's §"Mode justification" section
  records four points: documents-a-real-limitation, hermetic-by-default,
  AC6-deferred-clean-narrative, verdict=fail-is-load-bearing. Observed
  C_Σ = 0.9333 (α=1.000, β=1.000, γ=0.800; bottleneck γ); score_range
  `{min=0.0, max=0.95}` brackets observation and itself documents the
  limit.
- **`katas/05-adversarial/`** — three Quanton-protocol-spec files with
  identical surface structure but contradictory transport/format/canonical
  claims. Observed C_Σ = 0.7466 (α=0.969, β=0.470, γ=0.801; bottleneck β
  cross-reference + source-of-truth alignment). score_range
  `{min=0.0, max=0.78}` brackets observation just above; tighten as
  mechanical-scorer refinements lower the score.
- **Engine runner extension** (`engine/ocaml/bin/main.ml::run_kata`):
  branches on `kata.components` non-emptiness. Single-bundle path
  unchanged. Comparative path scores each component, sorts by C_Σ, asserts
  ranking match; emits per-component results + `ranking_correct: bool` in
  result JSON. Net ≈ 65 added lines; no Phase 1 behavior altered.
- **Manifest parser extension** (`engine/ocaml/lib/kata.ml`): new
  `kata_component` type; `components` and `ranking` fields on
  `kata_config`; otoml parsing of `[[components]]` array-of-tables.
  Phase 1 fields unchanged; `components = []` and `ranking = []` defaults
  preserve Phase 1 katas exactly.
- **Tests** (`engine/ocaml/test/test_kata.ml`): 25 new hermetic assertions
  covering kata-03 (id + mode + 2 components + ranking + difficulty),
  kata-04 (id + mode + verdict=fail + score_max + no components + README
  mode-justification claim), kata-05 (id + mode + verdict=fail + 3 input
  files + score_max + README adversarial-design claim). Total suite
  146 → 171 PASS lines.
- **Docs** (`katas/README.md` §"Current katas" + §"Comparative katas (Phase
  2)" + schema rows; `QUICKSTART.md` §8 smoke-test invocations for
  kata-03/04/05).
- **VERSION** `0.8.0` → `0.9.0`; **CHANGELOG.md** ledger row + `### 0.9.0`
  detail section; **`engine/ocaml/dune-project` + `tsc_engine.opam`**
  version strings bumped.

## Review summary

β R1 verdict: **APPROVED** (0 A-severity, 0 B-severity, 4 C-severity advisories).

C-1: alpha-closeout.md convention drift — α-R1 closeout content distributed across `claims.md` + `self-coherence.md §Head SHA` rather than a single `alpha-closeout.md`. Documented; not blocking.

C-2: kata-04 `score_range.max=0.95` permissively wide given observed C_Σ = 0.9333 (~1.7% margin). Internally consistent (kata.toml comment + README explicitly document the wideness as itself the kata's load-bearing assertion). Consider tightening if the mechanical scorer learns to discriminate philosophical prose.

C-3: kata-03's comparative branch emits `expected_verdict` field but the runner does not consult it for pass/fail — `ranking_correct` is the gate. Cosmetic; clarify in a future cycle.

C-4: γ scaffold's CHANGELOG ledger-row format text referenced an 8-column "Rounds" variant that doesn't match the actual 7-column schema in CHANGELOG.md. α's row correctly matches the existing schema. γ scaffold text could be updated in a follow-on.

1 review round. β additionally verified Phase 1 backward-compat by reproducing kata-01 (C_Σ = 0.9233) and kata-02 (C_Σ = 0.6888) baselines exactly.

## Process impact

- **kata.toml schema extension is strictly additive.** Phase 1 katas
  (01-glider, 02-random-soup) load and run identically; no Phase 1 fields
  removed or renamed.
- **Runner extension preserves the mechanical-only constraint.** AC6
  (LLM-mode kata support) deferred per γ's scaffold decision. `mode=llm`
  katas still exit non-0 with the same Phase 1 message (text updated:
  "Phase 1/2 katas are mechanical-only").
- **Test suite grew by 25 assertions** (146 → 171). All new tests are
  hermetic (no LLM, no network, no credentials).
- **CI compatibility.** `.github/workflows/katas.yml` auto-discovery glob
  picks up the three new katas automatically; no workflow changes needed.
  `release.yml` triggers on `v0.9.0` tag push.

## Validation evidence

- **AC1 (kata-03 comparative ships):** `coh --kata 03-comparative --mode
  mechanical` → exit 0, `ranking_correct: true`, components `glider`
  (0.9233) > `random-soup` (0.6889).
- **AC2 (kata-04 philosophical ships, mechanical mode justified):** `coh
  --kata 04-philosophical --mode mechanical` → exit 0, c_sigma=0.9333,
  matches `expected.verdict=fail` + `score_range`. README §"Mode
  justification" present (4-paragraph rationale).
- **AC3 (kata-05 adversarial ships):** `coh --kata 05-adversarial --mode
  mechanical` → exit 0, c_sigma=0.7466 ≤ score_max=0.78, verdict matched.
- **AC4 (tests cover all three):** `dune runtest` exit 0; PASS lines
  reference `kata-03`, `kata-04`, `kata-05`. Suite 146 → 171.
- **AC5 (docs surface new katas):** `grep -E
  "03-comparative|04-philosophical|05-adversarial" katas/README.md
  QUICKSTART.md` returns matches in both.
- **AC6 (LLM-mode runner support):** **Deferred** per γ's scaffold
  decision (mechanical-mode kata-04 makes AC6 non-blocking for v0.9.0).
  Phase 3 follow-on.

## Known issues

- 0.8.0 detail section was not retroactively authored (cycle #30 shipped
  only the ledger row). Not in cycle #34's scope; carried forward.
- kata-04's `expected.score_range = {min=0.0, max=0.95}` is intentionally
  wide; the wideness itself is documentation that the mechanical scorer
  cannot discriminate philosophical prose from engineering docs.
- kata-05's `expected.score_range.max = 0.78` is a thin margin above
  observed 0.7466. If a future α-axis refinement raises kata-05's C_Σ
  even slightly, the kata starts failing — at which point the kata's
  adversarial input must be hardened (cycle #34's "moving frontier"
  acknowledgment).
- `engine/ocaml/test/dune` gained explicit `(modules ...)` stanzas to
  build under dune ≥ 3.14. No behavioral change; previously the implicit
  module inference worked under dune 3.0–3.13. Filed as a noted change in
  CHANGELOG §0.9.0 Changed.
