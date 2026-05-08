# Plan — Engine 0.4.0

> **Reconstructed retroactively after v0.4.0 ship. Not a contemporaneous artifact.**
> Sequence reconstructed from commit order and timestamps. No PLAN.md was authored during the release cycle.

**Issue:** #27 (retroactive close-out)
**Version:** 0.4.0

---

## Actual Implementation Sequence

The actual sequence — as executed — deviates from the optimal CDD artifact order (design → plan → tests → code → docs → self-coherence → review). It was code-first, no design phase, no review.

| Step | Commit | What happened |
|------|--------|---------------|
| 1 | `298fcb4` | `dotenv.ml` authored (63 lines), added to `bin/dune` module list, called from `main.ml`. `.gitignore` updated to exclude `.tsc/`. |
| 2 | `46c6080` | VERSION file created at repo root. Dune rule generates `build_version.ml` from VERSION. `dune-build-info` dependency dropped. `release.yml` gated on tag-matches-VERSION. |
| 3 | `98d9f23` | Release scripts added: `scripts/release.sh`, `scripts/stamp-versions.sh`, `scripts/check-version-consistency.sh`. `dune-project` gets the `(version ...)` stanza back for opam metadata. |
| 4 | `b522aa3` | VERSION bumped to `0.4.0`. `dune-project` bumped to `0.4.0`. Tag pushed. |

**Elapsed time (commit timestamps):** Commits 1–3 spanned ~18 minutes (15:13–15:31 UTC). Commit 4 followed 2 minutes later. Total: ~20 minutes from first commit to tag.

---

## What the Optimal CDD Sequence Would Have Been

For a release of this size (3 substantive commits, dotenv feature + VERSION refactor + release scripts), the CDD path would be:

1. **Design** — name the incoherence (credential exposure, version sync fragility, manual release process), decide the fix shape
2. **Plan** — sequence the steps, note dependencies
3. **Tests** — at minimum: dotenv parse_line unit tests, check_permissions test
4. **Code** — `dotenv.ml`, VERSION file + dune rule, scripts
5. **Docs** — update operator manual to document `.tsc/.env` usage
6. **Self-coherence** — AC mapping, triadic assessment
7. **Review** — independent β review
8. **Gate** — CI green, CHANGELOG row written
9. **Release** — tag + CHANGELOG
10. **Post-release assessment** — coherence measurement, next move

**What was skipped:** steps 1 (design), 2 (plan), 3 (tests), 5 (docs), 6 (self-coherence), 7 (review), 8 (CHANGELOG gate), and 10 (post-release assessment). Cycle #27 retroactively closes the documentation and assessment gaps.

**What cannot be retroactively created:** contemporaneous tests, contemporaneous review, contemporaneous design rationale (only reconstructed here). The code shipped without them.

---

## Notes on Implementation Ordering

The actual order (dotenv → VERSION → scripts) was internally coherent:

- `dotenv.ml` doesn't depend on the VERSION refactor; it could ship standalone.
- The VERSION refactor was a prerequisite for `release.sh` (which reads VERSION).
- `scripts/` depended on the VERSION file and the dune build rule existing.

The ordering was correct even without a formal plan. The structural dependency was respected implicitly.
