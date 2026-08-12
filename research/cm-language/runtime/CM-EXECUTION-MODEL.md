# CM Execution Model: JSON Property Graph and `coh` Runtime

Status: proposed foundational design; exact wire details may be clarified by implementation evidence before ABI freeze  
Scope: executable JSON IR, linking, execution, evidence, and verification  
Deferred: `.cm` surface syntax and compiler implementation  
Authority: review candidate until accepted through the project-native review path

## Decision

TSC will make a JSON execution model work before extending the `.cm` compiler.
The compiler will later lower `.cm` into this model; it will not define a second
runtime ontology.

The executable heart of a CM is a finite typed directed acyclic graph of
property checkers. Every checker has the same logical execution envelope, while
its input, output, configuration, evidence, capability, and bound contracts are
parametric and explicit.

A complete CM is slightly more than that graph:

> A CM is a governing question, a typed property-checker graph, a declarative
> result derivation, an evidence-bearing receipt contract, and any warrant
> obligations required to support its claims.

This distinction is load-bearing. Checkers produce local facts and evidence.
They do not set the CM's final result. `coh` executes the graph, evaluates the
CM-owned result rule, and emits a `MeasurementReceipt` that a verifier can
recompute and accept or refuse.

## Why this is the next boundary

The repository contains two useful but incomplete execution witnesses:

- `coh-min` loads a hand-authored `NormalizedCMIR`, links a small plan, executes
  an input-sensitive `file.exists` check, and emits a verified receipt. Its
  result derivation and checker dispatch are still CM-specific OCaml.
- Ascent-0 executes a seven-provider graph with retained alternatives, phase
  ordering, oracle evidence, and result-specific receipt constraints. Its
  runtime contracts are local to that CM family.

Those witnesses constrain the general model from opposite directions. An
ordinary repository check proves that the model is usable. Ascent-0 proves that
it can retain alternatives, respect phase barriers, carry stronger evidence,
and discharge Core-grounded warrant obligations. Neither witness alone is a
sufficient ABI-freeze test.

The immediate engineering objective is therefore:

```text
JSON CM -> generic linker -> generic checker DAG runtime
        -> declarative result evaluator -> MeasurementReceipt -> verifier
```

A CM must be addable as data plus provider implementations. Adding a second CM
must not require a `cm_id` branch, a new CM-specific classifier, or a hand-wired
execution pipeline in `coh`.

## First principles

### 1. Measurement, not mutation

A CM may observe, calculate, judge, invoke a child CM, consult a bounded oracle,
or apply a pure transform. It does not admit, merge, release, repair, mutate the
measured project, or exercise project authority. Actors, CNOS, and CDS retain
those powers.

### 2. Explicit dataflow

Edges carry typed values or artifact references. Dependencies are derived from
input bindings, not hidden provider calls or shared mutable state. A node becomes
ready only when its required inputs are available.

### 3. Bounded execution

The v0 graph is finite and acyclic. Every checker declares its resource and
capability envelope. Recursion, mutation, unbounded loops, and unrestricted
general-purpose control flow are absent. Bounded collection operators may be
added only with explicit size and depth limits.

### 4. Evidence before claim strength

A result class may require warrant obligations. Providers must produce the
declared evidence; the runtime must retain it; the verifier must refuse a result
whose evidence does not discharge the required obligations. TSC Core supplies
the semantic and warrant foundation. It is not a separate runtime stage.

### 5. Recomputable results

The final result is a pure, total, bounded function of named run facts and
retained evidence predicates. Narrative derivation text is documentation, not
execution.

### 6. Fail closed

Missing bindings, undeclared capabilities, schema mismatches, digest mismatches,
unsupported strong claims, and non-recomputable derivations are refusal or
verification failure. They are never silently downgraded into success.

## Core ontology

| Concept | Owns | Does not own |
|---|---|---|
| Property | The local question or fact to be established | Provider selection |
| Checker requirement | Typed interface, capability class, schemas, evidence, bounds | Concrete implementation identity |
| Provider | One implementation of a checker capability | CM result authority |
| `NormalizedStep` | The check the normalized CM requires | Host-specific grants or paths |
| `SandboxPlanStep` | The selected provider, adapters, grants, and discharge proof | New methodology semantics |
| `RunRequest` | Exact CM, subject artifacts, parameters, profile, and ceilings | Host-local artifact identity |
| `CheckOutcome` | Local status, outputs, evidence, provenance, diagnostics | Final CM result |
| Result rule | Exactly one declared CM result from run facts | Provider effects |
| `MeasurementReceipt` | Request/IR/plan binding, trace, evidence, derivation witness, obligations | Mutation or admission authority |

