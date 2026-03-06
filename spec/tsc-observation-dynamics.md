# TSC Observation Dynamics v1.0.9

Formal Specification of Observer Construction, Verification, Epistemic Refinement, and Uncertainty-Aware Comparison

    Version:    v1.0.9
    Status:     Proposed Extension Specification
    Artifact:   Specification
    Normative dependencies:
        C≡ v3.1.0
        TSC Core v3.1.0
        TSC Operational v3.1.0
    Recommended repository path:
        spec/tsc-observation-dynamics.md

## 0. Identity

This document is the observation-layer specification of TSC.

It defines:

    what an observer is,
    how an observer-run is typed,
    how a run is classified,
    how refinement is ordered,
    how self-application is normalized,
    how verification remains replay-pure and proof-carrying,
    and how cross-observer comparison becomes uncertainty-aware.

Place in stack:

    C≡
      → TSC Core
      → TSC Operational
      → TSC Observation Dynamics   ← this document
      → Runtime / API / SDK
      → Application-specific observers

It is:

    not the foundation,
    not the core measurement calculus,
    not the operational witness protocol,

but the layer that makes observer semantics executable, replayable, auditable,
proof-carrying, comparison-safe, and interval-aware.

## 1. Status Discipline

    [N]  inherited normative basis
    [E]  formal extension compatible with inherited TSC basis
    [C]  external conjecture or interpretation

Normative reading rule:

    Nothing marked [E] or [C] may be cited as if it were already proven by [N].

## 2. Change Log

### From v1.0.8

    UNC-01  Comparison is now interval-aware.
            Score relations are derived from effective comparison intervals,
            not from point deltas alone.

    UNC-02  ScoreRelation extended with:
                UNRESOLVED_WITHIN_UNCERTAINTY
            which is distinct from INCOMPARABLE.

    UNC-03  IntervalsAvailable added as a first-class comparison atom.
            Ordering claims now require score intervals, not just point scores.

    NRM-03  Comparison normalizers must induce comparison intervals in target
            space and declare target confidence level and error budget.

    DER-02  Delta-interval derivation added:
                Δ_cmp = [L_lo − R_hi, L_hi − R_lo]

    DER-03  Ordering is now certified only when the delta interval lies wholly
            outside the equality band ±delta_eq.

    EXP-02  ComparisonExplanation gains uncertainty_driver.
            AI readers can now distinguish "mismatch" from "too close to call."

    EVD-05  Comparison reason codes extended:
                INTERVALS_MISSING
                NORMALIZER_INTERVAL_INVALID
                COMPARE_UNCERTAINTY_OVERLAP

    PRV-03  Comparison provenance minimum extended to include comparison
            intervals, interval basis, target confidence level, and
            normalizer error budget.

### From v1.0.7

    CMP-02  ComparisonMode introduced.
    CMP-03  ComparabilityLedger introduced.
    CMP-04  Raw and normalized comparability separated.
    NRM-02  Comparison normalizer introduced with explicit coverage scope.
    REL-01  ScoreRelation introduced.
    EVD-04  No false parity claims.
    EXP-01  ComparisonExplanation introduced.
    PRV-02  Comparison provenance minimum introduced.

### From v1.0.6

    POL-01  EvaluationPolicy introduced for witness and verdict stages.
    LED-01  WitnessLedger introduced.
    LED-02  VerdictLedger introduced.
    CLS-04  ver / acc / dep become ledger-derived.
    MAT-02  Trace-complete materialization refined.
    EVD-02  Acceptance made proof-carrying.
    ORD-01  Canonical witness and verdict orders frozen.

### From v1.0.5

    SYM-03  SymmetryMode introduced as first-class profile field.
    SYM-04  W1 generalized under covariant symmetry mode.
    ADM-02  Non-uniform aggregation forces COVARIANT symmetry mode.
    TRC-03  Legal controller traces made exact.
    DEC-01  Witness failure routed to DIAGNOSE → TERMINAL;
            verdict failure routed to VERDICT → REJECT.
    MAT-01  Trace-complete materialization introduced.
    EVD-01  Evidence closure introduced.
    CLS-03  Information preorder on Status3 introduced.

### From v1.0.4

    SYM-02  Permutation discipline corrected: absolute vs covariance distinction.
    AGR-03  Aggregation profile explicitly axis-indexed and permutation-aware.
    REP-01  Replay purity introduced.
    REP-02  EffectiveProfile formalized as frozen merge of BaseProfile and OverrideSet.
    OOD-01  Reference-state evolution separated from verification.
    RNG-01  ReplayClass and RandomnessRecord introduced.
    CMP-01  Observer/batch compatibility made first-class.

### From v1.0.3

    AGR-01  Aggregation profile W introduced as first-class object.
    AGR-02  V1/V2 generalized to weighted form.
    EXE-01  Execution outcome separated from controller outcome.
    EXE-02  Classification lifted to Status3 = {PASS, FAIL, UNDECIDED}.
    PRO-01  ParameterProfile made explicit canonical object.
    SEL-02  Self-application normalized through Bundle-domain lift.

