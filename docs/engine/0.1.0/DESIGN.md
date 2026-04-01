# OCaml-first, LLM-native TSC engine

**Issue:** TBD
**Version:** 0.1.0
**Mode:** MCA
**Active Skills:** design, ocaml, writing

## Problem

The repo declares theory / targets / verifier but the verifier layer is a transitional Python path that cannot resolve named targets. The target model (`targets/registry.tsc`, `targets/*.tsc`) is architecturally correct but never exercised by the implementation.

A second incoherence sits inside the measurement path: the implementation assumes local parser logic for Markdown syntax, while the evaluative work should happen at semantic coherence across file bundles via LLM. The Python orchestrator parses `[markdown]` sections from `project.tsc` and measures Markdown structure — not system coherence.

Evidence:
- `reference/python/measure_project.py` line 77: `parse_config()` expects repeated `[markdown]` sections
- `targets/registry.tsc` declares `tsc-target-registry/0.1` format — nothing reads it
- ARCHITECTURE.md says "The next implementation track is: a canonical OCaml engine" — it does not exist

## Constraints

- Python is not carried forward. `reference/python/` is removed or archived, not maintained in parallel.
- Markdown does not need a semantic parser.
- Target resolution must remain deterministic.
- Scoring must remain reproducible enough to compare runs.
- The engine must separate:
  - deterministic file collection
  - prompt construction
  - model invocation
  - structured result validation
- Secrets must not live in the repo.
- Theory (`spec/`) remains independent of implementation language.

## Challenged Assumption

This change challenges two existing assumptions:

1. that the current Python path should continue as the live orchestrator
2. that the measurement engine should parse Markdown structure instead of supplying raw target bundles to an LLM with a precise scoring protocol

Both assumptions no longer serve the repo.

## Impact Graph

### Downstream consumers
- CLI usage (`tsc` command, `make self-coherence`)
- self-measurement flow
- target registry / target manifests
- generated reports in `.tsc/`
- README / QUICKSTART / ARCHITECTURE wording
- `project.tsc` as live config

### Upstream producers
- `targets/registry.tsc` — target registry
- `targets/spec.tsc`, `targets/engine.tsc`, `targets/repo.tsc` — target manifests
- file bundles under `spec/`, `reference/` (then `engine/`), repo docs, tests

### Copies and authority
- `targets/registry.tsc` becomes canonical target authority (currently draft)
- `project.tsc` is removed or replaced by a compatibility pointer
- `runtime/SELF-MEASURE.md` becomes canonical scoring authority (new)
- generated reports remain derived artifacts only

### Rule / embedding changes
- docs must stop describing Python as the current implementation once cutover happens
- self-measurement instructions must define α / β / γ precisely enough for provider swaps
- no duplicate source of truth for target resolution

## Invariants

These must remain true after this change:

1. **Theory independence** — `spec/` remains independent of implementation language. No OCaml-specific content in theory docs.
2. **Target determinism** — given the same registry + manifests + file tree, target resolution produces the same ordered file list.
3. **Scoring authority** — `runtime/SELF-MEASURE.md` is the single textual authority for how α / β / γ are scored. The engine constructs prompts from it; it does not contain scoring logic itself.
4. **Purity boundary** — `engine/ocaml/lib/` is pure (no I/O, no Unix, no Sys). All I/O lives in `bin/` (CLI wiring) and `bin/provider.ml`.
5. **Secret isolation** — API keys are injected at runtime via environment variables. No secrets in repo, no secrets in generated reports.
6. **Report derivation** — generated reports in `.tsc/` are derived artifacts only. Canonical sources are `spec/`, `targets/`, `engine/ocaml/`, `runtime/SELF-MEASURE.md`.
7. **One registry** — `targets/registry.tsc` is the single target authority. No parallel target resolution path.

## Proposal

Build a new OCaml engine around four deterministic stages and one LLM stage.

### 1. Deterministic target resolution

Resolve named targets from `targets/registry.tsc` and `targets/*.tsc`.

Responsibilities:
- load registry
- select target by name
- resolve include/exclude globs
- expand nested target inclusion (`include_targets`)
- produce an ordered file bundle

No model involvement. Pure OCaml module: `Target_registry`.

### 2. Deterministic bundle preparation

Read files as raw text, attach metadata, construct a target bundle.

Per file:
- path
- target kind
- raw content
- content hash (SHA-256)
- optional chunk index if chunking is needed

No Markdown AST. No semantic parser. Files remain text. Pure module: `Bundle`.

### 3. Prompt construction

Build a canonical self-measure prompt from:
- target metadata
- scoring instructions (from `runtime/SELF-MEASURE.md`)
- file bundle
- response schema

The prompt is deterministic. The model receives the same structure every time. Pure module: `Prompt`.

### 4. LLM evaluation

The model scores:
- α — pattern coherence
- β — relational coherence
- γ — process coherence

and returns:
- numeric scores
- bottleneck axis
- evidence per axis
- unresolved ambiguity
- confidence / sufficiency
- concrete next fixes

