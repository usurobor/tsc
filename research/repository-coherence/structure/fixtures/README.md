# Structural Coherence fixtures

Discriminating fixtures for the [Structural Coherence CM](../CM.md), scored
against [`repository-planes-v1.1`](../../../../docs/architecture/decisions/repository-planes.md).

- [`plane-conformance.md`](./plane-conformance.md) — the primary fixture. Every
  case is immutable: synthetic, or a real path pinned to an exact
  `repository_commit`. It carries the F1/F2 root-file regression pairs
  (DEFECT @ `7514a21` → PASS @ `a01fbb8`), positive paths in their canonical
  plane, negatives drawn from the ADR's own recorded deferrals, the flipped
  `STRUCT-MIXED-001` negative, the 7-consumer graph for the factorized-β fixture,
  the near-miss deletion-without-consumer-graph FAIL case, and the surviving
  destination refusal — governed by an explicit asymmetry rule (an ADR bar or the
  closed docs taxonomy → defect; an undecided destination → refusal).

Structure is policy-conformance, so — unlike the legibility aspect's fresh-reader
task — the fixture classifies concrete tracked paths against the ratified planes
policy. A path passes by sitting in the plane the decision rule selects; it fails
by sitting elsewhere; and its correct home is refused only where the ADR still
leaves that home open. The CM measures against the policy — it does not author it.
