# CM language — CUE encoding of the TSC CM model

This tree encodes the TSC CM (Coherence Methodology) model in **CUE** as its
first concrete source language. It is a **parallel** encoding built to validate
the model: the existing Markdown CMs under `research/repository-coherence/`
remain the source of truth and the human/explanatory layer, and are not edited
here.

> **Where is this going?** See [`DIRECTION.md`](DIRECTION.md) — the product
> direction: the layered architecture, frozen principles, what is proven today,
> and the roadmap (the coherent whole that the CM-language issues are slices of).

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

> **Authoring the `.cm` surface language?** See [`LANGUAGE.md`](LANGUAGE.md) — the
> reference + short walkthrough for the ML-shaped `.cm` language the OCaml
> front-end (`surface/`) compiles to this IR.

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
its own procedure output. That required justified schema extensions (below): a
`#AspectMethodology` leaf shape (with `#Procedure` / `#ResultRule`), a
**corralled-open** `#ChildReceiptEnvelope` (closed shared fields + one
`aspect_ext` region), and optional `adr_clause` / `class` / `severity` on
`#Requirement`. The Result rule is grounded in typed per-finding fields and its
verdict is **computed by CUE**: the concrete instance is run 0002
(`DEFECTS_FOUND → DEFECT` @ `48b9a63`), `derived_result_class` is unified with
`result_class`, an inconsistent `result_class` and a typo'd top-level field are
both rejected by `cue vet`, and the parent's IR is byte-identical after the
change. (This reflects the post-review state; see the four fixes below.)

**Increment 3 — second leaf, shape validation.** `examples/legibility/cm.cue`
encodes the Repository Legibility Coherence CM
(`research/repository-coherence/legibility/CM.md`, v0.2) — a **second, differently-
shaped leaf** — against the SETTLED increment-2 leaf shape. The research question
was exact: does that shape encode a differently-shaped leaf **without adding any
schema construct**? **Yes — with ZERO change to `schema.cue`** (finding S6). Where
Structure emits `DEFECT` from policy violations with move/split/delete findings,
Legibility emits `PASS` (`COHERENT_WITHIN_DECLARED_SCOPE`) from a passing newcomer
fixture (6/6), its profile is a human newcomer (`technical-newcomer-human`) not a
policy version, and it carries a **bounded refusal** (`RUN-EXEC-01` — coh/kata exit
codes not executed). Legibility's own typed fields (per-requirement `REPO-*` check
verdicts, the blind newcomer fixture, a scoped refusal) ride the corralled
`aspect_ext` region + the already-open `findings`/`refusals` lists — no top-level
definition and no field on a closed shared shape was added. The concrete instance
is run 0003 (`COHERENT_WITHIN_DECLARED_SCOPE → PASS` @ `48b9a63`);
`derived_result_class` is CUE-computed and unified with `result_class`; the parent
and Structure IRs are byte-identical after this increment.

**Increment 4A — the generic leaf boundary + CM0 (no assessment runs).** The prior
schema is a *repository-coherence* language: `#ChildReceiptEnvelope`,
`#Methodology`, and `#AspectMethodology` all assume a git-repository/aspect world.
4A adds the smallest **generic leaf-CM** boundary *beneath* that specialization, so
a methodology whose target is *another methodology* — **CM0** — is an ordinary
`#LeafMethodology`, not a CM0 special case. `#AspectMethodology` is re-expressed as
a specialization (`#LeafMethodology & {…git_repository…}`), and `examples/cm0/cm.cue`
encodes CM0 as a pure `#CMSource & #LeafMethodology` — **no `#CM0Methodology` root
type exists**. The generalization **forces nothing**: it adds only optional/hidden
fields, and the three prior IRs re-export **byte-for-byte**. CM0 has **no run** in
4A (that is 4B/4C/4D): the five subcontracts are typed, provider-bound *check steps*
with **no receipts computed**, the boundary is measure-only and CUE-enforced, and
the CUE export is honestly typed as a `#NormalizedCMIR` (a methodology program, not
a `#CompiledCM`). See the increment-4A section (findings G1–G5) below.

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

# increment 3 — the Legibility leaf CM (ZERO schema change)
cue vet    schema.cue examples/legibility/cm.cue
cue export schema.cue examples/legibility/cm.cue \
  --out json -e legibility > compiled/legibility.json

# regression — both prior leaves/parent still vet and re-export byte-identical
cue vet schema.cue examples/repository-coherence/cm.cue
cue vet schema.cue examples/structure/cm.cue

# increment 4A — CM0, an ordinary #LeafMethodology whose target is a methodology
cue vet    schema.cue examples/cm0/cm.cue
cue export schema.cue examples/cm0/cm.cue \
  --out json -e cm0_ir > compiled/cm0.json      # CM0's NormalizedCMIR

# CM0's IR validates against the concrete #NormalizedCMIR contract
cue vet compiled/cm0.json schema.cue -d '#NormalizedCMIR'

