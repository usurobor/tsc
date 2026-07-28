# TSC Conformance v4.1 — Proof Obligations

**Version:** 4.1.0
**Status:** Draft
**Artifact:** Normative proof authority

## Governing question

> What must an implementation, methodology, and fixture prove before it may claim conformance with TSC 4.1?

The semantic specifications define what TSC means. This document defines how those claims are tested. Every requirement has a stable ID, an owning specification, a positive oracle, and a negative oracle.

A requirement is not satisfied by prose, a scalar, or a passing example that cannot fail.

## 1 · Conformance evidence

A conformance claim contains:

```text
requirement id
implementation or artifact digest
fixture id and version
proof class
positive result
negative result
raw evidence references
replay command or derivation
review status
```

### 1.1 Proof classes

```text
typecheck
proof
property
model
integration
artifact parity
security boundary
independent review
```

The proof class matches the claim strength.

### 1.2 Fixture contract

A conformance fixture declares:

```text
fixture id and version
status = specified | implemented | verified
domain
requirements covered
generator or constructor
independent oracle
model class and equivalence
search claims and explicit bounds/protocols
positive and negative cases
held-out or intervention boundary
reproducibility contract
expected categorical result
```

Domain fixtures live outside `spec/`. The specification states obligations, not domain laws.

### 1.3 Result states

```text
PASS
FAIL
UNRESOLVED
NOT_RUN
```

A `specified` fixture has no result and contributes no conformance standing.

## 2 · Foundation requirements

### FND-TYPE-001 — Dependent articulation typing

**Owner:** `c-equiv.md` §1

**Positive:** `art(s,φ,o)` typechecks when `φ : Rel(s,o)`.

**Negative:** moving `φ` into either pole position, or attaching it to different endpoints without declared transport, is rejected.

### FND-PATH-001 — Typed composition

**Owner:** `c-equiv.md` §2

**Positive:** composable relations preserve intermediate poles and produce a well-typed composite.

**Negative:** mismatched intermediate poles cannot compose.

### FND-PATH-002 — Declared role succession

**Owner:** `c-equiv.md` §§3.3, 9.3; `tsc-oper.md` §§3, 5, 7

**Positive:** an `EVENTWISE` generator makes no intrinsic cross-step path claim; a `STATE_LINKED(pole_of)` generator whose emitted endpoints match current and successor state poles produces a composable path. A β atlas may relate `EVENTWISE` emissions while the generator remains `EVENTWISE`.

**Negative:** a generator that claims intrinsic role succession without a path contract, or whose `STATE_LINKED` emission violates either endpoint equation, fails with:

```text
PATH_CONTRACT_UNDECLARED
PATH_COHERENCE_VIOLATION
```

An `EVENTWISE` presentation whose receipt relabels atlas-level connectivity as intrinsic generator succession also fails conformance; the relation remains in β and the generator remains `EVENTWISE`.

### FND-FUNCTOR-001 — Complete deterministic Set functor

**Owner:** `c-equiv.md` §4

**Positive:** object action, morphism action, identity law, and composition law are checked; the coalgebra-morphism square typechecks.

**Negative:** an implementation that defines only `F_I(Y)` and uses `F_I(h)` without a morphism action fails.

Expected refusal when compiled as a CM:

```text
COMPILE_REJECTED(FUNCTOR_INCOMPLETE)
```

### FND-FINAL-001 — Exact Set final behavior

**Owner:** `c-equiv.md` §5

**Positive:** for deterministic Set presentations in one declared universe, `Art^(I+)`, `ζ`, `beh_c`, the commuting law, and uniqueness are established.

**Negative:** a claimed `SET_FINAL` implementation with a different behavior object and no isomorphism or finality proof fails.

### FND-FINAL-002 — SET_FINAL applicability

**Owner:** `c-equiv.md` §6; enforcement: `tsc-oper.md` §3 through this requirement

**Positive:** a deterministic CM with real-valued `X`, `I`, and `Art` may use `SET_FINAL` when all are Set objects in one declared universe and the canonical functor is used.

