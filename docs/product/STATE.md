# Current State of TSC

> **Living state snapshot.** Assessment baseline: `main` at
> `2f06e803b761107403d5efa2e1fac3323bd0648d` (a precision correction to the
> repository-cleanup case study). The governing `NORTH-STAR.md` and the
> Ascent-0 wave issues (#117–#122) were filed immediately after and are
> reflected below.

**One line:** *The repository cleanup and the static methodology/language
substrate are substantially shipped. The v4 runtime, real CM execution, CM0
assessment, and generative Articulation Ascent are not.*

In the North-Star stack:

```text
C≡ expresses      specified
Ascent generates  researched by hand, not executable
CM programs       language + examples shipped
TSC warrants      v4.1 Draft semantics shipped
coh executes      only the old v3.2 proxy today
CM0 calibrates    source encoded; no assessment runs
```

The governing North Star says exactly this: the **warranting architecture
exists, while the generative operation it exists to warrant has not yet been
implemented.**

## One-screen artifact / functionality map

| Layer | Artifacts on main | What works | What does not work yet |
|---|---|---|---|
| TSC specification | v4.1 Draft specs; v4.0 last ratified | Formal receipt, candidate-fiber, CM lifecycle + authority semantics are written | No 4.1-conforming engine or methodology |
| Repository cleanup | Plane ADR v1.2, migrated tree, cleanup receipts + case study | Major docs/tree cleanup landed; unsafe wholesale deletion prevented | Some structural moves deferred; no fresh final composite after all moves |
| Repository CMs | Parent Repository Coherence, Legibility, Structure, frozen runs | Executed **manually** by LLMs; produced useful receipts | No general runtime executes them |
| CUE CM model | `schema.cue`, four principal examples, compiled JSON IR | `cue vet`/`cue export`, type constraints + result derivations work | Reference/IR machinery, not the final authoring UX or runtime |
| `.cm` language | OCaml parser/compiler, language reference, five example CMs | `.cm` compiles to CUE-exact normalized JSON; boundary probes reject | No provider execution, no installed CLI, no full type/effect system |
| CM0 | Generic leaf source, `InstrumentSubject`, normalized IR | Static source/IR + authority boundary compile | No calibration corpus, no `InstrumentAssessment` runs, no self-application |
| Articulation Ascent | North Star, D-001, hand traces, #117 | Trace 000 passed as a manual fresh-model control | No kernel, generative providers, runtime, held-out receipt, round-trip proof |
| coh | Released CLI 0.12.0 | Runs the frozen v3.2 repository proxy | Cannot compile/execute v4 CMs; emits no v4 receipts |

## 1. Repository cleanup — what is actually done

The front door and documentation architecture are materially cleaned. Responsibility-plane policy: `spec/` binds · `src/` runs · `conformance/` proves · `research/` investigates · `docs/` helps a person · `scripts/` automates. Docs use a **closed reader-intent taxonomy**, not α/β/γ folders; the ADR supplies the lifecycle rule for decisions, evidence, pre-normative work, machine-consumed artifacts, and superseded history.

**Physically landed:** root `QUICKSTART.md`/`ARCHITECTURE.md` → reader-intent doc planes; live `docs/beta/governance/` material split into semantic homes; the factorized-β fixture moved with **all** engine/test/workflow/doc consumers; the foundation-reconciliation bundle → `docs/evidence/`; polar-expression design → `research/`; live operator docs → `docs/guides/`; the old `docs/{alpha,beta,gamma}/` trees removed from HEAD after their live material was extracted; obsolete linkcheck exclusions removed.

**The cleanup's strongest result.** The original direction would have removed the legacy role trees as frozen history. The Structural CM found one JSON fixture inside them still had **seven live consumers** across engine, tests, CI, and docs. The unsafe delete was cancelled and replaced with: *enumerate consumers → extract live artifacts → repoint all consumers → verify → delete only the inert residual history.* This demonstrates a CM can **alter the repair plan itself** rather than mechanically enforcing an incorrect initial diagnosis.

**Structurally deferred** (policy-decided, moves not executed): `targets/`→engine config under `src/`; `katas/`→a tests plane; `schemas/`→co-located with owners; `runtime/SELF-MEASURE.md`→its owning skill. Out of scope by ADR: `.cdd/`, `.cn-sigma/`, `heldout/`.

**Evidence boundary (important):** there is **no fresh final Repository Coherence composite** against today's cleaned HEAD. The retained composite measured `48b9a63` (before the later migrations): Legibility PASS · Structure DEFECT · Operability NOT_IMPLEMENTED · Composite DEFECTS_FOUND — valid historical evidence for that exact snapshot. The case study maps the final migrations to the frozen findings but says a fresh post-wave composite has **not** been produced. Honest state: *the targeted cleanup landed and was reviewed, but repository-wide structural closure has not been remeasured on current HEAD.*

## 2. The Repository Coherence CM system

Under `research/repository-coherence/`: the parent CM + requirements + aspect registry; `legibility/` and `structure/` (CM, requirements, fixtures, frozen runs); `runs/` (composite receipt). The parent composes children over one exact snapshot, **retaining** receipts rather than averaging; its normalized interface is `PASS/DEFECT/INCOMPLETE/FAILED` while each child keeps its richer status.

Demonstrated manually (fresh-LLM execution): execute Legibility + Structure at one commit; emit evidence-bound findings + refusals; distinguish defects from incomplete observation and policy gaps; retain two truths about one repo; type findings by repairability; compose deterministically; protect the measure/repair boundary. **This is real methodology execution — but reference execution by LLM, not runtime execution by coh.**

## 3. The CUE CM model

`research/cm-language/` holds `schema.cue`, `examples/{repository-coherence,structure,legibility,cm0}/`, `compiled/` (normalized JSON), and the docs. Proven: composite + leaf forms; generic result classes; child-specific status mappings; typed receipts; finite procedures + result rules; a generic leaf abstraction; CM0 as an ordinary leaf (not a special built-in); content-addressed references; static authority boundaries; normalized JSON output; independent-executor agreement. CUE is explicitly the **model + IR-validation** layer; external execution bindings are a later increment.

**Artifact family partly separated.** Present: CM source concepts, `NormalizedCMIR`, generic methodology-source projections, `InstrumentSubject`, `InstrumentAssessment` shape. Still incomplete: full `RunRequest` + migration, full `MeasurementReceipt` separation, `CompilationReceipt`, runtime-linked `CompiledCM`, `CalibrationReceipt`, `AuthorizedCM`. **#112** tracks the separation.

## 4. The compact `.cm` language

More than a proposal — a **real compiler exists**. Under `research/cm-language/surface/`: `dune-project`, `lib/cm_surface.ml` (lexer + parser + lowering + JSON emitter), `bin/main.ml` (`cmc`), the five example `.cm` (`cm0`, `repository_coherence`, `legibility`, `structure`, `fifth`), negative probes, README.

Works: `dune build`; `cmc <file.cm>` and `cmc --source <file.cm>` parse + lower the compact ML-shaped syntax to normalized JSON. Demonstrated for the principal examples: **byte-identical** output to the approved CUE representation; independent `cue vet`; preservation of content-addressed provider/methodology references; compilation of composite, aspect-leaf, and reflective-leaf forms; rejection when mandatory authority prohibitions are removed. The language reference documents the implemented grammar and marks future constructs explicitly. **The compiler/IR loop is real functionality, not prose.**

A **fifth CM was authored from the language itself** — `fifth.cm` (Licensing Coherence: new governing question, five statuses, result mapping, six steps, seven requirements, measure-only boundary), authored from `LANGUAGE.md` + the curriculum and compiled successfully. Evidence the language is usable beyond reproducing the original three.

Does **not**: execute a provider; read/measure a repository; call an LLM; run a child CM; run a held-out oracle; emit a new dynamic `MeasurementReceipt`; link permissions/adapters/sandbox; implement `coh cm`. The language is also uneven — CM0 has typed provider-bound `let!`/`and!` steps, while Structure/Legibility/Licensing still carry free-form procedure action strings. Standard provider library, authoring guide, Hello-World suite, and runtime are open under **#113**. Best called: *a validated compiler/front-end for methodology declarations, not a methodology execution runtime.*

## 5. CM0

**Shipped (increment 4A, #111 closed):** generic leaf-CM abstraction; `ArtifactRef`/`TargetRef`/`MethodologyRef`; `InstrumentSubject`; `InstrumentAssessment` output shape; content-addressed refs; typed subcontracts; measure-only boundary; normalized CM0 IR; `.cm` CM0 source; compile-time rejection of forbidden admission/authorization behavior.

**Not shipped (increments 4B–4D, open #110):** calibration fixture corpus; repeatability; discrimination; refusal-behavior tests; assessment of Repository Coherence / Structure / Legibility; self-application; an actual `InstrumentAssessment` receipt. The old `src/skills/cm-of-cms/` remains the frozen v3.2 predecessor; it has **not** become the new CM0.

## 6. coh

Released `coh 0.12.0` runs structural repository-proxy scoring, semantic witness scoring, hybrid proxy adjudication, and the existing katas/measurement workflows. Its contract explicitly denies it can implement v4 Core/Operational, compile arbitrary v4 CMs, identify v4 candidate fibers, emit v4 α/β/γ receipts, or claim v4 conformance (root README + STATUS concur). So: `cmc` = prototype methodology compiler under `research/`; `coh` = released v3.2 proxy. **Presently separate.** No `coh cm check/compile/run` exists.

## 7. TSC v4.1 mathematics & engine

**Present (4.1 Draft):** polar sources; generator classes; joint generator-and-atlas realizations; relation + generator search; input-indexed equivalence; fit + complexity; candidate fibers; held-out/intervention tests; underdetermination; identification; proof-carrying receipts; CM lifecycle + authority separation. **Absent:** the implementation — the repo states `4.1 conformance standing: none`, and no implementation has emitted a passing 4.1 conformance receipt. The v4-engine wave **#102–#106** is open, marked *proposed, not dispatched* (attempt-budget governance, an OCaml typecheck probe, foundation negative/refusal machinery, a GoL thin receipt slice). **The CUE/.cm work is ahead of the v4 engine: we can express + compile methodologies, but not execute their v4 measurement semantics.**

## 8. Articulation Ascent

**Research shipped:** `research/ascent/` — program README, D-001 surface-grammar decision, Trace 000 (Hello World), deferred machine/human + hard/soft traces. Trace 000 passed a fresh-model control: from the leak-free viewpoint the model derived `source ≡ behavior`, named a center, and supplied a discriminating consequence without the withheld terms. The North Star and **#117** now place Ascent — not repo quality or CM0 — at the center.

**Not shipped:** `KERNEL.md`; an executable Ascent CM; articulation stdlib providers; candidate-generator impl; held-out descent engine; retained candidate-fiber runtime; decorative-lift oracle; round-trip checker; Ascent `MeasurementReceipt`; Ascent conformance suite. Ascent is currently *a converging research design plus a successful manual control trace — not an implemented generative system.* The **Ascent-0 wave (#118 → #119–#122)** is filed for review, not dispatched.

## 9. Strategy & public-facing artifacts

Real: `NORTH-STAR.md` (governing identity), `DIRECTION.md` (technical/product direction), `ADOPTION.md` (adoption strategy), the Repository Cleanup case study, the `.cm` language reference. The case study is evidence-bound and distinguishes measured outcomes from uninstrumented metrics. **Not yet:** a GitHub Pages site; an installable new CM toolchain; a GitHub Action for v4 CMs; a runtime demo; a public generative Ascent demonstration. Strategy itself says public positioning waits until the generative flagship exists.

## A correction to "we haven't touched code"

True for **production coh behavior**: the v3.2 engine's semantics have not been replaced by v4. No longer literally true for the repo as a whole: existing OCaml path literals + tests were updated during consumer-atomic file moves, and a new isolated OCaml compiler was added under `research/cm-language/surface/`. Accurate statement: *we have not changed the production proxy's measurement semantics; we have added research-grade compiler code and made meaning-preserving path updates to existing consumers.*

## The boundary, plainly

**Shipped today:** ✓ cleaned/simplified repository surface · ✓ accepted repository-plane policy · ✓ evidence-backed cleanup case study · ✓ manual composable Repository Coherence CMs · ✓ CUE CM type model · ✓ normalized JSON CM IR · ✓ compact `.cm` authoring language · ✓ isolated OCaml `.cm` compiler · ✓ composite/leaf/reflective CM source forms · ✓ fifth independently-authored CM · ✓ static CM0 source + authority boundary · ✓ North-Star + implementation roadmap.

**Not shipped today:** ✗ v4 CM runtime · ✗ provider execution · ✗ `coh cm run` · ✗ dynamic RunRequest→MeasurementReceipt path · ✗ CompilationReceipt / runtime CompiledCM · ✗ CM0 calibration or assessment runs · ✗ first v4 receipt · ✗ any 4.1 conformance standing · ✗ executable Articulation Ascent · ✗ held-out generative descent · ✗ candidate-fiber execution · ✗ round-trip validation · ✗ public developer product.

## Where we actually are

We have crossed from *ideas + Markdown specifications* to *a statically checkable methodology language + a compact compiler-backed authoring surface + real manually-executed methodologies + a repository case showing practical value.*

We have **not** crossed from *methodology program* to *executed v4 instrument*, nor from *evaluating an existing artifact* to *recovering a generator and producing a genuinely new held-out articulation.* That is precisely what the **#117 / Ascent-0 wave** must accomplish. The next-phase boundary:

```text
Ascent-0 exact fixture → generative provider contracts → minimum sandbox runtime
  → first held-out generated articulation → first proof-carrying Ascent receipt
```

That will be the moment TSC's implemented functionality catches up with its North Star.