# regression — the three prior IRs still re-export byte-identical (the "beneath" proof)
cue export schema.cue examples/repository-coherence/cm.cue --out json -e repository_coherence | diff - compiled/repository-coherence.json
cue export schema.cue examples/structure/cm.cue --out json -e structure | diff - compiled/structure.json
cue export schema.cue examples/legibility/cm.cue --out json -e legibility | diff - compiled/legibility.json
```

All commands exit 0. `cue` v0.13.2.

## Files

| Path | Role |
|---|---|
| `schema.cue` | The abstract model: `#Methodology` (composite) + `#AspectMethodology` (leaf), `#ChildReceiptEnvelope`, `#CompositeReceipt`, `#ResultClass`, `#ResultComposition`, `#Procedure`, `#ResultRule`, etc. |
| `examples/repository-coherence/cm.cue` | The parent Repository Coherence CM (composite) encoded against the schema. |
| `examples/structure/cm.cue` | The Structure Coherence CM (leaf, v0.2) encoded against `#AspectMethodology`. |
| `examples/legibility/cm.cue` | The Legibility Coherence CM (leaf, v0.2) encoded against `#AspectMethodology` — **zero schema change** (S6). |
| `compiled/repository-coherence.json` | The parent's canonical IR — real `cue export` output. |
| `compiled/structure.json` | The Structure leaf's canonical IR — real `cue export` output. |
| `compiled/legibility.json` | The Legibility leaf's canonical IR — real `cue export` output. |
| `examples/cm0/cm.cue` | **CM0** (increment 4A): the methodology whose target is another methodology, as an ordinary `#CMSource & #LeafMethodology` — plus its `#NormalizedCMIR` projection `cm0_ir`. No run. |
| `compiled/cm0.json` | CM0's **NormalizedCMIR** — real `cue export -e cm0_ir` output; validates against `#NormalizedCMIR`. A methodology program only; **no measurement receipt**. |

The increment-4A generic layer added beneath the specialization: `#LeafMethodology`,
`#CMSource`, `#NormalizedCMIR`, `#ArtifactRef`, `#TargetRef`, `#MethodologyRef`,
`#TargetContract`, `#ReceiptEnvelope`, `#ArtifactSlot`, `#InstrumentSubject`,
`#CheckStep`, `#InstrumentAssessment`, and the extended `#Boundary`.

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
extended — each extension is a recorded finding (a construct is earned only when
a real CM needs it). This section reflects the post-review (β REVISE) state:
Fix 1 (determinism — the Result rule is grounded in typed IR fields and the
verdict is CUE-computed), Fix 2 (S2 corralled-open), Fix 3 (profile v1.1), Fix 4
(requirement `class`/`severity` carried).

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

**S2 — corralled-open `#ChildReceiptEnvelope` (revised after review).**
*A leaf receipt cannot be expressed by the increment-1 envelope because* Structure
carries typed fields beyond the shared ten — `plane_classification`,
`canonical_path_map`, `policy_authority`, a computed `derivation`, and per-finding
`repairability` / `consumer_search` / `move_candidate` / `destination_resolved` —
and `#ChildReceiptEnvelope` was a **closed** definition that rejects any field not
declared on it. The first attempt opened the whole envelope with a bare `...`;
**β proved that voided ALL field-name validation** on the shared, load-bearing
interface (a receipt with a typo'd `result_clas` and a `totally_bogus` field
passed `cue vet`). The genuinely minimal fix keeps the shared ten fields
**closed** and adds **one** designated open sub-region, `aspect_ext?: {...}`,
where aspects hang their typed extensions (per-finding extras ride the
already-open `findings` list). `#StructureReceipt = #ChildReceiptEnvelope &
{ aspect_ext: {…}, findings: [...#StructureFinding], … }`; the leaf-private types
(`#Repairability`, `#ConsumerSearch`, `#StructureFinding`, `#StructureRefusal`)
live in the leaf package, not the generic model. Now a typo'd top-level field is
**rejected** by `cue vet` (verified) while the structure receipt still vets, and
the parent — which sets no `aspect_ext` — exports a byte-identical IR (verified).

**S3 — optional `adr_clause?`, `class?`, `severity?` on `#Requirement`
(parent-safe).** Leaf requirements each trace to a policy (ADR) clause, carry a
checking `class` (mechanical / semantic / process), and a `severity`; the
composite's `RCM-*` requirements carry none of these. *Added* all three as
**optional** fields. `class` is load-bearing, not cosmetic (Fix 4): the Result
rule's FAILED clause references "a required **mechanical** check", so which
requirements are mechanical must be in the IR — `derivation.mechanical_requirements`
is computed from it. The parent omits all three, so they are absent from the
parent IR and the parent still vets byte-identically. (A `#RetiredRequirement`
type was also added to carry the retired-id note as data.)

Nothing else in `schema.cue` changed. The composite `#Methodology` and every
increment-1 construct are untouched. `#ResultRule` / `#Procedure` /
`#AspectMethodology` (S1) are unchanged from the first submission — β accepted the
leaf shape; the revisions live in the leaf encoding (typed finding fields + a
CUE-computed `derivation`) and the two small schema tweaks above.

### Lossless-comparison — Structure CM.md (v0.2) → CUE field

