# CM Language — Product Direction

> **Status:** living direction doc. Tracks the north star, the architecture, what
> is proven today, and what remains. Execution detail lives in the linked GitHub
> issues; this doc is the coherent whole they are slices of.
>
> Companion: [`ADOPTION.md`](ADOPTION.md) — the *adoption* north star (who, why,
> what to ship first, how to frame and prove it). DIRECTION is the technical
> direction; ADOPTION is the go-to-market direction.

## 1. The product, in one sentence

A **coherence methodology (CM) is software** — authored in a small, learnable
language; compiled to a canonical representation; statically validated; executed
against real evidence; and assessed for whether it is a *credible instrument*
before anyone trusts its verdict.

The product turns CM development from **"fill in a large schema"** into
**"compose typed, checkable, already-assessed properties inside a bounded,
evidence-producing computation."**

## 2. Why

Before this program, a CM was prose plus, at best, a hand-built CUE/JSON scaffold.
That is not learnable (you reverse-engineer it), not executable (nothing runs the
steps), not composable (every CM re-implements analysis), and not *trustworthy by
construction* (a type-correct methodology can still measure the wrong thing).

The insight that organizes everything: **CUE proves the methodology is a valid
*program*; CM0 tests whether that valid program is a valid *instrument*.** Those
are different questions with different owners, and the product keeps them separate.

## 3. The layered architecture

Each layer has one owner. A question routes to exactly one of them.

