"""
reference/cli/tsc.py — TSC CLI

Command-line interface for TSC self-measurement.
"""

import json
import sys

import click


@click.group()
def main():
    """TSC: Triadic Self-Coherence Framework"""
    pass


@main.command("self")
@click.option("--theta", default=0.7, type=float, help="Struct vs dist weight")
@click.option("--lambda-alpha", "lambda_alpha", default=4.0, type=float)
@click.option("--lambda-beta", "lambda_beta", default=4.0, type=float)
@click.option("--lambda-gamma", "lambda_gamma", default=4.0, type=float)
@click.option("--n-boot", "n_boot", default=1000, type=int, help="Bootstrap samples")
@click.option("--Theta", "Theta_", default=0.90, type=float, help="CI_lo gate threshold")
@click.option("--seed", default=42, type=int, help="Random seed")
def self_measure(
    theta: float,
    lambda_alpha: float,
    lambda_beta: float,
    lambda_gamma: float,
    n_boot: int,
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
            Theta=Theta_,
            seed=seed,
        )

        click.echo("Computing C_Σ(TSC)...")
        rep = write_report(params)

        click.echo(json.dumps(rep, indent=2))
        click.echo(f"\nVerdict: {rep['verdict']}")

        sys.exit(0 if rep["verdict"] == "PASS" else 1)

    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        import traceback

        traceback.print_exc()
        sys.exit(2)


if __name__ == "__main__":
    main()
