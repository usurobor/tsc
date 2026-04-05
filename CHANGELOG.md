# Changelog

## Release Coherence Ledger

Grades use TSC's own triadic axes (see [spec/](spec/)). Engineering levels per [cnos ENGINEERING-LEVELS.md](https://github.com/usurobor/cnos/blob/main/docs/gamma/ENGINEERING-LEVELS.md).

| Version | C_Σ | α | β | γ | Level | Note |
|---------|-----|---|---|---|-------|------|
| 0.3.1 | A- | A- | A- | B+ | L5 | Binary renamed `tsc` → `coh` to avoid TypeScript compiler collision. |
| 0.3.0 | A- | A- | A- | B+ | L6 | Installable binary: rename to `tsc`, install.sh, release workflow, --version. Version source unified. |
| 0.2.0 | B+ | B+ | B+ | B | L6 | Doc coherence: triadic structure, operator manual, terminology standardized, 14 issues filed and resolved. |
| 0.1.1 | B | B | B+ | B- | L5 | CI fix: missing `.opam` + ezcurl type error. Reactive — caught post-merge. |
| 0.1.0 | B | B+ | B | B- | L7 | First OCaml engine. Targets, provider transport, CI, self-measurement workflow. CI broken at tag time. |

Pre-0.1.0 versions (2.0.0–3.1.0) used a Python implementation with category-theoretic axioms. Removed — available in git history. Not scored — different system.

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
