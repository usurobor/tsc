# Cleanup cell — contract

This document defines when the `tsc` repository is pristine.

## Standard

Pristine means the repository satisfies the cnos **write skill**
(`cnos.core/skills/write`) at **L7** rigor on every surface: structure, docs,
code comments, tests, examples, and spec prose.

A surface is pristine when a β audit finds none of:

- a word, sentence, paragraph, or section removable without loss;
- a stable fact stated in more than one home;
- a file carrying two governing questions;
- a point that arrives late, behind throat-clearing or setup;
- meaning carried by decorative contrast ("not X, not Y") instead of a positive claim;
- filler transitions, vague intensifiers, or commentary on the act of writing.

## Scope

Cleaning only — signal against noise. This cell changes no behavior, no logic,
no spec meaning, and no version. It cuts noise and gives each stable fact one
home. A change that alters what the code does or what the spec requires is out
of scope and belongs to a separate cell.

## Roles (CCNF, `cleanup` domain, WC class)

- **α** — `usurobor`. Produces the cleanup matter: the drift-removal edits.
- **β** — an independent audit each round (α ≠ β). Reviews the repository
  against the standard above and writes a numbered report to `reviews/`.
- **γ** — closes the cell when a β round returns clean, and records the
  `learning:` block.

## Closure

The cell reaches `accepted` when a β round finds nothing removable across all
surfaces. Each prior round is `repair_dispatch`: β names the noise, α cuts it,
β re-audits. `reviews/` holds every round in order for γ.
