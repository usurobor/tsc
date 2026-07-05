# Pre-registration: consistency by task factorization (the freedom seam)

Date: 2026-07-05
Revision: 3 (operator review 2026-07-05 rev 2 → REQUEST CHANGES;
`repeated_fact` cut, B3 fixture manifest committed, A3 made
formula-exact, locus-sparsity given a pre-witness inventory + a
NO-DECISION guard)
Status: PRE-REGISTRATION — awaiting operator review of the revised gate.
No code, instrument, engine, runtime, or workflow change is authorized
by this note.
Operator dispatch: yes (2026-07-05 conversation).
Companion: [METER-LOOP-DECISION.md](METER-LOOP-DECISION.md) — the
binding stop rule this note re-enters against, and
[DEFECT-HARVESTING.md](DEFECT-HARVESTING.md) — the parallel replacement
line that continues regardless.
Fixture source of truth (B3):
[fixtures/factorized-beta-controls.json](fixtures/factorized-beta-controls.json)
— committed with this revision; frozen before implementation.

## Re-entry conditions (from METER-LOOP-DECISION.md)

The meter-loop stop rule permits a new consistency experiment only with
ALL of: (1) operator dispatch; (2) a written theory of variance that
explains the v3.2.3 AND v3.2.4 measurements and names a variance source
**not already falsified**; (3) a pre-registered gate reviewed before
any implementation. This note supplies (2) and (3). Implementation is
NOT authorized by drafting or revising this note; it is held for a
further operator review after this revision.

This experiment is also outside the **rejected line** of the stop
record. The rejected line was "more structured witness filing as a
consistency fix" — a category/severity checklist (v3.2.3) and
machine-validated defect cards (v3.2.4), both of which added *reporting
structure* while the LLM continued to emit the scalar judgment. This
experiment does the opposite: it **removes the scalar judgment from the
LLM** and replaces holistic reading with adjudication over a
mechanically-enumerated locus set.

## Theory of variance

The witness task has four degrees of freedom: **coverage** (what the
LLM reads), **counting** (how many defects an observation counts as),
**aggregation** (the mapping from findings to the α/β/γ scalar, done
inside the model), and **reporting** (the filing format).

v3.2.3 and v3.2.4 both moved only **reporting**, and both failed. The
stop record's own k=5 finding is the constraint this theory respects and
does NOT contradict: witnesses converge on a shared defect core
(60–100%) but file the same defects under different axes, and one
witness's counting scale can sit an order of magnitude from its peers.

So discovery is **not** the primary residual source. The unfalsified
source, stated precisely:

> The remaining unfalsified variance is **unbounded locus
> selection/counting and scalar aggregation inside the witness task** —
> not reporting structure, and not primarily discovery overlap. The k=5
> evidence shows witnesses agree on the *big* defects; the witness still
> chooses an unbounded *set* of observations, chooses how many defects
> each observation counts as, and maps that private set to a scalar in
> its head. Factorization tests whether **deterministic locus
> enumeration plus mechanical counting/aggregation** reduces β variance
> while **preserving semantic discrimination**.

## Design: the mechanical/semantic seam

The consistency-vs-freedom trade is not a scalar dial (fully mechanical
= 100% consistent but LLM-free; fully free = discriminating but noisy).
It is a **factorization seam**. Cut the task so the LLM's only remaining
freedom is local semantic judgment, and make selection, counting, and
aggregation deterministic:

1. **Engine enumerates the β loci** (kills selection freedom). Every
   witness adjudicates the SAME fixed site set.
2. **LLM adjudicates each locus** with a bounded, evidence-anchored
   question. Three labels; the LLM never emits a scalar.
3. **Engine counts and aggregates** the verdicts into β by a
   pre-registered formula (kills counting/aggregation freedom).

## Scope: β only, single-shot, terminal

β is where mechanical locus-extraction is strongest and already built.
α (naming/conceptual drift) may be irreducibly holistic and would
confound attribution; γ is intermediate. **The first experiment
factorizes β only.** γ is explicitly OUT of scope: a β pass may justify
a *separate* γ pre-registration; a β failure terminates the
factorization claim. One gate, one verdict — not an
iterate-until-it-passes loop — and it does **not** reset the meter-loop
counter, which governs the closed filing-structure line.

## β locus schema

Allowed β locus `kind`s for this experiment — **each maps to an
existing deterministic β signal in `mechanical_scoring.ml`**, so the
enumerator cannot be invented after seeing target behaviour:

| `kind`               | mechanical anchor (β config)                          |
|----------------------|-------------------------------------------------------|
| `citation_bears_claim` | `cross_reference_consistency` + `source_of_truth_alignment` (internal link + anchor resolution) |
| `authority_claim`      | `authority_alignment` (authority self-claim detection) |
| `target_file_fit`      | `target_file_fit` (target declaration / H1 vs content) |

