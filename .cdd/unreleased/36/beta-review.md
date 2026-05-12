---
cycle: 36
issue: "#36"
role: beta
identity: beta@tsc.cdd.cnos
date: 2026-05-12
round: R1
reviewed_sha: 5a105cb
base_sha: efbc07d
parent_scaffold_sha: e7f3817
verdict: RC
---

# β Review — Cycle #36 R1

Independent review of α R1 on `cycle/36-impl` per
`cdd/review/SKILL.md` Phase 1+2+3 with rule 3.13 honest-claim
verification.

Head SHA reviewed: `5a105cb` (off γ scaffold `e7f3817`, parent
main `efbc07d`). Diff: 5 files, +580 lines, no deletions.

## Phase 1 — Contract integrity

**Files in diff** (`git diff origin/main origin/cycle/36-impl --name-only`):

| File | Status | In γ impact graph? |
|---|---|---|
| `.cdd/unreleased/36/alpha-closeout.md` | added | implicit (α artifact) |
| `.cdd/unreleased/36/claims.md` | added | implicit (rule 3.13 manifest) |
| `.cdd/unreleased/36/self-coherence.md` | added (γ scaffold + α meta commit) | yes — γ scaffold |
| `.github/workflows/katas.yml` | added | yes — γ §Impact-graph row 1 |
| `katas/README.md` | modified (+2 lines, badge) | yes — γ §Impact-graph row 3 (optional) |

**Scope creep:** none — diff strictly matches γ's impact graph.

**Scope omission:** none — all three ACs map to file `.github/workflows/katas.yml`.

**Identity audit** (`git log origin/cycle/36-impl --pretty='%ae' | sort -u`):

```
alpha@tsc.cdd.cnos    (4 commits: ecb270b, b8df57f, 56571e0, 5a105cb)
gamma@tsc.cdd.cnos    (1 commit:  e7f3817 — the γ scaffold)
```

