"""
reference/python/tsc_controller.py — Functional-core / effect-interpreter controller
TSC Operational v2.0.0 (compatible with Core v2.0.0)

REQUIRES: Python 3.10+ (pattern matching)

Design goals
------------
- Pure domain + pure transitions (no hidden mutation).
- Effects are ADTs interpreted by a tiny side-effect layer (hooks).
- S₃-symmetric naming aligned with v2 spec: H_c, V_c, D_c, C_sigma; WitnessFloors;
  out-of-distribution gate via Z_t vs Z_crit; Θ (Theta) decision threshold.
- Leaves alignment-ensemble details (commutation, conservation, symmetry, scale)
  to the environment. The controller only consumes Measurements and Witness health.

Public surface
--------------
- compute_c_from_file(...) -> float (v2.1 CLI/test entry point)
- verify_tsc_plus(...) -> VerifyResult
- transition(...)       -> (ControllerState, Effects)
- interpret(...)        -> TauBudget
- step(...)             -> ControllerState
"""

from __future__ import annotations

from collections.abc import Callable, Iterable, Mapping
from dataclasses import dataclass, field, replace
from enum import Enum, auto
from typing import Any, Literal


# ===== v2.1 CLI/TEST ENTRY POINT =====


def compute_c_from_file(path: str, *, seed: int | None = None) -> float:
    """
    Entry point for CLI and conformance tests.

    Purely functional: path → ParsedInput → Metrics → C_Σ

    To add support for new formats, add a parser function to
    reference/python/parsers/ and register it in the dispatch table.
    """
    from reference.python.parser_interface import parse_file

    # Pure pipeline: parse → verify → extract
    parsed = parse_file(path, seed)

    result = verify_tsc_plus(
        state=parsed.state,
        policy=parsed.policy,
        floors=parsed.floors,
        cfg=parsed.cfg,
        env=parsed.env,
    )

    return float(result.metrics.C_sigma)


# ===== CORE CONTROLLER (v2.0.0) =====

Dim = Literal["H", "V", "D"]


class State(Enum):
    OPTIMIZE = auto()
    REINFLATE = auto()
    MINIMAL_INFO = auto()
    LOCKDOWN = auto()
    HANDSHAKE = auto()


class Verdict(Enum):
    PASS = auto()
    FAIL = auto()
    FAIL_DEGENERATE = auto()  # H/V witness floors violated
    FAIL_DEGENERATE_D = auto()  # D witness floors violated


@dataclass(frozen=True)
class Metrics:
    """Dimensional coherence measurements for a single verification window."""

    H_c: float
    V_c: float
    D_c: float
    C_sigma: float
    C_sigma_CI: tuple[float, float]  # (lo, hi)


@dataclass(frozen=True)
class WitnessFloors:
    """Health minima for witnesses (keeps degeneracy from faking a pass)."""

    # Pattern witnesses (H) & relation witnesses (V)
    nu_min: float  # minimal variance / sample richness
    H_min: float  # minimal entropy or invariant count for H/V
    L_min: float  # minimal Lipschitz / stability margin for H/V
    # Process witnesses (D)
    nu_min_D: float
    H_min_D: float


@dataclass(frozen=True)
class WitnessStatus:
    """Minimal cross-dimension witness health summary (S₃-symmetric by design)."""

    H_variance: float = 0.0
    H_entropy: float = 0.0
    H_lipschitz: float = 0.0
    D_entropy: float = 0.0
    D_variance: float = 0.0

    def hv_fails(self, f: WitnessFloors) -> bool:
        return (
            (self.H_variance < f.nu_min)
            or (self.H_entropy < f.H_min)
            or (self.H_lipschitz < f.L_min)
        )

    def d_fails(self, f: WitnessFloors) -> bool:
        return (self.D_entropy < f.H_min_D) or (self.D_variance < f.nu_min_D)


@dataclass(frozen=True)
class OODStatus:
    """Simple OOD gate: Z_t is test statistic; compare to Z_crit."""

    Z_t: float
    Z_crit: float
    p_ref_hash: str | None = None  # provenance tag for reference distribution


@dataclass(frozen=True)
class TauBudget:
    """Measurement effort budget per dimension (kept S₃-symmetric)."""

    tau_max: float
    H: float = 0.0
    V: float = 0.0
    D: float = 0.0

    def shrink_worst(self, factor: float = 0.5) -> TauBudget:
        trip = {"H": self.H, "V": self.V, "D": self.D}
        worst = max(trip, key=trip.get)
        trip[worst] = max(0.0, trip[worst] * factor)
        return TauBudget(self.tau_max, trip["H"], trip["V"], trip["D"])


