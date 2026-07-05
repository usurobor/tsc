# α self-coherence — cycle/74 (factorized-β implementation)

Role: α (implementer). Authority: FROZEN
`docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md` (rev 4) +
`docs/beta/governance/fixtures/factorized-beta-controls.json` + issue #74
(AC1–AC10). Identity: `alpha@tsc.cdd.cnos`.

## Gap addressed

The witness β task still let the LLM (a) choose an unbounded locus set,
(b) choose how many defects each observation counts as, and (c) map that
private set to a scalar in its head. This cell cuts the freedom seam: the
engine now enumerates a deterministic β locus inventory, the LLM
adjudicates each *resolved* locus with a bounded three-label verdict (and
never emits a scalar), and the engine aggregates the verdicts into
`β_factorized` by the pre-registered formula.

## What was implemented

- **`engine/ocaml/lib/factorized_beta.ml` (+ `.mli`)** — the whole pure
  core:
  - locus / verdict / status types; exactly the three allowed kinds
    (`citation_bears_claim`, `authority_claim`, `target_file_fit`), no
    `repeated_fact`, no γ/version kind;
  - the three deterministic enumerators, each built on the *exact*
    mechanical anchors the scalar β signals use
    (`Mechanical_scoring.extract_md_links`, `normalize_link`,
    `link_resolves`, `doc_slug_map`, `slugify`);
  - `inventory` — canonical order (bundle file order → source line → kind
    order → column), `locus_id = beta.<short>.<ordinal:04d>` assigned by
    that order; `mechanical_status` two-valued;
  - `compute_beta` / `beta_of_verdicts` — `β = 1 − Σ(w·d)/Σ(w)` clamped
    to [0,1], `supports→0.0 insufficient→0.5 contradicts→1.0
    unresolved→1.0(no LLM)`, kind weights `1.0/1.0/0.5`, `N=0→β=1.0`,
    `locus_sparse ⇔ E<5` on the LLM-eligible (resolved) count;
  - locus-response schema (`parse_locus_response(s)`) + `validate_sample`
    (exactly one response per resolved `locus_id`; missing / duplicate /
    extraneous / evidence-incomplete → the sample is refused);
  - JSON serializers: the pre-witness inventory artifact
    (`inventory_to_json`, AC2 fields) and `aggregate_to_json`;
  - the bounded per-locus adjudication prompt surface
    (`adjudication_instruction`, `locus_prompt_block`);
  - the B3 typed-fixture gate (`parse_controls`, `typed_rule_errors`,
    `validate_controls`).
- **`engine/ocaml/lib/mechanical_scoring.mli`** — widened to expose the
  six deterministic β anchors (no behaviour change to the scalar path;
  visibility only), so the locus set cannot diverge from the signal it
  anchors.
- **`engine/ocaml/lib/dune`** — added `factorized_beta` to the library.
- **`engine/ocaml/test/test_factorized_beta.ml` (+ dune)** — the
  stable-locus-id regression test and the aggregation / sparsity /
  degenerate / response-validation / B3-typed-gate tests.

The `Coherence.phi` barrier is reused via the existing `Consistency`
report over the β field; it is NOT re-implemented here. The α/γ scalar
path (`Prompt`, `Report`, `Response_schema`, `main.ml`) is untouched.

## ACs addressed

- **AC1** — exactly the three allowed kinds; enforced by the type
  (`kind` has three constructors) and asserted in the inventory test.
- **AC2** — deterministic pre-witness inventory + `inventory_to_json`
  carrying `target, locus_id, kind, source_path, source_span,
  target_path, target_span, mechanical_status, llm_called`; written
  before any LLM call (pure function). Artifact *upload* is the CI
  witness's job.
- **AC3** — `test_stable_locus_ids`: same bundle → identical inventory +
  ids (idempotent) and the exact canonical sequence.
- **AC4** — `validate_sample` refuses missing / duplicate / extraneous
  responses; tests cover each.
- **AC5** — unresolved loci carry `d=1.0` with `llm_called=false`; tested
  on the enumerated bundle and in aggregation.
