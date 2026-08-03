# The `.cm` surface language — reference

The `.cm` language is the **external authoring surface** for the TSC CM
(Coherence Methodology) model: a small, restricted, ML-shaped language that an
isolated OCaml front-end (`surface/lib/cm_surface.ml`) compiles to the normalized
JSON IR. **CUE** (`schema.cue`) is the IR contract and independent validator.

Two languages, two jobs, one slogan:

> **CUE proves the methodology is a valid program; CM0 tests whether it's a valid
> instrument.**

This document is a **reference to the compiler that exists today**. Every
construct below is implemented in `cm_surface.ml`; the accuracy statement at the
end pins each to its parser function. Where something is not yet built it is
marked **FUTURE** with its issue. It is a companion to `README.md` (the model
overview) and `surface/README.md` (the surface→IR mapping and gate results), and
sits under issue **#114** (the authoring-guide direction, `< 10` core constructs,
`coh cm` toolchain, no-legacy/V4). It is not a second spec — the spec is
`schema.cue` and the four worked `.cm` sources.

The pipeline is straight-line, stdlib-only, no provider runtime:

```
.cm source  --lex-->  tokens  --parse-->  AST  --lower-->  normalized JSON IR
                                                             │
                                                             └─ cue vet -d '#…'  (independent oracle)
```

---

## 1. What the language is

- **External and restricted.** A `.cm` program declares a *finite* methodology:
  a fixed header, a bounded set of declarations, only the operations the grammar
  names. There are no user-defined functions, no loops, no imports — the workflow
  is finite by construction.
- **ML-shaped.** F#-style effectful binders (`let!` / `and!`) mark the provider
  invocations; ordinary declarations carry the contract. `->` in the header is
  the return arrow.
- **Measure-only at the boundary.** Every CM must declare the authorities it does
  **not** hold (`forbid …`). Dropping a required `forbid` is a compile error, not
  a lint (§5).
- **Lossless.** One `.cm` source carries the **full** authored `#CMSource`, not
  just the IR projection: content-addressed provider digests, per-step
  input/output/evidence contracts, the target contract, standing scope, and the
  boundary note. The default projection drops these to produce the IR; `--source`
  re-emits them all.
- **The compiler is code; CUE is the oracle.** The front-end can have bugs, which
  is exactly why #114 keeps CUE as an independent check: the compiler emits, CUE
  validates the emitted IR against the model. The `.cm` surface makes the
  *boundary* structurally mandatory (a CM that does not forbid the full authority
  set never lowers at all); CUE re-checks the structural shape of the result.

