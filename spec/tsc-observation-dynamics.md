# TSC Observation Dynamics v1.0.13
Formal Specification of Observer Construction, Verification, Epistemic Refinement, and Calibration-Grounded, Entry-Witnessed Comparison

Version: v1.0.13
Status: Proposed Extension Specification
Status consequence: verdict-bearing measurement (Core §5, Operational §5) does not depend on this extension; engines MAY implement its witnesses (the canonical engine emits the W2 gauge witness in provenance). Promotion to Normative follows the spec-release process (`CHANGELOG.md` § Spec releases).
Artifact: Specification
Changelog: `CHANGELOG.md` § Spec releases

Normative dependencies:
    C≡ v3.1.0
    TSC Core v3.2.0
    TSC Operational v3.2.1

Compatibility note for v3.2.0 dependency uplift:
    TSC Core v3.2.0 introduces the Barrier-Coherence Link
    (delta -> phi(delta) -> D -> Coh = exp(-D)) and splits the
    aggregate into C_Sigma^math (strict degeneracy) and
    C_Sigma^num (numerical, ε-floored). Observation Dynamics is
    forward-compatible: the typed transformation chain it requires
    (calibration bases, grounding witness, no ungrounded inflation)
    now has the barrier link as its typed discrepancy → energy step.
    Implementations MUST carry the v3.2.0 provenance fields
    (per-pair delta and D, phi specification, eta_phi clip,
    L_link constants, aggregate_math/aggregate_numeric, gauge
    witness ref+spread) through the observation ledgers.

Recommended repository path:
    spec/tsc-observation-dynamics.md

Patch discipline:
    This version inherits v1.0.12 in full,
    except where sections below explicitly replace or extend it.

## 0. Identity

TSC Observation Dynamics v1.0.13 is the calibration-grounded,
entry-witnessed observation-layer specification of TSC.

It preserves:
    replay-pure verification,
    proof-carrying ledgers,
    uncertainty-aware comparison,
    dependence-aware delta certification,
    lineage-certified and coverage-closed intervals,
    error-budget-ledgered and composition-certified comparison.

It adds:
    typed calibration bases for inflation magnitudes,
    empirical grounding records for budget entries,
    a grounding witness for budget ledgers,
    and a ban on ungrounded inflation in relation derivation.

## 1a. Correspondence to the core triad

This extension's vocabulary refines the core pattern language rather
than replacing it. Read: a **CalibrationBasis** types the *evidence
class* behind an inflation magnitude — an α-side discipline (the
pattern of a budget entry is only as stable as its evidence class); a
**GroundingRecord** binds a budget entry to cited evidence — a β-side
obligation (the entry and its justification must describe one
measurement); the **GroundingCertificate** over a ledger is a γ-side
witness (the budget survives change only if every entry's grounding
does). The v1.0.12 base this file extends is superseded in place by
this version — its inherited definitions are restated here wherever
they are load-bearing, and `CHANGELOG.md` § Spec releases carries the
lineage.

## 2. Change Log
### From v1.0.12

    CAL-01  CalibrationBasis introduced.
            Inflation magnitudes are now typed by their epistemic origin
            rather than accepted as bare assertions.

    CAL-02  GroundingRecord introduced.
            Every budget entry used in relation derivation must carry
            a grounding record linking inflation magnitude to evidence.

    CAL-03  ErrorBudgetEntry extended with calibration_basis
            and grounding_record fields.

    CAL-04  GroundingCertificate introduced.
            A budget ledger is grounded iff every entry carries a valid
            grounding record and a certificate attests this.

    CAL-05  BudgetGroundingWitness introduced.
            Budget grounding is now a witnessable property, not an
            unchecked self-declaration.

    CMP-08  ComparisonAtoms extended with:
                BUDGET_GROUNDED

    LDG-01  ErrorBudgetLedger extended with grounding_certificate_digest.

    EVD-09  No ungrounded inflation.
            An interval used for score_relation derivation must expose
            the calibration basis and grounding record of every budget
            entry that produced it.

    EXP-05  ComparisonExplanation gains grounding_quality.

    PRV-07  Comparison provenance minimum extended with:
                calibration bases
                grounding records
                grounding certificate digests
                dominant grounding quality

    C32-C36 Compare invariants added:
            budget grounding availability,
            calibration basis completeness,
            grounding record non-emptiness for non-zero inflations,
            grounding quality monotonicity under composition,
            and no fabricated inflation.

## 13. Calibration-Grounded Comparison Safety [E/N]

