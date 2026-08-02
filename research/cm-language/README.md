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
```

Both commands exit 0. `cue` v0.13.2.

## Files

| Path | Role |
|---|---|
| `schema.cue` | The abstract model: `#Methodology`, `#ChildReceiptEnvelope`, `#CompositeReceipt`, `#ResultClass`, `#ResultComposition`, etc. |
| `examples/repository-coherence/cm.cue` | The parent Repository Coherence CM encoded against the schema. |
| `compiled/repository-coherence.json` | The canonical IR — real `cue export` output. |

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
