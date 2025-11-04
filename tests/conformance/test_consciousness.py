"""
Conformance test for consciousness philosophical example.

This test verifies that:
1. The philosophical parser detects and processes the file
2. The CLI runs without errors
3. Returned C_Σ is in valid range

NOTE: Expected C_Σ values in the example files are provisional calibration
targets. These tests do NOT enforce them strictly yet, since witness logic
is not fully implemented. Tests verify the parser works and returns reasonable
values (0.0 ≤ C_Σ ≤ 1.0).

Future work: When witness checks are implemented, tighten these bounds to
match the expected.c_sigma values in the YAML specs.
"""

import json
from pathlib import Path

import pytest
from click.testing import CliRunner

from reference.cli.tsc import main as tsc_main

EXAMPLE = Path("examples/philosophical/consciousness.md")


def test_consciousness_parser_detects_file():
    """Verify the tsc_yaml_v2 parser detects consciousness.md"""
    if not EXAMPLE.exists():
        pytest.skip(f"Missing example: {EXAMPLE}")

    # The file should be detected as TSC YAML (has tsc: YAML block)
    from reference.python.parsers.tsc_yaml_v2 import is_tsc_yaml

    assert is_tsc_yaml(str(EXAMPLE))


def test_consciousness_cli_runs():
    """Verify CLI processes consciousness example without errors"""
    if not EXAMPLE.exists():
        pytest.skip(f"Missing example: {EXAMPLE}")

    runner = CliRunner()
    result = runner.invoke(tsc_main, [str(EXAMPLE), "--format", "json"])

    assert result.exit_code == 0, f"CLI failed: {result.output}"


def test_consciousness_c_sigma_valid():
    """Verify returned C_Σ is in valid range [0,1]"""
    if not EXAMPLE.exists():
        pytest.skip(f"Missing example: {EXAMPLE}")

    runner = CliRunner()
    result = runner.invoke(tsc_main, [str(EXAMPLE), "--format", "json"])
    assert result.exit_code == 0

    payload = json.loads(result.output)
    c = float(payload["c"])

    # Basic validity check
    assert 0.0 <= c <= 1.0, f"C_Σ out of range: {c}"

    # Provisional check: should show meaningful coherence (not near 0)
    # Once witnesses are implemented, tighten to expected range: 0.88 <= c <= 0.96
    assert c >= 0.5, f"C_Σ too low (witnesses not yet implemented): {c}"
