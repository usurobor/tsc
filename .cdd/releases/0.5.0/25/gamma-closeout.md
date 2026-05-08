# γ Close-out — Issue #25
# Sub 2 (#23): Complete v0.5.0 hybrid scoring

**Author:** γ
**Date:** 2026-05-08
**Version:** 0.5.0
**Merge commit:** 597e87d
**Branch merged:** cycle/25 → main
**Rounds:** 2 (R1: RC; R2: A)

---

## Cycle Summary

Issue #25 completed the v0.5.0 hybrid scoring pipeline: `mechanical_scoring.ml` (12 structural signals across α/β/γ axes), `hybrid_scoring.ml` (pure combiner), `--mode`/`--files` CLI, unified report shape with `mode` field, 61-assertion OCaml test suite, and doc updates across README/QUICKSTART/ARCHITECTURE.

β returned one correctness finding (F1: bare `"#"` in `trace_kws` semantically inverted the traceability signal) and one documentation note (F2: test count drift + AC6 oracle overstatement) at R1. Both resolved in a single fix round; R2 verdict A. The cycle narrowed RC → A in 2 rounds with no residual findings.

All 12 ACs from #22 map to evidence. AC8 (no Python) is partial by design — pre-existing Python in `tests/conformance/` is owned by Sub 3.

---

## Close-out Triage Table

| Finding | Source | Type | Disposition | Artifact / commit |
|---------|--------|------|-------------|-------------------|
| F1: bare `"#"` in `trace_kws` — semantic inversion of traceability signal (substring match fired on every Markdown heading) | β R1 | mechanical (keyword-list semantics) | Resolved in-cycle | `mechanical_scoring.ml:588`; commit `45b16bf` |
| F2: self-coherence assertion count claimed 58, actual 61; AC6 oracle claim overstated fixture role | β R1 | mechanical (doc accuracy) | Resolved in-cycle | `self-coherence.md`; commits `45b16bf` + `2ef36ce` |
| AC8 partial: pre-existing Python in `tests/conformance/` (6 files, 0 lines added this cycle) | α known debt | feature gap (deferred by design) | Deferred — Sub 3 owns Python removal | See §Deferred Outputs |
| Loaded-skill miss: alpha/SKILL.md §2.6 row 9 does not include test-assertion count check vs. self-coherence | α O1 / γ assessment | process (skill gap) | Next MCA committed — patch alpha/SKILL.md §2.6 row 9 | See §Deferred Outputs |

---

## §9.1 Trigger Assessment

| Trigger | Threshold | Fired? | Evidence | Disposition |
|---------|-----------|--------|----------|-------------|
| Review rounds > 2 | rounds > 2 | No | 2 rounds (R1 RC → R2 A in one fix round) | — |
| Mechanical ratio > 20% AND total findings ≥ 10 | ratio > 20% AND N ≥ 10 | No (N < 10) | 2/2 = 100% mechanical; N = 2 — below ≥10 threshold, ratio is noise | Note only: 100% mechanical ratio at N=2; no filing required |
| Avoidable tooling/environmental failure | any cycle-blocking tooling gap | No | No tooling blockage this cycle | — |
| Loaded-skill miss | a loaded skill should have prevented a finding but did not | Yes | F2 (test count discrepancy) catchable by a check not currently in alpha/SKILL.md §2.6 row 9 — α O1 names the gap explicitly | Next MCA: patch alpha/SKILL.md §2.6 row 9 (owner: γ, first AC defined below) |

**Loaded-skill miss — detail.** F2 (self-coherence assertion count 58 vs. actual 61) would have been prevented by running the test suite and comparing its output count against the self-coherence claim before signaling review readiness. alpha/SKILL.md §2.6 row 9 (polyglot re-audit) specifies running the matching toolchain for each language in the diff but does not name test-assertion count verification as a required step. This is a skill gap (underspecified), not an application gap. The correction is clear: add a test-count check to row 9. Patching requires a commit to the cnos repo (`cnos/src/packages/cnos.cdd/skills/cdd/alpha/SKILL.md`). Committed as next MCA below.

