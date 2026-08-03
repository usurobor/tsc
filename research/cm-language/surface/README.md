# CM surface language — spike (all four CMs: CM0 instrument leaf · Repository Coherence composite · Legibility & Structure aspect leaves)

Issue **#115** (sub of **#114**). Proves the `.cm` → OCaml → normalized-IR loop
end-to-end on the one clean methodology-only target, **CM0**: a compact ML-shaped
`.cm` source compiles, via an isolated OCaml front-end, to JSON **byte-identical**
to the already-approved `research/cm-language/compiled/cm0.json`, validated by
`cue vet` as `#NormalizedCMIR`. **No semantics reopened** — this changes notation,
not meaning.

**Follow-on (full-source faithfulness).** The `.cm` source is now a *lossless*
carrier of the **full** authored `#CMSource`, not just the IR projection: it
carries the content-addressed provider digests, the per-step input/output/evidence
contracts, `target_contract`, `standing_scope`, and the boundary note. One source,
two byte-exact projections:

```
                      ┌─ cmc cm0.cm ──────────→ normalized IR  (== compiled/cm0.json)
cm0.cm ── lex/parse ──┤                         cue vet -d '#NormalizedCMIR'
      (one AST)        └─ cmc --source cm0.cm ─→ full #CMSource (== cue export -e cm0)
                                                 cue vet -d '#CMSource'
```

**Follow-on (composite form).** The surface now spans the **composite** (parent)
CM as well as leaves: `repository_coherence.cm` is the Repository Coherence
`#Methodology` — children registry, `parallel cm.run` composition, invariants,
the precedence `decide`, the seven `RCM-*` requirements — compiling **byte-identical**
to the methodology-only projection `cue export … -e repository_coherence_source`.
See *Composite CM* below.

## Layout

| Path | Role |
|---|---|
| `dune-project` | Its **own** build root — `dune build` in `src/engine/ocaml` never descends here; shares no dependency with the frozen `coh` engine. |
| `lib/cm_surface.ml` | Lexer + recursive-descent parser + lowering + a hand-written JSON serializer that reproduces `cue export`'s exact bytes. **Stdlib only** (no yojson/menhir/ppx). |
| `bin/main.ml` | `cmc` CLI: `cmc <file.cm>` → IR; `cmc --source <file.cm>` → full `#CMSource`. |
| `cm0.cm` | CM0 (leaf/instrument) in the compact surface (full-source faithful). |
| `cm0_no_admit.cm` | Negative probe: drops `admit` from `forbid`. |
| `repository_coherence.cm` | Repository Coherence (composite/parent) in the compact surface. |
| `repository_coherence_no_averaging.cm` | Composite negative probe: drops `averaging` from `forbid`. |
| `legibility.cm` | Repository Legibility (aspect/repository leaf, free-form procedure) in the compact surface. |
| `legibility_no_measure_only.cm` | Aspect-leaf negative probe: drops `measure_only` from the boundary. |
| `structure.cm` | Repository Structure (aspect/repository leaf, free-form + `adr_clause` requirements) in the compact surface. |
| `structure_no_measure_only.cm` | Aspect-leaf negative probe: drops `measure_only` from the boundary. |

## Build & run

```
$ dune build                                  # in research/cm-language/surface/
$ dune exec bin/main.exe -- cm0.cm            # → normalized IR (compiled/cm0.json)
$ dune exec bin/main.exe -- --source cm0.cm   # → full #CMSource (cue export -e cm0)
```

## Gate results