“Property checker” is the unifying runtime role. Mechanical tools, LLM-backed
judges, child CMs, oracle adapters, and pure transforms implement different
checker classes through one envelope; they are not forced to share one concrete
payload type.

## Artifact pipeline

```text
.cm source (later)
       |
       v
NormalizedCMIR JSON  <---- authored directly during JSON-first phase
       |
       | + RunRequest + provider registry + host policy
       v
linker
       |
       v
SandboxExecutionPlan
       |
       v
checker DAG runtime
       |
       v
pure result evaluator
       |
       v
MeasurementReceipt
       |
       v
receipt verifier
```

Normalization and linking are deliberately different moments:

- normalization resolves source syntax, defaults, symbols, imports, and schemas
  into concrete methodology requirements;
- linking selects concrete providers and host adapters for one `RunRequest`, then
  proves that the plan satisfies the normalized requirements without granting
  more authority than was declared.

`CompiledCM` is not a second execution ontology. It is deferred. If later useful,
it may be a content-addressed cache/envelope around normalized IR and reusable
link metadata. The per-run `SandboxExecutionPlan` remains the only concrete
execution binding.

## JSON document family

The names and semantics below are the backbone for `tsc-cm-ir/0.2`. Field
spelling may be refined when the CUE schema and two-sided fixtures are built, but
implementations must preserve the boundaries between these objects.

### `NormalizedCMIR`

The normalized IR is closed, concrete, portable, and content-addressed. It
contains no measurement result and no concrete provider binding.

```json
{
  "format": "tsc-cm-ir/0.2",
  "cm": {
    "id": "example.repo-basics",
    "version": "0.1.0",
    "source_digest": "sha256:..."
  },
  "question": "Does the repository expose the required entry documentation?",
  "inputs": {},
  "steps": [],
  "result": {},
  "receipt": {},
  "permissions": {}
}
```

Required top-level semantics:

- `cm` identifies the methodology and its source lineage.
- `question` is the governing measurement question.
- `inputs` declares named, typed subject inputs.
- `steps` is the finite checker DAG.
- `result` declares the result vocabulary, executable rules, and warrant
  obligations.
- `receipt` selects one closed receipt family and its evidence contract.
- `permissions` is the maximum capability/resource envelope normalization allows
  the linker to request.

### `NormalizedStep`

```json
{
  "id": "readme_exists",
  "kind": "mechanical",
  "checker": {
    "capability": "fs.file-exists",
    "interface": "tsc-checker/0.1"
  },
  "inputs": {
    "root": {
      "from": { "input": "repository" },
      "schema": "tsc://schema/directory-artifact/0.1"
    }
  },
  "outputs": {
    "present": { "schema": "tsc://schema/boolean/0.1" }
  },
  "config": { "relative_path": "README.md" },
  "evidence": {
    "schema": "tsc://schema/file-observation/0.1",
    "required": true
  },
  "capabilities": {
    "request": ["subject.fs.read"]
  },
  "bounds": {
    "wall_time_ms": 1000,
    "output_bytes": 4096
  },
  "failure_policy": {
    "refused": "fact_unavailable",
    "incomplete": "fact_unavailable",
    "failed": "run_failed"
  }
}
```

Rules:

- `id` is unique within the CM.
- `kind` is one of `mechanical`, `semantic_judgment`, `invoke_cm`, `oracle`, or
  `transform`.
- `checker.capability` identifies what must be implemented; it does not select
  who implements it.
- Every input binds either a CM input or one named output port of another step.
  Those bindings define the graph edges.
- Every input, output, and evidence payload has an explicit schema.
- `config` is methodology-owned and portable. Host locators, credentials, and
  concrete provider configuration do not belong here.
- Requested capabilities and bounds are ceilings, not grants.
- `failure_policy` maps a checker outcome into run-fact availability or run
  status. It must not directly select a CM result class.

The existing `#TypedStep` and runtime-private step shapes mix requirement and
binding. They are migration sources, not the final executable step contract.
The existing `failure -> ResultClass` shortcut is superseded because it gives a
node hidden authority over the CM result.

### `RunRequest`

The run request is a first-class, canonical, content-addressed artifact.

