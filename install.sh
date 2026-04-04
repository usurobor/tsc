#!/bin/sh
# tsc installer — downloads pre-built tsc binary from GitHub Releases
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/usurobor/tsc/main/install.sh | sh
#
# Override install directory:
#   BIN_DIR=/usr/bin sh install.sh
#
# If /usr/local/bin requires root:
#   curl -fsSL https://raw.githubusercontent.com/usurobor/tsc/main/install.sh | sudo sh

set -e

REPO="usurobor/tsc"
BIN_DIR="${BIN_DIR:-/usr/local/bin}"
BINARY_NAME="tsc"
MIN_SIZE=1000000  # 1 MB — reject obviously bad downloads

# --- UX helpers ---

# Respect NO_COLOR (https://no-color.org/) and non-TTY
if [ -n "${NO_COLOR:-}" ] || [ ! -t 1 ]; then
  RED="" GREEN="" YELLOW="" RESET=""
else
  RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[0;33m' RESET='\033[0m'
fi

info() { printf '%s\n' "  $1"; }
ok()   { printf "${GREEN}%s${RESET}\n" "✓ $1"; }
warn() { printf "${YELLOW}%s${RESET}\n" "⚠ $1"; }
fail() {
  printf "${RED}%s${RESET}\n" "✗ $1" >&2
  shift
  for line in "$@"; do
    printf '%s\n' "  $line" >&2
  done
  exit 1
}

# --- Cleanup trap ---
TMPFILE=""
cleanup() { [ -n "$TMPFILE" ] && rm -f "$TMPFILE"; }
trap cleanup EXIT INT TERM

# --- Prerequisites ---
if ! command -v curl >/dev/null 2>&1; then
  fail "Cannot continue — curl is required but not found" \
    "" \
    "Fix by running:" \
    "  apt install curl    (Debian/Ubuntu)" \
    "  brew install curl   (macOS)" \
    "" \
    "Then rerun:" \
    "  curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | sh"
fi

# --- Detect platform ---
OS="$(uname -s)"
ARCH="$(uname -m)"

# v0.3.0: only linux-x64 binaries are published.
# When more targets are added to release.yml, expand this detection.
case "${OS}-${ARCH}" in
  Linux-x86_64) PLATFORM="linux"; ARCH="x64" ;;
  *)
    fail "Cannot continue — no pre-built binary for ${OS} ${ARCH}" \
      "" \
      "Currently supported: Linux x86_64" \
      "macOS and ARM support is planned — file or upvote an issue:" \
      "  https://github.com/${REPO}/issues" \
      "" \
      "You can build from source instead:" \
      "  git clone https://github.com/${REPO}.git && cd tsc" \
      "  make setup && make build"
    ;;
esac

TARGET="${PLATFORM}-${ARCH}"
ok "Detected platform: ${TARGET}"

# --- Fetch latest release ---
LATEST=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
  | grep '"tag_name"' \
  | sed -E 's/.*"([^"]+)".*/\1/') || true

if [ -z "$LATEST" ]; then
  fail "Cannot continue — could not determine latest release" \
    "" \
    "Fix by checking:" \
    "  1) Your internet connection" \
    "  2) https://github.com/${REPO}/releases has at least one release" \
    "" \
    "Then rerun:" \
    "  curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | sh"
fi

ok "Latest release: ${LATEST}"

# --- Download to temp file ---
ARTIFACT="${BINARY_NAME}-${TARGET}"
URL="https://github.com/${REPO}/releases/download/${LATEST}/${ARTIFACT}"

TMPFILE="$(mktemp)" || fail "Cannot continue — mktemp failed"

if ! curl -fsSL -o "$TMPFILE" "$URL"; then
  fail "Cannot download binary — HTTP request failed" \
    "" \
    "URL: $URL" \
    "" \
    "Fix by running:" \
    "  1) Check your internet connection" \
    "  2) Verify the release exists: https://github.com/${REPO}/releases" \
    "" \
    "Then rerun:" \
    "  curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | sh"
fi

# --- Size check ---
FILE_SIZE=$(wc -c < "$TMPFILE" | tr -d ' ')
if [ "$FILE_SIZE" -lt "$MIN_SIZE" ]; then
  fail "Cannot continue — downloaded file is too small (${FILE_SIZE} bytes)" \
    "" \
    "This usually means the release asset was not found (HTML error page)" \
    "or the download was truncated." \
    "" \
    "Expected: > 1 MB for a compiled binary" \
    "URL: $URL" \
    "" \
    "Fix by verifying the release asset exists:" \
    "  https://github.com/${REPO}/releases/tag/${LATEST}" \
    "" \
    "Then rerun:" \
    "  curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | sh"
fi

SIZE_MB=$(echo "scale=1; $FILE_SIZE / 1048576" | bc 2>/dev/null || echo "?")
ok "Downloaded ${ARTIFACT} (${SIZE_MB} MB)"

# --- Atomic install ---
chmod +x "$TMPFILE"

if ! mv "$TMPFILE" "${BIN_DIR}/${BINARY_NAME}" 2>/dev/null; then
  fail "Cannot install — failed to write to ${BIN_DIR}" \
    "" \
    "Fix by running with elevated permissions:" \
    "  curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | sudo sh" \
    "" \
    "Or override the install directory:" \
    "  BIN_DIR=\$HOME/.local/bin curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | sh"
fi
TMPFILE=""  # prevent cleanup from removing installed binary

ok "Installed to ${BIN_DIR}/${BINARY_NAME}"

# --- Verify ---
echo ""
"${BIN_DIR}/${BINARY_NAME}" --version
