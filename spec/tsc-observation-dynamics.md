# TSC Observation Dynamics v1.0.8

Formal Specification of Observer Construction, Verification, Epistemic Refinement, and Comparison-Safe Evaluation

    Version:    v1.0.8
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
    how symmetry is tested under weighted aggregation,
    how verification remains replay-pure and proof-carrying,
    and how cross-observer comparison becomes comparison-safe.

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
proof-carrying, and comparison-safe.

## 1. Status Discipline

    [N]  inherited normative basis
    [E]  formal extension compatible with inherited TSC basis
    [C]  external conjecture or interpretation

Normative reading rule:

    Nothing marked [E] or [C] may be cited as if it were already proven by [N].

## 2. Change Log

### From v1.0.7

    CMP-02  ComparisonMode introduced:
                RAW
                PROFILE_NORMALIZED
                REFERENCE_NORMALIZED
                FULLY_NORMALIZED

    CMP-03  ComparabilityLedger introduced.
            Compare is now proof-carrying, not heuristic.

    CMP-04  Raw comparability and normalized comparability are separated.
            Cross-observer ranking claims require explicit comparability evidence.

    NRM-02  Comparison normalizer N_cmp introduced with declared coverage scope,
            monotonicity claim, and error bound.

    REL-01  ScoreRelation introduced:
                LEFT_HIGHER
                RIGHT_HIGHER
                EQUAL_WITHIN_TOL
                INCOMPARABLE

    EVD-04  No false parity claims.
            A non-INCOMPARABLE relation cannot be asserted unless the
            required comparability checks pass.

    EXP-01  ComparisonExplanation object introduced.
            Comparative outputs can now state the dominant axis gap,
            branch pattern, and binding constraint explicitly.

    PRV-02  Comparison provenance minimum added.

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

Examples:

    dimensional scores
    dimensional leverages
    axis sensitivities
    aggregation weights
    axis-specific calibration maps

### Definition 3.3 (Permutation Action) [E]

For any π ∈ S₃ and any axis-indexed object q, define

    (π · q)_a := q_{π⁻¹(a)}.

For any compound object P with axis-indexed computational subfields,
π acts by permuting those subfields and leaving scalar/global fields unchanged.

### Definition 3.4 (SymmetryMode) [E]

    SymmetryMode := {ABSOLUTE, COVARIANT}

Interpretation:

    ABSOLUTE:
        Permute observed axis-material, hold effective profile fixed.

    COVARIANT:
        Permute observed axis-material and co-permute all
        computationally relevant axis-indexed profile fields.

### Definition 3.5 (Aggregation Profile) [N/E]

An aggregation profile is an axis-indexed weight triple

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
numerical floor ε, and aggregation profile W, define

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

Hence aggregate coherence is permutation-covariant in (s, W).

Corollary:

    If W = W_uniform, then C_Σ is absolutely S₃-invariant in s alone.

### Definition 3.9 (Effective Symmetry Profile) [E]

Let P_eff be the frozen effective profile.
Its computationally relevant axis-indexed subfields are denoted

    P_eff^axis

and include at least:

    μ_axis
    aggregation_profile
    any axis-specific calibration maps
    any axis-specific numerical policies used in score construction

Metadata-only fields, including axis aliases, are excluded.

### Definition 3.10 (W1 Symmetry Witness Under Mode) [E]

Let O = (O_alpha, O_beta, O_gamma) denote axis-material after articulation.

If symmetry_mode = ABSOLUTE, define

    w_S3
      :=
    max_{π ∈ S₃} | C_Σ(O; P_eff) − C_Σ(π · O; P_eff) |

If symmetry_mode = COVARIANT, define

    w_S3
      :=
    max_{π ∈ S₃} | C_Σ(O; P_eff) − C_Σ(π · O; π · P_eff^axis) |

### Admissibility Rule 3.11 (Symmetry/Profile Compatibility) [E]

If aggregation_profile ≠ W_uniform,
then symmetry_mode MUST equal COVARIANT.

If aggregation_profile = W_uniform,
then either symmetry mode is allowed,
but ABSOLUTE is the canonical default.

### Proposition 3.12 (Mode Collapse in Uniform Case) [E]

If aggregation_profile = W_uniform
and all other computationally relevant axis-indexed fields of P_eff are uniform,
then ABSOLUTE and COVARIANT W1 evaluations coincide.

