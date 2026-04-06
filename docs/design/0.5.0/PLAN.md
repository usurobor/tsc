# Plan — mechanical + hybrid scoring for TSC

**Issue:** #22
**Version:** 0.5.0
**Mode:** MCA
**Active Skills:** design, writing, cap
**Engineering Level:** L7

## Goal

Restore local, offline file-based measurement without giving up the new OCaml engine or the LLM-based semantic scorer.

The end state is one engine with three modes:

- mechanical
- llm
- hybrid

and one shared pipeline:

1. resolve input
2. build bundle
3. score bundle
4. validate result
5. write report

## Why this plan exists

The current engine made semantic scoring stronger, but removed a capability the old system had:

- direct file input
- no-network measurement
- low-cost local iteration
- deterministic structural feedback

That is a regression. This plan restores that capability inside the canonical OCaml engine instead of reviving Python as a parallel implementation.

## Sequencing principle

Do not add new target or provider complexity while the scoring split is still unclear. Implement in this order:

1. one shared bundle path
2. one deterministic mechanical scorer
3. one clear mode switch
4. one shared report schema
5. one hybrid orchestration layer
6. only then update docs and default behavior

## Scope

This plan covers:

- mechanical scoring backend
- hybrid orchestration
- direct file input
- report schema integration
- CLI mode selection
- docs updates

This plan does not cover:

- new theory
- new targets
- provider redesign
- Python compatibility
- secondary output formats

---

## Step 1 — stabilize the shared bundle path

### Deliverable

Named targets and direct file inputs both produce the same `Bundle.t`.

### Work

- Confirm the current target-resolution path produces a deterministic bundle
- Add direct file/glob input path
- Normalize ordering, hashing, and metadata shape
- Ensure both paths produce the same canonical bundle form

### Exit

The engine can build a bundle from:

- `--target spec --registry targets/registry.tsc`
- `--files docs/**/*.md README.md`

with the same downstream interface.

---

## Step 2 — define the mechanical scoring contract

### Deliverable

`engine/ocaml/lib/mechanical_scoring.mli`

### Work

- Define `config`
- Define `axis_result`
- Define `result`
- Define `diagnostic`
- Define deterministic guarantees
- Define what "mechanical" means and does not mean

### Exit

The structural scorer has a stable interface before implementation details expand.

---

## Step 3 — implement mechanical scoring

### Deliverable

`engine/ocaml/lib/mechanical_scoring.ml`

### Work

Implement deterministic structural signals for:

**α / pattern:**
- Terminology consistency
- Repeated heading / section structure
- Duplicate-definition tension
- Naming drift

**β / relational:**
- Cross-file reference consistency
- Authority / ownership agreement
- Source-of-truth alignment
- Target-to-file fit

**γ / process:**
- Generated vs canonical distinction
- Evolution / version surface consistency
- Traceability / closeout presence
- Drift across declared authority surfaces

### Exit

The engine can score a bundle with no provider, no network, and no Markdown AST.

---

## Step 4 — wire the mode switch

### Deliverable

One clear mode surface in the CLI and engine.

### Work

Add:

- `--mode mechanical`
- `--mode llm`
- `--mode hybrid`
- `--mode auto`

Behavior:

- `mechanical` → mechanical scorer only
- `llm` → provider scorer only
- `hybrid` → run both
- `auto` → hybrid if provider credentials present, else mechanical

### Exit

Mode choice is explicit and visible in every run.

---

## Step 5 — unify the report schema

### Deliverable

One canonical report model across all modes.

### Work

Extend the current result/report layer so it can represent:

- mechanical-only result
- llm-only result
- hybrid result with:
  - mechanical
  - llm
  - final

### Exit

Reports preserve backend distinction without inventing multiple incompatible output formats.

---

## Step 6 — implement hybrid scoring

### Deliverable

`engine/ocaml/lib/hybrid_scoring.ml` or equivalent orchestration in the main flow.

### Work

- Run both backends over the same bundle
- Preserve both result sets
- Compute final
- Make the final-source rule explicit:
  - LLM is semantic authority when available
  - Mechanical remains visible, not discarded

### Exit

Hybrid mode produces one report with both structural and semantic views.

---

## Step 7 — add tests

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

## Step 8 — update docs

### Deliverable

Docs reflect the new mode model clearly.

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

The docs describe the implementation truthfully.

---

## Step 9 — decide the default mode policy

### Deliverable

Explicit product decision.

### Work

Confirm whether the default CLI behavior should be:

- `auto` or
- `mechanical`

Recommended default: **auto**

Reason:

- Preserves the richer semantic path when available
- Never blocks local usage when credentials are absent

### Exit

One documented default.

---

## Acceptance Criteria

- [ ] AC1: `coh --mode mechanical --files <paths>` works without credentials or network
- [ ] AC2: `coh --mode llm --target spec --registry targets/registry.tsc` still works
- [ ] AC3: `coh --mode hybrid` preserves both result sets and one final result
- [ ] AC4: Direct file input and named target input share the same bundle model
- [ ] AC5: Mechanical scoring is deterministic on identical input
- [ ] AC6: Reports clearly mark mode and backend provenance
- [ ] AC7: Auto falls back to mechanical when provider credentials are missing
- [ ] AC8: Python is not reintroduced as a live engine
- [ ] AC9: `runtime/SELF-MEASURE.md` remains the canonical LLM scoring instruction
- [ ] AC10: Docs explain all modes and direct-file usage clearly

## Risks

### 1. Mechanical mode overclaims semantic authority

Mitigation:
- Label it structural/proxy scoring explicitly
- Preserve backend provenance in reports

### 2. Users compare mechanical and LLM scores as if they mean the same thing

Mitigation:
- Keep both result sets visible
- Define `final.source` explicitly

### 3. Mechanical scoring becomes too clever

Mitigation:
- Keep it deterministic and structural
- No hidden LLM fallback
- No semantic Markdown parsing

### 4. Direct file input drifts from target-based measurement

Mitigation:
- One shared bundle model
- Test parity at the bundle layer

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