### From v1.0.2

    SYM-01  κ_o renamed to ρ_o.
    NOT-01  Explicit notation bridge table added.
    REF-01  Monotonicity weakened to convergent-subsequence form.
    EPI-01  Triadic episode grounded to observer pipeline.
    DEP-01  Deployment threshold τ_lip_pol given recommended range.
    SEL-01  Self-application section added.

## 3. Symmetry, Aggregation, and Witness Semantics [N/E]

### Definition 3.1 (Axis Set) [N/E]

Let

    A := {α, β, γ}.

### Definition 3.2 (Axis-Indexed Objects) [E]

Any object of the form

    q = (q_alpha, q_beta, q_gamma)

is axis-indexed.

### Definition 3.3 (Permutation Action) [E]

For any π ∈ S₃ and any axis-indexed object q:

    (π · q)_a := q_{π⁻¹(a)}

### Definition 3.4 (SymmetryMode) [E]

    SymmetryMode := {ABSOLUTE, COVARIANT}

### Definition 3.5 (Aggregation Profile) [N/E]

An aggregation profile is

    W := (w_alpha, w_beta, w_gamma)

such that:

    w_alpha > 0
    w_beta  > 0
    w_gamma > 0
    w_alpha + w_beta + w_gamma = 3

Default:

    W_uniform := (1, 1, 1)

### Definition 3.6 (Aggregate Coherence) [N/E]

Given dimensional scores s = (s_alpha, s_beta, s_gamma),
numerical floor ε, and aggregation profile W:

    C_Σ(s; W)
      :=
    exp((1/3) · (
        w_alpha · ln(max(s_alpha, ε)) +
        w_beta  · ln(max(s_beta,  ε)) +
        w_gamma · ln(max(s_gamma, ε))
    ))

Uniform case:

    If W = W_uniform, then

        C_Σ(s; W_uniform) = (s_alpha · s_beta · s_gamma)^(1/3)

### Definition 3.7 (Diagnostic Leverage) [E]

For each axis a ∈ A:

    ℓ_a := −ln(max(s_a, ε))

Aggregate leverage:

    ℓ_Σ(s; W)
      :=
    (1/3) · (
        w_alpha · ℓ_alpha +
        w_beta  · ℓ_beta  +
        w_gamma · ℓ_gamma
    )

Equivalently:

    ℓ_Σ(s; W) = −ln(C_Σ(s; W))

### Proposition 3.8 (Permutation Law) [E/N]

For all π ∈ S₃:

    C_Σ(s; W) = C_Σ(π · s; π · W)

### Definition 3.9 (Effective Symmetry Profile) [E]

Let P_eff be the frozen effective profile.
Its computationally relevant axis-indexed subfields are denoted P_eff^axis.

### Definition 3.10 (W1 Symmetry Witness Under Mode) [E]

Let O = (O_alpha, O_beta, O_gamma) be axis-material after articulation.

If symmetry_mode = ABSOLUTE:

    w_S3
      :=
    max_{π ∈ S₃} | C_Σ(O; P_eff) − C_Σ(π · O; P_eff) |

If symmetry_mode = COVARIANT:

    w_S3
      :=
    max_{π ∈ S₃} | C_Σ(O; P_eff) − C_Σ(π · O; π · P_eff^axis) |

### Admissibility Rule 3.11 (Symmetry/Profile Compatibility) [E]

If aggregation_profile ≠ W_uniform,
then symmetry_mode MUST equal COVARIANT.

## 4. Observation Objects, Profiles, and Freezing Discipline [E]

### Definition 4.1 (Observation Domain) [E]

Let X be the declared domain of the phenomenon under observation.

### Definition 4.2 (Observation Batch) [E]

An observation batch is a finite sequence

    D = (x_1, …, x_N) ∈ X*

### Definition 4.3 (EvaluationPolicy) [E]

    EvaluationPolicy := {FAIL_FAST, EXHAUSTIVE}

### Definition 4.4 (WitnessOrder) [E]

    WitnessOrder_default := [S3, GAUGE, SCALE, VAR, LIP]

### Definition 4.5 (VerdictOrder) [E]

    VerdictOrder_default := [THRESHOLD, CI, OOD]

### Definition 4.6 (BaseProfile) [E]

    P_base := {
        theta,
        μ_axis,
        μ_pair,
        ε,
        aggregation_profile,
        symmetry_mode,
        witness_eval_policy,
        verdict_eval_policy,
        witness_order,
        verdict_order,
        Θ,
        τ_S3,
        τ_gauge,
        τ_scale,
        τ_var,
        τ_lip,
        τ_lip_pol?,
        δ_CI,
        ci_level,
        Z_crit,
        N_boot,
        OOD_reference_policy,
        calibration_refs?
    }

Canonical defaults:

    witness_eval_policy = FAIL_FAST
    verdict_eval_policy = FAIL_FAST
    witness_order       = WitnessOrder_default
    verdict_order       = VerdictOrder_default

### Definition 4.7 (OverrideSet) [E]

    ΔP := { any subset of legal P_base fields }

### Definition 4.8 (EffectiveProfile) [E]

    P_eff := freeze(merge(P_base, ΔP))

All scoring, witness evaluation, verdict evaluation, CI evaluation,
OOD evaluation, and classification derivation MUST use P_eff.

