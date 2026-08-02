# Data request: A3 disagreement extraction from the factorized-β run

Date: 2026-07-06
Author: κ (Herald) — recording operator intent as a typed request.
Status: **REQUEST** — no protocol change authorized by this note. Get the
data first; classify; only then decide whether a new experiment is justified.
Companions: [CONSISTENCY-FACTORIZATION-PREREG.md](CONSISTENCY-FACTORIZATION-PREREG.md)
(the frozen experiment + recorded FAIL), [self-measure-meter-loop.md](../../../docs/architecture/decisions/self-measure-meter-loop.md),
[defect-harvesting.md](../defect-harvesting.md).
Feeds: **#76** (meter-found semantic ambiguity queue) — this is its first concrete work item.

## The finding this request exists to investigate

> Deterministic code can force every witness to answer the **same question**,
> but if the question itself is semantically under-specified, honest witnesses
> can still answer **differently**.

The factorization made the **machinery** deterministic. It did **not** make the
**semantic predicate** deterministic. Tests prove "same bundle → same locus IDs
→ same aggregation formula → same gate arithmetic." They cannot prove that three
witnesses will agree that a target span semantically *supports* a source span.
So the FAIL is not a code/doc contradiction — it is the docs asking a still-ambiguous
question.

## What factorization removed — and the one freedom it left

Removed: **what to inspect** (engine enumerates the loci), **how to count**, **how
to aggregate** (engine, mechanically). Left: **what counts as semantic support** —
the residual inconsistency. Gate **A3** (mean exact-verdict agreement over unordered
sample pairs × eligible loci) failed because that residual predicate is not decidable
enough: e.g. a multi-claim source span partially supported by the target, or
"defines X" vs "is authoritative for X" — both readings defensible absent an explicit
repo rule.

## What we have vs what we need

- **Have:** the engine code, the prereg, the gate logic, the B3 fixture controls,
  and the public run surface.
- **Need:** the **raw per-locus inventory + per-sample responses** for the targets
  where A3 failed. Not summarized — the actual spans, the three verdicts, and the
  rationale snippets. That is what tells us *what kind* of ambiguity dominates.

## The request — exact extraction

From the factorized-β measurement run, produce a **disagreement table** for **every
target where A3 failed** (`cm-of-cms`, `methodology`, `repo`):

| column | meaning |
|---|---|
| `target` | held-out target |
| `locus_id` | `beta.<kind>.<ordinal>` |
| `kind` | `citation_bears_claim` \| `authority_claim` \| `target_file_fit` |
| `source_path` / `source_span` | the claiming site |
| `target_path` / `target_span` | the cited/target site |
| `r1` / `r2` / `r3` verdict | each sample's `supports` \| `contradicts` \| `insufficient` |
| `vote_pattern` | e.g. `2 supports / 1 insufficient` |
| `β contribution (per sample)` | the `w·d` this locus added under each sample |
| `rationale` | ≤ 1 sentence per sample |

Then **group the disagreement loci by disagreement type**:

1. `supports` vs `insufficient`
2. `insufficient` vs `contradicts`
3. `supports` vs `contradicts`
4. same verdict, **different rationale/evidence**

## Where the data lives (how to fulfill the request)

Run `factorized-beta-measure.yml` **28745643692** (`cycle/75` @ `2cf60ff`) uploaded,
per held-out target, the **pre-witness inventory** (locus_id + spans + kinds) and the
**k=3 raw witness responses** (per-locus verdicts + evidence + rationale), plus a
**gate-summary** artifact. Fulfilment = download those artifacts, join the inventory
(spans) with the three response sets (verdicts + rationale) on `locus_id`, compute the
per-locus vote pattern + agreement, and filter to the disagreement loci on the
A3-failing targets. This is exactly the parse step #76 (semantic ambiguity queue)
owns; the run's artifacts are its first input.

## Classification (perform on 20–50 disagreements, after extraction)

| code | disagreement cause |
|---|---|
| **A** | multi-claim source span (several claims in one span) |
| **B** | target span too broad or too short |
| **C** | authority/support **threshold** unclear (e.g. "defines X" ⇒ "authoritative for X"?) |
| **D** | a witness **missed explicit text** (read error) |
| **E** | real repo **ambiguity / content defect** |
| **F** | **label set too coarse** (`supports`/`insufficient`/`contradicts` can't express the case) |

**Decision rule (which cause implies which fix):**
- Mostly **A / B / F** → the *planned-local-measurement* idea (below) is promising —
  the problem is claim-decomposition / check-boundary, addressable structurally.
- Mostly **C / E** → the fix is **artifact clarification or gold-label adjudication**,
  not more measurement machinery.
- Mostly **D** → the fix is **cross-route / witness reliability**, not a new protocol.

## Candidate design — NOT authorized; contingent on the classification

**Planned local measurement** — framed honestly as *separating claim-decomposition
variance from semantic-verdict variance*, **not** "fixing LLM consistency":

```
Phase 0 — engine inventory      : the same deterministic β loci as before
Phase 1 — plan proposal         : k=3 planners decompose each resolved locus into
                                   atomic checks (check_id, source claim, target
                                   evidence needed, allowed labels, support-threshold
                                   sentence)
Phase 2 — plan consensus        : engine clusters proposals; only checks with ≥2/3
                                   agreement enter the FROZEN plan; singletons become
                                   a reported "plan tail" (not scored)
Phase 3 — constrained adjudication: k=3 judges answer ONLY the frozen atomic checks
Phase 4 — aggregation           : engine aggregates check verdicts → locus verdicts → β
```

**Risk to guard:** the plan phase reintroduces the *selection freedom* we removed —
witnesses could agree on a shallow plan and skip the hard checks. It is safe **only**
if the plan is frozen by consensus (and/or steward), never a free LLM-designed metric.
And it will **not** help if disagreement is truly interpretive even after atomic
decomposition (cause C/E) — there the fix is doctrine clarification or gold labels.

## Guardrails

- **Do not alter the protocol yet.** Extract → classify → then decide. No new
  experiment designed blind.
- This is **data harvesting** (ambiguity / disagreement), **not**
  consistency-optimization. It does **not** reopen the stopped meter loop, does not
  authorize a v3.2.5, and its metrics are agreement/ambiguity — never Coh.
- The factorized-β verdict stays **FAIL / terminal**; this request analyses *why*, it
  does not re-run or re-tweak the experiment.
