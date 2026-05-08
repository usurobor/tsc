---
cycle: 26
role: alpha
status: final
merge_commit: 5f6dc7ff3f813229c27a3c1736bb24861fa3bbf4
---

# α Close-out — Cycle 26

**Final:** written post-merge per CDD §2.8 re-dispatch path. β approved at R1; merge commit `5f6dc7f`.

---

## Cycle summary

Cycle 26 completes the Python→OCaml test migration: 6 `.py` test files deleted, `pyproject.toml` deleted, OCaml test suite extended with `test_auto_mode_fallback` (AC4 surface 8), and a `Credentials` module extracted from `main.ml` to make the auto-mode fallback branch independently testable.

Artifacts changed: `engine/ocaml/lib/credentials.ml` (new), `engine/ocaml/lib/dune` (modules list), `engine/ocaml/bin/main.ml` (delegate to `Credentials.has_llm_credentials()`), `engine/ocaml/test/test_mechanical.ml` (new test), `engine/ocaml/test/dune` (unix dependency). Six legacy Python files and `pyproject.toml` removed. CI workflow unchanged.

Review: 1 round (R1 APPROVED). No findings.

---

## Review round record

| Round | Verdict | Findings | Head SHA |
|---|---|---|---|
| R1 | APPROVED | None | `06fb2df` (impl) |

---

## Findings log

No findings. All ACs met at R1. No D/C/B/A findings.

---

## Friction log

1. **Stale issue status table** — The issue body's "Status" table stated `engine/ocaml/test/` did not exist. The directory and two test files (`test_coherence.ml`, `test_mechanical.ml`) had been present on main since the cycle #24 / v0.6.0 release. The issue was filed before v0.6.0 shipped. α's self-coherence described the actual branch state ("test/ existed with scaffolded OCaml tests but lacked AC4 surface 8") rather than the stale issue claim. No AC mapping error resulted.

2. **opam working-tree modification (pre-existing)** — `engine/ocaml/tsc_engine.opam` carried an uncommitted local modification (version/formatting) not on the cycle branch. Same surface noted in cycle #24 friction log. Not part of cycle #26 scope; β noted as not a finding.

---

## Patterns

### Pattern 1: issue-body staleness at cycle start

The issue "Status truth" table described a state that had already been superseded by a prior release. The table was not updated between the pre-v0.6.0 filing and the cycle #26 dispatch. α's self-coherence surfaced the discrepancy rather than transcribing the stale claim.

Same class as the post-release issue-body drift noted in cycle #24 (opam file state). Two occurrences across cycles #24 and #26.

### Pattern 2: minimal-surface extraction enabling testability

The `Credentials` module is 4 lines (a single function). The extraction was the minimum surface needed to make the auto-mode fallback branch testable via `Unix.putenv` without a full process invocation. The test correctly drives both branches (env var set / unset) through the extracted function.

---

## Engineering-level reading

- `Unix.putenv "" ""` (the None/unset path in `test_auto_mode_fallback`) is the standard OCaml idiom for unsetting an environment variable. The `unix` library addition to `test/dune` dependencies is required for this; the library was not previously a test dependency.

- AC4 surfaces 1–7 were pre-existing on main from cycle #24. Only surface 8 (auto-mode fallback) was new to cycle #26. The cycle's implementation scope was accordingly narrow: one new test case and one extracted module.

- The six legacy Python test files were: `test_consciousness.py`, `test_emergence.py`, `test_free_will.py`, `test_glider.py`, `test_random_soup.py`, `test_self_coherence.py`. All were philosophical/speculative fixtures with no OCaml counterparts; all were dropped rather than migrated. Rationale logged in self-coherence §Legacy test decisions.

- Post-cycle tracked debt: `CONTRIBUTING.md` and `.github/pull_request_template.md` contain stale Python/pytest references (Python 3.10–3.12 support matrix, `pip install`, `pytest` commands, `reference/python/parsers/` path). Outside issue #26 scope; pre-existing.