### Definition 4.9 (Observer Manifest) [E]

    M_o := {
        observer_id,
        observer_version,
        axis_aliases,
        domain_tag,
        schema_ref?,
        component_refs,
        base_profile_ref,
        allowed_override_keys,
        provenance_policy,
        declared_totality,
        dependency_hashes
    }

### Definition 4.10 (Batch Record) [E]

    batch_record := {
        batch_id?,
        domain_tag,
        schema_ref?,
        N,
        sampling_policy?,
        batch_hash?
    }

### Definition 4.11 (Compatibility Predicate) [E]

Compat(M_o, batch_record) holds iff manifest and batch domain/schema/preconditions agree.

### Definition 4.12 (Reference Snapshot) [E]

    R_ref := {
        reference_id?,
        policy,
        snapshot_digest,
        support_window_desc,
        created_at?,
        payload_or_pointer
    }

verify may read R_ref but MUST NOT mutate it.

### Definition 4.13 (Randomness Record) [E]

    RNG := {
        replay_class,
        bootstrap_seed?,
        alignment_seed_set?,
        backend_id?,
        numeric_profile?,
        nondeterminism_notes?
    }

where replay_class ∈ {
    BIT_EXACT,
    NUMERIC_EQUIVALENT,
    STOCHASTIC_AUDITABLE
}

### Definition 4.14 (Observer Pipeline) [E]

    o = (
        η_o,
        {A_a^o}_{a∈A},
        {Σ_a^o}_{a∈A},
        {E_ab^o}_{a≠b},
        P_base,
        M_o
    )

## 5. Check Ledgers and Evaluation Policy [E/N]

### Definition 5.1 (CheckStatus) [E]

    CheckStatus := {PASS, FAIL, NOT_EVALUATED}

### Definition 5.2 (SkipReason) [E]

    SkipReason := {
        FAIL_FAST_SHORT_CIRCUIT,
        STAGE_NOT_REACHED,
        RUNTIME_ABORT
    }

### Definition 5.3 (WitnessAtoms) [E]

    WitnessAtoms := {S3, GAUGE, SCALE, VAR, LIP}

### Definition 5.4 (VerdictAtoms) [E]

    VerdictAtoms := {THRESHOLD, CI, OOD}

### Definition 5.5 (WitnessEntry) [E]

    WitnessEntry(c) := {
        status,
        observed_value?,
        relation,
        floor_or_target?,
        evidence_ref?,
        skip_reason?
    }

### Definition 5.6 (VerdictEntry) [E]

    VerdictEntry(c) := {
        status,
        observed_value?,
        relation,
        floor_or_target?,
        evidence_ref?,
        reference_snapshot_digest?,
        skip_reason?
    }

### Definition 5.7 (WitnessLedger) [E]

    witness_ledger := {
        policy,
        order,
        first_failure?,
        S3,
        GAUGE,
        SCALE,
        VAR,
        LIP
    }

### Definition 5.8 (VerdictLedger) [E]

    verdict_ledger := {
        policy,
        order,
        first_failure?,
        THRESHOLD,
        CI,
        OOD
    }

### Definition 5.9 (Fail-Fast Witness Ledger Law) [E/N]

Under FAIL_FAST:

    first failure = FAIL,
    prior atoms = PASS,
    later atoms = NOT_EVALUATED with FAIL_FAST_SHORT_CIRCUIT.

### Definition 5.10 (Exhaustive Witness Ledger Law) [E]

Under EXHAUSTIVE and stage W reached:

    every witness atom has status ∈ {PASS, FAIL}.

### Definition 5.11 (Fail-Fast Verdict Ledger Law) [E/N]

Under FAIL_FAST:

    first failure = FAIL,
    prior atoms = PASS,
    later atoms = NOT_EVALUATED with FAIL_FAST_SHORT_CIRCUIT.

### Definition 5.12 (Exhaustive Verdict Ledger Law) [E]

Under EXHAUSTIVE and stage V reached:

    every verdict atom has status ∈ {PASS, FAIL}.

## 6. Run Classes, Truth Values, and Outcomes [E/N]

### Definition 6.1 (Status3) [E]

    Status3 := {PASS, FAIL, UNDECIDED}

### Definition 6.2 (Information Preorder on Status3) [E]

    UNDECIDED ≤_I PASS
    UNDECIDED ≤_I FAIL

PASS and FAIL are incomparable.

### Definition 6.3 (Declared Observer) [E]

Decl(o) iff o has a valid manifest M_o and base profile P_base.

### Definition 6.4 (Compatible Run) [E]

Cmp(o, D) iff Decl(o) and Compat(M_o, batch_record(D)).

### Definition 6.5 (Admissible Run) [E]

Adm(o, D, P_eff, R_ref) holds iff:

    run is compatible,
    typing is valid,
    sample and ensemble minima hold,
    required artifacts are computable,
    P_eff and R_ref are frozen,
    symmetry/profile compatibility holds,
    axis aliases remain metadata only.

### Definition 6.6 (Derived Verification Status) [E/N]

From witness_ledger:

    ver = PASS       iff all witness atoms PASS
    ver = FAIL       iff any witness atom FAIL
    ver = UNDECIDED  otherwise

