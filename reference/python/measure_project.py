#!/usr/bin/env python3
"""
TSC Project Measurement Orchestrator v3.1.2

Reads project.tsc and orchestrates measurement of all components.

Changes from v3.1.1:
- Component storage includes alpha, beta, c_sigma (not just c_sigma)
- Gamma calculation wired up for historical measurements
- Consistent version format with "v" prefix
- Bottleneck only considers alpha and beta
"""

import argparse
import json
import math
import subprocess
import tomllib
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from importlib import import_module

import measure_markdown


@dataclass
class WitnessResult:
    """Result from witness checks"""

    passed: bool
    details: dict


@dataclass
class ComponentMeasurement:
    """Measurement of a single component"""

    file: str
    witnesses: WitnessResult
    alpha: float
    beta: float
    gamma: float
    c_sigma: float
    alpha_details: dict
    beta_details: dict


def read_version() -> str:
    """Read version from pyproject.toml"""
    with open("pyproject.toml", "rb") as f:
        config = tomllib.load(f)
    return config["project"]["version"]


def get_all_version_tags() -> list[str]:
    """
    Get all git tags starting with 'v' sorted by version.

    Returns:
        List of tag names like ['v2.1.0', 'v2.2.0', 'v3.1.0']
    """
    try:
        result = subprocess.run(
            ["git", "tag", "-l", "v*"],
            capture_output=True,
            text=True,
            check=True,
        )
        tags = [tag.strip() for tag in result.stdout.split("\n") if tag.strip()]
        # Sort tags naturally by version
        return sorted(tags, key=lambda t: [int(x) for x in t.lstrip("v").split(".")])
    except subprocess.CalledProcessError:
        return []


def parse_config() -> list[dict]:
    """
    Parse project.tsc configuration.

    Handles repeated [markdown] sections by parsing manually
    since standard TOML doesn't allow duplicate section names.
    """
    if not Path("project.tsc").exists():
        raise FileNotFoundError("project.tsc not found!")

    components = []
    current_section = None
    current_data = {}

    with open("project.tsc") as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()

            # Skip comments and empty lines
            if not line or line.startswith("#"):
                continue

            # New section
            if line.startswith("[") and line.endswith("]"):
                # Save previous section
                if current_section == "markdown" and current_data:
                    components.append(current_data.copy())
                    current_data = {}

                # Start new section
                section_name = line[1:-1]
                current_section = section_name

            # Key-value pair
            elif "=" in line and current_section:
                key, value = line.split("=", 1)
                key = key.strip()
                value = value.strip().strip('"')
                current_data[key] = value

        # Don't forget last section
        if current_section == "markdown" and current_data:
            components.append(current_data)

    return components


def get_witness_module_name(file_path: str) -> str:
    """
    Convert file path to witness module name.

    Examples:
        README.md → witnesses.README
        spec/c-equiv.md → witnesses.spec.c_equiv
    """
    # Remove extension and convert to module path
    module_path = file_path.replace(".md", "").replace("/", ".")
    return f"witnesses.{module_path}"


