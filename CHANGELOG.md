# Changelog

## Spec releases

The spec lineage (C≡, TSC Core, TSC Operational, TSC Glossary, TSC Observation Dynamics) versions independently from the engine. Spec releases are theory work with no binary deployment; validation is mathematical reproduction and cross-spec consistency.

### Spec v3.2.1 (2026-05-09) — Cross-Target Aggregate Canonicalization

Coherence delta: docs-only patch · **Level:** L6

`spec/tsc-oper.md` §7.4 added: canonicalizes the **cross-target aggregate** `C_Σ_cross = (∏_i C_Σ_i)^(1/n)` (geometric mean of per-target C_Σ values) for self-application across multiple target scopes. Strictly additive; existing measurement and verdict logic unchanged. Resolves cycle #29 D3 — the cross-target formula previously computed ad-hoc in self-coherence reports is now normative.

**Affected:** `spec/tsc-oper.md` (§7.4 added; header v3.2.0 → v3.2.1; end-marker), `spec/tsc-glossary.md` (corresponds-to line bumped). `spec/tsc-core.md` unchanged.

**See:** cycle #32 self-coherence (AC2 / D3 #29).

### Spec v3.2.0 (2026-05-08) — Barrier-Coherence Patch

Coherence delta: C_Σ A- (`α A`, `β A`, `γ A-`) · **Level:** L7

Discrepancy → coherence link refactored as a typed transformation chain `δ → φ(δ) → D → Coh = exp(−D)`. Resolves three latent contradictions in v3.1.0: P2 unreachable (bounded Δ vs Δ → ∞ claim), λ overloaded (sensitivity *and* floor), and Degeneracy Axiom muddled with ε-flooring. Aggregate split into mathematical C_Σ^math and numerical C_Σ^num; they coincide whenever min sᵢ ≥ ε. Pre-v3.2.0 link-Lipschitz envelope corrected via L_link(λ); W2 split into ref + spread to close the best-π gauge loophole; W3 scale transform renamed φ → ψ; canonical v3.2.0 provenance JSON skeleton added.

**Affected:** `spec/tsc-core.md`, `spec/tsc-oper.md`, `spec/tsc-glossary.md`, `spec/tsc-observation-dynamics.md` (dependency uplift). C≡ v3.1.0 unchanged.

**See:** `RELEASE.md` for full coherence delta, validation, and known issues. Engine implementation deferred to a follow-on engine release.

---

## Engine releases

## Release Coherence Ledger

Grades use TSC's own triadic axes (see [spec/](spec/)). Engineering levels per [cnos ENGINEERING-LEVELS.md](https://github.com/usurobor/cnos/blob/main/docs/gamma/ENGINEERING-LEVELS.md).

