---
cycle: 29
issue: "Sub 6 (#23): Generate v3.2.0 self-coherence report"
branch: cycle/29-self-coherence
phase: alpha
role: alpha
---

# Cycle 29 — Self-Coherence

**Gap:** No v3.2.0 self-coherence report exists. Spec v3.2.0 claims a typed transformation chain (barrier transform, typed provenance, W2 dual-signal gauge witness). Without a self-coherence run under a v3.2.0-conformant engine, the claim is theoretical only. The cnos release skill expects post-release self-coherence; the spec v3.2.0 RELEASE.md explicitly deferred this to a follow-on. Dependencies (#24 OCaml v3.2.0 engine, #25 hybrid scoring) are now CLOSED.

**Mode:** MCA. The work is execution: run the v3.2.0 engine against canonical targets, capture provenance, author the report. No new design or architecture decision required beyond the path policy resolved in this issue.

## §Skills

- Tier 1: `CDD.md`, `alpha/SKILL.md`
- Tier 3: `cdd/post-release` — the self-coherence report is the post-release measurement for the spec v3.2.0 release
- Tier 3: `cnos.core/skills/write` — report is a documentation artifact; write skill applies as generation constraint

## §ACs

| AC | Status | Evidence |
|----|--------|----------|
| AC1 — Self-coherence report exists | **Met** | `docs/alpha/doctrine/3.2.0/SELF-COHERENCE.md` created in commit e45e866 |
| AC2 — Per-target scores recorded | **Met** | Report §Per-Target Results: spec α=0.968/β=0.910/γ=0.815/C_Σ=0.898; engine α=0.650/β=0.225/γ=0.687/C_Σ=0.521; repo α=0.915/β=0.385/γ=0.680/C_Σ=0.660. Confidence note per target. |
| AC3 — v3.2.0 provenance attached | **Met** | `docs/alpha/doctrine/3.2.0/provenance/{spec,engine,repo}.json` contain `provenance_v320` block with all v3.2.0 required fields from `spec/tsc-oper.md` §6 (discrepancy_symbol, barrier_phi, aggregate_math, aggregate_numeric, gauge_witness). Fields not computable in mechanical mode (L_link, per-pair δ) recorded as `null` with explanation. |
| AC4 — W2 ref+spread reported | **Met** | Report §W2 Gauge Witness: w_gauge_ref=0.000 and w_gauge_spread=0.000 per target; both ≤ τ_gauge_spread=0.050 (pass). Trivial-pass explanation given: geometric mean is S₃-symmetric by construction in mechanical mode. |
| AC5 — Honest grading | **Met** | Engine β=0.225 reported with root cause (_build/ artifact contamination). Aggregate C_Σ=0.675 grade C+. Bottleneck named (β). Hybrid deferral declared explicitly in §Known Gaps. Not everything A+. |
| AC6 — Report referenced in canonical doc index | **Met** | `docs/alpha/doctrine/README.md` §Self-coherence reports table added with link to 3.2.0/SELF-COHERENCE.md, engine version, and mode. |

## §Self-check

No ambiguity pushed onto β. All claims are backed by evidence in the diff:

- Engine ran successfully: three JSON output files in `.tsc/3.2.0-run/` confirm the scores cited.
- Provenance JSON files in `docs/alpha/doctrine/3.2.0/provenance/` were authored from the JSON output; v3.2.0 field values were computed using the formulas in `engine/ocaml/lib/coherence.ml` and verified as consistent.
- W2 trivially 0: confirmed by symmetry argument (geometric mean is S₃-symmetric) plus reference to coherence.ml implementation.
- AC3 provenance schema: fields match the skeleton in `spec/tsc-oper.md` §6 exactly.
- AC6 index: `docs/alpha/doctrine/README.md` verified after edit.
- No design artifact required: the issue body contains the path decision and all implementation guidance.
- No plan required: single sequence of steps, no non-trivial ordering decisions.
- Tests: not applicable (this is a documentation/measurement issue; ACs are satisfied by file existence + manual review, as specified by the issue's Oracle field for each AC).

One ambiguity resolved in-cycle: the issue says "Oracle: Schema validation against the v3.2.0 skeleton from Sub 1 AC5" for AC3. Interpreted as: the provenance JSON files must include all fields defined in the §6 skeleton with correct types. Mechanical-mode-null fields are present with explicit `null` values and a `notes` field explaining why. β should verify this interpretation is correct.

## §Debt

D1 — **Hybrid run deferred.** No LLM credentials available. The hybrid run (semantic scores, per-pair δ, non-trivial W2, L_link, bootstrap CI) is not present. The current report measures structural proxies only. A follow-on measurement with credentials would materially change the engine and repo β scores and would provide genuine W2 gauge invariance evidence.

D2 — **engine.tsc _build/ exclusion missing.** Engine target β=0.225 is artificially depressed by build artifacts. Fixing `engine.tsc` to exclude `engine/ocaml/_build/**` is the highest-leverage improvement to the measurement baseline. This is a target-definition issue, not an engine issue.

D3 — **Aggregate C_Σ formula not specified in spec.** The report uses geometric mean of per-target C_Σ values as the aggregate. This formula is not formally specified in tsc-oper.md or tsc-core.md; it is α's judgment call. β should confirm or correct.

D4 — **No CI.** Mechanical mode is deterministic; bootstrap CI requires LLM/hybrid mode. All scores are point estimates.

## CDD Trace

| Step | Artifact | Skills loaded | Decision |
|------|----------|---------------|----------|
| 0 Observe | — | — | Gap: no v3.2.0 self-coherence report exists; `docs/alpha/engine/0.3.0/SELF-COHERENCE.md` is v3.1-era precedent only. Dependencies #24 (OCaml v3.2.0 engine) and #25 (hybrid scoring) are CLOSED. |
| 1 Select | Issue #29 | — | Selected per CDD §3: open sub-issue under master #23; P1; deps landed. |
| 2 Branch | `cycle/29-self-coherence` | cdd | Branch created by γ from `origin/main`, pre-flight passed. |
| 3 Bootstrap | `.cdd/unreleased/29/self-coherence.md` scaffold | cdd | Scaffold committed by γ at branch creation. |
| 4 Gap | `.cdd/unreleased/29/self-coherence.md` §Gap | cdd, alpha | Gap: no v3.2.0 report. Mode: MCA. |
| 5 Mode | `.cdd/unreleased/29/self-coherence.md` §Skills | cdd, post-release, write | Mode MCA; Tier 3: cdd/post-release, cnos.core/skills/write. |
| 6 Artifacts | `docs/alpha/doctrine/3.2.0/SELF-COHERENCE.md`, `provenance/{spec,engine,repo}.json`, `docs/alpha/doctrine/README.md` | post-release, write | Design: not required (path policy in issue). Plan: not required (single sequence). Tests: not applicable (file-existence + manual review). Code: N/A. Docs: SELF-COHERENCE.md + provenance JSON + README update authored. |
| 7 Self-coherence | `.cdd/unreleased/29/self-coherence.md` | cdd, alpha | AC-by-AC check complete; self-check complete; debt explicit. |
| 7a Pre-review | `.cdd/unreleased/29/self-coherence.md` | cdd, alpha | Gate passed: (1) branch rebased on origin/main ee4a84d at 2026-05-08T21:51Z; (2) CDD Trace through step 7 present; (3) tests not applicable — docs-only change; (4) all 6 ACs evidenced; (5) debt D1–D4 explicit; (6) no schema-bearing contract changed; (7) no peer family; (8) no harness audit needed; (9) no mid-cycle patch; (10) local build+tests pass (opam exec -- dune build+runtest, 2026-05-08T21:51Z), CI on non-main branches requires PR — not applicable to docs-only change; (11) all commits alpha@cdd.tsc. Implementation SHA: ef833de. |

## Review-readiness | round 1 | base SHA: ee4a84d | implementation SHA: ef833de | branch CI: local build+tests green at 2026-05-08T21:51Z (CI does not run on non-main branches without PR; docs-only change, no OCaml code modified) | ready for β
