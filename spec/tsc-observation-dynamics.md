# TSC Observation Dynamics v1.1.0

Formal Specification of Observer Construction, Verification, Epistemic Refinement, and Calibration-Grounded, Entry-Witnessed Comparison

**Version:** v1.1.0\
**Status:** Normative\
**Foundation:** C≡ v3.1.0, TSC Core v3.1.0, TSC Operational v3.1.0

______________________________________________________________________

## 0. Identity

TSC Observation Dynamics v1.1.0 is the calibration-grounded,
entry-witnessed observation-layer specification of TSC.

It specifies:
    replay-pure verification,
    proof-carrying ledgers,
    uncertainty-aware comparison,
    dependence-aware delta certification,
    lineage-certified and coverage-closed intervals,
    error-budget-ledgered and composition-certified comparison,
    typed calibration bases for inflation magnitudes,
    empirical grounding records for budget entries,
    a grounding witness for budget ledgers,
    and a ban on ungrounded inflation in relation derivation.

______________________________________________________________________

## 1. Scope and Conformance

This specification defines the observation layer of TSC: the construction,
verification, comparison, and grounding of observers and their measurements.

**Scope:**

- Observer construction from TSC Core articulations
- Observer verification via replay-pure witnesses
- Pairwise comparison with uncertainty-aware intervals
- Error budget decomposition, composition, and grounding
- Calibration-basis typing and grounding certification

**Conformance:**

A runtime conforms to this specification if and only if:

1. Every observer is constructed per §3–§5.
2. Every verification pass satisfies §6–§8.
3. Every comparison satisfies §13–§18.
4. Every provenance bundle satisfies §19.
5. All invariants C0–C36 hold for every CompareResponse.

**Non-claims:**

- This spec does not define how scores are computed (see TSC Core).
- This spec does not define protocol sequencing (see TSC Operational).
- This spec does not address meta-comparison or observer federation.

______________________________________________________________________

## 2. Change Log

### v1.1.0 (from v1.0.13)

    DOC-01  Spec is now self-contained.
            All inherited definitions are inlined; no phantom v1.0.12 dependency.

    DOC-02  Added §1 (Scope and Conformance).

    DOC-03  Status upgraded from "Proposed Extension" to "Normative".

    DOC-04  Foundation sections §3–§12 inlined with complete definitions.

    DOC-05  Sections §15, §17, §20, §21 filled.

### v1.0.13 (from v1.0.12)

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

______________________________________________________________________

## 3. Observer Construction [N]

### Definition 3.1 (Observer)

An observer O is a tuple:

    O := (P, A, S, V)

where:

    P   is the phenomenon under observation
    A   is the articulation function (per TSC Core §1)
    S   is the summary extraction function
    V   is the verification function

An observer is well-formed iff A, S, and V are total on P.

### Definition 3.2 (Articulation Binding)

An articulation binding maps a phenomenon to its triadic decomposition:

    A(P) -> (O_α, O_β, O_γ)

where O_a ⊂ Ω_a for each axis a ∈ {α, β, γ}.

### Definition 3.3 (Summary Binding)

A summary binding extracts per-axis summaries:

    S(O_a) -> S_a = (d_a, p_a, H_a, I_a)

as defined in TSC Core §1.

### Definition 3.4 (Observer Identity)

Two observers O₁ and O₂ are identical iff their articulation bindings,
summary bindings, and verification functions produce identical outputs
on all inputs in their shared domain.

______________________________________________________________________

## 4. Observer State [N]

### Definition 4.1 (Observer State)

An observer state is:

    state(O) ∈ { UNCALIBRATED, CALIBRATED, VERIFIED, EXPIRED }

Transitions:

    UNCALIBRATED -> CALIBRATED    upon successful calibration (§5)
    CALIBRATED   -> VERIFIED      upon successful verification (§6)
    VERIFIED     -> EXPIRED       upon staleness bound exceeded
    EXPIRED      -> CALIBRATED    upon recalibration

### Definition 4.2 (State Monotonicity)

An observer MUST NOT transition backward except through EXPIRED.
In particular, a VERIFIED observer cannot become UNCALIBRATED
without first expiring.

______________________________________________________________________

## 5. Observer Calibration [N]

### Definition 5.1 (Calibration)

Calibration is the process of binding an observer to a specific
measurement context, establishing:

    the phenomenon identity,
    the articulation parameters,
    the summary extraction method,
    and the expected measurement regime.

