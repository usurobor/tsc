<!--
  CM0 — the 0th coherence methodology, authored in its own grammar.
  CANONICAL. This document is the source of truth for the CM0 methodology.
  The prose skill at skills/cm-of-cms/SKILL.md is the DEPLOYED essence
  (frontmatter contract + operator narrative) and points here as canonical
  for the α-Parts / β-Fit / γ-Evolve structure; the two must not contradict.

  Grammar: three H1 sections — `# α — Parts`, `# β — Fit`, `# γ — Evolve`.
  Each H2 is a MEASURABLE clause with an inline typed block
  (id, axis, evidence, mechanical_checks, semantic_checks, failure_modes,
  actions), typed by schemas/cm.cue #CMDocument. The machine-extraction of
  these blocks lives at schemas/fixtures/cm/valid/cm0.yaml and is what CI
  runs `cue vet` over; it must stay faithful to the blocks below.

  document_version: 0.2.0   (0.1.0 = the pre-migration α-as-consistency
  decomposition carried by SKILL.md §1; 0.2.0 = this migrated
  α-Parts / β-Fit / γ-Evolve / Consistency-standing decomposition — see
  ## Migration Rules. The bump IS the migration event.)
-->

# CM0 — the methodology of methodologies

TSC measures whether three descriptions of a system still describe one
system. A coherence methodology (CM) is itself such a system, so a CM is
measurable by the same triadic instrument — and CM0 is the pristine
reference CM: it defines how CMs are written, checked, reported, and
admitted, and it is measurable by its own grammar.

**A CM may express human values, but it must _compile_ before it may
_measure_:** its parts must exist (α), its parts must fit (β), its
evolution rules must be honest (γ), and its self-agreement must be
measured on a separate standing axis (Consistency). This document is CM0
authored in exactly that grammar, as the exemplar every candidate CM is
typechecked against (`schemas/cm.cue`).

**Self-pass is hygiene, not authority.** CM0 checks CMs including itself;
a clean self-check qualifies a CM to compete and wins nothing. Standing
still comes from external anchors, rival CMs, and outcome correlation
(carried verbatim from `skills/cm-of-cms/SKILL.md` §5/§6).

**The four axes.** The migrated decomposition is **α Parts / β Fit /
γ Evolve / Consistency (standing)**. The document is authored under three
H1s because Consistency is a *standing* axis — it is measured over
repeated runs, not authored as a section. The α `Consistency` organ below
is the *part* that declares the protocol; the `consistency-standing`
β-relation links it to the standing axis. See `## Migration Rules` for how
this decomposition supersedes the old α = *instrument self-agreement*.

---

# α — Parts

The organs a coherence methodology must **have**. Each clause is a
required part; a document missing one fails `cue vet` against
`#CMDocument` (that is the negative oracle).

## Purpose

```yaml
id: purpose
axis: alpha
evidence: the document's opening statement of what it measures and the
  compile-before-measure invariant it enforces
mechanical_checks:
  - "a Purpose organ is present under `# α — Parts`"
semantic_checks:
  - "the stated purpose is a measurement claim (what is measured, on what
     corpus), not a mission statement"
failure_modes:
  - "purpose is a value statement with no measurable referent"
  - "purpose claims a measurement the rest of the document does not perform"
actions:
  - "reject as non-measurable; require a corpus-and-axis purpose"
```

## Scope

```yaml
id: scope
axis: alpha
evidence: the declared corpus (which artifacts of a target CM are
  measured) and the standing scope the readings can reach
mechanical_checks:
  - "a Scope organ is present"
  - "declared corpus paths resolve inside the measured bundle"
semantic_checks:
  - "scope matches purpose — the corpus is what the purpose claims to read"
failure_modes:
  - "scope overreaches: claims standing beyond its anchor base"
  - "scope references artifacts outside the measured bundle"
actions:
  - "clamp standing_scope to the declared anchor base"
  - "mark out-of-bundle references as source-drift risk"
```

## Axes

```yaml
id: axes
axis: alpha
evidence: the axis set the methodology decomposes coherence into, with a
  one-line meaning per axis
