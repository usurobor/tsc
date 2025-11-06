# reference/python/braid_parser.py
"""
Shared braided equation parser and normalization engine.

Provides:
- AST: Var, Unit, Bin, Braid
- Parser: LaTeX → AST
- Normalization: MFI + Associativity + Braid unwrapping
- Equation extraction from markdown specs
"""

from __future__ import annotations

import re
from collections import Counter
from dataclasses import dataclass
from typing import Any

# ============================================================================
# AST (Abstract Syntax Tree)
# ============================================================================


@dataclass(frozen=True)
class Var:
    """Variable: x, y, z, etc."""

    name: str


@dataclass(frozen=True)
class Unit:
    """Typed unit: 1_a"""

    axis: str


@dataclass(frozen=True)
class Bin:
    """Binary operation: x ⊙_a y"""

    axis: str
    left: Any
    right: Any


@dataclass(frozen=True)
class Braid:
    """Braid/swap: φ_{ab}(inner)"""

    a: str
    b: str
    inner: Any


# Type alias for any AST node
from typing import Union
Term = Union[Var, Unit, Bin, Braid]


# ============================================================================
# Text Normalization (LaTeX → Canonical)
# ============================================================================


def normalize_latex(text: str) -> str:
    """Normalize LaTeX notation to canonical Unicode."""
    # Handle double-escaped backslashes from file reading
    text = text.replace('\\\\', '\\')
    
    # === NEW: Transform function notation to infix BEFORE stripping superscripts ===
    # C^{I}_{a}(x, y) → (x ⊙_a y)
    # Matches: \mathbf{C}^{I}_{a}(args) or C^{I}_{a}(args)
    import re
    
    def transform_func(match):
        axis = match.group(1)
        args = match.group(2)
        # Parse the two arguments
        parts = []
        depth = 0
        current = []
        for ch in args:
            if ch == ',' and depth == 0:
                parts.append(''.join(current).strip())
                current = []
            else:
                if ch in '({':
                    depth += 1
                elif ch in ')}':
                    depth -= 1
                current.append(ch)
        if current:
            parts.append(''.join(current).strip())
        
        if len(parts) == 2:
            return f"({parts[0]} ⊙_{axis} {parts[1]})"
        return match.group(0)  # fallback
    
    # Pattern: (mathbf{C} or C)^{I or R or E}_{axis}(args)
    text = re.sub(
        r'(?:\\mathbf\{C\}|C)\^[{]?[IRE][}]?_[{]?([a-z]+)[}]?\(([^)]+)\)',
        transform_func,
        text
    )
    
    # === Continue with existing normalization ===
    # Remove LaTeX sizing/delimiters
    # ... rest unchanged

    # Remove LaTeX sizing/delimiters
    text = re.sub(r"\\big[lr]?\(", "(", text)
    text = re.sub(r"\\big[lr]?\)", ")", text)
    text = re.sub(r"\\left\(", "(", text)
    text = re.sub(r"\\right\)", ")", text)
    text = re.sub(r"\\Big[lr]?\(", "(", text)
    text = re.sub(r"\\Big[lr]?\)", ")", text)

    # Fix escaped underscores
    text = text.replace("\\_", "_")
    text = text.replace("\\_{", "_{")

    # Map operators
    text = text.replace("\\odot", "⊙")
    text = text.replace("\\otimes", "⊗")
    text = text.replace("\\circ", "∘")
    text = text.replace("\\varphi", "φ")
    text = text.replace("\\phi", "φ")
    text = text.replace("\\sigma", "σ")

    # Remove text mode and bold
    text = re.sub(r"\\mathbf\{([^}]+)\}", r"\1", text)
    text = re.sub(r"\\text\{([^}]+)\}", r"\1", text)
    text = re.sub(r"\\mathrm\{([^}]+)\}", r"\1", text)

    # Remove ALL superscripts aggressively
    text = re.sub(r"\^\{[^}]*\}", "", text)
    text = re.sub(r"\^[a-zA-Z⊤⊥]", "", text)

    # Clean up spacing commands
    text = text.replace("\\quad", " ")
    text = text.replace("\\,", "")
    text = text.replace("\\;", "")
    text = text.replace("\\!", "")
    text = text.replace("\\:", "")

    # Handle isomorphism/equivalence separators
    text = text.replace(";\\cong;", "=")
    text = text.replace("\\cong", "=")
    text = text.replace("≅", "=")

    # Remove remaining LaTeX commands
    text = re.sub(r"\\[a-zA-Z]+", "", text)

    return text


