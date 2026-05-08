---
cycle: 26
role: alpha
verdict: A (β round 1)
merge_commit: 5f6dc7ff3f813229c27a3c1736bb24861fa3bbf4
---

# α Close-Out — Cycle 26

**Issue:** Sub 3 (#23) — Migrate tests Python→OCaml; remove all .py  
**Mode:** MCA — P1; multi-surface migration  
**Rounds:** 1 (no RC)  
**β verdict:** A

---

## Summary

Cycle 26 retired all Python test infrastructure: 6 `.py` files deleted, `pyproject.toml` deleted, OCaml test suite extended with `test_auto_mode_fallback` (AC4 surface 8), `Credentials` module extracted from `main.ml` to make the auto-mode fallback branch independently testable. The suite produces 74 PASS lines at `dune runtest` and covers all 8 AC4 surfaces. Six legacy Python test decisions logged with rationale in `self-coherence.md §Legacy test decisions`. All ACs met at R1. No findings at any round.

---

## Findings log

No findings. No D/C/B/A findings across any β review phase. R1 verdict: APPROVED.

---

## Observations

**Single-commit implementation was sufficient for a migration cycle with no new logic.** The full AC surface closed in one commit (`06fb2df`). Migration cycles bounded by deletion of retired artifacts plus extraction of minimal testability surface do not require iteration — the scope is determined by what the deleted layer covered, not by new design decisions. This is the expected commit shape for a pure migration.

**Legacy test drop decisions are the substantive work.** Five of the six Python files were dropped rather than ported. The effort in a migration cycle is auditing whether each legacy test has a mechanical analogue and recording the decision. The decisions table in `self-coherence.md` is the durable artifact; the OCaml code follows once the decisions are made.

**Credentials extraction was the only non-obvious step.** Extracting `Credentials.get_api_key` (4 lines) to enable `test_auto_mode_fallback` required recognizing that `Unix.putenv` needs a named function boundary to test both branches hermetically. Everything else was mechanical deletion and completion of pre-existing scaffold.

---

## Friction log

1. **Stale issue status table** — The issue body stated `engine/ocaml/test/` did not exist. The directory and two test files (`test_coherence.ml`, `test_mechanical.ml`) had been present on main since cycle #24 / v0.6.0. α's self-coherence described actual branch state rather than the stale claim. No AC mapping error resulted.

2. **opam working-tree modification (pre-existing)** — `tsc_engine.opam` carried an uncommitted local modification not on the cycle branch. Same surface noted in cycle #24. Not in scope; β noted as not a finding.

---

## Post-cycle tracked debt

`CONTRIBUTING.md` and `.github/pull_request_template.md` contain stale Python/pytest references (support matrix, `pip install`, `pytest` commands, `reference/python/parsers/` path). Pre-existing; outside issue #26 scope.
