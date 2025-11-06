# reference/python/braid_debug.py
"""
Debugging harness for braided equations in C≡ specs.
Parses equations, builds AST, applies normalization,
and reports where/why equations fail under current rules.
"""

from collections import Counter
from typing import Any

# Import shared parsing engine
from reference.python.braid_parser import (
    Bin,
    Braid,
    Unit,
    Var,
    extract_equations,
    normalize,
    parse_equation,
    structural_equal,
)

# ============================================================================
# Pretty Printing
# ============================================================================


def ast_pretty(t) -> str:
    """Pretty-print AST as readable equation."""
    if isinstance(t, Var):
        return t.name
    if isinstance(t, Unit):
        return f"1_{t.axis}"
    if isinstance(t, Bin):
        L = ast_pretty(t.left)
        R = ast_pretty(t.right)
        return f"({L} ⊙_{t.axis} {R})"
    if isinstance(t, Braid):
        return f"φ_{{{t.a}{t.b}}}({ast_pretty(t.inner)})"
    return str(t)


def ast_repr(t) -> str:
    """Repr-style AST printing for debugging."""
    if isinstance(t, Var):
        return f"Var({t.name})"
    if isinstance(t, Unit):
        return f"Unit({t.axis})"
    if isinstance(t, Bin):
        return f"Bin(⊙{t.axis}, {ast_repr(t.left)}, {ast_repr(t.right)})"
    if isinstance(t, Braid):
        return f"Braid({t.a},{t.b}, {ast_repr(t.inner)})"
    return repr(t)


# ============================================================================
# Feature Analysis
# ============================================================================


def _walk_nodes(t):
    """Walk all nodes in AST."""
    yield t
    if isinstance(t, Bin):
        yield from _walk_nodes(t.left)
        yield from _walk_nodes(t.right)
    elif isinstance(t, Braid):
        yield from _walk_nodes(t.inner)


def _count_features(t):
    """Count features (units, ops, braids) in AST."""
    counts = Counter()

    def go(n):
        if isinstance(n, Unit):
            counts[f"unit_{n.axis}"] += 1
        elif isinstance(n, Bin):
            counts[f"⊙_{n.axis}"] += 1
            go(n.left)
            go(n.right)
        elif isinstance(n, Braid):
            counts[f"φ_{{{n.a}{n.b}}}"] += 1
            go(n.inner)
        elif isinstance(n, Var):
            counts["var"] += 1

    go(t)
    return counts


# ============================================================================
# Diagnostic Analysis
# ============================================================================


def _detect_issue(lhs, rhs, baseline_rules: set[str]):
    """
    Detect why an equation fails normalization.

    Returns: (issue_description, lhs_normalized, rhs_normalized)
    """

    def axis_order(x):
        return x

    lhs_b = normalize(lhs, baseline_rules, axis_order=axis_order)
    rhs_b = normalize(rhs, baseline_rules, axis_order=axis_order)

    if structural_equal(lhs_b, rhs_b):
        return "Equal under baseline rules", lhs_b, rhs_b

    # Probe associativity
    lhs_a = normalize(lhs, baseline_rules | {"assoc"}, axis_order=axis_order)
    rhs_a = normalize(rhs, baseline_rules | {"assoc"}, axis_order=axis_order)
    if structural_equal(lhs_a, rhs_a):
        return "Equal if associativity (right-assoc) is added", lhs_b, rhs_b

    # Probe unit elimination
    lhs_u = normalize(lhs, baseline_rules | {"unit"}, axis_order=axis_order)
    rhs_u = normalize(rhs, baseline_rules | {"unit"}, axis_order=axis_order)
    if structural_equal(lhs_u, rhs_u):
        return "Equal if unit elimination is added", lhs_b, rhs_b

    # Braids present?
    has_braid = any(isinstance(n, Braid) for n in _walk_nodes(lhs)) or any(
        isinstance(n, Braid) for n in _walk_nodes(rhs)
    )
    if has_braid:
        return "Braids present; Yang–Baxter or braid composition likely required", lhs_b, rhs_b

    return (
        "Structure differs; possibly missing rule (assoc/unit/MFI) or notation variance",
        lhs_b,
        rhs_b,
    )


# ============================================================================
# Public API
# ============================================================================


def debug_braided_failures(ceq_text: str) -> dict[str, Any]:
    """
    Analyze braided equations in a C≡ spec text and report where/why they fail
    under the current baseline normalization (MFI + assoc + braid_unwrap).

    Returns a dict with:
    - coverage: {total, parsed, failed}
    - sample_failures: [{equation, lhs_ast, rhs_ast, lhs_nf, rhs_nf, difference}]
    - notation: {operator_counts}
    - diagnostics: {units_seen, axes_ops, braids_seen}
    - parse_errors: [{equation, error}]
    """
    BASELINE_RULES = {"mfi", "assoc", "braid_unwrap"}

    equations = extract_equations(ceq_text)
    total = len(equations)
    parsed = 0
    failures = []
    parse_errors = []
    seen_notations = Counter()
    diag_counts = Counter()

    for eq in equations:
        try:
            result = parse_equation(eq)
            if result is None:
                parse_errors.append({"equation": eq, "error": "Failed to parse"})
                continue

            lhs, rhs = result
            parsed += 1

            issue, lhs_b, rhs_b = _detect_issue(lhs, rhs, BASELINE_RULES)

            if "Equal under baseline rules" not in issue:
                failures.append(
                    {
                        "equation": eq,
                        "lhs_ast": ast_repr(lhs),
                        "rhs_ast": ast_repr(rhs),
                        "lhs_nf": ast_repr(lhs_b),
                        "rhs_nf": ast_repr(rhs_b),
                        "difference": issue,
                    }
                )

            diag_counts += _count_features(lhs)
            diag_counts += _count_features(rhs)

        except Exception as e:
            parse_errors.append({"equation": eq, "error": str(e)})

    return {
        "coverage": {"total": total, "parsed": parsed, "failed": len(failures)},
        "sample_failures": failures[:20],
        "notation": dict(seen_notations),
        "diagnostics": {
            "units_seen_total": sum(v for k, v in diag_counts.items() if k.startswith("unit_")),
            "axes_ops_counts": {k: v for k, v in diag_counts.items() if k.startswith("⊙_")},
            "braids_seen": {k: v for k, v in diag_counts.items() if k.startswith("φ_{")},
        },
        "parse_errors": parse_errors[:20],
    }
