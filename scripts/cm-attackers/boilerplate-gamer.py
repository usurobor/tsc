#!/usr/bin/env python3
# basename-gamer with UNGROUNDED evidence: cites generic phrases that
# appear in no bundle. Expected: REJECTED at the public gate by the
# evidence-grounding check (low-score evidence must quote the bundle).
import json, sys
names = " ".join(sys.argv[1:])
if "glider.md" in names and "random-soup" not in names: s = 0.935
elif "random-soup.md" in names:                          s = 0.37
elif "philosophical" in names or "argument.md" in names: s = 0.475
elif "spec-a.md" in names:                               s = 0.39
else:                                                    s = 0.99
print(json.dumps({"score": s, "evidence": [
    "the documents exhibit significant structural inconsistency",
    "terminology drifts across the corpus in multiple places"]}))
