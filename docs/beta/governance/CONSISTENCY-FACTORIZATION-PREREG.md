# Pre-registration: consistency by task factorization (the freedom seam)

Date: 2026-07-05
Revision: 2 (operator review 2026-07-05 — REQUEST CHANGES F1–F5 applied;
gate made executable; split frozen; schema and aggregation locked)
Status: PRE-REGISTRATION — awaiting operator review of the revised gate.
No code, instrument, engine, runtime, or workflow change is authorized
by this note.
Operator dispatch: yes (2026-07-05 conversation).
Companion: [METER-LOOP-DECISION.md](METER-LOOP-DECISION.md) — the
binding stop rule this note re-enters against, and
[DEFECT-HARVESTING.md](DEFECT-HARVESTING.md) — the parallel replacement
line that continues regardless.

## Re-entry conditions (from METER-LOOP-DECISION.md)

The meter-loop stop rule permits a new consistency experiment only with
ALL of: (1) operator dispatch; (2) a written theory of variance that
explains the v3.2.3 AND v3.2.4 measurements and names a variance source
**not already falsified**; (3) a pre-registered gate reviewed before
any implementation. This note supplies (2) and (3). Implementation is
NOT authorized by drafting or revising this note; it is held for a
second operator review after this revision.

This experiment is also outside the **rejected line** of the stop
record. The rejected line was "more structured witness filing as a
consistency fix" — a category/severity checklist (v3.2.3) and
machine-validated defect cards (v3.2.4), both of which added *reporting
structure* while the LLM continued to emit the scalar judgment. This
experiment does the opposite: it **removes the scalar judgment from the
LLM** and replaces holistic reading with adjudication over a
mechanically-enumerated locus set. It changes the task's factorization,
not its filing form.

## Theory of variance

The witness task has four degrees of freedom: **coverage** (what the
LLM reads), **counting** (how many defects an observation counts as),
**aggregation** (the mapping from findings to the α/β/γ scalar, done
inside the model), and **reporting** (the filing format).

v3.2.3 and v3.2.4 both moved only **reporting**, and both failed
(FALSIFIED +0.0128; FAILED, counter 2/2). The stop record's own k=5
finding is the constraint this theory must respect and does NOT
contradict:

> witnesses converge on a shared defect core (top clusters found by
> 60–100% of samples) but FILE the same defects under different axes,
> and one witness's counting scale can sit an order of magnitude from
> its peers.

So discovery is **not** the primary residual source — overlap exists on
the largest defects. The unfalsified source, stated precisely (F3):

> The remaining unfalsified variance is **unbounded locus
> selection/counting and scalar aggregation inside the witness task** —
> not reporting structure, and not primarily discovery overlap. The
> k=5 evidence shows witnesses agree on the *big* defects; but the
> witness still chooses an unbounded *set* of observations, chooses how
> many defects each observation counts as, and maps that private set to
> a scalar in its head. Factorization tests whether **deterministic
> locus enumeration plus mechanical counting/aggregation** reduces β
> variance while **preserving semantic discrimination**.

This explains both prior failures (reporting structure can touch none
of selection, counting, or aggregation) without asserting the falsified
claim that discovery is the dominant term.

## Design: the mechanical/semantic seam

The consistency-vs-freedom trade is not a scalar dial (fully mechanical
= 100% consistent but LLM-free; fully free = discriminating but noisy).
It is a **factorization seam**. Cut the task so the LLM's only remaining
freedom is local semantic judgment — the one thing mechanical scoring
cannot do — and make selection, counting, and aggregation deterministic:

1. **Engine enumerates the β loci** (kills selection freedom). Every
   witness adjudicates the SAME fixed site set. `mechanical_scoring.ml`
   already extracts them: `extract_md_links` + anchor resolution
   (cross-references and whether they resolve), authority self-claim
   detection, source-of-truth alignment over internal links, and
   target-file fit.
2. **LLM adjudicates each locus** with a bounded, local,
   evidence-anchored question. The answer space is three labels; the
   LLM never emits a scalar.
3. **Engine counts and aggregates** the per-locus verdicts into β by a
   pre-registered formula (§ Aggregation, kills counting/aggregation
   freedom).

This makes `hybrid` mode actually FUSE its two arms (LLM judges the
mechanically-found sites) rather than run them blind and report both
sub-objects side by side, which is the current behaviour.

## Scope: β only, single-shot, terminal

