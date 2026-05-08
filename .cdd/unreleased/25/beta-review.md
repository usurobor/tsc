# β-Review — Issue #25
# Sub 2 (#23): Complete v0.5.0 hybrid scoring

**Reviewer:** β
**Round:** 1
**Implementation SHA reviewed:** bc9d301
**Date:** 2026-05-08

---

## Disposition: Change Request → Re-review

One correctness bug (F1) must be fixed before merge. Everything else verifies. β will approve on resubmission once F1 is resolved; no other changes required.

---

## Build and Test Verification

| Check | Result |
|---|---|
| `dune build` | Clean — no warnings, no errors |
| `dune exec test/test_mechanical.exe` | **61/61 pass** (α claimed 58 — see F2) |
| `git diff main..cycle/25 -- '*.py'` | 0 lines (AC8 confirmed) |
| No credential read in `run_mechanical` path | Confirmed (AC1) |
| `--mode` / `--files` CLI | Confirmed in `bin/main.ml` (AC1, AC4) |
| `auto` fallback reads `LLM_API_KEY` | Confirmed (AC11) |
| `Report.to_json ~mode` backward-compatible | Confirmed — optional labeled arg (AC2, AC10) |
| `Hybrid_scoring.to_json` emits mechanical/llm/final | Confirmed (AC3, AC12) |
| README/QUICKSTART/ARCHITECTURE name all modes | Confirmed (AC7) |

---

## Findings

### F1 — MUST FIX — `sig_traceability_presence`: bare `"#"` in keyword list

**Location:** `engine/ocaml/lib/mechanical_scoring.ml:588`

```ocaml
let trace_kws = ["changelog"; "closes #"; "fixes #"; "issue #"; "#"] in
```

The bare string `"#"` is a substring match (`str_contains`). Every Markdown file that contains a heading matches — because all headings begin with `#`. This means the signal fires as true for virtually every file in any real bundle, making `traceability_presence` a heading-detector rather than a traceability-detector. The signal's discriminatory power is zero in practice.

This is not a calibration issue (existing debt acknowledges calibration imprecision): calibration concerns weight tuning, not semantic inversion of a signal. The `"#"` item breaks the invariant that `files_with_trace` reflects actual traceability markers.

**Fix:** remove `"#"` from `trace_kws`. The remaining keywords (`"closes #"`, `"fixes #"`, `"issue #"`, `"changelog"`) cover the intended patterns. Files with no traceability markers will correctly return the baseline `0.5` score.

```ocaml
(* before *)
let trace_kws = ["changelog"; "closes #"; "fixes #"; "issue #"; "#"] in
(* after *)
let trace_kws = ["changelog"; "closes #"; "fixes #"; "issue #"] in
```

---

### F2 — NOTE (no fix required) — Test count discrepancy and schema fixture not loaded

The self-coherence claims 58 assertions. Actual run: **61 passes**. α undercounted — the `test_score_ranges` function emits 12 per-signal assertions (4 per axis × 3 axes), not counted in α's total. The test suite is not deficient; the count in the self-coherence document is inaccurate.

Additionally, the AC6 oracle claim reads: *"Schema validator against `engine/ocaml/test/fixtures/report.schema.json`"*. The fixture exists and is correct, but the tests do not load it programmatically — they perform inline field checks. The fixture is reference documentation, not a live oracle. Both the fixture and the inline checks are coherent; the claim slightly overstates the integration. This is acceptable for V1 but worth correcting in the self-coherence when α addresses the re-review.

---

## AC-by-AC Verification (β independent read)

