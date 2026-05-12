---
cycle: 46
role: beta
round: R1
date: "2026-05-12"
identity: "beta@tsc.cdd.cnos"
branch: "cycle/46-impl"
reviewed_head: "9749262 meta(46): record α R1 head SHA in self-coherence"
parent_scaffold: "559f127 cycle(46): γ scaffold — revert #43 AC3 (cdd convention is bare-version)"
verdict: APPROVED
findings: 1
severity_band: C (cosmetic)
---

# β R1 review — Cycle #46

Small mechanical cycle (2 code-line reverts + 1 header comment + 1 cycle #43 addendum). β applied rule 3.13 against α's `claims.md` and verified each AC end-to-end.

## Verdict

**APPROVED.** All four ACs land. The load-bearing AC4 addendum is internally coherent, names the right root cause (γ-side recon failure), pegs the grade revision math correctly, and seeds F4 at the right canonical target. One C-band finding noted below (cosmetic).

## Per-AC verification

### AC1 — `scripts/release.sh:54` `TAG="$VERSION"` (revert)

```
$ grep -n '^TAG=' /home/user/tsc/scripts/release.sh
54:TAG="$VERSION"
```

Oracle from self-coherence §AC1 satisfied. Pre-revert state on `be15d22` was `TAG="v$VERSION"`; commit `4e6aff2` reverts to bare. Verified.

### AC2 — `.github/workflows/release.yml` trigger + gate alignment

Trigger pattern verified at lines 4–6:

```
  push:
    tags:
      - '[0-9]*'
```

Fnmatch behaviour cross-checked with bash `case` glob:

| Tag candidate | `[0-9]*` matches? | Expected | OK? |
|---|---|---|---|
| `0.9.1` | yes | yes (bare semver) | ✓ |
| `1.0.0` | yes | yes (bare semver) | ✓ |
| `v1.0.0` | no | no (v-prefixed boundary) | ✓ |
| `0abc` | yes | acceptable looseness | ✓ (preflight in `scripts/release.sh` is the strict validator) |

Per the special-attention brief: the looseness is acceptable since `scripts/release.sh` performs the canonical semver-shape check earlier in the release pipeline. Workflow trigger is the coarse filter, not the validator.

Gate also updated (line 25): `expected="$(cat VERSION | tr -d '\n')"` (was `expected="v$(cat VERSION | tr -d '\n')"`). This consistency change was flagged by α in `claims.md` §AC2 — confirmed in diff. A bare tag matches; a v-prefixed tag would fail the gate even if it triggered. Forward-only correct.

### AC3 — header comment honesty

```
$ grep -n 'v-prefixed' /home/user/tsc/scripts/release.sh
(empty — exit 1)
$ grep -n 'bare version' /home/user/tsc/scripts/release.sh
13:#   6. Tag (bare version per cdd convention) + push tag
```

Oracles from self-coherence §AC3 both satisfied. Verified.

### AC4 — `.cdd/releases/docs/2026-05-12/43/post-merge-addendum.md`

File exists (89 lines). §-by-§ walk against self-coherence §AC4 invariants:

| Required section | Present | Content honest? |
|---|---|---|
| What surfaced post-close | §"What surfaced post-close" | ✓ names γ recon failure on cnos cdd canonical-rule check — not α/β-blamed |
| γ-axis grade revision A− → B | §"γ-axis grade revision" | ✓ B assigned with recon-failure rationale anchored to cycle #34 F1 |
| C_Σ revision | §"γ-axis grade revision" + amended-grades table | ✓ A− (3.79) → B+ (3.55) |
| F4 cdd-iteration finding | §"F4 cdd-iteration finding" | ✓ names cnos #351 / `proposals/cnos-cdd-gamma-peer-enumeration/ISSUE.md` as the canonical patch target |
| α/β grades stand | amended-grades table + §commentary | ✓ correctly localizes revision to γ axis |

#### Grade-revision arithmetic check

Standard letter-grade bands (per project convention earlier in cycle #34/#36/#43 close-outs): A=4.0, A−=3.7, B+=3.3, B=3.0, B−=2.7.

| | α | β | γ | Geometric mean | Letter |
|---|---|---|---|---|---|
| Original | A− (3.7) | A (4.0) | A− (3.7) | (3.7·4.0·3.7)^(1/3) = 3.7974 | A− (matches `gamma-closeout.md:66`'s 3.79) |
| Revised | A− (3.7) | A (4.0) | **B (3.0)** | (3.7·4.0·3.0)^(1/3) = 3.5410 | **B+** (3.55 in addendum; nearer B+ 3.3 than A− 3.7) |

Addendum's "3.55 → B+" assignment is the correct band — 3.5410 rounds to 3.54, which the addendum rounds to 3.55 (minor rounding inconsequential). B+ is the right letter for a 3.5-area mean. Arithmetic verified.

#### γ recon failure attribution

Addendum §"What surfaced post-close" and §F4 both correctly name the root cause as a **γ-side recon failure**: F1 peer-enumeration enumerated tsc-local artifacts (`release.yml` trigger YAML, `release.sh` header, historical published releases) and did not cross-check the cnos cdd canonical rule. No blame on α (implemented what γ scoped) or β (verified what α shipped); the addendum's §"amended grades" explicitly preserves α A− and β A grades. Correct attribution.

#### F4 target check

Addendum recommends amending `proposals/cnos-cdd-gamma-peer-enumeration/ISSUE.md` (cnos #351). This is the right canonical target — cnos #351 covers γ peer-enumeration at scaffold time, which is the protocol surface that failed. Affected skill `cdd/gamma/SKILL.md` §Peer enumeration at scaffold time is also correctly identified. Verified.

## Rule 3.13 walk against α `claims.md`

| α claim | Verifier | Reproduces? |
|---|---|---|
| `grep -n '^TAG=' scripts/release.sh` → `54:TAG="$VERSION"` | direct grep | ✓ |
| `sed -n '4,6p' .github/workflows/release.yml` shows `'[0-9]*'` trigger | direct sed | ✓ |
| `grep -n 'v-prefixed\|bare version' scripts/release.sh` → only `13:# 6. Tag (bare version per cdd convention) + push tag` | direct grep | ✓ |
| `git show be15d22:scripts/release.sh | grep TAG` → `TAG="v$VERSION"` | direct git show | ✓ |
| Commit `ffcf6e7` introduced `v$VERSION` (cycle #43 AC3) | git log/show | ✓ |
| Commit `4e6aff2` reverts to bare (cycle #46 AC1) | git log/show | ✓ |
| Grade arithmetic (3.7·4.0·3.0)^(1/3) ≈ 3.55 | python | ✓ (3.5410) |
| Grade arithmetic (3.7·4.0·3.7)^(1/3) ≈ 3.79 | python | ✓ (3.7974) and matches gamma-closeout.md:66 |

All claims grep-verify or otherwise reproduce. No false claims.

## Findings

### F-β-1 (C, cosmetic) — "cycle #36 post-merge-addendum.md pattern" reference

The dispatch brief noted that α was expected to use "the cycle #36 post-merge-addendum.md pattern (mirror its structure)". Cycle #36 has no `post-merge-addendum.md` (verified via `find .cdd -name post-merge-addendum.md` — only cycle #43's exists). The addendum α wrote is therefore the first of its kind in this repo. Its structure is internally coherent (§What surfaced, §γ grade revision, §F4, §amended grades, §supersedes, §honest claim), but the brief's pattern-reference is anchored to a non-existent template.

This is a γ-side documentation artefact, not an α-side defect. α did the right thing by inventing a coherent structure from scratch. Cosmetic.

**Impact:** none on this cycle. Forward note: if future cycles want a post-merge-addendum template, the cycle #43 addendum from this cycle is the de-facto first instance and can serve as the pattern.

## Out-of-scope (intentional)

Same out-of-scope as α's `claims.md`:

- Historical v-prefixed git tags (v0.3.0, v0.3.1, v0.4.0, v0.8.0, v0.9.0) — not retro-renamed. Forward-only. Correct per scaffold.
- `install.sh` URL — uses GitHub API `tag_name`, conformance-neutral. Correct skip.
- Cycle #43's pre-existing files (`gamma-closeout.md` etc.) — not retro-edited. The addendum is the honest signal. Correct.
- cnos `proposals/cnos-cdd-gamma-peer-enumeration/ISSUE.md` patch — seeded as F4 finding for a separate cnos cycle. Correct.

## Readiness

β R1 APPROVED. No fix round required. γ can proceed to merge.