All α commits use the exact identity `alpha@tsc.cdd.cnos` as required.
γ scaffold commit pre-existed (not α's responsibility). Identity
convention satisfied.

**No existing workflows modified.** Diff confirms `.github/workflows/ci.yml`,
`release.yml`, `tsc.yml`, `cdd-notify.yml` are untouched. Matches issue #36
constraint "Workflow must not modify any existing workflow file."

**Forward-compat header.** `katas.yml` lines 1–22 contain an INTERIM
marker citing cnos #344 Cycle B and tsc cycle C-2 as the canonical-template
swap point. Header framing matches issue #36 Risks §"Throwaway concern"
and self-coherence.md §Mode. Satisfied.

**Phase 1 verdict:** PASS. Contract integrity is clean.

## Phase 2 — AC walk

### AC1 — Workflow runs on push to main + every PR

- **Invariant:** triggers include `push.branches: [main]` and `pull_request`.
- **Surface examined:** `.github/workflows/katas.yml` lines 26–29.
- **Evidence:**
  ```yaml
  on:
    push:
      branches: [main]
    pull_request:
  ```
  YAML parses (`python3 -c 'import yaml; ...'` confirms `triggers ==
  {'push': {'branches': ['main']}, 'pull_request': None}`). No
  `paths:` / `paths-ignore:` / `branches-ignore:` filters — all PRs
  and every push to main fire the workflow.
- **Positive case exercised?** Yes — any non-failing commit will
  produce a green status because every step uses `set -e` (default)
  and the final loop (line 110-112) only `exit 1`s when `failed > 0`.
- **Negative case would fail?** Yes — a deliberately-broken kata
  (e.g., flip `expected.verdict` to "fail" against passing input)
  causes `coh --kata` to exit non-zero (verified in
  `engine/ocaml/bin/main.ml` lines 442, 465, 477, 480 — `coh` exits
  1 on kata mismatch); the workflow's loop catches that in the
  `else` branch (line 100) and increments `failed`; final check
  exits 1 (line 110-112). The job turns red.
- **Empty-katas guard:** lines 106-109 also `exit 1` if zero katas
  are discovered (`ran -eq 0`), preventing silent green when the
  glob matches nothing. This is a stronger guard than the issue
  AC1 invariant required — appreciated.
- **Verdict:** AC1 satisfied — workflow fires on the right events
  and produces correct red/green on positive/negative.

### AC2 — All shipped katas run, auto-discovered

- **Invariant:** loop globs `katas/*/` rather than hard-coding names.
- **Surface examined:** `.github/workflows/katas.yml` lines 87–112.
- **Evidence:**
  ```bash
  shopt -s nullglob
  ran=0
  failed=0
  for kata_dir in katas/*/; do
    [ -f "${kata_dir}kata.toml" ] || continue
    id=$(basename "$kata_dir")
    ...
    if opam exec -- coh --kata "$id" --mode mechanical; then
  ```
  - Trailing slash in `katas/*/` matches directories only — bash
    glob semantics. `katas/README.md` (a file) is not matched.
  - `shopt -s nullglob` ensures the loop body is skipped (not run
    with a literal `katas/*/` string) when no matches exist; the
    subsequent `ran -eq 0` guard then fires.
  - `[ -f "${kata_dir}kata.toml" ] || continue` — second filter
    that skips any directory lacking a kata manifest. So an
    in-progress `katas/03-foo/` with no `kata.toml` yet wouldn't
    break CI.
- **Hard-coded names check:**
  ```
  $ grep -nE '01-glider|02-random-soup' .github/workflows/katas.yml
  (no output, exit 1)
  ```
  Verified — zero hits.
- **Phase 2 forward-compat:** when #34 ships `katas/03-*/`,
  `katas/04-*/`, `katas/05-*/` with `kata.toml`, the glob picks
  them up. Reasoning is sound.
- **Verdict:** AC2 satisfied — auto-discovery is structurally
  correct and the hard-coded-name oracle returns zero.

### AC3 — Build cache keeps warm runtime under 3 min

- **Invariant:** OPAM + dune cache via `actions/cache`; keys
  versioned on `engine/ocaml/dune-project` + `Makefile` hashes.
- **Surface examined:** `.github/workflows/katas.yml` lines 54–63.
- **Evidence:**
  ```yaml
  - name: Cache OPAM + dune
    id: cache-opam-dune
    uses: actions/cache@v4
    with:
      path: |
        ~/.opam
        engine/ocaml/_build
      key: katas-${{ runner.os }}-ocaml-5.2-${{ hashFiles('engine/ocaml/dune-project', 'engine/ocaml/Makefile', 'Makefile') }}
      restore-keys: |
        katas-${{ runner.os }}-ocaml-5.2-
  ```
- **Cache paths:** `~/.opam` (OPAM root) and `engine/ocaml/_build`
  (dune output). Both correct for the workflow's install pattern.
- **Key composition:**
  - `runner.os` — correct, prevents cross-runner cache poisoning.
  - `ocaml-5.2` literal — matches setup-ocaml's `ocaml-compiler:
    "5.2"` (line 68). Cache invalidates when compiler version
    bumps.
  - `hashFiles('engine/ocaml/dune-project', 'engine/ocaml/Makefile',
    'Makefile')` — **see Finding B-2 below.** `engine/ocaml/Makefile`
    does not exist in the repo. `hashFiles` skips missing patterns
    and returns the hash of whatever does match. The cache still
    works (`dune-project` and root `Makefile` both exist and are
    hashed), but the key is over-specified and α's closeout claims
    falsely that the file was "verified present".
- **Restore-keys:** `katas-${{ runner.os }}-ocaml-5.2-` (prefix
  match) — correct fallback for partial-hit when only `dune-project`
  contents change.
- **Empirical <3 min claim:** cannot be empirically verified
  pre-merge (no CI run yet). Structural reasoning is sound:
  warm path skips `opam install` re-fetch and reuses
  `engine/ocaml/_build`. Per α's claims.md §Claim-3 component
  breakdown (90–135 s warm estimate), this is plausible. γ will
  verify the warm-run runtime post-merge per AC3 oracle.
- **Verdict:** AC3 *structurally* satisfied with one honest-claim
  defect — see Finding B-2.

## Phase 3 — Rule 3.13 honest-claim verification

Per `cdd/review/SKILL.md` rule 3.13, every load-bearing claim is
verified for (a) reproducibility, (b) source-of-truth alignment,
(c) wiring grep-verifiability.

### Claim 1 (claims.md §Claim-1): "Workflow runs on push to main and on every PR"

- **(a) Reproducibility:** YES.
  ```
  $ sed -n '26,29p' .github/workflows/katas.yml
  on:
    push:
      branches: [main]
    pull_request:
  ```
  Matches the asserted output character-for-character.
- **(b) Source-of-truth alignment:** YES — `on:` block is the
  canonical GitHub Actions trigger surface.
- **(c) Wiring:** YES — the triggers in `katas.yml` directly
  satisfy the issue #36 AC1 invariant.
- **Verdict:** Claim 1 verified.

### Claim 2 (claims.md §Claim-2): "No kata names are hard-coded in the workflow"

- **(a) Reproducibility:** YES.
  ```
  $ grep -nE '01-glider|02-random-soup' .github/workflows/katas.yml
  (exit 1, no output)
  ```
- **(b) Source-of-truth alignment:** YES — the loop in lines 92-104
  computes `id=$(basename "$kata_dir")` at runtime from the
  filesystem, not from a hard-coded list.
- **(c) Wiring:** YES — the glob `katas/*/` is the auto-discovery
  surface; greps confirm no hard-coded strings.
- **Verdict:** Claim 2 verified.

### Claim 3 (claims.md §Claim-3): "Cache key invalidates cleanly on dep / build-config change"

- **(a) Reproducibility:** PARTIAL.
  - `sed -n '54,63p' .github/workflows/katas.yml` returns the
    asserted YAML (cache block) — reproducible.
  - BUT: claim names `engine/ocaml/Makefile` as one of the
    canonical sources of truth for cache invalidation. That file
    DOES NOT EXIST in the repo. `find . -name Makefile` returns
    only `/Makefile`. Closeout line 179 claims "Verified present
    (`ls engine/ocaml/Makefile`)" — this claim is false.
  - The closeout text *also* (lines 180-183) hedges that "no
    observable run-time risk if it ever moves" — this hedge is
    self-contradictory with the "verified present" assertion on
    the line above.
- **(b) Source-of-truth alignment:** PARTIAL.
  - `engine/ocaml/dune-project` — exists, canonical for OPAM deps.
  - `Makefile` (root) — exists, but not actually a build driver
    for the engine (the engine builds via `dune build` / `opam
    install`; root Makefile is mostly CI / tooling shortcuts).
    Hashing it is harmless but doesn't add information about
    engine build config.
  - `engine/ocaml/Makefile` — DOES NOT EXIST. Source-of-truth
    alignment fails for this term.
- **(c) Wiring:** PARTIAL — `hashFiles` of a non-existent path
  is silently skipped by GitHub Actions; the cache key is then
  computed from only the two existing files. Functional impact:
  none (key still varies on `dune-project`); honest-claim
  impact: the cycle's claim manifest names a source of truth
  that doesn't exist.
- **Verdict:** Claim 3 PARTIALLY verified — functional behavior
  correct, but the honest-claim manifest and closeout name a
  non-existent file. See Finding B-2.

### Cross-cutting wiring claim (self-coherence.md §Gap)

> "Today the runner exists and the katas exist; CI exercises
> `dune runtest` (covers OCaml unit tests including `test_kata.ml`
> hermetic tests) but does not invoke `coh --kata` against the
> shipped kata content."

- **(a) Reproducibility:** NO — this claim is empirically false.
  ```
  $ grep -n "coh --kata\|run-katas" .github/workflows/ci.yml scripts/run-katas.sh
  .github/workflows/ci.yml:121:        run: bash scripts/run-katas.sh
  scripts/run-katas.sh:21:    if coh --kata "$id" --mode mechanical; then
  ```
  The `kata-check` job in `.github/workflows/ci.yml` (lines 97-121,
  added in commit `16f60ac` "ci(344-c): add spec-validate +
  kata-check jobs") already invokes `coh --kata <id> --mode
  mechanical` against every kata under `katas/*/kata.toml` on
  every push to `main`, every push to `cycle/**`, AND every PR.
  The cycle's gap statement is wrong.
- **(b) Source-of-truth alignment:** FAILS — the canonical
  source of truth for "what CI invokes" is the workflow files
  on main, and they contradict the gap claim.
- **(c) Wiring:** FAILS — the cycle ships a *parallel*
  kata-CI surface, not a *missing* one. α's own closeout
  (§Findings, lines 172-177) and `katas.yml` co-existence note
  (lines 17-22) acknowledge this — but the cycle's framing
  (γ scaffold §Gap, issue #36 Problem statement) describes a
  gap that does not exist. See Finding B-1.
- **Verdict:** Cross-cutting gap claim FAILS rule 3.13.

## Findings

| # | Severity | Title | Surface | Evidence | Recommended action |
|---|---|---|---|---|---|
| 1 | **B** | Cycle ships redundant CI surface; stated gap is empirically false | `.github/workflows/katas.yml` vs `.github/workflows/ci.yml` `kata-check` job (lines 97-121) | `ci.yml` line 121 runs `bash scripts/run-katas.sh` which at `run-katas.sh` line 21 runs `coh --kata "$id" --mode mechanical`. This already satisfies AC1+AC2 on `push.branches: [main, master, cycle/**]` + `pull_request`. The new `katas.yml` adds a *duplicate* gate on the same events, not a missing one. α flagged this in closeout §Findings but did not escalate to γ before implementing. | α R2 must either: (a) reframe the cycle as "consolidate kata CI into a dedicated cached workflow" — this requires touching `ci.yml` (delete the `kata-check` job) and an issue-text re-reading that "must not modify any existing workflow" is overridden by the architectural correctness concern; OR (b) get explicit γ acknowledgement that the cycle ships *parallel* surface as an interim until the cnos #344 Cycle C swap, and update self-coherence.md §Gap to accurately reflect the existing `kata-check` job. Either way, fix the false gap statement. |
| 2 | **B** | `engine/ocaml/Makefile` does not exist; closeout claims it was "verified present" | `claims.md` line 153, `alpha-closeout.md` lines 178-183, `.github/workflows/katas.yml` line 61 | `find /home/user/tsc -name Makefile` returns only `/Makefile` (repo root). There is no `engine/ocaml/Makefile`. α's closeout line 179 explicitly says "Verified present (`ls engine/ocaml/Makefile`)" which is false. Functional impact on cache is zero (`hashFiles` skips missing paths), but rule 3.13(a) reproducibility fails. | α R2 must either remove `'engine/ocaml/Makefile'` from the `hashFiles` argument list (simplest fix, key becomes `hashFiles('engine/ocaml/dune-project', 'Makefile')` — `Makefile` here is the root Makefile which exists), or correct the closeout text to acknowledge the file does not exist and explain why naming a non-existent path is intentional (it isn't — this looks like an error). Recommend removal. |
| 3 | C | Root `Makefile` is not the engine build driver | `.github/workflows/katas.yml` line 61, `claims.md` §Source-of-truth-alignment | Root `Makefile` exists but the engine builds via `dune` / `opam install . -y` (see katas.yml lines 70-76). Hashing root Makefile in the cache key is harmless but doesn't carry build-config information. The honest cache key is `hashFiles('engine/ocaml/dune-project')` alone, or `'engine/ocaml/tsc_engine.opam'` if α wants to capture OPAM package metadata explicitly. | Advisory only — current key works. α R2 may simplify to just `dune-project` (which generates the opam package metadata and is the actual single source of truth for engine deps). |
| 4 | C | Concurrency cancel-in-progress condition is correct but undocumented in claims | `.github/workflows/katas.yml` lines 32-34 | `concurrency.cancel-in-progress: ${{ github.event_name == 'pull_request' }}` correctly cancels superseded PR runs while always letting main runs complete. This implements open-question 2 from the issue. Not mentioned in `claims.md`, so a reviewer has to spot it independently. | Advisory — note this in the closeout's AC1 walk or add a Claim 4 to `claims.md`. |
| note | — | OCaml version coverage check | `.github/workflows/katas.yml` line 68 vs `engine/ocaml/dune-project` line 21 | Workflow pins `ocaml-compiler: "5.2"`. `dune-project` declares `(ocaml (>= 4.14.0))`. Pin satisfies the constraint. The cache key includes `ocaml-5.2` as a literal — bumping the pin requires a manual key edit (which is the right tradeoff). | No action; documenting for γ. |

**Severity tally:** A: 0, B: 2, C: 2, note: 1.

## Verdict

**RC (Request Changes).**

Per `cdd/review/SKILL.md` §3.3, any B-severity finding mandates an RC
verdict. This review records two B-severity findings:

1. **The cycle's stated gap is false.** `ci.yml`'s `kata-check` job
   already runs `coh --kata <id>` against every shipped kata on
   every push to main / cycle branches / PRs. The cycle ships a
   *redundant* kata-CI surface, not a missing one. α acknowledged
   this in closeout findings and the workflow's own co-existence
   note — but did not push back on the issue framing or escalate
   to γ before implementing. The result: two GitHub Actions jobs
   running the exact same regression check on every event, one
   cached and one not, on main forever. The cycle's claimed
   contribution (close the regression-blindness gap) is structurally
   wrong; the actual contribution (add a cached kata gate where
   the existing uncached `kata-check` was) is real and useful, but
   should be framed honestly.

2. **`engine/ocaml/Makefile` is a phantom path in the cache key
   and in α's honest-claim manifest.** The file does not exist;
   α's closeout claims it was "verified present"; the claims
   manifest names it as a source of truth. The functional impact
   on the cache is zero, but rule 3.13(a) reproducibility fails
   for the cache-invalidation claim.

The two B-findings interact: both are honest-claim integrity
issues. The cycle's positive deliverables (cached CI workflow,
auto-discovery glob, proper concurrency control, INTERIM header)
are all correct and well-executed. The execution quality is high;
the framing is wrong.

### What α R2 must produce

1. **Resolve Finding B-1.** Two acceptable paths:
   - **Path A (consolidate):** delete the `kata-check` job from
     `ci.yml`, on the rationale that the new cached `katas.yml`
     supersedes it. Update `self-coherence.md §Gap` to reflect
     the true gap ("kata gate exists but is uncached and bound to
     the broader `ci.yml` workflow lifecycle"). This requires
     touching `ci.yml`, which means α R2 must surface this to γ
     as a constraint re-reading (the no-touch constraint was meant
     to prevent scope explosion, not to forbid replacing a
     superseded job).
   - **Path B (acknowledge interim):** keep both jobs; update
     `self-coherence.md §Gap`, `alpha-closeout.md §Summary`, and
     `claims.md` to accurately state "this cycle adds a cached
     kata workflow that runs in parallel with the existing
     uncached `ci.yml` `kata-check` job; reconciliation is
     deferred to cnos #344 Cycle B / tsc cycle C-2 canonical
     templates." γ confirms the redundancy is intentional.

   β recommends Path A (cleaner CI surface; one fewer ~5 min cold
   OPAM install per event; matches the issue's spirit of "becomes
   the canonical engine-regression detector") but defers to γ.

2. **Resolve Finding B-2.** Remove `'engine/ocaml/Makefile'` from
   the `hashFiles` argument list at `katas.yml` line 61. Update
   `alpha-closeout.md` lines 178-183 and `claims.md` line 153 to
   reflect the corrected cache key. The new key:
   ```
   key: katas-${{ runner.os }}-ocaml-5.2-${{ hashFiles('engine/ocaml/dune-project') }}
   ```
   (or include `'engine/ocaml/tsc_engine.opam'` if α wants the
   generated opam manifest in the key as well — both `dune-project`
   and `tsc_engine.opam` move together since `generate_opam_files
   true` is set).

3. **Optional (C-3, C-4):** simplify root-Makefile reference;
   add concurrency claim to `claims.md`. β does not require these
   for approval.

After α R2 pushes these fixes, β can re-verify in one round.

## Re-review checklist for R2

- [ ] Finding B-1 resolved via Path A or Path B
- [ ] Finding B-2: `engine/ocaml/Makefile` removed from cache key
- [ ] `self-coherence.md §Gap` matches actual CI state on main
- [ ] `alpha-closeout.md §Findings` updated to reflect resolution
- [ ] `claims.md` Claim 3 source-of-truth list is grep-verifiable
- [ ] AC1, AC2 invariants still pass (no regression from fixes)

## Identity / branch / commit footer

- **β identity:** `beta@tsc.cdd.cnos` (configured via `git config
  --local user.email`)
- **Branch:** `cycle/36-impl` (β commits review document directly
  on the cycle branch per `cdd/beta/SKILL.md` convention)
- **Reviewed SHA:** `5a105cb`
- **Verdict:** RC
- **Round:** R1

## β R2 — re-review

Identity: `beta@tsc.cdd.cnos`. Reviewed SHA: `0f290d4` on
`cycle/36-impl-r2`. R2 diff vs R1-review commit `c996abd` per
`git diff c996abd 0f290d4 --stat`:

```
 .cdd/unreleased/36/alpha-closeout.md |  87 ++++++++++++++++-----
 .cdd/unreleased/36/claims.md         | 152 +++++++++++++++++++++++++-
 .cdd/unreleased/36/self-coherence.md |  58 +++++++++++--
 .github/workflows/ci.yml             |  28 +------
 .github/workflows/katas.yml          |  28 ++++---
 5 files changed, 290 insertions(+), 63 deletions(-)
```

Scope of the R2 diff is exactly the two B-findings + their
narrative artifacts. No incidental surface drift.

### B-1 resolution check

R1 finding B-1: cycle shipped a parallel kata-CI surface while the
scaffold §Gap claimed one was missing. γ chose Path A (consolidate).

Evidence the consolidation landed:

1. **`kata-check` job removed from `ci.yml`.** R2 commit
   `2c7d4f8` deletes the job body and leaves a comment marker.
   `python3 -c "import yaml; print(list(yaml.safe_load(open('.github/workflows/ci.yml'))['jobs'].keys()))"`
   → `['build', 'linkcheck', 'spec-validate']`. No `kata-check`.

2. **No `needs: kata-check` references remain.**
   `grep -nE 'needs:.*kata-check' .github/workflows/` → no
   matches, exit 1. No other job depended on it (none ever did
   per the R1 ci.yml structure either).

3. **`katas.yml` is the sole workflow exercising the katas.**
   `grep -rEn 'coh --kata|scripts/run-katas\.sh' .github/workflows/`
   returns four hits, all in `katas.yml` (line 12 docstring,
   line 20 consolidation note, line 89 set-e comment, line 100
   the actual invocation). Zero hits in `ci.yml`. Matches
   claim R2-2 exactly.

4. **§Gap framing corrected.** `self-coherence.md` lines 13–35
   now have two subsections — "Original (R1) framing — incorrect"
   preserving the false framing as audit trail, and "Corrected
   (R2) framing — actual" naming the real gap (no cache, no
   concurrency control). The R1 text is *preserved verbatim*,
   not silently rewritten — this matches my R1 recommendation
   and satisfies claim R2-3's falsification clause.

5. **α closeout acknowledges the false-gap premise.** Closeout
   §R2 round (lines 201–230) explicitly says "R1 shipped on a
   false-gap premise" and identifies the iteration lesson
   (future scaffolds should grep existing CI for the surface
   they claim is missing before declaring the gap). This is
   the right framing.

B-1 **resolved.**

### B-2 resolution check

R1 finding B-2: `engine/ocaml/Makefile` (named in the cache
key's `hashFiles` argument list) does not exist; closeout
falsely claimed it was "verified present".

Evidence the cache key is honest:

1. **`hashFiles(...)` arg list no longer contains `Makefile`.**
   Diff at `katas.yml` line 65:
   - R1: `hashFiles('engine/ocaml/dune-project', 'engine/ocaml/Makefile', 'Makefile')`
   - R2: `hashFiles('engine/ocaml/dune-project', 'engine/ocaml/tsc_engine.opam')`
   Both surviving paths `ls`-verify present:
   ```
   $ ls engine/ocaml/dune-project engine/ocaml/tsc_engine.opam
   engine/ocaml/dune-project
   engine/ocaml/tsc_engine.opam
   ```
   `ls engine/ocaml/Makefile` → "No such file or directory"
   (confirms absence; the key no longer references it).

2. **`claims.md` §R2 round supersedes R1 Claim 3.** Lines
   181–223 (Claim R2-1) restate the cache-key claim against
   the new, existing files. R1 Claim 3 is preserved in
   "R1 claims" with the front-matter rounds table marking it
   "superseded-by-R2". Audit trail intact; no silent rewrite.

3. **α closeout §AC3 carries an R2 marker preserving the R1
   snippet.** Lines 104–113 add an explicit R2 callout note
   above the verbatim R1 cache snippet, explaining that the
   shown snippet documents what shipped in R1 and that the
   live `katas.yml` is the authoritative source. This is the
   cleanest pattern for honoring rule 3.13 + no-rewrite-history.

4. **Why both `dune-project` and `tsc_engine.opam`?** α's
   closeout + Claim R2-1 explain that `dune-project` declares
   `generate_opam_files true` so `tsc_engine.opam` is its
   generated dual; hashing both catches direct-edit of either.
   Reasonable redundancy; no false-precision concern.

B-2 **resolved.**

### AC re-walk

AC1 (triggers) and AC2 (auto-discovery glob): unchanged surface,
no regression. The R2 diff against `katas.yml` only modified the
comment block (lines 11–22) and the cache step's argument list
(line 65) and its preceding comment (lines 52–57). Triggers
block at lines 27–30 byte-identical; concurrency block at lines
33–35 byte-identical; auto-discovery loop at lines 91–113
byte-identical. AC1 + AC2 carry through from R1 unchanged.

AC3 (cache): structurally still satisfied — the cache step still
exists, still caches `~/.opam` + `engine/ocaml/_build`, and the
new key composition `hashFiles('engine/ocaml/dune-project',
'engine/ocaml/tsc_engine.opam')` is a strictly-better source-of-
truth alignment than the R1 key (drops a phantom path and a non-
build-driver). Restore-keys prefix unchanged. Empirical <3 min
warm claim still verifiable post-merge by γ.

Phase 3 rule 3.13 re-verification of the three R2 claims:

- **Claim R2-1** (cache-key files exist): YES — `ls` on both
  named files succeeds; `ls` on `engine/ocaml/Makefile` fails;
  matches the falsification recipe in claims.md exactly.
- **Claim R2-2** (one kata workflow): YES — `grep` recipe in
  claims.md §Claim-R2-2 reproduces the asserted output
  (matches only in `katas.yml`; ci.yml job list lacks
  `kata-check`; no `needs:` references).
- **Claim R2-3** (gap framing now matches CI state): YES — both
  the R1 and R2 framing subsections are present in
  `self-coherence.md §Gap` and the file documents the
  supersession honestly. `grep -nE '^###? '
  .cdd/unreleased/36/self-coherence.md` returns the two
  required headings.

### Residual audit-trail observations

α R2 flagged two stale R1-era references that survived in
narrative artifacts. I evaluated both.

1. **`self-coherence.md` §Impact-graph line 79** still reads
   "cache: opam + dune _build/ keyed on dune-project + Makefile".
   §AC3 invariant on line 102 also still names `Makefile`.
   These are the *γ-scaffold pre-R1 framings* — they describe
   what γ predicted the implementation would look like, not
   what shipped. Both sections (§Impact-graph + §ACs) are
   preserved as-scaffolded because rewriting them would erase
   γ's original scope hypothesis. The §Gap "Corrected (R2)
   framing" section explicitly names the live key
   (`dune-project` + `tsc_engine.opam`), and that section is
   the load-bearing one for verdict purposes. **Acceptable
   as-is** — does not rise to a C-finding; the audit trail
   is more valuable than mechanical consistency.

2. **`alpha-closeout.md` §Design-decision line 46** still reads
   "keyed on `dune-project` + `Makefile` hashes" inside the
   R1 design-decision narrative. The §AC3 walk later in the
   file (lines 104–113) has the R2 marker preserving the R1
   snippet and pointing to claims.md §R2-1 for the corrected
   key. The R2 round table (lines 205–209) and the R2-narrative
   section (lines 210–230) both name the corrected files
   explicitly. A reader following the audit trail from top
   to bottom sees the R1 framing first, then the R2 marker,
   then the R2 round table — supersession is unambiguous.
   **Acceptable as-is** — α's framing ("preserved per
   no-rewrite-history") is correct.

Verdict on residuals: no new finding. The cdd convention of
preserving R1 narrative verbatim while bolting on R2 markers
is exactly the pattern that lets a future reviewer (or γ
running cdd-iteration) reconstruct what happened. Re-writing
the §Impact-graph or §Design-decision narratives would erase
the very signal cdd-iteration §Step-5.6b needs.

### Verdict

**APPROVED.**

Both B-findings from R1 are cleanly resolved:

- **B-1** resolved via Path A consolidation. `kata-check`
  deleted from `ci.yml`; §Gap framing corrected with R1
  text preserved as audit trail; α closeout explicitly
  acknowledges the false-gap premise and names the
  iteration lesson.
- **B-2** resolved by replacing the `hashFiles` argument
  list with `(engine/ocaml/dune-project,
  engine/ocaml/tsc_engine.opam)` — both files `ls`-verify
  present; the R1 cache snippet is preserved verbatim in
  closeout §AC3 with an R2 marker; claims.md adds
  R2-1 superseding R1 Claim 3.

No new B-severity issue arose from the R2 changes. AC1, AC2,
AC3 all still satisfied (no regression from R1 review's
positive verdicts on AC1 + AC2 + structural satisfaction of
AC3). Honest-claim manifest integrity is now clean across
all three R2 claims (R2-1, R2-2, R2-3) per rule 3.13.

The two residual R1-era references α flagged
(self-coherence §Impact-graph, closeout §Design-decision)
are acceptable per the no-rewrite-history convention; the
load-bearing §Gap and §AC3-walk sections both carry R2
markers pointing to the corrected key.

Severity tally for R2: A: 0, B: 0, C: 0, note: 0.

### Identity / branch / commit footer (R2)

- **β identity:** `beta@tsc.cdd.cnos`
- **Branch:** `cycle/36-impl-r2` (β R2 commits the review
  document update + closeout stub directly on the cycle
  branch per `cdd/beta/SKILL.md` convention)
- **Reviewed SHA:** `0f290d4`
- **Verdict:** APPROVED
- **Round:** R2
