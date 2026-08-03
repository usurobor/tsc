# Ascent-0 · Sub 2 — Typed generative provider contracts

**Issue:** [#120](https://github.com/usurobor/tsc/issues/120) (under [#118](https://github.com/usurobor/tsc/issues/118) → flagship [#117](https://github.com/usurobor/tsc/issues/117)).
**Mode:** `design` — **typed contracts only. NO implementation.** The runtime that binds and runs these providers is Sub 3 ([#121](https://github.com/usurobor/tsc/issues/121)).
**Binds:** the frozen Sub-1 fixture [`research/ascent/fixtures/ascent-0/`](../../../ascent/fixtures/ascent-0/) (each case's `core_ir` block, the #116 obligations, and the sealed commit/reveal oracle). **Enforces:** #118 invariants 2 (frozen `H_M`) and 3 (no-oracle-leak). **Mirrors, does not edit:** [`../../schema.cue`](../../schema.cue) — its `#Boundary` fixed-false faces, closed-struct rejection, enum disjunctions, and negative-probe idioms.

This is the **typed seam between the compiled CM and the runtime**: one generative call plus six mechanical providers. The two firewalls are **enforced by `cue vet`, not by prose** — a semantic instance that smuggles a warrant, and a non-oracle provider that reaches the oracle, are both *rejected by the type checker* (proven by the negative fixtures below).

---

## The two firewalls (type-enforced)

**Firewall A — the LLM proposes but never warrants, and never owns `H_M`** (invariant 2).
The one semantic call returns exactly a `#CompiledView` **proposal**, a struct `close`d to five fields
(`governing_question`, `preserved_local_claims`, `closure_assumption`, `polar_view`, `named_obstruction`).
Because it is closed, **any** warrant-bearing field (a `result_class`, a `LIFT_VALIDATED`, a held-out
prediction, an equivalence verdict) or **any** field that sets/expands `H_M`, alphabets, bounds,
equivalence, search-completeness, or the held-out boundary is rejected as *field not allowed*. The
semantic provider's declared inputs are narrowed to the three leak-free surfaces
(`#SemanticInputSurface`), so it cannot even *name* `H_M` as an input; and `owns_H_M` / `emits_warrant`
are fixed **false** (the `schema.cue` `emits_admission_verdict: false` idiom), so a contract claiming
otherwise fails `cue vet`.

**Firewall B — the oracle is sealed from every non-oracle provider** (invariant 3).
The sealed surfaces are a typed set `#OracleSurface = "oracle_reveal" | "hidden_machine" |
"heldout_output_pre_reveal"`. Every provider declares `may_access` / `may_not_access` over
`#HiddenSurface`. In the shared base, `_oracle_cleared` is true **iff** `provider_class == "oracle"`;
for every other provider the `may_access` element type is narrowed to `#RestrictedSurface` (oracle
surfaces excluded), so a semantic or `FiniteModel` provider that lists an oracle surface in
`may_access` has no value in the disjunction — rejected. Only `Oracle.revealAndCompare` is cleared.

**The warrant is mechanical, and must be backed** (AC3/AC4). A warrant’s required backing is DATA per
result class (`#Warrant`); each mechanical provider declares which backings it can source
(`_can_back`), and a warrant it emits may only rely on those. So `Descent.predict` — which cannot
source `oracle_outcome` — **cannot** emit `LIFT_VALIDATED`: the claim is a type error.

---

## Files

```
contracts.cue              the typed contracts (package ascent0providers) — definitions only
suite.cue                  positive control: a valid instance of all seven providers (bound to case1)
negative/warrant_smuggle.cue   Firewall A negatives: semantic smuggling a warrant / owning H_M   (must FAIL)
negative/oracle_leak.cue       Firewall B negatives: non-oracle provider reading the oracle       (must FAIL)
negative/descent_warrant.cue   AC3/AC4 negative: Descent claiming an unbacked LIFT_VALIDATED       (must FAIL)
README.md                  this file
```

The negative fixtures live under `negative/` so they are **not** part of the package's positive
control: `cue vet contracts.cue suite.cue` (or `cue vet .`) sees only the well-formed contracts.

---

## The seven providers

**One semantic / generative call** — `#SemanticProvider`. `compileView` / `unclose` / `polarize` /
`nameObstruction` are conceptual **phases of this one judgment**, not four calls (AC1). Inputs: only
the one-POV behavior-primary viewpoint + training traces + the public methodology contract. Output:
a `#CompiledView` proposal. Search strength `sampled`; declares its sampling/repeatability (AC6).
Owns no `H_M`; emits no warrant.

**Six mechanical providers** (own the warrant). Every contract declares `input` · `output` ·
`capabilities` · `evidence` · `failure` · `search_strength` · `determinism`/`repeatability` ·
`may_access` / `may_not_access`.

---

## Each mechanical provider ↦ Sub-1 `core_ir` fields (#116, AC4)

`evidence.core_fields` names the #116 obligation; `evidence.fixture_fields` names the concrete
`generated/**/public.json` field(s) that carry it.

| Provider | Core (#116) fields produced | Sub-1 `core_ir` / public.json fields | May emit warrant |
|---|---|---|---|
| `FiniteModel.enumerate` | `H_M`, `SearchClaim` | `class.json`, `complete_candidate_set_size`, `core_ir.SearchClaim` (`complete_within_bound`) | — (declares `complete_within_bound`) |
| `Realization.fit` | `L_M`, `J_train`, `candidate_fiber`, `empty_or_unresolved_set` | `core_ir.L_M`, `core_ir.J_train`, `candidate_fiber_over_U`, `core_ir.empty_or_unresolved_set` | `NO_REALIZATION_IN_MODEL` (complete search + empty fit) |
| `Realization.quotient` | `equivalence`, `K_M`, `candidate_fiber`, `J_eval` | `core_ir.equivalence`, `core_ir.K_M`, `training_identification_fiber_over_U`, `core_ir.J_eval` | `ASCENT_UNDERDETERMINED` / `IDENTIFIED_IN_MODEL` |
| `Descent.predict` | `candidate_fiber`, `equivalence` | `heldout_distinct_predictions`, `heldout_is_separating`, `frozen_prediction_on_heldout` | **none** — cannot source `oracle_outcome` |
| `Oracle.revealAndCompare` | `oracle`, `candidate_fiber`, `empty_or_unresolved_set` | `oracle_commitment_sha256`, `expected_pass_count`, `expected_fail_count`, `expected_tested_fiber_size_after_reveal` | `LIFT_VALIDATED` |
| `RoundTrip.check` | `equivalence`, `candidate_fiber`, `J_eval` | `roundtrip_class_over_J_eval_after_fold`, `roundtrip_class_contains_hidden_machine` | `LIFT_VALIDATED` (validated continuation) |

`H_M` is produced by `FiniteModel.enumerate` alone (the LLM never sets it); the `oracle` Core field
is produced by `Oracle.revealAndCompare` alone. The result vocabulary is Core-faithful and never
collapsed: `NO_REALIZATION_IN_MODEL` (complete search, empty fit) is distinct from `UNRESOLVED`
(incomplete search, the mechanical failure mapping).

---

## `cue vet` — the three load-bearing results

Run from this directory (`cue` ≥ v0.13). Mirrors the `schema.cue` boundary-probe pattern:
the positive control exits 0; each firewall breach exits 1 with the conflicting-field message.

**1 — Positive control (well-formed contracts + a valid instance) → exit 0**

```
$ cue vet contracts.cue suite.cue
$ echo $?
0
```

**2 — Firewall A rejection (semantic smuggling a warrant / owning `H_M`) → exit 1**

```
$ cue vet contracts.cue negative/warrant_smuggle.cue
smuggle_warrant.output.result_class: field not allowed
smuggle_prediction.output.heldout_prediction_on_q: field not allowed
own_H_M.owns_H_M: conflicting values false and true
input_H_M.input.2: conflicting values "…" and "H_M_declaration"   (H_M is not a semantic input)
$ echo $?
1
```

**3 — Firewall B rejection (a non-oracle provider reading the oracle) → exit 1**

```
$ cue vet contracts.cue negative/oracle_leak.cue
leak_finite_search.may_access.0: conflicting values "…" and "hidden_machine"
leak_semantic.may_access.0:      conflicting values "…" and "heldout_output_pre_reveal"
leak_descent.may_access.1:       conflicting values "…" and "oracle_reveal"
$ echo $?
1
```

**Bonus — the warrant must be mechanically backed (AC3/AC4) → exit 1**

```
$ cue vet contracts.cue negative/descent_warrant.cue
descent_claims_validated.output.warrant.backed_by.oracle_outcome: conflicting values true and false
$ echo $?
1
```

Run alone (without `contracts.cue`) the negative files fail with *reference not found* — they never
silently pass.

---

## How an independent reviewer (β) refutes — and why each attempt fails

| β attack | where it dies |
|---|---|
| Turn the semantic call into four LLM calls. | There is one `#SemanticProvider` returning one `#CompiledView`; the four names are documented as phases, with no per-phase call type to instantiate. |
| Make the semantic output carry a `result_class` / held-out prediction. | `#CompiledView` is `close`d to five proposal fields → *field not allowed* (`warrant_smuggle.cue` a,b). |
| Let the semantic provider own or expand `H_M`. | `owns_H_M` fixed false → *conflicting values false and true*; and `H_M_declaration` is not a `#SemanticInputSurface`, so the LLM cannot even read the class (`warrant_smuggle.cue` c,d). |
| Give a non-oracle provider oracle access. | For any `provider_class != "oracle"`, `may_access` is narrowed to `#RestrictedSurface`; an oracle surface has no value in the disjunction → rejected (`oracle_leak.cue`). |
| Have `Descent.predict` (or `Realization`) declare a validated/unique result without its backing evidence. | The warrant's required backing pins a flag the provider cannot source to true, against its `_can_back` false → *conflicting values true and false* (`descent_warrant.cue`). |

---

## Non-goals (explicitly out of this cell)

No provider **implementation** (Sub 3 runtime); no `SandboxExecutionPlan`, no `ascent0_runner`, no IR
execution. No touching the frozen engine, `schema.cue` (referenced, not edited), or
`research/ascent/fixtures/ascent-0/`. No repository/check providers, no general registry, no prompt
engineering. **Nothing promoted to the public stdlib** — these contracts are Ascent-0-specific until
the slice survives end-to-end review (invariant 4).
