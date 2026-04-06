# Plan: hybrid scoring implementation

**Issue:** #22
**Design:** [DESIGN.md](DESIGN.md)
**Version:** 0.5.0

---

## Step 1 — shared bundle model

### Deliverable

One deterministic bundle type shared by all backends and both input paths.

### Work

- Define `bundle` type: path, target kind, raw content, content hash, optional chunk metadata
- Named target input (`--target spec --registry ...`) produces a bundle
- Direct file input (`--files docs/**/*.md`) produces a bundle
- Both paths use the same bundle construction

### Exit

Bundle model exists. Both input paths produce it. No scoring yet.

---

## Step 2 — direct file input

### Deliverable

`coh --files docs/**/*.md README.md` resolves files and builds a bundle without a registry or target definition.

### Work

- Add `--files` flag to CLI
- File resolution: expand globs, read content, build bundle entries
- No credentials required
- No network required

### Exit

`coh --files <paths>` builds a bundle and prints it (or a summary). No scoring yet.

---

## Step 3 — report schema

### Deliverable

One canonical JSON report schema used by all modes.

### Work

- Define report type with minimum fields: target, mode, alpha, beta, gamma, c_sigma, bottleneck_axis, evidence, unresolved_ambiguity, next_fixes, run_metadata
- Hybrid extensions: mechanical, llm, final (each with evidence_kind)
- JSON serialization
- Mode and evidence_kind always present

### Exit

Report schema exists and can be populated by any backend.

---

## Step 4 — refactor LLM backend to use shared bundle + report

### Deliverable

Current LLM scoring path refactored to consume the shared bundle model and emit the shared report schema.

### Work

- Current provider.ml / response_schema.ml adapted to accept a bundle
- Output mapped to the shared report schema
- `runtime/SELF-MEASURE.md` remains the canonical instruction
- No behavioral change — same results, new internal plumbing

### Exit

`coh --mode llm --target spec` works as before, using shared bundle and report. No regression.

---

## Step 5 — mechanical backend

### Deliverable

`engine/ocaml/lib/mechanical_scoring.ml` — pure OCaml, no I/O beyond file reads, deterministic.

### Work

V1 structural proxies:

- **α (terminology consistency):** intra-bundle term frequency alignment, repeated concept overlap
- **β (relational coherence):** cross-file reference density, authority/version/generated-vs-canonical consistency
- **γ (process coherence):** structural stability under chunking, bundle construction consistency

Properties:
- Deterministic on identical input
- No network, no credentials
- No Markdown semantic parser
- Labels output as `evidence_kind: "structural-proxy"`

### Exit

`coh --mode mechanical --files <paths>` produces a valid report with structural-proxy scores. No network calls.

---

## Step 6 — hybrid backend

### Deliverable

`engine/ocaml/lib/hybrid_scoring.ml` — runs both backends, preserves both result sets.

### Work

- Run both backends over the same bundle
- Preserve both result sets in report
- Compute final result
- Final-source rule: LLM is semantic authority when available; mechanical remains visible, not discarded

### Exit

Hybrid mode produces one report with both structural and semantic views.

---

## Step 7 — tests

### Deliverable

Mechanical and hybrid test coverage.

### Work

**Bundle parity:**
- Named target input and direct file input produce expected bundle structure

**Mechanical determinism:**
- Identical bundle + config → identical result

**Structural behavior:**
- Obvious duplicate contradiction lowers α
- Authority mismatch lowers β
- Generated/canonical drift lowers γ

**Hybrid shape:**
- Hybrid report includes both backends and final result
- Auto falls back correctly without credentials

### Exit

The backend split is test-protected.

---

## Step 8 — docs

### Deliverable

Docs reflect the new mode model.

### Work

Update:
- `README.md`
- `QUICKSTART.md`
- `ARCHITECTURE.md`

Key messaging:
- OCaml remains the canonical engine
- Python stays retired
- Offline/local file scoring is restored
- `SELF-MEASURE.md` remains the canonical LLM instruction
- Direct file input is back

### Exit

Docs describe the implementation truthfully.

---

## Step 9 — default mode policy

### Deliverable

Explicit product decision on CLI default.

### Work

Confirm default: **auto**

- If credentials present → hybrid
- If credentials absent → mechanical

Reason:
- Preserves the richer semantic path when available
- Never blocks local usage when credentials are absent

### Exit

One documented default.

---

## Acceptance Criteria

- [ ] AC1: `coh --mode mechanical --files <paths>` works without credentials or network
- [ ] AC2: `coh --mode llm --target spec` still works (no regression)
- [ ] AC3: `coh --mode hybrid` preserves both result sets and one final result
- [ ] AC4: Direct file input and named target input share the same bundle model
- [ ] AC5: Mechanical scoring is deterministic on identical input
- [ ] AC6: Reports clearly mark mode and backend provenance
- [ ] AC7: Auto falls back to mechanical when provider credentials are missing
- [ ] AC8: Python is not reintroduced as a live engine
- [ ] AC9: `runtime/SELF-MEASURE.md` remains the canonical LLM scoring instruction
- [ ] AC10: Docs explain all modes and direct-file usage clearly

## Risks

| # | Risk | Mitigation |
|---|------|------------|
| 1 | Mechanical mode overclaims semantic authority | Label as structural-proxy explicitly; preserve backend provenance |
| 2 | Users compare mechanical and LLM scores as equivalent | Keep both result sets visible; define final.source explicitly |
| 3 | Mechanical scoring becomes too clever | Keep it deterministic and structural; no hidden LLM fallback; no semantic Markdown parsing |
| 4 | Direct file input drifts from target-based measurement | One shared bundle model; test parity at the bundle layer |

## Non-goals

- Reviving Python
- Adding a Markdown semantic parser
- Redesigning provider integration
- Solving full cross-provider reproducibility
- Changing TSC theory in the same cycle

## End state

TSC regains:
- offline measurement
- direct file input
- cheap local iteration

without losing:
- the OCaml engine
- named targets
- semantic scoring
- one canonical result/report model