def measure_component(
    file_path: str,
    alpha_func: str,
    beta_func: str,
    previous_alpha: float | None = None,
    previous_beta: float | None = None,
) -> ComponentMeasurement:
    """
    Measure a single component.

    Args:
        file_path: Path to file to measure
        alpha_func: Name of alpha measurement function
        beta_func: Name of beta measurement function
        previous_alpha: Previous alpha for gamma calculation (optional)
        previous_beta: Previous beta for gamma calculation (optional)

    Returns:
        ComponentMeasurement with all scores
    """
    path = Path(file_path)

    # 1. Run witnesses
    witness_module_name = get_witness_module_name(file_path)

    try:
        witness_module = import_module(witness_module_name)
        witness_result = witness_module.check(path)
    except (ImportError, AttributeError):
        # Stub: witnesses not yet implemented
        witness_result = WitnessResult(
            passed=True, details={"note": "witness module not implemented yet"}
        )

    # 2. Read file content
    text = path.read_text()

    # 3. Measure alpha
    alpha_fn = getattr(measure_markdown, alpha_func)
    alpha, alpha_details = alpha_fn(text)

    # 4. Measure beta
    beta_fn = getattr(measure_markdown, beta_func)
    beta, beta_details = beta_fn(text)

    # 5. Calculate gamma
    if previous_alpha is not None and previous_beta is not None:
        # γ = √((α_curr / α_prev) · (β_curr / β_prev))
        # Avoid division by zero
        alpha_ratio = alpha / previous_alpha if previous_alpha > 0 else 1.0
        beta_ratio = beta / previous_beta if previous_beta > 0 else 1.0
        gamma = math.sqrt(alpha_ratio * beta_ratio)
    else:
        # First measurement: baseline γ = √(α·β)
        gamma = math.sqrt(alpha * beta)

    # 6. Calculate C_Σ
    c_sigma = (alpha * beta * gamma) ** (1 / 3)

    return ComponentMeasurement(
        file=file_path,
        witnesses=witness_result,
        alpha=alpha,
        beta=beta,
        gamma=gamma,
        c_sigma=c_sigma,
        alpha_details=alpha_details,
        beta_details=beta_details,
    )


def write_component_output(measurement: ComponentMeasurement, output_dir: Path):
    """Write component measurement to .tsc/components/"""

    # Determine output path
    file_path = Path(measurement.file)
    output_path = output_dir / "components" / file_path.with_suffix(".json")

    # Create directory
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Write JSON
    data = {
        "file": measurement.file,
        "witnesses": {
            "passed": measurement.witnesses.passed,
            "details": measurement.witnesses.details,
        },
        "measurements": {
            "alpha": measurement.alpha,
            "beta": measurement.beta,
            "gamma": measurement.gamma,
            "c_sigma": measurement.c_sigma,
        },
        "details": {
            "alpha": measurement.alpha_details,
            "beta": measurement.beta_details,
        },
    }

    output_path.write_text(json.dumps(data, indent=2))


def aggregate_measurements(measurements: list[ComponentMeasurement]) -> dict:
    """
    Aggregate component measurements into project-level scores.

    Uses geometric mean for all dimensions.
    """
    if not measurements:
        raise ValueError("No measurements to aggregate")

    alphas = [m.alpha for m in measurements]
    betas = [m.beta for m in measurements]
    gammas = [m.gamma for m in measurements]

    def geo_mean(values):
        product = 1.0
        for v in values:
            product *= v
        return product ** (1 / len(values))

    alpha_agg = geo_mean(alphas)
    beta_agg = geo_mean(betas)
    gamma_agg = geo_mean(gammas)
    c_sigma_agg = (alpha_agg * beta_agg * gamma_agg) ** (1 / 3)

    return {
        "alpha": alpha_agg,
        "beta": beta_agg,
        "gamma": gamma_agg,
        "c_sigma": c_sigma_agg,
    }


