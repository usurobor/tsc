"""
reference/python/parsers/tsc_yaml_v2.py

TSC v2.1.1 YAML Parser - Rich format with alignment ensembles
==============================================================

Parses markdown or YAML files containing structured TSC blocks with:
- Triadic observations (O_H, O_V, O_D)
- Alignment ensemble configurations (HV, HD, VD aligners)
- Witness floors and policy configurations
- Provisional coherence values (until real aligners implemented)

Design Philosophy
-----------------
This parser is **future-ready**: it extracts the full rich structure from
v2.1.1 TSC YAML blocks but returns provisional metrics via stubs. When real
alignment ensembles (entropic-OT, Sinkhorn, Procrustes) are implemented,
only the compute_metrics() function needs updating - the YAML schema and
controller integration remain stable.

Format Detection
----------------
Detects TSC blocks in three locations (priority order):
1. YAML front-matter (--- ... ---)
2. Fenced code blocks (```yaml ... ```)
3. Whole-file YAML (for .yaml/.yml files)

Example Usage
-------------
    from reference.python.parsers.tsc_yaml_v2 import parse_tsc_document

    parsed = parse_tsc_document("examples/philosophical/consciousness.md")
    # Returns ParsedInput with VerifyEnv containing provisional metrics

TODOs for Real Implementation
------------------------------
1. Replace compute_metrics() stubs with actual alignment ensembles:
   - Entropic optimal transport for HV/VD
   - Procrustes or CPD for HD
   - Cost matrix construction from feature vectors

2. Implement witness health extraction from alignment diagnostics:
   - Plan sparsity → H_variance
   - Dual potentials → H_lipschitz
   - Convergence metrics → stability bounds

3. Add commutation/conservation/symmetry checks as structured tests

4. Replace CI heuristics with bootstrap or analytical delta-method bounds

5. Add YAML schema validation with informative error messages

Version: 2.1.1
Compatible with: tsc_controller.py v2.0.0, spec/tsc-core.md v2.0.0
"""

from __future__ import annotations

import json
import math
import random
import re
from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:
    yaml = None  # Optional dependency; falls back to JSON

from reference.python.parser_interface import ParsedInput
from reference.python.tsc_controller import (
    Metrics,
    OODStatus,
    PolicyConfig,
    State,
    VerifyEnv,
    VerifyPolicy,
    WitnessFloors,
    WitnessStatus,
)

# ============================================================================
# YAML Discovery - Find TSC blocks in various document formats
# ============================================================================

_YAML_FENCE = re.compile(r"```(?:ya?ml)\s+(.*?)```", re.DOTALL | re.IGNORECASE)
_FRONT_MATTER = re.compile(r"^---\s*(.*?)\s*---", re.DOTALL)


def _load_yaml_or_json(txt: str) -> dict[str, Any]:
    """
    Load a YAML/JSON snippet with graceful fallback.

    Prefers YAML if pyyaml is available; otherwise tries JSON.
    Wraps top-level lists for uniformity.

    Parameters
    ----------
    txt : str
        Raw YAML or JSON text

    Returns
    -------
    dict
        Parsed structure (empty dict if parse fails)
    """
    if yaml is not None:
        data = yaml.safe_load(txt)
        if data is None:
            return {}
        if isinstance(data, dict):
            return data
        # Wrap top-level lists for uniformity
        return {"_": data}

    # JSON fallback
    try:
        data = json.loads(txt)
        if isinstance(data, dict):
            return data
        return {"_": data}
    except json.JSONDecodeError:
        return {}


def _first_tsc_block(s: str) -> dict[str, Any]:
    """
    Find first TSC YAML block in document.

    Searches in priority order:
    1. YAML front-matter (--- ... ---)
    2. Fenced code blocks (```yaml ... ```)
    3. Whole-file YAML

    Parameters
    ----------
    s : str
        Document text

    Returns
    -------
    dict
        Parsed TSC block

    Raises
    ------
    NotImplementedError
        If no valid TSC block found
    """
    # Try front-matter
    m = _FRONT_MATTER.search(s)
    if m:
        d = _load_yaml_or_json(m.group(1))
        if "tsc" in d or any(k in d for k in ("O_H", "O_V", "O_D", "aligners", "observations")):
            return d.get("tsc", d)

    # Try fenced YAML blocks
    for fm in _YAML_FENCE.findall(s):
        d = _load_yaml_or_json(fm)
        if "tsc" in d or any(k in d for k in ("O_H", "O_V", "O_D", "aligners", "observations")):
            return d.get("tsc", d)

    # Try whole-file YAML
    try:
        d = _load_yaml_or_json(s)
        if "tsc" in d or any(k in d for k in ("O_H", "O_V", "O_D", "aligners", "observations")):
            return d.get("tsc", d)
    except Exception:
        pass

    raise NotImplementedError("No TSC YAML found (expected 'tsc:' block or compatible structure)")


