---
cycle: 24
role: beta
artifact: beta-closeout
merge_commit: 36d0fe5125b12d1e03a20fef52c6512b7d819627
---

# Cycle 24 — β Close-out

## Merge evidence

| Field | Value |
|---|---|
| Merge commit | `36d0fe5125b12d1e03a20fef52c6512b7d819627` |
| Merge message | `feat(24): TSC spec v3.2.0 OCaml engine — barrier transform, L_link, math/num split, W2 ref+spread, provenance JSON, SELF-MEASURE rewrite` |
| Closes | #24 |
| Base (origin/main pre-merge) | `52d03873570b31971fed0bb106903fa200a0087d` |
| Cycle branch | `cycle/24-v320-engine` |
| Branch head at merge | `9c312a0` (R3 verdict commit; last implementation commit: `b6c15dc`) |
| Pushed to | `origin/main` |
| Branch state | merged; not yet deleted (δ/γ handles cleanup) |

## Review context

Three rounds. R1 and R2 returned RC; R3 approved.

| Round | Verdict | Findings | Head SHA |
|---|---|---|---|
| R1 | REQUEST CHANGES | F1 (C), F2 (C), F3 (B), F4 (A); opam note | `bbb681d` |
| R2 | REQUEST CHANGES | F5 (C) — F1/F2/F4 resolved; F3 partially resolved, introduced F5 | `d5c3545` |
| R3 | APPROVED | F5 resolved | `3828d08` (impl: `b6c15dc`) |

### Narrowing pattern across rounds

**R1 findings (4):** Two integration-wiring gaps (F1: main.ml not calling `extract_deltas`; F2: `gauge_witness` not called from `provenance_v320`); one doc/behavior inconsistency (F3: LLM instructed to compute `beta_preview ≈ exp(…)` — a Coh approximation); one label error (F4: Coh values labeled "delta=" in test output).

F1 and F2 share a root: new functions were implemented and tested in isolation but not wired into the end-to-end call path. Both functions existed in the codebase with no non-test callers. The self-coherence AC coverage tables listed them as "done" based on the function existing, not based on the function being called from the entry point.

**R2 findings (1):** F3 was fixed by removing the `beta_preview` formula, but the replacement text in SELF-MEASURE.md §3.3 made a new false claim: "engine derives beta from per-pair δ values deterministically." Traced against the code: the engine passes `result.result_beta` through from `validate_result` without derivation. The `validate_result` docstring in `response_schema.ml` was updated in the same commit and repeated the false claim.

F5 is a contract finding: a doc claim about engine behavior was written before verifying the engine actually implements that behavior. The claim originated in the fix for F3 (removing beta_preview), where the desired future behavior was described in the present tense.

**R3 (resolution):** α chose Option A (doc truthfulness): SELF-MEASURE.md §3.3 corrected to instruct LLM to provide `beta = s_beta` (real score ∈ [0,1]); `validate_result` docstring corrected to accurately describe LLM-provided vs. engine-computed fields. No false claims remain on any operator-visible surface.

## β-side findings

### Finding 1: Integration wiring gaps reached review (F1, F2)

**Pattern:** New modules (`coherence.ml`, `lipschitz.ml`) were implemented, tested, and declared "done" in self-coherence AC tables, but not wired into the runtime call path (`main.ml`, `report.ml`). The test coverage was real but exercised functions in isolation. The AC evidence rows described the function's behavior, not whether the function was reachable from the engine entry point.

**Surfaces affected:** `main.ml` (F1: `extract_deltas` not called), `report.ml::provenance_v320` (F2: `gauge_witness` not called). Both fixed in R1→R2 fix round.

### Finding 2: Write-before-verify produced a false contract claim (F5)

**Pattern:** The fix for F3 (removing `beta_preview`) replaced one incoherence with another: the desired behavior was documented before verifying the engine implements it. The false claim appeared in two places (SELF-MEASURE.md §3.3 and response_schema.ml docstring), both modified in the same commit. The self-coherence peer enumeration for that commit listed both surfaces as "corrected" but did not cross-check against the engine's actual runtime behavior.

**Surfaces affected:** `runtime/SELF-MEASURE.md` (operator-visible scoring contract), `engine/ocaml/lib/response_schema.ml` (module docstring). Fixed in R2→R3 fix round.

### Finding 3: §9.1 trigger fires — review rounds exceeded 2

Review went 3 rounds (R1 RC, R2 RC, R3 A). CDD §9.1 trigger fires: "review rounds exceeded target (default: 2)." PRA must include a `## Cycle Iteration` section.

**No new findings beyond these three.**
