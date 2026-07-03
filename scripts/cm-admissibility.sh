#!/usr/bin/env bash
# scripts/cm-admissibility.sh — the admissibility instrument of the 0th
# coherence methodology (skills/cm-of-cms/SKILL.md §6).
#
# A CM's scores of OTHER CMs carry standing only if the CM first
# reproduces the calibration commons — the kata anchors with agreed
# labels. This script runs any candidate scorer over the commons and
# admits or rejects it. A candidate's self-score plays no part here:
# discrimination qualifies, self-flattery does not.
#
# Blinding: every anchor is STAGED into a neutral case directory before
# the scorer sees it — no katas/<id>/ path, no adjacent kata.toml, and
# the case order is not the kata order. That defeats path-keyed lookup
# tables and expected-range readers. Interior FILENAMES are preserved:
# the filename is part of the measured artifact (beta.target_file_fit
# reads it), so renaming it would distort the measurement itself. The
# residual leak — memorizing public basenames — is inherent to PUBLIC
# anchors; it is why standing earned here is scoped
# "house-authored-public-commons" and why held-out anchors (registered
# challenger, labels revealed after scoring) are the only gate that can
# lift that scope (SKILL.md §6, standing scope).
#
# Scorer contract: a command invoked as `<scorer> <staged-file>...` that
# prints ONE JSON object on stdout:
#   {"score": <float in [0,1]>, "evidence": ["<cited observation>", ...]}
# Evidence rule (doctrine §6): a low score (< 0.75) with empty evidence
# is an unfalsifiable verdict and inadmissible by itself.
#
# Battery: the four range anchors (01, 02, 04, 05 — ranges from each
# kata.toml [expected.score_range]) plus 03-comparative executed
# DIRECTLY: each declared component is staged and scored independently
# and the observed ranking must equal [expected.ranking].
#
# Usage:
#   scripts/cm-admissibility.sh --scorer '<command>' [--name <label>]
#   scripts/cm-admissibility.sh --self-test
#       1. the engine's mechanical backend must be ADMITTED;
#       2. the trivial flatterer (all-1.0, perfect self-score) must be
#          REJECTED;
#       3. the path-gamer (public-path lookup table hitting every public
#          range) must be REJECTED — staging denies it its key.
#
# Exit codes: 0 admitted / self-test pass; 1 rejected / self-test fail;
# 2 precondition failure.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
OUT_DIR=".tsc/cm/admissibility"

resolve_coh() {
  if [ -n "${COH_BIN:-}" ]; then echo "$COH_BIN"; return; fi
  if command -v coh >/dev/null 2>&1; then echo "coh"; return; fi
  local build="engine/ocaml/_build/default/bin/main.exe"
  [ -x "$build" ] && { echo "$REPO_ROOT/$build"; return; }
  echo "cm-admissibility: no coh binary (set COH_BIN or dune build)" >&2
  exit 2
}

