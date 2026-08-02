# CM language — CUE encoding of the TSC CM model

This tree encodes the TSC CM (Coherence Methodology) model in **CUE** as its
first concrete source language. It is a **parallel** encoding built to validate
the model: the existing Markdown CMs under `research/repository-coherence/`
remain the source of truth and the human/explanatory layer, and are not edited
here.

## Architecture

```
abstract CM model
  → CUE source            (schema.cue + examples/<cm>/cm.cue)
  → compiled canonical JSON IR   (compiled/<cm>.json, via `cue export`)
  → Markdown stays the human/explanatory layer
  → execution via typed external bindings (tools/skills/child-CMs/oracles)  [later increment]
  → C≡ embedded as a typed field                                            [later increment]
```

A CM is a **package** (a directory), not one file.

## CUE-first rationale

No custom DSL yet. CUE is used first; a bespoke construct is added ONLY when a
real CM cannot be expressed without it. CUE already gives this model the three
things it needs:

1. **Types + constraints as one language.** `#ResultClass` is a four-value enum;
   the child envelope's `status_mapping[status]` is unified with `result_class`
   so an inconsistent receipt fails to compile.
2. **Composition as data, not prose.** The deterministic step-6 derivation lives
   in `result.precedence` and `result.mapping` — a fresh reader executes the
   parent result from the compiled JSON alone, with no code and no re-reading of
   the Markdown.
3. **A real compiler.** `cue vet` type-checks schema against instance;
   `cue export` emits the canonical IR. The JSON in `compiled/` is genuine
   `cue export` output, never hand-written.

## Status

**Increment 1 — parent only.** `schema.cue` types every load-bearing element of
the parent Repository Coherence CM (`research/repository-coherence/CM.md`, v0.1),
and `examples/repository-coherence/cm.cue` encodes that parent losslessly and
compiles. `#ChildReceiptEnvelope` is deliberately general enough that the
Structure and Legibility child receipts validate against it next increment; the
children themselves are **not** encoded yet (designed for, not delivered).

**Increment 2 — first leaf.** `examples/structure/cm.cue` encodes the Structure
Coherence CM (`research/repository-coherence/structure/CM.md`, v0.2) — a **leaf**
CM. Increment 1's `#Methodology` is *composite* (children + `#ResultComposition`);
a leaf has no children and derives its `result_class` from a **Result rule** over
its own procedure output. That required two minimal, justified schema extensions
(below): a `#AspectMethodology` leaf shape (with `#Procedure` / `#ResultRule`),
and opening `#ChildReceiptEnvelope` for aspect-specific typed fields. The
concrete instance is run 0002 (`DEFECTS_FOUND → DEFECT` @ `48b9a63`); its
mapping self-unification is accepted, and an inconsistent `result_class` is
rejected by `cue vet`. The parent's IR is byte-identical after the change.

## How to compile

Both files declare `package cm`; CUE unifies files passed on the command line
into one instance regardless of directory.

```
cd research/cm-language

# type-check schema + instance
cue vet schema.cue examples/repository-coherence/cm.cue

# emit the canonical JSON IR
cue export schema.cue examples/repository-coherence/cm.cue \
  --out json -e repository_coherence > compiled/repository-coherence.json

# increment 2 — the Structure leaf CM
cue vet    schema.cue examples/structure/cm.cue
cue export schema.cue examples/structure/cm.cue \
  --out json -e structure > compiled/structure.json

# regression — the parent still vets after the shared schema change
cue vet schema.cue examples/repository-coherence/cm.cue
```

All commands exit 0. `cue` v0.13.2.

## Files

| Path | Role |
|---|---|
| `schema.cue` | The abstract model: `#Methodology` (composite) + `#AspectMethodology` (leaf), `#ChildReceiptEnvelope`, `#CompositeReceipt`, `#ResultClass`, `#ResultComposition`, `#Procedure`, `#ResultRule`, etc. |
| `examples/repository-coherence/cm.cue` | The parent Repository Coherence CM (composite) encoded against the schema. |
| `examples/structure/cm.cue` | The Structure Coherence CM (leaf, v0.2) encoded against `#AspectMethodology`. |
| `compiled/repository-coherence.json` | The parent's canonical IR — real `cue export` output. |
| `compiled/structure.json` | The Structure leaf's canonical IR — real `cue export` output. |

## Lossless-comparison — Markdown parent → CUE field

Every load-bearing element of `research/repository-coherence/CM.md` (and its
`requirements.md`) mapped to the CUE field that now carries it.

