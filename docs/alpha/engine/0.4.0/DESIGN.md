# Design — Engine 0.4.0

> **Reconstructed retroactively after v0.4.0 ship. Not a contemporaneous artifact.**
> Source: commit diffs `298fcb4`, `46c6080`, `98d9f23`, `b522aa3`. No DESIGN.md was authored during the release cycle.

**Issue:** #27 (retroactive close-out of the gap this release left)
**Version:** 0.4.0
**Mode:** MCA
**Active Skills (at ship time):** none declared — partial-protocol release

---

## Problem

v0.3.1 shipped a working binary (`coh`) with one credential path: shell environment variables (`LLM_API_KEY`, `LLM_PROVIDER`, `LLM_MODEL`). For interactive development, this means the operator must either:

1. Set env vars in the shell before running `coh` — leaks secrets into shell history and `ps` output.
2. Use a wrapper script — fragile, per-user, not checked in.

There was no local config file path. The gap: credential loading was too exposed for everyday use.

A second, separate problem: the version source was `dune-build-info`, a library that had caused stale `.opam` regeneration failures three times across releases 0.1.0, 0.1.1, and 0.3.0. Version sync was manual and error-prone. The VERSION file as single source of truth was the obvious fix that had not been taken yet.

A third gap: no release automation existed beyond a CI workflow. Each release required manual coordination of VERSION bump, dune-project update, git tag, and push. This was ad-hoc and had been a source of friction.

## Decision

Three coordinated changes:

1. **Dotenv loading** (`298fcb4`): `engine/ocaml/bin/dotenv.ml` reads `.tsc/.env` (relative to `--root`) before reading environment variables. Real env vars always win. File warns if permissions are looser than 0600. This is the minimal, lowest-surface-area fix: no new dependencies, one new OCaml module.

2. **VERSION file** (`46c6080`): A plain-text `VERSION` file at repo root becomes the single source of truth. A dune build rule generates `build_version.ml` from it at build time. `dune-build-info` dependency is dropped. The release workflow gates on tag matching VERSION. No more manual sync, no more opam file drift.

3. **Release scripts** (`98d9f23`): `scripts/release.sh`, `scripts/stamp-versions.sh`, `scripts/check-version-consistency.sh` — adapted from the cnos release pipeline. `release.sh` orchestrates the full pipeline: preflight, bump, stamp, check, commit, tag, push.

## Design Constraints

*Inferred from commit messages and implementation:*

- **No new runtime dependencies.** The dotenv implementation uses only stdlib + Unix (already a dependency). Zero opam additions.
- **Real env wins.** Dotenv values never override existing env vars — the operator can always escape file-based config by setting the env var directly.
- **0600 permission gate.** The file warns if permissions are too open. Doesn't refuse to load (usability), but surfaces the risk.
- **VERSION as root-level fact.** The VERSION file sits at repo root (not inside `engine/ocaml/`) so it can be read by shell scripts without knowledge of the OCaml build system.
- **Scripts adapted, not invented.** `release.sh` is explicitly adapted from the cnos release pipeline (per commit message). Pattern reuse over reinvention.
- **Tag-matches-VERSION gate.** The release workflow (`release.yml`) was updated to fail if the git tag doesn't match VERSION. This closes the class of "tag says 0.4.0, binary says 0.3.1" mismatches.

## Alternatives Considered

*Inferred from the diff and the problem shape — not documented contemporaneously:*

- **`dune-build-info` (existing approach):** Kept causing stale opam file. Dropped. The VERSION + build rule approach is simpler and has no runtime library dependency.
- **Shell wrapper for credentials:** Would solve the env-var exposure problem but adds per-user indirection and isn't checkable. Rejected in favor of a file-based approach that's part of the project directory.
- **`.env` at repo root:** The file is placed at `.tsc/.env` (inside `.tsc/`, which is gitignored) rather than at the repo root. This keeps credentials inside the project's config namespace and away from accidental git-root operations.

## Known Gaps at Ship Time

- No CDD cycle executed. No DESIGN or PLAN authored contemporaneously. This is the gap that cycle #27 closes.
- No β review. Commits landed directly without an independent reviewer.
- γ did not write a post-release assessment or CHANGELOG row. Cycle #27 is the corrective.
- No tests for dotenv loading. The module is pure logic but has no automated test coverage.
- `release.sh` requires `interactive confirmation` (read -r -p "...") — cannot run non-interactively in CI. Suitable for operator-driven release only.
