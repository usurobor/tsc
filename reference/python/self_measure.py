"""
reference/python/self_measure.py — TSC Self-Measurement

Version from pyproject.toml (single source of truth)
Generates JSON reports only in docs/
"""

from __future__ import annotations

import json
import math
import platform
import random
import re
import statistics
import subprocess
import unicodedata
from collections import Counter
from collections.abc import Mapping
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from itertools import permutations
from pathlib import Path
from typing import Any

# Optional accelerators
try:
    import numpy as np
    import numpy.linalg as LA
except ImportError:
    np = None
    LA = None


# ============================================================================
# Version
# ============================================================================


def get_version() -> str:
    """Get version from pyproject.toml."""
    try:
        import tomllib
    except ImportError:
        import tomli as tomllib
    
    pyproject = Path(__file__).parent.parent.parent / "pyproject.toml"
    with open(pyproject, "rb") as f:
        data = tomllib.load(f)
        return f"v{data['project']['version']}"


# ============================================================================
# Configuration
# ============================================================================


@dataclass(frozen=True)
class Params:
    """Measurement parameters per Operational §2."""

    theta: float = 0.7
    lambda_alpha: float = 4.0
    lambda_beta: float = 4.0
    lambda_gamma: float = 4.0
    n_boot: int = 1000
    Theta: float = 0.90
    seed: int = 42


# ============================================================================
# Utilities
# ============================================================================

_TOKEN_PATTERN = re.compile(r"[A-Za-z0-9_≡αβγλΣΔ∧∨⊙⊗→←↔≈≃≤≥]+")


def tokenize_md(text: str) -> list[str]:
    """Extract normalized tokens from markdown."""
    text = unicodedata.normalize("NFKC", text)
    return [t.lower() for t in _TOKEN_PATTERN.findall(text)]


def cosine(u: Mapping[str, float], v: Mapping[str, float]) -> float:
    """Cosine similarity between frequency distributions."""
    keys = set(u) | set(v)
    num = sum(u.get(k, 0.0) * v.get(k, 0.0) for k in keys)
    du = math.sqrt(sum((u.get(k, 0.0) ** 2) for k in keys))
    dv = math.sqrt(sum((v.get(k, 0.0) ** 2) for k in keys))
    return 0.0 if du == 0.0 or dv == 0.0 else num / (du * dv)


def jensen_shannon(p: Mapping[str, float], q: Mapping[str, float]) -> float:
    """Jensen-Shannon divergence."""
    keys = set(p) | set(q)

    def kl(a, b):
        s = 0.0
        for k in keys:
            ak, bk = a.get(k, 0.0), b.get(k, 0.0)
            if ak > 0 and bk > 0:
                s += ak * math.log(ak / bk)
        return s

    m = {k: 0.5 * (p.get(k, 0.0) + q.get(k, 0.0)) for k in keys}
    return 0.5 * (kl(p, m) + kl(q, m))


def geo3(a: float, b: float, c: float) -> float:
    """Geometric mean with degeneracy protection."""
    a, b, c = max(a, 1e-12), max(b, 1e-12), max(c, 1e-12)
    return (a * b * c) ** (1.0 / 3.0)


def clamp01(x: float) -> float:
    """Clamp to [0, 1]."""
    return max(0.0, min(1.0, x))


def _vec(counter: Mapping[str, int | float]) -> dict[str, float]:
    """Normalize counter to probability distribution."""
    s = float(sum(counter.values())) or 1.0
    return {k: float(v) / s for k, v in counter.items()}


def parse_version(version_string: str) -> tuple[int, int, int]:
    """Parse version string to tuple for comparison."""
    match = re.search(r'v?(\d+)\.(\d+)\.(\d+)', version_string)
    if match:
        return (int(match.group(1)), int(match.group(2)), int(match.group(3)))
    return (0, 0, 0)


# ============================================================================
# Corpus
# ============================================================================

SPEC = Path("spec")
GLOSSARY = SPEC / "tsc-glossary.md"
DOCS = Path("docs")


def load_specs() -> dict[str, str]:
    """Load all specification markdown files."""
    if not SPEC.exists():
        raise FileNotFoundError(f"Spec directory not found: {SPEC}")
    files = [p for p in SPEC.glob("*.md") if p.is_file()]
    if not files:
        raise FileNotFoundError(f"No markdown files in {SPEC}")
    return {p.name: p.read_text(encoding="utf-8", errors="ignore") for p in files}


# ============================================================================
# Axis Score
# ============================================================================


