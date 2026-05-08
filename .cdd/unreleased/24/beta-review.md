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

---

## Round 2 — β re-review

**Verdict:** REQUEST CHANGES

**Round:** 2
**origin/main SHA:** 52d03873570b31971fed0bb106903fa200a0087d
**Cycle head SHA:** d5c3545d24160754878b51ffd82416822662ba76
**Fixed this round:** F1 (`036ee37`), F2 (`217ede5`), F4 (`0600608`) — resolved. F3 (`d600086`) — partial; introduced F5 below.
**Branch CI state:** green (`dune runtest` exits 0 at d5c3545, verified by β)
**Merge instruction:** pending resolution of F5

---

## §2.0.0 Contract Integrity (R2)

| Check | Result | Notes |
|---|---|---|
| Status truth preserved | yes | |
| Canonical sources/paths verified | yes | |
| Scope/non-goals consistent | yes | |
| Constraint strata consistent | partial | SELF-MEASURE.md §3.3 claims engine behavior not implemented — see F5 |
| Exceptions field-specific/reasoned | yes | |
| Path resolution base explicit | yes | |
| Proof shape adequate | yes | F1 and F2 close their AC integration paths |
| Cross-surface projections updated | partial | SELF-MEASURE.md §3.3 and response_schema.ml docstring claim engine derives beta; engine does not — see F5 |
| No witness theater / false closure | no | SELF-MEASURE.md §3.3 instructs LLM to set `beta=0.0` while claiming engine overwrites it; engine does not |
| PR body matches branch files | yes/n/a | |

---

## Fix verification (R2)

### F1 — extract_deltas wired in main.ml

**Resolved.** `run_llm` (main.ml:333–349) calls `Response_schema.extract_deltas j` after `validate_result` succeeds. The three `float option` values flow to `Report.to_json` via `~delta_alpha_beta:d_ab ~delta_beta_gamma:d_bg ~delta_gamma_alpha:d_ga`. The `validated_result` type is widened to `(result * d_ab * d_bg * d_ga) option`. The diff matches the R1 fix suggestion exactly.

### F2 — gauge_witness not called in report.ml::provenance_v320

**Resolved.** `provenance_v320` (report.ml:31–52) now constructs `c_sigma_fn` (geometric mean via `Coherence.aggregate`) and calls `Coherence.gauge_witness ~labeled:(s_alpha, s_beta, s_gamma) ~c_sigma_fn ~tau_gauge_spread:0.05`. All four W2 fields (`w_gauge_ref`, `w_gauge_spread`, `tau_gauge_spread`, `canonical_remap_procedure`) are passed to `Coherence.provenance_json`. W2 signals are no longer null in real reports.

### F3 — SELF-MEASURE.md §3.3 beta_preview approximation

**Partially resolved — introduces F5.**

The `beta_preview ≈ exp(−1.0 × Σδ / 3)` formula is removed from SELF-MEASURE.md §3.3. The bad LLM-side approximation is gone.

However, the replacement text in SELF-MEASURE.md §3.3 makes a false claim about engine behavior that is not implemented:

> `beta  = 0.0   (placeholder; the engine derives beta from the per-pair δ values)`
> `The engine derives beta from delta_alpha_beta, delta_beta_gamma, and delta_gamma_alpha deterministically. Do not compute Coh or any beta approximation yourself.`