| Layer | Owns | Artifact |
|---|---|---|
| **TSC v4.1 Core** (`spec/tsc-core.md`) | Abstract warrant semantics — what a methodological claim *means* (`H_M`, joint realization, atlas, identification, fit/complexity, held-out oracles) | — |
| **CM abstract semantics** (`spec/tsc-oper.md`) | The methodology lifecycle + authority model | — |
| **`.cm` surface language** | The human/LLM authoring surface — ML-shaped, restricted, learnable | `#CMSource` |
| **OCaml compiler** (`surface/`, future `coh cm`) | Parse · type/effect-check · lower · serialize | `#NormalizedCMIR` (+ `#CompilationReceipt`) |
| **CUE** (`schema.cue`) | The IR contract + independent validator (the compiler's conformance oracle) | validates the IR |
| **CM runtime** (future) | Operational semantics — invoke providers, sandbox, capture evidence, emit receipts | `#MeasurementReceipt` |
| **CM0** | Instrument fitness — is this valid, executed CM *credible*? | `#InstrumentAssessment` |
| **V** | Admission verdict | `AdmissionVerdict` |
| **δ** | Boundary authorization | `AuthorizedCM` |

Artifact-type family (one CUE package, no drift; JSON Schema only ever a derived
projection): `#CMSource` · `#NormalizedCMIR` · `#CompiledCM` · `#RunRequest` ·
`#MeasurementReceipt` · `#CompilationReceipt` · `#InstrumentSubject` ·
`#InstrumentAssessment`. See **#112**.

## 4. Principles (frozen)

1. **CUE proves a valid program; CM0 tests a valid instrument.** Distinct authorities; never conflated.
2. **The surface hides boilerplate, not obligations.** An abbreviating construct compiles to IR carrying the full Core contract. `decide | Identified when unique` must *establish* the Core condition (one equivalence class, declared input regime, complete-enough search, within bounds, no unresolved candidates) — never assert it by the token. See **#116**.
3. **Closed core, open libraries.** Core syntax + type/effect system are small and closed (canonical parsing, static inspection, stable IR, independent execution). Provider and property libraries are open; custom builders may exist later but must desugar to the same core IR. See **#113/#114**.
4. **Authority separation.** Every CM declares what it may do (`measure`) and may not without separate authorization (`compile/admit/authorize/repair`). CM0 may assess itself but **cannot admit or authorize itself** (`OPER-AUTH-001`).
5. **References are canonical; embeddings are projections.** Methodologies, receipts, fixtures, calibrations are content-addressed; an embedded copy is a digest-bound projection. See **#112**.
6. **Properties are assessed, not bare functions.** A property carries `Evidence<Finding>` + capabilities + provider digest + positive/negative/refusal fixtures + a determinism claim + a CM0 assessment — not `T -> bool`. Composing trusted, assessed properties *is* the developer experience. See **#116**.
7. **V4 forward, no legacy.** `coh` becomes the v4 toolchain outright; the frozen v3.2 repository-proxy is retired to historical-evidence-only (read, not run) — no `coh proxy` compatibility surface, no v3.2↔v4 interop burden. Historical receipts keep their instrument's meaning (no *retroactive* reinterpretation); that is not an obligation to maintain a legacy path.

## 5. What is proven today

- **CUE reference model** — three real CMs encoded and compiled: Repository Coherence (composite), Structural + Legibility (aspect leaves); plus CM0 (reflective leaf). Losslessly, minimally (every construct earned), with two independent blind executors deriving the same result classes from the package alone (**#109** closed; **#110/#111** CM0 4A closed).
- **The `.cm` surface language** — all four CMs *and* a fifth expressed in a compact ML-shaped surface, compiled by an isolated OCaml front-end to JSON **byte-identical** to the CUE reference, from one binary, no hardcoding. Every CM form (leaf · reflective-leaf · composite) is covered (**#114/#115**).
- **`.cm`-native origination** — `fifth.cm` (Licensing Coherence) was authored directly in `.cm` with *no* CUE counterpart — the surface can create methodologies, not just re-express them.
- **Learnability** — the step-8 acceptance test passed *yes-with-friction*: a fresh author wrote a valid, distinct 5th CM from `LANGUAGE.md` alone, first try, without reading the compiler or schema. The one friction (methodology-only validation) traced to a real root cause now being fixed (`#MethodologySource`).
- **The reference guide** — `LANGUAGE.md`, line-pinned accurate to the compiler.

## 6. Roadmap

Ordered by leverage, not urgency. Each is a tracked slice.

- **`#MethodologySource`** (kernel of #112 slice 2) — methodology-only projections vet directly; erases the step-8 validation friction. **Done** (`8b7f94e`): additive `#MethodologySource`/`#AspectMethodologySource`, existing IRs byte-identical, all five projections vet direct, `LANGUAGE.md` §8 simplified to a one-line `cue vet`.
- **#112 slice 2–4** — `#RunRequest`/`#MeasurementReceipt` (separate methodology from run), `#CompilationReceipt`, and the runtime artifacts (`#CompiledCM`/`#CalibrationReceipt`/`#AuthorizedCM`).
- **#113** — the standard **provider library** (`providers.cue`), `AUTHORING.md`, the Hello-World-first curriculum, and the `coh cm` toolchain (`check/compile/link/test/assess/run`, `receipt verify`).
- **#116** — **assessed property libraries** + the Core-warrant binding (the IR carries `H_M`/search-claims/bounds/identification behind every warrant-bearing construct).
- **#110 CM0 4B–4D** — CM0's assessment *function*: calibration/fixture corpus (migrating the frozen v3.2 assets as fixtures, not semantics), assessments of the three CMs, self-application.
- **The runtime** — execute the providers a `.cm` names; today the surface *declares* typed steps, nothing runs them yet.

## 7. The north star

A fresh developer, given the language guide and the assessed property libraries,
**composes** a new methodology out of trusted, CM0-verified properties — and it
compiles, validates, runs in a sandbox, and is assessed as an instrument before
its verdict counts. That is a genuine methodology ecosystem: coherence
methodologies as inspectable, composable, trustworthy-by-construction software.

## 8. How it is built (process)

- **δ orchestration with an α≠β firebreak** — one agent authors, an independent agent adversarially reviews, δ decides at boundaries. Every schema/compiler increment is reviewed before it touches `main`; mechanical diffs are δ-verified against objective gates (byte-identity, `cue vet`, no-regression).
- **Small, coherent increments** — each traces to a named incoherence; each keeps the prior IRs byte-identical unless a re-baseline is the explicit, reviewed point of the increment.
- **Operator identity** — commits are authored `usurobor <usurobor@gmail.com>` per the repo's CDD operator-identity convention (`.cdd/OPERATORS`); no tool/model identity is written into repository artifacts.
