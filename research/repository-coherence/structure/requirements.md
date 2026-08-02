# Repository Structural Coherence — requirements

Stable requirement IDs the CM checks against
[`repository-planes-v1`](../../../docs/architecture/decisions/repository-planes.md).
Each carries a class (mechanical or semantic), a default severity, the ADR clause
it derives from, and needs a positive and a negative fixture under
[`fixtures/`](./fixtures/). IDs are permanent; wording may sharpen.

| ID | Requirement | Class | Severity | ADR clause |
|---|---|---|---|---|
| `STRUCT-PLANE-001` | Every tracked path resolves to exactly one root plane; no path is a peer to the six planes or spans two. | mechanical | P0 | Target planes (root) |
| `STRUCT-RULE-001` | Each path's plane is the one the decision rule selects (*bind*→spec, *run*→src, *prove*→conformance, *still change*→research, *help a person*→docs, *automate*→scripts). | mechanical + semantic | P0 | Decision rule |
| `STRUCT-CANON-001` | Every artifact the ADR program-maps give a canonical home sits at that home. | mechanical | P0 | Program maps |
| `STRUCT-NAME-001` | Names predict content and are consistent within a plane; docs paths file by reader intent, never by α/β/γ role grammar. | mechanical + semantic | P1 | Docs reader-intent taxonomy |
| `STRUCT-FUNC-001` | Each directory serves one function; no plane is a single-occupant catch-all standing in for a real home. | semantic | P1 | Iterations 1 & 3 (defer `src/packages/`; no single-occupant `config/`) |
| `STRUCT-OWNER-001` | Each artifact has one owner — one authoritative home, no duplicate live copies. | mechanical | P0 | Invariants ("no document's meaning changes"; one home per artifact) |
| `STRUCT-MIXED-001` | No live directory mixes live-mutable content with frozen, snapshot, or archived content. | mechanical + semantic | P0 | Migration state (frozen snapshots preserved intact) |
| `STRUCT-LIFECYCLE-001` | Historical and generated artifacts are labelled and distinguishable; generated output does not read as a hand-authored source. | semantic | P1 | Do NOT touch (tooling/data ≠ content); build-output exclusions |
| `STRUCT-EXCLUDE-001` | The do-not-touch set (`.cdd/`, `.cn-sigma/`, `heldout/`) is excluded from content classification, never flagged as misplaced content. | mechanical | P0 | Do NOT touch |
| `STRUCT-REFUSE-001` | When the ADR does not decide a path's home, the CM returns `UNDERDETERMINED` for that path and does not assign a plane. | process | P0 | Deferred — foundation bundle ("a decision to take with the operator's frame, not to force here") |
| `STRUCT-REPAIR-001` | A repair run changes only findings in scope and preserves meaning; a move commit changes no document's meaning (evidence-boundary rule). | process | P0 | Invariants ("No meaning change, not no edits") |
| `STRUCT-REVIEW-001` | A `COHERENT_WITHIN_DECLARED_SCOPE` claim requires an independent full-scope review, separate from the repair actor. | process | P0 | Parent `RCM-BOUNDARY-001` |

## Subcontract → requirement map

```text
Placement            STRUCT-PLANE-001 · STRUCT-RULE-001 · STRUCT-CANON-001 · STRUCT-EXCLUDE-001
Naming               STRUCT-NAME-001
Ownership & function STRUCT-FUNC-001 · STRUCT-OWNER-001
Lifecycle            STRUCT-MIXED-001 · STRUCT-LIFECYCLE-001
Refusal (crosscut)   STRUCT-REFUSE-001
Process (boundary)   STRUCT-REPAIR-001 · STRUCT-REVIEW-001
```

## Notes on the three process requirements

`STRUCT-REFUSE-001`, `STRUCT-REPAIR-001`, and `STRUCT-REVIEW-001` do not score a
path. `STRUCT-REFUSE-001` binds the CM to policy authority — it may not invent a
home the ADR withholds. `STRUCT-REPAIR-001` and `STRUCT-REVIEW-001` constrain how
the downstream repair wave and its closure run; the CM records whether a closure
satisfied them, but it does not itself move files or close.

## Fixtures

Each `STRUCT-*` ID needs:
- a **positive** fixture — a path that satisfies it in its canonical plane;
- a **negative** fixture — a state that violates it, with the exact evidence the
  CM should surface.

Seed fixtures are drawn from this repository's own tree and the ADR's recorded
deferrals, so the CM demonstrably fires on real known debt (root `QUICKSTART.md`
/ `ARCHITECTURE.md` outside the docs planes; `docs/beta/governance/` live infra
inside a role-grammar tier tree) and correctly refuses the one home the ADR
leaves open (the foundation-contract-reconciliation bundle). See
[`fixtures/`](./fixtures/).
