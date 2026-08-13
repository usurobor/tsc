# γ scaffold — cycle/129

**Issue:** usurobor/tsc#129 — *coh-min M1a: generic CM execution — a second methodology runs as data, results derived from the IR*
**Branch:** `cycle/129` (from `main` `274342f`)
**Canonical issue text:** `.cdd/unreleased/129/issue-129.md` (this cell has no `gh`).
**Design authority:** `.cdd/unreleased/129/CM-EXECUTION-MODEL.pinned-61ba4d2.md` — a verbatim copy of the design doc at PR #128 head `61ba4d2` (Pi's seven-point correction pass applied). It is **not on `main`**; this pinned copy is your authority. Do not go looking for it elsewhere and do not use a different version.
**Predecessors:** #126 (runtime executes) and #127 (IR is canonical), both merged.

## Why this cycle exists (read this — it changes what "done" means)

`coh-min` today runs **exactly one** methodology. `Runner.classify` is written for
`example.readme-present`; any other `cm_id` fails closed; the result rule is OCaml
and only the vocabulary is data; the graph is a single node. That is a tracer.

This cycle makes it a **runtime**: a methodology becomes *data*. The forcing
function is the design's acceptance gate 1 — two structurally different ordinary
CMs run through the same parser, linker, scheduler, evaluator, and receipt writer
with **no `cm_id` dispatch and no CM-specific classifier**. If, at the end, adding a
third methodology would require touching OCaml, this cycle has failed regardless of
what the tests say.

Keep the boundary crisp and state it in the README: adding a **provider** is OCaml;
adding a **methodology** is not.

## α mandate (bounded step)

On `cycle/129`, satisfy every acceptance criterion in the issue, honoring the pinned
7-axis implementation contract and the design doc at `511b548`. You own the code;
do not merge.

## Load order

1. `.cdd/skills/cdd/alpha/SKILL.md` — α role discipline.
2. `SKILLS_ROOT/eng/ocaml/SKILL.md`, `SKILLS_ROOT/eng/write-functional/SKILL.md`,
   `SKILLS_ROOT/eng/code/SKILL.md`, `SKILLS_ROOT/eng/test/SKILL.md`,
   `SKILLS_ROOT/eng/ux-cli/SKILL.md`.
3. `.cdd/unreleased/129/issue-129.md` — the 11 ACs + the 7-axis contract.
4. `.cdd/unreleased/129/CM-EXECUTION-MODEL.pinned-61ba4d2.md` — the design. Read at
   minimum: *JSON document family*, *Declarative result semantics*, *Graph execution
   semantics*, *Acceptance gates* (especially gate 9), *Design invariants*.
5. `.cdd/unreleased/127/beta-review.md` and `.cdd/unreleased/126/beta-review.md` —
   β's standards across both prior cycles; that is the bar you will be re-reviewed
   against.

## Design decisions already settled — do not relitigate

These were converged in the Pi↔Sigma design round and are pinned in the doc:

- **Receipt** = one closed core + one closed, **discriminated** family extension.
  Not a bag of optional blocks. `tsc-measurement-receipt/0.2` — the `0.1` string is
  owned by what ships on `main` today and must not be reused.
- **Two step moments, not one.** `NormalizedStep` = what the methodology *requires*.
  `SandboxPlanStep` = what the linker *selected and granted*, citing the normalized
  step it discharges. Do not fuse them.
- **A step must not name the CM's result class.** The old `failure -> ResultClass`
  shortcut is superseded: it gives a node hidden authority over the CM verdict. Use
  `failure_policy` mapping an outcome to fact availability / run status.
- **Fact provenance invariant.** Any non-scheduler fact a rule reads must originate
  in a declared typed step output or declared evidence predicate. Scheduler facts
  are limited to status, principled skip/refusal/failure, bounds/coverage. A rule
  referencing an undeclared fact is refused **at load**.
- **Result rule** = ordered first-match clauses + a mandatory `default`. v0 algebra
  only: finite boolean ops, equality and ordered comparisons, presence/status
  predicates. No provider effects, mutation, recursion, or unbounded iteration.

