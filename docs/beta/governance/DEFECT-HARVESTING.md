# Design note: defect harvesting from witness runs

Date: 2026-07-04
Status: Design (Issue 6 of the post-loop stabilization wave; no code
implemented by this note)
Companion: [METER-LOOP-DECISION.md](METER-LOOP-DECISION.md) — the
binding record that stopped score optimization and dispatched this
design.

## Purpose

The witness route is unstable as a scalar optimizer but productive as
a defect finder: across the v3.2.3/v3.2.4 experiments it surfaced
real, citable defects — including defects in code its own maintainer
had just written (the duplicated barrier in P1, the multi-space error
strings in the v3.2.4 card surface). This note designs the harvest:
how a witness finding becomes a reviewed fix, how noise is rejected,
and how the harvest is measured **without** reintroducing
Coh-consistency as the objective.

## The defect record

One JSON object per harvested finding, accumulated in a queue file
(proposed home: `.tsc/meter/defect-queue.jsonl`; exact location is an
implementation decision):

```json
{
  "defect_id": "MFD-0007",
  "target": "spec",
  "primary_axis": "beta",
  "category": "broken-reference",
  "summary": "Glossary quick-reference cites epsilon default 10^-5 to Core §5; Core only requires epsilon > 0",
  "evidence": "spec/tsc-glossary.md:1019 vs spec/tsc-core.md §1/§5",
  "source_runs": [
    { "run": 28697625576, "samples": ["spec.r1"] },
    { "run": 28703325203, "samples": ["spec.r1", "spec.r2", "spec.r4", "spec.r5"] }
  ],
  "witness_frequency": "5/10 samples across 2 runs",
  "triage_status": "fixed",
  "triage_note": "verified against both files; citation was wrong",
  "resolution_pr": 70,
  "false_positive_reason": null
}
```

Field semantics:

- `defect_id` — stable `MFD-` (meter-found defect) identifier.
- `target` / `primary_axis` / `category` — the witness's filing,
  normalized by the maintainer at triage (the meter loop showed
  witnesses disagree on axis; the QUEUE stores the triaged filing and
  may note the witness split in `triage_note`).
- `evidence` — file:line or section citation. **A finding with no
  citation is not enqueueable.**
- `source_runs` / `witness_frequency` — where and how often
  independent samples surfaced it. Job logs carry per-sample
  observability JSON lines, so frequency is computable from CI logs
  alone.
- `triage_status` — `queued | confirmed | fixed | rejected |
  duplicate | out-of-scope`.
- `resolution_pr` — set when fixed; `false_positive_reason` — set
  when rejected.

## Evidence thresholds (enqueue rules)

A finding is enqueued when EITHER:

- **Repetition:** found by ≥ 2 independent samples (any runs), same
  defect under clustering (same cited surface + same claim, however
  filed); or
- **Citation + confirmation:** found by 1 sample with a direct
  file:line citation that the maintainer verifies against the tree
  before enqueueing.

Everything else (uncited impressions, "could not verify" hedges,
bundle-scope observations) is not a defect record; at most it feeds
target-manifest or instruction work through the normal issue process.

## Triage → CDD issue

- `queued → confirmed`: maintainer reproduces the defect against the
  current tree (the tree may have moved since the run).
- `confirmed` findings are batched into a CDD hygiene issue per the
  issue skill (incoherence, impact, source of truth, ACs, non-goals),
  normally one issue per wave, one commit per defect cluster, each
  fix citing its `defect_id` and evidence — the shape used by the
  post-loop hygiene wave.
- `rejected` requires `false_positive_reason` — the queue is also the
  meter's precision record.
- `duplicate` links the prior `defect_id`; duplicates are COUNTED
  (see metrics) because rediscovery of an unfixed defect is signal
  and rediscovery of a fixed one is a regression alarm.

## Worked example (from the v3.2.4 close-out set)

The ε-miscitation defect above is real and was fixed by the post-loop
hygiene wave (commit "Hygiene C-spec", this branch): found by spec
witnesses in both the baseline run (28697625576) and the experiment
run (28703325203), 5 samples total, always filed β, always citing the
glossary quick-reference row. It passes the repetition threshold
five times over; triage verified the citation against
`spec/tsc-core.md` §1/§5 (which declare only ε > 0) and the fix
corrected the glossary row's value source to the engine default.

A rejection example from the same set: a repo witness reported the
provenance schema fixture "pinned to v3.2.0 while the protocol
advanced to v3.2.4" — rejected with
`false_positive_reason: "report-shape version and witness-protocol
version are distinct lineages; the report shape IS still v3.2.0
(report.ml doc comment names the distinction)"`.

## Rejection path for noise

- No citation → never enqueued.
- Cited but not reproducible against the run's own tree → `rejected`
  with reason.
- Cited, reproducible, but a misreading (like the schema-version
  example) → `rejected` with the explaining reason; if the same
  misreading recurs across runs, that RECURRENCE is a documentation
  defect candidate (the surface invites the misreading) — enqueue
  THAT with the recurrence as evidence.

## Metrics (deliberately not Coh-consistency)

| Metric | Definition |
|--------|------------|
| Validated defect yield | confirmed + fixed records per witness run |
| False-positive rate | rejected / (all triaged), post-human-triage |
| Duplicate rediscovery rate | duplicates of UNFIXED defects per run (backlog pressure) |
| Regression rediscovery | duplicates of FIXED defects per run (should be zero; any hit is an alarm) |
| Time-to-fix | run date → resolution PR merge date per record |

These are the meter's operating numbers going forward. The
consistency statistic continues to be REPORTED (standing gate,
unchanged) but is not a target and not a success criterion for any of
this.

## Later: external calibration hook

Cross-route witnesses (a second provider or a human auditor scoring
the same bundle) plug into the same queue: their findings get the
same records with a `route` annotation on `source_runs`, and
precision can then be compared ACROSS routes — the first rung of the
diversity ladder named in the 0.10.4 ledger row that same-route
sampling cannot climb.

## Non-goals

- No automatic PR generation from witness findings — triage is human.
- No scoring, protocol, or standing change.
- No new workflow surfaces in this note; implementation (queue file,
  any tooling) is its own dispatched issue.
