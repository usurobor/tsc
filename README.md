# TSC

TSC defines how a declared methodology may warrant that observations belong to one lawful generative process.

The repository currently contains two different surfaces:

- **TSC specification 4.1.0 Draft** — the candidate theory and conformance contract;
- **`coh` software 0.12.0** — the current repository-proxy engine, which does not implement TSC v4.

Read [`STATUS.md`](STATUS.md) before interpreting any score or report.

## Repository map

| Path | Role | Authority |
|---|---|---|
| [`spec/`](spec/README.md) | Typed articulation, coherence receipts, methodology lifecycle, observation dynamics, conformance | Canonical draft specification |
| [`conformance/`](conformance/README.md) | Fixtures implementing specification requirement IDs | Evidence; no standing until verified |
| [`src/engine/ocaml/`](src/engine/ocaml/README.md) | Current `coh` repository-proxy executable | Canonical executable of the proxy methodology, not v4 |
| [`src/skills/`](src/skills/README.md) | Current self-measurement and CM-of-CMs declarations | Authority for existing proxy methodologies |
| [`katas/`](katas/README.md) | Regression inputs for the current proxy engine | Implementation regression only |
| [`illustrations/`](illustrations/README.md) | Conceptual examples | Informative |
| [`docs/`](docs/README.md) | Design, research, governance, and guides | Authority stated by each document |
| [`.tsc/`](.tsc/COHERENCE.md) | Generated reports and historical ledger | Generated state; not theory |

## Read the theory

1. [`spec/c-equiv.md`](spec/c-equiv.md) — polar expressions, typed articulation, and exact deterministic Set behavior;
2. [`spec/tsc-core.md`](spec/tsc-core.md) — behavior contracts, joint realization fibers, and structured receipts;
3. [`spec/tsc-oper.md`](spec/tsc-oper.md) — compilation, assessment, admission, authorization, execution, and refusal;
4. [`spec/tsc-observation-dynamics.md`](spec/tsc-observation-dynamics.md) — lineage, comparison, intervention, lift, and failure persistence;
5. [`spec/tsc-conformance.md`](spec/tsc-conformance.md) — permanent proof obligations.

The motivation and historical evidence live outside the normative specification:

- [`DESIGN.md`](docs/design/foundation-contract-reconciliation/DESIGN.md)
- [`ARCHAEOLOGY.md`](docs/design/foundation-contract-reconciliation/ARCHAEOLOGY.md)
- [`CUTOVER-RECEIPT.md`](docs/design/foundation-contract-reconciliation/CUTOVER-RECEIPT.md)
- [`Polar expression recovery`](docs/design/polar-expression-recovery/DESIGN.md)

## Run the current repository proxy

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/tsc/main/install.sh | sh
git clone https://github.com/usurobor/tsc.git
cd tsc
coh --mode mechanical --files spec/ --output .tsc/
```

Run the declared self-measurement route:

```bash
coh self --mode mechanical
```

These commands emit v3.2-era repository-proxy results. They are useful for regression, defect discovery, and historical comparison within that methodology. They are **not** v4 coherence receipts and carry no v4 conformance standing.

See [`QUICKSTART.md`](QUICKSTART.md) for the current executable path.

## Conformance status

No implementation currently conforms to TSC 4.1. The first fixture families are specified under [`conformance/`](conformance/README.md). A specified fixture earns no standing until its generator, oracle, positive case, negative case, and evidence are implemented and verified.

The candidate 4.1 normative headers carry `Status: Draft` until mathematical, document, and conformance review closes and a ratification-only commit is independently reviewed.

## Version domains

TSC versions these artifacts independently:

```text
specification
software / engine
methodology
receipt schema
```

`VERSION` is the software release source. Specification versions live in specification headers. A change in one lineage does not imply a change in another.

## Contributing

A contribution names the surface it changes and proves the matching contract:

- specification changes require mathematical and cross-spec review;
- conformance changes require positive and negative evidence;
- engine changes require regression tests and truthful status projections;
- methodology changes require calibration, standing, and lineage evidence.

## License and citation

TSC is licensed under [CC BY 4.0](LICENSE).

Citation metadata lives in [`CITATION.cff`](CITATION.cff). Do not copy a software version literal into another document.
