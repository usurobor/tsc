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

*(α fills in)*

## §Debt

*(α fills in)*

## CDD Trace

| Step | Artifact | Skills loaded | Decision |
|------|----------|---------------|----------|
| 0 Observe | — | — | Gap: no v3.2.0 self-coherence report exists; `docs/alpha/engine/0.3.0/SELF-COHERENCE.md` is v3.1-era precedent only. Dependencies #24 (OCaml v3.2.0 engine) and #25 (hybrid scoring) are CLOSED. |
| 1 Select | Issue #29 | — | Selected per CDD §3: open sub-issue under master #23; P1; deps landed. |
| 2 Branch | `cycle/29-self-coherence` | cdd | Branch created by γ from `origin/main`, pre-flight passed. |
| 3 Bootstrap | `.cdd/unreleased/29/self-coherence.md` scaffold | cdd | Scaffold committed by γ at branch creation. |