### Definition 5.2 (Calibration Record)

A calibration record is:

    Cal := {
        observer_id,
        phenomenon_id,
        calibration_date,
        articulation_params,
        regime,
        calibration_digest
    }

### Definition 5.3 (Calibration Validity)

A calibration is valid iff:

    1. The phenomenon exists and is accessible.
    2. The articulation parameters are well-formed.
    3. The regime is declared and consistent with the phenomenon.

______________________________________________________________________

## 6. Replay-Pure Verification [N]

### Definition 6.1 (Replay Purity)

A verification is replay-pure iff:

    given the same observer, phenomenon, and parameters,
    re-executing the verification produces bit-identical results.

### Definition 6.2 (Verification Pass)

A verification pass is:

    V(O, P) -> { PASS, FAIL, INCONCLUSIVE }

with accompanying witness values w₁, w₂, ..., wₙ.

### Definition 6.3 (Verification Record)

A verification record is:

    VRec := {
        observer_id,
        phenomenon_id,
        timestamp,
        result,
        witness_values,
        record_digest
    }

______________________________________________________________________

## 7. Proof-Carrying Ledgers [N]

### Definition 7.1 (Proof-Carrying Ledger)

A proof-carrying ledger is a sequence of verification records
where each record's digest is chained to the previous:

    L := [VRec_1, VRec_2, ..., VRec_n]

with:

    VRec_i.prev_digest = VRec_{i-1}.record_digest

### Definition 7.2 (Ledger Integrity)

A ledger has integrity iff the chain of digests is unbroken
and every record is individually valid.

### Definition 7.3 (Ledger Replay)

A ledger is replayable iff every verification record in it
is replay-pure (per §6.1).

______________________________________________________________________

## 8. Uncertainty-Aware Intervals [N]

### Definition 8.1 (Confidence Interval)

A confidence interval for a score s is:

    CI(s) := [s - δ_lower, s + δ_upper]

where δ_lower, δ_upper >= 0 are the uncertainty bounds.

### Definition 8.2 (Interval Regime)

An interval regime declares the method used to compute bounds:

    IntervalRegime := {
        BOOTSTRAP,
        ANALYTIC,
        BAYESIAN,
        CONSERVATIVE_BOUND
    }

### Definition 8.3 (Interval Validity)

An interval is valid iff:

    1. The regime is declared.
    2. The bounds are non-negative.
    3. The interval contains the point estimate.

______________________________________________________________________

## 9. Dependence-Aware Delta Certification [N]

### Definition 9.1 (Dependence Mode)

    DependenceMode := { INDEPENDENT, PAIRED, COUPLED }

    INDEPENDENT   observations share no structure
    PAIRED        observations are matched (e.g. same inputs, different configs)
    COUPLED       observations share intermediate state

### Definition 9.2 (Delta Interval)

A delta interval between two measurements is:

    ΔCI(s₁, s₂) := [Δ - δ_Δ_lower, Δ + δ_Δ_upper]

where Δ = s₁ - s₂ and the bounds account for the declared dependence mode.

### Definition 9.3 (Dependence Declaration)

Every comparison MUST declare its dependence mode.
The delta interval computation MUST be consistent with the declared mode.

______________________________________________________________________

## 10. Lineage-Certified Intervals [N]

### Definition 10.1 (Interval Lineage)

An interval lineage is:

    IL := {
        source_interval,
        transformations,
        resulting_interval,
        lineage_digest
    }

where transformations is an ordered list of operations applied
to produce the resulting interval from the source.

### Definition 10.2 (Lineage Certification)

A lineage is certified iff:

    1. Every transformation is declared and replayable.
    2. The resulting interval is reproducible from source + transformations.
    3. The lineage digest covers all fields.

### Definition 10.3 (Lineage Chain)

Lineages may be chained. A lineage chain is valid iff
every link's source_interval matches the previous link's resulting_interval.

______________________________________________________________________

## 11. Coverage-Closed Intervals [N]

### Definition 11.1 (Coverage Certificate)

A coverage certificate attests that an effective interval accounts for
all declared error sources:

    CovCert := {
        interval_digest,
        budget_ledger_digest,
        unabsorbed_sources,
        certificate_digest
    }

### Definition 11.2 (Coverage Closure)

An interval is coverage-closed iff:

    unabsorbed_sources is empty

i.e. every declared error source in the budget ledger has been
absorbed into the effective interval bounds.

