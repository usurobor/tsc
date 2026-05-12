---
cycle: 38
issue: "#38"
role: alpha
identity: alpha@tsc.cdd.cnos
date: 2026-05-12
convention: honest-claim manifest (cnos #344 activation §14; cycle #36 precedent)
rounds:
  - round: R1
    status: current
---

# Honest-Claim Manifest — Cycle #38

Per cnos #344 activation §14, every load-bearing claim in α's
artifacts is listed below with (a) the assertion, (b) the source of
truth it traces to, and (c) the reproduction recipe a reviewer can
run. Designed to support `cdd/review/SKILL.md` rule 3.13 (honest-claim
verification) and to enable β's required peer-enumeration check
that γ's §Gap framing was empirically correct on `8e3094c`.

## Claim 1 — Wiring: artifact-upload + step-summary patterns now exist in `katas.yml`

**Assertion** (from self-coherence.md §Honest-claim manifest claim 1 + cycle scaffold expectations):
> The final `katas.yml` on `cycle/38-impl` contains both `actions/upload-artifact@v4` and `$GITHUB_STEP_SUMMARY` invocations, in both the `run-katas` job (AC1+AC2) and the `validate-published-binary` job (AC3+AC4). Pre-cycle (`8e3094c` main), neither pattern was present.

**Source of truth:** `.github/workflows/katas.yml` on `cycle/38-impl` HEAD.

**Reproduction (post-state):**
```bash
rg -nE 'upload-artifact|GITHUB_STEP_SUMMARY' .github/workflows/katas.yml
# Expected: ≥3 hits. Actual: 14 hits across header + 2 step-summary
# steps + 2 upload-artifact steps.
```

**Reproduction (pre-state — no-false-negation check):**
```bash
git show 8e3094c:.github/workflows/katas.yml | grep -nE 'upload-artifact|GITHUB_STEP_SUMMARY'
# Expected: no output, exit code 1. Actual: ZERO_HITS_CONFIRMED.
```

The pre-state probe verifies γ's §Gap claim "katas.yml has neither artifact upload nor step summary" was not a false negation. Both surfaces are genuinely new in this cycle, not pre-existing.

**Falsification:** if a reviewer runs the post-state probe on `cycle/38-impl` HEAD and gets <3 hits, this claim is falsified.

## Claim 2 — Source-of-truth alignment: step-summary row schema matches docs

**Assertion** (from self-coherence.md §Honest-claim manifest claim 2 + AC5 requirement):
> The markdown table emitted to `$GITHUB_STEP_SUMMARY` in both jobs uses the row schema `| Kata | Verdict | C_Σ | Range | Status |`. `katas/README.md` §Where to find kata results names the same five-column schema explicitly. Both files are kept in lock-step; if one drifts, the other is wrong.

**Source of truth:**
- `.github/workflows/katas.yml` lines 209 + 394 (the table-header `echo` statements in both jobs).
- `katas/README.md` §Where to find kata results (the `| Kata | Verdict | C_Σ | Range | Status |` sentence).

**Reproduction:**
```bash
# Workflow header lines:
grep -nE '\| Kata \| Verdict \| C_.{1,3} \| Range \| Status \|' .github/workflows/katas.yml
# Expected: 2 matches (one per job).

# Docs row schema:
grep -nE '\| Kata \| Verdict \| C_.{1,3} \| Range \| Status \|' katas/README.md
# Expected: 1 match.
```

The Python parsing block in both jobs reads exactly the keys the engine emits at `engine/ocaml/bin/main.ml` lines 505–515: `kata_id`, `expected_verdict`, `c_sigma`, `score_range.{min,max}`, `kata_pass`. No key is invented; no key is silently ignored beyond the deliberate fallback to `—` for nullable fields.

**Falsification:** if a reviewer counts column-headers and the workflow emits ≠5 columns, or `katas/README.md` describes a different schema, this claim is falsified.

## Claim 3 — Reproducibility: AC4 Path B is documented + verifiable from CLI

**Assertion** (from self-coherence.md §Honest-claim manifest claim 3 + AC4):
> AC3 picks Path B (download `coh-linux-x64` from the latest GitHub Release) rather than Path A (build from `v*` tag). The choice is documented in `alpha-closeout.md` with a one-line repro command, AND the workflow itself contains an inline comment block enumerating the same three rationale points.

**Source of truth:**
- `.github/workflows/katas.yml` lines 263–292 (the `validate-published-binary` job's intro comment).
- `.cdd/unreleased/38/alpha-closeout.md` §AC4.

**Reproduction (CLI verification of the downloaded binary):**
```bash
# Recreate what the validation job does, locally:
gh release download --pattern 'coh-linux-x64' --output coh-linux-x64
chmod +x coh-linux-x64
./coh-linux-x64 --version
./coh-linux-x64 --kata 01-glider --mode mechanical
# Expected: KATA PASS line on stderr; result JSON on stdout.
```

**Reproduction (verify the choice is documented in both surfaces):**
```bash
grep -n 'Path B' .github/workflows/katas.yml .cdd/unreleased/38/alpha-closeout.md
# Expected: matches in both files.
```

**Falsification:** if a reviewer runs `gh release download` on the latest tag and the asset is absent (Path B's structural precondition), or the workflow's comment block names a *different* mechanism than the actual `gh release download` step that follows, this claim is falsified.

## Claim 4 — No false negation: γ's §Gap was correct (peer-enumeration discipline self-applied)

**Assertion** (from self-coherence.md §Honest-claim manifest claim 4 + F1 self-application):
> γ's §Gap table at `.cdd/unreleased/38/self-coherence.md` enumerated all five `.github/workflows/*.yml` files on `8e3094c` and asserted `katas.yml` was the only one missing both `upload-artifact` and `GITHUB_STEP_SUMMARY`. α verified the enumeration table is accurate by re-running the grep on each file.

**Source of truth:** `.cdd/unreleased/38/self-coherence.md` §Gap table.

**Reproduction:**
```bash
for f in .github/workflows/*.yml; do
  hits_upload=$(git show 8e3094c:"$f" 2>/dev/null | grep -c 'upload-artifact' || echo 0)
  hits_summary=$(git show 8e3094c:"$f" 2>/dev/null | grep -c 'GITHUB_STEP_SUMMARY' || echo 0)
  printf "%-30s upload=%s summary=%s\n" "$f" "$hits_upload" "$hits_summary"
done
# Expected (matches γ's §Gap table):
#   ci.yml          upload>0  summary=0
#   tsc.yml         upload>0  summary>0
#   release.yml     upload=0  summary=0  (but ships via softprops/action-gh-release)
#   cdd-notify.yml  upload=0  summary=0
#   katas.yml       upload=0  summary=0  ← the gap
```

The `release.yml` row is correctly classified: it does not use `actions/upload-artifact@v4` (it uses `softprops/action-gh-release@v2` to publish to GitHub Releases instead). γ's §Gap row for release.yml acknowledges this nuance explicitly, so the §Gap is not a category error.

**Falsification:** if a reviewer finds any of the enumeration rows mis-counted, the §Gap framing is wrong and α's cycle scope was wrong.

## Cross-claim consistency

- Claim 1 (wiring present post-cycle, absent pre-cycle) and Claim 4 (γ's pre-cycle enumeration was accurate) together establish that this cycle implements a genuine gap, not cosmetic motion.
- Claim 2 (schema alignment) implies AC5's docs commit is meaningful: the docs name a contract the workflow actually emits, so future drift between the two is mechanically detectable.
- Claim 3 (AC4 mechanism documented twice — in workflow comment and in closeout) implies a reviewer can audit the choice without context-loading either artifact alone.
- All four claims trace to lines in version-controlled files in this branch. No claim relies on runtime behaviour not yet observed; the actual CI green-on-merge verification is γ's F2 step, deferred to post-merge.

## Source-of-truth alignment

| Term used in claims/closeout | Source of truth |
|---|---|
| `coh-linux-x64` | `.github/workflows/release.yml` line 41 (rename step) + line 48 (upload to release) |
| `coh --kata <id>` | `engine/ocaml/bin/main.ml` line 207 (`Arg.Set_string kata`) |
| `--output` (kata mode) | NOT WIRED — `engine/ocaml/bin/main.ml` line 219 declares `--output` but the kata branch (line 516) emits to `Printf.printf` (stdout). Captured via `tee` in the workflow. Follow-on noted in alpha-closeout. |
| `kata_pass` / `c_sigma` / `expected_verdict` / `score_range.{min,max}` | `engine/ocaml/bin/main.ml` lines 505–515 (JSON shape emitted by run_kata) |
| `actions/upload-artifact@v4` | github.com/actions/upload-artifact v4 release notes |
| `softprops/action-gh-release@v2` | release.yml line 46 |
| `gh release download` | gh CLI built-in; pre-installed on ubuntu-22.04 runners |

All term usage is grep-verifiable in the workspace.

## Scope discipline

This manifest covers the four claims γ's scaffold required (§Honest-claim manifest in self-coherence.md). α did not introduce additional claims beyond what the cycle's scope required — each commit's body explains its own diff, and only the cross-cutting claims (wiring, schema alignment, AC4 mechanism, no-false-negation) warrant manifest-level entries.
