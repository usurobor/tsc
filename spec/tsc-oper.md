# TSC Operational v4 — Methodology Lifecycle and Authorized Measurement

**Version:** 4.0.0
**Status:** Draft
**Artifact:** Normative runtime contract

## 0 · Governing question

> How does a methodology move from authored source to authorized measurement without collapsing structural validity, instrument quality, standing, and boundary authority into one decision?

TSC Operational separates compilation, bounded execution, instrument assessment, admission, authorization, target execution, and receipt emission.

---

## Primitive contract

A Coherence Methodology declares a generator problem:

```text
CM := (
  identity,
  input and observation contract,
  generator class,
  relation and equivalence contract,
  fit and approximation contract,
  complexity contract,
  oracle contract,
  receipt schema,
  implementation and permission bindings
)
```

A target measurement produces a proof-carrying receipt containing, at minimum:

```text
methodology identity
target and input identity
manifestation evidence
relational atlas
candidate-fiber status
continuation status
uncertainty and provenance
standing and verdict authorization
```

Operational governs how the methodology and receipt acquire runtime and epistemic authority.

---

## 1 · Runtime artifacts

### 1.1 CM source

`CMSource` is the human-authored methodology package.

It contains:

```text
identity and version
input and observation contract
generator class
equivalence and tolerance contract
complexity and oracle contract
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
sandbox policy
input adapters
execution plan
receipt contract
```

Compilation establishes structural executability. It grants no standing and no authority over target data.

### 1.3 Calibration receipt

`CalibrationReceipt` records bounded executions over declared controls, repeats, malformed inputs, and held-out anchors.

It carries no target-measurement authority.

### 1.4 Instrument assessment

`InstrumentAssessment` is a CM0 measurement of the candidate methodology as an instrument.

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

CM0 measures. It does not admit or authorize.

### 1.5 Admission verdict

`AdmissionVerdict` is produced by validator `V` from the admission contract and assessment evidence.

```text
PASS | FAIL
```

The verdict answers whether the evidence satisfies the declared admission policy.

### 1.6 Boundary decision

`BoundaryDecision` is produced by `δ`.

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

`δ` decides what action follows from the evidence and verdict. It does not rewrite the measurement.

### 1.7 Authorized CM

`AuthorizedCM` binds:

```text
CompiledCM digest
admission verdict
boundary decision
standing scope
permissions
validity interval
revocation conditions
```

### 1.8 Measurement receipt

`MeasurementReceipt` is the Core receipt emitted when an authorized or explicitly sandboxed CM runs on a compatible target.

---

## 2 · Authority separation

The lifecycle has five distinct authorities:

```text
compiler   → structural validity and normalized execution descriptor
CM0        → instrument measurement
V          → admission verdict
δ          → boundary action
runtime    → faithful execution and receipt emission
```

No surface may silently assume another surface’s authority.

In particular:

- successful compilation does not imply instrument coherence;
- instrument coherence does not imply external validity;
- admission does not imply production authorization;
- execution does not imply standing;
- a score does not imply a verdict;
- a verdict does not imply a boundary action.

---

## 3 · Methodology lifecycle

### 3.1 AUTHOR

Input:

```text
CMSource
```

Output:

```text
source digest
```

The source is immutable for one lifecycle attempt. A change creates a new digest and requires re-evaluation of every dependent artifact.

