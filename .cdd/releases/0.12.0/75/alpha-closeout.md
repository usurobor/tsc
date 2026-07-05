# α close-out — cycle/75 (factorized-β measurement harness, Sub-2 of #73)

Role: α (implementer). Branch: `cycle/75` (off `main` @ 75a11fc, Sub-1
engine present). Identity: `alpha@tsc.cdd.cnos`. Issue #75 AC1–AC5.

## Verdict of this cell

Implementation **complete and review-ready**. The measurement harness,
the pure A/B/C gate core, the CLI wiring, the witness-free gate tests, and
the credentialed CI workflow are on `cycle/75` and pushed. **No terminal
PASS/FAIL/NO-DECISION is recorded here** — that is emitted by the CI gate
step over real witness output, not fabricated by α.

## Deliverables

| Artifact | Purpose |
|----------|---------|
| `engine/ocaml/lib/factorized_beta_gate.{ml,mli}` | pure gate core: β `Coh_consistency` (barrier reused), A3 agreement, `evaluate_gate` (A0–A3 + B1–B3 + C4/C5), B3 controls label check |
| `engine/ocaml/bin/main.ml` (+5 subcommands) | `factorized-beta-inventory` / `-target` / `-gate` / `-controls-prompt` / `-controls-check` (thin binary) |
| `engine/ocaml/lib/dune` | registers `factorized_beta_gate` |
| `engine/ocaml/test/test_factorized_beta_gate.ml` (+dune) | 15 witness-free tests (barrier, A3, full gate matrix, B3 controls) |
| `scripts/factorized-beta-measure.sh` | per-target orchestration: inventory+prompt → k factorized witnesses → free-witness β baseline → aggregate |
| `.github/workflows/factorized-beta-measure.yml` | witness-gate · guards (B1/B2) · measure (5 targets ×k=3) · b3-controls · gate → terminal token |
| `.cdd/unreleased/75/self-coherence.md` | α self-coherence + debt rows |

## #75 AC status

- **AC1** harness (script + `measure` job) drives k=3 over all five
  held-out targets — **built; RUN in CI**.
- **AC2** inventory / raw responses / validation / per-target
  `β_factorized` / free-witness baseline emitted + uploaded — **wired;
  upload in CI**.
- **AC3** gate evaluated exactly as preregistered — **done + tested**
  (`test_factorized_beta_gate`).
- **AC4** single terminal `PASS | FAIL | NO-DECISION` + gate summary as a
  committed artifact — **emitted by the CI gate step**.
- **AC5** frozen prereg + fixtures unedited; no post-hoc gate parameter —
  **held** (floors/margins are compile-time constants; no `docs/beta/
  governance/` change).

## Not done here (by design)

- The measurement RUN and the terminal verdict — the credentialed CI
  witness's job (`factorized-beta-measure.yml`).
- Recording the verdict in the prereg §experiment-record + the CHANGELOG
  witness index — κ-as-γ, after the CI run.
- Local `dune build` / `dune runtest` — no OCaml toolchain here; CI is the
  build oracle. Any compile error surfaced by CI is a mechanical fix in
  this cell.

## Constraints honored

- α/γ scalar path (`Prompt`, `Response_schema`, scalar `main.ml`
  subcommands, `runtime/SELF-MEASURE.md`, `scripts/coh-self`,
  `.github/workflows/tsc-self-measure.yml`) untouched.
- Frozen prereg + B3 fixture unedited. No credential re-pin. No standing
  promotion. No fabricated/stubbed verdict.

## Handoff

β reviews against #75 AC1–AC5 and writes `beta-review.md`; α/β close-outs
gate the merge (`validate-release-gate.sh --mode pre-merge`). Debt rows
1–5 in `self-coherence.md` are surfaced to δ. cycle/75 HEAD is the record.
