# TSC Changelog

## Release Coherence Ledger

Grades use TSC's own triadic axes (see [spec/](spec/)). Engineering levels per [cnos ENGINEERING-LEVELS.md](https://github.com/usurobor/cnos/blob/main/docs/gamma/ENGINEERING-LEVELS.md):

- **L4** — Pre-architecture: working prototype, no stable boundaries yet
- **L5** — Local correctness: fix works, follows patterns, no boundary change
- **L6** — System-safe: cross-surface coherence, failure modes handled
- **L7** — System-shaping: architecture boundary moved, class of future work eliminated

| Version | C_Σ | α | β | γ | Level | Coherence note |
|---------|-----|---|---|---|-------|----------------|
| 0.1.1 | B | B | B+ | B- | L5 | CI bootstrap fix (missing `.opam`) + ezcurl API type fix. Both reactive — caught post-merge, not pre-merge. |
| 0.1.0 | B | B+ | B | B- | L7 | First working OCaml engine. Provider transport, target registry, prompt assembly, structured reports. CI + self-measurement workflows. Python reference archived. Design docs shipped. Engine builds but CI was broken at tag time (`.opam` + ezcurl bugs shipped). |

### Archive

Versions 2.0.0–3.1.0 used a Python implementation with category-theoretic axioms (braided monoidal categories, hexagon coherence). That approach was replaced by the current term-algebra foundation and OCaml engine. See `archive/python-reference/` for the historical code. Those versions are not scored here — different system, different era.

---

## 0.1.1 (2026-04-01)

**CI bootstrap + ezcurl type fix**

Two bugs that shipped with 0.1.0 — both prevented CI from building.

### Fixed
- **CI bootstrap**: added generated `tsc_engine.opam` so `opam install . --deps-only` discovers the package and installs dune (#4)
- **Ezcurl API**: `Ezcurl.post` requires `~params:[]` and `~content:(`String ...)` — bare string caused a type error at `provider.ml:94` (#5)

### Changed
- CHANGELOG rewritten as Release Coherence Ledger

### Assessment
- α: B — two targeted fixes, both traced to root cause
- β: B+ — engine ↔ CI ↔ opam dependency chain now consistent
- γ: B- — fixes were reactive (CI failure post-merge), not caught pre-merge; no pre-push gate exists yet

---

## 0.1.0 (2026-04-01)

**First working TSC engine**

Complete rewrite: Python reference archived, OCaml engine ships. The theory (spec/) predates the engine and is stable. This release is the first implementation that can measure a target against the spec.

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
- **Targets** (`targets/`): declarative `.tsc` measurement target definitions
  - `spec.tsc` — measures spec corpus coherence
  - `engine.tsc` — measures engine implementation coherence
  - `repo.tsc` — measures repository-level coherence
  - `registry.tsc` — target registry configuration
- **CI** (`.github/workflows/ci.yml`): OCaml build pipeline (OCaml 5.2, dune, opam)
- **Self-measurement** (`.github/workflows/tsc.yml`): runs all three targets when `TSC_ENABLED=true`
- **Runtime** (`runtime/`): measurement instructions and self-measure protocol
- **Makefile**: `make setup`, `make build`, `make test`, `make measure`, `make clean`
- **Docs** (`docs/engine/0.1.0/`): design doc, implementation plan, self-coherence report

### Changed
- Python reference implementation archived to `archive/python-reference/`
- `README.md`, `ARCHITECTURE.md`, `QUICKSTART.md` rewritten for the OCaml engine
- `project.tsc` superseded by `targets/registry.tsc`

### Known issues at tag time
- CI build broken: missing `tsc_engine.opam` + incorrect ezcurl API call (fixed in 0.1.1)
- Self-measurement workflow untested end-to-end (requires secrets)

### Assessment
- α: B+ — clean module boundaries, each file has one job
- β: B — engine ↔ spec ↔ targets are connected but self-measurement not validated e2e; CI was broken at ship time
- γ: B- — first implementation shipped with build-breaking bugs; design docs exist but the measure-iterate loop hasn't closed yet
