# Self-Coherence Report — OCaml Engine v0.1.0

**Branch:** `claude/ocaml-engine-v0.1.0`
**Mode:** MCA
**Active Skills:** design, ocaml, writing

---

## Acceptance Criteria Evidence

### AC1: OCaml engine resolves `spec`, `engine`, and `repo` from `targets/registry.tsc`
- **File:** `engine/ocaml/lib/target_registry.ml`
- **Evidence:** `parse_registry` parses `tsc-target-registry/0.1` format. `resolve_target_path` maps target name → manifest path. `parse_manifest` reads include/exclude/include_targets.
- **Status:** Met (code exists; no build verification — see Known Limitations)

### AC2: File bundles are built deterministically without Markdown parsing
- **File:** `engine/ocaml/lib/bundle.ml`
- **Evidence:** `build_bundle` sorts files by path, computes hash per file via `hash_content`. No Markdown AST anywhere in the codebase. Files are raw text.
- **Status:** Met

### AC3: LLM scoring uses one canonical instruction surface
- **File:** `runtime/SELF-MEASURE.md`
- **Evidence:** 229-line instruction defining α/β/γ scoring, evidence rules, target-specific interpretation, no-guessing rule, JSON output contract. `engine/ocaml/lib/prompt.ml` reads this file as the system message.
- **Status:** Met

### AC4: Structured output validated against JSON schema
- **File:** `engine/ocaml/lib/response_schema.ml`
- **Evidence:** `validate_result` checks all required fields (target, alpha, beta, gamma, bottleneck_axis, confidence, summary, axis_evidence, unresolved_ambiguity, next_fixes). `validate_score` rejects out-of-range values. Returns `Error` for malformed input.
- **Status:** Met (uses internal JSON type; production should use yojson)

### AC5: Reports in machine-readable and human-readable form
- **File:** `engine/ocaml/lib/report.ml`
- **Evidence:** `to_json` generates JSON with result + metadata. `to_text` generates human-readable summary with C_Σ calculation, evidence, and run metadata.
- **Status:** Met

### AC6: Python is no longer the live implementation path
- **Evidence:** `reference/python/` moved to `archive/python-reference/`. README, ARCHITECTURE, QUICKSTART no longer reference Python as current. `project.tsc` header says "superseded by targets/registry.tsc".
- **Status:** Met

### AC7: Docs describe the OCaml engine truthfully
- **README.md:** "The canonical implementation is the OCaml engine in `engine/ocaml/`."
- **ARCHITECTURE.md:** Verifier section says "The canonical implementation is: engine/ocaml/"
- **QUICKSTART.md:** Shows OCaml build/run path with opam/dune
- **Status:** Met

### AC8: API secrets injected at runtime, never stored in repo
- **File:** `engine/ocaml/lib/provider.ml`
- **Evidence:** `config_from_env` reads `TSC_PROVIDER`, `TSC_MODEL`, `TSC_API_KEY`, `TSC_BASE_URL` from environment. No hardcoded secrets anywhere.
- **Status:** Met

### AC9: Re-running produces comparable metadata
- **File:** `engine/ocaml/bin/main.ml`, `engine/ocaml/lib/report.ml`
- **Evidence:** `run_metadata` includes target, file_hashes (path→hash), prompt_version, provider, model, timestamp. JSON report includes full metadata block.
- **Status:** Met

### AC10: `targets/registry.tsc` is consumed by the engine
- **File:** `targets/registry.tsc`
- **Evidence:** Header changed from "draft" to "The engine reads this file to resolve target names to manifests." `targets/README.md` authority section no longer says "draft."
- **Status:** Met

### AC11: `dune build` succeeds
- **Evidence:** No OCaml toolchain available in this environment. Code follows dune conventions (dune-project, lib/dune, bin/dune). Cannot verify build.
- **Status:** Not verified (environmental limitation — flagged in Plan §Risks item 6)

### AC12: Purity boundaries respected
- **Evidence:** `types.ml`, `target_registry.ml`, `bundle.ml`, `prompt.ml`, `response_schema.ml`, `report.ml` — all pure, no I/O, no Unix, no Sys (except `Sys.getenv_opt` in `provider.ml`). `provider.ml` is the only module that performs I/O (HTTP via curl subprocess). `bin/main.ml` wires I/O.
- **Status:** Met

---

## Triadic Self-Assessment

### α — pattern coherence
The engine has a consistent pattern: types define the domain, pure modules transform data, one impure module does I/O, CLI wires them. Field names are disambiguated at definition (ocaml skill §2.1). Module names match their responsibility. The target model uses consistent terminology (target, manifest, registry, bundle) across all surfaces.

**Score:** 0.80 — coherent structure, but hash implementation uses MD5 placeholder instead of SHA-256.

### β — relational coherence
Docs, targets, and engine agree on what the system is:
- README says "engine/ocaml/ — canonical implementation"
- ARCHITECTURE says "The canonical implementation is: engine/ocaml/"
- targets/engine.tsc includes `engine/ocaml/**/*.ml`
- targets/registry.tsc is consumed by the engine
- SELF-MEASURE.md defines the scoring contract the engine sends

One relational gap: `runtime/tsc-instructions.md` still references `v3.1.0` and the old authority chain without mentioning the engine transition.

**Score:** 0.75 — surfaces agree on the new identity, but legacy runtime instructions carry old assumptions.

### γ — process coherence
The system can survive change:
- theory is independent of implementation language (spec/ unchanged)
- target model is explicit and consumed
- scoring instruction is a separate surface from the engine
- provider is swappable via env vars
- reports include enough metadata for run comparison

Gap: no CI integration, no build verification, no formal stability policy for cross-run comparability.

**Score:** 0.70 — change paths are clear, but operational infrastructure is not yet present.

### C_Σ
(0.80 + 0.75 + 0.70) / 3 = **0.75**

### Bottleneck
**γ** — process coherence. The engine exists as code but has no build verification, no CI, and no operational infrastructure yet. The theory and target model are stable, but the verifier layer needs operational proof.

---

## Known Limitations

1. No OCaml toolchain in this environment — AC11 cannot be verified
2. `bundle.ml` uses `Digest` (MD5) as hash placeholder — production needs SHA-256
3. `response_schema.ml` uses internal JSON type — production needs yojson
4. `provider.ml` uses curl subprocess — production could use an HTTP library
5. `runtime/tsc-instructions.md` carries stale v3.1.0 references
6. No CI integration
7. No formal chunking policy for large targets
