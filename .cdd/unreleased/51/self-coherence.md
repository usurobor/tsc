# Self-coherence — cycle/51

Sub-issue: #51 — strict v3.2 LLM δ validation + validation_failure artifact
Master wave: #49 (v0.10.0-canonical-v3.2-cutover)
Branch: `cycle/51`
Mode: design-and-build (δ-as-γ single-session dispatch per `.cdd/DISPATCH` §5.2)

## CDD Trace

- Source: #51 (sub-issue of #49 master). 3 ACs enumerated in the issue body.
- Phase 1 — branch + intake: branched from `origin/main`, pushed `cycle/51`.
- Phase 2 — implementation:
  - AC1 — strict v3.2 δ validation entry point in `response_schema.ml`.
  - AC2 — `run_llm` / `run_hybrid` failure path writes
    `tsc-{target}-{ts}-validation-failure.json`, preserves raw, exits non-zero.
  - AC3 — no post-response mechanical fallback; auto-mode mechanical only
    selects before any provider call (already true on `main`, verified).
- Phase 3 — close-out: this file + `gamma-closeout.md` + progress comment.

## Per-AC evidence

(filled in during/after implementation; final SHA recorded in
`gamma-closeout.md`)

### AC1 — v3.2 response validation requires δ

- Surface: `engine/ocaml/lib/response_schema.ml`
- Status: pending
- Evidence: new `validate_v32_deltas` function; tests in
  `engine/ocaml/test/test_response_schema.ml`.

### AC2 — validation failures write durable artifact and exit non-zero

- Surface: `engine/ocaml/bin/main.ml` (`run_llm`, `run_hybrid`)
- Status: pending
- Evidence: artifact path + JSON shape per issue body; raw preserved; no
  coherence report.

### AC3 — no post-response mechanical fallback

- Surface: `engine/ocaml/bin/main.ml`
- Status: pending
- Evidence: failure path in `run_llm` / `run_hybrid` exits directly; auto-mode
  mechanical branch executes pre-provider only (lines 616-625 of `main.ml`
  pre-edit).

## Known debt

- **No OCaml toolchain in this sandbox.** Code changes are not compiled or
  tested in-cycle; β R1 must run `cd engine/ocaml && dune build && dune
  runtest`. Documented per dispatch instructions.
- All other constraints inside scope.

## Non-goals (carried from issue)

- Provider envelope redesign.
- Operational verdict logic.
- Non-δ response-schema expansion.
- Post-response mechanical recovery.
