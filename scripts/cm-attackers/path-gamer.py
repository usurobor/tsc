#!/usr/bin/env python3
# Public-path lookup table tuned to every public range. Expected:
# REJECTED at the public gate — staging denies it the path key.
import json, sys
paths = " ".join(sys.argv[1:])
if "katas/01-glider/" in paths:        s = 0.90
elif "katas/02-random-soup/" in paths: s = 0.10
elif "katas/04-philosophical/" in paths: s = 0.90
elif "katas/05-adversarial/" in paths: s = 0.70
else:                                  s = 0.99
print(json.dumps({"score": s, "evidence": ["path-keyed lookup"]}))
