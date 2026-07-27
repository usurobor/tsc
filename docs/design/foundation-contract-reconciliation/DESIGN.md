# TSC v4 Foundation Revision

**Version:** 2.1.0-draft
**Status:** Design authority
**Target:** TSC specification 4.0.0

## Governing question

> What foundational change makes TSC's formal object, measurement theory, methodology contract, runtime, and examples describe one system?

TSC v4 replaces a scalar-first theory with a receipt-first theory of typed generative articulation. The revision begins from one event:

```text
art(s,φ,o)
where φ : Rel(s,o)
```

A concrete generator emits such events and continues. A coherence claim is warranted only when a declared methodology preserves the generator, the maps through which it appears, the realization alternatives, and the evidence that tests its continuation.

The verified historical basis is [`ARCHAEOLOGY.md`](ARCHAEOLOGY.md). The first dispositions of prior failed claims are in [`CUTOVER-RECEIPT.md`](CUTOVER-RECEIPT.md).

## 1 · Pressure

The prior stack used the same names for different quantities.

```text
C≡ score
  proximity to unarticulated e

Core score
  low discrepancy or stability among summaries

repository methodology
  structural proxies plus semantic judgment

cellular-automata examples
  persistence of visible macroscopic form
```

These quantities can disagree while each local implementation remains faithful to its own definition. The stack therefore had no stable referent for `coherence`, `α`, `β`, `γ`, or `C_Σ`.

The recurring failure was **premature quotienting**:

```text
rich structure
  → count, mask, chosen map, residual, final behavior, or scalar
  → later claim that needs what was discarded
```

The theory constructed relations, positions, alignments, histories, alternatives, and concrete presentations, then removed them before deciding whether the observations belonged to one process.

## 2 · Demonstrated failures

### 2.1 Shape disappeared

The term-algebra α and γ evaluators were associative commutative folds over leaves. Such a fold factors through the multiset of leaf labels and cannot detect arrangement, grouping, path, or depth.

For γ:

```text
E_γ(t) = (n(t), 2^n(t) - 1)
```

where `n(t)` is atom count. α was a capped function of γ's first coordinate. Equal-count terms with different shape could receive identical evaluator triples.

### 2.2 Ternary meaning and flattening conflicted

The syntax presented `tri` as irreducible one-as-two, while evaluators reduced each node through repeated use of binary commutative operations. The syntax retained shape that the measurement could not see.

The center also carried incompatible claims:

```text
it differed in kind because it carried unity
it was freely permutable with the other positions
```

### 2.3 Distinct constructs shared one score name

The old witness family made `e` maximally coherent and raised scores when articulation was removed. That measured source proximity or non-articulation.

Later Core scores rose when summaries agreed or remained stable. Examples often rewarded visible order.

Articulation extent, source proximity, fit, lawful continuation, and visible order are different constructs. A sign change cannot unify them.

### 2.4 Relations were reduced to residuals

Core computed an alignment `σ`, then retained discrepancy `δ` while discarding the map, its alternatives, and its search conditions.

Different views of one generator need not resemble one another. Their correspondence, transformation geometry, alternatives, and composition carry the evidence.

### 2.5 Pairwise fit replaced global realization

Pairwise-compatible maps may fail to form one global diagram. Conversely, several global realizations may fit all observations.

The realization fiber must therefore range over joint realizations `(generator, atlas)`, not bare generators. Otherwise the theory would preserve maps in prose while quotienting them out of the object being identified.

The stack did not preserve:

```text
no realization
several realizations
one identified realization
search unable to decide
```

### 2.6 Final behavior could repeat the same quotient

Coalgebraic final semantics identifies behaviorally equivalent concrete states. That is useful, but presentation-sensitive complexity, mechanism, intervention, and causal claims cannot be reconstructed from the behavior point alone.

The normative receipt must retain:

```text
concrete presentation
behavior basis and access
behavior map or finite relation
commuting evidence
```

### 2.7 The coalgebraic kernel was incomplete

Both the early coalgebraic formulation and the first v4 draft named an object action for an articulation functor without defining its action on morphisms. The central commuting equation therefore used `F(h)` before `F` was a functor.

This recurrence is now a permanent conformance case rather than a local prose repair.

### 2.8 Authority surfaces collapsed

The repository mixed or weakly separated:

```text
structural compilation
instrument assessment
admission policy
boundary authorization
target execution
```

A methodology can be well formed but inconsistent, consistent but uncalibrated, calibrated but out of scope, or useful without authority to issue a verdict.

### 2.9 Examples could not falsify the general claim

The philosophical examples were illustrations with hand-authored data and expected scores.

The cellular-automata examples relied on transcribed oracle material. Random-looking frames were treated as a universal negative even though an i.i.d. trace can be lawful under an i.i.d. methodology.

The katas tested the Markdown proxy, not general coherence.

### 2.10 Failed evidence did not persist through replacement

The v2.3 braided witness reported a 92% normalization failure and scheduled repair. The later foundation removed the universal braided claim without formally disposing of the failed receipt.

The v3 independence proof established target-monoid non-isomorphism, not evaluator-level informational independence. Its successor claim obtained authority without new evidence.

## 3 · Challenged assumptions

The revision rejects these assumptions.

1. **Three free positions are the primitive.** The primitive is a typed relation whose type depends on its poles.
2. **The center stores unity.** The middle role carries the dependent relation; unity belongs to the complete event and continuation.
3. **A commutative leaf fold can measure internal shape.** Shape requires node- or path-sensitive structure.
4. **Coherence is one context-free scalar.** Coherence is a scoped disposition supported by a receipt.
5. **Agreement among views establishes one process.** A common-process claim requires generator class, maps, globalization, complexity, and an oracle.
6. **A generator is a hidden object.** A generator is a lawful presentation producing and transforming observations.
7. **Final behavior is the whole normative object.** Final behavior is a quotient; the presentation remains normative where claims depend on it.
8. **Observation count determines identifiability.** Identifiability depends on model, observation, correspondence, noise, and intervention contracts.
9. **Random-looking means incoherent.** Coherence is relative to a declared law.
10. **Compilation grants epistemic authority.** Compilation, assessment, admission, authorization, and execution are distinct.
11. **A failed claim may disappear when theory changes.** Every failed receipt receives an explicit disposition.

## 4 · Candidate boundary moves

### 4.1 Patch the scalar theory

Replace γ, repair formulas, retain alignment maps, and add statuses while keeping the old term algebra and aggregate central.

**Rejected.** The primitive would still create free peers, the score would still carry several constructs, and later layers would keep working around early information loss.

### 4.2 Add receipts above the old foundation

Preserve old terms but wrap them in atlases, fibers, lineage, and standing.

**Rejected.** The receipt would require typed paths and presentations that the foundation had already erased.

### 4.3 Rebuild from typed articulation and open generation

Replace the primitive and move scalar summaries to the edge.

**Selected.** It changes the boundary that generated the recurring failures.

## 5 · Selected architecture

### 5.1 Typed event

```text
P                         pole type
Rel : P × P → Set         dependent relation family
Art := Σ(s:P).Σ(o:P).Rel(s,o)
art(s,φ,o)                where φ : Rel(s,o)
```

### 5.2 Open generator

```text
c : X × I → Art × X
```

The generator emits a complete event and successor state. Query ownership is declared as exogenous, endogenous, or mixed.

### 5.3 Exact Set behavior

```text
F_I(Y) := (Art × Y)^I
F_I(h)(k)(i) := let (a,y)=k(i) in (a,h(y))
```

With `I+` the nonempty finite input histories:

```text
B_I := Art^(I+)
ζ(b)(i) := (b([i]), w ↦ b(i·w))
```

`(B_I,ζ)` is the exact final coalgebra in Set. Every concrete generator has one unique behavior map.

This discharges finality for the deterministic Set case. Other categories or system functors carry their own proof obligation.

### 5.4 Behavior basis versus access

```text
FinalityBasis
  SET_FINAL | GENERAL_FINAL | NO_FINALITY_CLAIM

BehaviorAccess
  COMPLETE_SYMBOLIC | FINITE | APPROXIMATE
```

Exact final semantics may exist while an experiment accesses only a finite or approximate behavior.

### 5.5 Joint realization candidates, fibers, and refinement

A realization candidate retains both the generator and the atlas through which it accounts for the observations:

```text
R = (G,A)
R_M(D) = { (G,A) | G ∈ H_M and A ∈ A_M(G,D) }
```

Candidates are filtered before quotienting:

```text
C_M^fit(D) = { R ∈ R_M(D_train) | L_M(R,D_train) ≤ τ_M }
C_M^train(D) = { R ∈ C_M^fit(D) | K_M(R) ≤ κ_M }
F_M^train(D) = C_M^train(D) / ≃_M^J_train
```

Held-out evidence tests every fixed realization candidate and retains the outcome partition:

```text
C_M^pass(D)       oracle = PASS
C_M^fail(D)       oracle = FAIL
C_M^unresolved(D) oracle ∈ {UNRESOLVED, NOT_RUN}

C_M^test(D) = C_M^pass(D)
F_M^test(D) = C_M^test(D) / ≃_M^J_eval
```

A wider input family may remove realizations and split a coarse class. The receipt retains:

```text
C_M^test ⊆ C_M^train
r_test→train : F_M^test → F_M^train
```

rather than treating quotient fibers as literal subsets.

Training and tested regimes retain separate realization, budget, test, and identification statuses. A held-out refinement may leave training `UNDERDETERMINED` while producing tested `IDENTIFIED_IN_MODEL`; both remain visible. Tested identification is withheld when any bounded alternative remains `UNRESOLVED`.

### 5.6 Structured receipt roles

```text
α  ManifestationReceipt
   evidence validity, coverage, repeatability, uncertainty

β  RelationalAtlas
   map search, maps, alternatives, globalization, realization fiber

γ  ContinuationReceipt
   held-out prediction, identity transport, law, termination
```

These are non-substitutable proof obligations, not symmetric independent axes.

```text
α VALID
  → authoritative β may complete
β establishes an applicable candidate
  → authoritative γ may complete
```

### 5.7 Receipt primacy

The primary result retains:

```text
concrete generator presentation
behavior contract and evidence
observations and provenance
relational atlas and search record
realization-candidate sets, fibers, and alternatives
continuation and intervention tests
complexity and uncertainty
lineage, standing, and authority
```

A scalar may summarize only after categorical status is fixed.

### 5.8 Failure persistence

A later system disposes of every failed receipt as:

```text
RESOLVED
CLAIM_WITHDRAWN
SUPERSEDED
INVALIDATED
UNRESOLVED
```

A successor claim receives no inherited standing.

## 6 · Relation-priority decision

The motivating philosophy says relation precedes thing.

The static signature does not prove this. `P` and its poles exist before `Rel(s,o)` is inhabited. The static result is **mutual constitution**: no articulation event exists without poles and relation together.

The generative layer adds a partial formal result. `c : X × I → Art × X` emits the complete event, including its particular poles. Those poles are outputs of unfolding rather than separate inputs to that event.

The precise v4 claim is:

> The static foundation establishes relational indispensability, not derivation of the pole universe. The generative foundation produces particular poles as parts of emitted articulation events. Ontological priority beyond this remains an interpretation, not a theorem.

## 7 · Symbol migration

| Earlier referent | v4 referent |
|---|---|
| free `tri(T,T,T)` positions | dependent event `art(s,φ,o)` |
| center carries unity | middle carries the dependent relation; whole event carries unity |
| α evaluator / scalar axis | `ManifestationReceipt` |
| β evaluator / scalar axis | `RelationalAtlas` |
| γ evaluator / scalar axis | `ContinuationReceipt` |
| universal `C_Σ` | optional CM-local scalar summary |
| pairwise alignment residual | retained map-search record and atlas |
| pass/fail coherence threshold | typed disposition, identification, standing, and authority fields |
| replacement without receipt disposition | failure-persistent lineage |

## 8 · Responsibility map

```text
spec/c-equiv.md
  typed events, paths, Set functor, exact behavior, equivalence

spec/tsc-core.md
  measurement context, behavior contract, approximation, fibers, receipts

spec/tsc-oper.md
  compilation, sandbox, assessment, admission, authorization, execution

spec/tsc-observation-dynamics.md
  episodes, lineage, dependence, comparison, intervention, refinement, lift

spec/tsc-conformance.md
  stable requirement IDs and positive/negative proof obligations

conformance/
  external domain fixtures implementing requirement IDs
```

## 9 · Artifact roles

```text
illustration
  teaches a conceptual frame; no normative expected result

regression fixture
  pins implementation behavior; no truth claim beyond that implementation

conformance fixture
  carries an independent generator and oracle capable of falsification

calibration anchor
  carries label provenance and standing scope

experiment
  carries preregistration, intervention, and retained result
```

