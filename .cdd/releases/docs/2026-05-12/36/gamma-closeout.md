---
cycle: 36
role: gamma
type: gamma-closeout
date: "2026-05-12"
merge_sha: "f4a69ef"
---

# γ Close-out — Cycle #36

**Issue:** tsc #36 — Wire engine katas into CI (run on every push to main + PR)
**Mode:** docs-only-plus-CI per §2.5b (no version bump; CI surface change only)
**Branch trail:** `cycle/36` (γ scaffold) → `cycle/36-impl` (α R1) → `cycle/36-impl-review` (β R1, RC) → `cycle/36-impl-r2` (α R2) → `cycle/36-impl-r2-review` (β R2, APPROVED)
**Merge commit:** `f4a69ef` (no-ff merge to main)
**Review rounds:** 2 (R1: RC, 2 B-findings; R2: APPROVED, 0 findings)
**ACs:** 3/3
**Dispatch configuration:** §5.2 single-session δ-as-γ via Claude Code Agent tool

## Cycle trail

| SHA | Role | Subject |
|---|---|---|
| `e7f3817` | γ | γ scaffold — self-coherence with §Gap §Mode §ACs §CDD-Trace |
| `ecb270b` | α | ci(36): add katas regression workflow — AC1+AC2+AC3 |
| `b8df57f` | α | docs(36): add katas CI status badge to katas/README.md |
| `56571e0` | α | closeout(36): α R1 closeout + honest-claim manifest |
| `5a105cb` | α | meta(36): record α R1 head SHAs in self-coherence |
| `c996abd` | β | review(36): β R1 verdict RC — two B-findings |
| `2c7d4f8` | α | ci(36): remove kata-check job (consolidated into katas.yml) — B-1 |
| `35033ec` | α | ci(36): fix cache key to reference only files that exist — B-2 |
| `426f2b9` | α | docs(36): correct §Gap framing — kata-check existed; consolidate |
| `dedbef5` | α | docs(36): update closeout + claims for R2 narrative |
| `0f290d4` | α | meta(36): record α R2 head SHAs in self-coherence |
| `ddccc3e` | β | review(36): β R2 verdict APPROVED — both B-findings resolved |
| `f4a69ef` | γ | merge(36): cycle/36-impl-r2-review → main — Closes #36 |

## Close-out triage

| Finding | Source | Type | Severity | Disposition |
|---|---|---|---|---|
| F1 false-gap framing — `ci.yml::kata-check` already exists | β R1 / γ pre-review observation | cycle-design / γ-recon | B | Resolved in R2 via Path A consolidation (commit `2c7d4f8`); cdd-iteration F1 below |
| F2 `engine/ocaml/Makefile` cache-key honest-claim violation | β R1 rule 3.13(a) | honest-claim | B | Resolved in R2 (commit `35033ec`); claims.md §R2-1 supersedes R1 Claim 3 |
| F3 §Impact graph + §Design-decision R1 audit-trail references to Makefile | α R2 self-flagged, β R2 evaluated | audit-trail | note | Accepted as-is per no-rewrite-history convention; corrected framing carried in §Gap "Corrected (R2)" + §AC3 R2 marker |

## §9.1 Triggers

