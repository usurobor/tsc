# TSC Observation Dynamics v1.0.5

Formal Specification of Observer Construction, Verification, Epistemic Refinement, and Replay-Pure Evaluation

    Version:    v1.0.5
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
    how aggregation behaves under permutation,
    and how verification remains replayable under historical OOD policies.

It is:

    not the foundation,
    not the core measurement calculus,
    not the operational witness protocol,

but the layer that makes observer semantics executable.

Place in stack:

    C≡
      → TSC Core
      → TSC Operational
      → TSC Observation Dynamics   ← this document
      → Runtime / API / SDK
      → Application-specific observers

## 1. Status Discipline

    [N]  inherited normative basis
    [E]  formal extension compatible with inherited TSC basis
    [C]  external conjecture or interpretation

Normative reading rule:

    Nothing marked [E] or [C] may be cited as if it were already proven by [N].

## 2. Change Log

### From v1.0.4

    SYM-02  Permutation discipline is corrected.
            The spec now distinguishes:
                − absolute S₃-invariance
                − permutation-covariance of axis-indexed objects
            This resolves the tension between non-uniform aggregation weights
            and the global claim of axis-permutation invariance.

    AGR-03  Aggregation profile W is now explicitly axis-indexed and
            permutation-aware. Uniform weighting yields absolute invariance;
            non-uniform weighting yields covariance under simultaneous
            permutation of scores and weights.

    REP-01  Replay purity is introduced.
            verify(o, D, …) is defined as evaluation against a frozen
            reference snapshot. It MUST NOT mutate hidden OOD state.

    REP-02  EffectiveProfile is formalized as the frozen merge of
            BaseProfile and OverrideSet. Response artifacts now expose
            effective-profile digest for replay.

    OOD-01  Reference-state evolution is separated from verification.
            Verification may emit a ReferenceUpdateProposal,
            but reference mutation is not part of verify itself.

    RNG-01  ReplayClass and RandomnessRecord are introduced so bootstrap,
            stochastic alignment, and approximate backends can be audited.

    CMP-01  Observer/batch compatibility is made first-class.
            Admissibility now requires declared compatibility between observer
            manifest and batch record.

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

## 3. Symmetry, Notation, and Aggregation Discipline [N/E]

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
    axis aliases
    aggregation weights

### Definition 3.3 (Permutation Action) [E]

For any permutation π ∈ S₃ and axis-indexed object q, define

    (π · q)_a := q_{π⁻¹(a)}.

This is the canonical induced action of axis relabeling.

### Definition 3.4 (Absolute Invariance vs Permutation-Covariance) [E]

A scalar-valued construction F is absolutely S₃-invariant iff

    F(q) = F(π · q)

for all π ∈ S₃.

A scalar-valued construction G on multiple axis-indexed objects is
permutation-covariant iff

    G(q, r, …) = G(π · q, π · r, …)

for all π ∈ S₃.

Normative reading:

    When non-uniform axis weights are present,
    aggregate coherence is permutation-covariant in (scores, weights),
    and absolutely invariant only in the uniform-weight case.

### Definition 3.5 (Inherited Carrier & Summaries) [N]

The framework inherits:

    carrier T of C≡ terms
    summaries S_a = (d_a, p_a, H_a, I_a), for a ∈ A

### Definition 3.6 (Notation Separation) [E]

Local symbols:

    μ_a      > 0        dimensional sensitivity hyperparameters
    μ_ab     > 0        pairwise coherence sensitivity hyperparameters
    ε        > 0        numerical floor
    Θ        ∈ (0,1]    acceptance threshold
    ℓ_a                 diagnostic leverage per axis
    ℓ_Σ                 aggregate diagnostic leverage
    ρ_o                 contraction scalar of observer o

Inherited score names remain:

    s_alpha, s_beta, s_gamma ∈ [0,1]