**`repeated_fact` is OUT of scope for this experiment (F1).** There is
no deterministic repeated-fact extractor in `mechanical_scoring.ml`
(only a `"fact-drift"` checklist *string* in `response_schema.ml`, which
is a witness category, not an enumerator). Including it would grant
post-hoc freedom to invent "repeated facts" after seeing behaviour, and
literal-version-claim matching would drag γ/version semantics into a β
experiment. It may return only via a separately designed and reviewed
extractor.

```json
{
  "locus_id": "beta.link.0007",
  "kind": "citation_bears_claim | authority_claim | target_file_fit",
  "source_path": "README.md",
  "source_span": "line/section cite of the claiming text",
  "target_path": "spec/tsc-core.md",
  "target_span": "line/section cite of the cited target",
  "question": "Does the cited target support the claim the source makes about it?",
  "mechanical_status": "resolved | unresolved | ambiguous"
}
```

`unresolved` = the mechanical link/anchor does not resolve (a broken
reference the engine already detects; scored without an LLM call).
`ambiguous` / `resolved` = present; the LLM judges semantic bearing.

## LLM locus-response schema

Exactly one response per `locus_id` — no more, no less. Bounded
verdict, mandatory evidence:

```json
{
  "locus_id": "beta.link.0007",
  "verdict": "supports | contradicts | insufficient",
  "confidence": 0.0,
  "evidence": "source cite + target cite (both required on a negative verdict)",
  "rationale": "one sentence"
}
```

## Aggregation formula — locked before code

**Locus inventory (deterministic, pre-witness).** For target T the
engine enumerates its β loci BEFORE any witness call and uploads the
inventory artifact (cited in the close-out). Define:

- **N(T)** = all enumerated β loci.
- **E(T)** = LLM-eligible loci = `mechanical_status ∈ {resolved,
  ambiguous}` (the sites where the seam is actually exercised).

Per-locus **defect weight** `d`:

| verdict / status                  | d   | LLM call |
|-----------------------------------|-----|----------|
| `supports`                        | 0.0 | yes      |
| `insufficient`                    | 0.5 | yes      |
| `contradicts`                     | 1.0 | yes      |
| `mechanical_status = unresolved`  | 1.0 | **no**   |

Per-`kind` weight `w`:

| kind                   | w   |
|------------------------|-----|
| `citation_bears_claim` | 1.0 |
| `authority_claim`      | 1.0 |
| `target_file_fit`      | 0.5 |

Over all N(T) loci (unresolved included, as real β defects):

```
β_factorized = 1 − ( Σ_i w(kind_i) · d(verdict_i) ) / ( Σ_i w(kind_i) )
```

clamped to [0,1]. Degenerate / malformed handling (declared):

- **N(T) = 0**: `β_factorized = 1.0`, `beta_loci: 0`; target is
  `locus_sparse`.
- **locus_sparse** ⇔ **E(T) < 5**. Sparsity is on the LLM-eligible
  count, NOT the total: a target whose loci are all mechanically
  `unresolved` exercises no LLM judgment, so its β consistency is
  trivially 1.0 and must not count as a seam pass. Sparsity is
  determined by the pre-witness inventory artifact, never discovered
  after LLM results. A `locus_sparse` target is **excluded from
  A1/A2/A3** and reported as observation; it is still counted in A0
  yield if any witness call is made.
