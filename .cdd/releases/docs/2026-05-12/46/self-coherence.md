---
cycle: 46
issue: "#46"
branch: "cycle/46"
mode: "design-and-build"
disconnect: "§2.5b docs-only-plus-CI — no version bump (2-line revert + workflow-trigger change + 1 comment + 1 addendum)"
date: "2026-05-12"
dispatch_configuration: "§5.2 single-session δ-as-γ via Claude Code Agent tool. γ axis grade capped at A− per §3.8 amendment."
self_application: "Dogfoods cycle #36 follow-on patches: F1 (peer-enumeration — this time including cnos cdd canonical-rule check, the gap cycle #43 exposed), F2 (SHA-anchored CI verification), F3 (parent-session quiescence)."
supersedes: "Cycle #43 AC3 (TAG='v$VERSION') — reverts based on user confirmation that cdd convention is bare-version, not v-prefix"
---

# Self-Coherence — Cycle #46

## Gap (peer-enumerated per F1 discipline — including cnos cdd convention check)

Peer-enumeration on main `be15d22` (run before authoring this §Gap):

| Surface | State | Conformance to cdd bare-version convention |
|---|---|---|
| `VERSION` file | `0.9.0` (bare) | ✓ conforming |
| `CHANGELOG.md` ledger rows | all bare (`\| 0.9.0 \|`, `\| 0.8.0 \|`, etc.) | ✓ conforming |
| `.cdd/releases/0.9.0/34/` directory | bare version | ✓ conforming |
| `scripts/release.sh:54` (post-#43) | `TAG="v$VERSION"` | **✗ non-conforming — to revert (AC1)** |
| `scripts/release.sh` header comment | "Tag (v-prefixed)" | **✗ non-conforming — to update (AC3)** |
| `.github/workflows/release.yml:5` | `tags: ['v*']` | **✗ non-conforming — to fix (AC2)** |
| Historical tags 0.5.0/0.6.0/0.7.0 | bare (script-produced before #43) | ✓ conforming — were correct |
| Historical tags v0.3.0/v0.3.1/v0.4.0/v0.8.0/v0.9.0 | v-prefixed (manual + post-#43 sigma) | ✗ non-conforming historical artifacts; **forward-only — not retro-renamed** |
| `install.sh` URL construction | reads `latest release tag_name` from API | conformance-neutral (uses whatever tag name exists) |

**Cnos cdd canonical-rule check (the step γ missed in cycle #43):**

User confirmed bare-version convention. cdd's principle: versions are content; tags should match `VERSION` exactly. The v-prefix on git tags was a tsc-local accident introduced manually for early releases, then assumed canonical when authoring `release.yml` trigger pattern. cycle #43's F1 captured tsc-local artifacts but did not check the canonical cdd rule for the prefix convention — γ-side recon failure.

**Gap reality:**

1. Cycle #43 shipped AC3 in the wrong direction. `scripts/release.sh:54` produces v-prefixed tags, but cdd convention is bare.
2. `.github/workflows/release.yml` trigger pattern `tags: ['v*']` only matches v-prefixed tags. With bare convention, future releases (e.g., a bare `0.9.1` tag) would not trigger the workflow at all — same root failure mode as cycle #43's Bug 1 (0.5.0/0.6.0/0.7.0 not triggering), just from the opposite direction.
3. Historical v-prefixed tags (v0.3.0, v0.3.1, v0.4.0, v0.8.0, v0.9.0) are non-conforming but history is immutable. Forward-only: new releases will use bare convention.
4. Cycle #43's γ-axis grade (A−, §5.2 cap) was based on F1 peer-enumeration covering the right surfaces but missing the canonical-rule check. Honest grade revision: **B** (recon failure on canonical-rule check).
5. Cycle #43's cdd-iteration needs a new finding (F4): F1 peer-enumeration must extend to cnos cdd canonical-rule checks, not just affected-files enumeration.

## Mode

`design-and-build`. Small mechanical cycle. Two-line code change + one comment + one addendum file. Not MCA.

## Cycle scope sizing (per cnos §1.6c)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | 2 lines | no |
| (b) Cross-module breadth | `scripts/release.sh` + `release.yml` + cycle #43 addendum | low |
| (c) Lifecycle span | mechanical | no |
| (d) MCA preconditions | not MCA | n/a |
| (e) Independent shippability | one cohesive convention fix | no |

**Decision:** keep whole. **4 ACs**, low-typical band. Smallest cycle in the recent sequence.

## ACs (from issue #46)

**AC1 — Revert release.sh TAG construction.**
- *Invariant:* `scripts/release.sh:54` reads `TAG="$VERSION"`.
- *Oracle:* `grep -n '^TAG=' scripts/release.sh` returns `54:TAG="$VERSION"`.

**AC2 — Fix release.yml trigger.**
- *Invariant:* `on: push: tags:` pattern matches bare-version tags (e.g., `'[0-9]*'`).
- *Oracle:* a bare semver-shaped tag would trigger; pattern doesn't require v prefix.

**AC3 — Header comment honesty.**
- *Invariant:* `scripts/release.sh` header comment reflects bare convention.
- *Oracle:* `grep 'v-prefixed' scripts/release.sh` empty; `grep 'bare version' scripts/release.sh` ≥1.

**AC4 — Cycle #43 post-merge addendum.**
- *Invariant:* `.cdd/releases/docs/2026-05-12/43/post-merge-addendum.md` records the recon failure + γ-grade revision (A− → B) + F4 finding seeding for the cdd-iteration.
- *Oracle:* file exists, contains: §Gap-finding, §γ-axis grade revision, §F4 cdd-iteration finding for cycle #43's records.
- *Surface:* new addendum file.

## Honest-claim manifest (R1 must produce)

α R1 must produce `claims.md` with:

1. **Wiring:** the revert produces a bare-tag on running `scripts/release.sh 0.9.1` (test-only — don't actually tag).
2. **Source-of-truth alignment:** all three surfaces (release.sh code, header comment, release.yml trigger) now consistently express the bare-version convention.
3. **No false negation:** the §Gap claim "cycle #43 AC3 went in wrong direction per cdd canonical rule" is verifiable: user confirmed in conversation; commit ffcf6e7 changed `TAG="$VERSION"` → `TAG="v$VERSION"`.
4. **γ-grade revision rationale:** the addendum's grade revision is anchored to the recon-failure definition in cycle #34's F1 cdd-iteration (γ peer-enumeration before scaffold) — γ should have checked the cdd canonical rule and didn't.

## CDD Trace

1. **Receive** — γ peer-enumerated (F1) INCLUDING the cnos cdd canonical-rule check this time. Result: §Gap conformance table.
2. **Dispatch α** — Agent tool, fresh context.
3. **α self-coherence + claims.md + readiness signal.**
4. **Dispatch β** — Agent tool, fresh context.
5. **Fix rounds if any.**
6. **Merge** — `cycle/46-impl` → main via PR.
7. **γ F2 verification (SHA-anchored)** — verify katas green on merge SHA.
8. **γ close-out** — only after F2 confirms green.
9. **cdd-iteration** — F1 self-application captured (this time done right); F4 finding for cycle #43 backported via addendum.

## Dispatch configuration

- **Operator δ = γ** (single-session via Agent tool — §5.2)
- **Identities:** `{alpha,beta,gamma}@tsc.cdd.cnos`
- **γ axis grade cap:** A− (§5.2)

**F1 self-application this cycle is the load-bearing self-fix:** cycle #43's F1 missed the canonical-rule check. This cycle's F1 includes it explicitly (§Gap conformance table column 3).

## Head SHA

α R1 head: `f1b954e` (closeout commit — `closeout(46): α R1 closeout + honest-claim manifest`).

Commit chain on `cycle/46-impl` from γ scaffold:

| SHA | Subject |
|---|---|
| `559f127` | `cycle(46): γ scaffold — revert #43 AC3 (cdd convention is bare-version)` |
| `4e6aff2` | `fix(release-script): revert TAG to bare version — AC1` |
| `1d11729` | `fix(ci/release): trigger on bare-version tags — AC2` |
| `015a11d` | `docs(release-script): header comment honesty — AC3` |
| `e01d976` | `docs(43): post-merge addendum with γ-grade revision — AC4` |
| `f1b954e` | `closeout(46): α R1 closeout + honest-claim manifest` |
| (this commit) | `meta(46): record α R1 head SHA in self-coherence` |