```json
{
  "format": "tsc-run-request/0.1",
  "cm_ir": { "kind": "normalized_cm_ir", "digest": "sha256:..." },
  "subject": {
    "repository": { "kind": "directory_snapshot", "digest": "sha256:..." }
  },
  "profile": "default",
  "parameters": {},
  "capability_ceiling": ["subject.fs.read"],
  "bounds": {
    "wall_time_ms": 10000,
    "child_cm_depth": 4,
    "child_cm_calls": 32,
    "evidence_bytes": 10485760
  }
}
```

Artifact digests identify inputs. Local paths, mount points, URLs, credentials,
and process handles are locators supplied by the host during linking; they do
not replace content identity. Repeating the same request may create a new
execution id, but must not change the canonical request digest.

### `SandboxExecutionPlan`

The plan is the linker's closed, concrete answer for one request.

```json
{
  "format": "tsc-sandbox-plan/0.1",
  "request_digest": "sha256:...",
  "cm_ir_digest": "sha256:...",
  "steps": [
    {
      "step_id": "readme_exists",
      "provider": {
        "id": "coh.fs.file-exists",
        "version": "0.1.0",
        "digest": "sha256:..."
      },
      "adapters": {
        "root": { "kind": "readonly_directory", "handle": "subject:repository" }
      },
      "grants": ["subject.fs.read"],
      "limits": { "wall_time_ms": 1000, "output_bytes": 4096 },
      "discharge": {
        "checker_interface": true,
        "input_schemas": true,
        "output_schemas": true,
        "evidence_schema": true,
        "capability_subset": true,
        "bounds_within_request": true
      }
    }
  ]
}
```

The linker must establish all of the following before execution:

1. every normalized step has exactly one binding;
2. the provider implements the required checker interface and capability class;
3. input, output, and evidence schemas are compatible;
4. grants are sufficient and do not exceed both the step request and the
   `RunRequest` ceiling;
5. plan limits are within normalized and request bounds;
6. every artifact adapter is confined to its declared subject surface;
7. provider identities and executable artifacts are pinned by version and
   digest.

Any unproved obligation refuses linking. Missing capability and excess
capability are both errors.

## Uniform checker contract

The logical interface is:

```text
execute(CheckRequest<Input>) -> CheckOutcome<Output, Evidence>
```

`CheckRequest` contains only the step's declared view:

```json
{
  "format": "tsc-check-request/0.1",
  "execution_id": "...",
  "step_id": "readme_exists",
  "input_refs": {},
  "config": {},
  "bounds": {},
  "grants": []
}
```

`CheckOutcome` has one closed status and typed payloads:

```json
{
  "format": "tsc-check-outcome/0.1",
  "status": "success",
  "outputs": {},
  "evidence": [],
  "provenance": {
    "provider_digest": "sha256:...",
    "request_digest": "sha256:..."
  },
  "usage": {},
  "diagnostics": []
}
```

The status is exactly one of:

- `success`: declared outputs and required evidence are present and valid;
- `incomplete`: the checker ran but could not establish its contracted fact;
- `refused`: policy, capability, bound, or epistemic conditions lawfully
  prevented the check;
- `failed`: the checker or adapter malfunctioned.

Only `success` may populate normal output ports. All statuses may retain
diagnostic evidence. The runtime validates the outcome against the step
contracts before making any output available downstream.

A provider cannot see undeclared subject data, grant itself capabilities,
invoke arbitrary peers, mutate shared state, or notarize the CM's final result.
If a provider returns a final result field, `coh` rejects or ignores it according
to the closed checker schema; it never treats it as authoritative.

## Graph execution semantics

1. The normalized graph must be finite and acyclic. Duplicate ids, unresolved
   ports, and schema-incompatible edges fail validation.
2. A step is ready when every required input is available and its plan binding is
   valid.
3. Ready steps may execute concurrently. Observable results must not depend on
   scheduling order; receipts record actual ordering for audit.
4. A successful, schema-valid outcome publishes its named output ports as
   immutable run facts.
5. `incomplete`, `refused`, and `failed` outcomes are retained as run facts and
   processed through `failure_policy`. Required downstream inputs that cannot be
   produced cause principled `skipped` trace entries, never fabricated values.
6. The runtime terminates when every step is terminal (`success`, `incomplete`,
   `refused`, `failed`, or `skipped`) or a run-level bound is reached.
7. The result evaluator then runs exactly once over the immutable fact set.

