#!/usr/bin/env bash
# stamp-versions.sh — Rewrite version-stamped files from the VERSION file.
#
# For tsc, the stamped files are:
#   - src/engine/ocaml/dune-project  (opam metadata, not used at build time)
#   - src/engine/ocaml/tsc_engine.opam (generated, but we keep it in sync)
#
# The binary reads version from VERSION via a dune build rule
# (build_version.ml), so no code files need stamping.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -f "$REPO_ROOT/VERSION" ]; then
  echo "ERROR: VERSION file not found"
  exit 1
fi

VERSION=$(cat "$REPO_ROOT/VERSION" | tr -d '\n')

if [ -z "$VERSION" ]; then
  echo "ERROR: VERSION file is empty"
  exit 1
fi

echo "Stamping version $VERSION into manifests..."

# 1. dune-project — top-level (version X.Y.Z)
#    Only match lines starting with '(' (not indented inside (package ...))
DUNE_PROJECT="$REPO_ROOT/src/engine/ocaml/dune-project"
if [ -f "$DUNE_PROJECT" ]; then
  if grep -q '^(version ' "$DUNE_PROJECT"; then
    OLD=$(grep '^(version ' "$DUNE_PROJECT" | head -1 | sed 's/(version \(.*\))/\1/')
    sed -i "s/^(version .*)/(version $VERSION)/" "$DUNE_PROJECT"
  else
    # Insert after (name tsc_engine) line
    sed -i "/^(name tsc_engine)/a\\\\n(version $VERSION)" "$DUNE_PROJECT"
    OLD="(none)"
  fi
  echo "  dune-project: $OLD → $VERSION"
fi

# 2. tsc_engine.opam — version: "X.Y.Z" (may or may not be present)
OPAM="$REPO_ROOT/src/engine/ocaml/tsc_engine.opam"
if [ -f "$OPAM" ]; then
  if grep -q '^version:' "$OPAM"; then
    sed -i "s/^version: .*/version: \"$VERSION\"/" "$OPAM"
    echo "  tsc_engine.opam: stamped version"
  fi
fi

echo ""
echo "Done. Run 'scripts/check-version-consistency.sh' to verify."
