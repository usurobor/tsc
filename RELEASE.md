# RELEASE.md

**Release:** TSC Engine v0.6.0 — Spec v3.2.0 OCaml Implementation
**Issue:** #24 (Sub 1 of master #23)
**Branch merged:** cycle/24-v320-engine → main
**Merge commit:** 36d0fe5125b12d1e03a20fef52c6512b7d819627
**Date:** 2026-05-08

## Outcome

Coherence delta: C_Σ B+ (`α B+`, `β A`, `γ B+`) · **Level:** L6

The OCaml engine now implements the full TSC spec v3.2.0 transformation chain. The v0.5.0 engine asked the LLM for `α/β/γ ∈ [0,1]` scores and computed `C_Σ = (s_α·s_β·s_γ)^(1/3)` directly. The v0.6.0 engine asks the LLM for per-pair discrepancy values (δ), applies the barrier transform `φ(δ) = δ/(1−δ)` deterministically, and computes coherence via the full chain `D = Σ_λ w_λ·φ(δ_λ)` and `Coh = exp(−D)`. Every report now carries the canonical v3.2.0 provenance JSON skeleton.

## What shipped

- **`engine/ocaml/lib/coherence.ml`** (new) — barrier transform (`phi`, `discrepancy_energy`, `coherence_link`), math/num aggregate split (`aggregate_math`, `aggregate_numeric`, `zero_component_present`, `numeric_floor_applied`), W2 gauge witness (`gauge_witness` with `w_gauge_ref`, `w_gauge_spread`, `tau_gauge_spread`, `canonical_remap_procedure`), provenance JSON assembly (`provenance_json`).
- **`engine/ocaml/lib/lipschitz.ml`** (new) — L_link case-split: `(4/λ)·exp(λ−2)` for `0 < λ ≤ 2`, `λ` for `λ ≥ 2`, continuous at `λ = 2`.
- **`engine/ocaml/lib/ood.ml`** (new) — OOD cutover guard: refuses or warns when a reference window carries `schema_version < "v3.2.0"`, emitting the reset diagnostic.
- **`engine/ocaml/lib/report.ml`** (extended) — `to_json` accepts optional `delta_alpha_beta`, `delta_beta_gamma`, `delta_gamma_alpha` and wires them into provenance via `provenance_v320`; `provenance_v320` calls `Coherence.gauge_witness` and `Lipschitz.l_link` so W2 and L_link fields are populated in real reports.
- **`engine/ocaml/lib/response_schema.ml`** (extended) — `extract_deltas` parses per-pair δ values from LLM JSON; `validate_result` docstring corrected to accurately describe LLM-provided vs. engine-computed fields.
- **`engine/ocaml/bin/main.ml`** (extended) — `run_llm` calls `extract_deltas` after `validate_result` and passes δ values to `Report.to_json`.
- **`engine/ocaml/test/test_coherence.ml`** (new) — 69 assertions covering AC1–AC7: barrier transform endpoint policy, L_link case-split and continuity, math/num aggregate split, W2 gauge witness, OOD cutover diagnostic.
- **`engine/ocaml/test/fixtures/provenance_v3_2_0.schema.json`** (new) — JSON schema for all required v3.2.0 provenance keys.
- **`runtime/SELF-MEASURE.md`** (rewritten) — LLM backend instructions updated for δ-based scoring: LLM provides per-pair discrepancy values (δ_αβ, δ_βγ, δ_γα) and per-component scores (s_α, s_β, s_γ) directly; engine applies the transformation chain deterministically.

## Review summary

Three rounds. R1 (4 findings): two integration-wiring gaps (new modules not wired into runtime call path) and two behavioral findings (LLM asked to compute a Coh approximation; test label mislabeled Coh values as δ values). R2 (1 finding): write-before-verify — fix for R1 F3 replaced a bad LLM instruction with a false engine-behavior claim. R3: approved. Single implementation root (pre-review caller-path check missing); all findings closed before merge.

## Known debt carried forward

- **AC6 integration test (live LLM):** full end-to-end oracle requires a live LLM provider (`LLM_API_KEY`). The schema side is validated via fixture; the δ-extraction path through `main.ml` is wired but not exercised end-to-end in this environment.
- **Beta derivation from δ:** engine currently passes `s_beta` through from the LLM (unchanged). Deriving `s_beta` deterministically from `δ_αβ, δ_βγ, δ_γα` is a deferred design extension (requires an explicit formula; not in this cycle's ACs).
- **Pre-review gate skill patch:** `alpha/SKILL.md` §2.6 in the `cnos` repo needs a "verify non-test callers for new module wiring" row. Filed as a project MCI for the next cnos CDD cycle.
- **Master #23:** Sub 3 (test migration) remains open.
