# Changelog

## Release Coherence Ledger

Grades use TSC's own triadic axes (see [spec/](spec/)). Engineering levels per [cnos ENGINEERING-LEVELS.md](https://github.com/usurobor/cnos/blob/main/docs/gamma/ENGINEERING-LEVELS.md).

| Version | C_Σ | α | β | γ | Level | Note |
|---------|-----|---|---|---|-------|------|
| 0.2.0 | B+ | B+ | B+ | B | L6 | Doc coherence: triadic structure, operator manual, terminology standardized, 14 issues filed and resolved. |
| 0.1.1 | B | B | B+ | B- | L5 | CI fix: missing `.opam` + ezcurl type error. Reactive — caught post-merge. |
| 0.1.0 | B | B+ | B | B- | L7 | First OCaml engine. Targets, provider transport, CI, self-measurement workflow. CI broken at tag time. |

Pre-0.1.0 versions (2.0.0–3.1.0) used a Python implementation with category-theoretic axioms. Archived to `archive/python-reference/`. Not scored — different system.

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
