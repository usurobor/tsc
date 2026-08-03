# CM / TSC — Adoption & Go-to-Market Direction

> **Status:** living strategy doc. Companion to [`DIRECTION.md`](DIRECTION.md):
> DIRECTION is the *technical* north star (architecture, principles, roadmap);
> this is the *adoption* north star (who, why, what to ship first, how to frame
> it, how to prove it). Honest by construction — it states what is not ready.

## 1. Honest verdict

Timely and potentially valuable — **not yet something most engineers would adopt
in its current form.** Ship it as an **ambitious research preview**, not a
production framework. Calling it production-ready today would overclaim.

The bet is real because the bottleneck in agentic engineering is shifting from
**generating** changes to **specifying what good work means, supervising
execution, evaluating the result, and deciding what may safely happen next.** As
agent capacity outpaces evaluation/supervision/governance practice,
methodology-as-code is exactly the missing layer.

But engineers will not adopt this because they are excited about the ontology,
C≡, coalgebras, CM0, or proof-carrying receipts. They may adopt it because it can:

> Define once how this repository should be judged → run that definition against
> an exact commit → get an **evidence-bound defect receipt** → give the receipt to
> repair agents → verify closure independently → reuse the methodology across
> models and repositories.

**That is the product.** Everything else is Foundations, shown later.

## 2. Where TSC is genuinely differentiated

The adjacent industry (LangSmith, Braintrust, agent-eval platforms) already does
datasets, scorers, immutable experiments, tracing, CI gating. TSC should **not**
compete on "we also run agent evals." Its distinction is that it defines the
**methodology, authority boundaries, evidence model, refusals, and consequences
around** an evaluation — not merely its scorer.

Practical differentiators, in adoption-priority order:

1. **Receipts, not just scores.** `Structure DEFECT · Finding F7: live fixture under a historical docs tree · 7 machine consumers found · destination policy unresolved · repairability=POLICY_REQUIRED` is immediately actionable to an owner or agent; `quality=0.76` is not.
2. **First-class refusal & incompleteness.** The system distinguishes *found a defect* / *didn't observe enough* / *search was heuristic* / *several lawful answers remain* / *policy doesn't decide* / *instrument failed to run.* This stops agents from converting every uncertainty into a confident repair.
3. **Measurement separate from repair.** `measure A → freeze receipt → repair B → remeasure B → independent review.` A strong defense against agents moving the target while claiming improvement.
4. **Composable properties without averaging.** A repo can be understandable but badly structured; both truths survive (Legibility PASS + Structure DEFECT, never a blended 0.7).
5. **Methodologies themselves are assessable (CM0).** Is the instrument repeatable, discriminating, correctly-refusing, declaration-matching, honestly-versioned? A real step beyond "write an LLM judge and trust it."

## 3. Positioning — integrate, don't replace

| Tool class | What it does | TSC's layer |
|---|---|---|
| Tests / linters | Verify predefined machine-checkable behavior | Providers inside a CM |
| Agent instructions / Skills | Tell agents how to act | A CM assesses how outcomes are judged |
| Agent eval platforms | Datasets, scorers, traces, experiments | TSC adds methodology, refusal, authority contract |
| Policy-as-code | Does structured state satisfy policy? | Mechanical provider; TSC adds semantic evidence + incomplete conclusions |
| CI/CD | Execute gates & delivery | Runtime substrate for CMs & receipts |
| **TSC** | Composes these into an **evidence-bound methodology** | the policy/evidence/authority layer |

TSC should **integrate with** LangSmith, Braintrust, GitHub Actions, test runners,
and policy systems — not try to replace their (already sophisticated) execution,
tracing, and experiment infrastructure.

## 4. Who adopts first

**Strong early-adopter profile:** maintainers using coding agents heavily;
repository-centric engineering; multiple agents/model providers; long-lived
docs/spec/policy surfaces; high cost of silent semantic drift; heavy review
burden; desire for more autonomous repair. (Solo maintainers delegating to agents;
agent-platform teams; docs/spec-heavy OSS; internal platform teams encoding
engineering policy; AI product teams needing governance beyond scorers;
safety/compliance teams, later.)

**Weak initial fit:** small conventional apps; teams happy with tests+lint+review;
teams not using autonomous agents; simple repository semantics; teams unwilling to
maintain explicit quality policy. For them TSC feels like ceremony — and that is
fine. A focused tool can be valuable without being universal.

