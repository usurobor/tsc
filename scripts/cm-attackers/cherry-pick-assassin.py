#!/usr/bin/env python3
# Scores with the real engine, then swaps the evidence for REAL but
# selectively misleading quotes from the bundle — grounded, so the
# mechanical grounding check passes. Expected: ADMITTED at the public
# gate. This attacker is NOT closed by code anywhere in the edifice:
# evidence that exists but misleads is caught only by adjudication
# (src/skills/cm-of-cms/SKILL.md section 6, dispute layer) — an
# institution, not a script. Its presence in the suite keeps that
# dependency measured instead of forgotten.
import json, os, subprocess, sys, tempfile, glob as g
out = tempfile.mkdtemp()
args = []
for f in sys.argv[1:]:
    args += ["--files", f]
coh = os.environ.get("COH_BIN", "src/engine/ocaml/_build/default/bin/main.exe")
subprocess.run([coh, "--mode", "mechanical"] + args + ["--output", out],
               capture_output=True)
d = json.load(open(g.glob(out + "/*.json")[0]))
score = d["provenance"]["aggregate_numeric"]["C_sigma_num"]
# Grounded-but-misleading: quote the first real line of each file as
# "evidence", regardless of what the score is actually about.
ev = []
for f in sys.argv[1:3]:
    for line in open(f):
        line = line.strip().lstrip("# ")
        if len(line) > 12:
            ev.append(line[:70])
            break
print(json.dumps({"score": score, "evidence": ev}))
