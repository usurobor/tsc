# TSC Observation Dynamics v1.0.7

Formal Specification of Observer Construction, Verification, Epistemic Refinement, and Proof-Carrying Check Ledgers

    Version:    v1.0.7
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
    how verification remains replay-pure,
    and how every terminal outcome carries explicit check-level evidence.

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
and proof-carrying.

## 1. Status Discipline

    [N]  inherited normative basis
    [E]  formal extension compatible with inherited TSC basis
    [C]  external conjecture or interpretation

Normative reading rule:

    Nothing marked [E] or [C] may be cited as if it were already proven by [N].

## 2. Change Log

### From v1.0.6

    POL-01  Evaluation policies are now first-class:
                FAIL_FAST | EXHAUSTIVE
            separately for witness-stage and verdict-stage checks.

    LED-01  WitnessLedger introduced.
            Witness outcomes are no longer just a flat signal bundle;
            they are fixed-slot check records with status, observed value,
            threshold relation, and skip reason if not evaluated.

    LED-02  VerdictLedger introduced.
            Threshold / CI / OOD checks are now proof-carrying check records.

    CLS-04  ver / acc / dep become ledger-derived.
            Classification is no longer a free-floating flag set.

    MAT-02  Trace-complete materialization is refined:
            once a stage is reached, the corresponding ledger MUST exist.

    EVD-02  Acceptance is now proof-carrying.
            ACCEPT requires explicit PASS evidence for every required witness
            and verdict check.

    EVD-03  Fail-fast is reconciled with provenance.
            Non-evaluated checks are represented explicitly as NOT_EVALUATED
            with a skip reason, rather than being silently absent.

    ORD-01  Canonical witness and verdict orders are frozen.
            This removes ambiguity across SDK implementations.

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

For any permutation π ∈ S₃ and any axis-indexed object q, define

    (π · q)_a := q_{π⁻¹(a)}.

For any compound object P with axis-indexed computational subfields,
π acts by permuting those subfields and leaving scalar/global fields unchanged.

### Definition 3.4 (SymmetryMode) [E]

    SymmetryMode := {ABSOLUTE, COVARIANT}

Interpretation:

    ABSOLUTE:
        Permuting axis assignments in the observed material leaves
        coherence unchanged under a fixed effective profile.

    COVARIANT:
        Permuting axis assignments in the observed material must be accompanied
        by the same permutation of all axis-indexed computational profile fields.

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

Uniform corollary:

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

Metadata-only fields, including axis aliases, are excluded from P_eff^axis.

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

Interpretation:

    FAIL_FAST:
        Stop evaluating later checks in the same stage after the first failure.

    EXHAUSTIVE:
        Evaluate every check in the stage regardless of earlier failures.

### Definition 4.4 (WitnessOrder) [E]

The canonical atomic witness order is

    WitnessOrder_default := [S3, GAUGE, SCALE, VAR, LIP]

Non-normative note:

    VAR and LIP are often computed from the same W4 ensemble artifact,
    but they remain distinct atomic acceptance conditions.

### Definition 4.5 (VerdictOrder) [E]

The canonical verdict order is

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

These correspond to the atomic witness acceptance conditions:

    S3     : w_S3    ≤ τ_S3
    GAUGE  : w_gauge ≤ τ_gauge
    SCALE  : w_scale ≤ τ_scale
    VAR    : w_var   ≤ τ_var
    LIP    : w_lip   < 1

### Definition 5.4 (VerdictAtoms) [E]

    VerdictAtoms := {THRESHOLD, CI, OOD}

These correspond to the atomic verdict acceptance conditions:

    THRESHOLD : C_Σ           ≥ Θ
    CI        : CI_hi − CI_lo ≤ δ_CI
    OOD       : Z_t           < Z_crit

### Definition 5.5 (Witness Entry) [E]

For each c ∈ WitnessAtoms, a witness entry is

    WitnessEntry(c) := {
        status,
        observed_value?,
        relation,
        floor_or_target?,
        evidence_ref?,
        skip_reason?
    }

Canonical relations:

    S3       relation = ≤
    GAUGE    relation = ≤
    SCALE    relation = ≤
    VAR      relation = ≤
    LIP      relation = <

Normative rule:

    If status ∈ {PASS, FAIL}, then observed_value MUST be present.
    If status = NOT_EVALUATED, then skip_reason MUST be present.

### Definition 5.6 (Verdict Entry) [E]

For each c ∈ VerdictAtoms, a verdict entry is

    VerdictEntry(c) := {
        status,
        observed_value?,
        relation,
        floor_or_target?,
        evidence_ref?,
        reference_snapshot_digest?,
        skip_reason?
    }

Canonical relations:

    THRESHOLD relation = ≥
    CI        relation = ≤
    OOD       relation = <

Normative rule:

    If status ∈ {PASS, FAIL}, then observed_value MUST be present.
    If status = NOT_EVALUATED, then skip_reason MUST be present.

### Definition 5.7 (WitnessLedger) [E]

A witness ledger is

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

