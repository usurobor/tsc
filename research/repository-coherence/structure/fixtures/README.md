# Structural Coherence fixtures

Discriminating fixtures for the [Structural Coherence CM](../CM.md), scored
against [`repository-planes-v1.1`](../../../../docs/architecture/decisions/repository-planes.md).

- [`plane-conformance.md`](./plane-conformance.md) — the primary fixture:
  positive paths in their canonical plane, negative paths drawn from the ADR's
  own recorded deferrals and known debt (so the CM fires on real debt), and the
  surviving refusal over a misplaced bundle's still-open destination — governed by
  an explicit asymmetry rule (an ADR bar or the closed docs taxonomy → defect; an
  undecided destination → refusal).

Structure is policy-conformance, so — unlike the legibility aspect's fresh-reader
task — the fixture classifies concrete tracked paths against the ratified planes
policy. A path passes by sitting in the plane the decision rule selects; it fails
by sitting elsewhere; and its correct home is refused only where the ADR still
leaves that home open. The CM measures against the policy — it does not author it.