| Markdown element (CM.md) | CUE field |
|---|---|
| Title / version `v0.1` | `id` / `version` |
| Governing question | `question` |
| Signature `RepositoryCoherenceCM(repository_snapshot, selected_aspects) → CompositeReceipt` | `input.repository_snapshot`, `input.selected_aspects`, `receipt: #CompositeReceipt` |
| "parent does not inspect files; composes aspects, never audiences" | `#Methodology` has no file-inspection field; children are `#AspectSource` refs only |
| Generic child receipt envelope (all 10 fields) | `#ChildReceiptEnvelope` (`aspect_id`, `cm_version`, `profile`, `repository_commit`, `result_class`, `status`, `scope`, `findings`, `refusals`, `unobserved_surfaces`, `evidence_refs`) |
| `result_class` = the four-value generic interface | `#ResultClass: "PASS" \| "DEFECT" \| "INCOMPLETE" \| "FAILED"` |
| The four `result_class` definitions + FAILED/INCOMPLETE boundary | `#ResultClassDefinitions` (carried on `result_class_definitions`) |
| `status` = child's richer vocabulary, retained verbatim, never collapsed | `#ChildReceiptEnvelope.status: string` (free), retained in `receipt.child_receipts[*].status` |
| "each child declares its own status → result_class mapping" | `#ChildReceiptEnvelope.status_mapping: {[string]: #ResultClass}`, unified so `status_mapping[status] == result_class` |
| Composition step 1–2 (resolve, verify implemented, execute on snapshot, validate envelope, reject other-commit) | `children: {[name]: #AspectSource}` (`implemented`, `selected`) + `receipt.child_receipts[*].repository_commit` bound + `invariants.same_snapshot` |
| Composition step 3 (retain child receipts unchanged) | `invariants.retain_child_receipts` + `receipt.child_receipts` (verbatim) |
| Composition step 4 (retain/surface cross-aspect relations; non-gating in v0.1) | `#CrossAspectRelation`, `receipt.atlas[...]`, `atlas.gating: false` |
| Composition step 5 (coverage; empty selection → INCOMPLETE) | `#Coverage` (`selected`/`executed`/`unavailable`/`failed`/`registered_unselected`); empty-selection rule stated in `#ResultComposition` doc |
| Composition step 6 (deterministic precedence, no weighting/averaging) | `result.precedence: ["FAILED","INCOMPLETE","DEFECT","PASS"]` + `invariants.allow_scalar_aggregation: false` |
| Step-6 four outcome branches → parent status names | `result.mapping: {FAILED→CM_EXECUTION_FAILED, INCOMPLETE→INCOMPLETE, DEFECT→DEFECTS_FOUND, PASS→COHERENT_WITHIN_MEASURED_ASPECTS}` |
| Parent statuses (exactly four) | `result.statuses` (closed list) |
| Parent α — execution manifestation / same-snapshot binding | `manifestation` (`same_snapshot_binding`, `records`) |
| Parent β — cross-aspect atlas, non-gating in v0.1 | `atlas` (`gating: false`, `note`) + `receipt.atlas` |
| Parent γ — continuation; first run `BASELINE — no prior composite receipt` | `#Continuation`, `receipt.continuation`, `continuation_baseline` sentinel |
| "What the parent does not own" (4 items) | `does_not_own: [...]` |
| Requirements reference (7 `RCM-*`) | `requirements: [...#Requirement]` (all 7, id + text) |
| `RCM-BOUNDARY-001` measure-only boundary | `boundary` (`measure_only: true`, `note`) + `#Requirement` entry |
| CompositeReceipt output shape | `#CompositeReceipt` (`repository_commit`, `coverage`, `child_receipts`, `composite_status`, `continuation`, `atlas`) |

### Capture gaps

**None lost.** Every load-bearing element of the Markdown parent is carried by a
typed CUE field, and the deterministic composition (step-6 precedence and the
status mapping) is now executable data rather than prose. Two observations, both
intended and neither a loss:

- The composition **algorithm's control flow** (walk `precedence`; first class
  present, with `unavailable`/empty-selection folded to `INCOMPLETE`) is carried
  as data plus a doc comment on `#ResultComposition`; it is not itself executed
  by CUE. Executing it belongs to the interpreter layer (typed external
  bindings), a later increment — the DATA needed to execute it is complete.
- The four `result_class` definitions and the α/β/γ notes are prose strings, but
  they are **model-required definitional fields** (the meaning of the composition
  interface), not explanatory commentary, so they are correctly present in the
  IR.

---

## Increment 2 — the Structure leaf CM

`examples/structure/cm.cue` encodes the Structure Coherence CM (leaf, v0.2)
against the schema. A leaf runs a **procedure** and derives its `result_class`
from a **Result rule** over that procedure's output; it composes no children.
The increment-1 composite model could not express this, so the schema was
extended twice — each extension is a recorded finding (a construct is earned
only when a real CM needs it).

### Schema extensions (each with its justification)

