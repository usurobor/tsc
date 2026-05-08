# β Close-out — Issue #25
# Sub 2 (#23): Complete v0.5.0 hybrid scoring

**Author:** β
**Date:** 2026-05-08
**Merge commit:** 597e87d
**Branch merged:** cycle/25 → main
**Rounds:** 2 (R1: RC; R2: A)

---

## Review Context

The cycle delivered the full hybrid scoring pipeline for issue #25 (Sub 2 of #23): `mechanical_scoring.ml`, `hybrid_scoring.ml`, `--mode`/`--files` CLI, unified report shape, 61-assertion OCaml test suite, and doc updates across README/QUICKSTART/ARCHITECTURE.

β received a review-readiness signal in `.cdd/unreleased/25/self-coherence.md` at commit `bc9d301`. β reviewed independently against the issue ACs (12 inherited from #22), the diff, and the self-coherence artifact.

### Narrowing pattern across rounds

**R1 (RC):** One correctness finding (F1) and one documentation note (F2). F1 was a semantic inversion: the bare string `"#"` in `trace_kws` caused `sig_traceability_presence` to fire true on every Markdown file containing a heading, nullifying the signal's discriminatory power. F2 was a self-coherence accuracy issue (test count claimed 58, actual 61; AC6 oracle claim overstated the fixture's role). F1 required code change; F2 required self-coherence correction only.

**R2 (A):** Both items resolved cleanly. F1 fix confirmed at `mechanical_scoring.ml:588`. Self-coherence corrected for count (61) and AC6 oracle claim. No new surfaces introduced. 61/61 tests pass on merge tree.

The cycle narrowed from R1 to R2 in a single fix round with no residual findings.

---

## Merge Evidence

| Item | Value |
|---|---|
| Merge commit SHA | 597e87d |
| Branch merged | cycle/25 |
| Merge target | main |
| origin/main SHA at merge | 56af43a3d03427cf739741c278121273d0ce1207 |
| Branch head at merge | 21faaef (β R2 verdict commit) |
| Merge strategy | ort (--no-ff) |
| Merge commit message | `feat(25): Complete v0.5.0 hybrid scoring — mechanical + hybrid + auto modes` + `Closes #25` |
| Pre-merge gate passed | yes (identity: beta@cdd.tsc; skill freshness: origin/main current; merge-tree test: 61/61 pass) |

---

## β-Side Findings

### F1 (R1, MUST FIX, resolved)
**Bare `"#"` in `trace_kws`** — `mechanical_scoring.ml:588`. The bare string was a substring match via `str_contains`, causing the signal to fire true on any file containing a Markdown heading. Signal was a heading-detector, not a traceability-detector. Removed in commit `45b16bf`.

Pattern: signal keyword list included an overly broad term that subsumed the intended patterns. The fix was purely subtractive (remove one item).

### F2 (R1, NOTE, resolved)
**Self-coherence test count and AC6 oracle claim.** α undercounted assertions (58 vs. actual 61 — the `test_score_ranges` function emits per-signal assertions not included in α's manual count). AC6 oracle claim described the JSON schema fixture as a live validator when it is reference documentation; tests use inline field checks. Both corrected in commit `45b16bf` and `2ef36ce`.

Pattern: manually maintained counts in self-coherence docs drift from actual test output. The correction was documentation-only; the test suite itself was accurate.

---

## Observations

1. **Ratio of mechanical to judgment findings:** Both R1 findings were partially mechanical (F1 was catchable by a semantic scan of keyword lists; F2 was catchable by running the test and counting). Neither required architectural reasoning. Mechanical ratio: 2/2 = 100% (small N).

2. **Fix-round shape:** The fix committed as two commits (45b16bf = code + β-review artifact; 2ef36ce = self-coherence fix-round appendix). The separation kept the code change and the CDD artifact update distinct. Clean.

3. **CI state at review-readiness:** α signaled readiness with "branch CI: local (dune build clean; 61/61 pass)" — remote CI state was noted as unknown. β ran the merge-tree test locally (61/61) before merge. Remote CI is out of scope for this project's current setup.

4. **AC coverage:** All 12 ACs from #22 map to evidence. AC8 (no Python) is partial/known — pre-existing Python in `tests/conformance/` is owned by Sub 3, not this cycle. The partial state is correctly disclosed in self-coherence and the β AC table.

---

## No Further β Findings

No additional findings. β closes this cycle with verdict A.