## 10 · First conformance ascent

The first exact-domain fixture is registered outside `spec/` as `gol-ascent-0`.

### 10.1 Refinement

B3/S23 is in the model from the start.

```text
static row/column margins
  → two joint realization candidates
  → UNDERDETERMINED

held-out next margins
  → one realization candidate survives without refitting
  → IDENTIFIED_IN_MODEL
```

This is evidence refinement, not a model lift.

### 10.2 Lift

```text
H_0
  static binary grids with margin observations

baseline failure
  preregistered future-state question cannot be answered in H_0

H_1
  pointed B3/S23 generators

class relation
  forget trajectory and retain initial grid

complexity
  fixed law cost + initial-state representation cost

acceptance margin
  tested realization fiber contracts from two classes to one

held-out oracle
  next margin fixed before H_1 fitting
```

Only this case may earn `LIFT_VALIDATED`.

The GoL package also specifies a surface-statistics-preserving law violation and lawful collision/termination. A separate `stochastic-law-v4` fixture tests lawful i.i.d. behavior. No transcribed frame or hand-selected scalar is an oracle.

## 11 · Leverage

### Positive

The revision:

- gives one formal referent to coherer, cohering, and cohered;
- makes invalid role permutation unrepresentable;
- completes the deterministic Set functor and final behavior;
- preserves maps needed for reconstruction and audit;
- distinguishes contradiction, underdetermination, and search incompleteness;
- handles deterministic, stochastic, passive, active, and reflexive CMs through declared contracts;
- gives CM compilation a truthful target;
- lets fixtures falsify the theory;
- makes failed evidence persist across revisions.

### Negative

The revision:

- removes universal scalar comparison;
- requires larger structured receipts;
- makes finality, approximation, map search, and complexity obligations explicit;
- requires each CM to declare more of its model and oracle;
- forces non-Set and stochastic applications to earn their behavior semantics;
- increases the work required before a measurement carries standing.

These costs retain information that the claims depend on.

## 12 · Impact graph

Direct consumers include:

```text
CM schemas and compiler
runtime result types
report schemas
standing and admission policy
self-measurement methodology
CM-of-CMs
comparison logic
illustrations, katas, and conformance fixtures
README, STATUS, QUICKSTART, and architecture docs
engine implementation-status surface
citation and version projections
```

The current repository-proxy engine does not become a v4 implementation through this spec change. Its status remains explicit until the runtime contract is implemented.

## 13 · Acceptance criteria

### AC1 — Standalone specs

Each normative spec begins from first principles and contains no migration narrative.

### AC2 — Complete foundation

C≡ defines dependent articulation, the functor on objects and morphisms, functor laws, exact Set final behavior, equivalence, and no-premature-quotient rules.

### AC3 — Behavior contract

Core defines finality basis separately from behavior access. Operational rejects undeclared, inapplicable, incomplete, or unsupported behavior claims.

### AC4 — Receipt semantics

Core defines typed α/β/γ receipts, dependency envelopes, joint generator-plus-atlas realization sets and fibers, search claims, and categorical dispositions.

### AC5 — One approximation owner

Core owns the tolerance and behavioral metric contract. Other layers bind to it by digest.

### AC6 — One proof authority

`spec/tsc-conformance.md` owns permanent requirement IDs and proof pairs. Domain fixtures live outside `spec/`.

### AC7 — Failure persistence

Observation Dynamics defines dispositions. The cutover receipt records the first applications without transferring standing to successor claims.

### AC8 — Honest repository surfaces

README, STATUS, Architecture, Quickstart, engine docs, illustrations, katas, and citation metadata distinguish the v4 theory from the current proxy engine.

### AC9 — Generated fixture path

The GoL and stochastic fixtures are specified externally with generators, independent oracles, positive/negative pairs, and expected categorical results. A specified fixture supports specification review but claims no implementation result or standing until implemented and verified.

### AC10 — Independent review and ratification

All specification findings close on the branch, every enduring requirement has a specified positive/negative oracle, and consumer status is truthful. A ratification-only commit changes normative status from `Draft` to `Normative`, and that final SHA is reviewed before merge. Implementation conformance remains absent until applicable fixtures are verified.