| Trigger | Fired? | Disposition |
|---|---|---|
| Coherence regression on merge | No | β R2 APPROVED clean |
| Avoidable tooling failure | **Yes** — γ recon failure (cycle shipped on false-gap premise) | cdd-iteration F1 — γ peer-enumeration gap |
| Honest-claim violation | **Yes** — α R1 §Claim 3 "Makefile verified present" was false | cdd-iteration F2 — claim verification before commit |
| Branch sprawl | **Yes** — 5 branches per cycle (same pattern as #32) | Already-named in proposals/cnos-cdd-claude-code-dispatch §5.2 |
| Mode-mismatch | No | docs-only-plus-CI correctly invoked §2.5b path |

## TSC Grades (honest, per §3.8)

| Axis | Grade | Reasoning |
|---|---|---|
| **α** | **B+** | 1 RC round, 2 binding findings (B-1 + B-2). R2 resolved both cleanly. **Honest-discount mitigant:** α R1 *flagged* B-1 in its own §Findings ("duplicates this workflow's purpose"); the failure was not surfacing it as a blocker before implementing. Honest signaling lifts the floor from B to B+. |
| **β** | **A** | Both R1 findings caught independently with strong reasoning. Rule 3.13 wiring discipline applied verbatim — peer-enumerated every workflow file, caught false-gap. R2 re-review focused, accurate, surfaced no spurious findings. |
| **γ** | **B** | Recon failure: filed issue #36 and scaffolded cycle without peer-enumerating `ci.yml` (where `kata-check` was added in 344-c). Cycle shipped on false-gap premise. Even after α R1 flagged the overlap in its closeout, γ chose "let β surface it" rather than actively reframing — a second recon-discipline miss. **Honest-discount mitigant for protocol response:** once β R1 raised RC, γ correctly directed α R2 to Path A consolidation. The cycle landed on the right outcome through β's catch, not γ's frame. §5.2 cap (A−) is irrelevant here — actual γ grade falls below the cap. |
| **C_Σ** | **B+** | (3.3 · 4.0 · 3.0)^(1/3) ≈ 3.41 |

**Level:** L7 (mechanical-mode CI gate; no engine semantics affected).

## What shipped

- `.github/workflows/katas.yml` — new dedicated workflow, 116 lines:
  - Triggers: `push.branches: [main]` + `pull_request`
  - Auto-discovery: `for kata_dir in katas/*/; do id=$(basename ...); coh --kata "$id"; done` (zero hard-coded kata names)
  - Build cache: `actions/cache@v4` keyed on `hashFiles('engine/ocaml/dune-project', 'engine/ocaml/tsc_engine.opam')`
  - Concurrency: `concurrency: { group: katas-${{ github.ref }}, cancel-in-progress: ${{ github.event_name == 'pull_request' }} }` — PR cancellation enabled; main never cancels
  - Forward-compat header: marked INTERIM pending cnos #344 Cycle B canonical templates
- `.github/workflows/ci.yml` — `kata-check` job removed (replaced with placeholder comment at line 97)
- `katas/README.md` — CI status badge added (+2 lines)

**Effective result:** katas now exercise as a CI regression gate with build caching, concurrency control, and a single canonical home (no duplicate parallel surface).

## Closure gate (per `cdd/gamma/SKILL.md` §2.10)

| Row | Condition | Status |
|---|---|---|
| 1 | alpha-closeout.md present | ✅ `.cdd/releases/docs/2026-05-12/36/alpha-closeout.md` |
| 2 | beta-review.md present | ✅ `.cdd/releases/docs/2026-05-12/36/beta-review.md` |
| 3 | beta-closeout.md present | ✅ `.cdd/releases/docs/2026-05-12/36/beta-closeout.md` |
| 4 | Honest-claim manifest present (cnos #344 §14 convention) | ✅ `.cdd/releases/docs/2026-05-12/36/claims.md` (R1 + R2 layers) |
| 5 | Merge commit recorded | ✅ `f4a69ef` |
| 6 | §2.5b docs-only disconnect followed | ✅ moved to `.cdd/releases/docs/2026-05-12/36/`; no tag |
| 7 | CHANGELOG ledger row | N/A — no version bump |
| 8 | cdd-iteration.md authored | ✅ `.cdd/releases/docs/2026-05-12/36/cdd-iteration.md` |
| 9 | Issue closed | Operator action — γ leaves comment on tsc #36 with merge SHA |
| 10 | All branches accounted for | Operator UI cleanup for 5 cycle branches (harness blocks delete) |

## Post-merge verification (operator action)

After main push, verify:

1. `gh run list --workflow=katas.yml` — workflow appears, runs on the push event
2. First run completes green (cold; expect 5–8 min OPAM install)
3. Subsequent run on same SHA (or another commit) — cache hit; runtime <3 min
4. `gh run list --workflow=ci.yml` — `kata-check` job no longer appears in the job list

## Deferred outputs / known debt

- **R1 narrative audit trail.** `.cdd/releases/docs/2026-05-12/36/self-coherence.md §Impact-graph` and `alpha-closeout.md §Design-decision line 46` still reference `engine/ocaml/Makefile` as part of R1-era reasoning. Accepted as-is per no-rewrite-history convention (β R2 evaluated; not escalated to C-finding). Live cache key and gap framing carry in the corrected (R2) sections.
- **Cnos activation Cycle B canonical templates.** When they ship, `katas.yml` should be swapped for the canonical template. Forward-compat header in the workflow names this explicitly.

**Cycle #36 closed.**
