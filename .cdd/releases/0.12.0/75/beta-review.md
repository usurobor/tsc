# β review — cycle/75 (factorized-β measurement harness, Sub-2 of #73)

Role: β (reviewer). Identity: `beta@tsc.cdd.cnos`. Authority: FROZEN
`docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md` (rev 4) +
`docs/beta/governance/fixtures/factorized-beta-controls.json` + issue #75
(AC1–AC5). Reviewing α's harness on `cycle/75` @ `4775837`.

## Verdict: **APPROVE**

The harness evaluates the pre-registered A/B/C gate **exactly** as frozen,
reuses the one barrier source, leaves the α/γ scalar path and the frozen
prereg/fixtures untouched, and its terminal **FAIL** is a **real measured
result** — not a pipeline or harness artifact. I am reviewing harness
QUALITY, not the verdict; a correct harness that measures FAIL is
APPROVE-able, and this one is.

κ performs the merge and records the FAIL verdict downstream. I do **not**
merge and I record no experiment PASS/FAIL beyond noting the measured
verdict was FAIL.

## Recursive-coherence result: **PASS**

The harness that adjudicates β-consistency is itself internally coherent
under its own doctrine (mechanical seam, no hidden freedom): pure gate core
in `factorized_beta_gate.{ml,mli}`, thin git-style CLI in `bin/main.ml`, the
canonical barrier reused (`Coherence.coherence_link`, not re-implemented),
deterministic inventory driven from `Factorized_beta` (Sub-1), floors/margins
as compile-time constants unreachable from witness output, and 15 witness-free
tests pinning the whole gate matrix including NO-DECISION. No selection,
counting, or aggregation freedom leaks into the gate arithmetic. The
interface (`.mli`) constrains the surface; exhaustive matches; distinct
record-field prefixes. CI build+unit-test oracle (`ci.yml`) is green on the
branch HEAD (run 330, `4775837`, success; the intermediate warning-50 build
break at `7a09957` was fixed by `2cf60ff`).

## AC3 — the load-bearing one: prereg line vs code line

`evaluate_gate` (`factorized_beta_gate.ml:164`) implements the frozen gate
verbatim. Item by item:

- **A0 (yield).** Prereg §A0 table: `E=0`→not_applicable; `0<E<5`→must pass,
  excluded from A1/A2/A3; `E≥5`→must pass + apply. Requires
  `declared_samples == validated_samples == 3`. Code: `a0_targets` =
  `tm_eligible_loci > 0` (E>0), `a0_fail` = not `(declared = gi_declared &&
  validated = gi_declared)` with `gi_declared = 3`. **Match.** Sparse
  `0<E<5` targets are correctly A0-checked yet excluded from A1/A2/A3.
- **A1.** Prereg: β `Coh_consistency_max_pairwise ≥ 0.90` on every
  non-`locus_sparse` target. Code: `a1_fail = beta_coh < gi_a1_floor` over
  `scored` (`not tm_locus_sparse`); `default_a1_floor = 0.90`. **Match.**
  The statistic is `beta_coh_consistency = Coherence.coherence_link
  ~lambda:1.0 ~delta:(beta_spread betas)`, and `beta_spread` is the
  max-abs-pairwise difference — the same `max_pairwise` spread
  `Witness_numeric.per_field_spread` computes, specialized to the β field.
  Barrier **reused, not re-implemented** (prereg constraint honored). Pinned
  by `test_beta_spread_and_coh` (exact `exp(-0.1/0.9)`).
- **A2.** Prereg: β `Coh_consistency_max_pairwise ≥` free-witness β baseline
  `+ 0.10`, evaluated against the recorded value. Code: `a2_fail = not
  (baseline_present && beta_coh >= baseline_beta_coh +. gi_a2_margin)` over
  `scored`; `default_a2_margin = 0.10`. **Match**, with absent baseline →
  miss (see note below).
