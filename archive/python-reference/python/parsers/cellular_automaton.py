# reference/python/parsers/cellular_automaton.py
from __future__ import annotations

"""
Parser for cellular automaton examples (Conway's Life).

Pure functional pipeline:
  markdown → frames → grids → H/V/D witnesses → ParsedInput
"""

import re
from collections.abc import Iterable

from reference.python.parser_interface import ParsedInput

# Local import to avoid cycles (parsers.__init__ imports us)
from reference.python.parsers.stub import stub_parser
from reference.python.tsc_controller import (
    Metrics,
    OODStatus,
    PolicyConfig,
    VerifyEnv,
    WitnessFloors,
    WitnessStatus,
)

Grid = list[list[int]]


def _peek_text(path: str, n: int = 1500) -> str:
    """Read first n characters of file."""
    try:
        with open(path, encoding="utf-8", errors="ignore") as f:
            return f.read(n)
    except (FileNotFoundError, OSError):
        return ""


def is_cellular_automaton(path: str) -> bool:
    """
    Predicate: file likely contains cellular automaton frames.

    Heuristics:
    - Contains '### Frame' headings (markdown style), OR
    - Contains fenced blocks tagged 'life' or 'cells', OR
    - Has ≥3 consecutive lines of grid characters (#, O, ., 0, 1, spaces)
    """
    text = _peek_text(path).lower()
    if "### frame" in text or "```life" in text or "```cells" in text:
        return True

    # Lightweight structural sniff
    lines = [ln.strip().lower() for ln in text.splitlines()[:200]]
    gridish = 0
    for ln in lines:
        if ln and all(ch in "#o.01 " for ch in ln):
            gridish += 1
            if gridish >= 3:
                return True
        else:
            gridish = 0
    return False


def cellular_automaton_parser(path: str, seed: int | None = None) -> ParsedInput:
    """
    Pure function: markdown file → ParsedInput for cellular automaton.

    Pipeline:
      1) read_markdown(path) → str
      2) extract_frames(markdown) → List[Grid]
      3) build witness closures over frames
      4) compose VerifyEnv
      5) construct ParsedInput
    """
    try:
        with open(path, encoding="utf-8", errors="ignore") as f:
            content = f.read()
    except OSError:
        return stub_parser(path, seed)

    frames = extract_frames(content)

    if not frames:
        return stub_parser(path, seed)

    # ---- Witness closures (pure, close over 'frames') ----

    def sample_index_set(_state, _policy) -> Iterable[int]:
        return range(len(frames))

    def compute_metrics(indices: Iterable[int]) -> Metrics:
        """
        Compute H/V/D coherence metrics.

        H = horizontal (spatial) adjacency within frames
        V = vertical (spatial) adjacency within frames
        D = temporal coherence between consecutive frames
        """
        idx_list = list(indices)

        # Spatial coherence (within-frame): H and V
        Hs, Vs = [], []
        for i in idx_list:
            H, V, _ = _adjacency_coherences(frames[i])
            Hs.append(H)
            Vs.append(V)

        Hm = sum(Hs) / len(Hs) if Hs else 0.0
        Vm = sum(Vs) / len(Vs) if Vs else 0.0

        # Temporal coherence (between frames): D as process dimension
        # Use only frames in the sampled indices
        sampled_frames = [frames[i] for i in idx_list]
        Dm = _temporal_stability(sampled_frames)

        # Geometric mean (as per TSC spec)
        if Hm > 0 and Vm > 0 and Dm > 0:
            C = (Hm * Vm * Dm) ** (1 / 3)
        else:
            C = 0.0

        ci = (max(C - 0.05, 0.0), min(C + 0.05, 1.0))
        return Metrics(C, Hm, Vm, Dm, ci)

    def compute_witnesses(indices: Iterable[int]) -> WitnessStatus:
        density = _mean_density([frames[i] for i in indices])
        stability = _temporal_stability([frames[i] for i in indices])
        return WitnessStatus(
            0.01 + 0.04 * (1 - abs(0.3 - density)),
            0.10 + 0.40 * stability,
            0.02 + 0.06 * (1 - density),
            0.10 + 0.35 * stability,
            0.010 + 0.020 * (1 - stability),
        )

    def compute_ood(indices: Iterable[int]) -> OODStatus:
        density = _mean_density([frames[i] for i in indices])
        dist = abs(density - 0.30)
        score = max(0.0, 1.0 - 2.0 * dist)
        return OODStatus(dist, score)

    env = VerifyEnv(
        sample_index_set=sample_index_set,
        compute_metrics=compute_metrics,
        compute_witnesses=compute_witnesses,
        compute_ood=compute_ood,
    )

    floors = WitnessFloors(
        nu_min=1e-3,
        H_min=0.10,
        L_min=1e-3,
        nu_min_D=1e-4,
        H_min_D=0.05,
    )
    cfg = PolicyConfig(Theta=0.80)

    return ParsedInput(env=env, floors=floors, cfg=cfg)


# --- Rest of the helper functions remain the same ---
_FRAME_HEADER_RE = re.compile(r"^\s{0,3}#{3,}\s*frame\b.*$", re.IGNORECASE | re.MULTILINE)


