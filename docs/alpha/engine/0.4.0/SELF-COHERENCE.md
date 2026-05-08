# Self-Coherence — 0.4.0

> **Reconstructed retroactively after v0.4.0 ship. Not a contemporaneous artifact.**
> No SELF-COHERENCE.md was authored during the release cycle. This document reconstructs what it would have contained, graded against the actual shipped diff.

**Issue:** #27 (retroactive close-out)
**Version:** 0.4.0
**Mode:** MCA — three coordinated improvements: dotenv credential loading, VERSION as single source of truth, release scripts.
**Active Skills (declared):** none — partial-protocol release. No CDD cycle was run.

---

## AC Evidence

Reconstructed ACs from the commit messages and problem shape (no formal AC list existed at ship time):

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| AC1 | `coh` loads credentials from `.tsc/.env` before env vars | Met | `engine/ocaml/bin/dotenv.ml` (63 lines); called in `main.ml` before `Provider.config_from_env ()` |
| AC2 | Real env vars always win over file values | Met | `Sys.getenv_opt key` check in `dotenv.ml:50` — skips `Unix.putenv` if already set |
| AC3 | Warns if `.tsc/.env` permissions are more open than 0600 | Met | `check_permissions` in `dotenv.ml:31–37` |
| AC4 | VERSION file is single source of truth for binary version | Met | `VERSION` at repo root; dune rule generates `build_version.ml`; `dune-build-info` dropped |
| AC5 | Release workflow gates on tag matching VERSION | Met | `release.yml` step "Gate — tag must match VERSION" |
| AC6 | `scripts/release.sh` automates the full release pipeline | Met | 90-line script: preflight, bump, stamp, check, commit, tag, push |
| AC7 | `scripts/check-version-consistency.sh` acts as CI gate | Met | 62-line script checks dune-project, main.ml, dune build rule |
| AC8 | No hardcoded version in source code | Met | `main.ml` uses `Build_version.version` not a string literal |

**ACs not met (gaps):**
- No dotenv tests (parse_line, check_permissions, load) — zero automated test coverage for the new module.
- Operator manual not updated with `.tsc/.env` documentation. Operators cannot discover the feature without reading source.
- No CHANGELOG row at tag time. No frozen artifact directory.

---

## Triadic Assessment

### α — Pattern Coherence

The implementation artifacts are internally coherent:

- `dotenv.ml` is well-factored: three functions (`parse_line`, `check_permissions`, `load`), each with a single responsibility. The security constraint (real env wins) is enforced at the point of application — `Sys.getenv_opt` check before `Unix.putenv`. Quote-stripping handles the common case without a dependency.
- The VERSION refactor correctly identifies the root cause of opam staleness (dune-build-info as an indirection layer that needs opam regeneration on change) and removes it entirely. The dune build rule is the idiomatic pattern.
- Release scripts are logically sequenced: stamp → check → commit → tag → push. `check-version-consistency.sh` independently verifies what `stamp-versions.sh` produced, which is the correct validation structure.

What α missed:
- No tests for `dotenv.ml`. A module that reads files, checks permissions, and sets env vars is testable and should have been tested.
- Operator manual not updated. Feature is invisible to operators who don't read source.

**Score: B** — Solid implementation architecture, zero test coverage for new module, docs surface not updated.

### β — Relational Coherence

No β review cycle occurred. Commits landed directly without an independent reviewer.

What was not reviewed:
- Whether `dotenv.ml` should refuse (not just warn) on overpermissive file
- Whether `.tsc/.env` loading should be conditional on a flag rather than always-on
- Whether the operator manual update was required before shipping
- Whether `release.sh`'s interactive confirmation (`read -r -p`) is appropriate given it cannot be used in CI

**Score: C+** — No formal review. The code is self-consistent but no surface agreement audit occurred.

### γ — Process Coherence

γ did not:
- File an issue before the release
- Author a DESIGN, PLAN, or SELF-COHERENCE doc
- Write a CHANGELOG ledger row
- Create a frozen artifact directory
- Write a post-release assessment

Cycle #27 exists to close the gap γ created. This is the direct evidence of γ failure.

**Score: C** — Complete protocol miss. Retrospective corrective required.

### C_Σ

Geometric mean: `(B × C+ × C)^(1/3)`

Using numeric mapping (B = 3.0, C+ = 2.3, C = 2.0):
`(3.0 × 2.3 × 2.0)^(1/3) = (13.8)^(1/3) ≈ 2.40` → **C+**

---

## Known Debt

- `dotenv.ml` has no tests. Any future change to the parsing logic has no regression guard.
- `.tsc/.env` feature is undocumented in the operator manual. Operators must read source to discover it.
- `release.sh` requires interactive input — cannot be used non-interactively. Suitable for operator-driven releases only.
- All CDD artifacts for this release were reconstructed post-hoc (cycle #27). The reconstruction is honest but cannot substitute for contemporaneous design rationale.
