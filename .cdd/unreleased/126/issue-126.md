# Issue usurobor/tsc#126

**Title:** coh-min: execute example.readme-present end to end (M2/M3 standalone runtime tracer)

## Gap

Today no TSC path *executes* an ordinary CM. The surface compiler emits IR and CUE validates it, but nothing runs the providers a `.cm` names — "the runtime (future) — nothing runs them yet" (`DIRECTION.md` §6). The Ascent-0 runtime executes the *hard* case only. We need the smallest thing that runs an **ordinary** CM end to end, to anchor the portable-runtime kernel (roadmap M2) and prove execution beats static validation (roadmap M3).

## Governing question

Can a minimal standalone runtime load a NormalizedCMIR, link a plan, invoke a **real** provider against a subject, and emit a `MeasurementReceipt` whose result **changes with the subject** — with no live CNOS control plane?

## Scope

Build `research/cm-language/runtime/coh-min/`: the ordinary-CM side of the two-sided kernel. One CM, `example.readme-present`; one provider, `file.exists`. Harvest the JSON serializer, SHA-256, and the link/execute/emit skeleton from the Ascent-0 runtime; **no** oracle, sealed reveal, or model enumeration.

Path: `load NormalizedCMIR → link SandboxExecutionPlan → execute finite provider DAG by input readiness → invoke provider backend → derive result → emit canonical MeasurementReceipt`.

## Acceptance criteria (executable oracle)

1. `dune build` succeeds under OCaml 5.2, stdlib-only (no opam deps).
2. Running against `fixtures/present/` (has `README.md`) yields a receipt with `result.result_class == "README_PRESENT"`.
3. Running against `fixtures/absent/` (no `README.md`) yields `result.result_class == "README_ABSENT"`.
4. The two receipts are **not** byte-identical (fixture-sensitivity: a real provider read the disk).
5. Both receipts validate: `cue vet <receipt> contracts/receipt.cue -d '#MeasurementReceipt'`.
6. The provider enforces path confinement (a `relative_path` escaping the subject root is denied) — the portable fail-closed invariant.
7. A `make gate` target runs 1–5 and fails loudly on any violation; CI (`.github/workflows/coh-min.yml`) is green on the cycle branch.

Static IR validation does **not** satisfy any of AC 2–4; only a real run does.

## Evidence required to close

The green `coh-min` CI run on the cycle branch, plus the two receipts (present/absent) attached or reproduced in `self-coherence.md`.

## Non-goals

- Not the production `coh cm run` (this is the tracer that becomes it).
- Not a general provider set — `file.exists` only.
- Not cmc-emitted IR — the IR is hand-authored, exactly as the Ascent-0 IR is today.
- Not the M1 shared-contract unification with the Ascent-0 receipt (separate step); `tsc-measurement-receipt/0.1` is the ordinary-CM projection.

## Implementation contract (pinned by δ; α MUST NOT improvise)

| Axis | Pin |
|---|---|
| Language | OCaml, **stdlib-only** (no yojson/menhir/ppx/unix); vendor `json.ml` + `sha256.ml` from the Ascent-0 runtime verbatim. |
| CLI integration target | A standalone `coh_min` executable (`run --ir <ir.json> --target <subject-dir> [--out <path>]`). NOT wired into the released `coh` engine; NOT `coh cm` yet. |
| Package scoping | New build root `research/cm-language/runtime/coh-min/` with its own `dune-project`; shares no code with `src/engine/ocaml` or the Ascent-0 project. |
| Existing-binary disposition | Additive; touches no existing binary, schema, or example. |
| Runtime dependencies | None beyond the OCaml stdlib for build/run; `cue` only in the CI gate (fetched binary). |
| JSON/wire contract | Emit canonical JSON (lexicographic keys, 2-space indent, LF, trailing newline — the Ascent-0 serializer's form). Receipt `format: tsc-measurement-receipt/0.1`. |
| Backward-compat invariant | No change to `main`'s current artifacts; the whole slice is new files under the new directory + one new workflow. |

## Notes for α

An off-protocol spike exists on branch `claude/tsc-recent-changes-onfjpj` (verified building/running under `ocamlopt` locally) that you MAY consult as a reference for shape, but you author the real artifact fresh on the cycle branch under this contract. β reviews the diff against this contract, not the spike.
