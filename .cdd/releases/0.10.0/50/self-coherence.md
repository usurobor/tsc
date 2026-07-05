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

## Per-AC evidence

### AC1 — public report JSON has no flat aggregate fields

- `engine/ocaml/lib/mechanical_scoring.ml`: `result` record now carries
  `aggregate : aggregate` instead of `c_sigma : float`; `result_to_json`
  emits aggregate facts only under `("provenance", provenance_to_json r)`.
- `engine/ocaml/lib/hybrid_scoring.ml`: `to_json` / `mech_subobj` /
  `llm_subobj` / `final` all drop flat `c_sigma`; canonical facts under
  nested `provenance` sub-object.
- `engine/ocaml/lib/report.ml`: JSON key renamed `provenance_v320` →
  `provenance`; no flat aggregate fields at top level.
- `engine/ocaml/test/fixtures/report.schema.json`: schema requires
  `provenance` and uses `not.anyOf` to reject `c_sigma`, `c_sigma_math`,
  `c_sigma_num`, `zero_component_present`, `numeric_floor_applied`, and
  `epsilon` at the top level and inside `mechanical` / `llm` / `final`
  sub-objects.
- `engine/ocaml/test/test_mechanical.ml`: new assertions verify both
  presence of `provenance` and absence of every forbidden flat field on
  mechanical and hybrid JSON.

### AC2 — production aggregate computations use `Coherence.aggregate`

- `Mechanical_scoring.compute_aggregate` calls `Coherence.aggregate`.
  `compute_c_sigma` (arithmetic weighted_avg) is removed.
- `Hybrid_scoring.aggregate_of_triple` calls `Coherence.aggregate`. The
  arithmetic `(fa +. fb +. fg) /. 3.0` line is gone.
- `Report.provenance_v320` calls `Coherence.aggregate` (unchanged from
  v0.9.x — was already canonical; reaffirmed and audited).
- `Mechanical_scoring.weighted_avg` is retained for axis-internal signal
  scoring in `axis_score_of_signals`; no production path uses it for
  the headline cross-axis aggregate.
- `engine/ocaml/test/test_mechanical.ml::test_aggregate_uses_coherence_helper`
  and `test_hybrid_aggregate_uses_coherence_helper` assert the headline
  facts equal `Coherence.aggregate`'s output, and differ from arithmetic
  mean for unequal axis triples.

### AC3 — comparison output names aggregate deltas by form

- `Mechanical_scoring.comparison` record renames `delta_c_sigma` to
  `delta_c_sigma_math` and `delta_c_sigma_num`.
- `comparison_to_json` emits both form-suffixed deltas. The unsuffixed
  `delta_c_sigma` is removed from the JSON shape and the OCaml record.
- `Mechanical_scoring.compare` populates both deltas from
  `Coherence.aggregate` outputs on old and new results.
- `summary` string updated to print both deltas.
- `engine/ocaml/test/test_mechanical.ml::test_comparison_delta_rename`
  asserts presence of new fields, absence of the old one, and the
  numeric correctness of `delta_c_sigma_num`.

### AC4 — gauge witness production call sites use the canonical aggregate

Three production call sites of `Coherence.gauge_witness`, all building
a `c_sigma_fn` from `Coherence.aggregate`:

1. `Mechanical_scoring.provenance_to_json` (new in this cycle) — used
   by `result_to_json`.
2. `Hybrid_scoring.provenance_for_triple` (new in this cycle) — used by
   `to_json`, `mech_subobj`, `llm_subobj`.
3. `Report.provenance_v320` (pre-existing; reaffirmed) — used by
   `Report.to_json`.

`test_mechanical_json_schema` adds an assertion that the mechanical
report's `provenance.gauge_witness.w_gauge_ref` is a number, proving
the canonical `c_sigma_fn` actually ran (not a null skeleton).

### AC5 — text and kata output use canonical names

- `Report.to_text` prints `C_Σ^math` and `C_Σ^num` from
  `Coherence.aggregate`; arithmetic-mean headline line is gone.
- `Mechanical_scoring.summarize_result` prints both canonical aggregate
  forms.
- `engine/ocaml/bin/main.ml`: kata runner uses
  `result.aggregate.c_sigma_num` for verdict range checks and emits
  `c_sigma_num` in the result JSON (replacing `c_sigma`); single-bundle
  and comparative branches both updated. Per-component log line uses
  `C_Σ^num`.
- `engine/ocaml/test/test_mechanical.ml::test_aggregate_degeneracy`
  asserts the degenerate-input proof-plan case: `s_alpha = 0 ⇒
  c_sigma_math = 0`, `c_sigma_num > 0`, `zero_component_present = true`,
  `numeric_floor_applied = true`.

## CDD Trace — populated

- Tier 1a: cdd canonical algorithm; gamma role skill; alpha role skill
  (single-session γ-as-α dispatch).
- Tier 1b: not separately needed; design-and-build mode in dispatch.
- Tier 3 (cnos.eng/skills/eng/ocaml): applied to module-boundary type
  changes, `.mli` updates, and JSON-fixture cutover.
- Authority: spec/tsc-core.md §5; engine/ocaml/test/fixtures/provenance_v3_2_0.schema.json;
  engine/ocaml/lib/coherence.ml (`Coherence.aggregate` helper).

## Known debt at close

- **Build/test verification deferred to CI**: no OCaml toolchain in the
  dispatch sandbox; `dune build` and `dune runtest` were not run locally.
  Type signatures and OCaml syntax have been audited by hand against
  the existing module surface; runtime behavior of the new tests
  (`test_aggregate_uses_coherence_helper`,
  `test_hybrid_aggregate_uses_coherence_helper`,
  `test_comparison_delta_rename`, `test_aggregate_degeneracy`) is
  expected to pass per spec but cannot be exercised here.
- **Push to `cycle/50` blocked by proxy**: after the initial scaffold
  commit landed (`cf7e6aa`), further pushes to `origin/cycle/50` return
  HTTP 403 from the local proxy. Fresh branches accept pushes; the
  full AC1–AC5 commit is on `origin/cycle/50-work` as a fallback so β
  / δ can access the work. See gamma-closeout for routing guidance.
- **`Hybrid_scoring.select_final`** still uses a 0.10 per-axis
  agreement threshold for source selection — out of scope for #50
  (this is not the cross-axis aggregate); preserved verbatim.
- **No backward-compat shim**: per master scope, this is a breaking
  pre-1.0 cutover. Old reports with flat `c_sigma` are now rejected by
  the schema and no longer produced.
