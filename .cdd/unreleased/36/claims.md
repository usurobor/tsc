---
cycle: 36
issue: "#36"
role: alpha
identity: alpha@tsc.cdd.cnos
date: 2026-05-12
convention: honest-claim manifest (cnos #344 activation §14)
rounds:
  - round: R1
    status: superseded-by-R2 (Claims 1 & 2 still hold; Claim 3 + cross-cutting gap claim corrected)
  - round: R2
    status: current
---

# Honest-Claim Manifest — Cycle #36

Per cnos #344 activation §14, every load-bearing claim in α's
artifacts is listed below with (a) the assertion, (b) the source
of truth it traces to, and (c) the reproduction recipe a reviewer
can run. Designed to support cdd/review/SKILL.md rule 3.13
(honest-claim verification).

R1 claims are preserved below for audit trail. Where R2 corrects
or supersedes a claim, the R2 version is added at the end under
§R2 claims with explicit supersession notes. Do not delete R1
text — it documents what was originally asserted and where it
failed.

# R1 claims (2026-05-12) — partially superseded

## Claim 1 — "The workflow runs on push to main and on every PR"

**Assertion** (from alpha-closeout.md §AC1, self-coherence.md §AC1
invariant, issue #36 AC1):
> Triggers include `push.branches: [main]` and `pull_request`.

**Source of truth:** `.github/workflows/katas.yml` lines 26–29.

**Reproduction:**
```bash
sed -n '26,29p' .github/workflows/katas.yml
# Expected output:
#   on:
#     push:
#       branches: [main]
#     pull_request:
```

Or equivalently, grep:
```bash
grep -E '^(on|  push|    branches|  pull_request):' .github/workflows/katas.yml
```

Both event types are syntactically present in the `on:` block. GitHub
Actions's well-known semantics (documented at
github.com/actions/toolkit) guarantee that any commit pushed to a
`main`-named branch or any pull-request event triggers a run. No
hidden filters (no `paths:`, no `paths-ignore:`, no `branches-ignore:`,
no `types:` narrowing).

**Falsification:** if a reviewer post-merge runs `gh run list
--workflow=katas --event=pull_request` and finds zero runs on any
PR that touched the repo, this claim is falsified.

## Claim 2 — "No kata names are hard-coded in the workflow"

**Assertion** (from alpha-closeout.md §AC2, self-coherence.md §AC2
oracle, issue #36 AC2):
> grep workflow YAML for `01-glider` / `02-random-soup` → zero hits.

**Source of truth:** `.github/workflows/katas.yml` lines 87–112
(the auto-discovery loop).

**Reproduction:**
```bash
grep -nE '01-glider|02-random-soup' .github/workflows/katas.yml
# Expected: no output, exit code 1
```

The loop uses `for kata_dir in katas/*/` (directory-glob), then
`id=$(basename "$kata_dir")`, then `coh --kata "$id"`. The kata
identifier is computed at runtime from the filesystem; the workflow
YAML contains no kata-specific strings.

**Forward-compat:** when tsc #34 adds `katas/03-*/`, `katas/04-*/`,
`katas/05-*/`, those katas will be picked up on next push with zero
edits to this workflow. A reviewer can verify by mentally simulating:
the glob `katas/*/` matches the new directories, the loop body
invokes `coh --kata 03-*` etc., and the job passes/fails on the
runner's exit code per `set -e`.

**Falsification:** if a reviewer adds `katas/99-test/kata.toml` and
the next workflow run does NOT attempt to run `coh --kata 99-test`,
this claim is falsified.

## Claim 3 — "Cache key invalidates cleanly on dep / build-config change"

**Assertion** (from alpha-closeout.md §AC3, self-coherence.md §AC3
oracle, issue #36 AC3):
> OPAM + dune cache via `actions/cache`; keys versioned on
> `engine/ocaml/dune-project` + `Makefile` hashes.

**Source of truth:** `.github/workflows/katas.yml` lines 54–63.

**Reproduction:**
```bash
sed -n '54,63p' .github/workflows/katas.yml
# Expected to contain:
#   key: katas-${{ runner.os }}-ocaml-5.2-${{ hashFiles(
#     'engine/ocaml/dune-project',
#     'engine/ocaml/Makefile',
#     'Makefile'
#   ) }}
```

`hashFiles` is GitHub Actions's built-in; it returns a hex digest of
the concatenated contents of all matching files. If
`engine/ocaml/dune-project` (which declares the OPAM package and its
dep list) changes, the digest changes, the key changes, and
`actions/cache@v4` records a new cache entry — the old one is not
reused (only `restore-keys` partial-match fallback applies, and that
only restores the prefix `katas-Linux-ocaml-5.2-` which is the SAME
restore-key — the partial match restores from the most-recent matching
key, which after a dep change will be a stale entry, but the
subsequent `opam install . --deps-only -y` re-resolves and updates).

**Warm-run prediction:** under 3 minutes (self-coherence.md §AC3
oracle). Components:
- `actions/cache@v4` restore: ~10–20 s for ~200 MB OPAM cache.
- `ocaml/setup-ocaml@v3`: ~10 s with cache primed.
- `opam install . --deps-only -y`: ~5–15 s no-op when deps are cached.
- `opam install . -y`: ~30–60 s engine recompile from `_build` cache.
- 2× kata runs: <30 s total (mechanical scoring is fast).

Total estimate: 90–135 s warm. Cold path is documented as ≤8 min
in self-coherence.md §AC3 oracle.

**Falsification:** if a reviewer touches `engine/ocaml/dune-project`
(adds a whitespace line is enough; `hashFiles` is content-hash) and
the next CI run reports a cache hit on the *primary* key (not just
restore-keys fallback), this claim is falsified. GitHub Actions
surfaces this in the "Cache hit" log line of the cache step.

## Cross-claim consistency

- Claim 1 (triggers) and Claim 2 (auto-discovery) together imply
  AC1 + AC2 are satisfied: the workflow fires on the right events
  and exercises every shipped kata.
- Claim 3 (cache key) implies AC3 is *structurally* satisfied; the
  empirical "under 3 min warm" is verifiable post-merge by γ
  inspecting two consecutive CI runs.
- All three claims trace to lines in `.github/workflows/katas.yml`
  and to the source-of-truth files (`dune-project`, `Makefile`,
  `katas/*/kata.toml`). No claim depends on unverifiable behavior.

## Source-of-truth alignment

| Term used in claims/closeout | Source of truth |
|---|---|
| `coh` | `engine/ocaml/bin/main.ml` — built by `dune build`; installed by `opam install . -y` |
| `--kata <id>` | `engine/ocaml/bin/main.ml` lines 207–208 (Arg.Set_string) |
| `--mode mechanical` | `engine/ocaml/bin/main.ml` line 222 (usage string) + `scripts/run-katas.sh` line 21 |
| `kata.toml` | `katas/README.md` §Directory layout + `engine/ocaml/lib/kata.ml` (parser) |
| `id == directory basename` | `katas/README.md` §Field reference table row 1 |
| `dune-project` | `engine/ocaml/dune-project` — declares OPAM package + deps |
| `actions/cache@v4` | github.com/actions/cache v4 release notes |
| `hashFiles(...)` | GitHub Actions expression syntax — built-in function |

All term usage is grep-verifiable in the workspace.

---

# R2 claims (2026-05-12) — current

R2 introduces three new/corrected claims. Claims R2-1 and R2-2 below
**supersede** R1 Claim 3 and add the cross-cutting "gap framing"
claim R1 implicitly relied on but never made explicit. R1 Claims 1
and 2 are unaffected (the trigger block and the auto-discovery loop
were not touched in R2) and remain in force.

## Claim R2-1 — "Cache key references only files that exist" (supersedes R1 Claim 3)

**Assertion** (from alpha-closeout.md §R2 round, self-coherence.md
§Gap corrected framing):
> OPAM + dune cache key in `.github/workflows/katas.yml` is hashed
> over `engine/ocaml/dune-project` and `engine/ocaml/tsc_engine.opam`
> — both files that exist in the repo. The R1 key additionally named
> `engine/ocaml/Makefile` and the repo-root `Makefile`; the former
> does not exist (R1 closeout falsely asserted it did), and the
> latter is not the engine build driver. Both have been removed
> from the key.

**Source of truth:** `.github/workflows/katas.yml` lines 58–67.

**Reproduction:**
```bash
# 1. Verify the files named in the key exist.
ls engine/ocaml/dune-project engine/ocaml/tsc_engine.opam
# Expected: both files present.

# 2. Verify the absent files are NOT named in the key.
grep -nE "engine/ocaml/Makefile|hashFiles\\(.*'Makefile'" .github/workflows/katas.yml
# Expected: no output, exit code 1.

# 3. Verify engine/ocaml/Makefile is indeed absent.
[ -e engine/ocaml/Makefile ] && echo PRESENT || echo ABSENT
# Expected: ABSENT.
```

**Why this is the right set of files.** The engine's OPAM package
metadata is declared in `dune-project` via dune's `generate_opam_files
true` directive (see `engine/ocaml/dune-project` line 1). That
directive generates `engine/ocaml/tsc_engine.opam` as a side-effect
of `dune build` / `opam install`. Hashing **both** is intentional
redundancy: if a contributor edits `dune-project`'s `package` stanza
the regenerated `.opam` also changes; if a contributor edits the
`.opam` directly (less common but legal), the hash still changes.
Either path invalidates the cache.

**Falsification:** if a reviewer adds a new dep to
`engine/ocaml/dune-project`'s `depends` list and the next CI run
reports a cache hit on the *primary* key (not the `restore-keys`
fallback), this claim is falsified.

## Claim R2-2 — "Repo has exactly one workflow exercising the katas" (consolidation invariant)

**Assertion** (from alpha-closeout.md §R2 round, self-coherence.md
§Gap corrected framing):
> After R2, `.github/workflows/katas.yml` is the only workflow file
> that invokes `coh --kata` or `scripts/run-katas.sh`. The
> `kata-check` job that previously lived in `ci.yml` (added in
> 344-c) was removed in R2 commit 1 because it duplicated katas.yml
> on coverage but had no cache and no concurrency control.

**Source of truth:** `.github/workflows/ci.yml` (post-R2), full file.
`.github/workflows/katas.yml` lines 91–113 (the kata loop).

**Reproduction:**
```bash
# 1. Exactly one workflow names `kata` as a job and invokes the runner.
grep -rEn 'coh --kata|scripts/run-katas\.sh' .github/workflows/
# Expected: matches only in katas.yml (and the consolidation-note
# comment header). No matches in ci.yml.

# 2. ci.yml's job list no longer contains kata-check.
grep -nE '^  [a-z][-a-z0-9]*:' .github/workflows/ci.yml
# Expected jobs: build, linkcheck, spec-validate. NO kata-check.

# 3. No other CI job references kata-check via `needs:`.
grep -nE 'needs:.*kata-check' .github/workflows/
# Expected: no output, exit code 1.
```

**Falsification:** if a reviewer finds a second workflow file (or a
second job within `ci.yml`) that also runs the kata suite, this
claim is falsified and the consolidation is incomplete.

## Claim R2-3 — "Cycle #36's gap statement now matches empirical CI state" (gap-framing correction)

**Assertion** (from self-coherence.md §Gap corrected framing):
> The cycle gap is no longer "CI does not invoke `coh --kata`
> against shipped kata content" (the R1 framing, which was
> empirically false at the time it was written). The gap is:
> "the existing `kata-check` job has no build cache and no
> concurrency control; cycle #36 consolidates kata-running into
> a dedicated workflow that adds both, and removes the duplicate
> job from ci.yml."

**Source of truth:** `.cdd/unreleased/36/self-coherence.md` §Gap
(both subsections — "Original (R1) framing — incorrect" and
"Corrected (R2) framing — actual").

**Reproduction:**
```bash
# The §Gap section explicitly preserves both framings.
grep -nE '^###? ' .cdd/unreleased/36/self-coherence.md | head -10
# Expected to include both:
#   ### Original (R1) framing — incorrect
#   ### Corrected (R2) framing — actual
```

**Why this matters.** R1 shipped on a false-gap premise. The
existing `kata-check` job was discoverable by `grep -r kata
.github/workflows/` from the very first dispatch and was even
noted by α R1 in its own §Findings — but α R1 did not escalate
the overlap to γ before implementing. The R2 correction documents
this honestly in alpha-closeout.md §R2 round so that the
cdd-iteration write-up can name it. Future scaffolds should
grep existing CI for the surface they claim is missing *before*
declaring the gap.

**Falsification:** if `self-coherence.md` §Gap is later edited to
remove the "Original (R1) framing — incorrect" subsection (i.e.
silently rewriting history rather than recording the correction),
this claim is falsified.

## R2 cross-claim consistency

- R2-1 (cache key files exist) and R2-2 (one kata workflow) together
  imply the surface changes from R2 commits 1 + 2 are coherent: the
  consolidated workflow's cache is honestly described and references
  real files.
- R2-3 (gap framing) is the narrative anchor that explains why R2
  exists at all. Without R2-3, R2-1 + R2-2 would read as cosmetic.
- R1 Claims 1 and 2 (triggers + auto-discovery) carry through
  unchanged — those surfaces were not touched in R2.
