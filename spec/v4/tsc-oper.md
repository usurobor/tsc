# TSC Operational v4.0.0-alpha.1 — CM Lifecycle and Receipt-Bearing Execution

**Version:** 4.0.0-alpha.1
**Date:** July 2026
**Status:** Draft
**Depends on:** C≡ v4 alpha; TSC Core v4 alpha

---

## 0. Scope

Operational v4 separates five surfaces that v3 and the early CM0 design partially conflated:

```text
compile
assess
admit
boundary-authorize
execute
```

It also defines the fail-closed lifecycle of one target measurement.

Operational does not define a universal scalar threshold. A CM may contain local numeric gates, but the runtime preserves Core’s categorical statuses and standing.

---

## 1. CM lifecycle

### 1.1 Source

A CM source package contains authored methodology matter:

```text
identity and version
input schema and adapters
generator class
observation construction
articulation/atlas/continuation obligations
metrics and tolerance calculus
complexity coding/prior
held-out oracle
sandbox and permissions
report schema
migration rules
```

### 1.2 Compile

The compiler validates and normalizes source into a runtime descriptor:

```text
CMSource → CompiledCM | CompileFailure
```

`CompiledCM` contains no epistemic authority by itself.

It records:

```text
source digest
normalized descriptor
resolved implementation/provider bindings
input and output contracts
sandbox permissions
static proof/check results
unresolved dynamic obligations
```

Compilation grants structural executability in the declared sandbox. It does not grant standing.

If the implementation chooses not to produce a normalized runtime descriptor, the operation MUST be named `check` or `assess`, not `compile`.

### 1.3 Sandbox execution

A compiled candidate MAY run before admission only in a bounded calibration/sandbox context.

Sandbox receipts carry:

```text
standing = NONE
verdict_authorized = false
purpose = calibration|consistency|discrimination|security
```

This execution is necessary to measure repeatability, discrimination, refusal behavior, and held-out performance.

### 1.4 CM0 assessment

CM0 measures the candidate CM as an instrument and emits:

```text
InstrumentAssessmentReceipt
```

CM0 does not admit its own object and does not execute the candidate’s domain measurement on behalf of the candidate.

It may observe candidate behavior on controls because the measured object remains the instrument.

### 1.5 Admission verdict

A separate validator/policy consumes:

```text
CompiledCM
InstrumentAssessmentReceipt
calibration and standing policy
```

and emits:

```text
AdmissionVerdict = PASS | FAIL | UNRESOLVED
```

### 1.6 Boundary authorization

A boundary decision applies the admission verdict:

```text
REGISTER
HOLD
REJECT
ALLOW_EXPERIMENTAL
OVERRIDE_DEGRADED
```

Compilation, assessment, verdict, and boundary action are distinct durable artifacts.

### 1.7 Authorized execution

An authorized or explicitly experimental CM may be applied to compatible target data:

```text
CompiledCM × Input → CoherenceReceipt | RefusalReceipt
```

Only results whose admission/standing policy permits it may cross a downstream operational boundary.

---

## 2. Measurement lifecycle

### HANDSHAKE

Validate:

- CM identity, digest, semantic version, and authorization;
- input schema and applicability;
- carrier/finality or approximation declaration;
- query/intervention ownership;
- sandbox permissions;
- required controls and held-out split;
- output schema.

Failure produces a refusal receipt.

### COVERAGE

Resolve required evidence and emit a content-addressed coverage manifest.

- missing required evidence → refusal;
- unreadable required evidence → refusal;
- empty observation set → refusal unless the CM explicitly defines an empty-input question;
- optional evidence is declared, never inferred from failure to read it.

### OBSERVE

Construct observation episodes and the α receipt.

The runtime records all observation-constructor versions and digests.

### ATLAS

Materialize correspondences, transformation maps, alternatives, uncertainty, local residuals, and path budgets.

The maps are retained even when a scalar residual is computed.

### REALIZE

Search the declared generator class under the complexity and fit contract.

The runtime records:

```text
search algorithm/version
search completeness class
candidate references
fit and complexity results
```

### GLOBALIZE

Evaluate the full relational diagram, not only pairwise fit.

A CM may instantiate:

- composition/cycle checks;
- global section or realization search;
- constraint solving;
- another typed globalization criterion.

Core does not hard-code one obstruction theory.

### CONTINUE

Test lawful continuation, held-out predictions, or interventions and emit the γ receipt.

A held-out query is valid only when its selection was not produced by the same candidate process in a way that leaks the answer, unless the CM explicitly tests endogenous-query behavior.

### CLASSIFY

Derive Core’s status product:

```text
observation
realizability
identifiability
continuation
model adequacy
lift
standing
```

### RECEIPT

Emit one proof-carrying receipt with all structured evidence or digest-linked artifacts.

### AUTHORITY

Apply standing and downstream policy:

```text
verdict_authorized = true | false
```

A measurement may be valid and publishable while lacking authority.

---

## 3. Fail-closed rules

The runtime MUST refuse rather than guess when:

- the CM is not applicable to the input;
- required evidence is absent;
- an input path escapes the declared sandbox;
- inclusion cycles are unresolved;
- observation delimiters or prompt framing are ambiguous;
- generator/finality assumptions are undeclared;
- tolerance and metric compatibility is missing;
- search completeness is required for a negative claim but absent;
- a supplied scalar contradicts mechanically derived structured evidence;
- standing is required but not earned.

No refusal path silently falls back to a more permissive methodology.

---

## 4. Derived-field authority

Each fact has one authoritative source.

Examples:

```text
structured maps → residuals
candidate fiber → realizability/identifiability statuses
held-out result → lift status
standing evidence → verdict_authorized
```

A witness may propose estimates. It may not provide a second authoritative value for a field the engine derives.

Contradictory supplied and derived fields produce refusal.

---

## 5. Standing

### 5.1 Separation

```text
compiled
internally valid
consistent
calibrated
has standing
verdict authorized
```

are distinct states.

### 5.2 Immediate authority-withholding rule

Any CM or witness with `standing = NONE | FAILED` emits:

```text
status = unresolved_for_authority
verdict_authorized = false
```

while retaining useful findings.

### 5.3 Promotion

Generic promotion semantics depend on:

- CM identity and digest;
- calibration basis;
- consistency and discrimination results;
- held-out and external-anchor provenance;
- semantic compatibility and migration lineage.

Promotion MUST NOT be inferred from a self-score alone.

---

## 6. Query and intervention modes

Every run records:

```text
query_mode
exogenous channel
endogenous query mechanism
randomization source
apparatus/operator boundary
input history
```

### 6.1 Passive prediction

Can falsify predictive adequacy.

### 6.2 Active identification

May distinguish candidates equivalent under passive observations.

### 6.3 Causal claim

Requires the CM to state the causal assumptions under which intervention differences warrant causal attribution.

The intervention is external to the tested model boundary, not claimed to be outside the larger world.

---

## 7. Approximation and error budgets

A run carries:

```text
local error entries
path-tolerance monoid and operation
path length/history
accumulated budget
behavioral metric/pseudometric
observed endpoint distance
compatibility verdict
grounding for every nonzero inflation
```

Composition cannot improve grounding quality without new evidence.

Longer paths are not mechanically penalized by a fixed tolerance unless the CM declares that policy and its consequence.

---

## 8. Lift protocol

A lift compares a smaller declared generator class `H₀` with a richer preregistered class `H₁`.

Required artifacts:

```text
pre-lift receipt under H₀
measured insufficiency/obstruction
H₁ registration and complexity rule
held-out oracle commitment
post-lift receipt
complexity-adjusted improvement
prediction/intervention result
```

Possible results:

```text
LIFT_PROPOSED
LIFT_VALIDATED
LIFT_REJECTED
UNRESOLVED
```

A larger class fitting the training observations is insufficient.

---

## 9. Report contract

Every report contains at least:

```json
{
  "schema": "tsc-receipt/4.0.0-alpha.1",
  "cm": {"id":"...","version":"...","digest":"..."},
  "compiled_cm_digest": "...",
  "input_digest": "...",
  "coverage": {"status":"complete","manifest_digest":"..."},
  "query": {"mode":"mixed","intervention_scope":"..."},
  "alpha": {},
  "beta": {},
  "gamma": {},
  "status": {},
  "presentation": {},
  "behavior": {},
  "semantic_witness": {},
  "standing": "NONE|EXPERIMENTAL|EARNED|FAILED",
  "verdict_authorized": false,
  "optional_summary": null,
  "provenance": {}
}
```

Large candidate sets, maps, traces, and proofs may be content-addressed external artifacts, but their digests and retrieval contract are mandatory.

---

## 10. Artifact roles

Operational v4 distinguishes:

```text
illustration
  teaches a conceptual framing; no normative expected result

regression fixture
  pins implementation behavior; does not establish construct validity

conformance fixture
  has an independent generator/oracle and can falsify the implementation

calibration anchor
  has label provenance and standing scope

experiment
  has preregistration, intervention/held-out design, and result lineage
```

An artifact MUST declare exactly one primary role. Reuse across roles requires explicit provenance and a statement of which claims are and are not inherited.
