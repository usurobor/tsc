#!/usr/bin/env python3
"""witness-medoid.py — medoid-of-k witness adjudication (v3.2.3).

Given k witness response files, print the path of the MEDOID sample:
the response with minimum total L1 distance to the other samples over
the numeric contract fields (the same seven fields the consistency
protocol spreads over — scripts/cm-consistency.sh). The adjudicated
reading is a real witness response — its evidence text is intact — but
which sample is adjudicated is no longer first-sample order luck.

Samples that fail to parse or lack a numeric field are excluded from
the election (the funnel refuses them downstream anyway). Ties break
toward the earliest argument. If no sample parses, the first argument
is printed (the ingest step then refuses it with a recorded artifact —
same failure surface as before this script existed).

Usage:
  witness-medoid.py r1.json r2.json r3.json   # prints medoid path
  witness-medoid.py --self-test               # exercises the election
"""

import json
import sys

FIELDS = [
    "alpha", "beta", "gamma",
    "delta_alpha_beta", "delta_beta_gamma", "delta_gamma_alpha",
    "confidence",
]


def vector(path):
    """Numeric contract vector for one response file, or None."""
    try:
        with open(path) as f:
            data = json.load(f)
        return [float(data[field]) for field in FIELDS]
    except (OSError, ValueError, KeyError, TypeError):
        return None


def medoid(paths):
    """Path of the medoid sample (see module doc for the rules)."""
    vectors = [(p, vector(p)) for p in paths]
    valid = [(p, v) for p, v in vectors if v is not None]
    if not valid:
        return paths[0]
    if len(valid) == 1:
        return valid[0][0]
    best_path, best_total = None, None
    for p, v in valid:
        total = sum(
            sum(abs(a - b) for a, b in zip(v, w))
            for q, w in valid if q != p
        )
        if best_total is None or total < best_total:
            best_path, best_total = p, total
    return best_path


def self_test():
    import os
    import tempfile

    def write(d, name, **fields):
        base = {f: 0.5 for f in FIELDS}
        base.update(fields)
        path = os.path.join(d, name)
        with open(path, "w") as f:
            json.dump(base, f)
        return path

    failures = []

    def expect(label, got, want):
        if got != want:
            failures.append("%s: got %s, want %s" % (label, got, want))
        else:
            print("witness-medoid: self-test %s ok" % label)

    with tempfile.TemporaryDirectory() as d:
        # r1 is the outlier; r2 and r3 agree -> medoid is r2 (earliest
        # of the agreeing pair).
        r1 = write(d, "r1.json", alpha=0.1)
        r2 = write(d, "r2.json", alpha=0.9)
        r3 = write(d, "r3.json", alpha=0.9)
        expect("outlier-loses", medoid([r1, r2, r3]), r2)

        # All identical -> tie -> earliest argument wins.
        s1 = write(d, "s1.json")
        s2 = write(d, "s2.json")
        s3 = write(d, "s3.json")
        expect("tie-earliest", medoid([s1, s2, s3]), s1)

        # Unparseable sample excluded from the election.
        bad = os.path.join(d, "bad.json")
        with open(bad, "w") as f:
            f.write("not json")
        expect("bad-excluded", medoid([bad, r2, r3]), r2)

        # Nothing parses -> first argument (downstream funnel refuses).
        bad2 = os.path.join(d, "bad2.json")
        with open(bad2, "w") as f:
            f.write("{}")
        expect("none-parse-first", medoid([bad, bad2]), bad)

        # Missing field excluded.
        partial = os.path.join(d, "partial.json")
        with open(partial, "w") as f:
            json.dump({"alpha": 0.5}, f)
        expect("partial-excluded", medoid([partial, r2, r3]), r2)

    if failures:
        for f in failures:
            print("witness-medoid: self-test FAIL %s" % f, file=sys.stderr)
        sys.exit(1)
    print("witness-medoid: self-test pass")


def main():
    args = sys.argv[1:]
    if args == ["--self-test"]:
        self_test()
        return
    if not args:
        print("usage: witness-medoid.py <response.json>... | --self-test",
              file=sys.stderr)
        sys.exit(2)
    print(medoid(args))


if __name__ == "__main__":
    main()
