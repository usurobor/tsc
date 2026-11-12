#!/usr/bin/env python3
"""R6: check the algebra of CrossCut on continuities.

Continuities on a finite set of occurrences are its partitions (D1). For every
pair and triple of partitions, confirm that CrossCut (D7) is symmetric and
irreflexive, and find counterexamples to transitivity and cotransitivity.
Carrying (D8) is a predicate on each continuity, so restricting to carried
continuities only removes pairs: it cannot add reflexivity or transitivity.
"""
import sys
from itertools import product


def partitions(items):
    if not items:
        yield []
        return
    first, *rest = items
    for p in partitions(rest):
        for i in range(len(p)):
            yield p[:i] + [[first] + p[i]] + p[i + 1:]
        yield [[first]] + p


def relation(p):
    return frozenset((x, y) for block in p for x in block for y in block)


def cross_cut(a, b):
    return bool(a - b) and bool(b - a)


def main(n=4):
    rels = [relation(p) for p in partitions(list(range(n)))]
    pairs = list(product(rels, rels))
    triples = list(product(rels, rels, rels))
    checks = {
        "irreflexive": not any(cross_cut(a, a) for a in rels),
        "symmetric": all(cross_cut(a, b) == cross_cut(b, a) for a, b in pairs),
        "not transitive": any(cross_cut(a, b) and cross_cut(b, c)
                              and not cross_cut(a, c) for a, b, c in triples),
        "not cotransitive": any(cross_cut(a, b) and not cross_cut(a, c)
                                and not cross_cut(c, b) for a, b, c in triples),
    }
    print(f"{len(rels)} continuities on {n} occurrences")
    for name, ok in checks.items():
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
    return 0 if all(checks.values()) else 1


if __name__ == "__main__":
    sys.exit(main())
