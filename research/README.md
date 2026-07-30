# research/ — pre-normative investigation

This plane holds work that is **not yet authoritative**: decisions, traces,
experiments, and results for programs still under investigation. Nothing here
binds an implementation.

If a research program survives, its surviving semantics are **re-authored**
afresh under `spec/` (RFC/KEP discipline). The research record stays here as
provenance — it is not moved into `spec/`, and it is not rewritten as though it
had always been normative.

## Programs

### Articulation Ascent — [`ascent/`](ascent/)

The generative program that uses TSC's warrant infrastructure (candidate
fibers, comparison, warrant classes, refusal, evidence lineage).

- [`ascent/DECISIONS.md`](ascent/DECISIONS.md) — D-001 (surface arity and frame
  construction), decided.
- [`ascent/traces/`](ascent/traces/) — hand traces that exercise the kernel
  design before `KERNEL.md` is written. `000-hello-world.md` is the v0.1 gate
  (passing fresh-model control); `001`/`002` are deferred stress traces.

Future: if the kernel survives its traces, an executable package lands under
`src/` and normative semantics are authored under `spec/`; a conformance family
lands under `conformance/ascent/`.