@dataclass(frozen=True)
class PolicyConfig:
    """Controller policy thresholds and horizons (interpreted by transition logic)."""

    Theta: float = 0.80  # decision threshold on CI_lo(C_sigma)
    delta: float = 0.05  # not used here, reserved (tolerance)
    Z_crit: float = 0.95  # OOD critical value
    M_Z: int = 3  # steps below Z_crit to exit LOCKDOWN
    epsilon_H: float = 0.05  # witness margin (used by hooks)
    M_R: int = 3  # reserved
    M_M: int = 5  # drift patience before MINIMAL_INFO
    M_H: int = 10  # consecutive HANDSHAKE passes to exit


@dataclass(frozen=True)
class VerifyPolicy:
    """Runtime policy knob bag (domain-specific)."""

    name: str = "default"
    params: Mapping[str, Any] = field(default_factory=dict)


# ----------------------------- Effects (ADTs) ---------------------------------


@dataclass(frozen=True)
class FreezeMetricsAndTrust:
    pass


@dataclass(frozen=True)
class SetAllKiToMin:
    pass


@dataclass(frozen=True)
class OversampleFailingDimensions:
    policy: VerifyPolicy


@dataclass(frozen=True)
class ReduceTauForWorstDimension:
    witnesses: WitnessStatus


@dataclass(frozen=True)
class RecenterAndRetuneLambdaMu:
    pass


@dataclass(frozen=True)
class ReallocateTauForProductiveAdaptation:
    pass


@dataclass(frozen=True)
class ApplySimplifyActions:
    target: str  # e.g., "witness_health" or "J_cost"


@dataclass(frozen=True)
class ResetCounters:
    names: tuple[str, ...] = ()


Effect = (
    FreezeMetricsAndTrust
    | SetAllKiToMin
    | OversampleFailingDimensions
    | ReduceTauForWorstDimension
    | RecenterAndRetuneLambdaMu
    | ReallocateTauForProductiveAdaptation
    | ApplySimplifyActions
    | ResetCounters
)


# ----------------------------- Pure Verifier ----------------------------------

Index = Any
SampleIndexSet = Callable[[State, VerifyPolicy], Iterable[Index]]
ComputeMetrics = Callable[[Iterable[Index]], Metrics]
ComputeWitnesses = Callable[[Iterable[Index]], WitnessStatus]
ComputeOOD = Callable[[Iterable[Index]], OODStatus]


@dataclass(frozen=True)
class VerifyEnv:
    """Plugs in domain-specific measurement procedures."""

    sample_index_set: SampleIndexSet
    compute_metrics: ComputeMetrics
    compute_witnesses: ComputeWitnesses
    compute_ood: ComputeOOD


@dataclass(frozen=True)
class VerifyResult:
    """Result of one verification window with named fields."""

    verdict: Verdict
    metrics: Metrics
    witnesses: WitnessStatus
    ood: OODStatus
    indices: tuple[Index, ...]


def verify_tsc_plus(
    *,
    state: State,
    policy: VerifyPolicy,
    floors: WitnessFloors,
    cfg: PolicyConfig,
    env: VerifyEnv,
) -> VerifyResult:
    """
    One-window verification:
      - Gated by OOD (LOCKDOWN if Z_t >= Z_crit)
      - Guarded by witness floors (degeneracy)
      - Decision by CI_lo(C_sigma) vs Theta
    """
    I = tuple(env.sample_index_set(state, policy))
    M = env.compute_metrics(I)
    W = env.compute_witnesses(I)
    O = env.compute_ood(I)

    lo, _ = M.C_sigma_CI

    # OOD gate (enter LOCKDOWN via transition)
    if O.Z_t >= cfg.Z_crit:
        return VerifyResult(
            verdict=Verdict.FAIL,
            metrics=M,
            witnesses=W,
            ood=O,
            indices=I,
        )

    # Degeneracy guards
    if W.hv_fails(floors):
        return VerifyResult(
            verdict=Verdict.FAIL_DEGENERATE,
            metrics=M,
            witnesses=W,
            ood=O,
            indices=I,
        )

    if W.d_fails(floors):
        return VerifyResult(
            verdict=Verdict.FAIL_DEGENERATE_D,
            metrics=M,
            witnesses=W,
            ood=O,
            indices=I,
        )

    verdict = Verdict.PASS if lo >= cfg.Theta else Verdict.FAIL

    return VerifyResult(
        verdict=verdict,
        metrics=M,
        witnesses=W,
        ood=O,
        indices=I,
    )