**S1 — `#AspectMethodology` (leaf shape) + `#Procedure` + `#ResultRule`.**
*A leaf CM cannot be expressed by the increment-1 model because* the composite
`#Methodology` derives its result from `#ResultComposition` — a precedence walked
over **child** `result_class`es — and emits a `#CompositeReceipt`. A leaf has no
children: it enumerates → classifies → records → refuses → searches consumers →
emits, and derives `result_class` from a rule with FAILED/INCOMPLETE/DEFECT/PASS
conditions over **its own** procedure output. None of `children`,
`#ResultComposition`, `#CompositeReceipt`, or the parent α/β/γ manifestation
fields apply. *Added* a separate `#AspectMethodology` (KISS: composite and leaf
are genuinely different shapes, so a discriminated union would only muddy both),
carrying `#Procedure` (typed `inputs` · ordered `steps` · `result`) and
`#ResultRule` (ordered guarded `clauses` + `otherwise`). `#ResultRule` is the
leaf analog of `#ResultComposition`: same FAILED>INCOMPLETE>DEFECT>PASS
precedence, but guards over procedure output instead of a precedence over
children. The leaf still emits a `#ChildReceiptEnvelope`, so it plugs into the
parent composition unchanged.

**S2 — opened `#ChildReceiptEnvelope` for aspect-specific typed fields.**
*A leaf receipt cannot be expressed by the increment-1 envelope because* Structure
carries typed fields beyond the shared ten — `plane_classification`,
`canonical_path_map`, `policy_authority`, and per-finding `repairability` +
`consumer_search` — and `#ChildReceiptEnvelope` was a **closed** definition that
rejects any field not declared on it. *Added* a single `...` opening the envelope
so each aspect unifies its own typed extensions onto it (`#StructureReceipt =
#ChildReceiptEnvelope & {…}` in the leaf package, where the leaf-private types
`#Repairability`, `#ConsumerSearch`, `#StructureFinding`, `#StructureRefusal`
live — they are not part of the generic model). The generic-vs-aspect-private
boundary is now preserved by *which fields the parent reads* (only
`result_class` / `status` / `status_mapping`), not by closedness. The parent
instance adds no extra fields, so its exported IR is byte-identical (verified).

**S3 — optional `adr_clause?` on `#Requirement` (minor, parent-safe).**
Leaf requirements each trace to a clause of their governing policy (the ADR);
the composite's `RCM-*` requirements do not. *Added* an **optional** `adr_clause?`
field; the parent omits it, so it is absent from the parent IR and the parent
still vets. (A `#RetiredRequirement` type was also added to carry the retired-id
note as data.)

Nothing else in `schema.cue` changed. The composite `#Methodology` and every
increment-1 construct are untouched.

### Lossless-comparison — Structure CM.md (v0.2) → CUE field

| Markdown element (`structure/CM.md`, `requirements.md`, run 0002) | CUE field |
|---|---|
| Title / `cm_version: 0.2` | `id: "tsc.repository-coherence.structure"` / `version: "0.2"` |
| Governing claim | `question` |
| Profile / policy authority (`repository-planes`) | `profile: "repository-planes-v1.2"` (see version-skew note) |
| Executable core — `Inputs: repository snapshot · policy snapshot · exclusions` | `procedure.inputs: [...#ProcedureInput]` (3 typed inputs) |
| Executable core — the 6 numbered steps | `procedure.steps: [...#ProcedureStep]` (`n` · `action` · `checks`→STRUCT-* ids) |
| Result rule (FAILED / INCOMPLETE / DEFECT / PASS conditions) | `procedure.result: #ResultRule` — 3 ordered `clauses` + `otherwise: "PASS"`, executable as data |
| Status vocabulary (5 values) + status→result_class mapping | `statuses: [...]` + `status_mapping: {…}` (`DEFECTS_FOUND→DEFECT`, `COHERENT_WITHIN_DECLARED_SCOPE→PASS`, `UNDERDETERMINED→INCOMPLETE`, `INCOMPLETE_OBSERVATION→INCOMPLETE`, `CM_EXECUTION_FAILED→FAILED`) |
| The four `result_class` definitions | `result_class_definitions: #ResultClassDefinitions` (carried once) |
| 15 `STRUCT-*` requirements (id · claim · ADR clause) | `requirements: [...#Requirement]` (all 15, `id`+`text`+`adr_clause`) |
| Retired `STRUCT-LIFECYCLE-001` note | `retired_requirements: [{id, note}]` |
| Generic child receipt envelope, `aspect_id: structure` | `receipt: #StructureReceipt` (= `#ChildReceiptEnvelope & …`), `aspect_id: "structure"` |
| Envelope additions `+ plane_classification` / `+ canonical_path_map` / `+ policy_authority` | `receipt.plane_classification` / `.canonical_path_map` / `.policy_authority` (S2) |
| Consumer-search contract (surfaces · strength · consumers · digest · unsearched) | `#ConsumerSearch` (per-finding `consumer_search`) |
| Typed repairability `MECHANICAL \| POLICY_REQUIRED \| DEFERRED` | `#Repairability` (per-finding `repairability`) |
| Findings F3–F12 (run 0002), each id · requirement · claim · repairability · evidence (+ consumer_search on F4/F7/F8/F9/F10/F11/F12) | `receipt.findings: [...#StructureFinding]` |
| Refusal R1 (`STRUCT-REFUSE-001`, destination operator-open) | `receipt.refusals: [...#StructureRefusal]` |
| Overall `status DEFECTS_FOUND → result_class DEFECT @ 48b9a63` | `receipt.status` / `.result_class` / `.repository_commit`, mapping self-unified |
| Measure-only boundary (`STRUCT-REPAIR/REVIEW-001`, parent `RCM-BOUNDARY-001`) | `boundary: #Boundary` |
| "defers to the ADR; authors no policy of its own" | `does_not_own: ["policy…", "repair…", "independent review closure"]` |