β is where mechanical locus-extraction is strongest and already built;
its loci are syntactically anchored. α (naming/conceptual drift) may be
irreducibly holistic and would confound attribution; γ is intermediate.
**The first experiment factorizes β only.** α and γ keep their current
holistic scalar. γ is explicitly OUT of scope (F5-answer 3): a β pass
may justify a *separate* γ pre-registration later; a β failure
terminates the factorization claim. This is one gate, one verdict — not
an iterate-until-it-passes loop — and it does **not** reset the
meter-loop counter, which governs the closed filing-structure line.

Likely partial outcome, pre-declared so it is not moved post hoc: β
snaps toward the floor; α stays holistic; γ untested here. A per-axis
result is the point.

## β locus schema (F2)

The engine emits one locus object per enumerated β site. `kind` is
fixed; `mechanical_status` is the engine's deterministic pre-verdict.

```json
{
  "locus_id": "beta.link.0007",
  "kind": "citation_bears_claim | authority_claim | repeated_fact | target_file_fit",
  "source_path": "README.md",
  "source_span": "line/section cite of the claiming text",
  "target_path": "spec/tsc-core.md",
  "target_span": "line/section cite of the cited target",
  "question": "Does the cited target support the claim the source text makes about it?",
  "mechanical_status": "resolved | unresolved | ambiguous"
}
```

