---
cycle: 46
role: alpha
round: R1
date: "2026-05-12"
identity: "alpha@tsc.cdd.cnos"
branch: "cycle/46-impl"
parent_scaffold: "559f127 cycle(46): γ scaffold — revert #43 AC3 (cdd convention is bare-version)"
---

# Honest-claim manifest — Cycle #46 α R1

This manifest covers the four ACs in `.cdd/unreleased/46/self-coherence.md`. Cycle is mechanical: 2 code-line reverts + 1 comment + 1 addendum. The load-bearing AC is the addendum (AC4), which makes cycle #43's record honest.

## Wiring claim

**AC1 — `scripts/release.sh:54` reads bare `TAG="$VERSION"`.**

Verification on this branch (`cycle/46-impl`, HEAD `e01d976` at claim time):

```
$ grep -n '^TAG=' scripts/release.sh
54:TAG="$VERSION"
```

Running `scripts/release.sh 0.9.1` (mental walk, not executed — release-gated by clean tree + on main + synced) would now construct `TAG="0.9.1"` rather than `TAG="v0.9.1"`. The downstream `git tag "$TAG"` and `git push origin "$TAG"` calls (lines 113, 115) therefore push a bare-version tag.

**AC2 — `.github/workflows/release.yml` triggers on bare-version tags.**

```
$ sed -n '4,6p' .github/workflows/release.yml
  push:
    tags:
      - '[0-9]*'
```

Pattern chosen: `'[0-9]*'`. Matches `0.9.1`, `0.10.0`, `1.0.0` (bare semver). Does NOT match `v0.9.1` (v-prefixed). Forward-only: future bare releases trigger the workflow; historical v-prefixed tags do not (they were manually published anyway). Same surface logic as cycle #43's Bug 1 fix, just rotated 180° to match the actual canonical convention.

Gate alignment: `expected="$(cat VERSION | tr -d '\n')"` (line 25) now compares the literal bare contents of `VERSION` against `GITHUB_REF_NAME`. A bare tag matches; a v-prefixed tag would fail the gate even if it somehow triggered.

**AC3 — `scripts/release.sh` header comment expresses bare convention.**

```
$ grep -n 'v-prefixed\|bare version' scripts/release.sh
13:#   6. Tag (bare version per cdd convention) + push tag
```

`grep 'v-prefixed' scripts/release.sh` returns empty. Oracle from §AC3 satisfied.

## Source-of-truth alignment

All three surfaces touched in this cycle (release.sh TAG construction, release.sh header comment, release.yml trigger pattern + gate prefix) now consistently express the bare-version convention. Cross-checked against the broader cdd-canonical surfaces:

| Surface | Convention expressed | Aligned? |
|---|---|---|
| `VERSION` file | `0.9.0` (bare) | ✓ baseline |
| `CHANGELOG.md` ledger rows | `\| 0.9.0 \|`, `\| 0.8.0 \|`, … (bare) | ✓ baseline |
| `.cdd/releases/0.9.0/34/` dir | bare | ✓ baseline |
| `scripts/release.sh:54` (this cycle) | `TAG="$VERSION"` → bare | ✓ now aligned |
| `scripts/release.sh:13` (this cycle) | "Tag (bare version per cdd convention)" | ✓ now aligned |
| `.github/workflows/release.yml:6` (this cycle) | `tags: ['[0-9]*']` | ✓ now aligned |
| `.github/workflows/release.yml:25` (this cycle) | `expected="$(cat VERSION ...)"` | ✓ now aligned |

No remaining surface within this cycle's diff range expresses v-prefix. Historical v-prefixed tags (v0.3.0, v0.3.1, v0.4.0, v0.8.0, v0.9.0) are out of scope per cycle scaffold (history is immutable; forward-only fix).

## No-false-negation claim

The §Gap assertion — "cycle #43 AC3 went in the wrong direction per cdd canonical convention" — is verifiable from git history, not just user testimony:

```
$ git show be15d22:scripts/release.sh | grep -n 'TAG=' | head -1
54:TAG="v$VERSION"
```

That is the pre-revert state on `main` at `be15d22` (cycle #43 INDEX merge). Cycle #43 commit `ffcf6e7` is the change that introduced `v$VERSION`; this cycle's commit `4e6aff2` reverts it.

The §Gap is not negated by absence: the canonical convention (bare) is positively attested by `VERSION`, `CHANGELOG.md`, and `.cdd/releases/0.9.0/`. Cycle #43's direction is what was novel and unsupported by canon, not the revert.

## AC4 grade revision rationale

The post-merge addendum (`.cdd/releases/docs/2026-05-12/43/post-merge-addendum.md`) revises cycle #43's γ-axis grade A− → B and C_Σ A− (3.79) → B+ (3.55). The rationale is anchored to a pre-existing definition, not freshly invented:

- **Recon-failure definition** is from cycle #34's F1 cdd-iteration finding: γ must enumerate the relevant peers before authoring §Gap.
- **The missed peer** in cycle #43 was the cnos cdd canonical rule for tag-prefix convention. γ enumerated tsc-local artifacts (`release.yml`, `release.sh` header, historical published releases) and treated their concurrence as canonical. None of those are cdd-canonical sources.
- **α and β grades stand** because their honest-claim duty was to implement and verify what γ scoped. Neither role had a duty to second-guess γ's canonical-rule determination — that is γ's job at scaffold time. The grade revision is correctly localized to the γ axis.
- **C_Σ recomputed:** `(α A− · β A · γ B)^(1/3) ≈ (3.7 · 4.0 · 3.0)^(1/3) ≈ 3.55 → B+`.
- **F4 finding** is seeded in the addendum's §F4 section, recommending a cnos patch to `proposals/cnos-cdd-gamma-peer-enumeration/ISSUE.md` (cnos #351) so that γ peer-enumeration at scaffold time explicitly includes a "check the cnos cdd skill bundle for the canonical rule of any convention being assumed" step.

The grade revision is itself a §3.13(a) honesty signal (per the addendum's §Honest claim section): cycle #43's `gamma-closeout.md` is not retro-edited (history immutable); the addendum sits alongside it.

## Out-of-scope (intentional non-changes)

- Historical v-prefixed git tags (v0.3.0, v0.3.1, v0.4.0, v0.8.0, v0.9.0) — not retro-renamed. Forward-only.
- `install.sh` URL construction — uses `latest release tag_name` from GitHub API, conformance-neutral.
- Cycle #43's `gamma-closeout.md`, `alpha-closeout.md`, `beta-review.md`, `cdd-iteration.md`, `claims.md` — not retro-edited. The post-merge addendum is the honest signal.
- cnos `proposals/cnos-cdd-gamma-peer-enumeration/ISSUE.md` — F4 finding is seeded in the addendum; actual cnos patch is a cnos cycle, not a tsc cycle.

## Readiness

α R1 is ready for β review. Head SHA recorded in self-coherence §Head SHA after this manifest commits.
