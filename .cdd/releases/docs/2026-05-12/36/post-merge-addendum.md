---
cycle: 36
type: post-merge-addendum
date: "2026-05-12"
parent: gamma-closeout.md
addendum_reason: "Original close-out deferred Post-merge verification to operator action. Verification happened post-close: CI ran red on first run, required hotfix. This addendum records the verification result + the fix without mutating the archived close-out."
---

# Post-merge addendum — Cycle #36

## Original close-out's deferred row

`gamma-closeout.md` §Post-merge verification (operator action):
> After main push, verify:
> 1. `gh run list --workflow=katas.yml` — workflow appears, runs on the push event
> 2. First run completes green (cold; expect 5–8 min OPAM install)
> 3. Subsequent run on same SHA — cache hit; runtime <3 min
> 4. `gh run list --workflow=ci.yml` — `kata-check` job no longer appears

That verification was deferred to operator action rather than performed by γ before close-out. This is exactly the gap `proposals/cnos-cdd-ci-green-gate/ISSUE.md` (F2 of cycle #36 follow-ons) is filed to close structurally.

## What actually happened

| Phase | Outcome |
|---|---|
| Merge to main | `f4a69ef` (cycle/36-impl-r2-review → main), then `2aca482` (γ close-out commit), then `9d5ffbb` (F1 proposal commit) |
| First katas workflow run | **FAILED** — exit 31, duration 1m 49s, run `25729149081` |
| Failed step | `Install engine (provides `coh` on PATH)` |
| Root cause | `opam install . -y` triggers opam's package-mode build (`dune build -p name @install`) which treats the extracted package source as its root. The `bin/dune` `build_version.ml` rule depends on `../../../VERSION`, which resolves outside the package-source sandbox. |
| Diagnosis path | Badge `failing` → run page exit 31 → log inspection showed failed step → cross-reference with `ci.yml::build` (which uses `dune build`, not `opam install`) revealed the divergence |
| Fix | PR #37 — replace `opam install . -y` with `opam exec -- dune build`; invoke katas via direct binary path `engine/ocaml/_build/default/bin/main.exe` instead of `opam exec -- coh` |
| Fix verification | PR #37's `katas` check turned `passing` |
| Fix merge | `8e3094c` (merge of `fix/katas-ci-binary-resolution` → main) |
| Post-fix main run | (recorded by the post-merge poll; expected `passing`) |

## γ-axis grade revision

Original close-out: **γ: B** (recon failure on §Gap framing).

Revised: **γ: C+** per the proposed §3.8 amendment in `proposals/cnos-cdd-ci-green-gate/`:
> Cycles that proceed to close-out without verifying CI cap the γ axis at B−.

Cycle #36 not only didn't verify CI but actively deferred verification to operator — the rule's stricter case ("ship without checking and CI is red") applies. Closer to **C+**.

Revised C_Σ: (α B+ · β A · γ C+)^(1/3) = (3.3 · 4.0 · 2.3)^(1/3) ≈ (30.4)^(1/3) ≈ 3.12 → **B−**.

Original C_Σ B+; revised C_Σ B−. One full band down.

## Honest assessment

The cycle delivered:
- Correct workflow design (auto-discovery, cache, concurrency, forward-compat header) ✓
- Correct integration shape (replaces overlapping ci.yml::kata-check) ✓
- Correct cdd protocol response (β R1 caught false-gap; α R2 consolidated; β R2 APPROVED) ✓
- **Verified CI runs green** ✗ — deferred to "after merge"; failed on first run

The protocol caught one half of the cycle's failure mode (β R1 found the framing was wrong) but did not catch the other half (no role verified CI ran green on the review SHA or the merge SHA).

`proposals/cnos-cdd-ci-green-gate/` is the exact patch. Cycle #36 just became the strongest possible empirical anchor for filing it: the cycle that shipped a CI gate did not gate its own CI.

## Cdd-iteration F2 — escalated

Originally F2 was a follow-on proposal *drafted* against cycle #36. Now it is *operationally validated*: this addendum is the cycle's own evidence that the rule is necessary. F2 escalates from drafted-proposal to filed-priority for the next cnos cdd patch wave.

## Outputs

| Output | Status |
|---|---|
| Fix PR #37 merged | ✅ `8e3094c` |
| Katas badge on main green | (recorded by post-merge poll) |
| Cycle #36 close-out addendum (this file) | ✅ |
| γ-axis grade revision | ✅ recorded above; INDEX.md update follows |
| F2 cnos proposal | Pushed (`proposals/cycle-36-followons` branch); awaits sigma to file |

## Closure gate (addendum row)

| Row | Condition | Status |
|---|---|---|
| 11 | Post-merge CI verified green | (filled by post-merge poll) |
| 12 | Post-merge fix (if needed) merged | ✅ `8e3094c` (PR #37) |
| 13 | γ-axis grade revised honestly | ✅ B → C+ |
| 14 | F2 proposal cross-referenced | ✅ |
