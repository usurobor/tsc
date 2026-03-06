# TSC Observation Dynamics v1.0.4

Formal Specification of Observer Construction, Verification, and Epistemic Refinement

    Version:    v1.0.4
    Status:     Proposed Extension Specification
    Artifact:   Specification
    Normative dependencies:
        C≡ v3.1.0
        TSC Core v3.1.0
        TSC Operational v3.1.0
    Recommended repository path:
        spec/tsc-observation-dynamics.md

## 0. Identity

This document is not a scientific article.
It is the observation-layer specification of TSC.

It defines:

    what an observer is,
    how an observer-run is typed,
    how a run is classified,
    how refinement is ordered,
    how self-application is normalized,
    and what implementation-facing contract must be exposed.

Intended audience:

    1. formalists and spec authors
    2. runtime / SDK implementers
    3. AI systems that read TSC specs directly
    4. researchers operationalizing TSC in experiments

Purpose:

    bridge TSC mathematics and executable verification,
    make observer construction auditable,
    freeze canonical run semantics,
    and define the interface boundary between specification and implementation.

Place in stack:

    C≡
      → TSC Core
      → TSC Operational
      → TSC Observation Dynamics   ← this document
      → Runtime / API / SDK
      → Application-specific observers

This document is therefore:

    a specification first,
    a whitepaper source second,
    and only a future paper substrate.

## 1. Status Discipline

    [N]  inherited normative basis
    [E]  formal extension compatible with inherited TSC basis
    [C]  external conjecture or interpretation

Normative reading rule:

    Nothing marked [E] or [C] may be cited as if it were already proven by [N].

## 2. Change Log

### From v1.0.3

    AGR-01  Aggregate coherence now admits an explicit aggregation profile.
            Default remains uniform, but weighted aggregation is now first-class.

    AGR-02  Invariants V1 and V2 are generalized so they are correct for both
            uniform and weighted aggregation.

    EXE-01  Execution outcome is separated from controller outcome.
            Runtime failure is no longer modeled as a controller terminal state.

    EXE-02  Classification statuses are lifted from booleans to a three-valued
            lattice: PASS / FAIL / UNDECIDED.

    PRO-01  ParameterProfile is made explicit and replayable.
            Thresholds, sensitivities, weights, CI settings, and OOD settings
            are frozen as a single canonical object.

    SEL-02  Self-application is normalized through a bundle-batch lift so that
            meta-observation still uses verify(o, D) rather than a new signature.

### From v1.0.2

    SYM-01  κ_o renamed to ρ_o to resolve collision with C≡ cohering seed κ.
    NOT-01  Explicit notation bridge table maps this spec's symbols to parent specs.
    REF-01  Postulate A_weak refined: monotonicity holds along convergent
            subsequences, not necessarily at every refinement step.
    EPI-01  Triadic episode connection to observer pipeline is made explicit.
    DEP-01  Deployment threshold τ_lip_pol given recommended default range.
    SEL-01  Self-application note added: how an observer-of-observers is typed.

### From v1.0.1

    ID-01   Document identity is now explicit.
    ID-02   Audience, purpose, and stack position are front matter.
    API-01  Canonical observer manifest introduced.
    API-02  Canonical verify contract frozen at schema level.
    API-03  Conformance profiles introduced.
    DOC-01  Repository placement and derived artifact policy defined.

## 3. Notation & Dependency Discipline [N/E]

### Definition 3.1 (Axis Set) [N/E]

Let

    A := {α, β, γ}.

All constructions in this document are invariant under permutations of A.

Any semantic labels attached to α, β, γ are metadata only.
They MUST be stored in provenance and MUST NOT alter verdict logic.

### Definition 3.2 (Inherited Carrier & Summaries) [N]

The framework inherits the carrier T of C≡ terms and the summary objects:

    S_a = (d_a, p_a, H_a, I_a),   for a ∈ A.

### Definition 3.3 (Notation Separation) [E]

To avoid symbol collision between this document and its parent specifications,
the following local symbols are used:

    μ_a      > 0        dimensional sensitivity hyperparameters
    μ_ab     > 0        pairwise coherence sensitivity hyperparameters
    ε        > 0        numerical floor
    Θ        ∈ (0,1]    acceptance threshold
    ℓ_a                 diagnostic leverage per axis
    ℓ_Σ                 aggregate diagnostic leverage
    ρ_o                 contraction scalar of observer o

