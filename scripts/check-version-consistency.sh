#!/usr/bin/env bash
# check-version-consistency.sh — CI gate for version coherence.
#
# Verifies that all version-stamped files agree with the VERSION file.
# Exit 0 if consistent, exit 1 on any mismatch.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION=$(cat "$REPO_ROOT/VERSION" | tr -d '\n')
ERRORS=0

check() {
  local file="$1" actual="$2" label="$3"
  if [ "$actual" != "$VERSION" ]; then
    echo "FAIL: $label — got '$actual', expected '$VERSION' (in $file)"
    ERRORS=$((ERRORS + 1))
  else
    echo "  ok: $label = $VERSION"
  fi
}

echo "Checking version consistency against VERSION=$VERSION"
echo ""

# 1. dune-project (version X.Y.Z)
DUNE_PROJECT="$REPO_ROOT/src/engine/ocaml/dune-project"
if [ -f "$DUNE_PROJECT" ] && grep -q '(version ' "$DUNE_PROJECT"; then
  DUNE_VER=$(grep '(version ' "$DUNE_PROJECT" | head -1 | sed 's/.*(version \(.*\))/\1/')
  check "$DUNE_PROJECT" "$DUNE_VER" "dune-project version"
else
  echo "  ok: dune-project has no (version ...) — VERSION file is sole source"
fi

# 2. No hardcoded version in main.ml
MAIN_ML="$REPO_ROOT/src/engine/ocaml/bin/main.ml"
if grep -q 'let version = "' "$MAIN_ML" 2>/dev/null; then
  HARDCODED=$(grep 'let version = "' "$MAIN_ML" | head -1 | sed 's/.*"\(.*\)"/\1/')
  echo "FAIL: main.ml has hardcoded version '$HARDCODED' — should use Build_version.version"
  ERRORS=$((ERRORS + 1))
else
  echo "  ok: main.ml reads version from generated module"
fi

# 3. build_version rule reads VERSION (structural check)
DUNE_BIN="$REPO_ROOT/src/engine/ocaml/bin/dune"
if grep -q 'build_version' "$DUNE_BIN" && grep -q 'VERSION' "$DUNE_BIN"; then
  echo "  ok: dune build rule reads VERSION file"
else
  echo "FAIL: dune build rule does not reference VERSION — binary won't get correct version"
  ERRORS=$((ERRORS + 1))
fi

echo ""
if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED: $ERRORS version inconsistencies found"
  echo "Fix: run 'scripts/stamp-versions.sh' then commit."
  exit 1
else
  echo "PASSED: all version sources agree with VERSION=$VERSION"
  exit 0
fi