### Definition 3.7 (Notation Bridge) [E]

    This spec        Parent spec symbol
    ─────────        ──────────────────
    μ_a              λ_α, λ_β, λ_γ
    μ_ab             λ_ab
    ε                ε
    Θ                Θ
    ℓ_a              λ_a
    ℓ_Σ              λ_Σ
    ρ_o              κ  (contraction scalar role)
    κ                reserved in this spec for C≡ seed only

### Definition 3.8 (Aggregation Profile) [N/E]

An aggregation profile is an axis-indexed weight triple

    W := (w_alpha, w_beta, w_gamma)

such that:

    w_alpha > 0
    w_beta  > 0
    w_gamma > 0
    w_alpha + w_beta + w_gamma = 3

Default profile:

    W_uniform := (1, 1, 1)

### Definition 3.9 (Aggregate Coherence) [N/E]

Given dimensional scores s = (s_alpha, s_beta, s_gamma)
and aggregation profile W, define

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

### Proposition 3.10 (Permutation Law for Aggregate Coherence) [E/N]

For all π ∈ S₃:

    C_Σ(s; W) = C_Σ(π · s; π · W)

Hence:

    Aggregate coherence is permutation-covariant in (s, W).

Corollary:

    If W = W_uniform, then C_Σ is absolutely S₃-invariant in s alone.

### Definition 3.11 (Diagnostic Leverage) [E]

For each axis a ∈ A:

    ℓ_a := −ln(max(s_a, ε))

Aggregate leverage under W:

    ℓ_Σ(s; W)
      :=
    (1/3) · (
        w_alpha · ℓ_alpha +
        w_beta  · ℓ_beta  +
        w_gamma · ℓ_gamma
    )

Equivalently:

    ℓ_Σ(s; W) = −ln(C_Σ(s; W))

Interpretation:

    lower ℓ_Σ  ⟺  higher C_Σ

## 4. Observation Objects and Freezing Discipline [E]

### Definition 4.1 (Observation Domain) [E]

Let X be the declared domain of the phenomenon under observation.

### Definition 4.2 (Observation Batch) [E]

An observation batch is a finite sequence

    D = (x_1, …, x_N) ∈ X*

with

    N = |D|.

### Definition 4.3 (BaseProfile) [E]