### Definition 6.7 (Derived Acceptance Status) [E/N]

From verdict_ledger given ver:

    acc = PASS       iff ver = PASS and all verdict atoms PASS
    acc = FAIL       iff ver = FAIL or any verdict atom FAIL
    acc = UNDECIDED  otherwise

### Definition 6.8 (Derived Deployment Status) [E]

From acc and witness_ledger.LIP:

    dep = PASS       iff acc = PASS and w_lip ≤ τ_lip_pol
    dep = FAIL       iff acc = FAIL or (acc = PASS and w_lip > τ_lip_pol)
    dep = UNDECIDED  otherwise

Constraint:

    τ_lip_pol < 1

### Definition 6.9 (Execution Outcome) [E]

    execution := {
        status ∈ {OK, ERROR},
        error_code?,
        error_stage?,
        error_message?
    }

### Definition 6.10 (Controller Outcome) [N/E]

    controller := {
        state_sequence,
        terminal_state? ∈ {ACCEPT, REJECT, TERMINAL}
    }

### Definition 6.11 (Classification Object) [E]

    classification := {
        decl,
        cmp,
        adm,
        ver,
        acc,
        dep
    }

## 7. Controller Trace Language and Trace-Complete Materialization [E/N]

### Definition 7.1 (Canonical Trace Alphabet) [E/N]

    H = HANDSHAKE
    M = MEASURE
    W = WITNESS
    D = DIAGNOSE
    V = VERDICT
    A = ACCEPT
    R = REJECT
    T = TERMINAL

### Definition 7.2 (Legal Completed Traces) [E/N]

    τ_accept   = H → M → W → V → A
    τ_reject   = H → M → W → V → R
    τ_terminal = H → M → W → D → T

### Definition 7.3 (Legal Prefixes Under Runtime Error) [E]

If execution.status = ERROR,
controller.state_sequence MUST be a proper prefix of a legal completed trace.

### Branch Law 7.4 (Witness-Failure Branch) [E/N]

If execution.status = OK and ver = FAIL:

    terminal_state = TERMINAL

### Branch Law 7.5 (Verdict-Failure Branch) [E/N]

If execution.status = OK and ver = PASS and acc = FAIL:

    terminal_state = REJECT

### Branch Law 7.6 (Acceptance Branch) [E/N]

If execution.status = OK and acc = PASS:

    terminal_state = ACCEPT

### Definition 7.7 (Trace-Complete Materialization) [E]

Once a stage is reached, its required artifacts MUST exist.
Silent absence is forbidden.

Minimum obligations:

    after H: header, observer, batch_record, effective_profile, replay,
             execution, controller, classification
    after M: summaries, pairwise, scores, ci
    after W: witness_ledger
    after D: diagnostics, reason_codes
    after V: verdict_ledger, ood?, reason_codes
    after A/R/T: controller.terminal_state

## 8. Evidence Closure and Proof-Carrying Outcomes [E/N]

### Definition 8.1 (Verify Reason Code Families) [E]

    INPUT_NOT_WELL_FORMED
    DOMAIN_INCOMPATIBLE
    SCHEMA_MISMATCH
    OVERRIDE_NOT_ALLOWED
    BATCH_TOO_SMALL
    ENSEMBLE_TOO_SMALL
    WITNESS_S3_FAIL
    WITNESS_GAUGE_FAIL
    WITNESS_SCALE_FAIL
    WITNESS_VAR_FAIL
    WITNESS_LIP_FAIL
    THRESHOLD_FAIL
    CI_TOO_WIDE
    OOD_FAIL
    RUNTIME_ERROR
    INTERNAL_ERROR

### Definition 8.2 (Evidence Closure) [E]

Any asserted verify reason code MUST have its supporting artifacts present.

### Invariant 8.3 (Proof-Carrying Terminal Outcome) [E]

If execution.status = OK and terminal_state ∈ {REJECT, TERMINAL},
reason_codes MUST be non-empty and evidence-closed.

### Invariant 8.4 (Proof-Carrying Acceptance) [E/N]

If terminal_state = ACCEPT:

    every witness atom = PASS
    every verdict atom = PASS
    no failure reason code may be asserted

## 9. Replay Purity and Reference Evolution [E/N]

### Invariant 9.1 (Replay Purity) [E/N]

For fixed o, D, P_eff, R_ref, RNG:

    verify(o, D, P_eff, R_ref, RNG)

is observationally pure.

### Definition 9.2 (Reference Update Proposal) [E]

    U_ref := {
        base_snapshot_digest,
        proposed_snapshot_digest?,
        update_policy,
        delta_summary?,
        eligibility_condition
    }

### Operation 9.3 (Explicit Reference Commit) [E]

    commit_reference(U_ref) → R_ref_next

## 10. Triadic Closure and Episode Dynamics [E]

### Definition 10.1 (Triadic Episode) [E]

    h_t = (m_t, u_t, y_t) ∈ M × U × Y

with deterministic update:

    F : M × U × Y → M × U × Y

### Definition 10.2 (Essential Dependence) [E]

