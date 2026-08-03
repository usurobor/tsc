# TSC — North Star

> **This doc governs.** [`DIRECTION.md`](DIRECTION.md) (technical) and
> [`ADOPTION.md`](ADOPTION.md) (go-to-market) describe the **first application and
> self-hosting calibration domain** — repository coherence. They are *evidence of
> generality*, not TSC's identity. If they ever read as "TSC is a repository-
> quality / agent-evaluation / policy-as-code tool," re-read this doc: that
> framing loses the program one layer up.

## The center

> **TSC is a generative reasoning system for recovering a higher-order generator
> from partial or opposed articulations — and for determining what, if anything,
> warrants that recovery.**

The repository work proved that methodology-as-code is *operationally useful*. It
did **not** yet exercise the generative heart of TSC.

## The stack

| Layer | Role |
|---|---|
| **C≡** (`spec/c-equiv.md`) | expresses articulation |
| **Articulation Ascent** (`research/ascent/`) | discovers a higher-order generator |
| **CM** | programs the discovery-and-test procedure |
| **TSC Core** (`spec/tsc-core.md`) | warrants · underdetermines · refutes · refuses |
| **coh** | compiles and executes |
| **CM0** | assesses the methodology as an instrument |
| **domain** | supplies observations, interventions, oracles |

Repository Coherence is **one domain application**: a repository → Legibility /
Structure / Operability articulations → composable CMs → evidence-bound receipts.

## The fundamental program

```text
one point of view  a
  → derive a genuine polar view  b
  → identify the obstruction that makes a and b appear incompatible
  → recover candidate higher-order generators  W
  → preserve the candidate fiber when several W remain
  → descend W into existing AND novel articulations
  → test whether those articulations return to the same W
  → warrant · underdetermine · refute · refuse
```

Formally: `a ≡ b  ⟹  { Wᵢ | Wᵢ lawfully articulates as a and as b }`. The decisive
test is **generative** — a candidate must generate articulations it was *not
fitted to repeat*:

```text
Wᵢ ──(unattempted query q)──► c        and, where apt,   Ascend(Descend(Wᵢ, q)) ≃ Wᵢ
```

**A candidate that merely summarizes the inputs is not the sought generator.**

## Generation is the purpose; warrant is the discipline

The move from *scoring* to *receipts* was **not the destination** — it was the
discipline needed to make the generative operation trustworthy. Without it, an LLM
can always produce an impressive-sounding "higher synthesis":

```text
duality ≡ toaster  →  four persuasive paragraphs        (the profundity-generator failure)
```

The v4.1 mathematics is the **resistance**: a declared candidate class; joint
generator + atlas realization; search-strength claims; equivalence indexed by
observations/interventions; fit and complexity; candidate fibers; held-out
descent; failed and unresolved alternatives; identification only within a declared
model. Core treats a polar source as a **claim to be realized**, retains generator
and atlas together, and distinguishes *no realization · over-budget realization ·
underdetermination · identification · failed tests · unresolved tests.*

So:

- **Generation is the purpose.**
- **Warrant is the discipline.**
- **Empirical measurement is one possible way of earning warrant — not constitutive.** A warrant may instead be: formal proof · typecheck · construction · counterexample · held-out prediction · intervention · historical-text recovery · **refusal**.

## What we have, and have not, done

We have now encoded the **warranting architecture** (generic leaf + composite CMs,
receipts, deterministic result derivation, CM0, the `.cm` surface). We have **not
yet** encoded the **generative operation** that architecture exists to warrant —
the CM-language README still places typed external execution bindings and embedded
C≡ articulation in later increments.

**The CM language must be generative, not merely evaluative.** Its standard library
needs articulation primitives, not only checks:

```text
Articulation.compileView · unclose · polarize · nameObstruction
             · lift · retainFiber · descend · roundTrip · testGenerativity
```

The flagship generative CM (the real fifth example — see `research/ascent/`):

```text
cm articulationAscent v0.1 (view: PointOfView, question: Question) -> AscentReceipt {
  let! frame       = Articulation.compileView view
  let! polarities  = Articulation.polarize frame
  let! obstruction = Articulation.nameObstruction frame polarities
  let! candidates  = Articulation.lift frame polarities obstruction
  let! descents    = candidates |> Articulation.descendHeldOut question
  let! roundTrips  = Articulation.roundTrip descents
  retain frame, polarities, obstruction, candidates, descents, roundTrips
  decide
  | InvalidPolarity        when polarities.empty
  | NoTensionIdentified    when obstruction.absent
  | DecorativeLift         when candidates.nonempty and obstruction.survives
  | AscentUnderdetermined  when candidates.inequivalent.count > 1
  | LiftValidated          when obstruction.killed and heldOutGenerativity and roundTripSupported
  | Unresolved
  forbid fabricateEvidence, eraseAlternatives, equateFluencyWithWarrant
}
```

Repository Structure demonstrates that CMs can **check**. Articulation Ascent must
demonstrate that CMs can **generate and discover**.

## Roadmap hierarchy (corrected)

CM0 is the right immediate language test (it forces generic leaves, typed
providers, instrument subjects/assessments, authority boundaries, self-application
without self-authorization) — **but CM0 is the instrument-calibration layer, not
the flagship.** The decisive sequence:

1. **Repository Coherence** — proves composition. *(done)*
2. **Structure + Legibility** — prove distinct leaf methodologies. *(done)*
3. **CM0** — proves reflectivity and instrument assessment. *(in progress: 4A done; 4B–4D open)*
4. **Articulation Ascent** — proves **generative methodology.** *(the flagship; not yet built)*
5. **Articulation Ascent self / round-trip fixtures** — prove the language can generate, preserve alternatives, test held-out descent, and refuse decoration.

**Public positioning should wait until Articulation Ascent exists**, or the
external audience will reasonably conclude TSC is an elaborate quality-assessment
framework.

## The true public identity

Not "repository quality methodology-as-code," not "an evaluation framework for
agents." The deeper formulation:

> **TSC is a language and runtime for generative reasoning with proof-carrying
> receipts.** It helps an agent move from one point of view to its polarity,
> recover candidate higher-order generators that make both lawful, generate new
> articulations from those candidates, and state exactly what the evidence
> warrants.

Compact: **From opposed views to a generative whole — with receipts.** ·
**Articulate. Lift. Generate. Warrant.**

Then Repository Coherence is the concrete engineering story — *the same machinery
can encode what a coherent repository means, measure an exact commit, prevent
unsafe repairs, and verify closure* — **evidence of generality, not the final
identity.**

## The invariant to freeze

```text
C≡   expresses.
Ascent generates.
CM   programs.
TSC  warrants.
coh  executes.
CM0  calibrates.
```

And the sentence that governs the remaining language work:

> **A CM language that can only assess existing artifacts has not yet recovered
> TSC's generative purpose.**

The repo-quality work gave us a remarkably strong warranting substrate. The next
major test is to put the **generative operator** back at the center and prove the
language can perform the operation TSC was invented to teach an LLM.