### 3.2 COMPILE

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
```

Output:

```text
COMPILED(CompiledCM)
```

or:

```text
COMPILE_REJECTED(diagnostics)
```

The compiler fails closed on unresolved paths, untyped relations, missing implementation bindings, undeclared effects, or incompatible adapters.

### 3.3 SANDBOX

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

### 3.4 ASSESS

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

### 3.5 VALIDATE

Validator `V` evaluates the assessment against an admission contract.

Output:

```text
AdmissionVerdict
```

The admission contract names every required witness, floor, scope, and refusal rule. Unavailable required evidence yields `FAIL`; it never becomes an inferred pass. `δ` may respond to that verdict with `hold` when policy permits later repair.

### 3.6 DECIDE

`δ` receives:

```text
CompiledCM
InstrumentAssessment
AdmissionVerdict
operator policy
```

and emits:

```text
BoundaryDecision
```

An override records:

```text
who authorized it
why it was necessary
which failed condition remains
what standing is lost
when the override expires
```

### 3.7 AUTHORIZE

A permissive boundary decision creates `AuthorizedCM`.

Authorization is scope-specific:

```text
sandbox
experimental
production
```

It may also restrict input classes, providers, resources, or output uses.

### 3.8 EXECUTE

The runtime executes the authorized CM on a target only after:

```text
applicability passes
input completeness passes
permissions pass
required evidence is readable
compiled and authorized digests match
```

Execution follows the target pipeline in §4.

### 3.9 RECEIPT

Every terminal execution state emits one receipt:

```text
success
refusal
unresolved
resource failure
provider failure
law violation
```

No silent fallback or empty green result is permitted.

---

## 4 · Target measurement pipeline

### 4.1 HANDSHAKE

Validate:

```text
CM identity and authorization
target identity
input schema
applicability
required permissions
required observation channels
```

Failure emits `NOT_APPLICABLE` or `INVALID_INPUT`.

### 4.2 COVER

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

Missing required evidence stops execution before scoring or classification.

### 4.3 OBSERVE

Construct observation episodes and the α receipt.

The runtime records:

```text
constructor identity
constructor digest
channel identity
input history
raw evidence reference
uncertainty
```

### 4.4 ATLAS

Construct the β relational atlas:

```text
correspondence maps
transformation maps
alternatives
residuals
uncertainty
path budgets
globalization checks
```

The runtime retains the maps even when it computes a summary.

### 4.5 REALIZE

Search the declared generator class under the fit and complexity contract.

Record:

```text
search algorithm and version
search claim
candidates considered
candidate references
fit values
complexity values
pruning and refusal reasons
```

### 4.6 CONTINUE

Execute held-out predictions, future-state tests, or interventions and construct the γ receipt.

A held-out item is valid only when its selection and label were unavailable to the fitting path under the declared provenance rules.

### 4.7 CLASSIFY

Derive:

```text
α status
fiber status
coherence disposition
identification status
γ continuation status
model adequacy
lift status
```

Every derived field is recomputable from the receipt or a referenced deterministic artifact.

### 4.8 EMIT

Write the complete measurement receipt and all referenced artifacts.

The runtime may render human and machine views, but both derive from one receipt model and must preserve semantic parity.

---

## 5 · Standing and authority

### 5.1 Standing states

Operational defines:

```text
NONE
EXPERIMENTAL
EARNED
FAILED
REVOKED
```

The admission policy defines the evidence needed to move between them.

### 5.2 Standing scope

Every non-`NONE` standing state names its scope, such as:

```text
house-authored public controls
house-authored blind controls
external blind controls
specific domain benchmark
specific deployment environment
```

Standing never extends beyond its evidence base by implication.

### 5.3 Verdict authorization

Every measurement receipt contains:

```text
standing
standing_scope
verdict_authorized : bool
boundary_use
```

A receipt may publish findings with `verdict_authorized = false`.

### 5.4 Promotion and revocation

Promotion requires new evidence under the declared policy.

Revocation occurs when:

- the CM digest changes;
- an anchor is invalidated;
- consistency falls below policy;
- a prohibited effect is discovered;
- a materially stronger counterexample defeats the admission basis;
- the authorization expires.

---

## 6 · Refusal rules

The runtime refuses rather than improvises when:

- the CM does not apply to the input;
- required evidence is missing or unreadable;
- a path escapes the declared root;
- an inclusion cycle is detected;
- input content breaks the framing or serialization contract;
- a required relation or transformation is untyped;
- the candidate search cannot support the requested status;
- the held-out boundary is compromised;
- uncertainty is ungrounded for a standing-bearing claim;
- provider output fails schema or evidence validation;
- resource or permission limits are exceeded.

A refusal receipt includes:

```text
stage
reason code
human explanation
evidence references
retry conditions
standing effect
```

---

## 7 · Reproducibility

### 7.1 Digests

The runtime records digests for:

```text
CM source
CompiledCM
implementation
input
observation constructors
provider/model/prompt when used
calibration set
policy
receipt schema
```

### 7.2 Deterministic core

Parsing, typechecking, path resolution, coverage, derivation, classification, and rendering are deterministic for the same declared inputs.

Non-deterministic witnesses are isolated and sampled under a declared repeat protocol.

### 7.3 Raw evidence

Raw provider output and raw observation references are retained or content-addressed according to policy, including failed validations.

### 7.4 No post-failure substitution

After an evidence-producing path has begun, its failure is terminal for that path. The runtime may start a separately declared fallback only when the receipt records the mode change and no result is represented as if it came from the failed path.

---

## 8 · Minimum report schema

Every report exposes:

```text
receipt_id
receipt_schema_version
cm_id, cm_version, cm_digest
compiled_cm_digest
authorization_digest
target identity and input digests
measurement mode
coverage manifest
α receipt
β receipt
γ receipt
coherence disposition
training/test fiber and identification status
test and oracle status
model and lift status
standing and verdict authorization
uncertainty and grounding
provenance
refusal, if any
```

A report may omit large artifacts only by content-addressed reference.

---

## 9 · Operational conformance

A runtime is conforming when the following hold.

### Lifecycle

- invalid source cannot produce `CompiledCM`;
- compiled but unassessed CMs may run only in sandbox;
- CM0 cannot admit itself or another CM;
- `V` cannot perform a boundary action;
- `δ` cannot rewrite the receipt;
- changed digests invalidate dependent authorization.

### Execution

- empty or incomplete required input produces refusal;
- coverage is content-addressed;
- structured maps survive into the receipt;
- a failed search cannot claim no realization without a complete search contract;
- failed standing prevents a verdict-bearing result;
- every terminal path emits a receipt.

### Security

- path traversal fails closed;
- inclusion cycles fail closed;
- undeclared network or file access fails closed;
- input framing cannot inject new control instructions;
- resource limits are enforced and receipted.
