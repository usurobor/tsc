# example.readme-present — authored intent

**The authoritative executable artifact for this CM is `ir/readme-present.ir.json`**
— a hand-authored `#NormalizedCMIR` that validates against the `0.2` contract at
`../../contracts/cm-ir.cue` (`make vet-ir` enforces it, and `make gate` depends
on that). This file is a **prose note recording author intent**. It is not
source, nothing compiles it, and nothing reads it at run time.

It was previously named `readme-present.cm`, which implied a compile path that
does not exist: `cmc` (the `.cm` front-end at `research/cm-language/surface/`)
rejects it. Renaming it to `.intent.md` is the honest form (#127 AC7) — a
reader or a tool globbing `*.cm` can no longer mistake it for compilable source.

## Governing question

Does the subject repository present a `README.md` at its root?

Deliberately the smallest useful methodology: one leaf terminating at a single
primitive mechanical provider (`fs.file-exists`). It exists to prove the runtime
path — validate the IR contract, link, execute a real provider, capture
evidence, derive a result, emit a receipt — not to say anything deep about
repositories. Its sibling `example.repo-legibility` is the structurally
different one; between them they are the genericity gate.

## What changed at `0.2` (#129), and what did not

**Did not change:** the question, the vocabulary
(`README_PRESENT` / `README_ABSENT` / `INCOMPLETE`), and the observable
behaviour. A subject with a `README.md` still measures `README_PRESENT`, one
without still measures `README_ABSENT`, the two receipts still differ, and an
escaping `relative_path` is still denied fail-closed with zero receipt bytes.
This CM **survives migrated, not deleted** — that is the backward-compatibility
invariant #129 was dispatched under.

**Did change:** the IR that expresses it.

| `0.1` | `0.2` |
|---|---|
| `procedure.steps[*].provider_class: "file.exists"` | `steps[*].checker.capability: "fs.file-exists"` — the methodology names what must be implemented, not who implements it |
| `produces: "readme_presence"` (one untyped surface) | `outputs: { present: { schema, required } }` — typed ports, each required or lawfully withholdable |
| `reads: ["target_root"]` | `inputs: { root: { from: { input: "repository" }, schema } }` — an explicit binding, which is the graph's edge |
| `failure: "INCOMPLETE"` | `failure_policy` mapping an outcome to fact availability or run status — a step no longer names the CM's verdict |
| `result_contract.derivation` (prose, executed by OCaml) | `result.rules` — an ordered first-match table with a mandatory `default`, executed by a generic evaluator |
| `result_contract.result_classes` (vocabulary only) | `result.classes` plus `result.obligations` — the vocabulary, and what a strong class must have retained |

The last row is the one that mattered. In `0.1` the vocabulary was data and the
**derivation** was OCaml: `Runner.classify` compared the CM's identity against
one hard-coded string. That function is deleted. The rules below are the whole
derivation, and the runtime that executes them has never heard of this CM.

## The intent, as a sketch

Illustrative pseudo-code — **not** a program in any implemented grammar; do not
feed it to `cmc`:

```text
subject   repository as root
measure   present by fs.file-exists { relative_path = "README.md" } over root
decide    INCOMPLETE      when readme_exists did not succeed
          README_PRESENT  when present
          README_ABSENT   otherwise
```

Each line maps onto the IR that actually executes:

| Intent | IR carrier |
|---|---|
| `subject repository as root` | `inputs.repository`, bound by `steps[0].inputs.root.from.input` |
| `measure … by fs.file-exists …` | `steps[0].checker.capability` + `steps[0].config.relative_path` |
| `decide` — the class **vocabulary** | `result.classes` |
| `decide` — the class **derivation** | `result.rules` + `result.default`, evaluated by the generic `Rule` evaluator |

There is no longer an honest-seam row. The vocabulary and the derivation are
both data; what remains in OCaml is the *provider* (`fs.file-exists`), and that
is the boundary the cycle exists to draw.

## Why this is not written in the `.cm` surface grammar

`LANGUAGE.md` §2 dispatches on the header's output type into exactly three
program forms, and every one of them is a *repository-coherence* shape:

| Output type | Form | Projection |
|---|---|---|
| `-> InstrumentAssessment` | instrument leaf (CM0) | `#NormalizedCMIR` + `#CMSource` |
| `-> AspectReceipt` | aspect leaf | `#AspectMethodologySource` |
| `-> CompositeReceipt` | composite parent | `#MethodologySource` |

`example.readme-present` is an **ordinary CM**: it emits a
`tsc-measurement-receipt/0.2` `MeasurementReceipt`, which is none of the three.
Expressing it in the real grammar would mean adding a fourth program form to
`cm_surface.ml` — i.e. building the surface compiler for ordinary CMs, which is
**deliberately deferred** until the runtime target stops moving. Until then the
IR is the authored artifact, and it is authored to be canonical.

## Provenance

The IR's `cm.source_digest` is the SHA-256 of **this file**, so the IR names the
authored intent it was written from:

```
$ sha256sum readme-present.intent.md
```