- **missing / duplicate locus answer**: the SAMPLE is refused by the
  funnel (malformed → not scored, matching the engine's "refuse, don't
  skip" contract). A refused sample counts against yield (A0).

The β scalar per sample is `β_factorized`; cross-sample consistency is
the existing barrier over the β field's max-pairwise spread
(`Witness_numeric.per_field_spread` → `max_pairwise` → `Coherence`). No
new statistic.

## Pre-registered gate

Measured on CI over the held-out target set, k=3, against a baseline
measured on the SAME tree immediately before the instrument change.
Two-sided; both sides must pass, per target.

### A — consistency objective

- **A0. Full yield.** `declared_samples == validated_samples == 3` on
  every held-out target; every sample answers every required `locus_id`
  exactly once.
- **A1. β consistency floor.** per-target β
  `Coh_consistency_max_pairwise ≥ 0.90` on every non-`locus_sparse`
  held-out target.
- **A2. β improvement.** per-target β `Coh_consistency_max_pairwise ≥`
  same-tree free-witness β baseline **+ 0.10** absolute. Baseline `B_β`
  measured and recorded before any change; A2 evaluated against the
  recorded value.
- **A3. Locus-level agreement — exact.** For target T with validated
  samples S and eligible loci L(T) = { l ∈ E(T) } (i.e.
  `mechanical_status ≠ unresolved`):

  ```
  agreement(T) = mean over all unordered sample pairs (s_i, s_j) in S,
                 and all loci l in L(T), of:
                     1 if verdict(s_i, l) == verdict(s_j, l)
                     0 otherwise
  A3 passes iff agreement(T) ≥ 0.90 for every non-locus_sparse
  held-out target.
  ```

  If L(T) = 0 or T is `locus_sparse` (E(T) < 5), T is excluded from A3
  — the same rule as A1/A2, applied consistently.

### B — discrimination retained (the guard)

- **B1. Kata non-regression.** kata-01 (glider) still PASSES; kata-02
  (random soup) still FAILS — verdicts unchanged.
- **B2. Admissibility non-regression.**
  `scripts/cm-admissibility.sh --self-test` preserves the exact
  registered verdict matrix — including the two *measured admissions*
  (`basename-gamer`, `cherry-pick-assassin`) — with exit 0. A
  non-regression guard, not evidence of semantic discrimination.
- **B3. β local semantic controls — the discrimination gate.** The
  fixture set at
  [`docs/beta/governance/fixtures/factorized-beta-controls.json`](fixtures/factorized-beta-controls.json)
  (committed with this revision; may not be edited in the
  implementation PR except to fix a syntax error caught before any
  measurement run) must pass. Each fixture carries: `id`, `kind`,
  `source_text`, `target_text`, `source_path`, `target_path`,
  `mechanical_status`, `expected_verdict`, `required_evidence_sides`.
  Required: **all hard controls pass while n < 20**; once **n ≥ 20**,
  **≥ 95% label agreement**; **every negative verdict cites both source
  and target evidence** (`required_evidence_sides` honored).
- **B4. Free-witness proximity — observation only.** factorized β
  reported against the free-witness β medoid (k=3), tolerance 0.10. A
  reported residual, NOT a pass/fail condition — B3 is the
  semantic-retention proof.

### C — standing, scope, and NO-DECISION

- **C1.** No standing promotion.
- **C2.** `standing_scope` stays `house-authored-public-commons`.
- **C3.** The existing max-pairwise standing statistic stays reported.
- **C4. NO-DECISION guard.** If **more than one** of the five held-out
  targets is `locus_sparse`, the experiment records **NO-DECISION** (not
  pass, not fail): the β seam did not have enough surface across the
  held-out set to be tested, and no implementation promotion occurs.
- **C5.** Otherwise a miss on ANY A0–A3 / B1–B3 condition on any
  scored held-out target records the experiment as FAILED (predictions,
  baseline, measured numbers, interpretation) here and in the CHANGELOG
  witness index, as v3.2.3/v3.2.4 were. On failure: no protocol
  promotion, no standing change; factorization code retained only as
  contract hardening with no consistency claim, or reverted.
- **C6.** A FAILED or NO-DECISION verdict is terminal for this
  factorization line absent a fresh operator dispatch.

Aligned with CM² doctrine: same-route LLM consistency is a standing
gate; reports below the floor publish without off-diagonal standing;
standing scope does not promote by prose.

## Resolved operator decisions

1. **Held-out / tuning split.** No real registry target is a tuning
   target. All five — `spec`, `engine`, `repo`, `methodology`,
   `cm-of-cms` (`targets/registry.tsc`) — are **held out**.
   Implementation tunes only against **synthetic fixtures** (the B3
   controls, unit fixtures) and the existing kata / admissibility
   commands as non-regression surfaces.
2. **B3/B4 tolerance.** The 0.10 free-witness proximity is **demoted**
   to observation (B4); the discrimination gate is the labeled β local
   controls (B3).
3. **γ.** OUT of scope.

### The three judgment calls (operator-approved rev 2, clarified here)

1. **Missing/duplicate locus answer refuses the sample** — approved;
   refusal keeps malformed output distinct from semantic uncertainty.
2. **`E=0 → β=1.0`; `E<5 → locus_sparse`** — approved, with the
   clarification now in Aggregation: sparsity is fixed by the
   **pre-witness inventory artifact**, never discovered after LLM
   results; and the NO-DECISION guard (C4) fires if more than one
   held-out target is sparse.
3. **A1 excludes `locus_sparse` targets** — approved, guarded by C4 so
   sparsity cannot silently shrink the tested set into a hollow pass.

## What is explicitly NOT claimed / authorized

- No claim that α or γ is decomposable; neither scalar is touched.
- No standing-gate change; k stays 3; the spread statistic and
  adjudication rule are unchanged as levers.
- No engine, runtime, `SELF-MEASURE.md`, workflow, release, ledger, or
  tag change is authorized by this note. This revision is docs-only
  (the prose + the frozen B3 fixture manifest).

## Proof / rejection mechanism

This pre-registration is rejected if any gate item cannot be evaluated
by a command, fixture, artifact, or explicit numeric comparison. A
further operator review is required before implementation.
