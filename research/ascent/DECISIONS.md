# Articulation Ascent — foundational decisions

**Status:** Experimental design authority
**Scope:** Decisions governing the pre-normative ascent kernel
**Date:** 2026-07-30

## D-001 · C≡ surface arity and frame construction

**Status:** Decided

### Question

How should the following expressions be parsed?

    ≡
    I ≡ AM
    ≡ ≡ ≡
    (I ≡ AM) (lim ≡ ∞) (1 ≡ 0)

Three candidate readings were considered:

1. `FLAT-JUXTAPOSITION`
2. `NESTED`
3. `ARITY-OVERLOADED`

### Decision

Adopt `FLAT-JUXTAPOSITION`.

The glyph `≡` always denotes an unarticulated whole occupying
the role position in which it appears. It is not equality, a separator,
or a ternary operator.

Exactly three juxtaposed terms construct one role frame:

    Frame(left, center, right)

The historical role glosses are:

    left    — coherer-role
    center  — cohering-role
    right   — cohered-role

These are structural roles. They do not assign agency, causality,
or activity to one component by syntax alone.

### Surface grammar

    Expr  ::= Term
            | Term Term Term

    Term  ::= "≡"
            | Label
            | "(" Expr ")"

The canonical intermediate representation is:

    Whole
    Label(name)
    Frame(left, center, right)

### Derived polar form

A source expression:

    x ≡ y

contains exactly three terms:

    x    ≡    y

and therefore compiles to:

    Frame(
      left   = x,
      center = Whole,
      right  = y
    )

The center is unarticulated, not absent.

A polar form is therefore an open frame whose cohering role remains
to be inhabited during execution.

### Full frame

The source:

    x y z

compiles to:

    Frame(x, y, z)

No glyph acts as a separator between the roles.

### Founding derivation

The canonical founding presentation is:

    ≡

    ≡ ≡ ≡

    (I ≡ AM) (lim ≡ ∞) (1 ≡ 0)

Its canonical representation is:

    Whole

    Frame(
      Whole,
      Whole,
      Whole
    )

    Frame(
      Frame(I, Whole, AM),
      Frame(lim, Whole, ∞),
      Frame(1, Whole, 0)
    )

The third line is a flat outer role frame whose three occupants are
themselves open polar frames.

### Invalid form

The historical spelling:

    (I ≡ AM) ≡ (lim ≡ ∞) ≡ (1 ≡ 0)

contains five top-level terms under the uniform grammar and is invalid.

It must not be accepted by:

- treating binary and ternary `≡` differently;
- silently choosing left or right association;
- flattening the terms;
- using the glyph as a separator.

If nesting is intended, it must be parenthesized explicitly.

### Consequences

- `≡ ≡ ≡` is `Frame(Whole, Whole, Whole)`.
- `I ≡ AM` is `Frame(I, Whole, AM)`.
- `≡ I AM` is well formed and means `Frame(Whole, I, AM)`.
- `I AM ≡` is well formed and means `Frame(I, AM, Whole)`.

These are not misspellings of `I ≡ AM`. Each places the unarticulated
whole in a different role and therefore leaves a different articulation
problem open.

The three open positions correspond to three operations:

    centre open  — recover the cohering:  `A ≡ B`
    left open    — recover the source:    `≡ A B`   (polar lift)
    right open   — generate the result:   `A B ≡`   (articulation descent)

Restricting the hole to the centre would remove descent from the
language.

- Position is semantic and preserved in the canonical representation.
- Swapping left and right changes the program by default.
- Every `≡` occurrence receives its own node and role address.
- Nested frames may not be reduced to an unordered label multiset.

### Reason

The decision gives the glyph one uniform meaning at every depth,
preserves the historical left/center/right semantics, keeps the center
as an explicit typed hole, and avoids the five-position ambiguity created
by treating `≡` as both center and separator.