**Toolchain.** Today the front-end is `cmc` (`surface/bin/main.ml`): `cmc
<file.cm>` emits the IR, `cmc --source <file.cm>` emits the full `#CMSource`;
validation is `cue vet … -d '#NormalizedCMIR'` / `-d '#CMSource'`. The intended
unified frontend is **`coh cm`** (#114) — **FUTURE**; today it is `cmc` + `cue`.

---

## 2. Program forms

The compiler dispatches on **the header's output type** into exactly three forms
(`Parse.parse`). The header grammar is uniform:

```
cm <name> v<ver> ( <params> ) -> <ReceiptType> { … }
```

- `<name>` is carried verbatim into the IR `id`/`cm_id` (`tsc.` prefix on the
  leaf IR); `v<ver>` has its leading `v` stripped (`v0.1` → `0.1`).
- `<params>` is a comma-separated list of `name` or `name: Type`.
- `<ReceiptType>` selects the form:

| Output type | Form | Projection type | Example |
|---|---|---|---|
| `-> InstrumentAssessment` | **leaf** (reflective / instrument) | `#NormalizedCMIR` + `#CMSource` | `cm0.cm` |
| `-> AspectReceipt` | **leaf** (aspect / repository) | `#AspectMethodology` | `legibility.cm`, `structure.cm` |
| `-> CompositeReceipt` | **composite** (parent) | `#Methodology` | `repository_coherence.cm` |

Any other output type is a compile error. The leaf `InstrumentAssessment` form is
the only one that has two distinct byte-exact projections (IR *and* full source);
the aspect leaf and composite each have **one** methodology-only projection today
— both `cmc` and `cmc --source` emit it, because their run/receipt IR is
**FUTURE** (#112 slice 2).

---

## 3. The constructs

Lexer basics: `#` begins a line comment; strings are `"double-quoted"` (with
`\n \t \r \" \\` escapes); atoms run over `[A-Za-z0-9_./!-]` (so `let!`,
`refusal-rubric`, `./legibility`, `cm.run` are single atoms); punctuation tokens
are `( ) { } [ ] : , = @ | ->`. High bytes (UTF-8 `§`, `δ`, em-dash) pass through
raw.

### 3.1 Instrument leaf (`-> InstrumentAssessment`, CM0)

The reflective instrument leaf uses **typed, provider-bound steps**. Body
declarations (each maps to an IR field — see `surface/README.md` for the full
table):

| Construct | Meaning / IR effect |
|---|---|
| `question "…"` | governing question (`#CMSource.question`; dropped from IR) |
| `target <kind> "<desc>"` | accepted-target contract (`target_contract`) |
| `source_digest sha256:<hex>` | content address of the authored source (IR `source_digest`; carried literally) |
| `require <role> : <kind> [optional]` | one `input_contract.required_artifacts[*]` `{role, kind, required}` |
| `lists <a>, <b>, …` | `input_contract.artifact_lists` |
| `binding <CLASS>` | `runtime_binding` (input + result contracts) |
| `standing "…"` | declared standing scope (source only) |
| `retain <a>, <b>, …` | `receipt_contract.reports` (the measure-only dimensions) |
| `decide from assessments deferred "<note>"` | `result_contract.derivation`; `emits.*: false` |
| `boundary_note "…"` | the source-level boundary note |
| `forbid <authorities>` | the measure-only boundary (§5) |

**Typed steps** are the centrepiece. The first is `let!`, every subsequent one
`and!` (F#-style: `let!` binds the first effect, `and!` adds independent parallel
ones — enforced, §3.5):

```
let! contract_integrity = mechanical via tool ir_contract_checker @sha256:ic0 on FAILED {
  reads    subject.normalized_ir, subject.source
  output   parts_present: bool, relations_consistent: bool, scope: language_level
  evidence ir_field_citations_required: true
}
```

Step header: `<id> = <kind> via <provider_kind> <provider_id> @<digest> on <FAIL>`
— `<kind>` is the `#StepKind` (`mechanical`, `oracle`, `invoke_cm`,
`semantic_judgment`, …), `via <provider_kind> <provider_id>` names the provider,
`@<digest>` is its content address, `on <FAIL>` is the `#ResultClass` a provider
failure maps to. The optional `{ … }` block carries, in any order:

- `reads <a>, <b>` — input surfaces;
- `protocol <x>` — a named protocol;
- `methodology <id> @<digest>` — a child-CM methodology ref (content-addressed);
- `skill <id> <kind> @<digest> v<ver>` — a digested skill ref;
- `output <k>: <v>, …` and `evidence <k>: <v>, …` — typed contracts (`true`/`false`
  → bool, any other bareword → string).

The default projection keeps only `{id, kind, provider_kind, failure}` per step
(the IR shape); `--source` emits the full provider/digest/contract records. The
step ids become `result_contract.subcontracts`.

### 3.2 Aspect leaf (`-> AspectReceipt`, Legibility / Structure)

The aspect/repository leaf uses a **free-form procedure** instead of typed steps:

| Construct | Meaning / IR effect |
|---|---|
| `question "…"` / `profile "…"` | `question`, `profile` |
| `statuses <A>, <B>, …` | the leaf's own status vocabulary |
| `status_mapping \| <STATUS> -> <CLASS>` (ladder) | `status_mapping` (each status → a `#ResultClass`) |
| `input <name>: "<role>"` | one `procedure.inputs[*]` `{name, role}` |
| `step <n>: "<action>" checks [<ID>, …]` | one `procedure.steps[*]` `{n (int), action, checks}` |
| `decide \| <CLASS> when "<cond>" … otherwise <CLASS>` | the leaf **result-clause ladder** → `procedure.result` `{clauses [{when, class}], otherwise}` |
| `requirement <ID> "<text>" class <c> severity <s> [adr "<clause>"]` | one `requirements[*]`; `adr "…"` is optional (Structure carries it, Legibility does not) |
| `retired <ID> "<note>"` | one `retired_requirements[*]` `{id, note}` (Structure) |
| `disowns "…", "…", …` | `does_not_own` |
| `boundary measure_only note "<…>"` | `boundary` `{measure_only: true, note}` (§5) |

`class` and `severity` accept a bareword *or* a quoted string (Legibility's
`class "mechanical + semantic"`). The `decide` ladder is the leaf's own
derivation: clauses are authored highest-precedence-first
(FAILED > INCOMPLETE > DEFECT), with `otherwise` the PASS else-arm — see §4 for
which of that ordering the compiler enforces.

A field-order subtlety the emitter reproduces: when `retired_requirements` is
**authored** (Structure) it sits in source position (after `requirements`); when
it is the schema default `[]` (Legibility) it is appended last. This mirrors
CUE's projection comprehension (instance-authored fields first, schema defaults
appended).

### 3.3 Composite (`-> CompositeReceipt`, Repository Coherence)

The parent composes child aspect receipts on a shared snapshot:

| Construct | Meaning / IR effect |
|---|---|
| `question "…"` | `question` |
| `child <name> from <src> [implemented] [selected]` | one `children[name]` `{aspect_id, source, implemented, selected}` (a flag present ⇒ `true`) |
| `let! <b> = parallel cm.run over aspects` | the composition body — parsed for fidelity, projected **out** of the methodology IR (captured structurally by `children` + `result`) |
| `require same_snapshot` | `invariants.same_snapshot` (mandatory) |
| `retain child_receipts` | `invariants.retain_child_receipts` (mandatory) |
| `statuses <A>, <B>, …` | the parent's status vocabulary |
| `decide by precedence \| <RC> -> <STATUS>` (ladder) | the **precedence ladder** → `result` `{precedence (clause order), mapping (RC→status)}` |
| `requirement <ID> "<text>"` | one `requirements[*]` `{id, text}` (no class/severity here) |
| `disowns "…", …` | `does_not_own` |
| `forbid <authorities>` | the measure-only + no-averaging boundary (§5) |

The composite **precedence ladder** (`decide by precedence | RC -> STATUS`) is
distinct from the leaf **result-clause ladder** (`decide | CLASS when "…"`): the
former maps each child `#ResultClass`, highest-first, to a parent status; the
latter guards over the leaf's own procedure output. The step-6 derivation is thus
carried as *data* (`result.precedence` + `result.mapping`) — a fresh reader walks
it from the JSON alone.

The emitter reconstructs the composite's constant scaffolding from schema defaults
(`manifestation`, `atlas.note`, `boundary.note`, `continuation_baseline`, the
`result_class_definitions` block), exactly as the leaf `--source` reconstructs its
constants — the surface need not restate them.

### 3.4 Content addresses

`@sha256:<hex>` is the digest form on providers, `methodology`, and `skill` refs
(the `@` and `:` are separate tokens; it lowers to the string `"sha256:<hex>"`).
`source_digest sha256:<hex>` is the bare form (no `@`). Content-addressing is what
makes the round-trip through `.cm` lossless — β's canonical `#112` digests survive
it.

### 3.5 Compiler-enforced structure (beyond the grammar)

The parser accepts the shape; the lowering *validates* invariants and rejects on
violation (exit 2):

- **Leaf:** the `forbid` set must be **complete and exactly** the five authorities
  `[compile, admit, authorize, repair, self_authorize]` — a missing one is
  rejected (§5), an unknown one is rejected. The first step must be `let!`, every
  later step `and!`. At least one step must exist, and all required declarations
  must be present.
- **Composite:** `forbid` must be exactly `[averaging, repair, admit, authorize]`;
  `require same_snapshot`, `retain child_receipts`, a non-empty `child` registry,
  and non-empty `decide by precedence` clauses are all mandatory.
- **Aspect leaf:** `boundary measure_only note "…"` is mandatory (dropping
  `measure_only` is rejected); `statuses`, `status_mapping`, and at least one
  `step` are required.

Note that value-level enum checks (that a step's `on <FAIL>` or a
`status_mapping` value is one of the four `#ResultClass`es) are **not** done by
the compiler — they are barewords to it. CUE enforces the enum at vet time. This
is the intended split: the surface enforces *boundary completeness and binder
shape*; CUE enforces *value domains and IR shape*.

---

## 4. Result classes & refusal

The four-value `#ResultClass` interface (`schema.cue`) is the common currency:

```
PASS  |  DEFECT  |  INCOMPLETE  |  FAILED
```

with the precedence **FAILED > INCOMPLETE > DEFECT > PASS** ("could not run" beats
"ran but couldn't conclude" beats "ran and found a defect" beats "clean"). Their
definitions are carried in every methodology-only projection as the constant
`result_class_definitions` block, reconstructed by the emitter.

- A **leaf** derives its class from the `decide` ladder over its own procedure
  output; the clauses are authored FAILED-first with `otherwise PASS`. The
  compiler records the clause order verbatim — it does **not** itself re-sort or
  verify the precedence; the ordering is an authoring convention that CUE's
  computed `derivation` checks at the run layer (**FUTURE**, #112 slice 2). The
  leaf's five-value `status` vocabulary maps onto the four classes via
  `status_mapping`.
- A **composite** composes children by walking `result.precedence` highest-first;
  the first child `result_class` present maps, via `result.mapping`, to the parent
  status.

**Refusal is first-class.** `INCOMPLETE` (ran but underdetermined) and `FAILED`
(could not execute) are ordinary outcomes, not errors — a bounded single-check
refusal is honest incompleteness of one check that does *not* flip the categorical
status, which the worked leaves encode as typed data (`legibility.cm` step 6, the
`INCOMPLETE` clause).

---

## 5. The authority boundary

`forbid` is the language-level face of the measure-only boundary. It is
**structurally mandatory**: the lowering requires the *complete* authority set and
rejects any CM that drops one.

- **Leaf** must `forbid compile, admit, authorize, repair, self_authorize`. This
  is **OPER-AUTH-001** ("CM0 cannot admit itself"): a CM0-family CM measures a
  candidate methodology and emits an `InstrumentAssessment` **only** — it does not
  compile, admit, authorize, decide a boundary action, or self-authorize. The
  boundary sets `receipt_contract.measure_only: true` and every `emits.*: false`.
- **Composite** must `forbid averaging, repair, admit, authorize`
  (RCM-NO-AGGREGATE-001: no scalar aggregation may erase a child finding;
  RCM-BOUNDARY-001: measure only).
- **Aspect leaf** must declare `boundary measure_only note "…"` (a run that edited
  files while observing them would destroy its own evidence).

Why the boundary bites at the surface and not at `cue vet`: `#NormalizedCMIR`
leaves the relevant contracts open, so the measure-only invariant is not re-checked
at the IR level — the `.cm` surface makes it structurally load-bearing instead.
The negative probes (`cm0_no_admit.cm`, `repository_coherence_no_averaging.cm`,
`legibility_no_measure_only.cm`, `structure_no_measure_only.cm`) each drop a
required `forbid` and are **rejected at compile time** (exit 2).

---

## 6. Lifecycle

```
.cm source ──► cmc          ──► normalized IR   ──► cue vet -d '#NormalizedCMIR'
           └─► cmc --source ──► full #CMSource   ──► cue vet -d '#CMSource'
```

One source, two byte-exact projections — demonstrated on **CM0**: `cmc cm0.cm` is
byte-identical to `compiled/cm0.json` (the IR projection), and `cmc --source
cm0.cm` is byte-identical to `cue export … -e cm0` (the full source, 7726 bytes,
digests and per-step contracts included). The serializer reproduces `cue export`'s
own bytes (4-space indent, insertion-order keys, `": "` separators, raw UTF-8,
trailing newline) — it is not a re-serialization of both sides.

The aspect leaf and composite have **one** projection each today (methodology-only);
their separate normalized-IR/run projection is **FUTURE** (#112 slice 2).

---

## 7. The graduated curriculum

The four worked `.cm` sources are the learning path, simplest first:

1. **`surface/cm0.cm`** — the instrument leaf. Typed provider steps
   (`let!`/`and!` + `via … @sha256 … on <FAIL>` + `{reads/output/evidence}`),
   `require`/`lists`/`binding`/`standing`, `decide from assessments deferred`, the
   five-authority `forbid`. The only CM with two projections.
2. **`surface/repository_coherence.cm`** — the composite. `child … from …
   [implemented] [selected]`, `parallel cm.run over aspects`, `require
   same_snapshot` / `retain child_receipts`, `decide by precedence`, seven `RCM-*`
   requirements, the four-authority `forbid`.
3. **`surface/legibility.cm`** — the first aspect leaf. Free-form procedure
   (`input`, numbered `step … checks [...]`), `status_mapping` ladder, the leaf
   `decide … when … otherwise` result ladder, `class`/`severity` requirements,
   `boundary measure_only note`.
4. **`surface/structure.cm`** — the second aspect leaf, proving the grammar
   generalizes: the same shape wholesale, plus the two optional deltas — `adr
   "<clause>"` on requirements and an authored `retired` requirement.

Each has a matching negative probe (`*_no_*.cm`) that drops a load-bearing
`forbid`/`measure_only` and is rejected.

---

## 8. Honest limits (not papered over)

- **The methodology-only vet wrinkle.** `#Methodology` and `#AspectMethodology`
  both **mandate a concrete `receipt`**, which the methodology-only projection
  omits. So `cue vet <projection> -d '#Methodology'` (or `-d
  '#AspectMethodology'`) reports the receipt fields incomplete — **identically for
  `cmc`'s output and for `cue export … -e <name>_source` itself**. This is a
  property of *projection vs. the full contract*, not an emitter defect. The
  achievable oracle is `projection ∪ frozen receipt → 0` (the projection unified
  with the receipt validates as a complete methodology missing only its run). A
  clean `#MethodologySource` definition (methodology-without-receipt) is the direct
  fix — **FUTURE**, #112 slice 2.
- **No runtime.** Today's `.cm` *names* providers (`via tool ir_contract_checker
  @sha256:ic0`) but **nothing executes them** — the front-end does IR/source
  emission only. Typed provider/property **libraries** and the interpreter are
  **FUTURE** (#113 programming model / typed provider libraries; #116 Core-warrant
  binding; #112 slice 4 runtime).
- **`source_digest` is carried literally.** The IR digest is the content address
  of the *approved* CUE export; the surface declares it verbatim rather than
  recomputing CUE's hash from the `.cm` form. It is information the IR encodes, so
  the surface carries it losslessly — but it is not independently recomputed by
  `cmc`.
- **The surface typechecks less than CUE.** The compiler enforces boundary
  completeness, binder shape, and required declarations; CUE additionally enforces
  the `#ResultClass` enum, IR closedness (a typo'd top-level key is rejected), the
  `status_mapping[status] == result_class` self-unification, and the computed
  derivation. Keeping CUE as the independent oracle is the point of the #114 split,
  not a temporary gap.
- **`coh cm` is the intended frontend** (#114); today it is `cmc` + `cue`. **FUTURE.**

---

## Accuracy statement — every documented construct → `cm_surface.ml`

For an independent reviewer to confirm nothing is invented. All line numbers are
`surface/lib/cm_surface.ml` unless noted.

**Lexer / tokens** — `Lex.tokenize` (118–179): comments 130–133; strings 146–170;
atoms + `is_atom_char` 112–116, 171–175; `->` (ARROW) 145; `@` (AT) 143; `|`
(PIPE) 144; `[` `]` 138–139; other punctuation 134–143.

**Header dispatch** — `Parse.parse` (737–762): `cm` 739, name 740, `strip_v`
version 741 (`strip_v` 325), params `parse_params` 728–736, `->` 745, output-type
dispatch 748–761 (`InstrumentAssessment`→Leaf 749–755, `CompositeReceipt`→Composite
756, `AspectReceipt`→Aspect 757, unknown-type error 758–761).

**Instrument-leaf body** — `parse_leaf_body` (467–532): `question` 477; `target
<kind> "<desc>"` 478–484; `source_digest sha256:…` 485 (`parse_digest_bare`
387–391); `require <role>:<kind> [optional]` 486–493; `lists` 494 (`atom_list`
327–333); `binding` 495; `standing` 496; `let!`/`and!` 497–500; `retain` 501;
`decide from assessments deferred "…"` 502–508; `boundary_note` 509; `forbid` 510.

**Typed step** — `parse_step` (452–464): `via` 455, provider_kind 456,
provider_id 457, `@<digest>` 458 (`parse_digest_at` 379–384), `on <FAIL>` 460–461.
Step block `parse_step_block` (413–449): `reads` 421–423, `protocol` 425,
`methodology <id> @<digest>` 426–432, `skill <id> <kind> @<digest> v<ver>`
433–442, `output` 443 / `evidence` 444 (`parse_kvlist` 402–410, bool/string value
`parse_value` 395–399).

**Composite body** — `parse_composite_body` (535–619): `question` 558; `child
<name> from <src> [implemented] [selected]` 559–572; `let! … = parallel cm.run
over aspects` 573–584; `require same_snapshot` 585; `retain child_receipts` 586;
`statuses` 587; `decide by precedence | RC -> STATUS` 588–593 (`parse_clauses`
541–553); `requirement <ID> "<text>"` 594–599; `disowns` 600 (`str_list` 336–342);
`forbid` 601.

**Aspect-leaf body** — `parse_aspect_body` (623–725): `question` 652; `profile`
653; `statuses` 654; `status_mapping | S -> C` 655 (`arrow_ladder` 365–376);
`input <name>: "<role>"` 656–662; `step <n>: "<action>" checks [...]` 663–671
(`bracket_atoms` 350–362); `decide | CLASS when "<cond>" … otherwise <CLASS>`
672–677 (`parse_result_rule` 632–647); `requirement <ID> "<text>" class <c>
severity <s> [adr "<clause>"]` 678–689 (`atom_or_str` 346–347, optional `adr` 687);
`retired <ID> "<note>"` 690–695; `disowns` 696; `boundary measure_only note "…"`
697–703.

**Boundary enforcement (§5)** — leaf `required_forbids = [compile; admit;
authorize; repair; self_authorize]` 774, checked in `validate` 784–794 (missing →
OPER-AUTH-001 error 789–791; unknown 793–794); binder shape `let!`-then-`and!`
796–802. Composite `composite_required_forbids = [averaging; repair; admit;
authorize]` 934, `validate_composite` 936–951 (same_snapshot 948, child_receipts
949, children 950, clauses 951). Aspect `validate_aspect` 1003–1007 (`measure_only`
mandatory 1004).

**Lowering / IR effects** — leaf IR `Lower.ir` 805–845 (`emits.*: false` 833–835,
`measure_only: true` 843); leaf full source `Lower.source` 848–904; composite
`Lower.composite` 953–995 (`result.precedence`/`mapping` 985–986,
`allow_scalar_aggregation` 966/979); aspect `Lower.aspect` 1009–1053
(`retired_requirements` ordering 1051–1053). Constant scaffolding reconstructed
914–929 (`result_class_definitions` 919–929).

**Content addresses** — `@sha256:<hex>` `parse_digest_at` 379–384; bare
`sha256:<hex>` `parse_digest_bare` 387–391.

**Two projections / public API** — `type mode = Ir | Source` 1059; `compile_string`
1061–1070 (Leaf → Ir/Source 1064; Composite/Aspect → single projection 1067–1068).

**`#ResultClass` (§4)** — defined in `schema.cue:17` (`"PASS" | "DEFECT" |
"INCOMPLETE" | "FAILED"`); the compiler treats a step's `on <FAIL>` and
`status_mapping` values as barewords (no enum check — `parse_step` 461,
`arrow_ladder` 365–376), so the enum is enforced by CUE, not `cmc` — as stated in
§3.5.
