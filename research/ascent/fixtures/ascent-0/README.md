# Ascent-0 · Sub 1 — Formal contract + executable fixture generator + sealed oracle

**Issue:** [#119](https://github.com/usurobor/tsc/issues/119) (under [#118](https://github.com/usurobor/tsc/issues/118) → flagship [#117](https://github.com/usurobor/tsc/issues/117)).
**Binds:** [`spec/tsc-core.md`](../../../../spec/tsc-core.md) v4.1. **Enforces:** #116 IR obligations. **Governed by:** [`docs/product/NORTH-STAR.md`](../../../../docs/product/NORTH-STAR.md).
**Scope of this cell:** a *frozen formal contract* + a *small, self-contained, deterministic* fixture generator + a *sealed oracle*. **It builds NO CM runtime and NO provider framework** — those are Subs 2–4.

> **The load-bearing rule.** Nothing numerically or combinatorially load-bearing is typed by hand. A small program ([`bin/`](bin/)) mechanically emits every fixture; a `replay` command proves digest identity. A hand-transcribed oracle presented as an exact fixture would recreate the exact defect this project already learned from — so the target is *generated and replayable*, not written down.

This README is the **frozen contract**; the numbers live only in the emitted artifacts under [`generated/`](generated/), which the generator reproduces byte-for-byte.

---

## 1 · The exact mathematical object (frozen)

A **deterministic pointed Mealy transducer**

```
W = (S, s0, Sigma, Gamma, delta, lambda)
delta : S x Sigma -> S        (total, deterministic)
lambda: S x Sigma -> Gamma    (total, deterministic)
1 <= |S| <= N ,  initial state s0 = 0
```

with a **canonical enumeration** of the whole bounded class (n ascending `1..N`; within `n`, cells ordered state-outer/input-inner; each cell a mixed-radix digit over `(delta, lambda)`, first cell most significant). See [`bin/mealy.ml`](bin/mealy.ml) and [`generated/class.json`](generated/class.json).

**Frozen parameters — the SMALLEST the five cases demonstrate:**

```
N = 2 ,  |Sigma| = 2  (a,b) ,  |Gamma| = 2  (0,1)
query universe U = all Sigma-strings of length 1..3   (|U| = 14)
class size |H_M| = 260 machines
```

The generator *proves* this is minimal (see §7, [`generated/minimality.json`](generated/minimality.json)); N ≤ 3 is **not** ratified by convenience — 2 is shown sufficient and 1 shown insufficient.

### Articulations (precise)

| term | meaning | who may see it |
|---|---|---|
| **behavior** | the reply-word function over the declared query family `J` (the behavior-primary POV) | the only **public semantic input** |
| **source** (polar projection) | the canonical transition-law presentation (`canonical_id`) | a **projection available only from a recovered candidate** — never handed to the invocation |
| **higher generator W** | the pointed transducer producing both | sealed (oracle) until reveal |

### The exact obstruction

> A finite observed trace set does not define behavior on unattempted inputs and may be realized by several inequivalent transition laws.

A candidate **kills** the obstruction only by supplying a lawful **prediction operator** (`run` on an unattempted input) that **survives held-out execution** against the sealed oracle.

---

## 2 · The frozen equivalence and the identification target

Equivalence `~=^J` = *identical reply word on every query in `J`*. It is **refinement-monotone** by construction (wider `J` ⇒ finer partition — Core §2.10). Two regimes:

- training regime uses `J_train` (the trained queries);
- tested regime uses `J_eval = J_train ∪ {held-out query}`.

`U` (length 1..3) is a **complete separator** for the class: two ≤2-state machines are behaviorally equivalent iff they agree on all strings of length `≤ n1+n2-1 ≤ 3`. The generator verifies this mechanically (`class.json.equivalence_separation_verified_mechanically = true`). The **identification fiber** `F_id = C_train / ~=^U` is therefore the true count of distinct behaviors among training-fitting candidates.

---

## 3 · The FROZEN Result rule

The category is a **pure function of derived facts** (never hand-set); see `result_rule` in [`bin/cases.ml`](bin/cases.ml):

```
not admissible                                             -> DECORATIVE_LIFT
else |C_train| = 0        (complete search, empty)          -> NO_REALIZATION_IN_MODEL
else oracle_run and separating and pass>=1 and tested_fiber=1 -> LIFT_VALIDATED
else |F_id| >= 2                                            -> ASCENT_UNDERDETERMINED
else                                                        -> IDENTIFIED_IN_MODEL
```

where

```
admissible        the proposal parses into H_M and exposes a prediction operator
C_train           complete bounded set with L_M = 0 (exact fit) and K_M <= N  (COMPLETE search)
F_id              C_train / ~=^U                    (identification fiber)
separating        the held-out query yields >= 2 distinct predictions across F_id
pass              candidates predicting the revealed (sealed) output
tested_fiber      C_pass / ~=^J_eval                (post-reveal)
```

Each case computes these facts and **asserts** the rule reproduces its designed category at emit time — so the label is *derived from the artifacts*, exactly what an independent reviewer recomputes.

This maps onto Core v4.1: `NO_REALIZATION_IN_MODEL` (§5.5, complete search + empty `C_fit`), `UNDERDETERMINED` (§5.5, several inequivalent classes), `LIFT_VALIDATED` (§10.4, held-out prediction without refitting + baseline failure), and `DECORATIVE_LIFT` (refused at A5 non-vacuity / admissibility, *before* realization). Core explicitly refuses to collapse empty-after-complete-search into uncertainty; so does this fixture.

---

## 4 · The five cases (mechanically generated; exact expected results)

All artifacts are under [`generated/cases/`](generated/cases/). Each `public.json` carries `expected_result`, the **derived** `derived_result`, the training traces, the complete candidate fiber, the cardinalities, and (for sealed cases) the frozen held-out predictions + the oracle commitment. Each `semantic_input.txt` is the leak-free behavior-primary POV (invariant 1, §6).

| # | case | expected | mechanically established by |
|---|---|---|---|
| 1 | `case1_lift_validated` | **LIFT_VALIDATED** | train `{a:0, aa:01, b:0, ba:00}`; held-out `ab` (out-of-fit, input-indexed: it tests the reply *after* an `a` then a `b`, a context absent from training). `F_id = 8`; `ab` yields distinct predictions `{00, 01}` ⇒ **separating**; sealed `W(ab)=01`; passing candidates predict `01`; tested fiber over `J_eval` collapses to **1**; the recovered class contains `W`. |
| 2 | `case2_ascent_underdetermined` | **ASCENT_UNDERDETERMINED** | train `{a:0, b:0}`; complete search retains `|C_train|=65`, `|F_id|=37` inequivalent classes; **no** oracle run. Two candidates of **equal complexity** `K_M=2` are exhibited with the distinguishing query `ab` (not in training) — so complexity cannot break the tie. |
| 3 | `case3_no_realization_in_model` | **NO_REALIZATION_IN_MODEL** | contradictory evidence `{a:0, a:1}`; the complete enumeration of all 260 machines fits **0**. Completeness argument emitted (determinism ⇒ a fixed history has a unique reply word at *any* state count). Distinct from `UNRESOLVED` (incomplete search) and `UNDERDETERMINED` (≥1 fit). |
| 4 | `case4_decorative_lift` | **DECORATIVE_LIFT** | a fluent proposed whole ("source and behavior are complementary manifestations…") **refused before realization** for lacking all 5 witnesses (typed generator · prediction operator · admissible realization in `H_M` · obstruction-dissolution · held-out consequence). It never enters the fiber. The underlying data `{a:0}` **is** realizable (130 fitting candidates) — so the refusal is of the *proposal*, not the data (distinct from case 3). |
| 5 | `case5_roundtrip` | **LIFT_VALIDATED** (validated continuation / round-trip) | train `{a:0, b:0, bb:00}`; `q* = ab` **separating** (`F_id = 21`, predictions `{00,01}`); descend `W` on `q*`, fold `(ab, W(ab)=01)` back in, re-ascend: the `U`-fiber **strictly shrinks** `21 → 8` (strong separation) and the round-trip class over `J_eval'` is a **singleton containing W** — `Ascend(D_train ∪ Descend(W, q*)) ≃ W`. |

All four categorical distinctions (`LIFT_VALIDATED` / `ASCENT_UNDERDETERMINED` / `NO_REALIZATION_IN_MODEL` / `DECORATIVE_LIFT`) are exercised.

---

## 5 · Core / IR obligations carried per case (#116)

Every realizable case emits a `core_ir` block naming the fields the later IR must carry:

```
H_M                deterministic Mealy <= N states over Sigma,Gamma (class.json)
SearchClaim        complete_within_bound(N=2, |Sigma|=2, |Gamma|=2)
joint_realization  generator G in H_M + identity observation atlas (trivial, retained)
equivalence        behavioral ~=^J, refinement-monotone
L_M                # training traces whose predicted reply differs; tau_M = 0 (exact)
K_M                generator state count; kappa_M = N = 2
J_train / J_eval   fit family / fit + held-out family
oracle             commit/reveal sealed held-out (cases 1, 5) or none
candidate_fiber    every surviving equivalence class (with representative + members)
empty/unresolved   retained explicitly (C_fail for case 1; empty C_fit for case 3)
```

The IR is **specified here, not built** — Subs 2–4 own the runtime.

---

## 6 · Invariants (frozen), enforced *by construction*

1. **One-POV input, no supplied dichotomy.** The only semantic-facing artifact is `semantic_input.txt`: a behavior-primary black-box POV + the training traces. The generator scans each such file and **fails the build** if any withheld term appears: `source`, `transition law`, `finite-state machine`, `Mealy machine`, `hidden generator` (`assert_leakfree`). The mechanical `public.json` legitimately uses that vocabulary — it is the backend contract, not the semantic input.
2. **Frozen model class.** `H_M`, bounds, search claim, equivalence, held-out boundary, and fit/complexity are declared in this contract *before* execution. Autonomous class discovery is a later #117 slice.
3. **No-oracle-leak (sealed oracle, commit/reveal).** For sealed cases the public `oracle_commitment_sha256 = sha256( canonical_document( reveal/<case>.json ) )` where the reveal bundle holds `hidden_machine ‖ heldout_query ‖ heldout_output ‖ salt`. The held-out **input** is public when prediction begins; the held-out **output** lives only in the separate `reveal/` bundle. Each candidate's held-out prediction is frozen in `public.json` *before* any reveal. **`verify` proves the commitment binds the on-disk reveal, and that the sealed output is `W`'s genuine reply (the oracle is not lying).**
4. **No premature generalization.** Nothing here is promoted to a standard; the contract is fixture-specific (invariant 4 / North-Star invariant 4).

### Sealing — what it does and does not mean

The reveal bundle **is committed to the repository** (the task requires it). The seal is therefore **not secrecy from a repo reader** — it is (a) **tamper-evidence**: the public commitment digest pins the exact reveal bytes, so the sealed output cannot be changed after predictions are frozen; and (b) a **protocol access rule** the later runtime (Sub 3) must enforce: *the reveal bundle may be read only via a dedicated oracle step, only after every candidate prediction is frozen.* The salt is a deterministic domain-separating nonce (derived by hashing a single master seed — no salt is hand-typed), not a secret. This is stated so the sealing claim is not overread.

---

## 7 · Smallest-N demonstration (mechanical)

[`generated/minimality.json`](generated/minimality.json), all computed by enumeration:

- **N ≥ 2 required.** Case 1's augmented dataset `D_train ∪ {(ab, sealed output)}` has an **empty** complete fit set at `N=1` (memoryless) but **4** fitting candidates at `N=2`: the validated held-out descent is unrealizable without state.
- **|Gamma| ≥ 2 required.** At `|Gamma|=1` every machine has identical behavior — distinct behaviors over `U` = **1** — so no fiber has ≥2 classes and no held-out can separate; neither `LIFT_VALIDATED` separation nor `ASCENT_UNDERDETERMINED` is demonstrable.
- **|Sigma| ≥ 2 required.** The bound obligation *input-indexed equivalence / behavior on unattempted **inputs*** is vacuous at `|Sigma|=1` (one symbol: widening the input family cannot split a class by input). At `|Sigma|=2`, widening the indexing family from a-only queries to `{a,b}` queries splits classes **6 → 148**, so the obligation does real work.

Hence `(N, |Sigma|, |Gamma|) = (2, 2, 2)` is the minimal object.

---

## 8 · Build · run · replay · verify

Requires only OCaml + `dune` + the stdlib `unix` library. No network, no external packages. SHA-256 is implemented in-tree ([`bin/sha256.ml`](bin/sha256.ml)) and self-tests against FIPS-180-4 known answers at every run, so digests are **real SHA-256** — reproducible with the system `sha256sum`.

```
make build          # dune build
make emit           # (re)generate generated/  (public artifacts + reveal/ + MANIFEST.sha256)
make replay         # prove byte identity: rebuild in memory, diff vs committed tree
make verify         # prove sealed-oracle commitments bind the reveal bundle
make check          # replay + verify + independent  sha256sum -c MANIFEST.sha256
```

Or directly: `dune exec bin/ascent0_gen.exe -- (emit|replay|verify) [OUTDIR]`.

**Reproducible digests** (from `emit`; `replay` and `sha256sum -c` reproduce them):

```
MANIFEST.sha256 digest                3b15c03c7ff502fcdff553ab45c8436039a40831f171966f2fb505e767b42387
oracle commitment case1 (reveal)      c9bb2e42a252d449bc72d5a444033ac5b9f6f4b1be06c5c38e25009f04eb3f92
oracle commitment case5 (reveal)      802f32fee1bdbe1bb0ac9ce41b4903ec83082e85e5520175a6ca3147f2923dc9
```

`generated/MANIFEST.sha256` is `sha256sum -c` compatible: `cd generated && sha256sum -c MANIFEST.sha256`.

---

## 9 · How an independent reviewer (β) refutes — and why each attempt fails

| β attack | where it dies |
|---|---|
| "A fixture is transcribed, not generated." | `make replay` rebuilds every artifact in memory and diffs byte-for-byte; `sha256sum -c` confirms with an independent tool. Tampering one byte flips `replay` to `REPLAY FAILED` (exit 1). |
| "The held-out is secretly in `J_train`." | `public.json.heldout_is_out_of_fit = true`; the held-out string is checked absent from the training inputs at emit time. |
| "The held-out does not separate." | `heldout_distinct_predictions` lists ≥2 distinct frozen predictions; emit **asserts** `separating`, and (case 5) that `q*` strictly shrinks the `U`-fiber. |
| "The 'underdetermined' case actually identifies one machine." | `inequivalent_class_count_over_U = 37`; an equal-complexity pair is exhibited with a witnessing query — no complexity tie-break exists. |
| "The 'no-realization' case is actually satisfiable." | `enumerated_class_size = 260`, `fitting_candidate_count = 0`, plus a determinism completeness argument; the search is complete, so this is `NO_REALIZATION_IN_MODEL`, never `UNRESOLVED`. |
| "The decorative candidate really predicts the held-out." | It is refused at the admissibility gate (all 5 witnesses absent) and **never runs**; meanwhile the same data is realizable (130 candidates), isolating the refusal to the proposal. |
| "The oracle is not sealed / could be edited." | `verify` proves `sha256(reveal)` equals the public commitment and that `W`'s genuine reply equals the sealed output; the reveal is a separate bundle; sealing semantics are stated in §6. |
| "A withheld term leaked into the input." | `assert_leakfree` fails the build if any of the five terms appears in any `semantic_input.txt`. |

---

## 10 · Non-goals (explicitly out of this cell)

No CM runtime, no provider framework, no `.cm` compilation, no IR execution (Subs 2–4). No touching the frozen engine, `research/cm-language/`, or `schema.cue`. Nothing promoted to a standard. No LLM prompt design. No `machine ≡ human` fixture. No claims beyond bounded-equivalence identification; no autonomous model-class discovery (`H_M` is frozen here).

---

## 11 · Files

```
README.md                     this frozen contract
Makefile                      build / emit / replay / verify / check
dune-project, bin/dune        dune project (stdlib + unix only)
bin/sha256.ml                 in-tree SHA-256 (FIPS-180-4, self-tested)
bin/mealy.ml                  the transducer, canonical enumeration, fit, equivalence, fibers
bin/serialize.ml              canonical deterministic JSON (stable bytes)
bin/cases.ml                  the five scenarios (INPUTS only) + derivation + assertions
bin/ascent0_gen.ml            emit / replay / verify / selftest driver
generated/
  index.json                  overview: config, result rule, per-case digests + commitments
  class.json                  H_M declaration + separator completeness witness
  minimality.json             the smallest-(N,Sigma,Gamma) proof
  MANIFEST.sha256             sha256sum -c compatible manifest of public artifacts
  cases/<case>/semantic_input.txt   leak-free behavior-primary POV (public semantic input)
  cases/<case>/public.json          mechanical contract: fiber, cardinalities, predictions, commitment
  reveal/<case>.json          sealed bundle: hidden machine, held-out output, salt (separate)
```
