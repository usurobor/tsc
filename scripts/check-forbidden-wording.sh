#!/usr/bin/env bash
# check-forbidden-wording.sh — forward-only CI gate for operational-verdict wording.
#
# Per #54 AC7 (the v0.10.0 canonical-v3.2 cutover cleanup cycle), newly-added
# active content must not introduce these phrases:
#
#   "Operational acceptance"
#   "Operationally accepted"
#   "self-coherence ACCEPT"
#   "release criteria satisfied"
#
# These phrases were retired in the v0.10.0 release wave; CDD review verdicts
# (APPROVED / REQUEST CHANGES) and the per-cycle self-coherence artifact are
# the canonical surfaces. Historical occurrences in frozen / archive paths
# remain valid — this check is FORWARD-ONLY: it only inspects newly-added
# lines in the diff against the base ref, and excludes:
#
#   - docs/{tier}/{bundle}/{X.Y.Z}/   (CDD §5.6 frozen snapshots)
#   - docs/archive/                    (explicit archive surface)
#   - .git/                            (git internals)
#   - _build/                          (dune build output)
#   - src/engine/ocaml/_build/             (in-tree dune build output)
#   - CHANGELOG.md                     (migration narrative may reference retired phrases)
#   - RELEASE.md                       (release narrative may reference retired phrases)
#   - scripts/check-forbidden-wording.sh (this script — names the strings it forbids)
#
# Usage:
#   scripts/check-forbidden-wording.sh                 # base = origin/main
#   scripts/check-forbidden-wording.sh main            # explicit base ref
#   BASE_REF=origin/main scripts/check-forbidden-wording.sh
#
# Exit codes:
#   0 — no newly-added forbidden phrases found in non-excluded paths
#   1 — at least one newly-added forbidden phrase found (script prints file + phrase + line)
#   2 — script invocation error (missing git, unreachable base ref, etc.)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

BASE_REF="${1:-${BASE_REF:-origin/main}}"

if ! command -v git >/dev/null 2>&1; then
  echo "check-forbidden-wording: git not on PATH" >&2
  exit 2
fi

if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  echo "check-forbidden-wording: cannot resolve base ref '$BASE_REF'" >&2
  exit 2
fi

# Forbidden phrases (literal strings; grep -F semantics).
FORBIDDEN=(
  "Operational acceptance"
  "Operationally accepted"
  "self-coherence ACCEPT"
  "release criteria satisfied"
)

# Path-prefix excludes — newly-added lines under these paths do not fail the
# check. Frozen version directories match the X.Y.Z pattern under a bundle
# (e.g. a path segment like `.../0.5.0/`).
is_excluded_path() {
  local path="$1"
  case "$path" in
    docs/archive/*) return 0 ;;
    .git/*)         return 0 ;;
    _build/*)       return 0 ;;
    src/engine/ocaml/_build/*) return 0 ;;
    CHANGELOG.md)   return 0 ;;
    RELEASE.md)     return 0 ;;
    scripts/check-forbidden-wording.sh) return 0 ;;
    # The CI workflow that invokes this check names the phrases it checks
    # for in its job-comment header — that self-reference is documentation,
    # not a new occurrence of the retired wording.
    .github/workflows/ci.yml) return 0 ;;
    .cdd/*)         return 0 ;;
  esac
  # docs/{tier}/{bundle}/{X.Y.Z}/... — three or more X.Y[.Z] numeric segments
  # in the version directory name. Match docs/<a>/<b>/<digits>.<digits>... .
  if [[ "$path" =~ ^docs/[^/]+/[^/]+/[0-9]+\.[0-9]+(\.[0-9]+)?/ ]]; then
    return 0
  fi
  return 1
}

errors=0
errors_file="$(mktemp)"

# `git diff --diff-filter=AM` keeps Added + Modified files. `-U0` strips
# context lines so we only see truly new content. Lines beginning with `+`
# (but not `+++`, the file header) are newly-added.
#
# We process the diff once and dispatch on path; the per-path exclusion runs
# once per hunk rather than once per phrase × per file.
diff_out="$(git diff --diff-filter=AM -U0 "$BASE_REF"...HEAD -- . || true)"

if [ -z "$diff_out" ]; then
  echo "check-forbidden-wording: no changed files vs $BASE_REF; pass"
  exit 0
fi

current_path=""
current_excluded=0
current_lineno=0

while IFS= read -r line; do
  case "$line" in
    "diff --git"*)
      # Reset state at the start of each file's hunk block.
      current_path=""
      current_excluded=0
      current_lineno=0
      ;;
    "+++ "*)
      # Strip "+++ b/" or "+++ /dev/null".
      raw="${line#+++ }"
      if [ "$raw" = "/dev/null" ]; then
        current_path=""
        current_excluded=1
      else
        # Drop leading "b/" if present.
        current_path="${raw#b/}"
        if is_excluded_path "$current_path"; then
          current_excluded=1
        else
          current_excluded=0
        fi
      fi
      ;;
    "@@ "*)
      # Hunk header: "@@ -<a>,<b> +<c>,<d> @@ ..."
      # Parse the new-file start line from "+<c>".
      hunk_new="${line#*+}"
      hunk_new="${hunk_new%% *}"
      hunk_new="${hunk_new%%,*}"
      current_lineno="$hunk_new"
      ;;
    "+"*)
      # Skip the "+++" file-header lines (handled above).
      if [ "${line:0:3}" != "+++" ]; then
        if [ "$current_excluded" -eq 0 ] && [ -n "$current_path" ]; then
          added_text="${line:1}"
          for phrase in "${FORBIDDEN[@]}"; do
            # Literal substring match (no regex semantics).
            if [ "${added_text#*"$phrase"}" != "$added_text" ]; then
              printf 'FORBIDDEN  %s:%d  %s\n' \
                "$current_path" "$current_lineno" "$phrase" >> "$errors_file"
              errors=$((errors + 1))
            fi
          done
        fi
        # Advance new-file line number for every added line.
        current_lineno=$((current_lineno + 1))
      fi
      ;;
    " "*|"-"*)
      # Context or removed line — does not advance new-file line number for
      # a removed line, advances for a context line. With -U0 there are no
      # context lines, only +/-/@@/diff/+++/---, so we leave the lineno alone.
      :
      ;;
  esac
done <<< "$diff_out"

if [ "$errors" -gt 0 ]; then
  echo "check-forbidden-wording: $errors newly-added forbidden phrase(s) found" >&2
  cat "$errors_file" >&2
  rm -f "$errors_file"
  exit 1
fi

rm -f "$errors_file"
echo "check-forbidden-wording: pass (base ref: $BASE_REF)"
exit 0
