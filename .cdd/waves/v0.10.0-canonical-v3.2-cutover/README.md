# Wave: v0.10.0 canonical v3.2 scoring cutover

**Master issue:** [#49](https://github.com/usurobor/tsc/issues/49)
**Dispatch mode:** `.cdd/DISPATCH` §5.2 — single-session δ-as-γ via Agent tool
**Wave started:** 2026-05-13
**Wave operator (δ):** Claude (Sonnet 4.6)

## Purpose

Drive the v0.10.0 canonicalization cutover (master #49 → 5 sub-issues) through
to a tagged release. The wave is the cross-cycle coordination surface that
sequences γ dispatches and aggregates progress.

## Members

| Sub | Issue | Title | Branch | Precondition | Parallelizable? |
|---|---|---|---|---|---|
| S1 | [#50](https://github.com/usurobor/tsc/issues/50) | canonical aggregate + report schema replacement | `cycle/50` | none | yes |
| S2 | [#51](https://github.com/usurobor/tsc/issues/51) | strict v3.2 LLM δ validation + validation_failure artifact | `cycle/51` | none | yes |
| S3 | [#52](https://github.com/usurobor/tsc/issues/52) | OOD aggregate_semantics detector | `cycle/52` | none | yes |
| S4 | [#53](https://github.com/usurobor/tsc/issues/53) | cross-target report surface (Operational §7.4) | `cycle/53` | #50 schema decisions | yes (schema lock-in only) |
| S5 | [#54](https://github.com/usurobor/tsc/issues/54) | cutover cleanup | `cycle/54` | #50 merged to `main` | no — held until S1 lands |

## Dispatch waves

**Wave 1 (in-flight):** γ@S1, γ@S2, γ@S3, γ@S4 dispatched in parallel.
**Wave 2 (deferred):** γ@S5 dispatched after S1 merges to `main`.
**Wave 3 (release):** δ tags `v0.10.0` after all five subs merge.

## Reporting protocol

Each γ writes to its own cycle artifact channel:
- branch `cycle/{N}` for code commits
- `.cdd/unreleased/{N}/self-coherence.md` for the primary branch artifact
- `.cdd/unreleased/{N}/gamma-closeout.md` for the cycle's close-out

The wave channel aggregates state from those per-cycle artifacts:
- `.cdd/waves/v0.10.0-canonical-v3.2-cutover/STATUS` — flat key/value rows, one per sub, updated by δ after each γ completes
- `.cdd/waves/v0.10.0-canonical-v3.2-cutover/dispatches/{N}.md` — δ's dispatch record + γ's final report per sub

## Authority notes

- `.cdd/DISPATCH` §5.2 authorizes δ-as-γ via the Agent tool — the runtime model is "one γ-shaped subagent per cycle, dispatched in parallel from a δ session."
- γ creates each cycle branch from `origin/main` (per CDD §1.4 γ algorithm Phase 1 step 3a). δ does not pre-create branches.
- The implementation cycles operate under known constraints: no OCaml toolchain in the dispatch sandbox; γ may scaffold + commit code but build/test verification falls to CI. Each γ documents this in its close-out.
- Pre-emptive work on branch `claude/canonicalize-v3.2-scoring-S3MVu` (Round-1 implementation, pre-contract) is **not** to be reused as-is. γ@S1 may reference it for prior-art, but must produce work coherent with the Round-3 contract in #50.
