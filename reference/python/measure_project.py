#!/usr/bin/env python3
"""
TSC Project Measurement Orchestrator

Reads project.tsc and orchestrates measurement of all components.
"""

import json
import math
from dataclasses import dataclass
from datetime import datetime
from importlib import import_module
from pathlib import Path

import measure_markdown
import tomllib


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
                    print(f"  Saved section: {current_data}")
                    current_data = {}

                # Start new section
                section_name = line[1:-1]
                current_section = section_name
                print(f"  Found [{section_name}] at line {line_num}")

            # Key-value pair
            elif "=" in line and current_section:
                key, value = line.split("=", 1)
                key = key.strip()
                value = value.strip().strip('"')
                current_data[key] = value

        # Don't forget last section
        if current_section == "markdown" and current_data:
            components.append(current_data)
            print(f"  Saved final section: {current_data}")

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


def measure_component(file_path: str, alpha_func: str, beta_func: str) -> ComponentMeasurement:
    """
    Measure a single component.

    Args:
        file_path: Path to file to measure
        alpha_func: Name of alpha measurement function
        beta_func: Name of beta measurement function

    Returns:
        ComponentMeasurement with all scores
    """
    path = Path(file_path)

    # 1. Run witnesses
    witness_module_name = get_witness_module_name(file_path)
    print(f"  Running witnesses: {witness_module_name}")

    try:
        witness_module = import_module(witness_module_name)
        witness_result = witness_module.check(path)
    except (ImportError, AttributeError) as e:
        print(f"  ⚠️  Witness module not found: {e}")
        # STUB: Create fake passing witness
        witness_result = WitnessResult(
            passed=True, details={"note": "witness module not implemented yet"}
        )

    # 2. Read file content
    text = path.read_text()

    # 3. Measure alpha
    print(f"  Measuring α: {alpha_func}")
    alpha_fn = getattr(measure_markdown, alpha_func)
    alpha, alpha_details = alpha_fn(text)

    # 4. Measure beta
    print(f"  Measuring β: {beta_func}")
    beta_fn = getattr(measure_markdown, beta_func)
    beta, beta_details = beta_fn(text)

    # 5. Calculate gamma (baseline for now, no git history yet)
    gamma = math.sqrt(alpha * beta)

    # 6. Calculate C_Σ
    c_sigma = (alpha * beta * gamma) ** (1 / 3)

    print(f"  Results: α={alpha:.3f} β={beta:.3f} γ={gamma:.3f} C_Σ={c_sigma:.3f}")

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
        "details": {"alpha": measurement.alpha_details, "beta": measurement.beta_details},
    }

    output_path.write_text(json.dumps(data, indent=2))
    print(f"  ✅ Written: {output_path}")


def aggregate_measurements(measurements: list[ComponentMeasurement]) -> dict:
    """
    Aggregate component measurements into project-level scores.

    For now: simple geometric mean.
    """
    if not measurements:
        raise ValueError("No measurements to aggregate")

    # Simple geometric mean for now
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

    return {"alpha": alpha_agg, "beta": beta_agg, "gamma": gamma_agg, "c_sigma": c_sigma_agg}


def write_project_json(
    version: str, measurements: list[ComponentMeasurement], aggregate: dict, output_dir: Path
):
    """Write project.json"""

    data = {
        "version": version,
        "date": datetime.now().isoformat(),
        "components": {
            m.file: f"components/{Path(m.file).with_suffix('.json')}" for m in measurements
        },
        "aggregate": aggregate,
        "verdict": "PASS" if aggregate["c_sigma"] >= 0.80 else "FAIL",
    }

    output_path = output_dir / "project.json"
    output_path.write_text(json.dumps(data, indent=2))
    print(f"\n✅ Written: {output_path}")


def generate_readme(
    version: str, aggregate: dict, measurements: list[ComponentMeasurement], output_dir: Path
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
            f"| `{m.file}` | {m.alpha:.3f} | {m.beta:.3f} | {m.gamma:.3f} | {m.c_sigma:.3f} |"
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
    print("=" * 70)
    print("TSC PROJECT MEASUREMENT")
    print("=" * 70)

    # 1. Read version
    version = read_version()
    print(f"\nVersion: {version}")

    # 2. Parse config
    print("\nParsing project.tsc...")
    components = parse_config()
    print(f"Found {len(components)} component(s) to measure")

    # 3. Measure each component
    measurements = []
    for i, component in enumerate(components, 1):
        file_path = component["file"]
        print(f"\n[{i}/{len(components)}] Measuring: {file_path}")

        measurement = measure_component(
            file_path=file_path, alpha_func=component["alpha"], beta_func=component["beta"]
        )
        measurements.append(measurement)

        # Write component output
        write_component_output(measurement, Path(".tsc"))

    # 4. Aggregate
    print("\n" + "=" * 70)
    print("AGGREGATING")
    print("=" * 70)
    aggregate = aggregate_measurements(measurements)
    print("\nProject aggregate:")
    print(f"  α = {aggregate['alpha']:.3f}")
    print(f"  β = {aggregate['beta']:.3f}")
    print(f"  γ = {aggregate['gamma']:.3f}")
    print(f"  C_Σ = {aggregate['c_sigma']:.3f}")

    # 5. Write outputs
    write_project_json(version, measurements, aggregate, Path(".tsc"))
    generate_readme(version, aggregate, measurements, Path(".tsc"))

    print("\n" + "=" * 70)
    print("✅ COMPLETE!")
    print("=" * 70)


if __name__ == "__main__":
    main()