def extract_frames(markdown: str) -> list[Grid]:
    """Pure: markdown → list of binary grids."""
    blocks: list[list[str]] = []

    for tag in ("life", "cells"):
        blocks.extend(_extract_fenced(markdown, tag))

    blocks.extend(_extract_frame_sections(markdown))

    if not blocks:
        blocks.extend(_extract_bare_grids(markdown))

    frames: list[Grid] = []
    for raw_lines in blocks:
        grid = _to_grid(raw_lines)
        if grid:
            frames.append(grid)

    unique: list[Grid] = []
    seen: set[tuple[tuple[int, ...], ...]] = set()
    for g in frames:
        key = tuple(tuple(row) for row in g)
        if key not in seen:
            unique.append(g)
            seen.add(key)
    return unique


def _extract_fenced(text: str, tag: str) -> list[list[str]]:
    rx = re.compile(rf"```{tag}\s*\n(.*?)\n```", re.IGNORECASE | re.DOTALL)
    blocks: list[list[str]] = []
    for m in rx.finditer(text):
        body = m.group(1)
        lines = [ln.rstrip() for ln in body.splitlines() if ln.strip()]
        if _looks_like_grid(lines):
            blocks.append(lines)
    return blocks


def _extract_frame_sections(text: str) -> list[list[str]]:
    lines = text.splitlines()
    idxs = [i for i, ln in enumerate(lines) if _FRAME_HEADER_RE.match(ln or "")]
    blocks: list[list[str]] = []
    for k, i in enumerate(idxs):
        j = idxs[k + 1] if k + 1 < len(idxs) else len(lines)
        body = [ln.rstrip() for ln in lines[i + 1 : j] if ln.strip()]
        grid_lines = [ln for ln in body if all(ch in "#Oo.01 " for ch in ln)]
        if _looks_like_grid(grid_lines):
            blocks.append(grid_lines)
    return blocks


def _extract_bare_grids(text: str) -> list[list[str]]:
    lines = [ln.rstrip() for ln in text.splitlines()]
    blocks: list[list[str]] = []
    cur: list[str] = []

    def flush():
        nonlocal cur
        if _looks_like_grid(cur):
            blocks.append(cur)
        cur = []

    for ln in lines:
        if ln and all(ch in "#Oo.01 " for ch in ln):
            cur.append(ln)
        else:
            flush()
    flush()
    return blocks


def _looks_like_grid(lines: list[str]) -> bool:
    if len(lines) < 3:
        return False
    width = max((len(ln) for ln in lines), default=0)
    if width < 3:
        return False
    total = sum(len(ln) for ln in lines)
    live = sum(sum(1 for ch in ln if ch in "#Oo1") for ln in lines)
    return total > 0 and (live / total) >= 0.05


def _to_grid(lines: list[str]) -> Grid:
    m: dict[str, int] = {"#": 1, "O": 1, "o": 1, "1": 1, ".": 0, "0": 0, " ": 0}
    grid: Grid = []
    width = max(len(ln) for ln in lines)
    for ln in lines:
        row = [m.get(ch, 0) for ch in ln.ljust(width)]
        grid.append(row)
    return grid


def _adjacency_coherences(grid: Grid) -> tuple[float, float, float]:
    if not grid or not grid[0]:
        return (0.0, 0.0, 0.0)
    h, w = len(grid), len(grid[0])

    h_eq = 0
    h_tot = 0
    for r in range(h):
        for c in range(w - 1):
            h_eq += 1 if grid[r][c] == grid[r][c + 1] else 0
            h_tot += 1
    H = h_eq / h_tot if h_tot else 0.0

    v_eq = 0
    v_tot = 0
    for r in range(h - 1):
        for c in range(w):
            v_eq += 1 if grid[r][c] == grid[r + 1][c] else 0
            v_tot += 1
    V = v_eq / v_tot if v_tot else 0.0

    d_eq = 0
    d_tot = 0
    for r in range(h - 1):
        for c in range(w - 1):
            d_eq += 1 if grid[r][c] == grid[r + 1][c + 1] else 0
            d_tot += 1
    for r in range(h - 1):
        for c in range(1, w):
            d_eq += 1 if grid[r][c] == grid[r + 1][c - 1] else 0
            d_tot += 1
    D = d_eq / d_tot if d_tot else 0.0

    return (H, V, D)


def _mean_density(frames: list[Grid]) -> float:
    tot = 0
    live = 0
    for g in frames:
        for row in g:
            tot += len(row)
            live += sum(row)
    return (live / tot) if tot else 0.0


def _temporal_stability(frames: list[Grid]) -> float:
    if len(frames) < 2:
        return 1.0
    sims: list[float] = []
    for a, b in zip(frames[:-1], frames[1:]):
        sims.append(_jaccard(a, b))
    return sum(sims) / len(sims)


def _jaccard(a: Grid, b: Grid) -> float:
    if not a or not a[0] or not b or not b[0]:
        return 0.0
    h = min(len(a), len(b))
    w = min(len(a[0]), len(b[0]))
    inter = 0
    union = 0
    for r in range(h):
        for c in range(w):
            av = a[r][c]
            bv = b[r][c]
            inter += 1 if (av == 1 and bv == 1) else 0
            union += 1 if (av == 1 or bv == 1) else 0
    return (inter / union) if union else 1.0


__all__ = ["is_cellular_automaton", "cellular_automaton_parser"]
