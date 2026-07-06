# β-review — Sub-2 (#79): prereg as a first-class typed compile object

**Reviewer:** independent β (review) cell, CDD wave CM0 (master #77), `.cdd/DISPATCH` §5.2.
**Branch reviewed:** `cycle/79` @ `d74d23e` against `origin/main`.
**Independence:** produced by a *different* α cell; reviewed adversarially (re-ran the
full cue-vet matrix and added isolation probes the shipped fixtures do not exercise).
**γ-axis capped at A− per §5.2** (single-session δ-as-γ; `release/SKILL.md` §3.8
configuration-floor). Recorded, not scored as a defect.

## Verdict: **APPROVE**

The pinned constraint holds. All three ACs pass. No blocking findings.

---

## Pinned constraint — "preregs are typed β contracts, not experiment notes"

**HOLDS.** `#Prereg` types every field named in the pinned constraint:
`id`, `title`, `axis`, `status`, `human_intent{claim, why_it_matters}`,
`hypothesis{variance_source, intervention}`,
`factorization{inventory_owner, judgment_owner, aggregation_owner, loci[#Locus]}`,
`judgment_contract{allowed_labels, evidence_required, refusal}`,
`aggregation{formula, label_weights, kind_weights}`,
`consistency_gate{samples, agreement_floor, standing_effect}`,
`discrimination_gate{controls}`, `no_decision{condition, consequence}`,
`success{all_of}`, `failure{any_of}`, `post_result_rule{on_failure, on_success, forbidden}`.
`#Locus` types `kind/enumerator/source_span/target_span`.

A prereg missing required structure is genuinely inexpressible: every required field
carries a `!=""` / bound / enum / min-length constraint, so absence yields an
`incomplete value` vet error. **The schema's openness (`...`) does not create a hole:**
a *typo'd* required key (`agregation_owner`) still fails because the real
`aggregation_owner` constraint stays unsatisfied (probe H below).

## AC → pass/miss

| AC | Requirement | Result |
|----|-------------|--------|
| AC1 | `schemas/prereg.cue` types the full prereg object | **PASS** |
| AC1 | `allowed_labels == label_weights` keys enforced **both directions** | **PASS** — proven in isolation (probes A + B) |
| AC1 | three factorization owners required | **PASS** |
| AC2 | valid + invalid fixtures; each invalid fails for its named reason | **PASS** — 2 valid clean, 7 invalid fail correctly |
| AC3 | factorized-β (rev-4) types as a valid `failed` fixture, round-trips | **PASS** — faithful to source, FAIL unchanged |

## cue-vet matrix (independently reproduced)

Ran with `cue v0.17.0` (installed locally via `go install cuelang.org/go/cmd/cue@latest`).
Command: `cue vet -d '#Prereg' schemas/prereg.cue <fixture>`. Results match the α cell's
self-coherence record exactly.

### valid (expect PASS)

| fixture | result |
|---------|--------|
| `valid/factorized-beta.yaml` | **PASS** |
| `valid/minimal-proposed.yaml` | **PASS** |

### invalid (expect FAIL for the named reason)

| fixture | named reason | cue error (head) |
|---------|--------------|------------------|
| `invalid/axis-not-declared.yaml` | axis not declared | `axis: incomplete value "alpha" \| "beta" \| "gamma"` |
| `invalid/evidence-absent.yaml` | evidence requirement absent | `judgment_contract.evidence_required: invalid value "" (out of bound !="")` |
| `invalid/factorization-owners-undeclared.yaml` | owners undeclared | `factorization.aggregation_owner / judgment_owner: incomplete value !=""` |
| `invalid/labels-not-weights.yaml` | labels ≠ weight keys | `_extra_labels: incompatible list lengths (0 and 1)` |
| `invalid/gate-not-executable.yaml` | gate has no numeric threshold | `consistency_gate.agreement_floor: incomplete value >=0 & <=1 & float` |
| `invalid/failure-consequence-missing.yaml` | failure/no-decision consequence missing | `no_decision.consequence` + `post_result_rule.on_failure: incomplete value !=""` |
| `invalid/standing-effect-absent.yaml` | standing_effect absent | `consistency_gate.standing_effect: invalid value "" (out of bound !="")` |

All 7 invalid fixtures are otherwise well-formed, so each fails **only** for its named
defect — the oracle is not contaminated by incidental errors.

### Adversarial isolation probes (β-added — not in the shipped fixture set)

The shipped `labels-not-weights` fixture triggers *both* halves of the bidirectional
label gate at once (α disclosed this as known-gap #3). I closed that gap by testing each
direction alone, plus other gates the fixtures do not exercise:

| probe | expectation | result |
|-------|-------------|--------|
| A: extra weight key only (forward-complete) | reverse gate fails | **FAIL** `_extra_labels: incompatible list lengths (0 and 1)` ✓ |
| B: extra allowed_label, no weight (reverse-complete) | forward gate fails | **FAIL** `aggregation.label_weights.maybe: incomplete value number` ✓ |
| C: uppercase `id` | pattern gate fails | **FAIL** `id: out of bound =~"^[a-z][a-z0-9-]*$"` ✓ |
| D: `samples: 1` | `>=2` fails | **FAIL** `samples: out of bound >=2` ✓ |
| E: empty `success.all_of` | `[_, ...]` fails | **FAIL** `incompatible list lengths (0 and 1)` ✓ |
| G: omit `on_success` | required | **FAIL** `post_result_rule.on_success: incomplete value !=""` ✓ |
| H: typo `aggregation_owner` | openness must not hide | **FAIL** (real key still unsatisfied) ✓ |
| I: locus missing `target_span` | loci fully typed | **FAIL** `factorization.loci.0.target_span: incomplete value !=""` ✓ |
| J: `status: retired` | enum fails | **FAIL** `conflicting values` ✓ |

**Both directions of the label/weight gate are proven independently.** ✓

## Factorized-β round-trip (checklist #5)

`valid/factorized-beta.yaml` vets **PASS** and faithfully carries the rev-4 prereg
(`docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md`), spot-checked against the
source doc:

- `status: failed`; `post_result_rule.on_failure: record_failed_experiment` — round-trip confirmed.
- owners `engine / llm / engine`.
- three loci kinds `citation_bears_claim` / `authority_claim` / `target_file_fit` — match source.
- label weights `supports 0.0 / insufficient 0.5 / contradicts 1.0` — match source.
- kind weights `citation 1.0 / authority 1.0 / target_file_fit 0.5` — match source.
- `agreement_floor 0.90`, A0–A3/B1–B3 success conjunction, NO-DECISION guard, and the
  `forbidden` list (no re-run, no re-tweak, no v3.2.5, no meter-loop reset).

**The FAIL is unchanged; the experiment is typed as a static fixture and is NOT re-run.** ✓

## Non-goals (checklist #6)

Diff (`origin/main...d74d23e`) adds **only** `schemas/prereg.cue`, the 9 fixtures, and
`.cdd/unreleased/79/self-coherence.md` — 11 files, 929 insertions, 0 deletions. No
`coh cm-compile` (Sub-3), no engine/meter change, no v3.2.5, no re-run of factorized-β.
**All non-goals honored.** ✓

## Findings

### Blocking
None.

### Non-blocking

- **N1 (doc/enforcement mismatch in the schema comment).** Lines 147–149 assert
  "*on_failure and forbidden are mandatory*". In fact (a) `forbidden: [...string]` is
  **optional** — omitting it vets clean (probe F), and (b) the truly-mandatory
  `on_success` is not named in the comment. So "what it forecloses" (`forbidden`) is
  described as a contract requirement in prose but not enforced by the type. The pinned
  constraint lists `forbidden` as part of `post_result_rule`; leaving it fully optional
  is mild under-enforcement. **Recommend** either tightening to require a present list
  (e.g. `forbidden: [...string]` made a hard field) or correcting the comment to read
  "*on_failure and on_success are mandatory; forbidden is optional*". Non-blocking: both
  shipped preregs declare `forbidden`, and the load-bearing consequence is carried by the
  enforced `on_failure`/`on_success`.

- **N2 (cosmetic — fixture header).** `invalid/gate-not-executable.yaml` header cites
  "*samples < 2 cannot produce a spread*" as rationale, but the fixture keeps `samples: 3`
  and the actual defect is the omitted `agreement_floor`. The fixture fails for the correct
  reason; only the prose aside is slightly muddled.

- **N3 (disclosed known gaps — accepted).** No CI wiring vets `fixtures/preregs/**` yet
  (downstream / Sub-3), and validation was on `cue v0.17.0` while CI pins `v0.13.2`. The
  constructs used (`list.Contains`, field-emitting comprehensions, disjunction enums,
  bound/`!=""` constraints) are stable across that range. Non-blocking for this sub; flagged
  for the compiler sub to add a vet job.

## Self-coherence check

`.cdd/unreleased/79/self-coherence.md` is accurate: its AC→evidence table, cue-vet matrix,
round-trip narrative, and the four known gaps all reproduce under independent re-run. The
γ A− cap and δ-as-γ configuration note are correctly recorded.

---

**APPROVE.** The pinned typed-β-contract constraint holds; AC1–AC3 pass; the bidirectional
label/weight gate is proven in both directions; the factorized-β prereg round-trips with its
terminal FAIL unchanged; non-goals are honored. N1 is a worthwhile but non-blocking tidy-up
for the α cell or a follow-on.