@dataclass(frozen=True)
class AxisScore:
    """Score for one observation axis with replicates."""

    mean: float
    reps: list[float]
    diag: dict[str, Any]


# ============================================================================
# α-axis: Pattern Stability
# ============================================================================


def _strip_code_and_math(md: str) -> str:
    """Strip fenced code blocks and inline code/math."""
    md = re.sub(r"(?s)```.*?```", " ", md)
    md = re.sub(r"`[^`]*`", " ", md)
    md = re.sub(r"\$[^$]*\$", " ", md)
    return md


def _structure_signature(md: str) -> Counter[str]:
    """Extract structural features from markdown."""
    sig = Counter()
    for lvl, head in re.findall(r"(?m)^(#{1,6})\s+([^\n]+)$", md):
        lvln = len(lvl)
        head_norm = "-".join(tokenize_md(head)[:4])
        sig[f"h{lvln}:{head_norm}"] += 1
    sig["bullets"] += len(re.findall(r"(?m)^\s*[-*+]\s+", md))
    sig["defs"] += len(re.findall(r"(?mi)^\s*definition[:\s]", md))
    return sig


def alpha_axis(params: Params, specs: Mapping[str, str]) -> AxisScore:
    """Compute α_c: pattern stability."""
    full = "\n".join(specs.values())
    viewA = _strip_code_and_math(full)
    vA = _vec(Counter(tokenize_md(viewA)))
    vB = _vec(_structure_signature(full))

    reps = []
    for k in range(64):
        if k % 2 == 0:
            reps.append(math.exp(-params.lambda_alpha * (1.0 - cosine(vA, vB))))
        else:
            masked = {t: v for t, v in vA.items() if len(t) > (2 + (k % 2))}
            js = jensen_shannon(vA, masked)
            reps.append(math.exp(-params.lambda_alpha * js))

    mean = sum(reps) / len(reps)
    return AxisScore(mean=mean, reps=reps, diag={"A_keys": len(vA), "B_keys": len(vB)})


# ============================================================================
# β-axis: Relational Coherence
# ============================================================================


def extract_terms(glossary_text: str) -> set[str]:
    """Extract canonical terms from glossary."""
    terms = set(t.lower() for t in re.findall(r"(?m)^##?\s+([A-Za-z0-9_ -]+)$", glossary_text))
    terms |= set(re.findall(r"\*\*([A-Za-z0-9_ -]+)\*\*", glossary_text))
    return {t.strip().lower() for t in terms if t.strip()}


def _extract_terms(glossary_text: str, specs: Mapping[str, str]) -> set[str]:
    """Extract terms from glossary and specs."""
    terms = extract_terms(glossary_text)
    if not terms:
        for txt in specs.values():
            terms |= set(t.lower() for t in re.findall(r"\*\*([A-Za-z0-9_ -]{3,})\*\*", txt))
    return {t.strip() for t in terms if t.strip()}


def dependency_edges(spec_texts: Mapping[str, str], terms: set[str]) -> list[tuple[str, str]]:
    """Extract file→term dependencies."""
    edges = []
    for fname, txt in spec_texts.items():
        lower = txt.lower()
        for t in terms:
            if t in lower:
                for _ in re.finditer(rf"(see|cf\.?)\s+{re.escape(t)}", lower):
                    edges.append((fname, t))
    return edges


def beta_embeddings(
    specs: Mapping[str, str], terms: set[str]
) -> tuple[dict[str, float], dict[str, float]]:
    """Two relational views."""
    edges = dependency_edges(specs, terms)
    deg = Counter([a for (a, _) in edges]) + Counter([b for (_, b) in edges])
    hist = _vec(deg)

    see = Counter()
    for t in terms:
        pat = re.compile(rf"(see|cf\.?)\s+{re.escape(t)}", re.IGNORECASE)
        see[t] = sum(len(pat.findall(v)) for v in specs.values())
    cross = _vec(see)

    return hist, cross


def pair_coh(params: Params, u: Mapping[str, float], v: Mapping[str, float]) -> float:
    """Compute pairwise coherence."""
    c = cosine(u, v)
    d_struct = 1.0 - c
    d_dist = jensen_shannon(u, v)
    delta = params.theta * d_struct + (1.0 - params.theta) * d_dist
    return math.exp(-params.lambda_beta * delta)