mechanical_checks:
  - "the three authored H1 axes (α Parts, β Fit, γ Evolve) are present"
  - "the Consistency standing axis is named"
semantic_checks:
  - "each axis is distinct — no axis is a rename of another without a
     migration entry"
failure_modes:
  - "an axis is silently redefined across versions (γ-migration violation)"
  - "two axes measure the same thing"
actions:
  - "require a `## Migration Rules` entry for any axis redefinition"
  - "reject a decomposition whose axes are not separable"
```

## Evidence

```yaml
id: evidence
axis: alpha
evidence: the mechanical signal inventory and the LLM estimate contract —
  what is inspected to produce each reading
mechanical_checks:
  - "declared mechanical signal codes exist in the declared engine backend"
  - "declared LLM estimate fields appear in the declared scoring instruction"
semantic_checks:
  - "every axis has at least one evidence source; no axis is scored from air"
failure_modes:
  - "a declared signal has no implementation (declaration↔implementation drift)"
  - "an axis is asserted with no cited evidence source"
actions:
  - "fail validation on any signal/estimate that does not resolve"
  - "mark an evidence-less axis unmeasurable"
```

## Preregs

```yaml
id: preregs
axis: alpha
evidence: the pre-registration objects the methodology admits — a proposed
  test frozen before implementation, with axis, gate, and post-result rule
mechanical_checks:
  - "each prereg names the axis it tests and a gate that is executable"
  - "each prereg declares its failure and no-decision consequences"
semantic_checks:
  - "the gate actually exercises the axis it claims (not a gameable proxy)"
failure_modes:
  - "a prereg's gate can pass without touching its declared axis"
  - "a prereg has no post-result rule (iterate-until-it-passes risk)"
actions:
  - "reject a prereg whose gate does not test its axis"
  - "require a terminal post-result rule (see CONSISTENCY-FACTORIZATION-PREREG.md)"
```

## Factorization

```yaml
id: factorization
axis: alpha
evidence: for every semantic score, who ENUMERATES the loci, who JUDGES
  each locus, and who AGGREGATES the verdicts
mechanical_checks:
  - "each semantic score declares an enumerate/judge/aggregate owner split"
semantic_checks:
  - "no single actor (the LLM) owns all three — that is unbounded freedom"
failure_modes:
  - "the LLM enumerates, judges, and aggregates in its head (scalar wobble)"
  - "aggregation is holistic, not a declared formula"
actions:
  - "reject or mark `draft` a CM whose LLM owns all three roles"
  - "require deterministic enumeration and aggregation around a bounded judge"
```

## Judgment

```yaml
id: judgment
axis: alpha
evidence: the bounded per-call schema the semantic witness answers in —
  a small label set plus mandatory evidence, never a free scalar
mechanical_checks:
  - "the witness output is a bounded label set (e.g. supports/contradicts/insufficient)"
  - "a negative verdict requires cited evidence from the object bundle"
semantic_checks:
  - "the labels are exhaustive and mutually exclusive for the predicate"
failure_modes:
  - "the witness emits a raw scalar (unbounded aggregation smuggled in)"
  - "a low verdict with no evidence (unfalsifiable)"
actions:
  - "refuse a sample whose output is not in the bounded contract"
  - "reject an evidence-less negative verdict"
```

## Aggregation

```yaml
id: aggregation
axis: alpha
evidence: the pre-registered, deterministic formula from per-locus
  verdicts to the axis scalar, and the barrier/geometric-mean rules
mechanical_checks:
  - "the verdict→scalar map is a declared formula computed by the engine"
  - "population aggregation is geometric (one credible zero annihilates)"
semantic_checks:
  - "the formula preserves the degeneracy axiom — friendly scores cannot
     buy off a fatal audit"
failure_modes:
  - "aggregation done inside the model (not reproducible)"
  - "arithmetic mean lets many high scores mask a zero"
actions:
  - "move aggregation into the engine, after witness validation"
  - "use the geometric mean for standing over auditors"
