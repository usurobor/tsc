# Self-Coherence — Issue #25
# Sub 2 (#23): Complete v0.5.0 hybrid scoring

## Gap

OCaml engine is LLM-only (`--mode llm` default, credentials required).
`mechanical_scoring.mli` is committed (`ceea066`) but the implementation is absent.
No `--mode` flag. No `--files` flag. No `hybrid_scoring.ml`. No OCaml test scaffolding.
Offline/CI measurement is impossible; Sub 3 (OCaml tests) is blocked.

Design and plan are committed at `docs/design/0.5.0/DESIGN.md` and `docs/design/0.5.0/PLAN.md`.
This cycle completes Plan Steps 1, 3–9.

## Mode

MCA — implementing committed plan against converged design.

## Active Skills

Tier 1a: CDD.md (v3.15.0), alpha/SKILL.md
Tier 1b: cdd/design (already done at docs/design/0.5.0/DESIGN.md), cdd/plan (already done at docs/design/0.5.0/PLAN.md)
Tier 2: OCaml engineering bundle (eng/ocaml)
Tier 3: cnos.core/skills/write (prose quality), cdd/design (reference), cdd/plan (reference)

## Impact Graph

- `engine/ocaml/lib/bundle.ml` — added `type t = target_bundle` and `type file = bundle_file` (Step 1, bundle parity)
- `engine/ocaml/lib/mechanical_scoring.ml` — implements `.mli` contract; 12 structural signals across α/β/γ (Step 3)
- `engine/ocaml/lib/hybrid_scoring.ml` — pure combiner: Mechanical_scoring.result + measure_result → unified hybrid JSON (Step 6)
- `engine/ocaml/lib/report.ml` — `to_json`/`to_text` gain `~mode` parameter; every report now has `"mode"` field (Step 5)
- `engine/ocaml/lib/dune` — added mechanical_scoring and hybrid_scoring to modules list; -w -16 flag
- `engine/ocaml/bin/main.ml` — `--mode {mechanical,llm,hybrid,auto}`, `--files <glob>` (repeatable), mode dispatch, auto fallback (Steps 1, 4, 9)
- `engine/ocaml/test/test_mechanical.ml` — 58 assertions: AC4 bundle parity, AC5 determinism, AC6 schema, AC12 backend preservation (Step 7)
- `engine/ocaml/test/dune` — test stanza
- `engine/ocaml/test/fixtures/report.schema.json` — canonical schema fixture (Step 6)
- `README.md`, `QUICKSTART.md`, `ARCHITECTURE.md` — document all modes and direct-file usage (Step 8)

## Acceptance Criteria — Status

| AC | Description | Status | Evidence |
|----|-------------|--------|---------|
| AC1 | `coh --mode mechanical --files <paths>` works without credentials | ✓ | `main.ml` run_mechanical path; no credential read; dune build passes |
| AC2 | `coh --mode llm --target spec` preserved from v0.4.0 | ✓ | run_llm path unchanged; Report.to_json now takes ~mode:"llm" |
| AC3 | `coh --mode hybrid` produces mechanical+llm+final sub-objects | ✓ | Hybrid_scoring.to_json produces mechanical/llm/final per DESIGN.md §5 |
| AC4 | Direct file input and named target share same `Bundle.t` shape | ✓ | Both call Bundle.build_bundle with same sort; test_bundle_parity passes |
| AC5 | Mechanical scoring is deterministic on identical input | ✓ | test_mechanical_determinism: 6 assertions; score_files is pure |
| AC6 | Canonical JSON schema across modes | ✓ | test_mechanical_json_schema + test_hybrid_json_schema; fixtures/report.schema.json |
| AC7 | README, QUICKSTART, ARCHITECTURE document all modes + direct-file | ✓ | All three docs updated: mode table, --files usage, hybrid report shape |
| AC8 | No Python reintroduced | ✓ (partial) | `git diff main..cycle/25 -- '*.py'` → 0 lines; pre-existing Python in tests/conformance/ owned by Sub 3 — see Known Debt |
| AC9 | LLM backend reads `runtime/SELF-MEASURE.md` | ✓ | `main.ml`: `let instruction = ref "runtime/SELF-MEASURE.md"` is default; run_llm reads it |
| AC10 | Every report contains `mode` field | ✓ | report.ml `to_json ~mode` adds "mode" to JSON; mechanical_scoring `result_to_json` adds "mode":"mechanical"; hybrid `to_json` adds "mode":"hybrid" |
| AC11 | `--mode auto` resolves to mechanical without credentials, hybrid with | ✓ | `has_llm_credentials()` checks LLM_API_KEY; auto dispatch in main.ml |
| AC12 | Hybrid preserves both results; `final.source` named explicitly | ✓ | Hybrid_scoring.result has hyb_mech + hyb_llm; to_json emits both sub-objects + final.source; test_hybrid_preserves_both passes |

## Self-check

**Did α push ambiguity onto β?**

No ambiguity pushed. All 12 ACs have concrete evidence. The one partial AC (AC8) is explicitly scoped: pre-existing Python in tests/conformance/ predates this cycle (`git log` shows last Python commit at c7a9c4f, before cycle/25). This cycle introduces no Python.

