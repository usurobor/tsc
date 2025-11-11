#!/usr/bin/env python3
"""
README Measurement Tool

Implements TSC measurement methodology for README documents.
See .tsc/methodologies/readme.md for full specification.
"""

import re
import os
import json
import math
import subprocess
from pathlib import Path
from collections import Counter
from dataclasses import dataclass
from typing import Optional, List, Dict, Any
from datetime import datetime


@dataclass
class WitnessResult:
    """Result of a witness check"""
    name: str
    passed: bool
    details: Dict[str, Any]


@dataclass
class MeasurementResult:
    """Result of README measurement"""
    version: str
    date: str
    commit_hash: str
    witnesses: List[WitnessResult]
    verdict: str  # PASS, FAIL, or FAIL_DEGENERATE
    failed_witness: Optional[str]
    alpha: Optional[float]
    beta: Optional[float]
    gamma: Optional[float]
    c_sigma: Optional[float]
    alpha_details: Optional[Dict[str, Any]]
    beta_details: Optional[Dict[str, Any]]


# ============================================================================
# WITNESSES
# ============================================================================

def check_accuracy_witness(readme_text: str, base_path: Path) -> WitnessResult:
    """Check if all internal file links are valid"""
    links = re.findall(r'\[([^\]]+)\]\(([^)]+)\)', readme_text)
    broken_links = []
    
    for label, path in links:
        # Skip external URLs and anchor links
        if path.startswith('http') or path.startswith('#'):
            continue
        
        # Strip anchor fragment before checking existence
        file_path_str = path.split('#')[0]
        
        # Resolve file path
        if file_path_str.startswith('./'):
            file_path = base_path / file_path_str[2:]
        elif file_path_str.startswith('../'):
            file_path = base_path / file_path_str
        else:
            file_path = base_path / file_path_str
        
        if not file_path.exists():
            broken_links.append({'label': label, 'path': path})
    
    return WitnessResult(
        name='accuracy',
        passed=len(broken_links) == 0,
        details={
            'total_internal_links': len([l for l in links 
                                         if not l[1].startswith('http') 
                                         and not l[1].startswith('#')]),
            'broken_links': broken_links
        }
    )


def check_staleness_witness(readme_text: str, cli_path: Optional[Path] = None) -> WitnessResult:
    """Check if documentation matches implementation"""
    issues = []
    
    # Check for --out flag claim
    if '--out' in readme_text:
        # If CLI path provided, check if it actually supports --out
        if cli_path and cli_path.exists():
            cli_content = cli_path.read_text()
            if 'out' not in cli_content or 'deprecated' in cli_content.lower():
                issues.append("Claims --out flag but CLI doesn't support it")
        else:
            issues.append("Claims --out flag (verification skipped - no CLI path)")
    
    return WitnessResult(
        name='staleness',
        passed=len(issues) == 0,
        details={'issues': issues}
    )


def check_completeness_witness(readme_text: str) -> WitnessResult:
    """Check if required sections are present"""
    h2_headers = [m.group(1).lower() for m in re.finditer(r'(?m)^##\s+([^\n]+)$', readme_text)]
    
    required_sections = ['installation', 'contributing', 'license']
    missing = [s for s in required_sections if not any(s in h for h in h2_headers)]
    
    return WitnessResult(
        name='completeness',
        passed=len(missing) == 0,
        details={
            'required': required_sections,
            'missing': missing,
            'found_headers': h2_headers
        }
    )


def check_purpose_witness(readme_text: str) -> WitnessResult:
    """Check if document serves its stated audiences"""
    h2_headers = [m.group(1).lower() for m in re.finditer(r'(?m)^##\s+([^\n]+)$', readme_text)]
    
    stated_audiences = ['engineer', 'philosopher', 'researcher', 'ai']
    found_audiences = [a for a in stated_audiences if any(a in h for h in h2_headers)]
    
    return WitnessResult(
        name='purpose',
        passed=len(found_audiences) >= 3,
        details={
            'stated_audiences': stated_audiences,
            'found_audiences': found_audiences,
            'count': len(found_audiences)
        }
    )


