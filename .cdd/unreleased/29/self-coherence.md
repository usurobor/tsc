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
| AC1 — Self-coherence report exists | pending | |
| AC2 — Per-target scores recorded | pending | |
| AC3 — v3.2.0 provenance attached | pending | |
| AC4 — W2 ref+spread reported | pending | |
| AC5 — Honest grading | pending | |
| AC6 — Report referenced in canonical doc index | pending | |

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