## 5. Maturity — stated honestly

| Dimension | State |
|---|---|
| theory / architecture | strong |
| reference semantics | emerging |
| real CMs · manual executions · CUE model | yes |
| compact authoring syntax | **proven for authoring; runtime not built** |
| runtime (provider execution) | **not built** |
| GitHub integration · general user workflow | **not built** |
| external validation | minimal |

`coh` today is still the **frozen v3.2 repository-proxy** (cannot compile v4 CMs,
emit v4 receipts, or carry v4 standing). The CUE work proved the model encodes and
that independent executors agree; provider execution / runtime bindings remain a
later increment. **Research preview = honest. Production-ready = overclaim.**

## 6. What engineers should see first

**Not** `TSC 4.1 · C≡ · coalgebra · joint realization fibers · CM0 ·
InstrumentAssessment`. **Instead:**

> Define how your repository should be judged. Run it. Get an evidence-bound
> receipt. Let agents repair only what the evidence and policy authorize.

Public description:

> **TSC is methodology-as-code for agentic engineering.** It turns quality goals
> into versioned, composable programs that measure an exact repository or workflow
> and produce evidence-bound receipts. Receipts distinguish defects from
> incomplete evidence and policy gaps, so repair agents can act without inventing
> the standard they are supposed to satisfy.

Theory lives under **Foundations**, never on the first screen.

## 7. The first product wedge — one built-in methodology

Do **not** first ask users to learn the CM language. Ship one valuable built-in:
**Repository Coherence** (Legibility · Structure · Operability). The first useful
command should feel like `coh repo assess .` (eventually `coh cm run
repository-coherence --target .`), producing: a terminal summary; a canonical JSON
receipt; a human-readable HTML report; GitHub Check annotations; exact commit + CM
digests; findings grouped by repairability.

```
Repository Coherence: DEFECTS_FOUND
Legibility  PASS · Structure DEFECT · Operability INCOMPLETE
3 mechanical repairs · 2 policy decisions required · 1 incomplete consumer search
Report: .coh/runs/…/report.html   Receipt: .coh/runs/…/receipt.json
```

**Built-in first, custom authoring second.** Users must first believe it (1)
catches important defects, (2) doesn't drown them in false positives, (3) saves
more time than it costs, (4) produces safer repair plans than generic prompting.
*Then* they care that they can author their own CMs.

## 8. The examples that matter

1. **Hello World** — "Does this repo have a readable README?" (positive/negative/incomplete). Teaches the whole language loop with zero theory.
2. **Structural coherence** — one artifact · one owner · one canonical home · all consumers enumerated before a move. First compelling real use case.
3. **Agent operability** — give a fresh agent the repo: find the implementation contract, install deps, run documented tests, find the active research program, recognize unsupported v4 execution, produce evidence. Highly relevant to agent-heavy teams.
4. **The wrong-repair case (the strongest demo).** *A planned cleanup was going to delete a legacy docs tree; the CM's consumer graph found parts still used by runtime, tests, and CI. The destructive repair was cancelled; the classification was fixed instead.* One story explains the entire value. (This actually happened in this repo — write it up.)
5. **CM0** — a methodology assessing another methodology. Keep as an *advanced* example; it demonstrates reflectivity but will not drive first adoption.

## 9. The GitHub Action matters more than a Pages site

The key adoption surface is likely:

```yaml
- uses: usurobor/coh-action@v1
  with: { methodology: repository-coherence }
```

Run on a PR → assess the exact head → compare to the baseline receipt → post a
concise check summary → attach the full receipt → block **only** on explicitly
configured conditions. It meets engineers where they already work (PR checks).

GitHub **Pages: yes** — but as documentation delivery, not the adoption strategy.
A lightweight generated site (repo stays canonical; docs version with code; no
backend). Site map: Home (one-sentence value + one receipt screenshot + 5-min
demo) · Why TSC? · Quickstart · Concepts · Tutorials · Reference · **Case studies**
· Foundations · **Limitations**.

## 10. What must be proved before asking people to adopt

