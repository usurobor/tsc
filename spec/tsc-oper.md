# TSC Operational v4 — Methodology Lifecycle and Authorized Measurement

**Version:** 4.0.0
**Status:** Draft
**Artifact:** Normative runtime contract

## Governing question

> How does a methodology move from authored source to authorized measurement without collapsing structural validity, instrument quality, standing, and boundary authority into one decision?

TSC Operational separates compilation, bounded execution, instrument assessment, admission, authorization, target execution, and receipt emission.

## 1 · Runtime artifacts

### 1.1 CM source

`CMSource` is the human-authored methodology package. It contains:

```text
identity and version
input and observation contract
generator and atlas-candidate classes
path contract
behavior contract
relation-search and generator-search contracts
equivalence and approximation contracts
complexity and oracle contracts
implementation bindings
permissions and resource declarations
receipt schema
```

### 1.2 Compiled CM

`CompiledCM` is the normalized runtime descriptor produced from `CMSource`.

It binds:

```text
source digest
compiled descriptor digest
validated schemas
resolved implementation/provider bindings
path contract and succession-check plan
behavior contract
search contracts and orchestration
approximation-contract digest
sandbox policy
input adapters
execution plan
receipt contract
```

Compilation establishes structural executability. It grants no standing and no authority over target data.

### 1.3 Calibration receipt

`CalibrationReceipt` records bounded executions over declared controls, repeats, malformed inputs, refusal cases, and held-out anchors.

It carries no target-measurement authority.

### 1.4 Instrument assessment

`InstrumentAssessment` is a CM0 measurement of a candidate methodology as an instrument.

It reports:

```text
parts present
relations fit
evolution and migration rules
repeat consistency
discrimination
refusal behavior
calibration evidence
defects and uncertainty
```

CM0 measures. It does not compile, admit, authorize, or decide a boundary action.

### 1.5 Admission verdict

`AdmissionVerdict` is produced by validator `V` from an admission contract and assessment evidence:

```text
PASS | FAIL
```

### 1.6 Boundary decision

`BoundaryDecision` is produced by `δ`:

```text
register
hold
reject
permit_sandbox
permit_experimental
permit_production
revoke
override_degraded
```

`δ` decides what action follows. It does not rewrite the measurement or verdict.

### 1.7 Authorized CM

`AuthorizedCM` binds:

```text
CompiledCM digest
AdmissionVerdict
BoundaryDecision
standing and scope
permissions
validity interval
revocation conditions
```

### 1.8 Measurement receipt

`MeasurementReceipt` is the Core receipt emitted when an authorized or explicitly sandboxed CM runs on a compatible target.

## 2 · Authority separation

The lifecycle has five distinct authorities:

```text
compiler   → structural validity and normalized execution descriptor
CM0        → instrument measurement
V          → admission verdict
δ          → boundary action
runtime    → faithful execution and receipt emission
```

No surface may assume another surface's authority.

```text
compilation does not imply instrument coherence
instrument coherence does not imply external validity
admission does not imply production authorization
execution does not imply standing
a score does not imply a verdict
a verdict does not imply a boundary action
```

## 3 · Compilation contract

### 3.1 General checks

The compiler performs:

```text
parse
typecheck
link
schema validation
adapter resolution
permission validation
receipt-schema validation
execution-plan normalization
path-contract validation
behavior-contract validation
search-contract validation
```

Output:

```text
COMPILED(CompiledCM)
```

or:

```text
COMPILE_REJECTED(code, diagnostics)
```

### 3.2 Behavior-contract validation

The compiler requires both:

```text
FinalityBasis
BehaviorAccess
```

#### SET_FINAL

The compiler validates the descriptor's `SET_FINAL` applicability evidence against the mathematical contract owned by C≡ §6. Operational does not duplicate that contract. The permanent proof obligation `FND-FINAL-002` tests the compiler's enforcement.

Absent or failed applicability evidence emits `SET_FINAL_INAPPLICABLE`. Operational may enforce the foundation contract; it may not restate a weaker one.

#### GENERAL_FINAL

`GENERAL_FINAL` passes only when the descriptor includes:

```text
carrier category
system functor object action
system functor morphism action
functor identity law
functor composition law
pointed-state contract
typed articulation interface
behavior object
finality witness
behavior-map contract
```

`GENERAL_FINAL` accepts only a complete universal-property witness in the declared category. A tolerant or approximate square without such a theorem does not pass as finality.

#### NO_FINALITY_CLAIM

`NO_FINALITY_CLAIM` may use `COMPLETE_SYMBOLIC`, `FINITE`, or `APPROXIMATE` access when the construction and supported claims are explicit. It cannot invoke final-coalgebra uniqueness, Lambek's isomorphism, or another finality consequence.

### 3.3 Compile refusal codes

