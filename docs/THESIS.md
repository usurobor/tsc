# The TSC Thesis

TSC (Triadic Self-Coherence) is a theory of measurement for systems that describe themselves.

It answers one question:

> Do three independent descriptions of the same system still describe one system?

The three descriptions are:

- **α — pattern coherence** — does the system have stable internal structure?
- **β — relational coherence** — do the parts refer to each other consistently?
- **γ — process coherence** — does the system evolve without losing identity?

These are not metrics to optimize. They are observations. A system either coheres or it does not.

## What TSC is not

TSC is not a linter. It does not enforce style, count errors, or check syntax.

TSC is not a test suite. It does not assert expected outputs.

TSC is not a quality score. A high C_Σ does not mean "good" — it means "coherent." A coherent system can be wrong. An incoherent system cannot be trusted to know whether it is right.

## How it works

1. A **target** declares what is being measured: which files, what kind of surface.
2. The **engine** collects those files into a raw bundle and sends them to an LLM with a scoring instruction.
3. The LLM returns α, β, γ scores with evidence.
4. The engine validates and reports.

The theory lives in `spec/`. The engine lives in `engine/ocaml/`. The scoring instruction lives in `runtime/SELF-MEASURE.md`.

## The triadic composite

The composite score is the geometric mean:

```
C_Σ^math = (α · β · γ)^(1/3)
C_Σ^num  = (max(α, ε) · max(β, ε) · max(γ, ε))^(1/3)
```

`C_Σ^math` is the mathematical aggregate — one zero component collapses it to zero. This is intentional: coherence is not an average.

`C_Σ^num` is the numerical aggregate used for reporting and verdicts. It floors each component at `ε = 10⁻⁵` so the score stays well-defined when a component is exactly zero. The two aggregates coincide whenever every component is at or above `ε`.

Both forms are emitted under `provenance.aggregate_math` and `provenance.aggregate_numeric` in every report (canonical v3.2 shape). There is no flat top-level `c_sigma` — readers consult provenance for the aggregate facts and the per-axis values for the bottleneck.
