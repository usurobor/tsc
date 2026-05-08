# Self-Coherence — v3.2.0

**Issue:** #29 (Sub 6 of #23)
**Engine:** v0.7.0 (OCaml, implementing spec v3.2.0)
**Mode:** mechanical (no LLM credentials present; hybrid deferred — see §Known Gaps)
**Date:** 2026-05-08

---

## Summary

TSC v3.2.0 measures itself with the v3.2.0-conformant OCaml engine. Three canonical targets were run: `spec`, `engine`, `repo`.

| Target | α | β | γ | C_Σ | Bottleneck |
|--------|---|---|---|-----|------------|
| spec   | 0.968 | 0.910 | 0.815 | 0.898 | γ |
| engine | 0.650 | 0.225 | 0.687 | 0.521 | **β** |
| repo   | 0.915 | 0.385 | 0.680 | 0.660 | **β** |
| **aggregate** | — | — | — | **0.675** | β |

Aggregate C_Σ = (0.898 × 0.521 × 0.660)^(1/3) = **0.675** — grade C+. The bottleneck is β across all three targets. The dominant gap is in the engine target (β = 0.225), driven largely by build artifacts in the corpus.

---

## Per-Target Results

### spec (theory corpus)

**α = 0.968** — Pattern coherence is strong. Terminology is consistent across all 156 heading phrases. All 5 spec files have H1 headers. Naming drift (camelCase vs. snake_case: 5 vs. 19) creates minor tension.

**β = 0.910** — Relational coherence is high. No internal cross-references, so cross-reference_consistency = 1.0. Authority alignment deducted because 5 files carry authority-claim language with no single declared authority file (spec/tsc-core.md is canonical but no machine-readable authority declaration is present).

**γ = 0.815** — Process coherence is the bottleneck. `traceability_presence = 0.5` (no structured traceability markers in spec files). `version_surface_consistency = 0.859` (64 version occurrences across 10 unique values including sub-version strings in spec prose). The spec contains version identifiers like "1.0.10–1.0.14" as internal section references, not release versions, creating false multiplicity.

**C_Σ = 0.898** — Bottleneck lever: traceability markers and version-surface discipline in the spec corpus.

**CI:** Point estimate; mechanical mode has no bootstrap CI. Confidence = 1.0 (deterministic structural proxy).

---

### engine (implementation corpus)

**α = 0.650** — Pattern coherence is impaired. The `repeated_structure` signal scores 0.0: 0/2 markdown-bearing files have H1 headers (dune build files have none, expected). `duplicate_definition_tension = 0.5` (shared heading labels like "section one/two" in test fixtures). The OCaml source itself scores well on naming drift (no mixed identifiers in headings).

**β = 0.225** — Relational coherence is the major bottleneck. `cross_reference_consistency = 0.0` (5/5 detected links unresolved) and `authority_alignment = 0.0` (23 files with authority-claim language).

**Root cause of β = 0.225:** The `engine/ocaml/**/*.ml` glob walks into `engine/ocaml/_build/` and includes compiled build artifacts in the corpus (58-file bundle includes generated files like `_build/default/lib/coherence.ml`, `_build/default/lib/hybrid_scoring.ml`). These generated files carry cross-references and authority-claim language that fail against the corpus boundary. This is a target-definition gap: `engine.tsc` lacks an explicit `_build/**` exclusion.

Without the build-artifact inflation, β would be materially higher. This is the primary finding.

**γ = 0.687** — Process coherence is moderate. `traceability_presence = 0.052` (3/58 files have traceability markers). Build-artifact files drag the denominator up without contributing traceability.

**C_Σ = 0.521** — Honest grade D+. This is not a judgment on the OCaml engine's correctness or spec conformance; it is a measurement of the corpus as defined by the current target file. Correcting the target to exclude `_build/` is expected to raise β significantly.

**CI:** Point estimate; mechanical mode, confidence = 1.0.

---

### repo (aggregate target)

**α = 0.915** — Strong pattern coherence across the merged corpus. Casing drift ("Quick start" vs. "Quick Start") is the only flagged inconsistency.

**β = 0.385** — Bottleneck. `cross_reference_consistency = 0.5` (7/14 links unresolved — several links point to `docs/beta/guides/OPERATOR-MANUAL.md` and `docs/alpha/doctrine/` which may resolve correctly once included in the bundle path context). `authority_alignment = 0.0` (31 files with authority-claim language; the signal requires a declared single authority file, which the aggregate target does not provide). `source_of_truth_alignment = 0.571` (8/14 cross-references point into the bundle).

**γ = 0.680** — Similar traceability gap as spec and engine combined.

**C_Σ = 0.660** — Grade C. The repo aggregate is constrained by the same β gap from the engine sub-target and the cross-reference issues in the wider corpus.

**CI:** Point estimate; mechanical mode, confidence = 1.0.

---

## W2 Gauge Witness

| Target | w_gauge_ref | w_gauge_spread | τ_gauge_spread | Pass |
|--------|------------|---------------|----------------|------|
| spec   | 0.000 | 0.000 | 0.050 | ✓ |
| engine | 0.000 | 0.000 | 0.050 | ✓ |
| repo   | 0.000 | 0.000 | 0.050 | ✓ |

**Note:** Both W2 signals are trivially 0 in mechanical mode. The mechanical C_Σ^math = (α·β·γ)^(1/3) is S₃-symmetric by construction — permuting the axis labels does not change the geometric mean. This satisfies the W2 requirement formally but does not test measurement-procedure gauge invariance in any meaningful way. Real gauge invariance testing requires hybrid/LLM mode where the scoring procedure might be sensitive to which axis labels are applied. W2 = 0 is a property of the formula, not evidence of implementation-level gauge independence.