def run_witnesses(readme_text: str, base_path: Path, cli_path: Optional[Path] = None) -> tuple[List[WitnessResult], str, Optional[str]]:
    """
    Run all witnesses and determine verdict
    
    Returns:
        witnesses: List of witness results
        verdict: PASS, FAIL, or FAIL_DEGENERATE
        failed_witness: Name of failed critical witness, or None
    """
    witnesses = [
        check_accuracy_witness(readme_text, base_path),
        check_staleness_witness(readme_text, cli_path),
        check_completeness_witness(readme_text),
        check_purpose_witness(readme_text)
    ]
    
    # Check critical witnesses (first 3)
    critical_witnesses = ['accuracy', 'staleness', 'completeness']
    for witness in witnesses:
        if witness.name in critical_witnesses and not witness.passed:
            return witnesses, 'FAIL_DEGENERATE', witness.name
    
    # All critical witnesses passed - measurement is valid
    return witnesses, 'PASS', None


# ============================================================================
# ALPHA MEASUREMENT (Pattern Coherence)
# ============================================================================

def tokenize(text: str) -> List[str]:
    """Tokenize text (strip code blocks, extract words)"""
    text = text.lower()
    # Remove code blocks
    text = re.sub(r'(?s)```.*?```', ' ', text)
    # Remove inline code
    text = re.sub(r'`[^`]*`', ' ', text)
    # Extract words
    return re.findall(r'[a-z0-9_]+', text)


def measure_alpha(readme_text: str) -> tuple[float, Dict[str, Any]]:
    """
    Measure pattern coherence (do headers match content?)
    
    Returns:
        alpha: Score [0, 1]
        details: Diagnostic information
    """
    # Extract content tokens
    content_tokens = tokenize(readme_text)
    content_counts = Counter(content_tokens)
    
    # Extract structure
    structure = Counter()
    
    # Headers
    for lvl, head in re.findall(r'(?m)^(#{1,6})\s+([^\n]+)$', readme_text):
        lvln = len(lvl)
        head_norm = '-'.join(tokenize(head)[:4])
        structure[f"h{lvln}:{head_norm}"] += 1
    
    # Bullets
    structure["bullets"] = len(re.findall(r'(?m)^\s*[-*+]\s+', readme_text))
    
    # Bold terms
    structure["bold"] = len(re.findall(r'\*\*[^*]+\*\*', readme_text))
    
    # Normalize to probability distributions
    def normalize(counter):
        total = sum(counter.values()) or 1
        return {k: v/total for k, v in counter.items()}
    
    content_vec = normalize(content_counts)
    structure_vec = normalize(structure)
    
    # Cosine similarity
    def cosine(u, v):
        keys = set(u) | set(v)
        num = sum(u.get(k, 0) * v.get(k, 0) for k in keys)
        du = math.sqrt(sum(u.get(k, 0)**2 for k in keys))
        dv = math.sqrt(sum(v.get(k, 0)**2 for k in keys))
        return num / (du * dv) if du and dv else 0.0
    
    # Jensen-Shannon divergence
    def jensen_shannon(p, q):
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
    
    cos_sim = cosine(content_vec, structure_vec)
    js_div = jensen_shannon(content_vec, structure_vec)
    
    # Compute alpha
    theta = 0.7
    lambda_alpha = 4.0
    distance = theta * (1 - cos_sim) + (1 - theta) * js_div
    alpha = math.exp(-lambda_alpha * distance)
    
    details = {
        'content_tokens': len(content_counts),
        'structure_elements': len(structure),
        'cos_sim': cos_sim,
        'js_div': js_div,
        'distance': distance
    }
    
    return alpha, details


# ============================================================================
# BETA MEASUREMENT (Relational Coherence)
# ============================================================================

