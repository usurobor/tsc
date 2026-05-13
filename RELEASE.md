# RELEASE.md

**Release:** TSC Engine v0.10.0 — canonical v3.2 scoring cutover
**Date:** 2026-05-13

## Outcome

Breaking release. The cross-axis aggregate is now the canonical v3.2
geometric mean everywhere. The arithmetic mean has been removed from
every headline-scoring path. The report shape, kata thresholds, and
related docs are realigned to spec v3.2 (see
[spec/tsc-core.md](spec/tsc-core.md) §5,
[spec/tsc-oper.md](spec/tsc-oper.md) §5–§6).

## Breaking changes

- **`C_Σ` is geometric everywhere.** The mechanical, hybrid, and LLM
  pipelines all compute the canonical aggregate via
  `Coherence.aggregate`. Reports carry both forms:
  - `c_sigma_math = (α · β · γ)^(1/3)` — strict; collapses to 0 when any
    component is exactly 0 (`zero_component_present: true`).
  - `c_sigma_num  = exp((1/3) · Σ ln(max(sᵢ, ε)))` — ε-floored numeric
    form; threshold-comparison value per spec/tsc-oper.md §5
    (`numeric_floor_applied` records when ε truncated a component).
- **The flat `c_sigma` field is removed.** It is not an alias and not a
  shim. Consumers must read `c_sigma_num` (for thresholding) and check
  `zero_component_present` for math degeneracy.
- **Report schema replaced.** `engine/ocaml/test/fixtures/report.schema.json`
  now requires
  `mode`, `schema_version`, `alpha`, `beta`, `gamma`, `c_sigma_math`,
  `c_sigma_num`, `zero_component_present`, `numeric_floor_applied`,
  `bottleneck_axis`, `provenance`. Hybrid sub-objects (`mechanical`,
  `llm`, `final`) carry the same canonical aggregate fields.
- **`provenance` (not `provenance_v320`) is the canonical field name.**
  The provenance bundle is unchanged in content
  (`provenance_v3_2_0.schema.json`).
- **Mechanical config dropped axis-weight knobs.** `Mechanical_scoring.config`
  no longer carries a `weights` record — the canonical v3.2 aggregate is
  unweighted geometric (S3-symmetric by construction). Intra-axis signal
  weights are unchanged.
- **Mechanical comparison delta split.** `delta_c_sigma` → `delta_c_sigma_num`
  + `delta_c_sigma_math`.
- **Kata thresholds re-baselined.** Every kata's `expected.score_range` is
  now over `c_sigma_num`. Geometric mean ≤ arithmetic mean (AM–GM), so
  positive-control floors moved down (kata-01: 0.87 → 0.80) and
  fail-side ceilings remain valid bracketers (kata-02 0.74, kata-04
  0.95, kata-05 0.78 → 0.80). Comments in each `kata.toml` record the
  cutover rationale and the canonical observation.
- **`project.tsc` removed.** It was already declared superseded by the
  target registry; the file is gone, not "soft-deprecated."
- **`v3.1.x` reference windows still hard-fail** the OOD cutover guard
  (`Ood.check_schema_version`), unchanged from v0.6.0.

## What shipped

- `engine/ocaml/lib/mechanical_scoring.{ml,mli}` — `result` now exposes
  `c_sigma_math`, `c_sigma_num`, `epsilon`, `zero_component_present`,
  `numeric_floor_applied`. `compute_aggregate` calls `Coherence.aggregate`.
  `result_to_json` emits canonical v3.2 fields plus an embedded
  `provenance` object built from the canonical W2 gauge witness.
- `engine/ocaml/lib/hybrid_scoring.ml` — rewritten end-to-end. Each
  backend's sub-object carries its own canonical aggregate. The final
  view, the `mechanical` and `llm` sub-objects, and the `final`
  sub-object all share one aggregate-field shape. The full v3.2
  `provenance` is attached to the hybrid report.
- `engine/ocaml/lib/report.ml` — `to_json` lifts `c_sigma_math` /
  `c_sigma_num` / degeneracy flags to the top level alongside the LLM
  scores; `to_text` prints both forms with a `zero_component_present` /
  `numeric_floor_applied` warning when applicable. The arithmetic mean
  is gone from the text report.
- `engine/ocaml/bin/main.ml` — kata runner compares against
  `c_sigma_num`; a `pass` verdict additionally fails strict math
  degeneracy (`zero_component_present`). The kata result JSON carries
  both aggregate forms plus the degeneracy flags.
- `engine/ocaml/test/fixtures/report.schema.json` — replaced.
- `engine/ocaml/test/test_mechanical.ml` — every schema assertion
  rewritten to the canonical v3.2 shape; tests now positively assert
  the absence of any flat `c_sigma` field.
- `katas/0{1,2,4,5}/kata.toml` — thresholds re-baselined and annotated.
- `docs/THESIS.md`, `QUICKSTART.md`, `ARCHITECTURE.md`,
  `docs/beta/guides/OPERATOR-MANUAL.md`, `katas/README.md` and the
  per-kata READMEs — rewritten to describe the canonical aggregate, not
  the arithmetic mean.
- `docs/design/0.5.0/DESIGN.md`,
  `docs/alpha/engine/0.5.0/POST-RELEASE-ASSESSMENT.md`,
  `docs/alpha/doctrine/3.2.0/SELF-COHERENCE.md` — annotated as
  ARCHIVAL pre-v3.2-cutover, with explicit pointers to the current
  report contract.
- `examples/philosophical/{free-will,emergence}.md` — embedded YAML
  expectations updated to `c_sigma_num`.
- `VERSION` 0.9.0 → 0.10.0; `engine/ocaml/dune-project` and
  `engine/ocaml/tsc_engine.opam` follow.
- `project.tsc` deleted.

## Migration

External consumers of the report JSON must:

- Replace any read of `c_sigma` with `c_sigma_num`.
- Treat `zero_component_present: true` as a strict FAIL irrespective of
  the numerical value.
- Optionally read `c_sigma_math` for math-degeneracy diagnostics and
  `numeric_floor_applied` to surface ε-floor activations.

Self-coherence reports computed by engine ≤ v0.9.x are not directly
comparable to v0.10.0 output; recompute the run.

## Provenance

`provenance` is emitted in every mode (mechanical, llm, hybrid) and
follows
[`engine/ocaml/test/fixtures/provenance_v3_2_0.schema.json`](engine/ocaml/test/fixtures/provenance_v3_2_0.schema.json).
The W2 gauge witness is computed over the canonical geometric aggregate
and is trivially zero in the symmetric mechanical configuration.