# ----------------------------- Pure Transition --------------------------------


@dataclass(frozen=True)
class Counters:
    ood_clear: int = 0
    drift: int = 0
    handshake_passes: int = 0


@dataclass(frozen=True)
class ControllerState:
    state: State = State.OPTIMIZE
    tau: TauBudget = field(default_factory=lambda: TauBudget(0.10))
    counters: Counters = field(default_factory=Counters)


def transition(
    *,
    floors: WitnessFloors,
    cfg: PolicyConfig,
    policy: VerifyPolicy,
    ctrl: ControllerState,
    verdict: Verdict,
    witnesses: WitnessStatus,
    ood: OODStatus,
) -> tuple[ControllerState, tuple[Effect, ...]]:
    """
    Pure next-state function with effect emission.
    Uses pattern matching for clarity.
    """
    s, c, tau = ctrl.state, ctrl.counters, ctrl.tau
    eff: list[Effect] = []

    # LOCKDOWN entry (immediate on OOD detection)
    if s != State.LOCKDOWN and ood.Z_t >= cfg.Z_crit:
        eff.extend([FreezeMetricsAndTrust(), SetAllKiToMin()])
        return (
            ControllerState(
                State.LOCKDOWN,
                TauBudget(tau.tau_max, 0, 0, 0),
                replace(c, ood_clear=0),
            ),
            tuple(eff),
        )

    # State-specific transitions using pattern matching
    match s:
        case State.LOCKDOWN:
            if ood.Z_t < cfg.Z_crit:
                n = replace(c, ood_clear=c.ood_clear + 1)
                if n.ood_clear >= cfg.M_Z:
                    eff.append(ResetCounters(("lockdown", "drift")))
                    return (
                        ControllerState(
                            State.OPTIMIZE, tau, replace(n, ood_clear=0, drift=0)
                        ),
                        tuple(eff),
                    )
                return replace(ctrl, counters=n), tuple(eff)
            # Still OOD: reset the clear counter
            return replace(ctrl, counters=replace(c, ood_clear=0)), tuple(eff)

        case State.HANDSHAKE:
            if verdict == Verdict.PASS:
                n = replace(c, handshake_passes=c.handshake_passes + 1)
                if n.handshake_passes >= cfg.M_H:
                    return (
                        ControllerState(
                            State.OPTIMIZE, tau, replace(n, handshake_passes=0)
                        ),
                        tuple(eff),
                    )
                return replace(ctrl, counters=n), tuple(eff)
            return replace(ctrl, counters=replace(c, handshake_passes=0)), tuple(eff)

        case _:
            # Handle verdicts for non-LOCKDOWN, non-HANDSHAKE states
            match verdict:
                case Verdict.FAIL_DEGENERATE | Verdict.FAIL_DEGENERATE_D:
                    eff.extend(
                        [
                            OversampleFailingDimensions(policy),
                            ReduceTauForWorstDimension(witnesses),
                            ApplySimplifyActions("witness_health"),
                        ]
                    )
                    return replace(ctrl, state=State.REINFLATE), tuple(eff)

                case Verdict.FAIL:
                    if s != State.MINIMAL_INFO:
                        n = replace(c, drift=c.drift + 1)
                        if n.drift > cfg.M_M:
                            eff.append(ApplySimplifyActions("J_cost"))
                            return (
                                ControllerState(
                                    State.MINIMAL_INFO, tau.shrink_worst(), n
                                ),
                                tuple(eff),
                            )
                        eff.extend(
                            [
                                RecenterAndRetuneLambdaMu(),
                                ReallocateTauForProductiveAdaptation(),
                            ]
                        )
                        return replace(ctrl, counters=n), tuple(eff)
                    # Already in MINIMAL_INFO; stay there
                    return ctrl, tuple(eff)

                case Verdict.PASS:
                    eff.append(ResetCounters(("drift", "handshake")))
                    return (
                        ControllerState(
                            State.OPTIMIZE,
                            tau,
                            replace(c, drift=0, handshake_passes=0),
                        ),
                        tuple(eff),
                    )


# ----------------------------- Interpreter ------------------------------------


