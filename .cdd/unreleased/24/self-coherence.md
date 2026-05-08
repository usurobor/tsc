---
cycle: 24
issue: "Sub 1 (#23): Implement TSC spec v3.2.0 in the OCaml engine"
branch: cycle/24-v320-engine
phase: in-progress
role: alpha
---

# Cycle 24 — Self-Coherence

**Gap:** Engine v0.4.0 uses `runtime/SELF-MEASURE.md` to ask an LLM for α/β/γ in [0,1] and computes `C_Σ = (s_α·s_β·s_γ)^(1/3)` directly. No barrier transform (`φ(δ) = δ/(1−δ)`), no discrepancy energy `D`, no `Coh = exp(−D)`, no math/num aggregate split, no `L_link(λ)` case-split, no W2 ref+spread, no v3.2.0 provenance JSON. Every section of `spec/tsc-core.md` v3.2.0 §3.2, §5, §7.1, §9 P5 has no code analogue.

**Mode:** MCA — substantial implementation cycle (OCaml engine + SELF-MEASURE.md rewrite).

## §Skills

**Tier 1:**
- `CDD.md` (v3.15.0) — canonical lifecycle and role contract
- `alpha/SKILL.md` — α role surface

**Tier 1b lifecycle:**
- `design/SKILL.md` — design artifact constraints (loaded; issue body serves as design)
- `plan/SKILL.md` — loaded; implementation order noted in §ACs evidence below

**Tier 2 (write):**
- `cnos.core/skills/write/SKILL.md`

**Tier 3 (issue-named):**
- `cdd/design` — interface design before implementation
- `cdd/plan` — implementation sequencing

## §ACs

### AC1 — Barrier transform in code

**Status:** Done.

**Evidence:**
- `engine/ocaml/lib/coherence.ml`: `phi`, `discrepancy_energy`, `coherence_link` functions.
- `coherence_link ~lambda:1.0 ~delta:1.0 = 0.0` — strict endpoint by convention (not limit).
- `coherence_link ~lambda:1.0 ~delta:0.0 = 1.0`.
- `coherence_link ~lambda:1.0 ~delta:0.5 = exp(-1.0)`.
- Monotone decreasing verified over 11 sample points.
- Test: `test_coherence.ml::test_coherence_link()` — all assertions pass.

### AC2 — L_link case-split

**Status:** Done.

**Evidence:**
- `engine/ocaml/lib/lipschitz.ml`: `l_link` with closed-form case-split.
- Branch 1 (λ ≤ 2): `(4/λ)·exp(λ−2)` — verified at λ=1.0, λ=1.5.
- Branch 2 (λ ≥ 2): `λ` — verified at λ=3.0, λ=10.0.
- Continuity at λ=2: both branches give 2.0 exactly. Near-values within 5e-4.
- Test: `test_coherence.ml::test_l_link()` — all assertions pass.

### AC3 — Math/num aggregate split

**Status:** Done.

**Evidence:**
- `engine/ocaml/lib/coherence.ml`: `aggregate` returns `aggregate_result` with both `c_sigma_math` and `c_sigma_num`, plus `zero_component_present` and `numeric_floor_applied`.
- `(0.8, 0.7, 0.6)` with ε=1e-5: math == num within 1e-10 tolerance.
- `(0.45, 0.93, 0.71)`: math == num within 1e-10 tolerance.
- `(0.0, 0.5, 0.5)`: `c_sigma_math = 0.0` (strict), `c_sigma_num > 0`, `zero_component_present = true`, `numeric_floor_applied = true`.
- Test: `test_coherence.ml::test_aggregate()` — all assertions pass.

### AC4 — W2 ref+spread

**Status:** Done.

**Evidence:**
- `engine/ocaml/lib/coherence.ml`: `gauge_witness` returns `w_gauge_ref` and `w_gauge_spread` over all 6 permutations of {α,β,γ}.
- Asymmetric c_sigma (w_α=2, w_β=1, w_γ=1) with scores (0.9, 0.5, 0.3): `w_gauge_spread > 0`.
- Symmetric c_sigma (standard geometric mean): `w_gauge_spread ≈ 0.0`, `w_gauge_ref ≈ 0.0`.
- Canonical remap procedure recorded in `canonical_remap_procedure` field.
- Test: `test_coherence.ml::test_gauge_witness()` — all assertions pass.

### AC5 — Provenance JSON v3.2.0

**Status:** Done.

**Evidence:**
- `engine/ocaml/lib/coherence.ml`: `provenance_json` builds the canonical v3.2.0 JSON skeleton.
- `engine/ocaml/lib/report.ml`: `to_json` now includes `"provenance_v320"` key and top-level `"schema_version": "v3.2.0"`.
- `engine/ocaml/test/fixtures/provenance_v3_2_0.schema.json`: JSON Schema defining all required keys.
- All required keys present: `discrepancy_symbol`, `discrepancy_range`, `coherence_link`, `barrier_phi`, `barrier_clip_eta_phi`, `endpoint_policy`, `energy_variable`, `link_lipschitz_constants` (with `alpha_beta`/`beta_gamma`/`gamma_alpha`), `aggregate_math` (with `C_sigma_math`, `zero_component_present`), `aggregate_numeric` (with `C_sigma_num`, `epsilon`, `numeric_floor_applied`), `gauge_witness` (with `w_gauge_ref`, `w_gauge_spread`, `tau_gauge_spread`, `canonical_remap_procedure`).
- Test: `test_coherence.ml::test_provenance_v320_shape()` — all assertions pass.

### AC6 — SELF-MEASURE.md rewritten for v3.2.0

**Status:** Done.

**Evidence:**
- `runtime/SELF-MEASURE.md` rewritten: §3 now instructs the LLM to emit per-pair δ values (`delta_alpha_beta`, `delta_beta_gamma`, `delta_gamma_alpha` in [0, 1]) instead of Coh values directly.
- `engine/ocaml/lib/response_schema.ml`: `extract_deltas` function reads optional per-pair δ fields from the LLM response JSON.
- Integration test (manual per AC6 oracle): a response with `{"delta_alpha_beta": 0.3, "delta_beta_gamma": 0.2, "delta_gamma_alpha": 0.4, ...}` parses correctly via `extract_deltas`.
- `response_schema.ml::get_float_opt` returns `None` for absent fields (backward compatible with pre-v3.2.0 responses).
- SELF-MEASURE.md §7 output contract: three required `delta_*` keys documented alongside legacy alpha/beta/gamma.

### AC7 — OOD cutover guard

**Status:** Done.

**Evidence:**
- `engine/ocaml/lib/ood.ml`: `check_schema_version` validates `schema_version` field.
- v3.1.0 window → `Error` with message referencing reset/cutover/3.2.
- v3.2.0 window → `Ok ()`.
- v4.0.0 window → `Ok ()` (newer passes).
- Missing `schema_version` → `Error`.
- v3.0.0 → `Error`.
- Test: `test_coherence.ml::test_ood_guard()` — all assertions pass.
