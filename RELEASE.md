# RELEASE.md

## Outcome

Coherence delta: C_Σ A (`α A`, `β A`, `γ A-`) · **Level:** `L5`

Binary renamed from `tsc` to `coh`. Name collision with TypeScript compiler eliminated. All surfaces agree on the new name.

## Why it matters

`tsc` is the TypeScript compiler. Any machine with Node.js installed has `tsc` on `$PATH`. Installing our binary as `tsc` silently shadows it — or gets shadowed by it. This is a name-coherence bug: the binary name collides with one of the most widely installed CLI tools in the ecosystem. `coh` (coherence) is short, unique, and descriptive.

## Changed

- **Binary renamed** `tsc` → `coh` across all surfaces: `bin/dune`, `main.ml`, `dune-project`, Makefile, CI workflows, release workflow, `install.sh`, operator manual, README, QUICKSTART.
- **Version bumped** to 0.3.1 in `dune-project`.

## Added

- **QUICKSTART.md**: real newcomer flow — install, configure, measure, read output. Replaces stub.
- **README quick start**: expanded to show full 3-step flow (install → configure → measure).

## Validation

- Release workflow produces `coh-linux-x64` binary (not `tsc-linux-x64`).
- `install.sh` installs as `coh`, runs `coh --version` to verify.
- No file in the repo references the old binary name `tsc` in an executable context.

## Known Issues

- macOS binary not yet published (linux-x64 only).
- Old v0.3.0 release still has `tsc-linux-x64` — users on that version need to upgrade.