F depends essentially on omitted coordinate k relative to projection π_ij iff
projectively identical states can have divergent projected futures.

### Lemma 10.3 (Binary Non-Closure) [E]

If F depends essentially on omitted coordinate k relative to π_ij,
no deterministic F_ij exists such that

    π_ij ∘ F = F_ij ∘ π_ij

## 11. Internal Coherence Attractor [N/E]

### Definition 11.1 (Observer-Induced Update Operator) [E/N]

    T_o : S^3 → S^3

with triadic cyclic update on summaries.

### Definition 11.2 (Contraction Scalar) [N/E]

    ρ_o := L_sum^o · L_align^o · max{μ_ab}

### Theorem 11.3 (Internal Attractor) [N/E]

If ρ_o < 1,
then T_o is a contraction and converges to unique fixed point S_o^*.

## 12. Refinement and Epistemic Time [E]

### Definition 12.1 (Refinement Run) [E]

    R = { r_τ }_{τ ∈ I}

with

    r_τ = (o_τ, D_τ, P_eff,τ, R_ref,τ, B_τ)

### Definition 12.2 (Admissibility-Preserving Refinement) [E]

A refinement run is admissibility-preserving iff
Adm(o_τ, D_τ, P_eff,τ, R_ref,τ) for every τ.

### Postulate A_weak (Monotone Convergent Subsequence) [E]

There exists a convergent subsequence with non-increasing ℓ_Σ,
equivalently non-decreasing C_Σ, under fixed aggregation profile.

### Definition 12.3 (Epistemic Time) [E]

Epistemic time is the refinement-order parameter τ.
It is not a physical clock variable.

## 13. Uncertainty-Aware Comparison Safety [E/N]

### Definition 13.1 (ComparisonMode) [E]

    ComparisonMode := {
        RAW,
        PROFILE_NORMALIZED,
        REFERENCE_NORMALIZED,
        FULLY_NORMALIZED
    }

### Definition 13.2 (ScoreRelation) [E]

    ScoreRelation := {
        LEFT_HIGHER,
        RIGHT_HIGHER,
        EQUAL_WITHIN_TOL,
        UNRESOLVED_WITHIN_UNCERTAINTY,
        INCOMPARABLE
    }

Interpretation:

    LEFT_HIGHER / RIGHT_HIGHER
        Ordering certified under declared mode.

    EQUAL_WITHIN_TOL
        Equality certified within tolerance band.

    UNRESOLVED_WITHIN_UNCERTAINTY
        Pair is comparable, but current uncertainty envelope does not certify
        order or equality.

    INCOMPARABLE
        Comparison contract itself failed.

### Definition 13.3 (CompareTolerance) [E]

    T_cmp := {
        delta_eq,
        numeric_tol?,
        target_confidence_level?
    }

with:

    delta_eq > 0

Interpretation:

    delta_eq defines the equivalence band around zero.

### Definition 13.4 (ComparisonAtoms) [E]

    ComparisonAtoms := {
        SAME_BATCH,
        SCORES_AVAILABLE,
        INTERVALS_AVAILABLE,
        EVIDENCE_CLOSED,
        PROFILE_EQ,
        REFERENCE_EQ,
        POLICY_EQ,
        RNG_COMPAT,
        NORMALIZER_VALID
    }

### Definition 13.5 (CompareCheckStatus) [E]

    CompareCheckStatus := {PASS, FAIL, NOT_APPLICABLE}

### Definition 13.6 (CompareEntry) [E]

    CompareEntry(a) := {
        status,
        left_value?,
        right_value?,
        evidence_ref?,
        note?
    }

### Definition 13.7 (Comparison Normalizer) [E]

A comparison normalizer is

    N_cmp := {
        normalizer_id,
        normalizer_version,
        covers,
        target_profile_digest?,
        target_reference_regime?,
        target_confidence_level?,
        map_spec,
        interval_map_spec,
        monotonicity_claim?,
        error_bound,
        proof_ref?
    }

where:

    covers ⊆ {PROFILE_EQ, REFERENCE_EQ, POLICY_EQ, RNG_COMPAT}

Normative rule:

    If mode ≠ RAW, the normalizer MUST induce comparison intervals
    in the target comparison space.

### Definition 13.8 (Comparability Ledger) [E]

    comparability_ledger := {
        mode,
        required_passes,
        SAME_BATCH,
        SCORES_AVAILABLE,
        INTERVALS_AVAILABLE,
        EVIDENCE_CLOSED,
        PROFILE_EQ,
        REFERENCE_EQ,
        POLICY_EQ,
        RNG_COMPAT,
        NORMALIZER_VALID,
        failing_atoms?
    }

### Definition 13.9 (Atomic Comparison Checks) [E]

SAME_BATCH = PASS iff:

    either batch hashes match,
    or both sides lack batch hashes but agree on batch_id/domain/schema/N.

SCORES_AVAILABLE = PASS iff:

    both bundles contain scores.C_Σ and axis scores.

INTERVALS_AVAILABLE = PASS iff:

    both bundles contain score intervals usable in comparison space.

EVIDENCE_CLOSED = PASS iff:

    both bundles are trace-complete and proof-carrying up to the compared stage.

