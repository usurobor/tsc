# Gamma close-out — cycle/50

Wave: `v0.10.0-canonical-v3.2-cutover` (master #49)
Sub-issue: #50 — S1 canonical aggregate + report schema replacement
Mode: design-and-build, single-session γ-as-α dispatch (CDD §5.2)

## Cycle summary

Cut the engine from arithmetic-aggregate reporting to canonical v3.2
aggregate reporting in a single coordinated change across mechanical,
hybrid, LLM/text, and kata-runner surfaces:

- All production cross-axis aggregate computation routes through
  `Coherence.aggregate`. The arithmetic helpers (`compute_c_sigma`,
  `hyb_final_csigma`) are removed.
- Public JSON has no flat `c_sigma` (or any flat aggregate fact) at any
  level — top, `mechanical`/`llm` sub-objects in hybrid, or `final`.
  The canonical `provenance` sub-object is the only place aggregate
  facts live; the schema fixture enforces this with `not.anyOf`.
- `Report.to_json`'s provenance JSON key was renamed `provenance_v320`
  → `provenance`. Mechanical and hybrid writers also emit `provenance`.
- `Mechanical_scoring.comparison` replaces `delta_c_sigma` with
  `delta_c_sigma_math` + `delta_c_sigma_num`.
- All three production `Coherence.gauge_witness` call sites build a
  `c_sigma_fn` from `Coherence.aggregate`.
- Text reports print `C_Σ^math` and `C_Σ^num`; the arithmetic-mean line
  is gone. Kata runner uses `c_sigma_num` for range checks.

## Per-AC status

| AC  | Status      | Surface(s) cut over | Evidence (committed tests) |
|-----|-------------|---------------------|----------------------------|
| AC1 | pass (no test runtime) | `report.schema.json`; `Mechanical_scoring.result_to_json`; `Report.to_json`; `Hybrid_scoring.to_json` | `test_mechanical_json_schema`, `test_hybrid_json_schema`, `test_hybrid_preserves_both` assert presence of `provenance` and absence of every forbidden flat key. |
| AC2 | pass (no test runtime) | `Mechanical_scoring.compute_aggregate`; `Hybrid_scoring.aggregate_of_triple`; `Report.provenance_v320` | `test_aggregate_uses_coherence_helper`, `test_hybrid_aggregate_uses_coherence_helper` assert equality with `Coherence.aggregate` and divergence from arithmetic mean for unequal triples. |
| AC3 | pass (no test runtime) | `Mechanical_scoring.{ml,mli}` comparison record + JSON | `test_comparison_delta_rename` asserts presence of `delta_c_sigma_num`/`delta_c_sigma_math`, absence of `delta_c_sigma`, and numeric correctness. |
| AC4 | pass (no test runtime) | All three production `gauge_witness` call sites | Three call sites audited: `Mechanical_scoring.provenance_to_json`, `Hybrid_scoring.provenance_for_triple`, `Report.provenance_v320`. New assertion verifies `w_gauge_ref` is emitted as a number. |
| AC5 | pass (no test runtime) | `Report.to_text`; `Mechanical_scoring.summarize_result`; `bin/main.ml` kata runner | `test_aggregate_degeneracy` covers the proof-plan corner case (s_α=0 ⇒ math=0, num>0); text/kata changes are by inspection. |

`pass (no test runtime)`: all source/test changes are in place; runtime
verification (`dune build` + `dune runtest`) cannot be performed in the
dispatch sandbox and is deferred to CI on the pushed branch.

## Test verification status

| Check | Status | Notes |
|-------|--------|-------|
| `dune build` | deferred to CI | No OCaml toolchain in sandbox. |
| `dune runtest` | deferred to CI | Same. |
| Hand-audit of types/.mli alignment | done | Aggregate type added to both `.ml` and `.mli`; comparison record matches; no orphan references to removed `c_sigma` field. |
| Grep audit for `r.c_sigma` / `.c_sigma`/`delta_c_sigma`/`hyb_final_csigma` | done | Remaining hits are documentation strings, the negative-assertion test cases, and uses of `Coherence.aggregate_result.{c_sigma_math, c_sigma_num}` (a different type — sourced from the helper). |
| Schema fixture validity | done by inspection | JSON Schema draft-07; uses `not.anyOf` blocks at every sub-object level. |
| Kata runner: comparative + single-bundle branches | done | Both updated to use `result.aggregate.c_sigma_num`. |

## Known debt

1. **No local build/test verification.** No OCaml toolchain in the
   dispatch sandbox. The branch must be exercised by CI; β should
   reject if `dune runtest` fails.

2. **`cycle/50` push blocked by proxy (infrastructure).** First scaffold
   push (`cf7e6aa`) landed normally. All subsequent pushes to
   `origin/cycle/50` return HTTP 403 from the local proxy — even simple
   fast-forwards, even after force-with-lease, even with a clean
   ASCII-only commit message and small diff. Fresh branches (e.g.
   `cycle/50-impl2`, `cycle/50-work`) accept pushes immediately. The
   full AC1–AC5 commit has been pushed to **`origin/cycle/50-work`**
   as a fallback so β / δ can access the work. Suggested resolution:
   δ may need to either (a) clear/relax the cycle/50 ref protection,
   (b) merge `cycle/50-work` over `cycle/50` via the GitHub UI, or
   (c) re-target the review to `cycle/50-work` for this cycle.

3. **`Hybrid_scoring.select_final` retains** the 0.10 per-axis
   agreement threshold for source selection. Out of scope for #50;
   not the cross-axis aggregate.

4. **No backward-compat shim.** Pre-1.0 breaking cutover per master
   scope. Reports with flat `c_sigma` are now rejected by the schema
   and no longer produced.

## Final branch state

- **Local `cycle/50` head**: `65fbe14` (AC1–AC5 cutover commit on top
  of scaffold `cf7e6aa`).
- **`origin/cycle/50` head**: `cf7e6aa` (scaffold only; further pushes
  blocked — see Known debt #2).
- **`origin/cycle/50-work` head**: `65fbe14` (full AC1–AC5 commit;
  fallback for β review).

The remote ref that carries the cycle's work is **`cycle/50-work`**
unless / until δ resolves the cycle/50 push block.

## What β should focus on

1. Schema/contract honesty: confirm `report.schema.json` rejects flat
   `c_sigma` and requires `provenance` at every public level. Run
   the schema against an actual mechanical run if possible
   (CI proof-plan in #50).

2. `Coherence.aggregate` routing: trace every public-JSON aggregate
   emission to `Coherence.aggregate` (no surviving arithmetic mean
   on the headline aggregate path). Confirm `weighted_avg` is only
   used for axis-internal signal scoring.

3. Comparison delta rename: confirm `delta_c_sigma` is gone from
   record, JSON, and `summary` string; both form-suffixed deltas
   carry the canonical aggregate difference.

4. Gauge-witness call-site discipline: confirm all three production
   call sites build the `c_sigma_fn` from `Coherence.aggregate`.

5. Text and kata: confirm both canonical aggregate forms are printed,
   no arithmetic-mean line remains, and kata range-check uses
   `c_sigma_num`.

6. Build/test: this is the verification CI runs. β should reject if
   `dune build` or `dune runtest` fails. Tests new in this cycle:
   `test_aggregate_uses_coherence_helper`,
   `test_hybrid_aggregate_uses_coherence_helper`,
   `test_comparison_delta_rename`, `test_aggregate_degeneracy`, plus
   the AC1 schema-presence and forbidden-field assertions inside
   `test_mechanical_json_schema` / `test_hybrid_json_schema` /
   `test_hybrid_preserves_both`.

## Blocker for δ

- **`cycle/50` push 403.** δ must either unblock `cycle/50` or accept
  `cycle/50-work` as the review/merge surface for this cycle.
