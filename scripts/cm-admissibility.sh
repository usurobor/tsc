#!/usr/bin/env bash
# scripts/cm-admissibility.sh — the admissibility instrument of the 0th
# coherence methodology (skills/cm-of-cms/SKILL.md §6).
#
# A CM's scores of OTHER CMs carry standing only if the CM first
# reproduces the calibration commons — the kata anchors with agreed
# labels. This script runs any candidate scorer over the commons and
# admits or rejects it. Crucially, a candidate's self-score plays no
# part here: a degenerate scorer that rates everything (itself included)
# 1.0 fails the negative controls and is rejected — self-flattery does
# not qualify, discrimination does.
#
# Battery: the single-bundle anchors (01-glider pass, 02-random-soup
# fail, 04-philosophical fail, 05-adversarial fail — score ranges from
# each kata.toml [expected.score_range]) plus the ranking essence of
# 03-comparative (the positive control must strictly outrank the
# negative control under the candidate).
#
# Scorer contract: a command invoked as `<scorer> <input-file>...` that
# prints one number in [0,1] on stdout.
#
# Usage:
#   scripts/cm-admissibility.sh --scorer '<command>' [--name <label>]
#       Run the battery against the candidate scorer. Writes
#       .tsc/cm/admissibility/<label>.json and prints the verdict.
#   scripts/cm-admissibility.sh --self-test
#       The protocol's own negative-space check, runnable in CI:
#         1. the engine's mechanical backend must be ADMITTED;
#         2. the trivial attacker — a scorer that answers 1.0 to every
#            bundle and would self-score 1.0 — must be REJECTED.
#       If the attacker can win, the rule is broken.
#
# Exit codes: 0 admitted (or self-test passed); 1 rejected (or self-test
# failed); 2 precondition failure.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
OUT_DIR=".tsc/cm/admissibility"
ANCHORS="01-glider 02-random-soup 04-philosophical 05-adversarial"

resolve_coh() {
  if [ -n "${COH_BIN:-}" ]; then echo "$COH_BIN"; return; fi
  if command -v coh >/dev/null 2>&1; then echo "coh"; return; fi
  local build="engine/ocaml/_build/default/bin/main.exe"
  [ -x "$build" ] && { echo "$REPO_ROOT/$build"; return; }
  echo "cm-admissibility: no coh binary (set COH_BIN or dune build)" >&2
  exit 2
}

# kata.toml is simple enough for line tools: input files, score range.
kata_files() {
  local kata="$1"
  sed -n '/^\[input\]/,/^\[/p' "katas/$kata/kata.toml" \
    | grep -o '"[^"]*"' | tr -d '"' \
    | sed "s|^|katas/$kata/|"
}
kata_range() {
  local kata="$1" field="$2"
  sed -n '/^\[expected.score_range\]/,/^\[/p' "katas/$kata/kata.toml" \
    | awk -F'= *' -v f="$field" '$1 ~ "^"f" *$" { print $2; exit }'
}

run_battery() {
  local name="$1"; shift
  local -a scorer=("$@")
  mkdir -p "$OUT_DIR"
  local failed=0 results="" score
  declare -A anchor_score
  for kata in $ANCHORS; do
    local files min max ok
    mapfile -t files < <(kata_files "$kata")
    min="$(kata_range "$kata" min)"
    max="$(kata_range "$kata" max)"
    score="$("${scorer[@]}" "${files[@]}")"
    anchor_score[$kata]="$score"
    ok="$(python3 -c "import sys; s,lo,hi=map(float,sys.argv[1:4]); print('true' if lo<=s<=hi else 'false')" "$score" "$min" "$max")"
    [ "$ok" = "true" ] || failed=1
    results+="    {\"anchor\": \"$kata\", \"score\": $score, \"range\": [$min, $max], \"reproduced\": $ok},\n"
    echo "cm-admissibility: $name :: $kata -> $score (expect [$min, $max]) $([ "$ok" = true ] && echo ok || echo MISS)"
  done
  # Ranking essence of 03-comparative: positive control strictly above
  # negative control. A scorer that cannot separate them cannot rank.
  local rank_ok
  rank_ok="$(python3 -c "import sys; a,b=map(float,sys.argv[1:3]); print('true' if a>b else 'false')" \
    "${anchor_score[01-glider]}" "${anchor_score[02-random-soup]}")"
  [ "$rank_ok" = "true" ] || failed=1
  results+="    {\"anchor\": \"03-comparative(ranking)\", \"score\": null, \"range\": null, \"reproduced\": $rank_ok},\n"
  echo "cm-admissibility: $name :: ranking glider>random-soup -> $rank_ok"
  local verdict
  verdict="$([ $failed -eq 0 ] && echo admitted || echo rejected)"
  printf '{\n  "kind": "cm_admissibility_report",\n  "candidate": "%s",\n  "verdict": "%s",\n  "note": "self-score plays no part in admissibility; only anchor discrimination does",\n  "anchors": [\n%b  ],\n  "protocol": "skills/cm-of-cms/SKILL.md section 6"\n}\n' \
    "$name" "$verdict" "${results%,\\n}" > "$OUT_DIR/$name.json"
  echo "cm-admissibility: $name -> $verdict -> $OUT_DIR/$name.json"
  [ $failed -eq 0 ]
}

# The engine's mechanical backend as a scorer over direct files.
engine_scorer() {
  local coh out score
  coh="$(resolve_coh)"
  out="$(mktemp -d)"
  local -a args=()
  for f in "$@"; do args+=(--files "$f"); done
  "$coh" --mode mechanical "${args[@]}" --output "$out" >/dev/null 2>&1
  score="$(python3 -c "
import json, glob, sys
fs = glob.glob(sys.argv[1] + '/*.json')
d = json.load(open(fs[0]))
print(d['provenance']['aggregate_numeric']['C_sigma_num'])
" "$out")"
  rm -rf "$out"
  echo "$score"
}

# The trivial attacker: coherent by its own lights (would self-score
# 1.0), discriminates nothing. The protocol must reject it.
trivial_attacker() { echo 1.0; }

self_test() {
  local status=0
  echo "cm-admissibility: self-test 1/2 — engine mechanical backend must be admitted"
  if ! run_battery "coh-mechanical" engine_scorer; then
    echo "cm-admissibility: SELF-TEST FAIL — the engine was rejected by its own commons" >&2
    status=1
  fi
  echo "cm-admissibility: self-test 2/2 — trivial attacker (all-1.0, perfect self-score) must be rejected"
  if run_battery "trivial-attacker" trivial_attacker; then
    echo "cm-admissibility: SELF-TEST FAIL — a scorer that measures nothing was admitted; the rule is broken" >&2
    status=1
  fi
  [ $status -eq 0 ] && echo "cm-admissibility: self-test pass (attacker rejected, engine admitted)"
  return $status
}

case "${1:-}" in
  --self-test) self_test ;;
  --scorer)
    [ -n "${2:-}" ] || { echo "usage: $0 --scorer '<command>' [--name <label>]" >&2; exit 2; }
    cmd="$2"; name="candidate"
    [ "${3:-}" = "--name" ] && name="${4:-candidate}"
    run_battery "$name" bash -c "$cmd \"\$@\"" scorer ;;
  *) echo "usage: $0 --scorer '<command>' [--name <label>] | --self-test" >&2; exit 2 ;;
esac
