# cdd/retro: close-out artifacts for cycles #331 + #333 (partial-protocol releases)

**Labels:** `docs, P1, cdd`
**Priority:** P1 — both cycles closed in protocol-violation per the very rules they introduced (cycle #331 patches 3, 5, 6; cycle #333 alpha/operator/CDD patches). The longer the gap remains, the more credibility the cdd protocol loses.
**Status:** Drafted; ready for cycle dispatch.
**Mode:** `docs-only` — no code change, no version bump. Retroactive reconstruction. Disconnect via the §2.5b path that cycle #331 introduced.

## Problem

**What exists:** Cycles #331 (PR #332, merged at `315e529`) and #333 (PR #333, merged at `6ffdf48`) shipped substantive cdd-skill patches to `cnos:main`. The patches are correct and present. Neither cycle produced any close-out artifacts.

Audit (post-merge state of `cnos:main`, performed 2026-05-09):

| Required by | Artifact | #331 | #333 |
|---|---|---|---|
| `gamma/SKILL.md` §2.10 row 1 | `.cdd/unreleased/{N}/alpha-closeout.md` | MISSING | MISSING |
| `gamma/SKILL.md` §2.10 row 2 | `.cdd/unreleased/{N}/beta-closeout.md` | MISSING | MISSING |
| `gamma/SKILL.md` §2.10 (closure declaration) | `.cdd/unreleased/{N}/gamma-closeout.md` | MISSING | MISSING |
| `CDD.md` §5.3a | `.cdd/unreleased/{N}/self-coherence.md` | MISSING | MISSING |
| `CDD.md` §5.3a | `.cdd/unreleased/{N}/beta-review.md` | MISSING | MISSING |
| `post-release/SKILL.md` (PRA) | `docs/gamma/cdd/.../POST-RELEASE-ASSESSMENT.md` | MISSING | MISSING |
| Cycle #331 patch 3 (its own §2.5b) | `.cdd/releases/docs/{ISO}/{N}/` cycle-dir move | MISSING | MISSING |
| Cycle #331 patch 4 (Rounds column) | `CHANGELOG.md` ledger row | MISSING | MISSING |
| Cycle #331 patch 6 (its own Step 5.6b) | `.cdd/unreleased/{N}/cdd-iteration.md` | MISSING (mandatory — cycle #331 produced 6 `cdd-*-gap` findings) | MISSING (mandatory — cycle #333 produced ≥3 `cdd-*-gap` findings) |
| Cycle #331 patch 6 | `.cdd/iterations/INDEX.md` | not initialized | not initialized |
| Cycle #331 patch 6 (cross-repo trace) | `.cdd/iterations/cross-repo/tsc/cdd-supercycle/` | not created | n/a (no cross-repo source) |
| Branch hygiene | `cycle/{N}-*` deleted on origin | NO (cycle/331-cdd-supercycle-learnings still on origin at d3c3b3c) | NO (cycle/330-tsc-upstream-patches still on origin at 30c02d1) |

The very directories these cycles introduced (`.cdd/releases/docs/`, `.cdd/iterations/`) do not exist on `cnos:main`.

**What is expected:** Per `gamma/SKILL.md` §2.10, no cycle closes until all closure-gate rows pass. Per cycle #331's own §3.8 rubric (patch 5):

- **C** = "partial-protocol release with multiple drift items"
- **< C** = "re-open and remediate; do not close"

Both cycles have ≥10 drift items; under their own rule they should be re-opened and remediated. This issue executes that remediation.

**Where they diverge:** The cycles closed without artifacts. The artifacts must be authored retroactively, honestly graded, and placed in the canonical locations the cycles' own patches define.

## Impact

- **Recursive irony.** Cycle #331 introduced rule 3.13 ("doc claims must match artifacts") yet its own PR-BODY claimed validation that did not happen. Cycle #331 introduced §2.5b for docs-only disconnect yet did not use the path itself. Cycle #331 introduced Step 5.6b for `cdd-iteration.md` yet did not produce the artifact for itself.
- **Authority drift.** Without the close-out artifacts, cnos cannot tell which cycle introduced which rule. The lineage that patch 6 mandates is missing exactly where it would matter most — for the cycle that introduced the lineage requirement.
- **Branch sprawl.** `cycle/330-tsc-upstream-patches` and `cycle/331-cdd-supercycle-learnings` accumulate on origin without close-out signal.
- **Audit failure.** Future γ reading `.cdd/iterations/INDEX.md` to measure cdd's learning rate finds nothing — exactly the friction patch 6 was designed to eliminate.
- **Precedent.** If the protocol's authoring cycle skips the protocol, every future cycle has a defensible reason to skip too.

## Status truth

| Surface | Status | Notes |
|---|---|---|
| Cycle #331 patches 1–6 on `cnos:main` | Shipped | Commits `1a4f196` … `d3c3b3c`, merged at `315e529` (2026-05-08) |
| Cycle #333 patches | Shipped | Commits `efed11e`, `c48d5a9`, `30c02d1`, merged at `6ffdf48` (2026-05-08) |
| Cycle #331 close-out artifacts | NOT SHIPPED | Audit above |
| Cycle #333 close-out artifacts | NOT SHIPPED | Audit above |
| `.cdd/releases/docs/` (introduced by patch 3) | Directory does not exist | |
| `.cdd/iterations/` (introduced by patch 6) | Directory does not exist | |
| `cycle/{330,331}-*` branches on origin | Still present | Should be deleted at close-out per `release/SKILL.md` §2.6a |
| `CHANGELOG.md` rows for cycles | MISSING | Last row is 3.73.0; 3.74.0 itself is also unrowed |

## Source of truth

| Claim / surface | Canonical source | Status |
|---|---|---|
| Cycle #331 PR | https://github.com/usurobor/cnos/pull/332 | merged |
| Cycle #333 PR | https://github.com/usurobor/cnos/pull/333 | merged |
| Cycle #331 merge SHA | `315e529` | confirmed `git log` |
| Cycle #333 merge SHA | `6ffdf48` | confirmed `git log` |
| Patch shape per cycle | `git log --oneline` per branch | confirmed (no review-driven changes against authored content) |
| Cross-repo source for #331 | `usurobor/tsc:.cdd/iterations/cross-repo/cnos/cdd-supercycle/LINEAGE.md` | shipped |
| Patch 5 honest-grading rubric | `cdd/release/SKILL.md` §3.8 (post-#331 merge) | shipped |
| Patch 6 cdd-iteration artifact | `cdd/CDD.md` §5.3a/§5.3b + `cdd/post-release/SKILL.md` Step 5.6b + `cdd/gamma/SKILL.md` §2.10 row 14 | shipped |
| §2.5b docs-only disconnect | `cdd/release/SKILL.md` §2.5b | shipped |

## Cycle scope sizing (informal — proposed by usurobor/tsc proposals/cnos-cdd-cycle-scope-sizing)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | 0 new modules | no |
| (b) Cross-module breadth | many files, all under `.cdd/` and `docs/gamma/cdd/` | moderate |
| (c) Lifecycle span | docs-only retroactive reconstruction | no |
| (d) MCA preconditions | n/a — `design-and-build` | no |
| (e) Independent shippability | could split per-cycle (#331 retro + #333 retro) but both share scaffolding | moderate |

**Decision:** keep whole. Both retro close-outs share template and scaffolding; splitting doubles the work without independent value. AC count is at-edge (9); the at-edge state is justified by the shared retro-reconstruction shape.

## Scope

**In scope:**

For **cycle #331** (PR #332):
- Retroactively author `.cdd/unreleased/331/{self-coherence,beta-review,alpha-closeout,beta-closeout,gamma-closeout,cdd-iteration}.md`. Each marked retroactive in its header.
- Honestly grade per §3.8 rubric. Cycle #331's own audit shows ≥10 drift items → grade is **C or below** for the cycle. Patches themselves are clean (verbatim, no review-driven changes); axis grades reflect both: α B/A- (clean diff, missing self-coherence at the time), β C/C+ (no `beta-review.md`, no enforcement of closure gate), γ C (no PRA, no closure declaration, no triage). C_Σ ≈ C+.
- Move cycle dir to `.cdd/releases/docs/{ISO-date}/331/` per the §2.5b path the cycle introduced.
- Author `cdd-iteration.md` listing the 6 cdd-skill-gap findings the cycle's own patches addressed (mandatory per §2.10 row 14).

For **cycle #333** (PR #333, closing #330):
- Same artifact set retroactively for cycle 333.
- Honest grading: ≥10 drift items → grade is C or below. Same shape.
- Move cycle dir to `.cdd/releases/docs/{ISO-date}/333/`.
- Author `cdd-iteration.md` for the cycle's findings (alpha §2.6 rows 11–13, operator stream-json default, CDD §1.6b re-dispatch complexity — ≥3 findings).

**For both cycles:**
- Initialize `.cdd/iterations/INDEX.md` with rows for cycles 331 and 333.
- Initialize `.cdd/iterations/cross-repo/tsc/cdd-supercycle/` (mirror of `usurobor/tsc:.cdd/iterations/cross-repo/cnos/cdd-supercycle/`) with `LINEAGE.md` confirming the cross-repo trace.
- Author PRA(s) at `docs/gamma/cdd/docs/{ISO-date}/POST-RELEASE-ASSESSMENT.md`. May be one PRA covering both cycles (since they share the protocol-skip pattern) or one per cycle — γ decides at authoring time.
- Add CHANGELOG ledger rows for both cycles. Honest grades.
- Delete the `cycle/330-tsc-upstream-patches` and `cycle/331-cdd-supercycle-learnings` branches on origin.
- Disconnect THIS cycle (the retro cycle) via §2.5b — including this cycle's own `cdd-iteration.md` (this cycle is itself a `cdd-protocol-gap` finding triage event).

**Out of scope:**
- Re-running the patches' β review (the patches landed; what's missing is the close-out, not the work).
- Modifying any of cycle #331's or #333's commits or their content.
- Any new cdd-skill patches.
- Tagging `3.74.0` to include #331/#333 (they merged AFTER 3.74.0; the next tag is a separate γ decision).
- Cross-repo cleanup on `usurobor/tsc:.cdd/iterations/cross-repo/cnos/cdd-supercycle/` — that's tsc's responsibility per its own LINEAGE.md (which says delete after cnos PR merges + cnos's own `cdd-iteration.md` exists; this issue creates that file, then tsc can clean up).

**Deferred:**
- Validation of the heuristic in `usurobor/tsc:.cdd/proposals/cnos-cdd-cycle-scope-sizing/ISSUE.md` — that's a separate cycle.

## Acceptance criteria

### AC1: Cycle #331 close-out artifact set complete

**Invariant:** `.cdd/releases/docs/{ISO-date}/331/` exists on `cnos:main` and contains exactly: `self-coherence.md`, `beta-review.md`, `alpha-closeout.md`, `beta-closeout.md`, `gamma-closeout.md`, `cdd-iteration.md`. Each file's header explicitly marks it as retroactively reconstructed, citing this cycle's issue number.
**Oracle:** `find .cdd/releases/docs -path '*331*' -name '*.md' | wc -l` returns ≥6; `head -20` of each file shows the `retroactive: true` header marker.
**Positive:** All 6 files present; retroactive headers present.
**Negative:** Any file missing OR file headers don't mark as retroactive.
**Surface:** `.cdd/releases/docs/{ISO-date}/331/`.

### AC2: Cycle #333 close-out artifact set complete

**Invariant:** Same as AC1, for cycle 333: `.cdd/releases/docs/{ISO-date}/333/` exists with the 6 files, retroactive headers.
**Oracle:** `find .cdd/releases/docs -path '*333*' -name '*.md' | wc -l` returns ≥6.
**Positive:** All 6 files present.
**Negative:** Any file missing.
**Surface:** `.cdd/releases/docs/{ISO-date}/333/`.

### AC3: Honest grading per §3.8 rubric

**Invariant:** Each cycle's PRA (or close-out) records α/β/γ grades following §3.8 rubric. Both cycles' C_Σ ≤ C+ (recall: ≥10 drift items per cycle → at minimum **C**; honesty requires no inflation). Patches themselves graded separately from cycle execution.
**Oracle:** Manual review against §3.8. `grep -E "C_Σ|alpha|beta|gamma" docs/gamma/cdd/docs/{ISO}/POST-RELEASE-ASSESSMENT.md` shows letter grades per axis.
**Positive:** Grades are honest; rubric is cited; grades ≤ C+ for both cycles.
**Negative:** Inflated grades; or grades not justified against drift-item count; or rubric not cited.
**Surface:** PRA(s) at `docs/gamma/cdd/docs/{ISO}/`.

### AC4: cdd-iteration.md per Step 5.6b

**Invariant:** Each cycle's `.cdd/releases/docs/{ISO}/{N}/cdd-iteration.md` lists the cycle's `cdd-*-gap` findings per the per-finding shape from `cdd/post-release/SKILL.md` Step 5.6b. Cycle #331 lists 6 findings (one per patch). Cycle #333 lists ≥3 findings. Each finding has Source / Class / Trigger / Description / Root cause / Disposition (`patch-landed` for all, since the patches are already on main).
**Oracle:** `grep -cE '^### F[0-9]+' .cdd/releases/docs/*/331/cdd-iteration.md` returns 6; same for `333` returns ≥3.
**Positive:** Both files match the per-finding shape; class vocabulary correct.
**Negative:** Findings missing OR class vocabulary wrong OR disposition not `patch-landed`.
**Surface:** Per-cycle `cdd-iteration.md`.

### AC5: `.cdd/iterations/INDEX.md` initialized

**Invariant:** `.cdd/iterations/INDEX.md` exists with header row + ≥3 data rows: cycle 331, cycle 333, AND cycle THIS-N (the retro cycle's own row, since this cycle itself produces a `cdd-protocol-gap` finding by triaging the others).
**Oracle:** `grep -cE '^\| [0-9]+ \|' .cdd/iterations/INDEX.md` returns ≥3.
**Positive:** Header + 3 rows present; columns match Step 5.6b template.
**Negative:** File missing OR row count < 3 OR columns drift from template.
**Surface:** `.cdd/iterations/INDEX.md`.

### AC6: Cross-repo trace mirror initialized

**Invariant:** `.cdd/iterations/cross-repo/tsc/cdd-supercycle/LINEAGE.md` exists on `cnos:main` and references the cross-repo source in `usurobor/tsc:.cdd/iterations/cross-repo/cnos/cdd-supercycle/LINEAGE.md` by commit SHA. The mirror confirms each of the 6 patches landed and acknowledges the trace is now bilateral.
**Oracle:** `grep -E "usurobor/tsc|772ddc0" .cdd/iterations/cross-repo/tsc/cdd-supercycle/LINEAGE.md` matches.
**Positive:** File present; cites tsc-side commit SHA.
**Negative:** File missing OR no cross-reference to tsc source.
**Surface:** `.cdd/iterations/cross-repo/tsc/cdd-supercycle/LINEAGE.md`.

### AC7: PRA authored

**Invariant:** `docs/gamma/cdd/docs/{ISO-date}/POST-RELEASE-ASSESSMENT.md` exists and follows `cdd/post-release/SKILL.md` template. Either one combined PRA covering both cycles or one per cycle (γ's call). Each PRA includes §3 Process Learning naming the protocol-skip pattern as the central failure mode of the original cycles, and §4b Cycle Iteration since two §9.1 triggers fired (loaded skill failed to prevent a finding; recurring failure mode across two cycles).
**Oracle:** `find docs/gamma/cdd/docs -name 'POST-RELEASE-ASSESSMENT.md' -newer .cdd/iterations/INDEX.md` returns ≥1; manual review of §3 + §4b.
**Positive:** PRA present; §3 names the protocol-skip; §4b names the §9.1 trigger and disposition.
**Negative:** PRA missing OR §3/§4b empty/silent on the protocol-skip.
**Surface:** `docs/gamma/cdd/docs/{ISO-date}/POST-RELEASE-ASSESSMENT.md`.

### AC8: CHANGELOG ledger rows added

**Invariant:** `CHANGELOG.md` Release Coherence Ledger gains rows for cycles #331 and #333, with the Rounds column populated per patch 4. Grades match AC3.
**Oracle:** `grep -nE '^\| #?33[13]' CHANGELOG.md` returns 2 matches.
**Positive:** Both rows present; Rounds column filled; grades match PRA.
**Negative:** Either row missing OR Rounds column blank OR grades drift from PRA.
**Surface:** `CHANGELOG.md`.

### AC9: Branch cleanup + this cycle's own clean disconnect

**Invariant:** `cycle/331-cdd-supercycle-learnings` and `cycle/330-tsc-upstream-patches` are deleted on origin. THIS cycle's own `.cdd/unreleased/{N}/` is moved to `.cdd/releases/docs/{ISO-date}/{N}/` per §2.5b (recursive coherence — the cycle that fixes the protocol-skip itself follows the protocol).
**Oracle:** `git ls-remote origin | grep -E 'cycle/(330|331)'` returns no matches; `find .cdd/releases/docs -path '*{THIS-N}*'` returns the cycle dir.
**Positive:** Branches deleted; this cycle's own dir moved.
**Negative:** Either branch lingers OR this cycle's own dir is in `.cdd/unreleased/`.
**Surface:** Origin branch list; `.cdd/releases/docs/`.

## Proof plan

**Invariant:** Cnos's protocol-self-application is restored: cycles #331 + #333 + this cycle have full close-out artifact sets at canonical paths; the cdd-iteration aggregator is initialized; cross-repo trace is bilateral.
**Surface:** `.cdd/releases/docs/`, `.cdd/iterations/`, `docs/gamma/cdd/docs/`, `CHANGELOG.md`, origin branch list.
**Oracle:** Composite — AC1–AC9 each map to a grep or filesystem check; β verifies each AC and additionally applies rule 3.13 (honest-claim verification) to the retroactive PRA — every measurement quoted in the PRA must trace to artifacts in this commit.
**Positive case:** All 9 ACs pass; grep checks return expected counts; honest grades present.
**Negative case:** Any AC fails; or grades inflated (β should reject).
**Operator-visible projection:** `.cdd/iterations/INDEX.md` becomes the single source of truth for "what has cdd learned about itself"; future cycles can extend it. The PRA's §4b establishes a pattern: when a cycle introduces a new protocol rule, the cycle that follows must verify the introducing cycle followed the rule.
**Known gap:** The original two cycles' β reviews cannot be reconstructed (they may not have happened). The retroactive `beta-review.md` honestly states "no in-cycle β review record exists; this file reconstructs review state from post-merge inspection of the merged diff" rather than fabricating one.

## Skills to load

**Tier 3:**
- `cnos.eng/skills/eng/writing` — for retroactive narrative reconstruction of the close-out artifacts
- (No code skills — `docs-only` cycle.)

**Why:**
- All work is structured prose (close-out artifacts, PRA, ledger rows, lineage docs). No code.

## Active design constraints

- **Honest grading.** No A or A- grades for cycles #331 or #333. The §3.8 rubric the cycles introduced applies to them. Inflation is a binding finding.
- **Retroactive headers.** Every reconstructed artifact's header must mark it `retroactive: true` with the issue number that triggered the reconstruction. Future readers must not mistake reconstruction for original artifact.
- **No fabrication.** Where evidence is missing (e.g., no `beta-review.md` was ever written), the retroactive artifact says so explicitly. Reconstruction ≠ invention.
- **Recursive coherence on this cycle's own close-out.** The cycle that fixes the protocol-skip MUST ITSELF FOLLOW THE PROTOCOL. Failure here is non-negotiable; β should reject any disconnect that skips this cycle's own close-out.
- **Bilateral cross-repo lineage.** `cnos:.cdd/iterations/cross-repo/tsc/cdd-supercycle/` and `usurobor/tsc:.cdd/iterations/cross-repo/cnos/cdd-supercycle/` must reference each other by commit SHA.
- **Branch cleanup is mechanical.** Per `release/SKILL.md` §2.6a — if it's merged, it's dead. Delete the branches.
- **Disconnect path:** `cnos:.cdd/releases/docs/{ISO-date}/{N}/` (the §2.5b path that cycle #331 itself introduced).

## Related artifacts

- `usurobor/cnos#331` (cycle 331 issue, closed) — first failure case
- `usurobor/cnos#332` (PR for #331, merged at `315e529`) — patches landed
- `usurobor/cnos#330` (cycle 330 issue) — second failure case
- `usurobor/cnos#333` (PR for #330, merged at `6ffdf48`) — patches landed
- `cnos:src/packages/cnos.cdd/skills/cdd/release/SKILL.md` §2.5b (the path this cycle uses)
- `cnos:src/packages/cnos.cdd/skills/cdd/release/SKILL.md` §3.8 (the rubric this cycle scores against)
- `cnos:src/packages/cnos.cdd/skills/cdd/post-release/SKILL.md` Step 5.6b (the artifact this cycle creates)
- `cnos:src/packages/cnos.cdd/skills/cdd/gamma/SKILL.md` §2.10 row 14 (the gate this cycle should have passed originally)
- `usurobor/tsc:.cdd/iterations/cross-repo/cnos/cdd-supercycle/LINEAGE.md` (cross-repo source)
- `usurobor/tsc#27` (cycle 27 close-out) — precedent for retroactive close-out (v0.4.0 retro)

## Non-goals

- Tagging cnos `3.75.0` to include cycles #331/#333 — separate γ decision once retro close-outs land.
- Reverting or modifying any of cycle #331's or #333's patches.
- Adding new cdd-skill patches.
- Re-running the original cycles' β reviews.
- Updating `usurobor/tsc:.cdd/iterations/cross-repo/cnos/cdd-supercycle/` — tsc-side cleanup is tsc's responsibility once this cycle's `cdd-iteration.md` exists.
- Validating cycle-scope-sizing heuristic (deferred to its own cycle).

## Success / closure condition

This issue is closeable when:
- AC1–AC9 each map to evidence in the branch diff.
- β applies rule 3.13 to the retro PRA and confirms every measurement traces to commit artifacts.
- Both original cycles graded honestly (≤ C+) per §3.8 rubric they introduced.
- This cycle's own close-out follows the full protocol (recursive coherence — patch 6's `cdd-iteration.md`, §2.5b disconnect, branch deletion, INDEX.md update, PRA authored).
- Cycle branches `cycle/330-tsc-upstream-patches` and `cycle/331-cdd-supercycle-learnings` deleted from origin.
- Master cnos #331 and #333 issues remain closed (this cycle does not re-open them; the cycles closed in spirit, just without artifacts — this fixes the artifacts).