def measure_at_tag(
    tag: str, components: list[dict], previous_measurement: dict | None
) -> dict | None:
    """
    Checkout a git tag and measure all components at that version.

    Args:
        tag: Git tag to checkout (e.g. 'v2.1.0')
        components: List of component configs from project.tsc
        previous_measurement: Previous measurement dict for gamma calculation

    Returns:
        Measurement dict with version, date, scores, and component breakdown
    """
    print(f"\n{'='*70}")
    print(f"MEASURING TAG: {tag}")
    print(f"{'='*70}")

    # Checkout the tag
    try:
        subprocess.run(
            ["git", "checkout", tag],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as e:
        print(f"⚠️  Failed to checkout {tag}: {e}")
        return None

    # Extract previous component measurements for gamma calculation
    prev_components = {}
    if previous_measurement and "components" in previous_measurement:
        prev_components = previous_measurement["components"]

    # Measure all components
    measurements = []
    for component in components:
        file_path = component["file"]
        if not Path(file_path).exists():
            print(f"  ⚠️  Skipping {file_path} (not present at {tag})")
            continue

        print(f"  Measuring: {file_path}")

        # Get previous alpha/beta for this specific component
        prev_comp = prev_components.get(file_path, {})
        prev_alpha = prev_comp.get("alpha")
        prev_beta = prev_comp.get("beta")

        measurement = measure_component(
            file_path=file_path,
            alpha_func=component["alpha"],
            beta_func=component["beta"],
            previous_alpha=prev_alpha,
            previous_beta=prev_beta,
        )
        measurements.append(measurement)

    if not measurements:
        return None

    # Aggregate
    aggregate = aggregate_measurements(measurements)

    # Build measurement dict
    return {
        "version": tag,
        "date": datetime.now().isoformat(),
        "alpha": aggregate["alpha"],
        "beta": aggregate["beta"],
        "gamma": aggregate["gamma"],
        "c_sigma": aggregate["c_sigma"],
        "components": {
            m.file: {"alpha": m.alpha, "beta": m.beta, "c_sigma": m.c_sigma}
            for m in measurements
        },
    }


def recalculate_all_measurements(components: list[dict]) -> list[dict]:
    """
    Recalculate measurements for all git tags.

    Args:
        components: List of component configs from project.tsc

    Returns:
        List of measurement dicts ordered chronologically
    """
    # Check for uncommitted changes
    result = subprocess.run(
        ["git", "status", "--porcelain"],
        capture_output=True,
        text=True,
        check=True,
    )
    has_changes = bool(result.stdout.strip())

    if has_changes:
        print("⚠️  Uncommitted changes detected. Stashing...")
        subprocess.run(
            ["git", "stash", "push", "-m", "TSC recalculate backup"],
            check=True,
        )

    # Save current branch
    result = subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        capture_output=True,
        text=True,
        check=True,
    )
    original_branch = result.stdout.strip()

    # Get all version tags
    tags = get_all_version_tags()
    if not tags:
        print("⚠️  No version tags found")
        return []

    print(f"Found {len(tags)} version tags: {', '.join(tags)}")

    measurements = []
    previous_measurement = None

    try:
        for tag in tags:
            measurement = measure_at_tag(tag, components, previous_measurement)
            if measurement:
                measurements.append(measurement)
                previous_measurement = measurement

        # Return to original branch
        print(f"\n{'='*70}")
        print(f"Returning to {original_branch}")
        print(f"{'='*70}")
        subprocess.run(
            ["git", "checkout", original_branch],
            check=True,
            capture_output=True,
        )

        # Restore stashed changes
        if has_changes:
            print("♻️  Restoring stashed changes...")
            subprocess.run(
                ["git", "stash", "pop"],
                check=True,
                capture_output=True,
            )

    except Exception as e:
        # Always try to return to original branch and restore changes
        print(f"\n⚠️  Error during recalculation: {e}")
        subprocess.run(
            ["git", "checkout", original_branch],
            capture_output=True,
        )
        if has_changes:
            subprocess.run(["git", "stash", "pop"], capture_output=True)
        raise

    return measurements


def write_project_json(
    measurements_array: list[dict],
    current_version: str,
    current_aggregate: dict,
    output_dir: Path,
):
    """
    Write project.json with measurements array format.

    Args:
        measurements_array: List of all measurements (historical + current)
        current_version: Current version string (with v prefix)
        current_aggregate: Current aggregate scores
        output_dir: Output directory (.tsc/)
    """
    # Find bottleneck dimension (only alpha and beta - gamma is calculated)
    bottleneck_dim = min(
        [("alpha", current_aggregate["alpha"]), ("beta", current_aggregate["beta"])],
        key=lambda x: x[1],
    )

    data = {
        "type": "project",
        "measurements": measurements_array,
        "current": {
            "version": current_version,
            "verdict": "PASS" if current_aggregate["c_sigma"] >= 0.80 else "FAIL",
            "bottleneck": {
                "dimension": bottleneck_dim[0],
                "value": bottleneck_dim[1],
            },
        },
    }

    output_path = output_dir / "project.json"
    output_path.write_text(json.dumps(data, indent=2))
    print(f"\n✅ Written: {output_path}")