## 4. Observation Objects, Profiles, and Freezing Discipline [E]

### Definition 4.1 (Observation Domain) [E]

Let X be the declared domain of the phenomenon under observation.

### Definition 4.2 (Observation Batch) [E]

An observation batch is a finite sequence

    D = (x_1, …, x_N) ∈ X*

with

    N = |D|.

### Definition 4.3 (EvaluationPolicy) [E]

    EvaluationPolicy := {FAIL_FAST, EXHAUSTIVE}

### Definition 4.4 (WitnessOrder) [E]

    WitnessOrder_default := [S3, GAUGE, SCALE, VAR, LIP]

### Definition 4.5 (VerdictOrder) [E]

    VerdictOrder_default := [THRESHOLD, CI, OOD]

### Definition 4.6 (BaseProfile) [E]

Every observer design carries a base profile

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

An override set is a partial object

    ΔP := { any subset of legal P_base fields }

Override rule:

    Overrides are permitted only if declared legal by the observer manifest.

### Definition 4.8 (EffectiveProfile) [E]

The effective profile is

    P_eff := freeze(merge(P_base, ΔP))

Normative rule:

    All scoring, witness evaluation, verdict evaluation,
    CI evaluation, OOD evaluation, and classification derivation
    MUST use P_eff.

### Definition 4.9 (Observer Manifest) [E]

Every observer MUST admit a serializable manifest

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

Compat(M_o, batch_record) holds iff:

    (i)   domain tags are equal or explicitly declared compatible
    (ii)  schema constraints, if present, are satisfied
    (iii) declared_totality covers the batch domain
    (iv)  manifest-level preconditions on N or sampling are satisfied

### Definition 4.12 (Reference Snapshot) [E]

    R_ref := {
        reference_id?,
        policy,
        snapshot_digest,
        support_window_desc,
        created_at?,
        payload_or_pointer
    }

Normative rule:

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

where

    replay_class ∈ {
        BIT_EXACT,
        NUMERIC_EQUIVALENT,
        STOCHASTIC_AUDITABLE
    }

### Definition 4.14 (Observer Pipeline) [E]

An observer is a typed pipeline

    o = (
        η_o,
        {A_a^o}_{a∈A},
        {Σ_a^o}_{a∈A},
        {E_ab^o}_{a≠b},
        P_base,
        M_o
    )

where:

    η_o       : X* → T                encoder (domain → carrier)
    A_a^o     : T → P(Ω_a^o)          articulator per axis
    Σ_a^o     : P(Ω_a^o) → S_a^o      summarizer per axis
    E_ab^o    = {σ_ab^1, …, σ_ab^m}   alignment ensemble, m ≥ 3

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

Normative rule:

    If status ∈ {PASS, FAIL}, then observed_value MUST be present.
    If status = NOT_EVALUATED, then skip_reason MUST be present.

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

Normative rule:

    If status ∈ {PASS, FAIL}, then observed_value MUST be present.
    If status = NOT_EVALUATED, then skip_reason MUST be present.

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

If witness_ledger.policy = FAIL_FAST
and first_failure = c,
then:

    (i)   every atom strictly before c has status = PASS
    (ii)  c has status = FAIL
    (iii) every atom strictly after c has status = NOT_EVALUATED
          with skip_reason = FAIL_FAST_SHORT_CIRCUIT

### Definition 5.10 (Exhaustive Witness Ledger Law) [E]

If witness_ledger.policy = EXHAUSTIVE
and stage W has been reached,
then every witness atom has status ∈ {PASS, FAIL}.

### Definition 5.11 (Fail-Fast Verdict Ledger Law) [E/N]

If verdict_ledger.policy = FAIL_FAST
and first_failure = c,
then:

    (i)   every atom strictly before c has status = PASS
    (ii)  c has status = FAIL
    (iii) every atom strictly after c has status = NOT_EVALUATED
          with skip_reason = FAIL_FAST_SHORT_CIRCUIT

### Definition 5.12 (Exhaustive Verdict Ledger Law) [E]

If verdict_ledger.policy = EXHAUSTIVE
and stage V has been reached,
then every verdict atom has status ∈ {PASS, FAIL}.

## 6. Run Classes, Truth Values, and Outcomes [E/N]

### Definition 6.1 (Status3) [E]

    Status3 := {PASS, FAIL, UNDECIDED}