| Markdown element (`structure/CM.md`, `requirements.md`, run 0002) | CUE field |
|---|---|
| Title / `cm_version: 0.2` | `id: "tsc.repository-coherence.structure"` / `version: "0.2"` |
| Governing claim | `question` |
| Profile / policy authority (`repository-planes` **v1.1**) | `profile: "repository-planes-v1.1"` (matches CM.md/requirements/fixtures/run 0002; see S5) |
| Executable core — `Inputs: repository snapshot · policy snapshot · exclusions` | `procedure.inputs: [...#ProcedureInput]` (3 typed inputs) |
| Executable core — the 6 numbered steps | `procedure.steps: [...#ProcedureStep]` (`n` · `action` · `checks`→STRUCT-* ids) |
| Result rule (FAILED / INCOMPLETE / DEFECT / PASS conditions) | `procedure.result: #ResultRule` — 3 ordered `clauses` (each `when` names the typed `derivation.*` fields) + `otherwise: "PASS"`; the verdict is CUE-computed in `receipt.aspect_ext.derivation` |
| Status vocabulary (5 values) + status→result_class mapping | `statuses: [...]` + `status_mapping: {…}` (`DEFECTS_FOUND→DEFECT`, `COHERENT_WITHIN_DECLARED_SCOPE→PASS`, `UNDERDETERMINED→INCOMPLETE`, `INCOMPLETE_OBSERVATION→INCOMPLETE`, `CM_EXECUTION_FAILED→FAILED`) |
| The four `result_class` definitions | `result_class_definitions: #ResultClassDefinitions` (carried once) |
| 15 `STRUCT-*` requirements (id · claim · ADR clause · **class** · **severity**) | `requirements: [...#Requirement]` (all 15, `id`+`text`+`adr_clause`+`class`+`severity`) |
| Requirement **class** (mechanical / semantic / process) + severity (requirements.md) | `#Requirement.class?` / `.severity?` (Fix 4; `class` feeds `derivation.mechanical_requirements`) |
| Retired `STRUCT-LIFECYCLE-001` note | `retired_requirements: [{id, note}]` |
| Generic child receipt envelope, `aspect_id: structure` | `receipt: #StructureReceipt` (= `#ChildReceiptEnvelope & …`), `aspect_id: "structure"` |
| Envelope additions `+ plane_classification` / `+ canonical_path_map` / `+ policy_authority` | `receipt.aspect_ext.plane_classification` / `.canonical_path_map` / `.policy_authority` (S2 corralled) |
| Consumer-search contract (surfaces · strength · consumers · digest · unsearched) | `#ConsumerSearch` (per-finding `consumer_search`, or `null`) |
| Typed repairability `MECHANICAL \| POLICY_REQUIRED \| DEFERRED` | `#Repairability` (per-finding `repairability`) |
| Move/split/delete finding MUST carry a consumer graph (else not repair-ready) | per-finding `move_candidate: bool` + `consumer_search: #ConsumerSearch \| null`; the FAILED arm detects `move_candidate ∧ consumer_search==null` (Fix 1) |
| Repairability typing implies whether policy decides the destination | per-finding `destination_resolved: bool` = `repairability != "POLICY_REQUIRED"` (drives the INCOMPLETE "every destination unresolved" arm) |
| Result-rule verdict for run 0002 (the Overall §) | `receipt.aspect_ext.derivation` — CUE-computed guard sets + booleans + `derived_result_class`, unified with `result_class` |
| Findings F3–F12 (run 0002), each id · requirement · claim · repairability · evidence · move_candidate (+ consumer_search on F4/F7/F8/F9–F12) | `receipt.findings: [...#StructureFinding]` |
| Refusal R1 (`STRUCT-REFUSE-001`, destination operator-open) | `receipt.refusals: [...#StructureRefusal]` |
| Overall `status DEFECTS_FOUND → result_class DEFECT @ 48b9a63` | `receipt.status` / `.result_class` (= `derivation.derived_result_class`) / `.repository_commit`, mapping self-unified |
| Measure-only boundary (`STRUCT-REPAIR/REVIEW-001`, parent `RCM-BOUNDARY-001`) | `boundary: #Boundary` |
| "defers to the ADR; authors no policy of its own" | `does_not_own: ["policy…", "repair…", "independent review closure"]` |

### S5 — profile v1.1 is a scope boundary, not a version skew (Fix 3)

The first submission labelled the CM `profile: repository-planes-v1.2` (the policy
now on `main`) while its body was v1.1. **β showed that is a contradiction, not a
cosmetic label:** ADR v1.2 §3 is substantive — it closes R1 (decides the
foundation-bundle destination) and makes F3–F8 mechanical. But this CM's *body* is
v1.1: every requirement `adr_clause` cites "(v1.1) §1/§2/§3", `STRUCT-REFUSE-001`
is still open, and the R1 refusal is live. A v1.2 label on a v1.1 body is a
receipt an executor would trip on.

This increment is a **faithful, lossless encoding of Structure CM v0.2 as it
exists** (v1.1-bodied). Reconciling the CM to v1.2 — closing R1, reclassifying
F3–F8 as mechanical, retiring the refusal — is a **separate methodology cell**
(a new run against the v1.2 policy), **out of scope for the language encoding**;
folding it in here would break losslessness. So the active `profile` is
`repository-planes-v1.1`, matching `structure/CM.md`, `requirements.md`,
`fixtures/`, and run 0002. The frozen run-0002 receipt stays `v1.1 @ 48b9a63`
verbatim (correct — immutable). **Deferred, recorded here:** Structure CM v0.2's
body is now behind ADR v1.2 and wants a reconciliation cell.

### Capture gap

- **No loss.** Every load-bearing element of the leaf CM (inputs, the six steps,
  the Result rule, the 15 requirements + their class/severity, the receipt
  envelope + Structure extensions under `aspect_ext`, the consumer-search
  contract, typed repairability, the refusal) is a typed CUE field. Unlike the
  first submission, the Result rule is no longer prose-only: each clause `when`
  names the typed `derivation.*` fields it reads, and the verdict itself is
  **computed by CUE** in `receipt.aspect_ext.derivation` and unified with
  `result_class`, so the IR is mechanically evaluable and the verdict is
  compiler-checked (a broken finding fails `cue vet`).

### The coverage→INCOMPLETE fold — parent-only (carried forward)

