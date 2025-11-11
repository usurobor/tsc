# tests/conformance/test_glider.py
from pathlib import Path

import pytest
from click.testing import CliRunner

from reference.cli.tsc import main as tsc_main

EXAMPLE = Path("examples/cellular-automata/glider.md")

pytestmark = pytest.mark.filterwarnings("ignore::DeprecationWarning")


# tests/conformance/test_glider.py
def test_cli_help_smoke():
    runner = CliRunner()
    result = runner.invoke(tsc_main, ["--help"])
    assert result.exit_code == 0
    assert "TSC CLI (v3.1.0)" in result.output


def test_glider_c_in_range():
    if not EXAMPLE.exists():
        pytest.skip(f"Missing example: {EXAMPLE}")

    runner = CliRunner()
    result = runner.invoke(tsc_main, ["compute", str(EXAMPLE), "--format", "json"])
    assert result.exit_code == 0, result.output

    # Parse JSON-like output printed by rich (it's strict JSON)
    import json

    payload = json.loads(result.output)
    c = float(payload["c_sigma"])

    # Initial band; tighten after calibration
    assert 0.994 <= c <= 0.999