### Definition 6.2 (Information Preorder on Status3) [E]

    UNDECIDED ≤_I PASS
    UNDECIDED ≤_I FAIL

PASS and FAIL are incomparable.

### Definition 6.3 (Declared Observer) [E]

Decl(o) holds iff:

    observer o has a valid manifest M_o and base profile P_base.

### Definition 6.4 (Compatible Run) [E]

Cmp(o, D) holds iff:

    Decl(o) and Compat(M_o, batch_record(D)).

### Definition 6.5 (Admissible Run) [E]

Adm(o, D, P_eff, R_ref) holds iff:

    (i)    Cmp(o, D)
    (ii)   η_o, A_a^o, Σ_a^o are well-typed
    (iii)  |D| ≥ N_min
    (iv)   |E_ab^o| ≥ 3 for each required pair
    (v)    required artifacts are computable in principle
    (vi)   P_eff is frozen before final scoring
    (vii)  R_ref is frozen before OOD evaluation
    (viii) symmetry/profile compatibility rule 3.11 holds
    (ix)   axis aliases, if present, are metadata only

### Definition 6.6 (Derived Verification Status) [E/N]

If witness_ledger is present, define:

    ver = PASS
        iff every witness atom has status = PASS

    ver = FAIL
        iff at least one witness atom has status = FAIL

    ver = UNDECIDED
        iff no witness atom has status = FAIL
        and at least one witness atom has status = NOT_EVALUATED

If witness_ledger is absent:

    ver = UNDECIDED unless admissibility has already failed.

### Definition 6.7 (Derived Acceptance Status) [E/N]

If ver = FAIL:

    acc = FAIL

Else if verdict_ledger is present, define:

    acc = PASS
        iff ver = PASS
        and every verdict atom has status = PASS

    acc = FAIL
        iff ver = PASS
        and at least one verdict atom has status = FAIL

    acc = UNDECIDED
        iff ver = PASS
        and no verdict atom has status = FAIL
        and at least one verdict atom has status = NOT_EVALUATED

If verdict_ledger is absent and ver ≠ FAIL:

    acc = UNDECIDED

### Definition 6.8 (Derived Deployment Status) [E]

Let lip_entry := witness_ledger.LIP if witness_ledger is present.

Define:

    dep = PASS
        iff acc = PASS
        and lip_entry.status = PASS
        and lip_entry.observed_value ≤ τ_lip_pol

    dep = FAIL
        iff acc = FAIL
        or (acc = PASS and lip_entry.status = PASS and lip_entry.observed_value > τ_lip_pol)

    dep = UNDECIDED
        otherwise

Constraint:

    τ_lip_pol < 1

### Definition 6.9 (Execution Outcome) [E]

    ExecStatus := {OK, ERROR}

    execution := {
        status,
        error_code?,
        error_stage?,
        error_message?
    }

