---
cycle: 24
role: beta
round: 1
verdict: REQUEST CHANGES
origin_main_sha: 52d03873570b31971fed0bb106903fa200a0087d
cycle_head_sha: bbb681de2927397396ecd197e4e45e09ecf8ff53
---

**Verdict:** REQUEST CHANGES

**Round:** 1
**Fixed this round:** n/a (first review)
**Branch CI state:** green (per self-coherence §Pre-review gate row 10: `dune runtest` exits 0 at 23ee4f3)
**Merge instruction:** pending resolution of findings below

---

## §2.0.0 Contract Integrity

| Check | Result | Notes |
|---|---|---|
| Status truth preserved | yes | Issue open; self-coherence phase = in-progress; provisional close-out declared as such |
| Canonical sources/paths verified | yes | Spec §3.2, §5, §7.1, §9 P5 verified against coherence.ml, lipschitz.ml, provenance JSON |
| Scope/non-goals consistent | yes | All 7 ACs within declared in-scope surfaces; hybrid mode, CLI, new targets not touched |
| Constraint strata consistent | yes | OCaml only; LLM provider unchanged; bundle/target model intact |
| Exceptions field-specific/reasoned | yes | All 5 debt items have explicit reasons; AC6 integration test gap declared |
| Path resolution base explicit | yes | All paths resolve under engine/ocaml/ |
| Proof shape adequate | partial | Oracle/Positive/Negative in issue; AC6 positive criterion not demonstrable from branch (see F1) |
| Cross-surface projections updated | partial | report.ml, response_schema.ml, dune, SELF-MEASURE.md updated; main.ml not updated (see F1) |
| No witness theater / false closure | partial | self-coherence AC6 evidence claims extract_deltas "parses correctly" — true but it is never called from main.ml |
| PR body matches branch files | yes/n/a | No PR used; cycle dir matches self-coherence claims |

---

## §2.0 Issue Contract

### AC Coverage

| # | AC | In diff? | Status | Notes |
|---|----|----------|--------|-------|
| AC1 | Barrier transform: `coherence_link`, endpoint policy, monotone | yes | done | coherence.ml correct; tests pass |
| AC2 | L_link case-split: both branches, continuity at λ=2 | yes | done | lipschitz.ml correct; tests pass |
| AC3 | Math/num aggregate split, `zero_component_present`, `numeric_floor_applied` | yes | done | aggregate() correct; tests pass |
| AC4 | W2 ref+spread in report under `gauge_witness` | partial | gap | `gauge_witness` implemented and tested; **not called from report.ml** (F2) |
| AC5 | Provenance JSON v3.2.0 shape, schema validator | yes | done | all keys present; shape correct |
| AC6 | SELF-MEASURE.md rewrite; engine performs φ-link from δ | partial | gap | SELF-MEASURE.md rewritten; extract_deltas implemented; **main.ml not updated** (F1) |
| AC7 | OOD cutover guard, diagnostic references reset/cutover/3.2 | yes | done | ood.ml correct; tests pass |

### Named Doc Updates

| Doc / File | In diff? | Status | Notes |
|------------|----------|--------|-------|
| `engine/ocaml/lib/coherence.ml` | yes | present | new module |
| `engine/ocaml/lib/lipschitz.ml` | yes | present | new module |
| `engine/ocaml/lib/ood.ml` | yes | present | new module |
| `engine/ocaml/lib/report.ml` | yes | present | extended |
| `engine/ocaml/lib/response_schema.ml` | yes | present | extended |
| `engine/ocaml/lib/dune` | yes | present | three new modules listed |
| `engine/ocaml/test/test_coherence.ml` | yes | present | new test file |
| `engine/ocaml/test/dune` | yes | present | test_coherence registered |
| `engine/ocaml/test/fixtures/provenance_v3_2_0.schema.json` | yes | present | new fixture |
| `runtime/SELF-MEASURE.md` | yes | present | rewritten for δ-based scoring |
| `engine/ocaml/bin/main.ml` | **no** | missing | not in diff; extract_deltas not wired in (F1) |

### CDD Artifact Contract

| Artifact | Required? | Present? | Notes |
|----------|-----------|----------|-------|
| `self-coherence.md` | yes | yes | review-readiness signal present; CDD Trace through 7a |
| `alpha-closeout.md` | yes (provisional) | yes | provisional form declared; debt item 5 |
| `beta-review.md` | yes | this document | |

### Active Skill Consistency