**Negative:** `SET_FINAL` is rejected when:

```text
a carrier is not a Set object in the declared universe;
required universe evidence is absent;
the CM substitutes a noncanonical functor;
a stochastic or nondeterministic kernel is used without reifying randomness
or choice as declared deterministic input or state.
```

Expected refusal:

```text
COMPILE_REJECTED(SET_FINAL_INAPPLICABLE)
```

### FND-FINAL-003 — General finality completeness

**Owner:** `tsc-core.md` §3; `tsc-oper.md` §3

**Positive:** `GENERAL_FINAL` supplies carrier category, object action, morphism action, functor laws, pointed-state contract, articulation interface, behavior object, and finality witness.

**Negative:** an incomplete claim fails with the appropriate refusal:

```text
INITIAL_STATE_WITNESS_MISSING
ARTICULATION_INTERFACE_MISSING
FUNCTOR_INCOMPLETE
FUNCTOR_LAWS_UNPROVED
FINALITY_UNSUPPORTED
```

### FND-SHAPE-001 — Commutative-fold blindness

**Owner:** `c-equiv.md` §8

**Positive:** a shape-sensitive evaluator distinguishes equal-leaf-multiset trees with different internal shape by retaining nodes or paths.

**Negative:** an associative commutative leaf fold may not claim depth, order, grouping, or path sensitivity.

### FND-ROLE-001 — Role-preserving symmetry

**Owner:** `c-equiv.md` §9

**Positive:** serialization reorder preserves role labels, endpoints, relation typing, and decoded event.

**Negative:** free semantic permutation of source, relation, and result is rejected.

### FND-POLAR-001 — Polar syntax is not equality

**Owner:** `c-equiv.md` §§0.1–0.2

**Positive:** `1 ≡ 0` parses canonically as `Dim(LabelTerm(1),LabelTerm(0))`; the exact three-line foundational expression parses to `Whole`, `Frame(Whole,Whole,Whole)`, and the declared nested frame AST.

**Negative:** interpreting `≡` as arithmetic equality, logical identity, a directed event, or an ambiguous binary chain fails conformance.

### FND-POLAR-002 — Nested shape retention

**Owner:** `c-equiv.md` §§0.3–0.4

**Positive:** `Dim(Dim(1,0),Dim(lim,∞))` retains four label nodes and three distinct dimension nodes through parsing, canonical serialization, elaboration, and receipt projection.

**Negative:** a commutative fold, flattening, reassociation, or unordered multiset representation that loses any dimension node fails conformance.

### FND-POLAR-003 — Orientation and reversal honesty

**Owner:** `c-equiv.md` §§0.3, 1.6

**Positive:** projective and inclusive dimension nodes are separately typed; explicit root reversal swaps the two boundary subtrees, preserves their internal orientation, and is involutive.

**Negative:** treating projective and inclusive nodes as one untyped flag, silently equating `Dim(x,y)` with `Dim(y,x)`, or using reversal as semantic equivalence without a witness fails conformance.

### FND-POLAR-004 — Grounding is forgetful only

**Owner:** `c-equiv.md` §0.5

**Positive:** every polar term has the same grounding value while its structural AST remains unchanged and separately retained.

**Negative:** grounding used to justify equality, substitution, flattening, realization, identification, or standing fails conformance.

### FND-POLAR-005 — Structural admissibility is non-vacuous

**Owner:** `c-equiv.md` §§1.6–1.7

**Positive:** a raw typed elaboration becomes structurally admissible only through a declared label and Whole interpretation, constructor policy, structural candidate class, nondegeneracy predicate, boundary-faithfulness rule, and structural equivalence; at least one negative case is executable.

**Negative:** raw initial, terminal, empty, singleton, lookup, monic, or epic cones/cocones admitted by existence alone fail conformance.

### FND-FRAME-001 — Frame elaboration is explicit

**Owner:** `c-equiv.md` §§0.2, 1.8; `tsc-core.md` §2.0

