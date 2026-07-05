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