where:

    policy = P_eff.witness_eval_policy
    order  = P_eff.witness_order
    each slot is a WitnessEntry

### Definition 5.8 (VerdictLedger) [E]

A verdict ledger is

    verdict_ledger := {
        policy,
        order,
        first_failure?,
        THRESHOLD,
        CI,
        OOD
    }

where:

    policy = P_eff.verdict_eval_policy
    order  = P_eff.verdict_order
    each slot is a VerdictEntry

### Definition 5.9 (Fail-Fast Witness Ledger Law) [E/N]

If witness_ledger.policy = FAIL_FAST
and first_failure = c,
then:

    (i)   every witness atom strictly before c in order has status = PASS
    (ii)  the slot for c has status = FAIL
    (iii) every witness atom strictly after c has status = NOT_EVALUATED
          and skip_reason = FAIL_FAST_SHORT_CIRCUIT

### Definition 5.10 (Exhaustive Witness Ledger Law) [E]

If witness_ledger.policy = EXHAUSTIVE
and stage W has been reached,
then every witness atom has status ∈ {PASS, FAIL}.

### Definition 5.11 (Fail-Fast Verdict Ledger Law) [E/N]

If verdict_ledger.policy = FAIL_FAST
and first_failure = c,
then:

    (i)   every verdict atom strictly before c in order has status = PASS
    (ii)  the slot for c has status = FAIL
    (iii) every verdict atom strictly after c has status = NOT_EVALUATED
          and skip_reason = FAIL_FAST_SHORT_CIRCUIT

### Definition 5.12 (Exhaustive Verdict Ledger Law) [E]

If verdict_ledger.policy = EXHAUSTIVE
and stage V has been reached,
then every verdict atom has status ∈ {PASS, FAIL}.

## 6. Run Classes, Truth Values, and Outcomes [E/N]

### Definition 6.1 (Status3) [E]

    Status3 := {PASS, FAIL, UNDECIDED}

### Definition 6.2 (Information Preorder on Status3) [E]

Define

    UNDECIDED ≤_I PASS
    UNDECIDED ≤_I FAIL

and PASS, FAIL are incomparable.

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

Normative constraint:

    τ_lip_pol < 1

Recommended default range:

    τ_lip_pol ∈ [0.80, 0.95]

Recommended starting point:

    τ_lip_pol = 0.90

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

where each field takes values in Status3.

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

Witness failure MUST NOT terminate in REJECT.

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

Interpretation:

    Once a stage is reached, its ledger must exist;
    silent absence is not allowed.

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

Required support:

    INPUT_NOT_WELL_FORMED
        → execution.status = ERROR
          and execution.error_stage = HANDSHAKE

    DOMAIN_INCOMPATIBLE or SCHEMA_MISMATCH
        → observer manifest and batch_record present
          and classification.cmp = FAIL

    OVERRIDE_NOT_ALLOWED
        → effective_profile present
          and override information recorded

    BATCH_TOO_SMALL
        → batch_record.N present
          and classification.adm = FAIL

    ENSEMBLE_TOO_SMALL
        → manifest or provenance records ensemble insufficiency
          and classification.adm = FAIL

    WITNESS_S3_FAIL
        → witness_ledger.S3.status = FAIL
          and controller.terminal_state = TERMINAL

    WITNESS_GAUGE_FAIL
        → witness_ledger.GAUGE.status = FAIL
          and controller.terminal_state = TERMINAL

    WITNESS_SCALE_FAIL
        → witness_ledger.SCALE.status = FAIL
          and controller.terminal_state = TERMINAL

    WITNESS_VAR_FAIL
        → witness_ledger.VAR.status = FAIL
          and controller.terminal_state = TERMINAL

    WITNESS_LIP_FAIL
        → witness_ledger.LIP.status = FAIL
          and controller.terminal_state = TERMINAL

    THRESHOLD_FAIL
        → verdict_ledger.THRESHOLD.status = FAIL
          and controller.terminal_state = REJECT

    CI_TOO_WIDE
        → verdict_ledger.CI.status = FAIL
          and controller.terminal_state = REJECT

    OOD_FAIL
        → verdict_ledger.OOD.status = FAIL
          and controller.terminal_state = REJECT

    RUNTIME_ERROR or INTERNAL_ERROR
        → execution.status = ERROR

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

Acceptance MUST be explicit proof of all required passes,
not merely absence of a recorded failure.

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

Interpretation:

    Reference evolution is explicit and external to verify.

## 10. Triadic Closure and Episode Dynamics [E]

### Definition 10.1 (Triadic Episode) [E]

A triadic episode is

    h_t = (m_t, u_t, y_t) ∈ M × U × Y

where:

    m_t = model state
    u_t = intervention / action
    y_t = observed yield / outcome

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

Let

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

A refinement run is a sequence

    R = { r_τ }_{τ ∈ I}

with

    r_τ = (o_τ, D_τ, P_eff,τ, R_ref,τ, B_τ)

and

    B_τ = B_{o_τ}(D_τ; P_eff,τ, R_ref,τ)

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

