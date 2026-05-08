# Self-Coherence — v0.7.0 / TSC Core v3.2.0

**Engine version:** 0.7.0\
**Spec version:** TSC Core v3.2.0 (normative)\
**Protocol:** SELF-MEASURE v3.2.0\
**Mode:** mechanical (structural-proxy scoring; no LLM credentials)\
**Date:** 2026-05-08\
**Issue:** #29 (Sub 6 of #23)\
**Run artifacts:** `.tsc/tsc-{target}-2026-05-08T21:48:{ss}Z.json`

---

## 1. Per-Target Scores

### 1.1 spec (5 files)

| Axis | Score | Bottleneck |
|------|-------|-----------|
| α | 0.968 | |
| β | 0.910 | |
| γ | 0.815 | ✓ |
| **C_Σ** | **0.898** | |

**Evidence:**
- α: All 156 heading phrases consistent; 5/5 files with H1; minor camelCase drift (5 snake_case, 19 camelCase in headings)
- β: 5 files contain authority-claim language (acceptable — spec files are normative surfaces); no internal links (score 1.0 on cross-reference)
- γ bottleneck: 64 version occurrences, 10 unique (v3.1.0, v3.2.0, C≡ spec semvers all co-present); 0 traceability markers (`changelog`, `closes #`, etc.)

**Bottleneck diagnosis:** γ is pulled down by two signals: version diversity (10 unique strings across spec files, expected but penalized by the proxy) and absence of explicit traceability. The spec intentionally references multiple spec versions (C≡ v3.1.0, TSC Core v3.2.0) so version diversity is structural, not a coherence failure.

**Grade: A−** (C_Σ = 0.898)

---

### 1.2 engine (58 files)

| Axis | Score | Bottleneck |
|------|-------|-----------|
| α | 0.650 | |
| β | 0.225 | ✓ |
| γ | 0.691 | |
| **C_Σ** | **0.522** | |

**Evidence:**
- α: 0/2 heading files have H1 (dune build files have no H1); duplicate section headings (`section one`, `section two`, `overview`) across generated modules; naming drift is clean (0 mixed identifiers)
- β bottleneck: 23 files with authority-claim language (score 0.0); 5/5 internal links unresolved
- γ: 12/58 files marked generated; 77 version occurrences, 7 unique (0.5.0, 0.7.0, 3.0.0, 3.1.0, 3.2.0); only 3/58 traceability markers

**Mechanical grading caveat:** The engine bundle glob `engine/ocaml/**/*.ml` (from `targets/engine.tsc`) picks up `_build/default/lib/*.ml` — dune-generated OCaml modules whose content includes implementation phrases like "canonical" and "authority surface". These inflate the authority-claim count (23 files vs. ~8 canonical source files). The β score of 0.225 is driven partly by build-artifact contamination, not purely by genuine relational incoherence.

Real β signal: the engine's OCaml source files do use domain vocabulary ("canonical", "source of truth") from the spec, and the 5 unresolved internal links point outside the bundle. These are genuine signals, but the 0.0 floor for authority-alignment is disproportionate to the actual gap.

**Grade: D+** (C_Σ = 0.522; proxy-inflated downward; structural artifact in bundle scoping)

---

### 1.3 repo (69 files)

| Axis | Score | Bottleneck |
|------|-------|-----------|
| α | 0.915 | |
| β | 0.385 | ✓ |
| γ | 0.682 | |
| **C_Σ** | **0.661** | |

**Evidence:**
- α: 11/13 heading files with H1; casing drift on "Quick start" vs "Quick Start"; snake_case/camelCase mix (8/21)
- β bottleneck: 7/14 internal links unresolved (docs/beta/guides/OPERATOR-MANUAL.md, docs/alpha/doctrine/ — both outside the target bundle); 31 files with authority-claim language (score 0.0)
- γ: 15/69 generated markers; 144 version occurrences, 15 unique (broad version scatter across cross-layer bundle); 3/69 traceability markers

**Grade: C** (C_Σ = 0.661; β gap is real — cross-layer link resolution and authority-surface spread)

---

### 1.4 direct (spec/tsc-core.md + runtime/SELF-MEASURE.md, 2 files)

