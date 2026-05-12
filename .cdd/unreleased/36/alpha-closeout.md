---
cycle: 36
issue: "#36"
role: alpha
identity: alpha@tsc.cdd.cnos
branch: cycle/36-impl
parent_branch: cycle/36
parent_sha: e7f3817
date: 2026-05-12
round: R1
---

# α Closeout — Cycle #36

## Summary

Implemented the kata-regression CI gate per issue #36. Added one new
workflow file (`.github/workflows/katas.yml`) and one CI badge in
`katas/README.md`. Three logical commits on `cycle/36-impl` off the
γ scaffold at `e7f3817`.

## Design decision: Option A (standalone workflow file)

The dispatch prompt's §Key-design-decision recommended Option B
(adding a `katas` job to `ci.yml` that consumes the existing `build`
job's `coh-linux-x64` artifact). I chose **Option A** (standalone
`katas.yml`) for these reasons:

1. **Option B would require modifying `ci.yml`.** Issue #36 §Constraints
   says "must not modify any existing workflow." Adding a new job to
   `ci.yml` modifies that file. The dispatch prompt's "fall back to
   Option A if Option B is structurally complicated" clause covers
   this, but the cleaner reading is that the constraint forbids
   touching `ci.yml` at all.
2. **`ci.yml` already has a `kata-check` job** (lines 97–121) that
   invokes `scripts/run-katas.sh`. That job predates issue #36, has
   no cache step, and does not satisfy AC3. Reusing its artifact
   would mean two kata-related jobs in `ci.yml` (the legacy one and
   a new one), which is messier than one standalone workflow.
3. **Separation eases the cnos Cycle B + tsc C-2 template swap.** The
   forward-compat marker (`INTERIM workflow`) and standalone file are
   easier to replace wholesale than a job entry inside a multi-job
   YAML.
4. **AC3 is still satisfied** without the build-job artifact — the
   `actions/cache@v4` step caches `~/.opam` and `engine/ocaml/_build`
   keyed on `dune-project` + `Makefile` hashes. A warm run skips
   `opam install` and reuses the dune build artifacts.

Trade-off: cold runs install OPAM end-to-end (~5–8 min, same as the
existing `kata-check`). This is the AC3 "cold ≤ 8 min, warm < 3 min"
band documented in self-coherence.md §AC3 oracle.

## AC walk

### AC1 — Workflow runs on push to main + every PR

- **File:** `.github/workflows/katas.yml`
- **Triggers** (lines 26–29):
  ```yaml
  on:
    push:
      branches: [main]
    pull_request:
  ```
- **Invariant:** matches issue #36 AC1 invariant literally.
- **Negative case:** the workflow uses default `set -e` shell
  semantics in the multi-line `run:` block (line 88). The kata loop
  (lines 92–104) tracks `failed` count and `exit 1`s if `failed > 0`
  (lines 110–112). A deliberately-broken kata (e.g., `kata-01` with
  `expected.verdict = "fail"` against passing input) would surface
  as red.
- **Verification:** post-merge, γ will run `gh run list
  --workflow=katas` to confirm both `push` and `pull_request`
  events trigger runs.

### AC2 — All shipped katas run, auto-discovered

- **Auto-discovery loop** (lines 92–104):
  ```bash
  for kata_dir in katas/*/; do
    [ -f "${kata_dir}kata.toml" ] || continue
    id=$(basename "$kata_dir")
    ...
    opam exec -- coh --kata "$id" --mode mechanical
  done
  ```
- **Grep verification:** the strings `01-glider` and `02-random-soup`
  do not appear anywhere in `.github/workflows/katas.yml`:
  ```
  $ grep -E '01-glider|02-random-soup' .github/workflows/katas.yml
  (no output, exit 1)
  ```
- **Directory-only glob:** the trailing slash in `katas/*/` matches
  only directories — `katas/README.md` is skipped naturally without
  any explicit guard. The `[ -f "${kata_dir}kata.toml" ]` continue
  guard further ensures only valid kata directories run (so e.g. an
  in-progress `katas/03-foo/` with no `kata.toml` yet is skipped).
- **Phase 2 forward-compat:** when #34 ships `katas/03-*/`,
  `katas/04-*/`, `katas/05-*/` with `kata.toml`, the loop picks them
  up with no workflow edit.

