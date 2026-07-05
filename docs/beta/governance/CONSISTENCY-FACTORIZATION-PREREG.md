# Pre-registration: consistency by task factorization (the freedom seam)

Date: 2026-07-05
Status: PRE-REGISTRATION — awaiting operator review of the gate.
No code, instrument, or engine change is authorized by this note.
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
any implementation. This note supplies (2) and (3). It is held for
operator review before any implementation begins — implementation is
NOT authorized by drafting this note.

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

The witness task has four independent degrees of freedom:

1. **Coverage** — what the LLM chooses to read in a multi-thousand-line
   bundle (unconstrained, non-exhaustive).
2. **Counting** — how many distinct defects an observation counts as
   (unbounded scale).
3. **Aggregation** — the mapping from findings to the α/β/γ scalar,
   performed inside the model.
4. **Reporting** — the format a finding is filed in (checklist, cards,
   severities).

v3.2.3 and v3.2.4 both moved **knob 4**. The measured result and the
witness's own post-mortem locate the residual variance elsewhere:

- v3.2.3 (FALSIFIED, +0.0128): "the variance is in DISCOVERY, not
  reporting — the three witnesses found DIFFERENT defects in the same
  bundle." → **coverage** (knob 1).
- v3.2.4 (FAILED, counter 2/2): "one repo witness returned checklist
  counts an order of magnitude beyond its peers." → **counting**
  (knob 2). The k=5 pass added: witnesses "converge on a shared defect
  core (60–100%) but FILE the same defects under different axes" →
  residual **aggregation/axis-assignment** (knob 3).

Knobs 1–3 have never been constrained. Both experiments left the LLM
emitting the continuous `s_alpha / s_beta / s_gamma` scalars
(SELF-MEASURE §3.2–3.3) after a self-directed, non-exhaustive read.
Reporting structure cannot touch coverage, counting, or aggregation.
**The un-falsified variance source is the LLM's freedom over coverage,
counting, and aggregation — i.e. the task factorization itself.**

## Design: the mechanical/semantic seam

The consistency-vs-freedom trade is not a scalar dial (fully mechanical
= 100% consistent but LLM-free; fully free = discriminating but noisy).
It is a **factorization seam**. Cut the task so the LLM's only remaining
freedom is local semantic judgment — the one thing mechanical scoring
cannot do — and make coverage, counting, and aggregation deterministic:

1. **Engine enumerates the loci** (kills coverage freedom). Every
   witness adjudicates the SAME fixed site set. The engine already
   extracts these deterministically in `mechanical_scoring.ml`:
   `extract_md_links` + anchor resolution (every cross-reference and
   whether it resolves), `extract_versions` (γ markers),
   `extract_headings` / `doc_slug_map` (α boundaries), and it already
   scores `cross_reference_consistency` and `terminology_consistency`.
2. **LLM adjudicates each locus** with a bounded, local,
   evidence-anchored question — e.g. "this reference resolves
   syntactically; does the cited target actually bear out the claim the
   citing text makes about it? yes / no / cite." The answer space is
   small, so independent readers agree.
3. **Engine counts and aggregates** the per-locus judgments into α/β/γ
   (kills counting and aggregation freedom). The LLM never emits a
   scalar.

This makes `hybrid` mode actually FUSE its two arms (LLM judges the
mechanically-found sites) rather than run them blind and report both
sub-objects side by side, which is the current behaviour.

## Scope of the first experiment: β only

β (relational coherence) is where mechanical locus-extraction is
strongest and already built: references, anchors, repeated facts,
authority claims are all syntactically anchored sites the engine can
enumerate exhaustively. α (naming / conceptual drift) may be
irreducibly holistic — no syntactic site to point at — and γ is
intermediate. Attempting all three at once would confound attribution.

**The first experiment factorizes β only.** α and γ keep their current
holistic scalar. This is the cleanest possible falsification of the
seam theory: if forcing coverage + counting + aggregation to be
deterministic does not raise β consistency, the theory is wrong and no
broader version is worth running.

Likely partial outcome, pre-declared so it is not moved post hoc: β
snaps toward the floor; α stays noisy; γ untested here. A per-axis
result is the point — it tells us which axes admit a low-freedom
decomposition and which do not, which is itself a thesis-relevant
finding.

## Pre-registered gate

Measured on CI over the held-out target set (targets NOT in the tuning
set — the five-target registry split is fixed before the run and
recorded in the dispatch), k=3, against a baseline measured on the
SAME tree immediately before the instrument change.

The gate is **two-sided**: consistency alone is trivially maximized by
degenerating toward mechanical mode. Both sides must pass.

### Side A — consistency (the objective)

- **A1.** Per-axis β k=3 `Coh_consistency` (barrier over the β field's
  spread, `Witness_numeric.per_field_spread`) ≥ **0.90** (the standing
  floor, never yet reached) on every held-out target.
- **A2.** AND ≥ baseline β consistency **+0.10** absolute (the v3.2.3
  effect-size convention), so a near-floor baseline cannot pass on
  noise.

Baseline β consistency `B_β` is MEASURED and recorded before any
change; A2 is evaluated against that recorded value, not a guessed one.

### Side B — discrimination retained (the guard)

The constrained meter must still separate coherent from incoherent —
it must not buy consistency by going blind. Reuses the held-out
attacker suite and katas built in the last wave; no new infrastructure.

- **B1.** kata-01 (glider, positive control) still PASSES and kata-02
  (random soup, negative control) still FAILS — verdicts unchanged.
- **B2.** All five held-out attackers still separated: each attacker's
  β (or C_Σ where β is not the attacked axis) stays below the honest
  targets by at least its current margin, within a 0.02 tolerance.
- **B3.** On held-out real targets, the factorized β stays within
  **0.10** of the current free-witness β central tendency (medoid of
  k=3). This proves the new β still tracks the semantic signal rather
  than a mechanical proxy dressed up as a judgment.

### Falsification line

The experiment FAILS if ANY of A1, A2, B1, B2, B3 is missed on any
held-out target. A failure is recorded (predictions, baseline, measured
numbers, interpretation) in this note and the CHANGELOG witness index,
exactly as v3.2.3/v3.2.4 were. On failure, no protocol promotion, no
standing change; the factorization code, if written, is retained only
as contract hardening with no consistency claim, or reverted.

This experiment does NOT reset the meter-loop counter in
METER-LOOP-DECISION.md — that record governs the *filing-structure*
line, which stays closed. This is a distinct line with its own single
pre-registered gate; it does not open an iterate-until-it-passes loop.
A miss here is terminal for the factorization claim absent a further
operator dispatch.

## What is explicitly NOT claimed by this note

- No claim that α is decomposable; the first experiment does not touch
  α's scalar.
- No standing-gate change: `standing_scope` stays
  `house-authored-public-commons`; the standing statistic stays
  max-pairwise vs the 0.90 floor.
- No change to k (stays 3), the spread statistic, or the adjudication
  rule as a consistency lever — the change is the *task factorization*,
  and the gate measures that alone.

## Open items for operator review

1. The held-out / tuning target split (which of the five targets are
   held out for B2/B3 vs used while building the locus adjudication).
2. Whether B3's tolerance (0.10) is the right band, or tighter.
3. Whether to gate γ in the same experiment or hold it for a second
   pre-registration once β is settled.
