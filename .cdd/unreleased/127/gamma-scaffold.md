# γ scaffold — cycle/127

**Issue:** usurobor/tsc#127 — *coh-min: consume schema-compliant NormalizedCMIR and enforce it in the gate (case 0)*
**Branch:** `cycle/127`
**Canonical issue text:** `.cdd/unreleased/127/issue-127.md` (this cell has no `gh`; read the issue there).
**Predecessor:** #126 (merged at `main` `e8b8319`) — the slice you are repairing.

## Why this cycle exists (δ's framing — read it, it changes what "done" means)

#126 shipped a runtime that genuinely executes, but δ's contract for it said the IR
was hand-authored "exactly as the Ascent-0 IR is today". The hand-authored part was
true; the **conforming** part was not. The IR does not validate against the project's
canonical `#NormalizedCMIR`, and nothing in the gate asked. That is the defect class
this cycle closes: not just fixing one file, but making the schema **mechanically
enforced** so the next five cases cannot drift the same way.

Strategic context: the surface compiler is **deliberately deferred**. The project is
hand-authoring schema-valid IR for a ladder of increasing-complexity cases
(`#StepKind` = mechanical → collection → invoke_cm → semantic_judgment → oracle),
learning the runtime ABI from real runs, and writing the compiler only once the target
stops moving. So the IR is not a temporary crutch — for now it **is** the authored
artifact, and it must be canonical.

## α mandate (bounded step)

On `cycle/127`, make `coh-min` consume a schema-compliant `#NormalizedCMIR` and make
the build refuse any IR that is not. Satisfy every acceptance criterion in the issue,
honoring the pinned implementation contract. You own the code; do not merge.

## Load order

1. `.cdd/skills/cdd/alpha/SKILL.md` — α role discipline.
2. `SKILLS_ROOT/eng/ocaml/SKILL.md`, `SKILLS_ROOT/eng/write-functional/SKILL.md`,
   `SKILLS_ROOT/eng/code/SKILL.md`, `SKILLS_ROOT/eng/test/SKILL.md`.
3. `.cdd/unreleased/127/issue-127.md` — ACs + the 7-axis contract.
4. `.cdd/unreleased/126/beta-review.md` — β's prior review of this slice; its standards
   are the bar you will be re-reviewed against.

## Environment facts (verified by γ)

- `ocamlopt` 4.14.1 at `/usr/bin/ocamlopt`. **`dune` is NOT installed here** and cannot
  be apt-installed. Verify locally with a flat `ocamlopt` compile of
  `lib/{sha256,json,provider,runner}.ml` plus a driver derived from `bin/coh_min.ml`
  (strip the `Coh_min.` module prefix for a flat build). The canonical `dune build` /
  `dune runtest` run in CI.
- `cue` v0.9.2 at `/usr/local/bin/cue`.
- The canonical schema is `research/cm-language/schema.cue` — **read it, conform to it,
  do not edit it**. From the coh-min directory it is `../../schema.cue`.
- A CONFORMING reference IR: `../ascent-0/ir/ascent0.ir.json`. Vet it yourself to see
  a passing example:
  `cue vet ../ascent-0/ir/ascent0.ir.json ../../schema.cue -d '#NormalizedCMIR'`
- The current FAILING vet (reproduce it first, so you know the target):
  `cue vet examples/readme-present/ir/readme-present.ir.json ../../schema.cue -d '#NormalizedCMIR'`
- The surface compiler, for AC7 context: build it flat from
  `research/cm-language/surface/{lib/cm_surface.ml,bin/main.ml}` (`ocamlopt cm_surface.ml
  main.ml -o cmc`). It rejects the current `readme-present.cm` with
  `expected "cm", got identifier "methodology"`. `LANGUAGE.md` carries the real grammar.

## Verification you MUST run before signalling review-readiness

Both IRs vet against `#NormalizedCMIR`; `make vet-ir` fails loudly on a deliberately
broken IR (prove the gate bites, then restore); both fixtures still yield
`README_PRESENT`/`README_ABSENT` with differing, `cue vet`-clean receipts; the escape IR
is still denied fail-closed; a missing-canonical-block IR fails closed; the full test
suite passes. Record every transcript in `.cdd/unreleased/127/self-coherence.md`.

## Exit

Commit to `cycle/127` authored `usurobor <usurobor@gmail.com>` (no tool/model trailers),
push, write `self-coherence.md`, and return a summary with your verification results.
δ will dispatch β to review the diff against the contract.
