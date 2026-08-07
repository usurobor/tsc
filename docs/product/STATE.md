# Current State of TSC

> **Living state snapshot.** Assessment baseline: `main` at
> `e2172fdcf1a44c7e103eb9e41cf2512b82d4865c`. The **Ascent-0 wave
> (#118 → #119–#122) is merged and closed**; **#123** (Ascent-1) and **#117**
> (the flagship generative CM) are open. The governing `NORTH-STAR.md` still
> holds.

**One line:** *The repository cleanup and the static methodology/language
substrate are shipped, and the first **executable** generative slice (Ascent-0)
now runs end to end — but it proves firewall-safe **identification**, not
generative **correctness**, and only for one hand-wired CM family. A general CM
runtime, real CM0 assessment, and generative Articulation Ascent are still not
shipped.*

In the North-Star stack:

```text
C≡ expresses      specified
Ascent generates  first executable slice shipped (Ascent-0): firewall-safe
                  identification proven; generative correctness NOT yet
CM programs       language + examples shipped
TSC warrants      v4.1 Draft semantics shipped
coh executes      only the old v3.2 proxy; a research runtime (ascent0_runner)
                  executes ONE CM family end to end
CM0 calibrates    source encoded; no assessment runs
```

The generative operation the warranting architecture exists to warrant now has
its **first executable evidence** — but at the identification layer only. The
generative-correctness step (does the proposer's committed prediction match
reality?) is #123.

## One-screen artifact / functionality map

| Layer | Artifacts on main | What works | What does not work yet |
|---|---|---|---|
| TSC specification | v4.1 Draft specs; v4.0 last ratified | Formal receipt, candidate-fiber, CM lifecycle + authority semantics are written | No 4.1-conforming engine or methodology |
| Repository cleanup | Plane ADR v1.2, migrated tree, cleanup receipts + case study | Major docs/tree cleanup landed; unsafe wholesale deletion prevented | Some structural moves deferred; no fresh final composite after all moves |
| Repository CMs | Parent Repository Coherence, Legibility, Structure, frozen runs | Executed **manually** by LLMs; produced useful receipts | No general runtime executes them |
| CUE CM model | `schema.cue`, four principal examples, compiled JSON IR | `cue vet`/`cue export`, type constraints + result derivations work | Reference/IR machinery, not the final authoring UX or runtime |
| `.cm` language | OCaml parser/compiler, language reference, five example CMs | `.cm` compiles to CUE-exact normalized JSON; boundary probes reject | No provider execution, no installed CLI, no full type/effect system |
| CM0 | Generic leaf source, `InstrumentSubject`, normalized IR | Static source/IR + authority boundary compile | No calibration corpus, no `InstrumentAssessment` runs, no self-application |
| **Articulation Ascent (Ascent-0)** | **Merged wave**: executable fixture generator + sealed oracle, typed provider firewalls, sandbox runtime, five-case closure | **`ascent0_runner` executes the compiled IR end to end and emits CUE-valid `MeasurementReceipt`s for all five cases**; oracle seal (commit-before-reveal) structurally enforced; receipt **computed, not echoed** (perturbation-verified) | Firewall-safe **identification**, **not** generative **correctness** (#123); single hand-authored CM family; no general runtime; IR is hand-authored (cmc is family-specialized) |
| coh | Released CLI 0.12.0 | Runs the frozen v3.2 repository proxy | Cannot compile/execute v4 CMs; emits no v4 receipts; no `coh cm run` |

## 1. Repository cleanup — what is actually done

The front door and documentation architecture are materially cleaned. Responsibility-plane policy: `spec/` binds · `src/` runs · `conformance/` proves · `research/` investigates · `docs/` helps a person · `scripts/` automates. Docs use a **closed reader-intent taxonomy**, not α/β/γ folders; the ADR supplies the lifecycle rule for decisions, evidence, pre-normative work, machine-consumed artifacts, and superseded history.

**Physically landed:** root `QUICKSTART.md`/`ARCHITECTURE.md` → reader-intent doc planes; live `docs/beta/governance/` material split into semantic homes; the factorized-β fixture moved with **all** engine/test/workflow/doc consumers; the foundation-reconciliation bundle → `docs/evidence/`; polar-expression design → `research/`; live operator docs → `docs/guides/`; the old `docs/{alpha,beta,gamma}/` trees removed from HEAD after their live material was extracted; obsolete linkcheck exclusions removed.

**The cleanup's strongest result.** The original direction would have removed the legacy role trees as frozen history. The Structural CM found one JSON fixture inside them still had **seven live consumers** across engine, tests, CI, and docs. The unsafe delete was cancelled and replaced with: *enumerate consumers → extract live artifacts → repoint all consumers → verify → delete only the inert residual history.* This demonstrates a CM can **alter the repair plan itself** rather than mechanically enforcing an incorrect initial diagnosis.

**Structurally deferred** (policy-decided, moves not executed): `targets/`→engine config under `src/`; `katas/`→a tests plane; `schemas/`→co-located with owners; `runtime/SELF-MEASURE.md`→its owning skill. Out of scope by ADR: `.cdd/`, `.cn-sigma/`, `heldout/`.

**Evidence boundary (important):** there is **no fresh final Repository Coherence composite** against today's cleaned HEAD. The retained composite measured `48b9a63` (before the later migrations): Legibility PASS · Structure DEFECT · Operability NOT_IMPLEMENTED · Composite DEFECTS_FOUND — valid historical evidence for that exact snapshot. Honest state: *the targeted cleanup landed and was reviewed, but repository-wide structural closure has not been remeasured on current HEAD.*

## 2. The Repository Coherence CM system

Under `research/repository-coherence/`: the parent CM + requirements + aspect registry; `legibility/` and `structure/` (CM, requirements, fixtures, frozen runs); `runs/` (composite receipt). The parent composes children over one exact snapshot, **retaining** receipts rather than averaging; its normalized interface is `PASS/DEFECT/INCOMPLETE/FAILED` while each child keeps its richer status.

Demonstrated manually (fresh-LLM execution) — real methodology execution, but **reference execution by LLM, not runtime execution by coh.**

## 3. The CUE CM model

`research/cm-language/` holds `schema.cue`, `examples/{repository-coherence,structure,legibility,cm0}/`, `compiled/` (normalized JSON), and the docs. CUE is explicitly the **model + IR-validation** layer.

**Artifact family partly separated.** Present: CM source concepts, `NormalizedCMIR`, generic methodology-source projections, `InstrumentSubject`, `InstrumentAssessment` shape. Still incomplete: full `RunRequest` + migration, full `MeasurementReceipt` separation as a shared family type, `CompilationReceipt`, runtime-linked `CompiledCM`, `CalibrationReceipt`, `AuthorizedCM`. **#112** tracks the separation. *(Note: the Ascent-0 runtime already produces a concrete `#NormalizedCMIR` and a runtime-local `#MeasurementReceipt` + `SandboxExecutionPlan` — a first real instance of the run→receipt path, not yet lifted into the shared #112 family.)*

## 4. The compact `.cm` language

A **real compiler exists** under `research/cm-language/surface/`: `cmc` lexes/parses/lowers the compact ML-shaped syntax to normalized JSON, **byte-identical** to the approved CUE representation for the principal examples; a fifth CM (`fifth.cm`) was authored from the language itself. **The compiler/IR loop is real functionality, not prose.**

Does **not**: execute a provider; measure a repository; call an LLM; run a child CM; emit a *general* dynamic `MeasurementReceipt`; implement `coh cm`. It is also uneven — CM0 has typed provider-bound `let!`/`and!` steps while Structure/Legibility/Licensing still carry free-form procedure strings (Pi/Omega flagged this as the smallest language gap for check-style CMs). Standard provider library, authoring guide, Hello-World, and runtime are open under **#113**. **Note:** the Ascent-0 runtime IR is **hand-authored**, not `cmc`-emitted (cmc is specialized to three fixed CM families) — so a general runtime must consume `#NormalizedCMIR` from any source and not depend on `cmc`.

## 5. CM0

**Shipped (increment 4A, #111 closed):** generic leaf-CM abstraction; refs; `InstrumentSubject`; `InstrumentAssessment` output shape; typed subcontracts; measure-only boundary; normalized CM0 IR; `.cm` CM0 source; compile-time rejection of forbidden admission/authorization behavior.

**Not shipped (increments 4B–4D, open #110):** calibration fixture corpus; repeatability; discrimination; refusal-behavior tests; assessment of any CM; self-application; an actual `InstrumentAssessment` receipt. Ascent-0's `MeasurementReceipt`s are **retained as calibration/prior evidence for CM0**, not a conforming assessment.

## 6. coh

Released `coh 0.12.0` runs the frozen v3.2 repository proxy; its contract explicitly denies it can implement v4 Core/Operational, compile arbitrary v4 CMs, or claim v4 conformance. So: `cmc` = prototype methodology compiler under `research/`; `ascent0_runner` = a research runtime for one CM family; `coh` = released v3.2 proxy. **All presently separate.** No `coh cm check/compile/run` exists.

## 7. TSC v4.1 mathematics & engine

**Present (4.1 Draft):** polar sources; generator classes; joint realizations; search; input-indexed equivalence; fit + complexity; candidate fibers; held-out/intervention tests; underdetermination; identification; proof-carrying receipts; CM lifecycle + authority separation. **Absent:** a 4.1-*conforming* engine — the repo states `4.1 conformance standing: none`. The v4-engine wave **#102–#106** is open, *proposed, not dispatched*.

**What changed:** Ascent-0 is the first code to **execute** several of these constructs for a bounded model — complete enumeration over a declared class, exact-fit realization, quotient/equivalence, candidate-fiber retention, held-out descent, a sealed oracle, and a proof-carrying receipt — but over a **research fixture domain (a Mealy transducer class)**, not the general v4 measurement semantics, and it carries no 4.1 conformance standing.

## 8. Articulation Ascent

**Research shipped:** `research/ascent/` — program README, D-001 surface-grammar decision, Trace 000 (a fresh-model control from the leak-free viewpoint).

**Ascent-0 wave — SHIPPED and merged (#118 → #119–#122 CLOSED):**
- **#119** `research/ascent/fixtures/ascent-0/` — an **executable** fixture generator + sealed oracle; a deterministic Mealy-transducer class (size 260), five cases; nothing load-bearing hand-typed.
- **#120** `research/cm-language/providers/ascent-0/` — typed provider firewalls (one semantic proposer + six mechanical warrantors), **`cue vet`-enforced** (LLM proposes, only the oracle capability warrants).
- **#121–#122** `research/cm-language/runtime/ascent-0/` — `ascent0_runner` loads the `#NormalizedCMIR`, links a `SandboxExecutionPlan`, executes the seven-provider DAG, and emits a CUE-valid `MeasurementReceipt`. **All five cases** reach their required outcomes (`LIFT_VALIDATED`, `ASCENT_UNDERDETERMINED`, `NO_REALIZATION_IN_MODEL`, `DECORATIVE_LIFT`, round-trip); mechanical providers **compute from public inputs**; the oracle seal (commit-before-reveal) is structurally enforced; the receipt is **computed, not echoed** (a public-input perturbation moves the receipt). Built under the α≠β firebreak, which caught a real dead-branch bug and an author self-proof overclaim before merge.

**Honest scope — do not overclaim.** Ascent-0 proves **firewall-safe, mechanism-side identification**, *not* the blind LLM's generative **correctness**. In the one driven blind run the provider's committed prediction was **wrong** (`ab→00` vs oracle `01`); the mechanism warranted `01` independently, and a deliberately wrong-but-admissible proposal validates byte-identically. That is the firewall working, not laundering — but it means "the LLM generated the validated output" is **false** and must not be claimed. Measuring generative correctness (bind + test the proposer's committed prediction) is **#123 (Ascent-1)**, filed under the flagship **#117**.

**Not yet:** a general (multi-CM) runtime; `coh cm run`; `cmc`-emitted (vs hand-authored) Ascent IR; the CM0 assessment of the runtime; Ascent depth beyond the tracer. **Converged next direction** (Pi ↔ Omega ↔ Sigma, live on the agent-dialogue channel, **not yet promoted to issues**): build the **general CM runtime** by generalizing `ascent0_runner`, with an ordinary check-style CM as the first product proof and **Ascent-0 as the ABI-freeze conformance fixture**.

## 9. Strategy & public-facing artifacts

Real: `NORTH-STAR.md`, `DIRECTION.md`, `ADOPTION.md`, the Repository Cleanup case study, the `.cm` language reference. **Not yet:** a GitHub Pages site; an installable new CM toolchain; a GitHub Action for v4 CMs; a public generative demonstration. Public positioning waits until the generative flagship (genuine generative correctness, #117/#123) exists — Ascent-0's identification result is not that flagship.

## The boundary, plainly

**Shipped today:** ✓ cleaned repository surface + plane policy + cleanup case study · ✓ manual composable Repository Coherence CMs · ✓ CUE CM type model + normalized JSON IR · ✓ compact `.cm` authoring language + isolated OCaml compiler · ✓ static CM0 source + authority boundary · ✓ **Ascent-0 executable slice**: fixture generator + sealed oracle, typed provider firewalls, sandbox runtime, five-case CUE-valid receipts, structurally-enforced oracle seal, computed-not-echoed · ✓ North-Star + roadmap.

**Shipped for ONE CM family only (Ascent-0 research runtime), NOT general:** ◑ provider execution · ◑ dynamic `RunRequest → MeasurementReceipt` path · ◑ held-out descent · ◑ candidate-fiber execution · ◑ round-trip validation · ◑ first proof-carrying Ascent receipt (identification-grade).

**Not shipped today:** ✗ general (multi-CM) CM runtime · ✗ `coh cm run` · ✗ `CompilationReceipt` / runtime `CompiledCM` · ✗ CM0 calibration or assessment runs · ✗ any 4.1 conformance standing · ✗ generative **correctness** (proposer prediction bound + tested) · ✗ public developer product.

## Where we actually are

We have crossed from *ideas + Markdown specifications* to *a statically checkable methodology language + a compact compiler-backed authoring surface + real manually-executed methodologies + a repository case showing practical value* — **and now, for one bounded fixture domain, to an executable runtime that recovers candidates, retains alternatives, honors a sealed oracle, and emits a proof-carrying receipt.**

We have **not** crossed from *firewall-safe identification* to *measured generative correctness*, nor from *one hand-wired CM family* to *a general CM runtime*. That is exactly the next boundary the converged direction targets:

```text
generalize ascent0_runner → shared provider/evidence/receipt ABI (constrained jointly
  by an ordinary check-style CM and Ascent-0) → first ordinary-CM receipt through the
  general runtime → Ascent-0 reproduced through the same ABI (freeze gate) → #123
  generative-correctness → #117 flagship
```

That will be the moment TSC's implemented functionality catches up with its North Star.
