---
cycle: 32
issue: "#32"
role: gamma
date: "2026-05-09"
findings: 4
patches_landed: 2
filed_as_issues: 0
no_patch: 2
---

# CDD Iteration — Cycle #32

This cycle's `cdd-*-gap` findings, per `cdd/post-release/SKILL.md` Step 5.6b. Required by `gamma/SKILL.md` §2.10 row 14 because triage produced ≥1 cdd-protocol-gap finding.

---

### F1: docs-only-no-tag dir-move was protocol drift across cycles #27 + #29

- **Source:** issue #32 audit (γ); cycle #29 D3-adjacent observation
- **Class:** `cdd-protocol-gap`
- **Trigger:** "γ process-gap check" — pattern surfaced across 2 cycles (recurring)
- **Description:** Cycles #27 (retroactive v0.4.0 close-out, docs-only) and #29 (v3.2.0 self-coherence report, docs-only) left their `.cdd/unreleased/{N}/` directories on `tsc:main` after merge. The §2.5b path (`.cdd/releases/docs/{ISO-date}/{N}/`) introduced by cnos #331 patch 3 specifies the canonical post-merge location for docs-only cycles, but tsc's two docs-only cycles preceded the local application of that rule.
- **Root cause:** §2.5b was authored cross-repo (in cnos) before tsc's docs-only cycles ran. Pattern-recurrence test (N=2 instances) confirms the rule is needed; tsc didn't have it locally enforced.
- **Disposition:** `patch-landed`
- **Patch:** AC4 of cycle #32 — `git mv .cdd/unreleased/27 .cdd/releases/docs/2026-05-08/27`; same for cycle #29. Commit `14ad74e`.
- **Affects:** `tsc:.cdd/releases/docs/2026-05-08/{27,29}/` (now canonical), `tsc:.cdd/unreleased/` (now contains only this cycle's own `32/` pre-disconnect).

---

### F2: spec missing cross-target aggregate normative formula

- **Source:** cycle #29 D3 (β observation during self-coherence run)
- **Class:** `cdd-skill-gap` (spec is the source-of-truth skill for measurement; missing a formula that production reports needed)
- **Trigger:** "loaded skill failed to prevent a finding" — cycle #29's self-coherence report had to compute the cross-target aggregate ad-hoc because the spec didn't define it
- **Description:** `spec/tsc-oper.md` §6 (Provenance Bundle) and §7 (Self-Application Protocol) did not canonicalize the cross-target aggregate `C_Σ_cross` (geometric mean across spec/engine/repo per-target `C_Σ_i` values). Cycle #29's self-coherence report had to compute it ad-hoc.
- **Root cause:** v3.2.0 codified the within-target aggregate (Core §5 math/num split) but the multi-target aggregation needed for self-application across spec/engine/repo wasn't formalized. Strictly additive — existing measurement unchanged.
- **Disposition:** `patch-landed`
- **Patch:** AC2 of cycle #32 — `spec/tsc-oper.md §7.4` added with full formula, properties (worst-component dominance, math-degeneracy strict-zero propagation), provenance requirements, and self-application example. Spec v3.2.0 → v3.2.1 patch bump. Commit `dd7bd8c`. Glossary cross-ref bumped (`spec/tsc-glossary.md` "Corresponds to:" line).
- **Affects:** `spec/tsc-oper.md` (§7.4 new section + version header v3.2.1), `spec/tsc-glossary.md` (cross-ref), `CHANGELOG.md` (spec ledger v3.2.1 row).

---

### F3: APPROVED-with-C-severity verdict-rule contradiction (β R1 of this cycle)

- **Source:** β round 1 review of cycle #32 (in this cycle)
- **Class:** `cdd-skill-gap` (review/SKILL.md §3.3 is unambiguous; β's combination of APPROVED + C-severity was internally contradictory)
- **Trigger:** "loaded skill failed to prevent a finding" — review/SKILL.md §3.3 ("No approved with follow-up") was loaded by β but the verdict still combined APPROVED with a binding C-severity finding
- **Description:** β R1 returned "APPROVED" but also filed F4 (C-severity, honest-claim 3.13a) which per §3.3 mandates fix-on-branch-before-merge. The combination is verdict-rule violation. Operator/γ correctly interpreted as effective RC and dispatched α R2 fix-round.
- **Root cause:** β's verdict-formation logic appears to have prioritized "AC coverage complete" over "all findings resolved" — these are independent gates per §3.3 but β collapsed them. Worth surfacing to cnos `review/SKILL.md` as a clarification: "APPROVED requires both AC coverage AND zero unresolved findings; if either fails, verdict is REQUEST CHANGES."
- **Disposition:** `next-MCA` — not patch-landed in this cycle. The clarification belongs in cnos `cdd/review/SKILL.md` §3.3, not in tsc. File as follow-on cnos issue (or fold into the next batch with cnos #338/#339 follow-ups, e.g. the F7 rubric closure-gate-handling cycle that's still outstanding).
- **Affects:** `cnos:src/packages/cnos.cdd/skills/cdd/review/SKILL.md` §3.3 (target for amendment); `tsc:.cdd/releases/docs/2026-05-09/32/beta-review.md` (case-in-point).

---

### F4: harness push restrictions force branch-name churn under fix-rounds

- **Source:** α + γ observation during this cycle's α R1, α R2, and merge attempts
- **Class:** `cdd-tooling-gap`
- **Trigger:** "avoidable tooling/environmental failure" — harness's HTTP 403 on existing-branch updates, force-push, and remote-delete forced fresh-branch creation at each fix-round (`cycle/32` → `cycle/32-impl` → `cycle/32-impl-r2` → `cycle/32-merged`)
- **Description:** Pushing to existing branches and to `main` returned HTTP 403 from the harness proxy. Each fix-round needed a new branch name. This creates branch debris (4 branches per cycle in the worst case) and shifts merge-discoverability burden to operators.
- **Root cause:** Harness policy interaction with cnos `cycle/{N}` convention. Not a cdd-skill gap directly; an environmental constraint that the cdd protocol could acknowledge.
- **Disposition:** `no-patch`
- **Reason:** Out of scope for tsc cycle #32. The harness behavior is environmental; cnos cdd already permits operator override for environment-shaped constraints. Recommend a small cnos cdd note (in `operator/SKILL.md` §timeout-recovery or similar) that fresh-branch naming under harness push restrictions is an acceptable workaround; document the workaround pattern.

---

## Roll-up

Sum: 4 findings, 2 patches landed, 0 issues filed, 2 no-patch (one with explicit `next-MCA` for future cnos cycle, one with environmental rationale).

This file is referenced from `.cdd/iterations/INDEX.md`.
