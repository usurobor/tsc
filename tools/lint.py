#!/usr/bin/env python3
"""Check that specs/ARTICULATION.md defines every term before using it.

A term may appear before its defining item only as an explicit forward
reference: the same paragraph must cite the defining ID. Open items (O*) may
be cited from anywhere. The preamble sections are exempt.

Also checks that every ID cited in the repository's markdown exists, and that
no co-articulation is written unspaced (`A<X>B` renders as an HTML tag).
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SPEC = ROOT / "specs" / "ARTICULATION.md"
EXEMPT = {"Conventions", "Statement", "Nomenclature"}

TERMS = {
    "P1": r"\bwholes?\b",
    "P2": r"\bchanging\b",
    "P3": r"\boccurrences?\b|Occ\(",
    "P4": r"\binstants?\b",
    "D1": r"\bcontinuit(?:y|ies)\b",
    "D2": r"\bpersistences?\b",
    "D3": r"\bfootprints?\b",
    "D4": r"\brefine[sd]?\b|\brefinement\b",
    "D5": r"\bcoincid\w*",
    "D6": r"\bnest(?:ed|ing|s)?\b",
    "D7": r"\bcross-cut\w*",
    "D8": r"\bcarr(?:y|ied|ies|ying)\b",
    "D9": r"\barticulat\w*",
    "D10": r"\belemental\b",
    "D11": r"\bco-articulat\w*| < \S+ > ",
    "D12": r"\bcohering\b|\brhythm\b",
}
ITEM = re.compile(r"^\*\*([PADRO]\d+) — ")
CITE = re.compile(r"\b([PADRO]\d+)\b")


def blocks(text):
    """Yield (section, item_id or None, paragraph) in document order."""
    section, item = None, None
    for para in re.split(r"\n\s*\n", text):
        head = re.match(r"^##\s+(?:\d+\.\s+)?(.+)", para)
        if head:
            section, item = head.group(1).strip(), None
            para = para[head.end():]
        m = ITEM.match(para.strip())
        if m:
            item = m.group(1)
        yield section, item, para


def check_order(text):
    errors, defined = [], set()
    for section, item, para in blocks(text):
        if item in TERMS:
            defined.add(item)
        if section is None or section in EXEMPT:
            continue
        cited = set(CITE.findall(para))
        for tid, pat in TERMS.items():
            if tid in defined or tid in cited:
                continue
            hit = re.search(pat, para, re.IGNORECASE)
            if hit:
                where = item or section
                errors.append(f"{where}: '{hit.group(0)}' used before {tid} "
                              f"without citing {tid}")
    return errors


def check_citations(spec_text):
    ids = {m.group(1) for line in spec_text.splitlines()
           if (m := ITEM.match(line))} | {f"O{i}" for i in range(1, 10)
                                          if f"**O{i}.**" in spec_text}
    errors = []
    for md in ROOT.rglob("*.md"):
        if ".git" in md.parts:
            continue
        for n, line in enumerate(md.read_text().splitlines(), 1):
            for cid in CITE.findall(line):
                if cid not in ids:
                    errors.append(f"{md.relative_to(ROOT)}:{n}: "
                                  f"unknown ID {cid}")
    return errors


UNSPACED = re.compile(r"\w<\w[^<>\s]*>\w")


def check_render():
    errors = []
    for md in ROOT.rglob("*.md"):
        if ".git" in md.parts:
            continue
        for n, line in enumerate(md.read_text().splitlines(), 1):
            if UNSPACED.search(line):
                errors.append(f"{md.relative_to(ROOT)}:{n}: unspaced "
                              f"co-articulation renders as an HTML tag")
    return errors


def main():
    text = SPEC.read_text()
    errors = check_order(text) + check_citations(text) + check_render()
    for e in errors:
        print(e)
    print(f"{len(errors)} error(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