| Gate | Command | Result |
|---|---|---|
| **AC1** build | `dune build` (in `surface/`) | exit **0** |
| AC1 engine unaffected | `dune build` (in `src/engine/ocaml`) | exit 1 — **pre-existing**, only `otoml`/`ezcurl` missing in this sandbox; **0** references to `surface/`. Separate build roots (no shared/root `dune-project`), so my work cannot perturb the engine build outcome. |
| AC1 compile | `dune exec bin/main.exe -- cm0.cm` | exit **0** |
| **AC2** byte-identity | `diff <(cmc cm0.cm) ../compiled/cm0.json` | **empty**; `cmp` identical. **CUE-exact** — this reproduces `cue export`'s own bytes (4-space indent, insertion-order keys, `": "` separators, trailing `}\n`), **not** a re-serialization of both sides. No documented deviation on serialization. |
| **AC2-full** full-source byte-identity | `diff <(cmc --source cm0.cm) <(cue export ../schema.cue ../examples/cm0/cm.cue --out json -e cm0)` | **empty**; `cmp` identical (7726 bytes, digests included). CUE-exact. |
| **AC3** CUE oracle (IR) | `cue vet <ir.json> ../schema.cue -d '#NormalizedCMIR'` | exit **0** |
| AC3 CUE oracle (source) | `cue vet <source.json> ../schema.cue -d '#CMSource'` | exit **0** |
| **Composite byte-identity** | `diff <(cmc --source repository_coherence.cm) <(cue export ../schema.cue ../examples/repository-coherence/cm.cue --out json -e repository_coherence_source)` | **empty** (CUE-exact). |
| Composite oracle | `cue vet <cmc-output ∪ frozen receipt> ../schema.cue -d '#Methodology'` | exit **0** (see *Composite CM → oracle*; bare `-d '#Methodology'` on the receipt-less projection is incomplete **identically** for `cmc` and `cue export`). |
| Composite negative probe | `cmc --source repository_coherence_no_averaging.cm` | **rejected**, exit **2**. |
| **Legibility byte-identity** | `diff <(cmc --source legibility.cm) <(cue export ../schema.cue ../examples/legibility/cm.cue --out json -e legibility_source)` | **empty** (CUE-exact). |
| Legibility oracle | `cue vet <cmc-output ∪ frozen receipt> ../schema.cue -d '#AspectMethodology'` | exit **0** (bare `-d` on the receipt-less projection is incomplete **identically** for `cmc` and `cue export` — same wrinkle as the composite). |
| Legibility negative probe | `cmc legibility_no_measure_only.cm` | **rejected**, exit **2**. |
| **Structure byte-identity** | `diff <(cmc --source structure.cm) <(cue export ../schema.cue ../examples/structure/cm.cue --out json -e structure_source)` | **empty** (CUE-exact). |
| Structure oracle | `cue vet <cmc-output ∪ frozen receipt> ../schema.cue -d '#AspectMethodology'` | exit **0** (bare `-d` on the receipt-less projection incomplete **identically** for `cmc` and `cue export`). |
| Structure negative probe | `cmc structure_no_measure_only.cm` | **rejected**, exit **2**. |
| CM0 no-regression | `cmc cm0.cm == compiled/cm0.json`; `cmc --source cm0.cm == cue export -e cm0` | both byte-identical. |
| Composite no-regression | `cmc --source repository_coherence.cm == cue export -e repository_coherence_source` | byte-identical. |
| Legibility no-regression | `cmc --source legibility.cm == cue export -e legibility_source` | byte-identical. |
| **AC4** no semantics reopened | `git diff main -- schema.cue compiled` empty; `examples/` changed only by the additive `repository_coherence_source` expr (full `-e repository_coherence` still byte-identical) | holds. |
| Negative probe (CM0) | `cmc cm0_no_admit.cm` (and `--source`) | **rejected**, exit **2** (see below). |

## Surface → IR mapping (how the notation collapses)

| `.cm` construct | `compiled/cm0.json` field |
|---|---|
| `cm cm0 v0.1` | `cm_id: "tsc." ^ name` (`tsc.cm0`), `cm_version` (`v` stripped) |
| `(instrument: Methodology)` | `input_contract.kind = "instrument_subject"` (from the subject name `instrument`; `Methodology` documents the target, which the IR does not carry) |
| `-> InstrumentAssessment` | `result_contract.kind` **and** `receipt_contract.kind` = `"instrument_assessment"` |
| `source_digest sha256:…` | `source_digest` (carried literally — see below) |
| `require <role> : <kind> [optional]` | one `input_contract.required_artifacts[*]` `{role,kind,required}` |
| `lists a, b, …` | `input_contract.artifact_lists` |
| `binding INCOMPLETE` | `input_contract.runtime_binding` **and** `result_contract.runtime_binding` |
| `let!` / `and! id = kind via pk pid on FAIL` | one `procedure.steps[*]` `{id,kind,provider_kind,failure}`; the step ids become `result_contract.subcontracts` |
| `retain …` (9 dimensions) | `receipt_contract.reports` |
| `decide from assessments deferred "…"` | `result_contract.subcontracts` (from the step ids) + `derivation` (the quoted string) + `emits.*: false` |
| `forbid compile, admit, authorize, repair, self_authorize` | `receipt_contract.measure_only: true` + `result_contract.emits.{admission_verdict,authorization,boundary_decision}: false` |

### Two honest design points