```

## Consistency

```yaml
id: consistency
axis: alpha
evidence: the protocol that tests the methodology against the same input
  repeatedly and measures the agreement of its outputs (the part that
  feeds the Consistency STANDING axis via the consistency-standing relation)
mechanical_checks:
  - "the mechanical arm is exactly reproducible: identical bundle → identical scores"
  - "the LLM arm samples k>=2 times against the frozen prompt"
semantic_checks:
  - "the repeat spread maps through the canonical barrier phi(d)=d/(1-d),
     Coh_consistency = exp(-phi)"
failure_modes:
  - "a 'deterministic' backend that drifts (hidden input)"
  - "wide LLM spread averaged away instead of reported"
actions:
  - "hard-fail the run on any mechanical divergence"
  - "publish Coh_consistency; below floor carries no off-diagonal standing"
```

## Discrimination

```yaml
id: discrimination
axis: alpha
evidence: the calibration commons the methodology reproduces — pass the
  positive control, fail the negative, rank the comparative pair, catch
  the adversarial trap
mechanical_checks:
  - "the scorer passes the positive kata and fails the negative kata"
  - "admissibility self-test rejects the flatterer and the path-gamer"
semantic_checks:
  - "the meter separates coherent from incoherent on unseen cases, not
     just memorized anchors"
failure_modes:
  - "a degenerate all-1.0 flatterer or all-0 assassin passes"
  - "a lookup-table gamer tuned to public ranges passes"
actions:
  - "confer no standing on a scorer that cannot read the commons"
  - "grow the commons when a gamed reading is demonstrated"
```

## Refusal

```yaml
id: refusal
axis: alpha
evidence: the single validation funnel that turns any malformed or
  prohibited witness output into a durable, named validation-failure
  artifact instead of a silent fallback
mechanical_checks:
  - "every refusal stage (parse, schema, prohibited-fields, mismatch) names itself"
  - "a refusal renders no coherence report and never falls back to mechanical scoring"
semantic_checks:
  - "refusal is distinguishable from semantic uncertainty (malformed ≠ insufficient)"
failure_modes:
  - "a malformed response silently scored or skipped"
  - "a prohibited field (computed Coh) accepted"
actions:
  - "refuse, don't skip: preserve the raw response, name the stage"
  - "reject prohibited computed fields at the funnel"
```

## Report

```yaml
id: report
axis: alpha
evidence: the operator-visible projection — verdict, per-axis breakdown,
  critical findings, and what a human must CLARIFY when witnesses disagree
mechanical_checks:
  - "the report carries a verdict and a per-axis (α/β/γ + consistency) breakdown"
  - "the report carries a standing_scope stating how far its standing reaches"
semantic_checks:
  - "witness disagreement is surfaced as a reported signal (ambiguous
     predicate → clarify), not hidden as scalar wobble"
failure_modes:
  - "the report states a number with no findings or actions"
  - "admissible-static and has-standing-measured collapsed into one column"
actions:
  - "route every finding to a recommended action (findings-actions relation)"
  - "keep admissible-vs-standing as separate columns"
```

---

# β — Fit

The relations the parts must satisfy — declaration ↔ implementation fit,
lifted to methodology organs. Each clause checks that two organs describe
one system.

## Purpose ↔ Axes

```yaml
id: purpose-axes
axis: beta
evidence: the Purpose organ and the Axes organ
mechanical_checks:
  - "every axis named in Axes is motivated by the stated Purpose"
semantic_checks:
  - "the purpose is fully covered by the axes — nothing claimed is unmeasured"
failure_modes:
  - "an axis exists that the purpose never asks for"
  - "the purpose claims a dimension no axis measures"
actions:
  - "drop or motivate an orphan axis"
  - "add an axis or narrow the purpose"
```

## Axes ↔ Evidence

```yaml
id: axes-evidence
axis: beta
evidence: the Axes organ and the Evidence organ
mechanical_checks:
  - "every axis has at least one declared evidence source"
semantic_checks:
  - "the evidence actually bears on the axis it is assigned to"
failure_modes:
  - "an axis with no evidence (scored from air)"
  - "evidence filed under the wrong axis"
