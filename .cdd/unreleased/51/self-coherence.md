# Self-coherence — cycle/51

Sub-issue: #51 — strict v3.2 LLM δ validation + validation_failure artifact
Master wave: #49 (v0.10.0-canonical-v3.2-cutover)
Branch: `cycle/51`
Mode: design-and-build (δ-as-γ single-session dispatch per `.cdd/DISPATCH` §5.2)

## CDD Trace

- Source: #51 (sub-issue of #49 master). 3 ACs enumerated in the issue body.
- Phase 1 — branch + intake: branched from `origin/main`, pushed `cycle/51`
  (intake commit `34341fb`).
- Phase 2 — implementation: single squash-style commit `8c67974` covering
  AC1, AC2, AC3, and tests.
- Phase 3 — close-out: this file + `gamma-closeout.md` + #51 progress
  comment.

## Per-AC evidence

### AC1 — v3.2 response validation requires δ

- Surface: `engine/ocaml/lib/response_schema.ml`
- Status: **implemented** in commit `8c67974`.
- Evidence:
  - New type `v32_validation_error = { missing_fields: string list;
    invalid_fields: (string * string) list }`.
  - New constant `v32_required_delta_fields` = `["delta_alpha_beta";
    "delta_beta_gamma"; "delta_gamma_alpha"]`.
  - New `classify_v32_delta key json` returns `` `Missing ``,
    `` `Invalid of string `` (observed value rendered), or
    `` `Valid of float ``.
  - New `validate_v32_deltas json` returns `Ok (d_ab, d_bg, d_ga)` on
    full validity, else `Error v32_validation_error` with the **full**
    list of offenders (no short-circuit) so the artifact can report
    them all at once.
  - New `format_v32_validation_error err` renders a single-line stderr
    message that names missing and invalid fields with observed values.
  - Legacy `extract_deltas` is preserved (no callers regressed) but its
    docstring now points new strict callers at `validate_v32_deltas`.
- Tests: `engine/ocaml/test/test_response_schema.ml` (new module wired
  via `engine/ocaml/test/dune`). Cases:
  - positive — three floats in `[0, 1]` → `Ok`
  - positive — integer `0` and `1` at the boundaries → `Ok`
  - negative — missing `delta_beta_gamma` → `Error` naming it
  - negative — all three missing → `Error` with all three named
  - negative — `delta_alpha_beta = 1.5` → `Error` with observed value
    in `invalid_fields`
  - negative — negative δ value rejected
  - negative — string-valued δ rejected
  - negative — mixed missing + invalid populates both lists

### AC2 — validation failures write durable artifact and exit non-zero

- Surface: `engine/ocaml/bin/main.ml` (`run_llm`, `run_hybrid`).
- Status: **implemented** in commit `8c67974`.
- Evidence:
  - New helper `write_validation_failure_artifact ~output_dir ~target
    ~ts ~err` emits exactly the JSON shape specified by #51 AC2 with
    fields `kind`, `schema = "tsc-llm-response/v3.2"`, `status =
    "error"`, `missing_required_fields`, `invalid_fields`, and the
    canonical `message` string.
  - The `invalid_fields` array entries are `{ field, observed_value,
    expected_range: "[0, 1]" }` so the artifact carries the observed
    value, not just the field name.
  - `run_llm` now writes the raw response to
    `tsc-<target>-<ts>-raw.txt` **before** any validation step (so the
    raw is preserved on every failure mode). On JSON parse failure,
    schema-validation failure, or strict v3.2 δ failure it logs the
    cause to stderr and `exit 1`s without rendering
    `tsc-<target>-<ts>.json` or `tsc-<target>-<ts>.txt`.
  - `run_hybrid` is wired identically: raw saved unconditionally; on
    any post-provider validation failure it writes the
    validation-failure artifact and `exit 1`s without rendering the
    hybrid report.
  - Successful runs (all three δ values present and in `[0, 1]`) pass
    `Some d` triples to `Report.to_json` so the v3.2 δ provenance
    fields are no longer back-filled from `None`.

### AC3 — no post-response mechanical fallback

- Surface: `engine/ocaml/bin/main.ml`.
- Status: **implemented** in commit `8c67974` (the existing structure
  already satisfied AC3; the commit makes the invariant explicit and
  removes the prior silent `exit 0` fall-through after validation
  failure in `run_llm`).
- Evidence:
  - Entrypoint comment recorded directly above the `match args.cli_mode
    with Auto -> …` block: "auto-mode mechanical selection is
    PRE-PROVIDER ONLY. Once we enter run_llm / run_hybrid below and
    issue a provider call, any post-response failure is terminal and
    never falls back to mechanical scoring."
  - In both `run_llm` and `run_hybrid`, every error path under
    `Response_schema.parse_json` / `validate_result` /
    `validate_v32_deltas` calls `exit 1` and never invokes
    `Mechanical_scoring`.

## Known debt

- **No OCaml toolchain in this sandbox.** Code changes are not compiled
  or test-run in-cycle. β R1 must execute `cd engine/ocaml && dune
  build && dune runtest` to verify the AC1 test module passes and the
  new code typechecks.
- **Hard blocker on push.** From 17:07 UTC onward this session's git
  proxy (`http://127.0.0.1:33539/git/usurobor/tsc`) has rejected every
  `git-receive-pack` POST with `HTTP/1.1 403 Forbidden` regardless of
  commit content, author identity, signing status, or wait interval.
  The intake commit `34341fb` was pushed successfully at 17:06:24; the
  subsequent implementation commit `8c67974` is held locally only.
  Details and recovery hooks for δ are in `gamma-closeout.md`.
- All other constraints inside scope.

## Non-goals (carried from issue)

- Provider envelope redesign.
- Operational verdict logic.
- Non-δ response-schema expansion.
- Post-response mechanical recovery.