The initial model has no general conditional nodes. Conditional progress is
expressed by typed output availability: for example, a semantic checker may
withhold an `admissible_proposal` output, causing realization steps that require
it to be skipped. The result rule interprets that trace explicitly.

## Declarative result semantics

`result` declares a closed vocabulary and an ordered, total rule table:

```json
{
  "classes": ["README_PRESENT", "README_ABSENT", "INCOMPLETE"],
  "rules": [
    {
      "id": "incomplete-run",
      "when": { "not": { "step_status": ["readme_exists", "success"] } },
      "emit": "INCOMPLETE"
    },
    {
      "id": "present",
      "when": { "eq": [{ "fact": "readme_exists.present" }, true] },
      "emit": "README_PRESENT"
    }
  ],
  "default": { "id": "absent", "emit": "README_ABSENT" }
}
```

Semantics:

- rules are evaluated in declaration order;
- the first matching rule emits the result class;
- exactly one terminal `default` is required, making evaluation total;
- every emitted class must be in `classes`;
- expressions are pure JSON ASTs over immutable run facts;
- the v0 algebra contains finite boolean operations, equality and ordered
  comparisons, presence/status predicates, and bounded `count`, `all`, and `any`;
- provider calls, mutation, recursion, dynamic code, unbounded iteration, and
  host access are forbidden;
- the evaluator records the matched rule id and the exact fact/evidence digests
  it read;
- the verifier recomputes the result from the receipt and refuses a mismatch.

Ordered first-match plus a mandatory default is the foundational v0 choice. It
is intentionally smaller than a general expression language. Static linting
should warn about unreachable or shadowed rules, but the execution semantics are
unambiguous even before such linting is complete.

## Warrant obligations

A result class may declare obligations that are stronger than ordinary output
schema validity:

```json
{
  "class": "LIFT_VALIDATED",
  "requires": [
    "retained_alternatives.before_result",
    "oracle.commit_before_reveal",
    "oracle.separates_candidates",
    "roundtrip.supported"
  ]
}
```

The compiler or normalizer elaborates warrant-bearing language constructs into
these obligations. The linker proves that selected providers can produce the
required evidence. The runtime retains it. The verifier applies the closed
obligation rules. A strong class with absent or contradictory evidence is
invalid even if the result-rule AST would otherwise emit it.

The initial obligation catalog should include only what the ordinary CM and
Ascent-0 fixtures exercise. It can grow under versioning; an unknown obligation
is not treated as discharged.

## `MeasurementReceipt`

The receipt is a closed common core plus one closed, discriminated family
extension.

```json
{
  "format": "tsc-measurement-receipt/0.1",
  "execution_id": "...",
  "request": { "digest": "sha256:..." },
  "cm_ir": { "digest": "sha256:..." },
  "plan": { "digest": "sha256:..." },
  "runtime": { "id": "coh", "version": "...", "digest": "sha256:..." },
  "trace": [],
  "evidence": [],
  "result": {
    "class": "README_PRESENT",
    "rule_id": "present",
    "fact_refs": []
  },
  "obligations": [],
  "extension": {
    "family": "repository_measurement",
    "schema": "tsc://receipt/repository-measurement/0.1",
    "value": {}
  }
}
```

The common core binds:

- exact request, normalized IR, plan, runtime, and provider identities;
- all step outcomes, principled skips, failures, refusals, and coverage;
- an evidence manifest with content digests and provenance;
- the runtime-derived result and derivation witness;
- declared obligations and their evidence-backed discharge state.

The extension carries family-specific evidence. Ordinary repository
measurements and Ascent receipts share the core but use different closed
extensions. A loose map of optional blocks is forbidden: the result and family
discriminants determine which evidence is required.

Receipt verification is a separate operation from receipt creation. It checks
schemas and digests, replays the pure result rule, validates trace/plan
consistency, and applies obligation rules. Static CUE validation alone is not a
runtime verification claim.

## Child CMs and recursion

`invoke_cm` is a checker kind. Its provider constructs a child `RunRequest` from
declared parent inputs and returns a child `MeasurementReceipt` as evidence. The
parent may consume only projections declared in the child checker's output
schema; it does not inherit the child's authority or bypass its verifier.

Recursion is bounded by:

- a maximum child depth and call count in the `RunRequest`;
- a digest stack that refuses direct or indirect cycles;
- explicit input/output schemas at every boundary;
- a requirement that recursive composition eventually reaches primitive
  mechanical, judgment, oracle, or transform providers.

