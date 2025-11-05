# tests/conformance/test_random_soup.py
from pathlib import Path

import pytest
from click.testing import CliRunner

from reference.cli.tsc import main as tsc_main

EXAMPLE = Path("examples/cellular-automata/random-soup.md")

pytestmark = pytest.mark.filterwarnings("ignore::DeprecationWarning")


@pytest.mark.parametrize("seed", [1, 2, 3, 4, 5])
def test_random_soup_c_in_range(seed: int):
    if not EXAMPLE.exists():
        pytest.skip(f"Missing example: {EXAMPLE}")

    runner = CliRunner()
    result = runner.invoke(
        tsc_main, ["compute", str(EXAMPLE), "--format", "json", "--seed", str(seed)]
    )
    assert result.exit_code in [0, 1], result.output  # May fail coherence threshold

    import json

    payload = json.loads(result.output)
    c = float(payload["c_sigma"])

    # Temporal coherence for random i.i.d. frames
    # Expected ~0.25-0.35 depending on Jaccard implementation details
    assert 0.20 <= c <= 0.40
