# Quickstart: Run the Current Repository Proxy

This guide runs software release `0.12.0`. It does not run a TSC v4-conforming methodology.

Read [`STATUS.md`](STATUS.md) before interpreting output.

## 1 · Install

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/tsc/main/install.sh | sh
```

## 2 · Clone

```bash
git clone https://github.com/usurobor/tsc.git
cd tsc
```

## 3 · Choose a proxy mode

| Mode | Credentials | Current behavior |
|---|---|---|
| `mechanical` | None | Deterministic Markdown/corpus structural proxies |
| `llm` | Required | Semantic judgments under `runtime/SELF-MEASURE.md` |
| `hybrid` | Required | Both proxy routes, preserving projections |
| `auto` | Optional | Hybrid with complete credentials; mechanical otherwise |

## 4 · Run against files

```bash
coh --mode mechanical --files spec/ --output .tsc/
```

## 5 · Run a named target

```bash
coh --mode mechanical --target spec --registry targets/registry.tsc
```

## 6 · Run current self-measurement

```bash
coh self --mode mechanical
```

With provider credentials, `coh self` may run the current hybrid proxy route. `src/skills/self-measure/SKILL.md` governs that route.

## 7 · Read output honestly

Current reports contain v3.2-era proxy fields such as:

```text
alpha
beta
gamma
bottleneck_axis
C_sigma_math
C_sigma_num
```

They are useful for current-engine regression, structural defect discovery, and semantic ambiguity harvesting under the frozen proxy contract.

They do not establish a v4 joint realization fiber, relational atlas, lawful generator continuation, conformance, or standing.

## 8 · Run regression katas

```bash
bash scripts/run-katas.sh
```

`01-glider` and `02-random-soup` are document-scoring regressions, not positive and negative examples of the v4 coherence construct.

## 9 · Read v4

- [`spec/README.md`](spec/README.md)
- [`spec/tsc-conformance.md`](spec/tsc-conformance.md)
- [`conformance/README.md`](conformance/README.md)
- [`src/engine/ocaml/CONTRACT.md`](src/engine/ocaml/CONTRACT.md)

No command currently emits a passing v4 conformance receipt.