Increment 1 recorded that the composite's `unavailable`/empty-selection →
`INCOMPLETE` fold is carried as data + a doc comment on `#ResultComposition`, not
executed by CUE. **Does Structure exercise anything similar?** Yes, an analog but
NOT the same fold: a leaf has no children to be `unavailable`, so the
coverage-fold does not apply. Its equivalent is the Result rule's INCOMPLETE
clause — heuristic consumer search, or *every* actionable destination unresolved
— which folds an incomplete observation to `INCOMPLETE` at the leaf boundary (the
same PASS/DEFECT/INCOMPLETE/FAILED interface the parent then composes). Unlike the
parent's fold, this one is **not** left to a doc comment: it is grounded in typed
per-finding fields (`consumer_search.search_strength`, `destination_resolved`) and
**computed by CUE** in `derivation.incomplete_guard`. Run 0002 does **not** trigger
it: inventory is complete (475 tracked / 255 classified), no search is `heuristic`
(`derivation.heuristic_searches == []`), and destinations are not all unresolved
(`derivation.unresolved_destinations == [F4,F6,F7,F8]`, not all ten), so
`incomplete_guard == false` — the run lands on the DEFECT clause.

### Two-executor readiness

Could a fresh executor derive Structure's `result_class` for run-0002's inputs
using **only** `compiled/structure.json` — with zero appeal to CM.md or domain
knowledge? **Yes — result `DEFECT`,** and the IR carries the whole derivation as
typed data under `receipt.aspect_ext.derivation`. The executor walks
`procedure.result.clauses` top-to-bottom, evaluating each `when` over named IR
fields:

1. **FAILED?** `failed_mechanical_checks` non-empty **OR**
   `move_candidates_missing_search` non-empty. In the IR both are `[]`
   (`failed_mechanical_checks: []`; every finding with `move_candidate: true` —
   F4, F7, F8, F9–F12 — has a non-null `consumer_search`). → `failed_guard = false`.
2. **INCOMPLETE?** `heuristic_searches` non-empty **OR** `unresolved_destinations`
   equals *all* findings. In the IR `heuristic_searches: []` (every
   `search_strength` is `complete` or `complete_within_bound`, and
   `incomplete_search_strengths: ["heuristic"]` states those both count as
   complete); `unresolved_destinations: [F4,F6,F7,F8]` (the four POLICY_REQUIRED
   findings) ≠ all ten findings. → `incomplete_guard = false`.
3. **DEFECT?** `findings_establishing_defect` non-empty. In the IR it lists all ten
   (F3–F12). → `defect_guard = true` → **`DEFECT`.**

Every one of those fact-sets and booleans is present in the compiled IR, and
`derived_result_class: "DEFECT"` is computed by CUE and unified with the receipt's
`result_class`. Determinism is therefore compiler-checked, not asserted:

- `derivation.derived_result_class == receipt.result_class == "DEFECT"` (unified).
- **Negative probe A** — forcing `result_class: "PASS"` on this `DEFECTS_FOUND`
  receipt → `cue vet` **rejects** (conflicts with both the derived `DEFECT` and the
  `status_mapping`).
- **Negative probe B** — a typo'd top-level `result_clas` / `totally_bogus` field →
  `cue vet` **rejects** (`field not allowed`; the S2 corralling restored this).
- **Liveness probe C** — appending a malformed move-candidate (`move_candidate:
  true`, `consumer_search: null`) makes `move_candidates_missing_search: ["FX"]`
  and `derived_result_class: "FAILED"` — proving the FAILED arm is not dead code but
  genuinely detects the near-miss fixture's `CM_EXECUTION_FAILED` scenario.

---

## Increment 3 — the Legibility leaf CM (shape validation, zero extension)

`examples/legibility/cm.cue` encodes the Repository Legibility Coherence CM (leaf,
v0.2) against the schema. The increment's core research question: **does the
increment-2 leaf shape encode a second, differently-shaped leaf CM without any new
schema construct?** It does. **Nothing in `schema.cue` changed** — verified by an
empty `git diff` on `schema.cue` and by both prior IRs re-exporting byte-identical.

### Why Legibility is a genuinely different leaf (so this is a real test)

| axis | Structure (increment 2) | Legibility (increment 3) |
|---|---|---|
| verdict at HEAD | `DEFECTS_FOUND → DEFECT` | `COHERENT_WITHIN_DECLARED_SCOPE → PASS` |
| profile | a **policy version** (`repository-planes-v1.1`) | a **human reader** (`technical-newcomer-human`) |
| check shape | move/split/delete findings + `consumer_search` | per-requirement `REPO-*` verdicts + a blind newcomer fixture (6/6) |
| refusal | destination refusal (`R1`, silent policy) | **bounded** single-check refusal (`RUN-EXEC-01`, exec not run) |
| defect list at HEAD | 10 findings (F3–F12) | **empty** (no in-scope defect) |

Structure's `move_candidate` / `consumer_search` / `destination_resolved` fields do
**not** apply to Legibility and were **not** forced on. Legibility's own typed
fields live entirely in the leaf package (`#RequirementCheck`, `#NewcomerQuestion`,
`#LegibilityRefusal`, `#LegibilityFinding`, `#LegibilityReceipt`) and hang under the
one corralled `aspect_ext` region + the already-open `findings` / `refusals` lists
— exactly the mechanism S2 introduced. Using an open region that already exists is
**not** a schema extension.

### S6 — the leaf shape sufficed with ZERO extension (the validating finding)

This is the increment's finding. The settled increment-2 leaf shape
(`#AspectMethodology` + `#Procedure` + `#ResultRule` + corralled `#ChildReceiptEnvelope`
with `aspect_ext?` + `#Requirement.class`) encoded Legibility **losslessly with no
new top-level definition and no new field on any closed shared shape.** Concretely,
the four things that make Legibility *look* like it needs new machinery each landed
on an existing affordance:

1. **PASS instead of DEFECT** — the leaf `#ResultRule` already walks
   `FAILED > INCOMPLETE > DEFECT` guards over procedure output with `otherwise:
   "PASS"`. Legibility's run-0003 trips no guard, so it lands on `otherwise` = PASS.
   No shape change: PASS was always the else-arm.
