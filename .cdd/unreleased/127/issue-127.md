# Issue usurobor/tsc#127

**Title:** coh-min: consume schema-compliant NormalizedCMIR and enforce it in the gate (case 0)

## Gap

`coh-min` (#126) executes a methodology end to end, but the artifact it executes is **not** the project's canonical IR. Demonstrated:

```
$ cue vet runtime/ascent-0/ir/ascent0.ir.json schema.cue -d '#NormalizedCMIR'
  exit 0                                                    # ascent-0 conforms

$ cue vet runtime/coh-min/examples/readme-present/ir/readme-present.ir.json schema.cue -d '#NormalizedCMIR'
  receipt_contract.kind: incomplete value string
  exit 1                                                    # coh-min does NOT
```

The IR omits the required `result_contract` and `receipt_contract` blocks, so it is a private JSON shape that only `coh-min` understands. Nothing caught this because **`coh-min`'s gate never vets the IR** — it validates only the emitted receipt. #126's contract said the IR was hand-authored "exactly as the Ascent-0 IR is today"; the hand-authored part held, the *conforming* part did not.

This is the load-bearing repair before any further cases: every subsequent CM we hand-author must be schema-valid, and the schema must be enforced mechanically, or the drift repeats and compounds.

## Governing question

Does `coh-min` accept a **schema-compliant `#NormalizedCMIR`** as its input, and does the build refuse any IR that is not?

## Scope

Repair the readme-present case to canonical form and wire the enforcement. Deliberately **not** in scope: the surface compiler (`.cm` → IR) — the compiler is correctly deferred until the runtime target stops moving; and any tightening of `schema.cue`'s run-side stub (a later case, driven by the next step kinds).

## Acceptance criteria (executable oracle)

1. `cue vet examples/readme-present/ir/readme-present.ir.json ../../schema.cue -d '#NormalizedCMIR'` exits 0. The escape IR (`readme-present.escape.ir.json`) conforms too — a negative fixture is not excused from the schema.
2. A `make vet-ir` target performs (1) for **every** IR under `examples/`, and `make gate` depends on it, and the CI workflow runs it. A non-conforming IR must fail the gate loudly.
3. No regression: present → `README_PRESENT`, absent → `README_ABSENT`, receipts differ, both receipts still `cue vet` against `#MeasurementReceipt`, escape IR still denied fail-closed (exit 1, no receipt).
4. The result-class **vocabulary is read from the IR** (`result_contract`), not hardcoded as OCaml string literals: a receipt's `result_class` must be one the IR declares, and the runner fails closed if the derived class is not in the IR's declared set. (The *derivation* stays in OCaml — `ascent-0`'s `derivation` field is prose, and machine-executable derivation is out of scope here.)
5. An IR missing a required canonical block fails closed: exit 1, no receipt, clean `IR error`-class message. Pinned by regression tests.
6. `dune runtest` passes with the new regressions added to the existing suite.
7. `readme-present.cm` no longer implies a compile path that does not exist. `cmc` rejects it today (`expected "cm", got identifier "methodology"`). Either express it in the real surface grammar (see `LANGUAGE.md` §`cm <name> v<ver> ( <params> ) -> <ReceiptType>`), or rename it so no reader or tool mistakes it for compilable source, with a header stating the IR is the authoritative executable artifact.

## Reference: a conforming IR

`runtime/ascent-0/ir/ascent0.ir.json` validates. Its top-level keys are `format, cm_id, cm_version, source_digest, input_contract, procedure, result_contract, receipt_contract`; `result_contract` carries `kind`, `subcontracts`, `runtime_binding`, `emits`, and a prose `derivation`; `receipt_contract` carries `kind`, `reports`, `measure_only`. Model the readme-present blocks on these — do not copy Ascent-specific fields that have no meaning for an ordinary CM.

## Evidence required to close

Green `coh-min` CI on the cycle branch (now including `vet-ir`), plus the `cue vet … -d '#NormalizedCMIR'` exit-0 transcript for both IRs reproduced in `self-coherence.md`.

## Implementation contract (pinned by δ; α MUST NOT improvise)

| Axis | Pin |
|---|---|
| Language | OCaml, **stdlib-only** (no yojson/ppx/unix). `json.ml`/`sha256.ml` stay **byte-identical** to `../ascent-0/lib/` — do not touch them. |
| CLI integration target | The existing `coh_min` executable and its flags are unchanged. Not `coh cm` yet. |
| Package scoping | Changes confined to `research/cm-language/runtime/coh-min/**` and `.github/workflows/coh-min.yml`. |
| Existing-binary disposition | Additive/repair only; no other binary, schema, or example touched. **Do not edit `research/cm-language/schema.cue`** — conform to it, do not bend it. |
| Runtime dependencies | None beyond the stdlib at build/run; `cue` used only in the Makefile/CI gates. |
| JSON/wire contract | Canonical JSON output unchanged; receipt `format: tsc-measurement-receipt/0.1` unchanged. IR gains the canonical blocks; `format: tsc-cm-ir/0.1` retained. |
| Backward-compat invariant | All #126 acceptance criteria continue to hold; the receipt's observable shape does not regress. |
