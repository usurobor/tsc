# Self-Coherence — 0.3.0

**Issue:** #21
**Mode:** MCA
**Active Skills:** cdd/design, eng/ux-cli, eng/writing

## AC Evidence

| AC | Status | Evidence |
|----|--------|----------|
| AC1 | Ready | `install.sh` exists, downloads from GitHub Releases, installs to `$BIN_DIR` |
| AC2 | Met | Downloads to `mktemp` temp file, `mv` to final path. Trap cleans up on failure. |
| AC3 | Met | Size check rejects < 1 MB with actionable error |
| AC4 | Met | All errors use `✗` with cause → fix → rerun structure |
| AC5 | Met | All success output uses `✓` |
| AC6 | Met | `NO_COLOR` env var and non-TTY suppress ANSI escapes |
| AC7 | Met | Unknown OS/arch hits explicit `fail()` with supported list |
| AC8 | Met | `tsc --version` prints `tsc 0.3.0 (abc1234)` — version from dune-project via dune-build-info, commit from git via build rule |
| AC9 | Met | `grep -r tsc-engine` in build/workflow files returns zero hits |
| AC10 | Met | Operator manual has "Install" section with one-liner + from-source |
| AC11 | Met | README quick start has `curl \| sh` one-liner |
| AC12 | Met | Every `fail()` call includes symbol + cause + fix instructions |

AC1 is "ready" not "met" because it requires a published GitHub Release to
test end-to-end. The script is complete and correct; verification requires
tagging v0.3.0 and running the release workflow.

## Triadic Assessment

### α — pattern coherence

The binary has one name (`tsc`), one version source (`dune-project`, injected
via `dune-build-info`, commit hash via dune build rule), and one install path. The installer follows UX-CLI
skill patterns: symbols, actionable errors, NO_COLOR. No decorative color.
No silent fallbacks. Platform detection matches exactly what the release
workflow publishes (linux-x64 only in v0.3.0).

The install.sh structure matches the design proposal exactly:
prerequisites → detect → fetch → download → verify → move → confirm.

**Score:** 0.85

### β — relational coherence

All surfaces agree on the binary name:
- `bin/dune` → `(public_name tsc)`
- `Makefile` → `dune exec -- tsc`
- CI workflows → `tsc` / `tsc-linux-x64`
- Operator manual → `tsc --target ...`
- README → `curl | sh` installs `tsc`
- Changelog → documents the rename

The install.sh uses the same release artifact naming as `release.yml`
(`tsc-{platform}-{arch}`). The `--version` output matches the design's
version field.

**Score:** 0.85

### γ — process coherence

Full CDD cycle: design doc → plan → implementation → self-coherence.
Version directory (`0.3.0/`) contains DESIGN, PLAN, SELF-COHERENCE.
Engine bundle README updated with version history entry.

The release workflow enables a repeatable tag → build → publish → install path.
Version bump is manual (known debt).

**Score:** 0.80

### C_Σ

`(0.85 · 0.85 · 0.80)^(1/3) = 0.83` — grade B+

## Known Debt

- macOS binary requires a macos runner
- No checksum verification in installer
- No retry on download failure
- AC1 not fully verified until first release is published
- `install.sh` uses `grep | sed` for JSON parsing (same fragility as cnos; acceptable for a minimal installer with no jq dependency)

## Friction Log

- `%%VERSION%%` substitution in dune requires `dune subst` which only runs
  during `dune-release`. Used `dune-build-info` library instead — reads version
  from `dune-project` at build time. One dependency, but single source of truth.
- Initial implementation detected macOS and ARM platforms but the release
  workflow only publishes linux-x64. Fixed by restricting detection to match
  what is actually published. Explicit build-from-source fallback for other
  platforms.
