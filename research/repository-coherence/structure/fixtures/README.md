# Structural Coherence fixtures

Discriminating fixtures for the [Structural Coherence CM](../CM.md), scored
against [`repository-planes-v1.1`](../../../../docs/architecture/decisions/repository-planes.md).

- [`plane-conformance.md`](./plane-conformance.md) — the primary fixture, with
  every row pinned to an exact `repository_commit` (v0.2): commit-pinned positive
  paths in their canonical plane, negative paths drawn from the ADR's own recorded
  deferrals and known debt (so the CM fires on real debt), the F1/F2
  QUICKSTART/ARCHITECTURE regression pair (defect @ `7514a21` → pass @ `a01fbb8`),
  the real 7-consumer factorized-beta graph pinned @ `7514a21`, the `docs/beta/`
  live/frozen MIXED negative, the α/β/γ-deletion near-miss regression case, and
  the surviving refusal over a misplaced bundle's still-open destination —
  governed by an explicit asymmetry rule (an ADR bar, the closed docs taxonomy, or
  live/frozen mixing → defect; an undecided destination → refusal).

Structure is policy-conformance, so — unlike the legibility aspect's fresh-reader
task — the fixture classifies concrete tracked paths against the ratified planes
policy. A path passes by sitting in the plane the decision rule selects; it fails
by sitting elsewhere; and its correct home is refused only where the ADR still
leaves that home open. The CM measures against the policy — it does not author it.
