# Self-Coherence Report — OCaml Engine v0.1.0

**Branch:** `claude/ocaml-engine-v0.1.0`
**Mode:** MCA
**Active Skills:** design, ocaml, writing
**Loaded post-iteration:** architecture-evolution, process-economics

---

## Acceptance Criteria Evidence

### AC1: OCaml engine resolves `spec`, `engine`, and `repo` from `targets/registry.tsc`
- **File:** `engine/ocaml/lib/target_registry.ml`, `engine/ocaml/bin/main.ml`
- **Evidence:** `parse_registry` parses `tsc-target-registry/0.1` format. `resolve_target_path` maps target name → manifest path. `parse_manifest` reads include/exclude/include_targets. `resolve_files` in main.ml expands `include_targets` recursively for aggregate targets.
- **Status:** Met (code exists; no build verification — see Known Limitations)

### AC2: File bundles are built deterministically without Markdown parsing
- **File:** `engine/ocaml/lib/bundle.ml`
- **Evidence:** `build_bundle` sorts files by path, computes SHA-256 hash per file via `Digestif.SHA256`. No Markdown AST anywhere in the codebase. Files are raw text.
- **Status:** Met

### AC3: LLM scoring uses one canonical instruction surface
- **File:** `runtime/SELF-MEASURE.md`
- **Evidence:** 229-line instruction defining α/β/γ scoring, evidence rules, target-specific interpretation, no-guessing rule, JSON output contract. `engine/ocaml/lib/prompt.ml` reads this file as the system message.
- **Status:** Met

### AC4: Structured output validated against JSON schema
- **File:** `engine/ocaml/lib/response_schema.ml`
- **Evidence:** `parse_json` uses `Yojson.Safe.from_string`. `validate_result` checks all required fields. `validate_score` rejects out-of-range values. `main.ml` wires validation — writes structured reports only on success, raw response always.
- **Status:** Met

### AC5: Reports in machine-readable and human-readable form
- **File:** `engine/ocaml/lib/report.ml`
- **Evidence:** `to_json` uses `Yojson.Safe.pretty_to_string` for structured output. `to_text` generates human-readable summary with C_Σ, evidence, and run metadata.
- **Status:** Met

### AC6: Python is no longer the live implementation path
- **Evidence:** `reference/python/` moved to `archive/python-reference/`. README, ARCHITECTURE, QUICKSTART no longer reference Python as current. `project.tsc` header says "superseded by targets/registry.tsc".
- **Status:** Met

### AC7: Docs describe the OCaml engine truthfully
- **README.md:** `engine/ocaml/` listed as canonical implementation
- **ARCHITECTURE.md:** Verifier section says `engine/ocaml/`
- **QUICKSTART.md:** Shows OCaml build/run path with opam/dune
- **Status:** Met

### AC8: API secrets injected at runtime, never stored in repo
- **File:** `engine/ocaml/bin/provider.ml`
- **Evidence:** `config_from_env` reads `TSC_PROVIDER`, `TSC_MODEL`, `TSC_API_KEY`, `TSC_BASE_URL` from environment. No hardcoded secrets. Request body built via `Yojson.Safe` (no string interpolation of secrets). Curl invoked via `Unix.create_process` with `--config -` (no shell).
- **Status:** Met

### AC9: Re-running produces comparable metadata
- **File:** `engine/ocaml/bin/main.ml`, `engine/ocaml/lib/report.ml`
- **Evidence:** `run_metadata` includes target, file_hashes (path→SHA-256), prompt_version, provider, model, timestamp. JSON report includes full metadata block via Yojson.
- **Status:** Met

### AC10: `targets/registry.tsc` is consumed by the engine
- **File:** `targets/registry.tsc`
- **Evidence:** Header: "The engine reads this file to resolve target names to manifests." No "draft" qualifier.
- **Status:** Met

### AC11: `dune build` succeeds
- **Evidence:** No OCaml toolchain available in this environment. Cannot verify build.
- **Status:** Not verified (environmental limitation — flagged in Plan §Risks item 6)

### AC12: Purity boundaries respected
- **Evidence:** `lib/` contains only pure modules: `types.ml`, `target_registry.ml`, `bundle.ml`, `prompt.ml`, `response_schema.ml`, `report.ml` — no I/O, no Unix, no Sys. `provider.ml` lives in `bin/` (not `lib/`), is the only module that performs I/O. `bin/main.ml` wires I/O.
- **Status:** Met

---