| AC | β Verdict | Notes |
|----|-----------|-------|
| AC1 | ✓ | `run_mechanical` reads no credentials; `score_bundle` is pure computation |
| AC2 | ✓ | `run_llm` path unchanged except `Report.to_json ~mode:"llm"` — backward-compat |
| AC3 | ✓ | `Hybrid_scoring.to_json` emits `mechanical`, `llm`, `final`; `final.source` ∈ {llm, mechanical, agreement} |
| AC4 | ✓ | `Bundle.build_bundle` sorts by path; both input paths call same function; test passes |
| AC5 | ✓ | `score_files` is pure; two runs produce identical `c_sigma`; property test passes |
| AC6 | ✓ (with F2 note) | Schema shape confirmed by inline tests; fixture is static reference |
| AC7 | ✓ | README, QUICKSTART, ARCHITECTURE each enumerate mechanical/llm/hybrid/auto and show `--files` usage |
| AC8 | ✓ (partial, known) | Zero Python lines in diff; pre-existing Python owned by Sub 3 |
| AC9 | ✓ | `cli_instruction` defaults to `"runtime/SELF-MEASURE.md"`; `run_llm` reads it |
| AC10 | ✓ | `Report.to_json ~mode` adds top-level `"mode"` field; mechanical and hybrid emit `"mode"` independently |
| AC11 | ✓ | `has_llm_credentials()` checks `LLM_API_KEY`; auto dispatch in `main.ml` confirmed |
| AC12 | ✓ | `hyb_mech` and `hyb_llm` are preserved fields on `Hybrid_scoring.result`; both subobjects emitted in JSON; `test_hybrid_preserves_both` passes |

---

## Architecture Notes (no action required)

- `sig_source_of_truth_alignment` and `sig_cross_reference_consistency` use slightly different link-resolution predicates (substring vs prefix-match). Both are conservative; no AC is affected. Acceptable for V1.
- `hyb_final_csigma = (fa +. fb +. fg) /. 3.0` is a simple average, not weighted by `mechanical_scoring` config weights. Consistent with DESIGN.md §5 which specifies unweighted final score. Correct.
- `has_llm_credentials()` reads only `LLM_API_KEY`. Future multi-provider support (Sub 5) should extend this check. Not in scope here.

---

## Required before re-review

- [ ] Remove bare `"#"` from `trace_kws` in `mechanical_scoring.ml:588` (F1)
- [ ] Update self-coherence: correct test count to 61; correct AC6 oracle claim to "inline field checks; fixture is reference documentation"
- [ ] Re-run `dune exec test/test_mechanical.exe` — all tests should still pass after F1 fix (the fixture files happen to contain real traceability markers via `"closes #"` / `"changelog"` etc.)

---

## Post-fix disposition

β will approve on resubmission if:
1. F1 fix lands cleanly (`dune build` green, 61/61 still pass)
2. Self-coherence updated per above
3. No new surfaces introduced

---

# Round 2 — APPROVED

**Verdict:** APPROVED

**Round:** 2
**origin/main SHA at review base:** 56af43a3d03427cf739741c278121273d0ce1207
**Branch head SHA:** 2ef36ce05266c6bfd316488b4a0f1205c9953914
**Fixed this round:** 45b16bf (F1 fix + beta-review.md), 2ef36ce (self-coherence fix-round)
**Branch CI state:** green (merge-tree: 61/61 pass, `dune build` clean)
**Merge instruction:** `git merge --no-ff cycle/25` into main with `Closes #25`

## R2 Verification

### F1 resolved
`trace_kws` at `mechanical_scoring.ml:588` now reads:
```ocaml
let trace_kws = ["changelog"; "closes #"; "fixes #"; "issue #"] in
```
Bare `"#"` removed. Confirmed by `git show origin/cycle/25:engine/ocaml/lib/mechanical_scoring.ml | grep trace_kws`.

### F2 (note) resolved
- Test count corrected to 61 throughout self-coherence (§Impact Graph, §Self-check, §CDD Trace).
- AC6 oracle claim corrected to "inline field checks; fixtures/report.schema.json is reference documentation (not loaded programmatically)".

### Test suite on merge tree
`dune exec test/test_mechanical.exe` on the pre-committed merge tree (`origin/main` merged with `origin/cycle/25`): 61/61 pass, zero unmerged paths, zero new validator findings.

### Pre-merge gate
| Row | Result |
|---|---|
| 1 Identity truth | `beta@cdd.tsc` ✓ |
| 2 Canonical-skill freshness | `origin/main` @ 56af43a confirmed current before review; no re-load required |
| 3 Non-destructive merge-test | Clean merge, 61/61 on merge tree, worktree torn down |

No new findings. Search space closed. Branch is coherent and ready to merge.
