# α close-out — cycle/74 (factorized-β implementation)

Role: α (implement). Branch: `cycle/74` (off `origin/main`). Identity:
`alpha@tsc.cdd.cnos`. Authority: FROZEN rev-4 prereg + frozen B3 fixture +
issue #74 (AC1–AC10). Never merged by α — β merges.

## Deliverables (all on `cycle/74`)

| Deliverable | File |
|---|---|
| β locus types, three enumerators, inventory, aggregation, response validation, prompt surface, B3 typed-gate | `engine/ocaml/lib/factorized_beta.ml` |
| Public interface | `engine/ocaml/lib/factorized_beta.mli` |
| Exposed deterministic β anchors (visibility only) | `engine/ocaml/lib/mechanical_scoring.mli` |
| Library wiring | `engine/ocaml/lib/dune` |
| Stable-locus-id regression + aggregation/validation/B3 tests | `engine/ocaml/test/test_factorized_beta.ml` |
| Test wiring | `engine/ocaml/test/dune` |
| α self-coherence | `.cdd/unreleased/74/self-coherence.md` |
| α close-out | `.cdd/unreleased/74/alpha-closeout.md` |

The frozen prereg and fixture were **not** edited. The fixture is valid
JSON (`jq -e .` clean) — no pre-run syntax fix was needed. The α/γ scalar
path is untouched; `Coherence.phi` is reused, not re-implemented.

## AC status

| AC | Status | Note |
|---|---|---|
| AC1 exactly three kinds | ✅ done | enforced by the `kind` type; asserted in test |
| AC2 pre-witness inventory + fields | ✅ done | `inventory` + `inventory_to_json`; artifact *upload* is CI's |
| AC3 stable locus ids | ✅ done | `test_stable_locus_ids` (idempotent + exact sequence) |
| AC4 refuse missing/duplicate | ✅ done | `validate_sample`; tests for missing/dup/extraneous |
| AC5 unresolved d=1.0, no LLM | ✅ done | tested on the bundle and in aggregation |
| AC6 aggregation exact | ✅ done | `compute_beta`; formula/sparsity/degenerate tests |
| AC7 B3 gate | ◐ partial | typed-fixture gate done + tested; label-agreement → CI witness |
| AC8 A/B/C incl. NO-DECISION | ⏳ deferred-to-CI | measurement (baseline, k=3, NO-DECISION) runs in the credentialed CI witness |
| AC9 admissibility matrix | ⏳ deferred-to-CI | no admissibility surface changed; CI confirms exit 0 |
| AC10 PASS/FAIL/NO-DECISION close-out | ⏳ deferred-to-γ | written post-measurement by κ-as-γ per the scaffold |

Blocked: none. The deferred ACs are structurally downstream (they need an
LLM/baseline/credentialed witness that is explicitly not α's job).

## Build/test verification

**Not runnable locally** — no OCaml toolchain in this container. Code
written to the existing module/test conventions (exact interfaces, no dead
bindings, exhaustive matches). Verification is deferred to the CI oracle
(`ci.yml`: `dune build && dune runtest` on OCaml 5.2; `cdd-artifact-validate`).

## Unpinned rows surfaced to δ

Recorded in `self-coherence.md` → "Debt / unpinned rows surfaced to δ":
(1) `locus_id` ordinal base/width (chose global 1-based, 4-digit);
(2) broken non-`.md` links enumerated as unresolved (faithful to literal
text + `cross_reference_consistency`); (3) first-inline-link choice for
`authority_claim`; (4) evidence-side incompleteness treated as a sample
refusal. All bounded and reversible.

## Handoff

Signalled **review-ready** to β. β reviews the committed diff against
AC1–AC10, writes `beta-review.md`, and on APPROVE merges to main. γ
(κ-as-γ) writes the PASS/FAIL/NO-DECISION verdict once the CI measurement
lands.

HEAD SHA on `cycle/74`: recorded in the return message to κ (the pushed
commit is the canonical record).
