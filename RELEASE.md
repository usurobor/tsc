# RELEASE.md

**Release:** TSC Engine v0.5.0 — Hybrid Scoring
**Issue:** #25 (Sub 2 of master #23)
**Branch merged:** cycle/25 → main
**Merge commit:** 597e87d
**Date:** 2026-05-08

## Outcome

Coherence delta: C_Σ A (`α A`, `β A`, `γ A`) · **Level:** L6

The OCaml engine now has three measurement modes — `mechanical`, `llm`, `hybrid` — plus an `auto` default that picks `hybrid` when credentials are present, else `mechanical`. Offline and CI measurement are unblocked: `coh --mode mechanical --files <paths>` requires no network or credentials. Every report carries a top-level `mode` field. Hybrid mode produces `mechanical`, `llm`, and `final` sub-objects in one JSON output, preserving both backends without blurring them.

## What shipped

- **`engine/ocaml/lib/mechanical_scoring.ml`** — 12 structural signals across α/β/γ axes (pattern, relational, process), implementing the `.mli` contract from cycle #22.
- **`engine/ocaml/lib/hybrid_scoring.ml`** — pure combiner; LLM is authority unless both backends agree; `final.source` named explicitly.
- **`engine/ocaml/lib/bundle.ml`** — `type t` + `type file`; direct file input (`--files <glob>`) shares the same `Bundle.t` as named targets (bundle parity).
- **`engine/ocaml/bin/main.ml`** — `--mode {mechanical,llm,hybrid,auto}` + `--files <glob>` (repeatable) CLI surface; `auto` fallback reads `LLM_API_KEY`.
- **`engine/ocaml/lib/report.ml`** — `to_json ~mode` adds `"mode"` to every report output.
- **`engine/ocaml/test/test_mechanical.ml`** — 61 assertions covering bundle parity (AC4), determinism (AC5), JSON schema shape (AC6), hybrid backend preservation (AC12).
- **`engine/ocaml/test/fixtures/report.schema.json`** — canonical report schema fixture (reference documentation).
- **`README.md`, `QUICKSTART.md`, `ARCHITECTURE.md`** — document all modes and direct-file usage.

## Review summary

Two rounds. R1: one correctness finding (bare `"#"` in `trace_kws` caused traceability signal to fire on every Markdown heading — semantic inversion fixed by removing the overly broad keyword) and one documentation note (assertion count 58 vs. actual 61; AC6 oracle claim corrected). R2: approved. Single fix round; no residual findings.

## Known debt carried forward

- **AC8 partial:** pre-existing Python in `tests/conformance/` predates this cycle — Sub 3 owns removal.
- **v3.2.0 provenance fields:** Sub 1 will extend `mechanical` and `llm` sub-objects with v3.2.0 provenance JSON keys; the unified report container accommodates extension without re-engineering.
- **Mechanical score calibration:** V1 uses structural-proxy signal weights; a calibration pass is deferred.
- **Hybrid adjudication policy:** V1 average policy; future calibration may introduce weighted adjudication.
- **`--mode auto` integration test:** credential-absent path verified by code review; an automated integration test is deferred to Sub 3.
