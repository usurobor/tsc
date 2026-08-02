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

### Repository Coherence CM — [`repository-coherence/`](repository-coherence/)

A parent methodology that composes coherence aspects — structural, legibility,
operational — over one repository snapshot, retaining their conflicts instead of
averaging them. TSC applied to its own repository. It measures and emits defects;
it does not repair.

- parent contract: [`repository-coherence/CM.md`](repository-coherence/CM.md) —
  composition, coverage, and the `RCM-*` requirement IDs.
- parent requirements: [`repository-coherence/requirements.md`](repository-coherence/requirements.md)
  — the parent requirement set (moved out of `CM.md`).
- aspect registry: [`repository-coherence/ASPECTS.md`](repository-coherence/ASPECTS.md)
  — the aspect registry and the decompose-by-property rule.
- implemented aspects: legibility
  ([`legibility/`](repository-coherence/legibility/)), structure
  ([`structure/`](repository-coherence/structure/)).
- latest composite: [`repository-coherence/runs/0001-composite.md`](repository-coherence/runs/0001-composite.md)
  — BASELINE, `DEFECTS_FOUND`.
  - measured snapshot: `48b9a635c59ec6ba00dd80ee7a48d1160d1e0656`
  - receipt publication commit: `920eba24f2f2224fa5b31c8721947693b4734e62`
    (one-commit lag: the snapshot is measured, then the receipt is published in a
    descendant commit).
- operability: registered, not implemented.
