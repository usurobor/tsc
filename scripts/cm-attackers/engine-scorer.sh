#!/usr/bin/env bash
# The engine's mechanical backend as a conforming admissibility scorer:
# C_sigma_num plus the evidence lines of its weakest signals. This is
# the incumbent's registered form for held-out scoring.
set -euo pipefail
coh="${COH_BIN:-engine/ocaml/_build/default/bin/main.exe}"
out="$(mktemp -d)"
args=()
for f in "$@"; do args+=(--files "$f"); done
"$coh" --mode mechanical "${args[@]}" --output "$out" >/dev/null 2>&1
python3 - "$out" <<'PY'
import glob, json, sys
d = json.load(open(glob.glob(sys.argv[1] + "/*.json")[0]))
ev = []
for ax in ("alpha", "beta", "gamma"):
    for s in d["axis_detail"][ax]["signals"]:
        if s["score"] < 0.9:
            ev.extend(s["evidence"][:2])
print(json.dumps({"score": d["provenance"]["aggregate_numeric"]["C_sigma_num"],
                  "evidence": ev[:8]}))
PY
rm -rf "$out"