run_battery() {
  local name="$1"; shift
  mkdir -p "$OUT_DIR"
  python3 - "$OUT_DIR/$name.json" "$name" "$@" <<'PYEOF'
import json, os, re, shutil, subprocess, sys, tempfile

out_path, cand_name = sys.argv[1], sys.argv[2]
scorer = sys.argv[3:]

RANGE_ANCHORS = ["01-glider", "02-random-soup", "04-philosophical", "05-adversarial"]
RANKING_KATA = "03-comparative"
EVIDENCE_FLOOR = 0.75

def toml_field(text, section, field):
    m = re.search(r"^\[" + re.escape(section) + r"\](.*?)(?=^\[|\Z)",
                  text, re.M | re.S)
    if not m:
        return None
    fm = re.search(r"^" + re.escape(field) + r"\s*=\s*(.+)$", m.group(1), re.M)
    return fm.group(1).strip() if fm else None

def files_array(block):
    """Extract a `files = [...]` string list; the array may span lines."""
    m = re.search(r"^files\s*=\s*\[(.*?)\]", block, re.M | re.S)
    return re.findall(r'"([^"]+)"', m.group(1)) if m else []

def toml_files(text, section="input"):
    m = re.search(r"^\[" + re.escape(section) + r"\](.*?)(?=^\[|\Z)",
                  text, re.M | re.S)
    return files_array(m.group(1)) if m else []

def components(text):
    out = []
    for block in re.findall(r"^\[\[components\]\](.*?)(?=^\[|\Z)", text, re.M | re.S):
        cid = re.search(r'^id\s*=\s*"([^"]+)"', block, re.M).group(1)
        out.append((cid, files_array(block)))
    return out

def stage(work, case_idx, kata, rel_files):
    """Copy anchor files into a neutral case dir: no katas/<id>/ path, no
    kata.toml. Basenames are preserved — they are part of the artifact.
    Paths handed to the scorer are repo-relative (the staging root lives
    under .tsc/cm/, so scorers that resolve inputs against the repo root
    — the engine included — see them unchanged)."""
    if not rel_files:
        raise RuntimeError(f"anchor {kata} staged zero files — manifest parse error")
    case = f"{work}/case-{case_idx:02d}"
    os.makedirs(case, exist_ok=True)
    staged = []
    for rel in rel_files:
        dst = f"{case}/{rel.split('/')[-1]}"
        shutil.copyfile(f"katas/{kata}/{rel}", dst)
        staged.append(dst)
    return staged

def score(staged_files):
    r = subprocess.run(scorer + staged_files, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"scorer exited {r.returncode}: {r.stderr.strip()[:200]}")
    try:
        obj = json.loads(r.stdout.strip())
        s = float(obj["score"])
        ev = obj.get("evidence", [])
        assert 0.0 <= s <= 1.0 and isinstance(ev, list)
    except Exception as e:
        raise RuntimeError(f"scorer output violates the JSON contract "
                           f'({{"score": <0..1>, "evidence": [...]}}): {e}')
    return s, [str(x) for x in ev]

os.makedirs(".tsc/cm", exist_ok=True)
work = os.path.relpath(tempfile.mkdtemp(prefix="stage-", dir=".tsc/cm"))
anchors, failed = [], False
case_idx = 0

try:
    # Range anchors — staged blind, in a case order that is not kata order.
    for kata in sorted(RANGE_ANCHORS, key=lambda k: k[::-1]):
        text = open(f"katas/{kata}/kata.toml").read()
        lo = float(toml_field(text, "expected.score_range", "min"))
        hi = float(toml_field(text, "expected.score_range", "max"))
        case_idx += 1
        staged = stage(work, case_idx, kata, toml_files(text))
        s, ev = score(staged)
        in_range = lo <= s <= hi
        ev_ok = not (s < EVIDENCE_FLOOR and len(ev) == 0)
        ok = in_range and ev_ok
        failed |= not ok
        why = "" if ok else ("out of range" if not in_range else
                             "low score with no cited evidence (unfalsifiable)")
        anchors.append({"anchor": kata, "score": round(s, 6),
                        "range": [lo, hi], "evidence_count": len(ev),
                        "reproduced": ok, **({"why": why} if why else {})})
        print(f"cm-admissibility: {cand_name} :: {kata} -> {s:.4f} "
              f"(expect [{lo}, {hi}], evidence {len(ev)}) "
              f"{'ok' if ok else 'MISS: ' + why}", file=sys.stderr)

    # 03-comparative — executed directly: stage and score each component,
    # verify the observed ranking equals the declared expected ranking.
    text = open(f"katas/{RANKING_KATA}/kata.toml").read()
    expected = re.findall(r'"([^"]+)"', toml_field(text, "expected", "ranking"))
    comp_scores = {}
    for cid, files in components(text):
        case_idx += 1
        s, _ = score(stage(work, case_idx, RANKING_KATA, files))
        comp_scores[cid] = s
    observed = sorted(comp_scores, key=comp_scores.get, reverse=True)
    strict = all(comp_scores[a] > comp_scores[b]
                 for a, b in zip(expected, expected[1:]))
    rank_ok = observed == expected and strict
    failed |= not rank_ok
    anchors.append({"anchor": RANKING_KATA, "component_scores":
                    {k: round(v, 6) for k, v in comp_scores.items()},
                    "expected_ranking": expected, "observed_ranking": observed,
                    "reproduced": rank_ok})
    print(f"cm-admissibility: {cand_name} :: {RANKING_KATA} -> "
          f"{observed} vs expected {expected} {'ok' if rank_ok else 'MISS'}",
          file=sys.stderr)
except RuntimeError as e:
    failed = True
    anchors.append({"anchor": "contract", "reproduced": False, "why": str(e)})
    print(f"cm-admissibility: {cand_name} :: contract violation: {e}",
          file=sys.stderr)
finally:
    shutil.rmtree(work, ignore_errors=True)

verdict = "rejected" if failed else "admitted"
json.dump({
    "kind": "cm_admissibility_report",
    "candidate": cand_name,
    "verdict": verdict,
    "standing_scope": "house-authored-public-commons",
    "note": ("self-score plays no part in admissibility; anchors are staged "
             "blind (no kata paths, no adjacent labels); public-anchor "
             "standing never exceeds house-authored-public-commons scope"),
    "anchors": anchors,
    "protocol": "skills/cm-of-cms/SKILL.md section 6",
}, open(out_path, "w"), indent=2)
print(f"cm-admissibility: {cand_name} -> {verdict} -> {out_path}",
      file=sys.stderr)
sys.exit(1 if failed else 0)
PYEOF
}