All Definitions 13.1–13.40 from v1.0.12 remain in force
except where explicitly extended below.

### Definition 13.41 (CalibrationBasis) [E]

    CalibrationBasis := {
        EMPIRICAL_MEASUREMENT,
        ANALYTIC_BOUND,
        CONSERVATIVE_DEFAULT,
        PRIOR_CALIBRATION_REF,
        DECLARED_WITHOUT_EVIDENCE
    }

Interpretation:

    EMPIRICAL_MEASUREMENT
        inflation magnitude was determined by direct measurement,
        e.g. repeated trials, held-out calibration sets, or
        empirical error characterization of a normalizer.

    ANALYTIC_BOUND
        inflation magnitude was derived from a proven mathematical bound,
        e.g. Hoeffding inequality, propagation-of-error formula,
        or machine-epsilon arithmetic.

    CONSERVATIVE_DEFAULT
        inflation magnitude is a conservative conventional value
        adopted by policy when direct evidence is unavailable.
        The policy reference must be recorded.

    PRIOR_CALIBRATION_REF
        inflation magnitude is inherited from a prior calibration
        campaign whose results are referenced by digest.

    DECLARED_WITHOUT_EVIDENCE
        inflation magnitude was declared without any of the above.
        This is legal but carries the lowest grounding quality.

### Definition 13.42 (GroundingQuality) [E]

    GroundingQuality := {
        FULL,
        BOUNDED,
        CONVENTIONAL,
        INHERITED,
        UNGROUNDED
    }

with the total order:

    FULL > BOUNDED > CONVENTIONAL > INHERITED > UNGROUNDED

Mapping from CalibrationBasis:

    EMPIRICAL_MEASUREMENT    -> FULL
    ANALYTIC_BOUND           -> BOUNDED
    CONSERVATIVE_DEFAULT     -> CONVENTIONAL
    PRIOR_CALIBRATION_REF    -> INHERITED
    DECLARED_WITHOUT_EVIDENCE -> UNGROUNDED

### Definition 13.43 (GroundingRecord) [E]

A grounding record is

    G := {
        calibration_basis,
        grounding_quality,
        evidence_digest?,
        method_description?,
        calibration_date?,
        validity_scope?,
        staleness_bound?
    }

with:

    calibration_basis ∈ CalibrationBasis
    grounding_quality = quality_map(calibration_basis)

Normative rules:

    if calibration_basis = EMPIRICAL_MEASUREMENT,
    then evidence_digest MUST be non-empty.

    if calibration_basis = ANALYTIC_BOUND,
    then method_description MUST be non-empty.

    if calibration_basis = CONSERVATIVE_DEFAULT,
    then method_description MUST reference the policy source.

    if calibration_basis = PRIOR_CALIBRATION_REF,
    then evidence_digest MUST reference the prior calibration artifact.

    if calibration_basis = DECLARED_WITHOUT_EVIDENCE,
    then no evidence fields are required,
    but grounding_quality = UNGROUNDED.

### Definition 13.44 (ErrorBudgetEntry — extended) [E]

An error-budget entry is extended to

    B_e := {
        source_kind,
        lower_inflation,
        upper_inflation,
        declared_by,
        calibration_basis,
        grounding_record,
        evidence_ref?,
        note?
    }

with:

    source_kind         ∈ ErrorSourceKind
    lower_inflation     >= 0
    upper_inflation     >= 0
    calibration_basis   ∈ CalibrationBasis
    grounding_record    is a valid GroundingRecord

Normative rule:
    if lower_inflation > 0 or upper_inflation > 0,
    then grounding_record MUST be present and non-trivial
    (i.e. calibration_basis must be declared).

### Definition 13.45 (GroundingCertificate) [E]

A grounding certificate is

    G_cert := {
        ledger_digest,
        entry_count,
        minimum_grounding_quality,
        ungrounded_entry_count,
        ungrounded_inflation_total,
        certificate_digest
    }

where:

    minimum_grounding_quality =
        min over all entries of entry.grounding_record.grounding_quality

    ungrounded_entry_count =
        count of entries where grounding_quality = UNGROUNDED

    ungrounded_inflation_total = (
        Σ lower_inflation over ungrounded entries,
        Σ upper_inflation over ungrounded entries
    )

Interpretation:
    G_cert summarizes the epistemic quality of a budget ledger
    so that comparison consumers can assess how much of the
    interval inflation rests on evidence vs assertion.

### Definition 13.46 (BudgetGroundingWitness) [E]

