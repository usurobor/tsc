# cdd: Incorporate supercycle learnings — honest-claim review, MCA preconditions, docs-only disconnect, round metrics, honest-grading rubric, cdd-iteration self-iteration home

**Labels:** `docs, P2, cdd`
**Priority:** P2 — protocol-coherence improvement; the supercycle exposed six recurring patterns the cdd skills did not yet address (five from the supercycle's runtime; one meta-finding from authoring the cross-repo bundle for this very PR).
**Status:** Patches authored; ready for cycle dispatch.
**Mode:** docs-only (no code, no version bump; per `cdd/release/SKILL.md` §2.5b proposed in this issue). Cross-repo finding lineage tracked at `.cdd/iterations/cross-repo/cnos/cdd-supercycle/` per the structure proposed in patch 6.

## Problem

**What exists:** cnos.cdd skill bundle defines γ→α→β cycle with verdict rules, finding taxonomy, ledger format, MCA mode declaration, and post-release assessment. The bundle is functional and was used end-to-end across the cnos-tsc supercycle (`usurobor/tsc#23`, 5 cycles closed in roughly one day, three engine releases v0.5.0/v0.6.0/v0.7.0).

**What is expected:** The supercycle surfaced six recurring patterns the existing skills don't yet address:

1. β catches "honest-claim" findings (doc claims X; code/data doesn't back X) but the rule is implicit — review/SKILL.md taxonomy has only `mechanical / judgment / contract`.
2. MCA mode is declared but preconditions (design+plan stable, cited in source-of-truth) aren't named — γ can assert MCA without the upfront artifacts that make MCA work.
3. release/SKILL.md §2.5a covers `.cdd/unreleased/{N}/` move on tagged release; silent on docs-only-no-tag cycles. Two recurrences observed (cycle 27 retro close-out; cycle 29 self-coherence report).
4. Review-round count is a real learning-curve indicator (1 → 2 → 3 → 1 → 2 across the supercycle's five cycles) but isn't surfaced in the ledger row or PRA structured output.
5. §3.8 "honest grades — not everything is A+" is qualitative — reviewers can pick different letters without a shared rubric.
6. **(meta-finding)** cdd has triggers (CDD.md §9.1) and dispositions (PRA §3+§4b: patch-landed / next-MCA / no-patch) but no canonical artifact under `.cdd/` for cdd-self-improvement findings. PRA §3 prose can't be aggregated. Reconstructing the supercycle's 5 findings required reading 5 separate `gamma-closeout.md` files. Cross-repo work (tsc → cnos) had no canonical place under `.cdd/` — the prior version of this very bundle violated the "all artifacts under .cdd" principle by sitting at `pr-bundles/` at the repo root.

**Where they diverge:**
- review/SKILL.md verdict rules end at 3.12; no rule for honest-claim verification.
- issue/SKILL.md describes mode-as-text but enforces no preconditions for MCA; mis-labeled MCA cycles inflate review pressure (cycle 25 was MCA but α had to load context for 20 minutes; cycle 24 was not labeled MCA and ran 3 rounds).
- release/SKILL.md §2.5a says move on tagged release; cycle 27 and 29 left their `.cdd/unreleased/` directories on main with no clear protocol.
- post-release/SKILL.md §4 tracks Avg review rounds but not per-cycle or per-class; release ledger row format is `| Version | C_Σ | α | β | γ | Level | Note |` with no Rounds column.
- §3.8 says "honest grades" but gives only one example; reproducibility across reviewers is low.

## Impact

- **Authority drift across releases.** Without the honest-claim rule, β reviewers may catch the right class of bug (as happened in the supercycle) without the cdd skill making it reproducible — the next reviewer may miss it.
- **MCA mis-labeling cost.** Review pressure correlates with whether design+plan were stable. Mis-labeled MCA cycles run longer and burn α context.
- **Docs-only cycles drift.** `.cdd/unreleased/{N}/` directories accumulate on main when no tag follows.
- **Round-count signal lost.** The 1 → 2 → 3 → 1 → 2 trace across the supercycle is real data — without surfacing it in the ledger, the next supercycle re-discovers it from scratch.
- **Grade inflation risk.** Without a rubric, the next post-release assessment can score every release A+.

## Status truth

| Surface | Status | Notes |
|---|---|---|
| `cdd/review/SKILL.md` verdict rules 3.1–3.12 | Shipped | No honest-claim sub-rule. |
| `cdd/issue/SKILL.md` mode mention | Shipped | MCA referenced; no preconditions defined. |
| `cdd/release/SKILL.md` §2.5a tagged-release move | Shipped | Silent on no-tag case. |
| `cdd/post-release/SKILL.md` §4 review-quality fields | Shipped | Avg rounds only; no per-cycle table; only `mechanical / judgment` finding classes. |
| Release ledger row format | Shipped | Includes Level; no Rounds column. |
| `cdd/release/SKILL.md` §3.8 honest grades | Shipped | Qualitative; no rubric. |

## Source of truth

| Claim / surface | Canonical source | Status |
|---|---|---|
| Existing review verdict rules | `src/packages/cnos.cdd/skills/cdd/review/SKILL.md` §Verdict Rules | Shipped |
| Existing issue mode mention | `src/packages/cnos.cdd/skills/cdd/issue/SKILL.md` | Shipped |
| Existing release move protocol | `src/packages/cnos.cdd/skills/cdd/release/SKILL.md` §2.5a | Shipped |
| Existing post-release §4 fields | `src/packages/cnos.cdd/skills/cdd/post-release/SKILL.md` §4 + Step 5.5 | Shipped |
| Existing ledger format | `src/packages/cnos.cdd/skills/cdd/release/SKILL.md` §2.4 | Shipped |
| Existing §3.8 grading | `src/packages/cnos.cdd/skills/cdd/release/SKILL.md` §3.8 | Shipped |
| **Empirical evidence** | `usurobor/tsc#23` (master), cycles #24, #25, #26, #27, #29 close-outs | Shipped |
| Earlier upstream patches (queued) | `usurobor/cnos#330` | In flight (different patches: stream-json default, alpha placeholder, no-tag dir-move via #2.5b — overlap with this issue's patch 3) |

## Scope

**In scope:**
- `cdd/review/SKILL.md`: add verdict rule 3.13 (honest-claim verification) + finding-taxonomy entry + checklist items.
- `cdd/issue/SKILL.md`: add mode-declaration table + MCA preconditions section + checklist items.
- `cdd/release/SKILL.md`: add §2.5b (docs-only disconnect, no tag); rename §2.5a heading; expand §2.4 ledger format; replace §3.8 with rubric.
- `cdd/post-release/SKILL.md`: expand §4 with per-cycle round counts table + 5-class finding taxonomy; update Step 2 ledger row format; add Step 5.6b authoring `cdd-iteration.md`.
- `cdd/CDD.md`: add `cdd-iteration.md` to canonical filename table (§Tracking); add 3 rows to §5.3a Artifact Location Matrix (cdd-iteration, INDEX, cross-repo); add 2 rows to §5.3b ownership matrix (cdd-iteration ownership + INDEX update).
- `cdd/gamma/SKILL.md`: add §2.10 closure gate row 14 (artifact required when triage produces cdd-`*`-gap findings).

**Out of scope:**
- Tooling changes (e.g. `scripts/release.sh` enforcement of bare tags is in `usurobor/cnos#330`).
- Two-agent (δ=γ) configuration sanction or rejection — that's a separate cnos design issue.
- Branch-hygiene authority (standing vs per-cycle) — separate cnos design issue.
- Self-coherence report dir placement convention — separate cnos design issue.
- Patches that overlap with `usurobor/cnos#330` (operator stream-json default, alpha §2.6 placeholder validation) — left to #330.

**Deferred:**
- Updating any cnos `kata` references for the new rules.

## Acceptance criteria

### AC1: Honest-claim verification rule 3.13 in `review/SKILL.md`

**Invariant:** review/SKILL.md verdict rules include 3.13 with three sub-checks (reproducibility, source-of-truth alignment, wiring claims), all binding.
**Oracle:** `grep -n "3.13" src/packages/cnos.cdd/skills/cdd/review/SKILL.md` returns at least one match in the verdict-rules section; checklist gains three honest-claim rows.
**Positive:** Rule exists; checklist has rows for 3.13a/b/c.
**Negative:** Rule absent or finding taxonomy missing `honest-claim` class.
**Surface:** `src/packages/cnos.cdd/skills/cdd/review/SKILL.md`.

### AC2: MCA preconditions in `issue/SKILL.md`

**Invariant:** issue/SKILL.md has a mode-declaration section naming MCA / explore / design-and-build / docs-only, and three explicit MCA preconditions (design committed at stable path, plan committed with step ordering, both stable).
**Oracle:** `grep -n "MCA preconditions" src/packages/cnos.cdd/skills/cdd/issue/SKILL.md` returns a header match; checklist gains mode-declaration row.
**Positive:** Section exists; checklist enforces.
**Negative:** Mode mentioned but preconditions not enumerated.
**Surface:** `src/packages/cnos.cdd/skills/cdd/issue/SKILL.md`.

### AC3: Docs-only disconnect §2.5b in `release/SKILL.md`

**Invariant:** release/SKILL.md has §2.5b naming the docs-only-no-tag case, the date-keyed `.cdd/releases/docs/{ISO-date}/{N}/` move target, and the date-keyed PRA path.
**Oracle:** `grep -nE "2\.5b|docs-only disconnect" src/packages/cnos.cdd/skills/cdd/release/SKILL.md` returns matches; §2.5a heading renamed to include "(tagged release)".
**Positive:** §2.5b present with bash snippet for the move.
**Negative:** Silent on no-tag case OR forces synthetic version bump.
**Surface:** `src/packages/cnos.cdd/skills/cdd/release/SKILL.md`.

### AC4: Round-count metric in `post-release/SKILL.md` and ledger format

**Invariant:** post-release/SKILL.md §4 has a per-cycle round-counts table and a 5-class finding-taxonomy table (mechanical / wiring / honest-claim / judgment / contract). Both Step 2 (post-release) and §2.4 (release) describe the ledger row as including a Rounds column.
**Oracle:** `grep -n "Per-cycle round counts" src/packages/cnos.cdd/skills/cdd/post-release/SKILL.md` matches; ledger format documented as `| X.Y.Z | C_Σ | α | β | γ | Level | Rounds | Coherence note |`.
**Positive:** Both tables present; both files agree on the ledger format.
**Negative:** Rounds missing from one of the two skill files (drift).
**Surface:** `src/packages/cnos.cdd/skills/cdd/post-release/SKILL.md`, `src/packages/cnos.cdd/skills/cdd/release/SKILL.md` §2.4.

### AC5: Honest-grading rubric §3.8 in `release/SKILL.md`

**Invariant:** §3.8 contains a per-axis rubric mapping A through <C to numeric values, and a formula for C_Σ as geometric mean.
**Oracle:** `grep -nE "Per-axis rubric|geometric mean" src/packages/cnos.cdd/skills/cdd/release/SKILL.md` matches.
**Positive:** Table present; numeric formula present; example references the cnos-tsc cycle 27 retroactive C+ grade.
**Negative:** §3.8 left as qualitative prose.
**Surface:** `src/packages/cnos.cdd/skills/cdd/release/SKILL.md` §3.8.

### AC6: `cdd-iteration.md` artifact + INDEX + cross-repo structure

**Invariant:** `CDD.md` §Tracking and §5.3a/§5.3b name `cdd-iteration.md` and `.cdd/iterations/INDEX.md` and `.cdd/iterations/cross-repo/{target}/{slug}/`. `post-release/SKILL.md` Step 5.6b describes the author procedure with per-finding shape, aggregator update, and cross-repo trace. `gamma/SKILL.md` §2.10 row 14 enforces the artifact at closure when applicable.
**Oracle:** `grep -nE "cdd-iteration\.md|iterations/INDEX|iterations/cross-repo" src/packages/cnos.cdd/skills/cdd/{CDD,post-release/SKILL,gamma/SKILL,review/SKILL}.md` returns matches in CDD.md (3 sections), post-release/SKILL.md (Step 5.6b + pre-publish gate), gamma/SKILL.md (§2.10 row 14).
**Positive:** All four oracle sites match; per-finding shape and class vocabulary (`cdd-skill-gap` / `cdd-protocol-gap` / `cdd-tooling-gap` / `cdd-metric-gap`) defined.
**Negative:** Any of the three layers missing (per-cycle / aggregator / cross-repo).
**Surface:** `src/packages/cnos.cdd/skills/cdd/CDD.md` §Tracking + §5.3a + §5.3b; `post-release/SKILL.md` Step 5.6b + pre-publish gate; `gamma/SKILL.md` §2.10.

## Proof plan

**Invariant:** All five patches land coherently across `cdd/{review,issue,release,post-release}/SKILL.md`; cross-references between files agree (e.g. release/SKILL.md §2.4 and post-release/SKILL.md Step 2 both name the same ledger format).
**Surface:** Four skill files in the cnos.cdd package.
**Oracle:** β reviews the diff; γ runs `grep` checks for AC1–AC5 oracles; β additionally applies rule 3.13 to *this issue's own diff* (recursive consistency check — does this issue's prose make claims its diff supports?).
**Positive case:** All five ACs pass; finding taxonomy on `usurobor/tsc#23` cycles 24/29 retrofits cleanly under the new 5-class taxonomy without recategorizing.
**Negative case:** Cross-reference drift between release/SKILL.md and post-release/SKILL.md on the ledger format; or honest-claim rule applied to this issue's prose itself produces a finding.
**Operator-visible projection:** The next cnos cycle's PRA uses the new §4 tables and the new ledger Rounds column.
**Known gap:** Kata exercises in `cnos.cdd.kata/katas/` are not updated to exercise rule 3.13 or the new modes; a follow-on issue should update kata coverage.

## Skills to load

**Tier 3:**
- `cnos.core/skills/skill` — for skill-program/frontmatter coherence on the modified SKILL.md files
- `cnos.eng/skills/eng/writing` — for prose patches to skill files

**Why:**
- All five patches are documentation/skill changes — no code, no runtime, no platform.

## Active design constraints

- **No frontmatter changes.** Each patched SKILL.md keeps its existing frontmatter unchanged.
- **No new sub-skills created.** All patches go in existing skill files.
- **No cross-package edits.** Patches are confined to `src/packages/cnos.cdd/`.
- **Examples reference the empirical evidence.** Where the supercycle produced concrete data (cycle 27's C+ retroactive grade, the 1→2→3→1→2 round trace, the F1–F4 honest-claim findings on cycle 29), patches cite that evidence directly so the rule is anchored in observed behavior.
- **No overlap with `usurobor/cnos#330`.** Patches in this issue do not duplicate work queued there (operator stream-json default, alpha §2.6 placeholder validation). The docs-only disconnect (§2.5b) is referenced by both — coordinate during merge.

## Related artifacts

- `usurobor/tsc` master issue #23 (closed) and sub-issue close-outs:
  - `.cdd/releases/0.6.0/24/{self-coherence,beta-review,alpha-closeout,beta-closeout,gamma-closeout}.md`
  - `.cdd/releases/0.7.0/26/...`
  - `.cdd/unreleased/27/...` (still on main — exhibit A for §2.5b)
  - `.cdd/unreleased/29/...` (still on main — exhibit B for §2.5b)
- `usurobor/cnos#330` (consolidated upstream skill patches; coordinate on §2.5b overlap)
- `src/packages/cnos.cdd/skills/cdd/{review,issue,release,post-release}/SKILL.md`

## Non-goals

- Tooling changes to `scripts/release.sh` (covered by `usurobor/cnos#330`).
- Sanctioning or rejecting the two-agent (δ=γ) configuration that ran the supercycle.
- Branch-hygiene authority decision.
- Self-coherence report directory placement convention.
- Kata coverage updates for the new rules.
- Spec changes to TSC, c-equiv, or any non-cdd package.

## Success / closure condition

This issue is closeable when:
- AC1–AC5 each map to evidence in the branch diff.
- β applies rule 3.13 to *this issue's own diff* and finds no honest-claim violations.
- Cross-references between release/SKILL.md §2.4 and post-release/SKILL.md Step 2 agree on the ledger format.
- The five commits land as a clean linear history.
- Mode = docs-only; disconnect via the §2.5b path proposed in this very issue (recursive coherence — the issue's own disconnect tests its proposed protocol).
