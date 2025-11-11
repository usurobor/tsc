# QUICKSTART (v3.1.0)

This guide assumes Python **3.10+**.

## 1) Install

```bash
python3 -m pip install --upgrade pip
pip install -e ".[dev]"
```

This exposes a `tsc` CLI (via an internal reference package). It does not imply a stable import API.

## 2) Understanding the parser system

The reference controller is **pure and immutable**. To work with your data, you write **pure parser functions** that transform files into verification inputs.

### It works immediately:

```bash
tsc examples/cellular-automata/glider.md --format text
# Returns computed C_Σ from parsed frames
```

The system includes two parsers:

- **Cellular automaton parser** - extracts grids from markdown frames
- **Stub parser** - returns fixed values (fallback)

Parser selection is automatic via predicate dispatch.

### File structure:

```
reference/python/
├── tsc_controller.py          # Pure v2.0.0 state machine (untouched)
├── parser_interface.py        # ParsedInput dataclass and parse_file()
└── parsers/
    ├── __init__.py            # Predicate dispatch (PARSERS list)
    ├── stub.py                # Returns fixed values for testing
    └── cellular_automaton.py  # Extracts H/V/D from Life frames
```

## 3) Run the CLI

```bash
# Text output
tsc examples/cellular-automata/glider.md --format text

# JSON output
tsc examples/cellular-automata/glider.md --format json

# With seed (for random-soup reproducibility)
tsc examples/cellular-automata/random-soup.md --format json --seed 42
```

## 4) Run tests

```bash
pytest
```

- `test_glider.py` and `test_random_soup.py` include executable contracts for C_Σ
- They are marked `xfail` until parser produces valid results
- Remove `xfail` and tighten bands after calibration (see below)

## 5) Add support for your data format

Write a pure parser function in `reference/python/parsers/my_format.py`:

```python
# reference/python/parsers/my_format.py

from typing import Optional
from reference.python.parser_interface import ParsedInput
from reference.python.tsc_controller import (
    VerifyEnv, WitnessFloors, PolicyConfig,
    Metrics, WitnessStatus, OODStatus
)


def is_my_format(path: str) -> bool:
    """Predicate: detect your format."""
    with open(path) as f:
        first_line = f.readline()
    return first_line.startswith("MY_FORMAT")


def my_format_parser(path: str, seed: Optional[int] = None) -> ParsedInput:
    """
    Pure function: path → ParsedInput
    
    Pipeline:
      1. Read and parse file
      2. Build witness functions (closures over data)
      3. Compose into VerifyEnv
      4. Return immutable ParsedInput
    """
    
    # 1. Parse your format
    with open(path) as f:
        data = parse_my_data(f.read())
    
    # 2. Build pure witness functions (closures)
    def compute_metrics(indices):
        return compute_h_v_d_coherence(data, indices)
    
    def compute_witnesses(indices):
        return assess_witness_health(data, indices)
    
    def compute_ood(indices):
        return check_distribution_shift(data, indices)
    
    # 3. Compose environment
    env = VerifyEnv(
        sample_index_set=lambda s, p: range(len(data)),
        compute_metrics=compute_metrics,
        compute_witnesses=compute_witnesses,
        compute_ood=compute_ood
    )
    
    # 4. Configure thresholds
    floors = WitnessFloors(
        nu_min=1e-3, 
        H_min=0.1, 
        L_min=1e-3, 
        nu_min_D=1e-4, 
        H_min_D=0.05
    )
    cfg = PolicyConfig(Theta=0.80)
    
    return ParsedInput(env=env, floors=floors, cfg=cfg)


__all__ = ["is_my_format", "my_format_parser"]
```

Register in `parsers/__init__.py` (just 2 lines):

```python
# Add import
from reference.python.parsers.my_format import is_my_format, my_format_parser

# Add to PARSERS list (before stub)
PARSERS = [
    (is_my_format, my_format_parser),           # Your parser
    (is_cellular_automaton, cellular_automaton_parser),
    (is_stub, stub_parser),                     # Always last
]
```

That's it! The predicate and parser live together in one file.

See `parsers/stub.py` for a minimal complete example, or `parsers/cellular_automaton.py` for a realistic parser with markdown frame extraction.

## 6) Calibrate tolerance bands (once)

1. Run ≥200 trials per case (vary seeds, or sampling windows)
1. Compute median and MAD; set bounds to median ± 3×MAD (clip to [0,1])
1. Update assertions in `tests/conformance/` and commit with a short note (N, seeds, machine)

## 7) Developer UX

```bash
make setup      # install dev deps
make lint       # code style
make fmt        # auto-format
make test       # run tests
make quickstart # run glider example
```

## 8) Project structure

```
/spec/              # Normative specifications
/examples/          # Positive/negative control examples
/reference/         # Reference implementation (non-stable API)
  /python/
    /parsers/       # Parser functions (extensible)
/tests/             # Conformance tests
```

See [README.md](README.md) for full navigation guide.
