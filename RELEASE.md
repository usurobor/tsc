# RELEASE.md

**Release:** TSC Engine v0.7.0 — Test migration: Python retired, OCaml suite complete
**Issue:** #26 (Sub 3 of master #23)
**Branch merged:** cycle/26-test-migration → main
**Merge commit:** 5f6dc7ff3f813229c27a3c1736bb24861fa3bbf4
**Date:** 2026-05-08

## Outcome

Coherence delta: C_Σ A (`α A`, `β A`, `γ A`) · **Level:** L6

All Python test infrastructure retired. The OCaml test suite now covers all 8 AC4 surfaces (74 PASS lines from `dune runtest`). The `Credentials` module was extracted to make the auto-mode fallback independently testable. `CONTRIBUTING.md` and `.github/pull_request_template.md` carry stale Python/pytest references (known doc debt; filed as MCI).

## What shipped

- **`engine/ocaml/lib/credentials.ml`** (new) — `Credentials` module extracted from `bin/main.ml`: `has_llm_credentials : unit -> bool`. Enables independent testing of the auto-mode fallback branch without process invocation.
- **`engine/ocaml/lib/dune`** (extended) — `credentials` module added to library modules list.
- **`engine/ocaml/bin/main.ml`** (changed) — mode-dispatch now calls `Tsc_engine.Credentials.has_llm_credentials()` instead of the inlined predicate. Behavior identical; no functional change to the binary.
- **`engine/ocaml/test/test_mechanical.ml`** (extended) — `test_auto_mode_fallback` added: drives both auto-mode branches via `Unix.putenv`; completes AC4 surface 8. Total suite: 74 PASS lines.
- **`engine/ocaml/test/dune`** (extended) — `unix` library added to test dependencies.
- **Deleted:** `tests/conformance/test_consciousness.py`, `test_emergence.py`, `test_free_will.py`, `test_glider.py`, `test_random_soup.py`; `tests/self/test_self_coherence.py`; `pyproject.toml`. Legacy decisions logged: 5 Drop (Python-controller-coupled, no mechanical-scorer analogue), 1 Rewrite (self-coherence superseded by `test_coherence.ml` + `test_mechanical.ml`).

## Review summary

Single round. R1 verdict: APPROVED; no findings across all review phases (contract integrity, issue contract, diff/context inspection, architecture check). β pre-merge gate: all 3 rows passed (identity verified, canonical-skill freshness confirmed, merge-test worktree `dune build` + `dune runtest` exit 0).

## Known debt carried forward

- **`CONTRIBUTING.md` / `.github/pull_request_template.md`:** stale Python/pytest references (Support Matrix, `pip install`, `pytest` commands, `reference/python/parsers/` path). Python is now fully retired; these surfaces actively mislead. Filed as doc-cleanup MCI.
- **AC6 end-to-end integration test:** full δ-extraction path through `main.ml` wired but not exercised with a live `LLM_API_KEY`. Carried from cycle #24.
- **Beta derivation from δ values:** engine passes `s_beta` through from LLM unchanged; deterministic derivation deferred. Carried from cycle #24.
- **`alpha/SKILL.md` §2.6 caller-path trace patch (cnos repo):** MCI from cycle #24; not triggered this cycle; remains in backlog.
- **Master #23:** Sub 5 (#28) and Sub 6 (#29) remain open.
