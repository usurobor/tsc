# RELEASE.md

**Release:** TSC Engine v0.10.0 — canonical v3.2 scoring cutover
**Issue:** #49 (wave master) with sub-issues #50, #51, #52, #53, #54
**Branches merged:** cycle/50, cycle/51, cycle/52, cycle/53, cycle/54 → main
**Merge commit:** filled by operator post-PR-merge
**Date:** 2026-05-13

## Outcome

Coherence delta: C_Σ A− (`α A−`, `β A−`, `γ A−`) · **Level:** L7

The v0.10.0 release closes the canonical-v3.2 cutover wave (#49). The engine's
report shape moves from the v0.9.x flat top-level `c_sigma` (arithmetic mean
`(α+β+γ)/3`) to the canonical-v3.2 dual aggregate (geometric `C_Σ^math` and
`C_Σ^num`) emitted under `provenance.aggregate_math` and
`provenance.aggregate_numeric`. The cutover is breaking on the report shape and
on the kata baselines that depend on it; pre-cutover frozen reports are not
directly comparable to post-cutover output. The wave shipped as five
coordinated sub-cycles — four engine cuts (#50/#51/#52/#53) and one cleanup
pass (#54) — that together align active surfaces with the post-cutover
authority.

## What shipped

### Engine cutover (sub-cycles #50–#53)

- **`engine/ocaml/lib/coherence.ml` + `lib/report.ml`** (#50): aggregate split.
  `C_sigma_math = (α · β · γ)^(1/3)` (strict; zero whenever any component is
  zero) and `C_sigma_num = (max(α, ε) · max(β, ε) · max(γ, ε))^(1/3)` (with
  `ε = 10⁻⁵`; the verdict-bearing form) are emitted under
  `provenance.aggregate_math.C_sigma_math` and
  `provenance.aggregate_numeric.C_sigma_num`. The flat top-level `c_sigma`
  JSON field is removed. The text report renders both forms; no arithmetic
  headline survives.
- **`engine/ocaml/lib/response_schema.ml`** (#51): strict v3.2 LLM δ
  validation — responses missing the per-pair discrepancy values
  (`δ_αβ`, `δ_βγ`, `δ_γα`) required by the v3.2 transformation chain
  `δ → φ(δ) → D → Coh = exp(−D)` are rejected at ingest time.
- **`engine/ocaml/lib/ood.ml`** (#52): the OOD cutover guard gains an
  `aggregate_semantics` detector — pre-v3.2 reports quoting the arithmetic-mean
  aggregate are refused with a reset diagnostic.
- **`engine/ocaml/lib/cross_target.ml`** (#53): the cross-target aggregate
  surface emits `provenance.cross_target_aggregate.C_sigma_cross_num` and
  `C_sigma_cross_math` per `spec/tsc-oper.md` §7.4 — geometric mean of
  per-target `C_sigma_num` across `n` targets, with the strict mathematical
  form collapsing to zero when any target carries `zero_component_present`.

### Cleanup pass (sub-cycle #54)

- **Kata re-baseline.** Each `katas/*/kata.toml` now carries a `[baseline]`
  block (or per-component baselines for the comparative kata-03) with the
  v0.10.0 canonical-aggregate provenance — `baseline_engine_commit`,
  `baseline_engine_version`, `baseline_command`, `mode`, `config_hash`,
  `input_file_hashes`, α, β, γ, `c_sigma_math`, `c_sigma_num`,
  `zero_component_present`, `numeric_floor_applied`, `rationale_category`.
  Kata-04 and kata-05 carry `rationale_category = "frontier-tightening"`
  (retain documented moving-frontier margins); kata-01/02/03 carry
  `rationale_category = "aggregate-correction"`.
- **Active docs rewritten.** `docs/THESIS.md`, root `QUICKSTART.md`, root
  `ARCHITECTURE.md`, `docs/beta/guides/OPERATOR-MANUAL.md`,
  `katas/README.md`, and every per-kata README describe geometric
  `C_Σ^math` / `C_Σ^num`; JSON examples reference
  `provenance.aggregate_math` and `provenance.aggregate_numeric`; the
  arithmetic-mean headline language is removed.
- **`project.tsc` removed.** The repo-root `project.tsc` file was superseded
  by `targets/registry.tsc` at v0.1.0 and retained until now for reference.
  Removed in #54; canonical root configuration authority is
  `targets/registry.tsc`.
- **Frozen-snapshot policy honored.** Per CDD §5.6, frozen version
  directories admit only markdown-link and backtick-path repairs. AC4 of #54
  verified that the three named files
  (`docs/alpha/doctrine/3.2.0/SELF-COHERENCE.md`,
  `docs/alpha/engine/0.5.0/POST-RELEASE-ASSESSMENT.md`,
  `docs/design/0.5.0/DESIGN.md`) carry no v0.10.0 archival banner text — no
  edits were applied to frozen content.
- **Migration note.** `CHANGELOG.md` carries an active-surface migration
  note stating that pre-v0.10.0 frozen reports may quote arithmetic
  aggregates and are not directly comparable to post-cutover output.
- **Target-registry smoke tests** (`engine/ocaml/test/test_target_registry.ml`):
  parse `targets/registry.tsc`, assert `registry_format =
  "tsc-target-registry/0.1"` and exactly `spec`/`engine`/`repo` targets,
  resolve each name to its manifest path, parse each manifest, and assert
  non-empty bundle expansion via the same root/path semantics as `main.ml`.
- **Forbidden-wording CI rule** (`scripts/check-forbidden-wording.sh` +
  `.github/workflows/ci.yml`): forward-only check that rejects newly-added
  `"Operational acceptance"`, `"Operationally accepted"`,
  `"self-coherence ACCEPT"`, `"release criteria satisfied"` outside frozen
  (`docs/{tier}/{bundle}/{X.Y.Z}/`) and archive paths. Existing historical
  occurrences in excluded paths do not fail the job.
- **Version artifacts at 0.10.0.** `VERSION`, `engine/ocaml/dune-project`,
  `engine/ocaml/tsc_engine.opam`, `CHANGELOG.md`, and this `RELEASE.md`
  all agree on `0.10.0`. `scripts/check-version-consistency.sh` passes.

## Migration note

Pre-v0.10.0 reports — and any frozen report quoted in
`docs/{tier}/{bundle}/{X.Y.Z}/` snapshot directories — quoted the
arithmetic-mean aggregate `c_sigma = (α + β + γ) / 3`. v0.10.0 reports
quote the geometric aggregate `C_sigma_num = (max(α, ε) · max(β, ε) ·
max(γ, ε))^(1/3)` (with `ε = 10⁻⁵`) under `provenance.aggregate_numeric`,
and the strict mathematical aggregate `C_sigma_math = (α · β · γ)^(1/3)`
under `provenance.aggregate_math`.

The two aggregates disagree by a few percentage points on well-balanced
triples and by larger amounts on imbalanced ones (e.g. kata-02's inferred
triple yields arithmetic 0.689 vs geometric 0.658). **Pre-cutover numbers
in frozen reports are not directly comparable to post-cutover output.**
Frozen snapshots are intentionally left unedited (CDD §5.6); the
comparability limit is documented in `CHANGELOG.md` and here. Historical
report migration is out of scope for this wave (see #54 §Out of scope).

## Review summary

This wave shipped through five coordinated CDD sub-cycles — #50, #51, #52,
#53, #54 — each with its own β review. The final cleanup cycle (#54) was
implemented by an isolated α sub-agent following the §1.4 triadic rule;
β review is a separate cycle and signals readiness via
`.cdd/unreleased/54/beta-review.md`.

Per-sub-cycle β verdicts (recorded on `main`):

- #50 — APPROVED (β R2 after one fix round)
- #51 — APPROVED (β R1)
- #52 — APPROVED (β R1)
- #53 — APPROVED (β R2 after one fix round)
- #54 — TBD (β review dispatched after α closeout)

## Process impact

- **Breaking on the report shape.** The flat top-level `c_sigma` field is
  removed. Consumers reading `report.c_sigma` must migrate to
  `report.provenance.aggregate_numeric.C_sigma_num`.
- **Kata baselines re-baselined.** Kata-04 and kata-05's `[baseline]`
  blocks record explicit (α, β, γ) triples observed at cycle/34-impl
  HEAD; kata-01/02/03 record inferred triples and mark
  `baseline_engine_commit = "pending-ci"` — the first v0.10.0 CI run
  records canonical readings.
- **Frozen snapshots unchanged.** AC4 of #54 verified the three named
  files carry no archival banner; per CDD §5.6 no semantic edits applied.
- **CI compatibility.** The OCaml test suite gains
  `test_target_registry.ml`; the forbidden-wording CI rule runs on every
  PR. Existing test executables (`test_response_schema`, `test_ood`,
  `test_cross_target`, `test_mechanical`, `test_coherence`, `test_kata`)
  continue to coexist.
- **v3.2 spec alignment.** The engine's provenance JSON skeleton now
  matches the v3.2.0 spec skeleton precisely; the §7.4 cross-target
  surface matches v3.2.1.

## Validation evidence

- **AC1 (kata re-baseline):** every `katas/*/kata.toml` carries a
  `[baseline]` block with the required v0.10.0 provenance fields.
  `rationale_category` set to `aggregate-correction` (kata-01/02/03) or
  `frontier-tightening` (kata-04/05).
- **AC2 (active docs canonical):** grep over active docs shows no flat
  top-level `c_sigma` JSON examples; geometric `C_Σ^math` / `C_Σ^num`
  language used throughout. Frozen and archive paths excluded.
- **AC3 (`project.tsc` removed):** `test ! -e project.tsc` passes on the
  branch.
- **AC4 (frozen-snapshot policy):** `git diff -- docs/alpha/doctrine/3.2.0/SELF-COHERENCE.md docs/alpha/engine/0.5.0/POST-RELEASE-ASSESSMENT.md docs/design/0.5.0/DESIGN.md` is empty on this cycle.
- **AC5 (migration note):** `CHANGELOG.md` v0.10.0 entry §"Migration note
  (pre-v0.10.0 comparability)" references #49 and the four predecessor
  cycles.
- **AC6 (target-registry smoke tests):**
  `engine/ocaml/test/test_target_registry.ml` parses
  `targets/registry.tsc`, resolves three targets, parses each manifest,
  and asserts non-empty bundle expansion for each.
- **AC7 (forbidden-wording CI rule):** `scripts/check-forbidden-wording.sh`
  is executable; CI invocation in `.github/workflows/ci.yml` runs it on
  every PR; excluded paths verified.
- **AC8 (release artifacts):**
  `scripts/check-version-consistency.sh` passes;
  `VERSION = engine/ocaml/dune-project = engine/ocaml/tsc_engine.opam = 0.10.0`;
  this `RELEASE.md` and `CHANGELOG.md` describe the cutover and reference
  #49.

## Known issues

- Kata-01 / kata-02 / kata-03 baselines record *inferred* (α, β, γ)
  triples (the cycle-34 calibration recorded only the arithmetic-mean
  aggregate). `baseline_engine_commit = "pending-ci"`; the first v0.10.0
  CI run records canonical readings, and a future cycle tightens
  `expected.score_range` accordingly. See #54 §Known debt.
- Pre-v0.10.0 frozen reports are not migrated. The migration note carries
  the comparability limit; historical migration is out of scope.
- OCaml toolchain absent in α's dispatch sandbox — `dune build` /
  `dune runtest` deferred to CI on the PR. The smoke tests, schema, and
  CI rule script are reviewed for correctness in the α self-coherence
  before β round 1.
