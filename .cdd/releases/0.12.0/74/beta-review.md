# β review — cycle/74 (factorized-β engine)

Role: β (reviewer). Identity: `beta@tsc.cdd.cnos`. Authority: FROZEN
`docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md` (rev 4) +
`docs/beta/governance/fixtures/factorized-beta-controls.json` + issue #74
(AC1–AC10). Reviewed SHA: `1376022132a2fe67743699f19c5b3541ad772e48`
(`cycle/74` HEAD). **β does NOT merge this round — κ/δ holds the merge
decision.**

## Verdict: APPROVE

The implementation matches the frozen prereg exactly on every load-bearing
axis. Recursive-coherence check passes with no mismatches. AC1–AC7 are
satisfied (AC7 in its checkable half); AC8/AC9/AC10 are correctly and
explicitly deferred — α did not silently claim them. CI is green on the
HEAD SHA. The four unpinned rows are each bounded, reversible, and
faithful to the prereg text; none is a defect.

## Recursive-coherence result — PASS

Verified line-for-line against the frozen prereg. Each row: prereg
authority ↔ code site.

| Prereg requirement | Code site | Match |
|---|---|---|
| Three allowed kinds only; **no `repeated_fact`, no γ/version kind** (§"β locus schema", F1) | `factorized_beta.ml:31-34` `type kind = Citation_bears_claim \| Authority_claim \| Target_file_fit` (exhaustive; three constructors) | ✅ |
| Enumerators built on the **real mechanical anchors** (§"β locus enumerators") | `extract_md_links` / `is_internal_link` / `normalize_link` / `link_resolves` / `doc_slug_map` / `slugify` all reused from `Mechanical_scoring` (ll. 173, 288, 305-307, 345-348, 401); no invented surface | ✅ |
| `mechanical_status` **two-valued** (§"β locus schema") | `ml:38-40` `Resolved \| Unresolved`; non-document links excluded upstream (`resolves_to_non_document`, ll. 173-179, 303) | ✅ |
| Aggregation `β = 1 − Σ(w·d)/Σ(w)`, clamped [0,1], over **all** N(T) (§"Aggregation formula") | `ml:458-468` fold over all loci; `1.0 -. swd /. sw` via `clamp01` | ✅ |
| Defect weights `supports 0.0 / insufficient 0.5 / contradicts 1.0` | `defect_weight_of_verdict` `ml:110-113` | ✅ |
| `unresolved → d=1.0, no LLM call` | `ml:462-464` (`Unresolved -> 1.0`, verdict never consulted); `llm_called = (status=Resolved)` `ml:636` | ✅ |
| Kind weights `citation 1.0 / authority 1.0 / target_file_fit 0.5` | `kind_weight` `ml:89-92` | ✅ |
| `N(T)=0 → β=1.0` | `ml:454-456` | ✅ |
| `locus_sparse ⇔ E(T)<5` **on the resolved (LLM-eligible) count** | `eligible_count` filters `Resolved` (`ml:430-431`); `locus_sparse = eligible < 5` (`ml:470`) | ✅ |
| Response validation **refuses missing / duplicate** (exactly one per resolved id) | `validate_sample` `ml:591-621`; `Missing_response` / `Duplicate_response` / `Extraneous_response` | ✅ |

