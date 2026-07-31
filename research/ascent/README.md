# Articulation Ascent

Articulation Ascent is the primary research program for the current bounded sprint. It is pre-normative: nothing here binds an implementation, and its program vocabulary is its own until the specification adopts it.

## Governing question

Starting from a single point of view, and given no polar pair in the input, can the method autonomously compile a frame, invert its load-bearing closure, and produce a *non-decorative* higher articulation — one that carries a warrant and draws distinctions the starting view could not?

TSC supplies the warrant infrastructure (candidate fibers, comparison, warrant classes, refusal, and evidence lineage). C≡ supplies the expression language. See [`../../STATUS.md`](../../STATUS.md) for how this program sits against the rest of the project.

## What is decided

Foundational decisions live in [`DECISIONS.md`](DECISIONS.md).

- **D-001 — C≡ surface arity and frame construction.** Adopt `FLAT-JUXTAPOSITION`: the glyph `≡` always denotes an unarticulated whole occupying its role position, and exactly three juxtaposed terms build one role frame `Frame(left, center, right)`. A polar form `x ≡ y` compiles to `Frame(x, Whole, y)` — an open frame whose center is unarticulated, not absent.

## What is still open

- Whether whole-recovery returns a fiber (more than one warranted articulation) on a broad, leak-free intent, and whether the bootstrap intent should stay broad or be narrowed — surfaced by the Trace 000 control run.
- The kernel itself: `KERNEL.md` is not yet written (see the trigger below).
- Future planes — an executable package (`src/…/ascent/`) and its conformance — recorded in the [repository-planes ADR](../../docs/architecture/decisions/repository-planes.md) and deferred until the method is executable.

## Traces

Traces are hand-run vertical slices of the mechanism, kept under [`traces/`](traces/).

- **[`000-hello-world.md`](traces/000-hello-world.md) — active.** The smallest end-to-end slice: one viewpoint, one closure, one derived polarity, one inhabited center, one whole, one executable oracle. It is the kernel's unit test. Its fresh-model control run **passed**: given only the leak-free viewpoint and intent, a fresh model derived the `source ≡ behavior` polarity, named the cohering center, and produced a discriminating consequence — without being handed the withheld vocabulary.
- **[`001-machine-human-turing.md`](traces/001-machine-human-turing.md) — deferred.** A stress trace on an AI-relevant viewpoint (machine imitation versus genuine thought). Deferred until the bootstrap kernel is fixed, so the harder case tests a settled mechanism rather than co-evolving with it.
- **[`002-hard-soft-flickering.md`](traces/002-hard-soft-flickering.md) — deferred.** A formal-calibration case aimed at a strong `FORMAL_PROOF` warrant and a migration audit that can reach contradictory residue. Deferred for the same reason.

## What triggers `KERNEL.md`

Trace 000 writes `KERNEL.md` v0.1 only if its derivation survives one audit question: did the procedure *derive* `behavior` and `evaluation` from the source-exhaustiveness closure, or did it merely restate programming-language semantics already known? A surviving derivation fixes the bootstrap kernel, and the deferred traces then run against it.
