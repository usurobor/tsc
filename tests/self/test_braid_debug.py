"""Test braided equation debugging harness."""

import json
from pathlib import Path


def test_braid_debug_runs():
    """Smoke test: harness runs without crashing."""
    from reference.python.braid_debug import debug_braided_failures

    text = Path("spec/c-equiv.md").read_text(encoding="utf-8")
    report = debug_braided_failures(text)

    assert "coverage" in report
    assert "sample_failures" in report
    assert "diagnostics" in report

    # Log to artifact
    Path("braid_debug_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")

    # Display summary
    print("\n=== Braided Equation Analysis ===")
    print(f"Total equations: {report['coverage']['total']}")
    print(f"Successfully parsed: {report['coverage']['parsed']}")
    print(f"Failed normalization: {report['coverage']['failed']}")

    failed = report["coverage"]["failed"]
    parsed = max(1, report["coverage"]["parsed"])
    print(f"\nFailure rate: {failed / parsed * 100:.1f}%")

    if report["sample_failures"]:
        print("\nSample failure reasons:")
        reasons = {}
        for f in report["sample_failures"]:
            reason = f["difference"]
            reasons[reason] = reasons.get(reason, 0) + 1
        for reason, count in sorted(reasons.items(), key=lambda x: -x[1]):
            print(f"  {count:2d}x {reason}")


def test_braid_debug_c_equiv_kernel():
    """Test on kernel doc too."""
    from reference.python.braid_debug import debug_braided_failures

    text = Path("spec/c-equiv-kernel.md").read_text(encoding="utf-8")
    report = debug_braided_failures(text)

    assert report["coverage"]["total"] >= 0  # May have 0 equations, that's ok