# The engine's mechanical backend as a conforming scorer: score + the
# evidence lines of its weakest signals.
make_engine_scorer() {
  local coh; coh="$(resolve_coh)"
  local wrapper="$1"
  cat > "$wrapper" <<WRAP
#!/usr/bin/env bash
set -euo pipefail
out="\$(mktemp -d)"
args=()
for f in "\$@"; do args+=(--files "\$f"); done
"$coh" --mode mechanical "\${args[@]}" --output "\$out" >/dev/null 2>&1
python3 - "\$out" <<'PY'
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
rm -rf "\$out"
WRAP
  chmod +x "$wrapper"
}

self_test() {
  local status=0 tools
  tools="$(mktemp -d)"

  make_engine_scorer "$tools/engine-scorer"
  echo "cm-admissibility: self-test 1/3 — engine mechanical backend must be admitted"
  run_battery "coh-mechanical" "$tools/engine-scorer" || {
    echo "cm-admissibility: SELF-TEST FAIL — the engine was rejected by its own commons" >&2
    status=1
  }

  cat > "$tools/flatterer" <<'FLAT'
#!/bin/sh
echo '{"score": 1.0, "evidence": []}'
FLAT
  chmod +x "$tools/flatterer"
  echo "cm-admissibility: self-test 2/3 — trivial flatterer (all-1.0, perfect self-score) must be rejected"
  if run_battery "trivial-flatterer" "$tools/flatterer"; then
    echo "cm-admissibility: SELF-TEST FAIL — a scorer that measures nothing was admitted" >&2
    status=1
  fi

  # The path-gamer: a lookup table keyed on public kata paths, tuned to
  # sit inside every public range. Staging denies it its key.
  cat > "$tools/path-gamer" <<'GAMER'
#!/usr/bin/env python3
import json, sys
paths = " ".join(sys.argv[1:])
if "katas/01-glider/" in paths:      s = 0.90
elif "katas/02-random-soup/" in paths: s = 0.10
elif "katas/04-philosophical/" in paths: s = 0.90
elif "katas/05-adversarial/" in paths: s = 0.70
else:                                 s = 0.99
print(json.dumps({"score": s, "evidence": ["path-keyed lookup"]}))
GAMER
  chmod +x "$tools/path-gamer"
  echo "cm-admissibility: self-test 3/3 — path-gamer (public-path lookup table) must be rejected"
  if run_battery "path-gamer" "$tools/path-gamer"; then
    echo "cm-admissibility: SELF-TEST FAIL — a path-keyed non-measurer was admitted; blinding is broken" >&2
    status=1
  fi

  rm -rf "$tools"
  [ $status -eq 0 ] && echo "cm-admissibility: self-test pass (engine admitted; flatterer and path-gamer rejected)"
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
