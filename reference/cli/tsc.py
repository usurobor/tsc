"""
reference/cli/tsc.py — TSC Command Line Interface

Commands:
  compute  Compute C_Σ from a TSC YAML file
  self     Compute C_Σ for the TSC repository itself
"""

import json
import sys

import click

from reference.python.tsc_controller import compute_c_from_file


@click.group()
def main():
    """TSC Framework CLI."""
    pass


@main.command("compute")
@click.argument("path", type=click.Path(exists=True))
@click.option("--format", type=click.Choice(["text", "json"]), default="text")
@click.option("--seed", type=int, default=None)
def compute(path: str, format: str, seed: int | None):
    """Compute C_Σ from a TSC YAML file."""
    try:
        c_sigma = compute_c_from_file(path, seed=seed)

        if format == "json":
            click.echo(json.dumps({"C_sigma": c_sigma, "path": path}, indent=2))
        else:
            click.echo(f"C_Σ = {c_sigma:.4f}")

        # Exit code based on threshold (0.3 for examples)
        sys.exit(0 if c_sigma >= 0.3 else 1)

    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(2)


@main.command("self")
@click.option("--out", default="coherence_report.json", help="Output report path")
@click.option("--theta", default=0.7, type=float, help="Struct vs dist weight")
@click.option("--lambda-alpha", "lambda_alpha", default=4.0, type=float)
@click.option("--lambda-beta", "lambda_beta", default=4.0, type=float)
@click.option("--lambda-gamma", "lambda_gamma", default=4.0, type=float)
@click.option("--n-boot", "n_boot", default=1000, type=int, help="Bootstrap samples")
@click.option("--tau-braid", "tau_braid", default=1e-3, type=float, help="Braided threshold")
@click.option("--Theta", "Theta_", default=0.90, type=float, help="CI_lo gate threshold")
@click.option("--seed", default=42, type=int, help="Random seed")
def self_measure(
    out: str,
    theta: float,
    lambda_alpha: float,
    lambda_beta: float,
    lambda_gamma: float,
    n_boot: int,
    tau_braid: float,
    Theta_: float,
    seed: int,
):
    """Compute C_Σ for the TSC repository and emit provenance bundle."""
    try:
        from reference.python.self_measure import Params, write_report

        params = Params(
            theta=theta,
            lambda_alpha=lambda_alpha,
            lambda_beta=lambda_beta,
            lambda_gamma=lambda_gamma,
            n_boot=n_boot,
            tau_braid=tau_braid,
            Theta=Theta_,
            seed=seed,
        )

        click.echo("Computing C_Σ(TSC)...")
        rep = write_report(out, params)

        click.echo(json.dumps(rep, indent=2))
        click.echo(f"\nReport written to: {out}")
        click.echo(f"Verdict: {rep['verdict']}")

        sys.exit(0 if rep["verdict"] == "PASS" else 1)

    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        import traceback

        traceback.print_exc()
        sys.exit(2)


if __name__ == "__main__":
    main()
