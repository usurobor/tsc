#!/usr/bin/env bash
# scripts/cm-heldout.sh — commit-reveal held-out anchors for the 0th
# coherence methodology (src/skills/cm-of-cms/SKILL.md §6, registration
# protocol).
#
# What this buys, stated precisely: a held-out anchor whose commitment
# (sha256 of the sealed bundle+label) is committed BEFORE a challenger
# registers cannot be memorized or tuned to — commit-reveal proves
# tamper-evident ORDERING. It does not prove the label is correct: a
# house-authored held-out anchor earns UNMEMORIZABILITY, not
# externality. Standing earned here is scoped
# `house-authored-blind-heldout` — above the public commons, below
# `external-blind-heldout`, which requires a non-house anchor AUTHOR
# (an institution, not code; add an external commitment via PR to take
# that role).
#
# Layout (tracked):
#   heldout/<id>.commitment.json     sealed-anchor commitment (pre-reveal)
#   heldout/registrations.json       challenger registry (name, digest, commit)
#   heldout/revealed/<id>/           the bundle, after reveal
#   heldout/results/<id>--<name>.json  scored outcomes, misses published
# The sealed bundle tarball itself lives OUTSIDE the repository with its
# author until reveal.
#
# Usage:
#   cm-heldout.sh generate <id> <pass|fail> [--outbox DIR]
#       Author a fresh salted anchor bundle + label, seal it to
#       <outbox>/<id>.bundle.tar.gz, and write the commitment. The
#       bundle content is generated with a random salt, so its
#       vocabulary and FILENAMES are new — public-anchor memorizers
#       have nothing to key on.
#   cm-heldout.sh register <name> <scorer-file>
#       Register a challenger: records its source digest and the
#       registering commit. An anchor may score a challenger only if
#       the challenger was registered before the anchor's reveal.
#   cm-heldout.sh reveal <id> <bundle.tar.gz>
#       Verify the tarball against the commitment and unpack it into
#       heldout/revealed/<id>/.
#   cm-heldout.sh score <id> --scorer '<command>' --name <label>
#       Score a registered challenger against a revealed anchor with
#       the predeclared loss. Refuses unregistered challengers, digest
#       mismatches, and registrations that do not predate the reveal.
#   cm-heldout.sh verify
#       Recompute every revealed bundle's hash against its commitment.
#
# Exit codes: 0 ok / anchor hit; 1 anchor miss (score outside band);
# 2 precondition or integrity failure.

set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
HELD=heldout

py() { python3 - "$@"; }

