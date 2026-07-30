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
      Give the most complete account you can of what this program is.

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

    Intent demands a complete account of what the program is, not merely an
    identifier for it.
    → the identity branch (source artifact) answers "what identifies it" and is
      retained as a valid STABLE_STANCE, but it does not discharge the demand;
    → selects the constitution branch (ASCENT_REQUIRED).
    Active branch:   constitution
    End-to-end path: unique after intent is applied

(Navigation, not a claim that the natural-language compiler must return exactly
one frame. The path is unique; the compilation is not forced to be.)

**Pilot variance — flag now, not at viewpoint 40.** Intent does real
navigation work here: it selects constitution over identity, and the entire
ascent depends on that selection. Intent is therefore a **variance factor** in
the pilot — it must be varied deliberately and logged, not held fixed and its
influence rediscovered later. A different intent ("what identifies this build?")
would rest at STABLE_STANCE with no ascent, from the same viewpoint.

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

## First-run control (fresh model, no context)

**Setup.** The model-visible payload above (Viewpoint + Intent only) was given
to a fresh model with no ascent context, no method, no vocabulary, and no repo
access. *Caveat:* fresh context but same model family — a proxy for, not a
substitute for, a genuinely independent model.

**Result: PASS.** Unprompted, it:

- identified the load-bearing closure and pressed on its sufficiency — *"a claim
  of identity plus a claim of sufficiency … press on the word 'is' … the text is
  one relatum; it is not the relation";*
- generated the polarity in the exact vocabulary the input withheld — *"the
  program as a static artifact … and the program as a dynamic occurrence"; "the
  source text is the score; the execution is the performance";*
- named the cohering center — semantics + implementation + environment as the
  interpreting relation through which text becomes program;
- produced a discriminating consequence — *"run with stdout redirected to
  /dev/null, the very same text produces no visible greeting"* (same source +
  different environment → different behavior).

The static/dynamic inversion appeared as a *move* (grant the strongest reading,
test sufficiency, separate relatum from relation), not merely recalled as a
conclusion. This is first-case support for the typed-inversion claim.

**Finding — Intent variance, confirmed on run 1.** The leak-free Intent ("the
most complete account of what this program is") is broad enough to open an
articulation the harness-side derivation did not anticipate: the program as a
*cultural/communicative* artifact (*"the canonical first program, a proof the
toolchain is alive"*). So the ascent fiber on this viewpoint is not obviously
size 1 — the pragmatic articulation is a second branch the operational ascent
(`source ≡ behavior`) does not contain. Open question for `KERNEL.md`: does
whole-recovery return a fiber here, and should the bootstrap Intent stay broad
(leak-free, fiber > 1) or be narrowed (risking a behavior leak)?