- **AC6** — `compute_beta` implements the formula exactly; tests cover
  supports / insufficient / contradicts / unresolved, kind weights,
  `E<5` sparsity, and `N=0→β=1.0`.
- **AC7 (checkable half)** — `validate_controls` typed-fixture gate;
  `test_b3_fixture_typed_gate` loads the committed fixture and asserts all
  8 controls are well-typed. `jq -e .` on the fixture is clean (verified;
  no syntax fix needed). The label-agreement half needs a witness run →
  deferred to CI.
- **AC8** — the A/B/C gate *evaluation* is the credentialed CI witness's
  measurement (baseline, k=3, NO-DECISION). This cell supplies the
  deterministic inventory + aggregation + validation the gate consumes;
  the gate arithmetic itself is not run here (no LLM, no baseline).
  **Deferred-to-CI.**
- **AC9** — `scripts/cm-admissibility.sh --self-test` untouched (no
  admissibility surface changed). **Deferred-to-CI** to confirm exit 0.
- **AC10** — the PASS / FAIL / NO-DECISION close-out is written after the
  CI measurement (κ-as-γ per the scaffold); α records only the
  implementation close-out. **Deferred-to-CI/γ.**

## Self-check

- Enumerators use only surfaces the engine already computes; no invented
  locus surface. The three kinds are exhaustive by construction.
- Aggregation, sparsity, and degenerate rules match the prereg tables
  line-for-line; unit tests pin the numbers.
- Response validation follows "refuse, don't skip"; a refused sample is a
  recorded fact that counts against A0 yield.
- The LLM emits no scalar; the engine computes β.

## Local build verification — IMPOSSIBLE in this container

There is **no OCaml toolchain** here (`dune`/`opam`/`ocaml` absent), so I
could **not** run `dune build` / `dune runtest` locally. The code was
written to match the existing module + test style (interfaces kept exact,
no dead bindings, exhaustive matches). **Build/test verification is
deferred to the CI oracle** (`ci.yml` → `dune build && dune runtest` on
OCaml 5.2; `cdd-artifact-validate`). If CI surfaces a compile error, it is
a mechanical fix within this cell, not a contract change.

## Debt / unpinned rows surfaced to δ

1. **`locus_id` ordinal base/width.** The prereg fixes the shape
   (`beta.<kind short>.<zero-padded ordinal>`, example `beta.link.0007`)
   but not the base or pad width. I chose a **single global 1-based
   counter, 4 digits** in canonical emission order. Stable and
   reproducible; if δ wants per-kind or 0-based ordinals, it is a
   one-line change to `inventory`.
2. **Broken non-`.md` links.** The prereg excludes links that *resolve
   to* a non-document (existing directory / existing non-`.md` file) but
   scores `unresolved` when "path or anchor does not resolve." A broken
   link with a non-`.md` extension (e.g. `[x](img/logo.png)` where the
   file is absent) resolves to *nothing*, not to a non-document, so I
   enumerate it as an **unresolved** locus (d=1.0, no LLM) — faithful to
   the literal text and to `cross_reference_consistency`, which counts
   every internal link. Flagged in case δ intended such links dropped.
3. **First-link choice for `authority_claim`.** When a self-claim line
   carries more than one inline document link, I take the **first**
   (left-to-right) non-`(resolved non-document)` link as the adjudicated
   surface. The prereg says "an inline link … in the same sentence" but
   does not disambiguate multiplicity.
4. **Evidence-side enforcement in `validate_sample`.** I treat a
   `contradicts` verdict lacking both source and target evidence as a
   sample **refusal** (malformed response), consistent with B3's "every
   negative verdict cites both source and target" and "refuse, don't
   skip." If δ wants this as a non-refusing observation instead, move the
   `Incomplete_evidence` branch out of `validate_sample`.

None of these block the measurement; each is a bounded, reversible
choice.

## Review-readiness

Implementation + tests + inventory/aggregation/validation are complete on
`cycle/74` and pushed. Signalling **review-ready** to β. Not merged (β
merges). The k=3 factorized-β measurement and the A/B/C verdict run in the
credentialed CI witness downstream.