### AC3 — Build cache keeps warm runtime under 3 min

- **Cache step** (lines 54–63):
  ```yaml
  - name: Cache OPAM + dune
    uses: actions/cache@v4
    with:
      path:
        - ~/.opam
        - engine/ocaml/_build
      key: katas-${{ runner.os }}-ocaml-5.2-${{ hashFiles('engine/ocaml/dune-project', 'engine/ocaml/Makefile', 'Makefile') }}
      restore-keys:
        - katas-${{ runner.os }}-ocaml-5.2-
  ```
- **Key design:**
  - `runner.os` — never share cache across runner images.
  - `ocaml-5.2` constant — bumping the compiler version invalidates
    the cache via the key string itself.
  - `hashFiles(dune-project, Makefile, top-level Makefile)` — any dep
    change (dune-project's `package` block governs OPAM deps) or
    build-config change invalidates the cache cleanly.
  - `restore-keys` — partial-match fallback: a dep-change miss still
    restores a same-OS, same-OCaml prefix and re-runs only the
    delta `opam install`.
- **Warm path:** when the cache hits, `opam install . --deps-only -y`
  is a near-no-op (deps already in `~/.opam`), and `opam install . -y`
  recompiles the engine quickly because `_build/` is restored.
  Expected warm runtime: ~1–2 min of OPAM setup-OCaml + ~30 s of
  `opam install` no-ops + kata runs (<10 s each). Under 3 min.
- **Cold path:** documented as ≤8 min in self-coherence.md AC3
  oracle; same band as the existing `kata-check` job.
- **AC3 oracle for β:** β can verify by inspecting two consecutive
  CI runs on `cycle/36-impl` — second run should hit the cache and
  complete faster.

## Commits

```
b8df57f docs(36): add katas CI status badge to katas/README.md
ecb270b ci(36): add katas regression workflow — AC1+AC2+AC3
e7f3817 (cycle/36) cycle(36): γ scaffold — self-coherence with §Gap §Mode §ACs §CDD-Trace
```

Two implementation commits + the γ scaffold. The closeout + claims
+ self-coherence-update commit follows.

## Diff stats

```
 .github/workflows/katas.yml | 112 +++++++++++++++++++++++++++++++++++
 katas/README.md             |   2 +
 2 files changed, 114 insertions(+)
```

No deletions. No modifications to existing CI files (`ci.yml`,
`release.yml`, `tsc.yml`, `cdd-notify.yml`). No engine code changes.

## Constraints check

| Constraint | Compliance |
|---|---|
| Identity exact (`alpha@tsc.cdd.cnos`) | yes — `git config user.email` returns `alpha@tsc.cdd.cnos` |
| No modification to existing workflows | yes — `katas.yml` is a new file; `ci.yml` et al. untouched |
| No engine code changes | yes — diff is workflow + one markdown line |
| Forward-compat marker | yes — `katas.yml` lines 1–22 explicitly mark this as INTERIM, citing cnos #344 Cycle B + tsc C-2 as the canonical-template swap point |
| Don't run workflow locally | yes — validated only via `python3 -c 'import yaml; yaml.safe_load(...)'` |
| Don't merge to main | yes — α stops at push of `cycle/36-impl` |

## Findings (no fixes)

- **`ci.yml`'s `kata-check` job (lines 97–121) duplicates this
  workflow's purpose** without a cache step. Reconciliation is
  deferred per the issue's no-touch-existing-workflows constraint
  and the explicit Co-existence note in `katas.yml` lines 17–22.
  Recommend a future cycle remove `kata-check` from `ci.yml` once
  this workflow has run green on main for several cycles.
- **`engine/ocaml/Makefile` is referenced in the cache key
  hashFiles list.** Verified present (`ls engine/ocaml/Makefile`)
  but no observable run-time risk if it ever moves — `hashFiles` of
  a missing file returns empty, which would just collapse the key
  prefix and effectively share the cache across Makefile revisions.
  Acceptable; documented.

## Ready for β

Per cdd/alpha/SKILL.md, α stops at this closeout. β picks up from
`cycle/36-impl` head SHA recorded in self-coherence.md §Head SHA.
