---
cycle: 32
issue: "#32"
branch: "cycle/32"
mode: "design-and-build"
disconnect: "§2.5b (docs-only, no tag — except potentially a v3.2.1 spec patch bump if D3 ships)"
date: "2026-05-09"
---

# Self-Coherence — Cycle #32

## Gap

Master #23 closed with one named-debt sub-issue (#28 Claude CLI provider, P3 deferred) and a cleanup-cycle commitment (#32) bundling deferred outputs from the supercycle's γ-closeouts plus repo hygiene. Specifically:

- **Cycle #29 D2** — `engine.tsc` target does not exclude `engine/ocaml/_build/**`. Self-measurement of the engine target is contaminated by build artifacts; β scores for the engine target are wrong.
- **Cycle #29 D3** — `spec/tsc-oper.md §6` does not canonicalize the cross-target aggregate `C_Σ` (geometric mean across spec/engine/repo target scores). Cycle #29's self-coherence report had to compute it ad-hoc; the formula isn't normative.
- **Cycle #26 γ MCI** — `CONTRIBUTING.md` and `.github/pull_request_template.md` carry stale Python/pytest references. Python is fully retired; these surfaces actively mislead new contributors.
- **Cycles #27 + #29 protocol-skip residual** — `.cdd/unreleased/27/` and `.cdd/unreleased/29/` directories still on `tsc:main` (docs-only-no-tag cycles never moved to `.cdd/releases/docs/{ISO}/{N}/`).
- **CI red on main** — pre-existing infrastructure failure (`libcurl4-gnutls-dev` apt 404 mirror) per cycle #26 β observation.
- **Stale issues** — #6 (Apr 2) and #22 (Apr 6) likely subsumed by cycle #25/#29 work but never closed.
- **Branch hygiene** — multiple stale `claude/*` (pre-#287), `pr-bundles/*`, `proposals/*`, and `courier/*` branches accumulating on origin.

The selected gap is the *cleanup-cycle bundle* per master #23 close-out's next-MCA commitment.

## Mode

`design-and-build` — D3 (spec/tsc-oper.md §6 canonicalization) requires design judgment for the cross-target aggregate formula and may need a v3.2.0 → v3.2.1 spec patch bump; the rest is mechanical hygiene. This cycle does not qualify as MCA per `cdd/issue/SKILL.md` §Mode declaration: no separate design+plan committed at a stable path; D3's design lives in this self-coherence document and the eventual α implementation.

## Cycle scope sizing (per cnos cdd/issue §Cycle scope sizing, post-#334)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | 1 — D3 requires a small spec section addition | low |
| (b) Cross-module breadth | 5+ files (`targets/engine.tsc`, `spec/tsc-oper.md`, `CONTRIBUTING.md`, `.github/pull_request_template.md`, `.cdd/`, `CHANGELOG.md`, plus possibly `scripts/release.sh` if #30 folds in) | moderate |
| (c) Lifecycle span | docs cycle with one spec patch | borderline (spec patch is normative; rest is hygiene) |
| (d) MCA preconditions | not MCA | n/a |
| (e) Independent shippability | D3 (spec patch + version bump) is genuinely a different mental model from the rest; the hygiene items are tightly coupled with each other | **moderate split signal** |

**Decision:** **keep whole** — with explicit justification.

**Justification:** Cleanup-cycles bundle disparate hygiene by design; splitting D3 out as #32b would add process overhead (separate γ scaffold, separate β review, separate close-out artifacts) for a single-section spec addition. The cycle-scope-sizing heuristic permits keep-whole with at-edge AC count when γ articulates a tight justification — cleanup is the natural unit here. If D3 turns out to require a spec version bump (v3.2.1), the version bump rides with the cleanup commit; CHANGELOG ledger row carries it.

**At-edge acknowledgment:** AC count below targets the upper end of "typical" (5–7) and may reach 8–10 ("at-edge"). β should pay particular attention to whether D3's spec patch and the hygiene items actually cohere — if any sub-deliverable could ship independently with no side effects, it's a candidate for split in the next iteration.

## Active Skills

**Tier 1a (always loaded):**
- `cdd/CDD.md` (post-#331/#333/#334/#335 patches)
- `cdd/SKILL.md`
- `cdd/alpha/SKILL.md` (current role for α)

**Tier 1b (lifecycle phase skills):**
- `cdd/issue/SKILL.md` (mode declaration, MCA preconditions, cycle scope sizing)
- `cdd/release/SKILL.md` (§2.5b docs-only disconnect, §3.8 honest-grading rubric)
- `cdd/post-release/SKILL.md` (Step 5.6b cdd-iteration.md, §4 review-quality fields)
- `cdd/review/SKILL.md` (rule 3.13 honest-claim verification)

**Tier 1c (β closure bundle, β only):**
- `cdd/release/SKILL.md`
- `cdd/post-release/SKILL.md`

**Tier 2 (engineering bundle):**
- `cnos.eng/skills/eng/writing` (prose patches to docs + spec)
- `cnos.eng/skills/eng/ocaml` (light — `targets/engine.tsc` is a manifest, not OCaml code, but cross-reference is in scope)

**Tier 3 (issue-specific):**
- None named beyond Tier 1b. The cycle is hygiene + one spec section addition.

## Impact graph

```
targets/engine.tsc                  D2: add `_build/**` to exclude list
spec/tsc-oper.md §6                 D3: canonicalize cross-target C_Σ formula; possible v3.2.1 patch
spec/tsc-glossary.md                D3 cross-ref: glossary entry for cross-target aggregate (if added)
CONTRIBUTING.md                     stale Python refs → OCaml-only contributor onboarding
.github/pull_request_template.md    stale `pip install` / `pytest` refs → OCaml dev cycle
.cdd/unreleased/27/                 move to .cdd/releases/docs/{ISO}/27/ per §2.5b
.cdd/unreleased/29/                 move to .cdd/releases/docs/{ISO}/29/ per §2.5b
.cdd/iterations/INDEX.md            initialize (recursive coherence with cnos; this cycle's own row + retro for past cycles)
CI workflow file (.github/workflows) verify red, fix `libcurl4-gnutls-dev` apt 404 if mechanical
CHANGELOG.md                        add ledger row for #32 (and v3.2.1 row if D3 bumps spec)
spec/VERSION-equivalent             v3.2.0 → v3.2.1 if D3 includes patch bump

Verify-and-close (no diff impact):
  Issue #6                          verify functional satisfaction by cycle #29; close with rationale
  Issue #22                         verify functional satisfaction by cycle #25; close with rationale

Branch hygiene (operator-side; UI deletion):
  pr-bundles/cnos-cdd-supercycle, courier/*, proposals/*, claude/* legacy
```

## Acceptance Criteria

### AC1: D2 — engine.tsc excludes _build artifacts

**Invariant:** `targets/engine.tsc` excludes `engine/ocaml/_build/**` (and any other build-output paths) from the engine target's bundle.
**Oracle:** `grep -E '_build|exclude' targets/engine.tsc` shows the exclusion pattern; running `coh --target engine --mode mechanical` produces a bundle file count that does NOT include `_build/` artifacts.
**Positive:** Engine target's bundle contains only source + spec + manifest files; no build outputs.
**Negative:** `_build/` paths appear in the bundle.
**Surface:** `targets/engine.tsc`.

### AC2: D3 — spec/tsc-oper.md §6 canonicalizes cross-target C_Σ

**Invariant:** `spec/tsc-oper.md` adds a section (in §6 or a new §X) defining the cross-target aggregate `C_Σ` as the geometric mean of per-target `C_Σ` values: `C_Σ_{cross} = (∏_i C_Σ_i)^(1/n)` where i ranges over targets in scope (typically `spec`, `engine`, `repo`).
**Oracle:** `grep -nE "cross.target|geometric mean.*target|C_\\\\Sigma_\\{cross\\}" spec/tsc-oper.md` matches.
**Positive:** Section present with formula; cycle #29's self-coherence report's ad-hoc computation is now normative.
**Negative:** Formula absent or ambiguous about which targets aggregate.
**Surface:** `spec/tsc-oper.md` (new section); possibly `spec/tsc-glossary.md` (cross-reference); possibly `CHANGELOG.md` spec ledger v3.2.0 → v3.2.1.

### AC3: CONTRIBUTING.md + PR template no Python references

**Invariant:** Neither `CONTRIBUTING.md` nor `.github/pull_request_template.md` contains references to Python tooling: `pip`, `pip install`, `pytest`, `requirements.txt`, `setup.py`, `pyproject.toml`, `reference/python/parsers/`, or "Support Matrix Python".
**Oracle:** `grep -iE "pip|pytest|python|requirements\\.txt|setup\\.py|pyproject" CONTRIBUTING.md .github/pull_request_template.md` returns no matches in operative content (allowing for "no Python" or historical references that explicitly mark retirement).
**Positive:** Contributor docs describe OCaml-only dev cycle (`opam install`, `dune build`, `dune runtest`).
**Negative:** Any `pip install` / `pytest` / `pyproject` reference remains as live instruction.
**Surface:** `CONTRIBUTING.md`, `.github/pull_request_template.md`.

### AC4: Stalled `.cdd/unreleased/{27,29}/` resolved per §2.5b

**Invariant:** `.cdd/unreleased/27/` and `.cdd/unreleased/29/` are moved to `.cdd/releases/docs/{ISO-date}/{N}/` per §2.5b's docs-only disconnect path. The ISO-date is the ORIGINAL merge date of each cycle (cycle #27: 2026-05-08 per merge `108a77a`; cycle #29: 2026-05-08 per merge `e119aa6`) — not this cycle's date.
**Oracle:** `find .cdd/releases/docs -path '*27*' -name '*.md' | wc -l` ≥ 5; same for `29`. `find .cdd/unreleased -name '*.md'` returns nothing.
**Positive:** Both cycle dirs at canonical post-§2.5b path; `.cdd/unreleased/` empty.
**Negative:** Either dir still in `unreleased/` or moved to a wrong-date path.
**Surface:** `.cdd/releases/docs/2026-05-08/{27,29}/`.

### AC5: CI build green on main

**Invariant:** `.github/workflows/ci.yml` (or whichever workflow runs `dune build`) passes on the post-merge state of `cycle/32`. `libcurl4-gnutls-dev` apt 404 is resolved (apt source updated, package list refreshed, or alternative installation path).
**Oracle:** GitHub Actions run on `cycle/32` HEAD shows `build` job green.
**Positive:** CI green; `dune build` + `dune runtest` complete on the merge tree.
**Negative:** Build job red OR the fix introduces a new red.
**Surface:** `.github/workflows/ci.yml` (or the apt source files / Dockerfile referenced therein).

### AC6: Stale issues #6 and #22 verify-and-closed

**Invariant:** Issues #6 and #22 are either closed (with explicit rationale linking to subsuming cycle) or carry an updated comment naming the rationale and remaining gap.
**Oracle:** `gh issue view 6 --repo usurobor/tsc --json state,closedAt` and same for `22` show `state: closed`; closure comment cites cycle #29 (#6) and cycle #25 (#22) respectively.
**Positive:** Both closed; rationale cites subsuming cycle.
**Negative:** Either still open with no recent comment.
**Surface:** GitHub issues #6 and #22.

### AC7: `.cdd/iterations/INDEX.md` initialized on tsc

**Invariant:** Per cnos #331 patch 6 (Step 5.6b), tsc has `.cdd/iterations/INDEX.md` with at minimum the courier/cross-repo work tsc has already produced (4 cnos cycles' worth of bundles for #331, #333, #334-equivalent, #335; plus the just-merged cnos #338 + #339 if cross-repo work for them was tsc-side).
**Oracle:** File exists; format matches Step 5.6b template (Cycle / Issue / Date / Findings counts / Path); ≥1 row.
**Positive:** File present; rows match the cross-repo trace dirs that exist on tsc.
**Negative:** File absent OR rows drift from actual cross-repo work.
**Surface:** `.cdd/iterations/INDEX.md`.

### AC8: This cycle's own close-out follows the protocol

**Invariant:** `cycle/32`'s own close-out artifact set is complete BEFORE merge: `self-coherence.md` (this file), `beta-review.md` (β rounds), `alpha-closeout.md` (α post-merge), `beta-closeout.md` (β post-merge), `gamma-closeout.md` (γ closure declaration), `cdd-iteration.md` (this cycle produces ≥1 cdd-protocol-gap finding by definition — the docs-only-cycle dir-move resolution closes the gap that cycles #27/#29 left open).
**Oracle:** All 6 files present at `.cdd/releases/docs/2026-05-09/32/` after disconnect.
**Positive:** Full close-out artifact set; no protocol skip (recursive coherence — this cycle does NOT repeat the #331/#333/#334 pattern).
**Negative:** Any artifact missing at disconnect.
**Surface:** `.cdd/releases/docs/2026-05-09/32/`.

## Self-check

- All 8 ACs are independently testable via grep / find / file-existence / GitHub API checks.
- D2 + D3 + cleanup + verify-and-close + INDEX init = 7 substantive deliverables; AC8 is the recursive-coherence requirement (this cycle follows the protocol it bundles fixes for). 8 ACs total — at the upper edge of typical per cnos #334 cycle-scope-sizing.
- Mode = `design-and-build`. Justified above.
- Active skills: Tier 1a/1b/1c standard; Tier 2 writing + light OCaml; no Tier 3 specials.
- Disconnect path: §2.5b docs-only — UNLESS D3 includes a v3.2.0 → v3.2.1 spec patch bump, in which case spec ledger row + spec version bump rides with the same commit (mixed: docs-only disconnect for the cycle artifacts, spec patch for the spec change).

## Known Debt (carried into this cycle's body)

- **Pre-merge gate circular dependency** (surfaced by cnos cycle #338 yesterday): the new mechanical pre-merge closure-gate from cnos #339 requires `gamma-closeout.md` BEFORE merge, but γ writes `gamma-closeout.md` AFTER merge. cnos #338 hit this; δ merged on β's behalf. **Whether tsc cycle #32 hits this depends on whether tsc has deployed cnos #339's gate locally yet.** Likely not (tsc's release.sh is independent of cnos's cdd-skill bundle for now). If the gate were deployed, cycle #32 would hit the same circular dependency. Track as known debt; address via the candidate MCA cnos #338 surfaced ("split gate artifact requirements into pre-merge α/β tier and post-merge γ tier"). Out of scope for this cycle.

- **D1 + D4** (LLM-credentials-blocked): hybrid self-coherence run + CI on mechanical scores. Not in this cycle. Stays in lag table.

- **#28** (Claude CLI provider, P3 deferred): not in this cycle. Stays as named debt.

## CDD Trace (initial — through step 7a will be filled by α; step 5 here)

| Step | Artifact | Skills loaded | Decision |
|------|----------|---------------|----------|
| 0 Observe | CHANGELOG, lag table, doctor/status, last PRA | cdd, cdd/issue | observation inputs read; selected #32 per §3.3 |
| 1 Select | — | cdd | selected #32 (master #23 next-MCA commitment); decisive clause CDD §3.3 |
| 2 Branch | `cycle/32` | cdd | branch created from origin/main per §4.2; pre-flight passed per §4.3 |
| 3 Bootstrap | this file | cdd | scaffold present |
| 4 Gap | this §Gap | — | named seven deliverables + recursive-coherence requirement |
| 5 Mode | this §Mode | cdd/issue | `design-and-build`; cycle-scope at-edge keep-whole with justification |
| (steps 6–7a will be filled by α during implementation) | | | |

## Review-readiness signal (placeholder; α will fill at fix-round R1)

| Field | Value |
|---|---|
| Base SHA | 6b3ab08 (origin/main) |
| Head SHA | (filled by α at review-readiness) |
| Branch CI state | (filled — must be green or `provisional` with explicit reason) |
| Ready for β | (filled by α: "ready for β review against ACs 1–8") |