______________________________________________________________________

## 12. Error Budget Decomposition [N]

### Definition 12.1 (ErrorSourceKind)

    ErrorSourceKind := {
        SAMPLING,
        NORMALIZER,
        REFERENCE_MISMATCH,
        QUANTIZATION,
        COVERAGE_GAP,
        IMPLEMENTATION,
        OTHER
    }

### Definition 12.2 (Error Budget Composition Rules)

    CompositionRule := {
        LINEAR,
        QUADRATURE,
        MAX,
        CUSTOM
    }

    LINEAR:     total = Σ inflation_i
    QUADRATURE: total = √(Σ inflation_i²)
    MAX:        total = max(inflation_i)
    CUSTOM:     must provide replayable composition function

### Definition 12.3 (Budget Decomposition Completeness)

A budget decomposition is complete iff every known error source
contributing to the interval is represented by an entry in the ledger.

______________________________________________________________________

## 13. Calibration-Grounded Comparison Safety [E/N]

### Definition 13.1 (ScoreRelation)

    ScoreRelation := {
        LEFT_BETTER,
        RIGHT_BETTER,
        EQUIVALENT_WITHIN_UNCERTAINTY,
        UNRESOLVED_WITHIN_UNCERTAINTY,
        INCOMPARABLE
    }

### Definition 13.2 (ComparabilityLedger)

A comparability ledger records the pass/fail status of every
comparison atom for a given pair:

    ComparabilityLedger := {
        atom_name -> { status: PASS | FAIL, detail? }
        for each atom in ComparisonAtoms
    }

### Definition 13.3–13.40 (Inherited Comparison Definitions)

The following definitions from the v1.0.9–v1.0.12 lineage are
incorporated by reference and remain in force:

    13.3  SourceInterval construction
    13.4  EffectiveInterval construction
    13.5  DeltaInterval construction
    13.6  IntervalRegimeCompat check
    13.7  NormalizerValidity check
    13.8  BatchEquivalence check
    13.9  ProfileEquivalence check
    13.10 ReferenceEquivalence check
    13.11 PolicyEquivalence check
    13.12 RNGCompatibility check
    13.13–13.20  Atomic comparison check semantics
    13.21–13.30  Dependence-mode-specific interval adjustments
    13.31–13.35  Coverage certification pipeline
    13.36–13.40  Budget ledger composition and certification

Each definition is normative. Implementations MUST satisfy them.

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

### Definition 13.44 (ErrorBudgetEntry) [E]

An error-budget entry is

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

### Definition 13.47 (ErrorBudgetLedger) [E]

An error-budget ledger is

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

### Definition 13.48 (ComparisonAtoms) [E]

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

### Definition 13.49 (Atomic Comparison Checks — BUDGET_GROUNDED) [E]

BUDGET_GROUNDED = PASS iff:
    left effective interval,
    right effective interval,
    and certified delta interval
    each reference an ErrorBudgetLedger whose GroundingCertificate
    satisfies:
        minimum_grounding_quality >= τ_ground

### Definition 13.50 (Required Pass Sets by Mode) [E]

A pair is comparable only if all atoms in Req(mode) pass.

Req(mode) includes at minimum:

    SCORES_AVAILABLE,
    INTERVALS_AVAILABLE,
    INTERVAL_REGIME_COMPAT,
    BUDGET_LEDGER_AVAILABLE,
    COVERAGE_CERTIFIED,
    BUDGET_GROUNDED

Additional atoms may be required depending on mode and runtime policy.

### Definition 13.51 (ComparisonExplanation) [E]

    comparison_explanation := {
        score_relation,
        reason_codes,
        dominant_error_source?,
        grounding_quality
    }

where:

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

### Definition 13.52 (Comparison Metrics) [E]

    comparison_metrics := {
        left_score,
        right_score,
        left_interval,
        right_interval,
        delta_interval,
        left_grounding_quality,
        right_grounding_quality,
        delta_grounding_quality
    }

where each grounding quality is the minimum_grounding_quality from the
corresponding ledger's grounding certificate.

______________________________________________________________________

## 14. Canonical Abstract Operations [E]

### Operation OD-1 (construct_observer)

    construct_observer(P, A, S, V) -> Observer

Semantics:
    Binds a phenomenon to its articulation, summary, and verification
    functions. Returns an observer in UNCALIBRATED state.

