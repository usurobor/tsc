# Ascent-0 · Sub 3 — the smallest sandbox runtime that executes the IR and emits one MeasurementReceipt

**Issue:** [#121](https://github.com/usurobor/tsc/issues/121) (under [#118](https://github.com/usurobor/tsc/issues/118) → flagship [#117](https://github.com/usurobor/tsc/issues/117)).
**Mode:** a **tracer bullet, not a platform.** It executes the Ascent-0 IR end-to-end for the **validated (case 1)** path and emits **one** valid `MeasurementReceipt`.
**Grounds on (references, never edits):** the Sub-1 frozen fixture [`research/ascent/fixtures/ascent-0/`](../../../ascent/fixtures/ascent-0/), the Sub-2 typed provider contracts [`research/cm-language/providers/ascent-0/`](../../providers/ascent-0/), and [`research/cm-language/schema.cue`](../../schema.cue).

The pipeline this cell implements:

```
Ascent-0 CM (NormalizedCMIR) → sandbox linker → SandboxExecutionPlan
                             → reference executor → MeasurementReceipt
```

## Honest terminology

- The linked artifact is a **`SandboxExecutionPlan`**, **never** a normative `CompiledCM` (that needs the full Operational compile contract, absent here).
- The command is **`dune exec ascent0_runner -- run case1`** (or `make run`), **never** `coh cm run`.
- The semantic step is a **canned deterministic `#CompiledView`** (a fixture response — the **deterministic conformance arm**); the blind live-LLM arm and the other four cases are **#122**, out of scope here.

## THE crux — the runtime COMPUTES, it does not read the answer key

The mechanical providers compute every load-bearing number from the **public inputs** (the training traces + the declared `H_M` / bounds), never from the fixture's precomputed values:

| step | provider | what it genuinely does | case-1 result (computed) |
|---|---|---|---|
| `finite_model_enumerate` | `FiniteModel.enumerate` | real complete bounded enumeration of `H_M` | `enumerated_class_size = 260` |
| `realization_fit` | `Realization.fit` | exact-fit partition `L_M = 0` over the class | `fit_candidate_count = 8` |
| `realization_quotient` | `Realization.quotient` | quotient `F_id = C_train / ~=^U` | `identification_fiber_size = 8` |
| `descent_predict` | `Descent.predict` | runs each surviving candidate's transition law on the held-out query `ab` | predictions `{00, 01}`, **separating**, then **frozen** |
| `oracle_reveal_compare` | `Oracle.revealAndCompare` | opens the sealed reveal, verifies the commitment, partitions by the revealed output | `revealed 01`, `pass = 4`, `fail = 4`, `tested_fiber = 1` |
| `roundtrip_check` | `RoundTrip.check` | folds the confirmed `(ab, 01)` back in and re-ascends | `fiber_over_J_eval = 1`, contains `W` |

**Computed → `LIFT_VALIDATED`:** predicted `01` = revealed `01`, tested fiber collapses to `1`, recovered class contains the hidden machine.

The single place the runtime reads the fixture case files (`read_public_inputs` in [`lib/runtime.ml`](lib/runtime.ml)) consumes **only** public-input surfaces — the training traces, the bounds (`Sigma`, `Gamma`, `N`), the public held-out query, and the public commitment digest — and **deliberately never touches** `candidate_fiber_over_U`, `complete_candidate_set_size`, `frozen_prediction_on_heldout`, `heldout_distinct_predictions`, `training_identification_fiber_over_U`, `derived_result`, or any `expected_*` field (those are Sub-1's *expected* values; they are listed by name in that function so a reviewer can confirm by inspection). `J_train` / `J_eval` are **derived** from the traces + held-out query, not read.

The Mealy engine ([`lib/mealy.ml`](lib/mealy.ml)) is the runtime's **own** reimplementation of the frozen mathematical object; it does not link the Sub-1 generator.

## Oracle seal at runtime (invariant 3)

Firewall B is enforced in the **linker** and the **executor**, not just documented:

- **Linker** ([`lib/runtime.ml`](lib/runtime.ml) `link`): only the `oracle` step's sandbox capability lists the oracle surfaces; every non-oracle step is linked with an **oracle-free** capability (oracle surfaces stripped, regardless of what the IR declared).
- **Executor**: `read_sealed_reveal` is the **only** path to `generated/reveal/…`. It refuses any caller whose capability lacks `oracle_reveal` and logs every access with the caller's provider class. The receipt's `oracle_seal.reveal_access_log` therefore contains exactly one entry (`oracle`), and `non_oracle_reveal_accesses = 0`.
- **Ordering**: `descent_predict` freezes the predictions at logical tick 5; the oracle refuses to open the reveal unless the predictions are already frozen, and opens it at tick 6. `oracle_seal.ordering_ok = true` witnesses `frozen_tick < reveal_tick`.
- **Tamper-evidence**: the oracle recomputes SHA-256 over the raw reveal bytes ([`lib/sha256.ml`](lib/sha256.ml), FIPS-180-4, self-tested) and checks it equals the public `oracle_commitment_sha256` (`commitment_verified = true`).

`make firewall` runs a standalone probe proving a non-oracle capability is **denied** the reveal and the oracle one is allowed.

## Alternatives retained (no premature collapse)

The executor never collapses a multi-candidate fiber before the Result rule. Case 1 alone demonstrates it: all **8** identification-fiber classes are retained through descent, then partitioned into **4 pass / 4 fail** — every representative is listed in the receipt's `retained_alternatives`. The Result rule reads `tested_fiber = 1` as a *derived fact*; it does not discard the retained alternatives.

## The IR: hand-authored, not `cmc`-compiled — and why

The task prefers authoring the CM in `.cm` and compiling via `cmc`. The existing `cmc` ([`../../surface/`](../../surface/)) is specialised to **three fixed CM families** (the CM0 instrument leaf, the composite `#Methodology`, the aspect `#AspectMethodology` leaf), each with its own hard-coded parser body, lowerer, and mandatory-boundary check. The Ascent-0 procedure is a **new, seventh-provider generative DAG** (`semantic → FiniteModel.enumerate → Realization.fit → Realization.quotient → Descent.predict → Oracle.revealAndCompare → RoundTrip.check`) — a new CM family. Its **step kinds** map cleanly onto the existing `#StepKind` enum (`semantic_judgment`, `mechanical`, `oracle`), so **no `cmc` grammar extension is needed for expressiveness** — but adding a whole new family body to `cmc` would balloon this tracer bullet. Per the issue's sanctioned fallback, the IR is therefore **hand-authored** ([`ir/ascent0.ir.json`](ir/ascent0.ir.json)) and validates against the frozen schema:

```
cue vet ir/ascent0.ir.json ../../schema.cue -d '#NormalizedCMIR'   # exit 0
```

**No `cmc` extension was made; `research/cm-language/surface/` is untouched.**

## Build · run · gates

Stdlib-only OCaml + `dune`; `cue` for the two oracles. Its **own** dune root (shares nothing with the frozen `coh` engine at `src/engine/ocaml`).

| Gate | Command | Result |
|---|---|---|
| build | `dune build` (here) | exit **0** |
| engine unaffected | `dune build` (in `src/engine/ocaml`) | exit **1** — **pre-existing** (`otoml` missing in sandbox), separate build root, **0** references to this project; identical to the Sub-1/Sub-2 finding |
| IR oracle | `cue vet ir/ascent0.ir.json ../../schema.cue -d '#NormalizedCMIR'` | exit **0** |
| run | `dune exec ./bin/ascent0_runner.exe -- run case1` | exit **0**, emits one `MeasurementReceipt` |
| receipt oracle | `cue vet receipt.case1.json contracts/receipt.cue -d '#MeasurementReceipt'` | exit **0** |
| derived category | receipt `result.result_class` | **`LIFT_VALIDATED`**, `computed: true` |
| oracle seal | receipt `oracle_seal` | `ordering_ok: true`, `non_oracle_reveal_accesses: 0` |
| firewall probe | `dune exec ./bin/ascent0_runner.exe -- firewall-selftest case1` | non-oracle **DENIED**, oracle allowed |
| determinism | two `run`s | byte-identical receipts |

`make check` runs all of them. The receipt validates against a **runtime-local** `#MeasurementReceipt` ([`contracts/receipt.cue`](contracts/receipt.cue)) — `schema.cue` explicitly *defers* the full `#RunRequest` / `#MeasurementReceipt` separation to a future `#112` slice, so this cell carries its own receipt contract and does not touch `schema.cue`. That contract is **closed** (a stray field is rejected) and **mirrors** (does not import) the Sub-2 `#ResultClass` vocabulary and the closed five-field `#CompiledView`, so the embedded semantic proposal is re-checked for Firewall A and `result_class` is pinned to the Core-faithful set. Both facts (the contract bites) are shown by the tamper probes in the report.

## Files

```
dune-project, {lib,bin}/dune   own stdlib-only dune root
lib/sha256.ml                  in-tree SHA-256 (FIPS-180-4, self-tested) — oracle commitment check
lib/json.ml                    dependency-free JSON parser + canonical serializer
lib/mealy.ml                   the runtime's OWN bounded Mealy class: enumerate/run/fit/quotient/predict
lib/runtime.ml                 load · resolve RunRequest · link SandboxExecutionPlan · execute DAG ·
                               invoke backends · capture evidence · retain alternatives · evaluate · emit
bin/ascent0_runner.ml          the `run` / `firewall-selftest` CLI
ir/ascent0.ir.json             the hand-authored NormalizedCMIR (vets #NormalizedCMIR)
contracts/receipt.cue          the runtime-local #MeasurementReceipt (vets the emitted receipt)
fixtures/canned_compiled_view_case1.json   the deterministic #CompiledView (no live LLM)
Makefile                       build · run · vet-ir · vet-receipt · firewall · check
```

## Non-goals (explicitly out of this cell — #122 / later)

The other four cases; the blind live-LLM arm; a generic scheduler / authorization / shell / registry / a second CM; calling the artifact a `CompiledCM`; editing the frozen engine, `schema.cue`, the Sub-1 fixture, or the Sub-2 contracts; reading the sealed reveal from any non-oracle path.
