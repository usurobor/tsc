# Design: hybrid scoring architecture for TSC

**Issue:** #22
**Version:** 0.5.0
**Mode:** MCA
**Active Skills:** design, cap, writing
**Engineering Level:** L7

## Problem

TSC originally supported direct, local, file-based measurement through a mechanical pipeline. That path was fast, offline, deterministic, and cheap. The current OCaml engine moved the system to an LLM-native design, which improved semantic judgment but removed local/no-credential measurement. That is a regression.

The repo now has:

- a canonical OCaml engine
- named targets (`spec`, `engine`, `repo`)
- a canonical LLM scoring instruction in `runtime/SELF-MEASURE.md`

But it no longer has:

- direct file input without credentials
- a fast local structural measurement path
- a low-cost CI baseline
- a way to compare structural and semantic judgments cleanly

The incoherence is not "LLM mode exists." The incoherence is that LLM mode is the *only* mode.

## Decision

Implement one OCaml engine with two scoring backends and one shared report model.

Backends:

- **mechanical** — deterministic structural scoring
- **llm** — semantic scoring via `runtime/SELF-MEASURE.md`
- **hybrid** — run both, preserve both, and report the relationship between them

Default mode: **auto** — if provider credentials are present, run hybrid; otherwise run mechanical.

This keeps:

- one target model
- one bundle model
- one CLI
- one report schema

while restoring offline measurement.

## Prior Art

### Semgrep

Semgrep provides local CLI scans as a first-class path. That makes fast local/CI usage normal rather than a degraded fallback.

### CodeQL

CodeQL separates:

- preparation of an analyzable target
- analysis over that target
- structured output from that analysis

That separation is the right architectural lesson for TSC too.

### Structured result systems

Best-in-class analyzers preserve a stable machine-readable result contract. TSC should do the same with a canonical JSON schema, with optional later adapters if needed.

## Constraints

- OCaml remains the canonical implementation language.
- Python is not reintroduced as a live engine.
- `runtime/SELF-MEASURE.md` remains the canonical LLM scoring instruction.
- Direct file input must work again without network or credentials.
- Mechanical and LLM modes must share the same target resolution and bundle construction path.
- Markdown semantic parsing is not required in V1.
- The engine must not silently change meaning between modes.

## Challenged Assumption

The current assumption is:

> One canonical engine implies one canonical scorer.

That is false. The coherent unit is:

- one engine
- one target model
- one bundle model
- **multiple scoring backends**

## Impact Graph

### Upstream surfaces

- `targets/registry.tsc`
- `targets/spec.tsc`
- `targets/engine.tsc`
- `targets/repo.tsc`
- direct file/glob inputs

### Core engine surfaces

- `engine/ocaml/lib/target_registry.ml`
- `engine/ocaml/lib/bundle.ml`
- `engine/ocaml/lib/provider.ml`
- `engine/ocaml/lib/response_schema.ml`
- `engine/ocaml/lib/report.ml`

### New engine surfaces

- `engine/ocaml/lib/mechanical_scoring.ml`
- `engine/ocaml/lib/hybrid_scoring.ml`

### Docs / UX surfaces

- `README.md`
- `QUICKSTART.md`
- `ARCHITECTURE.md`
- `runtime/SELF-MEASURE.md`

---

## Proposal

### 1. One engine, multiple scoring backends

The OCaml engine should have this shape:

1. Resolve target or file input
2. Build deterministic bundle
3. Choose scoring backend
4. Compute result
5. Validate and write report

The scoring backend is selected by `--mode`:

- `mechanical`
- `llm`
- `hybrid`
- `auto`

### 2. Restore direct file input

The engine must support both:

**Named targets:**
```bash
coh --target spec --registry targets/registry.tsc
```

**Direct file input:**
```bash
coh --mode mechanical --files docs/**/*.md README.md
```

Direct file input is required to restore the old low-friction measurement path.

### 3. Mechanical backend

Mechanical mode computes structural proxies over the raw file bundle. It should not attempt deep semantic interpretation.

**V1 responsibilities:**

- Terminology consistency
- Repeated concept alignment
- Cross-file reference density / stability where available
- Authority / version / generated-vs-canonical consistency
- Structural stability under chunking / bundle construction

**Output:**

- `alpha`
- `beta`
- `gamma`
- `c_sigma`
- structural evidence only

**Mechanical mode is:**

- fast
- offline
- deterministic
- cheap

**Mechanical mode is not:**

- a semantic judge
- a replacement for the LLM path

### 4. LLM backend

The LLM backend remains the semantic scorer. It uses:

- `runtime/SELF-MEASURE.md`
- the same deterministic bundle model
- one structured output schema

