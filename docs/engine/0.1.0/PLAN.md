# Plan — OCaml-first, LLM-native TSC engine

**Issue:** TBD
**Version:** 0.1.0
**Mode:** MCA
**Active Skills:** design, ocaml, writing

Implements [DESIGN.md](DESIGN.md). See §Problem there for gap and targets.

## Step 1 — Scaffold the OCaml engine

### Deliverable
`engine/ocaml/` with a minimal executable skeleton that builds.

### Work
- create `engine/ocaml/dune-project`
- create `engine/ocaml/tsc_engine.opam`
- create `engine/ocaml/lib/dune` (library)
- create `engine/ocaml/bin/dune` (executable)
- create `engine/ocaml/bin/main.ml` (CLI entrypoint)
- stub all library modules

### ACs
- AC11: `dune build` succeeds

### Exit
The OCaml engine compiles to a native binary.

---

## Step 2 — Implement target resolution

### Deliverable
`Target_registry` module: named target → ordered file list.

### Work
- parse `targets/registry.tsc` (TOML-like format)
- parse `targets/*.tsc` manifests
- expand include/exclude glob patterns
- expand nested `include_targets`
- produce stable file ordering
- attach file metadata

### ACs
- AC1: resolves `spec`, `engine`, `repo` from registry
- AC10: registry is consumed (not draft-only)
- AC12: `Target_registry` is pure (no I/O in lib/)

### Exit
The engine can resolve any named target into a concrete file list.

---

## Step 3 — Implement bundle construction

### Deliverable
`Bundle` module: file list → target bundle with hashes.

### Work
- read files as raw text
- compute SHA-256 per file
- attach path, target kind, size
- no Markdown AST

### ACs
- AC2: bundles are deterministic, raw text, SHA-256 hashed
- AC12: `Bundle` is pure except for file reads (reads happen in caller)

### Exit
The engine can serialize a target into a prompt-ready bundle.

---

## Step 4 — Write the canonical self-measure instruction

### Deliverable
`runtime/SELF-MEASURE.md`

### Work
- define how α / β / γ are scored
- define evidence requirements
- define no-guessing rules
- define output schema contract
- define target-specific interpretation (spec / engine / repo)

### ACs
- AC3: one canonical instruction surface exists

### Exit
The prompt logic has one canonical textual authority.

---

## Step 5 — Define the response schema

### Deliverable
`Response_schema` module: validate structured JSON output.

### Work
- define required fields: target, alpha, beta, gamma, bottleneck_axis, confidence, summary, axis_evidence, unresolved_ambiguity, next_fixes
- validate types and ranges
- reject malformed responses

### ACs
- AC4: malformed output is rejected deterministically
- AC12: validation is pure

### Exit
Structured output can be validated without I/O.

---

## Step 6 — Implement provider abstraction

### Deliverable
`Provider` module: provider-agnostic LLM API client.

### Work
- read provider name, model name, API key, optional base URL from env
- support HTTP POST to provider API
- return raw response string for validation
- never persist secrets

### ACs
- AC8: secrets from env only, never in repo
- AC12: `Provider` is the only impure module for LLM calls

### Exit
The engine can call one provider cleanly.

---

## Step 7 — Implement prompt construction

### Deliverable
`Prompt` module: target bundle + self-measure instruction → prompt.

### Work
- read `runtime/SELF-MEASURE.md` as system instruction
- render target metadata
- render file bundle (paths + raw content)
- render response schema requirements
- produce deterministic prompt string

### ACs
- AC3: uses SELF-MEASURE.md
- AC9: prompt is deterministic for same bundle
- AC12: pure module

### Exit
Prompt generation is deterministic and testable.

---

## Step 8 — Implement report generation

### Deliverable
`Report` module: validated response → machine-readable + human-readable reports.

### Work
- write JSON report with all fields
- write text summary
- persist run metadata: target, file hashes, prompt version, model/provider, timestamp

### ACs
- AC5: both report formats generated
- AC9: metadata enables run comparison

### Exit
Reports are generated and inspectable.

---

## Step 9 — End-to-end integration

### Deliverable
CLI runs end-to-end: `tsc-engine measure --target spec`

### Work
- wire all modules in `main.ml`
- parse CLI args (target name, provider config)
- resolve target → build bundle → construct prompt → call provider → validate → report
- handle errors at each stage

### ACs
- AC1, AC2, AC3, AC4, AC5, AC8, AC9, AC10, AC11, AC12 (all)

### Exit
One target runs end-to-end.

---

## Step 10 — Update docs and archive Python

### Deliverable
Docs align with new reality. Python archived.

### Work
- update README.md: implementation section → OCaml
- update ARCHITECTURE.md: verifier section → OCaml engine, remove "next track" language
- update QUICKSTART.md: OCaml build/run path
- update targets/README.md: registry now live
- update targets/registry.tsc: remove draft header
- update targets/engine.tsc: include `engine/ocaml/**`
- update targets/repo.tsc: add `runtime/SELF-MEASURE.md`
- archive `reference/python/` → `archive/python/`
- update or remove `project.tsc`

### ACs
- AC6: Python no longer live
- AC7: docs describe OCaml engine truthfully
- AC10: registry no longer draft

### Exit
The repo says what it is and matches what it runs.

---

## Acceptance Checkpoints

### Checkpoint A (Steps 1–2)
- [ ] OCaml skeleton builds
- [ ] target registry resolves all three targets

### Checkpoint B (Steps 3–5)
- [ ] bundles are deterministic with hashes
- [ ] self-measure instruction exists
- [ ] response schema validates

### Checkpoint C (Steps 6–8)
- [ ] provider call works
- [ ] prompt is deterministic
- [ ] reports generated

### Checkpoint D (Steps 9–10)
- [ ] end-to-end run succeeds
- [ ] docs updated
- [ ] Python archived

---

## Risks

1. Prompt too vague → pretty output, weak measure
2. Prompt too rigid → brittle scoring
3. Chunking policy distorts target coherence
4. Provider drift reduces comparability
5. Registry format stabilizes slower than engine implementation
6. No OCaml toolchain in current environment → skeleton only, no build verification