## Provider linking and the useful part of Spring

Spring's inversion-of-control model is a useful secondary analogy: the CM
declares what checker capability it needs, and the linker injects a concrete
provider. The plan is the explicit, immutable equivalent of the resulting
wiring. Profiles may influence selection, but the selected provider, version,
digest, adapters, and grants are recorded.

The model deliberately does not inherit Spring's reflective autowiring, mutable
application context, lifecycle callbacks, AOP interception, implicit global
configuration, or circular dependencies. Reproducible measurement requires
explicit wiring and a closed plan.

For the graph itself, the Common Workflow Language is the closer precedent:
typed ports, explicit dataflow, and bounded workflow execution. TSC adds the
parts a generic workflow model does not supply: methodology-owned judgment,
warrant obligations, fail-closed provider capabilities, retained evidence, and
independently verifiable measurement receipts.

## Acceptance gates

The execution model is not ready to freeze until all of these are executable:

1. **Genericity:** two structurally different ordinary CMs run through the same
   parser, linker, scheduler, result evaluator, receipt writer, and verifier
   without `cm_id` dispatch or a CM-specific classifier.
2. **Graph behavior:** at least one CM contains independent steps and a dependent
   step, proving typed edges, readiness, principled skip behavior, and
   scheduling-independent results.
3. **Input sensitivity:** changing a measured subject changes retained evidence
   and the verified result where the CM says it should.
4. **Link safety:** missing capabilities, excess grants, provider digest
   mismatch, unresolved adapters, and schema-incompatible edges fail closed.
5. **Result honesty:** undeclared classes, non-total rules, result/witness
   mismatch, and provider-supplied final results are rejected.
6. **Evidence honesty:** a strong result missing required evidence is rejected.
7. **Confinement:** path escape and undeclared subject access are denied and
   retained in the trace.
8. **Two-sided ABI proof:** an ordinary check-style CM and Ascent-0 both run
   through this artifact family before the shared ABI is frozen.

The Ascent gate is structural, not a claim that Ascent-0 proved blind-LLM
generative correctness. It historically proved firewall-safe mechanism-side
identification; that scope remains unchanged.

## Implementation order

1. Accept this execution model as the bounded design backbone for the M1
   contract work.
2. Define closed CUE/JSON schemas for `NormalizedCMIR`, `RunRequest`,
   `SandboxExecutionPlan`, checker request/outcome, and `MeasurementReceipt`.
3. Convert the current README fixture and add a second structurally different
   ordinary CM plus negative fixtures.
4. Implement one generic `coh` parser, linker, DAG scheduler, rule evaluator,
   receipt writer, and verifier. Delete CM-specific result classification and
   dispatch from the acceptance path.
5. Execute a proper multi-check repository CM from JSON.
6. Add the `.cm -> NormalizedCMIR` compiler against the proven JSON target.
7. Reproduce Ascent-0 through the same ABI, repair any lost evidence or phase
   semantics, and only then freeze the shared contract.

## Deferred decisions

The following are intentionally outside the foundational v0 backbone:

- exact `.cm` syntax and compiler architecture;
- package registry, dependency resolution, and remote distribution;
- remote provider transport and CNOS-host protocol;
- cross-run cache semantics;
- unrestricted scatter/gather or streaming collection dataflow;
- a complete Core warrant-obligation catalog;
- signature and transparency-log policy;
- whether a reusable `CompiledCM` cache is worth introducing.

Deferral does not make these free-form extension points. Until versioned, they
are absent and must fail closed if encountered.

## Design invariants

The implementation is conformant only while these statements remain true:

- JSON is the executable IR; `.cm` is a later authoring language that lowers to
  it.
- A CM's executable heart is a finite typed property-checker DAG.
- Every checker uses one logical envelope with explicit typed contracts.
- Properties and checker requirements are distinct from provider
  implementations.
- Normalized requirements are distinct from linked plan bindings.
- Checkers produce facts and evidence; the CM-owned rule produces the result.
- Results are pure, total, bounded, and independently recomputable.
- Strong claims are limited by retained evidence and discharged obligations.
- `MeasurementReceipt` is the evidence-bearing output boundary.
- CMs measure; actors and project-native processes retain mutation and authority.
- Ordinary-CM usability and Ascent-0 evidence semantics jointly constrain the
  ABI before freeze.

