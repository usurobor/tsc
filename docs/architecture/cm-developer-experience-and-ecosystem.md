# TSC — CM Developer Experience and Ecosystem Architecture
**Vision Draft 0.2**

Status: architecture vision under review — Sigma review applied and converged with Pi in the runtime-implementation dialogue. Not TSC project authority until promoted into a main-reachable artifact. **Subordinate to `docs/product/NORTH-STAR.md`** (generative reasoning remains TSC's identity; this note is the ecosystem layer beneath it) and **reconciles with `docs/product/DIRECTION.md`**.
Basis: the converged Pi–Omega–Sigma dialogue on methodology-as-code, Core semantics, the general CM runtime, and the two-sided ordinary-CM / Ascent-0 kernel.

## Governing sentence

TSC is becoming a language and runtime for executable judgment: methodologies compile, properties compose recursively, primitive providers form the effect boundary, and typed receipts preserve what the evidence warrants—and what it does not.

Repository Coherence is the first package and calibration domain. It is not the identity of TSC.

## 0. Why this note starts with developer experience

Architecture should be derived from the experience we want to make possible, not from the accidental shape of today’s research tree.

The target experience is ordinary software development:

- start a CM project;
- install existing methodology, property, provider, schema, and fixture packages;
- state one governing question in a top-level CM;
- compose existing properties where they fit;
- leave explicit typed holes where the methodology is not yet understood;
- progressively decompose high-level properties into smaller child CMs;
- terminate only at primitive mechanical, semantic/LLM, oracle, or pure-transform effects;
- compile, test, run, inspect, and verify receipts;
- publish the resulting package for others to reuse.

This is closer to a synthesis of npm/NuGet/Maven/Cargo, a typed functional language, a build system, and proof-oriented development than to a checklist engine.

## 1. The end-to-end CM developer journey

The command names and manifest filename below are illustrative. The workflow and boundaries are the proposal; exact spellings remain implementation decisions.

### 1.1 Install the toolchain

The developer installs two distinct tools:

- `cn`: project, package, registry, environment, and host integration;
- `coh`: CM compiler, linker, runtime, and receipt verifier.

The separation is intentional. A runtime must not depend on the package manager for its semantics, just as Node can execute JavaScript without npm being online and the JVM can execute bytecode without Maven.

### 1.2 Create a CM project

    cn init cm acme-repository-coherence
    cd acme-repository-coherence

Illustrative generated tree:

    acme-repository-coherence/
    ├── cn.toml                  # package manifest; exact filename TBD
    ├── cn.lock                  # exact dependency/provider digests
    ├── src/
    │   └── Main.cm             # package entry CM
    ├── tests/
    │   ├── fixtures/
    │   └── expected/
    ├── schemas/
    └── README.md

The manifest declares at least:

- package identity and version;
- package kind;
- entry CM;
- target types;
- CM/property dependencies;
- provider capability dependencies;
- schema and fixture dependencies;
- compatibility constraints;
- publication metadata.

### 1.3 Find and install a relevant methodology

A developer should rarely begin from a blank universe. They search the registry for the closest existing articulation:

    cn search cm "repository coherence"
    cn add @tsc/repository-coherence

That package may already define child CMs such as Legibility, Structure, or Operability. The developer composes it; they do not need to inherit from an opaque framework class.

They may also install a CM0 package as a development dependency:

    cn add --dev @tsc/cm0

The domain CM asks whether the target is coherent under the declared methodology. CM0 asks whether the methodology/provider instrument deserves trust. Those are separate questions.

### 1.4 Install reusable property libraries

    cn add @tsc/property-legibility
    cn add @tsc/property-structure
    cn add @tsc/property-operability

A property package states what is being assessed and how results derive from evidence. A property is not the same thing as its provider implementation.

### 1.5 Install primitive provider implementations

    cn add @cn/provider-git
    cn add @cn/provider-schema
    cn add @cn/provider-llm
    cn add @cn/provider-child-cm

This distinction is load-bearing:

- property / child CM = what question is being answered;
- provider = how a primitive observation, cognition step, oracle call, or transform is performed;
- runtime = what links, schedules, bounds, caches, executes, and records those providers.

Calling every package a “property provider” would collapse the methodology/effect boundary. CN should support multiple package kinds, even if all are distributed through one registry.

### 1.6 Write the top-level CM

Illustrative F#-influenced syntax—not a syntax freeze:

    module Acme.RepositoryCoherence

    let main target = cm {
        question
            "What makes this repository coherent for a technical newcomer
             and safe for routine engineering operation?"

        let! legibility = run Repository.Legibility target
        and! structure  = run Repository.Structure target

        and! operability =
            unresolved<AspectReceipt>
                "Operability is declared but not yet decomposed."

        return
            compose {
                retain [ legibility; structure; operability ]
                precedence [ Failed; Incomplete; Defect; Pass ]
            }
    }

This source already expresses a valid methodology shape even though one property is not implemented.

The hole is not a hidden TODO and is never interpreted as success. It is typed, named, visible in build output, and becomes explicit incomplete coverage in any run receipt.

### 1.7 Build while the methodology is still incomplete

    coh cm build

The build performs:

- package and import resolution;
- parsing and type checking;
- property/provider capability checking;
- elaboration of any TSC Core obligations required by strong constructs;
- normalized CM IR generation;
- typed-hole reporting;
- deterministic dependency locking.

A build may succeed structurally while reporting unresolved methodology holes. A run that reaches such a hole yields `INCOMPLETE`, not `PASS` and not a runtime crash.

This is analogous to typed-hole-driven development: the developer starts from the whole question and progressively makes each missing articulation explicit.

### 1.8 Gradually unpack high-level properties

The developer next opens Operability and asks what it means in this problem domain:

    let operability target = cm {
        question "Can a newcomer build, test, and run this repository?"

        let! build = Build.succeeds target
        and! tests = Test.succeeds target
        and! runbook = Semantic.judge {
            evidence = Documentation.localSetup target
            question = "Can the declared procedure be followed from a fresh checkout?"
            bounds = SemanticBounds.singleArtifact
        }

        return
            derive {
                pass when build.pass && tests.pass && runbook.supported
                defect from [ build.findings; tests.findings; runbook.findings ]
                incomplete when anyIncomplete [ build; tests; runbook ]
                failed when anyExecutionFailed [ build; tests; runbook ]
            }
    }

Each of those operations may itself be:

- another reusable CM;
- a locally defined child CM;
- a primitive mechanical provider;
- an isolated semantic/LLM provider;
- an oracle provider;
- a pure typed transform;
- an explicit refusal or unresolved hole.

Recursive decomposition stops only at primitive effects. Everything above the primitive boundary remains inspectable CM source.

### 1.9 Test the methodology as code

    coh cm test

A serious CM package carries:

- positive fixtures;
- negative fixtures;
- incomplete-evidence fixtures;
- provider-failure fixtures;
- refusal fixtures;
- deterministic source-to-IR checks;
- result-derivation checks;
- regression fixtures from real failures;
- CM0 assessment evidence when maturity requires it.

The developer can test the methodology without running it against a private production target.

### 1.10 Run against an exact target

    coh cm run \\
      --target git:https://example/repo.git@<commit-sha> \\
      --profile technical-newcomer

Conceptual pipeline:

    .cm source
      → normalized CM IR
      → exact RunRequest
      → provider linking
      → SandboxExecutionPlan
      → bounded execution
      → MeasurementReceipt
      → independent receipt verification

Every run is bound to exact methodology, target, provider, schema, instruction/model, runtime, and package digests.

### 1.11 Inspect and verify the receipt

    coh receipt show runs/<run-id>.json
    coh receipt verify runs/<run-id>.json

The receipt preserves:

- target snapshot;
- methodology and dependency versions;
- provider identities and capabilities;
- evidence and evidence references;
- coverage and unobserved surfaces;
- alternatives retained before lawful collapse;
- refusals, truncation, and search strength;
- per-step failures;
- result derivation;
- the final categorical result;
- optional downstream score projections without making those projections authoritative.

### 1.12 Publish the package

    cn publish

Another developer can now install the methodology, extend it by composition, replace provider implementations while preserving capability contracts, rerun it against another exact target, or consume its receipts in a dashboard or authorized engineering workflow.

## 2. The core concepts a CM developer learns

The language should have a small conceptual vocabulary.

### 2.1 CM / methodology

An executable, versioned inquiry that defines:

- a governing question;
- accepted target and scope;
- required properties or child CMs;
- provider-bound observations;
- evidence and refusal contracts;
- result derivation;
- receipt shape.

### 2.2 Property

A checkable claim or question about a target. A nontrivial property should normally be represented as a CM so it can decompose recursively and emit its own receipt.

### 2.3 Provider

A primitive implementation of bounded observation, cognition, oracle access, or pure transformation. Providers do not receive authority merely because they can produce a result-shaped value.

### 2.4 Receipt

The immutable, typed handoff from measurement to a consumer. A receipt records evidence and derivation; it does not itself merge, repair, release, or authorize.

### 2.5 Profile / policy

A declared parameter selecting audience, thresholds, query family, environment, or organizational policy without silently rewriting the methodology after evidence is observed.

### 2.6 CM0

A methodology that assesses a CM/provider instrument for repeatability, discrimination, refusal, source/IR/implementation integrity, and evolution behavior. CM0 does not admit itself and does not replace external authorization.

### 2.7 Actor / CDS layer

The layer that creates or changes artifacts and holds lifecycle authority. It may consume CM receipts to decide whether to revise, dispatch, merge, release, or refuse. That authority remains outside the CM runtime.

## 3. One registry, multiple package kinds

`cn` is analogous to npm, NuGet, Maven, or Cargo only at the package-ecosystem level. The TSC ecosystem needs a richer kind system than “everything is a provider.”

Proposed package kinds:

1. Methodology package
   - top-level or composite CMs;
   - examples: RepositoryCoherence, ReviewReadiness, CM0, ArticulationAscent.

2. Property library package
   - reusable child CMs and property contracts;
   - examples: OneAuthoritativeHome, StatusTruth, AcceptanceCoverage.

3. Provider package
   - primitive runtime implementations;
   - examples: Git inventory, schema validation, bounded LLM judgment, theorem prover, external oracle.

4. Schema/type package
   - evidence, input, output, receipt, and target types.

5. Profile/policy package
   - audience profiles, organizational thresholds, accepted query families, score projections.

6. Fixture/calibration package
   - public synthetic targets, positive/negative cases, regression corpora, CM0 evidence.

These may share one manifest and registry protocol while retaining different package kinds and validation rules.

## 4. The ecosystem map

The analogies are useful only if the boundaries stay explicit.

### 4.1 TSC

TSC defines:

- the CM language and semantics;
- normalized IR contracts;
- receipt contracts;
- result and refusal semantics;
- TSC Core obligations for warrant-bearing constructs;
- CM0 calibration semantics;
- standard property and methodology libraries.

### 4.2 `coh`

`coh` is the compiler/runtime/verifier layer. It is closer to a combination of Node, the JVM/.NET runtime, a build linker, and an attestation verifier than to a simple executable.

Target commands:

    coh cm check
    coh cm build
    coh cm test
    coh cm run
    coh receipt verify

The current released `coh` remains a v3.2-era repository proxy. The vision requires a new general CM path; it must not be falsely described as already shipped.

### 4.3 `cn`

`cn` is the package and workspace plane:

- initialize projects;
- resolve/install packages;
- maintain lockfiles;
- discover provider implementations;
- publish packages;
- manage trusted registries;
- integrate local and remote execution environments.

It is analogous to npm/NuGet/Maven/Cargo, but it also participates in CNOS capability and agent infrastructure.

### 4.4 CNOS

CNOS is the preferred host substrate for the ecosystem:

- package distribution and discovery;
- activation and agent identity;
- provider registration;
- credentials and permissions;
- sandbox execution;
- LLM invocation;
- caching and restart;
- distributed provider hosts;
- actor/CDS lifecycle and authority.

However, `coh` should retain a minimal standalone execution boundary. A compiled CM with installed local providers should be runnable and verifiable without requiring a live CNOS control plane. CNOS is the preferred ecosystem host, not the owner of TSC semantics.

This portability boundary is the lesson shared by successful language ecosystems: the runtime, package manager, and orchestration environment cooperate, but no package manager is allowed to redefine the language’s truth conditions.

### 4.5 The portable-runtime / host-integration split

The portability boundary above is not just a nice-to-have; it decides where work lives and who owns which contract. The runtime effort divides into two masters with a one-directional dependency.

- **TSC / `coh` — the portable-runtime master.** Owns the host-independent kernel: the ABI, the normalized IR contracts, the evidence and receipt model, the receipt verifier, and a standalone executor that can run a compiled CM with locally installed providers and no live control plane. This side owns the *meaning* of a run and the *safety invariant* — expressed as a verifier plus conformance fixtures that any conforming runtime must pass.

- **CNOS / `cn` — the host-integration master.** Owns provider registration and discovery, credentials and permissions, sandbox execution, scheduling, distributed provider hosts, caching/restart, and CDS/actor authority. This side owns the *transport* of a run and the *enforcement* of the safety invariant in a real environment.

The dependency runs one way: the host lowers its concerns to the portable contracts. There is exactly one RunRequest, one SandboxExecutionPlan contract, and one MeasurementReceipt ontology, defined by `coh`; CNOS does not introduce a second run/receipt ontology and cannot redefine the truth conditions of a receipt. Two refinements make the division precise:

- **Package meaning vs. transport.** `coh` fixes what a package *means* (its typed contents, obligations, and evidence model); `cn`/CNOS fix how a package is *transported* (resolved, distributed, cached, hosted).
- **Safety invariant vs. enforcement.** `coh` defines the safety *invariant* and ships the verifier and conformance fixtures that pin it; CNOS *enforces* that invariant with real sandboxing, credentials, and capability gating. A standalone `coh` still checks the invariant; a host cannot weaken it.

## 5. Compilation, execution, and Core mathematics

The complete path is:

    surface construct
      → compiler elaborates types and warrant obligations into normalized IR
      → linker proves that selected providers expose required capabilities
      → runtime preserves evidence, bounds, alternatives, phases, and refusals
      → receipt verifier checks that the emitted result is supported

Core mathematics is not a separate stage that “runs.” It is the semantic contract behind strong language constructs.

For ordinary checks such as “does the file exist?” or “did every moved file preserve its consumers?”, Core obligations may be empty or minimal.

For claims such as:

- Identified;
- Equivalent;
- no realization in the declared model class;
- underdetermined;
- held-out generalization;
- recovered generator;

the compiler must make the obligations impossible to omit. The IR and receipt may need to retain:

- declared model/generator class;
- search strength and bounds;
- fit and complexity regime;
- equivalence/query family;
- candidate alternatives or fibers;
- held-out, oracle, intervention, proof, or construction evidence.

Most CM developers should use standard library constructs that carry those obligations rather than write the mathematics directly.

## 6. The general runtime kernel must be shaped by both easy and hard CMs

The first public demonstration should be an ordinary practical CM. It should not be the sole source of the runtime architecture.

The shared kernel must be extracted from the intersection of:

- ordinary check-style CMs such as Repository Coherence or Review Readiness;
- the already executed Ascent-0 hard case.

The resulting domain-neutral kernel requires:

1. Typed provider effects
   - explicit input/output schemas;
   - capabilities;
   - resource limits;
   - evidence contract;
   - cache identity;
   - failure/refusal semantics;
   - fail-closed handling of adversarial inputs: path confinement (no escape outside declared roots), rejection of include/import cycles, structured separation of prompt text from data so untrusted content cannot become instructions, and denial of any undeclared network or file access.

   This safety behavior is the portable invariant `coh` owns per §4.5: the invariant and its conformance fixtures ship with the runtime and are checked by the verifier even standalone, while CNOS enforces it with real sandboxing and capability gating.

2. DAG and readiness semantics
   - deterministic dependency ordering;
   - principled skip/incomplete behavior;
   - no accidental crash-as-verdict.

3. Singleton- and collection-valued evidence
   - alternatives retained until evidence lawfully permits collapse;
   - a fiber is the general case of retained admissible alternatives, not an Ascent-only special object.

4. Bounded collection dataflow
   - typed map/fanout/fold;
   - stable item identities;
   - deterministic aggregation order;
   - declared cardinality/resource budgets;
   - per-item evidence/receipts;
   - partial-failure semantics;
   - caching and restart.

5. Explicit phases and information barriers
   - later evidence cannot contaminate an earlier proposal or judgment;
   - commit/reveal is one Ascent implementation of the general barrier contract, not the only possible mechanism.

6. Runtime-derived results
   - providers emit observations or proposals;
   - the runtime computes the result from retained evidence and declared derivation rules;
   - a provider cannot notarize its own conclusion merely by returning a result-shaped value.

7. Recomputable receipts
   - independent verification from retained inputs/evidence;
   - derivation is executable, not narrative only.

8. Extensible warrant obligations
   - ordinary checks carry small obligations;
   - Core-bearing claims progressively require stronger evidence structures without a second runtime ontology.

KISS boundary: the ABI and receipt schema must have typed places for these structures, and Ascent-0 must exercise them before the ABI freezes. We should not implement every generic combinator or every Core obligation catalog before a concrete CM requires it.

## 7. The two-sided ABI-freeze test

The runtime may be demonstrated first with an ordinary CM, but the ABI is not stable until two different classes of program pass through it.

Product proof:

    an ordinary methodology runs end to end
    → useful practical result
    → mechanical + semantic + child-CM providers
    → reproducible receipts

Semantic-hardness proof:

    Ascent-0 runs through the same generalized ABI
    → same retained-fiber counts
    → same phase/seal ordering
    → zero unauthorized reveal access
    → same runtime-computed result
    → no second scheduler, receipt ontology, or host-language escape hatch

The ordinary pilot proves the platform is useful. Ascent-0 proves the platform did not define away the hard case.

## 8. What final success looks like

A CM author can:

- discover an existing methodology from a registry;
- compose it into a local top-level CM;
- install reusable properties and provider implementations;
- start from a high-level question with typed holes;
- refine the methodology top down;
- compile to deterministic normalized IR;
- run locally or on CNOS;
- receive a typed evidence-bound receipt;
- verify the receipt independently;
- publish the methodology as a package.

A property-library author can:

- publish reusable child CMs with fixtures, types, and result derivations;
- leave provider selection to the linker/host where lawful;
- version semantics independently of report presentation.

A provider author can:

- implement one primitive capability against the stable ABI;
- declare schemas, resources, provenance, and warrant contract;
- be mechanically or semantically specialized without changing CM source.

A repository or engineering owner can:

- select the methodology and policy profile they actually endorse;
- see categorical findings, incomplete evidence, failures, refusals, and retained disagreement;
- add a scorecard or manager report as a versioned projection without making the score the truth source;
- rerun only affected providers/CMs on a new snapshot;
- compare change receipts across time.

An agent/CDS system can:

- generate or repair an artifact;
- execute the same CM used by CI, an independent reviewer, or a customer;
- consume the receipt;
- keep merge/release/authorization outside the methodology runtime.

## 9. Current state and the gap

As of the current TSC state around `main` `32dfda8`:

Exists:

- compact `.cm` source language research;
- an OCaml source-to-normalized-IR compiler;
- CUE validation and normalized JSON artifacts;
- composite and leaf CM examples;
- a specialized Ascent-0 runtime with typed providers, candidate retention, phase sealing, and MeasurementReceipts — which proves firewall-safe, mechanism-side identification, not blind-provider generative correctness (a driven blind run predicted `ab→00` against oracle `01` yet the mechanism still validated the lift via the fit-set fiber; measuring generative correctness is the deferred `#123` gap);
- Repository Coherence, Legibility, and Structure methodologies/receipts;
- CM0 research artifacts.

Does not yet exist as a general shipped path:

- a settled CN package manifest/kind model for CM ecosystems;
- general provider ABI and digest-pinned registry;
- ordinary leaf CMs using typed provider-bound steps consistently;
- general linker and sandbox runtime;
- generic child-CM invocation;
- generic bounded collection dataflow;
- a general receipt verifier;
- `coh cm` as the production runtime path;
- CN registry publication and installation of CM packages;
- conforming CM0 assessment of the completed instrument.

## 10. Recommended sequence from here

1. Promote this developer-experience vision into a TSC-native architecture note after adversarial review.

2. Reconcile `#112`, `#113`, and `#116` against the vision and current `main`; amend rather than duplicate where possible.

3. Extract the shared runtime kernel from the ordinary-CM requirements and `ascent0_runner`.

4. Finish Source → IR → RunRequest → SandboxExecutionPlan → MeasurementReceipt contracts.

5. Implement the minimal provider ABI/linker and typed ordinary leaf steps. The first tracer may use explicit local, digest-pinned bindings — no package manager is required yet; package resolution is deferred until the runtime is proven.

6. Run one open practical methodology family end to end. Strong candidates remain:
   - IssueContract → ChangeCoherence → ReviewReadiness;
   - an open/synthetic WA-style repository-audit slice.

7. Re-run Ascent-0 through the same generalized kernel.

8. Freeze the ABI only after both the practical and semantic-hardness proofs pass.

9. Define the minimum package model — only once the runtime is proven and the ABI is frozen, so the manifest describes a real, stable contract rather than a guessed one:
   - manifest;
   - package kinds;
   - lockfile;
   - dependency/provider resolution;
   - publication boundary.

10. Promote the surviving runtime into `coh cm`, integrate package workflows through `cn`, and run CM0 against the completed instrument.

11. Resume deeper Ascent work as a program in the same language and runtime—not as a bespoke engine.

## 11. Decisions this note intentionally does not fake

The architecture is converged enough to guide work, but these exact choices still require design:

- final manifest and lockfile names;
- package namespace and registry naming convention;
- exact `.cm` syntax for imports, typed holes, bounded collections, and profiles;
- provider transport ABI (in-process, subprocess, RPC, or multiple bindings);
- exact standalone-`coh` versus CNOS-hosted execution packaging;
- how package trust, signatures, and CM0 standing are represented in registry metadata;
- which practical CM family is the first public end-to-end pilot.

Those should be derived from the developer journey and tested by concrete packages, not invented independently.

## Final vision

The final system is an ecosystem of TSC programs, libraries, and primitive effects:

    CM developer writes methodology.cm
      → `cn` resolves methodology/property/provider packages
      → `coh` compiles and elaborates obligations
      → linker selects capability-compatible providers
      → CNOS or the local host executes the bounded graph
      → typed receipts compose upward
      → verifier checks the claim
      → an external actor decides what to do

In that ecosystem:

- `cn` is the package/workspace plane;
- `coh` is the CM compiler/runtime/verifier;
- TSC Core supplies the semantics of warrant-bearing constructs;
- CN packages carry methodologies, properties, providers, schemas, profiles, and fixtures;
- CNOS supplies the preferred execution, identity, capability, caching, agent, and lifecycle substrate;
- CM0 calibrates the instrument;
- CDS/actors retain mutation and authority;
- receipts are the stable boundary between judgment and action.

That is the concrete destination: not a repository scorer, not a collection of prompt skills, and not one monolithic TSC engine, but a programmable ecosystem for transparent, reusable, independently verifiable methodologies.
