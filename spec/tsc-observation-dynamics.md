# TSC Observation Dynamics v1.0.12
Formal Specification of Observer Construction, Verification, Epistemic Refinement, and Error-Budget-Ledgered, Composition-Certified Comparison

Version: v1.0.12
Status: Proposed Extension Specification
Artifact: Specification

Normative dependencies:
    C≡ v3.1.0
    TSC Core v3.1.0
    TSC Operational v3.1.0

Recommended repository path:
    spec/tsc-observation-dynamics.md

Patch discipline:
    This version inherits v1.0.11 in full,
    except where sections below explicitly replace or extend it.

## 0. Identity

TSC Observation Dynamics v1.0.12 is the error-budget-ledgered,
composition-certified observation-layer specification of TSC.

It preserves:
    replay-pure verification,
    proof-carrying ledgers,
    uncertainty-aware comparison,
    dependence-aware delta certification,
    lineage-certified and coverage-closed intervals.

It adds:
    explicit error-budget ledgers,
    coverage certificates with replayable composition,
    per-source inflation accounting,
    and a ban on opaque scalar error absorption.

## 2. Change Log
### From v1.0.11

    BGT-01  ErrorSourceKind introduced.
            Comparison uncertainty sources are now typed rather than collapsed
            into a single absorbed_error_budget scalar.

    BGT-02  ErrorBudgetEntry and ErrorBudgetLedger formalized.
            Every comparison interval now carries an auditable budget ledger.

    BGT-03  CompositionRule introduced.
            Coverage closure is now replayable under an explicit composition law.

    COV-02  CoverageCertificate introduced.
            A coverage-closed interval is now certified by a proof object,
            not just asserted in provenance.

    LIN-05  IntervalLineage extended.
            Lineage now points to both budget-ledger and coverage-certificate
            digests.

    CMP-07  ComparisonAtoms extended with:
                BUDGET_LEDGER_AVAILABLE
                COVERAGE_CERTIFIED

    EVD-08  No opaque closure.
            An interval used for score_relation derivation must expose the full
            per-source inflation ledger that produced it.

    EXP-04  ComparisonExplanation gains budget_driver.

    PRV-06  Comparison provenance minimum extended with:
                error_budget_ledgers
                coverage_certificates
                composition rules
                per-source inflations
                absorbed totals

    C25-C31 Compare invariants added:
            budget availability,
            coverage certification,
            additive conservative replay,
            mandatory accounting of declared error sources,
            and no hidden budget compression.

## 13. Error-Budget-Ledgered Comparison Safety [E/N]

All Definitions 13.1–13.25 from v1.0.11 remain in force
except where explicitly extended below.

### Definition 13.26 (ErrorSourceKind) [E]

    ErrorSourceKind := {
        STATISTICAL_CI,
        NORMALIZER_ERROR,
        COUPLING_PROPAGATION,
        NUMERIC_TOLERANCE,
        CALIBRATION_UNCERTAINTY,
        REFERENCE_DRIFT,
        OTHER_DECLARED
    }

Interpretation:
    these are comparison-layer uncertainty sources that may widen
    effective comparison intervals before relation derivation.

### Definition 13.27 (ErrorBudgetEntry) [E]

An error-budget entry is

    B_e := {
        source_kind,
        lower_inflation,
        upper_inflation,
        declared_by,
        evidence_ref?,
        note?
    }

with:

    source_kind      ∈ ErrorSourceKind
    lower_inflation  >= 0
    upper_inflation  >= 0

Interpretation:
    B_e records how much additional uncertainty from one declared source
    is conservatively absorbed on each side of an interval.

### Definition 13.28 (CompositionRule) [E]

    CompositionRule := {
        ADDITIVE_CONSERVATIVE
    }

Interpretation:
    v1.0.12 standardizes one composition law:
    conservative interval inflation by additive accumulation of
    lower and upper source-wise inflations.

### Definition 13.29 (ErrorBudgetLedger) [E]