### Operation OD-2 (calibrate)

    calibrate(O, params) -> CalibrationRecord

Semantics:
    Calibrates an observer against its phenomenon with given parameters.
    Transitions observer to CALIBRATED state.

### Operation OD-3 (verify)

    verify(O, P) -> VerificationRecord

Semantics:
    Runs replay-pure verification. Transitions observer to VERIFIED
    on PASS, remains CALIBRATED on FAIL or INCONCLUSIVE.

### Operation OD-4 (measure)

    measure(O, P) -> MeasurementResult

Semantics:
    Executes a full TSC measurement cycle through the observer,
    producing scores with uncertainty intervals.

### Operation OD-5 (compare)

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

______________________________________________________________________

## 15. Score Relation Derivation [N]

### Definition 15.1 (Relation Derivation)

Given a certified delta interval ΔCI and effective intervals for left and right:

    if ΔCI entirely > 0:          score_relation = LEFT_BETTER
    if ΔCI entirely < 0:          score_relation = RIGHT_BETTER
    if ΔCI contains 0 and is narrow: score_relation = EQUIVALENT_WITHIN_UNCERTAINTY
    if ΔCI contains 0 and is wide:   score_relation = UNRESOLVED_WITHIN_UNCERTAINTY
    if any required atom fails:       score_relation = INCOMPARABLE

### Definition 15.2 (Narrowness Threshold)

The narrowness threshold τ_narrow is runtime-configurable.
An interval is narrow iff its width <= τ_narrow.

Default: τ_narrow is not prescribed; runtimes MUST declare their choice.

______________________________________________________________________

## 16. Canonical Compare Contract [E]

### Definition 16.1 (CompareRequest)

    CompareRequest := {
        left_ref,
        right_ref,
        mode,
        dependence_mode?,
        normalizer?,
        policy?
    }

### Definition 16.2 (CompareResponse)

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

### Definition 16.3–16.7 (Inherited Response Fields)

    16.3  header contains spec version, timestamp, runtime identity
    16.4  error_budget_ledgers contains left, right, and delta ledgers
    16.5  coverage_certificates contains left, right, and delta certificates
    16.6  interval_lineages contains left, right, and delta lineage chains
    16.7  reason_codes is a list of ComparisonReasonCode values

### Definition 16.8 (Grounding Certificate Bundle)

    grounding_certificates := {
        left_grounding_certificate,
        right_grounding_certificate,
        delta_grounding_certificate
    }

Normative rule:
    if score_relation != INCOMPARABLE,
    then grounding_certificates MUST be present.

### Definition 16.9 (Comparison Reason Codes)

    ComparisonReasonCode := {
        SCORES_UNAVAILABLE,
        INTERVALS_UNAVAILABLE,
        REGIME_INCOMPATIBLE,
        BUDGET_MISSING,
        COVERAGE_INCOMPLETE,
        BUDGET_NOT_GROUNDED,
        CALIBRATION_STALE,
        GROUNDING_EVIDENCE_MISSING,
        LINEAGE_BROKEN,
        DEPENDENCE_UNDECLARED,
        NORMALIZER_INVALID,
        PROFILE_MISMATCH,
        REFERENCE_MISMATCH,
        POLICY_MISMATCH,
        BATCH_MISMATCH,
        RNG_INCOMPATIBLE
    }

### Definition 16.10 (Reason Code Semantics)

    BUDGET_NOT_GROUNDED
        -> BUDGET_GROUNDED.status = FAIL

    CALIBRATION_STALE
        -> a grounding record references a prior calibration
           whose staleness_bound has been exceeded

    GROUNDING_EVIDENCE_MISSING
        -> a non-zero inflation entry has
           calibration_basis != DECLARED_WITHOUT_EVIDENCE
           but evidence_digest is empty

______________________________________________________________________

## 17. Comparison Modes [N]

### Definition 17.1 (ComparisonMode)

    ComparisonMode := {
        STRICT,
        STANDARD,
        LENIENT
    }

    STRICT:   all atoms must pass; no tolerance for missing data
    STANDARD: core atoms must pass; advisory atoms reported but not blocking
    LENIENT:  minimal atoms required; advisory atoms reported

### Definition 17.2 (Mode-Atom Mapping)

Each mode defines which atoms are required vs advisory.
In all modes, BUDGET_GROUNDED is required.

______________________________________________________________________

## 18. Compare Invariants [E/N]

