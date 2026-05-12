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