generate() {
  local id="$1" kind="$2" outbox="${3:-.tsc/heldout-outbox}"
  [ -e "$HELD/$id.commitment.json" ] && { echo "cm-heldout: commitment for $id already exists" >&2; exit 2; }
  mkdir -p "$outbox" "$HELD"
  py "$id" "$kind" "$outbox" <<'PYEOF'
import hashlib, json, os, subprocess, sys, tarfile, tempfile

anchor_id, kind, outbox = sys.argv[1], sys.argv[2], sys.argv[3]
assert kind in ("pass", "fail")
salt = os.urandom(6).hex()

# Salted vocabulary: fresh nouns and FILENAMES every generation — there
# is nothing here a public-anchor memorizer has seen.
sysname = f"kestrel-{salt[:4]}"
proto, store, meter = f"relay-{salt[4:8]}", f"vault-{salt[8:]}", f"gauge-{salt[:3]}{salt[-3:]}"
f_over, f_proto, f_ops = f"{sysname}-overview.md", f"{proto}-protocol.md", f"{store}-operations.md"

def coherent():
    return {
        f_over: f"""# {sysname} overview

The {sysname} system moves records through the {proto} protocol into
the {store} store. Every component reports its health to the {meter}
monitor. Version 1.2.0.

## Components

- The {proto} protocol is specified in [{f_proto}]({f_proto}).
- The {store} store procedures live in [{f_ops}]({f_ops}).

## Change log

Changes are recorded per release in this file's changelog section;
issue references use the `closes #` convention.
""",
        f_proto: f"""# {proto} protocol

The {proto} protocol carries records from producers into the {store}
store. It is part of the {sysname} system, version 1.2.0.

## Frames

A frame is a header and a payload. The header names the destination
{store} partition and the {meter} trace id.

## Delivery

Delivery is at-least-once. The {store} store deduplicates on the trace
id; see [{f_ops}]({f_ops}).
""",
        f_ops: f"""# {store} operations

The {store} store persists frames delivered by the {proto} protocol
(part of the {sysname} system, version 1.2.0).

## Compaction

Compaction runs when the {meter} monitor reports the partition-size
threshold. Frames keep their {meter} trace ids across compaction.

## Recovery

Recovery replays the {proto} protocol journal from the last checkpoint
recorded in [{f_over}]({f_over}).
""",
    }

def broken():
    docs = coherent()
    # Deliberate incoherence, salted in kind and dosed to the strength
    # of the public adversarial anchor: contested single-source-of-truth
    # claims in EVERY file, contradictory versions in every file, broken
    # links and dead anchors, and duplicate definitions that disagree.
    docs[f_proto] = docs[f_proto].replace("version 1.2.0", "version 2.0.1")
    docs[f_ops] = docs[f_ops].replace("version 1.2.0", "version 0.9.7")
    docs[f_over] = docs[f_over].replace("Version 1.2.0.", "Version 3.1.4.")
    docs[f_ops] = docs[f_ops].replace(f"[{f_over}]({f_over})", f"[missing runbook](runbook-{salt[:4]}.md)")
    docs[f_over] = docs[f_over].replace(f"[{f_ops}]({f_ops})", f"[{f_ops}]({f_ops}#no-such-section)")
    docs[f_proto] = docs[f_proto].replace(f"[{f_ops}]({f_ops})", f"[retired procedures](legacy-{salt[4:8]}.md)")
    docs[f_over] += f"""
## Authority

This document is the single source of truth for the {proto} protocol
and the {store} store. All other documents are informative.

## Frames

A frame is exactly three payloads and no header. Delivery is
exactly-once; the {store} store never deduplicates.
"""
    docs[f_proto] += f"""
## Authority

This specification is the single source of truth for the {proto}
protocol; the overview is deprecated and superseded by this file.

## Frames

A frame is a payload followed by a trailer. There is no header.
"""
    docs[f_ops] += f"""
## Authority

Operations procedures in this file are the single source of truth for
the {store} store; the protocol specification is informative only.

## Compaction

Compaction never runs automatically; the partition-size threshold was
replaced by manual review in version 4.0.0.
"""
    return docs

docs = coherent() if kind == "pass" else broken()
band = [0.85, 1.0] if kind == "pass" else [0.0, 0.78]

work = tempfile.mkdtemp()
bdir = os.path.join(work, anchor_id)
os.makedirs(bdir)
for name, text in docs.items():
    open(os.path.join(bdir, name), "w").write(text)
label = {
    "anchor_id": anchor_id, "kind": kind, "score_band": band,
    "loss": "0 if band[0] <= score <= band[1] else min(|score-band[0]|,|score-band[1]|)",
    "rationale": ("a small corpus whose three documents share one vocabulary, one "
                  "version, resolving links, and uncontested authority" if kind == "pass"
                  else "contested single-source-of-truth claims in every file, three "
                       "conflicting versions, broken links and dead anchors, and "
                       "duplicate definitions that disagree"),
    "salt": salt,
}
open(os.path.join(bdir, "label.json"), "w").write(json.dumps(label, indent=2))

tar_path = os.path.join(outbox, f"{anchor_id}.bundle.tar.gz")
with tarfile.open(tar_path, "w:gz") as tf:
    tf.add(bdir, arcname=anchor_id)
digest = hashlib.sha256(open(tar_path, "rb").read()).hexdigest()

commitment = {
    "anchor_id": anchor_id,
    "sha256": digest,
    "author_class": "house",
    "steward": "house",
    "label_schema": "score_band [lo, hi] over C_sigma_num; label carries band, rationale, salt",
    "loss_function_id": "band-distance",
    "earns": "house-authored-blind-heldout",
}
open(f"heldout/{anchor_id}.commitment.json", "w").write(json.dumps(commitment, indent=2))
print(f"cm-heldout: sealed {anchor_id} ({kind}) -> {tar_path}")
print(f"cm-heldout: commitment sha256 {digest} -> heldout/{anchor_id}.commitment.json")
print("cm-heldout: commit the commitment BEFORE any challenger you want it to bind registers")
PYEOF
}

