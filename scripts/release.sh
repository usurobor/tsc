#!/usr/bin/env bash
# release.sh — Single-command release pipeline for tsc/coh.
#
# Usage: scripts/release.sh <version> [summary]
# Example: scripts/release.sh 0.5.0 "feat: multi-target measurement"
#
# Steps:
#   1. Preflight (clean tree, on main, synced with origin)
#   2. Bump VERSION
#   3. Stamp manifests
#   4. Check consistency
#   5. Commit + push
#   6. Tag (v-prefixed) + push tag
#
# Release workflow triggers on the tag push.

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <version> [summary]"
  echo "Example: $0 0.5.0 'feat: multi-target measurement'"
  exit 1
fi

VERSION="$1"
shift
SUMMARY="${*:-}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# --- Preflight ---

if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: working tree not clean. Commit or stash first."
  exit 1
fi

BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "main" ]; then
  echo "ERROR: must be on main (currently on $BRANCH)."
  exit 1
fi

git fetch origin main --quiet
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)
if [ "$LOCAL" != "$REMOTE" ]; then
  echo "ERROR: local main ($LOCAL) differs from origin/main ($REMOTE)."
  echo "Pull or push first."
  exit 1
fi

TAG="v$VERSION"
if git tag -l "$TAG" | grep -q "$TAG"; then
  echo "ERROR: tag $TAG already exists."
  exit 1
fi

COMMIT_MSG="release: $TAG"
if [ -n "$SUMMARY" ]; then
  COMMIT_MSG="release: $TAG — $SUMMARY"
fi

echo "=== Release $TAG ==="
echo ""

# --- CHANGELOG ledger gate ---

echo "Checking CHANGELOG Release Coherence Ledger for version $VERSION..."
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

if ! grep -q "^| $VERSION |" "$CHANGELOG"; then
  echo ""
  echo "ERROR: CHANGELOG.md missing Release Coherence Ledger row for version $VERSION"
  echo ""
  echo "Required row format in the Release Coherence Ledger table:"
  echo "| $VERSION | [C_Σ] | [α] | [β] | [γ] | [Level] | [Note] |"
  echo ""
  echo "Edit CHANGELOG.md and add the required row to the Release Coherence Ledger table,"
  echo "then re-run this release script."
  exit 1
fi
echo "✓ CHANGELOG ledger row found for version $VERSION"
echo ""

# --- Bump + stamp + check ---

echo "$VERSION" > VERSION
echo "✓ VERSION → $VERSION"

bash scripts/stamp-versions.sh
echo ""
bash scripts/check-version-consistency.sh
echo ""

# --- Stage and confirm ---

git add -A
echo "--- Staged changes ---"
git diff --cached --stat
echo ""

read -r -p "Commit, tag $TAG, and push? [y/N] " confirm
if [ "$confirm" != "y" ]; then
  echo "Aborted. Changes staged but not committed."
  exit 1
fi

# --- Commit + tag + push ---

git commit -m "$COMMIT_MSG"
git tag "$TAG"
git push origin main
git push origin "$TAG"

echo ""
echo "✓ Released $TAG. Workflow will build and publish."