# ============================================================================
# Configuration Parsing - Extract policy, floors, state from YAML
# ============================================================================


def _get_state(s: str | None) -> State:
    """Parse controller state from string."""
    if not s:
        return State.OPTIMIZE
    try:
        return State[s.upper()]
    except (KeyError, AttributeError):
        return State.OPTIMIZE


def _floors_from(d: Mapping[str, Any] | None) -> WitnessFloors:
    """
    Parse witness health floors from YAML.

    Uses spec-aligned defaults if not provided.
    """
    if not d:
        return WitnessFloors(
            nu_min=1e-3,  # Minimal variance
            H_min=0.1,  # Minimal entropy
            L_min=1e-3,  # Minimal Lipschitz
            nu_min_D=1e-4,  # D variance floor
            H_min_D=0.05,  # D entropy floor
        )
    return WitnessFloors(
        nu_min=float(d.get("nu_min", 1e-3)),
        H_min=float(d.get("H_min", 0.1)),
        L_min=float(d.get("L_min", 1e-3)),
        nu_min_D=float(d.get("nu_min_D", 1e-4)),
        H_min_D=float(d.get("H_min_D", 0.05)),
    )


def _policy_from(d: Mapping[str, Any] | None) -> VerifyPolicy:
    """Parse verification policy from YAML."""
    if not d:
        return VerifyPolicy()
    return VerifyPolicy(name=str(d.get("name", "default")), params=dict(d.get("params", {})))


def _cfg_from(d: Mapping[str, Any] | None) -> PolicyConfig:
    """
    Parse controller policy configuration from YAML.

    Includes decision thresholds (Theta), OOD gates (Z_crit),
    and state transition parameters.
    """
    if not d:
        return PolicyConfig()
    return PolicyConfig(
        Theta=float(d.get("Theta", 0.80)),
        delta=float(d.get("delta", 0.05)),
        Z_crit=float(d.get("Z_crit", 0.95)),
        M_Z=int(d.get("M_Z", 3)),
        epsilon_H=float(d.get("epsilon_H", 0.05)),
        M_R=int(d.get("M_R", 3)),
        M_M=int(d.get("M_M", 5)),
        M_H=int(d.get("M_H", 10)),
    )


# ============================================================================
# Utility Functions
# ============================================================================


def _clamp01(x: float) -> float:
    """Clamp value to [0, 1] interval."""
    return 0.0 if x < 0.0 else 1.0 if x > 1.0 else x


def _geomean3(a: float, b: float, c: float) -> float:
    """
    Geometric mean of three values with degeneracy protection.

    Used for C_Σ = (H_c · V_c · D_c)^(1/3)
    """
    a, b, c = max(a, 1e-12), max(b, 1e-12), max(c, 1e-12)
    return float((a * b * c) ** (1.0 / 3.0))


# ============================================================================
# Core Parsing - Extract structured observations and config
# ============================================================================


@dataclass(frozen=True)
class ParsedTSC:
    """
    Intermediate parse result containing all TSC block components.

    This structure is converted to ParsedInput for controller consumption.
    """

    state: State
    policy: VerifyPolicy
    floors: WitnessFloors
    cfg: PolicyConfig
    N: int  # Window size
    O_H: Sequence[Mapping[str, Any]]  # H dimension observations
    O_V: Sequence[Mapping[str, Any]]  # V dimension observations
    O_D: Sequence[Mapping[str, Any]]  # D dimension observations
    aligners: Mapping[str, Mapping[str, Any]]  # Aligner configs (HV, HD, VD)
    provisional: Mapping[str, Any]  # Provisional coherence values
    ood: Mapping[str, Any]  # OOD detection config


