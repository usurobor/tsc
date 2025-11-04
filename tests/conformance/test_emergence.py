"""
Conformance test for emergence philosophical example.

This test verifies that:
1. The tsc_yaml_v2 parser detects and processes the file
2. The CLI runs without errors
3. Returned C_Σ is in valid range

NOTE: Expected C_Σ values are provisional. Tests verify basic functionality,
not strict conformance to expected values (since witnesses aren't implemented yet).
"""

import json
from pathlib import Path

import pytest
from click.testing import CliRunner

from reference.cli.tsc import main as tsc_main

EXAMPLE = Path("examples/philosophical/emergence.md")


def test_emergence_parser_detects_file():
    """Verify the tsc_yaml_v2 parser detects emergence.md"""
    if not EXAMPLE.exists():
        pytest.skip(f"Missing example: {EXAMPLE}")
    
    # The file should be detected as TSC YAML (has tsc: YAML block)
    from reference.python.parsers.tsc_yaml_v2 import is_tsc_yaml
    assert is_tsc_yaml(str(EXAMPLE))


def test_emergence_cli_runs():
    """Verify CLI processes emergence example without errors"""
    if not EXAMPLE.exists():
        pytest.skip(f"Missing example: {EXAMPLE}")
    
    runner = CliRunner()
    result = runner.invoke(tsc_main, [str(EXAMPLE), "--format", "json"])
    
    assert result.exit_code == 0, f"CLI failed: {result.output}"


def test_emergence_c_sigma_valid():
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
    
    # Provisional check: should show meaningful coherence
    # Once witnesses are implemented, tighten to expected range: 0.83 <= c <= 0.93
    assert c >= 0.4, f"C_Σ too low (witnesses not yet implemented): {c}"