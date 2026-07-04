# Engine

The canonical TSC measurement engine. OCaml-first, LLM-native.

## Canonical spec

The canonical implementation is `engine/ocaml/`. The operator manual is [docs/beta/guides/OPERATOR-MANUAL.md](../../beta/guides/OPERATOR-MANUAL.md).

## Documents

| Document | Path | Purpose |
|----------|------|---------|
| Design | [0.1.0/DESIGN.md](0.1.0/DESIGN.md) | Architecture, acceptance criteria, invariants |
| Plan | [0.1.0/PLAN.md](0.1.0/PLAN.md) | Implementation steps and checkpoints |
| Self-coherence | [0.1.0/SELF-COHERENCE.md](0.1.0/SELF-COHERENCE.md) | AC evidence, triadic self-assessment, friction log |
| Scoring instruction | [runtime/SELF-MEASURE.md](../../../runtime/SELF-MEASURE.md) | LLM-executable scoring rules and output contract |
| Operator manual | [OPERATOR-MANUAL.md](../../beta/guides/OPERATOR-MANUAL.md) | Build, configure, run, troubleshoot |

## Version history

Releases 0.1.0–0.5.0 have frozen artifact directories here. From 0.6.0
onward, per-release records live in [CHANGELOG.md](../../../CHANGELOG.md)
and per-cycle CDD artifacts instead of frozen directories — the rows
below link the changelog for those.

| Version | Record | Note |
|---------|--------|------|
| 0.11.0 | [CHANGELOG.md](../../../CHANGELOG.md) | Official release consolidating the 0.10.1–0.10.5 self-measurement + CM² wave; SELF-MEASURE v3.2.2; held-out commit-reveal standing. |
| 0.10.5 | [CHANGELOG.md](../../../CHANGELOG.md) | Witness-contract calibration wave (SELF-MEASURE v3.2.1, refuted and withdrawn in v3.2.2). |
| 0.10.4 | [CHANGELOG.md](../../../CHANGELOG.md) | Release ledger learns k=3 sampling: per-target consistency columns, single-sample rows migrated. |
| 0.10.3 | [CHANGELOG.md](../../../CHANGELOG.md) | Standing-scope wave: admissibility v2, displacement thresholds, challenger registration, `standing_scope` typed, k=3 witness sampling in measurement CI. |
| 0.10.2 | [CHANGELOG.md](../../../CHANGELOG.md) | CM² wave: methodologies as measurable objects; new targets `methodology` and `cm-of-cms`. |
| 0.10.1 | [CHANGELOG.md](../../../CHANGELOG.md) | Self-measurement platformization: `coh self`, witness funnel, external witness route, per-release coherence ledger. |
| 0.10.0 | [CHANGELOG.md](../../../CHANGELOG.md) | Canonical v3.2 scoring cutover: geometric `C_Σ^math` / `C_Σ^num` under `provenance`; strict v3.2 LLM δ validation; cross-target report surface (#49 wave). |
| 0.9.0 | [CHANGELOG.md](../../../CHANGELOG.md) | Phase 2 kata progression: comparative, philosophical, adversarial katas; `[[components]]` + ranking runner. |
| 0.8.0 | [CHANGELOG.md](../../../CHANGELOG.md) | Process enforcement: CHANGELOG release gate in release scripts. |
| 0.7.0 | [CHANGELOG.md](../../../CHANGELOG.md) | Test migration: Python retired; OCaml test suite; auto-mode fallback; Credentials module. |
| 0.6.0 | [CHANGELOG.md](../../../CHANGELOG.md) | Spec v3.2.0 engine: barrier transform φ, math/num split, W2 gauge witness, δ-based SELF-MEASURE protocol. |
| 0.5.0 | [0.5.0/POST-RELEASE-ASSESSMENT.md](0.5.0/POST-RELEASE-ASSESSMENT.md) | Hybrid scoring: mechanical + llm + hybrid + auto modes. Three-mode engine, 61-assertion OCaml test suite, direct file input. Full CDD cycle (#25). |
| 0.4.0 | [0.4.0/POST-RELEASE-ASSESSMENT.md](0.4.0/POST-RELEASE-ASSESSMENT.md) | Dotenv credential loading, VERSION as single source of truth, release scripts. |
| 0.3.1 | — | Binary renamed `tsc` → `coh`. Single-commit hot fix; no design phase — frozen artifact directory not created. |
| 0.3.0 | [0.3.0/POST-RELEASE-ASSESSMENT.md](0.3.0/POST-RELEASE-ASSESSMENT.md) | Installable CLI binary. Rename to `tsc`. |
| 0.1.0 | [0.1.0/](0.1.0/) | First release. Replaces Python reference. |