1. **`source_digest` is carried literally.** In the IR it is the content address
   of the authored source (the sha256 of CUE's canonical `-e cm0` export). This
   spike targets the *approved* digest, so the surface declares it verbatim rather
   than recomputing CUE's hash from a different (`.cm`) source form. It is
   information the IR encodes, so the surface carries it — losslessly.

2. **The surface carries the full source; the IR is its projection.** Each step's
   `via <pk> <provider_id> @<digest>` and its `{ reads / output / evidence … }`
   block carry the concrete provider, its content-addressed digest, and its typed
   contracts. The default (`cmc`) projects these to the IR shape (`provider_kind`
   only, no per-step contracts) — exactly as CUE's `cm0_ir` comprehension projects
   the rich `cm0` source. `cmc --source` re-emits the **full** source byte-identical
   to `cue export … -e cm0` (7726 bytes). Nothing the source encodes is dropped by
   the surface — the earlier spike's lossiness (digests, per-step contracts) is
   closed. β's flag addressed: the content-addressing #112 made canonical now
   survives the round-trip through `.cm`.

## Full-source surface syntax (what the follow-on added)

Small, uniform additions — the grammar stays < 15 constructs:

- `question "…"`, `target <kind> "…"`, `standing "…"`, `boundary_note "…"` — the
  four source-level string fields the IR drops.
- `@sha256:<hex>` — a content-address digest, on a provider (`via tool foo
  @sha256:ic0`), a child-CM `methodology` ref, or a `skill` ref.
- an optional per-step `{ … }` block with `reads a, b`, `protocol x`,
  `methodology <id> @<digest>`, `skill <id> <kind> @<digest> v<ver>`,
  `output k: v, …`, `evidence k: v, …` (value `true`/`false` → bool, else string).

The `--source` emitter reconstructs the constant scaffolding CUE materializes
(`ref: null`, empty artifact lists, `contract_integrity:
"assessable_from_normalized_ir"`, the `output.subject` duplication of `input`, and
the fixed `emits_*`/`may_*` = false of a measure-only CM) so the surface need not
restate it.

## Composite CM — Repository Coherence (`#Methodology`)

The surface spans the **composite** (parent) form, not just leaves.
`repository_coherence.cm` compiles **byte-identical** to the methodology-only
projection of the parent — `repository_coherence` **minus its concrete run**
(`receipt`):

```
$ dune exec bin/main.exe -- --source repository_coherence.cm
# == cue export ../schema.cue ../examples/repository-coherence/cm.cue \
#      --out json -e repository_coherence_source
```

That projection expression is an **additive** one-liner added to
`examples/repository-coherence/cm.cue` (`repository_coherence_source: {for k, v in
repository_coherence if k != "receipt" {(k): v}}`); the original
`repository_coherence` expr is untouched and its full IR
(`compiled/repository-coherence.json`) stays byte-identical.

Composite grammar added (small, reuses the leaf lexer/JSON machinery):

| `.cm` construct | `#Methodology` field |
|---|---|
| `cm repository-coherence v0.1 (repo, aspects) -> CompositeReceipt` | `id` (verbatim), `version`, and the constant `input` `{repository_snapshot, selected_aspects}` |
| `child <name> from <src> [implemented] [selected]` | one `children[name]` `{aspect_id, source, implemented, selected}` (flag present ⇒ true) |
| `let! receipts = parallel cm.run over aspects` | the composition body — captured structurally by `children` + `result`, so **projected out** of the methodology IR (a composite has no `procedure`) |
| `require same_snapshot` / `retain child_receipts` / `forbid averaging` | the `invariants` block `{same_snapshot, retain_child_receipts, allow_scalar_aggregation}` |
| `statuses …` + `decide by precedence \| RC -> STATUS` | `result` `{statuses, precedence (clause order), mapping (RC→status)}` |
| `requirement RCM-… "…"` (×7) | `requirements[*]` `{id, text}` |
| `disowns "…", …` | `does_not_own` |
| `forbid …, repair, admit, authorize` | `boundary.measure_only: true` |

The emitter reconstructs the composite's constant scaffolding from schema defaults —
`manifestation`, `atlas.note`, `boundary.note`, `continuation_baseline`, and the
`result_class_definitions` block — exactly as CM0's `--source` reconstructs its
constants. The composite has no separate normalized IR in this increment (that is
#112 slice 2), so both `cmc` and `cmc --source` emit this one methodology-only
projection.

### The `#Methodology` oracle, honestly

`#Methodology` **mandates a concrete `receipt`** (repository_commit,
composite_status, continuation.status). The methodology-only projection omits it, so
`cue vet <projection> -d '#Methodology'` reports those three as incomplete —
**identically for `cmc`'s output and for `cue export … -e repository_coherence_source`
itself** (verified). That is a property of the *projection vs. the full contract*,
not a defect in the emitter. The achievable, meaningful oracle: the projection
**unified with the frozen `receipt`** validates as a complete `#Methodology`
(`cue vet <cmc-output ∪ receipt> -d '#Methodology'` → **0**) — i.e. `cmc`'s output is
a valid `#Methodology` missing only its run. A `#MethodologySource` definition
(methodology-without-receipt) is the clean home for a direct oracle and is left to
#112 slice 2, which introduces the source/run separation at the schema level.

## Aspect leaf CM — Legibility (`#AspectMethodology`, free-form procedure)

The surface now spans **all three CM forms**: the CM0 instrument leaf (typed provider
steps), the Repository Coherence composite, and now an **aspect/repository leaf** with
a **free-form** procedure. `legibility.cm` compiles **byte-identical** to the
methodology-only projection `legibility` **minus its concrete run** (`receipt`):

```
$ dune exec bin/main.exe -- --source legibility.cm
# == cue export ../schema.cue ../examples/legibility/cm.cue --out json -e legibility_source
```

Same additive one-liner (`legibility_source: {for k, v in legibility if k != "receipt"
{(k): v}}`) added to `examples/legibility/cm.cue`; the original `legibility` expr is
untouched and its full IR stays byte-identical.

Free-form-procedure grammar added (the third CM form; reuses the leaf/composite lexer
and JSON machinery):

| `.cm` construct | `#AspectMethodology` field |
|---|---|
| `cm tsc.repository-coherence.legibility v0.2 (…) -> AspectReceipt` | `id` (verbatim), `version`; dispatched as an aspect leaf on the output type |
| `profile "…"` | `profile` |
| `statuses …` + `status_mapping \| STATUS -> CLASS` | `statuses` + `status_mapping` (the `\| K -> V` ladder, five entries) |
| `input <name>: "<role>"` (×4) | `procedure.inputs[*]` `{name, role}` |
| `step <n>: "<action>" checks [REPO-…]` (×7) | `procedure.steps[*]` `{n (int), action, checks}` — free-form `#ProcedureStep`, not CM0's typed step |
| `decide \| CLASS when "<cond>" … otherwise PASS` | `procedure.result` `{clauses [{when, class}], otherwise}` — a result-rule ladder (distinct from the composite's precedence ladder) |
| `requirement REPO-… "<text>" class <c> severity <s>` (×11) | `requirements[*]` `{id, text, class, severity}` (`class` accepts `"mechanical + semantic"` as a quoted value) |
| `disowns "…", …` | `does_not_own` |
| `boundary measure_only note "<…>"` | `boundary` `{measure_only: true, note}` |

New tokens: `[` `]` (bracket check-lists) and JSON integers (`step.n`). The emitter
reconstructs the schema-default constants — `result_class_definitions` and
`retired_requirements: []` (#AspectMethodology's default) — as before. Both `cmc` and
`cmc --source` emit this one methodology-only projection.

### The `#AspectMethodology` oracle, honestly

Identical wrinkle to the composite: `#AspectMethodology` **mandates a concrete
`receipt`** (the `#ChildReceiptEnvelope` run), which the methodology-only projection
omits — so `cue vet <projection> -d '#AspectMethodology'` reports the receipt fields
incomplete, **identically for `cmc`'s output and for `cue export … -e
legibility_source` itself** (verified). The achievable oracle: the projection
**unified with the frozen `receipt`** validates as a complete `#AspectMethodology`
(`cue vet <cmc-output ∪ receipt> -d '#AspectMethodology'` → **0**). Same
`#MethodologySource` deferral to #112 slice 2.

### Structure — a second aspect leaf, ~all reuse

`structure.cm` reuses the Legibility aspect-leaf grammar wholesale (profile, statuses,
`status_mapping` ladder, typed inputs, free-form `step`s, the `decide` result ladder,
`disowns`, `boundary measure_only note`), compiling **byte-identical** to `structure`
minus its `receipt`. Two small deltas, both handled additively:

- **`adr_clause` on requirements.** Structure's 15 `STRUCT-*` requirements each trace to
  a repository-planes ADR clause. Surface: `requirement STRUCT-… "<text>" class <c>
  severity <s> adr "<clause>"` — an **optional** trailing `adr "…"`. It is emitted
  between `text` and `class` (CUE field order). Several clauses carry embedded quotes
  (e.g. `"…\"α/β/γ … never a filing taxonomy\"…"`); the surface escapes them `\"`, and
  the serializer re-escapes on output — a clean round-trip.
- **Authored `retired_requirements`.** Structure retires `STRUCT-LIFECYCLE-001`. Surface:
  `retired STRUCT-LIFECYCLE-001 "<note>"`. Because it is *authored* (not the schema
  default `[]` that Legibility leaves), CUE's projection comprehension emits it in
  **source position** (after `requirements`, before `does_not_own`) — whereas
  Legibility's default `[]` is appended *after* `result_class_definitions`. The emitter
  reproduces both orderings: authored ⇒ in place; default ⇒ appended last. This is the
  one place the "instance-authored fields first, schema defaults appended" rule of the
  projection is visible as an ordering difference between two otherwise-identical leaves.

Same `#AspectMethodology` receipt wrinkle and merged-receipt oracle as Legibility.

### Overlapping invariant checks (compiler + CUE — #114 AC4)

- **Compiler-enforced:** `forbid` completeness (all five authorities), the `let!`
  then `and!` binder shape, presence of every required declaration.
- **CUE-enforced:** the IR is `close({…})` (a stray/typo'd top-level key is
  rejected), `format` is pinned, `procedure.steps` is a list, the four contract
  sub-objects are present. The two overlap on structural shape and are
  complementary on the boundary (see the probe).

## Negative probe — the boundary is load-bearing

`cm0_no_admit.cm` drops `admit` from `forbid`. **It is rejected at compile time:**

```
$ dune exec bin/main.exe -- cm0_no_admit.cm ; echo $?
cmc: cm cm0: measure-only boundary must `forbid` all of [compile, admit,
authorize, repair, self_authorize]; missing "admit". The boundary is
load-bearing (OPER-AUTH-001: CM0 cannot admit itself).
2
```

**Why parser-rejection rather than a failing `cue vet`** (the sanctioned OR
branch): `#NormalizedCMIR` leaves `result_contract` and `receipt_contract` open
(`{…}`), so the measure-only invariant (`emits.*: false`, `measure_only: true`) is
**not** re-checked at the IR level — it lives in `#Boundary` / `#InstrumentAssessment`
at the *source* layer. The `.cm` surface makes that boundary **structurally
mandatory**: a CM0-family CM that does not forbid the full authority set never
lowers to an IR at all. The boundary bites at the surface, which is where the
authored program declares it.

The **composite** carries the same discipline. `repository_coherence_no_averaging.cm`
drops `averaging` from `forbid` and is rejected at compile time (exit 2):

```
cmc: cm repository-coherence: composite boundary must `forbid` all of [averaging,
repair, admit, authorize]; missing "averaging". The boundary is load-bearing
(RCM-NO-AGGREGATE-001: no scalar aggregation; RCM-BOUNDARY-001: measure only).
```

`cue vet` cannot catch this: `#Methodology` leaves `invariants.allow_scalar_aggregation`
an unconstrained `bool`, so — as with CM0 — the no-aggregate boundary must bite at
the surface.

The **aspect leaf** carries it too. `legibility_no_measure_only.cm` drops
`measure_only` from the boundary (`boundary note "…"` instead of `boundary
measure_only note "…"`) and is rejected at compile time (exit 2): the surface makes
`boundary measure_only note "…"` structurally mandatory for every aspect leaf
(RCM-BOUNDARY-001 — a run that edited files while observing them would destroy its own
evidence). General over the aspect-leaf family, not overfit to Legibility —
`structure_no_measure_only.cm` is rejected identically (exit 2).

## Clarity judgment (AC5): `.cm` vs the CUE source for CM0

**Verdict: the `.cm` surface is clearer than `examples/cm0/cm.cue` for CM0 — by a
wide margin on the authoring surface, with two honest caveats.**

Concrete, measured on CM0:

- **Size / signal.** `cm0.cm` is ~30 non-comment lines; `cm.cue` is ~135 lines,
  most of it record scaffolding (`#TypedStep & {provider: {kind:…, id:…, digest:…},
  input:{reads:[…]}, output_contract:{…}, evidence_contract:{…}}` per step, ×5).
  The five subcontracts read as five aligned `let!`/`and!` lines instead of five
  nested records.

- **The boundary is a first-class statement, not a struct with a proof obligation.**
  `.cm` says `forbid compile, admit, authorize, repair, self_authorize` on one
  line. The CUE encodes the same fact as a `boundary: {measure_only:true;
  may_compile:false; …}` record *plus* a conditional `if measure_only {…}` block in
  the schema that makes the conflict bite — powerful, but you must read two files to
  see that "CM0 cannot admit itself" is enforced. The surface makes the intent the
  syntax.

- **The measure/authority split is legible at a glance.** `let!`/`and!` mark the
  effectful provider invocations; `decide`/`forbid` mark derivation and boundary.
  In the CUE these are all just fields of one big struct, distinguished only by
  reading the field names and the schema's comments.

- **The source→IR projection is visible in both, honestly.** CUE shows it as `cm0`
  (rich) vs `cm0_ir` (the `for s in … {id, kind, provider_kind, failure}`
  comprehension). `.cm` shows it as: surface carries `via tool ir_contract_checker`,
  IR keeps `provider_kind` only. The surface's version is the projection *rule*
  written once in the compiler, not spelled out per-CM.

**Caveats (where CUE is genuinely ahead, not to be papered over):**

1. **CUE is executable specification; `.cm` needs a compiler.** `cue vet` checks the
   IR against the model with no code we wrote; the `.cm` front-end is code that can
   have bugs. This is exactly why #114 keeps CUE as the *IR contract and independent
   oracle* — the two-check design (compiler emits, CUE validates) is the point, and
   this spike exercises it (AC3).

2. **CUE enforces cross-field invariants the surface currently pushes into the
   compiler.** The `_compiled_bound` honesty guard and the `status_mapping[status]`
   self-unification are constraints CUE checks structurally; the `.cm` surface would
   need typechecker rules (a later increment) to match that reach. For CM0 the
   relevant boundary invariant *is* enforced (structurally mandatory `forbid`), but
   the general claim "the surface typechecks everything CUE does" is not yet true and
   is not claimed here.

**Net:** for **authoring** CM0, `.cm` is clearly better — it reads as the
methodology it always was, and the record/envelope/precedence machinery collapses
into the program it was encoding. CUE remains the right **IR contract + validator**.
That is precisely the #114 split (`.cm` = surface, CUE = IR oracle), and CM0 is the
first end-to-end proof of it.

**Composite (Repository Coherence):** the gain is if anything larger. The 155-line
CUE parent — `#ResultComposition` precedence/mapping records, the `#AspectSource`
children map, seven requirement structs — becomes a ~30-line program whose
composition (`parallel cm.run over aspects`), derivation (`decide by precedence`),
and boundary (`forbid averaging, repair, admit, authorize`) are each one legible
statement. The precedence walk that a fresh reader must reconstruct from
`result.precedence` + `result.mapping` in the JSON is written as the `decide` ladder
directly. Same two caveats as CM0 apply (CUE stays the executable oracle; the
surface's typechecker is thinner than CUE's cross-field constraints — and here the
composite has no receipt-less `#Methodology` oracle yet, deferred to #112 slice 2).

**Aspect leaf (Legibility):** the free-form procedure reads especially well — seven
`step n: "…" checks […]` lines and a `decide | CLASS when "…" … otherwise PASS` ladder
are exactly the executable core, where the CUE nests them under
`procedure.steps`/`procedure.result.clauses` records. The `status_mapping` and
`class`/`severity`-annotated requirements carry one-to-one. The honest limit is
sharper here than for CM0: Legibility's *run* (the `#LegibilityReceipt` with its
CUE-computed `derivation` — the two-executor result check that makes
`derived_result_class` conflict with a wrong `result_class`) is exactly the part the
methodology-only projection omits, and is where CUE's executable-constraint power is
most load-bearing. The `.cm` surface authors the *program*; CUE still owns the
*derivation check*. That is the intended #114 split, now demonstrated across all three
CM forms (instrument leaf · composite · aspect leaf).

**All four target CMs (#114) now compile from `.cm` byte-identical to their approved
IR:** CM0 (instrument leaf — normalized IR *and* full `#CMSource`), Repository Coherence
(composite `#Methodology`), and Legibility + Structure (aspect `#AspectMethodology`
leaves). Structure is the closing proof that the aspect-leaf grammar generalizes: a
second, ADR-grounded leaf reuses it wholesale, with only an optional `adr_clause` and an
authored `retired` requirement as deltas — no new machinery. The judgment holds across
the set: `.cm` is the clearer authoring surface, CUE remains the IR contract and
independent oracle, and the source→run separation (the receipt-less `#MethodologySource`
oracle) is the one clean follow-up, deferred to #112 slice 2.
