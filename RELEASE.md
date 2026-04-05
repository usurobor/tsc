# RELEASE.md

## Outcome

Coherence delta: C_Σ A- (`α A-`, `β A-`, `γ B+`) · **Level:** `L6`

The engine is now installable without building from source. Single binary name (`tsc`), single version source (`dune-project`), UX-CLI compliant installer. The gap between "presented as a CLI" and "requires full OCaml toolchain to install" is closed for linux-x64.

## Why it matters

tsc was a CLI that couldn't be installed like one. Users needed to clone the repo, install OCaml, opam, dune, and build from source — a 10+ minute process for a single binary. The installer makes it a 10-second `curl | sh`. This also establishes the UX standard for the installer as a product surface, not a bootstrap hack.

## Added

- **Installer** (`install.sh`): POSIX one-liner install via `curl | sh`. Atomic temp-file download, size validation (rejects < 1 MB), `NO_COLOR`/TTY-aware output, actionable error messages (cause → fix → rerun), explicit platform detection with build-from-source fallback.
- **Release workflow** (`.github/workflows/release.yml`): tag-triggered, builds `tsc-linux-x64` and attaches to GitHub Release.
- **`--version` flag**: `tsc --version` prints version derived from `dune-project` via `dune-build-info`, with git commit hash.

## Changed

- **Binary renamed** from `tsc-engine` to `tsc` across all surfaces (bin/dune, Makefile, CI, workflows, operator manual, README).
- **CI artifact** renamed from `tsc-engine-linux-x86_64` to `tsc-linux-x64`.
- **Operator manual**: new "Install" section with one-liner and build-from-source paths.
- **README**: quick start now points to install one-liner.

## Validation

- `curl -fsSL https://raw.githubusercontent.com/usurobor/tsc/main/install.sh | sh` installs working binary on linux-x64.
- `tsc --version` reports version from dune-project with git hash.
- Interrupted download (Ctrl-C mid-stream) leaves no corrupted binary at install path.
- HTML error page download (wrong URL) rejected by size check with actionable error.

## Known Issues

- macOS binary requires a macOS runner — not in v0.3.0 (linux-x64 only).
- No checksum verification (HTTPS-only, same as all surveyed installers).
- Stale `.opam` file caused first tag attempt to fail — same failure class as 0.1.0 and 0.1.1. Pre-tag opam automation needed.

## Design

- [DESIGN.md](docs/alpha/engine/0.3.0/DESIGN.md): installer survey, UX-CLI compliance, atomic install pattern.
- [POST-RELEASE-ASSESSMENT.md](docs/alpha/engine/0.3.0/POST-RELEASE-ASSESSMENT.md): full cycle assessment.
