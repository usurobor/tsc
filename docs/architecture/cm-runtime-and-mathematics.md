# TSC — CM Runtime and the Role of Mathematics

> **Status:** Architecture clarification
> **Date:** 2026-08-05
> **Scope:** Current implementation, intended runtime, provider model, and the exact place of v4.1 mathematics
> **Source:** [Google Doc](https://docs.google.com/document/d/1JUFFojoLWQqfKuwf7Bm-RLeHibqb3XEcDmCgGVlTskk/edit)
> **Source revision:** `AIroW35H3Jkm7TxfBJd0Oy8IzKhS2s9m3XifOo7N8aTBcNgCqw7s-heI5fzpmAvCnlJPWux2_QOjrgTiDv4EBojL4bqWsHDxRzw_jvtzKlE`

## Executive answer

The .cm compiler does not execute a methodology. It translates human-authored .cm source into a normalized, machine-readable methodology program.

That program must then be linked to concrete implementations and executed by a CM runtime. The intended eventual public runtime is coh, but the released coh 0.12.0 is still the frozen v3.2 repository proxy and does not yet run arbitrary v4 CMs. Today there are three distinct execution modes:

1. Manual/reference execution — an LLM reads a CM contract and performs it, producing a receipt. This is how Repository Legibility and Structure were first exercised.
2. Specialized research execution — the Ascent-0 sandbox runner executes one bounded CM/provider graph end to end.
3. General runtime — not yet shipped. This is the highest-priority missing layer if the CM language is to become immediately useful.

The mathematics is not another runtime. It is the semantic and warrant contract behind the conclusions a CM is permitted to make. For simple checks, almost none of the advanced mathematics needs to be visible to the developer. For claims such as “one generator explains these observations,” “the generator is identified,” “several generators remain underdetermined,” or “this lift generalizes to held-out inputs,” the v4.1 mathematics defines exactly what those words mean and what evidence is required.

The short stack is:

```text
.cm source              developer writes the methodology
cmc compiler            parses, typechecks, lowers
NormalizedCMIR JSON     canonical methodology program
CUE                     independently validates the IR contract
linker                  resolves provider implementations and permissions
CM runtime              executes the provider DAG and emits a receipt
v4.1 Core math          defines the warrant behind stronger conclusions
CM0                     assesses whether the methodology/provider instrument is credible
V                       issues admission verdict
δ                       authorizes boundary action
```

## 1. What the .cm compiler currently does

The compact .cm language is an ML/F#-inspired authoring surface. Its purpose is to let a developer write a methodology as an evidence-producing computation rather than hand-author a large CUE or JSON object.

A conceptual example:

```text
cm repositoryStructure v0.2 (repo, policy) -> StructuralReceipt {
  let! paths = Git.tracked repo
  let! classes = Repository.classify policy paths
  let! consumers = Repository.consumers repo classes.moves

  retain paths, classes, consumers

  decide
  | Failed when anyStepFailed
  | Incomplete when paths.partial or consumers.incomplete
  | Defect when classes.violations.nonempty
  | Pass

  forbid repair, policyChange, admit, authorize
}
```

The compiler turns that into normalized JSON containing, among other things:

- methodology identity and version;
- typed inputs and output receipt;
- provider operation references;
- step dependency graph;
- evidence-retention contract;
- result-rule precedence;
- refusal semantics;
- authority prohibitions;
- digests and source references.

**Compilation answers:**

  Is this a valid methodology program?

**It does not answer:**

  Did the repository satisfy the methodology?

That second question requires execution.

## 2. What applies the JSON

The JSON is consumed by a CM runtime, not by the LLM directly and not by JSON itself.

The intended execution pipeline is:

```text
CMSource (.cm)
    ↓ parse / typecheck / lower
NormalizedCMIR
    ↓ resolve operations to implementations
SandboxExecutionPlan or CompiledCM
    ↓ execute against RunRequest
MeasurementReceipt
```

The distinction between NormalizedCMIR and CompiledCM matters.

**NormalizedCMIR says:**

  This is the concrete canonical methodology program.

**CompiledCM says:**

  Every operation has been linked to a concrete provider; permissions, adapters, sandbox policy, execution order, schemas, contracts, and implementation digests are resolved.

The current generic compiler reaches the first artifact. A general linker/runtime reaching the second artifact is still missing.

## 3. Is coh the runtime?

Eventually, yes: coh should become the user-facing compiler, linker, runner, and receipt verifier for v4 CMs.

The intended commands are approximately:

```text
coh cm check <cm>
coh cm compile <cm>
coh cm test <cm>
coh cm run <cm> --target <target> --sandbox
coh cm assess <cm>
coh receipt verify <receipt>
```

But status truth is important:

- released coh 0.12.0 executes the frozen v3.2 repository-proxy methodology;
- it does not compile arbitrary v4 CMs;
- it does not emit general v4 MeasurementReceipts;
- it does not yet implement the general provider runtime;
- the Ascent-0 sandbox runner is research code proving a narrow execution slice, not yet general coh.

So the highest-priority engineering objective is a general CM Runtime MVP, later promoted into coh.

## 4. Where the LLM fits

The LLM is neither the compiler nor the whole runtime. It is one possible provider implementation inside the runtime.

A CM can contain multiple operation classes:

### Mechanical operations

- list tracked files;
- parse manifests;
- search references;
- resolve links;
- run tests;
- validate schemas;
- enumerate finite models;
- compute a digest;
- compare against an oracle.

### Semantic or cognitive operations

- classify a document’s purpose;
- judge whether prose contradicts a declared policy;
- derive a polar point of view;
- name an obstruction;
- review a proposed explanation;
- compare two receipts semantically.

### Nested methodology operations

- invoke Legibility CM;
- invoke Structure CM;
- invoke CM0;
- compose child receipts.

### Oracle operations

- reveal held-out expected output;
- run an intervention;
- test a prediction;
- verify a proof or construction.

A semantic step may invoke an isolated LLM CLI or API with:

- an exact instruction or skill digest;
- typed input;
- output schema;
- evidence requirements;
- model/provider identity;
- sampling/repeatability declaration;
- bounded permissions.

The runtime then validates the LLM’s output before it becomes evidence.

The LLM may propose. It does not automatically warrant.

## 5. Is “provider” the right term?

Provider is a useful TSC/runtime term, but it is not the standard F# name.

In F# computation-expression vocabulary:

- the computation-expression builder defines how let!, and!, return, and other operations compose;
- the values used with let! are computations in that builder’s context.

In TSC, it helps to separate three concepts:

### Operation or property

  What the CM developer calls.

  Examples:
    Git.tracked
    Repository.oneAuthoritativeHome
    LLM.classifyPurpose
    CM.run Structure

### Provider

  The concrete implementation of the operation.

  Examples:
    built-in Git library implementation
    shell command or executable
    Claude CLI with a pinned prompt
    GPT provider with a pinned skill
    finite-model enumerator
    human review queue

### Runtime/builder

  The engine that sequences operations, enforces effects and permissions, captures evidence, applies result rules, and emits the receipt.

So the clean formulation is:

  developers compose typed operations or assessed properties;
  providers implement those operations;
  the CM runtime executes them.

“Provider” is therefore closer to an effect handler, capability implementation, or service adapter than to an F# computation-expression builder.

## 6. What an assessed property is

A checkable property should not be merely:

  Repository -> bool

It should be closer to:

  Repository -> Evidence<AuthoritativeHomeFinding>

A reusable property package carries:

- identity and version;
- typed inputs and outputs;
- evidence contract;
- provider implementation reference and digest;
- required capabilities;
- positive fixture;
- negative fixture;
- refusal fixture;
- repeatability claim;
- CM0 assessment.

For example:

  Repository.Artifact.oneAuthoritativeHome

could be implemented mechanically for exact duplicate paths, semantically for claims duplicated in prose, or as a composition of both. The CM author calls one property. The package owns the underlying providers and evidence contract.

This is the immediate practical value of the language: engineers can build libraries of reusable, independently assessed methodology operations.

## 7. Where the mathematics enters

The v4.1 mathematics is not required because JSON needs math. It is required because strong coherence claims need precise meaning.

There are three levels.

### Level A — ordinary checks

Examples:

- README exists;
- links resolve;
- credentials are committed;
- every moved file’s consumers were updated;
- a document is in a prohibited directory.

These can be implemented by ordinary logic, schemas, queries, and semantic judgment. The developer need not manipulate generator fibers or coalgebras.

The result is still valuable evidence:

  DEFECT
  PASS
  INCOMPLETE
  FAILED

No advanced mathematical claim is implied.

### Level B — compositional methodology

Examples:

- Repository Coherence composes Legibility and Structure;
- the parent retains child receipts;
- one child can pass while another reports a defect;
- no weighted average erases a child finding.

Here the formal content is mainly typed composition, partial order/precedence of result classes, evidence retention, and authority separation. Again, the full generator mathematics need not be visible.

### Level C — generative or identification claims

Examples:

- these observations arise from one lawful generator;
- the generator is identified within a declared model class;
- two inequivalent generators remain possible;
- no generator exists in the declared class;
- a candidate generalizes to held-out interventions;
- two views are projections of one higher-order process;
- an Articulation Ascent lift is validated rather than decorative.

Now the Core mathematics is load-bearing.

The methodology must declare or inherit:

H\_M
  The allowed generator/model class.

A\_M(G,D,S)
  The admissible atlas or relation structures connecting a generator to observations and an optional polar source.

R = (G,A)
  A joint realization candidate: generator plus atlas, not a bare model.

SearchClaim
  Whether search is complete, complete within a bound, heuristic, or sampled.

L\_M(R,D)
  Fit/loss under the declared evidence.

K\_M(R)
  Complexity or prior cost, including nontrivial maps/atlases.

τ\_M and κ\_M
  Admissible fit and complexity bounds.

R ≃\_M^J R′
  Equivalence under the declared query/intervention family J.

F\_M^train and F\_M^test
  Candidate fibers: equivalence classes surviving training and held-out tests.

Oracle contract
  The held-out, interventional, proof, construction, or other discriminating test.

These definitions tell us exactly when the runtime may emit:

- NO\_REALIZATION\_IN\_MODEL;
- REALIZABLE\_OVER\_BUDGET;
- UNDERDETERMINED;
- IDENTIFIED\_IN\_MODEL;
- held-out PASS/FAIL/UNRESOLVED/NOT\_RUN.

## 8. The key point: math is a claim-strength contract

The mathematics does not tell the runtime which command to execute. The provider contracts and runtime do that.

The mathematics tells the runtime what evidence is sufficient for which conclusion.

For example, a surface program might say:

  let! candidates = Model.search class evidence
  decide
  | Identified when candidates.unique

The word “unique” cannot be trusted on its own.

The compiler/IR/runtime must establish that:

- the model class was declared before search;
- the search was complete enough for the conclusion;
- candidates were filtered by fit and complexity;
- uniqueness means one equivalence class, not one serialization;
- the equivalence is indexed by the declared query family;
- unresolved candidates are absent;
- held-out obligations were satisfied where required.

That is where the math bites.

The compact language hides boilerplate. It must not hide these obligations.

## 9. How math is implemented operationally

A mathematical obligation can be discharged in several ways.

### By static validation

- required fields are present;
- result mapping is total;
- a claim such as Identified is illegal unless the IR carries the required search/equivalence/oracle contracts;
- authority boundaries are valid.

### By a mechanical provider

- complete bounded enumeration;
- SAT/SMT/LP solver;
- model fitting;
- equivalence checking;
- finite behavioral comparison;
- metric calculation;
- proof checker;
- oracle execution.

### By a proof or witness artifact

- functor laws;
- finality witness;
- construction proof;
- typecheck receipt;
- theorem prover output.

### By a semantic provider

- proposes a generator class;
- proposes a relation/atlas;
- names a conceptual obstruction;
- explains a candidate whole.

But semantic proposal alone cannot establish identification. Mechanical/proof/oracle evidence must satisfy the declared Core contract.

## 10. Current gap between the CM language and the Core math

This is important and should not be blurred.

The current .cm/CUE work has successfully encoded:

- leaf CMs;
- composite CMs;
- typed result classes;
- provider-bound steps;
- receipt shape;
- authority prohibitions;
- deterministic compilation to JSON.

It has not yet completed the general binding from every warrant-bearing surface construct to all v4.1 Core obligations.

That is the purpose of the Core-warrant/property-library work:

- check-style CMs can run immediately through ordinary providers;
- stronger claims must compile to IR carrying H\_M, search, atlas, equivalence, fit/complexity, oracle, and fiber semantics;
- a methodology missing those obligations must fail validation rather than silently emit a strong conclusion.

Ascent-0 implements a narrow, domain-specific version of this binding. The general CM runtime and property libraries do not yet.

## 11. Recommended highest-priority implementation program

The next priority should be the general CM Runtime MVP, using Repository Coherence as the first product case.

### Phase 1 — freeze the artifact pipeline

```text
.cm
-> NormalizedCMIR
-> RunRequest
-> SandboxExecutionPlan
-> MeasurementReceipt
```

### Phase 2 — provider ABI and registry

Implement three provider classes first:

- mechanical command/library provider;
- isolated LLM semantic provider;
- child-CM provider.

Add oracle and pure-transform providers as required.

### Phase 3 — execute one practical composite CM

Run:

```text
Repository Coherence
  - Legibility
  - Structure
```

against an exact repository commit.

The runtime must:

- execute all steps;
- retain evidence;
- distinguish DEFECT/INCOMPLETE/FAILED/PASS;
- preserve child receipts;
- emit one canonical composite receipt.

### Phase 4 — integrate into coh

Only after the reference runtime is stable:

  coh cm check
  coh cm compile
  coh cm test
  coh cm run --sandbox
  coh receipt verify

The old v3.2 proxy remains explicitly separate until replaced or retired through a truthful compatibility boundary.

### Phase 5 — Core-warrant standard library

Build assessed property/math-builder packages:

- ModelSearch.complete / bounded;
- Identification.jointRealization;
- Evidence.fitAndHeldOut;
- Approximation.pathBudgeted;
- Articulation fiber and descent operations.

These packages expand compact surface constructs into full Core IR obligations.

### Phase 6 — CM0

Assess providers and methodologies for:

- source/IR/implementation integrity;
- repeatability;
- discrimination;
- refusal;
- evolution.

## 12. Final architecture

The full system is:

Developer
  writes a compact .cm methodology by composing typed operations and assessed properties.

Compiler
  turns it into a canonical NormalizedCMIR and rejects statically invalid claims.

Linker
  resolves operation references to concrete providers and builds a sandboxed execution plan.

Runtime
  executes mechanical code, isolated LLM cognition, child CMs, transforms, and oracles; validates outputs and retains evidence.

TSC Core mathematics
  governs what stronger conclusions the evidence is permitted to support.

Receipt
  preserves target, CM, provider, evidence, findings, refusals, alternatives, and result derivation.

CM0
  assesses whether the CM/provider combination is a credible instrument.

V
  decides whether the assessment satisfies an admission contract.

δ
  decides whether the methodology may be registered, sandboxed, used experimentally, or authorized for a boundary action.

### The concise formulation

  The .cm language programs the inquiry.
  Providers perform the work.
  The runtime orchestrates and receipts it.
  The v4.1 math limits what may be concluded.
  CM0 tests whether the instrument deserves trust.

### Current state

  The compiler exists.
  The normalized IR exists.
  Manual and one specialized runtime execution exist.
  A general provider runtime in coh does not yet exist.
  The general Core-math binding does not yet exist.

Therefore the highest-priority practical step is not more Ascent research. It is to make the existing CM language executable through a general, sandboxed, receipt-producing provider runtime, with the Core mathematics added wherever a methodology makes warrant-bearing generative or identification claims.