1. **It reduces supervision cost** — measure operator minutes, prompt/review turns, agent retries, time-from-finding-to-verified-closure; compare *prompt-and-review-again* vs *run CM → frozen receipt → bounded cells → remeasure*. This dramatic reduction is the central product hypothesis and needs a **recorded** comparison.
2. **It catches defects existing tools miss** — false authority, mixed-lifecycle dirs, policy gaps, semantic contradictions, unsafe moves via hidden consumers, newcomer inability to reconstruct project identity. Tests/linters rarely capture these.
3. **It avoids creating bureaucracy** — measure CM source lines, time to author/update, false-positive rate, % findings actionable, policy decisions surfaced, executor agreement. *A CM that takes a week to author for a one-hour repair has failed.*

## 11. The public evidence package

Before any real launch, publish **one rigorous case study** — the *Repository
Cleanup Case Study*: initial state (exact commit, baseline prompt-based process,
operator burden) → CM (Legibility + Structure, requirements, fixtures, version) →
Run 1 (findings, refusals, proposed repairs) → repair wave (cells, reviews,
operator decisions) → **prevented failure** (legacy-tree deletion caught by the
consumer graph) → Run 2 (closed findings, independent verification) → **measured
outcomes** (elapsed time, operator minutes, model calls, findings closed,
regressions, incorrect repairs prevented). Far stronger than a theory paper.

> **First draft written:** [`case-studies/repository-cleanup.md`](case-studies/repository-cleanup.md)
> — grounded in the frozen receipts, the plane ADR (v1.2), and the repair-wave
> commits; qualitative outcomes documented, quantitative metrics flagged
> "to instrument."

## 12. Release sequence

- **Research preview (now):** repo + Pages docs + architecture essay + CUE reference model + four example CMs + receipts from the TSC repo case + limitations & roadmap. Audience: researchers, agent-tool builders, design partners, formal-methods/policy-as-code people. *Not* marketed as production-ready.
- **Developer preview (after the runtime MVP):** `coh cm check/compile/run`, `coh receipt verify`, built-in Repository Coherence, the GitHub Action, HTML+JSON receipts. Custom `.cm` authoring stays experimental.
- **Author preview:** the compact syntax, editor diagnostics / language server, the property library, `cm init`, fixture runner, CM0 assessment.
- **Ecosystem (only after real usage):** versioned property packages, a CM registry, provider adapters, hosted run history, cross-repo dashboards, team policy management.

## 13. Framing the language publicly

Do **not** lead with "a new F#-inspired language" (sounds like a DSL hunting for a
problem). Lead with **"write executable quality methodologies by composing typed,
checkable properties,"** then show a short, obviously-readable example. The syntax
is *evidence the system is usable*, not the headline.

## 14. Adoption probability (honest)

- Broad adoption of the full theory soon — **unlikely.**
- A niche of agent-heavy maintainers wanting repository methodology-as-code — **plausible.**
- Teams valuing a tool that reduces repeated agent supervision and yields actionable evidence — **very plausible, if demonstrated.**
- Tolerating a new language *before* seeing that value — **unlikely.**
- Becoming a wider standard — **possible, only after successful narrow tooling + interoperability.**

The climate is favorable (agent capacity rising faster than governance) but
crowded (agent platforms, eval platforms, AI governance, policy-as-code). TSC must
earn attention through **one unmistakable result**: an owner gave agents a complex
repository-quality objective; the methodology captured it once; the system found
defects and policy gaps, **prevented a destructive repair**, reduced repeated
supervision, and produced a verifiable final state.

## 15. Landing-page copy (draft)

- **Hero:** *Methodology-as-code for agentic engineering.*
- **Subhead:** *Define how your repository or agent workflow should be judged. Run the methodology against an exact snapshot. Get an evidence-bound receipt that distinguishes defects, incomplete evidence and policy decisions — then let agents repair only what the receipt authorizes.*
- **Encode quality once** — replace repeated prompts and reviewer memory with versioned methodologies.
- **Delegate safely** — give repair agents bounded, evidence-backed work instead of an open-ended goal.
- **Verify closure** — remeasure the repaired state and preserve the result as a reproducible receipt.

## Bottom line

Build it for engineers — but **first as a tool that removes supervision burden,
not a theory engineers must adopt.** GitHub Pages: yes. Examples: absolutely. A
GitHub Action: essential. **A concrete case study with measured time savings and a
prevented destructive repair: more important than either.** A compact language:
valuable *after* the built-in methodology proves itself.

The adoption sequence is **problem → one built-in solution → compelling evidence →
tool integration → authoring language → methodology ecosystem** — not *theory →
language → ecosystem → hope someone finds a problem.*
