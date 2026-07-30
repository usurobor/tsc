#!/usr/bin/env bash
# scripts/ci/validate-v4-conformance.sh — validate the TSC v4 conformance
# fixture suite against its schema and its closure obligations.
#
# Same surface split as scripts/ci/validate-skill-frontmatter.sh: the CUE
# schema (schemas/conformance-fixture.cue) owns shape / type / enum / the
# status-conditional field constraints; this script owns discovery and the
# cross-file closure checks that keep the conformance suite honest against
# its registry and the normative conformance authority
# (spec/tsc-conformance.md):
#
#   (a) cue vet — every conformance/**/fixture.toml against the fixture
#       schema, run only when `cue` is installed (skipped with a clear
#       message otherwise; the checks below still run);
#   (b) registry <-> manifest closure — every registry.toml reference
#       resolves to a manifest on disk (and its id matches), and every
#       manifest on disk is referenced by the registry;
#   (c) requirement grounding — every requirement ID referenced by a
#       fixture is defined in spec/tsc-conformance.md;
#   (d) polarity coverage — every requirement covered by a case has BOTH
#       a positive and a negative case (aggregated across the suite);
#   (e) evidence rules — a `specified` fixture carries no execution
#       evidence; an `implemented` fixture carries evidence but no review;
#       a `verified` fixture carries replayable PASS evidence AND an
#       independent PASS review.
#
# Exit codes:
#   0  every fixture and closure check passed
#   1  one or more validation failures
#   2  prerequisite missing (python3 / tomllib, or a required input path)
#
# Usage: ./scripts/ci/validate-v4-conformance.sh
#
# Honors NO_COLOR.

set -euo pipefail

# --- color / symbols ----------------------------------------------------
if [[ -n "${NO_COLOR:-}" || ! -t 1 ]]; then
  RED="" GREEN="" YELLOW="" RESET=""