actions:
  - "reject an evidence-less axis as unmeasurable"
  - "re-file mis-axed evidence"
```

## Evidence ↔ Factorization

```yaml
id: evidence-factorization
axis: beta
evidence: the Evidence organ and the Factorization organ
mechanical_checks:
  - "every semantic evidence source has a declared enumerate/judge/aggregate split"
semantic_checks:
  - "mechanical evidence is genuinely deterministic; only semantic evidence
     is routed to the bounded judge"
failure_modes:
  - "semantic evidence with no factorization (unbounded LLM freedom)"
  - "mechanical evidence needlessly sent to the LLM"
actions:
  - "require a factorization owner-split for each semantic source"
  - "keep deterministic evidence out of the witness task"
```

## Prereg ↔ Axis

```yaml
id: prereg-axis
axis: beta
evidence: the Preregs organ and the Axes organ
mechanical_checks:
  - "every prereg names an axis that exists in the Axes organ"
semantic_checks:
  - "the prereg's gate exercises the named axis, not an adjacent proxy"
failure_modes:
  - "a prereg tests an axis the methodology does not declare"
  - "a prereg's gate passes without touching its axis"
actions:
  - "reject a prereg whose axis is undeclared"
  - "reject a gate that does not test its axis"
```

## Prereg ↔ Success-Gate

```yaml
id: prereg-success-gate
axis: beta
evidence: the Preregs organ and its declared success / failure / no-decision gates
mechanical_checks:
  - "each prereg declares success, failure, AND no-decision consequences"
  - "each gate is evaluable by a command, fixture, or numeric comparison"
semantic_checks:
  - "the gate is stricter-to-game than to pass honestly"
failure_modes:
  - "a prereg with a success gate but no failure/no-decision rule"
  - "a gate item that cannot be evaluated mechanically"
actions:
  - "require terminal failure and no-decision rules"
  - "reject a non-evaluable gate item (per PREREG proof/rejection mechanism)"
```

## Judgment ↔ Aggregation

```yaml
id: judgment-aggregation
axis: beta
evidence: the Judgment organ's label set and the Aggregation organ's formula
mechanical_checks:
  - "every judgment label has a defined weight in the aggregation formula"
semantic_checks:
  - "the aggregation preserves the ordering the labels imply
     (supports < insufficient < contradicts in defect weight)"
failure_modes:
  - "a label with no weight (unhandled verdict)"
  - "aggregation that ignores a label's severity"
actions:
  - "map every label to a weight before execution"
  - "reject an aggregation that drops a label"
```

## Consistency ↔ Standing

```yaml
id: consistency-standing
axis: beta
evidence: the Consistency α-organ and the Standing-Discipline γ-clause —
  the seam where measured self-agreement becomes (or fails to become) standing
mechanical_checks:
  - "a report below the LLM consistency floor carries no off-diagonal standing"
  - "the mechanical arm gates hard; the LLM arm gates standing, not publishing"
semantic_checks:
  - "standing is off-diagonal (what other admissible CMs say), never a self-score"
failure_modes:
  - "a self-score promoted to standing"
  - "an unstable meter (low Coh_consistency) granted standing"
actions:
  - "strip standing from any reading below the consistency floor"
  - "route standing through admissible auditors only"
```

## Findings ↔ Actions

```yaml
id: findings-actions
axis: beta
evidence: the Report organ's critical findings and its recommended actions
mechanical_checks:
  - "every critical finding maps to at least one recommended action"
semantic_checks:
  - "the action, if taken, would resolve or contest the finding"
failure_modes:
  - "a finding with no action (dead-end diagnosis)"
  - "an action that does not address any finding"
actions:
  - "attach an action to every finding"
  - "drop or re-anchor an orphan action"
```

---

# γ — Evolve

How the methodology changes without lying about what its old readings
meant. These clauses are self-referential: CM0's own axis rename (v0.1.0 →
v0.2.0) is measured against them (`## Migration Rules`).

## Versioning