**Is every claim backed by evidence in the diff?**

Yes. All implementation files compile (`dune build` passes). All 58 tests pass (`dune exec test/test_mechanical.exe`). The mechanical_scoring.ml types exactly match mechanical_scoring.mli per OCaml's module system enforcement.

**Peer enumeration:** This change touches the report layer (report.ml). The LLM report path (`run_llm`) is audited: it calls `Report.to_json ~result ~metadata ~mode:"llm" ()` — the new signature is backward-compatible via the optional `~mode` parameter. The text path `Report.to_text` is likewise updated. The mechanical and hybrid paths produce independent JSON (not through report.ml).

**Harness audit:** No shell harnesses write report JSON. The test fixture `report.schema.json` is a static JSON document, not a code-generating harness.

## Known Debt

- **AC8 partial**: 6 Python conformance tests in `tests/conformance/` predate this cycle and are NOT reintroduced by it. Removal is owned by Sub 3. `git diff main..cycle/25 -- '*.py'` is zero.
- **v3.2.0 provenance fields**: Sub 1 will add provenance JSON keys to report sub-objects. The unified report shape here accommodates extension: `mechanical` and `llm` sub-objects can gain additional fields without schema breakage.
- **Hybrid adjudication policy**: V1 uses "LLM is authority unless agreement"; future calibration may want a stronger policy. Noted in DESIGN.md §Known Debt.
- **Mechanical score calibration**: Signal weights and scoring functions are V1 structural proxies. A calibration pass will improve accuracy. Not required for closure.
- **Auto mode integration test**: AC11 is verified by code review (has_llm_credentials() reads LLM_API_KEY) but no integration test exercises the credential-absent path. Sub 3 can add this.
- **α close-out**: Written after β merge via re-dispatch per CDD.md §1.6a. Provisional close-out not written here; declared as debt per alpha/SKILL.md §2.8.

## CDD Trace

| Step | Artifact | Skills loaded | Decision |
|------|----------|---------------|----------|
| 0 Observe | — | — | Cycle 2 under master #23; #27 just closed (docs-only). Assessment committed next MCA as #25. |
| 1 Select | issue #25 | CDD.md §3.3 | Assessment commitment default fires: #25 is the named next MCA. |
| 2 Branch | `cycle/25` from `origin/main` (56af43a) | cdd | Pre-flight passed; branch pushed by γ. |
| 3 Bootstrap | — | — | No dedicated bootstrap: design and version dir already exist at docs/design/0.5.0/ from prior cycles. Small-change exemption not needed; docs/design/0.5.0/ serves as the version snapshot. |
| 4 Gap | this file §Gap | cdd | Named: LLM-only engine, no `--mode`, no `--files`, `.mli` without `.ml`. |
| 5 Mode | this file §Mode | cdd, write, design, plan | MCA — implementing committed plan. Tier 3: write, design, plan. |
| 6 Artifacts | `engine/ocaml/lib/`, `engine/ocaml/bin/main.ml`, `engine/ocaml/test/`, docs | ocaml, write | Steps 1,3–9 complete: bundle.ml, mechanical_scoring.ml, hybrid_scoring.ml, report.ml, main.ml, tests, docs |
| 7 Self-coherence | this file | cdd | AC-by-AC evidence mapped above; 58 tests pass; dune build clean. |
| 7a Pre-review | this file §Review-Readiness | cdd | Gate rows checked — see Review-Readiness section below. |
| 8 Review | `.cdd/unreleased/25/beta-review.md` | review | β pending |
| 9 Gate | pending | release | β pending |
| 10 Release | pending | release | β pending |

## Review-Readiness | round 1 | implementation SHA: 71238ec | branch CI: local build green (dune build + dune exec test/test_mechanical.exe — 58/58 pass) | ready for β

Pre-review gate (alpha/SKILL.md §2.6):

1. `origin/cycle/25` rebased onto `origin/main` (56af43a) — branch created from that SHA; no new main commits since dispatch. Verified at 2026-05-08T00:00Z.
2. Self-coherence carries CDD Trace through step 7 — ✓
3. Tests present: `engine/ocaml/test/test_mechanical.ml` — 58 assertions covering AC4, AC5, AC6, AC12. `dune exec test/test_mechanical.exe` → all pass.
4. Every AC has evidence — ✓ (see §ACs)
5. Known debt explicit — ✓ (see §Debt)
6. Schema/shape audit: mechanical_scoring.mli contract unchanged. `report.ml` `to_json` signature extended with optional `~mode` (backward-compat). Hybrid JSON shape validated by test.
7. Peer enumeration: report callers — `run_llm`, `run_mechanical`, `run_hybrid` — all three audited and updated.
8. Harness audit: no shell or CI harnesses generate report JSON. Not applicable.
9. Post-patch re-audit: OCaml (dune build clean) + Markdown (docs reviewed against AC7). No other languages in diff.
10. Branch CI: local build green. Remote CI state unknown — β should wait for green before merge.
11. Git author email: `alpha@cdd.tsc` ✓ (verified via `git log -1 --format='%ae' HEAD`)