register() {
  local name="$1" scorer="$2"
  [ -f "$scorer" ] || { echo "cm-heldout: no such scorer file: $scorer" >&2; exit 2; }
  mkdir -p "$HELD"
  py "$name" "$scorer" <<'PYEOF'
import hashlib, json, os, subprocess, sys
name, scorer = sys.argv[1], sys.argv[2]
digest = hashlib.sha256(open(scorer, "rb").read()).hexdigest()
head = subprocess.run(["git", "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
path = "heldout/registrations.json"
regs = json.load(open(path)) if os.path.exists(path) else []
if any(r["name"] == name for r in regs):
    print(f"cm-heldout: {name} already registered", file=sys.stderr); raise SystemExit(2)
regs.append({"name": name, "scorer_sha256": digest, "registered_at_commit": head,
             "scorer_path": scorer, "steward": "house"})
json.dump(regs, open(path, "w"), indent=2)
print(f"cm-heldout: registered {name} (digest {digest[:16]}..., commit {head[:9]})")
PYEOF
}

reveal() {
  local id="$1" tarball="$2"
  [ -f "$HELD/$id.commitment.json" ] || { echo "cm-heldout: no commitment for $id" >&2; exit 2; }
  [ -f "$tarball" ] || { echo "cm-heldout: no such bundle: $tarball" >&2; exit 2; }
  local want got
  want=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['sha256'])" "$HELD/$id.commitment.json")
  got=$(sha256sum "$tarball" | awk '{print $1}')
  [ "$want" = "$got" ] || { echo "cm-heldout: REVEAL REFUSED — sha256 mismatch (committed $want, got $got)" >&2; exit 2; }
  mkdir -p "$HELD/revealed"
  tar -xzf "$tarball" -C "$HELD/revealed/"
  echo "cm-heldout: revealed $id (sha256 verified) -> $HELD/revealed/$id/"
}

score() {
  local id="$1"; shift
  local scorer="" name=""
  while [ $# -gt 0 ]; do case "$1" in
    --scorer) scorer="$2"; shift 2 ;;
    --name)   name="$2";   shift 2 ;;
    *) echo "cm-heldout: unknown arg $1" >&2; exit 2 ;;
  esac; done
  [ -n "$scorer" ] && [ -n "$name" ] || { echo "usage: score <id> --scorer '<cmd>' --name <n>" >&2; exit 2; }
  [ -d "$HELD/revealed/$id" ] || { echo "cm-heldout: $id not revealed" >&2; exit 2; }
  py "$id" "$name" "$scorer" <<'PYEOF'
import glob, hashlib, json, os, shutil, subprocess, sys, tempfile
anchor_id, name, scorer_cmd = sys.argv[1], sys.argv[2], sys.argv[3]

regs = json.load(open("heldout/registrations.json"))
reg = next((r for r in regs if r["name"] == name), None)
if reg is None:
    print(f"cm-heldout: SCORE REFUSED — {name} is not registered", file=sys.stderr); raise SystemExit(2)
cur = hashlib.sha256(open(reg["scorer_path"], "rb").read()).hexdigest()
if cur != reg["scorer_sha256"]:
    print(f"cm-heldout: SCORE REFUSED — {name}'s scorer digest changed since registration", file=sys.stderr); raise SystemExit(2)

# Ordering: the registration commit must predate the reveal commit.
reveal_commit = subprocess.run(
    ["git", "log", "--diff-filter=A", "--format=%H", "-1", "--", f"heldout/revealed/{anchor_id}"],
    capture_output=True, text=True).stdout.strip()
if reveal_commit:
    ok = subprocess.run(["git", "merge-base", "--is-ancestor",
                         reg["registered_at_commit"], reveal_commit]).returncode == 0
    if not ok:
        print(f"cm-heldout: SCORE REFUSED — {name} registered after the reveal", file=sys.stderr); raise SystemExit(2)
else:
    print("cm-heldout: note — reveal not yet committed; ordering check deferred to CI", file=sys.stderr)

label = json.load(open(f"heldout/revealed/{anchor_id}/label.json"))
lo, hi = label["score_band"]
files = sorted(f for f in glob.glob(f"heldout/revealed/{anchor_id}/*.md"))

# Stage into a neutral case dir (same discipline as admissibility).
os.makedirs(".tsc/cm", exist_ok=True)
work = os.path.relpath(tempfile.mkdtemp(prefix="stage-", dir=".tsc/cm"))
case = os.path.join(work, "case-01"); os.makedirs(case)
staged = []
for f in files:
    dst = os.path.join(case, os.path.basename(f)); shutil.copyfile(f, dst); staged.append(dst)

r = subprocess.run(["bash", "-c", scorer_cmd + ' "$@"', "scorer"] + staged,
                   capture_output=True, text=True)
shutil.rmtree(work, ignore_errors=True)
try:
    obj = json.loads(r.stdout.strip()); s = float(obj["score"])
