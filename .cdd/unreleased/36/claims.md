---
cycle: 36
issue: "#36"
role: alpha
identity: alpha@tsc.cdd.cnos
date: 2026-05-12
convention: honest-claim manifest (cnos #344 activation §14)
---

# Honest-Claim Manifest — Cycle #36 α R1

Per cnos #344 activation §14, every load-bearing claim in α's
artifacts is listed below with (a) the assertion, (b) the source
of truth it traces to, and (c) the reproduction recipe a reviewer
can run. Designed to support cdd/review/SKILL.md rule 3.13
(honest-claim verification).

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