The LLM backend is authoritative for semantic coherence judgments.

### 5. Hybrid backend

Hybrid runs both backends on the same bundle. It preserves:

- mechanical result
- LLM result
- final adjudicated result

**Suggested contract:**

```json
{
  "target": "spec",
  "mode": "hybrid",
  "mechanical": {
    "alpha": 0.81, "beta": 0.74, "gamma": 0.62,
    "c_sigma": 0.72,
    "evidence_kind": "structural-proxy"
  },
  "llm": {
    "alpha": 0.88, "beta": 0.83, "gamma": 0.79,
    "c_sigma": 0.83,
    "evidence_kind": "semantic-judgment"
  },
  "final": {
    "source": "llm",
    "alpha": 0.88, "beta": 0.83, "gamma": 0.79,
    "c_sigma": 0.83
  }
}
```

**Rules:**

- Preserve both measurements
- Do not blur them
- Make evidence kind explicit

### 6. Report schema

Use one canonical JSON schema across all modes.

**Minimum fields:**

- `target`
- `mode`
- `alpha`
- `beta`
- `gamma`
- `c_sigma`
- `bottleneck_axis`
- `evidence`
- `unresolved_ambiguity`
- `next_fixes`
- `run_metadata`

Hybrid adds:

- `mechanical`
- `llm`
- `final`

JSON is canonical. Optional later adapters may emit SARIF-like or other formats if useful.

### 7. Bundle model

Bundle construction remains deterministic and shared.

Per file:

- path
- target kind
- raw content
- content hash
- optional chunk metadata

No semantic Markdown parser in V1. The bundle is the common substrate for both backends.

### 8. CLI surface

Required commands / flags:

```bash
coh --mode mechanical --files ...
coh --mode llm --target spec --registry targets/registry.tsc --instruction runtime/SELF-MEASURE.md
coh --mode hybrid --target repo --registry targets/registry.tsc
coh --mode auto --target spec --registry targets/registry.tsc
```

Default: `auto`

If no provider credentials are present: `auto` resolves to `mechanical`.

### 9. Runtime / secret contract

Provider config must come from runtime config only:

- provider name
- model name
- API key
- optional base URL

No secrets in repo. No secrets in target manifests.

---

## Leverage

This design **restores:**

- offline measurement
- direct file input
- fast CI feedback
- low-cost author loops

while **keeping:**

- the OCaml engine
- the target model
- the LLM semantic path
- one report contract

It removes the regression without reintroducing a second implementation language or second engine.

## Negative Leverage

This **adds:**

- one more backend to maintain
- risk of users comparing mechanical and LLM scores as if they mean the same thing
- more report complexity
- more test surface

## Alternatives Considered

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| LLM-only engine | One scorer, one path | Regresses offline/local measurement | Rejected |
| Restore Python as offline engine | Fastest path back to local mode | Two live engines, split authority | Rejected |
| OCaml engine with only mechanical scoring | Fully local and deterministic | Loses semantic judgment advantage | Rejected |
| OCaml engine with mechanical + llm + hybrid | Restores local path, keeps semantic depth, one engine | More internal complexity | **Chosen** |

## Process Cost / Automation Boundary

**Automate:**

- target resolution
- direct file bundle construction
- mechanical scoring
- LLM prompt generation
- response validation
- report generation

**Do not automate:**

- theory changes inferred from one run
- silent backend substitution
- semantic interpretation of backend disagreement without explicit policy

## Acceptance Criteria

- [ ] AC1: `coh --mode mechanical --files <paths>` works without credentials or network
- [ ] AC2: `coh --mode llm --target spec` still works (no regression)
- [ ] AC3: `coh --mode hybrid` produces both structural and semantic results in one report
- [ ] AC4: Direct file input and named target input share the same bundle model
- [ ] AC5: Mechanical mode is deterministic on identical input
- [ ] AC6: All modes emit the same canonical JSON schema shape
- [ ] AC7: README / QUICKSTART / ARCHITECTURE document all modes
- [ ] AC8: Python remains retired as a live engine
- [ ] AC9: `runtime/SELF-MEASURE.md` remains the canonical LLM backend instruction
- [ ] AC10: Mode choice is visible in every report
- [ ] AC11: Auto falls back to mechanical when provider credentials are absent
- [ ] AC12: Backend disagreement is preserved, not hidden, in hybrid mode

## Known Debt

- Mechanical scoring weights and proxies will need one calibration pass
- Hybrid adjudication may need a stronger final-selection policy later
- Optional secondary report formats can wait
- Non-Markdown/non-text target handling may need one more pass once engine targets grow