F1 (bare `"#"` in `trace_kws`) was also mechanical and catchable by semantic review of keyword lists. §2.6 row 9 specifies full-language re-audit; the failure was not applying semantic review of keyword-list semantics. This is an application gap — the skill was right, α did not follow it to the required depth. No skill patch needed for F1.

---

## Cycle Iteration

No formal §9.1 trigger fired requiring cycle iteration (rounds = 2 ≤ 2; mechanical ratio N < 10 = noise; no tooling failure). Independent γ process-gap check (gamma/SKILL.md §2.9) finds one actionable gap: the loaded-skill miss described above. Committed as next MCA. No further cycle iteration required.

---

## Skill Gap Candidate Dispositions

| Skill gap | Detected via | Disposition |
|-----------|-------------|-------------|
| alpha/SKILL.md §2.6 row 9 — no test-assertion count verification step | α O1: "running the test and reading the output line before writing the count would have closed this" | Next MCA: cnos — patch alpha/SKILL.md §2.6 row 9 to add: for each test runner in the diff, run the suite and verify output assertion count matches self-coherence claim. Owner: γ. First AC: row 9 names running the test suite and verifying its output count against the self-coherence claim as a required step before signaling review readiness. |
| alpha/SKILL.md §2.6 row 9 — keyword-list semantic review not named | α O2 / β O1: F1 catchable by semantic scan | Application gap, not skill gap. §2.6 row 9 specifies full-language OCaml re-audit; deep semantic review of keyword-list entries is within scope. No skill patch needed. |

---

## Deferred Outputs

| Output | Owner | Source | First AC / Evidence |
|--------|-------|--------|---------------------|
| AC8: Python removal from `tests/conformance/` (6 files) | Sub 3 (master #23) | AC8 partial | `git ls-files '*.py'` returns empty |
| v3.2.0 provenance JSON keys in report sub-objects | Sub 1 (master #23) | Known debt | Mechanical and LLM sub-objects carry v3.2.0 provenance fields |
| `--mode auto` integration test (credential-absent path) | Sub 3 | α known debt | Integration test exercises auto fallback without `LLM_API_KEY` |
| alpha/SKILL.md §2.6 row 9 — test-assertion count check | γ (cnos repo) | Loaded-skill miss | Row 9 names test-runner assertion-count verification against self-coherence claim |
| Hybrid adjudication policy calibration | future cycle | DESIGN.md §Known Debt | V1 average policy reviewed against measurement data |
| Mechanical score calibration pass | future cycle | DESIGN.md §Known Debt | Signal weights calibrated against reference corpus |

---

## Hub Memory Evidence

Hub memory not updated in this γ session — γ operating in tsc workspace without hub repo access. The cycle record is complete in the tsc repo: gamma-closeout.md, RELEASE.md, POST-RELEASE-ASSESSMENT.md, CHANGELOG.md v0.5.0 row, VERSION updated to 0.5.0, cycle dir moved to `.cdd/releases/0.5.0/25/`. Next γ session with hub access should update the daily reflection and adhoc thread for issue #23 master.

---

## Next MCA

**Next:** #23 Sub 3 — Python test migration, `tests/conformance/` cleanup, OCaml integration tests.
**Owner:** to be assigned via γ dispatch.
**Branch:** pending — γ creates `cycle/<N>` from `origin/main` before dispatch.
**First AC:** `git ls-files '*.py'` returns empty.
**MCI frozen?** No — lag is balanced after v0.5.0 ship. Sub 1 (v3.2.0 provenance) and Sub 5 (Claude CLI) remain design-committed. Sub 3 is selected as next because AC8 debt is the most concrete closure criterion and Sub 3's mechanical foundation (now in place) enables OCaml-only conformance tests.

---

Cycle #25 closed. Next: #23 Sub 3.