## Triadic Self-Assessment (post-iteration)

### α — pattern coherence
The engine has a consistent pattern: types define the domain, pure modules in `lib/` transform data, one impure module (`bin/provider.ml`) does I/O, CLI (`bin/main.ml`) wires them. Field names are disambiguated at definition (ocaml skill §2.1). Module names match their responsibility. The target model uses consistent terminology (target, manifest, registry, bundle) across all surfaces.

SHA-256 hashing now uses `digestif` (not stdlib MD5 placeholder). JSON uses `yojson` throughout (not internal type). Purity boundary is clean — provider is in `bin/`, not `lib/`.

**Score:** 0.85

### β — relational coherence
All surfaces agree on what the system is:
- README, ARCHITECTURE, QUICKSTART → `engine/ocaml/` is canonical
- targets/engine.tsc → includes `engine/ocaml/**/*.ml`
- targets/registry.tsc → consumed by engine, no "draft"
- SELF-MEASURE.md → defines the scoring contract the engine sends
- `runtime/tsc-instructions.md` → scoped to "theory-mode LLM integration", points to SELF-MEASURE.md for measurement

`include_targets` expansion implemented — `repo` target actually resolves spec + engine files.

**Score:** 0.80

### γ — process coherence
The system can survive change:
- theory independent of implementation language (spec/ unchanged)
- target model explicit and consumed
- scoring instruction is a separate surface
- provider swappable via env vars
- reports include metadata for run comparison
- invariant list explicit in DESIGN.md

Gaps: no CI, no build verification, no formal stability policy.

**Score:** 0.72

### C_Σ
(0.85 + 0.80 + 0.72) / 3 = **0.79**

### Bottleneck
**γ** — process coherence. Operational infrastructure (CI, build verification) absent. The architecture is sound but unproven at runtime.

---

## Cycle Iteration

### Triggers fired
- [x] loaded skill failed to prevent a finding: `architecture-evolution` not loaded → invariant list missing from first pass
- [x] loaded skill failed to prevent a finding: `ocaml` loaded but purity boundary violated (provider.ml in lib/)

### Friction log
1. First pass shipped MD5 placeholder and internal JSON type — known debt that should have been resolved before first commit, not as immediate outputs
2. `provider.ml` placed in `lib/` despite being impure — direct violation of ocaml skill §2.3
3. Shell injection risk in `provider.ml` (curl via `Printf.sprintf`) and `main.ml` (`Sys.command` for mkdir) — ocaml skill §2.5 says safe subprocess
4. Response validation was bypassed with a "TODO" comment despite being AC4
5. `include_targets` parsed but never expanded — functional gap in aggregate target resolution
6. No invariant list in design spec — architecture-evolution §2.6 requires it
7. `architecture-evolution` and `process-economics` skills not loaded for a system-boundary change

### Root cause
Skill selection gap. Chose `design`, `ocaml`, `writing` as active skills. Should have included `architecture-evolution` for a system-boundary change. The `ocaml` skill was loaded but not applied deeply enough — purity boundary and safe-subprocess rules were violated on first pass.

### Skill impact
- **ocaml** (loaded): should have prevented purity violation and shell injection. Loaded but not deeply applied.
- **architecture-evolution** (not loaded): should have prevented missing invariant list and would have forced explicit boundary-move comparison.
- **process-economics** (not loaded): would have flagged that process overhead (version dir, self-coherence) was not priced.

### MCA
Iteration applied: provider moved to `bin/`, shell injection fixed, validation wired, include_targets expanded, invariant list added. For future cycles: `architecture-evolution` must be loaded for any system-boundary MCA.

### Cycle level
**L6** — L5 misses (purity violation, shell injection, validation bypass) were caught in self-review and fixed. L6 cross-surface alignment achieved after iteration. L7 partially achieved (system boundary changed, target model made canonical) but invariant discipline and skill selection were not clean on first pass.

---

## Known Limitations

1. No OCaml toolchain in this environment — AC11 cannot be verified
2. No CI integration
3. No formal chunking policy for large targets
4. No formal cross-run stability policy
5. `target_registry.ml` uses imperative style (refs + while loop) — could be refactored to fold

## Deferred Outputs

| Item | Next MCA | First AC |
|---|---|---|
| CI integration | `claude/ci-engine-v0.1.1` | `dune build` passes in GitHub Actions |
| Chunking policy | blocked until first real runs | — |
| Stability policy | blocked until multi-run data | — |