else
  RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[0;33m' RESET=$'\033[0m'
fi
SYM_OK="ok" SYM_FAIL="FAIL" SYM_SKIP="skip"

# --- prereqs ------------------------------------------------------------
command -v python3 >/dev/null 2>&1 || {
  echo "${RED}${SYM_FAIL}${RESET} prerequisite missing: python3" >&2
  exit 2
}
python3 -c 'import tomllib' 2>/dev/null || {
  echo "${RED}${SYM_FAIL}${RESET} prerequisite missing: python3 tomllib (needs Python 3.11+)" >&2
  exit 2
}

# --- paths --------------------------------------------------------------
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCHEMA="${REPO_ROOT}/schemas/conformance-fixture.cue"
CONF_DIR="${REPO_ROOT}/conformance"
REGISTRY="${CONF_DIR}/registry.toml"
SPEC="${REPO_ROOT}/spec/tsc-conformance.md"

for p in "$SCHEMA" "$CONF_DIR" "$REGISTRY" "$SPEC"; do
  [[ -e "$p" ]] || {
    echo "${RED}${SYM_FAIL}${RESET} required input path not found: ${p#"$REPO_ROOT"/}" >&2
    exit 2
  }
done

rc=0

# --- (a) CUE schema vet (optional) --------------------------------------
if command -v cue >/dev/null 2>&1; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  while IFS= read -r fx; do
    rel="${fx#"$REPO_ROOT"/}"
    json="${TMP}/$(printf '%s' "$rel" | tr '/' '_').json"
    if ! python3 -c 'import tomllib, json, sys
with open(sys.argv[1], "rb") as f: data = tomllib.load(f)
with open(sys.argv[2], "w") as f: json.dump(data, f)' "$fx" "$json"; then
      printf "%s%s%s %s :: cue :: toml-parse :: cannot parse TOML\n" \
        "$RED" "$SYM_FAIL" "$RESET" "$rel"
      rc=1
      continue
    fi
    if err=$(cd "$REPO_ROOT" && cue vet -d '#Fixture' "$SCHEMA" "$json" 2>&1); then
      printf "%s%s%s cue %s\n" "$GREEN" "$SYM_OK" "$RESET" "$rel"
    else
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" == *"$json"* ]] && continue
        printf "%s%s%s %s :: cue :: schema :: %s\n" "$RED" "$SYM_FAIL" "$RESET" "$rel" "$line"
      done <<<"$err"
      rc=1
    fi
  done < <(find "$CONF_DIR" -name 'fixture.toml' -type f | sort)
else
  printf "%s%s%s cue not installed — skipping CUE schema vet; closure checks still run\n" \
    "$YELLOW" "$SYM_SKIP" "$RESET"
fi

# --- (b)-(e) closure / grounding / coverage / evidence checks -----------
if ! python3 - "$REPO_ROOT" <<'PYEOF'
import sys, os, re, glob, tomllib

repo = sys.argv[1]
conf_dir = os.path.join(repo, "conformance")
registry_path = os.path.join(conf_dir, "registry.toml")
spec_path = os.path.join(repo, "spec", "tsc-conformance.md")

findings = []
def fail(where, rule, msg):
    findings.append(f"{where} :: {rule} :: {msg}")

ID_RE = re.compile(r"^(FND|CORE|BETA|OPER|OBS|CONF)-[A-Z]+-[0-9]{3}$")
ANY_ID_RE = re.compile(r"(FND|CORE|BETA|OPER|OBS|CONF)-[A-Z]+-[0-9]{3}")

def load_toml(path):
    with open(path, "rb") as f:
        return tomllib.load(f)

registry = load_toml(registry_path)
reg_fixtures = registry.get("fixture", [])

disk_manifests = {
    os.path.relpath(p, conf_dir)
    for p in glob.glob(os.path.join(conf_dir, "**", "fixture.toml"), recursive=True)
}

# (b) registry <-> manifest closure
declared_manifests = set()
for entry in reg_fixtures:
    mid = entry.get("id", "")
    man = entry.get("manifest", "")
    if not man:
        fail("registry.toml", "closure", f"fixture entry id='{mid}' has no manifest")
        continue
    declared_manifests.add(man)
    abs_man = os.path.join(conf_dir, man)
    if not os.path.isfile(abs_man):
        fail("registry.toml", "closure", f"manifest referenced but not on disk: {man}")
        continue
    fx = load_toml(abs_man)
    if fx.get("id", "") != mid:
        fail(man, "closure", f"manifest id='{fx.get('id','')}' != registry id='{mid}'")

for man in sorted(disk_manifests):
    if man not in declared_manifests:
        fail(man, "closure", "manifest on disk not referenced by registry.toml")

# spec-defined requirement IDs
spec_text = open(spec_path, encoding="utf-8").read()
spec_ids = {m.group(0) for m in ANY_ID_RE.finditer(spec_text)}

referenced_ids = set()
pos_covered = set()
neg_covered = set()

for man in sorted(declared_manifests):
    abs_man = os.path.join(conf_dir, man)
    if not os.path.isfile(abs_man):
        continue
    fx = load_toml(abs_man)
    status = fx.get("status", "")

    for rid in fx.get("requirements", []):
        referenced_ids.add(rid)
    for c in fx.get("cases", []):
        rid = c.get("requirement", "")
        pol = c.get("polarity", "")
        if rid:
            referenced_ids.add(rid)
            if pol == "positive":
                pos_covered.add(rid)
            elif pol == "negative":
                neg_covered.add(rid)

    # (e) evidence rules
    has_evidence = "evidence" in fx
    has_verification = "verification" in fx
    if status == "specified":
        if has_evidence:
            fail(man, "evidence", "specified fixture must carry no execution evidence")
        if has_verification:
            fail(man, "evidence", "specified fixture must carry no verification")
    elif status == "implemented":
        if not has_evidence:
            fail(man, "evidence", "implemented fixture requires an evidence block")
        if has_verification:
            fail(man, "evidence", "implemented fixture must not carry a verification block")
    elif status == "verified":
        ev = fx.get("evidence", {}) or {}
        ver = fx.get("verification", {}) or {}
        repro = fx.get("reproducibility", {}) or {}
        if ev.get("result", "") != "PASS":
            fail(man, "evidence", "verified fixture requires evidence.result = PASS")
        if not ev.get("root") or not ev.get("digest"):
            fail(man, "evidence", "verified fixture requires replayable PASS evidence (root + digest)")
        if not repro.get("command"):
            fail(man, "evidence", "verified fixture requires a replay command")
        if ver.get("result", "") != "PASS":
            fail(man, "evidence", "verified fixture requires an independent PASS review")
        if not ver.get("reviewer") or not ver.get("review_ref"):
            fail(man, "evidence", "verified fixture review requires reviewer + review_ref")
    else:
        fail(man, "status", f"unknown status '{status}'")

# (c) referenced IDs must exist in the conformance spec
for rid in sorted(referenced_ids):
    if not ID_RE.match(rid):
        fail("conformance", "id-format", f"malformed requirement id: {rid}")
    elif rid not in spec_ids:
        fail("conformance", "id-in-spec", f"requirement '{rid}' not defined in spec/tsc-conformance.md")

# (d) every covered requirement needs both polarities
covered = pos_covered | neg_covered
for rid in sorted(covered):
    if rid not in pos_covered:
        fail("conformance", "polarity", f"requirement '{rid}' has no positive case")
    if rid not in neg_covered:
        fail("conformance", "polarity", f"requirement '{rid}' has no negative case")

if findings:
    for line in findings:
        print(f"FAIL {line}")
    print(f"{len(findings)} finding(s)")
    sys.exit(1)

print(f"ok closure: {len(declared_manifests)} fixture(s), "
      f"{len(covered)} requirement(s) covered with pos+neg, "
      f"all referenced IDs grounded in spec/tsc-conformance.md")
sys.exit(0)
PYEOF
then
  rc=1
fi

if [[ $rc -ne 0 ]]; then
  printf "%s%s%s validate-v4-conformance: findings above\n" "$RED" "$SYM_FAIL" "$RESET" >&2
  exit 1
fi
printf "%s%s%s validate-v4-conformance: all checks passed\n" "$GREEN" "$SYM_OK" "$RESET"
exit 0
