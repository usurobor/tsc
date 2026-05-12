---
cycle: 43
type: post-merge-addendum
date: "2026-05-12"
parent: gamma-closeout.md
addendum_reason: "γ recon failure surfaced post-merge — cycle #43 assumed v-prefix convention from tsc-local artifacts (release.yml trigger, release.sh header) without checking cnos cdd canonical rule. User confirmed: cdd convention is bare-version. Cycle #46 reverts the wrong-direction fix; this addendum records the honest grade revision."
---

# Post-merge addendum — Cycle #43

## What surfaced post-close

After cycle #43 closed (merge `9ad9d68`, γ close-out `ae61bc5`, INDEX merge `be15d22`), the user flagged that cdd's canonical convention is **bare-version everywhere — no `v` prefix**.

Cycle #43 had inferred a v-prefix convention from tsc-local artifacts:

- `.github/workflows/release.yml:5` trigger pattern `tags: ['v*']`
- `scripts/release.sh` header comment "Tag (v-prefixed)"
- Historical published releases (v0.4.0, v0.8.0, v0.9.0)

None of those are authoritative cdd-canonical sources. The actual canonical surfaces (which γ's F1 peer-enumeration listed but did not cross-check against the canonical cdd rule) all express bare-version:

- `VERSION` file: `0.9.0` (bare)
- `CHANGELOG.md` Release Coherence Ledger: rows `| 0.9.0 |`, `| 0.8.0 |`, etc.
- `.cdd/releases/0.9.0/34/` directory naming

Cycle #43's α implemented the AC3 fix (commit `ffcf6e7`) in the wrong direction: `TAG="$VERSION"` → `TAG="v$VERSION"`. The historical bare tags `0.5.0/0.6.0/0.7.0` were classified as "Bug 1 victims" when in fact they were the conforming ones; the v-prefixed historical tags were the non-conforming accidents.

The root cause is γ-side: F1 peer-enumeration before scaffold enumerated affected files but did not include a "check the canonical cdd rule for any convention being assumed" step. Same shape as the gap cnos #351 is patching (γ peer-enumeration at scaffold time) but extended to convention-rule checks.

## γ-axis grade revision

**Original:** γ A− (§5.2 cap).

**Revised:** **γ B** — recon failure on cnos cdd canonical-rule check during F1 peer-enumeration. The §5.2 cap is no longer the binding constraint; the recon-failure deduction is.

The recon-failure definition is anchored to cycle #34's F1 cdd-iteration (γ peer-enumeration before scaffold): γ must enumerate the relevant peers before authoring §Gap. In cycle #43, the relevant peer set should have included the canonical cdd rule for tag-prefix convention, not only tsc-local artifacts. γ enumerated tsc-local artifacts and missed the canonical source.

**Revised C_Σ:** (α A− · β A · γ B)^(1/3) ≈ (3.7 · 4.0 · 3.0)^(1/3) ≈ 3.55 → **B+**.

Original C_Σ A− (3.79) revised to B+ (3.55).

## F4 cdd-iteration finding (backported to cycle #43's records)

**F4 — cdd-protocol-gap: γ F1 peer-enumeration must include cnos cdd canonical-rule checks.**

*Source:* this addendum. Surfaced when user pointed out cdd convention is bare-version after cycle #43 shipped the v-prefix direction.

*Root cause:* F1 as currently practiced prescribes enumerating files in the directories the cycle's surfaces touch. It does not prescribe checking the cnos cdd skill bundle for any convention being assumed (file naming, tag format, schema field shape, etc.). Cycle #43's γ inferred the prefix convention from tsc-local artifacts (release.yml YAML, release.sh header comment, historical published releases) and treated their concurrence as evidence of canonical convention. None of those surfaces are cdd-canonical — they are tsc-local accidents.

*Trigger class:* cdd-protocol-gap. Affects every cycle that asserts a convention without explicit cross-check against cnos cdd skill files.

*Recommended cnos patch:* amend `proposals/cnos-cdd-gamma-peer-enumeration/ISSUE.md` (cnos #351 — γ peer-enumeration at scaffold time) with an additional step:

> "Before authoring §Gap, γ MUST also check the relevant cnos cdd skill files for the canonical rule of any convention being assumed (file naming, tag format, schema field shape, etc.). Inferring convention from local artifacts without checking the canonical source is a γ-side honest-claim violation analogous to α's rule 3.13(a)."

*Affected cnos cdd skill:* `cdd/gamma/SKILL.md` §Peer enumeration at scaffold time (per cnos #351 in-flight).

*Same shape as F3 from cycle #34:* there, γ inferred state from one source without checking the authoritative one. Here, γ inferred convention from tsc-local sources without checking cnos canonical. Different surfaces, same recon-failure class.

## Cycle #43 close-out: amended grades

| Axis | Original | Revised |
|---|---|---|
| α | A− | A− (unchanged — α implemented what γ scoped) |
| β | A | A (unchanged — β verified what α shipped; canonical-rule check was not in β's review surface either, but the binding gap is on γ) |
| γ | A− (§5.2 cap) | **B** (recon failure on canonical-rule check) |
| C_Σ | A− (3.79) | **B+** (3.55) |

The α and β grades stand. α implemented the AC3 that γ scoped; β verified the implementation against γ's scaffold. Neither role had a duty to second-guess γ's canonical-rule determination — that's γ's job at scaffold time. The grade revision is correctly attributed to the γ axis.

## Cycle #46 supersedes cycle #43's AC3

Cycle #46 (`cycle/46-impl`) reverts cycle #43's AC3 (commit `ffcf6e7`):

- `scripts/release.sh:54`: `TAG="v$VERSION"` → `TAG="$VERSION"` (AC1)
- `.github/workflows/release.yml` trigger: `'v*'` → `'[0-9]*'` + gate `expected="v$(...)"` → `expected="$(...)"` (AC2)
- `scripts/release.sh` header step #6: "Tag (v-prefixed)" → "Tag (bare version per cdd convention)" (AC3)
- This addendum (AC4)

γ fills the merge SHA here at cycle #46 close-out: **[pending — γ fills at merge]**.

Forward-only: historical v-prefixed tags (v0.3.0, v0.3.1, v0.4.0, v0.8.0, v0.9.0) stay as-is. They are immutable audit-trail of the period when v-prefix was assumed. Next bare-version release (e.g., 0.9.1 or 0.10.0) demonstrates the corrected convention end-to-end.

## Honest claim

This addendum is itself a §3.13(a) honesty signal: cycle #43 shipped a fix in the wrong direction because γ's recon was incomplete. The right response is not to retro-edit `gamma-closeout.md` (history is immutable) but to author this addendum alongside it, so that anyone reading the cycle #43 record sees both the original honest-at-the-time grade and the post-merge revision.

The recursive-coherence beat: cycle #46's load-bearing AC is this addendum, not the code changes. The code changes are mechanical. The addendum is the cycle making itself honest about its predecessor.
