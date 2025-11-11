"""
reference/python/tsc_measure.py — TSC Coherence Measurement

Computes TSC coherence scores and writes to .tsc/tsc-v*.json
"""

from __future__ import annotations

import json
import math
import platform
import random
import re
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


def get_version() -> str:
    try:
        import tomllib
    except ImportError:
        try:
            import tomli as tomllib
        except:
            return "v3.1.0"
    
    pyproject = Path(__file__).parent.parent.parent / "pyproject.toml"
    if not pyproject.exists():
        return "v3.1.0"
    
    with open(pyproject, "rb") as f:
        data = tomllib.load(f)
        return f"v{data['project']['version']}"


@dataclass(frozen=True)
class Params:
    theta: float = 0.7
    lambda_alpha: float = 4.0
    lambda_beta: float = 4.0
    lambda_gamma: float = 4.0
    n_boot: int = 1000
    Theta: float = 0.90
    seed: int = 42


_TOKEN_PATTERN = re.compile(r"[A-Za-z0-9_≡αβγλΣΔ∧∨⊙⊗→←↔≈≃≤≥]+")

def tokenize_md(text: str) -> list[str]:
    text = unicodedata.normalize("NFKC", text)
    return [t.lower() for t in _TOKEN_PATTERN.findall(text)]

def cosine(u: Mapping[str, float], v: Mapping[str, float]) -> float:
    keys = set(u) | set(v)
    num = sum(u.get(k, 0.0) * v.get(k, 0.0) for k in keys)
    du = math.sqrt(sum((u.get(k, 0.0) ** 2) for k in keys))
    dv = math.sqrt(sum((v.get(k, 0.0) ** 2) for k in keys))
    return 0.0 if du == 0.0 or dv == 0.0 else num / (du * dv)

def jensen_shannon(p: Mapping[str, float], q: Mapping[str, float]) -> float:
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
    a, b, c = max(a, 1e-12), max(b, 1e-12), max(c, 1e-12)
    return (a * b * c) ** (1.0 / 3.0)

def clamp01(x: float) -> float:
    return max(0.0, min(1.0, x))

def _vec(counter: Mapping[str, int | float]) -> dict[str, float]:
    s = float(sum(counter.values())) or 1.0
    return {k: float(v) / s for k, v in counter.items()}

def parse_version(version_string: str) -> tuple[int, int, int]:
    match = re.search(r'v?(\d+)\.(\d+)\.(\d+)', version_string)
    if match:
        return (int(match.group(1)), int(match.group(2)), int(match.group(3)))
    return (0, 0, 0)

SPEC = Path("spec")
GLOSSARY = SPEC / "tsc-glossary.md"
TSC = Path(".tsc")  # TSC measurement blocks (hidden dir)

def load_specs() -> dict[str, str]:
    if not SPEC.exists():
        raise FileNotFoundError(f"Spec directory not found: {SPEC}")
    files = [p for p in SPEC.glob("*.md") if p.is_file()]
    if not files:
        raise FileNotFoundError(f"No markdown files in {SPEC}")
    return {p.name: p.read_text(encoding="utf-8", errors="ignore") for p in files}

@dataclass(frozen=True)
class AxisScore:
    mean: float
    reps: list[float]
    diag: dict[str, Any]

def _strip_code_and_math(md: str) -> str:
    md = re.sub(r"(?s)```.*?```", " ", md)
    md = re.sub(r"`[^`]*`", " ", md)
    md = re.sub(r"\$[^$]*\$", " ", md)
    return md

def _structure_signature(md: str) -> Counter[str]:
    sig = Counter()
    for lvl, head in re.findall(r"(?m)^(#{1,6})\s+([^\n]+)$", md):
        lvln = len(lvl)
        head_norm = "-".join(tokenize_md(head)[:4])
        sig[f"h{lvln}:{head_norm}"] += 1
    sig["bullets"] += len(re.findall(r"(?m)^\s*[-*+]\s+", md))
    sig["defs"] += len(re.findall(r"(?mi)^\s*definition[:\s]", md))
    return sig