Canonical remap procedure: `lexicographic ascending by score value (lowest→α, middle→β, highest→γ)`.

---

## L_link and Barrier Chain

L_link values are null for all three targets in mechanical mode. The mechanical scoring path computes axis-level scores directly from structural proxies; it does not construct pairwise discrepancy values (δ_αβ, δ_βγ, δ_γα) from which L_link would be computed. The barrier transform chain (δ → φ(δ) = δ/(1−δ) → D = λ·φ(δ) → Coh = exp(−D)) applies to the LLM/hybrid path where pairwise observations produce δ values.

| Pair | L_link | Notes |
|------|--------|-------|
| α–β | null | mechanical mode |
| β–γ | null | mechanical mode |
| γ–α | null | mechanical mode |

---

## Aggregate Flags

| Target | zero_component_present | numeric_floor_applied | C_Σ^math | C_Σ^num |
|--------|----------------------|----------------------|----------|---------|
| spec   | false | false | 0.895 | 0.895 |
| engine | false | false | 0.465 | 0.465 |
| repo   | false | false | 0.621 | 0.621 |

C_Σ^math ≠ C_Σ_mechanical: the mechanical scoring reports arithmetic mean (α+β+γ)/3 for its C_Σ field; C_Σ^math is the geometric mean (α·β·γ)^(1/3). Both are reported for completeness.

---

## Bottleneck Narrative

β is the system bottleneck at every granularity. Three contributing factors:

1. **_build/ artifact contamination (engine target).** The `engine.tsc` target file includes `engine/ocaml/**/*.ml` which walks into `_build/` by the engine's own glob expansion. This is the largest single gap: β drops to 0.225 for the engine target. Fix: add `"engine/ocaml/_build/**"` to the engine target's `exclude` list.

2. **Authority-alignment signal is strict.** The mechanical engine penalizes any corpus where multiple files carry authority-claim language without a single declared authority file. For the theory corpus (spec), this is somewhat expected (each spec file is authoritative for its domain). The signal doesn't distinguish between intentional multi-authority design and incoherence. This is an instrument limitation at the current version.

3. **Traceability markers absent.** γ is consistently ~0.7 across all targets. The spec and engine source files do not carry structured traceability markers (issue numbers, decision records, etc.). This is a deliberate choice in the current codebase, not an oversight. The signal accurately identifies the absence; whether absence is a gap depends on the project's governance model.

**Dimensional leverage:** Fixing the `_build/` target exclusion alone is estimated to raise engine β from 0.225 to ~0.6–0.7, which would raise aggregate C_Σ from 0.675 to approximately 0.75. This is the highest-leverage single fix.

---

## Provenance

Full v3.2.0 provenance JSON for each target: `provenance/spec.json`, `provenance/engine.json`, `provenance/repo.json`.

All three files conform to the `v3.2.0` schema from `spec/tsc-oper.md` §6. Fields not computed in mechanical mode (L_link, per-pair δ values) are recorded as `null`.

---

## Known Gaps

1. **Hybrid mode not run.** No LLM credentials were available at measurement time. The hybrid run (which would provide semantic axis scores, per-pair δ values, L_link values, and non-trivial W2 results) is deferred. When credentials become available, re-run with `--mode hybrid` against all three targets and update this report with the hybrid results alongside the mechanical results.

2. **engine.tsc _build/ exclusion.** The target definition includes build artifacts in the engine corpus. The β score of 0.225 does not reflect the actual implementation quality. Fixing this target file is the highest-leverage next action.

3. **W2 is trivially satisfied.** Mechanical mode's geometric mean is structurally S₃-symmetric. Genuine gauge-independence measurement requires the LLM path.

4. **No CI on mechanical scores.** Mechanical mode produces point estimates. Confidence intervals require the bootstrap procedure, which depends on an ensemble of observations (only available in hybrid/LLM mode).

5. **OOD reference window.** Per spec/tsc-core.md §12, the OOD reset was required on the v3.2.0 cutover. No prior v3.2.0 reference window exists. This is the first v3.2.0 measurement; the reference window starts here.

---

## Acceptance Criteria Evidence

| AC | Status | Evidence |
|----|--------|----------|
| AC1 — Report exists | **Met** | This file at `docs/alpha/doctrine/3.2.0/SELF-COHERENCE.md` |
| AC2 — Per-target scores | **Met** | §Per-Target Results: all three targets, all five values (α/β/γ/C_Σ + confidence note) |
| AC3 — v3.2.0 provenance attached | **Met** | `provenance/spec.json`, `provenance/engine.json`, `provenance/repo.json` — all include `provenance_v320` block with v3.2.0 required fields |
| AC4 — W2 ref+spread reported | **Met** | §W2 Gauge Witness: w_gauge_ref=0.0, w_gauge_spread=0.0 per target; both ≤ τ=0.05; W2 trivially passes with explanation |
| AC5 — Honest grading | **Met** | Engine β=0.225 named with root cause; aggregate C_Σ=0.675 grade C+; bottleneck identified; hybrid deferral declared in §Known Gaps |
| AC6 — Referenced in index | **Met** | `docs/alpha/doctrine/README.md` updated (see adjacent commit) |

---

## Path Decision

This report is keyed to spec version (`docs/alpha/doctrine/3.2.0/`), not engine version. Rationale: the spec lineage is what advanced in this release cycle. Multiple engine versions may produce this report; the spec version is the stable key. Per the issue recommendation.