Every observer design carries a base parameter profile

    P_base := {
        theta,
        μ_axis,
        μ_pair,
        ε,
        aggregation_profile,
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

### Definition 4.4 (OverrideSet) [E]

An override set is a partial object

    ΔP := {
        any subset of P_base fields
    }

Override rule:

    Overrides are permitted only if declared legal by the observer manifest.

### Definition 4.5 (EffectiveProfile) [E]

The effective profile is the frozen merge

    P_eff := freeze(merge(P_base, ΔP))

Normative rule:

    All scoring, witness evaluation, CI evaluation, OOD evaluation,
    and verdict logic MUST use P_eff, not P_base.

### Definition 4.6 (Observer Manifest) [E]

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

### Definition 4.7 (Batch Record) [E]

The batch record is

    batch_record := {
        batch_id?,
        domain_tag,
        schema_ref?,
        N,
        sampling_policy?,
        batch_hash?
    }

### Definition 4.8 (Compatibility Predicate) [E]

Compat(M_o, batch_record) holds iff:

    (i)   domain tags are equal or explicitly declared compatible
    (ii)  schema_ref constraints, if present, are satisfied
    (iii) declared_totality of the observer covers the batch domain
    (iv)  any manifest-level preconditions on N or sampling are satisfied

### Definition 4.9 (Observer Pipeline) [E]

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
    P_base    = base profile
    M_o       = observer manifest

### Definition 4.10 (Measurement Bundle) [E]

Running observer o on batch D against a frozen reference snapshot R_ref
yields a canonical bundle

    B_o(D; P_eff, R_ref) := {
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
        witnesses?,
        ci?,
        ood?,
        reference_update_proposal?,
        provenance?,
        reason_codes
    }

## 5. Replay, Randomness, and Reference State [E/N]

### Definition 5.1 (Reference Snapshot) [E]

A reference snapshot is a frozen OOD reference artifact

    R_ref := {
        reference_id?,
        policy,
        snapshot_digest,
        support_window_desc,
        created_at?,
        payload_or_pointer
    }

Normative rule:

    verify reads R_ref but MUST NOT mutate it.

### Definition 5.2 (Reference Update Proposal) [E]

A reference update proposal is an explicit artifact

    U_ref := {
        base_snapshot_digest,
        proposed_snapshot_digest?,
        update_policy,
        delta_summary?,
        eligibility_condition
    }

Interpretation:

    Verification may propose reference evolution,
    but proposal generation is not reference mutation.

### Definition 5.3 (ReplayClass) [E]

Let

    ReplayClass := {
        BIT_EXACT,
        NUMERIC_EQUIVALENT,
        STOCHASTIC_AUDITABLE
    }

Semantics:

    BIT_EXACT            repeated evaluation reproduces identical artifacts
    NUMERIC_EQUIVALENT   repeated evaluation reproduces within declared tolerances
    STOCHASTIC_AUDITABLE repeated evaluation may vary, but all randomness and
                         approximation sources are fully recorded

### Definition 5.4 (RandomnessRecord) [E]

A randomness record is

    RNG := {
        replay_class,
        bootstrap_seed?,
        alignment_seed_set?,
        backend_id?,
        numeric_profile?,
        nondeterminism_notes?
    }

### Invariant 5.5 (Replay Purity) [E/N]

For fixed:

    observer o
    batch D
    effective profile P_eff
    reference snapshot R_ref
    randomness record RNG

the operation verify(o, D, P_eff, R_ref, RNG) is observationally pure:

    it returns a bundle,
    but does not mutate hidden reference state.

### Invariant 5.6 (Explicit State Evolution) [E]

Any change to OOD reference state MUST occur outside verify
and MUST be represented by an explicit commit or equivalent state-transition artifact.

## 6. Run Classes, Outcomes, and Truth Values [E/N]

### Definition 6.1 (Three-Valued Classification Status) [E]

    Status3 := {PASS, FAIL, UNDECIDED}

### Definition 6.2 (Declared Observer) [E]

Decl(o) holds iff:

    observer o has a valid manifest M_o and base profile P_base.

### Definition 6.3 (Compatible Run) [E]

Cmp(o, D) holds iff:

    Decl(o) and Compat(M_o, batch_record(D)).

### Definition 6.4 (Admissible Run) [E]

Adm(o, D, P_eff, R_ref) holds iff:

    (i)    Cmp(o, D)
    (ii)   η_o, A_a^o, Σ_a^o are well-typed on D or η_o(D)
    (iii)  |D| ≥ N_min
    (iv)   |E_ab^o| ≥ 3 for every required pair
    (v)    required artifacts for summaries, coherences, witnesses,
           CI, OOD, and provenance are computable in principle
    (vi)   P_eff is frozen before final scoring
    (vii)  R_ref is frozen before OOD evaluation
    (viii) axis aliases, if present, are recorded as metadata only

Admissible means:

    runnable and auditable.

### Definition 6.5 (Verified Run) [E/N]

Ver(o, D, P_eff, R_ref) holds iff Adm(o, D, P_eff, R_ref) and all hard witnesses pass:

    w_S3    ≤ τ_S3
    w_gauge ≤ τ_gauge
    w_scale ≤ τ_scale
    w_var   ≤ τ_var
    w_lip   < 1

### Definition 6.6 (Accepted Run) [E/N]

Acc(o, D, P_eff, R_ref) holds iff Ver(o, D, P_eff, R_ref) and:

    C_Σ(s; W_eff)   ≥ Θ
    CI_hi − CI_lo   ≤ δ_CI
    Z_t             < Z_crit

where:

    W_eff = P_eff.aggregation_profile

### Definition 6.7 (Deployment-Ready Run) [E]

Dep(o, D, P_eff, R_ref) holds iff Acc(o, D, P_eff, R_ref) and additionally:

    w_lip ≤ τ_lip_pol
    with τ_lip_pol < 1

Recommended default range:

    τ_lip_pol ∈ [0.80, 0.95]

Recommended starting point:

    τ_lip_pol = 0.90

### Definition 6.8 (Execution Outcome) [E]

    ExecStatus := {OK, ERROR}

    execution := {
        status,
        error_code?,
        error_stage?,
        error_message?
    }

### Definition 6.9 (Controller Outcome) [N/E]

    CtrlTerminal := {ACCEPT, REJECT, TERMINAL}

    controller := {
        state_sequence,
        terminal_state?
    }

### Definition 6.10 (Classification Object) [E]

    classification := {
        decl,
        cmp,
        adm,
        ver,
        acc,
        dep
    }

where each field takes values in Status3.

### Invariant 6.11 (Implication Chain) [E]

    dep = PASS ⟹ acc = PASS ⟹ ver = PASS ⟹ adm = PASS ⟹ cmp = PASS ⟹ decl = PASS

### Invariant 6.12 (Witness Failure Rule) [N/E]

If any hard witness fails, then:

    ver = FAIL
    acc = FAIL
    dep = FAIL

### Invariant 6.13 (Execution / Classification Separation) [E]

If execution.status = ERROR, then:

    controller.state_sequence MUST be a realized prefix of a legal controller trace,
    terminal_state MAY be absent,
    and one or more classification fields MAY be UNDECIDED.

Runtime failure MUST NOT be encoded as a controller terminal state.

## 7. Triadic Closure & Episode Dynamics [E]

### Definition 7.1 (Triadic Episode) [E]

A triadic episode is

    h_t = (m_t, u_t, y_t) ∈ M × U × Y

where:

    m_t = model state
    u_t = intervention / action
    y_t = observed yield / outcome

with deterministic update:

    F : M × U × Y → M × U × Y

### Definition 7.2 (Essential Dependence) [E]

F depends essentially on omitted coordinate k relative to projection π_ij iff
there exist z, z' such that

    π_ij(z) = π_ij(z')
but
    π_ij(F(z)) ≠ π_ij(F(z'))

### Lemma 7.3 (Binary Non-Closure) [E]

If F depends essentially on omitted coordinate k relative to π_ij,
then there does not exist deterministic F_ij such that

    π_ij ∘ F = F_ij ∘ π_ij

Proof:

    Identical projected inputs would have divergent projected futures,
    so F_ij could not be single-valued.  ∎

### Corollary 7.4 (Auxiliary-State Requirement) [E]

A genuinely triadic episode cannot in general be reduced to a closed binary
dynamics without adding hidden state or memory.

### Note 7.5 (Episode vs Evaluation Layer) [E]

The episode layer and evaluator layer are distinct:

    episode layer:
        orders model / action / yield through time

    evaluator layer:
        applies α / β / γ measurements to articulated material within or across episodes

## 8. Internal Coherence Attractor [N/E]

### Definition 8.1 (Observer-Induced Update Operator) [E/N]

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

### Definition 8.2 (Contraction Scalar) [N/E]

Let

    ρ_o := L_sum^o · L_align^o · max{μ_ab}

### Theorem 8.3 (Internal Attractor) [N/E]

If

    ρ_o < 1,

then T_o is a contraction on S^3 and for every initial triple S^(0),

    S^(n+1) = T_o(S^(n))

converges to a unique fixed point

    S_o^*.

### Definition 8.4 (Fixed-Point Profile) [E]

The fixed-point profile of observer o under effective aggregation profile W_eff is

    FP(o; W_eff) := (S_o^*, C_Σ(s*; W_eff), ℓ_Σ(s*; W_eff))

## 9. Refinement & Epistemic Time [E]

### Definition 9.1 (Refinement Run) [E]

A refinement run is a sequence

    R = { r_τ }_{τ ∈ I}

with

    r_τ = (o_τ, D_τ, P_eff,τ, R_ref,τ, B_τ)

and

    B_τ = B_{o_τ}(D_τ; P_eff,τ, R_ref,τ)

### Definition 9.2 (Admissibility-Preserving Refinement) [E]

A refinement run is admissibility-preserving iff

    Adm(o_τ, D_τ, P_eff,τ, R_ref,τ)

for every τ ∈ I.

### Postulate A_weak (Monotone Convergent Subsequence) [E]

Along an admissibility-preserving refinement run, coherence improves in the
sense that there exists a convergent subsequence {r_{τ_k}} such that,
under fixed aggregation profile,

    ℓ_Σ(B_{τ_{k+1}}) ≤ ℓ_Σ(B_{τ_k})

equivalently,

    C_Σ(B_{τ_{k+1}}) ≥ C_Σ(B_{τ_k})

Non-normative note:

    Individual refinement steps may temporarily worsen coherence.

### Definition 9.3 (Epistemic Time) [E]

Epistemic time is the refinement-order parameter τ.
It orders observer-runs.
It is not a physical clock variable.

## 10. Canonical Abstract Operations [E]

This section freezes implementation-facing semantics,
but not transport protocol.

### 10.1 Mandatory Operations

**Operation OD-1:**

    describe_observer(o) → M_o

**Operation OD-2:**

    verify(o, D, P_base_or_ref?, ΔP?, R_ref?, RNG?) → B_o(D; P_eff, R_ref)

Semantics:

    verify is replay-pure.
    It computes all reachable artifacts against frozen inputs.
    It MUST NOT mutate reference state.

### 10.2 Optional Operations

**Operation OD-3:**

    commit_reference(U_ref) → R_ref_next

Semantics:

    Explicitly advances OOD reference state from a proposal.

**Operation OD-4:**

    refine(R, budget?, objective?) → ProposalSet

Default objective:

    minimize ℓ_Σ subject to admissibility preservation.

**Operation OD-5:**

    compare(o_1, o_2, D, R_ref?) → ComparativeBundle

Purpose:

    Compare observers on the same batch and same reference snapshot.

## 11. Canonical Schema: Verify Contract [E]

### Definition 11.1 (Verification Request) [E]

A canonical verify request contains:

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

Semantics:

    observer_manifest   = M_o
    base_profile        = explicit P_base or reference thereto
    override_set        = ΔP
    batch               = D
    reference_snapshot  = R_ref
    randomness_record   = RNG

Constraint:

    The implementation MUST compute and freeze

        P_eff = freeze(merge(P_base, ΔP))

    before final scoring.

### Definition 11.2 (Verification Response) [E]

A canonical verify response is

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
        witnesses?,
        ci?,
        ood?,
        reference_update_proposal?,
        provenance?,
        reason_codes
    }

### Definition 11.3 (Effective Profile Object) [E]

    effective_profile := {
        profile_digest,
        aggregation_profile,
        frozen_fields,
        base_profile_digest?,
        override_digest?
    }

### Definition 11.4 (Replay Object) [E]

    replay := {
        replay_class,
        randomness_record,
        reference_snapshot_digest?,
        implementation_fingerprint?
    }

### Definition 11.5 (OOD Object) [E]

If present:

    ood := {
        Z_t,
        Z_crit,
        pass,
        reference_snapshot_digest,
        policy
    }

### Definition 11.6 (Controller Trace Rule) [E/N]

If execution.status = OK,
then controller.state_sequence MUST be a legal trace over

    HANDSHAKE → MEASURE → WITNESS → {DIAGNOSE | VERDICT}
              → {TERMINAL | ACCEPT | REJECT}

If execution.status = ERROR,
then controller.state_sequence MUST be a realized prefix of a legal trace.

## 12. Verify Invariants [E/N]

**Invariant V0:**

    If π ∈ S₃ and scores are present, then

        C_Σ(s; W) = C_Σ(π · s; π · W)

**Invariant V1:**

    If scores are present, then

        scores.C_Σ
          =
        exp((1/3) · (
            w_alpha · ln(max(scores.s_alpha, ε)) +
            w_beta  · ln(max(scores.s_beta,  ε)) +
            w_gamma · ln(max(scores.s_gamma, ε))
        ))

    where (w_alpha, w_beta, w_gamma) = scores.aggregation_profile.

**Invariant V2:**

    If scores and diagnostics are present, then

        diagnostics.ℓ_Σ = −ln(scores.C_Σ)

**Invariant V3:**

    classification.dep = PASS
        ⟹ classification.acc = PASS
        ⟹ classification.ver = PASS
        ⟹ classification.adm = PASS
        ⟹ classification.cmp = PASS
        ⟹ classification.decl = PASS

**Invariant V4:**

    Any hard witness failure implies

        classification.ver = FAIL
        classification.acc = FAIL
        classification.dep = FAIL

**Invariant V5:**

    execution.status = ERROR MUST NOT be represented by
    controller.terminal_state = TERMINAL_ERROR.

**Invariant V6:**

    verify MUST NOT mutate reference state.

**Invariant V7:**

    effective_profile.profile_digest MUST uniquely identify the frozen
    parameterization used for scoring, witness logic, CI, and OOD evaluation.

**Invariant V8:**

    Provenance, if present, MUST contain enough information to replay
    the realized verdict logic on the recorded summaries, witnesses,
    effective profile, randomness record, and reference snapshot.

### Definition 12.1 (Legacy Boolean Compatibility) [E]

Implementations MAY emit

    legacy_verdict := {
        decl,
        cmp,
        adm,
        ver,
        acc,
        dep
    }

only if no classification field is UNDECIDED.

## 13. Provenance & Replay Minimum [E/N]

Every successful or partially successful verify response MUST record at least:

    observer_id
    observer_version
    batch size N
    domain tag
    effective profile digest
    aggregation profile
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
If replay_class ≠ BIT_EXACT, the source of nondeterminism MUST be recorded.

## 14. Self-Application [E]

### Definition 14.1 (Bundle Domain Lift) [E]

Let Bundle be the set of canonical verify responses conforming to §11.2.
Define

    X_meta := Bundle

A meta-batch is an ordinary batch over the lifted domain:

    D_meta = (B_1, …, B_k) ∈ X_meta*

### Definition 14.2 (Meta-Observer) [E]

A meta-observer o_meta is an observer over X_meta such that:

    η_meta       encodes bundles into T
    A_a^meta     articulates bundle-structures per axis
    Σ_a^meta     summarizes cross-bundle structures
    E_ab^meta    aligns summaries across bundles
    P_base,meta  is a base profile
    M_meta       is a manifest

### Definition 14.3 (Self-Application Contract) [E]

Given base observers o_1, …, o_k applied to a shared batch D and reference snapshot R_ref,
construct

    B_i := verify(o_i, D, …, R_ref, …)

Then define

    D_meta := (B_1, …, B_k)

and self-apply via

    verify(o_meta, D_meta, …, R_ref_meta, …)

No new top-level API is introduced.

### Proposition 14.4 (Finite Termination of Self-Application) [E]

If D_meta is finite and o_meta is an admissible finite pipeline,
then self-application terminates after finite execution steps.

## 15. External Hypotheses Boundary [C]

The following are outside the normative scope of this specification:

    physical-time identification with epistemic time
    thermodynamic dissipation laws
    gravitational geometrization
    metaphysical necessity of triadicity

## 16. Repository Placement & Derived Artifacts [E]

Canonical file:

    spec/tsc-observation-dynamics.md

Derived non-normative artifacts MAY include:

    1. whitepaper explaining motivation and interpretation
    2. language-specific implementation guides
    3. benchmark suites
    4. scientific paper with proofs, experiments, or case studies
    5. JSON Schema / protobuf / IDL definitions derived from §11–§13

Normative rule:

    If any derived artifact contradicts this file,
    this file governs the observation layer.

## 17. Final Position

TSC Observation Dynamics v1.0.5 is the replay-pure observation-layer specification of TSC.

Its decisive moves are:

    weighted aggregation without false symmetry claims,
    frozen effective profiles,
    explicit observer/batch compatibility,
    pure verification against frozen reference snapshots,
    explicit reference evolution,
    and auditable randomness classes.

That is stricter mathematics.
That is safer runtime behavior.
That is the right shape for the next layer.
