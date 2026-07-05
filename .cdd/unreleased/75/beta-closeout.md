# β close-out — cycle/75 (factorized-β measurement harness, Sub-2 of #73)

Role: β (reviewer). Identity: `beta@tsc.cdd.cnos`. Branch: `cycle/75`
@ `4775837`. Issue #75 AC1–AC5. Companion: `beta-review.md`.

## Review verdict: **APPROVE**

The factorized-β measurement harness is correct against the FROZEN A/B/C
gate (`CONSISTENCY-FACTORIZATION-PREREG.md` rev 4), self-coherent, and
scoped. Recursive-coherence: **PASS**. All five ACs pass. See
`beta-review.md` for the line-by-line prereg-vs-code check, the per-AC
findings, and my position on α's five unpinned rows (all acceptable /
reversible; none a defect).

## Measured experiment verdict (record only — κ records downstream)

The credentialed CI witness (`factorized-beta-measure` run #2, `2cf60ff`,
conclusion success, all 9 jobs green) produced the terminal token **FAIL**:

- **A0** PASS (yield 3/3 on all 5 applicable targets).
- **A1** MISS — β Coh_consistency below 0.90 on `cm-of-cms, methodology, repo`.
- **A2** MISS — below baseline+0.10 (or baseline absent) on
  `cm-of-cms, methodology, repo, spec`.
- **A3** MISS — locus-verdict agreement below 0.90 on
  `cm-of-cms, methodology, repo`.
- **B1 / B2 / B3** PASS (discrimination retained).
- 4 targets scored, 1 `locus_sparse` (`engine`) → C4 does not fire →
  C5 records **FAILED**.

This is a **real measured result**, not a pipeline/harness artifact: build
green, guards + b3-controls + all five measure jobs + gate succeeded, and the
gate evaluated over the measured per-target records. The FAIL is independently
driven by A1 **and** A3 below floor on three scored held-out targets.

## Merge status

**Not merged by β.** Per the cycle/75 dispatch, **κ performs the actual merge
to `main` and records the FAIL verdict** in the prereg §experiment-record and
the CHANGELOG witness index, then closes #75 → #73. β writes the review +
close-out only. I record no experiment PASS/FAIL here beyond noting the
measured verdict was FAIL (terminal for this factorization line absent a fresh
operator dispatch, per prereg C6).

## Artifacts

| Artifact | Purpose |
|----------|---------|
| `.cdd/unreleased/75/beta-review.md` | full review (APPROVE; recursive-coherence PASS; per-AC; AC3 prereg-vs-code; 5-row positions; FAIL-is-real confirmation) |
| `.cdd/unreleased/75/beta-closeout.md` | this β merge record |

## Handoff to κ

APPROVE. Merge `cycle/75` → `main`; record the measured **FAIL** in the
prereg experiment-record + CHANGELOG witness index; close #75 → #73. No
harness defects to fix. The five α debt rows are surfaced to δ as
acceptable/reversible (no blocker).
