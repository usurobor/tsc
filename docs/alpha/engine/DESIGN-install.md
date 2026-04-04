# Installable CLI binary

**Issue:** #21
**Mode:** MCA
**Active Skills:** cdd/design, eng/ux-cli, eng/writing
**Engineering Level:** L6

## Problem

The engine builds in CI but cannot be installed without cloning the repo and
building from source (opam + dune + OCaml >= 4.14 + ezcurl + digestif + yojson).
That is a 10+ minute setup for a single binary.

cnos solved this with `install.sh`, but its implementation has three coherence
gaps against its own CLI UX skill. Those gaps are present in all four major
installer scripts surveyed (rustup, deno, homebrew, bun).

## Evidence

| Installer | Atomic install | Integrity check | UX-CLI symbols | NO_COLOR | Actionable errors |
|-----------|---------------|-----------------|----------------|----------|-------------------|
| cnos      | No            | No              | No             | N/A (no color) | Partial |
| rustup    | Yes (mktemp)  | No (in script)  | No             | No (TTY only)  | Yes |
| deno      | No            | No              | No             | N/A (no color) | Weak |
| homebrew  | N/A (git)     | N/A (git)       | No             | No (TTY only)  | Yes |
| bun       | Partial (mv)  | No              | No             | No (TTY only)  | Yes |

None of the surveyed installers follow the cnos UX-CLI skill. None check
`NO_COLOR`. None verify checksums. Rustup is the only one that does atomic
install correctly (download to temp, then move).

## Best-in-class patterns worth adopting

**1. Atomic install (rustup).** Download to `mktemp` temp file, verify, then
`mv` to final path. A failed download never leaves a corrupt binary on PATH.

**2. Actionable error messages (rustup, homebrew).** Every failure states: what
went wrong, why, and what to do. Homebrew includes doc URLs. Rustup explains
workarounds (e.g., noexec `/tmp`).

**3. TLS enforcement (rustup).** `--proto '=https' --tlsv1.2` with cipher suite
selection per TLS backend. Other installers rely on system defaults.

**4. Retry with backoff (rustup, homebrew).** Rustup uses `curl --retry 3 -C -`.
Homebrew wraps git fetch in `retry()` with exponential backoff. Single-attempt
installers (deno, bun, cnos) fail on transient network errors.

**5. Graceful TTY detection (bun).** Initialize color vars to empty, populate
only when TTY detected. Clean, auditable, degrades to plain text in pipes/CI.

**Anti-patterns to avoid:**

- Deno's `*) target="x86_64-unknown-linux-gnu"` silently installs wrong binary
  on unsupported arch instead of failing.
- grep/sed JSON parsing (cnos) — works today, structurally fragile.
- Downloading directly to final path (cnos, deno) — partial download = broken binary.
- Color-only signaling without symbols (violates UX-CLI skill).

## Constraints

- POSIX sh (`#!/bin/sh`) — no bashisms. Must work in dash, ksh, zsh.
- No dependency beyond `curl`, `uname`, `mktemp`, `chmod`, `mv`, `rm`.
  No `jq`, no `unzip`, no `git`.
- Single binary, no archive extraction needed.
- GitHub Releases as distribution channel (same as cnos).
- Binary naming convention: `tsc-{platform}-{arch}` (e.g., `tsc-linux-x64`).

## Challenged Assumption

cnos's install.sh assumed that a minimal `curl | sh` installer doesn't need to
follow the same UX standards as the CLI it installs. This design challenges that:
the installer is the user's first interaction with the tool. It should model the
same UX discipline.

## Impact Graph

| Artifact | Role |
|----------|------|
| `install.sh` (new) | Installer script |
| `.github/workflows/release.yml` (new) | Builds + attaches binaries to GitHub Release on tag |
| `.github/workflows/ci.yml` | Artifact name `tsc-engine-*` → `tsc-*` |
| `engine/ocaml/bin/dune` | `public_name` from `tsc-engine` to `tsc` |
| `engine/ocaml/bin/main.ml` | `--version` flag, usage string |
| `engine/ocaml/dune-project` | `(version ...)` field as single source of truth |
| `Makefile` | `dune exec -- tsc-engine` → `dune exec -- tsc` |
| `docs/beta/guides/OPERATOR-MANUAL.md` | Install section + binary name |
| `README.md` | Quick start one-liner |
| `CHANGELOG.md` | Release entry |

## Proposal

### install.sh

POSIX sh. Structure:

```
1. Header comment (purpose, usage, override vars)
2. UX helpers (symbols, color with TTY + NO_COLOR gating)
3. Prerequisite check (curl)
4. Platform detection (uname -s/-m, case statements, fail on unknown)
5. Fetch latest version (curl GitHub API, grep/sed with explicit failure)
6. Download to temp file (mktemp)
7. Size check (reject < 1MB — catches HTML error pages, truncation)
8. Atomic move to BIN_DIR
9. chmod +x
10. Verify (run --version)
11. Cleanup trap (always remove temp file)
```

UX-CLI compliance:

