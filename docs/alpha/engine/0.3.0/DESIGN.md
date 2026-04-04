# Installable CLI Binary

**Issue:** #21
**Version:** 0.3.0
**Mode:** MCA
**Active Skills:** cdd/design, eng/ux-cli, eng/writing
**Engineering Level:** L6

## Problem

The engine builds in CI, but a user still has to clone the repo and build from
source to install it. That is too much friction for a single binary.

The incoherence is simple:

- the engine is presented as a CLI
- the repo has a release surface
- but installation still assumes build-from-source as the normal path

That keeps the engine more like a developer artifact than a real tool.

## Decision

Ship the engine as an installable binary.

The install path should be:

- one POSIX `install.sh`
- one GitHub Releases workflow
- one binary name: `tsc`
- one version source: `dune-project`

The installer should model the same UX discipline as the CLI it installs.

## Evidence

The current state requires:

- repo clone
- OCaml toolchain
- opam
- dune
- dependency install
- manual build

That is appropriate for development.
It is not the right default for installation.

The surveyed installer scripts are useful as pattern sources, but none of them
should be copied wholesale. The parts worth keeping are:

| Pattern | Source | What it solves |
|---------|--------|----------------|
| Atomic install via temp file + move | rustup | Failed download never corrupts installed binary |
| Actionable error messages | rustup, homebrew | User can fix without reading source |
| TLS enforcement (`--proto '=https' --tlsv1.2`) | rustup | Prevents silent downgrade |
| Retry with backoff | rustup, homebrew | Transient network failure doesn't fail install |
| TTY-aware color with empty-var init | bun | Clean degradation in pipes and CI |
| Explicit failure on unknown platform | (anti-deno) | No silent wrong-binary install |

Anti-patterns observed across all four (rustup, deno, homebrew, bun) and cnos:

- None follow the cnos UX-CLI skill (no symbols, no structured error format)
- None check `NO_COLOR`
- None verify checksums
- cnos and deno download directly to final path (partial download = broken binary)
- Deno silently falls back to linux-x64 on unknown arch

## Constraints

- POSIX `sh` — no bashisms. Must work in dash, ksh, zsh.
- No dependency beyond `curl`, `uname`, `mktemp`, `chmod`, `mv`, `rm`.
- Single binary, no archive extraction needed.
- GitHub Releases as the distribution channel.
- Binary naming: `tsc-{platform}-{arch}` (e.g., `tsc-linux-x64`).

## Challenged Assumption

cnos's install.sh assumed that a minimal `curl | sh` installer doesn't need to
follow the same UX standards as the CLI it installs. This design challenges that:
the installer is the user's first interaction with the tool. It is part of the
product surface, not a disposable bootstrap hack.

## Impact Graph

| Artifact | Change |
|----------|--------|
| `install.sh` (new) | Installer script |
| `.github/workflows/release.yml` (new) | Build + attach binaries on tag push |
| `.github/workflows/ci.yml` | Artifact name `tsc-engine-*` → `tsc-*` |
| `engine/ocaml/bin/dune` | `public_name` from `tsc-engine` to `tsc` |
| `engine/ocaml/bin/main.ml` | `--version` flag, usage string |
| `engine/ocaml/dune-project` | `(version ...)` as single source of truth |
| `Makefile` | `tsc-engine` → `tsc` |
| `docs/beta/guides/OPERATOR-MANUAL.md` | Install section + binary name |
| `README.md` | Quick start one-liner |
| `CHANGELOG.md` | 0.3.0 entry |

## Proposal

### 1. Installer

Create `install.sh` as a POSIX shell installer.

Required behavior:

1. check `curl`
2. detect platform and architecture
3. fetch latest release version
4. download binary to a temp file
5. reject obviously bad downloads (< 1 MB)
6. atomically move to final path
7. `chmod +x`
8. verify with `tsc --version`
9. always clean up temp files

### 2. UX

The installer uses the same interaction discipline as the CLI:

- symbol-based success / warning / failure
- actionable errors (cause → fix → rerun)
- plain output when `NO_COLOR` is set or stdout is not a TTY

Minimum helpers:

