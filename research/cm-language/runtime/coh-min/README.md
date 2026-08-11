# coh-min — the minimal standalone CM runtime tracer

`coh-min` is the smallest thing that runs an **ordinary CM end to end**: it loads
a NormalizedCMIR, links a SandboxExecutionPlan, executes a finite provider DAG by
input readiness, invokes a **real** provider (`file.exists`), and emits one
`MeasurementReceipt`. It is the M2 tracer for the portable `coh` runtime, on the
path to becoming `coh cm run` — **not** the production toolchain yet.

## What it proves (the M3 gate)

Execution, not static validation. Run the first CM, `example.readme-present`,
against two subject directories:

```
make gate
```

- `examples/readme-present/fixtures/present/` has a `README.md` → receipt
  `result_class: README_PRESENT`
- `examples/readme-present/fixtures/absent/` has none → receipt
  `result_class: README_ABSENT`

The gate fails if either class is wrong or if the two receipts are byte-identical.
Changing the subject changes the receipt because a real provider read the disk —
which is exactly what "the runtime executes providers" means, and what static IR
validation cannot show.

## The IR is canonical, and the build proves it

The artifact `coh-min` executes is a **`#NormalizedCMIR`** as defined by the
project schema, `research/cm-language/schema.cue` — not a private JSON shape:

```
make vet-ir
```

vets every discovered IR under `examples/` against `#NormalizedCMIR`, and
`make gate` depends on it, so no IR reaches the runtime without having been
proved canonical first. Negative fixtures are not excused: the escape IR
(`readme-present.escape.ir.json`) is vetted too, and differs from the good one
in exactly one line. An empty target list fails rather than passing vacuously.

The target list is *discovered*, never enumerated. Every `*.json` under
`examples/` falls into exactly one of three classes, and the gate acts on all
three — which is what lets the closure claim be stated without hedging:

| Class | Rule | `make vet-ir` |
|---|---|---|
| **IR** | any `*.json` inside an `ir/` directory, or any `*.ir.json` anywhere | vetted against `#NormalizedCMIR` |
| **Subject data** | anything under a `fixtures/` directory | ignored — a subject repository may legitimately contain JSON that is not a methodology, and vetting a `package.json` would be a false failure |
| **Unclassified** | any other `*.json` | **refused**, with a message naming the file and both conventions |

So a `*.json` cannot be added under `examples/` without being either gated or
explicitly classified. Naming alone is not load-bearing: the same non-conforming
IR is caught as `naming.ir.json` *and* as `naming.json`.

### Two mechanisms, one contract

`cue vet` and the runtime's own `Ir.of_json` are complementary, and the overlap
is smaller than it looks. CUE's unification makes some **absent** blocks
indistinguishable from empty ones — a concrete schema literal (`format`) unifies
to itself when omitted, and an open struct or list (`procedure`,
`result_contract`) is complete as `{}` / `[]`. Deleting one canonical block from
the shipped IR (cue v0.9.2):

| Missing block | `cue vet` | the runtime |
|---|---|---|
| `format`, `procedure`, `result_contract` | **passes** | fails closed |
| `cm_id`, `cm_version`, `source_digest`, `input_contract`, `receipt_contract` | fails | fails closed |

So the schema owns **exactness** (the closed top-level field set and the shape of
every block present — a stray field or a wrong type is rejected), and the
runtime owns **presence and fail-closed consumption** (all eight canonical
blocks, plus every field it reads). Neither alone is sufficient. Tightening
`#NormalizedCMIR` is the other half of the repair and is deliberately out of
this slice's scope; the schema is conformed to, never edited.

### Result-class vocabulary

The receipt's `result_class` is **the IR's word, not the runner's**. The CM
declares its vocabulary in `result_contract.result_classes`; the runtime reads
that list and refuses to emit a receipt carrying a class the CM never declared:

```
✗ coh_min: result_class "README_PRESENT" is not declared in the IR's
  result_contract.result_classes ["PRESENT", "ABSENT", "INCOMPLETE"]; …
```

The *derivation* is still OCaml (`Runner.classify`), exactly as ascent-0's
`result_contract.derivation` is still prose. Lowering a derivation into
executable data is a later slice; separating vocabulary from derivation is what
this one buys.

