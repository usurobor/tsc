# β close-out — cycle/74 (factorized-β implementation)

Role: β (review + merge). Identity: `beta@tsc.cdd.cnos`.
Sub-issue: #74 — factorized-β implementation cell. Master: #73.
Verdict: **APPROVE** (see `beta-review.md`). Merged to `main` as **Sub-1 completion only** — this cell is the implementation substrate, **not** the verdict cell.

## What merged

The factorized-β engine substrate: deterministic β locus inventory + the three enumerators (`citation_bears_claim`, `authority_claim`, `target_file_fit`), the exact `β_factorized` aggregation, response validation, the B3 typed-fixture gate, and the tests — `engine/ocaml/lib/factorized_beta.{ml,mli}`, `mechanical_scoring.mli` (visibility only), dune wiring, `test/test_factorized_beta.ml`.

## Merge basis (mechanical proof)

- **β review:** APPROVE; recursive-coherence PASS vs frozen prereg rev 4 (zero mismatches, 7-locus id sequence hand-traced); no defects.
- **CI green** on the reviewed head: `ci` (dune build + runtest) = success; `CDD Artifact Validate` = success.
- **AC1–AC7** satisfied (AC7 in its checkable half — the typed fixture gate; `jq -e .` clean).
- **AC8/AC9/AC10** correctly **deferred** — the A/B/C measurement + PASS/FAIL/NO-DECISION belong to Sub-2, not here.
- The four α unpinned rows accepted as bounded/reversible (operator-ratified).
- Note: the old scalar `tsc-self-measure` run on the branch is **not** the merge gate and **not** the factorized-β verdict surface; it is the pre-existing scalar witness whose consistency variance is expected.

## Frozen-authority integrity

The frozen prereg (`CONSISTENCY-FACTORIZATION-PREREG.md`) and B3 fixtures were **not** edited. The α/γ scalar path is untouched; `Coherence.phi` is reused, not re-implemented.

## Explicitly NOT recorded here

**No PASS / FAIL / NO-DECISION.** The verdict is downstream in Sub-2 (the measurement harness: per-locus prompts → k=3 witnesses per held-out target → `β_factorized` → consistency → A/B/C gate). κ-as-γ records the terminal verdict in the prereg + CHANGELOG once Sub-2 lands it.

## Cycle status

Implementation substrate: **complete + merged**. #74 stays open until Sub-2 lands the measurement verdict (per master #73 closure condition), unless the project closes implementation and measurement as separate subs under #73.