An error-budget ledger is

    B_err := {
        composition_rule,
        entries,
        total_lower_inflation,
        total_upper_inflation,
        ledger_digest
    }

where:

    composition_rule ∈ CompositionRule
    entries          = finite list of ErrorBudgetEntry

For ADDITIVE_CONSERVATIVE:

    total_lower_inflation = Σ_{e ∈ entries} e.lower_inflation
    total_upper_inflation = Σ_{e ∈ entries} e.upper_inflation

Normative rule:
    if entries = ∅, then both totals MUST equal 0.

### Definition 13.30 (CoverageCertificate) [E]

A coverage certificate is

    C_cov := {
        parent_interval_ids,
        budget_ledger_digest,
        composition_rule,
        resulting_interval_id,
        certified_lo,
        certified_hi,
        certificate_digest
    }

Interpretation:
    C_cov certifies that a resulting interval was obtained by replayable
    inflation of its parent interval(s) under the referenced budget ledger
    and composition rule.

Normative rule:
    replay(C_cov) MUST reconstruct the certified interval bounds from
    the referenced parent interval(s) and budget ledger.

### Definition 13.31 (IntervalLineage — extended) [E]

Every interval lineage object is extended to

    L_I := {
        interval_id,
        interval_basis,
        interval_regime,
        parent_interval_ids?,
        resample_family_id?,
        alignment_certificate_digest?,
        coupling_trace_digest?,
        budget_ledger_digest,
        coverage_certificate_digest,
        lineage_digest
    }

Normative rule:
    any interval lineage used in comparison MUST contain both
    budget_ledger_digest and coverage_certificate_digest.

### Definition 13.32 (CoverageClosedInterval) [E]

A coverage-closed interval is

    J := {
        lo,
        hi,
        level,
        basis,
        regime,
        lineage,
        budget_ledger_digest,
        coverage_certificate_digest
    }

with:
    lo <= hi

Interpretation:
    J is the interval actually used by the comparison engine.

Normative rule:
    J MUST NOT be used in score_relation derivation unless its
    coverage certificate replays successfully.

### Definition 13.33 (Coverage Closure Construction) [E/N]

Let I_parent be a parent interval and let B_err be its referenced
error-budget ledger.

Under ADDITIVE_CONSERVATIVE, define the coverage-closed interval

    J = inflate(I_parent, B_err)

by:

    J.lo = I_parent.lo - B_err.total_lower_inflation
    J.hi = I_parent.hi + B_err.total_upper_inflation

Normative rule:
    if any declared comparison-layer error source is not represented
    in B_err, then J is not coverage-closed.

### Definition 13.34 (ComparisonAtoms — extended) [E]

ComparisonAtoms from v1.0.11 are extended by:

    BUDGET_LEDGER_AVAILABLE
    COVERAGE_CERTIFIED

Thus the comparison atom set becomes:

    ComparisonAtoms := {
        SAME_BATCH,
        SCORES_AVAILABLE,
        INTERVALS_AVAILABLE,
        INTERVAL_REGIME_COMPAT,
        INTERVAL_LINEAGE_AVAILABLE,
        BUDGET_LEDGER_AVAILABLE,
        COVERAGE_CERTIFIED,
        EVIDENCE_CLOSED,
        PROFILE_EQ,
        REFERENCE_EQ,
        POLICY_EQ,
        RNG_COMPAT,
        NORMALIZER_VALID,
        DELTA_REGIME_VALID,
        DELTA_LINEAGE_VALID
    }

### Definition 13.35 (Atomic Comparison Checks — extensions) [E]

INTERVAL_LINEAGE_AVAILABLE = PASS iff:
    every effective interval and the certified delta interval
    carry an IntervalLineage object with non-empty lineage_digest,
    budget_ledger_digest, and coverage_certificate_digest.

BUDGET_LEDGER_AVAILABLE = PASS iff:
    left effective interval,
    right effective interval,
    and certified delta interval
    each reference a replayable ErrorBudgetLedger with:
        composition_rule,
        entries,
        totals,
        and ledger_digest.