The budget grounding witness for a ledger B_err is

    w_ground(B_err) :=
        minimum_grounding_quality(G_cert(B_err))

Witness threshold:
    a runtime MAY define a minimum acceptable grounding quality
    τ_ground ∈ GroundingQuality.

    Default: τ_ground = CONVENTIONAL

    w_ground passes iff
        minimum_grounding_quality >= τ_ground

### Definition 13.47 (ErrorBudgetLedger — extended) [E]

An error-budget ledger is extended to

    B_err := {
        composition_rule,
        entries,
        total_lower_inflation,
        total_upper_inflation,
        ledger_digest,
        grounding_certificate_digest
    }

Normative rule:
    every ledger used in score_relation derivation MUST reference
    a valid GroundingCertificate.

### Definition 13.48 (ComparisonAtoms — extended) [E]

ComparisonAtoms from v1.0.12 are extended by:

    BUDGET_GROUNDED

Thus the comparison atom set becomes:

    ComparisonAtoms := {
        SAME_BATCH,
        SCORES_AVAILABLE,
        INTERVALS_AVAILABLE,
        INTERVAL_REGIME_COMPAT,
        INTERVAL_LINEAGE_AVAILABLE,
        BUDGET_LEDGER_AVAILABLE,
        COVERAGE_CERTIFIED,
        BUDGET_GROUNDED,
        EVIDENCE_CLOSED,
        PROFILE_EQ,
        REFERENCE_EQ,
        POLICY_EQ,
        RNG_COMPAT,
        NORMALIZER_VALID,
        DELTA_REGIME_VALID,
        DELTA_LINEAGE_VALID
    }

### Definition 13.49 (Atomic Comparison Checks — extensions) [E]

BUDGET_GROUNDED = PASS iff:
    left effective interval,
    right effective interval,
    and certified delta interval
    each reference an ErrorBudgetLedger whose GroundingCertificate
    satisfies:
        minimum_grounding_quality >= τ_ground

### Definition 13.50 (Required Pass Sets by Mode — extension) [E]

Req(mode) from v1.0.12 is extended by:

    BUDGET_GROUNDED

Normative rule:
    a pair is comparable only if this additional atom passes
    alongside all previously required atoms.

### Definition 13.51 (ComparisonExplanation — extended) [E]

comparison_explanation is extended with:

    grounding_quality ∈ {
        FULL,
        BOUNDED,
        CONVENTIONAL,
        INHERITED,
        UNGROUNDED,
        MIXED
    }

Interpretation:
    grounding_quality reports the worst-case epistemic quality
    across all budget ledgers used in the comparison.
    MIXED indicates that ledgers have different minimum qualities.

### Definition 13.52 (Comparison Metrics — extended) [E]

comparison_metrics is extended to include grounding summaries:

    comparison_metrics := {
        ...all fields from v1.0.12...,
        left_grounding_quality,
        right_grounding_quality,
        delta_grounding_quality
    }

where each is the minimum_grounding_quality from the
corresponding ledger's grounding certificate.

## 14. Canonical Abstract Operations [E]

### Operation OD-5 — replacement

    compare(B_left, B_right, mode, N_cmp?, T_cmp?, dependence_mode?) -> CompareResponse

Semantics:
    compare is comparison-safe, uncertainty-aware, dependence-aware,
    lineage-certified, budget-ledgered, and calibration-grounded.

It MUST:

    1. compute comparability_ledger
    2. construct source intervals
    3. construct grounded error-budget ledgers for left, right, and delta intervals
    4. construct coverage-certified effective intervals
    5. construct a certified delta interval with replayable lineage
    6. evaluate budget grounding witness
    7. emit score_relation
    8. emit reason_codes whenever relation is INCOMPARABLE
       or UNRESOLVED_WITHIN_UNCERTAINTY

It MUST NOT:

    1. use any interval for relation derivation unless it is coverage-certified
    2. collapse multiple declared error sources into an opaque scalar
       without a replayable budget ledger
    3. claim direct paired or coupled tightening without corresponding lineage
    4. leave declared comparison-layer error bounds unabsorbed
    5. use inflation magnitudes in relation derivation without
       recording their calibration basis and grounding record

## 16. Canonical Compare Contract [E]

### Definition 16.2 (CompareResponse — replacement) [E]

    CompareResponse := {
        header,
        left_ref,
        right_ref,
        mode,
        dependence_mode,
        normalizer?,
        comparability_ledger,
        comparison_metrics?,
        error_budget_ledgers?,
        grounding_certificates?,
        coverage_certificates?,
        interval_lineages?,
        score_relation,
        comparison_explanation?,
        reason_codes,
        provenance?
    }