# ============================================================================
# Lexer (Tokenization)
# ============================================================================

TOKEN_SPEC = [
    ("SPACE", r"\s+"),
    ("LPAREN", r"\("),
    ("RPAREN", r"\)"),
    ("LBRACE", r"\{"),
    ("RBRACE", r"\}"),
    ("COMMA", r","),
    ("EQUAL", r"[=≡≅]"),
    ("UNDER", r"_"),
    ("ODOT", r"⊙|\\odot|odot|\*|⋆|∘|•|⨂"),
    ("UNIT", r"1"),
    ("BRAID", r"φ|varphi|\\varphi|\\phi|sigma|\\sigma|σ|β|\\beta|braid"),
    ("IDENT", r"[A-Za-zΑ-Ωα-ω][A-Za-z0-9_Α-Ωα-ω]*"),
    ("OTHER", r"."),
]
TOKEN_RE = re.compile("|".join(f"(?P<{name}>{pat})" for name, pat in TOKEN_SPEC))


class Lexer:
    def __init__(self, s: str):
        self.s = normalize_latex(s)
        self.tokens = [(m.lastgroup, m.group()) for m in TOKEN_RE.finditer(self.s)]
        self.pos = 0

    def peek(self):
        return self.tokens[self.pos] if self.pos < len(self.tokens) else (None, None)

    def pop(self, expected=None):
        tok = self.peek()
        if expected and tok[0] != expected:
            raise ValueError(f"Expected {expected}, got {tok}")
        self.pos += 1
        return tok

    def skip_space(self):
        while self.peek()[0] == "SPACE":
            self.pop()


# ============================================================================
# Parser (Text → AST)
# ============================================================================


class Parser:
    def __init__(self, s: str):
        self.lex = Lexer(s)
        self.notation_counts = Counter()

    def _parse_axis(self) -> str:
        self.lex.skip_space()
        kind, _ = self.lex.peek()
        if kind != "UNDER":
            raise ValueError("Expected '_' before axis")
        self.lex.pop()
        self.lex.skip_space()
        kind, val = self.lex.peek()
        if kind == "LBRACE":
            self.lex.pop()
            axis_chars = []
            while True:
                k, v = self.lex.peek()
                if k is None:
                    raise ValueError("Unclosed '{' in axis")
                if k == "RBRACE":
                    self.lex.pop()
                    break
                self.lex.pop()
                if k != "COMMA":
                    axis_chars.append(v)
            axis = "".join(axis_chars).strip()
            if len(axis) == 0:
                raise ValueError("Empty axis")
            return axis
        else:
            k, v = self.lex.pop("IDENT")
            return v

    def _parse_factor(self):
        self.lex.skip_space()
        kind, val = self.lex.peek()
        if kind == "LPAREN":
            self.lex.pop()
            node = self._parse_expr()
            self.lex.skip_space()
            self.lex.pop("RPAREN")
            return node
        if kind == "UNIT":
            self.lex.pop()
            axis = self._parse_axis()
            return Unit(axis)
        if kind == "BRAID":
            self.notation_counts[f"BRAID:{val}"] += 1
            self.lex.pop()
            a_b = self._parse_axis()
            if len(a_b) >= 2:
                a, b = a_b[0], a_b[1]
            else:
                a = a_b
                b = a_b
            self.lex.skip_space()
            kind2, _ = self.lex.peek()
            if kind2 == "LPAREN":
                self.lex.pop()
                inner = self._parse_expr()
                self.lex.skip_space()
                self.lex.pop("RPAREN")
            else:
                inner = self._parse_factor()
            return Braid(a, b, inner)
        if kind == "IDENT":
            # Check for function call: C_a(x, y) or similar
            name = val
            self.lex.pop()
            
            # Look for subscript (function with axis)
            self.lex.skip_space()
            if self.lex.peek()[0] == "UNDER":
                axis = self._parse_axis()
                self.lex.skip_space()
                
                # Check for function call parentheses
                if self.lex.peek()[0] == "LPAREN":
                    self.lex.pop()  # consume (
                    
                    # Parse comma-separated arguments
                    args = []
                    while True:
                        self.lex.skip_space()
                        if self.lex.peek()[0] == "RPAREN":
                            break
                        arg = self._parse_expr()
                        args.append(arg)
                        self.lex.skip_space()
                        
                        if self.lex.peek()[0] == "COMMA":
                            self.lex.pop()
                            continue
                        elif self.lex.peek()[0] == "RPAREN":
                            break
                        else:
                            raise ValueError("Expected ',' or ')' in function call")
                    
                    self.lex.pop()  # consume )
                    
                    # Transform: C_a(x, y) → Bin(a, x, y)
                    if name in ['C', 'mathbf'] and len(args) == 2:
                        return Bin(axis, args[0], args[1])
                    elif len(args) == 1:
                        return args[0]
                    else:
                        raise ValueError(f"Unexpected function {name}_{axis} with {len(args)} args")
                
                # Not a function call, just a subscripted variable
                return Var(f"{name}_{axis}")
            
            # Plain variable
            return Var(name)

    def _parse_expr(self):
        left = self._parse_factor()
        while True:
            self.lex.skip_space()
            kind, val = self.lex.peek()
            if kind == "ODOT" or (kind == "OTHER" and val in ["∘", "•"]):
                self.notation_counts[f"ODOT:{val}"] += 1
                self.lex.pop()
                axis = self._parse_axis()
                right = self._parse_factor()
                left = Bin(axis, left, right)
                continue
            break
        return left