`unresolved` = the mechanical link/anchor/fact does not resolve at all
(a broken reference the engine already detects). `ambiguous` = resolves
but the engine cannot determine bearing (the LLM's job). `resolved` =
mechanically present; the LLM judges semantic bearing.

## LLM locus-response schema (F2)

The witness returns exactly one response per locus_id — no more, no
less. Bounded verdict, mandatory evidence:

```json
{
  "locus_id": "beta.link.0007",
  "verdict": "supports | contradicts | insufficient",
  "confidence": 0.0,
  "evidence": "source cite + target cite (both required on a negative verdict)",
  "rationale": "one sentence"
}
```

## Aggregation formula (F2) — locked before code

Per-locus **defect weight** `d` from verdict:

| verdict / status                         | d    | LLM call |
|------------------------------------------|------|----------|
| `supports`                               | 0.0  | yes      |
| `insufficient`                           | 0.5  | yes      |
| `contradicts`                            | 1.0  | yes      |
| `mechanical_status = unresolved`         | 1.0  | **no** (engine decides) |

Per-`kind` weight `w` (declared here; not discoverable during
implementation):

| kind                 | w   |
|----------------------|-----|
| `citation_bears_claim` | 1.0 |
| `authority_claim`      | 1.0 |
| `repeated_fact`        | 1.0 |
| `target_file_fit`      | 0.5 |

Over the E eligible loci for a target:

```
β_factorized = 1 − ( Σ_i w(kind_i) · d(verdict_i) ) / ( Σ_i w(kind_i) )
```

clamped to [0,1]. Degenerate / malformed handling (declared):

- **E = 0** (no β loci): `β_factorized = 1.0`, `beta_loci: 0` recorded.
- **locus-sparse** (E < 5): target is flagged `locus_sparse`, reported
  as observation, and **excluded from A1/A2** — too few sites to clear
  a +0.10 improvement above noise.
- **missing locus answer** or **duplicate locus answer**: the SAMPLE is
  refused by the funnel (malformed → not scored, not silently coerced,
  matching the engine's existing "refuse, don't skip" contract). A
  refused sample counts against yield (A0).

The β scalar per sample is `β_factorized`. Cross-sample consistency is
the existing barrier over the β field's max-pairwise spread
(`Witness_numeric.per_field_spread` → `max_pairwise` → `Coherence`
barrier). No new statistic.

## Pre-registered gate

Measured on CI over the held-out target set, k=3, against a baseline
measured on the SAME tree immediately before the instrument change.
Two-sided: consistency alone is trivially maximized by degenerating
toward mechanical mode, so both sides must pass, per target.

### A — consistency objective

- **A0. Full yield.** `declared_samples == validated_samples == 3` on
  every held-out target; every sample answers every required locus_id
  exactly once (missing/duplicate → refused, per Aggregation).
- **A1. β consistency floor.** per-target β
  `Coh_consistency_max_pairwise ≥ 0.90` on all five held-out targets
  (locus-sparse targets excluded, reported).
- **A2. β improvement.** per-target β `Coh_consistency_max_pairwise ≥`
  same-tree free-witness β baseline **+ 0.10** absolute. Baseline `B_β`
  is measured and recorded before any change and evaluated against that
  recorded value.
- **A3. Locus-level agreement.** for each held-out target, pairwise
  agreement over local locus verdicts ≥ **0.90**, excluding loci
  mechanically marked `unresolved`.

### B — discrimination retained (the guard)

- **B1. Kata non-regression.** kata-01 (glider) still PASSES; kata-02
  (random soup) still FAILS — verdicts unchanged.
- **B2. Admissibility non-regression (F1).**
  `scripts/cm-admissibility.sh --self-test` preserves the exact
  registered verdict matrix — including the two *measured admissions*
  (`basename-gamer`, `cherry-pick-assassin`) — with exit 0. This is a
  non-regression guard, **not** evidence that factorized β is
  semantically discriminating. (The prior "each attacker's β" wording
  was invalid: registered attackers are scorer programs in
  `heldout/registrations.json`, not β-bearing target bundles.)
- **B3. β local semantic controls (F4) — the discrimination gate.** A
  predeclared fixture set of β loci with known-correct labels must
  pass. Controls (each a tiny synthetic β locus):
  - resolving citation whose target TRULY supports the source claim →
    `supports`;
  - resolving citation whose target does NOT support the claim →
    `contradicts`;
  - broken link → `mechanical_status = unresolved` (engine, no LLM);
  - repeated-fact drift → `contradicts`;
  - authority conflict → `contradicts`;
  - target-file / H1 mismatch (`target_file_fit`) → `contradicts`;
  - a clean no-defect control → `supports`.
  Required: **all hard controls pass while n < 20**; once **n ≥ 20**,
  **≥ 95% label agreement**; **every negative verdict cites both source
  and target evidence**.
- **B4. Free-witness proximity — observation only (F4).** factorized β
  is reported against the free-witness β medoid (k=3) with tolerance
  0.10. This is a reported residual, NOT proof of discrimination; it
  cannot pass or fail the gate on its own — B3 is the semantic-retention
  proof.

### C — standing and scope

- **C1.** No standing promotion.
- **C2.** `standing_scope` stays `house-authored-public-commons`.
- **C3.** The existing max-pairwise standing statistic stays reported.
- **C4.** A miss on ANY A0–A3 / B1–B3 condition on any held-out target
  records the experiment as FAILED (predictions, baseline, measured
  numbers, interpretation) in this note and the CHANGELOG witness
  index, as v3.2.3/v3.2.4 were. On failure: no protocol promotion, no
  standing change; factorization code, if written, is retained only as
  contract hardening with no consistency claim, or reverted.
- **C5.** A miss is **terminal** for this factorization line absent a
  fresh operator dispatch.

Aligned with CM² doctrine: same-route LLM consistency is a standing
gate; reports below the floor publish without off-diagonal standing;
standing scope does not promote by prose.

## Resolved operator decisions (were open items)

1. **Held-out / tuning split (F5).** **No real registry target is a
   tuning target.** All five registry targets — `spec`, `engine`,
   `repo`, `methodology`, `cm-of-cms` (`targets/registry.tsc`) — are
   **held out**. Implementation may tune only against **synthetic
   fixtures**: purpose-built β locus fixtures, unit fixtures, and the
   existing kata / admissibility commands used as non-regression
   surfaces. Stricter than strictly necessary; prevents Goodhart
   leakage.
2. **B3/B4 tolerance.** The 0.10 free-witness proximity is **demoted**,
   not tightened — kept as observation (B4). The discrimination gate is
   the labeled β local controls (B3), because the free-witness scalar is
   the unstable instrument this line exists to replace and must not hold
   veto over its replacement.
3. **γ.** OUT of scope. β-only is the first falsification; a β pass may
   justify a separate γ pre-registration; a β failure terminates the
   factorization claim.

## What is explicitly NOT claimed / authorized

- No claim that α or γ is decomposable; neither scalar is touched.
- No standing-gate change; k stays 3; the spread statistic and
  adjudication rule are unchanged as levers.
- No engine, runtime, `SELF-MEASURE.md`, workflow, release, ledger, or
  tag change is authorized by this note. This revision is docs-only.

## Proof / rejection mechanism

This pre-registration is itself rejected if any gate item cannot be
evaluated by a command, fixture, artifact, or explicit numeric
comparison. Second operator review is required before implementation.
