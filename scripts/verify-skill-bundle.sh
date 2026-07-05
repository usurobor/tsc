#!/usr/bin/env bash
# verify-skill-bundle.sh — vendored CDD skill bundle integrity gate
# (cdd/activation/SKILL.md §16 "Integrity check in CI").
#
# Re-hashes every vendored file under .cdd/skills/{cdd,cds,handoff} and compares
# against the committed manifest .cdd/skills/MANIFEST.sha256, which was generated
# from the cnos source tree at the SHA pinned in .cdd/CDD-VERSION. Any drift
# (manual edit, partial refresh, path collision) fails with a named diff.
set -euo pipefail
cd "$(dirname "$0")/.."

manifest=".cdd/skills/MANIFEST.sha256"
pin="$(head -1 .cdd/CDD-VERSION 2>/dev/null || true)"

# Pin format (cdd/activation/SKILL.md §4): 40-char hex SHA on line 1; optional
# non-empty tag on line 2; no trailing content. Guards the one-line-pin regression.
if ! printf '%s' "$pin" | grep -qE '^[0-9a-f]{40}$'; then
  echo "ERROR: .cdd/CDD-VERSION line 1 is not a 40-char hex SHA: '$pin'" >&2
  exit 1
fi
pin_lines="$(grep -c '' .cdd/CDD-VERSION)"
if [ "$pin_lines" -gt 2 ]; then
  echo "ERROR: .cdd/CDD-VERSION has $pin_lines lines; max 2 (SHA + optional tag)" >&2
  exit 1
fi
pin_tag="$(sed -n '2p' .cdd/CDD-VERSION)"
if [ -n "$pin_tag" ] && [ -z "${pin_tag// /}" ]; then
  echo "ERROR: .cdd/CDD-VERSION line 2 present but blank (tag must be non-empty)" >&2
  exit 1
fi
echo "OK: .cdd/CDD-VERSION pin format valid (${pin:0:12}${pin_tag:+ / $pin_tag})"

if [ ! -f "$manifest" ]; then
  echo "ERROR: $manifest missing — vendored bundle has no integrity manifest." >&2
  exit 1
fi

echo "skill-bundle integrity: pin ${pin:0:12} · $(wc -l < "$manifest") files"

if ( cd .cdd/skills && sha256sum -c --quiet MANIFEST.sha256 ); then
  echo "OK: vendored skill bundle matches manifest"
else
  echo "ERROR: vendored skill bundle diverged from .cdd/skills/MANIFEST.sha256." >&2
  echo "Re-vendor from cnos at the pinned SHA (see .cdd/skills/README.md §Refresh)," >&2
  echo "or investigate the unexpected local edit." >&2
  exit 1
fi
