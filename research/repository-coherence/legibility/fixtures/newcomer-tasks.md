# Newcomer-task fixture

The primary semantic fixture. Give a fresh reader (the declared profile) only
the repository front door and ask six questions. Each answer must be reachable
from `README.md` plus at most one documented hop, without Git history, without
the glossary for basic identity, and without contradiction elsewhere — then
verified against its authority source.

| # | Question | Authority source the answer is checked against |
|---|---|---|
| Q1 | What is TSC? | `README.md` first screen · `docs/THESIS.md` |
| Q2 | Which specification is authoritative? | `STATUS.md` · `spec/README.md` |
| Q3 | What can be executed today? | `README.md` run section · `docs/quickstart/` |
| Q4 | What does the current `coh` engine actually implement? | `src/engine/ocaml/README.md` · `src/engine/ocaml/CONTRACT.md` |
| Q5 | What is the active research program? | `STATUS.md` program priority · `research/ascent/` |
| Q6 | What should a newcomer read or run next? | `README.md` "start here" |

## Pass condition

A question **passes** when the reader's answer is (a) correct against the
authority source, (b) reached in ≤ 1 hop from the front door, and (c) not
contradicted by any other live document. A question **fails** when the front
door is silent, the designated entry point is unreadable without the glossary,
the answer needs Git history, or another live document disagrees.

## Scoring

Record per-question `PASS / FAIL / PARTIAL` with the answer given, the hop taken,
and the authority check. The fixture as a whole passes only when all six pass;
this is `REPO-ENTRY-001` plus the comprehension face of `REPO-DOC-001`.

## Control

Run with a fresh model or a reader who has not seen the repository. A maintainer
cannot run this fixture on their own repository — they already know the answers,
which is precisely the coherence the fixture is testing for.
