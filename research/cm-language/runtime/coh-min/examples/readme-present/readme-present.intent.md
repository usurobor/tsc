# example.readme-present — authored intent

**The authoritative executable artifact for this CM is `ir/readme-present.ir.json`**
— a hand-authored `#NormalizedCMIR` that validates against the canonical
`research/cm-language/schema.cue` (`make vet-ir` enforces it, and `make gate`
depends on that). This file is a **prose note recording author intent**. It is
not source, nothing compiles it, and nothing reads it at run time.

It was previously named `readme-present.cm`, which implied a compile path that
does not exist: `cmc` (the `.cm` front-end at `research/cm-language/surface/`)
rejects it. Renaming it to `.intent.md` is the honest form (#127 AC7) — a
reader or a tool globbing `*.cm` can no longer mistake it for compilable source.

## Governing question

Does the subject repository present a `README.md` at its root?

Deliberately the smallest useful methodology: one leaf terminating at a single
primitive mechanical provider (`file.exists`). It exists to prove the runtime
path — validate the IR contract, link, execute a real provider, capture
evidence, emit a receipt — not to say anything deep about repositories.

## Why this is not written in the `.cm` surface grammar

`LANGUAGE.md` §2 dispatches on the header's output type into exactly three
program forms, and every one of them is a *repository-coherence* shape:

| Output type | Form | Projection |
|---|---|---|
| `-> InstrumentAssessment` | instrument leaf (CM0) | `#NormalizedCMIR` + `#CMSource` |
| `-> AspectReceipt` | aspect leaf | `#AspectMethodologySource` |
| `-> CompositeReceipt` | composite parent | `#MethodologySource` |

`example.readme-present` is an **ordinary CM**: it emits a
`tsc-measurement-receipt/0.1` `MeasurementReceipt`, which is none of the three.
Expressing it in the real grammar would mean adding a fourth program form to
`cm_surface.ml` — i.e. building the surface compiler for ordinary CMs, which is
**deliberately deferred** until the runtime target stops moving (#127 §Scope).
Until then the IR is the authored artifact, and it is authored to be canonical.

## The intent, as a sketch

Illustrative pseudo-code — **not** a program in any implemented grammar; do not
feed it to `cmc`:

```text
subject   repository as target_root
measure   readme_presence by file.exists { relative_path = "README.md" } over target_root
decide    README_PRESENT when readme_presence
          README_ABSENT  otherwise
```

Each line maps onto the IR that actually executes:

| Intent | IR carrier |
|---|---|
| `subject repository as target_root` | `input_contract.required_artifacts[0]` (`role: target_root`) |
| `measure … by file.exists … ` | `procedure.steps[0]` (`provider_class: file.exists`, `config.relative_path`) |
| `decide` — the class **vocabulary** | `result_contract.result_classes`, read and enforced by the runtime |
| `decide` — the class **derivation** | prose in `result_contract.derivation`; executed by `Runner.classify` |

That last row is the honest seam: the vocabulary is data the runtime reads from
the IR and refuses to exceed; the derivation is still OCaml (as ascent-0's
`derivation` field is still prose). Lowering a derivation into executable data
is a later slice.

## Provenance

The IR's `source_digest` is the SHA-256 of **this file**, so the IR names the
authored intent it was written from:

```
$ sha256sum readme-present.intent.md
```
