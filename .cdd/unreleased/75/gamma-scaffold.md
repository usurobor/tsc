# gamma-scaffold.md — cycle/75

Sub-issue: #75 — factorized-β measurement harness + k=3 run + A/B/C verdict
Master: #73. Depends on: #74 (engine substrate, merged to main @ 75a11fc).
Branch: `cycle/75` (off `origin/main` @ 75a11fc — Sub-1 engine present).
Dispatch mode: §5.2 single-session δ-as-γ via Agent tool (κ operating δ=γ; γ cap A−).

## This is the VERDICT cell

Sub-1 shipped the engine (`engine/ocaml/lib/factorized_beta.ml`). Sub-2 builds the harness
that *runs the experiment* and records the terminal PASS / FAIL / NO-DECISION against the
frozen pre-registered gate. No verdict was recorded in Sub-1.

## Frozen authority (immutable — no protocol edits after seeing output)

- `docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md` (rev 4) — the A/B/C gate.
- `docs/beta/governance/fixtures/factorized-beta-controls.json` — the B3 oracle.
- `engine/ocaml/lib/factorized_beta.{ml,mli}` — inventory + adjudication prompts + aggregation.

## Scope (per #75)

Harness (script + CI job) that: emits per-locus prompts → runs k=3 factorized-β witnesses per
held-out target (all five) via the credentialed CI witness → uploads inventory / raw responses /
validation artifacts → per-target `β_factorized` → free-witness baseline → A0/A1/A2/A3 + B1/B2/B3
+ C gate summary → terminal PASS / FAIL / NO-DECISION.

## Environment

- No local OCaml toolchain and no witness credential in this container: α builds the harness +
  CI wiring; the **measurement RUN is the credentialed CI witness** (`CLAUDE_CODE_OAUTH_TOKEN`,
  verified working). Build/lint validated by `ci.yml` + `cdd-artifact-validate`.
- Reuse the existing self-measure witness plumbing (`.github/workflows/tsc-self-measure.yml`,
  `scripts/coh-self`) as the pattern; do NOT re-pin credentials or touch the α/γ scalar path.

## Handoff

α builds the harness + `self-coherence.md` + `alpha-closeout.md` on `cycle/75`; β reviews
against #75 AC1–AC5, writes `beta-review.md`. The measurement run + verdict are recorded by
κ-as-γ in the prereg experiment-record + CHANGELOG once the credentialed CI run lands.
