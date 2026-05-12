---
cycle: 36
type: cdd-iteration
date: "2026-05-12"
dispatch_configuration: "§5.2 single-session δ-as-γ via Claude Code Agent tool"
finding_count: { skill-gap: 1, protocol-gap: 0, tooling-gap: 0, metric-gap: 0, positive: 1 }
---

# cdd-iteration — Cycle #36

Cycle #36 produced **one cdd-skill-gap** finding and **one positive-signal** observation. Cycle was rated B+ (C_Σ) — the protocol corrected itself via β's R1 catch, but γ shipped on a false-gap premise that better recon would have prevented.

## F1 — cdd-skill-gap: γ peer-enumeration before scaffold

**Source:** β R1 binding finding B-1 (verdict RC). Root cause was γ-side, not α-side: γ filed issue #36 and authored the cycle scaffold without reading `.github/workflows/ci.yml` line-by-line. `ci.yml` contained a `kata-check` job (added in cycle 344-c, commit `16f60ac`) that already exercised the same surface the new workflow proposed to add. The cycle's §Gap statement ("CI does not invoke `coh --kata` against shipped kata content") was empirically false from the moment it was written.

**Trigger class:** §9.1 avoidable tooling failure — cycle dispatched on a misframed gap when a 30-second peer-enumeration of `.github/workflows/` would have surfaced the conflict.

**Discoverability:** `grep -rEn 'coh --kata|scripts/run-katas\.sh' .github/workflows/` returns the existing `kata-check` invocation. The check is mechanical, fast, and obvious in retrospect.

**Why it survived γ:** the cycle was framed as "tsc has shipped kata progression but not wired CI" — true premise, false conclusion. γ inferred that CI didn't wire katas because the activation skill's Cycle C (tsc adoption) was "still in progress" per visible cnos signal — but 344-c had in fact shipped the `kata-check` job. γ failed to verify the inference against the actual file.

**Disposition (this cycle):** B-1 surfaced by β R1; α R2 consolidated via Path A (deleted `kata-check` from `ci.yml`; kept `katas.yml` as canonical home with cache + concurrency improvements). Final state is correct.

**Affected cnos cdd skill section:** `cdd/gamma/SKILL.md` §γ-scaffold-time invariants — should name "peer-enumerate every file in the impact graph's affected directories before authoring §Gap" as a required step. Today γ's responsibility is implicit; making it explicit would prevent this class of failure.

**Recommended cnos patch (out of scope for this cycle):**

Add to `cdd/gamma/SKILL.md`:

> **§ Peer enumeration at scaffold time.** Before authoring §Gap in `self-coherence.md`, γ must:
> 1. List every file in the directories named by the issue's `impact graph`.
> 2. Grep for the term/symbol/surface the cycle proposes to add or change.
> 3. If any match is found, name it explicitly in §Gap — either as "this gap is partially closed by X, this cycle completes it" or "X overlaps the proposed surface and must be reconciled in scope."
>
> A §Gap that asserts "X does not exist" without grep-evidence is a γ-side honest-claim violation analogous to α's rule 3.13(a) reproducibility constraint.

**Recommended action:** file as cnos cdd issue under `cdd/gamma/SKILL.md`. Cross-reference §3.8 honest-grading rubric — γ axis grade should reflect peer-enumeration discipline.

**Cross-repo trace:** `.cdd/iterations/cross-repo/cnos/gamma-peer-enumeration/` to be created on follow-on.

## P1 — positive: β rule 3.13 wiring discipline caught γ's recon failure

**Source:** β R1 review document, β R2 confirmation.

β R1 independently peer-enumerated all four workflow files on main, found the existing `kata-check` job, and surfaced it as binding finding B-1. β did exactly what γ should have done at scaffold time — the protocol's role-separation produced the correct catch.

This validates the rule-3.13 wiring claim in `cdd/review/SKILL.md` (cnos #331 patch 1): "every 'X is wired into Y' claim grep-verifies in the diff." β extended the principle to wired-elsewhere claims ("X is not wired into Y") — the negation form is symmetric and equally subject to verification.

**Why it matters:** the cycle's correctness was rescued by β's discipline. Without rule 3.13 being canonical in `cdd/review/SKILL.md`, β might have approved on AC-walk alone and the duplicate workflows would have shipped. The cnos #331 patch is paying for itself in real cycles.

**Disposition:** no fix needed. Recorded as cycle-of-the-protocol-working signal.

## Branch sprawl (not a finding — pre-named)

5 branches for 1 cycle (`cycle/36`, `cycle/36-impl`, `cycle/36-impl-review`, `cycle/36-impl-r2`, `cycle/36-impl-r2-review`). Same harness-403 pattern as cycle #32. Already named in `proposals/cnos-cdd-claude-code-dispatch` §5.2 (single-session δ-as-γ under harness push restrictions). No new disposition.

## Dispatch configuration result

§5.2 single-session δ-as-γ via Claude Code Agent tool. Sub-agent dispatches (α R1, β R1, α R2, β R2) ran cleanly. Stop-hook fired twice on in-flight sub-agent WT edits but did not block progress; α/β committed and pushed from their own contexts as expected. Branch-name churn handled via the documented fresh-branch-on-403 pattern.

**γ grade cap A−** (per §5.2 proposed amendment) was irrelevant — actual γ grade (B) fell below the cap due to recon failure. The cap is a ceiling, not a floor. Honest-grading discipline preserved.

## Outputs to file

| Output | Target | Status |
|---|---|---|
| F1 — γ peer-enumeration cnos cdd patch | cnos cdd issue under `cdd/gamma/SKILL.md` | To file as `proposals/cnos-cdd-gamma-peer-enumeration` follow-on |
| P1 — rule 3.13 working signal | cycle archive (this file) | ✅ recorded |
| Branch sprawl | already named in `proposals/cnos-cdd-claude-code-dispatch` §5.2 | ✅ no new file needed |

## INDEX

To be appended to `.cdd/iterations/INDEX.md`:

| Cycle | Date | Findings | Patches Filed | MCAs | No-Patch |
|---|---|---|---|---|---|
| 36 | 2026-05-12 | 1 (skill-gap) + 1 (positive) | 1 (γ peer-enumeration) | 0 | 1 (branch sprawl, pre-named) |