def measure_beta(readme_text: str) -> tuple[float, Dict[str, Any]]:
    """
    Measure relational coherence (are cross-references working?)
    
    Returns:
        beta: Score [0, 1]
        details: Diagnostic information
    """
    # Extract bold terms as proxy for glossary
    terms = set()
    for match in re.findall(r'\*\*([^*]+)\*\*', readme_text):
        term = match.strip().lower()
        if 2 < len(term) < 30:
            terms.add(term)
    
    # Find explicit cross-references
    cross_refs = []
    for term in terms:
        pattern = re.compile(rf'(see|cf\.?|→)\s+[^\n]*{re.escape(term)}', re.IGNORECASE)
        matches = pattern.findall(readme_text)
        if matches:
            cross_refs.append((term, len(matches)))
    
    # Count total links
    total_links = len(re.findall(r'\[([^\]]+)\]\(([^)]+)\)', readme_text))
    
    # Embedding 1: Term frequency (degree distribution)
    degree_counts = Counter()
    for term in terms:
        count = readme_text.lower().count(term)
        if count > 0:
            degree_counts[term] = count
    
    # Embedding 2: Explicit cross-reference counts
    cross_ref_counts = Counter(dict(cross_refs))
    
    # Normalize
    def normalize(counter):
        total = sum(counter.values()) or 1
        return {k: v/total for k, v in counter.items()}
    
    hist1 = normalize(degree_counts)
    hist2 = normalize(cross_ref_counts) if cross_ref_counts else {}
    
    if hist2:
        # Compute similarity
        def cosine(u, v):
            keys = set(u) | set(v)
            num = sum(u.get(k, 0) * v.get(k, 0) for k in keys)
            du = math.sqrt(sum(u.get(k, 0)**2 for k in keys))
            dv = math.sqrt(sum(v.get(k, 0)**2 for k in keys))
            return num / (du * dv) if du and dv else 0.0
        
        def jensen_shannon(p, q):
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
        
        cos_sim = cosine(hist1, hist2)
        js_div = jensen_shannon(hist1, hist2)
        
        # Compute beta
        theta = 0.7
        lambda_beta = 4.0
        distance = theta * (1 - cos_sim) + (1 - theta) * js_div
        beta = math.exp(-lambda_beta * distance)
    else:
        cos_sim = 0.0
        js_div = 1.0
        beta = 0.0
    
    details = {
        'terms': len(terms),
        'cross_refs': len(cross_refs),
        'total_links': total_links,
        'cos_sim': cos_sim,
        'js_div': js_div
    }
    
    return beta, details


# ============================================================================
# GAMMA MEASUREMENT (Trajectory)
# ============================================================================

def measure_gamma(alpha: float, beta: float, prev_measurement: Optional[MeasurementResult]) -> tuple[float, Dict[str, Any]]:
    """
    Measure trajectory (is README evolving coherently?)
    
    Returns:
        gamma: Score [0, 1]
        details: Diagnostic information
    """
    baseline_health = math.sqrt(alpha * beta)
    
    if prev_measurement and prev_measurement.c_sigma is not None:
        # Compute improvement
        prev_c_sigma = prev_measurement.c_sigma
        curr_c_sigma = (alpha * beta * baseline_health) ** (1/3)
        
        improvement = (curr_c_sigma - prev_c_sigma) / prev_c_sigma if prev_c_sigma > 0 else 0.0
        
        # Apply formula
        gamma = baseline_health + (1.0 - baseline_health) * improvement
        gamma = max(0.0, min(1.0, gamma))  # Clamp to [0, 1]
        
        details = {
            'baseline_health': baseline_health,
            'prev_c_sigma': prev_c_sigma,
            'curr_c_sigma': curr_c_sigma,
            'improvement': improvement,
            'formula': 'baseline + (1 - baseline) * improvement'
        }
    else:
        # No history - use baseline
        gamma = baseline_health
        details = {
            'baseline_health': baseline_health,
            'formula': 'sqrt(alpha * beta)'
        }
    
    return gamma, details


