# Issue usurobor/tsc#129

**Title:** coh-min M1a: generic CM execution — a second methodology runs as data, results derived from the IR

## Gap

`coh-min` executes, but it executes **one** methodology. `Runner.classify` is written for `example.readme-present` and any other `cm_id` fails closed; the result rule is OCaml, the vocabulary alone is data; the graph is a single node. Adding a methodology today means writing OCaml.

That is a tracer, not a runtime. The execution model's first acceptance gate is genericity: *two structurally different ordinary CMs run through the same parser, linker, scheduler, result evaluator, and receipt writer without `cm_id` dispatch or a CM-specific classifier.*

## Governing question

Can a methodology be added to `coh` as **data alone** — a JSON IR and nothing else — and produce a correct, evidence-bearing, schema-valid receipt?

## Design authority

`research/cm-language/runtime/CM-EXECUTION-MODEL.md` at **PR #128 head `511b548`** (branch `design/cm-execution-model`). It is a **review candidate**, not yet merged: implement the decisions as written at that pinned SHA. If its independent review changes a decision, this contract is amended rather than reinterpreted. Relevant sections: *JSON document family*, *Declarative result semantics*, *Graph execution semantics*, *Acceptance gates* (esp. gate 9), *Design invariants*.

Artifact-family master: `#112` (its amendment is pending and does not block this cycle).

## Acceptance criteria (executable oracle)

1. **Genericity — the headline.** A **second, structurally different** ordinary CM runs end to end through the same binary. The commit that adds the *methodology* touches **no `.ml` file** (its provider is separate, AC2). No `cm_id`-keyed branch exists anywhere in the load/link/execute/evaluate/emit path — demonstrate by search, and by the second CM running without any such branch existing.
2. **One new provider, stdlib-only.** Exactly one additional mechanical provider (e.g. a size/line-count/content predicate over a confined path). Adding a *provider* is OCaml; adding a *methodology* is not. Keep that boundary crisp and state it in the README.
3. **A real DAG.** The second CM has **≥2 independent steps** and **≥1 step whose input binds another step's declared output port**. Execution follows readiness, not declaration order. When a dependent step's required input cannot be produced, it is a **principled skip** recorded in the trace **naming the missing input** — never a fabricated value, never a crash. Prove both branches with fixtures (dependency satisfied / dependency unsatisfiable).
4. **The result rule is data.** Derivation comes from an ordered first-match rule table with a mandatory `default` in the IR's `result` block, evaluated by a generic evaluator implementing the v0 algebra (finite boolean ops, equality and ordered comparisons, presence/status predicates). `Runner.classify` and every CM-specific classifier are **deleted** from the acceptance path. The receipt records the matched `rule_id` and the fact references read.
5. **Fact provenance.** Every non-scheduler fact a rule reads originates in a declared typed step output or declared evidence predicate. Scheduler-owned facts are limited to execution status, principled skip/refusal/failure, and bounds/coverage. A rule referencing an undeclared fact is refused **at load**, not at evaluation.
6. **Result honesty.** Refuse, fail-closed: a class not in the declared `classes`; a rule table with no `default`; a provider-supplied final-result field (ignored or rejected, never authoritative). Each pinned by a regression test.
7. **Schemas `0.2`, provably required.** Closed CUE for `#NormalizedCMIR` (`tsc-cm-ir/0.2`) and `#MeasurementReceipt` (`tsc-measurement-receipt/0.2`) — the `0.1` strings stay owned by what is on `main` today. Every canonical block and runtime-consumed field must be **provably required** (concrete-typed, not an open struct/list), not merely protected against extras. Both CMs' IRs and every emitted receipt vet.
8. **Gate 9 negative fixtures.** One missing-block case per canonical top-level block, for **both** artifact families. Every case must fail the **runtime**; document which also fail `cue vet` and which are CUE-blind (the measured 3-of-8 pattern). `make vet-ir`-style discovery covers them; the gate runs them and fails loudly.
9. **`RunRequest` as an artifact.** The subject is bound by content digest, not a path. Define **one** versioned directory-subject snapshot scheme (name it, e.g. `directory-merkle/0.1`) per the design's fail-closed boundary — an unnamed or unknown scheme refuses. Local paths remain locators. The receipt binds the request, IR, and plan digests.
10. **No regression.** `readme-present` still yields `README_PRESENT` / `README_ABSENT` with differing receipts; path confinement still denies fail-closed with zero receipt bytes; the existing suite still passes.
11. **`make gate` covers 1–10 and CI is green on the cycle branch.**

## Evidence required to close

Green `coh-min` CI on the cycle branch, plus in `self-coherence.md`: the two CMs' receipts, the skip-branch trace showing the named missing input, the genericity demonstration (no `cm_id` branch), and the gate-9 matrix (per block: `cue vet` verdict vs runtime verdict).

## Non-goals — do not build these here

- A standalone `verify` subcommand (next cell; the receipt must *carry* what a verifier needs, but the verifier itself is separate).
- `CheckRequest`/`CheckOutcome` as wire artifacts — the logical envelope is enough at this size.
- `semantic_judgment`, `invoke_cm`, `oracle`, `transform` step kinds; bounded collection operators; warrant obligations beyond what these two CMs exercise.
- Ascent-0 conversion; the `.cm` compiler; `CompiledCM`; package/registry anything.

## Implementation contract (pinned by δ; α MUST NOT improvise)

| Axis | Pin |
|---|---|
| Language | OCaml, **stdlib-only** (no yojson/ppx/unix). `lib/json.ml` and `lib/sha256.ml` stay **byte-identical** to `../ascent-0/lib/`. |
| CLI integration target | The existing `coh_min` executable. Flags may gain a `--request` form; `run --ir … --target …` must keep working. Not `coh cm` yet. |
| Package scoping | `research/cm-language/runtime/coh-min/**` and `.github/workflows/coh-min.yml` only. |
| Existing-binary disposition | Additive plus the deletion of CM-specific classification. No other binary or example touched. **Do not edit `research/cm-language/schema.cue`**; the `0.2` contracts live under `coh-min/contracts/` until promoted. |
| Runtime dependencies | None beyond the stdlib at build/run; `cue` only in the gates. |
| JSON/wire contract | Canonical JSON (lexicographic keys, 2-space indent, LF, trailing newline). `tsc-cm-ir/0.2`, `tsc-measurement-receipt/0.2`, `tsc-run-request/0.1`. |
| Backward-compat invariant | Every #126 and #127 acceptance criterion continues to hold. The `readme-present` CM survives as data — migrated to `0.2`, not deleted. |

