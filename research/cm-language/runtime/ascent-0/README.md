# Ascent-0 runtime — the sandbox runtime that executes the IR and emits proof-carrying MeasurementReceipts

**Issues:** [#121](https://github.com/usurobor/tsc/issues/121) (Sub-3 tracer bullet) → [#122](https://github.com/usurobor/tsc/issues/122) (Sub-4 end-to-end generative closure), under [#118](https://github.com/usurobor/tsc/issues/118) → flagship [#117](https://github.com/usurobor/tsc/issues/117).
**Mode:** the servant of Ascent. Sub-3 executed the IR end-to-end for the **validated (case 1)** path and emitted **one** valid `MeasurementReceipt`; **Sub-4 wires all five fixture cases to their required outcomes across two execution arms.**

```
Ascent-0 CM (NormalizedCMIR) → sandbox linker → SandboxExecutionPlan
                             → reference executor → MeasurementReceipt
```

## Honest terminology

- The linked artifact is a **`SandboxExecutionPlan`**, **never** a normative `CompiledCM` (that needs the full Operational compile contract, absent here).
- The command is **`dune exec ascent0_runner -- run <case>`** (or `make run-all`), **never** `coh cm run`.
- The semantic step is a **proposal**, never a warrant. In the **deterministic arm** it is a canned `#CompiledView` per case (`fixtures/canned_compiled_view_<case>.json`); in the **blind arm** it is an externally-supplied proposal (`--proposal <path>`).

## Two execution arms

Both arms run the **identical mechanical backend**; they differ only in the provenance of the one semantic proposal.

- **A. Deterministic conformance arm** (`--arm deterministic`, the default). A canned `#CompiledView` per case makes the categorical results reproducible; any failure here is a wiring/logic bug, not reasoning variance.
- **B. Blind live-LLM arm** (`--arm blind --proposal <path>`). The proposal is produced by a provider that saw **only** the sanctioned one-POV semantic input — no withheld vocabulary (`source`/`transition law`/`FSM`/`Mealy`/`hidden generator`), no oracle access, no fixture answer key. The runtime ingests it and the mechanical backend **earns or refuses** the result.
  - `dune exec ascent0_runner -- blind-prompt <case>` prints the **exact** sanctioned prompt the runtime emits (the leak-checked one-POV input + the required output schema). This is the whole context a blind provider agent may use.
  - The proposal is ingested through the **same** admissibility gate and mechanical pipeline as the canned arm; the prose of the proposal cannot fake a result — the warrant comes from enumeration/fit/quotient/descent/oracle/round-trip, not from the proposal.

## The five cases and their required outcomes

`make check-all` runs all five (deterministic arm) and `cue vet`s every receipt.

| Case | Result (computed) | What the mechanical backend does |
|---|---|---|
| `case1` validated | `LIFT_VALIDATED` | recover generators, predict held-out `ab`, sealed-oracle-verify `predicted=actual`, round-trip returns the class containing `W` |
| `case2` underdetermined | `ASCENT_UNDERDETERMINED` | complete bounded search retains **≥2** inequivalent classes; no oracle collapses them |
| `case3` no realization | `NO_REALIZATION_IN_MODEL` | complete search over the whole class yields an **empty** exact-fit set — never `UNRESOLVED` |
| `case4` decorative | `DECORATIVE_LIFT` | the proposal presents no typed generator and no prediction operator → **refused BEFORE realization** (no search runs) |
| `case5` round-trip | `LIFT_VALIDATED` | `q*=ab` strongly separates; folding `Descend(W,q*)` back and re-ascending returns the single `J_eval` class that contains `W` (scoped equivalence, not identity) |

## The admissibility gate — how `DECORATIVE_LIFT` is genuinely reached (closes #121's deferral)

Sub-3 carried `DECORATIVE_LIFT` only as a **defensive guard** (a non-`#CompiledView` crashed at the semantic step, so `admissible` was always true). Sub-4 makes it **mechanically reachable**:

- The semantic proposal carries a typed `generative_commitment` (the machine-ingestible witnesses); the gate is **structural**, not prose aesthetics. A proposal is **admissible** iff it presents a typed generator that references the declared class **and** supplies a prediction operator.
- An admissible proposal yields the `admissible_proposal` capability that `finite_model_enumerate` reads (see `ir/ascent0.ir.json`). A **decorative** proposal (case4: no typed generator, no operator) is withheld this capability, so the whole realization chain is **skipped** — the refusal happens *before/at realization*, exactly as Core requires. The receipt's `skipped_steps` lists `finite_model_enumerate` missing `admissible_proposal`, and the four other categories remain distinct (case4 alone has `search_ran=false`, `enumerated_class_size=0`).

## THE crux — the runtime COMPUTES, it does not read the answer key

The mechanical providers compute every load-bearing number from the **public inputs** (training traces + declared `H_M`/bounds), never from the fixture's precomputed values. The single place the runtime reads the fixture case files (`read_public_inputs` in [`lib/runtime.ml`](lib/runtime.ml)) consumes **only** public-input surfaces — the training traces (`observed_reply` for cases 1/2/5, `required_reply` for the contradictory case 3), the bounds (`Sigma`, `Gamma`, `N`), the public held-out query, and the public commitment digest — and **deliberately never touches** any `expected_*` / `derived_result` / precomputed-fiber field (all listed by name in that function so a reviewer can confirm by inspection). `J_train`/`J_eval` are **derived** from the traces + held-out query.

The Mealy engine ([`lib/mealy.ml`](lib/mealy.ml)) is the runtime's **own** reimplementation of the frozen object; it does not link the Sub-1 generator.

## Oracle seal (invariant 3), retained alternatives, round-trip

Firewall B is enforced in the **linker** (only the oracle step's capability lists oracle surfaces) and the **executor** (`read_sealed_reveal` is the only path to the sealed reveal; it denies any capability lacking `oracle_reveal` and logs every access). Predictions are **frozen** before the reveal is opened, and the receipt's `oracle_seal.ordering_ok` witnesses `frozen_tick < reveal_tick`; `non_oracle_reveal_accesses = 0`. The executor never collapses a multi-candidate fiber before the Result rule (`retained_before_result_rule ≥ 2` for the validated/underdetermined categories). `make firewall` proves a non-oracle capability is denied the reveal.

## The receipt contract — a discriminated union that bites per category

[`contracts/receipt.cue`](contracts/receipt.cue) states the common shape once, then **each `result_class` tightens the receipt**: `LIFT_VALIDATED` requires a verified oracle, a tested fiber collapsed to 1, round-trip support, and ≥2 retained alternatives; `ASCENT_UNDERDETERMINED` requires ≥2 inequivalent classes and no oracle; `NO_REALIZATION_IN_MODEL` requires an empty fit after a complete search; `DECORATIVE_LIFT` requires `admissible=false` and `search_ran=false`. Firewall A (the embedded `#CompiledView` is exactly five fields) holds for every case, including the decorative one. The contract is **runtime-local** — `schema.cue` defers the full `#RunRequest`/`#MeasurementReceipt` separation to a future #112 slice, so this cell carries its own and does not touch `schema.cue`.

## Build · run · gates

Stdlib-only OCaml + `dune`; `cue` for the oracles. Its **own** dune root (shares nothing with the frozen `coh` engine).

| Gate | Command |
|---|---|
| build | `make build` |
| IR oracle | `make vet-ir` (`cue vet ir/ascent0.ir.json ../../schema.cue -d '#NormalizedCMIR'`) |
| run all five (deterministic arm) | `make run-all` |
| vet all five receipts | `make vet-receipts` |
| firewall probe | `make firewall` |
| blind prompt | `make blind-prompt` |
| full Sub-4 gate | `make check-all` |
| Sub-3 back-compat (case1 only) | `make check` |

Receipts carry absolute fixture paths, so they are **git-ignored and regenerated**, not committed (see `.gitignore`).

## Files

```
dune-project, {lib,bin}/dune   own stdlib-only dune root
lib/sha256.ml                  in-tree SHA-256 (FIPS-180-4, self-tested)
lib/json.ml                    dependency-free JSON parser + canonical serializer
lib/mealy.ml                   the runtime's OWN bounded Mealy class: enumerate/run/fit/quotient/predict
lib/runtime.ml                 load · resolve RunRequest · load proposal · link plan · execute DAG ·
                               admissibility gate · invoke backends · retain alternatives · evaluate · emit
bin/ascent0_runner.ml          the run / blind-prompt / firewall-selftest CLI
ir/ascent0.ir.json             the hand-authored NormalizedCMIR (vets #NormalizedCMIR)
contracts/receipt.cue          the per-category #MeasurementReceipt (vets every receipt)
fixtures/canned_compiled_view_case{1..5}.json   the deterministic-arm proposals (no live LLM)
Makefile                       build · vet-ir · run-all · vet-receipts · firewall · blind-prompt · check-all
```

## Non-goals (explicitly out of this cell)

A live LLM invocation from inside this runtime (the blind arm ingests an externally-produced proposal — δ drives the blind provider); a generic scheduler / authorization / shell / registry / a second CM; calling the artifact a `CompiledCM`; editing the frozen engine, `schema.cue`, the Sub-1 fixture, or the Sub-2 contracts; reading the sealed reveal from any non-oracle path; counting a non-conformant CM0 review toward CM0 4B–4D.
