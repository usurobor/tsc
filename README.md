# TSC

TSC is a framework for deciding whether several observations can be explained by one lawful process, while preserving the evidence, the alternative explanations, and the questions left unresolved.

It returns a proof-carrying receipt — not a single score — so a coherence decision can be inspected, disputed, and traced back to its evidence.

## Where the project stands today

| Aspect | State |
|---|---|
| Specification | 4.1.0 Draft |
| Last ratified specification | 4.0.0 Normative |
| Current CLI | `coh` 0.12.0 — a v3.2-era repository proxy, **not** TSC v4 |
| Current research | Articulation Ascent |

[`STATUS.md`](STATUS.md) is the single authority for detailed status, versions, and the ratified-4.0.0 locator. Read it before interpreting any score or report.

## Start here

| I want to… | Go to |
|---|---|
| Understand the idea | [`docs/THESIS.md`](docs/THESIS.md) |
| Try the current CLI | [`docs/quickstart/README.md`](docs/quickstart/README.md) |
| Read the spec | [`spec/README.md`](spec/README.md) |
| Follow Articulation Ascent | [`research/ascent/README.md`](research/ascent/README.md) |
| Contribute | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| Navigate all documentation | [`docs/README.md`](docs/README.md) |

## Run the current repository proxy

The current `coh` engine is a repository-proxy tool from the v3.2-era line. It does **not** implement TSC v4 and emits no v4 conformance receipt.

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/tsc/main/install.sh | sh
git clone https://github.com/usurobor/tsc.git
cd tsc
coh --mode mechanical --files 'spec/**/*.md' --output .tsc/
```

Its outputs are v3.2-era proxy results, useful for regression and structural defect discovery. They carry no v4 coherence meaning and no v4 conformance standing. See [`docs/quickstart/README.md`](docs/quickstart/README.md) for the full executable path.

## Learn more

- **The specification** — reading order, layer authority, and version domains: [`spec/README.md`](spec/README.md)
- **Why the foundation is shaped this way** — design history and prior-cycle records: [`docs/README.md`](docs/README.md)
- **Conformance** — what a 4.1 implementation must prove; nothing conforms to 4.1 yet: [`conformance/README.md`](conformance/README.md)
- **Detailed status** — versions, ratification, and evidence standing: [`STATUS.md`](STATUS.md)

## License and citation

TSC is licensed under [CC BY 4.0](LICENSE). Citation metadata lives in [`CITATION.cff`](CITATION.cff). Do not copy a software version literal into another document.