## Design (harvested from Ascent-0, generalized)

| Stage | What it does |
|---|---|
| `Ir.of_json` | validate the document into a typed IR: canonical blocks present, consumed fields typed — or a fail-closed `IR error` |
| `link` | normalize the validated steps into a plan; bind each step's capability (`may_access`) |
| `execute` | run a step only when its typed `reads` surfaces are all present; unrun steps are principled skips, never crashes |
| `backend` | invoke the real provider; `file.exists` confines the path, then stats the subject and reports what it saw |
| `evaluate` | derive the result from the produced evidence (runtime-derived, not provider-notarized), then gate it on the vocabulary the IR declares |
| `emit` | canonical-JSON `MeasurementReceipt` with a content-addressed plan digest |

It vendors the JSON serializer and SHA-256 from the Ascent-0 runtime (verbatim,
stdlib-only) but has **no** oracle, sealed reveal, or model enumeration: this is
the ordinary-CM side of the two-sided kernel. Ascent-0 is the hard side; M4
reproduces it through the same shared ABI before any freeze.

### Module layout

- `lib/json.ml`, `lib/sha256.ml` — vendored verbatim from `../ascent-0/lib/`.
- `lib/ir.ml` — the `#NormalizedCMIR` contract as a typed value. **Pure and
  total**: parsing the IR either yields a value every later stage can rely on or
  an error naming the dotted path at fault. It reads through its own
  `result`-returning accessors because the vendored `Json.member` raises.
- `lib/provider.ml` — the provider layer. `confine` is a **pure** path-confinement
  function (its whole negative space is testable without a filesystem);
  `file_exists` is the thin effectful shell that stats the confined path. Both
  report expected failure through `result`, never exceptions.
- `lib/runner.ml` — `link` / `execute` / `evaluate` / `emit`. The DAG executor is
  a recursion over an immutable state record; every expected failure is carried
  in `result` and surfaces at the CLI as a fail-closed non-zero exit.
- `bin/coh_min.ml` — the CLI (`run --ir … --target … [--out …]`).
- `test/test_coh_min.ml` — stdlib assertions (`dune runtest`).

## Path confinement (the portable fail-closed invariant)

`file.exists` **denies** any `relative_path` that is empty, absolute, or carries a
`..` segment — anything that could climb out of the subject root. A denied path
fails the whole run closed: non-zero exit, **no** receipt. Prove it:

```
make confine
```

Lexical (component-wise) confinement is deliberate: the stdlib has no `realpath`
and the contract forbids Unix, so admission never depends on I/O.

## Honest scope

- The executed artifact is the **hand-authored** IR (`ir/readme-present.ir.json`),
  exactly as the Ascent-0 runtime consumes a hand-authored IR today. It is now
  canonical (`#NormalizedCMIR`) and gated, but it is still hand-authored: the
  surface compiler for ordinary CMs is deliberately deferred until the runtime
  target stops moving.
- There is **no `.cm` source** for this example, and no file pretends to be one.
  `readme-present.intent.md` is a prose note recording author intent; the three
  program forms `cm_surface.ml` implements (`InstrumentAssessment`,
  `AspectReceipt`, `CompositeReceipt`) cannot express an ordinary CM emitting a
  `MeasurementReceipt`, so writing one would mean building the deferred
  compiler. The IR is the authoritative executable artifact and says so.
- The result-class **derivation** is still OCaml (`Runner.classify`) for this one
  CM; only the vocabulary is data. Any other `cm_id` is left unclassified and
  fails closed.
- `file.exists` is the **only** wired provider.
- Receipt format `tsc-measurement-receipt/0.1` is the ordinary-CM projection of
  the shared receipt shape M1 will unify with Ascent-0's.

## Build and run

Stdlib-only OCaml; no opam dependencies (the canonical build is `dune`; `cue` is
needed only for `make vet-ir` / `make vet` / `make gate`).

```
make build      # dune build
make test       # dune runtest (unit + end-to-end assertions)
make run        # execute both fixtures
make vet-ir     # cue vet every example IR against #NormalizedCMIR
make vet        # cue vet both receipts against #MeasurementReceipt
make gate       # vet-ir, then the full M3 gate (AC1-5)
make confine    # the path-confinement fail-closed check (AC6)
```
