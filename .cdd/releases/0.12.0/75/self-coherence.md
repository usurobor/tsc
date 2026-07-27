# α self-coherence — cycle/75 (factorized-β measurement harness)

Role: α (implementer). Authority: FROZEN
`docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md` (rev 4) +
`docs/beta/governance/fixtures/factorized-beta-controls.json` + issue #75
(AC1–AC5). Identity: `alpha@tsc.cdd.cnos`. Sub-2 of #73 — the **VERDICT
cell**: Sub-1 (#74) shipped the engine substrate; this cell builds the
harness that RUNS the experiment and produces the terminal
PASS / FAIL / NO-DECISION against the frozen gate.

## Gap addressed

Sub-1 gave the deterministic inventory, `β_factorized` aggregation, and
sample validation, but nothing that (a) drives k=3 factorized-β witnesses
over the five held-out targets, (b) measures the same-tree free-witness β
baseline, (c) computes the per-target β `Coh_consistency` + locus-verdict
agreement, or (d) evaluates the A/B/C gate into a single terminal verdict.
This cell adds exactly that — thin binary over a pure gate core, a
reviewable orchestration script, and a credentialed CI workflow. No
verdict is fabricated: PASS/FAIL/NO-DECISION is emitted by the CI gate
step over real witness output.

## What was implemented

- **`engine/ocaml/lib/factorized_beta_gate.ml` (+ `.mli`)** — the pure
  gate core:
  - `beta_spread` / `beta_coh_consistency` — β cross-sample consistency
    (A1) as the **max-pairwise spread over the per-sample `β_factorized`
    values, routed through {!Coherence.coherence_link}** (λ=1). The
    barrier is NOT re-implemented (prereg constraint); it is the same
    max-pairwise statistic `Witness_numeric.per_field_spread` computes,
    specialized to the single β field.
  - `locus_agreement` — A3, the mean over all unordered sample pairs and
    eligible loci of verdict-equality, exactly per the prereg formula.
  - `target_measure` record + `to_json` / `of_json` — the per-target
    measurement artifact (N, E, sparse, declared/validated/refused,
    per-sample β, β Coh_consistency, agreement, free-witness baseline).
  - `evaluate_gate` — A0 yield · A1 ≥ 0.90 · A2 ≥ baseline+0.10 · A3 ≥
    0.90 on every non-`locus_sparse` target, plus B1/B2/B3; **C4** (>1
    held-out `locus_sparse` → NO-DECISION) and **C5** (any A/B miss →
    FAILED); `string_of_verdict_token` → `PASS | FAIL | NO-DECISION`.
  - `controls_prompt` / `controls_check` / `b3_result` — B3 discrimination
    gate: the typed-fixture half (reusing `Factorized_beta.validate_controls`)
    plus the **witness label-agreement** half — builds synthetic resolved
    loci from the frozen controls, and checks each witness verdict against
    the oracle `expected_verdict` (n<20 ⇒ every hard control matches;
    n≥20 ⇒ ≥95%) with the negative-verdict two-sided-evidence rule.
- **`engine/ocaml/bin/main.ml`** — five thin git-style subcommands
  (mirroring `consistency-spread` / `witness-medoid`), pure-core-in-lib:
  - `factorized-beta-inventory` — emit the pre-witness inventory artifact
    (`inventory_to_json`) + the bounded adjudication prompt
    (`adjudication_instruction`) for a target.
  - `factorized-beta-target` — ingest k witness responses → `parse` →
    `validate_sample` (refuse, don't skip) → per-sample `β_factorized` →
    β `Coh_consistency` + A3 agreement → the per-target measurement
    record, carrying the free-witness baseline for A2.
  - `factorized-beta-gate` — read the per-target records + B1/B2/B3 flags
    → `evaluate_gate` → gate summary + the single terminal token.
  - `factorized-beta-controls-prompt` / `-check` — the B3 controls
    adjudication prompt + the label-agreement check.
  The α/γ scalar path (`Prompt`, `Response_schema`, the scalar subcommands,
  `runtime/SELF-MEASURE.md`, `scripts/coh-self`,
  `.github/workflows/tsc-self-measure.yml`) is **untouched**.
- **`engine/ocaml/lib/dune`** — added `factorized_beta_gate`.
- **`engine/ocaml/test/test_factorized_beta_gate.ml` (+ dune)** — 15
  witness-free tests: barrier routing, A3 agreement, the whole gate
  combination (PASS / a FAIL per each of A0/A1/A2/A3/guard / NO-DECISION /
  one-sparse-still-scored), JSON round-trip, and the B3 controls check
  over the committed frozen fixture (agree / mismatch / evidence-side).
- **`scripts/factorized-beta-measure.sh`** — per-target orchestration:
  emit inventory+prompt → k factorized witnesses → same-tree free-witness
  scalar β baseline (k scalar witnesses → funnel-validate →
  `cm-consistency.sh llm-spread` → β-field spread → barrier) → aggregate.
  The witness CALL is delegated to `$WITNESS_CMD "<prompt>" "<response>"`
  so the engine steps stay deterministic and reviewable; CI supplies the
  credentialed Claude-CLI wrapper.
- **`.github/workflows/factorized-beta-measure.yml`** — the run:
  `witness-gate` (secret presence, like self-measure) · `guards`
  (credential-free B1 katas + B2 admissibility) · `measure` (5-target
  matrix, k=3, factorized + baseline arms; auth routing + acceptEdits
  settings mirrored from `tsc-self-measure.yml`) · `b3-controls` (typed +
  label agreement) · `gate` (combine → terminal token, gate summary,
  step-summary). All artifacts uploaded; prompts (full bundle text)
  excluded from upload.

## ACs addressed

- **AC1** — the harness (script + `measure` CI job) drives k=3
  factorized-β witnesses over all five held-out targets using
  `factorized_beta`'s inventory + adjudication + aggregation, gated on
  `CLAUDE_CODE_OAUTH_TOKEN`. **Built here; the RUN is CI's job.**
- **AC2** — emits + uploads inventory artifacts, raw responses, validation
  (refusal counts in the measurement record), per-target `β_factorized`,
  and the free-witness baseline (`--baseline-beta-coh` + `baseline/*.llm.json`).
  Wiring built; **artifact upload runs in CI.**
- **AC3** — `evaluate_gate` implements the gate exactly as preregistered
  (A0/A1/A2/A3 + B1/B2/B3 + C4/C5); pinned by `test_factorized_beta_gate`.
- **AC4** — the single terminal token `PASS | FAIL | NO-DECISION` + gate
  summary is a committed CI artifact (`fb-gate-summary-<sha>`). **Emitted
  by the CI gate step over real witnesses.**
- **AC5** — the frozen prereg + fixtures are **not** edited (verified: no
  change under `docs/beta/governance/`); no gate parameter is settable
  from witness output — floors/margins are compile-time constants.

## Self-check

- The A1 statistic reuses the one barrier source (`Coherence.coherence_link`);
  no second phi. A3 is the literal prereg formula. Weights/floors/margins
  match the prereg tables (0.90 / +0.10 / 0.90; k=3).
- C4 takes precedence: >1 held-out `locus_sparse` → NO-DECISION even if an
  A/B check would otherwise miss — matching "the seam did not have enough
  surface to be tested." (Surfaced below as a judgment call.)
- A2 with an **absent** baseline is a miss, not a free pass — improvement
  cannot be claimed without a recorded baseline (conservative).
- Refusal is "refuse, don't skip": a malformed/incomplete sample counts
  against A0 yield in the per-target record.
- The verdict is never hardcoded or stubbed; the gate reads only measured
  per-target records + measured B-flags.

## Local build verification — IMPOSSIBLE in this container

There is **no OCaml toolchain** here (`dune`/`opam`/`ocaml` absent) and
**no witness credential**, so I could **not** run `dune build` /
`dune runtest` or exercise the witness locally. Code was written to the
existing module/test conventions (interfaces kept exact, exhaustive
matches, no unused bindings, distinct record-field prefixes). **Build +
unit-test verification is deferred to the CI oracle** (`ci.yml` →
`dune build && dune runtest` on OCaml 5.2; `cdd-artifact-validate`); the
**measurement RUN + terminal verdict are the credentialed CI witness's
job** (`factorized-beta-measure.yml`). If CI surfaces a compile error it
is a mechanical fix within this cell, not a contract change.

## Debt / unpinned rows surfaced to δ

1. **β consistency field vs vector.** The prereg says the barrier runs
   over "the β field's max-pairwise spread (`Witness_numeric.per_field_spread`
   → `max_pairwise` → `Coherence`)". `Witness_numeric` is the 7-field
   scalar vector; there is no β-scalar-only entry point. I compute the
   identical max-pairwise spread over the `β_factorized` scalars directly
   and route it through `Coherence.coherence_link` (same λ=1, same
   formula) rather than threading a 1-field vector through
   `Witness_numeric`. Numerically identical; flagged in case δ wants the
   literal `Witness_numeric` call site.
2. **Free-witness β baseline definition (A2 / B4).** "free-witness β
   baseline `B_β`" is taken as the **β-field** max-pairwise
   `Coh_consistency` of the same-tree scalar witness (k=3), i.e.
   `coh_from_delta(fields.beta.spread)` from `cm-consistency.sh llm-spread`
   — not the overall (max-over-all-fields) consistency. This is the
   β-only reading A2 needs; confirm δ agrees it is β-field, not composite.
3. **C4 precedence over an A/B miss.** When >1 held-out target is
   `locus_sparse` I return NO-DECISION unconditionally (prereg C4 text is
   unconditional). If δ intends a hard B1/B2/B3 regression to FAIL even
   under the sparsity guard, reorder the two clauses in `evaluate_gate`.
4. **B3 label-agreement run shape.** The prereg fixes the thresholds
   (n<20 all hard; n≥20 ≥95%; negatives cite both sides) but not the run
   arity. I run the 7 llm-called controls through **one** witness pass
   (n=7<20 → every control must match). If δ wants k-repeated control
   adjudication (a consistency reading on the controls too), the
   `b3-controls` job loops like `measure`.
5. **A2 baseline granularity for B4.** I record `baseline_beta_coh` (A2)
   but not a free-witness β **medoid point value** for the B4 proximity
   observation (0.10 tolerance). B4 is observation-only (not a
   pass/fail), so the gate does not consume it; if δ wants the B4 residual
   in the summary, the measure script must also emit `fields.beta.values`
   median alongside the spread.

None of these block the measurement; each is a bounded, reversible choice.

## Review-readiness

Harness + gate core + CLI wiring + tests + CI workflow + closeout are
complete on `cycle/75` and pushed. Signalling **review-ready** to β. Not
merged (β merges). The k=3 factorized-β measurement over the five held-out
targets and the terminal A/B/C verdict run in the credentialed CI witness
(`factorized-beta-measure.yml`); κ-as-γ records the verdict in the prereg
experiment-record + the CHANGELOG witness index once the run lands.
