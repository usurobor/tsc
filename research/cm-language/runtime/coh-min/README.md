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

- `fixtures/present/` has a `README.md` → receipt `result_class: README_PRESENT`
- `fixtures/absent/`  has none         → receipt `result_class: README_ABSENT`

The gate fails if either class is wrong or if the two receipts are byte-identical.
Changing the subject changes the receipt because a real provider read the disk —
which is exactly what "the runtime executes providers" means and what static IR
validation cannot show.

## Design (harvested from Ascent-0, generalized)

| Stage | What it does |
|---|---|
| `link` | normalize `procedure.steps` into a plan; bind each step's capability (`may_access`) |
| `execute` | run a step only when its typed `reads` surfaces are all present; unrun steps are principled skips, never crashes |
| `backend` | invoke the real provider; `file.exists` stats the subject and reports what it saw |
| `evaluate` | derive the result from produced evidence (runtime-derived, not provider-notarized) |
| `emit` | canonical-JSON `MeasurementReceipt` with a content-addressed plan digest |

It shares the JSON serializer and SHA-256 with the Ascent-0 runtime (vendored,
stdlib-only) but has **no** oracle, sealed reveal, or model enumeration: this is
the ordinary-CM side of the two-sided kernel. Ascent-0 is the hard side; M4
reproduces it through the same shared ABI before any freeze.

## Honest scope

- The executed artifact is the **hand-authored** IR (`ir/readme-present.ir.json`),
  exactly as the Ascent-0 runtime consumes a hand-authored IR today. The `.cm`
  records intent; the surface compiler does not yet emit this IR.
- `file.exists` is the **only** wired provider.
- Receipt format `tsc-measurement-receipt/0.1` is the ordinary-CM projection of
  the shared receipt shape M1 will unify with Ascent-0's.

## Build and run

Stdlib-only OCaml; no opam dependencies.

```
make build                       # dune build
make run                         # execute both fixtures
make vet                         # cue vet both receipts
make gate                        # the full M3 gate
```