def _parse_core(doc: Mapping[str, Any]) -> ParsedTSC:
    """
    Parse TSC YAML structure into typed components.

    Extracts observations, aligners, thresholds, and provisional values.
    """
    # Window / sampling
    win = doc.get("window", {}) or doc.get("sampling", {}) or {}
    N = int(win.get("N", 32))

    # Observations - support both nested and flat structures
    obs = doc.get("observations", {})
    O_H = list(obs.get("O_H", doc.get("O_H", [])) or [])
    O_V = list(obs.get("O_V", doc.get("O_V", [])) or [])
    O_D = list(obs.get("O_D", doc.get("O_D", [])) or [])

    # Aligner configurations
    aligners = dict(doc.get("aligners", {}))

    # Provisional values (used until real aligners implemented)
    provisional = dict(doc.get("provisional", {}))

    # OOD detection config
    ood = dict(doc.get("ood", {}))

    return ParsedTSC(
        state=_get_state(doc.get("state")),
        policy=_policy_from(doc.get("policy")),
        floors=_floors_from(doc.get("floors")),
        cfg=_cfg_from(doc.get("cfg")),
        N=N,
        O_H=O_H,
        O_V=O_V,
        O_D=O_D,
        aligners=aligners,
        provisional=provisional,
        ood=ood,
    )


# ============================================================================
# VerifyEnv Construction - Build measurement callbacks
# ============================================================================


def _make_env(parsed: ParsedTSC, seed: int | None) -> VerifyEnv:
    """
    Construct VerifyEnv with provisional metric computation.

    This function creates the measurement callbacks expected by the controller.
    Currently uses stubs; real alignment ensembles go here.

    Parameters
    ----------
    parsed : ParsedTSC
        Parsed TSC structure
    seed : int | None
        Random seed for deterministic CI computation

    Returns
    -------
    VerifyEnv
        Environment with measurement callbacks
    """
    rnd = random.Random(seed if seed is not None else 0xC0FFEE)

    def sample_index_set(_state: State, _policy: VerifyPolicy) -> Iterable[int]:
        """Simple deterministic index window."""
        return range(parsed.N)

    # ========================================================================
    # Provisional Metrics (STUB - replace with real aligners)
    # ========================================================================

    def _infer_stub_score(items: Sequence[Mapping[str, Any]], keys: Sequence[str]) -> float:
        """
        Heuristic coherence score from observations.

        Looks for numeric confidence/score fields; falls back to count-based score.

        TODO: Replace with actual alignment ensemble computation.
        """
        vals: list[float] = []
        for item in items:
            for k in keys:
                v = item.get(k)
                if isinstance(v, (int, float)):
                    vals.append(float(v))
                    break
        if vals:
            return _clamp01(sum(vals) / max(1, len(vals)))
        # Count-based fallback: monotone, saturating
        return _clamp01(0.45 + 0.12 * math.log1p(len(items)))

    def compute_metrics(I: Iterable[int]) -> Metrics:
        """
        Compute dimensional coherence metrics.

        Current: Provisional values from YAML or inferred from observations
        TODO: Implement real alignment ensembles:
              - Entropic OT for HV/VD
              - Procrustes/CPD for HD
              - Extract alignment diagnostics for witness health
        """
        # Prefer explicit provisional numbers if provided
        H_c = parsed.provisional.get("H_c")
        V_c = parsed.provisional.get("V_c")
        D_c = parsed.provisional.get("D_c")

        # Infer from observations if not explicitly provided
        if not isinstance(H_c, (int, float)):
            H_c = _infer_stub_score(parsed.O_H, ("confidence", "p", "score", "weight"))
        if not isinstance(V_c, (int, float)):
            V_c = _infer_stub_score(parsed.O_V, ("confidence", "clarity", "score", "p"))
        if not isinstance(D_c, (int, float)):
            D_c = _infer_stub_score(parsed.O_D, ("confidence", "p", "score"))

        H_c = _clamp01(float(H_c))
        V_c = _clamp01(float(V_c))
        D_c = _clamp01(float(D_c))
        C_sigma = _geomean3(H_c, V_c, D_c)

        # Lightweight CI: width shrinks with sample size
        # TODO: Replace with bootstrap or analytical bounds
        I_len = sum(1 for _ in I)
        base = 0.25 / math.sqrt(max(1, I_len))
        jitter = (rnd.random() - 0.5) * 0.01
        w = max(0.02, base) + jitter
        lo = _clamp01(C_sigma - w)
        hi = _clamp01(C_sigma + w)

        return Metrics(H_c=H_c, V_c=V_c, D_c=D_c, C_sigma=C_sigma, C_sigma_CI=(lo, hi))

    # ========================================================================
    # Witness Health (STUB - extract from alignment diagnostics)
    # ========================================================================

    def _proxy_richness(n: int) -> float:
        """Monotone, saturating richness proxy from observation count."""
        return float(n / (n + 64))

    def compute_witnesses(I: Iterable[int]) -> WitnessStatus:
        """
        Compute witness health indicators.

        Current: Proxy from observation counts
        TODO: Extract from alignment diagnostics:
              - Plan sparsity → variance
              - Dual potentials → Lipschitz bounds
              - Convergence metrics → entropy estimates
        """
        nH, nV, nD = len(parsed.O_H), len(parsed.O_V), len(parsed.O_D)

        H_variance = max(1e-6, _proxy_richness(nH))
        H_entropy = max(1e-6, 0.05 + 0.10 * math.log1p(nH))
        H_lipschitz = max(1e-6, 0.01 + 0.10 * math.log1p(nV))
        D_entropy = max(1e-6, 0.04 + 0.10 * math.log1p(nD))
        D_variance = max(1e-6, _proxy_richness(nD))

        # Allow YAML overrides for testing
        override = parsed.provisional.get("witnesses", {})
        if isinstance(override, Mapping):
            H_variance = float(override.get("H_variance", H_variance))
            H_entropy = float(override.get("H_entropy", H_entropy))
            H_lipschitz = float(override.get("H_lipschitz", H_lipschitz))
            D_entropy = float(override.get("D_entropy", D_entropy))
            D_variance = float(override.get("D_variance", D_variance))

        return WitnessStatus(
            H_variance=H_variance,
            H_entropy=H_entropy,
            H_lipschitz=H_lipschitz,
            D_entropy=D_entropy,
            D_variance=D_variance,
        )

    # ========================================================================
    # OOD Detection
    # ========================================================================

    def compute_ood(I: Iterable[int]) -> OODStatus:
        """Extract OOD gate parameters from YAML."""
        Z_t = float(parsed.ood.get("Z_t", 0.0))
        Z_crit = float(parsed.ood.get("Z_crit", 0.95))
        p_ref_hash = parsed.ood.get("p_ref_hash")
        if p_ref_hash is not None:
            p_ref_hash = str(p_ref_hash)
        return OODStatus(Z_t=Z_t, Z_crit=Z_crit, p_ref_hash=p_ref_hash)

    return VerifyEnv(
        sample_index_set=sample_index_set,
        compute_metrics=compute_metrics,
        compute_witnesses=compute_witnesses,
        compute_ood=compute_ood,
    )


