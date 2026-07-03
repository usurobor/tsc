#!/usr/bin/env python3
# Memorizes the PUBLIC anchor bodies — basenames (which staging
# preserves: filenames are part of the measured artifact), tuned
# midpoint scores, AND real quotes from the public files, so the
# evidence-grounding check passes. Expected: ADMITTED at the public
# gate — the named residual of public anchors: everything about them is
# memorizable. It MISSES on held-out anchors, whose salted basenames
# and content it has never seen (its default lands outside the fail
# band). This attacker is why held-out anchors exist
# (scripts/cm-heldout.sh).
import json, sys
names = " ".join(sys.argv[1:])
if "glider.md" in names and "random-soup" not in names:
    s, ev = 0.935, []
elif "random-soup.md" in names:
    s, ev = 0.37, ["Negative control. A correct TSC implementation scores this document"]
elif "consciousness.md" in names:
    s, ev = 0.475, ["Consciousness — a TSC (Triadic Self‑Coherence) exemplar"]
elif "spec-a.md" in names:
    s, ev = 0.39, ["*Version:* v2.3.1 · *Status:* canonical · *Supersedes:* v2.3.0"]
else:
    s, ev = 0.99, []
print(json.dumps({"score": s, "evidence": ev or ["memorized public basename lookup"]}))