def beta_axis(params: Params, specs: Mapping[str, str], glossary_text: str) -> AxisScore:
    """Compute β_c: relational coherence."""
    terms = _extract_terms(glossary_text, specs) or {"coherence", "witness", "kernel"}

    h1, h2 = beta_embeddings(specs, terms)
    probes = []

    probes.append(pair_coh(params, h1, h2))

    if np is not None and LA is not None:
        keys = sorted(set(h1) | set(h2))
        u = np.array([h1.get(k, 0.0) for k in keys])
        v = np.array([h2.get(k, 0.0) for k in keys])
        if u.any() and v.any():
            u = u / (LA.norm(u) or 1.0)
            v = v / (LA.norm(v) or 1.0)
            r2 = float(u @ v)
            probes.append(clamp01((1.0 + r2) / 2.0))

    probes.append(pair_coh(params, h1, h2))

    reps = [clamp01(p) for p in probes for _ in range(32)]
    mean = sum(reps) / len(reps)
    return AxisScore(mean=mean, reps=reps, diag={"terms": len(terms)})


# ============================================================================
# γ-axis: Process Coherence
# ============================================================================


def gamma_axis(
    params: Params,
    specs_now: Mapping[str, str],
    current_scores: dict[str, float] | None = None,
    current_version: str | None = None
) -> AxisScore:
    """Compute γ_c: process coherence via self-improvement tracking."""
    if not DOCS.exists():
        DOCS.mkdir(exist_ok=True)
        return AxisScore(mean=0.5, reps=[0.5]*64, diag={"note": "No previous report"})
    
    if not current_scores:
        return AxisScore(mean=0.5, reps=[0.5]*64, diag={"note": "No current scores"})
    
    if not current_version:
        current_version = get_version()
    
    current_ver_tuple = parse_version(current_version)
    
    # Find reports from BEFORE current version
    prev_reports = []
    for report_path in DOCS.glob("self-coherence-v*.json"):
        match = re.search(r'self-coherence-(v\d+\.\d+\.\d+)', report_path.name)
        if match:
            report_version = match.group(1)
            report_ver_tuple = parse_version(report_version)
            
            if report_ver_tuple < current_ver_tuple:
                prev_reports.append((report_ver_tuple, report_path))
    
    if not prev_reports:
        return AxisScore(mean=0.5, reps=[0.5]*64, diag={
            "note": "No previous report found",
            "current_version": current_version
        })
    
    prev_reports.sort(reverse=True)
    _, prev_report_path = prev_reports[0]
    
    try:
        prev = json.loads(prev_report_path.read_text(encoding="utf-8"))
        
        roadmap = prev.get('roadmap', {})
        next_step = roadmap.get('next_step', {})
        
        bottleneck = next_step.get('axis')
        target = next_step.get('target_value')
        prev_value = next_step.get('current_value')
        
        if not bottleneck or target is None or prev_value is None:
            return AxisScore(mean=0.5, reps=[0.5]*64, diag={
                "note": "Previous report missing roadmap",
                "prev_report": prev_report_path.name
            })
        
        curr_value = current_scores.get(f'{bottleneck}_c', 0.0)
        
        if curr_value >= target:
            γ_c = 1.0
            achieved = True
        else:
            if target > prev_value:
                progress = (curr_value - prev_value) / (target - prev_value)
                γ_c = max(0.0, min(1.0, progress))
            else:
                γ_c = 0.5
            achieved = False
        
        diag = {
            "prev_report": prev_report_path.name,
            "prev_version": prev.get('version', 'unknown'),
            "current_version": current_version,
            "bottleneck": bottleneck,
            "prev_value": prev_value,
            "curr_value": curr_value,
            "target": target,
            "achieved": achieved,
            "improvement": curr_value - prev_value
        }
        
        reps = [γ_c * (1.0 + 0.01 * ((k % 5) - 2)) for k in range(64)]
        reps = [max(0.0, min(1.0, r)) for r in reps]
        
        return AxisScore(mean=γ_c, reps=reps, diag=diag)
        
    except Exception as e:
        return AxisScore(mean=0.5, reps=[0.5]*64, diag={
            "error": str(e),
            "prev_report": prev_report_path.name
        })


# ============================================================================
# Bootstrap CI
# ============================================================================


def _bootstrap_ci_over_C(
    a_reps: list[float], b_reps: list[float], g_reps: list[float], n_boot: int, seed: int
) -> tuple[float, float]:
    """Bootstrap 95% CI."""
    rng = random.Random(seed)
    if not (a_reps and b_reps and g_reps):
        return (0.0, 0.0)

    means = []
    for _ in range(n_boot):
        a = a_reps[rng.randrange(len(a_reps))]
        b = b_reps[rng.randrange(len(b_reps))]
        g = g_reps[rng.randrange(len(g_reps))]
        C = geo3(a, b, g)
        means.append(C)

    means.sort()
    lo = means[int(0.025 * n_boot)]
    hi = means[int(0.975 * n_boot) - 1]
    return (lo, hi)


