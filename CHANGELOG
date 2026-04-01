# Changelog

All notable changes to TSC will be documented in this file.

Version history prior to v0.1.0 is archived. The Python reference implementation
and category-theoretic framing were replaced by the current OCaml engine and
term-algebra foundation.

---

## [0.1.1] - 2026-04-01

### Fixed
- CI: added generated `tsc_engine.opam` so `opam install . --deps-only` discovers the package and installs dune (#4)
- Engine: `Ezcurl.post` requires `~params:[]` and `~content:(`String ...)` — bare string caused type error at `provider.ml:94` (#5)

### TSC
- α: B — two targeted fixes, both traced to root cause
- β: B+ — engine ↔ CI ↔ opam chain now consistent
- γ: B — fixes were reactive (CI failure post-merge), not caught pre-merge

---

## [0.1.0] - 2026-04-01

First working implementation of the TSC measurement engine.

### Added
- **Engine** (`engine/ocaml/`): OCaml-first, LLM-native measurement engine
  - `provider.ml` — HTTP transport via ezcurl (no subprocess, no temp files)
  - `main.ml` — CLI entry point: reads target files, bundles spec + instructions, calls provider
  - `target_registry.ml` — discovers and loads `.tsc` target definitions
  - `prompt.ml` — assembles measurement prompts from bundled context
  - `report.ml` — parses structured JSON responses into scored reports
  - `response_schema.ml` — defines expected provider response structure
  - `types.ml` — core domain types (targets, scores, config)
  - `bundle.ml` — file bundling for context assembly
- **Targets** (`targets/`): declarative measurement target definitions
  - `spec.tsc` — measures spec corpus coherence
  - `engine.tsc` — measures engine implementation coherence
  - `repo.tsc` — measures repository-level coherence
  - `registry.tsc` — target registry configuration
- **CI** (`.github/workflows/ci.yml`): OCaml build pipeline
  - ocaml/setup-ocaml@v3, OCaml 5.2
  - `opam install . --deps-only`, `dune build`, `dune runtest`
  - Markdown link checking via lychee
- **Self-measurement** (`.github/workflows/tsc.yml`): runs all three targets when `TSC_ENABLED=true`
- **Runtime** (`runtime/`): measurement instructions and self-measure protocol
- **Makefile**: `make setup`, `make build`, `make test`, `make measure`, `make clean`
- **Docs** (`docs/engine/0.1.0/`): design doc, implementation plan, self-coherence report

### Changed
- Python reference implementation archived to `archive/python-reference/`
- `README.md`, `ARCHITECTURE.md`, `QUICKSTART.md` rewritten for the OCaml engine
- `project.tsc` superseded by `targets/registry.tsc`

### TSC
- α: B+ — clean module boundaries, each file has one job
- β: B — engine ↔ spec ↔ targets are connected but self-measurement not yet validated end-to-end (CI skips without secrets)
- γ: B- — first implementation; design docs exist but the build-measure-iterate loop hasn't closed yet

---

## Archive

Versions 2.0.0–3.1.0 used a Python implementation with category-theoretic axioms
(braided monoidal categories, hexagon coherence). That approach was replaced by
the current term-algebra foundation and OCaml engine. See `archive/python-reference/`
for the historical code.
