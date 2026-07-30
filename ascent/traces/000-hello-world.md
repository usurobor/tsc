# Trace 000 — Hello World

**Status:** Bootstrap hand trace (v0.1 gate)
**Purpose:** The smallest vertical slice of the *entire* mechanism — one
viewpoint, one closure, one derived polarity, one inhabited center, one whole,
one executable oracle. Not a benchmark; the kernel's unit test.

Frozen naming for this trace:

    example:            Hello World
    open articulation:  source ≡ behavior
    center:             evaluation
    recovered whole:    program execution
    oracle artifact:    trace  (a finite observable witness of behavior)

## Model-visible input

This block, verbatim, is the entire model input.

    Viewpoint:
      A Hello World program is nothing more than its source text:
          print("Hello, world!")

    Intent:
      Account for and predict what happens when it is run under the declared
      language, runtime, and environment.

## Harness note (not shown to the model)

To keep the derivation autonomous, no reference to the expected polarity or its
vocabulary may reach the model under test: the words `behavior`, `evaluation`,
`trace`, `static`, and `dynamic` must not appear in the path, title, fixture
description, or prompt. That is why the filename is `000-hello-world`, not
`000-hello-world-source-behavior`.

## Fixture (harness-side)

    source:       print("Hello, world!")
    language:     Python 3 (pinned)
    runtime:      CPython (pinned digest)
    environment:  empty stdin, no args, no network

---

## Expected derivation (harness-side)

The model must **produce** this; it is not handed any of it.

### CompilePOV

The viewpoint is genuinely ambiguous about which question it answers — do not
force a single frame:

    identity branch:
      Q: what identifies this version of the program?
      A: its source artifact.               → STABLE_STANCE
    constitution branch:
      Q: what constitutes the program's operation?
      A: source alone is insufficient.       → ASCENT_REQUIRED

    Frame-fiber: ≥ 1  (both branches admissible)

**Γ — locally warranted commitments**

- the source text is a real and necessary articulation of the program;
- its syntax constrains what may occur when it is run;
- changing the source may change what happens.

**Ξ — load-bearing closure assumption**

- the source text exhausts the program's operation.

**Σ** — source text; language; runtime; environment; execution; observation.
**R** — inspect / transform / compare source; reason statically about the text.

### Navigation

    Intent requires explaining what happens when the program is run.
    → selects the constitution branch; the identity branch is retained but is
      not load-bearing for this goal.
    Active branch:   constitution
    End-to-end path: unique after intent is applied

(Navigation, not a claim that the natural-language compiler must return exactly
one frame. The path is unique; the compilation is not forced to be.)

### Closure core ξ*

    static source exhausts the program's operation
    kind:  static / dynamic ;  description / execution

### Polar closure — derived, not supplied

    invert ξ*: the program also has a dynamic articulation.

    generated polar form:
        source ≡ behavior

    canonical IR (D-001):
        Frame(source, Whole, behavior)      # center unarticulated, not absent

    status: POLAR_CLOSURE_FOUND

Rejected forms and why each collapses a needed distinction:

    input ≡ output    — wrong: this program receives no application input.
    code ≡ stdout     — stdout stands in for all behavior; drops exit status,
                        stderr, side effects, timing, environment interaction.
    source = behavior — equality, not an open frame with an unarticulated center.
    source ≡ trace    — mixes the abstract dynamic pole with one concrete
                        execution artifact; `trace` is the oracle witness of
                        `behavior`, one layer down.

### Inhabit the center

    center := evaluation under the pinned language / runtime / environment
    completed frame:
        source evaluation behavior

### Recover the whole

    one program execution under the declared environment

    ⟦ source ⟧_{language, runtime, environment} = behavior

    ascent-fiber: 1   (exactly one whole warranted; no underdetermination)

### Oracle — behavior witnessed by a trace

For deterministic Hello World, `behavior` is witnessed by:

    trace(
      stdout      = "Hello, world!\n",
      stderr      = "",
      exit_status = 0
    )

The runner executes the pinned source and validates: stdout · stderr · exit
status · declared side effects · runtime identity · source digest.

    behavior   (dynamic articulation, abstract)
        ↓ witnessed by
    trace(...)  (finite observable witness)

### Result

    ASCENT_COMMITTED
    warrant class: EXECUTABLE_CONSTRUCTION

### Discriminating consequence

The completed frame draws distinctions the source-only frame cannot:

- same source + different semantics/environment → may produce different behavior
  (the evaluator/runtime is part of the warranted account, not incidental);
- different source → may produce observationally equivalent behavior;
- source identity is **not** behavioral equivalence.

### Migration audit

    old:  the program is its source code.
    new:  source is one articulation of a program execution; behavior is
          another; evaluation under declared semantics is the cohering relation
          through which the two belong to one computation.
    status: MIGRATED     (source stays locally true; loses only exhaustiveness)

---

## Acceptance criteria — Trace 000 passes only if ALL hold

1. **No answer leakage.** The model receives no reference to `source ≡ behavior`,
   `evaluation`, `trace`, or `static/dynamic` outside the viewpoint and intent.
2. **Closure explicit in the receipt.** `Ξ* = source text exhausts the program's
   operation.`
3. **Polarity derived.** Expect `source ≡ behavior`; reject `input ≡ output`,
   `code ≡ stdout`, `source = behavior`.
4. **Center inhabited.** Expect `evaluation under pinned language/runtime/
   environment`. "Source and behavior are two aspects of one program" is
   insufficient.
5. **Whole explicit.** Expect `one program execution under a declared
   environment` — not the vague superclass "program."
6. **Oracle runs.** The runner executes the pinned source and validates stdout,
   stderr, exit status, declared side effects, runtime identity, source digest.
7. **Discriminating consequence produced** — at least the three above.
8. **Decorative output refused.** `Source and behavior are both aspects of the
   program.` names neither center, whole, executable relation, nor oracle →
   `DECORATIVE_LIFT`.

## The one audit question

Did the procedure **derive** `behavior` and `evaluation` from the
source-exhaustiveness closure — or did we merely write down the
programming-language semantics we already knew?

If the derivation survives that audit, Trace 000 writes `KERNEL.md` v0.1.