COVERAGE_CERTIFIED = PASS iff:
    left effective interval,
    right effective interval,
    and certified delta interval
    each reference a replayable CoverageCertificate and
    the certificate replay reproduces the recorded bounds.

DELTA_LINEAGE_VALID = PASS iff:

    if dependence_mode ∈ {UNKNOWN, INDEPENDENT}:
        delta interval basis = CONSERVATIVE_MARGINAL_DIFF
        and delta lineage references parent interval lineages
        and no hidden paired/coupled tightening is used

    if dependence_mode = PAIRED:
        SAME_BATCH = PASS
        and delta lineage basis = DIRECT_PAIRED_DELTA
        and delta lineage references either:
            a shared resample_family_id
            or an alignment_certificate_digest
        and delta lineage includes budget_ledger_digest
        and coverage_certificate_digest

    if dependence_mode = COUPLED_NORMALIZED:
        mode != RAW
        and NORMALIZER_VALID = PASS
        and delta lineage basis = DIRECT_NORMALIZED_DELTA
        and delta lineage references coupling_trace_digest
        and delta lineage includes budget_ledger_digest
        and coverage_certificate_digest

### Definition 13.36 (Required Pass Sets by Mode — extension) [E]

Req(mode) from v1.0.11 is extended by:

    BUDGET_LEDGER_AVAILABLE
    COVERAGE_CERTIFIED

Normative rule:
    a pair is comparable only if these additional atoms pass
    alongside all previously required atoms.

### Definition 13.37 (Effective Comparison Intervals — replacement) [E]

Let I_L^src and I_R^src denote the source comparison intervals
obtained exactly as in v1.0.11.

Let:

    B_L  = left error-budget ledger
    B_R  = right error-budget ledger
    C_L  = left coverage certificate
    C_R  = right coverage certificate

Then the effective comparison intervals are:

    J_L = inflate(I_L^src, B_L)
    J_R = inflate(I_R^src, B_R)

with:
    J_L certified by C_L
    J_R certified by C_R

Normative rule:
    J_L and J_R MUST be coverage-closed before any delta derivation.

### Definition 13.38 (Certified Delta Interval — replacement) [E]

Let D_raw be the raw delta interval determined by dependence mode:

    if dependence_mode ∈ {UNKNOWN, INDEPENDENT}:
        D_raw.lo = J_L.lo - J_R.hi
        D_raw.hi = J_L.hi - J_R.lo
        D_raw.basis = CONSERVATIVE_MARGINAL_DIFF

    if dependence_mode = PAIRED:
        D_raw = direct paired-delta interval
        D_raw.basis = DIRECT_PAIRED_DELTA

    if dependence_mode = COUPLED_NORMALIZED:
        D_raw = direct normalized-delta interval
        D_raw.basis = DIRECT_NORMALIZED_DELTA

Let:

    B_Δ = delta error-budget ledger
    C_Δ = delta coverage certificate

Then the certified delta interval is:

    Δ_cmp = inflate(D_raw, B_Δ)

with:
    Δ_cmp certified by C_Δ

Normative rule:
    no interval tighter than the conservative marginal-difference envelope
    may be used unless both:
        DELTA_REGIME_VALID = PASS
        DELTA_LINEAGE_VALID = PASS

### Definition 13.39 (Comparison Metrics — extended) [E]

comparison_metrics is extended to include budget totals:

    comparison_metrics := {
        left_point,
        right_point,
        left_interval,
        right_interval,
        delta_point,
        delta_interval,
        delta_interval_basis,
        dependence_mode,
        left_absorbed_budget,
        right_absorbed_budget,
        delta_absorbed_budget,
        delta_axis_scores?,
        delta_axis_leverage?,
        tolerance
    }

where:

    left_absorbed_budget  = (
        left_budget_ledger.total_lower_inflation,
        left_budget_ledger.total_upper_inflation
    )

    right_absorbed_budget = (
        right_budget_ledger.total_lower_inflation,
        right_budget_ledger.total_upper_inflation
    )

    delta_absorbed_budget = (
        delta_budget_ledger.total_lower_inflation,
        delta_budget_ledger.total_upper_inflation
    )

