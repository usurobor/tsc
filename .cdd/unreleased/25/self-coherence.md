# Self-Coherence — Issue #25
# Sub 2 (#23): Complete v0.5.0 hybrid scoring

## Gap

OCaml engine is LLM-only (`--mode llm` default, credentials required).
`mechanical_scoring.mli` is committed (`ceea066`) but the implementation is absent.
No `--mode` flag. No `--files` flag. No `hybrid_scoring.ml`. No OCaml test scaffolding.
Offline/CI measurement is impossible; Sub 3 (OCaml tests) is blocked.

Design and plan are committed at `docs/design/0.5.0/DESIGN.md` and `docs/design/0.5.0/PLAN.md`.
This cycle completes Plan Steps 1, 3–9.

## Mode

MCA — implementing committed plan against converged design.

## Active Skills

Tier 1a: CDD.md, alpha/SKILL.md
Tier 1b: cdd/design (already done), cdd/plan (already done)
Tier 2: OCaml engineering bundle
Tier 3: cdd/design, cdd/plan (reference), cdd/review (α pre-review), cdd/release

## Impact Graph

- `mechanical_scoring.ml` — implements `.mli` contract (Step 3)
- `bundle.ml` — extend or verify `--files` / direct-file path (Step 1)
- `engine/ocaml/bin/main.ml` — add `--mode {mechanical,llm,hybrid,auto}` + `--files` flag (Step 4)
- `report.ml` / `response_schema.ml` — unified report shape: `mechanical`, `llm`, `final` sub-objects (Step 5)
- `hybrid_scoring.ml` — orchestrate both backends, produce unified result (Step 6)
- `engine/ocaml/test/` — OCaml test scaffolding for all ACs (Step 7)
- `README.md`, `QUICKSTART.md`, `ARCHITECTURE.md` — doc updates (Step 8)
- Default mode = `auto` policy (Step 9)

## Acceptance Criteria — Status

| AC | Description | Status |
|----|-------------|--------|
| AC1 | `coh --mode mechanical --files <paths>` works without credentials | pending |
| AC2 | `coh --mode llm --target spec` preserved from v0.4.0 | pending |
| AC3 | `coh --mode hybrid` produces mechanical+llm+final sub-objects | pending |
| AC4 | Direct file input and named target share same `Bundle.t` shape | pending |
| AC5 | Mechanical scoring is deterministic on identical input | pending |
| AC6 | Canonical JSON schema across modes (schema fixture validates) | pending |
| AC7 | README, QUICKSTART, ARCHITECTURE document all modes + direct-file | pending |
| AC8 | No Python reintroduced (`git ls-files '*.py'` empty) | pending |
| AC9 | LLM backend reads `runtime/SELF-MEASURE.md` | pending |
| AC10 | Every report contains `mode` field | pending |
| AC11 | `--mode auto` resolves to mechanical without credentials, hybrid with | pending |
| AC12 | Hybrid mode preserves both results; `final.source` named explicitly | pending |

## Known Debt

- Sub 1 (v3.2.0 provenance fields in report sub-objects) is a separate cycle; report schema shape here must accommodate those fields without re-engineering.
- Sub 3 (OCaml test migration of legacy Python tests) coordinates on test fixtures but is independent.
- No SELF-MEASURE.md rewrite in this cycle (Sub 1 owns).

## CDD Trace

| Step | Artifact | Skills loaded | Decision |
|------|----------|---------------|----------|
| 0 Observe | — | — | Cycle 2 under master #23; #27 just closed (docs-only). Assessment committed next MCA as #25. |
| 1 Select | issue #25 | CDD.md §3.3 | Assessment commitment default fires: #25 is the named next MCA. |
| 2 Branch | `cycle/25` from `origin/main` (56af43a) | cdd | Pre-flight passed; branch pushed. |
| 3 Bootstrap | — | — | α to create `docs/design/0.5.0/` snapshot stubs (design already committed; version dir for 0.5.0 bootstrap) |
| 4 Gap | this file §Gap | cdd | Named: LLM-only engine, no `--mode`, no `--files`, `.mli` without `.ml` |
| 5 Mode | this file §Mode | cdd | MCA — implementing committed plan |
| 6 Artifacts | pending | — | α to implement per plan Steps 1, 3–9 |
| 7 Self-coherence | this file | cdd | α to complete §AC Status, §Evidence, §CDD Trace |
| 7a Pre-review | pending | — | α to signal after CI green |
| 8 Review | `.cdd/unreleased/25/beta-review.md` | review | β pending |
| 9 Gate | pending | release | β pending |
| 10 Release | pending | release | β pending |

## Review-Readiness

[NOT READY — γ scaffold only. α to fill implementation, update AC evidence, and complete pre-review gate before signaling ready.]