# ============================================================================
# Public Entry Point
# ============================================================================


def is_tsc_yaml(path: str) -> bool:
    """
    Predicate: does this file contain TSC v2.1.1 YAML structure?

    Used by parser dispatch in parsers/__init__.py
    """
    try:
        text = Path(path).read_text(encoding="utf-8")

        _first_tsc_block(text)  # Raises if not found
        return True
    except (NotImplementedError, FileNotFoundError, OSError):
        return False


def parse_tsc_document(path: str, seed: int | None = None) -> ParsedInput:
    """
    Parse TSC v2.1.1 format document.

    Extracts structured observations (O_H, O_V, O_D), aligner configs,
    and constructs VerifyEnv with provisional metrics.

    Parameters
    ----------
    path : str
        Path to markdown or YAML file containing TSC block
    seed : int | None
        Random seed for deterministic CI computation

    Returns
    -------
    ParsedInput
        Bundle for compute_c_from_file() containing:
        - state: Controller state
        - policy: Verification policy
        - floors: Witness health thresholds
        - cfg: Controller policy config
        - env: VerifyEnv with measurement callbacks

    Examples
    --------
    >>> from reference.python.parsers.tsc_yaml_v2 import parse_tsc_document
    >>> parsed = parse_tsc_document("examples/philosophical/consciousness.md")
    >>> # Pass to controller
    >>> from reference.python.tsc_controller import compute_c_from_file
    >>> c_sigma = compute_c_from_file("examples/philosophical/consciousness.md")
    """
    text = Path(path).read_text(encoding="utf-8")
    block = _first_tsc_block(text)
    parsed = _parse_core(block)
    env = _make_env(parsed, seed)

    return ParsedInput(
        env=env,
        floors=parsed.floors,
        cfg=parsed.cfg,
        policy=parsed.policy,
        state=parsed.state,
    )


__all__ = ["is_tsc_yaml", "parse_tsc_document"]
