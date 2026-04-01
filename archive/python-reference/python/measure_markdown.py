"""
Generic markdown measurement functions.

These functions work on any markdown file and implement the TSC measurement
dimensions (α, β, γ).
"""

import math
import re
from collections import Counter
from pathlib import Path


def _tokenize(text: str) -> list[str]:
    """Tokenize text (strip code blocks, extract words)"""
    text = text.lower()
    # Remove code blocks
    text = re.sub(r'(?s)```.*?```', ' ', text)
    # Remove inline code
    text = re.sub(r'`[^`]*`', ' ', text)
    # Extract words
    return re.findall(r'[a-z0-9_]+', text)


def pattern_coherence(text: str) -> tuple[float, dict]:
    """
    Measure α: Do headers match content?
    
    Algorithm:
    1. Tokenize content → frequency distribution
    2. Extract structure (headers, bullets, bold) → structure distribution
    3. Compute cosine similarity between distributions
    4. Compute Jensen-Shannon divergence between distributions
    5. Combine into distance metric
    6. Return α = exp(-λ * distance) ∈ [0, 1]
    
    Returns:
        (alpha, details): Score and diagnostic info
    """
    # Extract content tokens
    content_tokens = _tokenize(text)
    content_counts = Counter(content_tokens)
    
    # Extract structure
    structure = Counter()
    
    # Headers - normalize header text to tokens
    for lvl, head in re.findall(r'(?m)^(#{1,6})\s+([^\n]+)$', text):
        lvln = len(lvl)
        head_norm = '-'.join(_tokenize(head)[:4])
        structure[f"h{lvln}:{head_norm}"] += 1
    
    # Bullets
    structure["bullets"] = len(re.findall(r'(?m)^\s*[-*+]\s+', text))
    
    # Bold terms
    structure["bold"] = len(re.findall(r'\*\*[^*]+\*\*', text))
    
    # Normalize to probability distributions
    def normalize(counter):
        total = sum(counter.values()) or 1
        return {k: v / total for k, v in counter.items()}
    
    content_vec = normalize(content_counts)
    structure_vec = normalize(structure)
    
    # Cosine similarity
    def cosine(u, v):
        keys = set(u) | set(v)
        num = sum(u.get(k, 0) * v.get(k, 0) for k in keys)
        du = math.sqrt(sum(u.get(k, 0) ** 2 for k in keys))
        dv = math.sqrt(sum(v.get(k, 0) ** 2 for k in keys))
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
        'cosine_similarity': cos_sim,
        'js_divergence': js_div,
        'distance': distance
    }
    
    return alpha, details


def relational_coherence(text: str) -> tuple[float, dict]:
    """
    Measure β: Are terms properly cross-referenced?
    
    Algorithm:
    1. Extract terms (bold text, definitions)
    2. Find explicit cross-references (see X, cf. Y)
    3. Build degree distribution (term frequency)
    4. Build cross-reference distribution
    5. Compute similarity between distributions
    6. Return β = exp(-λ * distance) ∈ [0, 1]
    
    Returns:
        (beta, details): Score and diagnostic info
    """
    # Extract bold terms as proxy for glossary
    terms = set()
    for match in re.findall(r'\*\*([^*]+)\*\*', text):
        term = match.strip().lower()
        if 2 < len(term) < 30:
            terms.add(term)
    
    # Find explicit cross-references
    cross_refs = []
    for term in terms:
        pattern = re.compile(
            rf'(see|cf\.?|→)\s+[^\n]*{re.escape(term)}',
            re.IGNORECASE
        )
        matches = pattern.findall(text)
        if matches:
            cross_refs.append((term, len(matches)))
    
    # Count total links
    total_links = len(re.findall(r'\[([^\]]+)\]\(([^)]+)\)', text))
    
    # Embedding 1: Term frequency (degree distribution)
    degree_counts = Counter()
    for term in terms:
        count = text.lower().count(term)
        if count > 0:
            degree_counts[term] = count
    
    # Embedding 2: Explicit cross-reference counts
    cross_ref_counts = Counter(dict(cross_refs))
    
    # Normalize to probability distributions
    def normalize(counter):
        total = sum(counter.values()) or 1
        return {k: v / total for k, v in counter.items()}
    
    hist1 = normalize(degree_counts)
    hist2 = normalize(cross_ref_counts) if cross_ref_counts else {}
    
    if hist2:
        # Compute similarity
        def cosine(u, v):
            keys = set(u) | set(v)
            num = sum(u.get(k, 0) * v.get(k, 0) for k in keys)
            du = math.sqrt(sum(u.get(k, 0) ** 2 for k in keys))
            dv = math.sqrt(sum(v.get(k, 0) ** 2 for k in keys))
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
        # No cross-references found
        cos_sim = 0.0
        js_div = 1.0
        beta = 0.0
    
    details = {
        'terms': len(terms),
        'cross_refs': len(cross_refs),
        'links': total_links,
        'cosine_similarity': cos_sim,
        'js_divergence': js_div
    }
    
    return beta, details