def generate_readme(
    version: str,
    aggregate: dict,
    measurements: list[ComponentMeasurement],
    output_dir: Path,
):
    """Generate human-readable .tsc/README.md"""

    lines = [
        "# TSC Self-Measurement Dashboard",
        "",
        f"**Current Version:** {version}",
        f"**Status:** {'✅ PASS' if aggregate['c_sigma'] >= 0.80 else '❌ FAIL'}",
        f"**C_Σ:** {aggregate['c_sigma']:.3f}",
        "",
        "---",
        "",
        "## Current Score",
        "",
        "| Metric | Score | Status |",
        "|--------|-------|--------|",
        (
            f"| **α (pattern)** | {aggregate['alpha']:.3f} | "
            f"{'✅' if aggregate['alpha'] >= 0.80 else '⚠️'} |"
        ),
        (
            f"| **β (relation)** | {aggregate['beta']:.3f} | "
            f"{'✅' if aggregate['beta'] >= 0.80 else '⚠️'} |"
        ),
        (
            f"| **γ (trajectory)** | {aggregate['gamma']:.3f} | "
            f"{'✅' if aggregate['gamma'] >= 0.80 else '⚠️'} |"
        ),
        (
            f"| **C_Σ (aggregate)** | {aggregate['c_sigma']:.3f} | "
            f"{'✅ PASS' if aggregate['c_sigma'] >= 0.80 else '❌ FAIL'} |"
        ),
        "",
        "---",
        "",
        "## Component Breakdown",
        "",
        "| Component | α | β | γ | C_Σ |",
        "|-----------|---|---|---|-----|",
    ]

    for m in measurements:
        lines.append(
            f"| `{m.file}` | {m.alpha:.3f} | {m.beta:.3f} | "
            f"{m.gamma:.3f} | {m.c_sigma:.3f} |"
        )

    lines.extend(
        [
            "",
            "---",
            "",
            f"*Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} UTC*",
            f"*Generated from {len(measurements)} component(s)*",
        ]
    )

    output_path = output_dir / "README.md"
    output_path.write_text("\n".join(lines) + "\n")
    print(f"✅ Written: {output_path}")