Inherited score names remain:

    s_alpha, s_beta, s_gamma ∈ [0,1]

### Definition 3.4 (Notation Bridge) [E]

The following table maps local symbols to parent specifications.
The mapping is semantic equivalence, not redefinition.

    This spec        Parent spec symbol      Parent location
    ─────────        ──────────────────      ───────────────
    μ_a              λ_α, λ_β, λ_γ          TSC Core §4
    μ_ab             λ_ab                    TSC Core §3.2
    ε                ε                       TSC Core §4
    Θ                Θ                       TSC Operational §5
    ℓ_a              λ_a                     TSC Core §11
    ℓ_Σ              λ_Σ                     TSC Core §11
    ρ_o              (new)                   this spec §7.2
    κ (not used)     κ                       C≡ §1.4 (cohering seed)

The renaming of leverage from λ to ℓ avoids collision with the sensitivity
hyperparameters λ_α, λ_β, λ_γ of TSC Core §4 within the same document.

The symbol κ is reserved for the C≡ cohering seed and is not reused here.

### Definition 3.5 (Aggregation Profile) [N/E]

An aggregation profile is a weight triple

    W := (w_alpha, w_beta, w_gamma)

such that:

    w_alpha > 0
    w_beta  > 0
    w_gamma > 0
    w_alpha + w_beta + w_gamma = 3

Default aggregation profile:

    W_default := (1, 1, 1)

### Definition 3.6 (Aggregate Coherence) [N/E]

Given dimensional scores and an aggregation profile W, define

    C_Σ(W)
      :=
    exp((1/3) · (
        w_alpha · ln(max(s_alpha, ε)) +
        w_beta  · ln(max(s_beta,  ε)) +
        w_gamma · ln(max(s_gamma, ε))
    ))

If W = W_default, this reduces to

    C_Σ = (s_alpha · s_beta · s_gamma)^(1/3)

### Definition 3.7 (Diagnostic Leverage) [E]

For each axis a ∈ A:

    ℓ_a := −ln(max(s_a, ε))

Aggregate leverage under W:

    ℓ_Σ(W)
      :=
    −(1/3) · (
        w_alpha · ln(max(s_alpha, ε)) +
        w_beta  · ln(max(s_beta,  ε)) +
        w_gamma · ln(max(s_gamma, ε))
    )

Hence:

    ℓ_Σ(W) = −ln(C_Σ(W))

Interpretation:

    lower ℓ_Σ  ⟺  higher C_Σ

## 4. Observation Objects [E]

### Definition 4.1 (Observation Domain) [E]

Let X be the declared domain of the phenomenon under observation.

### Definition 4.2 (Observation Batch) [E]

An observation batch is a finite sequence

    D = (x_1, …, x_N) ∈ X*

with

    N = |D|.

### Definition 4.3 (ParameterProfile) [E]

