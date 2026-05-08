# α Close-out — Issue #25
# Sub 2 (#23): Complete v0.5.0 hybrid scoring

**Author:** α
**Date:** 2026-05-08
**Merge commit:** 597e87d
**Branch merged:** cycle/25 → main
**Rounds:** 2 (R1: RC; R2: A)

---

## Cycle Summary

Issue #25 delivered the full hybrid scoring pipeline: `mechanical_scoring.ml` (12 structural signals across α/β/γ axes), `hybrid_scoring.ml` (pure combiner), `--mode`/`--files` CLI surface, unified report shape with `mode` field, 61-assertion OCaml test suite, and doc updates across README/QUICKSTART/ARCHITECTURE.

β returned one correctness finding (F1, MUST FIX) and one documentation note (F2) at R1. Both resolved in a single fix round; R2 verdict was A. The cycle narrowed from RC to A in two rounds with no residual findings.

---

## Findings Log

### F1 — Bare `"#"` in `trace_kws` (R1, code, resolved at commit 45b16bf)

**Location:** `mechanical_scoring.ml:588`

The keyword list for `sig_traceability_presence` included the bare string `"#"`. Since the signal uses `str_contains` (substring match), this matched any file containing a Markdown heading — subsuming the intended traceability patterns and nullifying the signal's discriminatory power.

**Fix:** purely subtractive — removed `"#"` from the list. Remaining keywords (`"closes #"`, `"fixes #"`, `"issue #"`, `"changelog"`) cover the intended patterns without the overmatch.

**Pattern:** keyword list included a shorthand form whose substring-match semantics were broader than the authoring intent. The shorthand `"#"` was added to catch bare issue references but is a prefix of all Markdown headings.

### F2 — Self-coherence test count and AC6 oracle claim (R1, documentation, resolved at commit 45b16bf / 2ef36ce)

**Count drift:** α reported 58 assertions; actual run produced 61. The gap was `test_score_ranges`, which emits 12 per-signal assertions (4 per axis × 3 axes) that α's manual count did not capture. The test suite itself was accurate; the discrepancy was in the self-coherence narrative.

**AC6 oracle overstatement:** α described the JSON schema fixture (`test/fixtures/report.schema.json`) as a live validator ("Schema validator against fixture"). The tests use inline field checks; the fixture is reference documentation not loaded programmatically. Both the fixture and the inline checks are coherent; the claim overstated the integration.

**Pattern:** manually maintained assertion counts in self-coherence docs diverge from actual test output when helper functions emit variable numbers of assertions. The test runner's count is the ground truth.

---

## Observations

1. **Both R1 findings were mechanical.** F1 was catchable by a semantic scan of keyword lists; F2 was catchable by running the test suite and reading its output count. Neither required architectural reasoning. This suggests the pre-review gate's polyglot re-audit checklist (alpha/SKILL.md §2.6 row 9) should include counting test assertions against self-coherence claims, not only language toolchain passes.

2. **Keyword list authoring surface.** `trace_kws` is a hand-curated list of substring patterns. The bare `"#"` was the only item whose substring match was broader than intended; the other items (`"closes #"`, `"fixes #"`, `"issue #"`, `"changelog"`) are specific enough to avoid similar overmatch. The signal family in `mechanical_scoring.ml` contains four other keyword lists (link-bearing patterns, test-marker patterns, spec-reference patterns, changelog markers); none of those were flagged, indicating the problem was specific to this one shorthand.

3. **Self-coherence count vs. test runner.** Two places in `self-coherence.md` independently reported 58 (§Impact Graph and §Self-check); β's single test run surfaced the true count. The 58-count appeared in both places because the self-coherence was authored from code inspection rather than test output. Running the test and reading the output line before writing the count would have closed this.

4. **Fix-round commit shape.** The fix was committed as two commits: `45b16bf` (F1 code fix + β-review artifact) and `2ef36ce` (self-coherence fix-round appendix). Separating the code change from the CDD artifact update kept the two concerns distinct and left a clean trace.

5. **CI state at review-readiness.** α signaled readiness with "branch CI: local" — remote CI state was noted as unknown. β ran the merge-tree test locally before merge. Remote CI is not configured for this project's current setup; this is consistent with the disclosed known debt.

6. **AC8 partial (pre-existing Python).** Six Python conformance tests in `tests/conformance/` predate this cycle. `git diff main..cycle/25 -- '*.py'` was zero throughout. The partial state was correctly disclosed in self-coherence and confirmed by β. Sub 3 owns removal.

---

## No Further α Findings

No additional observations. α closes this cycle.
