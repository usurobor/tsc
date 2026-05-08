---
cycle: 26
issue: "Sub 3 (#23): Migrate tests Python → OCaml; remove all .py"
branch: cycle/26-test-migration
phase: complete
role: alpha
---

# Cycle 26 — Self-Coherence

**Gap:** `tests/conformance/*.py` (5 files) and `tests/self/test_self_coherence.py` remain tracked despite CHANGELOG v0.1.0 declaring Python retired. `engine/ocaml/test/` existed with scaffolded OCaml tests but lacked AC4 surface 8 (auto-mode fallback). `pyproject.toml` lingered without Python content to justify it. `dune runtest` ran zero tests as of the branch creation (scaffold only).

**Mode:** MCA — P1; multiple surfaces: delete 6 Python files, remove `pyproject.toml`, implement/complete OCaml test suite (8 coverage surfaces), extract `Credentials` module, verify CI (pre-existing).

## §Skills

- Tier 3: `cdd/plan` (operationalize ordered steps), `cdd/review` (β review protocol)

## §ACs

| AC | Status | Evidence |
|----|--------|----------|
| AC1 — No Python in tracked content | **MET** | `git ls-files '*.py'` → 0 rows. All 6 `.py` files removed via `git rm`. |
| AC2 — pyproject.toml removed if no Python remains | **MET** | `git ls-files pyproject.toml` → 0 rows. Removed alongside Python files. |
| AC3 — dune runtest non-empty, exits 0 | **MET** | `dune runtest` exits 0 with 74 PASS lines across `test_mechanical` and `test_coherence`. |
| AC4 — Test coverage of v3.2.0 chain (8 surfaces) | **MET** | All 8 surfaces: (1) δ→φ→D→Coh `test_coherence_link`, (2) L_link `test_l_link`, (3) math/num split `test_aggregate`, (4) W2 ref+spread `test_gauge_witness`, (5) provenance JSON `test_provenance_v320_shape`, (6) bundle parity `test_bundle_parity`, (7) mechanical determinism `test_mechanical_determinism`, (8) auto-mode fallback `test_auto_mode_fallback`. |
| AC5 — CI runs dune runtest | **MET** | `.github/workflows/ci.yml` `Test` step: `opam exec -- dune runtest`; failure fails build (no `\|\| true`). Pre-existing; verified intact. |
| AC6 — Decisions about legacy tests recorded | **MET** | See §Legacy test decisions below. All 6 files logged with rationale. |

## §Legacy test decisions

| File | Decision | Rationale |
|------|----------|-----------|
| `tests/conformance/test_consciousness.py` | **Drop** | Called Python `verify_tsc_plus` controller (retired at v0.1.0). Philosophical framing has no mechanical-scorer analogue. Bundle could be reframed as fixture in a follow-on per issue scope. |
| `tests/conformance/test_emergence.py` | **Drop** | Same as consciousness: Python controller-coupled, no direct OCaml analogue. |
| `tests/conformance/test_free_will.py` | **Drop** | Same rationale. |
| `tests/conformance/test_glider.py` | **Drop** | Conway CA philosophical example; tied to Python controller; no mechanical-scorer test target. |
| `tests/conformance/test_random_soup.py` | **Drop** | Stochastic input would violate the `dune runtest` determinism constraint. Python controller-coupled. |
| `tests/self/test_self_coherence.py` | **Rewrite** | CDD self-coherence sanity check; skipped since v3.0.0 for "term algebra rewrite." Superseded by `test_coherence.ml` (δ→φ→D→Coh chain, L_link, aggregate, W2, provenance) and `test_mechanical.ml` (bundle, determinism, JSON schema, auto-mode fallback). |

**Reframe candidates deferred:** The philosophical example bundles (consciousness, emergence, free-will, glider, random-soup) are candidates for OCaml fixture-based reframing in a follow-on issue, per the issue's stated non-goal.

## §Self-check

- Every AC is backed by an observable artifact: file deletion confirmed by `git ls-files`, test output observed directly from `dune runtest` (74 PASS lines).
- The auto-mode fallback (AC4 surface 8) is tested via `Tsc_engine.Credentials.has_llm_credentials` — the logic was extracted from `bin/main.ml` into the library to make it testable without process invocation. `main.ml` updated to use the library function (behavior identical, no functional change to the binary).
- No ambiguity pushed onto β: every AC has a clear pass/fail artifact.
- `dune runtest` is non-trivially non-empty: 74 PASS lines, not a silent exit 0.

## §Debt

- Philosophical fixture reframing (consciousness, emergence, free-will, glider, random-soup → OCaml bundle fixtures) deferred to a follow-on issue per issue scope.
- AC7 (OOD cutover guard) tested in `test_coherence.ml` — not in issue AC4 list but substantively covers a shipped guard.

## CDD Trace

| Step | Artifact | Skills loaded | Decision |
|------|----------|---------------|----------|
| 0 Observe | — | — | Gap: Python files tracked; OCaml tests scaffolded but incomplete (missing AC4 surface 8); pyproject.toml unjustified; `dune runtest` silent (scaffold only). |
| 1 Select | Issue #26 | — | Selected per CDD §3 (P1; master #23 cannot close while Sub 3 open). Policy drift: CHANGELOG v0.1.0 declares OCaml-only; Python test files remain tracked. |
| 2 Branch | `cycle/26-test-migration` | cdd | Branch created by γ from `origin/main` (be6c098), pre-flight passed. |
| 3 Bootstrap | `.cdd/unreleased/26/self-coherence.md` scaffold | cdd | Scaffold committed by γ at branch creation. |
| 4 Gap | `.cdd/unreleased/26/self-coherence.md` §Gap | — | 6 Python files tracked; no auto-mode fallback test; pyproject.toml unjustified; `dune runtest` silent (scaffold only). |
| 5 Mode | `.cdd/unreleased/26/self-coherence.md` §Mode | cdd, plan, review | MCA — P1 substantial: delete Python tests, complete OCaml test suite (8 surfaces), extract Credentials module, remove pyproject.toml. |
| 6 Artifacts | `engine/ocaml/lib/credentials.ml`, `engine/ocaml/lib/dune`, `engine/ocaml/bin/main.ml`, `engine/ocaml/test/test_mechanical.ml`, `engine/ocaml/test/dune`, `tests/conformance/*.py` (deleted ×5), `tests/self/test_self_coherence.py` (deleted), `pyproject.toml` (deleted) | plan | All surfaces touched and verifiable in diff. |
| 7 Self-coherence | `.cdd/unreleased/26/self-coherence.md` | cdd | AC-by-AC check completed. All 6 ACs met. |
| 7a Pre-review | `.cdd/unreleased/26/self-coherence.md` | cdd | Ready for β. `dune runtest` exits 0 with 74 PASS lines. `git ls-files '*.py'` → 0. CI pre-existing and correct. |