PROFILE_EQ = PASS iff:

    effective profile digests match.

REFERENCE_EQ = PASS iff:

    if OOD is used on either side, reference snapshot digests match;
    else NOT_APPLICABLE.

POLICY_EQ = PASS iff:

    symmetry mode, witness/verdict policies, and witness/verdict orders match.

RNG_COMPAT = PASS iff:

    replay classes match and numeric profiles are compatible.

NORMALIZER_VALID = PASS iff:

    mode ≠ RAW,
    N_cmp is present,
    every mismatch the comparison intends to normalize lies in N_cmp.covers,
    interval_map_spec exists,
    error_bound is declared,
    and proof_ref or equivalent validation evidence is present.

In RAW mode:

    NORMALIZER_VALID = NOT_APPLICABLE.

### Definition 13.10 (Required Pass Set by Mode) [E]

Req(RAW)
    =
    {SAME_BATCH, SCORES_AVAILABLE, INTERVALS_AVAILABLE, EVIDENCE_CLOSED,
     PROFILE_EQ, POLICY_EQ, RNG_COMPAT}
    ∪ {REFERENCE_EQ if REFERENCE_EQ ≠ NOT_APPLICABLE}

Req(PROFILE_NORMALIZED)
    =
    {SAME_BATCH, SCORES_AVAILABLE, INTERVALS_AVAILABLE, EVIDENCE_CLOSED,
     POLICY_EQ, RNG_COMPAT, NORMALIZER_VALID}
    ∪ {REFERENCE_EQ if REFERENCE_EQ ≠ NOT_APPLICABLE}

Req(REFERENCE_NORMALIZED)
    =
    {SAME_BATCH, SCORES_AVAILABLE, INTERVALS_AVAILABLE, EVIDENCE_CLOSED,
     PROFILE_EQ, POLICY_EQ, RNG_COMPAT, NORMALIZER_VALID}

Req(FULLY_NORMALIZED)
    =
    {SAME_BATCH, SCORES_AVAILABLE, INTERVALS_AVAILABLE, EVIDENCE_CLOSED,
     NORMALIZER_VALID}

Any failed atom outside N_cmp.covers blocks comparability.

### Definition 13.11 (Comparable Pair) [E]

(B_L, B_R) is comparable under mode iff:

    every atom in Req(mode) has status = PASS

and

    no failed atom outside N_cmp.covers is ignored.

### Definition 13.12 (Comparison Interval Object) [E]

A comparison interval is

    I_cmp := {
        lo,
        hi,
        level?,
        basis,
        error_budget?
    }

where:

    basis ∈ {
        RAW_CI,
        NORMALIZED_INTERVAL
    }

Normative rule:

    lo ≤ hi

### Definition 13.13 (Effective Comparison Intervals) [E]

If mode = RAW:

    I_L := {
        lo    = left.ci.CI_lo,
        hi    = left.ci.CI_hi,
        level = left.ci.method_level?,
        basis = RAW_CI
    }

    I_R := {
        lo    = right.ci.CI_lo,
        hi    = right.ci.CI_hi,
        level = right.ci.method_level?,
        basis = RAW_CI
    }

If mode ≠ RAW:

    N_cmp MUST induce

        I_L^N, I_R^N

    in the target comparison space, each with declared basis and error_budget.

### Definition 13.14 (Delta Interval) [E]

Given effective comparison intervals I_L and I_R, define

    Δ_cmp := {
        lo = I_L.lo − I_R.hi,
        hi = I_L.hi − I_R.lo
    }

Interpretation:

    Δ_cmp is the conservative uncertainty envelope for left-minus-right.

### Definition 13.15 (Comparison Metrics) [E]

    comparison_metrics := {
        left_point,
        right_point,
        left_interval,
        right_interval,
        delta_point,
        delta_interval,
        delta_axis_scores?,
        delta_axis_leverage?,
        tolerance
    }

where:

    delta_point = left_point − right_point
    delta_interval = Δ_cmp

### Definition 13.16 (Derived Score Relation) [E]

If the pair is not comparable:

    score_relation = INCOMPARABLE

Else if Δ_cmp.lo > delta_eq:

    score_relation = LEFT_HIGHER

Else if Δ_cmp.hi < −delta_eq:

    score_relation = RIGHT_HIGHER

Else if −delta_eq ≤ Δ_cmp.lo and Δ_cmp.hi ≤ delta_eq:

    score_relation = EQUAL_WITHIN_TOL

Else:

    score_relation = UNRESOLVED_WITHIN_UNCERTAINTY

### Definition 13.17 (Comparison Explanation) [E]

    comparison_explanation := {
        basis,
        dominant_axis?,
        dominant_constraint?,
        terminal_pattern,
        uncertainty_driver?,
        note?
    }

where:

    basis ∈ {RAW, NORMALIZED}

    dominant_axis
        = argmax_a |delta_axis_leverage[a]|
          if delta_axis_leverage is available

    dominant_constraint
        = first failing witness atom,
          or first failing verdict atom,
          or null

    terminal_pattern
        = (left.controller.terminal_state?, right.controller.terminal_state?)

    uncertainty_driver ∈ {
        LEFT_INTERVAL_WIDTH,
        RIGHT_INTERVAL_WIDTH,
        NORMALIZER_ERROR,
        MIXED,
        NONE
    }