def alpha_axis(params: Params, specs: Mapping[str, str]) -> AxisScore:
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

def extract_terms(glossary_text: str) -> set[str]:
    terms = set(t.lower() for t in re.findall(r"(?m)^##?\s+([A-Za-z0-9_ -]+)$", glossary_text))
    terms |= set(re.findall(r"\*\*([A-Za-z0-9_ -]+)\*\*", glossary_text))
    return {t.strip().lower() for t in terms if t.strip()}

def _extract_terms(glossary_text: str, specs: Mapping[str, str]) -> set[str]:
    terms = extract_terms(glossary_text)
    if not terms:
        for txt in specs.values():
            terms |= set(t.lower() for t in re.findall(r"\*\*([A-Za-z0-9_ -]{3,})\*\*", txt))
    return {t.strip() for t in terms if t.strip()}

def dependency_edges(spec_texts: Mapping[str, str], terms: set[str]) -> list[tuple[str, str]]:
    edges = []
    for fname, txt in spec_texts.items():
        lower = txt.lower()
        for t in terms:
            if t in lower:
                for _ in re.finditer(rf"(see|cf\.?)\s+{re.escape(t)}", lower):
                    edges.append((fname, t))
    return edges

def beta_embeddings(specs: Mapping[str, str], terms: set[str]) -> tuple[dict[str, float], dict[str, float]]:
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
    c = cosine(u, v)
    d_struct = 1.0 - c
    d_dist = jensen_shannon(u, v)
    delta = params.theta * d_struct + (1.0 - params.theta) * d_dist
    return math.exp(-params.lambda_beta * delta)

def beta_axis(params: Params, specs: Mapping[str, str], glossary_text: str) -> AxisScore:
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

def _bootstrap_ci_over_C(a_reps: list[float], b_reps: list[float], g_reps: list[float], n_boot: int, seed: int) -> tuple[float, float]:
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

def s3_witness_over_reps(a: AxisScore, b: AxisScore, g: AxisScore, ci_lo: float, ci_hi: float) -> dict[str, Any]:
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

def load_previous_report(current_version: str) -> dict | None:
    """Load the most recent report before current_version."""
    if not TSC.exists():
        return None
    
    current_ver_tuple = parse_version(current_version)
    prev_reports = []
    
    for report_path in TSC.glob("tsc-v*.json"):
        match = re.search(r'tsc-(v\d+\.\d+\.\d+)', report_path.name)
        if match:
            report_version = match.group(1)
            report_ver_tuple = parse_version(report_version)
            if report_ver_tuple < current_ver_tuple:
                prev_reports.append((report_ver_tuple, report_path))
    
    if not prev_reports:
        return None
    
    prev_reports.sort(reverse=True)
    _, prev_report_path = prev_reports[0]
    
    try:
        return json.loads(prev_report_path.read_text(encoding="utf-8"))
    except Exception:
        return None

