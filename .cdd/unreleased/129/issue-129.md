# Issue usurobor/tsc#129

**Title:** coh-min M1a: generic CM execution — a second methodology runs as data, results derived from the IR

## Gap

`coh-min` executes, but it executes **one** methodology. `Runner.classify` is written for `example.readme-present` and any other `cm_id` fails closed; the result rule is OCaml, the vocabulary alone is data; the graph is a single node. Adding a methodology today means writing OCaml.

That is a tracer, not a runtime. The execution model's first acceptance gate is genericity: *two structurally different ordinary CMs run through the same parser, linker, scheduler, result evaluator, and receipt writer without `cm_id` dispatch or a CM-specific classifier.*

## Governing question

Can a methodology be added to `coh` as **data alone** — a JSON IR and nothing else — and produce a correct, evidence-bearing, schema-valid receipt?

## Design authority

`research/cm-language/runtime/CM-EXECUTION-MODEL.md` at **PR #128 head `61ba4d2`** (branch `design/cm-execution-model`) — the head carrying Pi's seven-point correction pass. Implement the decisions as written at that pinned SHA. Relevant sections: *JSON document family*, *Uniform checker contract* (required vs optional output ports), *Declarative result semantics*, *Graph execution semantics*, *Acceptance gates* 9–11, *Design invariants*.

**Status: this cycle is HELD at its γ scaffold pending Pi's exact-head GO on `61ba4d2`. Do not dispatch α until that GO lands.**

Artifact-family master: `#112` (amendment pending; does not block this cycle).

## Acceptance criteria (executable oracle)

1. **Genericity — the headline.** A **second, structurally different** ordinary CM runs end to end through the same binary. The commit that adds the *methodology* touches **no `.ml` file** (its provider is separate, AC2). No `cm_id`-keyed branch exists anywhere in the load/link/execute/evaluate/emit path — demonstrate by search, and by the second CM running without any such branch existing.
2. **One new provider, stdlib-only.** Exactly one additional mechanical provider (e.g. a size/line-count/content predicate over a confined path). Adding a *provider* is OCaml; adding a *methodology* is not. Keep that boundary crisp and state it in the README.
3. **A real DAG, with required/optional ports.** The second CM has **≥2 independent steps** and **≥1 step whose input binds another step's declared output port**. Every declared output is `required` (default) or `optional`: a `success` outcome missing a **required** output is rejected, not downgraded; an absent **optional** output is lawful withholding. A dependent step whose required input binds an absent optional port is a **principled skip** recorded in the trace **naming the unpublished port** — never a fabricated value, never a crash. Exercise both branches with fixtures, and exercise lawful withholding at least once.
4. **The result rule is data.** Derivation comes from an ordered first-match rule table with a mandatory `default` in the IR's `result` block, evaluated by a generic evaluator implementing the v0 algebra (finite boolean ops, equality and ordered comparisons, presence/status predicates). `Runner.classify` and every CM-specific classifier are **deleted** from the acceptance path. The receipt records the matched `rule_id` and the fact references read.
5. **Fact provenance.** Every non-scheduler fact a rule reads originates in a declared typed step output or declared evidence predicate. Scheduler-owned facts are limited to execution status, principled skip/refusal/failure, and bounds/coverage. A rule referencing an undeclared fact is refused **at load**, not at evaluation.
6. **Result honesty.** Refuse, fail-closed: a class not in the declared `classes`; a rule table with no `default`; a provider-supplied final-result field (ignored or rejected, never authoritative). Each pinned by a regression test.
7. **Schemas `0.2`, required by construction.** Closed CUE for `#NormalizedCMIR` (`tsc-cm-ir/0.2`) and `#MeasurementReceipt` (`tsc-measurement-receipt/0.2`) — the `0.1` strings stay owned by what is on `main` today. Every canonical block and runtime-consumed field must be **required by construction** using CUE's required-field marker **`field!:`** (or a mechanism proved equivalent by fixture). *Concreteness is not the lever*: measured with cue v0.9.2, a concrete literal like `format: "…"` is exactly the case that slips through when absent, while `cm_id: string` is caught. Each schema must additionally carry a **non-vacuity fixture** proving it rejects something it ought to reject. Both CMs' IRs and every emitted receipt vet.
8. **Gate 9 negative fixtures.** One missing-block case per canonical top-level block, for **both** artifact families. Every case must fail the **runtime**; document which also fail `cue vet` and which are CUE-blind. `make vet-ir`-style discovery covers them; the gate runs them and fails loudly.
9. **`RunRequest` as an artifact, with a named snapshot scheme.** The subject is bound by content digest, not a path. Every subject entry names a versioned `scheme` (define exactly one, e.g. `directory-merkle/0.1`); an absent or unrecognized scheme refuses fail-closed. Local paths remain locators. The receipt binds the request, IR, and plan digests.
10. **Digest binding is checked (gate 10).** A receipt whose `request`, `cm_ir`, or `plan` digest does not match the artifact it was produced from is refused. Carry a negative fixture per binding — each must fail even though every field is individually well-typed.
11. **Checker config schemas validated at link time (gate 11).** A step's `config` shape is owned by the checker **capability contract**; the linker validates the normalized step's `config` against the capability it binds, and a non-validating config refuses at link time rather than reaching the provider. Negative fixture required.
12. **No regression.** `readme-present` still yields `README_PRESENT` / `README_ABSENT` with differing receipts; path confinement still denies fail-closed with zero receipt bytes; the existing suite still passes.
13. **`make gate` covers 1–12 and CI is green on the cycle branch.**

## Evidence required to close

Green `coh-min` CI on the cycle branch, plus in `self-coherence.md`: the two CMs' receipts, the skip-branch trace showing the named unpublished port, the lawful-withholding case, the genericity demonstration (no `cm_id` branch), the gate-9 matrix (per block: `cue vet` verdict vs runtime verdict), and the digest-mismatch and config-violation refusals.

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

---

**Amendment history.** Original AC7 required blocks to be "provably required (concrete-typed, not an open struct or list)". That guidance was backwards — concreteness is what lets an absent block slip through — and is replaced by `field!:` plus non-vacuity. ACs 3, 10, and 11 were added or extended for the required/optional output-port semantics, digest binding, and config-schema ownership introduced by the design's correction pass. Design authority moved `511b548` → `61ba4d2`.