### Definition 13.40 (ComparisonExplanation — extended) [E]

comparison_explanation is extended with:

    budget_driver ∈ {
        STATISTICAL_CI,
        NORMALIZER_ERROR,
        COUPLING_PROPAGATION,
        NUMERIC_TOLERANCE,
        CALIBRATION_UNCERTAINTY,
        REFERENCE_DRIFT,
        MIXED,
        NONE
    }

Interpretation:
    budget_driver names the dominant inflation source across the
    interval budget ledgers actually used in comparison.

## 14. Canonical Abstract Operations [E]

### Operation OD-5 — replacement

    compare(B_left, B_right, mode, N_cmp?, T_cmp?, dependence_mode?) -> CompareResponse

Semantics:
    compare is comparison-safe, uncertainty-aware, dependence-aware,
    lineage-certified, and budget-ledgered.

It MUST:

    1. compute comparability_ledger
    2. construct source intervals
    3. construct error-budget ledgers for left, right, and delta intervals
    4. construct coverage-certified effective intervals
    5. construct a certified delta interval with replayable lineage
    6. emit score_relation
    7. emit reason_codes whenever relation is INCOMPARABLE
       or UNRESOLVED_WITHIN_UNCERTAINTY

It MUST NOT:

    1. use any interval for relation derivation unless it is coverage-certified
    2. collapse multiple declared error sources into an opaque scalar
       without a replayable budget ledger
    3. claim direct paired or coupled tightening without corresponding lineage
    4. leave declared comparison-layer error bounds unabsorbed

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
        coverage_certificates?,
        interval_lineages?,
        score_relation,
        comparison_explanation?,
        reason_codes,
        provenance?
    }

### Definition 16.3 (Error Budget Ledger Bundle) [E]

    error_budget_ledgers := {
        left_budget_ledger,
        right_budget_ledger,
        delta_budget_ledger
    }

Normative rule:
    if score_relation != INCOMPARABLE,
    then error_budget_ledgers MUST be present.

### Definition 16.4 (Coverage Certificate Bundle) [E]

    coverage_certificates := {
        left_coverage_certificate,
        right_coverage_certificate,
        delta_coverage_certificate
    }

Normative rule:
    if score_relation != INCOMPARABLE,
    then coverage_certificates MUST be present.

### Definition 16.5 (Interval Lineage Bundle — replacement) [E]

    interval_lineages := {
        left_interval_lineage,
        right_interval_lineage,
        delta_interval_lineage
    }

Normative rule:
    if score_relation != INCOMPARABLE,
    then interval_lineages MUST be present.

### Definition 16.6 (Comparison Reason Codes — extension) [E]

Comparison reason codes from v1.0.11 are extended by:

    BUDGET_LEDGER_MISSING
    COVERAGE_NOT_CERTIFIED
    ERROR_SOURCE_UNACCOUNTED

Thus the reason-code family includes at least:

    BATCH_MISMATCH
    SCORES_MISSING
    INTERVALS_MISSING
    INTERVAL_REGIME_MISMATCH
    INTERVAL_LINEAGE_MISSING
    BUDGET_LEDGER_MISSING
    COVERAGE_NOT_CERTIFIED
    EVIDENCE_NOT_CLOSED
    PROFILE_MISMATCH
    REFERENCE_MISMATCH
    POLICY_MISMATCH
    RNG_MISMATCH
    NORMALIZER_MISSING
    NORMALIZER_SCOPE_INVALID
    NORMALIZER_PROOF_MISSING
    NORMALIZER_ERROR_UNABSORBED
    DELTA_REGIME_INVALID
    DELTA_LINEAGE_INVALID
    DEPENDENCE_UNDECLARED
    PAIRED_ALIGNMENT_MISSING
    COUPLING_TRACE_MISSING
    ERROR_SOURCE_UNACCOUNTED
    COMPARE_UNCERTAINTY_OVERLAP
    COMPARE_INSUFFICIENT_EVIDENCE