**Positive:** a three-role frame preserves all three polar terms and carries a declared typed frame witness plus role-to-witness bridges.

**Negative:** silently coercing the cohering polar term into `Rel(root(coherer),root(cohered))`, parsing a frame as binary association, or dropping a role term fails conformance.

### FND-CONSERVATIVE-001 — v4.0 conservative embedding

**Owner:** `c-equiv.md` §1.9; `tsc-core.md` §2.0

**Positive:** every valid typed v4.0 presentation and receipt remains valid with `polar_source = none` and retains identical generator, behavior, receipt, standing, and authority semantics.

**Negative:** making a polar source mandatory, changing a no-polar-source classification, or reinterpreting a historical v4.0 receipt as polar evidence fails conformance.

## 3 · Core requirements

### CORE-PRESENTATION-001 — Truthful presentation kind

**Owner:** `tsc-core.md` §§1, 3; `tsc-oper.md` §3

**Positive:** a deterministic `X × I → Art × X` candidate uses `SetPresentation`; a stochastic kernel uses a declared `GeneralPresentation` with functor, pointed-state contract, and typed articulation interface, unless randomness is explicitly reified into a deterministic Set presentation.

**Negative:** a stochastic or nondeterministic kernel declared as canonical `SET_FINAL` without such reification fails with `SET_FINAL_INAPPLICABLE`; a general presentation missing its point or articulation interface fails closed.

### CORE-EVIDENCE-001 — Manifestation validity

**Owner:** `tsc-core.md` §7.1

**Positive:** complete, grounded observations produce `α = VALID`.

**Negative:** missing required evidence produces `α = INCOMPLETE`; no coherence disposition is emitted as though the evidence were complete.

### CORE-RECEIPT-001 — Typed non-substitutability

**Owner:** `tsc-core.md` §§6–7

The three receipts have distinct schemas and proof obligations.

**Positive dependency path:**

```text
α VALID
  → β may complete
β establishes an applicable candidate
  → γ may complete
```

**Negative A:**

```text
α INCOMPLETE
β BLOCKED_BY(α-validity)
γ BLOCKED_BY(α-validity)
overall UNRESOLVED
```

**Negative B:**

```text
α VALID
β globalization failure
γ BLOCKED_BY(β-realizability)
```

Local trajectories may remain evidence; they cannot become an authoritative γ pass for a common generator that β did not establish.

**Negative C:**

```text
α VALID
β IDENTIFIED_IN_MODEL
γ LAW_VIOLATION
overall REFUTED_IN_MODEL
```

No receipt may discharge another receipt's proof obligation.

### CORE-JOINT-001 — Joint generator-atlas realization

**Owner:** `tsc-core.md` §§2.7–2.10, 5; `tsc-core.md` §7.2

**Positive:** every candidate fiber ranges over `R = (G,A)`, retaining the concrete generator and the atlas that relates it to observations. Fit, complexity, equivalence, oracle results, and identification are well defined on the joint realization or carry a proof that a projection is sufficient.

**Negative:** a methodology that selects a map during fitting, builds the candidate fiber over bare `G`, and discards atlas alternatives fails receipt and identification conformance.

### CORE-POLAR-001 — Polar realization classification

**Owner:** `tsc-core.md` §§2.0, 2.6, 2.8–2.10, 5.5.1

**Positive:** the Core polar realization contract combines C≡ structural admissibility with a declared polar candidate class, complete applicable search, complexity and fit contributions, held-out or intervention oracle, target, and equivalence. Zero surviving classes yields `NO_REALIZATION_IN_MODEL`, several yields `UNDERDETERMINED`, and one yields scoped `IDENTIFIED_IN_MODEL` for the declared target.

**Negative:** raw or merely structurally admissible elaborations counted as measurement realizations, incomplete search reported as absence, or grounding reported as identification fails conformance.

### CORE-POLAR-002 — Polar evidence remains in the β atlas

**Owner:** `tsc-core.md` §§2.7–2.9, 7.2, 8 A3, 12