```yaml
id: versioning
axis: gamma
evidence: the CM document version (SemVer) and its distinction from the
  repo VERSION
mechanical_checks:
  - "the document declares a SemVer distinct from the repo VERSION"
  - "an axis or evidence change bumps the document version"
semantic_checks:
  - "the version increment matches the magnitude of the change
     (axis rename → minor-or-major, not a silent edit)"
failure_modes:
  - "an axis redefinition shipped without a version bump"
  - "document version conflated with repo version"
actions:
  - "bump the document version on any axis/evidence change"
  - "record the increment reason in the version note"
```

## Experiment / Failed-Memory

```yaml
id: experiment-failed-memory
axis: gamma
evidence: the record of terminal experiments (their predictions, baseline,
  measured numbers, verdict) preserved so a failed line is not silently re-run
mechanical_checks:
  - "each terminal experiment records verdict + measured numbers in a durable ledger"
  - "a FAILED/NO-DECISION line names its terminality and re-entry precondition"
semantic_checks:
  - "a new experiment names a variance source NOT already falsified"
failure_modes:
  - "a falsified line silently re-run (meter-loop reopen)"
  - "a failure recorded without its numbers (unauditable)"
actions:
  - "hold a re-run until operator dispatch + a non-falsified theory of variance"
  - "keep failed experiments as memory, not deletions (METER-LOOP-DECISION.md)"
```

## Migration

```yaml
id: migration
axis: gamma
evidence: the `## Migration Rules` ledger mapping old readings onto the
  new decomposition; self-referentially, CM0's α rename
mechanical_checks:
  - "a `## Migration Rules` entry exists for every axis redefinition"
  - "each entry states whether old readings remain interpretable"
semantic_checks:
  - "the old→new mapping is a total interpretation — no old reading is orphaned"
failure_modes:
  - "an axis renamed with no migration entry (silent redefinition)"
  - "old readings left with no defined new reading"
actions:
  - "reject an axis change lacking a migration entry"
  - "provide an interpretation for every old reading"
```

## Standing-Discipline

```yaml
id: standing-discipline
axis: gamma
evidence: the standing-scope declaration and its promotion rules — how far
  a reading's standing reaches and what mechanics (not prose) can extend it
mechanical_checks:
  - "every report carries a standing_scope"
  - "scope promotes only when mechanics change (registered challengers,
     revealed held-out anchors, external anchors), never by prose"
semantic_checks:
  - "a provisional-γ CM (no evolution history) is still an admissible
     candidate — provisional, not zero, not ignored"
failure_modes:
  - "standing promoted by prose"
  - "a new CM rejected for lacking evolution history"
actions:
  - "keep standing_scope at its anchor base until mechanics change"
  - "admit provisional-γ candidates; mark them provisional, do not reject"
```

## Change-Isolation

```yaml
id: change-isolation
axis: gamma
evidence: the boundary that keeps an instrument change from silently
  rewriting what old readings meant — canonical vs generated, DO-NOT-EDIT
  headers, traceability
mechanical_checks:
  - "generated state lives under .tsc/ and is never canonical"
  - "rendered surfaces carry a DO-NOT-EDIT header pointing at their source"
semantic_checks:
  - "an old reading is comparable across versions or explicitly marked incomparable"
failure_modes:
  - "an edit to generated state treated as canonical"
  - "a scoring change that silently rewrites old numbers"
actions:
  - "route edits to the canonical source, re-render the surface"
  - "mark cross-version readings incomparable when the instrument changed"
```

## Governance

```yaml
id: governance
axis: gamma
evidence: who may authorize a change — operator dispatch, review gates,
  and the separation of the merge boundary from implementation
mechanical_checks:
  - "instrument/experiment changes require a recorded operator dispatch"
  - "a pre-registered gate is reviewed before any implementation"
semantic_checks:
  - "the authorizer is distinct from the implementer (no self-authorization)"
failure_modes:
  - "an implementation authorized by drafting the note that proposes it"
  - "a merge performed by the cell that implemented it"
actions:
  - "hold implementation for operator review of the prereg"
  - "keep the merge boundary with the reviewing role (κ/δ/β)"
