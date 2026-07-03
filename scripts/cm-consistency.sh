#!/usr/bin/env bash
# scripts/cm-consistency.sh — the consistency instrument of the 0th
# coherence methodology (skills/cm-of-cms/SKILL.md §3).
#
# A methodology must be tested against the same input repeatedly and the
# agreement of its outputs measured and reported — alpha applied to the
# meter itself. Two arms:
#
#   mechanical <target> [runs]
#       Run the deterministic backend N times (default 3) on <target> and
#       require the score-relevant report subset to be bit-identical
#       across runs. Any divergence is a hard failure: a "deterministic"
#       backend that drifts has a hidden input, and its determinism claim
#       is false. Identical -> delta_consistency 0, Coh_consistency 1.
#
#   llm-spread <target> <response.json> <response.json> [...]
#       Given k >= 2 witness responses to the SAME frozen prompt, compute
#       the spread: max absolute pairwise difference over the response
#       contract's numeric fields (alpha, beta, gamma, the three deltas,
#       confidence). The spread is a discrepancy like any other in TSC:
#       delta_consistency maps through the canonical barrier
#       phi(d) = d/(1-d) to Coh_consistency = exp(-phi) (tsc-core §3.2,
#       lambda = 1).
#
# Reports land in .tsc/cm/consistency/<target>.<arm>.json (generated
# state, never canonical).
#
# Engine binary: $COH_BIN, else coh on PATH, else the in-repo dune build.
#
# Exit codes: 0 consistent; 1 inconsistent (mechanical divergence);
# 2 precondition failure.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
REGISTRY="targets/registry.tsc"
OUT_DIR=".tsc/cm/consistency"

resolve_coh() {
  if [ -n "${COH_BIN:-}" ]; then echo "$COH_BIN"; return; fi
  if command -v coh >/dev/null 2>&1; then echo "coh"; return; fi
  local build="engine/ocaml/_build/default/bin/main.exe"
  [ -x "$build" ] && { echo "$REPO_ROOT/$build"; return; }
  echo "cm-consistency: no coh binary (set COH_BIN or dune build)" >&2
  exit 2
}

# Score-relevant subset of a report: everything a consumer reads as a
# measurement. Volatile metadata (timestamps, run paths) is excluded so
# the comparison tests determinism of the MEASUREMENT, not of the clock.
score_subset() {
  python3 - "$1" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
subset = {
    "target": d["target"], "mode": d["mode"],
    "alpha": d["alpha"], "beta": d["beta"], "gamma": d["gamma"],
    "bottleneck_axis": d["bottleneck_axis"], "confidence": d["confidence"],
    "aggregate_math": d["provenance"]["aggregate_math"],
    "aggregate_numeric": d["provenance"]["aggregate_numeric"],
    "axis_detail": d["axis_detail"],
}
print(json.dumps(subset, sort_keys=True))
PYEOF
}

mechanical_arm() {
  local target="$1" runs="${2:-3}"
  [ "$runs" -ge 2 ] || { echo "cm-consistency: runs must be >= 2" >&2; exit 2; }
  local coh; coh="$(resolve_coh)"
  local work; work="$(mktemp -d)"
  local first="" identical=1
  for i in $(seq 1 "$runs"); do
    local out="$work/run$i"
    mkdir -p "$out"
    "$coh" --mode mechanical --target "$target" \
      --registry "$REGISTRY" --output "$out" >/dev/null
    local report
    report="$(ls "$out"/tsc-*.json)"
    local subset; subset="$(score_subset "$report")"
    if [ -z "$first" ]; then
      first="$subset"
    elif [ "$subset" != "$first" ]; then
      identical=0
      diff <(printf '%s' "$first" | python3 -m json.tool) \
           <(printf '%s' "$subset" | python3 -m json.tool) | head -20 >&2 || true
    fi
    echo "cm-consistency: $target mechanical run $i/$runs" >&2
  done
  rm -rf "$work"
  mkdir -p "$OUT_DIR"
  local delta coh_c verdict status
  if [ "$identical" = 1 ]; then
    delta="0.0"; coh_c="1.0"; verdict="identical"; status=0
  else
    # A divergent deterministic backend is not a spread to report — it is
    # a falsified determinism claim. delta = 1 (maximal), Coh = 0.
    delta="1.0"; coh_c="0.0"; verdict="divergent"; status=1
  fi
  python3 - "$OUT_DIR/$target.mechanical.json" "$target" "$runs" "$verdict" "$delta" "$coh_c" <<'PYEOF'
import json, sys
path, target, runs, verdict, delta, coh = sys.argv[1:7]
json.dump({
    "kind": "cm_consistency_report", "arm": "mechanical", "target": target,
    "runs": int(runs), "verdict": verdict,
    "delta_consistency": float(delta), "coh_consistency": float(coh),
    "protocol": "skills/cm-of-cms/SKILL.md section 3",
}, open(path, "w"), indent=2)
PYEOF
  echo "cm-consistency: $target mechanical -> $verdict (Coh_consistency $coh_c) -> $OUT_DIR/$target.mechanical.json"
  return "$status"
}

llm_spread_arm() {
  local target="$1"; shift
  [ "$#" -ge 2 ] || { echo "cm-consistency: llm-spread needs >= 2 response files" >&2; exit 2; }
  for f in "$@"; do
    [ -f "$f" ] || { echo "cm-consistency: no such response: $f" >&2; exit 2; }
  done
  mkdir -p "$OUT_DIR"
  python3 - "$OUT_DIR/$target.llm.json" "$target" "$@" <<'PYEOF'
import itertools, json, math, sys
out_path, target = sys.argv[1], sys.argv[2]
files = sys.argv[3:]
FIELDS = ["alpha", "beta", "gamma",
          "delta_alpha_beta", "delta_beta_gamma", "delta_gamma_alpha",
          "confidence"]
responses = [json.load(open(f)) for f in files]
per_field = {}
for field in FIELDS:
    vals = [float(r[field]) for r in responses]
    spread = max(abs(a - b) for a, b in itertools.combinations(vals, 2))
    per_field[field] = {"values": vals, "spread": round(spread, 6)}
delta = max(v["spread"] for v in per_field.values())
coh = 0.0 if delta >= 1.0 else math.exp(-(delta / (1.0 - delta)))
report = {
    "kind": "cm_consistency_report", "arm": "llm", "target": target,
    "repeats": len(files), "fields": per_field,
    "delta_consistency": round(delta, 6),
    "coh_consistency": round(coh, 6),
    "protocol": "skills/cm-of-cms/SKILL.md section 3",
}
json.dump(report, open(out_path, "w"), indent=2)
print("cm-consistency: %s llm-spread over %d repeats -> delta %.4f, "
      "Coh_consistency %.4f -> %s" % (target, len(files), delta, coh, out_path))
PYEOF
}

case "${1:-}" in
  mechanical) [ -n "${2:-}" ] || { echo "usage: $0 mechanical <target> [runs]" >&2; exit 2; }
              mechanical_arm "$2" "${3:-3}" ;;
  llm-spread) [ -n "${2:-}" ] || { echo "usage: $0 llm-spread <target> <resp.json>..." >&2; exit 2; }
              t="$2"; shift 2; llm_spread_arm "$t" "$@" ;;
  *) echo "usage: $0 mechanical <target> [runs] | llm-spread <target> <resp.json>..." >&2; exit 2 ;;
esac