# ============================================================================
# S₃ Witness
# ============================================================================


def s3_witness_over_reps(
    a: AxisScore, b: AxisScore, g: AxisScore, ci_lo: float, ci_hi: float
) -> dict[str, Any]:
    """Test S₃ axis-permutation invariance."""
    axis_data = [("α", a.reps), ("β", b.reps), ("γ", g.reps)]
    perms = list(permutations(axis_data))

    diag = {"permutations": {}, "baseline_CI": [ci_lo, ci_hi]}
    all_ok = True

    for perm in perms:
        n = min(len(perm[0][1]), len(perm[1][1]), len(perm[2][1]))
        Cs = [geo3(perm[0][1][i], perm[1][1][i], perm[2][1][i]) for i in range(n)]
        Cmean = sum(Cs) / len(Cs)
        ok = ci_lo <= Cmean <= ci_hi
        all_ok &= ok

        perm_name = "-".join(tag for tag, _ in perm)
        diag["permutations"][perm_name] = {"C_sigma": Cmean, "within_CI": ok}

    diag["passed"] = all_ok
    return diag


# ============================================================================
# Report Generation
# ============================================================================


def measure_self(params: Params = Params()) -> dict[str, Any]:
    """Compute C_Σ(TSC) with full witness verification."""
    current_version = get_version()
    
    specs = load_specs()
    glossary_text = (
        GLOSSARY.read_text(encoding="utf-8", errors="ignore") if GLOSSARY.exists() else ""
    )

    A = alpha_axis(params, specs)
    B = beta_axis(params, specs, glossary_text)
    
    current_scores = {'alpha_c': A.mean, 'beta_c': B.mean, 'gamma_c': 0.0}
    G = gamma_axis(params, specs, current_scores, current_version)

    C = geo3(A.mean, B.mean, G.mean)
    ci_lo, ci_hi = _bootstrap_ci_over_C(A.reps, B.reps, G.reps, params.n_boot, params.seed)

    s3_diag = s3_witness_over_reps(A, B, G, ci_lo, ci_hi)

    verdict = "PASS" if (ci_lo >= params.Theta and s3_diag["passed"]) else "FAIL"

    scores_only = {'alpha': A.mean, 'beta': B.mean, 'gamma': G.mean}
    bottleneck_axis = min(scores_only, key=scores_only.get)
    bottleneck_score = scores_only[bottleneck_axis]

    try:
        git_commit = subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"], text=True
        ).strip()
        dirty = bool(subprocess.check_output(["git", "status", "--porcelain"], text=True).strip())
    except Exception:
        git_commit, dirty = "unknown", False

    report = {
        "version": current_version,
        "date": datetime.now(timezone.utc).isoformat(),
        "verdict": verdict,
        "scores": {
            "alpha_c": A.mean,
            "beta_c": B.mean,
            "gamma_c": G.mean,
            "C_sigma": C
        },
        "ci": {
            "C_sigma_lo": ci_lo,
            "C_sigma_hi": ci_hi,
            "n_boot": params.n_boot
        },
        "bottleneck": {
            "axis": bottleneck_axis,
            "score": bottleneck_score,
            "identified_at": current_version
        },
        "roadmap": {
            "next_step": {
                "axis": bottleneck_axis,
                "current_value": bottleneck_score,
                "target_value": 0.85,
                "rationale": f"Improve {bottleneck_axis} axis to raise C_Σ above threshold"
            }
        },
        "witnesses": {
            "S3_permutation": s3_diag
        },
        "axes_diag": {
            "alpha": A.diag,
            "beta": B.diag,
            "gamma": G.diag
        },
        "params": asdict(params),
        "provenance": {
            "git_commit": git_commit,
            "dirty": dirty,
            "python": platform.python_version(),
            "spec_files": sorted(list(specs.keys()))
        }
    }
    
    return report


def write_report(params: Params = Params()) -> dict[str, Any]:
    """Compute measurement and write JSON report."""
    report = measure_self(params)
    
    DOCS.mkdir(exist_ok=True)
    
    version = report['version']
    json_path = DOCS / f"self-coherence-{version}.json"
    json_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    
    print(f"✅ Written: {json_path}")
    
    return report


if __name__ == "__main__":
    print("Running TSC self-measurement...")
    try:
        report = write_report()
        print(json.dumps(report, indent=2))
        if report["verdict"] != "PASS":
            raise SystemExit(1)
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        raise SystemExit(2)