### Definition 16.7 (Comparison Evidence Closure — extension) [E]

A comparison reason code is evidence-closed iff the corresponding failed atom
or unresolved certified-delta condition is present and replayable.

Examples:

    BUDGET_LEDGER_MISSING
        -> BUDGET_LEDGER_AVAILABLE.status = FAIL

    COVERAGE_NOT_CERTIFIED
        -> COVERAGE_CERTIFIED.status = FAIL

    ERROR_SOURCE_UNACCOUNTED
        -> a declared comparison-layer error source is absent from all
           relevant budget ledgers

    NORMALIZER_ERROR_UNABSORBED
        -> normalizer.error_bound declared
           but not absorbed into any certified interval used for derivation

## 18. Compare Invariants [E/N]

All Compare Invariants C0–C24 from v1.0.11 remain in force.

The following are added:

Invariant C25:
    if comparability_ledger.BUDGET_LEDGER_AVAILABLE.status = FAIL,
    then score_relation = INCOMPARABLE

Invariant C26:
    if comparability_ledger.COVERAGE_CERTIFIED.status = FAIL,
    then score_relation = INCOMPARABLE

Invariant C27:
    for every error-budget ledger used in comparison under
    ADDITIVE_CONSERVATIVE,

        total_lower_inflation = Σ lower_inflation(entry)
        total_upper_inflation = Σ upper_inflation(entry)

Invariant C28:
    every interval used in score_relation derivation MUST be replayable
    from its parent interval(s), referenced error-budget ledger,
    and referenced coverage certificate.

Invariant C29:
    if normalizer.error_bound is declared and mode != RAW,
    then at least one ErrorBudgetEntry with

        source_kind = NORMALIZER_ERROR

    MUST appear in a relevant budget ledger and be absorbed before
    relation derivation.

Invariant C30:
    if coupling_trace.propagated_error_bound is declared,
    then at least one ErrorBudgetEntry with

        source_kind = COUPLING_PROPAGATION

    MUST appear in the relevant budget ledger and be absorbed before
    relation derivation.

Invariant C31:
    every declared comparison-layer error source arising from:
        interval regime,
        normalizer,
        coupling trace,
        numeric tolerance used in interval inflation,
        calibration uncertainty,
        or reference drift
    MUST appear in at least one relevant budget ledger.

    Otherwise:
        score_relation = INCOMPARABLE

## 19. Provenance Minimum [E/N]

Every CompareResponse provenance bundle from v1.0.11 is extended.

In addition to all previously required fields, provenance MUST record:

    error_budget_ledgers
    coverage_certificates
    composition rules
    per-source lower inflations
    per-source upper inflations
    total lower inflation per interval
    total upper inflation per interval

If dependence_mode = PAIRED:
    the resample family digest and alignment certificate digest MUST be recorded.

If dependence_mode = COUPLED_NORMALIZED:
    the coupling trace digest MUST be recorded.

If normalizer.error_bound is declared:
    the absorbed NORMALIZER_ERROR contribution MUST be recorded.

If any coverage closure uses inflation beyond the parent interval:
    the budget ledger digest and coverage certificate digest MUST be recorded.

If score_relation = UNRESOLVED_WITHIN_UNCERTAINTY:
    uncertainty_driver SHOULD be recorded.

If budget_driver is not NONE:
    budget_driver SHOULD be recorded.

## 22. Final Position

TSC Observation Dynamics v1.0.12 is the error-budget-ledgered,
composition-certified observation-layer specification of TSC.

Its decisive moves are:

    lineage is no longer enough without per-source budget accounting,
    coverage closure is no longer a scalar but a replayable composition,
    every certified interval now carries both ancestry and inflation proof,
    declared comparison-layer error sources must be explicitly absorbed,
    and no runtime may hide interval widening behind a single opaque number.

That is stricter than v1.0.11.
That is more honest about why comparison intervals are as wide as they are.
That is safer for runtimes, SDKs, and AI readers.
That is the next clean step.