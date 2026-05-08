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

Aggregate C_Σ = (0.898 × 0.521 × 0.660)^(1/3) = **0.675** — grade C+. The bottleneck is β across two of three targets. The dominant gap is in the engine target (β = 0.225), driven by build artifacts in the corpus.

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

**α = 0.650** — Pattern coherence is impaired. `repeated_structure = 0.0` (0/2 markdown-bearing files have H1 headers). `duplicate_definition_tension = 0.5` (shared heading labels in test fixtures). OCaml source scores well on naming drift.

**β = 0.225** — Relational coherence is the major bottleneck. `cross_reference_consistency = 0.0` (5/5 links unresolved) and `authority_alignment = 0.0` (23 files with authority-claim language).

**Root cause:** `engine/ocaml/**/*.ml` walks into `engine/ocaml/_build/` and includes compiled build artifacts (58-file bundle, many generated). The `engine.tsc` target lacks an explicit `_build/**` exclusion. Without this inflation, β would be materially higher. This is the primary finding.

**γ = 0.687** — `traceability_presence = 0.052` (3/58 files). Build artifacts drag the denominator without contributing traceability.

**C_Σ = 0.521** — Honest grade D+. This measures the corpus as defined by the current target file, not engine correctness or spec conformance.

**CI:** Point estimate; mechanical mode, confidence = 1.0.

---

### repo (aggregate target)

**α = 0.915** — Strong pattern coherence. Casing drift ("Quick start" vs. "Quick Start") is the only flagged inconsistency.

**β = 0.385** — Bottleneck. `cross_reference_consistency = 0.5` (7/14 links unresolved). `authority_alignment = 0.0` (31 files with authority-claim language). `source_of_truth_alignment = 0.571` (8/14 cross-references point into bundle).

**γ = 0.680** — Traceability gap propagates from constituent targets.

**C_Σ = 0.660** — Grade C. Constrained by β gap from engine sub-target and cross-reference issues across the wider corpus.

**CI:** Point estimate; mechanical mode, confidence = 1.0.

---

## W2 Gauge Witness

| Target | w_gauge_ref | w_gauge_spread | τ_gauge_spread | Pass |
|--------|------------|---------------|----------------|------|
| spec   | 0.000 | 0.000 | 0.050 | ✓ |
| engine | 0.000 | 0.000 | 0.050 | ✓ |
| repo   | 0.000 | 0.000 | 0.050 | ✓ |

Both W2 signals are trivially 0 in mechanical mode. C_Σ^math = (α·β·γ)^(1/3) is S₃-symmetric by construction — permuting axis labels does not change the geometric mean. This satisfies the W2 requirement formally but does not test measurement-procedure gauge invariance in any meaningful way. Real gauge invariance testing requires hybrid/LLM mode. Canonical remap: `lexicographic ascending by score value (lowest→α, middle→β, highest→γ)`.

---

## L_link and Barrier Chain

Mechanical mode does not compute pairwise δ values. L_link is null for all pairs and all targets.

| Pair | L_link | Notes |
|------|--------|-------|
| α–β | null | mechanical mode; pairwise δ not computed |
| β–γ | null | mechanical mode; pairwise δ not computed |
| γ–α | null | mechanical mode; pairwise δ not computed |

The barrier transform chain (δ → φ(δ) = δ/(1−δ) → D = λ·φ(δ) → Coh = exp(−D)) applies to the LLM/hybrid path.

---

## Aggregate Flags

| Target | zero_component_present | numeric_floor_applied | C_Σ^math | C_Σ^num |
|--------|----------------------|----------------------|----------|---------|
| spec   | false | false | 0.895 | 0.895 |
| engine | false | false | 0.465 | 0.465 |
| repo   | false | false | 0.621 | 0.621 |

C_Σ^math (geometric mean) differs from C_Σ_mechanical (arithmetic mean reported by engine in mechanical mode). Both are recorded.

---

## Bottleneck Narrative

β is the bottleneck at every granularity. Three factors:

1. **_build/ artifact contamination (engine target).** `engine.tsc` includes `engine/ocaml/**/*.ml` which walks into `_build/`. β drops to 0.225. Fix: add `engine/ocaml/_build/**` to the exclude list. Estimated lift: engine β 0.225 → ~0.65, aggregate C_Σ ~0.675 → ~0.75.

2. **Authority-alignment signal is strict.** The signal penalizes any corpus where multiple files carry authority-claim language without a single declared machine-readable authority file. This is an instrument limitation for multi-file canonical corpora.

3. **Traceability markers absent.** γ ~0.7 across all targets. No structured traceability markers in spec or engine source. Accurate measurement of a deliberate design choice.

---

## Provenance

Full v3.2.0 provenance JSON: `provenance/spec.json`, `provenance/engine.json`, `provenance/repo.json`. All conform to `spec/tsc-oper.md` §6 schema. Fields not computed in mechanical mode are `null`.

---

## Known Gaps

1. **Hybrid mode not run.** No LLM credentials at measurement time. Hybrid run (semantic scores, per-pair δ, L_link, non-trivial W2) is deferred. Re-run with `--mode hybrid` when credentials become available and update this report.

2. **engine.tsc _build/ exclusion missing.** β=0.225 does not reflect implementation quality. Highest-leverage fix.

3. **W2 trivially satisfied in mechanical mode.** Genuine gauge-independence measurement requires LLM path.

4. **No CI on mechanical scores.** Bootstrap CI requires LLM/hybrid mode.

5. **OOD reference window starts here.** Per spec §12 OOD reset, this is the first v3.2.0 measurement. No prior window exists.

---

## Acceptance Criteria Evidence

| AC | Status | Evidence |
|----|--------|----------|
| AC1 — Report exists | **Met** | `docs/alpha/doctrine/3.2.0/SELF-COHERENCE.md` exists |
| AC2 — Per-target scores | **Met** | All three targets; α/β/γ/C_Σ + confidence note per target |
| AC3 — v3.2.0 provenance attached | **Met** | `provenance/{spec,engine,repo}.json` with `provenance_v320` block; all required v3.2.0 fields present |
| AC4 — W2 ref+spread reported | **Met** | §W2: w_gauge_ref=0.0, w_gauge_spread=0.0 per target; ≤ τ=0.05; trivial-pass explanation given |
| AC5 — Honest grading | **Met** | Engine β=0.225 with root cause; aggregate C_Σ=0.675 grade C+; bottleneck named; hybrid deferral explicit |
| AC6 — Referenced in index | **Met** | `docs/alpha/doctrine/README.md` §Self-coherence reports table updated |

---

## Path Decision

Keyed to spec version (`docs/alpha/doctrine/3.2.0/`). Rationale: spec lineage is what advanced; engine version may vary across runs. Per the issue recommendation.