**Positive:** the receipt retains the canonical polar AST, node-to-pole assignments, boundary legs, raw elaborations, structurally admissible elaborations, measurement-admitted and rejected candidates, frame witnesses, bridges, search evidence, and content-addressed references.

**Negative:** a scalar, root pole, accepted realization, or best-fit residual replacing the polar tree, rejected alternatives, or maps fails conformance.

### CORE-REALIZE-001 — Realizability, budget, and test failure

**Owner:** `tsc-core.md` §§5, 9

**Positive A:** a complete search proving `C_M^fit` empty yields training `NO_REALIZATION_IN_MODEL` with budget and identification `NOT_ESTABLISHED`.

**Positive B:** fitting realization candidates with none inside the complexity bound yield `REALIZABLE_IN_MODEL + REALIZABLE_OVER_BUDGET`.

**Positive C:** a nonempty bounded training set whose every fixed realization candidate is in the grounded `FAIL` partition yields `TestStatus.FAILED` and `REFUTED_IN_MODEL` for that model and test regime. It is not relabeled `NO_REALIZATION_IN_MODEL`.

**Negative:** failed heuristic or sampled search yields `UNRESOLVED`; an over-budget fit, unresolved candidate outcome, or incomplete oracle is not relabeled no realization, failed test, or refutation.

### CORE-ID-001 — Input-indexed identification

**Owner:** `c-equiv.md` §7.3; `tsc-core.md` §§2.3, 2.10, 5.5, 9.5

**Positive:** every `IDENTIFIED_IN_MODEL` field names its regime (`training` or `tested`), identification target, passive and active input families, equivalence, model class, bounds, and search claims. A held-out refinement may preserve training `UNDERDETERMINED` beside tested `IDENTIFIED_IN_MODEL` only when every nonpassing bounded candidate has a terminal `FAIL`; unresolved alternatives make tested identification `NOT_ESTABLISHED`.

**Negative:** identification without a declared regime, target, or input/intervention family is rejected.

### CORE-EQUIV-001 — Well-defined input-indexed quotient

**Owner:** `tsc-core.md` §§2.9, 5

**Positive:** joint realization candidates are filtered before quotienting; fit, complexity, and oracle outcomes are congruent with the declared equivalence; a wider input family records a refinement map from finer tested classes to coarse training classes.

**Negative:** quotienting before a presentation-sensitive complexity check, or assigning different oracle outcomes inside one declared test-equivalence class, produces `UNRESOLVED` and fails identification conformance.

### BETA-SEARCH-001 — Relation-search accountability

**Owner:** `tsc-core.md` §§2.6–2.7; `tsc-oper.md` §5

**Positive:** β retains relation search claim, solver identity, maps considered, alternatives, pruning reasons, parameters, uncertainty, and orchestration with generator search.

**Negative:** selecting one best map, emitting only a residual, and discarding alternatives or search conditions fails conformance.

### CORE-GLOBAL-001 — Globalization

**Owner:** `tsc-core.md` §§7.2, 8

**Positive:** a full-diagram criterion establishes one compatible atlas.

**Negative:** pairwise-compatible maps that fail the declared globalization rule do not produce support.

### CORE-REFINE-001 — Evidence refinement

**Owner:** `tsc-core.md` §§5.6, 10.1; `tsc-observation-dynamics.md` §6

**Positive:** independent evidence removes presentations or splits equivalence classes in a fixed fitted set, with a retained refinement map and no refitting.

**Negative:** changing candidate parameters, model class, declared input language, or tested boundary while calling the operation refinement fails.

### CORE-LIFT-001 — Severe model lift

**Owner:** `tsc-core.md` §§10.2–10.4; `tsc-observation-dynamics.md` §7

**Positive:** a preregistered class or boundary change reproduces a baseline failure, survives complexity cost, meets the acceptance margin, and predicts held-out evidence.

**Negative:** a larger model that only improves training fit does not validate a lift.

### CORE-LAW-001 — Law-relative stochastic coherence

**Owner:** `tsc-core.md` A7

**Positive:** a stochastic trace compatible with its declared stochastic law may be supported.

