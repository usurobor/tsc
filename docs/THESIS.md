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
2. The **engine** collects those files into a deterministic bundle.
3. The engine scores the bundle through one of three backends:
   - `mechanical` — deterministic structural-proxy scoring; no credentials, no network.
   - `llm` — semantic scoring via `runtime/SELF-MEASURE.md`.
   - `hybrid` — runs both; LLM is the semantic authority, mechanical anchors structural witnesses.
4. The engine returns α, β, γ scores and the canonical v3.2 composite, with evidence.
5. The engine validates and reports.

The theory lives in `spec/`. The engine lives in `engine/ocaml/`. The scoring instruction lives in `runtime/SELF-MEASURE.md`.

## The triadic composite

The composite is the geometric mean (spec [tsc-core.md](../spec/tsc-core.md) §5). Two canonical forms are reported:

```
C_Σ^math = (α · β · γ)^(1/3)
C_Σ^num  = exp((1/3) · Σ ln(max(sᵢ, ε)))
```

`C_Σ^math` is the strict mathematical form — one zero collapses it to zero, signalled by `zero_component_present`. `C_Σ^num` is the ε-floored numerical form used for thresholding, bootstrap CI, and OOD comparison; `numeric_floor_applied` records when the floor was active. The two forms coincide whenever every component is at least ε.

The composite is **not** an arithmetic average. A weak axis pulls it toward the bottleneck; an axis at zero collapses the whole. This is intentional — coherence is not an average.
