# Structural Coherence fixtures

Discriminating fixtures for the [Structural Coherence CM](../CM.md), scored
against [`repository-planes-v1`](../../../../docs/architecture/decisions/repository-planes.md).

- [`plane-conformance.md`](./plane-conformance.md) — the primary fixture:
  positive paths in their canonical plane, negative paths drawn from the ADR's
  own recorded deferrals (so the CM fires on real known debt), and the
  `UNDERDETERMINED` cases the ADR leaves open — governed by an explicit
  asymmetry rule (an ADR bar → defect; ADR silence → refusal).

Structure is policy-conformance, so — unlike the legibility aspect's fresh-reader
task — the fixture classifies concrete tracked paths against the ratified planes
policy. A path passes by sitting in the plane the decision rule selects; it fails
by sitting elsewhere; and it is `UNDERDETERMINED` when the ADR does not decide.
The CM measures against the policy — it does not author it.
