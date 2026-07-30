# ADR — Repository planes

**Status:** Accepted · partial migration in progress
**Date:** 2026-07-30

## Context

The tree had grown by accretion and mixed abstraction levels at the root
(human-knowledge classes, lifecycle stages, executable-artifact types, and
machine-config types all as peers). Newcomers had no coherent path. We want the
simplest, most coherent structure that follows proven practice
(cnos reader-intent docs; Diátaxis; OpenTelemetry spec/impl/conformance
separation; Rust-RFC / Kubernetes-KEP proposal lifecycle).

## Decision

Organize the repository by **plane of responsibility** — not by file-type and
not by TSC's own ontology. Documentation is organized by **reader intent**.
Topics are navigated through indexes / program-maps, not physical co-location.

### Target planes (root)

| plane | question it answers |
|---|---|
| `spec/` | what must implementations and methodologies satisfy? |
| `src/` | what executable behavior do we ship? (engine, skills) |
| `conformance/` | what proves compliance with the spec? |
| `research/` | what are we investigating before it is authoritative? |
| `docs/` | what does a human learn, do, look up, or understand? |
| `scripts/` | what automates repository work? |

Decision rule: *does it bind* → `spec/`; *run* → `src/`; *prove the spec* →
`conformance/`; *still change* → `research/`; *help a person* → `docs/`;
*automate* → `scripts/`.

### Docs reader-intent taxonomy (Diátaxis + cnos portal)

`quickstart · concepts · guides · reference · architecture · development ·
papers · evidence`. One human need per document. α/β/γ is measurement and role
grammar — never a filing taxonomy.

### Iterations applied to the original proposal (YAGNI / KISS)

1. **Defer `src/packages/`.** One real executable package today (the proxy);
   keep `src/` flat (`src/engine/`, `src/skills/`) until a second package
   (ascent) is executable.
2. **Co-locate tests with their build system.** dune expects the engine's tests
   in-tree; a universal top-level `tests/` fights language idioms. Reserve any
   shared plane for build-agnostic fixtures only.
3. **`targets/` are engine-owned config** — the `coh` binary resolves them — so
   they fold into the engine, not a single-occupant `config/` plane.
4. **"No meaning change," not "no edits."** Mechanical path/link fixups are part
   of an atomic move; no document's *meaning* changes in a move commit.

### Do NOT touch

`.cdd/` (vendored, manifest-pinned), `.cn-sigma/`, `heldout/` (CM self-test
data) are tooling/data, not repository content.

## Migration state

**Done (this milestone):**

- Landed 4.1.0 Draft + repository reconciliation + the Articulation Ascent
  capture on `main` first, so no reviewed work is orphaned under a moved tree
  (sequencing per the accepted recommendation). In-flight branches deleted.
- Established `research/` as the pre-normative plane; moved `ascent/` →
  `research/ascent/` (zero references — safe).
- Established `docs/architecture/decisions/` (this ADR).

**Deferred to CI-gated iterations (recorded, not loose ends):**

- **Docs reader-intent portal population** — `concepts/`, `guides/`,
  `reference/`, etc.; split the foundation docs by job
  (`DESIGN.md` → `docs/architecture/decisions/`, `ARCHAEOLOGY.md` →
  `research/foundation/archaeology/`, `CUTOVER-RECEIPT.md` → `docs/evidence/`);
  `illustrations/` → `docs/concepts/illustrations/`. Safe (markdown + links).
- **`src/` consolidation** — `engine/` and `skills/` under `src/`, `targets/`
  folded into the engine, `katas/` to a tests plane, schemas co-located with
  owners. This rewires 100s of references plus CI `working-directory`, dune,
  opam, `cue`, the `.cdd` manifest, and the self-measure render byte-identity —
  **none of which this environment can build-verify locally.** It must land as
  one atomic change **gated by CI**, not pushed blind. Reference counts at time
  of writing: `engine/ocaml` 118, `skills/` 106, `katas/` 53, `targets/` 44,
  `runtime/SELF-MEASURE` 43, `schemas/` 35.

## Invariants any move commit must preserve

CI green; render byte-identity holds (`scripts/render-self-measure.sh --check`);
targets resolve; conformance validator exits 0
(`scripts/ci/validate-v4-conformance.sh`); no document's meaning changes.

## Program maps (how topics navigate without topic-folders)

### TSC Foundation
- Specification: `spec/` · Conformance: `conformance/foundation-v4/`
- Implementation: `engine/ocaml/` (→ `src/engine/` when consolidated)
- History: `research/foundation/` (archaeology, once moved)

### Articulation Ascent
- Research program: `research/ascent/` · Decisions: `research/ascent/DECISIONS.md`
- Traces: `research/ascent/traces/` · Future package: `src/…/ascent/` ·
  Future conformance: `conformance/ascent/`
