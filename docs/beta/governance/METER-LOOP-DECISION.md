# Decision record: the meter self-improvement loop is stopped

Date: 2026-07-04
Status: Binding until superseded by an operator dispatch
Owner: operator (usurobor)

## Decision

The self-improving meter loop — iterating the witness contract
(`runtime/SELF-MEASURE.md`) to raise semantic witness consistency — is
**stopped**. Its pre-registered stop rule fired: two consecutive
candidates failed their falsification gates.

**Loop stopped: counter 2/2.**

| Candidate | Claim | Gate | Result |
|-----------|-------|------|--------|
| SELF-MEASURE v3.2.3 (per-axis defect checklist + medoid-of-k) | per-target k=3 Coh_consistency +0.10 | pre-registered, measured on CI | **FALSIFIED** (+0.0128, noise-level) — counter 1/2 |
| SELF-MEASURE v3.2.4 (structured defect cards + precedence + k-fair statistic) | full yield; min mean-pairwise ≥ 0.85; ≥ +0.03 over the v3.2.3 k=5 baseline; ≥ 80% cluster axis agreement | pre-registered, measured on CI run 28703325203 | **FAILED** (yield 4/5 on repo; min 0.725; two targets moved negative) — counter 2/2 |

Both experiments' full records (predictions, baselines, measured
numbers, interpretations) live inside
`runtime/SELF-MEASURE.md` §3.2 and in the CHANGELOG's
"Witness-protocol releases (SELF-MEASURE)" index.

## Rejected line of work

**More structured witness filing as a consistency fix.** Two distinct
structuring mechanisms — a category/severity checklist (v3.2.3) and
machine-validated defect cards with a filing-precedence rule
(v3.2.4) — both failed to move the consistency statistic. The
evidence across both experiments:

- the variance is not in *reporting discipline*: witnesses follow the
  walk and the card contract when they comply at all;
- it is not primarily in *discovery*: witnesses converge on a shared
  defect core (top clusters found by 60–100% of samples);
- it is in *judgment* — which axis a shared defect belongs to and how
  many defects an observation counts as — and one witness's counting
  scale can sit an order of magnitude from its peers';
- heavier contracts additionally **cost yield**: under v3.2.4,
  witnesses began skipping the checklist walk entirely (repo 4/5 on
  the registered run; spec 3/5 on the incidental second draw).

## What is NOT permitted without a new dispatch

No SELF-MEASURE protocol revision whose purpose is to improve the
consistency statistic may be designed, pre-registered, or run — in
particular no "v3.2.5-style" prompt/schema tweak. This includes
indirect forms: no changing k, the spread statistic, the adjudication
rule, or the instruction's scoring rubric with a consistency-movement
rationale. There is no discretionary exception; the re-entry
condition below is the only door.

## Re-entry condition

A new witness-contract consistency experiment requires ALL of:

1. an explicit operator dispatch;
2. a written theory of variance that explains the v3.2.3 AND v3.2.4
   measurements and identifies a variance source **not already
   falsified** by them (i.e. not reporting structure, not discovery
   overlap);
3. a pre-registered gate reviewed before any implementation.

## Replacement line of work

The meter remains in service as a **defect finder**, not an
optimization target:

1. **Pipeline stabilization** — the measurement pipeline is corrected
   when it is wrong (e.g. the funnel-valid medoid election, PR #69),
   with regression proof; red CI is reserved for pipeline failures,
   never for expected witness variance.
2. **Defect harvesting** — repeated, cited witness findings become
   CDD issues through the queue defined in
   [DEFECT-HARVESTING.md](DEFECT-HARVESTING.md); its metrics are
   defect-yield metrics, not Coh-consistency.
3. **External calibration design** — cross-route witnesses and
   externally-anchored calibration (the diversity ladder named in the
   0.10.4 ledger row) as the eventual consistency evidence, replacing
   same-route prompt iteration.
4. **Content hygiene** — meter-found content defects are fixed as
   ordinary content work, never claimed as meter improvement.

## Standing consequences (unchanged by this record)

- The standing gate stays max-pairwise vs the 0.90 floor;
  `standing_scope` stays `house-authored-public-commons`.
- Witness-route measurements publish with failed standing when the
  floor is missed; low consistency withholds standing, per CM²
  doctrine.
- The measurement route samples k=3 (`llm_repeats: 3`).