Interpretation:

    Explanation is descriptive.
    It never overrides score_relation.

## 14. Canonical Abstract Operations [E]

### Operation OD-1

    describe_observer(o) → M_o

### Operation OD-2

    verify(o, D, P_base_or_ref?, ΔP?, R_ref?, RNG?) → VerifyResponse

Semantics:

    verify is replay-pure and proof-carrying.

### Operation OD-3

    commit_reference(U_ref) → R_ref_next

### Operation OD-4

    refine(R, budget?, objective?) → ProposalSet

### Operation OD-5

    compare(B_left, B_right, mode, N_cmp?, T_cmp?) → CompareResponse

Semantics:

    compare is comparison-safe and uncertainty-aware.
    It MUST return:
        comparability_ledger
        comparison_metrics if relation ≠ INCOMPARABLE
        score_relation
        reason_codes
    It MUST NOT emit LEFT_HIGHER, RIGHT_HIGHER, or EQUAL_WITHIN_TOL
    unless the relation is certified by Definition 13.16.

## 15. Canonical Verify Contract [E]

### Definition 15.1 (VerifyRequest) [E]

    VerifyRequest := {
        spec_name,
        spec_version,
        observer_manifest,
        base_profile?,
        override_set?,
        batch,
        reference_snapshot?,
        randomness_record?,
        provenance_policy_override?
    }

### Definition 15.2 (VerifyResponse) [E]

    VerifyResponse := {
        header,
        observer,
        batch_record,
        effective_profile,
        replay,
        execution,
        controller,
        classification,
        summaries?,
        pairwise?,
        scores?,
        diagnostics?,
        witness_ledger?,
        verdict_ledger?,
        ci?,
        ood?,
        reference_update_proposal?,
        provenance?,
        reason_codes
    }

## 16. Canonical Compare Contract [E]

### Definition 16.1 (CompareRequest) [E]

    CompareRequest := {
        spec_name,
        spec_version,
        left_bundle,
        right_bundle,
        mode,
        normalizer?,
        tolerance?,
        provenance_policy_override?
    }

### Definition 16.2 (CompareResponse) [E]

    CompareResponse := {
        header,
        left_ref,
        right_ref,
        mode,
        normalizer?,
        comparability_ledger,
        comparison_metrics?,
        score_relation,
        comparison_explanation?,
        reason_codes,
        provenance?
    }

### Definition 16.3 (Comparison Reason Codes) [E]

Reason codes SHOULD be drawn from:

    BATCH_MISMATCH
    SCORES_MISSING
    INTERVALS_MISSING
    EVIDENCE_NOT_CLOSED
    PROFILE_MISMATCH
    REFERENCE_MISMATCH
    POLICY_MISMATCH
    RNG_MISMATCH
    NORMALIZER_MISSING
    NORMALIZER_SCOPE_INVALID
    NORMALIZER_PROOF_MISSING
    NORMALIZER_INTERVAL_INVALID
    COMPARE_UNCERTAINTY_OVERLAP
    COMPARE_INSUFFICIENT_EVIDENCE

### Definition 16.4 (Comparison Evidence Closure) [E]

A comparison reason code is evidence-closed iff the corresponding failed atom
or unresolved interval condition is present and replayable.

Examples:

    BATCH_MISMATCH
        → SAME_BATCH.status = FAIL

    SCORES_MISSING
        → SCORES_AVAILABLE.status = FAIL

    INTERVALS_MISSING
        → INTERVALS_AVAILABLE.status = FAIL

    PROFILE_MISMATCH
        → PROFILE_EQ.status = FAIL

    REFERENCE_MISMATCH
        → REFERENCE_EQ.status = FAIL

    POLICY_MISMATCH
        → POLICY_EQ.status = FAIL

    RNG_MISMATCH
        → RNG_COMPAT.status = FAIL

    NORMALIZER_SCOPE_INVALID or NORMALIZER_PROOF_MISSING or NORMALIZER_INTERVAL_INVALID
        → NORMALIZER_VALID.status = FAIL

    COMPARE_UNCERTAINTY_OVERLAP
        → score_relation = UNRESOLVED_WITHIN_UNCERTAINTY
          and comparison_metrics.delta_interval present

## 17. Verify Invariants [E/N]

**Invariant V0:**

    If π ∈ S₃ and scores are present:

        C_Σ(s; W) = C_Σ(π · s; π · W)

**Invariant V1:**

    If aggregation_profile ≠ W_uniform,
    then symmetry_mode = COVARIANT.

**Invariant V2:**

    classification.ver is derived from witness_ledger when present.

**Invariant V3:**

    classification.acc is derived from verdict_ledger when present.

**Invariant V4:**

    classification.dep is derived from lip evidence and τ_lip_pol when present.

**Invariant V5:**

    If execution.status = OK and ver = FAIL,
    then terminal_state = TERMINAL.

**Invariant V6:**

    If execution.status = OK and ver = PASS and acc = FAIL,
    then terminal_state = REJECT.

**Invariant V7:**

    If execution.status = OK and acc = PASS,
    then terminal_state = ACCEPT.

