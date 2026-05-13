# Self-coherence — cycle/50 (canonical aggregate + report schema replacement)

Master: #49 (v0.10.0 canonical v3.2 scoring cutover)
Sub: #50 — S1 canonical aggregate + report schema replacement
Mode: design-and-build (single dispatch, γ-as-α)
CDD: §5.2 single-session δ-as-γ via Agent tool

## Gap

Engine v0.9.0 publishes the cross-axis aggregate as a single arithmetic
mean (`(α + β + γ)/3`) under a flat top-level `c_sigma` key in every
public-report shape (mechanical, hybrid, LLM text, kata-runner). Spec
v3.2 (`spec/tsc-core.md` §5) defines the canonical aggregate as the
geometric mean with two reported forms — `C_Σ^math` (strict; zero-
collapse) and `C_Σ^num` (ε-floored) — and the canonical provenance
fixture (`provenance_v3_2_0.schema.json`) requires those facts under
`provenance.aggregate_math` / `provenance.aggregate_numeric`. Helper
`Coherence.aggregate` already implements the canonical math; production
callers do not consume it for the headline aggregate.

This sub-issue cuts the production surfaces to canonical aggregate fact
emission and removes flat aggregate fields from every public report
shape.

## Mode: design-and-build

No new module required; the helper `Coherence.aggregate` is already
shipped. The work is a coordinated rename + schema + caller cutover
across mechanical, hybrid, report, kata, and the test fixture, in one
breaking pre-1.0 step (no compatibility shim — per master scope).

## AC mapping

| AC  | Surface(s)                                        | Implementation summary |
|-----|---------------------------------------------------|------------------------|
| AC1 | `report.schema.json`, `Mechanical_scoring.result_to_json`, `Report.to_json`, `Hybrid_scoring.to_json` | Drop top-level `c_sigma` (and ban siblings); require `provenance` with `aggregate_math` and `aggregate_numeric`. |
| AC2 | `Mechanical_scoring.score_files`, `Hybrid_scoring.combine`, `Hybrid_scoring` sub-objects, `Report.provenance_v320` | Cross-axis aggregate routed through `Coherence.aggregate`; `weighted_avg` retained for axis-internal signal scoring only. |
| AC3 | `Mechanical_scoring.comparison`, `comparison_to_json`, mli | Replace `delta_c_sigma` with `delta_c_sigma_num` (+ `delta_c_sigma_math` where meaningful). |
| AC4 | `Report.provenance_v320` (only production gauge_witness call site) | `c_sigma_fn` built from `Coherence.aggregate` (already true; reaffirmed and asserted). |
| AC5 | `Report.to_text`, `Mechanical_scoring.summarize_result`, `bin/main.ml` kata runner | Print `C_Σ^math` and `C_Σ^num`, drop arithmetic-mean line; kata uses `c_sigma_num` for range/result. |

JSON key rename: in `Report.to_json` the provenance JSON key changes
from `provenance_v320` → `provenance`. Mechanical and hybrid writers
also emit aggregate facts under `provenance`.

## CDD Trace

- Tier 1a: cdd (canonical algorithm), gamma role skill, alpha role skill.
- Tier 1b/c: not separately loaded (single-session dispatch; no MCA
  artifact required for build mode).
- Tier 3: cnos.eng/skills/eng/ocaml — referenced via #50 skills list;
  applied directly to type and JSON contract changes.

## Known debt / open seams

- **Build/test verification deferred to CI**: no OCaml toolchain in the
  dispatch sandbox. `dune build` and `dune runtest` could not be run
  locally; CI on the pushed `cycle/50` branch is the verification
  channel.
- New tests (assertions for aggregate routing, delta rename, schema
  rejection of flat aggregate) are committed alongside source; they are
  expected to compile but cannot be exercised here.
- Hybrid `select_final` semantics still use a 0.10 axis-component
  agreement threshold — out of scope per #50 (this is not the cross-
  axis aggregate).

## Per-AC evidence (populated by phase 3)

Filled in as implementation lands. See `gamma-closeout.md` for the per-
AC status table and final SHA.
