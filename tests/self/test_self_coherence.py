"""
tests/self/test_self_coherence.py — Self-coherence test suite
"""

import json
from pathlib import Path

import pytest

pytestmark = pytest.mark.skip(reason="Self-measurement needs rewrite for v3.0.0 (term algebra)")

def test_self_coherence_runs_and_emits_report():
    """Test that self-measurement runs and emits a valid report."""
    from reference.python.self_measure import write_report

    rep = write_report("coherence_report.json")

    # Schema validation
    assert "scores" in rep and "C_sigma" in rep["scores"]
    assert "ci" in rep
    assert rep["ci"]["C_sigma_lo"] <= rep["scores"]["C_sigma"] <= rep["ci"]["C_sigma_hi"]

    # Witnesses present
    assert "witnesses" in rep
    assert "S3_permutation" in rep["witnesses"]
    assert "braid_CI" in rep["witnesses"]
    assert len(rep["witnesses"]["braid_CI"]) == 2

    # Provenance
    assert "provenance" in rep
    assert "git_commit" in rep["provenance"]

    # Report file exists
    assert Path("coherence_report.json").exists()

    # Validate JSON
    data = json.loads(Path("coherence_report.json").read_text())
    assert data["scores"]["C_sigma"] >= 0.0


def test_gamma_requires_git():
    """Test that γ_c fails explicitly without git history."""
    from reference.python.self_measure import Params, gamma_axis, load_specs

    # This test will pass if run in a git repo with spec/ history
    # or fail with clear error message if not
    specs = load_specs()

    try:
        result = gamma_axis(Params(), specs)
        # If we get here, git is available
        assert result.mean >= 0.0
        assert len(result.reps) > 0
    except ValueError as e:
        # Expected if no git history
        assert "γ_c requires two git snapshots" in str(e)


def test_s3_witness_structure():
    """Test that S₃ witness has correct structure."""
    from reference.python.self_measure import Params, measure_self

    rep = measure_self(Params())

    s3 = rep["witnesses"]["S3_permutation"]
    assert "passed" in s3
    assert "permutations" in s3
    assert "baseline_CI" in s3

    # Should have 6 permutations (3! = 6)
    assert len(s3["permutations"]) == 6


def test_braided_witness_detects_equations():
    """Test that braided witness parses equations from spec."""
    from reference.python.self_measure import Params, measure_self

    rep = measure_self(Params())

    assert "braid_pairs" in rep["witnesses"]
    # Should find at least some equations
    assert rep["witnesses"]["braid_pairs"] > 0