def parse_equation(eqline: str) -> tuple[Term, Term] | None:
    """Parse equation string into (LHS, RHS) AST pair."""
    try:
        s = normalize_latex(eqline)
        m = re.search(r"(?<![=])([=≡≅])(?![=])", s)
        if not m:
            return None
        lhs_s, rhs_s = s[: m.start()], s[m.end() :]
        p1 = Parser(lhs_s)
        lhs = p1._parse_expr()
        p2 = Parser(rhs_s)
        rhs = p2._parse_expr()
        return lhs, rhs
    except Exception:
        return None


# ============================================================================
# Normalization Rules
# ============================================================================


def right_assoc(term: Term) -> tuple[Term, bool]:
    """Right-associate binary operations: (x ⊙ y) ⊙ z → x ⊙ (y ⊙ z)"""
    changed = False

    def go(t):
        nonlocal changed
        if isinstance(t, Bin):
            l = go(t.left)
            r = go(t.right)
            t2 = Bin(t.axis, l, r)
            if isinstance(t2.left, Bin) and t2.left.axis == t2.axis:
                changed = True
                return Bin(t2.axis, t2.left.left, Bin(t2.axis, t2.left.right, t2.right))
            return t2
        elif isinstance(t, Braid):
            inner = go(t.inner)
            if inner is not t.inner:
                changed = True
            return Braid(t.a, t.b, inner)
        else:
            return t

    return go(term), changed


def mfi_step(term: Term, axis_order=None) -> tuple[Term, bool]:
    """Apply middle-four interchange (braided monoidal law)."""
    changed = False

    def key(a):
        return a if axis_order is None else axis_order(a)

    def go(t):
        nonlocal changed
        if isinstance(t, Bin):
            l = go(t.left)
            r = go(t.right)
            t2 = Bin(t.axis, l, r)
            if isinstance(t2.left, Bin) and isinstance(t2.right, Bin):
                a = t2.left.axis
                b = t2.axis
                if t2.right.axis == a and a != b:
                    if key(a) < key(b):
                        x, y = t2.left.left, t2.left.right
                        z, w = t2.right.left, t2.right.right
                        changed = True
                        return Bin(a, Bin(b, x, z), Bin(b, y, w))
            return t2
        elif isinstance(t, Braid):
            inner = go(t.inner)
            if inner is not t.inner:
                changed = True
            return Braid(t.a, t.b, inner)
        else:
            return t

    return go(term), changed


def braid_unwrap(term: Term) -> tuple[Term, bool]:
    """Unwrap braids that contain their MFI result: φ(result) → result"""
    changed = False

    def go(t):
        nonlocal changed
        if isinstance(t, Braid):
            inner = go(t.inner)
            # If inner is already transformed (Bin node), unwrap
            if isinstance(inner, Bin):
                changed = True
                return inner
            return Braid(t.a, t.b, inner)
        elif isinstance(t, Bin):
            return Bin(t.axis, go(t.left), go(t.right))
        return t

    return go(term), changed