def measure_self(params: Params = Params()) -> dict[str, Any]:
    """Compute C_Σ(TSC) with past/present/future structure."""
    current_version = get_version()
    
    specs = load_specs()
    glossary_text = GLOSSARY.read_text(encoding="utf-8", errors="ignore") if GLOSSARY.exists() else ""

    # Compute α and β
    A = alpha_axis(params, specs)
    B = beta_axis(params, specs, glossary_text)
    
    # Load previous report
    prev_report = load_previous_report(current_version)
    
    # Compute γ_c based on achievement of previous roadmap
    # γ measures health of the generative process that creates specs
    
    # Baseline: Current health = geometric mean of outputs (α, β)
    baseline_health = math.sqrt(A.mean * B.mean)
    
    γ_c = baseline_health  # Default: current process health
    achievement = None
    
    if prev_report and 'roadmap' in prev_report and 'next_target' in prev_report['roadmap']:
        prev_roadmap = prev_report['roadmap']['next_target']
        target_axis = prev_roadmap['axis']
        start_value = prev_roadmap['current_value']
        target_value = prev_roadmap['target_value']
        
        # Get current value for that axis
        current_scores = {'alpha_c': A.mean, 'beta_c': B.mean}
        actual_value = current_scores.get(f'{target_axis}_c', 0.0)
        improvement = actual_value - start_value
        
        # Calculate γ_c (no hardcoded constants)
        if actual_value >= target_value:
            γ_c = 1.0  # Process proved it can self-improve!
            target_reached = True
        else:
            target_reached = False
            if target_value > start_value:
                progress = (actual_value - start_value) / (target_value - start_value)
                progress = max(0.0, min(1.0, progress))
                # Process health = baseline + (remaining distance to full health) × progress
                γ_c = baseline_health + (1.0 - baseline_health) * progress
            else:
                γ_c = baseline_health
        
        achievement = {
            "target_reached": target_reached,
            "target_axis": target_axis,
            "start_value": start_value,
            "target_value": target_value,
            "actual_value": actual_value,
            "improvement": improvement,
            "gamma_c": γ_c,
            "baseline_health": baseline_health
        }
    
    # γ for C_Σ calculation (reps for bootstrap)
    γ_reps = [γ_c * (1.0 + 0.01 * ((k % 5) - 2)) for k in range(64)]
    γ_reps = [max(0.0, min(1.0, r)) for r in γ_reps]

    C = geo3(A.mean, B.mean, γ_c)
    ci_lo, ci_hi = _bootstrap_ci_over_C(A.reps, B.reps, γ_reps, params.n_boot, params.seed)
    
    γ_score = AxisScore(mean=γ_c, reps=γ_reps, diag={"achievement": achievement})
    s3_diag = s3_witness_over_reps(A, B, γ_score, ci_lo, ci_hi)
    verdict = "PASS" if (ci_lo >= params.Theta and s3_diag["passed"]) else "FAIL"

    # Identify current bottleneck (only α and β, γ is meta-metric)
    scores_only = {'alpha': A.mean, 'beta': B.mean}
    bottleneck_axis = min(scores_only, key=scores_only.get)
    bottleneck_score = scores_only[bottleneck_axis]

    # Provenance
    try:
        git_commit = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], text=True).strip()
        dirty = bool(subprocess.check_output(["git", "status", "--porcelain"], text=True).strip())
    except Exception:
        git_commit, dirty = "unknown", False

    report = {
        "version": current_version,
        "date": datetime.now(timezone.utc).isoformat(),
        "verdict": verdict,
        "current": {
            "scores": {
                "alpha_c": A.mean,
                "beta_c": B.mean,
                "gamma_c": γ_c,
                "C_sigma": C
            },
            "ci": {
                "C_sigma_lo": ci_lo,
                "C_sigma_hi": ci_hi,
                "n_boot": params.n_boot
            },
            "bottleneck": {
                "axis": bottleneck_axis,
                "score": bottleneck_score
            }
        },
        "roadmap": {
            "next_target": {
                "axis": bottleneck_axis,
                "current_value": bottleneck_score,
                "target_value": min(0.85, bottleneck_score + 0.30),
                "rationale": f"Improve {bottleneck_axis} axis to raise C_Σ above threshold"
            }
        },
        "witnesses": {
            "S3_permutation": s3_diag
        },
        "axes_diag": {
            "alpha": A.diag,
            "beta": B.diag,
            "gamma": γ_score.diag
        },
        "params": asdict(params),
        "provenance": {
            "git_commit": git_commit,
            "dirty": dirty,
            "python": platform.python_version(),
            "spec_files": sorted(list(specs.keys()))
        }
    }
    
    # Add historical if we have previous data
    if prev_report:
        prev_scores = prev_report.get('current', {}).get('scores') or prev_report.get('scores', {})
        prev_roadmap = prev_report.get('roadmap', {}).get('next_target')
        
        report["historical"] = {
            "previous_version": prev_report.get('version', 'unknown'),
            "previous_scores": {
                "alpha_c": prev_scores.get('alpha_c', 0.0),
                "beta_c": prev_scores.get('beta_c', 0.0),
                "gamma_c": prev_scores.get('gamma_c', 0.0),
                "C_sigma": prev_scores.get('C_sigma', 0.0)
            },
            "previous_roadmap": prev_roadmap,
            "achievement": achievement,
            "changes": {
                "alpha_c": A.mean - prev_scores.get('alpha_c', 0.0),
                "beta_c": B.mean - prev_scores.get('beta_c', 0.0),
                "gamma_c": γ_c - prev_scores.get('gamma_c', 0.0),
                "C_sigma": C - prev_scores.get('C_sigma', 0.0)
            }
        }
    
    return report