### Capture gap + one deliberate deviation

- **Version skew (deliberate, documented).** The CM's `profile` is encoded as
  `repository-planes-v1.2` — the policy authority now on `main` (commit `2cb2932`
  ratified v1.2). `structure/CM.md`, `requirements.md`, and `fixtures/` still read
  v1.1 because those Markdown files are the source of truth and are **not edited**
  here. The frozen run-0002 receipt is encoded **verbatim** at `profile:
  repository-planes-v1.1` / `policy_authority … @ 48b9a63 (v1.1)` — it is an
  immutable historical receipt and records the version it actually executed
  under. So the CM tracks current policy while its frozen run keeps its own
  version. This is the sole place the CUE encoding does not copy CM.md's literal
  text, and it is intentional per the increment-2 brief.
- **No other loss.** Every load-bearing element of the leaf CM (inputs, the six
  steps, the Result rule, the 15 requirements, the receipt envelope + Structure
  extensions, the consumer-search contract, typed repairability, the refusal) is
  a typed CUE field. As with the parent, the Result rule's control flow (walk
  clauses top-down; first guard true) is carried as data + a doc comment on
  `#ResultRule`; executing it is the interpreter layer's job, and the DATA is
  complete.

### The coverage→INCOMPLETE fold — parent-only (carried forward)

Increment 1 recorded that the composite's `unavailable`/empty-selection →
`INCOMPLETE` fold is carried as data + a doc comment on `#ResultComposition`, not
executed by CUE. **Does Structure exercise anything similar?** Yes, an analog but
NOT the same fold: a leaf has no children to be `unavailable`, so the
coverage-fold does not apply. Its equivalent is the Result rule's INCOMPLETE
clause — *"inventory or consumer search is incomplete, or policy leaves every
actionable destination unresolved"* — which folds an incomplete observation to
`INCOMPLETE` at the leaf boundary (the same PASS/DEFECT/INCOMPLETE/FAILED
interface the parent then composes). Like the parent's fold it is carried as an
ordered `#ResultRule` clause (data) with a doc comment, not executed by CUE. Run
0002 does **not** trigger it: inventory is complete (475 tracked / 255 classified,
no inaccessible surface) and every move-candidate carries its consumer graph, so
the INCOMPLETE and FAILED clauses are both false — the run lands on the DEFECT
clause.

### Two-executor readiness

Could a fresh executor derive Structure's `result_class` for run-0002's inputs by
applying the encoded Result rule from `compiled/structure.json` alone? **Yes —
result `DEFECT`.** Walk `procedure.result.clauses` top-to-bottom:

1. **FAILED?** *"a required mechanical check cannot execute, or a move/split/delete
   finding is emitted without its mandatory consumer_search block."* Inventory ran
   (475 tracked, 255 classified); every move-candidate finding (F4, F7, F8,
   F9–F12) carries a `consumer_search` block. → **false.**
2. **INCOMPLETE?** *"inventory or consumer search is incomplete, or policy leaves
   every actionable destination unresolved."* Inventory complete; consumer graphs
   complete/complete-within-bound; policy resolves the actionable destinations for
   F3–F5, F7, F9–F12 (only R1's destination is refused, not *every* one). →
   **false.**
3. **DEFECT?** *"at least one policy violation is established."* F3–F12 establish
   policy violations. → **true → `DEFECT`.**

No re-reading of the Markdown is needed; the clauses, the findings, and the
consumer-search completeness are all in the compiled IR. The receipt's own
`result_class: "DEFECT"` matches this independent derivation, and `status_mapping`
(`DEFECTS_FOUND → DEFECT`) is self-unified so an inconsistent receipt fails
`cue vet` (verified with a negative probe).
