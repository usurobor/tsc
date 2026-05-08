---
cycle: 24
role: alpha
status: final
merge_commit: 36d0fe5125b12d1e03a20fef52c6512b7d819627
---

# α Close-out — Cycle 24

**Final:** written post-merge per CDD §2.8 re-dispatch path. β approved at R3; merge commit `36d0fe5`.

---

## Cycle summary

Cycle 24 implements TSC spec v3.2.0 in the OCaml engine: barrier transform φ, discrepancy energy D, coherence link Coh = exp(−D), math/num aggregate split, L_link case-split, W2 gauge witness (ref+spread), v3.2.0 provenance JSON skeleton, SELF-MEASURE.md δ-based scoring protocol, and OOD cutover guard.

7 ACs delivered across 3 new modules (`coherence.ml`, `lipschitz.ml`, `ood.ml`), 2 extended modules (`report.ml`, `response_schema.ml`), 1 rewritten doc (`runtime/SELF-MEASURE.md`), 1 new test file (`test_coherence.ml`), and 1 new fixture schema (`provenance_v3_2_0.schema.json`).

Review: 3 rounds (R1 RC, R2 RC, R3 APPROVED). CDD §9.1 trigger fired (rounds exceeded 2).

---

## Review round record

| Round | Verdict | Findings | Head SHA |
|---|---|---|---|
| R1 | REQUEST CHANGES | F1 (C), F2 (C), F3 (B), F4 (A); opam note | `bbb681d` |
| R2 | REQUEST CHANGES | F5 (C) — F1/F2/F4 resolved; F3 partially resolved, introduced F5 | `d5c3545` |
| R3 | APPROVED | F5 resolved | `3828d08` (impl: `b6c15dc`) |

---

## Findings log

### F1 — `extract_deltas` not called from `main.ml` (C, R1→R2)

`Response_schema.extract_deltas` was implemented and tested in isolation. The self-coherence AC6 evidence row described the function's behavior without verifying the function was reachable from the engine entry point. `main.ml` was not in the diff; AC6 "done" status was claimed without checking the call path.

Fix: `run_llm` (main.ml:333–349) wired to call `extract_deltas` after `validate_result`; `validated_result` type widened to carry `(result * d_ab * d_bg * d_ga) option`; delta values passed to `Report.to_json`.

### F2 — `gauge_witness` not called from `report.ml::provenance_v320` (C, R1→R2)

`Coherence.gauge_witness` existed with no non-test callers. `provenance_v320` computed `agg` and `l_*` but passed `~w_gauge_ref:None` (and other W2 fields) as defaults to `Coherence.provenance_json`. W2 signals were always null in real reports. Same root pattern as F1.

Fix: `provenance_v320` now constructs `c_sigma_fn` (geometric mean via `Coherence.aggregate`) and calls `Coherence.gauge_witness`; all four W2 fields populated and passed to `provenance_json`.

### F3 — SELF-MEASURE.md §3.3 LLM-side `beta_preview` approximation (B, R1→R2 partial)

§3.3 instructed the LLM to compute `beta_preview ≈ exp(-1.0 * Σδ / 3)` — a Coh approximation. This contradicted AC6's negative criterion (LLM must not compute Coh or α/β/γ without going through δ). F3 was partially resolved in R1→R2 by removing the formula, but the replacement text introduced F5.

### F4 — `monotone_check` format string labeled Coh values as "delta=" (A, R1→R2)

`monotone_check` received Coh values (`List.map (Coherence.coherence_link ...) samples`) but the format string read `"AC1: monotone at delta=%g -> %g"`. Fixed by renaming to `"AC1: monotone — coh[i]=%g >= coh[i+1]=%g"`.

### F5 — False engine-derivation claim in SELF-MEASURE.md §3.3 and `validate_result` docstring (C, R2→R3)

The F3 fix replaced the `beta_preview` formula with text asserting: "The engine derives beta from the per-pair δ values deterministically." Traced against the code: `to_json` (report.ml:77) emits `("beta", \`Float result.result_beta)` — the raw LLM-provided field — with no derivation. The `validate_result` docstring in `response_schema.ml` repeated the same false claim in the same commit.

