# TSC Architecture

## Purpose

This document explains the architecture of the TSC repo as it exists conceptually.

TSC is organized around three layers:

- **theory**
- **targets**
- **verifier**

This is not yet a claim about the final directory layout.
It is the architectural contract the repo should satisfy.

---

## 1. Theory

The theory lives in `spec/`.

This is the canonical definition layer:
- what TSC is
- what α / β / γ mean
- what witnesses and invariants are
- what a target means

If the verifier and the theory disagree, the theory defines the intended semantics and the verifier is wrong.

---

## 2. Targets

A target is a declared bundle that TSC knows how to measure.

Examples:
- `spec` — canonical theory documents only
- `engine` — current implementation surfaces
- `repo` — aggregate repo target

A target is not "whatever files happen to be nearby."
It is an explicit measurement declaration.

Targets are declared in:
- `targets/*.tsc` — named target manifests (the intended model)
- `targets/registry.tsc` — draft registry that will replace `project.tsc`

The current live measurement config is still `project.tsc`, which the Python orchestrator consumes directly. The target manifests are not yet loaded by tooling.

---

## 3. Verifier

The verifier is the executable layer.

Current state:
- the Python path under `reference/python/` is the active reference implementation

Intended state:
- an OCaml engine becomes the canonical implementation

That means the current Python implementation should be treated as:
- reference
- prototype
- compatibility path

It should not continue to define the repo's future identity implicitly.

---

## 4. Self-measurement

Self-measurement is one target, not the repo's identity.

The self-measurement surfaces exist to answer:
- is the theory coherent as theory?
- is the implementation coherent as implementation?
- is the repo coherent as a whole?

These must be separate targets.

Otherwise one unfinished layer drags down everything and the score stops being informative.

---

## 5. Generated state

Generated measurement state belongs in `.tsc/`.

`.tsc/` is:
- local measurement output
- reports
- generated history

It is not the canonical source of the theory.
It is not the canonical source of the target model.

Those live in:
- `spec/` (theory)
- `project.tsc` (live measurement config)
- `targets/` (intended named-target model)

---

## 6. Immediate architectural direction

The next coherent architecture move is:

1. rewrite the repo charter
2. define named targets
3. keep Python explicitly reference-grade
4. add an OCaml engine only after the target model is stable
5. postpone large physical file moves until meaning is clear

---

## 7. Non-goals

This architecture does not assume:
- immediate repo splitting
- immediate physical re-layout
- that self-measurement should dominate the repo narrative
- that the Python implementation should remain canonical
