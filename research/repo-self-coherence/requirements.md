# Repository Self-Coherence — requirements

Stable requirement IDs the CM checks. Each carries a class (mechanical or
semantic), a default severity, and needs a positive and a negative fixture under
`fixtures/`. IDs are permanent; wording may sharpen.

| ID | Requirement | Class | Severity |
|---|---|---|---|
| `REPO-ENTRY-001` | The front door identifies the project, the runnable surface, the active research, and the next paths — in one screen. | semantic | P0 |
| `REPO-DOC-001` | Every live document answers one governing question, with purpose and authority visible immediately. | semantic | P1 |
| `REPO-AUTH-001` | Every stable fact has one authoritative home; no two documents claim incompatible authority. | semantic + mechanical | P0 |
| `REPO-STATUS-001` | Every status projection agrees with its authority source (spec version, software version, ratification, conformance standing). | mechanical | P1 |
| `REPO-PATH-001` | Every current path and Markdown link on the live surface resolves. | mechanical | P0 |
| `REPO-STRUCTURE-001` | Directory placement matches the declared repository-plane contract; no two documentation systems are presented as authoritative at once. | mechanical + semantic | P0 |
| `REPO-HISTORY-001` | Historical, superseded, or generated artifacts cannot be read as current instructions. | semantic | P1 |
| `REPO-RUN-001` | Documented runnable commands execute under the declared environment. | mechanical | P0 |
| `REPO-NOISE-001` | Repetition, stale wrappers, and obsolete navigation do not obscure current project truth. | semantic | P2 |
| `REPO-REPAIR-001` | A repair run changes only findings in scope and preserves meaning (evidence-boundary rule). | process | P0 |
| `REPO-REVIEW-001` | A `COHERENT_WITHIN_DECLARED_SCOPE` claim requires an independent full-scope review, separate from the repair actor. | process | P0 |

## Notes on the two process requirements

`REPO-REPAIR-001` and `REPO-REVIEW-001` do not score the artifact; they constrain
how the downstream repair wave and its closure are run. The CM records whether a
given closure satisfied them, but it does not itself repair or close.

## Fixtures

Each `REPO-*` ID needs:
- a **positive** fixture — a repository state (or minimal excerpt) that satisfies it;
- a **negative** fixture — a state that violates it, with the exact evidence the
  CM should surface.

Seed fixtures are drawn from this repository's own before/after history: the
pre-cleanup commit `650bb13` supplies negatives (a broken headline command for
`REPO-RUN-001`, a README/STATUS contradiction for `REPO-AUTH-001`, ~42 dead
relative links for `REPO-PATH-001`, a fabricated parser subsystem for
`REPO-HISTORY-001`/`REPO-DOC-001`); the post-cleanup commit `1c752a8` supplies the
matching positives for the content-level axes — while still failing
`REPO-ENTRY-001`, `REPO-STRUCTURE-001`, and `REPO-DOC-001` on the documentation
architecture. See `runs/` and `results/`.