```sh
info()  { printf '%s\n' "  $1"; }
ok()    { printf '%s\n' "✓ $1"; }
warn()  { printf '%s\n' "⚠ $1"; }
fail()  { printf '%s\n' "✗ $1" >&2; shift; for line in "$@"; do printf '%s\n' "  $line" >&2; done; exit 1; }
```

Example outputs:

```
✓ Detected platform: linux-x64
✓ Latest release: v0.3.0
✓ Downloaded tsc-linux-x64 (4.2 MB)
✓ Installed to /usr/local/bin/tsc

tsc v0.3.0
```

```
✗ Cannot download binary — HTTP request failed

  URL: https://github.com/usurobor/tsc/releases/download/v0.3.0/tsc-linux-x64

  Fix by running:
    1) Check your internet connection
    2) Verify the release exists: https://github.com/usurobor/tsc/releases

  Then rerun:
    curl -fsSL https://raw.githubusercontent.com/usurobor/tsc/main/install.sh | sh
```

NO_COLOR and TTY gating:

```sh
if [ -n "${NO_COLOR:-}" ] || [ ! -t 1 ]; then
  # plain output — symbols only, no ANSI
fi
```

### --version flag

Single source of truth: `(version X.Y.Z)` in `dune-project`. Dune generates
this into the binary at build time via `%%VERSION%%` substitution. No separate
VERSION file needed — dune-project already exists and is the package metadata
root.

### release.yml workflow

Triggers on `v*` tags. Steps:
1. Checkout
2. Setup OCaml 5.2
3. opam install deps
4. dune build
5. Rename binary to `tsc-linux-x64`
6. Create GitHub Release via `softprops/action-gh-release`
7. Attach binary

Start with linux-x64 only (existing ubuntu runner). macOS requires a separate
runner — add when needed.

### Binary rename

`tsc-engine` → `tsc` everywhere. The tool does one thing. If subcommands come
later, `tsc measure` still works. Matches cnos pattern (`cn`, not `cn-agent`).

## Leverage

- Users can install in <10 seconds instead of 10+ minutes
- CI/CD pipelines can `curl | sh` without OCaml toolchain
- Future: add macOS runner for universal install
- Installer UX sets quality bar for the CLI itself

## Negative Leverage

- Release workflow adds a manual step (tag → release) to the publish process
- Platform matrix grows over time (linux-x64, linux-arm64, macos-x64, macos-arm64)
- No checksum verification in V1 (relies on HTTPS transport security, same as
  every surveyed installer)

## Non-goals

- No daemon mode
- No Homebrew/opam/nix packaging
- No Windows
- No auto-update
- No subcommand dispatch
- No checksum/signature verification (V1 — same as rustup/deno/bun/homebrew)
- No cross-compilation (one runner per platform)

## File Changes

| Action | File | Change |
|--------|------|--------|
| Create | `install.sh` | Installer script per proposal above |
| Create | `.github/workflows/release.yml` | Tag-triggered release workflow |
| Edit | `engine/ocaml/bin/dune` | `public_name` → `tsc` |
| Edit | `engine/ocaml/bin/main.ml` | Add `--version` flag, update usage |
| Edit | `engine/ocaml/dune-project` | Add `(version 0.3.0)` |
| Edit | `.github/workflows/ci.yml` | Artifact name `tsc-engine-*` → `tsc-*` |
| Edit | `Makefile` | `tsc-engine` → `tsc` |
| Edit | `docs/beta/guides/OPERATOR-MANUAL.md` | Install section, binary name |
| Edit | `README.md` | Quick start one-liner |
| Edit | `CHANGELOG.md` | 0.3.0 entry |

## Acceptance Criteria

- [ ] AC1: `install.sh` downloads and installs `tsc` binary — `sh install.sh` on a clean linux-x64 machine produces a working `/usr/local/bin/tsc`
- [ ] AC2: Atomic install — interrupted download does not leave corrupt binary (download to temp, mv to final)
- [ ] AC3: Size check — binary < 1MB is rejected with actionable error
- [ ] AC4: All errors use `✗` symbol and include cause + fix + rerun command
- [ ] AC5: Success output uses `✓` symbol
- [ ] AC6: NO_COLOR and non-TTY produce symbol-only output (no ANSI escapes)
- [ ] AC7: Unknown platform/arch fails explicitly (no silent fallback)
- [ ] AC8: `tsc --version` prints version string derived from dune-project
- [ ] AC9: Release workflow triggers on `v*` tag and attaches `tsc-linux-x64` binary to GitHub Release
- [ ] AC10: All references to `tsc-engine` updated to `tsc` (bin/dune, Makefile, CI, operator manual, README)
- [ ] AC11: Operator manual documents both install paths (one-liner + build from source)
- [ ] AC12: Expert can identify install failures in <2s from terminal output
- [ ] AC13: Novice can fix install failures using only terminal output

## Known Debt

- macOS binary requires a macos runner (not in V1)
- No checksum verification (HTTPS-only, same as all surveyed installers)
- No retry logic on download failure (add if users report transient failures)
- Version in dune-project must be bumped manually before tagging