- **A3.** Prereg §A3: `agreement(T) =` mean over all unordered sample pairs
  and all eligible loci `l ∈ L(T)` (`mechanical_status ≠ unresolved`) of
  verdict-equality; pass iff `≥ 0.90`. Code: `locus_agreement`
  (`:38`) folds unordered pairs (`s1 :: rest`, iterate `rest`) × `eligible_ids`,
  counting `v1 = v2`; `a3_fail = tm_agreement < gi_a3_floor` over `scored`;
  `default_a3_floor = 0.90`. `eligible_ids` in the CLI is exactly the
  `Resolved` loci (`main.ml:608`). **Match.** Pinned by `test_locus_agreement`
  (1.0 / 0.5 / vacuous).
- **B1/B2/B3.** Booleans wired from credential-free guards (katas, admissibility)
  and the B3 controls job. **Match.**
- **C4.** Prereg: >1 held-out `locus_sparse` → NO-DECISION (not pass/fail).
  Code: `if sparse_count > 1 then No_decision` — evaluated **before**
  `all_ab_pass`, so it takes precedence, matching the frozen "Otherwise" in
  C5. **Match.**
- **C5.** Prereg: otherwise any A/B miss → FAILED. Code:
  `else if all_ab_pass then Pass else Fail`. **Match.**

No prereg line is off. No gate parameter is settable from witness output
(AC5): the three floors/margin are `let default_a{1,2,3}_* = …` constants.

### A2 "baseline absent" — defensible miss, not a harness gap

α scores an absent free-witness baseline as an A2 miss (conservative:
improvement cannot be claimed without a recorded baseline; pinned by
`test_gate_fail_a2_no_baseline`). The measured run missed A2 on
`cm-of-cms, methodology, repo, spec` — the first three also miss A1/A3, so
they FAIL independently. `spec` is the interesting case: it **passed** A1
and A3 (β highly self-consistent) but missed A2. From CI logs alone I cannot
distinguish "baseline pipeline produced <2 valid scalar samples → absent"
from "baseline present but factorized didn't beat it by +0.10." Either way:

- It is a **defensible, deterministic** score, not a spurious FAIL. The
  gate reads only measured records; the floor is a constant.
- It does **not** change the verdict — A1/A3 miss on three *other* scored
  targets is independently sufficient for C5 FAIL.
- There is an inherent **ceiling** in the frozen +0.10 margin: if the
  free-witness β baseline is already high, a +0.10 absolute gain is
  unreachable (β clamps at 1.0). That is a **prereg design property**
  (rev 4, frozen), faithfully implemented — **not** a harness defect and
  outside β's remit to change.

I flag the spec A2 cause as an observation for the experiment record
(κ / the close-out), not as a change request.

## Confirmation: the FAIL is a real measured result

Healthy run: `factorized-beta-measure` #2 (`2cf60ff`), conclusion **success**,
all 9 jobs green — `witness-gate` (credential present), `guards` (B1/B2),
`measure` ×5 (`spec, engine, repo, methodology, cm-of-cms`, k=3, factorized +
baseline arms), `b3-controls`, and `gate`. The gate step evaluated over the
five downloaded per-target measurement records and emitted:

```
[PASS] A0 — yield 3/3 on all 5 applicable target(s)
[MISS] A1 — below 0.90 on: cm-of-cms, methodology, repo
[MISS] A2 — below baseline + 0.10 (or baseline absent) on: cm-of-cms, methodology, repo, spec
[MISS] A3 — below 0.90 on: cm-of-cms, methodology, repo
[PASS] B1 — kata-01 pass / kata-02 fail
[PASS] B2 — cm-admissibility --self-test verdict matrix unchanged
[PASS] B3 — β local semantic controls (typed rules + label agreement)
targets scored: 4; locus_sparse: 1; -> FAIL
```

Non-spurious: the FAIL is driven by A1 **and** A3 measured below 0.90 on
three scored held-out targets (cm-of-cms, methodology, repo) — the β seam did
not hold cross-sample β-consistency or locus-verdict agreement there. Only 1
target (`engine`) is `locus_sparse`, so C4 does not fire; B1/B2/B3 all passed
on real output (discrimination retained). The agreement statistic counts only
loci both samples answered (missing answers are skipped, biasing *toward*
PASS), so it cannot manufacture a low-agreement FAIL. The verdict is a genuine
measured negative for the factorization claim.

