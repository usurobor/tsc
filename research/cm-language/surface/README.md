# CM surface language — spike increment 1 (CM0)

Issue **#115** (sub of **#114**). Proves the `.cm` → OCaml → normalized-IR loop
end-to-end on the one clean methodology-only target, **CM0**: a compact ML-shaped
`.cm` source compiles, via an isolated OCaml front-end, to JSON **byte-identical**
to the already-approved `research/cm-language/compiled/cm0.json`, validated by
`cue vet` as `#NormalizedCMIR`. **No semantics reopened** — this changes notation,
not meaning.

```
cm0.cm  --lex-->  tokens  --parse-->  AST  --lower-->  normalized JSON IR
                                                            │
                                          cue vet … -d '#NormalizedCMIR'  (oracle)
```

## Layout

| Path | Role |
|---|---|
| `dune-project` | Its **own** build root — `dune build` in `src/engine/ocaml` never descends here; shares no dependency with the frozen `coh` engine. |
| `lib/cm_surface.ml` | Lexer + recursive-descent parser + lowering + a hand-written JSON serializer that reproduces `cue export`'s exact bytes. **Stdlib only** (no yojson/menhir/ppx). |
| `bin/main.ml` | `cmc` CLI: `cmc <file.cm>` → normalized JSON IR on stdout. |
| `cm0.cm` | CM0 in the compact surface. |
| `cm0_no_admit.cm` | Negative probe: drops `admit` from `forbid`. |

## Build & run

```
$ dune build                              # in research/cm-language/surface/
$ dune exec bin/main.exe -- cm0.cm        # → normalized JSON IR on stdout
```

## Gate results

| Gate | Command | Result |
|---|---|---|
| **AC1** build | `dune build` (in `surface/`) | exit **0** |
| AC1 engine unaffected | `dune build` (in `src/engine/ocaml`) | exit 1 — **pre-existing**, only `otoml`/`ezcurl` missing in this sandbox; **0** references to `surface/`. Separate build roots (no shared/root `dune-project`), so my work cannot perturb the engine build outcome. |
| AC1 compile | `dune exec bin/main.exe -- cm0.cm` | exit **0** |
| **AC2** byte-identity | `diff <(cmc cm0.cm) ../compiled/cm0.json` | **empty**; `cmp` identical. **CUE-exact** — this reproduces `cue export`'s own bytes (4-space indent, insertion-order keys, `": "` separators, trailing `}\n`), **not** a re-serialization of both sides. No documented deviation on serialization. |
| **AC3** CUE oracle | `cue vet <out.json> ../schema.cue -d '#NormalizedCMIR'` | exit **0** |
| **AC4** no semantics reopened | `git status`; `git diff HEAD -- schema.cue examples compiled` | only `surface/` added; frozen files byte-identical (empty diff). |
| Negative probe | `cmc cm0_no_admit.cm` | **rejected**, exit **2** (see below). |

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

2. **The surface is richer than the IR (as intended).** Each step's `via <pk>
   <provider_id>` names the concrete provider (`ir_contract_checker`, …); the IR
   projects only `provider_kind`, dropping the id — exactly as the CUE `cm0` source
   carries full provider refs while the `cm0_ir` projection keeps only
   `provider.kind`. The surface is the authored program; the IR is its normalized
   projection.

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