Impure module: `Provider`. Takes provider name, model name, API key, optional base URL from runtime configuration only.

### 5. Deterministic validation and report generation

Validate structured output against schema. Reject malformed responses. Persist:
- machine-readable report (JSON)
- human-readable report (text)
- run metadata (target, file hashes, prompt version, model, timestamp)

Pure validation: `Response_schema`. Report generation: `Report`.

## Leverage

This change:
- removes the transitional Python identity
- aligns the repo with the intended OCaml direction stated in ARCHITECTURE.md
- removes needless Markdown parser work
- makes the target model actually canonical (consumed, not just declared)
- makes self-measurement explicit and provider-agnostic
- simplifies future embedding into cnos or other OCaml systems

## Negative Leverage

This adds:
- provider dependency (external LLM API)
- prompt and schema design work
- nondeterminism risk at the scoring layer
- the need for careful caching and reproducibility policy
- full replacement rather than incremental migration

## Alternatives Considered

| Option | Pros | Cons | Decision |
|---|---|---|---|
| Keep Python and patch it | Lower short-term cost | Preserves transitional architecture | Rejected |
| Keep deterministic Markdown parsing, add OCaml later | Feels safer | Solves the wrong problem; parser still dominates | Rejected |
| OCaml engine with deterministic parsing, no LLM | Fully local | Misses the semantic-evaluation advantage | Rejected |
| OCaml engine + deterministic target resolution + raw-text bundle + LLM scoring | Clean authority, minimal syntax assumptions | Requires prompt discipline and schema validation | **Chosen** |

## Process Cost / Automation Boundary

### Process cost
Maintainers must:
- keep target manifests accurate
- keep the self-measure instruction precise
- track provider/model drift when comparing runs

### Automation boundary
Automate:
- registry loading, bundle resolution, file hashing
- prompt generation, schema validation, report generation
- caching identical bundle runs

Do not automate:
- semantic interpretation of the score
- theory changes inferred from one run
- silent prompt rewrites that change the measure

## Non-goals

V1 does not:
- support multiple canonical engines
- preserve Python compatibility
- parse Markdown semantically
- solve all reproducibility problems across providers
- replace the theory with prompt magic

## File Changes

### Create
- `engine/ocaml/bin/main.ml` — CLI entrypoint
- `engine/ocaml/bin/dune` — dune build for CLI
- `engine/ocaml/lib/target_registry.ml` — registry + manifest parsing
- `engine/ocaml/lib/bundle.ml` — file collection + hashing
- `engine/ocaml/lib/prompt.ml` — prompt construction
- `engine/ocaml/lib/provider.ml` — LLM API client (impure)
- `engine/ocaml/lib/response_schema.ml` — output validation
- `engine/ocaml/lib/report.ml` — report generation
- `engine/ocaml/lib/dune` — dune library
- `engine/ocaml/dune-project` — dune project root
- `engine/ocaml/tsc_engine.opam` — opam package
- `runtime/SELF-MEASURE.md` — canonical LLM scoring instruction
- `tests/ocaml/` — engine tests

### Edit
- `README.md` — update implementation description
- `ARCHITECTURE.md` — update verifier section, remove Python reference
- `QUICKSTART.md` — update to OCaml path
- `targets/README.md` — update authority statement (registry now live)
- `targets/registry.tsc` — remove draft status
- `targets/engine.tsc` — update include paths to `engine/ocaml/**`
- `targets/repo.tsc` — add `runtime/SELF-MEASURE.md` to includes
- `project.tsc` — add transition comment or remove

### Remove or archive
- `reference/python/` — archive (move to `archive/python/` or delete)

## Acceptance Criteria

- [ ] AC1: OCaml engine resolves `spec`, `engine`, and `repo` targets from `targets/registry.tsc`
- [ ] AC2: File bundles are built deterministically without Markdown parsing — files are read as raw text with SHA-256 hashes
- [ ] AC3: LLM scoring uses one canonical instruction surface (`runtime/SELF-MEASURE.md`)
- [ ] AC4: Structured output is validated against a JSON schema — malformed responses are rejected
- [ ] AC5: Reports are generated in machine-readable (JSON) and human-readable (text) form
- [ ] AC6: Python is no longer the live implementation path — `reference/python/` is archived or removed
- [ ] AC7: Docs (README, ARCHITECTURE, QUICKSTART) describe the OCaml engine truthfully
- [ ] AC8: API secrets are injected at runtime via environment variables, never stored in repo
- [ ] AC9: Re-running the same target on the same bundle produces comparable metadata (target, hashes, prompt version, model, timestamp)
- [ ] AC10: `targets/registry.tsc` is consumed by the engine (no longer draft-only)
- [ ] AC11: `dune build` succeeds for the engine
- [ ] AC12: Each OCaml module respects purity boundaries — `lib/` is pure, `provider.ml` is the only I/O module for LLM calls

## Known Debt

- Provider/model drift may affect scores even with fixed prompts
- Chunking policy needs refinement after first real runs
- Cross-run comparability will need a formal stability policy
- No CI integration in v0.1.0
