#!/usr/bin/env bash
# scripts/coherence-ledger.sh — maintain .tsc/COHERENCE.md, the per-release
# coherence ledger (skills/self-measure/SKILL.md §6, ledger contract).
#
# One row per version tag, measured MECHANICALLY (deterministic,
# credential-free) so every row is reproducible and comparable. The
# instrument column records which engine binary measured the row: for the
# release itself that is the release's own engine; for backfilled history
# it is the backfilling engine — a constant meter across old trees, which
# is what makes the curve comparable.
#
# Usage:
#   scripts/coherence-ledger.sh append <version>
#       Measure the CURRENT tree and append a row for <version>.
#       Idempotent: if a row for <version> exists, exits 0 unchanged.
#       Used by the tsc-coherence-ledger workflow on tag push.
#   scripts/coherence-ledger.sh backfill
#       Regenerate the ledger from every version tag, oldest to newest,
#       measuring each tag's tree (its own targets/registry.tsc) with the
#       CURRENT engine binary. Rewrites the file.
#
# Engine binary: $COH_BIN, else coh on PATH, else the in-repo dune build.
#
# Exit codes: 0 ok; 1 measurement failure; 2 precondition failure.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
LEDGER=".tsc/COHERENCE.md"

resolve_coh() {
  if [ -n "${COH_BIN:-}" ]; then echo "$COH_BIN"; return; fi
  if command -v coh >/dev/null 2>&1; then echo "coh"; return; fi
  local build="engine/ocaml/_build/default/bin/main.exe"
  [ -x "$build" ] && { echo "$REPO_ROOT/$build"; return; }
  echo "coherence-ledger: no coh binary (set COH_BIN or dune build)" >&2
  exit 2
}
COH="$(resolve_coh)"

# Measure a tree (cwd) mechanically: prints "spec engine repo cross"
# ("-" for a target that fails to measure). Uses the tree's own registry.
measure_tree() {
  local root="$1" out
  out="$(mktemp -d)"
  local spec="-" engine="-" repo="-" cross="-"
  for t in spec engine repo; do
    if "$COH" --mode mechanical --target "$t" \
         --registry "targets/registry.tsc" --root "$root" \
         --output "$out" >/dev/null 2>&1; then :; fi
  done
  "$COH" --mode mechanical --target spec --target engine --target repo \
    --registry "targets/registry.tsc" --root "$root" \
    --output "$out" >/dev/null 2>&1 || true
  read -r spec engine repo cross < <(python3 - "$out" <<'PYEOF'
import json, glob, sys
vals = {"spec": "-", "engine": "-", "repo": "-", "cross": "-"}
for f in glob.glob(sys.argv[1] + "/tsc-*.json"):
    try:
        d = json.load(open(f))
    except Exception:
        continue
    if d.get("kind") == "cross_target_report":
        vals["cross"] = "%.4f" % d["provenance"]["cross_target_aggregate"]["C_sigma_cross_num"]
    elif d.get("mode") == "mechanical" and d.get("target") in vals:
        vals[d["target"]] = "%.4f" % d["provenance"]["aggregate_numeric"]["C_sigma_num"]
print(vals["spec"], vals["engine"], vals["repo"], vals["cross"])
PYEOF
  )
  rm -rf "$out"
  echo "$spec $engine $repo $cross"
}

ledger_header() {
  cat <<'EOF'
# Coherence ledger

One row per release: `coh self` in mechanical mode (deterministic,
credential-free — every row reproducible). Maintained by the
tsc-coherence-ledger workflow on version-tag push; historical rows were
backfilled by measuring each tag's tree (its own `targets/registry.tsc`)
with a single fixed engine, so the curve is comparable across releases.
The instrument column names the engine that measured the row.
Contract: skills/self-measure/SKILL.md §6.

| Release | Date | spec C | engine C | repo C | cross C_Σ | Instrument |
|---------|------|----------|----------|--------|-----------|------------|
EOF
}

instrument_version() {
  "$COH" --version 2>/dev/null | awk '{print $2}' || echo "unknown"
}

append_row() {
  local version="$1"
  mkdir -p .tsc
  [ -f "$LEDGER" ] || ledger_header > "$LEDGER"
  if grep -q "^| $version " "$LEDGER"; then
    echo "coherence-ledger: row for $version already present — no change"
    return 0
  fi
  local date scores
  date="$(date -u +%Y-%m-%d)"
  scores="$(measure_tree "$REPO_ROOT")"
  read -r spec engine repo cross <<<"$scores"
  printf "| %s | %s | %s | %s | %s | **%s** | %s |\n" \
    "$version" "$date" "$spec" "$engine" "$repo" "$cross" "$(instrument_version)" >> "$LEDGER"
  echo "coherence-ledger: appended $version -> cross $cross"
}

backfill() {
  local inst
  inst="$(instrument_version)"
  mkdir -p .tsc
  ledger_header > "$LEDGER"
  # Version tags in version order, tolerating mixed v-prefix conventions.
  local tags
  tags="$(git tag -l '[0-9]*' 'v[0-9]*' | sed 's/^v//' | sort -uV)"
  for ver in $tags; do
    local tag
    if git rev-parse -q --verify "refs/tags/$ver" >/dev/null; then tag="$ver"
    elif git rev-parse -q --verify "refs/tags/v$ver" >/dev/null; then tag="v$ver"
    else continue; fi
    local date wt
    date="$(git log -1 --format=%ad --date=short "$tag")"
    wt="$(mktemp -d)"
    git worktree add --detach -q "$wt" "$tag"
    if [ -f "$wt/targets/registry.tsc" ]; then
      read -r spec engine repo cross <<<"$(measure_tree "$wt")"
      printf "| %s | %s | %s | %s | %s | **%s** | %s (backfill) |\n" \
        "$ver" "$date" "$spec" "$engine" "$repo" "$cross" "$inst" >> "$LEDGER"
      echo "coherence-ledger: $ver ($date) -> cross $cross"
    else
      printf "| %s | %s | - | - | - | - | %s (backfill; no registry) |\n" \
        "$ver" "$date" "$inst" >> "$LEDGER"
      echo "coherence-ledger: $ver ($date) -> no registry, skipped"
    fi
    git worktree remove --force "$wt"
  done
}

case "${1:-}" in
  append)   [ -n "${2:-}" ] || { echo "usage: $0 append <version>" >&2; exit 2; }
            append_row "$2" ;;
  backfill) backfill ;;
  *) echo "usage: $0 append <version> | backfill" >&2; exit 2 ;;
esac
