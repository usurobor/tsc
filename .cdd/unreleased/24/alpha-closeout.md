---
cycle: 24
role: alpha
status: provisional — pending β outcome
---

# α Close-out — Cycle 24 [provisional]

**Provisional:** written at review-readiness time per CDD §1.6a fallback (bounded dispatch model; β has not yet reviewed). γ supplements with PRA observations.

---

## Cycle summary

Cycle 24 implements TSC spec v3.2.0 in the OCaml engine: barrier transform φ, discrepancy energy D, coherence link Coh = exp(−D), math/num aggregate split, L_link case-split, W2 gauge witness (ref+spread), v3.2.0 provenance JSON skeleton, SELF-MEASURE.md δ-based scoring protocol, and OOD cutover guard.

7 ACs delivered across 3 new modules (`coherence.ml`, `lipschitz.ml`, `ood.ml`), 2 extended modules (`report.ml`, `response_schema.ml`), 1 rewritten doc (`runtime/SELF-MEASURE.md`), 1 new test file (`test_coherence.ml`), and 1 new fixture schema.

---

## Friction log

1. **Labeled-arg partial application** — OCaml labeled arguments cannot be partially applied for `List.map` without a lambda wrapper. Caught at build time on first run; one-line fix. No process gap.

2. **Near-continuity test tolerance** — initial `1e-6` tolerance on `L_link(1.9999) ~= 2.0` was too tight (|L_link(1.9999) - 2.0| ≈ 0.0001). Corrected to `5e-4`. The test was correct in intent; the tolerance needed to match the distance from the boundary point.

3. **AC6 end-to-end integration** — full oracle requires a live LLM provider (LLM_API_KEY not available in this environment). Integration test is declared debt. The schema side (response_schema.ml `extract_deltas`) is validated via in-process JSON construction.

---

## Observations

- The mathematical structure (φ → D → Coh) cleanly separates into three functions: `phi`, `discrepancy_energy`, `coherence_link`. The endpoint convention (`delta=1 → Coh=0`) is enforced by a guard, not by limit arithmetic.

- C_Σ^math and C_Σ^num are structurally different: math uses the product (strict zero at degeneracy), num uses the log-sum (uses epsilon floor). They coincide above ε — this is not an approximation but an algebraic identity when all sᵢ ≥ ε.

- The W2 gauge witness spread is exactly 0 for any S₃-symmetric C_Σ function (geometric mean with equal weights). The spread signal is only non-trivial when the function uses unequal axis weights or per-axis λ values. This is correct behavior, not a limitation.

- `ood.ml` is minimal and correct. The only logic is version comparison. The cutover diagnostic message includes "reset" and "3.2" per the AC7 oracle.

- `report.ml::to_json` signature: optional labeled args with `None` defaults make the change backward-compatible without any call-site updates needed. This was the right interface choice.

---

## Engineering-level reading

Pattern observations only — no dispositions.

- OCaml's labeled optional argument design (`?param = None`) provided clean backward compatibility for the `to_json` extension. The same pattern should be usable for any future report field additions.

- The test suite uses a simple pass/fail assertion style (`check cond label`) consistent with the existing `test_mechanical.ml`. This style has no external dependencies and produces clear output. The pattern held up for 69 assertions without friction.

- `coherence.ml::provenance_json` accepts all values as optional (`~field = None` defaults) so it can be called at any point in the pipeline — even before per-pair δ values are available — while still emitting the correct JSON shape with nulls. This matches the spec's requirement for the skeleton to always be present.