```

## Re-entry

```yaml
id: re-entry
axis: gamma
evidence: the conditions under which a stopped line may be re-entered —
  operator dispatch, a non-falsified theory of variance, a reviewed gate
mechanical_checks:
  - "re-entry requires ALL of: operator dispatch, non-falsified variance
     theory, pre-reviewed gate"
  - "a terminal line names its re-entry precondition explicitly"
semantic_checks:
  - "the re-entry does not contradict a prior falsification"
failure_modes:
  - "re-entry by re-tweak without fresh dispatch"
  - "re-entering a line whose variance source is already falsified"
actions:
  - "block re-entry absent all three conditions"
  - "record the re-entry decision against the stop rule"
```

---

## Migration Rules

The move from document **v0.1.0** (the α = *instrument self-agreement /
consistency* decomposition carried by `skills/cm-of-cms/SKILL.md` §1) to
**v0.2.0** (this α Parts / β Fit / γ Evolve / **Consistency standing**
decomposition) is an **axis rename on the self-referential 0th
methodology** — precisely the event the `migration` and
`standing-discipline` γ-clauses govern. It is recorded here as a versioned
migration; old readings remain interpretable.

| from (v0.1.0) | to (v0.2.0) | interpretable? | note |
|---|---|---|---|
| α = *instrument self-agreement / consistency* | **Consistency (standing axis)** + the α `consistency` organ | yes | The old α number was a self-agreement reading. It is re-read as a **Consistency standing** value; the *part* that produces it is now the α `Consistency` organ, linked to the standing axis by the `consistency-standing` β-relation. No old α reading is orphaned. |
| β = *declaration ↔ implementation fit* | **β — Fit** (organ-to-organ relations) | yes | Unchanged in meaning; generalized from declaration↔implementation to the eight organ relations. Old β readings map directly. |
| γ = *instrument evolution* | **γ — Evolve** (versioning, migration, standing, re-entry, …) | yes | Unchanged in meaning; expanded into seven named clauses. Old γ readings map directly. |
| (implicit) *the parts of a methodology* | **α — Parts** (twelve required organs) | n/a (new) | α is repurposed from "self-agreement" to "the organs a methodology must have." This is the ONE non-aligning axis; its old reading is preserved via the row above, not lost. |

**Self-check against the `migration` clause.** The mechanical checks
require (1) a `## Migration Rules` entry for every axis redefinition —
present: α, β, γ rows above; and (2) each entry states interpretability —
present: the `interpretable?` column. The semantic check requires a total
interpretation with no orphaned old reading — satisfied: the only
non-aligning change (α) has its old *consistency* reading re-homed on the
Consistency standing axis rather than dropped. **CM0 v0.2.0 passes its own
`migration` clause.** (This self-pass is hygiene, not authority — see the
header.)

**Self-check against the `versioning` clause.** An axis change bumped the
document version (0.1.0 → 0.2.0) and the reason is recorded in the header
and this section. **Passes.**

**Known residual (recorded, not papered over).** The α axis does *not*
align with the old decomposition (β and γ do). The migration keeps the old
α *reading* interpretable, but a consumer that indexed "α" by name across
versions will find α now means Parts, not consistency. This is inherent to
an axis rename and is exactly why the change is versioned and laddered
through the `migration` clause rather than shipped silently. The
`standing-discipline` clause is not violated: no standing was promoted by
this rename.

---

## Provenance and non-goals

- **Canonical source of truth:** this document (`docs/beta/governance/CM0.md`).
- **Deployed essence:** `skills/cm-of-cms/SKILL.md` — the frontmatter
  comparable contract (`#CMOfCMs`) and operator narrative; it points here
  as canonical for the α-Parts / β-Fit / γ-Evolve structure. The two must
  not contradict.
- **Typed by:** `schemas/cm.cue` `#CMDocument` (extends, does not
  supersede, `schemas/skill.cue #CoherenceMethodology`).
- **Non-goals (this document):** no `coh cm-compile` (Sub-3), no
  `schemas/prereg.cue` (Sub-2), no change to the scalar meter, no
  meter-consistency reopen, no v3.2.5. CM0 claims no authority from
  self-checking.