2. **A newcomer human profile** — `profile` is a free `string` on both
   `#AspectMethodology` and `#ChildReceiptEnvelope`; `"technical-newcomer-human"`
   fits with no change. (The parent never learns the leaf's profile vocabulary.)
3. **Per-requirement checks + a blind fixture** (a different *evidence* shape than
   Structure's findings) — carried as `requirement_checks` and `newcomer_fixture`
   under `aspect_ext`, plus `#Requirement.class` (reused, not added) driving
   `mechanical_requirements`. The defect list `findings` is simply empty this run.
4. **The bounded refusal** — carried on the already-open `refusals` list with a
   leaf-private `#LegibilityRefusal` type; its typed `scope` field is the whole
   trick (below). No envelope change.

**Minimality ledger: ZERO schema changes.** The ideal outcome. The increment-2 leaf
shape is validated by a second, differently-shaped leaf: `schema.cue` is untouched,
`compiled/repository-coherence.json` and `compiled/structure.json` re-export
byte-identical, and Legibility still vets and exports. No S6-plus **extension** was
forced; S6 records the **absence** of one. (Had any real element of Legibility been
inexpressible, it would appear here as a justified extension with the same rigor as
S1–S3; none was.)

### The bounded refusal — a scope boundary, not a defect and not an INCOMPLETE

The load-bearing subtlety. `RUN-EXEC-01` is `kind: INCOMPLETE_OBSERVATION` — the
`coh` / `run-katas.sh` exit codes were not executed (no opam/network) — yet the run
is `PASS`, not `INCOMPLETE`. CM.md and the run state exactly why: the refusal
**bounds one check, not the inventory, and does not flip the categorical status.**
That reading is encoded as **typed data**, not inferred: every `#LegibilityRefusal`
carries a `scope: "single_check" | "inventory"`, and `derivation.incomplete_guard`
fires only for `inventory_incomplete_refusals` — refusals whose `scope` is in
`derivation.status_flipping_refusal_scopes` (`["inventory"]`). `RUN-EXEC-01` has
`scope: "single_check"`, so it lands in `bounded_refusals` (recorded, non-flipping)
and trips nothing. REPO-RUN-001's *structural* face still passes, so it is not a
`failed_requirement_check` either. A fresh executor reads this off the IR — no
appeal to the prose.

### Lossless-comparison — Legibility CM.md (v0.2) → CUE field

| Markdown element (`legibility/CM.md`, `requirements.md`, run 0003) | CUE field |
|---|---|
| Title / `cm_version: 0.2` | `id: "tsc.repository-coherence.legibility"` / `version: "0.2"` |
| Governing claim | `question` |
| Reader profile (technical newcomer, no TSC vocabulary) | `profile: "technical-newcomer-human"` |
| Four subcontracts (local clarity · relational/authority · lifecycle/lineage · operability) | `procedure.steps` (7 ordered steps mapping the four subcontracts + newcomer fixture + α/β/γ) |
| Executable inputs (snapshot · reader profile · live-surface policy · exclusions) | `procedure.inputs: [...#ProcedureInput]` (4 typed inputs) |
| Result rule (FAILED / INCOMPLETE / DEFECT / PASS) | `procedure.result: #ResultRule` — 3 ordered `clauses` (each `when` names the typed `derivation.*` fields) + `otherwise: "PASS"`; verdict CUE-computed in `receipt.aspect_ext.derivation` |
| Status vocabulary (5 values) + status→result_class mapping | `statuses` + `status_mapping` (`COHERENT_WITHIN_DECLARED_SCOPE→PASS`, `DEFECTS_FOUND→DEFECT`, `UNDERDETERMINED→INCOMPLETE`, `INCOMPLETE_OBSERVATION→INCOMPLETE`, `CM_EXECUTION_FAILED→FAILED`) |
| 11 `REPO-*` requirements (id · claim · **class** · **severity**) | `requirements: [...#Requirement]` (all 11, `id`+`text`+`class`+`severity`; no `adr_clause` — Legibility traces to its own fixtures, not an ADR) |
| Refusal semantics (bounded vs inventory; refusal is a finding) | `#LegibilityRefusal` (`kind` + **`scope`**); `derivation.inventory_incomplete_refusals` vs `bounded_refusals` |
| Generic child receipt envelope, `aspect_id: legibility` | `receipt: #LegibilityReceipt` (= `#ChildReceiptEnvelope & …`), `aspect_id: "legibility"` |
| Envelope fields (scope · unobserved_surfaces · evidence_refs) | `receipt.scope` / `.unobserved_surfaces` / `.evidence_refs` (verbatim from run 0003) |
| α — manifestation (commit observed, inventory complete) | `receipt.aspect_ext.manifestation` (+ `evidence_refs` inventory digest) |
| β — relational/authority atlas (graph, not a scalar) | `receipt.aspect_ext.authority_atlas: [...]` |
| Status matrix (lifecycle labels) | `receipt.aspect_ext.status_matrix: {…}` |
| γ — continuation vs run 0002 (R7, N1 closed) | `receipt.aspect_ext.continuation` |
| Newcomer-task fixture (6 questions, ≤1 hop, 6/6 PASS) | `receipt.aspect_ext.newcomer_fixture` (`questions` + computed `total`/`passed`/`all_pass`) |
| Per-requirement Findings table (9 scored `REPO-*` PASS) | `receipt.aspect_ext.requirement_checks: [...#RequirementCheck]` |
| No in-scope defect (empty defect list) | `receipt.findings: []` |
| Bounded refusal `RUN-EXEC-01` | `receipt.refusals: [#LegibilityRefusal]` (kind `INCOMPLETE_OBSERVATION`, scope `single_check`) |
| Overall `status COHERENT_WITHIN_DECLARED_SCOPE → result_class PASS @ 48b9a63` | `receipt.status` / `.result_class` (= `derivation.derived_result_class`) / `.repository_commit`, mapping self-unified |
| Measure-only boundary (`REPO-REPAIR/REVIEW-001`, parent `RCM-BOUNDARY-001`) | `boundary: #Boundary` |
| "does not repair, does not review, structure is a separate aspect" | `does_not_own: [...]` |

**Capture gap: none.** Every load-bearing element of the leaf CM and run 0003 is a
typed CUE field, and the verdict is CUE-computed and compiler-checked.

### Two-executor readiness — deriving PASS from `compiled/legibility.json` alone

A fresh executor derives Legibility's `result_class` for run-0003 using **only** the
compiled IR, walking `procedure.result.clauses` top-to-bottom over the named
`receipt.aspect_ext.derivation.*` fields:

1. **FAILED?** `execution_failed_refusals` non-empty. In the IR it is `[]` — the sole
   refusal `RUN-EXEC-01` is `kind: INCOMPLETE_OBSERVATION`, not `CM_EXECUTION_FAILED`.
   → `failed_guard = false`.
2. **INCOMPLETE?** `inventory_incomplete_refusals` non-empty. In the IR it is `[]`:
   `RUN-EXEC-01` has `scope: "single_check"`, which is **not** in
   `status_flipping_refusal_scopes: ["inventory"]`, so it is a `bounded_refusal`
   (`["RUN-EXEC-01"]`) that does **not** flip the run. Inventory is complete; no
   claimed authority missing. → `incomplete_guard = false`. **This is the crux: the
   bounded refusal does not trip INCOMPLETE, read straight off the typed `scope`.**
3. **DEFECT?** `defect_findings` **OR** `failed_requirement_checks` **OR**
   `failed_newcomer_questions` non-empty. In the IR all three are `[]`: the defect
   list `findings` is empty, all nine scored `REPO-*` `requirement_checks` are
   `PASS`, and the `newcomer_fixture` is 6/6 (`all_pass: true`). → `defect_guard =
   false`.
4. No guard fired → `otherwise` = **`PASS`.**

`derived_result_class: "PASS"` is computed by CUE and unified with `result_class`
and `status_mapping["COHERENT_WITHIN_DECLARED_SCOPE"]` — all three resolve to `PASS`.
Determinism is compiler-checked, not asserted:

- `derivation.derived_result_class == receipt.result_class == status_mapping[status]
  == "PASS"` (unified).
- **Negative probe A** — forcing `result_class: "DEFECT"` on this
  `COHERENT_WITHIN_DECLARED_SCOPE` receipt → `cue vet` **rejects** (conflicts with
  both the derived `PASS` and the `status_mapping`).
- **Negative probe C (corralled)** — a typo'd top-level `result_clas` field →
  `cue vet` **rejects** (`field not allowed`; the shared ten stay closed).
- **Liveness of every arm** (`examples`-independent evaluation of the exact guard
  formula over injected inputs): empty sets → `PASS`; a failing newcomer question →
  `DEFECT`; a `FAIL` `REPO-*` check → `DEFECT`; an **inventory**-scoped observation
  refusal → `INCOMPLETE`; a `CM_EXECUTION_FAILED` refusal → `FAILED`; a **bounded**
  single-check refusal alone → `PASS`. None of the four arms is dead code, and the
  PASS/INCOMPLETE boundary genuinely turns on the refusal's typed `scope`.

## Two-executor agreement (acceptance oracle) + a caught drift

Two fresh, independent executors ran all three CMs **from this package alone**
(no access to the Markdown source CMs, run receipts, or conversation), each
deriving `result_class` by evaluating the Result rule / composition precedence
over the typed fact-sets rather than reading the recorded verdict. Both reproduced
the prior manual executions and agreed with each other and with the recorded IR:

| cm | derived | recorded | manual baseline |
|---|---|---|---|
| structure | DEFECT | DEFECT | DEFECT |
| legibility | PASS | PASS | PASS |
| repository-coherence (composite) | DEFECTS_FOUND | DEFECTS_FOUND | DEFECTS_FOUND |

The test earned its keep: both executors independently flagged that the parent's
**embedded** `child_receipts.legibility` had drifted from the standalone legibility
leaf IR — `profile: "reader-profiles-v1"` (stale) vs the leaf's
`technical-newcomer-human`, and a `status_mapping` missing the
`INCOMPLETE_OBSERVATION` key the leaf carries. Non-gating (legibility still composes
as `PASS`), but a real inconsistency introduced when the parent example (increment 1)
hand-authored a placeholder legibility child before the legibility leaf existed
(increment 3). Synced here to the authoritative leaf values.

**Open refinement (not yet earned):** the parent embeds hand-authored copies of its
child receipts, which can drift from the leaves. A reference-based parent (composing
the leaf IRs directly) would make drift structurally impossible; deferred until the
duplication demonstrably costs more than the coupling would. Likewise the leaf
`derivation` guard→`#ResultClass` skeleton is now duplicated verbatim across both
leaf CMs — a candidate to promote to a shared `#LeafDerivation` once a third leaf
(e.g. CM0) lands.

---

## Increment 4A — the generic leaf boundary + CM0 (no assessment runs)

The prior schema was a *repository-coherence* language: `#ChildReceiptEnvelope`
(`aspect_id`/`profile`/`repository_commit`), `#Methodology`
(`repository_snapshot`/`selected_aspects`), and `#AspectMethodology` (an aspect
leaf) all assume a git-repository/aspect world. 4A adds the **smallest generic
leaf-CM boundary beneath** that specialization, so a methodology whose target is
*another methodology* — **CM0** — is an ordinary `#LeafMethodology`, not a special
case. It authors **CM0's source only**: no assessment runs, no `InstrumentAssessment`
result computed, no fixtures/calibration data (4B/4C/4D).

The design is governed by one hard constraint: **the three existing IRs must
re-export byte-for-byte.** That is the proof the generalization is *beneath* — that
it forces nothing on the settled layer. Every design choice below falls out of
reconciling the generic layer with that constraint.

### What was added (all beneath the specialization)

- **Reference algebra:** `#ArtifactRef` (content-addressed `id`·`kind`·`digest`,
  optional `version`), `#TargetRef`, `#MethodologyRef`, `#TargetContract`.
- **Generic receipt:** `#ReceiptEnvelope` (`methodology`·`target`·`result_class`·
  `status`·`status_mapping`·`scope`·`findings`·`refusals`·`evidence_refs`).
- **Generic leaf:** `#LeafMethodology` (id·version·question·`target_contract?`·
  `input?`·`procedure`·`boundary`·`output?`·`receipt?`), an **open base** so a leaf
  family specializes it with its own vocabulary.
- **Instrument types:** `#ArtifactSlot`, `#InstrumentSubject`, `#InstrumentAssessment`.
- **Typed step / provider algebra (the centerpiece):** `#StepKind`, `#ProviderRef`,
  `#TypedStep`.
- **Source/IR types:** `#CMSource`, `#NormalizedCMIR`.
- **Extended `#Boundary`:** `may_compile?`/`may_admit?`/`may_authorize?`/`may_repair?`.
- **`#AspectMethodology` re-expressed** as `#LeafMethodology & {…git_repository…}`.
- **`examples/cm0/cm.cue`** — CM0 as `#CMSource & #LeafMethodology`, plus its
  `#NormalizedCMIR` projection `cm0_ir`; **`compiled/cm0.json`** = `cue export -e cm0_ir`.

### Findings

**G1 — the generic layer adds only OPTIONAL or HIDDEN fields, so it forces nothing.**
`cue export` emits every concrete regular field, including default-valued ones —
so a single `bool | *false` added to a shared shape would materialize a new key in
every frozen IR. Every generic addition to a shared/aspect shape is therefore
*optional* (`may_*?`, `target_contract?`, `input?`, `output?`, `aspect_id?`) or
*hidden* (`_target_contract`, `_compiled_bound`). Proven: `repository-coherence`,
`structure`, and `legibility` re-export **byte-identical** to the committed
`compiled/*.json` (three empty diffs).

**G2 — the aspect's git-repository target is a HIDDEN field.** `#AspectMethodology:
#LeafMethodology & {…}` should bind `target_contract: {kind: "git_repository"}`, but
a *regular* `target_contract` adds a `target_contract` key to `structure.json` /
`legibility.json` (verified: a concrete field on a definition exports on every
instance). To keep byte-identity, the binding is a **hidden** field
`_target_contract: #TargetContract & {kind: "git_repository"}` — type-checked, never
exported. `aspect_id?` is optional for the same reason (the aspects carry `aspect_id`
on the *receipt*, not at the top level). CM0 — a fresh instance with no byte
baseline — carries `target_contract` as ordinary exported data.

**G3 — `#ChildReceiptEnvelope` is related to `#ReceiptEnvelope` by documentation,
not subtyping.** A clean `#ChildReceiptEnvelope: #ReceiptEnvelope & {…}` would add
`methodology`/`target` keys to the three frozen child receipts (which carry
`aspect_id`/`profile`/`repository_commit` instead). That perturbs instance data, so
per the increment brief `#ChildReceiptEnvelope` is **kept as-is** and the
correspondence recorded here: `#ReceiptEnvelope` is the generic interface;
`#ChildReceiptEnvelope` is its repository specialization, differing only in identity
fields.

**G4 — `#CMSource` is related to the settled types by documentation, not `&`.**
`#CMSource` names the *authored methodology program* — the role `#Methodology`,
`#LeafMethodology`, and `#AspectMethodology` play. Wiring them structurally
(`#Methodology: #CMSource & {…}`) was tried and **reverted**: `cue export` orders
fields by declaration position, so embedding `#CMSource` reordered `requirements` /
`procedure` / `result` ahead of `boundary` and **broke byte-identity** (the values
were identical; the field ORDER changed). So the settled types stay untouched and
their `#CMSource` role is documented; **CM0** — with no byte baseline — is authored
as an explicit `#CMSource & #LeafMethodology`, exercising the source contract where
it costs nothing. (Same principle as G3: byte-identity wins over clean subtyping;
the relation is recorded as a finding.)

**G5 — the CUE export is honestly a `#NormalizedCMIR`, not a `#CompiledCM`.**
`#NormalizedCMIR` is a closed, fully-concrete, content-addressed contract
(`format`·`cm_id`·`cm_version`·`source_digest`·`input_contract`·`procedure`·
`result_contract`·`receipt_contract`) — the normalized JSON a methodology *program*
produces. It is explicitly **not** a normative `#CompiledCM` (the later runtime
descriptor with resolved provider bindings, execution plan, and sandbox policy —
absent here). CM0, which has **no run** in 4A, is the first clean carrier of this
source→IR separation: `compiled/cm0.json` is a methodology program only (no
measurement receipt) and **validates against `#NormalizedCMIR`**
(`cue vet compiled/cm0.json schema.cue -d '#NormalizedCMIR'` → 0). The honesty is
enforced structurally in `#InstrumentSubject`: `normalized_ir` is a required slot
and grounds *language-level* contract integrity, while `compiled` is a non-required
slot and `runtime_binding.status` is `INCOMPLETE` until a CompiledCM is bound. A
subject claiming `runtime_binding.status: "COMPLETE"` with no compiled ref bound
**fails `cue vet`** (`_compiled_bound: false` conflicts `true`) — CM0 cannot
fabricate runtime completeness from a normalized IR (negative probe P5; positive
control P6 passes when a real compiled ref is bound).

**G6 — the typed step / provider algebra, coexisting with `#ProcedureStep`.**
`#ProcedureStep` carries a free-form `action: string` — enough to *describe* an
aspect leaf's six steps, but not an instruction *set* a second executor could bind
and run. CM0 forces the missing algebra: `#StepKind`
(`mechanical`·`semantic_judgment`·`invoke_cm`·`oracle`·`transform`), `#ProviderRef`
(`kind`·`id`·`digest?`), and `#TypedStep` (`id`·`kind`·`provider`·`input`·
`output_contract`·`evidence_contract`·`failure?`). CM0's five subcontracts are
ordinary `#TypedStep` compositions — **not prose**: `contract_integrity` and
`evolution` are `mechanical` tool steps over the normalized IR; `repeatability` is an
`oracle`; `discrimination` is an `invoke_cm` step binding a `#MethodologyRef` with a
MeasurementReceipt-*shaped* `output_contract` (the type itself deferred to #112);
`refusal` is a `semantic_judgment` binding an LLM provider to a digested skill
`#ArtifactRef` with `evidence_contract: {citations_required, disagreement_retained}`.
Crucially `#TypedStep` **coexists** with `#ProcedureStep`: the three settled examples
keep `#ProcedureStep` unchanged, only `#LeafMethodology`-family leaves (CM0) use
`#TypedStep`, and the three IRs stay byte-identical (migration of the settled
examples to typed steps is deferred to #113 slice E). No `#StepKind` value compiles,
admits, or authorizes, so a step of kind `"compile"`/`"authorize"` fails `cue vet`
(negative probe P2).

### The boundary bites (measure-only is enforced, not asserted)

`#Boundary` gains typed authority fields `may_compile?`/`may_admit?`/`may_authorize?`/
`may_repair?`; a measure-only boundary constrains each to `false`. This is the
language-level enforcement of **OPER-AUTH-001** (`spec/tsc-conformance.md`, "CM0
cannot admit itself") and **tsc-oper.md §1.4/§2** ("CM0 measures. It does not
compile, admit, authorize, or decide a boundary action"). Enforcement is proven by
negative probes that all **fail `cue vet`**:

- **P1** — a `#Boundary & {measure_only: true, may_compile: true}` →
  `may_compile: conflicting values false and true`.
- **P2** — a `#TypedStep` of `kind: "compile"` → `3 errors in empty disjunction`
  (not a member of `#StepKind`).
- **P3** — an `#InstrumentAssessment & {emits_admission_verdict: true}` →
  `conflicting values false and true` (an assessment measures; it does not admit).
- **P4** — an `#InstrumentSubject` whose `source.ref` is an embedded object rather
  than an `#ArtifactRef` → `field not allowed` / `null vs struct` (references are
  canonical — AC7; CM0 embeds no child/receipt copies).
- **P5** — a subject claiming `runtime_binding.status: "COMPLETE"` with no compiled
  ref (G5 above).

Positive control **P6** (COMPLETE *with* a bound compiled `#ArtifactRef`) passes,
proving the AC5 guard is live rather than always-failing.

### Closedness note (a small, recorded relaxation)

`#LeafMethodology` is an **open** base (`...`): a leaf family adds its own fields via
`&`, which a closed definition rejects (`field not allowed`). Consequently
`#AspectMethodology`, previously a closed definition, is now open at the methodology
top level. This is a deliberate, minor relaxation — the **load-bearing** closedness
is the S2-corralled *receipt* envelope (`#ChildReceiptEnvelope`), which is
**unchanged**, and the three IRs remain byte-identical. `close()` does not restore
top-level protection here because the open base's `...` defeats it (verified).

### `#ArtifactSlot` — declaring a subject without fabricating a digest

`#InstrumentSubject`'s artifact roles (`source`, `normalized_ir`, `compiled`) are
`#ArtifactSlot`s (`kind`·`required`·`ref: #ArtifactRef | *null`), not bare
`#ArtifactRef`s. Reason: CM0 has **no run**, so it *declares* the subject contract
without a bound target — and a declaration cannot carry a real content-address for a
target it has not measured. A slot declares the role and leaves `ref` unbound
(`null`); a run binds it to an `#ArtifactRef`. The type admits only `#ArtifactRef` or
`null`, so an embedded copy in place of a ref fails `cue vet` (P4) — AC7 holds. The
list roles (`implementation_refs`/`calibrations`/`fixtures`/`lineage`) are
`[...#ArtifactRef]` directly.

### Deferred (recorded, not done in 4A)

- **Run/receipt separation of the three fused examples** — they intentionally fuse a
  CM with a concrete run-0002/0003 receipt (correct for #109). Splitting them into
  `#CMSource` + `#RunRequest` + `#MeasurementReceipt` re-baselines their IRs and is
  **#112 slice 2**; `#RunRequest`/`#MeasurementReceipt` are **not** introduced here.
- **Migration of the settled examples to `#TypedStep`** — **#113 slice E**.
- **Provider/fixture corpus and calibration data** — **#113 slice B / 4B**.
- **`#LeafDerivation` promotion** — CM0 is now the third leaf, but the shared
  `derivation` skeleton is **not** promoted (a later, earned step).
- **Assessment runs / self-application** — **4C / 4D**.
