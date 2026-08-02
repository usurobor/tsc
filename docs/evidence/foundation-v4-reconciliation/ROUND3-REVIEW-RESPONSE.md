# Round 3 Review Response — TSC v4 Specification Set

**Review SHA:** `c2871d6aec2ce5e228c4ecd6e56063bcae11cad1`
**Disposition:** all Round 2 findings F15–F23 resolved in this candidate
**Status:** proposed author response; reviewer verdict remains `REQUEST CHANGES` until the resulting repository SHA is reviewed

## Finding disposition

| Finding | Disposition | Change |
|---|---|---|
| F15 | accepted | Added `CONF-COVERAGE-001` and `CONF-STATUS-001`; schema and registry now exercise both. |
| F16 | accepted with scope refinement | Added mandatory `PathContract = EVENTWISE | STATE_LINKED(pole_of)`. Role succession is expressible and testable without forcing every emission stream to be a state path. |
| F17 | accepted | The Set universe now closes explicitly under nonempty finite sequences. |
| F18 | accepted | `beh_c` is defined by explicit one-step and recursive equations. |
| F19 | pushed back as a semantic defect; clarified mechanically | The previous implication already had the correct direction. It is now also stated as relation inclusion `J₁⊆J₂ ⇒ (≃^{J₂})⊆(≃^{J₁})`, making the equivalence explicit. |
| F20 | accepted | Model refutation now references completed aggregate `γ.status = LAW_VIOLATION`, whose definition already encodes identification or complete exhaustion of alternatives. |
| F21 | accepted with ownership correction | C≡ §6 solely owns mathematical `SET_FINAL` applicability; `FND-FINAL-002` owns its proof; Core records evidence and Operational enforces it without restating the conditions. |
| F22 | accepted | Added `CORE-AUTH-001`; A9 now states that Core's normative schema contains no standing, verdict, or boundary authority. |
| F23 | accepted under F16, with phase separation | `PATH_CONTRACT_UNDECLARED` is a compile refusal. `PATH_COHERENCE_VIOLATION` is data-dependent and therefore a runtime refusal, with the same stable code used when a static trace can already establish the mismatch. |

## Path-contract decision

The review correctly found that the prior text asserted role succession without connecting emitted events. The proposed universal fix `π:X→P` is valid for transition-like generators, but not every generator uses an articulation pole as its concrete state identity.

The foundation therefore requires an explicit choice:

```text
EVENTWISE
  every output is a typed event;
  no consecutive-path claim

STATE_LINKED { pole_of : X → P }
  c(x,i)=(a,x') requires:
  src(a)=pole_of(x)
  dst(a)=pole_of(x')
```

This makes the glider-style succession claim rigorous while preserving observation generators whose events are related through another atlas or diagram rather than through state identity. The exact behavior section also proves that a state-linked generator's behavior map lands in the path-coherent behavior predicate `Path_I`; the ambient final coalgebra remains the correct eventwise final object.

## Authority and finality ownership

The mathematical hypotheses for the canonical Set final coalgebra occur once, in C≡ §6. Core's `SET_FINAL` variant carries only applicability evidence against that semantic contract. Operational enforces it, while `FND-FINAL-002` tests the enforcement without becoming part of the Core data type. This removes three normatively drifting copies without creating a foundation-to-runtime dependency.

## Conformance self-application

The proof authority is now subject to its own permanent obligations. Its validator must establish requirement/fixture closure and must reject fixture status that outruns evidence. These requirements themselves are covered by the registered foundation fixture, producing a finite auditable closure rather than an unenforced release paragraph.

## Review boundary

All normative specifications remain `Draft`. This response does not claim approval. The next β round should read the exact resulting SHA, including the informative glossary, and verify the ratification-only step only after the substantive findings are closed.