## The second CM — structure is pinned, content is yours

Design it yourself, but it MUST have: ≥2 **independent** steps; ≥1 step whose input
binds another step's declared **output port**; a reachable **principled skip** when
that dependency cannot be produced; and ≥3 result classes. Fixtures must exercise
both branches (dependency satisfied, dependency unsatisfiable). Exactly **one** new
stdlib-only mechanical provider.

## Environment facts (verified by γ)

- `ocamlopt` 4.14.1 at `/usr/bin/ocamlopt`. **`dune` is NOT installed** here and
  cannot be apt-installed. Verify locally with a flat `ocamlopt` compile of the lib
  modules plus a driver derived from `bin/coh_min.ml` (strip the `Coh_min.` prefix).
  The canonical `dune build` / `dune runtest` run in CI.
- `cue` v0.9.2 at `/usr/local/bin/cue`.
- The `0.2` contracts live under `coh-min/contracts/`. **Do not edit
  `research/cm-language/schema.cue`** — the current `#NormalizedCMIR` there is `0.1`
  and stays as it is; promoting `0.2` into the project schema is a later cycle.
- Measured and load-bearing for AC8: a `close()`d CUE struct rejects *extra* fields
  but **not absent** ones. On the shipped IR, deleting `format`, `procedure`, or
  `result_contract` still passes `cue vet`. Your `0.2` schemas must make every
  canonical block *provably required*, and the runtime must refuse absence
  independently. Report the per-block matrix; do not assume it matches the old one.

## Verification you MUST run before signalling review-readiness

Both CMs end to end; the skip branch with the missing input named in the trace; the
genericity demonstration (no `cm_id` branch in the acceptance path, and the second
CM's methodology added without touching `.ml`); every gate-9 negative fixture failing
the runtime; result-honesty refusals; `readme-present` unregressed; path confinement
still fail-closed with zero receipt bytes; full suite. Record every transcript in
`.cdd/unreleased/129/self-coherence.md`.

## Exit

Commit to `cycle/129` authored `usurobor <usurobor@gmail.com>` (no tool/model
trailers), push, write `self-coherence.md`, and return a summary with your
verification results. δ dispatches β to review the diff against the contract.

**Close-outs are pre-merge blockers here** (`CDD.md` §5.3b): after β's verdict you
will be re-dispatched to write `.cdd/unreleased/129/alpha-closeout.md`. Expect it.

---

## Amendment — dispatch released, and the frame this cycle sits in (δ, 2026-08-13)

**Released by the operator.** The earlier hold pending Pi's exact-head GO is lifted:
Pi's seven corrections are applied and the pinned design here is the corrected head
`61ba4d2`. Build within Pi's constraints as written in that document — the design is
settled; this cycle is execution, not negotiation.

**The frame.** The goal is *run an arbitrary CM expressed in JSON*. It splits:

- **FLAT** — every step terminates at a primitive provider; no CM invokes another CM.
- **NESTED** — a CM invokes other CMs and receipts compose.

**This cycle is FLAT, over the built-in provider set.** Nesting is not in scope and
must not be anticipated in the code: no `invoke_cm`, no child `RunRequest`, no
receipt-inside-receipt. Adding a *provider* is OCaml; adding a *methodology* is data
— that boundary is the whole point of the cycle and must be stated in the README.

Two consequences worth holding in mind while you build, neither of which is scope:

- The result evaluator, the linker, and the receipt writer must not acquire any
  knowledge of a specific CM. If a third methodology would require touching OCaml,
  the cycle has failed regardless of the tests.
- A standalone `verify` subcommand is the immediate successor cell, so the receipt
  must **carry** everything a verifier needs (matched `rule_id`, fact refs, the
  request/IR/plan digests of AC10) even though you do not build the verifier here.

**Tests are a first-class deliverable, not a trailer.** Every acceptance criterion
gets its own executable check. The gate must fail loudly on each. A criterion
verified only by reading the code is not verified.