### Definition 6.10 (Controller Outcome) [N/E]

    CtrlTerminal := {ACCEPT, REJECT, TERMINAL}

    controller := {
        state_sequence,
        terminal_state?
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

### Invariant 6.12 (Implication Chain) [E]

    dep = PASS ⟹ acc = PASS ⟹ ver = PASS ⟹ adm = PASS ⟹ cmp = PASS ⟹ decl = PASS

### Invariant 6.13 (Information Monotonicity) [E]

Along a single realized verify run, each classification field is monotone under ≤_I.

### Invariant 6.14 (Execution / Controller Separation) [E]

Runtime failure MUST NOT be encoded as a controller terminal state.

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

The legal completed traces are exactly:

    τ_accept   = H → M → W → V → A
    τ_reject   = H → M → W → V → R
    τ_terminal = H → M → W → D → T

### Definition 7.3 (Legal Prefixes Under Runtime Error) [E]

If execution.status = ERROR,
then controller.state_sequence MUST be a proper prefix of one of the legal completed traces.

### Branch Law 7.4 (Witness-Failure Branch) [E/N]

If execution.status = OK and ver = FAIL, then:

    controller.state_sequence = τ_terminal
    controller.terminal_state = TERMINAL

### Branch Law 7.5 (Verdict-Failure Branch) [E/N]

If execution.status = OK and ver = PASS and acc = FAIL, then:

    controller.state_sequence = τ_reject
    controller.terminal_state = REJECT

### Branch Law 7.6 (Acceptance Branch) [E/N]

If execution.status = OK and acc = PASS, then:

    controller.state_sequence = τ_accept
    controller.terminal_state = ACCEPT

### Definition 7.7 (Trace-Complete Materialization) [E]

A verify response is trace-complete iff the fields required by the realized
controller prefix are present.

Minimum obligations by last reached state:

    after H:
        header
        observer
        batch_record
        effective_profile
        replay
        execution
        controller
        classification

    after M:
        all H fields
        summaries
        pairwise
        scores
        ci

    after W:
        all M fields
        witness_ledger

    after D:
        all W fields
        diagnostics
        reason_codes

    after V:
        all W fields
        verdict_ledger
        ood?
        reason_codes

    after A or R or T:
        all fields required by the predecessor state
        controller.terminal_state

Silent absence is forbidden once a stage is reached.

## 8. Evidence Closure and Proof-Carrying Outcomes [E/N]

### Definition 8.1 (Reason Code Families) [E]

Reason codes SHOULD be drawn from:

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

A reason code is evidence-closed iff its supporting artifacts are present.

### Invariant 8.3 (Proof-Carrying Terminal Outcome) [E]

If execution.status = OK and controller.terminal_state ∈ {REJECT, TERMINAL},
then:

    reason_codes MUST be non-empty
    and every asserted reason code MUST be evidence-closed.

### Invariant 8.4 (Proof-Carrying Acceptance) [E/N]

If controller.terminal_state = ACCEPT, then:

    (i)   every witness atom has status = PASS
    (ii)  every verdict atom has status = PASS
    (iii) no failure reason code may be asserted

## 9. Replay Purity and Reference Evolution [E/N]

### Invariant 9.1 (Replay Purity) [E/N]

For fixed

    o, D, P_eff, R_ref, RNG

the operation

    verify(o, D, P_eff, R_ref, RNG)

is observationally pure:

    it returns a bundle,
    but does not mutate hidden reference state.

### Definition 9.2 (Reference Update Proposal) [E]

    U_ref := {
        base_snapshot_digest,
        proposed_snapshot_digest?,
        update_policy,
        delta_summary?,
        eligibility_condition
    }

Verification MAY emit U_ref,
but proposal emission is not state mutation.

### Operation 9.3 (Explicit Reference Commit) [E]

    commit_reference(U_ref) → R_ref_next

## 10. Triadic Closure and Episode Dynamics [E]

### Definition 10.1 (Triadic Episode) [E]

    h_t = (m_t, u_t, y_t) ∈ M × U × Y

with deterministic update:

    F : M × U × Y → M × U × Y

### Definition 10.2 (Essential Dependence) [E]

F depends essentially on omitted coordinate k relative to projection π_ij iff
there exist z, z' such that

    π_ij(z) = π_ij(z')
but
    π_ij(F(z)) ≠ π_ij(F(z'))

### Lemma 10.3 (Binary Non-Closure) [E]

If F depends essentially on omitted coordinate k relative to π_ij,
then there does not exist deterministic F_ij such that

    π_ij ∘ F = F_ij ∘ π_ij

### Corollary 10.4 (Auxiliary-State Requirement) [E]

A genuinely triadic episode cannot in general be reduced to a closed binary
dynamics without adding hidden state or memory.

## 11. Internal Coherence Attractor [N/E]

### Definition 11.1 (Observer-Induced Update Operator) [E/N]

For a fixed observer o, define

    T_o : S^3 → S^3

by

    T_o(S_alpha, S_beta, S_gamma)
      =
    (
      T_alpha^o(S_beta, S_gamma),
      T_beta^o(S_gamma, S_alpha),
      T_gamma^o(S_alpha, S_beta)
    )

### Definition 11.2 (Contraction Scalar) [N/E]

    ρ_o := L_sum^o · L_align^o · max{μ_ab}

### Theorem 11.3 (Internal Attractor) [N/E]

If

    ρ_o < 1,

then T_o is a contraction on S^3 and for every initial triple S^(0),

    S^(n+1) = T_o(S^(n))

converges to a unique fixed point

    S_o^*.

## 12. Refinement and Epistemic Time [E]

### Definition 12.1 (Refinement Run) [E]

    R = { r_τ }_{τ ∈ I}

with

    r_τ = (o_τ, D_τ, P_eff,τ, R_ref,τ, B_τ)

### Definition 12.2 (Admissibility-Preserving Refinement) [E]

A refinement run is admissibility-preserving iff

    Adm(o_τ, D_τ, P_eff,τ, R_ref,τ)

for every τ ∈ I.

### Postulate A_weak (Monotone Convergent Subsequence) [E]

Along an admissibility-preserving refinement run,
there exists a convergent subsequence {r_{τ_k}} such that,
under fixed aggregation profile,

    ℓ_Σ(B_{τ_{k+1}}) ≤ ℓ_Σ(B_{τ_k})

equivalently,

    C_Σ(B_{τ_{k+1}}) ≥ C_Σ(B_{τ_k})

### Definition 12.3 (Epistemic Time) [E]

Epistemic time is the refinement-order parameter τ.
It orders observer-runs.
It is not a physical clock variable.

## 13. Comparison Safety [E/N]

### Definition 13.1 (ComparisonMode) [E]

    ComparisonMode := {
        RAW,
        PROFILE_NORMALIZED,
        REFERENCE_NORMALIZED,
        FULLY_NORMALIZED
    }

Interpretation:

    RAW:
        Compare bundles without normalization.

    PROFILE_NORMALIZED:
        Normalize profile differences, hold reference regime fixed.

    REFERENCE_NORMALIZED:
        Normalize reference-regime differences, hold profile fixed.

    FULLY_NORMALIZED:
        Normalize all declared differences covered by N_cmp.

### Definition 13.2 (ScoreRelation) [E]

    ScoreRelation := {
        LEFT_HIGHER,
        RIGHT_HIGHER,
        EQUAL_WITHIN_TOL,
        INCOMPARABLE
    }

### Definition 13.3 (CompareTolerance) [E]

    T_cmp := {
        delta_eq,
        numeric_tol?
    }

with:

    delta_eq > 0

### Definition 13.4 (ComparisonAtoms) [E]

    ComparisonAtoms := {
        SAME_BATCH,
        SCORES_AVAILABLE,
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

Normative rule:

    If status ∈ {PASS, FAIL}, the supporting evidence MUST be replayable.
    If status = NOT_APPLICABLE, the reason MUST be clear from mode or artifact structure.

### Definition 13.7 (Comparison Normalizer) [E]

A comparison normalizer is

    N_cmp := {
        normalizer_id,
        normalizer_version,
        covers,
        target_profile_digest?,
        target_reference_regime?,
        map_spec,
        monotonicity_claim?,
        error_bound,
        proof_ref?
    }

where:

    covers ⊆ {PROFILE_EQ, REFERENCE_EQ, POLICY_EQ, RNG_COMPAT}

Interpretation:

    N_cmp declares exactly which kinds of mismatch it is allowed to normalize.

### Definition 13.8 (Comparability Ledger) [E]

    comparability_ledger := {
        mode,
        required_passes,
        SAME_BATCH,
        SCORES_AVAILABLE,
        EVIDENCE_CLOSED,
        PROFILE_EQ,
        REFERENCE_EQ,
        POLICY_EQ,
        RNG_COMPAT,
        NORMALIZER_VALID,
        failing_atoms?
    }

### Definition 13.9 (Atomic Comparison Checks) [E]

SAME_BATCH = PASS iff one of the following holds:

    (i)   left.batch_record.batch_hash = right.batch_record.batch_hash
    (ii)  batch_hash is absent on both sides, but
          batch_id, domain_tag, schema_ref, and N all agree

Otherwise:

    SAME_BATCH = FAIL

SCORES_AVAILABLE = PASS iff:

    both bundles contain scores.C_Σ and axis scores

EVIDENCE_CLOSED = PASS iff:

    both bundles are trace-complete with respect to their realized controller traces
    and satisfy proof-carrying outcome constraints up to the stage being compared

PROFILE_EQ = PASS iff:

    left.effective_profile.profile_digest = right.effective_profile.profile_digest

REFERENCE_EQ = PASS iff:

    if OOD is used on either side, the reference snapshot digests are equal;
    otherwise REFERENCE_EQ = NOT_APPLICABLE

POLICY_EQ = PASS iff:

    symmetry_mode,
    witness_eval_policy,
    verdict_eval_policy,
    witness_order,
    and verdict_order
    are equal across the two effective profiles

RNG_COMPAT = PASS iff:

    replay classes are identical
    and any declared numeric profile is compatible

NORMALIZER_VALID = PASS iff:

    mode ≠ RAW
    and N_cmp is present
    and every mismatch the comparison intends to overlook
        is explicitly included in N_cmp.covers
    and proof_ref or equivalent validation evidence is present

In RAW mode:

    NORMALIZER_VALID = NOT_APPLICABLE

### Definition 13.10 (Required Pass Set by Mode) [E]

Let Req(mode) be the set of atoms that MUST pass.

For RAW:

    Req(RAW)
      =
    {SAME_BATCH, SCORES_AVAILABLE, EVIDENCE_CLOSED, PROFILE_EQ, POLICY_EQ, RNG_COMPAT}
    ∪ {REFERENCE_EQ if REFERENCE_EQ ≠ NOT_APPLICABLE}

For PROFILE_NORMALIZED:

    Req(PROFILE_NORMALIZED)
      =
    {SAME_BATCH, SCORES_AVAILABLE, EVIDENCE_CLOSED, POLICY_EQ, RNG_COMPAT, NORMALIZER_VALID}
    ∪ {REFERENCE_EQ if REFERENCE_EQ ≠ NOT_APPLICABLE}

    Additionally: if PROFILE_EQ = FAIL, then PROFILE_EQ MUST be in N_cmp.covers.

For REFERENCE_NORMALIZED:

    Req(REFERENCE_NORMALIZED)
      =
    {SAME_BATCH, SCORES_AVAILABLE, EVIDENCE_CLOSED, PROFILE_EQ, POLICY_EQ, RNG_COMPAT, NORMALIZER_VALID}

    Additionally: if REFERENCE_EQ = FAIL, then REFERENCE_EQ MUST be in N_cmp.covers.

For FULLY_NORMALIZED:

    Req(FULLY_NORMALIZED)
      =
    {SAME_BATCH, SCORES_AVAILABLE, EVIDENCE_CLOSED, NORMALIZER_VALID}

    Additionally: any FAIL among {PROFILE_EQ, REFERENCE_EQ, POLICY_EQ, RNG_COMPAT}
    MUST belong to N_cmp.covers.

### Definition 13.11 (Comparable Pair) [E]

A pair of bundles (B_L, B_R) is comparable under mode if and only if:

    every atom in Req(mode) has status = PASS

and

    no failed atom outside N_cmp.covers is ignored.

### Definition 13.12 (Comparison Space) [E]

A comparison space is a target space Y_cmp carrying at least one scalar coordinate

    C_cmp : Y_cmp → ℝ

If mode = RAW:

    Y_cmp is the raw score space and
    C_cmp(B) = B.scores.C_Σ

If mode ≠ RAW:

    N_cmp induces a mapping

        Φ_cmp : Bundle → Y_cmp

    and C_cmp(B) := C_cmp(Φ_cmp(B))

Normative rule:

    Any normalized scalar used for ordering MUST be produced by the declared normalizer.

### Definition 13.13 (Comparison Metrics) [E]

    comparison_metrics := {
        left_score,
        right_score,
        delta_score,
        delta_axis_scores?,
        delta_axis_leverage?,
        tolerance
    }

where:

    left_score  = comparison scalar for left bundle
    right_score = comparison scalar for right bundle
    delta_score = left_score − right_score
    tolerance   = T_cmp.delta_eq

### Definition 13.14 (Derived Score Relation) [E]

If the pair is not comparable:

    score_relation = INCOMPARABLE

Else if |delta_score| ≤ delta_eq:

    score_relation = EQUAL_WITHIN_TOL

Else if delta_score > delta_eq:

    score_relation = LEFT_HIGHER

Else:

    score_relation = RIGHT_HIGHER

### Definition 13.15 (Comparison Explanation) [E]

    comparison_explanation := {
        basis,
        dominant_axis?,
        dominant_constraint?,
        terminal_pattern,
        note?
    }

where:

    basis ∈ {RAW, NORMALIZED}

    dominant_axis
        = argmax_a |delta_axis_leverage[a]|
          if axis leverage deltas are available

    dominant_constraint
        = first failing witness atom,
          or first failing verdict atom,
          or null if neither side failed

    terminal_pattern
        = (left.controller.terminal_state?, right.controller.terminal_state?)

Interpretation:

    Explanation is descriptive, not an additional proof primitive.

## 14. Canonical Abstract Operations [E]

### Operation OD-1

    describe_observer(o) → M_o

### Operation OD-2

    verify(o, D, P_base_or_ref?, ΔP?, R_ref?, RNG?) → VerifyResponse

Semantics:

    verify is replay-pure,
    computes all reachable artifacts against frozen inputs,
    and MUST return a trace-complete, proof-carrying response.

### Operation OD-3

    commit_reference(U_ref) → R_ref_next

### Operation OD-4

    refine(R, budget?, objective?) → ProposalSet

Default objective:

    minimize ℓ_Σ subject to admissibility preservation.

### Operation OD-5

    compare(B_left, B_right, mode, N_cmp?, T_cmp?) → CompareResponse

Semantics:

    compare is comparison-safe.
    It MUST return a comparability ledger.
    It MUST NOT emit LEFT_HIGHER / RIGHT_HIGHER / EQUAL_WITHIN_TOL
    unless the pair is comparable under the declared mode.

If comparison claims parity or ordering,
then the claim MUST be backed by:

    comparability_ledger,
    comparison_metrics,
    and explicit basis (raw or normalized).

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

Constraint:

    Implementation MUST compute and freeze

        P_eff = freeze(merge(P_base, ΔP))

    before final scoring.

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

### Definition 15.3 (Effective Profile Object) [E]

    effective_profile := {
        profile_digest,
        aggregation_profile,
        symmetry_mode,
        witness_eval_policy,
        verdict_eval_policy,
        witness_order,
        verdict_order,
        frozen_fields,
        base_profile_digest?,
        override_digest?
    }

### Definition 15.4 (Replay Object) [E]

    replay := {
        replay_class,
        randomness_record,
        reference_snapshot_digest?,
        implementation_fingerprint?
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

where:

    left_bundle  = canonical VerifyResponse
    right_bundle = canonical VerifyResponse
    mode         = ComparisonMode
    normalizer   = N_cmp if mode ≠ RAW
    tolerance    = T_cmp

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
    EVIDENCE_NOT_CLOSED
    PROFILE_MISMATCH
    REFERENCE_MISMATCH
    POLICY_MISMATCH
    RNG_MISMATCH
    NORMALIZER_MISSING
    NORMALIZER_SCOPE_INVALID
    NORMALIZER_PROOF_MISSING
    COMPARE_INSUFFICIENT_EVIDENCE

### Definition 16.4 (Comparison Evidence Closure) [E]

A comparison reason code is evidence-closed iff its supporting comparison atom
has status = FAIL and the corresponding evidence_ref is present.

Examples:

    BATCH_MISMATCH
        → comparability_ledger.SAME_BATCH.status = FAIL

    PROFILE_MISMATCH
        → comparability_ledger.PROFILE_EQ.status = FAIL

    REFERENCE_MISMATCH
        → comparability_ledger.REFERENCE_EQ.status = FAIL

    POLICY_MISMATCH
        → comparability_ledger.POLICY_EQ.status = FAIL

    RNG_MISMATCH
        → comparability_ledger.RNG_COMPAT.status = FAIL

    NORMALIZER_SCOPE_INVALID or NORMALIZER_PROOF_MISSING
        → comparability_ledger.NORMALIZER_VALID.status = FAIL

## 17. Verify Invariants [E/N]

**Invariant V0:**

    If π ∈ S₃ and scores are present, then

        C_Σ(s; W) = C_Σ(π · s; π · W)

**Invariant V1:**

    If aggregation_profile ≠ W_uniform,
    then effective_profile.symmetry_mode = COVARIANT.

**Invariant V2:**

    classification.ver is derived exactly from witness_ledger when present.

**Invariant V3:**

    classification.acc is derived exactly from verdict_ledger when present.

**Invariant V4:**

    classification.dep is derived exactly from lip evidence and τ_lip_pol when present.

**Invariant V5:**

    If execution.status = OK and ver = FAIL,
    then controller.terminal_state = TERMINAL.

**Invariant V6:**

    If execution.status = OK and ver = PASS and acc = FAIL,
    then controller.terminal_state = REJECT.

**Invariant V7:**

    If execution.status = OK and acc = PASS,
    then controller.terminal_state = ACCEPT.

**Invariant V8:**

    The verify response MUST be trace-complete with respect to the realized controller prefix.

**Invariant V9:**

    Every asserted verify reason code MUST be evidence-closed.

**Invariant V10:**

    If replay_class ≠ BIT_EXACT,
    the source of nondeterminism MUST be recorded.

**Invariant V11:**

    verify MUST NOT mutate reference state.

## 18. Compare Invariants [E/N]

**Invariant C0:**

    If mode = RAW,
    then comparability_ledger.NORMALIZER_VALID.status = NOT_APPLICABLE.

**Invariant C1:**

    score_relation ≠ INCOMPARABLE
        implies
    every atom in Req(mode) has status = PASS.

**Invariant C2:**

    If score_relation ∈ {LEFT_HIGHER, RIGHT_HIGHER, EQUAL_WITHIN_TOL},
    then comparison_metrics MUST be present.

**Invariant C3:**

    If mode ≠ RAW and score_relation ≠ INCOMPARABLE,
    then normalizer MUST be present
    and comparability_ledger.NORMALIZER_VALID.status = PASS.

**Invariant C4:**

    If any failed comparison atom lies outside N_cmp.covers,
    then score_relation = INCOMPARABLE.

**Invariant C5:**

    Any asserted comparison reason code MUST be evidence-closed.

**Invariant C6:**

    If score_relation = INCOMPARABLE,
    then reason_codes MUST be non-empty.

**Invariant C7:**

    No implementation may emit LEFT_HIGHER, RIGHT_HIGHER,
    or EQUAL_WITHIN_TOL as a raw claim when mode = RAW and
    PROFILE_EQ = FAIL or POLICY_EQ = FAIL or SAME_BATCH = FAIL.

**Invariant C8:**

    If delta_axis_leverage is present, then comparison_explanation.dominant_axis
    MUST equal argmax_a |delta_axis_leverage[a]|.

**Invariant C9:**

    If one side terminates in TERMINAL due to witness failure,
    comparison_explanation.dominant_constraint MAY identify the failing witness,
    but this diagnostic note MUST NOT override score_relation semantics.

**Invariant C10:**

    compare MUST NOT mutate either input bundle or any referenced snapshot.

## 19. Provenance Minimum [E/N]

Every successful or partially successful verify response MUST record at least:

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
    dependency hashes or immutable references if available
    controller state sequence
    timestamp

If any override is used, it MUST be recorded.
If any calibration map is used, it MUST be recorded.
If any axis alias is used, it MUST be recorded.
If replay_class ≠ BIT_EXACT, the nondeterminism source MUST be recorded.
If any check is NOT_EVALUATED, its skip_reason MUST be recorded.

Every CompareResponse MUST record at least:

    left bundle identifier or digest
    right bundle identifier or digest
    mode
    required pass set
    comparability ledger
    tolerance
    score_relation
    normalizer identifier/version if used
    normalizer covers if used
    timestamp

If any normalized comparison is asserted,
the normalizer error bound MUST be recorded.

## 20. Self-Application [E]

### Definition 20.1 (Bundle Domain Lift) [E]

Let Bundle be the set of canonical VerifyResponses conforming to §15.2.
Define

    X_meta := Bundle

A meta-batch is an ordinary batch over the lifted domain:

    D_meta = (B_1, …, B_k) ∈ X_meta*

### Definition 20.2 (Meta-Observer) [E]

A meta-observer is an observer over X_meta subject to the same rules:

    same effective-profile freezing,
    same symmetry discipline,
    same replay purity,
    same trace completeness,
    same witness and verdict ledgers,
    same proof-carrying outcomes.

### Proposition 20.3 (Finite Termination of Self-Application) [E]

If D_meta is finite and the meta-observer is an admissible finite pipeline,
then self-application terminates after finite execution steps.

### Note 20.4 (Comparison on Self-Application) [E]

Meta-observers MAY compare bundles produced by observers over the same base batch,
but the comparison contract of §§13–19 still governs.
Self-application does not relax comparability requirements.

## 21. External Hypotheses Boundary [C]

The following remain outside the normative scope of this specification:

    physical-time identification with epistemic time
    thermodynamic dissipation laws
    gravitational geometrization
    metaphysical necessity of triadicity

## 22. Final Position

TSC Observation Dynamics v1.0.8 is the comparison-safe, proof-carrying observation-layer specification of TSC.

Its decisive moves are:

    verification remains replay-pure and ledger-derived,
    comparison now has explicit modes,
    normalization scope is declared rather than implied,
    parity claims require comparability evidence,
    and cross-observer ordering can no longer hide behind silent mismatches.

That is cleaner than v1.0.7.
That is safer for SDKs.
That is kinder to AI readers.
That is the next step.