## 13. Canonical Abstract Operations [E]

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

    compare(o_1, o_2, D, R_ref?, profile_normalization?) → ComparativeBundle

If comparison claims parity,
then the same effective profile and reference regime MUST be used
or the normalization rule MUST be explicit.

## 14. Canonical Verify Contract [E]

### Definition 14.1 (VerifyRequest) [E]

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

### Definition 14.2 (VerifyResponse) [E]

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

### Definition 14.3 (Effective Profile Object) [E]

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

### Definition 14.4 (Replay Object) [E]

    replay := {
        replay_class,
        randomness_record,
        reference_snapshot_digest?,
        implementation_fingerprint?
    }

### Definition 14.5 (Legacy Compatibility) [E]

Implementations MAY additionally emit:

    legacy_witnesses := {
        w_S3,
        w_gauge,
        w_scale,
        w_var,
        w_lip
    }

only if every witness atom has status ∈ {PASS, FAIL}.

Implementations MAY additionally emit:

    legacy_verdict := {
        decl,
        cmp,
        adm,
        ver,
        acc,
        dep
    }

only if no classification field is UNDECIDED.

## 15. Verify Invariants [E/N]

**Invariant V0:**

    If π ∈ S₃ and scores are present, then

        C_Σ(s; W) = C_Σ(π · s; π · W)

**Invariant V1:**

    If aggregation_profile ≠ W_uniform,
    then effective_profile.symmetry_mode = COVARIANT.

**Invariant V2:**

    If scores are present, then

        scores.C_Σ
          =
        exp((1/3) · (
            w_alpha · ln(max(scores.s_alpha, ε)) +
            w_beta  · ln(max(scores.s_beta,  ε)) +
            w_gamma · ln(max(scores.s_gamma, ε))
        ))

**Invariant V3:**

    If scores and diagnostics are present, then

        diagnostics.ℓ_Σ = −ln(scores.C_Σ)

**Invariant V4:**

    If witness_ledger is present, then classification.ver is derived exactly
    by Definition 6.6.

**Invariant V5:**

    If verdict_ledger is present, then classification.acc is derived exactly
    by Definition 6.7.

**Invariant V6:**

    classification.dep is derived exactly by Definition 6.8 whenever the
    required lip evidence is present.

**Invariant V7:**

    If witness_ledger.policy = FAIL_FAST,
    then witness_ledger obeys Definition 5.9;
    if witness_ledger.policy = EXHAUSTIVE,
    then it obeys Definition 5.10.

**Invariant V8:**

    If verdict_ledger.policy = FAIL_FAST,
    then verdict_ledger obeys Definition 5.11;
    if verdict_ledger.policy = EXHAUSTIVE,
    then it obeys Definition 5.12.

**Invariant V9:**

    If execution.status = OK and ver = FAIL,
    then controller.terminal_state = TERMINAL.

**Invariant V10:**

    If execution.status = OK and ver = PASS and acc = FAIL,
    then controller.terminal_state = REJECT.

**Invariant V11:**

    If execution.status = OK and acc = PASS,
    then controller.terminal_state = ACCEPT.

**Invariant V12:**

    verify MUST NOT mutate reference state.

**Invariant V13:**

    The response MUST be trace-complete with respect to the realized controller prefix.

**Invariant V14:**

    Every asserted reason code MUST be evidence-closed.

**Invariant V15:**

    If replay_class ≠ BIT_EXACT,
    the source of nondeterminism MUST be recorded.

## 16. Provenance Minimum [E/N]

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

## 17. Self-Application [E]

### Definition 17.1 (Bundle Domain Lift) [E]

Let Bundle be the set of canonical verify responses conforming to §14.2.
Define

    X_meta := Bundle

A meta-batch is an ordinary batch over the lifted domain:

    D_meta = (B_1, …, B_k) ∈ X_meta*

### Definition 17.2 (Meta-Observer) [E]

A meta-observer is an observer over X_meta subject to the same rules:

    same effective-profile freezing,
    same symmetry discipline,
    same replay purity,
    same trace completeness,
    same witness and verdict ledgers,
    same proof-carrying terminal outcomes.

### Proposition 17.3 (Finite Termination of Self-Application) [E]

If D_meta is finite and the meta-observer is an admissible finite pipeline,
then self-application terminates after finite execution steps.

## 18. External Hypotheses Boundary [C]

The following remain outside the normative scope of this specification:

    physical-time identification with epistemic time
    thermodynamic dissipation laws
    gravitational geometrization
    metaphysical necessity of triadicity

## 19. Final Position

TSC Observation Dynamics v1.0.7 is the proof-carrying observation-layer specification of TSC.

Its decisive moves are:

    explicit evaluation policy,
    fixed witness and verdict orders,
    ledgers instead of silent omission,
    classification derived from recorded checks,
    fail-fast reconciled with provenance,
    and acceptance made as evidentially explicit as rejection.

That is cleaner than 1.0.6.
That is safer for SDKs.
That is kinder to AI readers.
That is the next step.