The compiler fails closed with stable codes, including:

```text
BEHAVIOR_MODE_UNDECLARED
SET_FINAL_INAPPLICABLE
PRESENTATION_KIND_UNDECLARED
INITIAL_STATE_WITNESS_MISSING
ARTICULATION_INTERFACE_MISSING
PATH_CONTRACT_UNDECLARED
FUNCTOR_INCOMPLETE
FUNCTOR_LAWS_UNPROVED
FINALITY_UNSUPPORTED
BEHAVIOR_ACCESS_UNDECLARED
APPROXIMATION_CONTRACT_MISSING
SEARCH_CLAIM_MISSING
RELATION_SEARCH_CONTRACT_MISSING
SEARCH_ORCHESTRATION_UNDECLARED
RECEIPT_SCHEMA_INVALID
PERMISSION_UNDECLARED
ADAPTER_INCOMPATIBLE
```

The compiler never silently substitutes finite or approximate behavior for a failed finality claim.

## 4 · Methodology lifecycle

### 4.1 AUTHOR

Input:

```text
CMSource
```

Output:

```text
source digest
```

The source is immutable for one lifecycle attempt. A source change creates a new digest and invalidates dependent artifacts.

### 4.2 COMPILE

The compiler applies §3 and emits `CompiledCM` or a compile refusal.

### 4.3 SANDBOX

A compiled candidate may run before admission only in the declared calibration sandbox.

The sandbox enforces:

```text
read/write paths
network access
provider access
CPU, memory, and time budgets
input size
secret access
output locations
```

Every sandbox run emits a receipt, including refusals and resource exhaustion.

### 4.4 ASSESS

CM0 measures the candidate methodology using:

```text
static package evidence
repeat runs
positive and negative controls
malformed and out-of-domain inputs
held-out or blinded anchors when available
refusal and degradation behavior
```

Output:

```text
InstrumentAssessment
```

Self-assessment is a hygiene check. It is never the sole source of standing.

### 4.5 VALIDATE

Validator `V` evaluates the assessment against the admission contract.

Unavailable required evidence yields `FAIL`; it never becomes an inferred pass.

### 4.6 DECIDE

`δ` receives:

```text
CompiledCM
InstrumentAssessment
AdmissionVerdict
operator policy
```

and emits `BoundaryDecision`.

An override records:

```text
who authorized it
why it was necessary
which failed condition remains
what standing is lost
when the override expires
```

### 4.7 AUTHORIZE

A permissive boundary decision creates `AuthorizedCM` for a specific scope:

```text
sandbox
experimental
production
```

Authorization may restrict input classes, providers, resources, and output uses.

### 4.8 EXECUTE

The runtime executes a CM on a target only after:

```text
applicability passes
input completeness passes
permissions pass
required evidence is readable
compiled and authorized digests match
behavior and approximation contracts are available
```

### 4.9 RECEIPT

Every terminal state emits one receipt:

```text
success
refusal
unresolved
resource failure
provider failure
law violation
```

No silent fallback or empty green result is permitted.

## 5 · Target measurement pipeline

The stages below name logical obligations. A CM may interleave relation search and generator search only when its compiled execution plan declares the schedule, stop rule, retained alternatives, and determinism or repeat protocol.

### 5.1 HANDSHAKE

Validate:

```text
CM identity and authorization
target identity
input schema
applicability
required permissions
required observation channels
path contract
behavior contract
```

Failure emits `NOT_APPLICABLE`, `INVALID_INPUT`, or a compile/authorization refusal.

### 5.2 COVER

Resolve all required and optional evidence.

Emit a content-addressed coverage manifest:

```text
required items found
optional items found
missing items
unreadable items
unexpected items
item digests
resolver version
```

Missing required evidence stops execution before classification.

### 5.3 OBSERVE

Construct observation episodes and the α receipt.

Record:

```text
constructor identity and digest
channel identity
input history
raw evidence reference
uncertainty
```

If α is not `VALID`, later roles may retain diagnostics but are marked `BLOCKED_BY(α-validity)` for authoritative classification.

For `STATE_LINKED(pole_of)`, each executed transition also verifies:

```text
src(a) = pole_of(x)
dst(a) = pole_of(x')
```

A mismatch terminates that execution path with `PATH_COHERENCE_VIOLATION`. An `EVENTWISE` contract emits no cross-step succession claim.

### 5.4 RELATE

Enumerate, fit, and retain relation candidates:

```text
relation-search evidence
correspondence and transformation maps
alternatives and pruning reasons
residuals and uncertainty
path checks
provisional globalization evidence
```

Relation candidates may depend on generator hypotheses when the declared orchestration permits it. A β diagram may relate `EVENTWISE` emissions, but relation search does not mutate the compiled path contract or authorize an intrinsic role-succession claim.