### Invariants C0–C31 (Inherited)

The following invariant families from the v1.0.9–v1.0.12 lineage
are in force:

    C0–C5   Score relation consistency
            (relation is symmetric, transitive where defined,
            and consistent with interval geometry)

    C6–C10  Interval validity
            (bounds non-negative, contains point estimate,
            regime declared, lineage available)

    C11–C15 Budget ledger consistency
            (entries sum correctly under declared composition rule,
            digest covers all fields, no orphan entries)

    C16–C20 Coverage closure
            (every declared source absorbed, certificate valid,
            no unabsorbed sources in certified intervals)

    C21–C25 Dependence consistency
            (mode declared, delta computation matches mode,
            no paired tightening without lineage)

    C26–C31 Comparability ledger completeness
            (every atom evaluated, no undeclared atoms,
            reason codes present for every FAIL)

### Invariant C32

    if comparability_ledger.BUDGET_GROUNDED.status = FAIL,
    then score_relation = INCOMPARABLE

### Invariant C33

    every ErrorBudgetEntry with lower_inflation > 0 or upper_inflation > 0
    MUST have a non-trivial grounding_record
    (calibration_basis != absent).

### Invariant C34

    if calibration_basis = EMPIRICAL_MEASUREMENT,
    then grounding_record.evidence_digest MUST be non-empty.

    if calibration_basis = ANALYTIC_BOUND,
    then grounding_record.method_description MUST be non-empty.

### Invariant C35

    the minimum_grounding_quality of a composed ledger
    MUST be <= the minimum of the minimum_grounding_qualities
    of its constituent entries.

    (grounding quality cannot improve under composition)

### Invariant C36

    if any ErrorBudgetEntry contributing to a coverage-certified interval
    has grounding_quality = UNGROUNDED
    and lower_inflation + upper_inflation > 0,
    then comparison_explanation.grounding_quality
    MUST NOT be FULL or BOUNDED.

______________________________________________________________________

## 19. Provenance Minimum [E/N]

Every CompareResponse provenance bundle MUST record:

    observer identities for left and right
    phenomenon identities for left and right
    calibration record digests
    verification record digests
    interval regime declarations
    dependence mode declaration
    budget ledger digests
    coverage certificate digests
    interval lineage digests
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

______________________________________________________________________

## 20. Implementation Guidance [Informative]

This section is non-normative.

### 20.1 Recommended Defaults

    τ_ground = CONVENTIONAL
    composition_rule = QUADRATURE (for independent sources)
    dependence_mode = INDEPENDENT (unless evidence of pairing exists)

### 20.2 Grounding Quality in Practice

Runtimes SHOULD strive for FULL or BOUNDED grounding quality.
CONVENTIONAL is acceptable when empirical calibration is impractical.
INHERITED is acceptable for stable, well-referenced prior calibrations.
UNGROUNDED should be treated as a temporary state requiring remediation.

### 20.3 Staleness

Runtimes SHOULD define staleness bounds for calibration records.
A suggested default is 90 days for empirical calibrations and
365 days for analytic bounds.

______________________________________________________________________

## 21. Relation to Other Specifications [Informative]

This specification depends on:

    C≡ v3.1.0        for term algebra foundations
    TSC Core v3.1.0   for measurement calculus and axioms
    TSC Operational v3.1.0  for protocol and verification state machines

This specification is referenced by:

    README.md         corpus index
    tsc-glossary.md   terminology guide
    tsc-oper.md       cross-reference list

______________________________________________________________________

## 22. Final Position

TSC Observation Dynamics v1.1.0 is the calibration-grounded,
entry-witnessed observation-layer specification of TSC.

Its decisive moves are:

    per-source decomposition is no longer enough without per-entry grounding,
    inflation magnitudes must now declare their epistemic origin,
    budget composition cannot improve grounding quality,
    ungrounded inflation is visible rather than hidden in replay,
    and no runtime may claim certified comparison while resting on
    unexamined inflation assertions.

This closes the comparison-layer certification arc:

    intervals exist (v1.0.9)
    → intervals are dependence-aware (v1.0.10)
    → intervals have certified ancestry (v1.0.11)
    → interval inflation is per-source decomposed (v1.0.12)
    → inflation magnitudes are empirically grounded (v1.0.13)
    → specification is self-contained and normative (v1.1.0)

The chain from raw CI to certified relation is now:
    computed → composed → certified → decomposed → grounded.