def main():
    """Main orchestrator"""
    # Parse arguments
    parser = argparse.ArgumentParser(description="TSC Project Measurement")
    parser.add_argument(
        "--recalculate",
        action="store_true",
        help="Recalculate measurements for all git tags",
    )
    args = parser.parse_args()

    print("=" * 70)
    print("TSC PROJECT MEASUREMENT")
    print("=" * 70)

    # 1. Read version
    version = read_version()
    version_tag = f"v{version}"
    print(f"\nVersion: {version_tag}")

    # 2. Parse config
    print("\nParsing project.tsc...")
    components = parse_config()
    print(f"Found {len(components)} component(s) to measure")

    # 3. Branch based on mode
    if args.recalculate:
        print("\n🔄 RECALCULATE MODE: Measuring all git tags")

        # Recalculate all measurements from git history
        measurements_array = recalculate_all_measurements(components)

        # Measure current state (after returning from git checkout)
        print(f"\n{'='*70}")
        print(f"MEASURING CURRENT: {version_tag}")
        print(f"{'='*70}")

        # Get previous measurement for gamma calculation
        previous_measurement = measurements_array[-1] if measurements_array else None
        prev_components = (
            previous_measurement.get("components", {}) if previous_measurement else {}
        )

        current_measurements = []
        for i, component in enumerate(components, 1):
            file_path = component["file"]
            print(f"\n[{i}/{len(components)}] Measuring: {file_path}")

            # Extract previous alpha/beta for this component
            prev_comp = prev_components.get(file_path, {})
            prev_alpha = prev_comp.get("alpha")
            prev_beta = prev_comp.get("beta")

            measurement = measure_component(
                file_path=file_path,
                alpha_func=component["alpha"],
                beta_func=component["beta"],
                previous_alpha=prev_alpha,
                previous_beta=prev_beta,
            )
            current_measurements.append(measurement)
            write_component_output(measurement, Path(".tsc"))

        # Aggregate current
        current_aggregate = aggregate_measurements(current_measurements)

        print(f"\n  α = {current_aggregate['alpha']:.3f}")
        print(f"  β = {current_aggregate['beta']:.3f}")
        print(f"  γ = {current_aggregate['gamma']:.3f}")
        print(f"  C_Σ = {current_aggregate['c_sigma']:.3f}")

        # Add current to measurements array
        measurements_array.append(
            {
                "version": version_tag,
                "date": datetime.now().isoformat(),
                "alpha": current_aggregate["alpha"],
                "beta": current_aggregate["beta"],
                "gamma": current_aggregate["gamma"],
                "c_sigma": current_aggregate["c_sigma"],
                "components": {
                    m.file: {"alpha": m.alpha, "beta": m.beta, "c_sigma": m.c_sigma}
                    for m in current_measurements
                },
            }
        )

    else:
        print("\n📊 DEFAULT MODE: Measuring current state")

        # Load existing measurements array
        project_json_path = Path(".tsc/project.json")
        if project_json_path.exists():
            with open(project_json_path) as f:
                existing_data = json.load(f)
                measurements_array = existing_data.get("measurements", [])
        else:
            measurements_array = []

        # Get previous measurement for gamma calculation
        previous_measurement = measurements_array[-1] if measurements_array else None
        prev_components = (
            previous_measurement.get("components", {}) if previous_measurement else {}
        )

        # Measure current state
        current_measurements = []
        for i, component in enumerate(components, 1):
            file_path = component["file"]
            print(f"\n[{i}/{len(components)}] Measuring: {file_path}")

            # Extract previous alpha/beta for this component
            prev_comp = prev_components.get(file_path, {})
            prev_alpha = prev_comp.get("alpha")
            prev_beta = prev_comp.get("beta")

            measurement = measure_component(
                file_path=file_path,
                alpha_func=component["alpha"],
                beta_func=component["beta"],
                previous_alpha=prev_alpha,
                previous_beta=prev_beta,
            )
            current_measurements.append(measurement)
            write_component_output(measurement, Path(".tsc"))

        # Aggregate current
        print("\n" + "=" * 70)
        print("AGGREGATING")
        print("=" * 70)
        current_aggregate = aggregate_measurements(current_measurements)
        print("\nProject aggregate:")
        print(f"  α = {current_aggregate['alpha']:.3f}")
        print(f"  β = {current_aggregate['beta']:.3f}")
        print(f"  γ = {current_aggregate['gamma']:.3f}")
        print(f"  C_Σ = {current_aggregate['c_sigma']:.3f}")

        # Add current to measurements array
        measurements_array.append(
            {
                "version": version_tag,
                "date": datetime.now().isoformat(),
                "alpha": current_aggregate["alpha"],
                "beta": current_aggregate["beta"],
                "gamma": current_aggregate["gamma"],
                "c_sigma": current_aggregate["c_sigma"],
                "components": {
                    m.file: {"alpha": m.alpha, "beta": m.beta, "c_sigma": m.c_sigma}
                    for m in current_measurements
                },
            }
        )

    # 4. Write outputs
    write_project_json(
        measurements_array=measurements_array,
        current_version=version_tag,
        current_aggregate=current_aggregate,
        output_dir=Path(".tsc"),
    )
    generate_readme(version_tag, current_aggregate, current_measurements, Path(".tsc"))

    print("\n" + "=" * 70)
    print("✅ COMPLETE!")
    print("=" * 70)


if __name__ == "__main__":
    main()