# ============================================================================
# GIT HISTORY
# ============================================================================

def get_readme_history(repo_path: Path, limit: int = 10) -> List[Dict[str, str]]:
    """Get README commit history from git"""
    try:
        result = subprocess.run(
            ['git', 'log', '--format=%H|%ai|%s', '--follow', '--', 'README.md'],
            cwd=repo_path,
            capture_output=True,
            text=True,
            check=True
        )
        
        commits = []
        for line in result.stdout.strip().split('\n'):
            if '|' in line:
                hash_val, date, subject = line.split('|', 2)
                commits.append({
                    'hash': hash_val,
                    'date': date,
                    'subject': subject
                })
        
        return commits[:limit]
    except subprocess.CalledProcessError:
        return []


def get_readme_at_commit(repo_path: Path, commit_hash: str) -> Optional[str]:
    """Get README content at specific commit"""
    try:
        result = subprocess.run(
            ['git', 'show', f'{commit_hash}:README.md'],
            cwd=repo_path,
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout
    except subprocess.CalledProcessError:
        return None


# ============================================================================
# MAIN MEASUREMENT FUNCTION
# ============================================================================

def measure_readme(
    readme_path: Path,
    repo_path: Optional[Path] = None,
    cli_path: Optional[Path] = None,
    prev_measurement: Optional[MeasurementResult] = None
) -> MeasurementResult:
    """
    Measure README coherence
    
    Args:
        readme_path: Path to README.md
        repo_path: Path to git repo root (for history)
        cli_path: Path to CLI file (for staleness check)
        prev_measurement: Previous measurement for gamma
    
    Returns:
        MeasurementResult with full details
    """
    if not readme_path.exists():
        raise FileNotFoundError(f"README not found: {readme_path}")
    
    readme_text = readme_path.read_text()
    base_path = readme_path.parent
    
    # Get version info
    version = "current"
    commit_hash = "unknown"
    if repo_path:
        try:
            result = subprocess.run(
                ['git', 'rev-parse', '--short', 'HEAD'],
                cwd=repo_path,
                capture_output=True,
                text=True,
                check=True
            )
            commit_hash = result.stdout.strip()
        except:
            pass
    
    # Run witnesses
    witnesses, verdict, failed_witness = run_witnesses(readme_text, base_path, cli_path)
    
    # If witnesses fail, don't measure
    if verdict == 'FAIL_DEGENERATE':
        return MeasurementResult(
            version=version,
            date=datetime.now().isoformat(),
            commit_hash=commit_hash,
            witnesses=witnesses,
            verdict=verdict,
            failed_witness=failed_witness,
            alpha=None,
            beta=None,
            gamma=None,
            c_sigma=None,
            alpha_details=None,
            beta_details=None
        )
    
    # Measure alpha and beta
    alpha, alpha_details = measure_alpha(readme_text)
    beta, beta_details = measure_beta(readme_text)
    
    # Measure gamma
    gamma, gamma_details = measure_gamma(alpha, beta, prev_measurement)
    
    # Compute C_Σ
    c_sigma = (alpha * beta * gamma) ** (1/3)
    
    # Determine final verdict
    if c_sigma >= 0.80:
        verdict = 'PASS'
    else:
        verdict = 'FAIL'
    
    return MeasurementResult(
        version=version,
        date=datetime.now().isoformat(),
        commit_hash=commit_hash,
        witnesses=witnesses,
        verdict=verdict,
        failed_witness=None,
        alpha=alpha,
        beta=beta,
        gamma=gamma,
        c_sigma=c_sigma,
        alpha_details=alpha_details,
        beta_details=beta_details
    )


# ============================================================================
# REPORTING
# ============================================================================

def print_measurement_report(result: MeasurementResult):
    """Print human-readable measurement report"""
    print("=" * 70)
    print("README MEASUREMENT REPORT")
    print("=" * 70)
    
    print(f"\nVersion: {result.version}")
    print(f"Date: {result.date[:10]}")
    print(f"Commit: {result.commit_hash}")
    
    print(f"\n{'='*70}")
    print("WITNESSES")
    print("=" * 70)
    
    for witness in result.witnesses:
        status = '✅ PASS' if witness.passed else '❌ FAIL'
        print(f"\n{witness.name.upper()}: {status}")
        
        if not witness.passed:
            if witness.name == 'accuracy':
                broken = witness.details.get('broken_links', [])
                print(f"  Broken links ({len(broken)}):")
                for link in broken[:5]:
                    print(f"    - {link['path']}")
            elif witness.name == 'staleness':
                for issue in witness.details.get('issues', []):
                    print(f"    - {issue}")
            elif witness.name == 'completeness':
                missing = witness.details.get('missing', [])
                print(f"    - Missing sections: {', '.join(missing)}")
            elif witness.name == 'purpose':
                found = witness.details.get('found_audiences', [])
                print(f"    - Found only {len(found)} audience sections")
    
    print(f"\n{'='*70}")
    print(f"VERDICT: {result.verdict}")
    if result.failed_witness:
        print(f"Failed witness: {result.failed_witness}")
    print("=" * 70)
    
    if result.verdict != 'FAIL_DEGENERATE':
        print(f"\n{'='*70}")
        print("MEASUREMENTS")
        print("=" * 70)
        
        print(f"\nα (pattern coherence):   {result.alpha:.3f}")
        if result.alpha_details:
            print(f"  Content tokens: {result.alpha_details['content_tokens']}")
            print(f"  Structure elements: {result.alpha_details['structure_elements']}")
            print(f"  Cosine similarity: {result.alpha_details['cos_sim']:.4f}")
        
        print(f"\nβ (relational coherence): {result.beta:.3f}")
        if result.beta_details:
            print(f"  Terms: {result.beta_details['terms']}")
            print(f"  Cross-references: {result.beta_details['cross_refs']}")
            print(f"  Total links: {result.beta_details['total_links']}")
        
        print(f"\nγ (trajectory):          {result.gamma:.3f}")
        
        print(f"\nC_Σ (aggregate):         {result.c_sigma:.3f}")
        
        verdict_symbol = "✅" if result.verdict == "PASS" else "❌"
        print(f"\nFinal: {verdict_symbol} {result.verdict}")


def save_measurement(result: MeasurementResult, output_path: Path):
    """Save measurement to JSON"""
    data = {
        'version': result.version,
        'date': result.date,
        'commit_hash': result.commit_hash,
        'verdict': result.verdict,
        'failed_witness': result.failed_witness,
        'witnesses': [
            {
                'name': w.name,
                'passed': w.passed,
                'details': w.details
            }
            for w in result.witnesses
        ],
        'measurements': {
            'alpha': result.alpha,
            'beta': result.beta,
            'gamma': result.gamma,
            'c_sigma': result.c_sigma
        },
        'details': {
            'alpha': result.alpha_details,
            'beta': result.beta_details
        }
    }
    
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(data, indent=2))


# ============================================================================
# CLI
# ============================================================================

def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Measure README coherence using TSC methodology'
    )
    parser.add_argument(
        'readme',
        type=Path,
        help='Path to README.md'
    )
    parser.add_argument(
        '--repo',
        type=Path,
        help='Path to git repo root (for history)'
    )
    parser.add_argument(
        '--cli',
        type=Path,
        help='Path to CLI file (for staleness check)'
    )
    parser.add_argument(
        '--output',
        type=Path,
        help='Output JSON file'
    )
    
    args = parser.parse_args()
    
    # Measure
    result = measure_readme(
        readme_path=args.readme,
        repo_path=args.repo,
        cli_path=args.cli
    )
    
    # Print report
    print_measurement_report(result)
    
    # Save if requested
    if args.output:
        save_measurement(result, args.output)
        print(f"\n✅ Saved to {args.output}")


if __name__ == '__main__':
    main()