Traced against the code: `to_json` (report.ml:57–100) emits `("beta", `Float result.result_beta)` where `result.result_beta` comes from `validate_result`'s `get_float "beta" json` — the raw LLM-provided field. The delta values are passed to `provenance_v320` but are used only as a presence gate for computing L_link constants; they are never used to derive or overwrite `result.result_beta`. The `validate_result` docstring in response_schema.ml repeats the same false claim: *"When present, the engine performs the barrier-transform chain deterministically instead of treating the LLM output as Coh directly."*

Consequence: when the LLM follows SELF-MEASURE.md instructions and emits `"beta": 0.0`, `result.result_beta = 0.0`, and all new reports will show `"beta": 0.0` with `C_sigma_math = 0.0` (since `gauge_witness` and `aggregate` receive `s_beta = 0.0`). This is a functional regression for all LLM-driven measurements.

### F4 — monotone_check label

**Resolved.** Format string corrected to `"AC1: monotone — coh[i]=%g >= coh[i+1]=%g"` (test_coherence.ml:53). The bound variables `a`/`b` are now correctly labelled as Coh values.

### Opam file

**Resolved.** `git diff origin/main origin/cycle/24-v320-engine -- engine/ocaml/tsc_engine.opam` is empty. The cycle branch opam file is identical to main. The uncommitted edits were discarded and not landed on the cycle branch.

---

## Findings (R2)

| # | Finding | Evidence | Severity | Type |
|---|---------|----------|----------|------|
| F5 | SELF-MEASURE.md §3.3 and response_schema.ml docstring claim "the engine derives beta from the per-pair δ values deterministically"; engine emits `result.result_beta` directly (0.0 as instructed to LLM by SELF-MEASURE.md); no derivation implemented; all new LLM reports will have `beta=0.0` and `C_sigma_math=0.0` | `report.ml:77`: `("beta", \`Float result.result_beta)` — LLM value passed through; no delta→beta derivation in `to_json` or `provenance_v320`; SELF-MEASURE.md §3.3 instructs `beta = 0.0` while claiming engine overwrites | C | judgment + contract |

---

## Regressions Required (D-level only)

None — F5 is C-tier.

---

## Notes

**F5 fix options:**

**Option A (minimal — doc truthfulness):** The engine currently does not derive beta from delta values, and the AC list does not specify a formula. Correct the false claim in two places:

1. `runtime/SELF-MEASURE.md` §3.3: replace `beta = 0.0 (placeholder...)` with:
   ```
   beta = s_beta  (provide a real score ∈ [0, 1], same as alpha/gamma)
   ```
   Remove the line: "The engine derives `beta` from `delta_alpha_beta`, `delta_beta_gamma`, and `delta_gamma_alpha` deterministically. Do not compute Coh or any beta approximation yourself."

2. `engine/ocaml/lib/response_schema.ml` docstring on `validate_result`: remove the sentence *"When present, the engine performs the barrier-transform chain deterministically (coherence.ml) instead of treating the LLM output as Coh directly."*

**Option B (implement derivation):** Add a beta derivation step in `report.ml::to_json` — compute Coh values from each delta using `Coherence.coherence_link`, then aggregate to an `s_beta` value and overwrite `result.result_beta`. Requires an explicit formula (not in the issue ACs). This would be beyond the declared cycle scope; β recommends Option A to close F5 within the current cycle scope.

β recommends Option A. If derivation is the desired design direction, file it as a new issue with an explicit formula before closing this cycle.

---

## Round 3 — β re-review

**Verdict:** APPROVED

**Round:** 3
**origin/main SHA:** 52d03873570b31971fed0bb106903fa200a0087d
**Cycle head SHA:** 3828d08a90ab406465a196f738693d9aea6df1d2
**Fixed this round:** F5 (`b6c15dc`) — resolved.
**Branch CI state:** green (doc-only fix; α confirmed `dune runtest` exits 0 at b6c15dc; F1–F4 fixes code-bearing, all passing per R2 verification)
**Merge instruction:** `git merge --no-ff cycle/24-v320-engine` into main with `Closes #24`

---

## §2.0.0 Contract Integrity (R3)

| Check | Result | Notes |
|---|---|---|
| Status truth preserved | yes | |
| Canonical sources/paths verified | yes | |
| Scope/non-goals consistent | yes | |
| Constraint strata consistent | yes | F5 fix removes false engine-derivation claim; all surfaces now agree |
| Exceptions field-specific/reasoned | yes | |
| Path resolution base explicit | yes | |
| Proof shape adequate | yes | |
| Cross-surface projections updated | yes | SELF-MEASURE.md §3.2 + §3.3 and response_schema.ml docstring are now consistent with engine behavior |
| No witness theater / false closure | yes | SELF-MEASURE.md §3.3 instructs LLM to provide real `beta = s_beta ∈ [0,1]`; no false engine-derivation claim |
| PR body matches branch files | yes/n/a | |

---

## Fix verification (R3)

### F5 — SELF-MEASURE.md §3.3 false engine-derivation claim

**Resolved.** α chose Option A (doc truthfulness) as β recommended.

1. **SELF-MEASURE.md §3.2**: Added `s_beta ∈ [0, 1]` as an LLM-estimated component score — "relational coherence score (β axis cross-file fit)". LLM is now explicitly instructed to estimate and provide this value.

2. **SELF-MEASURE.md §3.3**: Changed to `beta = s_beta` — instructs LLM to provide a real score in [0,1], not `0.0` placeholder. No mention of engine derivation.

3. **response_schema.ml `validate_result` docstring**: Now correctly states "The three top-level scores (alpha, beta, gamma) are LLM-provided values in [0, 1]; the delta fields carry per-pair discrepancy estimates used in provenance JSON." — no false engine-derivation claim.

4. **Grep confirmation (per α self-coherence R3)**: `grep -n "engine derives beta\|engine derives s_beta\|placeholder.*engine" runtime/SELF-MEASURE.md engine/ocaml/lib/response_schema.ml` → 0 hits.

The fix is complete and coherent: SELF-MEASURE.md now correctly describes the scoring contract (LLM provides real scores; engine applies barrier transform to δ values for provenance), and response_schema.ml accurately characterizes the validated fields.

---

## Findings (R3)

None. F5 resolved. No new findings.

---

## Approval scope

All seven ACs are evidenced in the diff. F1–F5 are resolved across rounds. CI green at branch head. No remaining incoherence found in the contract, implementation, or operator-visible surfaces.

β approves this branch for merge into main. Merge closes #24.