def unit_elim(term: Term) -> tuple[Term, bool]:
    """Unit elimination: 1_a ⊙_a x → x and x ⊙_a 1_a → x"""
    changed = False
    
    def go(t):
        nonlocal changed
        if isinstance(t, Bin):
            l = go(t.left)
            r = go(t.right)
            # Left unit: 1_a ⊙_a x → x
            if isinstance(l, Unit) and l.axis == t.axis:
                changed = True
                return r
            # Right unit: x ⊙_a 1_a → x
            if isinstance(r, Unit) and r.axis == t.axis:
                changed = True
                return l
            return Bin(t.axis, l, r)
        elif isinstance(t, Braid):
            inner = go(t.inner)
            if inner is not t.inner:
                changed = True
            return Braid(t.a, t.b, inner)
        else:
            return t
    
    return go(term), changed

def normalize(term: Term, rules: Set[str], axis_order=None, max_iter=100) -> Term:
    """..."""
    t = term
    for _ in range(max_iter):
        changed_any = False
        if "assoc" in rules:
            t, ch = right_assoc(t)
            changed_any |= ch
        if "unit" in rules:  # ADD THIS
            t, ch = unit_elim(t)
            changed_any |= ch
        if "mfi" in rules:
            t, ch = mfi_step(t, axis_order=axis_order)
            changed_any |= ch
        if "braid_unwrap" in rules:
            t, ch = braid_unwrap(t)
            changed_any |= ch
        if not changed_any:
            break
    return t


def structural_equal(a: Term, b: Term) -> bool:
    """Check if two terms are structurally equal."""
    return a == b  # dataclass equality


# ============================================================================
# Equation Extraction
# ============================================================================


def extract_equations(text: str) -> list[str]:
    """
    Extract C≡ equations from markdown spec text.

    Filters out definitions and meta-statements, keeps verifiable axioms.
    """
    eqs = []

    # Extract from Display Math $$...$$
    for match in re.finditer(r"\$\$(.*?)\$\$", text, re.DOTALL):
        content = match.group(1).strip()
        for line in content.split("\n"):
            line = line.strip()
            if ("=" in line or "≡" in line or "cong" in line) and len(line) > 5:
                eqs.append(line)

    # Extract from Inline Math $...$
    for match in re.finditer(r"(?<!\$)\$(?!\$)(.*?)\$(?!\$)", text):
        content = match.group(1).strip()
        if (
            any(sym in content for sym in ["⊙", "odot", "\\odot", "varphi", "\\varphi", "1_", "C^"])
            and len(content) > 10
        ):
            if "=" in content or "≡" in content or "cong" in content:
                eqs.append(content)

    # Fallback: Line-based for non-LaTeX
    lines = text.splitlines()
    in_code = False
    fence_re = re.compile(r"^\s*`{3,}")

    for line in lines:
        if fence_re.match(line):
            in_code = not in_code
            continue
        if in_code:
            continue

        if any(sym in line for sym in ["⊙", "odot", "\\odot", "varphi", "\\varphi", "1_", "C^"]):
            if "=" in line or "≡" in line:
                eqs.append(line.strip())

    # Surgical filtering
    filtered = []
    for eq in eqs:
        # Skip meta-statements and definitions
        if ":=" in eq:
            continue
        if "text{NF}" in eq or "NF[" in eq:
            continue
        if re.search(r"\bLet\s", eq, re.IGNORECASE):
            continue
        if re.search(r"\b(If|Then)\b.*\bthen\b", eq, re.IGNORECASE):
            continue

        # Skip C6 Adjointness (extension, deferred)
        if "\\top" in eq or "⊤" in eq:
            continue

        # Skip role rotation
        if "ρ" in eq or "\\rho" in eq:
            continue

        # Skip incomplete fragments
        normalized = normalize_latex(eq)
        if re.search(r"=\s*[a-z]\s*$", normalized):
            continue

        # Skip closure axiom (definitional, not verifiable)
        if re.search(r'C.*\(.*C.*,.*C.*\).*=.*C', eq):
            continue

        filtered.append(eq)

    return filtered