| Axis | Score |
|------|-------|
| α | 0.979 |
| β | 0.985 |
| γ | 0.800 |
| **C_Σ** | **0.921** |
| confidence | 0.67 (2 files, below 3-file minimum) |

This is the minimal measurement pair from the dispatch prompt. High scores reflect a clean two-file bundle: one normative spec, one protocol document. Confidence is reduced because the bundle is below the 3-file minimum for full signal confidence.

**Grade: A** (C_Σ = 0.921; confidence limited)

---

## 2. W2 Reference and Spread

Initial v3.2.0 OOD reference window, seeded from 2 same-day mechanical runs. Pre-v3.2.0 C_Σ values are **not** comparable (barrier-transform cutover; see spec §12 and `engine/ocaml/lib/ood.ml`).

| Target | C_Σ run-1 | C_Σ run-2 | C_Σ_ref (mean) | Spread (σ) | W2 |
|--------|-----------|-----------|----------------|-----------|-----|
| spec   | 0.8976    | 0.8976    | 0.8976         | <0.001    | <0.001 |
| engine | 0.5207    | 0.5220    | 0.5213         | 0.0006    | 0.0013 |
| repo   | 0.6598    | 0.6605    | 0.6602         | 0.0003    | 0.0007 |

Spread is effectively zero — mechanical scoring is deterministic for identical bundles. Tiny gamma variation in engine/repo between runs reflects files added to the working tree between the two runs (~8 minutes apart).

**OOD status:** This is the initialization measurement for the v3.2.0 epoch. The reference distribution requires ≥10 independent runs before W2-based stability z-scores are meaningful. Current values are seed measurements, not stability verdicts.

---

## 3. Honest Grading

**spec (A−):** The spec target is strongly coherent. Pattern and relational coherence are high. The γ bottleneck is real but bounded: version diversity is intentional (the spec cross-references C≡ v3.1.0 by design), and the absence of explicit traceability markers is a documentation-style choice. Not a failure.

**engine (D+):** The mechanical β score of 0.225 is the most significant number in this report. It is partly an artifact of the bundle scoping (build artifacts included), but even correcting for that, the engine bundle has genuine β gaps: OCaml source files use spec domain vocabulary that registers as contested authority, and the documentation links point outside the bundle scope. The D+ grade is honest: the engine's relational coherence surface needs improvement, but the specific floor (0.0 on authority-alignment) overestimates the severity.

**repo (C):** The repo aggregate is β-bottlenecked for genuine reasons. The OPERATOR-MANUAL.md and doctrine links exist but are outside the `repo` target bundle. Expanding the bundle to include docs/beta/ would likely raise β materially. As-measured, C is correct.

**direct (A):** The two-file measurement confirms that the spec and its measurement protocol are tightly aligned. High confidence that the core self-measurement pair is internally coherent.

**Summary verdict:** The TSC spec (A−) and self-measurement protocol (A direct pair) are coherent at v3.2.0. The engine implementation (D+) and full repo (C) show real β gaps, amplified by bundle-scoping artifacts. The measurement is honest — the system correctly identifies its own relational coherence as the weakest axis.

---

## 4. Known Debt

1. **Bundle scoping:** `targets/engine.tsc` glob `engine/ocaml/**/*.ml` includes `_build/` artifacts. An exclude pattern `engine/ocaml/_build/**` would eliminate build-artifact contamination from the β signal.
2. **OOD window underweight:** 2 same-day runs. The W2 ref+spread values are initialization seeds. Meaningful OOD detection requires ≥10 runs across independent time points.
3. **No barrier-transform δ values:** Mechanical mode produces component scores (α, β, γ) directly; it does not compute normalized discrepancy δ pairs or apply the barrier transform φ(δ) = δ/(1−δ). The spec §3 δ pairs (delta_alpha_beta, delta_beta_gamma, delta_gamma_alpha) are not reported in mechanical mode. LLM or hybrid mode is required for full v3.2.0 δ output.
4. **No confidence intervals:** Bootstrap CI (spec §6) is not implemented in mechanical mode. All scores are point estimates.
5. **Traceability gap (γ):** Only 3 files in the 69-file repo bundle carry traceability markers. This is a real process signal: more of the repo's implementation files should reference issues or changelog entries.
