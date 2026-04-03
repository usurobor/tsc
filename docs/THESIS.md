# TSC

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
C_Σ = (α · β · γ)^(1/3)
```

One zero collapses everything. This is intentional — coherence is not an average.