def generate_readme() -> str:
    """Generate README.md content from all tsc-v*.json files."""
    if not TSC.exists():
        return "# TSC Coherence Tracker\n\nNo measurements found.\n"
    
    json_files = sorted(TSC.glob("tsc-v*.json"))
    if not json_files:
        return "# TSC Coherence Tracker\n\nNo measurements found.\n"
    
    # Parse all reports
    reports = []
    for json_path in json_files:
        try:
            data = json.loads(json_path.read_text())
            reports.append(data)
        except Exception:
            continue
    
    if not reports:
        return "# TSC Coherence Tracker\n\nNo measurements found.\n"
    
    # Sort by version
    def version_key(report):
        version = report.get('version', 'v0.0.0')
        return parse_version(version)
    
    reports.sort(key=version_key)
    
    # Generate markdown
    md = "# TSC Coherence Tracker\n\n"
    md += "> Auto-generated from `.tsc/tsc-v*.json`\n\n"
    md += "## Coherence Scores Over Time\n\n"
    
    # Main scores table
    md += "| Version | Date | α | β | γ | C_Σ | Verdict | Bottleneck |\n"
    md += "|---------|------|---|---|---|-----|---------|------------|\n"
    
    for report in reports:
        version = report.get('version', 'unknown')
        date = report.get('date', '')[:10]
        scores = report.get('current', {}).get('scores', {})
        verdict = report.get('verdict', 'UNKNOWN')
        bottleneck = report.get('current', {}).get('bottleneck', {})
        
        alpha = scores.get('alpha_c', 0.0)
        beta = scores.get('beta_c', 0.0)
        gamma = scores.get('gamma_c', 0.0)
        c_sigma = scores.get('C_sigma', 0.0)
        
        verdict_icon = "✅" if verdict == "PASS" else "❌"
        bottleneck_axis = bottleneck.get('axis', '?')
        bottleneck_score = bottleneck.get('score', 0.0)
        
        md += f"| {version} | {date} | {alpha:.3f} | {beta:.3f} | {gamma:.3f} | {c_sigma:.3f} | {verdict_icon} | {bottleneck_axis} ({bottleneck_score:.3f}) |\n"
    
    # Achievement tracking
    md += "\n## Achievement Tracking\n\n"
    md += "Shows whether each version delivered on its previous roadmap promise.\n\n"
    md += "| Version | Target Axis | Start | Target | Actual | Δ | γ_c | Status |\n"
    md += "|---------|-------------|-------|--------|--------|---|-----|--------|\n"
    
    for report in reports:
        version = report.get('version', 'unknown')
        hist = report.get('historical', {})
        
        if not hist or not hist.get('achievement'):
            md += f"| {version} | — | — | — | — | — | 0.500 | (baseline) |\n"
        else:
            ach = hist['achievement']
            target_axis = ach.get('target_axis', '?')
            start = ach.get('start_value', 0.0)
            target = ach.get('target_value', 0.0)
            actual = ach.get('actual_value', 0.0)
            improvement = ach.get('improvement', 0.0)
            gamma_c = ach.get('gamma_c', 0.0)
            reached = ach.get('target_reached', False)
            
            status = "✅ Achieved" if reached else "⚠️ Missed"
            
            md += f"| {version} | {target_axis} | {start:.3f} | {target:.3f} | {actual:.3f} | {improvement:+.3f} | {gamma_c:.3f} | {status} |\n"
    
    # Roadmap tracking
    md += "\n## Roadmap Declarations\n\n"
    md += "What each version promised to improve next.\n\n"
    md += "| Version | Declares | Current | Target | Required Δ |\n"
    md += "|---------|----------|---------|--------|------------|\n"
    
    for report in reports:
        version = report.get('version', 'unknown')
        roadmap = report.get('roadmap', {}).get('next_target', {})
        
        if roadmap:
            axis = roadmap.get('axis', '?')
            current = roadmap.get('current_value', 0.0)
            target = roadmap.get('target_value', 0.0)
            delta = target - current
            
            md += f"| {version} | {axis} | {current:.3f} | {target:.3f} | +{delta:.3f} |\n"
    
    # Changes over time
    md += "\n## Changes Between Versions\n\n"
    md += "| From → To | Δα | Δβ | Δγ | ΔC_Σ |\n"
    md += "|-----------|----|----|----|----|--|\n"
    
    for i in range(1, len(reports)):
        prev = reports[i-1]
        curr = reports[i]
        
        prev_version = prev.get('version', '?')
        curr_version = curr.get('version', '?')
        
        changes = curr.get('historical', {}).get('changes', {})
        
        if changes:
            d_alpha = changes.get('alpha_c', 0.0)
            d_beta = changes.get('beta_c', 0.0)
            d_gamma = changes.get('gamma_c', 0.0)
            d_c_sigma = changes.get('C_sigma', 0.0)
            
            def fmt_delta(d):
                sign = "+" if d >= 0 else ""
                return f"{sign}{d:.3f}"
            
            md += f"| {prev_version} → {curr_version} | {fmt_delta(d_alpha)} | {fmt_delta(d_beta)} | {fmt_delta(d_gamma)} | {fmt_delta(d_c_sigma)} |\n"
    
    # Summary stats
    md += "\n## Summary Statistics\n\n"
    
    if reports:
        first = reports[0]
        last = reports[-1]
        
        first_scores = first.get('current', {}).get('scores', {})
        last_scores = last.get('current', {}).get('scores', {})
        
        md += f"**Total Progress ({first.get('version')} → {last.get('version')})**\n\n"
        
        for axis in ['alpha_c', 'beta_c', 'gamma_c', 'C_sigma']:
            label = axis.replace('_c', '').replace('C_sigma', 'C_Σ')
            start = first_scores.get(axis, 0.0)
            end = last_scores.get(axis, 0.0)
            delta = end - start
            pct = (delta / start * 100) if start > 0 else 0
            
            md += f"- **{label}**: {start:.3f} → {end:.3f} ({delta:+.3f}, {pct:+.1f}%)\n"
    
    md += "\n---\n\n"
    md += f"*Last updated: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')} UTC*\n"
    md += f"*Generated from {len(reports)} measurement(s)*\n"
    
    return md

def write_report(out: str | None = None, params: Params = Params()) -> dict[str, Any]:
    """Write measurement report to .tsc/tsc-{version}.json and update README.md
    
    Args:
        out: Ignored (kept for CLI backward compatibility)
        params: Measurement parameters
    """
    report = measure_self(params)
    TSC.mkdir(exist_ok=True)
    
    # Write JSON
    version = report['version']
    json_path = TSC / f"tsc-{version}.json"
    json_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"✅ Written: {json_path}")
    
    # Auto-generate README
    readme_content = generate_readme()
    readme_path = TSC / "README.md"
    readme_path.write_text(readme_content, encoding="utf-8")
    print(f"✅ Updated: {readme_path}")
    
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