Denominator correctly ranges over all loci including unresolved (prereg
"unresolved included, as real β defects"); sparsity is correctly on E,
not N (prereg's explicit anti-hollow-pass rule). The `beta.<short>.<04d>`
id and canonical order (bundle file → source line → kind rank → column)
are pinned and proven idempotent by `test_stable_locus_ids`, whose
expected 7-locus sequence I hand-traced against the enumerators and
confirmed exact.

## Per-AC assessment

| AC | β assessment | Basis |
|---|---|---|
| AC1 exactly three kinds | **done** | enforced by the `kind` type; asserted in `test_stable_locus_ids` |
| AC2 pre-witness inventory + fields | **done** | `inventory` + `inventory_to_json` carry all 9 fields (target, locus_id, kind, source_path, source_span, target_path, target_span, mechanical_status, llm_called); pure fn ⇒ pre-witness. Artifact *upload* is legitimately CI's |
| AC3 stable locus ids | **done** | `test_stable_locus_ids` (idempotent + exact canonical sequence) |
| AC4 refuse missing/duplicate | **done** | `validate_sample`; tests cover missing / dup / extraneous / evidence-incomplete |
| AC5 unresolved d=1.0, no LLM | **done** | aggregation branch + `llm_called=false` serialization; tested on bundle |
| AC6 aggregation exact | **done** | `compute_beta`; formula / kind-weight / sparsity / N=0 tests all pin numbers |
| AC7 B3 gate | **done (checkable half)** | `validate_controls` typed gate; `test_b3_fixture_typed_gate` loads the committed fixture (8 controls) and asserts well-typed; `jq -e .` clean. Label-agreement half needs a witness run — correctly deferred |
| AC8 A/B/C incl. NO-DECISION | **deferred-correctly** | gate *measurement* (baseline, k=3, NO-DECISION) is the credentialed CI witness's; marked ⏳, not claimed |
| AC9 admissibility matrix | **deferred-correctly** | no admissibility surface touched; CI confirms exit 0; marked ⏳, not claimed |
| AC10 PASS/FAIL/NO-DECISION close-out | **deferred-correctly** | written post-measurement by γ (κ-as-γ); marked ⏳, not claimed |

α did **not** silently claim AC8/AC9/AC10 — each is explicitly marked
deferred in both `self-coherence.md` and `alpha-closeout.md`, consistent
with the split that credentialed measurement is downstream of this cell.

## Position on the four unpinned rows

1. **`locus_id` ordinal base/width (global 1-based, 4-digit).**
   **Acceptable / reversible.** The prereg fixes only the shape
   (`beta.<short>.<zero-padded ordinal>`, example `beta.link.0007`); a
   4-digit global counter matches the example width. Deterministic and
   proven stable by test. A one-line change if δ later wants per-kind
   ordinals. **Not a defect.**
2. **Broken non-`.md` links enumerated as `unresolved`.**
   **Acceptable — the correct literal reading.** The prereg's exclusion
   is specifically for links that *resolve to* an existing
   directory/non-`.md` file (they have no readable `target_span`). A
   broken `img/logo.png` resolves to *nothing*, so it is not a
   non-document resolution; it is a plain broken reference, which
   `cross_reference_consistency` counts. Scoring it `unresolved` (d=1.0,
   no LLM, not counted toward E) can only *lower* β as a real β defect —
   the correct direction. `resolves_to_non_document` (`ml:173-179`)
   implements exactly this distinction. **Not a defect.**
3. **First inline link for `authority_claim` multiplicity.**
   **Acceptable / reversible.** The prereg says "an inline link … in the
   same sentence" without disambiguating multiplicity; taking the first
   left-to-right non-(resolved-non-document) link (`ml:337-344`) is
   deterministic. The line-vs-sentence granularity is explicitly
   permitted by the prereg's own "the sentence (or line)" phrasing.
   **Not a defect.**
4. **Evidence-side incompleteness → sample refusal.**
   **Acceptable / reversible.** Treating a `contradicts` verdict lacking
   both source+target evidence as a refusal (`Incomplete_evidence`,
   `ml:606-609`) is faithful to B3 ("every negative verdict cites both
   source and target") and to "refuse, don't skip." The adjudication
   prompt (`adjudication_instruction`) explicitly instructs the
   `{source,target}` evidence object and the both-sides rule, so the
   witness is warned. Reversible by moving the branch out of
   `validate_sample` if δ later wants it as a non-refusing observation.
   **Not a defect.**

All four are bounded, reversible engineering choices that do not alter the
frozen contract or the measurement.

## Code quality

- **.mli ↔ .ml consistent.** `inventory : Bundle.file list` in the `.mli`
  resolves to `Types.bundle_file` (`Bundle.file = bundle_file` alias in
  `bundle.ml`), the type the `.ml` consumes — no mismatch. All exposed
  symbols are defined and used.
- **Exhaustive matches; no wildcard hiding.** `kind`, `mechanical_status`,
  `verdict` are matched exhaustively throughout (aggregation, validation,
  serialization). No dead bindings.
- **Pure core stays pure.** `factorized_beta.ml` has no I/O / network /
  LLM call (file I/O lives only in the test's fixture loader).
- **`Coherence.phi` reused, not re-implemented** — the cross-sample
  barrier stays the existing `Consistency`/`Coherence` path; this module
  does not touch it.
- **α/γ scalar path untouched.** The only change outside the new module is
  `mechanical_scoring.mli` widening visibility of six already-computed
  anchors (no `.ml` behaviour change); `dune` wiring; tests.
- **Minor note (not blocking):** `beta_of_verdicts` (`ml:476-481`) falls
  back to `Supports` (d=0, most lenient) for a `locus_id` absent from the
  verdict assoc. The comment marks it unreachable after `validate_sample`,
  which is correct given the contract that it is fed only validated
  output. Flagged only as a latent lenient default; not a defect.

## CI status — GREEN

On `cycle/74` HEAD `1376022`:
- `ci` (dune build + runtest, OCaml 5.2) = **completed / success** ✅
- `CDD Artifact Validate` = **completed / success** ✅
- `tsc-self-measure` = in_progress — the **old scalar witness**; its
  consistency-variance is expected and is **not** a build break (per the
  review contract).

The prior commit `dc739bd` had `ci` = failure (an ambiguous-docstring
warning-50); HEAD `1376022` fixes it and turns `ci` green. Since neither
reviewer nor implementer has a local OCaml toolchain, the green build is
the compile-correctness oracle — it confirms the diff builds and every
`test_factorized_beta` assertion passes.

## Bottom line

**APPROVE.** Recursive coherence PASS with zero mismatches; AC1–AC7 done
(AC7 checkable half), AC8–AC10 correctly deferred; CI green; four unpinned
rows all acceptable and reversible. No changes requested. Merge decision
belongs to κ/δ this round; the credentialed CI witness measurement and the
γ PASS/FAIL/NO-DECISION close-out remain downstream.