```sh
info() { printf '%s\n' "  $1"; }
ok()   { printf '%s\n' "✓ $1"; }
warn() { printf '%s\n' "⚠ $1"; }
fail() { printf '%s\n' "✗ $1" >&2; shift; for line in "$@"; do printf '%s\n' "  $line" >&2; done; exit 1; }
```

Example success:

```
✓ Detected platform: linux-x64
✓ Latest release: v0.3.0
✓ Downloaded tsc-linux-x64 (4.2 MB)
✓ Installed to /usr/local/bin/tsc

tsc v0.3.0
```

Example failure:

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

### 3. Version source

Use `(version ...)` in `engine/ocaml/dune-project` as the single source of
truth. Dune generates this into the binary at build time via `%%VERSION%%`
substitution. The binary exposes it through `tsc --version`.

### 4. Release workflow

Tag-triggered (on `v*`). Steps:

1. Checkout
2. Setup OCaml 5.2
3. opam install deps
4. dune build
5. Rename binary to `tsc-linux-x64`
6. Create GitHub Release via `softprops/action-gh-release`
7. Attach binary

Start with linux-x64 only. macOS requires a separate runner — add when needed.

### 5. Binary naming

Rename from `tsc-engine` to `tsc`. The engine is the tool. The public name
should reflect that. Matches cnos pattern (`cn`, not `cn-agent`).

## Invariants

These must remain true after the change:

1. **Atomic install** — failed downloads never replace a working binary
2. **Version coherence** — tag, binary, docs, and release notes agree
3. **Name coherence** — `tsc` is the public name everywhere
4. **UX coherence** — installer messages follow the same standards as the CLI
5. **Minimal dependency surface** — install path stays small and auditable

## Leverage

- Users can install in <10 seconds instead of 10+ minutes
- CI/CD pipelines can `curl | sh` without OCaml toolchain
- Installer UX sets quality bar for the CLI itself

## Negative Leverage

- Release workflow adds a manual step (tag → release) to the publish process
- Platform matrix grows over time
- No checksum verification in V1

## Non-goals

- No daemon mode
- No Homebrew/opam/nix packaging
- No Windows
- No auto-update
- No subcommand dispatch
- No checksum/signature verification (V1)
- No cross-compilation

## File Changes

| Action | File | Change |
|--------|------|--------|
| Create | `install.sh` | Installer script per proposal |
| Create | `.github/workflows/release.yml` | Tag-triggered release workflow |
| Edit | `engine/ocaml/bin/dune` | `public_name` → `tsc` |
| Edit | `engine/ocaml/bin/main.ml` | `--version` flag, update usage |
| Edit | `engine/ocaml/dune-project` | Add `(version 0.3.0)` |
| Edit | `.github/workflows/ci.yml` | Artifact name `tsc-engine-*` → `tsc-*` |
| Edit | `Makefile` | `tsc-engine` → `tsc` |
| Edit | `docs/beta/guides/OPERATOR-MANUAL.md` | Install section, binary name |
| Edit | `README.md` | Quick start one-liner |
| Edit | `CHANGELOG.md` | 0.3.0 entry |

## Acceptance Criteria

- [ ] AC1: `install.sh` installs a working `tsc` binary on clean linux-x64
- [ ] AC2: Interrupted download never leaves a corrupt final binary
- [ ] AC3: Obviously bad downloads are rejected with actionable error output
- [ ] AC4: Success and failure output use symbols consistently
- [ ] AC5: `NO_COLOR` and non-TTY suppress ANSI color
- [ ] AC6: Unsupported platform/arch fails explicitly
- [ ] AC7: `tsc --version` reports the version from dune-project
- [ ] AC8: Release workflow attaches `tsc-linux-x64` to the GitHub release
- [ ] AC9: All public references to `tsc-engine` are removed
- [ ] AC10: Operator manual documents install and build-from-source paths
- [ ] AC11: README quick start points to the install path
- [ ] AC12: Installer failure output is understandable without opening the source

## Known Debt

- macOS binary requires a macos runner (not in V1)
- No checksum verification (HTTPS-only, same as all surveyed installers)
- No retry logic on download failure (add if users report transient failures)
- Version in dune-project must be bumped manually before tagging