**Negative:** visual disorder alone cannot serve as a universal incoherence oracle.

### CORE-TERM-001 — Lawful termination

**Owner:** `tsc-core.md` §7.3

**Positive:** an identified candidate, or every surviving candidate in a complete set, ending under a preregistered termination rule produces `LAWFUL_TERMINATION`.

**Negative:** disappearance is not automatically law violation or coherence degradation; one terminating candidate among mixed lawful alternatives does not establish universal termination.

### CORE-SCALAR-001 — Receipt primacy

**Owner:** `tsc-core.md` §§8, 11–12

**Positive:** every scalar points to a complete structured receipt and stays within its declared categorical status.

**Negative:** a scalar-only result fails conformance and cannot override fiber, law, standing, or authority status.

### CORE-AUTH-001 — Core authority neutrality

**Owner:** `tsc-core.md` A9; `tsc-oper.md` §2

**Positive:** a Core receipt classifies evidence and may later be wrapped by Operational standing, verdict, and boundary artifacts without changing the Core receipt.

**Negative:** a Core-only receipt schema that grants standing, emits an admission verdict, or performs a boundary decision fails conformance.

## 4 · Operational requirements

### OPER-AUTH-001 — Authority separation

**Owner:** `tsc-oper.md` §§1–4

**Positive:** compiler, CM0, `V`, `δ`, and runtime emit distinct artifacts.

**Negative:** compilation alone cannot admit, authorize, or issue a target verdict; CM0 cannot admit itself.

### OPER-BEHAVIOR-001 — Behavior contract enforcement

**Owner:** `tsc-oper.md` §3

**Positive:** every compiled CM has a valid `FinalityBasis` and `BehaviorAccess`; `NO_FINALITY_CLAIM` may use an explicit construction without claiming finality.

**Negative:** undeclared or unsupported modes fail closed; no silent final-to-finite fallback occurs; a no-finality CM cannot invoke Lambek or universal uniqueness.

### OPER-POLAR-001 — Polar compilation fails closed

**Owner:** `tsc-oper.md` §§3.1.1, 3.3, 5.4–5.5, 7

**Positive:** the compiler canonicalizes polar syntax, binds realization and frame contracts, retains shape, and the runtime carries candidate and refusal evidence into β.

**Negative:** malformed or ambiguous syntax, missing orientation/search/nondegeneracy/frame declarations, implicit relation coercion, grounding misuse, or silent flattening emits a stable refusal and no measurement receipt claiming success.

### OPER-INPUT-001 — Complete input boundary

**Owner:** `tsc-oper.md` §§5, 7

**Positive:** required evidence produces a content-addressed coverage manifest.

**Negative:** empty, missing, unreadable, out-of-root, cyclic, or framing-breaking input produces a refusal receipt before classification.

### OPER-STANDING-001 — Standing and verdict authority

**Owner:** `tsc-oper.md` §6

**Positive:** earned standing and verdict authority name their scope and evidence.

**Negative:** failed or absent standing cannot produce a verdict-bearing result.

### OPER-RECEIPT-001 — Terminal receipt

**Owner:** `tsc-oper.md` §§4.9, 9

**Positive:** success, refusal, unresolved, provider failure, resource failure, and law violation all emit receipts.

**Negative:** no terminal path is silent or represented as an empty success.

## 5 · Observation Dynamics requirements

### OBS-COMPARE-001 — Compatibility before comparison

**Owner:** `tsc-observation-dynamics.md` §5

**Positive:** compatible receipts compare under one declared relation with dependence and uncertainty.

**Negative:** incompatible methodologies or behavior contracts produce `INCOMPARABLE`.

### OBS-POLAR-001 — Polar compatibility and lift

**Owner:** `tsc-observation-dynamics.md` §§2, 5–7, 10

**Positive:** directly compared receipts agree on polar source, C≡ admissibility contract, Core realization contract, frame contract, and search semantics or carry a validated transport; changing any load-bearing polar contract is classified as a lift.