| Version | C_Σ | α | β | γ | Level | Note |
|---------|-----|---|---|---|-------|------|
| 0.7.0 | A | A | A | A | L6 | Test migration: Python retired, 74-assertion OCaml suite, auto-mode fallback test, Credentials module. (#26, cycle: L6) |
| 0.6.0 | B+ | B+ | A | B+ | L6 | Spec v3.2.0 engine: barrier transform φ, L_link case-split, math/num split, W2 gauge witness (ref+spread), provenance JSON skeleton, SELF-MEASURE.md δ-based protocol, OOD cutover guard. 69-assertion test suite. (#24, cycle: L6) |
| 0.5.0 | A | A | A | A | L6 | Hybrid scoring: mechanical + llm + hybrid + auto modes. 12 structural signals, 61-assertion OCaml test suite, direct file input. Full CDD cycle (#25). |
| 0.4.0 | C+ | B | C+ | C | L6 | Dotenv credential loading + VERSION as single source of truth + release scripts. Partial-protocol release: no CDD cycle, β review absent, post-release artifacts retroactive (#27). |
| 0.3.1 | A- | A- | A- | B+ | L5 | Binary renamed `tsc` → `coh` to avoid TypeScript compiler collision. |
| 0.3.0 | A- | A- | A- | B+ | L6 | Installable binary: rename to `tsc`, install.sh, release workflow, --version. Version source unified. |
| 0.2.0 | B+ | B+ | B+ | B | L6 | Doc coherence: triadic structure, operator manual, terminology standardized, 14 issues filed and resolved. |
| 0.1.1 | B | B | B+ | B- | L5 | CI fix: missing `.opam` + ezcurl type error. Reactive — caught post-merge. |
| 0.1.0 | B | B+ | B | B- | L7 | First OCaml engine. Targets, provider transport, CI, self-measurement workflow. CI broken at tag time. |

Pre-0.1.0 versions (2.0.0–3.1.0) used a Python implementation with category-theoretic axioms. Removed — available in git history. Not scored — different system.

---

## 0.7.0 (2026-05-08)

Test migration: Python retired, OCaml test suite complete. Full CDD cycle (#26, Sub 3 of #23).

### Added
- **`engine/ocaml/lib/credentials.ml`**: `Credentials` module — `has_llm_credentials : unit -> bool` extracted from `bin/main.ml` to enable hermetic testing of the auto-mode fallback branch.
- **`engine/ocaml/test/test_mechanical.ml`** (extended): `test_auto_mode_fallback` added via `Unix.putenv`; completes AC4 surface 8. Total suite: 74 PASS lines.

### Changed
- **`engine/ocaml/lib/dune`**: `credentials` module added to library modules list.
- **`engine/ocaml/bin/main.ml`**: mode-dispatch calls `Tsc_engine.Credentials.has_llm_credentials()`. Behavior identical.
- **`engine/ocaml/test/dune`**: `unix` library added to test dependencies.

### Removed
- **`tests/conformance/`**: `test_consciousness.py`, `test_emergence.py`, `test_free_will.py`, `test_glider.py`, `test_random_soup.py` — Drop (Python-controller-coupled, no mechanical-scorer analogue).
- **`tests/self/test_self_coherence.py`** — Rewrite (superseded by `test_coherence.ml` + `test_mechanical.ml`).
- **`pyproject.toml`** — removed; no Python content remains.

### Known debt
- AC6 live-LLM integration test: carried from cycle #24.
- Beta derivation from δ values: carried from cycle #24.
- `alpha/SKILL.md` §2.6 caller-path trace patch (cnos repo): carried from cycle #24.
- `CONTRIBUTING.md` / `.github/pull_request_template.md`: stale Python/pytest references; doc-cleanup MCI filed.
- MCI freeze in effect: ≥3 issues at growing lag (#28, #29, #30, #31).

---

## 0.6.0 (2026-05-08)

TSC spec v3.2.0 implementation in the OCaml engine. Full CDD cycle (#24, Sub 1 of #23).

### Added
- **`engine/ocaml/lib/coherence.ml`**: barrier transform `φ(δ) = δ/(1−δ)`, discrepancy energy `D`, coherence link `Coh = exp(−D)` with strict zero at `δ=1`. Math/num aggregate split (`C_Σ^math`, `C_Σ^num`, `zero_component_present`, `numeric_floor_applied`). W2 gauge witness (`w_gauge_ref`, `w_gauge_spread`, `tau_gauge_spread`). Provenance JSON assembly.
- **`engine/ocaml/lib/lipschitz.ml`**: L_link closed-form case-split — `(4/λ)·exp(λ−2)` for `0 < λ ≤ 2`, `λ` for `λ ≥ 2`, continuous at `λ = 2`.
- **`engine/ocaml/lib/ood.ml`**: OOD cutover guard — refuses/warns on `schema_version < "v3.2.0"` with reset diagnostic.
- **`engine/ocaml/test/test_coherence.ml`**: 69 assertions covering AC1–AC7 (barrier transform, L_link, math/num split, W2 gauge witness, OOD cutover).
- **`engine/ocaml/test/fixtures/provenance_v3_2_0.schema.json`**: JSON schema for all required v3.2.0 provenance keys.

### Changed
- **`engine/ocaml/lib/report.ml`**: `to_json` accepts optional per-pair δ args; `provenance_v320` wires `gauge_witness` and `l_link` so W2 and L_link fields are populated in real reports.
- **`engine/ocaml/lib/response_schema.ml`**: `extract_deltas` added; `validate_result` docstring corrected (LLM-provided vs. engine-computed fields accurately described).
- **`engine/ocaml/bin/main.ml`**: `run_llm` calls `extract_deltas` and passes δ values to `Report.to_json`.
- **`runtime/SELF-MEASURE.md`**: rewritten for δ-based scoring — LLM provides per-pair discrepancy values (δ_αβ, δ_βγ, δ_γα) and per-component scores; engine applies transformation chain.

### Known debt
- AC6 live-LLM integration test: `LLM_API_KEY` not available in this environment; δ-extraction path wired but not exercised end-to-end.
- Beta derivation from δ values: deferred design extension.
- `alpha/SKILL.md` §2.6 pre-review gate patch (cnos repo): caller-path trace row not yet landed.

---

## 0.5.0 (2026-05-08)

Hybrid scoring pipeline. Full CDD cycle (#25, Sub 2 of #23).

### Added
- **`mechanical_scoring.ml`**: 12 structural signals across α/β/γ axes (pattern, relational, process). Implements `mechanical_scoring.mli` from #22.
- **`hybrid_scoring.ml`**: pure combiner producing `mechanical`, `llm`, and `final` sub-objects. LLM is authority unless both backends agree; `final.source` named explicitly.
- **`bundle.ml`** `type t` + `type file`: direct file input (`--files <glob>`) shares the same `Bundle.t` as named targets.
- **`--mode {mechanical,llm,hybrid,auto}`** + **`--files <glob>`** (repeatable) CLI flags. `auto` resolves to `mechanical` without credentials, `hybrid` with.
- **`"mode"` field** in every report output via `report.ml to_json ~mode`.
- **OCaml test suite** (`engine/ocaml/test/test_mechanical.ml`): 61 assertions covering bundle parity, determinism, JSON schema shape, hybrid preservation.
- **`fixtures/report.schema.json`**: canonical report schema fixture (reference documentation).
- **README, QUICKSTART, ARCHITECTURE** updated to document all modes and direct-file usage.

### Fixed
- `sig_traceability_presence`: bare `"#"` in `trace_kws` caused semantic inversion (fired on any Markdown heading). Removed; remaining keywords cover the intended patterns.

### Known debt
- AC8 partial: pre-existing Python in `tests/conformance/` — Sub 3 owns removal.
- v3.2.0 provenance fields in report sub-objects — Sub 1.
- Mechanical score calibration and hybrid adjudication policy — future cycles.

---

## 0.3.1 (2026-04-05)

Binary naming collision fix.

### Changed
- Binary renamed from `tsc` to `coh` (coherence). `tsc` conflicts with the TypeScript compiler on any machine with Node.js installed.
- Release artifact renamed from `tsc-linux-x64` to `coh-linux-x64`.
- CI artifact, install.sh, operator manual, workflows all updated.

---

## 0.3.0 (2026-04-04)

Installable CLI binary. Full CDD cycle (#21).

### Added
- **Installer** (`install.sh`): one-liner install via `curl | sh`. Atomic temp-file install, UX-CLI compliant output, NO_COLOR support, explicit platform detection.
- **Release workflow** (`.github/workflows/release.yml`): tag-triggered, builds and attaches `tsc-linux-x64` to GitHub Release.
- **`--version` flag**: `tsc --version` prints version derived from source.

### Changed
- Binary renamed from `tsc-engine` to `tsc` everywhere (bin/dune, Makefile, CI, workflows, operator manual).
- CI artifact renamed from `tsc-engine-linux-x86_64` to `tsc-linux-x64`.
- Operator manual: new "Install" section with one-liner and build-from-source paths.
- README quick start: install one-liner instead of "see operator manual".

### Design
- [DESIGN.md](docs/alpha/engine/0.3.0/DESIGN.md): installer survey (cnos, rustup, deno, homebrew, bun), UX-CLI compliance analysis, atomic install pattern.
- [PLAN.md](docs/alpha/engine/0.3.0/PLAN.md): 6-step implementation plan.

---

## 0.2.0 (2026-04-03)

Documentation coherence iteration. Thorough cross-file review, 14 issues filed, all resolved.

### Added
- **Operator manual** (`docs/beta/guides/OPERATOR-MANUAL.md`): build, config, run, CI, troubleshooting
- **THESIS.md** (`docs/THESIS.md`): entry point above the triad
- **DOCUMENTATION-SYSTEM.md** (`docs/beta/governance/`): triadic doc structure adapted from cnos
- **Doctrine bundle** (`docs/alpha/doctrine/`): indexes spec/ theory
- **Engine bundle** (`docs/alpha/engine/`): indexes engine design, versioned artifacts
- CI uploads binary artifact (`tsc-engine-linux-x86_64`)

### Changed
- Env vars renamed: `TSC_PROVIDER` → `LLM_PROVIDER`, `TSC_MODEL` → `LLM_MODEL`, `TSC_API_KEY` → `LLM_API_KEY`
- QUICKSTART.md replaced with pointer to operator manual (#7, #13)
- README.md rewritten as repo index — no longer re-explains TSC (#12, #16)
- Axis terminology standardized to "pattern / relational / process" across all docs (#14)
- ARCHITECTURE.md repo map now includes `docs/` and `archive/` (#15)
- Bottleneck rule removed from operator manual — geometric mean suffices (#10)
- SELF-MEASURE.md moved from doctrine bundle to engine bundle (#20)
- SELF-COHERENCE.md formula corrected to geometric mean notation (#18)
- Broken link in engine bundle README fixed (#19)
- Citation version updated to v0.1.1 (#8)

### Archived
- `runtime/tsc-instructions.md` → `archive/tsc-instructions.md` (#9)

---

## 0.1.1 (2026-04-01)

### Fixed
- `tsc_engine.opam` committed so opam discovers deps and installs dune (#4)
- `Ezcurl.post` called with `~params:[]` and `~content:(`String ...)` (#5)

### Changed
- Changelog rewritten as coherence ledger

---

## 0.1.0 (2026-04-01)

OCaml engine replaces Python reference. Theory (spec/) is stable and predates the engine.

### Added
- **Engine** (`engine/ocaml/`): provider transport (ezcurl), target registry, prompt assembly, structured report parsing, CLI entry point
- **Targets** (`targets/`): declarative `.tsc` definitions for spec, engine, and repo coherence
- **CI**: OCaml 5.2 build + linkcheck (`.github/workflows/ci.yml`)
- **Self-measurement**: runs all targets when `TSC_ENABLED=true` (`.github/workflows/tsc.yml`)
- **Docs** (`docs/alpha/engine/0.1.0/`): design, plan, self-coherence report

### Changed
- Python archived to `archive/python-reference/`
- README, ARCHITECTURE, QUICKSTART rewritten
- `project.tsc` superseded by `targets/registry.tsc`

### Known issues
- CI broken at tag time: missing `.opam` + ezcurl API mismatch (fixed in 0.1.1)
- Self-measurement untested end-to-end (requires secrets)