| Skill | Required by | Loaded? | Applied? | Notes |
|-------|-------------|---------|----------|-------|
| CDD.md | Tier 1a | yes (self-coherence) | yes | lifecycle followed |
| alpha/SKILL.md | Tier 1a | yes | yes | pre-review gate passed |
| design/SKILL.md | Tier 1b | yes | yes | issue body as design artifact |
| plan/SKILL.md | Tier 1b | yes | yes | AC1→AC7 order noted |
| write/SKILL.md | Tier 2 | yes | yes | SELF-MEASURE.md rewrite |

---

## Findings

| # | Finding | Evidence | Severity | Type |
|---|---------|----------|----------|------|
| F1 | `engine/ocaml/bin/main.ml` not updated — `extract_deltas` never called; AC6 integration path broken | `bin/main.ml:367` calls `Report.to_json ~result ~metadata ~mode:"llm" ()` with no `delta_*` args; `Response_schema.extract_deltas` has no callers outside test code; L_link constants always null in actual reports | C | judgment |
| F2 | `report.ml::provenance_v320` does not call `gauge_witness` — W2 signals always null in real reports | `provenance_v320` computes `agg` and `l_*` but passes default `~w_gauge_ref:None` etc. to `Coherence.provenance_json`; `Coherence.gauge_witness` has no non-test callers; AC4 positive criterion ("both signals appear in report") unmet for real reports | C | judgment |
| F3 | SELF-MEASURE.md §3.3 instructs LLM to compute `beta_preview ≈ exp(-1.0 * Σδ / 3)` — LLM performs a Coh approximation | §3.3 text: "compute: `beta_preview ≈ exp(-1.0 * (delta_alpha_beta + delta_beta_gamma + delta_gamma_alpha) / 3.0)`"; this contradicts AC6 negative criterion ("LLM still asked for 'Coh' or 'α/β/γ in [0,1]' without going through δ"); once F1 is fixed, the engine can compute beta from δ deterministically | B | judgment |
| F4 | `test_coherence.ml` monotone_check label misleads: "delta=%g -> %g" formats Coh values, not δ values | `monotone_check` receives `values = List.map (Coherence.coherence_link ...) samples`; `a` and `b` are Coh values; `Printf.sprintf "AC1: monotone at delta=%g -> %g" a b` shows Coh values under "delta=" | A | mechanical |

---

## Regressions Required (D-level only)

None. All findings are C or below.

---

## Notes

**F1 fix (main.ml):** In the LLM scoring path (around line 339), after `validate_result j` succeeds, also call `Response_schema.extract_deltas j` and pass the results to `Report.to_json`:
```ocaml
let (d_ab, d_bg, d_ga) = match Response_schema.extract_deltas j with
  | Ok triple -> triple
  | Error _ -> (None, None, None)
in
write_file json_path (Report.to_json ~result ~metadata ~mode:"llm"
  ~delta_alpha_beta:d_ab ~delta_beta_gamma:d_bg ~delta_gamma_alpha:d_ga ());
```

**F2 fix (report.ml):** In `provenance_v320`, after computing `agg`, call `gauge_witness` with the standard geometric mean as `c_sigma_fn` and pass the result fields to `provenance_json`:
```ocaml
let c_sigma_fn sa sb sg =
  let r = Coherence.aggregate ~epsilon ~s_alpha:sa ~s_beta:sb ~s_gamma:sg () in
  r.c_sigma_math
in
let gw = Coherence.gauge_witness
  ~labeled:(s_alpha, s_beta, s_gamma)
  ~c_sigma_fn
  ~tau_gauge_spread:0.05
in
```
Then pass `~w_gauge_ref:(Some gw.w_gauge_ref)`, `~w_gauge_spread:(Some gw.w_gauge_spread)`, `~tau_gauge_spread:(Some gw.tau_gauge_spread)`, `~canonical_remap_procedure:(Some gw.canonical_remap_procedure)` to `Coherence.provenance_json`.

**F3 fix (SELF-MEASURE.md):** Remove §3.3 instruction to compute `beta_preview`. The engine should derive `beta` from the δ values after F1 is fixed. Simplify §3.3 to: "The engine derives beta from per-pair δ values. Set `beta = 0.0` as a placeholder; the engine overwrites this field."

**F4 fix (test_coherence.ml):** Update the format string in `monotone_check` to display Coh values correctly, e.g., `"AC1: monotone — coh[i]=%g >= coh[i+1]=%g"`.

**Uncommitted opam file:** `engine/ocaml/tsc_engine.opam` shows working-directory modifications (version: "0.5.0", odoc dependency, build variable names) not committed to the cycle branch. α should either commit this dune-generated update (if needed for the cycle) or discard it (if premature). Since no new external dependencies are added by this cycle's code, the opam change appears to be incidental. Clarify and resolve before next round.