**Negative:** comparing incompatible polar trees/contracts directly, relabeling a changed polar source as evidence refinement, or dropping prior rejected realizations and failures from lineage fails conformance.

### OBS-HOLDOUT-001 — Holdout integrity

**Owner:** `tsc-observation-dynamics.md` §§1, 7–8

**Positive:** a held-out or intervention item has provenance independent of the fitting path under the declared boundary.

**Negative:** a post-hoc query cannot be relabeled held out.

### OBS-DEPEND-001 — Dependence and coverage

**Owner:** `tsc-observation-dynamics.md` §4

**Positive:** overlap and shared sources are represented in the dependence graph.

**Negative:** overlapping evidence is not treated as independent by default.

### OBS-APPROX-001 — Bound approximation

**Owner:** `tsc-core.md` §4; `tsc-observation-dynamics.md` §3

**Positive:** every path ledger references one Core approximation-contract digest and shows local budgets, composed budget, endpoint distance, and compatibility.

**Negative:** Observation Dynamics cannot redefine a second tolerance algebra or compare receipts with incompatible contracts.

### OBS-LINEAGE-001 — Failure persistence

**Owner:** `tsc-observation-dynamics.md` §9

**Positive:** a later system disposes of a prior failed receipt as `RESOLVED`, `CLAIM_WITHDRAWN`, `SUPERSEDED`, `INVALIDATED`, or `UNRESOLVED` with evidence.

**Negative:** removing or replacing a failed claim without a disposition record fails conformance.

A successor claim receives no inherited standing from the disposed claim.

## 6 · External fixture registry

Conformance fixtures are registered under:

```text
conformance/registry.toml
```

and validated against:

```text
schemas/conformance-fixture.cue
```

The registry cites fixtures by ID. Domain semantics remain in the fixture package, not this specification.

The initial registry contains:

```text
foundation-v4
  foundation, Core, Operational, comparison, and lineage proof pairs

gol-ascent-0
  exact-domain cases for underdetermination, refinement, lift, law violation,
  and lawful termination

stochastic-law-v4
  law-relative stochastic compatibility and violation

polar-syntax-v4-1
  parser, ordered AST, nesting, grounding, frame, and conservative-embedding proof pairs

polar-realization-v4-1
  non-vacuity, candidate-fiber, receipt, runtime, comparison, and lift proof pairs
```

A fixture contributes standing only when its status is `verified` and its raw evidence is reproducible.

## 7 · Conformance self-application

### CONF-COVERAGE-001 — Requirement and fixture closure

**Owner:** this document §§1, 6, 7

**Positive:** every requirement ID is referenced by at least one registered fixture with both a positive and a negative case, and every fixture requirement reference resolves to an existing ID.

**Negative:** an orphan requirement ID, dangling fixture reference, duplicate requirement ID, or missing polarity fails conformance validation.

### CONF-STATUS-001 — Evidence-bound fixture status

**Owner:** this document §§1.2–1.3; `schemas/conformance-fixture.cue`

**Positive:** `verified` status carries reproducible PASS evidence, its digest and replay command, and an immutable independent-review reference with PASS result.

**Negative:** a fixture labeled `verified` without either replayable PASS evidence or independent immutable PASS review fails schema and registry validation; a `specified` fixture carrying evidence or verification also fails.

## 8 · Specification ratification and implementation conformance

Specification ratification and implementation conformance are separate claims.

TSC 4.1 may change from `Draft` to `Normative` when:

```text
every semantic layer is internally complete and cross-referenced;
every conformance requirement has an owner and positive/negative oracle;
registered fixture contracts cover every requirement without claiming unrun results;
consumer and implementation-status surfaces are truthful;
independent mathematical and document review reports zero unresolved findings;
a ratification-only commit changes the normative headers;
that final commit is reviewed before merge.
```

Ratification makes the specification authoritative. It does not grant conformance to an engine or methodology.

An implementation may claim TSC 4.1 conformance only when the applicable registered fixtures are `verified`, their positive and negative evidence is reproducible, and every required receipt is bound to the reviewed implementation digest.
