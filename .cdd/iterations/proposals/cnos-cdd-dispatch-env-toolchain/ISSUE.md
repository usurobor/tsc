# cdd/review + cdd/alpha: Add "dispatch-env-toolchain-absent" verdict shape — structural-only review when runtime AC oracles cannot be exercised in the dispatch context

**Labels:** `docs, P2, cdd`
**Priority:** P2 — recurring shape not named in spec; β's honest workaround currently surfaces as a verdict-header qualifier outside §3.3's canonical vocabulary. Without explicit sanction, the qualifier reads as a verdict-rule violation (cycle-#32-R1-trap-shaped) on first read.
**Status:** Drafted; ready for cycle dispatch.
**Mode:** `docs-only` — prose-only patches to two existing skill sections.
**Depends on:** None. Sister proposal: `proposals/cnos-cdd-claude-code-dispatch` (operator §5 — Dispatch configurations) — the toolchain-absent failure mode is downstream of single-session δ-as-γ activation, but the patch landing surface (`review/SKILL.md` §3.10 + `alpha/SKILL.md` §2.6 row 9) is distinct.

## Problem

**What exists:**

- `cdd/review/SKILL.md` §3.3 ("All findings must be resolved before merge") forbids "approved with follow-up" — APPROVED is binary; if a finding requires fix-on-branch, the verdict is REQUEST CHANGES.
- `cdd/review/SKILL.md` §3.10 ("CI / release-gate state") says "If merge is requested, verify required CI/build checks are green on branch head. If checks are missing/stale/red, approval is provisional: 'Do not merge until checks finish green.'"
- `cdd/alpha/SKILL.md` §2.6 row 9 ("branch CI is green on the head commit, or, if local CI is unavailable, the artifact's review-readiness section says so explicitly and β waits for green before merge").

**What is expected:** cdd names a third failure shape — **the build toolchain required for the AC's runtime oracle is absent from BOTH α's and β's dispatch environments**. This is distinct from:

- (a) "Checks are missing/stale/red" (§3.10) — presumes checks can be run somewhere but didn't run successfully.
- (b) "Local CI is unavailable" (α §2.6 row 9) — presumes the *infrastructure* is missing but the toolchain itself could be invoked if it were.

Under dispatch-env-toolchain-absence, neither (a) nor (b) holds. The toolchain itself (`dune`/`ocaml`/`opam` in the tsc cycle-#33 case; could be `go`/`cargo`/`bazel`/etc. in other projects) is not installed in the dispatch context. α cannot run `dune runtest`; β cannot run `coh --kata 01-glider`. The runtime ACs degrade to structural well-formedness checks at both α-side and β-side gates.

**Where they diverge:** cycle #33 (`usurobor/tsc#33`) hit this shape. β's R1 verdict header read `APPROVED (structural-only; runtime verification deferred to release-time CI)` with zero D/C/B/A findings. The verdict is binary-approved; the qualifier names review scope, not a deferred follow-up. **But the qualifier is not in §3.3's canonical verdict vocabulary** (which is exactly `APPROVED` or `REQUEST CHANGES`), so on first read the verdict shape resembles the cycle-#32-R1 trap (APPROVED + binding finding). β must spend explicit prose disambiguating, and γ must spend explicit prose triaging. The protocol can absorb the disambiguation once: by sanctioning the shape.

## Impact

- **Verdict-rule ambiguity.** β's honest "structural-only" qualifier reads as a §3.3 violation on first parse. Future β agents may either (i) split-the-difference and call REQUEST CHANGES on a structurally sound branch (false-RC; cycle stalls); (ii) drop the qualifier and call APPROVED silently (false-APPROVED; release-time CI catches it but the cycle's own audit trail lies); or (iii) reproduce the explicit disambiguation prose, every cycle, for the same shape. None of these are coherent.
- **Honest-claim discipline pressure.** Without a sanctioned "structural-only" verdict shape, α and β are pressured to claim runtime measurements they could not perform. cycle #33 held the line (α framed score-range justifications as REFERENCE not MEASUREMENT; β verified) but the protocol's incentive gradient is in the wrong direction.
- **Release-time CI gate is implicit.** When the verdict header says "runtime verification deferred to release-time CI," the binding gate becomes whichever CI workflow runs the actual oracle. cdd does not currently name this dependency, so different repos handle it differently (some run kata on push, some on release, some not at all).
- **Recursive coherence weakens.** The cycle that introduces the toolchain-dependent feature (kata framework) cannot demonstrate the feature works during its own dispatch window. The grade reflects what shipped (per §3.8 "score the release, not the intent"), but "what shipped" is only the structural component; the runtime component is held in escrow until release CI completes. Without protocol sanction, this looks like a coverage hole rather than a documented protocol path.

## Status truth

| Surface | Status | Notes |
|---|---|---|
| `cdd/review/SKILL.md` §3.3 verdict-rule vocabulary | Shipped | `APPROVED` / `REQUEST CHANGES` only |
| `cdd/review/SKILL.md` §3.10 provisional-approval semantics | Shipped | "Do not merge until checks finish green" — presumes checks runnable |
| `cdd/alpha/SKILL.md` §2.6 row 9 local-CI escape | Shipped | "if local CI is unavailable, the artifact's review-readiness section says so explicitly" — presumes infrastructure, not toolchain, is the gap |
| `structural-only` verdict shape | NOT NAMED | This proposal |
| Release-time-CI-as-binding-gate dependency | NOT NAMED | This proposal |
| Empirical evidence — `tsc:cycle/33` | Shipped | `.cdd/releases/docs/2026-05-11/33/{self-coherence,beta-review,gamma-closeout,cdd-iteration}.md` |

## Source of truth

| Claim / surface | Canonical source | Status |
|---|---|---|
| §3.3 verdict-rule | `cdd/review/SKILL.md §3.3` | Shipped |
| §3.10 CI-state rule | `cdd/review/SKILL.md §3.10` | Shipped |
| α §2.6 row 9 local-CI rule | `cdd/alpha/SKILL.md §2.6` | Shipped |
| cycle-#33 empirical | `usurobor/tsc:.cdd/releases/docs/2026-05-11/33/cdd-iteration.md` F1 + F3 | Shipped |
| cycle-#33 verdict | `usurobor/tsc:.cdd/releases/docs/2026-05-11/33/beta-review.md` line 1 | Shipped |
| sister: §1.6c dispatch sizing | `cdd/CDD.md §1.6c` (cnos #338) | Shipped |
| sister: claude-code-dispatch proposal | `proposals/cnos-cdd-claude-code-dispatch/ISSUE.md` | Drafted (open) |

## Cycle scope sizing (per cnos #334 heuristic)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | 0 — prose-only changes to 2 skill files | no |
| (b) Cross-module breadth | 2 files (`review/SKILL.md`, `alpha/SKILL.md`); ≤3 sections touched | low |
| (c) Lifecycle span | docs-only | low |
| (d) MCA preconditions | docs-only; not MCA | n/a |
| (e) Independent shippability | Single coherent patch; both file edits should land together | no |

**Decision:** **keep whole** — small docs-only cycle, 4 ACs.

## Scope

**In scope:**

1. **`cdd/review/SKILL.md` §3.10 extension** — add a subsection or amendment titled "Dispatch-env-toolchain-absent" naming the failure shape and the sanctioned verdict form:

   > When β's dispatch environment lacks the build toolchain required to invoke an AC's runtime oracle (e.g., `dune`/`ocaml`/`opam` for OCaml projects, `cargo` for Rust, `bazel` for monorepos), AND α's dispatch environment had the same absence (so the toolchain absence is environmental, not implementation-side), β may write the verdict header as:
   >
   > `APPROVED (structural-only; runtime verification deferred to release-time CI)`
   >
   > ONLY IF ALL of the following hold:
   >
   > 1. Zero findings (any severity D/C/B/A) in the findings table.
   > 2. All structural checks pass (contract integrity, AC walk, diff inspection, hermeticity check, honest-claim 3.13a/b/c verification, active design constraints).
   > 3. Release-time CI is named in `self-coherence.md` §Review-readiness or β's §Notes as the binding gate for the runtime oracles, with a concrete pointer to the workflow file (e.g., `.github/workflows/ci.yml`).
   > 4. α's `self-coherence.md` §Pre-review gate honestly flagged the toolchain absence at α-side (row 9 honest-deferral); β confirms the absence in their own context with `command -v <toolchain>` output recorded in beta-review §Notes.
   > 5. The merge commit message names "runtime verification deferred to release-time CI" so the audit trail records the gate dependency.
   >
   > This verdict shape is NOT "approved with follow-up" — there are zero findings requiring α fix-rounds, and the runtime-CI dependency is not a follow-up fix but a separate gate at a downstream lifecycle phase.

2. **`cdd/alpha/SKILL.md` §2.6 row 9 amendment** — extend the existing local-CI escape valve to name dispatch-env-toolchain-absence as a distinct case:

   > Row 9 amendment: branch CI is green on the head commit, OR local CI is unavailable AND the artifact's review-readiness section says so explicitly AND β waits for green before merge, OR **the build toolchain required to invoke the AC's runtime oracle is absent from α's dispatch environment** — in which case α's §Pre-review gate row 9 honestly flags the toolchain absence (e.g., "`command -v dune` returns nothing; runtime oracle deferred to β + release-time CI"), and the cycle's gate satisfaction is downstream of β's structural-only review path (§3.10 amendment).

3. **(Optional, recommended) `cdd/release/SKILL.md` §3.8 grading-floor note** — when a cycle ships under the structural-only verdict shape, note that release-time CI is the cycle's truth-table for whether the runtime ACs actually passed. If release-time CI subsequently red's, the cycle's grade is downgradeable retroactively per §3.8 "score the release, not the intent" — the structural-only shape doesn't inflate grades; it just allows the cycle to close in advance of empirical confirmation.

**Out of scope:**

- Tooling: provisioning the build toolchain into dispatch envs. That's a harness-side concern, not a cdd-spec concern.
- The release-time CI workflow itself. Each project owns its CI; cdd just names the dependency.
- Retroactive re-grading of prior cycles that ran under this shape (none other than tsc #33 are known to date).

## Acceptance criteria

### AC1: `cdd/review/SKILL.md` §3.10 amendment ships

**Invariant:** `cdd/review/SKILL.md` §3.10 has a sub-section or amendment naming the dispatch-env-toolchain-absent failure shape and the `APPROVED (structural-only; runtime verification deferred to release-time CI)` verdict form, with the 5 preconditions listed verbatim.
**Oracle:** `grep -nE "structural-only|toolchain.absent|runtime verification deferred" cdd/review/SKILL.md` matches; the 5 preconditions are enumerated as a numbered list.
**Surface:** `src/packages/cnos.cdd/skills/cdd/review/SKILL.md`.

### AC2: `cdd/alpha/SKILL.md` §2.6 row 9 amendment ships

**Invariant:** `cdd/alpha/SKILL.md` §2.6 row 9 extends to name the dispatch-env-toolchain-absent case.
**Oracle:** `grep -nE "toolchain.absent|command -v" cdd/alpha/SKILL.md` matches in §2.6 row 9 context.
**Surface:** `src/packages/cnos.cdd/skills/cdd/alpha/SKILL.md`.

### AC3: (optional) `cdd/release/SKILL.md` §3.8 grading note ships

**Invariant:** §3.8 names release-time CI as the empirical truth-table for cycles that shipped under structural-only verdicts; retroactive downgrade is contemplated.
**Oracle:** `grep -nE "structural-only|release.time CI.*truth" cdd/release/SKILL.md` matches.
**Surface:** `src/packages/cnos.cdd/skills/cdd/release/SKILL.md` §3.8 (optional; can be deferred to a follow-on if AC1 + AC2 are sufficient).

### AC4: tsc cycle #33 is the empirical anchor

**Invariant:** The patch's empirical-anchor commentary points to tsc cycle #33's `cdd-iteration.md` F1 + F3 and `beta-review.md` line 1 as the test-case for the new verdict shape.
**Oracle:** Either inline or in a follow-on PRA section.
**Surface:** Cnos cdd-iteration trace or PRA for the cycle that lands this patch.

## Proof plan

**Invariant:** β can write `APPROVED (structural-only; runtime verification deferred to release-time CI)` with confidence that the verdict is canonically sanctioned (not a §3.3 violation in disguise), and γ can triage the verdict without writing disambiguation prose every cycle.
**Surface:** `cdd/review/SKILL.md` §3.10, `cdd/alpha/SKILL.md` §2.6 row 9, optionally `cdd/release/SKILL.md` §3.8.
**Oracle:** β reviews against AC1–AC4; the patch's own cycle is the first to run under the newly-sanctioned shape (recursive coherence opportunity, not a hard requirement).
**Positive case:** Future toolchain-absent cycles converge cleanly without per-cycle disambiguation prose; the verdict shape lands in the canonical vocabulary.
**Negative case:** The amendment is parsed as expanding the §3.3 "approved with follow-up" loophole, weakening the discipline. Mitigation: the 5 preconditions specifically forbid the §3.3 trap (precondition 1: zero findings is the hard floor).
**Operator-visible projection:** PRAs and gamma-closeouts include a "dispatch-env-toolchain-absence" column in their close-out triage tables when the shape fires; release-time CI is named as the binding gate per cycle that uses the shape.
**Known gap:** This proposal does not address what happens if release-time CI subsequently fails (the structural-only verdict was sound; the release-time oracle uncovered a real bug). That's a §3.6 ("If CI fails post-tag, amend don't re-tag") concern and §3.8 retroactive-downgrade concern, addressed in the optional AC3 sub-bullet.

## Active design constraints

- **Do not weaken §3.3.** The structural-only verdict shape MUST require zero findings. If any finding fires, the verdict is REQUEST CHANGES per §3.3.
- **Toolchain absence is environmental, not implementation-side.** The shape applies only when BOTH α and β contexts share the absence. If α can build but β cannot, that's a β-environment issue (escalate to operator); if α can't build but β can, that's α-environment debt and β should run the oracle.
- **Release-time CI is binding.** When the verdict ships, the cycle's grade is provisional on release-CI green. §3.8 retroactive-downgrade contemplates the case where release CI subsequently red's.
- **Honest-claim 3.13a holds throughout.** No "measurement" claims may be made in self-coherence under the structural-only verdict; only "reference" claims (input frontmatter, spec threshold, prior empirical run) are permitted.
- **Audit-trail preservation.** The merge commit message names the deferred-to-release-CI dependency so the cycle's published history records the gate state honestly.

## Related artifacts

- `usurobor/tsc:.cdd/releases/docs/2026-05-11/33/cdd-iteration.md` F1 + F3 — empirical anchor for this proposal
- `usurobor/tsc:.cdd/releases/docs/2026-05-11/33/beta-review.md` line 1 — verdict shape that motivated this proposal
- `cdd/review/SKILL.md` §3.3 (verdict rule) + §3.10 (CI state)
- `cdd/alpha/SKILL.md` §2.6 row 9 (pre-review gate local-CI escape)
- `cdd/release/SKILL.md` §3.8 (honest-grading rubric; retroactive-downgrade clause)
- `cdd/CDD.md` §1.6c (dispatch sizing; sister rule for budget/scope)
- `proposals/cnos-cdd-claude-code-dispatch/ISSUE.md` (sister proposal; single-session δ-as-γ configuration)

## Non-goals

- Patching the harness to install build toolchains.
- Defining what counts as a "build toolchain" globally — left to per-project convention (a project's `README.md` or `QUICKSTART.md` says what's needed; cdd just names the absence).
- Multi-language toolchain-absence policy (e.g., what if a project requires `dune` AND `cargo` AND β's env has one but not the other). Defer to a follow-on; the cycle-#33 shape is single-toolchain.
- Retroactive re-grading of any prior cycles (none other than #33 are known).

## Success / closure condition

This issue is closeable when:

- AC1 + AC2 ship (AC3 optional; can defer to follow-on).
- The patch cycle's own close-out cites the new verdict shape (recursive-coherence opportunity).
- β agents running future cycles can cite the canonical §3.10 amendment when writing the structural-only verdict header, without disambiguation prose.
- The next cycle that hits dispatch-env-toolchain-absence (whether on tsc or another adopter) converges cleanly.
