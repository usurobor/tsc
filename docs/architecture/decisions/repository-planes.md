# ADR — Repository planes

**Status:** Accepted · v1.1 · partial migration in progress
**Date:** 2026-07-30 (v1) · 2026-08-02 (v1.1 amendments)

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

## Amendments (v1.1 · 2026-08-02)

Three operator policy decisions, encoded here. The v1 Decision text, decision
rule, Do-NOT-touch set, and Program maps above stand unchanged.

### 1 · The docs reader-intent taxonomy is closed

The eight reader-intent folders — `quickstart · concepts · guides · reference ·
architecture · development · papers · evidence` — are the **exhaustive** set of
`docs/` subfolders. A `docs/` subfolder outside them is a structural **defect to
rehome**, not merely undetermined. This closes what v1 left as a
named-but-unfenced list. *Rationale: an open taxonomy let real filing debt hide
as refusal.*

Consequently `docs/design/` is **not a ratified plane** — its contents are
misplaced and need a real home. This settles *misplacement* only. The correct
**destination** of the foundation-contract-reconciliation bundle remains the open
operator decision the "Deferred" note already records ("a decision to take with
the operator's frame, not to force here"). Misplacement is now determined;
destination is a separate, still-open question — no contradiction.

### 2 · generated-vs-source is ratified

Derived or generated artifacts must be distinguishable from hand-authored source
— by an excluded build directory, a generated marker, or a clearly-derived path.
*Precedent:* the render byte-identity invariant
(`scripts/render-self-measure.sh --check`) already treats a rendered artifact as
derived-and-verified, and `_build/` is excluded dune output. *Rationale: source a
reader may edit must not be mistaken for output a tool regenerates.*

### 3 · historical-labelling is ratified

Historical, archived, or frozen material retained on the live tree must carry a
lifecycle label — a banner or a marker. *Precedent:*
`docs/evidence/releases/0.12.0.md` carries a "Historical" banner, and
`docs/{alpha,beta,gamma}` are declared frozen snapshots. *Rationale: unlabelled
history on a live tree reads as current.*

### 4 · Cross-plane names-predict-content — considered and declined

A general rule that *every* plane's names predict their content was considered
and **declined** as a structure rule. It is a **legibility** value — can a reader
predict what a path holds — not a placement rule, and belongs to the legibility
aspect. Structure ratifies only "docs file by reader intent," the closed docs
taxonomy (§1), and "α/β/γ … never a filing taxonomy." Recorded here, not silently
dropped.

## Migration state

**Done (this milestone):**

- Landed 4.1.0 Draft + repository reconciliation + the Articulation Ascent
  capture on `main` first, so no reviewed work is orphaned under a moved tree
  (sequencing per the accepted recommendation). In-flight branches deleted.
- Established `research/` as the pre-normative plane; moved `ascent/` →
  `research/ascent/` (zero references — safe).
- Established `docs/architecture/decisions/` (this ADR).
- Established `docs/concepts/` and moved `illustrations/` →
  `docs/concepts/illustrations/` (reader-intent: *concepts* = explanation).
  Two references (README map row, this ADR) rewritten; no outbound links inside
  the illustrations broke (all same-directory). Markdown + links only.
- **Consolidated the executable planes under `src/`:** `engine/` → `src/engine/`,
  `skills/` → `src/skills/` (branch `cycle/repo-planes-src`, **CI-gated**). All
  live path references rewritten; frozen `.cdd/`, `docs/alpha/`, and CHANGELOG
  history preserved. Fixed-depth breakages caught and repaired locally: the
  `VERSION` build dep (`bin/dune`) and the kata-test path candidates. Verified
  locally before hand-off to CI: `cue` schema vet, render byte-identity,
  conformance validator, skill-frontmatter validator, dune structure parse. The
  pinned OCaml 5.2 build + link (otoml/digestif/ezcurl) is CI's gate.

**Deferred to CI-gated iterations (recorded, not loose ends):**

- **Docs reader-intent portal population** — `guides/`, `reference/`, etc. as
  real content lands (empty scaffolding is YAGNI, not resolution).
- **Foundation-contract-reconciliation bundle** — deferred, and *not* the
  mechanical three-way fragmentation first sketched (`DESIGN.md` → decisions,
  `ARCHAEOLOGY.md` → research/foundation, `CUTOVER-RECEIPT.md` → evidence).
  On inspection the folder is one cross-referenced review thread — `DESIGN.md`,
  `ARCHAEOLOGY.md`, `CUTOVER-RECEIPT.md`, and `ROUND2/3/4-REVIEW-RESPONSE.md`
  all answer each other — so a by-file split would orphan the review responses
  and break the thread. It also sits in a genuinely open plane: it is design
  *history* of something now **authoritative** (ratified 4.0.0), which fits
  neither `research/` (defined as *not yet* authoritative) nor a live-reference
  plane. The coherent home (intact bundle under an archive/history plane vs.
  `docs/explanation/`) is a decision to take with the operator's frame, not to
  force here.
- **Remaining `src/` moves** — `targets/` folded into the engine, `katas/` to a
  tests plane, `runtime/SELF-MEASURE.md` co-located with its skill, schemas
  co-located with owners. Each a further CI-gated change.

## Invariants any move commit must preserve

CI green; render byte-identity holds (`scripts/render-self-measure.sh --check`);
targets resolve; conformance validator exits 0
(`scripts/ci/validate-v4-conformance.sh`); no document's meaning changes.

## Program maps (how topics navigate without topic-folders)

### TSC Foundation
- Specification: `spec/` · Conformance: `conformance/foundation-v4/`
- Implementation: `src/engine/ocaml/`
- History: `research/foundation/` (archaeology, once moved)

### Articulation Ascent
- Research program: `research/ascent/` · Decisions: `research/ascent/DECISIONS.md`
- Traces: `research/ascent/traces/` · Future package: `src/…/ascent/` ·
  Future conformance: `conformance/ascent/`
