# Engine

The canonical TSC measurement engine. OCaml-first, LLM-native.

## Canonical spec

The canonical implementation is `engine/ocaml/`. The operator manual is [docs/beta/guides/OPERATOR-MANUAL.md](../../beta/guides/OPERATOR-MANUAL.md).

## Documents

| Document | Path | Purpose |
|----------|------|---------|
| Design | [0.1.0/DESIGN.md](0.1.0/DESIGN.md) | Architecture, acceptance criteria, invariants |
| Plan | [0.1.0/PLAN.md](0.1.0/PLAN.md) | Implementation steps and checkpoints |
| Self-coherence | [0.1.0/SELF-COHERENCE.md](0.1.0/SELF-COHERENCE.md) | AC evidence, triadic self-assessment, friction log |
| Scoring instruction | [runtime/SELF-MEASURE.md](../../../runtime/SELF-MEASURE.md) | LLM-executable scoring rules and output contract |
| Operator manual | [OPERATOR-MANUAL.md](../../beta/guides/OPERATOR-MANUAL.md) | Build, configure, run, troubleshoot |

## Version history

| Version | Directory | Note |
|---------|-----------|------|
| 0.1.0 | [0.1.0/](0.1.0/) | First release. Replaces Python reference. |
