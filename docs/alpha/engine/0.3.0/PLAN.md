# Plan: Installable CLI Binary

Implements [DESIGN.md](DESIGN.md). See §Problem there for gap and targets.

**Strategy:** bottom-up. Rename the binary first (everything else depends on
the name), then add --version, then build the release surface (workflow +
installer), then update docs.

---

## Steps

### Step 1: Binary rename (P0)

Rename `tsc-engine` → `tsc` in all build and runtime surfaces.

**AC:** `dune exec -- tsc` works. No remaining references to `tsc-engine` in
build files or workflows.

**Files:**
- `engine/ocaml/bin/dune` — `public_name` → `tsc`
- `engine/ocaml/bin/main.ml` — usage string
- `Makefile` — `dune exec -- tsc-engine` → `dune exec -- tsc`
- `.github/workflows/tsc.yml` — `tsc-engine` → `tsc`

**Depends on:** nothing. **Unblocks:** Steps 2–6.

### Step 2: --version flag (P0)

Add `(version ...)` to dune-project. Handle `--version` in main.ml.

**AC:** `tsc --version` prints `tsc 0.3.0`. Version derived from dune-project
at build time.

**Files:**
- `engine/ocaml/dune-project` — add `(version 0.3.0)`
- `engine/ocaml/bin/main.ml` — check for `--version` before `Arg.parse`

**Depends on:** Step 1 (binary named `tsc`).

### Step 3: Release workflow (P0)

Create tag-triggered workflow that builds and publishes binary.

**AC:** Pushing a `v*` tag builds the binary and creates a GitHub Release with
`tsc-linux-x64` attached.

**Files:**
- `.github/workflows/release.yml` (new)

**Depends on:** Step 1 (binary name). **Unblocks:** Step 4.

### Step 4: Installer (P0)

Create `install.sh` per DESIGN.md proposal.

**AC:** `curl -fsSL .../install.sh | sh` downloads latest release, installs to
`/usr/local/bin/tsc`, runs `tsc --version`. UX-CLI compliant output. Atomic
install via temp file.

**Files:**
- `install.sh` (new)

**Depends on:** Step 2 (--version), Step 3 (release exists to download from).

### Step 5: Update CI artifact name (P1)

Rename CI artifact from `tsc-engine-linux-x86_64` to `tsc-linux-x64`.

**AC:** CI artifact name matches release binary naming convention.

**Files:**
- `.github/workflows/ci.yml`

**Depends on:** Step 1.

### Step 6: Update docs (P1)

Update operator manual, README, changelog.

**AC:** Operator manual documents install path. README quick start mentions
one-liner. Changelog has 0.3.0 entry. Citation bumped to v0.3.0.

**Files:**
- `docs/beta/guides/OPERATOR-MANUAL.md`
- `README.md`
- `CHANGELOG.md`

**Depends on:** Steps 1–4 (need final binary name and install command).

---

## Test strategy

- `dune build` must succeed after Step 1
- `dune exec -- tsc --version` must print version after Step 2
- `shellcheck install.sh` must pass (POSIX compliance)
- Manual: push a tag to verify release workflow (deferred to first release)

## Non-goals

- Running install.sh end-to-end in CI (requires a published release)
- macOS binary
- Automated version bumping