**Invariant V8:**

    verify response MUST be trace-complete.

**Invariant V9:**

    Every asserted verify reason code MUST be evidence-closed.

**Invariant V10:**

    If replay_class ≠ BIT_EXACT,
    nondeterminism source MUST be recorded.

**Invariant V11:**

    verify MUST NOT mutate reference state.

## 18. Compare Invariants [E/N]

**Invariant C0:**

    If mode = RAW,
    then NORMALIZER_VALID.status = NOT_APPLICABLE.

**Invariant C1:**

    If score_relation ≠ INCOMPARABLE,
    then every atom in Req(mode) has status = PASS.

**Invariant C2:**

    If score_relation ∈ {
        LEFT_HIGHER,
        RIGHT_HIGHER,
        EQUAL_WITHIN_TOL,
        UNRESOLVED_WITHIN_UNCERTAINTY
    },
    then comparison_metrics MUST be present
    and left_interval, right_interval, delta_interval MUST be present.

**Invariant C3:**

    If mode ≠ RAW and score_relation ≠ INCOMPARABLE,
    then normalizer MUST be present
    and NORMALIZER_VALID.status = PASS.

**Invariant C4:**

    If any failed comparison atom lies outside N_cmp.covers,
    then score_relation = INCOMPARABLE.

**Invariant C5:**

    If score_relation = LEFT_HIGHER,
    then delta_interval.lo > delta_eq.

**Invariant C6:**

    If score_relation = RIGHT_HIGHER,
    then delta_interval.hi < −delta_eq.

**Invariant C7:**

    If score_relation = EQUAL_WITHIN_TOL,
    then −delta_eq ≤ delta_interval.lo
         and delta_interval.hi ≤ delta_eq.

**Invariant C8:**

    If score_relation = UNRESOLVED_WITHIN_UNCERTAINTY,
    then:
        pair is comparable
        and not(C5)
        and not(C6)
        and not(C7).

**Invariant C9:**

    If score_relation = INCOMPARABLE,
    then reason_codes MUST be non-empty.

**Invariant C10:**

    If score_relation = UNRESOLVED_WITHIN_UNCERTAINTY,
    then reason_codes MUST be non-empty
    and SHOULD include COMPARE_UNCERTAINTY_OVERLAP.

**Invariant C11:**

    Every asserted comparison reason code MUST be evidence-closed.

**Invariant C12:**

    No implementation may emit LEFT_HIGHER, RIGHT_HIGHER,
    or EQUAL_WITHIN_TOL in RAW mode when SAME_BATCH = FAIL
    or PROFILE_EQ = FAIL
    or POLICY_EQ = FAIL.

**Invariant C13:**

    If delta_axis_leverage is present,
    then dominant_axis MUST equal argmax_a |delta_axis_leverage[a]|.

**Invariant C14:**

    compare MUST NOT mutate either input bundle or any referenced snapshot.

## 19. Provenance Minimum [E/N]

Every verify response MUST record at least:

    observer_id
    observer_version
    batch size N
    domain tag
    effective profile digest
    aggregation profile
    symmetry mode
    witness evaluation policy
    verdict evaluation policy
    witness order
    verdict order
    witness floors
    CI level
    N_boot
    OOD policy
    reference snapshot digest if OOD is used
    randomness record
    controller state sequence
    timestamp

Every CompareResponse MUST record at least:

    left bundle identifier or digest
    right bundle identifier or digest
    mode
    required pass set
    comparability ledger
    tolerance
    score_relation
    comparison intervals
    interval basis
    target confidence level if normalized
    normalizer identifier/version/covers if used
    normalizer error bound if used
    timestamp

If score_relation = UNRESOLVED_WITHIN_UNCERTAINTY,
the uncertainty driver SHOULD be recorded.

## 20. Self-Application [E]

### Definition 20.1 (Bundle Domain Lift) [E]

Let Bundle be the set of canonical VerifyResponses.
Define:

    X_meta := Bundle

### Definition 20.2 (Meta-Observer) [E]

A meta-observer is an observer over X_meta subject to the same rules:

    same freezing,
    same symmetry discipline,
    same replay purity,
    same ledgers,
    same uncertainty-aware comparison semantics.

### Proposition 20.3 (Finite Termination of Self-Application) [E]

If D_meta is finite and the meta-observer is an admissible finite pipeline,
self-application terminates after finite execution steps.

## 21. External Hypotheses Boundary [C]

Outside scope:

    physical-time identification with epistemic time
    thermodynamic dissipation laws
    gravitational geometrization
    metaphysical necessity of triadicity

## 22. Final Position

TSC Observation Dynamics v1.0.9 is the uncertainty-aware, comparison-safe observation-layer specification of TSC.

Its decisive moves are:

    comparison now consumes intervals, not just point scores,
    comparability is separated from resolvability,
    unresolved overlap is no longer confused with mismatch,
    normalized order claims require interval-producing normalizers,
    and every comparison claim is certified against a conservative delta envelope.

That is stricter than v1.0.8.
That is more honest about uncertainty.
That is better for SDKs.
That is kinder to AI readers.
That is the next clean step.