class Hooks:
    """
    Implement these in your runtime. This default is a pure no-op layer.
    """

    # Side-effectful targets (override as needed)
    def freeze_metrics_and_trust(self) -> None: ...

    def set_all_Ki_to_min(self) -> None: ...

    def oversample_failing_dimensions(self, policy: VerifyPolicy) -> None: ...

    def reduce_tau_for_worst_dimension(
        self, tau: TauBudget, witnesses: WitnessStatus
    ) -> TauBudget:
        return tau

    def recenter_and_retune_lambda_mu(self) -> None: ...

    def reallocate_tau_for_productive_adaptation(self, tau: TauBudget) -> TauBudget:
        return tau

    def apply_simplify_actions(self, target: str) -> None: ...

    def reset_counters(self, names: tuple[str, ...]) -> None: ...

    # Optional policy checks for MINIMAL_INFO → exit
    def witnesses_above_margins_for(
        self, required_steps: int, epsilon_H: float
    ) -> bool:
        return False

    def pass_M_M_with_non_increasing_J_cost(self, required_steps: int) -> bool:
        return False


def interpret(
    effects: Iterable[Effect],
    *,
    hooks: Hooks,
    tau: TauBudget,
    witnesses: WitnessStatus,
) -> TauBudget:
    """
    Apply emitted effects through hooks and return the updated tau budget.
    Uses pattern matching for effect dispatch.
    """
    for e in effects:
        match e:
            case FreezeMetricsAndTrust():
                hooks.freeze_metrics_and_trust()

            case SetAllKiToMin():
                hooks.set_all_Ki_to_min()

            case OversampleFailingDimensions(policy):
                hooks.oversample_failing_dimensions(policy)

            case ReduceTauForWorstDimension(witnesses_data):
                tau = hooks.reduce_tau_for_worst_dimension(tau, witnesses_data)

            case RecenterAndRetuneLambdaMu():
                hooks.recenter_and_retune_lambda_mu()

            case ReallocateTauForProductiveAdaptation():
                tau = hooks.reallocate_tau_for_productive_adaptation(tau)

            case ApplySimplifyActions(target):
                hooks.apply_simplify_actions(target)

            case ResetCounters(names):
                hooks.reset_counters(names)

    return tau


# ----------------------------- One-step runner --------------------------------


def step(
    *,
    ctrl: ControllerState,
    floors: WitnessFloors,
    cfg: PolicyConfig,
    policy: VerifyPolicy,
    env: VerifyEnv,
    hooks: Hooks,
) -> ControllerState:
    """One-step verification + transition + effect interpretation."""
    result = verify_tsc_plus(
        state=ctrl.state,
        policy=policy,
        floors=floors,
        cfg=cfg,
        env=env,
    )

    next_ctrl, effs = transition(
        floors=floors,
        cfg=cfg,
        policy=policy,
        ctrl=ctrl,
        verdict=result.verdict,
        witnesses=result.witnesses,
        ood=result.ood,
    )

    new_tau = interpret(
        effects=effs,
        hooks=hooks,
        tau=next_ctrl.tau,
        witnesses=result.witnesses,
    )

    return replace(next_ctrl, tau=new_tau)


# ----------------------------- Self-test --------------------------------------

if __name__ == "__main__":
    print("Testing controller with Python 3.10+ pattern matching...")

    # Test environment
    def sample_index_set(state: State, policy: VerifyPolicy):
        return range(32)

    def compute_metrics(I):
        return Metrics(0.91, 0.90, 0.92, 0.91, (0.86, 0.95))

    def compute_witnesses(I):
        return WitnessStatus(0.02, 0.25, 0.06, 0.22, 0.015)

    def compute_ood(I):
        return OODStatus(0.10, 0.95)

    env = VerifyEnv(sample_index_set, compute_metrics, compute_witnesses, compute_ood)
    floors = WitnessFloors(1e-3, 0.1, 1e-3, 1e-4, 0.05)
    policy = VerifyPolicy()
    cfg = PolicyConfig()
    hooks = Hooks()

    ctrl = ControllerState()
    for i in range(3):
        ctrl = step(ctrl=ctrl, floors=floors, cfg=cfg, policy=policy, env=env, hooks=hooks)
        print(
            f"step={i} state={ctrl.state.name} "
            f"τ=({ctrl.tau.H:.3f},{ctrl.tau.V:.3f},{ctrl.tau.D:.3f})"
        )

    print("\nTesting CLI entry point...")
    try:
        c = compute_c_from_file("examples/cellular-automata/glider.md")
        print(f"✓ compute_c_from_file() returned C_Σ = {c:.4f}")
    except NotImplementedError as e:
        print(f"⚠ compute_c_from_file() not yet implemented: {e}")
    except FileNotFoundError:
        print("⚠ Example file not found (expected if running outside repo root)")

    print("\n✓ Pattern matching working correctly")