Consequence: the LLM was simultaneously instructed to set `beta = 0.0` as a placeholder and told the engine would overwrite it. The engine did not overwrite it. All reports following this instruction would emit `beta = 0.0` and `C_sigma_math = 0.0`.

Fix (Option A — doc truthfulness): SELF-MEASURE.md §3.3 corrected to `beta = s_beta` (LLM provides a real score ∈ [0,1]); `validate_result` docstring corrected to describe LLM-provided vs. engine-computed fields accurately. Grep confirmed zero residual occurrences of false-derivation language.

---

## Friction log

1. **Labeled-arg partial application** — OCaml labeled arguments cannot be partially applied for `List.map` without a lambda wrapper. Caught at build time; one-line fix.

2. **Near-continuity test tolerance** — initial `1e-6` tolerance on `L_link(1.9999) ~= 2.0` was too tight (|L_link(1.9999) - 2.0| ≈ 0.0001). Corrected to `5e-4`.

3. **AC6 end-to-end integration** — full oracle requires a live LLM provider (LLM_API_KEY not available). Integration test declared debt in self-coherence. The schema side validated via in-process JSON construction.

4. **Opam file** — `engine/ocaml/tsc_engine.opam` had uncommitted working-directory modifications (version `0.5.0`, odoc dependency, build variable names) not present on the cycle branch. β noted the discrepancy in R1 notes. Resolved by confirming and discarding the uncommitted edits; opam file on branch is identical to main.

---

## Patterns

### Pattern 1: function-exists ≠ function-reachable (F1, F2)

Two findings shared the same root: a function implemented and tested in isolation was declared "done" in the AC evidence table based on its existence, not based on whether it was called from the engine entry point. The self-coherence audit covered the function's unit behavior but did not trace the call graph from `main.ml` to verify the function was live in the runtime path.

Surfaces: `main.ml` (F1), `report.ml::provenance_v320` (F2).

### Pattern 2: write-before-verify on a doc claim about engine behavior (F5)

The fix for F3 described desired future engine behavior in the present tense ("engine derives beta…") before verifying the engine implements it. The claim appeared in two surfaces modified in the same commit (SELF-MEASURE.md and response_schema.ml). The self-coherence peer enumeration for that commit listed both surfaces as "corrected" without cross-checking against the actual runtime code path.

This is the same class as prior-cycle F3-bis (intra-doc repetition without grep-every-occurrence), applied to a cross-file behavioral claim rather than a numeric value.

### Pattern 3: partial-fix introduction of a new finding at higher impact (F3→F5)

F3 (B-tier, doc/behavior inconsistency) was partially resolved by removing one piece of incorrect text, but the replacement introduced F5 (C-tier functional regression): the LLM was instructed to provide a placeholder value that the engine was falsely claimed to overwrite. The impact of F5 was higher than F4 (A-tier label error) because it affected the correctness of all new LLM-driven measurements.

---

## Engineering-level reading

- The mathematical structure (φ → D → Coh) cleanly separates into three functions. The endpoint convention (`delta=1 → Coh=0`) is enforced by a guard, not by limit arithmetic.

- C_Σ^math and C_Σ^num are structurally different: math uses the product (strict zero at degeneracy), num uses the log-sum (uses epsilon floor). They coincide above ε — algebraic identity, not approximation.

- The W2 gauge witness spread is exactly 0 for any S₃-symmetric C_Σ function (geometric mean with equal weights). Non-trivial spread arises only with unequal axis weights or per-axis λ values.

- `report.ml::to_json` labeled optional args (`?param = None`) provided backward compatibility without call-site updates. The same interface pattern is available for future report field additions.

- The test suite uses `check cond label` assertions consistent with `test_mechanical.ml`. 69 assertions, no external dependencies, clear failure output.

- `coherence.ml::provenance_json` accepts all values as optional, enabling calls at any pipeline stage while emitting the correct JSON shape with nulls where values are absent.