## Per-AC

- **AC1 — PASS.** Harness (script `scripts/factorized-beta-measure.sh` +
  `measure` matrix job) drove k=3 factorized-β witnesses over all five
  held-out targets via `Factorized_beta` inventory/adjudication/aggregation,
  gated on `CLAUDE_CODE_OAUTH_TOKEN`. All 5 measure jobs succeeded.
- **AC2 — PASS.** Inventory, raw responses, validation (refusal counts in the
  record), per-target `β_factorized`, and free-witness baseline emitted and
  uploaded (`fb-artifacts-<target>-<sha>`, e.g. 15 files for spec); prompts
  (full bundle text) correctly excluded from upload.
- **AC3 — PASS.** Gate evaluated exactly as preregistered (verified line by
  line above); pinned by `test_factorized_beta_gate` (15 tests).
- **AC4 — PASS.** Single terminal token `FAIL` + gate summary committed as
  `fb-gate-summary-<sha>`; the token is the CLI's final stdout line.
- **AC5 — PASS.** `git diff origin/main...origin/cycle/75 -- docs/beta/governance/`
  is empty (frozen prereg + fixtures unedited); floors/margins are
  compile-time constants; no post-hoc gate parameter.

## Scope / constraint checks

- **Thin CLI, pure core.** The five `factorized-beta-*` subcommands in
  `bin/main.ml` are argument-parsing + I/O only; all gate arithmetic and the
  B3 controls logic live in `factorized_beta_gate.ml`. Confirmed.
- **α/γ scalar path untouched.** Diff over `runtime/*`, `scripts/coh-self`,
  `prompt.ml`, `response_schema.ml`, `.github/workflows/tsc-self-measure.yml`
  is empty. `runtime/SELF-MEASURE.md` unedited.
- **Workflow trigger.** `factorized-beta-measure.yml` `on:` is
  `workflow_dispatch:` and nothing else (operator directive, commit `4775837`);
  the five jobs (witness-gate · guards · measure · b3-controls · gate) are
  otherwise intact. Confirmed sole trigger.

## Position on α's 5 unpinned rows

All five are **acceptable / reversible**; none is a defect. Two are in fact
the *required* reading of the frozen text.

1. **β field vs `Witness_numeric` vector routing — ACCEPTABLE (correct).**
   `beta_spread` is literally the max-abs-pairwise difference
   `per_field_spread` computes; routing it through `Coherence.coherence_link`
   (λ=1) reuses the one barrier and adds no new statistic — exactly what the
   prereg demands. Threading a 1-field vector through `Witness_numeric` would
   be numerically identical ceremony. Pinned by test. Reversible.
2. **Free-witness β baseline = β-field (not composite) Coh — ACCEPTABLE
   (correct).** A2 is explicitly a β-improvement claim; using
   `fields.beta.spread` from `cm-consistency llm-spread` is the right
   same-statistic comparison. A composite would confound α/γ. Aligned with
   prereg "free-witness β baseline."
3. **C4 precedence over an A/B miss — ACCEPTABLE (required).** Prereg C4 is
   unconditional and C5 begins "Otherwise," so C4 must take precedence.
   α's ordering is faithful to the frozen text (moot in this run: 1 sparse).
4. **B3 label-agreement arity (n=7<20, one pass, every hard control must
   match) — ACCEPTABLE.** Prereg fixes the thresholds, not the arity; a
   single pass under the strict "all hard controls pass while n<20" rule
   satisfies the frozen requirement. B3 passed on real witness output.
   Reversible to k-repeat if δ wants a consistency read on the controls.
5. **B4 medoid point value not emitted — ACCEPTABLE.** B4 is
   observation-only (prereg demotes it); the gate does not consume it, and
   the A2 baseline β Coh *is* recorded. A minor reporting nicety, reversible.

## Bottom line

Harness is correct against the frozen gate, self-coherent, and scoped. The
measured verdict is a genuine **FAIL** (A1/A3 below floor on three scored
targets; B1/B2/B3 retained). **APPROVE.** κ merges and records FAIL.
