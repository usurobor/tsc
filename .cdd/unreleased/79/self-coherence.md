# Self-coherence — Sub-2 (#79): prereg as a first-class compile object

Cell: α (implementation), single-session δ-as-γ under `.cdd/DISPATCH` §5.2.
Master: #77 (CM0-compiler wave). Sub: #79.
γ-axis capped at **A−** per §5.2 dispatch (`release/SKILL.md` §3.8,
configuration-floor clause) — expected, not a defect.

## What Sub-2 builds

A prereg is a **typed β contract**, not experiment notes: "for THIS axis,
using THIS evidence and THIS factorization, this experiment counts as
success/failure." If a prereg cannot be expressed in `schemas/prereg.cue`
it is not yet executable — that is the point of the schema. No compiler
(Sub-3/#80); no re-run of the factorized-β experiment (typed here only as a
fixture, its FAIL unchanged); no meter-consistency reopen; no v3.2.5.

## AC → evidence

| AC | Requirement | Evidence |
|----|-------------|----------|
| 1 | `schemas/prereg.cue` types a prereg as a compile object with all named fields | `schemas/prereg.cue` — `#Prereg` def: `id`, `title`, `axis` (enum), `status` (proposed\|approved\|executed\|failed\|passed\|no_decision), `human_intent{claim, why_it_matters}`, `hypothesis{variance_source, intervention}`, `factorization{inventory_owner, judgment_owner, aggregation_owner, loci[]}`, `judgment_contract{allowed_labels, evidence_required, refusal}`, `aggregation{formula, label_weights, kind_weights}`, `consistency_gate{samples, agreement_floor, standing_effect}`, `discrimination_gate{controls}`, `no_decision{condition, consequence}`, `success{all_of}`, `failure{any_of}`, `post_result_rule{on_failure, on_success, forbidden}` |
| 1 | Enforce `allowed_labels` == keys of `label_weights` | `#Prereg` structural gate 1: forward loop requires a weight for every allowed label (concreteness); reverse `_extra_labels` comprehension + `list.Contains` unified with `[]` rejects any extra weight key. Both directions proven by the `labels-not-weights` fixture (fails: `_extra_labels: incompatible list lengths (0 and 1)`) |
| 1 | The three factorization owners must be declared | `factorization.{inventory_owner,judgment_owner,aggregation_owner}: !=""` (required, non-empty). Proven by `factorization-owners-undeclared` fixture |
| 2 | valid + invalid fixtures; invalids cover the 7 named reasons | `fixtures/preregs/valid/*.yaml` (2) and `fixtures/preregs/invalid/*.yaml` (7); each invalid fails for its named reason (matrix below) |
| 3 | Type the factorized-β prereg (rev-4) as a valid `failed` fixture | `fixtures/preregs/valid/factorized-beta.yaml` — `status: failed`, `post_result_rule.on_failure: record_failed_experiment`, three loci kinds `citation_bears_claim`/`authority_claim`/`target_file_fit`, label weights `supports 0.0 / insufficient 0.5 / contradicts 1.0`, kind weights `citation 1.0 / authority 1.0 / target_file_fit 0.5`. Vets PASS |

## cue-vet matrix

Ran with `cue` **v0.17.0** (installed locally via `go install
cuelang.org/go/cmd/cue@latest`; CI pins v0.13.2 — the constructs used
(`list.Contains`, field-emitting comprehensions, disjunction enums,
`!=""`/bound constraints) are stable and available in both). Command:
`cue vet -d '#Prereg' schemas/prereg.cue <fixture>`.

### valid (expect PASS)

| fixture | result |
|---------|--------|
| `valid/factorized-beta.yaml` | **PASS** |
| `valid/minimal-proposed.yaml` | **PASS** |

### invalid (expect FAIL, each for its named reason)

| fixture | named reason | cue error (head) |
|---------|--------------|------------------|
| `invalid/axis-not-declared.yaml` | axis not declared | `axis: incomplete value "alpha" \| "beta" \| "gamma"` |
| `invalid/evidence-absent.yaml` | judgment evidence requirement absent | `judgment_contract.evidence_required: invalid value "" (out of bound !="")` |
| `invalid/factorization-owners-undeclared.yaml` | factorization owners undeclared | `factorization.aggregation_owner / judgment_owner: incomplete value !=""` |
| `invalid/labels-not-weights.yaml` | labels ≠ weight keys | `_extra_labels: incompatible list lengths (0 and 1)` |
| `invalid/gate-not-executable.yaml` | gate has no numeric threshold | `consistency_gate.agreement_floor: incomplete value >=0 & <=1 & float` |
| `invalid/failure-consequence-missing.yaml` | failure / no-decision consequence missing | `no_decision.consequence` + `post_result_rule.on_failure: incomplete value !=""` |
| `invalid/standing-effect-absent.yaml` | consistency-gate standing_effect absent | `consistency_gate.standing_effect: invalid value "" (out of bound !="")` |

All 2 valid PASS, all 7 invalid FAIL for their named reason. No unexpected
passes, no misfires.

## Factorized-β prereg round-trip

The rev-4 prereg (`docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md`,
terminal FAIL) was typed into `fixtures/preregs/valid/factorized-beta.yaml`
and vets **PASS** against `#Prereg`. The round-trip carries the real
executed contract faithfully: the factorization owners (engine / llm /
engine), the three deterministic locus enumerators, the bounded three-label
judgment contract with mandatory both-sided evidence on the negative
verdict, the aggregation formula and its label/kind weights, the A0–A3 /
B1–B3 success conjunction and failure disjunction, the C4 NO-DECISION guard,
and the terminal `status: failed` with `on_failure: record_failed_experiment`
and the `forbidden` list (no re-run, no re-tweak, no v3.2.5, no meter-loop
reset). The FAIL is unchanged; the experiment was not re-run. This confirms
the schema is expressive enough for a genuine, already-adjudicated prereg
including its terminal verdict — the PINNED CONSTRAINT holds.

## Known gaps

1. **No CI wiring.** No workflow vets `fixtures/preregs/**` against
   `schemas/prereg.cue` yet. CI's `skill-validate` job sets up CUE but only
   validates SKILL.md frontmatter via `scripts/ci/validate-skill-frontmatter.sh`.
   Wiring a prereg-vet job (and/or a `.expect`-style negative harness like
   the skill-frontmatter fixtures) is downstream — the compiler is Sub-3/#80.
   Local matrix above stands as the self-check.
2. **CUE version skew.** Validated on v0.17.0 locally; CI pins v0.13.2. The
   constructs used are stable across the range, but this was not exercised
   on v0.13.2 in this cell.
3. **Label-match forward direction is proven jointly, not in isolation.**
   The `labels-not-weights` fixture has both an extra weight and a missing
   weight; cue reports the reverse (`_extra_labels`) failure first. Both
   halves of the bidirectional gate are in the schema and each is exercised
   by the shared fixture; a forward-only fixture was not added.
4. **Locus `kind` is generic (`!=""`).** `#Prereg` does not restrict locus
   kinds to the β allowed set, since a prereg for another axis would carry
   different kinds; the β-specific kind enum lives in the fixture, not the
   schema.

## Configuration note

γ-axis capped at **A−** per §5.2 dispatch (single-session δ-as-γ;
`release/SKILL.md` §3.8 configuration-floor clause). γ/δ separation is
structurally absent in this cell — expected, recorded here for the
gamma-closeout to carry forward.
