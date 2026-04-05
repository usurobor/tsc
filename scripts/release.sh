#!/usr/bin/env bash
# release.sh — Automate the tsc/coh release pipeline.
#
# Usage: scripts/release.sh <version> <summary>
# Example: scripts/release.sh 0.4.0 "feat: dotenv credential loading"
#
# Steps:
#   1. Preflight (clean tree, on main)
#   2. Bump VERSION
#   3. Stamp manifests
#   4. Check consistency
#   5. Commit
#   6. Tag (v-prefixed)
#   7. Push main + tag
#
# Release workflow (release.yml) triggers on the tag push and builds
# the binary + GitHub release automatically.

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <version> <summary>"
  echo "Example: $0 0.4.0 'feat: dotenv credential loading'"
  exit 1
fi

VERSION="$1"
shift
SUMMARY="$*"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Preflight
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: working tree not clean. Commit or stash first."
  exit 1
fi

BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "main" ]; then
  echo "ERROR: must be on main (currently on $BRANCH)."
  exit 1
fi

if ! git diff --quiet origin/main..HEAD 2>/dev/null; then
  echo "WARNING: local main is ahead of origin."
  read -r -p "Continue? [y/N] " confirm
  [ "$confirm" = "y" ] || exit 1
fi

echo "=== Release v$VERSION — $SUMMARY ==="
echo

# 1. Bump VERSION
echo "$VERSION" > VERSION
echo "✓ VERSION → $VERSION"

# 2. Stamp manifests
bash scripts/stamp-versions.sh
echo

# 3. Check consistency
bash scripts/check-version-consistency.sh
echo

# 4. Stage and show
git add -A
echo "--- Staged changes ---"
git diff --cached --stat
echo

# 5. Confirm
read -r -p "Commit, tag v$VERSION, and push? [y/N] " confirm
if [ "$confirm" != "y" ]; then
  echo "Aborted. Changes staged but not committed."
  exit 1
fi

# 6. Commit + tag
git commit -m "release: v$VERSION — $SUMMARY"
git tag "v$VERSION"

# 7. Push
git push origin main
git push origin "v$VERSION"

echo
echo "✓ Tagged v$VERSION and pushed."
echo "  Release workflow will build and publish automatically."
