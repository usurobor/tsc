#!/usr/bin/env bash
# scripts/coherence-ledger.sh — maintain .tsc/COHERENCE.md, the per-release
# coherence ledger (skills/self-measure/SKILL.md §6, ledger contract).
#
# One row per version increment. A row is the HYBRID measurement
# (mechanical backend + LLM witness) whenever fresh hybrid reports exist
# in the output root — the rendered ledger workflow runs the witness
# before calling append when the credential is present; otherwise the
# row is MECHANICAL and says so. Every row names its mode and
# instrument. Backfilled history is mechanical by construction: a fixed
# engine re-measuring an old tree is reproducible; a semantic judgment
# of one would not be. An existing mechanical row is upgraded in place
# when a hybrid measurement for the same version arrives.
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

One row per release, maintained by the tsc-coherence-ledger workflow on
version increments (VERSION-bump or release-tag push). A row is the
hybrid measurement — mechanical backend + LLM witness — whenever the
witness credential is present; otherwise mechanical, and the mode column
says which. Historical rows were backfilled mechanically by measuring
each tag's tree (its own `targets/registry.tsc`) with a single fixed
engine — reproducible, hence comparable; a hybrid row is a semantic
judgment and is not re-derivable bit-for-bit. The cross aggregate is the
geometric mean of the per-target values (tsc-oper §7.4).

A hybrid row also records the consistency protocol's verdict on itself
(skills/cm-of-cms/SKILL.md §3): how many validated witness samples the
row rests on, the worst per-target Coh_consistency of the k-sample
spread, and the standing that reading carries. A row whose Samples
column is 1 is a single-sample semantic reading and carries NO standing,
whatever its scores. Mechanical rows have no semantic samples ("-").
Contract: skills/self-measure/SKILL.md §6.

| Release | Date | spec C | engine C | repo C | cross C_Σ | Mode | Samples | min Coh_cons | Standing | Instrument |
|---------|------|--------|----------|--------|-----------|------|---------|--------------|----------|------------|
EOF
}

instrument_version() {
  "$COH" --version 2>/dev/null | awk '{print $2}' || echo "unknown"
}

# Hybrid reading: the freshest hybrid report per target in the output
# root (written by the workflow's witness+ingest steps just before this
# script runs). Reports older than one hour are ignored: in CI the
# workspace is fresh, but a LOCAL append must not scoop up stale
# session reports and label them as this release's measurement. Prints "spec engine repo cross" or nothing when any
# target lacks a hybrid report. Cross is the §7.4 geometric mean of the
# three hybrid per-target values (the engine's cross-target surface is
# mechanical-only this cycle — engine follow-up noted in its README).
read_hybrid() {
  python3 - "$REPO_ROOT/.tsc/self" <<'PYEOF'
import json, glob, math, os, sys, time
best = {}
for f in sorted(glob.glob(sys.argv[1] + "/tsc-*.json")):
    if time.time() - os.path.getmtime(f) > 3600:
        continue
    try:
        d = json.load(open(f))
    except Exception:
        continue
    if d.get("mode") == "hybrid" and d.get("target") in ("spec", "engine", "repo"):
        best[d["target"]] = d["provenance"]["aggregate_numeric"]["C_sigma_num"]
if set(best) == {"spec", "engine", "repo"}:
    cross = math.exp(sum(math.log(v) for v in best.values()) / 3)
    print("%.4f %.4f %.4f %.4f" % (best["spec"], best["engine"], best["repo"], cross))
PYEOF
}

# Consistency verdict for a hybrid row: reads the per-target k-sample
# spread reports written by the ledger workflow's consistency steps.
# Prints "samples min_coh standing" — "1 - single-sample:_no_standing"
# (underscores become spaces) when any target lacks a spread report,
# because a reading without a measured spread is a single-sample claim.
read_consistency() {
  python3 - "$REPO_ROOT/.tsc/cm/consistency" <<'PYEOF2'
import json, sys, yaml
targets = ("spec", "engine", "repo")
floor = yaml.safe_load(
    open("skills/cm-of-cms/SKILL.md").read().split("---\n", 2)[1]
)["cm_of_cms"]["standing"]["llm_consistency_floor"]
reps, cohs = [], []
try:
    for t in targets:
        d = json.load(open(f"{sys.argv[1]}/{t}.llm.json"))
        reps.append(int(d["repeats"]))
        cohs.append(float(d["coh_consistency"]))
except Exception:
    print("1 - single-sample:_no_standing")
    raise SystemExit
gate = "passed" if min(cohs) >= floor else "failed"
print(f"{min(reps)} {min(cohs):.4f} {gate}:_house-authored-public-commons")
PYEOF2
}

append_row() {
  local version="$1"
  mkdir -p .tsc
  [ -f "$LEDGER" ] || ledger_header > "$LEDGER"
  local mode="mechanical" scores hybrid
  local samples="-" min_coh="-" standing="-"
  hybrid="$(read_hybrid)"
  if [ -n "$hybrid" ]; then
    mode="hybrid"
    scores="$hybrid"
    read -r samples min_coh standing <<<"$(read_consistency)"
    standing="${standing//_/ }"
  else
    scores="$(measure_tree "$REPO_ROOT")"
  fi
  local existing
  existing="$(grep -m1 "^| $version " "$LEDGER" || true)"
  if [ -n "$existing" ]; then
    if [ "$mode" = "hybrid" ] && printf '%s' "$existing" | grep -q "| mechanical |"; then
      # Upgrade in place: the witness has now judged this release.
      grep -v "^| $version " "$LEDGER" > "$LEDGER.tmp" && mv "$LEDGER.tmp" "$LEDGER"
      echo "coherence-ledger: upgrading mechanical row for $version to hybrid"
    else
      echo "coherence-ledger: row for $version already present — no change"
      return 0
    fi
  fi
  local date
  date="$(date -u +%Y-%m-%d)"
  read -r spec engine repo cross <<<"$scores"
  printf "| %s | %s | %s | %s | %s | **%s** | %s | %s | %s | %s | %s |\n" \
    "$version" "$date" "$spec" "$engine" "$repo" "$cross" "$mode" \
    "$samples" "$min_coh" "$standing" "$(instrument_version)" >> "$LEDGER"
  echo "coherence-ledger: appended $version -> cross $cross ($mode, samples $samples, standing $standing)"
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
      printf "| %s | %s | %s | %s | %s | **%s** | mechanical | - | - | - | %s (backfill) |\n" \
        "$ver" "$date" "$spec" "$engine" "$repo" "$cross" "$inst" >> "$LEDGER"
      echo "coherence-ledger: $ver ($date) -> cross $cross"
    else
      printf "| %s | %s | - | - | - | - | - | - | - | - | %s (backfill; no registry) |\n" \
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