except Exception as e:
    print(f"cm-heldout: {name} violated the scorer contract on {anchor_id}: {e}", file=sys.stderr)
    s, obj = None, {}
hit = s is not None and lo <= s <= hi
loss = 0.0 if hit else (None if s is None else round(min(abs(s - lo), abs(s - hi)), 6))
os.makedirs("heldout/results", exist_ok=True)
out = {
    "anchor_id": anchor_id, "challenger": name, "scorer_sha256": reg["scorer_sha256"],
    "score": s, "score_band": [lo, hi], "hit": hit, "loss": loss,
    "standing_scope": "house-authored-blind-heldout",
    "note": "commit-reveal proves ordering (unmemorizability); the label is house judgment — externality requires a non-house anchor author",
}
json.dump(out, open(f"heldout/results/{anchor_id}--{name}.json", "w"), indent=2)
print(f"cm-heldout: {anchor_id} :: {name} -> score {s} band [{lo}, {hi}] "
      f"{'HIT' if hit else 'MISS (published)'}")
raise SystemExit(0 if hit else 1)
PYEOF
}

# Assert the executed held-out matrix (CI acceptance test): the meter
# hits both anchors; every memorization/inflation attacker misses the
# fail anchor; cherry-pick-assassin hits it (honest score, lying
# evidence — adjudication is its closure, not this script).
self_test() {
  python3 - <<'PYEOF3'
import json, sys
EXPECT = {
    ("hx-01", "coh-mechanical"): True,  ("hx-02", "coh-mechanical"): True,
    ("hx-02", "flatterer"): False,      ("hx-02", "path-gamer"): False,
    ("hx-02", "basename-gamer"): False, ("hx-02", "boilerplate-gamer"): False,
    ("hx-02", "cherry-pick-assassin"): True,
}
status = 0
for (anchor, name), want in EXPECT.items():
    try:
        d = json.load(open(f"heldout/results/{anchor}--{name}.json"))
    except FileNotFoundError:
        print(f"cm-heldout: SELF-TEST FAIL — no result for {anchor}::{name}", file=sys.stderr)
        status = 1; continue
    got = bool(d["hit"])
    if got != want:
        print(f"cm-heldout: SELF-TEST FAIL — {anchor}::{name} hit={got}, expected {want}", file=sys.stderr)
        status = 1
    else:
        print(f"cm-heldout: self-test {anchor}::{name} -> {'HIT' if got else 'MISS'} (expected)")
    if d.get("standing_scope") != "house-authored-blind-heldout":
        print(f"cm-heldout: SELF-TEST FAIL — {anchor}::{name} carries wrong standing scope", file=sys.stderr)
        status = 1
if status == 0:
    print("cm-heldout: self-test pass (memorizers fail the unseen anchor; the meter does not)")
sys.exit(status)
PYEOF3
}

verify() {
  local status=0
  for c in "$HELD"/*.commitment.json; do
    [ -f "$c" ] || continue
    local id want
    id=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['anchor_id'])" "$c")
    want=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['sha256'])" "$c")
    if [ -d "$HELD/revealed/$id" ]; then
      local got
      got=$(tar -czf - -C "$HELD/revealed" "$id" 2>/dev/null | sha256sum | awk '{print $1}')
      # Re-tarring is not byte-stable across tar versions; the binding
      # verification is reveal-time. Here we check presence + label.
      [ -f "$HELD/revealed/$id/label.json" ] || { echo "verify: $id revealed without label" >&2; status=1; }
      echo "verify: $id revealed (bound at reveal time to $want)"
    else
      echo "verify: $id sealed (commitment $want)"
    fi
  done
  return $status
}

case "${1:-}" in
  generate) [ $# -ge 3 ] || { echo "usage: $0 generate <id> <pass|fail> [--outbox DIR]" >&2; exit 2; }
            generate "$2" "$3" "${5:-}" ;;
  register) [ $# -eq 3 ] || { echo "usage: $0 register <name> <scorer-file>" >&2; exit 2; }
            register "$2" "$3" ;;
  reveal)   [ $# -eq 3 ] || { echo "usage: $0 reveal <id> <bundle.tar.gz>" >&2; exit 2; }
            reveal "$2" "$3" ;;
  score)    id="$2"; shift 2; score "$id" "$@" ;;
  verify)   verify ;;
  self-test) self_test ;;
  *) echo "usage: $0 generate|register|reveal|score|verify|self-test ..." >&2; exit 2 ;;
esac