### Definition 16.8 (Grounding Certificate Bundle) [E]

    grounding_certificates := {
        left_grounding_certificate,
        right_grounding_certificate,
        delta_grounding_certificate
    }

Normative rule:
    if score_relation != INCOMPARABLE,
    then grounding_certificates MUST be present.

### Definition 16.9 (Comparison Reason Codes — extension) [E]

Comparison reason codes from v1.0.12 are extended by:

    BUDGET_NOT_GROUNDED
    CALIBRATION_STALE
    GROUNDING_EVIDENCE_MISSING

Thus the reason-code family includes at least:

    ...all codes from v1.0.12...,
    BUDGET_NOT_GROUNDED,
    CALIBRATION_STALE,
    GROUNDING_EVIDENCE_MISSING

### Definition 16.10 (Comparison Evidence Closure — extension) [E]

Examples:

    BUDGET_NOT_GROUNDED
        -> BUDGET_GROUNDED.status = FAIL

    CALIBRATION_STALE
        -> a grounding record references a prior calibration
           whose staleness_bound has been exceeded

    GROUNDING_EVIDENCE_MISSING
        -> a non-zero inflation entry has
           calibration_basis != DECLARED_WITHOUT_EVIDENCE
           but evidence_digest is empty

## 18. Compare Invariants [E/N]

All Compare Invariants C0–C31 from v1.0.12 remain in force.

The following are added:

Invariant C32:
    if comparability_ledger.BUDGET_GROUNDED.status = FAIL,
    then score_relation = INCOMPARABLE

Invariant C33:
    every ErrorBudgetEntry with lower_inflation > 0 or upper_inflation > 0
    MUST have a non-trivial grounding_record
    (calibration_basis != absent).

Invariant C34:
    if calibration_basis = EMPIRICAL_MEASUREMENT,
    then grounding_record.evidence_digest MUST be non-empty.

    if calibration_basis = ANALYTIC_BOUND,
    then grounding_record.method_description MUST be non-empty.

Invariant C35:
    the minimum_grounding_quality of a composed ledger
    MUST be <= the minimum of the minimum_grounding_qualities
    of its constituent entries.

    (grounding quality cannot improve under composition)

Invariant C36:
    if any ErrorBudgetEntry contributing to a coverage-certified interval
    has grounding_quality = UNGROUNDED
    and lower_inflation + upper_inflation > 0,
    then comparison_explanation.grounding_quality
    MUST NOT be FULL or BOUNDED.

## 19. Provenance Minimum [E/N]

Every CompareResponse provenance bundle from v1.0.12 is extended.

In addition to all previously required fields, provenance MUST record:

    calibration_basis per budget entry
    grounding_quality per budget entry
    grounding_certificate_digest per ledger
    minimum_grounding_quality across all ledgers used

If any entry has calibration_basis = PRIOR_CALIBRATION_REF:
    the referenced calibration artifact digest MUST be recorded.

If any entry has staleness_bound declared:
    the comparison timestamp and staleness status MUST be recorded.

If grounding_quality = UNGROUNDED for any entry:
    the ungrounded_inflation_total MUST be recorded
    so consumers can assess how much interval width rests on assertion.

## 22. Final Position

TSC Observation Dynamics v1.0.13 is the calibration-grounded,
entry-witnessed observation-layer specification of TSC.

Its decisive moves are:

    per-source decomposition is no longer enough without per-entry grounding,
    inflation magnitudes must now declare their epistemic origin,
    budget composition cannot improve grounding quality,
    ungrounded inflation is visible rather than hidden in replay,
    and no runtime may claim certified comparison while resting on
    unexamined inflation assertions.

That is stricter than v1.0.12.
That is more honest about where the numbers come from.
That is safer for runtimes, SDKs, and AI readers.

This closes the comparison-layer certification arc:

    intervals exist (v1.0.9)
    → intervals are dependence-aware (v1.0.10)
    → intervals have certified ancestry (v1.0.11)
    → interval inflation is per-source decomposed (v1.0.12)
    → inflation magnitudes are empirically grounded (v1.0.13)

The chain from raw CI to certified relation is now:
    computed → composed → certified → decomposed → grounded.

The next genuine concerns — meta-comparison, comparison-informed refinement,
observer federation — belong at a different architectural level.
They do not belong in a v1.0.14 patch.

That is the convergence point of this arc.