### 5.5 REALIZE

Search the generator class jointly with the retained relation candidates to construct joint realization candidates under the declared fit, complexity, and search contracts.

Record:

```text
search algorithms and versions
generator and relation search claims
search orchestration and stop rule
generators and maps considered
joint realization-candidate and atlas references
fit and complexity values
pruning and refusal reasons
```

Finalize the β atlas, globalization result, fit and bounded realization-candidate sets, training fiber, and search evidence.

If β establishes no applicable realization candidate, γ is `BLOCKED_BY(β-realizability)` for claims about a common generator.

### 5.6 CONTINUE

Execute held-out predictions, future-state tests, or interventions for every fixed bounded realization candidate; retain PASS, FAIL, UNRESOLVED, and NOT_RUN outcomes; construct γ and the tested fiber from the PASS set.

A held-out item is valid only when its selection and label were unavailable to the fitting path under the declared provenance rules.

### 5.7 CLASSIFY

Derive:

```text
α status and evaluation
β status and evaluation
γ status and evaluation
fit, bounded, passing, failing, and unresolved realization-candidate references
training and test candidate classifications
coherence disposition
training and tested identification statuses and target
model adequacy
lift status
```

Every derived field is recomputable from the receipt or a referenced deterministic artifact.

### 5.8 EMIT

Write the complete measurement receipt and referenced artifacts.

Human and machine views derive from one receipt model and preserve semantic parity.

## 6 · Standing and authority

### 6.1 Standing states

```text
NONE
EXPERIMENTAL
EARNED
FAILED
REVOKED
```

### 6.2 Standing scope

Every non-`NONE` state names its evidence scope, such as:

```text
house-authored public controls
house-authored blind controls
external blind controls
specific domain benchmark
specific deployment environment
```

Standing never extends beyond its evidence base by implication.

### 6.3 Verdict authorization

Every receipt contains:

```text
standing
standing_scope
verdict_authorized : bool
boundary_use
```

A receipt may publish findings with `verdict_authorized = false`.

### 6.4 Promotion and revocation

Promotion requires new evidence under declared policy.

Revocation occurs when:

```text
CM or implementation digest changes
an anchor is invalidated
consistency falls below policy
a prohibited effect is discovered
a stronger counterexample defeats the admission basis
authorization expires
```

## 7 · Refusal rules

The runtime refuses rather than improvises when:

```text
CM does not apply to the input
required evidence is missing or unreadable
path escapes the declared root
inclusion cycle is detected
input breaks framing or serialization
required relation or transformation is untyped
path contract is missing for a claimed succession
STATE_LINKED emission violates its source/successor pole law
behavior mode is undeclared or unsupported
functor action or law is incomplete
pointed-state or articulation interface is missing
approximation contract is missing
search orchestration is undeclared
relation or generator search cannot support the requested claim
held-out boundary is compromised
uncertainty is ungrounded for a standing-bearing claim
provider output fails schema or evidence validation
resource or permission limits are exceeded
```

Stable path-related refusal codes are:

```text
PATH_CONTRACT_UNDECLARED
PATH_COHERENCE_VIOLATION
```

A refusal receipt includes:

```text
stage
reason code
human explanation
evidence references
retry conditions
standing effect
```

## 8 · Reproducibility

### 8.1 Digests

Record digests for:

```text
CM source
CompiledCM
implementation
input
observation constructors
relation and generator search implementations
search orchestration
provider/model/prompt when used
calibration set
policy
path contract
behavior contract
approximation contract
receipt schema
```

### 8.2 Deterministic core

Parsing, typechecking, path resolution, coverage, derivation, classification, and rendering are deterministic for the same declared inputs.

Non-deterministic witnesses are isolated and sampled under a declared repeat protocol.

### 8.3 Raw evidence

Raw provider output and raw observation references are retained or content-addressed according to policy, including failed validations.

### 8.4 No post-failure substitution

After an evidence-producing path begins, its failure is terminal for that path. A separately declared fallback records the mode change and cannot represent its result as if it came from the failed path.

## 9 · Minimum report schema

Every report exposes:

```text
receipt_id
receipt_schema_version
CM identity and digests
compiled and authorization digests
target identity and input digests
measurement mode
coverage manifest
path-contract digest
behavior contract
approximation-contract digest
α receipt
β receipt
γ receipt
coherence disposition
fit, bounded, passing, failing, and unresolved realization-candidate references
training/test fibers and refinement map
training and test candidate classifications
identification target
test and oracle status
model and lift status
standing and verdict authorization
uncertainty and grounding
provenance
refusal, if any
```

Large artifacts may be omitted only by content-addressed reference.

## 10 · Conformance

The normative proof obligations for Operational are defined in [`tsc-conformance.md`](tsc-conformance.md) under the `OPER-*` requirement IDs.