Every observer MUST carry a frozen parameter profile

    P_o := {
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

Semantics:

    theta                discrepancy-weight / reconciliation parameter
    μ_axis               axis sensitivities
    μ_pair               pairwise sensitivities
    ε                    numerical floor
    aggregation_profile  W
    Θ                    acceptance threshold
    τ_*                  witness floors
    δ_CI                 CI-width tolerance
    ci_level             CI confidence level
    Z_crit               OOD threshold
    N_boot               bootstrap count
    OOD_reference_policy rolling / fixed OOD regime
    calibration_refs     optional calibration artifacts

Normative rule:

    P_o MUST be frozen before final scoring.

### Definition 4.4 (Observer Pipeline) [E]

An observer is a typed pipeline

    o = (
        η_o,
        {A_a^o}_{a∈A},
        {Σ_a^o}_{a∈A},
        {E_ab^o}_{a≠b},
        P_o,
        M_o
    )

where:

    η_o       : X* → T                encoder (domain → carrier)
    A_a^o     : T → P(Ω_a^o)          articulator per axis
    Σ_a^o     : P(Ω_a^o) → S_a^o      summarizer per axis
    E_ab^o    = {σ_ab^1, …, σ_ab^m}   alignment ensemble, m ≥ 3
    P_o       = frozen parameter profile
    M_o       = observer manifest

### Definition 4.5 (Observer Manifest) [E]

Every observer MUST admit a serializable manifest

    M_o := {
        observer_id,
        observer_version,
        axis_aliases,
        domain_tag,
        schema_ref?,
        component_refs,
        parameter_profile_ref,
        provenance_policy,
        declared_totality,
        dependency_hashes
    }

where:

    observer_id            stable identifier
    observer_version       semantic version of observer design
    axis_aliases           optional semantic names for α, β, γ
    domain_tag             declared application domain
    schema_ref             optional schema for batch objects
    component_refs         encoder / articulator / summarizer / aligner / scorer / witness suite refs
    parameter_profile_ref  pointer or embedded digest for P_o
    provenance_policy      what must be recorded
    declared_totality      stated domain on which the observer is intended to run
    dependency_hashes      immutable references if available

### Definition 4.6 (Measurement Bundle) [E]

Running observer o on batch D yields

    B_o(D) := {
        header,
        observer,
        batch_record,
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
        provenance?,
        reason_codes
    }

Fields marked ? MAY be absent if execution terminates before they are computed.

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

## 5. Run Classes, Outcomes, and Truth Values [E/N]

### Definition 5.1 (Three-Valued Classification Status) [E]

Let

    Status3 := {PASS, FAIL, UNDECIDED}

Interpretation:

    PASS       predicate established
    FAIL       predicate refuted
    UNDECIDED  predicate not yet evaluable from realized execution trace

### Definition 5.2 (Declared Observer) [E]

Decl(o) holds iff:

    observer o has a valid manifest M_o and frozen parameter profile P_o.

### Definition 5.3 (Admissible Run) [E]

Adm(o, D) holds iff:

    (i)   Decl(o)
    (ii)  η_o, A_a^o, Σ_a^o are well-typed on D or η_o(D)
    (iii) |D| ≥ N_min
    (iv)  |E_ab^o| ≥ 3 for every required pair
    (v)   required artifacts for summaries, coherences, witnesses,
          CI, OOD, and provenance are computable in principle
    (vi)  P_o is frozen before final scoring
    (vii) axis aliases, if present, are declared in provenance policy

Admissible means:

    runnable and auditable.

### Definition 5.4 (Verified Run) [E/N]

Ver(o, D) holds iff Adm(o, D) and all hard witness conditions pass:

    w_S3    ≤ τ_S3
    w_gauge ≤ τ_gauge
    w_scale ≤ τ_scale
    w_var   ≤ τ_var
    w_lip   < 1

Verified means:

    operationally and mathematically valid.

### Definition 5.5 (Accepted Run) [E/N]

Acc(o, D) holds iff Ver(o, D) and:

    C_Σ(W)         ≥ Θ
    CI_hi − CI_lo  ≤ δ_CI
    Z_t            < Z_crit

Accepted means:

    valid + coherent enough + precise enough + distributionally stable enough.

### Definition 5.6 (Deployment-Ready Run) [E]

Dep(o, D) holds iff Acc(o, D) and additionally:

    w_lip ≤ τ_lip_pol
    with τ_lip_pol < 1

Recommended default range:

    τ_lip_pol ∈ [0.80, 0.95]

Recommended starting point for new domains:

    τ_lip_pol = 0.90

DeploymentReady means:

    accepted with an extra engineering safety margin on contraction.

### Definition 5.7 (Execution Outcome) [E]

Execution outcome is distinct from verdict classification.

    ExecStatus := {OK, ERROR}

with canonical object

    execution := {
        status,
        error_code?,
        error_stage?,
        error_message?
    }

Interpretation:

    status = OK      runtime completed normally
    status = ERROR   runtime or transport failed before normal completion

### Definition 5.8 (Controller Outcome) [N/E]

Controller outcome records realized operational-state progression only.

    CtrlTerminal := {ACCEPT, REJECT, TERMINAL}

with canonical object

    controller := {
        state_sequence,
        terminal_state?
    }

Normative rule:

    terminal_state belongs to controller semantics, not runtime semantics.

### Definition 5.9 (Classification Object) [E]

The classification object is

    classification := {
        decl,
        adm,
        ver,
        acc,
        dep
    }

where each field takes values in Status3.

### Invariant 5.10 (Implication Chain) [E]

For all observers o and batches D:

    dep = PASS ⟹ acc = PASS ⟹ ver = PASS ⟹ adm = PASS ⟹ decl = PASS

### Invariant 5.11 (Witness Failure Rule) [N/E]

If any hard witness fails, then:

    ver = FAIL
    acc = FAIL
    dep = FAIL

### Invariant 5.12 (Execution / Classification Separation) [E]

If execution.status = ERROR, then:

    controller.state_sequence MUST be a realized prefix of a legal controller trace,
    terminal_state MAY be absent,
    and at least one classification field MAY be UNDECIDED.

Runtime failure MUST NOT be encoded as a controller terminal state.

## 6. Triadic Closure & Dynamics [E]

### Definition 6.1 (Triadic Episode) [E]

A triadic episode is

    h_t = (m_t, u_t, y_t) ∈ M × U × Y

where:

    m_t = model state
    u_t = intervention / action
    y_t = observed yield / outcome

with deterministic update:

    F : M × U × Y → M × U × Y

### Definition 6.2 (Essential Dependence) [E]

F depends essentially on omitted coordinate k relative to projection π_ij iff
there exist z, z' such that

    π_ij(z) = π_ij(z')
but
    π_ij(F(z)) ≠ π_ij(F(z'))

### Lemma 6.3 (Binary Non-Closure) [E]

If F depends essentially on omitted coordinate k relative to π_ij,
then there does not exist deterministic F_ij such that

    π_ij ∘ F = F_ij ∘ π_ij

Proof:

    Identical projected inputs would have divergent projected futures,
    so F_ij could not be single-valued.  ∎

### Corollary 6.4 (Auxiliary-State Requirement) [E]

A genuinely triadic episode cannot in general be reduced to a closed binary
dynamics without adding hidden state or memory.

Interpretation:

    Binary dichotomies are generally lossy projections of a triadically closed process.

### Note 6.5 (Episode vs Evaluation Layer) [E]

The episode layer and the evaluator layer are distinct.

    episode layer:
        orders model / action / yield through time

    evaluator layer:
        applies α / β / γ measurements to articulated material within or across episodes

The evaluator triad operates within observation episodes.
The episode dynamics govern the temporal sequence of evaluations.

## 7. Internal Coherence Attractor [N/E]

### Definition 7.1 (Observer-Induced Update Operator) [E/N]

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

### Definition 7.2 (Contraction Scalar) [N/E]

Let

    ρ_o := L_sum^o · L_align^o · max{μ_ab}

### Theorem 7.3 (Internal Attractor) [N/E]

If

    ρ_o < 1,

then T_o is a contraction on S^3 and for every initial triple S^(0),

    S^(n+1) = T_o(S^(n))

converges to a unique fixed point

    S_o^*.

Interpretation:

    Coherence acts as an internal attractor in summary-space.

### Definition 7.4 (Fixed-Point Profile) [E]

The fixed-point profile of observer o is

    FP(o) := (S_o^*, C_Σ(W)^*, ℓ_Σ(W)^*)

## 8. Refinement & Epistemic Time [E]

### Definition 8.1 (Refinement Run) [E]

A refinement run is a sequence

    R = { r_τ }_{τ ∈ I}

with

    r_τ = (o_τ, D_τ, B_τ)
and
    B_τ = B_{o_τ}(D_τ)

### Definition 8.2 (Admissibility-Preserving Refinement) [E]

A refinement run is admissibility-preserving iff

    Adm(o_τ, D_τ)

for every τ ∈ I.

### Postulate A_weak (Monotone Convergent Subsequence) [E]

Along an admissibility-preserving refinement run, coherence improves in the
following sense:

    There exists a convergent subsequence { r_{τ_k} } such that

        ℓ_Σ(B_{τ_{k+1}}) ≤ ℓ_Σ(B_{τ_k})

    equivalently,

        C_Σ(B_{τ_{k+1}}) ≥ C_Σ(B_{τ_k})

    under a fixed aggregation profile and numerical floor.

Non-normative note:

    Individual refinement steps may temporarily worsen coherence.
    The postulate does not require every step to improve.

### Definition 8.3 (Epistemic Time) [E]

Epistemic time is the refinement-order parameter τ.
It orders observer-runs.
It is not a physical clock variable.

### Definition 8.4 (Epistemic Preorder) [E]

For states r_i, r_j in a refinement run:

    r_i ≤_E r_j   iff   i ≤ j

## 9. Canonical Abstract Operations [E]

This section freezes implementation-facing semantics,
but not transport protocol.

A conforming implementation MAY use:

    Python objects,
    JSON,
    protobuf,
    typed structs,
    database records,

or any other representation,
provided canonical information content is preserved.

### 9.1 Mandatory Operations

**Operation OD-1:**

    describe_observer(o) → M_o

Semantics:

    Returns the canonical observer manifest.

**Operation OD-2:**

    verify(o, D, profile?) → B_o(D)

Semantics:

    Executes the observer on batch D,
    computes all reachable artifacts,
    returns controller trace,
    returns execution outcome,
    and returns classification plus diagnostics.

### 9.2 Optional Operations

**Operation OD-3:**

    refine(R, budget?, objective?) → ProposalSet

Default objective:

    minimize ℓ_Σ subject to admissibility preservation.

**Operation OD-4:**

    compare(o_1, o_2, D) → ComparativeBundle

Purpose:

    Compare observers on the same batch D
    without conflating observer identity with phenomenon identity.

## 10. Canonical Schema: Verify Contract [E]

### Definition 10.1 (Verification Request) [E]

A canonical verify request contains:

    VerifyRequest := {
        spec_name,
        spec_version,
        observer_manifest,
        parameter_profile,
        batch,
        parameter_overrides?,
        witness_floor_overrides?,
        profile?,
        provenance_policy_override?
    }

Required semantics:

    spec_name         = "TSC Observation Dynamics"
    spec_version      = version string of this spec
    observer_manifest = M_o
    parameter_profile = P_o
    batch             = observation batch D

Constraint:

    Any override MUST be frozen before final scoring.
    Any override that changes aggregation weights MUST be recorded.

### Definition 10.2 (Verification Response) [E]

A canonical verify response is

    VerifyResponse := {
        header,
        observer,
        batch_record,
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
        provenance?,
        reason_codes
    }

Required header fields:

    header := {
        spec_name,
        spec_version,
        run_id,
        timestamp
    }

Required controller fields:

    controller := {
        state_sequence,
        terminal_state?
    }

Required execution fields:

    execution := {
        status,
        error_code?,
        error_stage?,
        error_message?
    }

Required classification fields:

    classification := {
        decl,
        adm,
        ver,
        acc,
        dep
    }

### Definition 10.3 (Controller Trace Rule) [E/N]

If execution.status = OK,
then controller.state_sequence MUST be a legal trace over

    HANDSHAKE → MEASURE → WITNESS → {DIAGNOSE | VERDICT}
              → {TERMINAL | ACCEPT | REJECT}

If execution.status = ERROR,
then controller.state_sequence MUST be a realized prefix of a legal trace.

### Definition 10.4 (Canonical Score Object) [E]

If scores are present, they MUST have the form

    scores := {
        s_alpha,
        s_beta,
        s_gamma,
        aggregation_profile,
        C_Σ
    }

### Definition 10.5 (Canonical Diagnostics Object) [E]

If diagnostics are present, they MUST have the form

    diagnostics := {
        ℓ_alpha,
        ℓ_beta,
        ℓ_gamma,
        ℓ_Σ,
        ρ
    }

### Definition 10.6 (Reason Codes) [E]

Reason codes SHOULD be drawn from:

    INPUT_NOT_WELL_FORMED
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

### 10.7 Verify Invariants [E/N]

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
        ⟹ classification.decl = PASS

**Invariant V4:**

    Any hard witness failure implies

        classification.ver = FAIL
        classification.acc = FAIL
        classification.dep = FAIL

**Invariant V5:**

    Provenance, if present, MUST contain enough information
    to replay the realized verdict logic on the recorded summaries,
    witnesses, profile, and thresholds.

**Invariant V6:**

    execution.status = ERROR MUST NOT be represented by
    controller.terminal_state = TERMINAL_ERROR.

### Definition 10.8 (Legacy Boolean Compatibility) [E]

For compatibility with v1.0.3-style consumers,
implementations MAY emit

    legacy_verdict := {
        adm,
        ver,
        acc,
        dep
    }

only if no classification field is UNDECIDED.

## 11. Conformance Profiles [E]

**Profile OD-Minimal:**

    MUST implement describe_observer
    MUST implement verify
    MUST emit canonical request/response fields

**Profile OD-Refinement:**

    satisfies OD-Minimal
    MUST implement refine

**Profile OD-Comparative:**

    satisfies OD-Minimal
    MUST implement compare

**Profile OD-Full:**

    satisfies OD-Minimal
    satisfies OD-Refinement
    satisfies OD-Comparative

Conformance statement format:

    "Implements TSC Observation Dynamics v1.0.4 / Profile <name>"

## 12. Provenance Minimum [E/N]

Every successful or partially successful verify response MUST record at least:

    observer_id
    observer_version
    parameter_profile digest or full embedded profile
    dependency hashes or immutable references if available
    batch size N
    domain tag
    aggregation profile
    sampling policy
    witness floors
    bootstrap method and N_boot
    CI level
    OOD reference policy / description
    calibration refs if any
    controller state sequence
    timestamp

If any calibration map is used, it MUST be recorded.
If any axis alias is used, it MUST be recorded.
If any override is used, it MUST be recorded.

## 13. Self-Application [E]

### Definition 13.1 (Bundle Domain Lift) [E]

Let Bundle be the set of canonical verify responses conforming to §10.2.
Define the meta-domain

    X_meta := Bundle

A meta-batch is then an ordinary batch over the lifted domain:

    D_meta = (B_1, …, B_k) ∈ X_meta*

### Definition 13.2 (Meta-Observer) [E]

A meta-observer o_meta is an observer over X_meta such that:

    η_meta       encodes bundles into T
    A_a^meta     extracts axis-a structures across bundles
    Σ_a^meta     summarizes cross-bundle axis-a information
    E_ab^meta    aligns summaries across bundles
    P_meta       is a frozen parameter profile
    M_meta       is a manifest

### Definition 13.3 (Self-Application Contract) [E]

Given base observers o_1, …, o_k applied to a shared phenomenon-batch D,
construct their bundles

    B_i := verify(o_i, D)

and form

    D_meta := (B_1, …, B_k)

Then self-application is simply

    verify(o_meta, D_meta)

No new top-level API is introduced.

### Proposition 13.4 (Finite Termination of Self-Application) [E]

If D_meta is finite and o_meta is an admissible finite pipeline,
then self-application terminates after finite execution steps.

Reason:

    The meta-observer processes a finite batch of finite artifacts;
    no infinite regress is required by the contract.

## 14. External Hypotheses Boundary [C]

The following are outside the normative scope of this specification:

    physical-time identification with epistemic time
    thermodynamic dissipation laws
    gravitational geometrization
    metaphysical necessity of triadicity

These may be discussed elsewhere,
but they are not licensed by this specification alone.

## 15. Repository Placement & Derived Artifacts [E]

Canonical file:

    spec/tsc-observation-dynamics.md

Derived non-normative artifacts MAY include:

    1. a whitepaper explaining motivation and interpretation
    2. implementation guides for specific languages
    3. benchmark suites
    4. a scientific paper with proofs, experiments, or case studies
    5. concrete JSON Schema / protobuf definitions derived from §10

Normative rule:

    If any derived artifact contradicts this file,
    this file governs the observation layer.

## 16. Final Position

TSC Observation Dynamics v1.0.4 is the observation-layer specification of TSC.

It is:

    not the foundation,
    not the core measurement calculus,
    not the operational witness protocol,

but the layer that defines:

    what an observer is,
    how an observer-run is classified,
    how refinement is ordered,
    how self-application is normalized,
    and how those semantics cross into implementation.

The decisive move in v1.0.4 is this:

    controller logic remains operational,
    runtime failure remains runtime,
    aggregation is explicit,
    and replayability is first-class.

That is cleaner mathematics.
That is safer software.
That is the right next layer in the stack.
