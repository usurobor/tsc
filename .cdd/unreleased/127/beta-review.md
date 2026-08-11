# β review — cycle/127

**Verdict:** REQUEST CHANGES

**Round:** 1
**Review SHA (head):** `bb785ffef69137b6b1afe83b945478512424567b`
**Diff base:** `origin/main` = `e8b8319281cc5aea85ad9856a864000477faaa0d` (re-fetched synchronously at review time; `git merge-base origin/main HEAD` == main tip, so the branch has not drifted behind main)
**Branch CI state:** **mixed** — `coh-min` success, `ci` success, **`CDD Artifact Validate` failure** (see §CI status and F1)
**Merge instruction (once findings clear):** `git merge cycle/127` into `main` with `Closes #127`

> **Read this verdict correctly.** All seven acceptance criteria pass, and every
> one of them was verified by β running the oracle independently, not by reading
> α's transcript. The implementation is the strongest surface this slice has
> produced: `lib/ir.ml` is a genuinely total, pure validator, and the AC4
> vocabulary gate is proved by a discriminating experiment that a hardcoded
> runner could not survive. The verdict is REQUEST CHANGES on **merge
> readiness**, not on the implementation — the repo's own pre-merge closure gate
> currently answers "merge blocked" on this SHA, for a reason **inherited from
> cycle 126 and not caused by, nor fixable within, #127**. See F1 for the
> recovery path, which is γ/δ-side.

---

## §Verification method

`dune` is unavailable in this cell, as α reported and γ verified. Every local
claim below was produced by β independently, with β's own commands:

- **Flat native build** — `ocamlopt -w +a-4-70 -warn-error +a-4-70 sha256.ml
  json.ml provider.ml ir.ml runner.ml driver.ml -o coh_min` over
  `lib/{sha256,json,ir,provider,runner}.ml` plus a driver derived from
  `bin/coh_min.ml` and a test derived from `test/test_coh_min.ml` with the
  `Coh_min.` prefix stripped. Both binaries compiled **clean, exit 0**, with
  warnings-as-errors.
- `cue` v0.9.2 at `/usr/local/bin/cue`.
- **Canonical `dune build` / `dune runtest`** evidence is the `coh-min` CI job on
  the review SHA, whose per-step conclusions β read from the Actions API rather
  than inferring from the run-level result.

β did not reuse any artifact α produced. The IRs, receipts and negative fixtures
below were built by β.

---

## §2.0.0 Contract Integrity

| Check | Result | Notes |
|---|---|---|
| Status truth preserved | yes | α claims **only** what it could observe. §Review-readiness explicitly says "Branch CI: not observable from this cell" and asks β to confirm — no overclaim. β found the CI picture is more complicated than α's ask covered (F1), but that is a gap in the ask, not a false claim. |
| Canonical sources/paths verified | yes | `SCHEMA = ../../schema.cue` resolves from the coh-min root to `research/cm-language/schema.cue`; `cue vet` run from that base by β. |
| Scope/non-goals consistent | yes | `schema.cue` is **not** in the diff (0 hits). The surface compiler was not built; AC7 took the rename limb and says why. |
| Constraint strata consistent | yes | Required / optional split is explicit and honest: `config` is genuinely optional (`J.t option`), the eight canonical blocks are hard, `result_classes` is deliberately stricter than the schema and is documented as such in three places. |
| Exceptions field-specific/reasoned | yes | §Debt carries 5 items, each with a reason and a bound. No blanket exemption. |
| Path resolution base explicit | yes | `Provider.confine` is subject-root-relative with its whole negative space tested (8 pure assertions, β re-ran them). |
| Proof shape adequate | yes | Invariant, oracle, positive, negative, operator-visible projection and known gap are all present for each AC. Negative fixtures differ from the canonical one in exactly one field. |
| Cross-surface projections updated | yes | Makefile target, `make gate` dependency, CI step, README §Build-and-run target list and README §Two-mechanisms table all move together. β verified each. |
| No witness theater / false closure | **no** | One structural-closure claim in `Makefile:16-17` is demonstrably stronger than the code — see **F2**. Everything else is backed by a rejection mechanism β triggered by hand. |
| PR body matches branch files | n/a | No PR. β verified the equivalent: §CDD Trace's artifact enumeration matches `git diff --name-status origin/main...HEAD` exactly, all 15 files. |
| γ artifacts present (gamma-scaffold.md) | yes | `.cdd/unreleased/127/gamma-scaffold.md` present on the cycle branch. Rule 3.11b satisfied via canonical §5.1 path; no exemption claimed or needed. |

---

## §2.0 Issue Contract

### AC Coverage

| # | AC | In diff? | Status | Notes (β's own evidence) |
|---|----|----------|--------|--------|
| 1 | Both IRs vet against `#NormalizedCMIR` | yes | **PASS** | β ran `cue vet <ir> ../../schema.cue -d '#NormalizedCMIR'` over both: `readme-present.ir.json` **exit 0**, `readme-present.escape.ir.json` **exit 0**. `../ascent-0/ir/ascent0.ir.json` still exit 0 (no collateral damage to the reference). The two IRs differ in exactly one line (`"relative_path": "README.md"` vs `"../README.md"`), so the negative fixture is a true one-variable negative. |
| 2 | `make vet-ir` over every IR under `examples/`; `make gate` depends on it; CI runs it; non-conforming IR fails loudly | yes | **PASS** (with F2 on the closure *claim*) | See §AC2 evidence below — four independent probes. |
| 3 | No regression (#126 ACs hold) | yes | **PASS** | See §AC3 evidence below. |
| 4 | Result-class vocabulary read from the IR | yes | **PASS** | See §AC4 evidence below — β's discriminating experiment goes beyond α's. |
| 5 | Missing canonical block fails closed, clean `IR error`, no receipt | yes | **PASS** | 8 of 8 blocks, at the CLI. See §AC5 evidence below. |
| 6 | `dune runtest` passes with new regressions | yes | **PASS** | β's flat build: **32 ok, 0 FAIL, exit 0** — matches α's claimed 32 exactly. Canonical `dune runtest` = CI step 8 "Test (unit + end-to-end)", **conclusion `success`** on `bb785ff`. |
| 7 | `readme-present.cm` no longer implies a compile path | yes | **PASS** | `ls examples/*/*.cm` → no such file. Repo-wide grep for `readme-present.cm` returns **only** frozen `.cdd/` cycle records (126 + 127) plus one deliberate backreference in the new intent file explaining the rename. No live consumer, glob, Makefile or dune rule references a `.cm`. `sha256sum readme-present.intent.md` = `939abe2e…1667`, byte-equal to both IRs' `source_digest` — the digest is genuine, not fabricated. |

### AC2 evidence (β's four probes)

| Probe | Command | Result |
|---|---|---|
| Baseline | `make vet-ir` | exit 0, 2 IRs reported conforming |
| **Gate bites** | delete `receipt_contract` from the shipped IR, `make vet-ir` | **exit 2**, `receipt_contract.kind: incomplete value string` + `FAIL(vet-ir): … does not conform` |
| **Non-vacuous** | (i) `make vet-ir IRS=""` (ii) a real tree with `examples/` present but empty | **exit 2** both, `FAIL(vet-ir): no *.ir.json found under examples/ — the gate would pass vacuously` |
| **Discovery is recursive** | drop a bogus IR at `examples/newcase/ir/bogus.ir.json` | **exit 2** — picked up without any Makefile edit |

`make gate` depends on it: `Makefile:66` reads `gate: vet-ir vet`, with `vet-ir`
first. **CI runs it, verified by parsing not reading:** `yaml.safe_load` of
`.github/workflows/coh-min.yml` yields 9 steps, step 7 named
`Vet IRs against #NormalizedCMIR` — the full string, un-truncated, so α's fix for
the unquoted-`#` YAML comment trap is confirmed present and correct. β further
confirmed at *runtime* rather than only in source: the Actions API reports step 7
on `bb785ff` with `"conclusion": "success"`, so the step genuinely executed.

### AC3 evidence

| Check | Result |
|---|---|
| present → `README_PRESENT` | exit 0, `"result_class": "README_PRESENT"` |
| absent → `README_ABSENT` | exit 0, `"result_class": "README_ABSENT"` |
| receipts differ | `cmp` reports differ |
| present receipt vs `#MeasurementReceipt` | `cue vet` **exit 0** |
| absent receipt vs `#MeasurementReceipt` | `cue vet` **exit 0** |
| escape IR denied fail-closed | **exit 1**, **stdout 0 bytes** (β measured with `wc -c`, so "no receipt" is a byte count, not an assumption), stderr `✗ coh_min: relative_path "../README.md" contains a ".." segment and could escape the subject root` |

`examples/readme-present/contracts/receipt.cue` is **unchanged** in the diff, and
its `result_class: "README_PRESENT" | "README_ABSENT" | "INCOMPLETE"` agrees with
the IR's newly declared `result_classes` — no authority conflict between the two
surfaces (review §2.1.8).

### AC4 evidence — the vocabulary is genuinely data, proved by changing the data

β did not read the code and conclude; β edited the IR's declared classes and ran
the **same binary** against the **same fixtures**:

| IR's `result_classes` | vs `fixtures/present` | vs `fixtures/absent` |
|---|---|---|
| `[README_PRESENT, README_ABSENT, INCOMPLETE]` (shipped) | exit 0, receipt, `README_PRESENT` | exit 0, receipt, `README_ABSENT` |
| `[PRESENT, ABSENT, INCOMPLETE]` (renamed) | **exit 1, 0 bytes** | **exit 1, 0 bytes** |
| `[README_PRESENT, INCOMPLETE]` (one class dropped) | **exit 0, receipt** | **exit 1, 0 bytes** |
| `[README_PRESENT, README_ABSENT, INCOMPLETE, EXTRA_CLASS]` (superset) | exit 0, receipt, `README_PRESENT` | exit 0, receipt, `README_ABSENT` |
| `[]` (empty) | **exit 1**, `IR error: result_contract.result_classes declares no result class` | same |

Row 3 is the decisive one and is **stronger than the experiment α ran**: with the
vocabulary partially narrowed, one and the same binary *emits a receipt for one
subject and refuses for the other*. No hardcoded vocabulary can produce that
split. The refusal names both the offending class and the declared set, so it is
operator-actionable. β also confirmed that the renamed-vocabulary IR still passes
`cue vet` (exit 0) — i.e. this gate is doing work the schema does not do.

Bounding note (not a finding): `Runner.classify` can only ever derive one of
`README_PRESENT` / `README_ABSENT` / `INCOMPLETE`, so the gate can only ever
*narrow*, never widen, what reaches the receipt. Declaring a superset therefore
cannot smuggle a class past `receipt.cue`. β checked this explicitly because a
data-driven vocabulary is exactly the shape that could otherwise breach a
downstream contract.

### AC5 evidence — 8 of 8 at the CLI

β generated eight IRs, each the shipped IR minus exactly one canonical block, and
ran the real binary against `fixtures/present`:

| Missing block | exit | stdout bytes | stderr |
|---|---|---|---|
| `format` | 1 | 0 | `IR error: format is missing` |
| `cm_id` | 1 | 0 | `IR error: cm_id is missing` |
| `cm_version` | 1 | 0 | `IR error: cm_version is missing` |
| `source_digest` | 1 | 0 | `IR error: source_digest is missing` |
| `input_contract` | 1 | 0 | `IR error: input_contract is missing` |
| `procedure` | 1 | 0 | `IR error: procedure is missing` |
| `result_contract` | 1 | 0 | `IR error: result_contract is missing` |
| `receipt_contract` | 1 | 0 | `IR error: receipt_contract is missing` |

Clean `IR error` class, exit 1, zero receipt bytes — 8 of 8. The regression table
in `test/test_coh_min.ml:220` iterates `Ir.canonical_blocks`, the same list
`Ir.of_json` enforces, so a ninth block cannot acquire an untested regression.
β confirmed the helper `is_ir_error` (`test/test_coh_min.ml:165-169`) carries the
`| exception _ -> false` arm, so an escaping exception **fails** the test rather
than silently passing it — β's own #126 F1 bug class is closed, not merely
avoided.

### §α's `cue vet` finding — β reproduced it independently; it is ACCURATE

This was the item δ most needs a trustworthy read on. β rebuilt the matrix from
scratch (own script, own fixtures, cue v0.9.2, `-d '#NormalizedCMIR'`), deleting
one canonical block at a time from the shipped IR:

| Missing block | `cue vet` | first diagnostic | the runtime |
|---|---|---|---|
| `format` | **PASSES** | — | fails closed |
| `procedure` | **PASSES** | — | fails closed |
| `result_contract` | **PASSES** | — | fails closed |
| `cm_id` | fails | `cm_id: incomplete value string` | fails closed |
| `cm_version` | fails | `cm_version: incomplete value string` | fails closed |
| `source_digest` | fails | `source_digest: incomplete value string` | fails closed |
| `input_contract` | fails | `input_contract.kind: incomplete value string` | fails closed |
| `receipt_contract` | fails | `receipt_contract.kind: incomplete value string` | fails closed |

**β's read: α's claim is exactly correct — 3 of 8, and the three named blocks are
the right three.** The mechanism α gives is also correct: a schema field whose
value is already concrete (`format: "tsc-cm-ir/0.1"`) unifies to that literal
when the data omits it, and an open struct is complete as `{}`, so absence and
emptiness are indistinguishable for `procedure` and `result_contract`. Only
fields left *incomplete* when absent (`cm_id: string`, `…kind: string`) fail.

**Why this matters to δ beyond this cycle.** `cue vet` alone would admit an IR
with **no procedure and no result_contract** — a document that declares no work
and no vocabulary — as a conforming `#NormalizedCMIR`. Any future surface that
treats "vets against `#NormalizedCMIR`" as sufficient to mean "is a usable CM IR"
is relying on a guarantee the schema does not give. The schema gate is real but
narrower than the project's own language implies. In this slice the exposure is
closed at run time by `Ir.of_json` (8 of 8 above), and the division of authority
— *schema owns exactness, runtime owns presence* — is documented consistently in
`lib/ir.ml:11-45`, `README.md` §Two mechanisms, and §Finding of self-coherence.
β checked all three renderings against the measured matrix and they agree with
each other and with the measurement (review §2.1.2 multi-format parity).

α correctly declined to fix this by editing `schema.cue`: the issue's §Scope
excludes tightening the run-side stub and the pinned contract forbids touching
the file. It is recorded as §Debt item 1. **β endorses that as the highest-value
follow-up in the set** and recommends δ file it as its own case: it is the same
defect class #127 closes, one layer up.

### Named Doc Updates

| Doc / File | In diff? | Status | Notes |
|---|---|---|---|
| `README.md` | yes | ok | New §The IR is canonical, §Two mechanisms (with the measured matrix), §Result-class vocabulary; §Honest scope and target list corrected. β verified every factual claim in the new sections against its own measurements. |
| `readme-present.intent.md` | yes (A) | ok | Replaces the `.cm`. First line states the IR is authoritative; states nothing compiles or reads it; explains why the real grammar cannot express it. Intent sketch fenced as `text` and labelled not-a-program. |
| `.github/workflows/coh-min.yml` | yes | ok | New vetted step; comment names the YAML `#` trap. |
| `Makefile` | yes | ok | `vet-ir` added, `gate` depends on it. See F2 on one comment. |
| `lib/runner.ml` comment | yes | ok | The stale "the `.cm`'s `decide` block" wording is reworded; it no longer asserts a `.cm` exists. |

### CDD Artifact Contract

| Artifact | Required? | Present? | Notes |
|---|---|---|---|
| `.cdd/unreleased/127/issue-127.md` | yes | yes | 7 ACs + pinned 7-axis contract |
| `.cdd/unreleased/127/gamma-scaffold.md` | yes | yes | Rule 3.11b satisfied |
| `.cdd/unreleased/127/self-coherence.md` | yes | yes | Every claim β relied on was re-derived independently; none was found false |
| `.cdd/unreleased/127/beta-review.md` | yes | yes | this file |

### Active Skill Consistency

| Skill | Required by | Loaded? | Applied? | Notes |
|---|---|---|---|---|
| `eng/ocaml` | OCaml runtime change | yes | **yes, visibly** | §3.10's smell list is the actual content of the refactor: the old `link` fabricated `may_access = []`, `search_strength = "exact"`, `config = J.Obj []` and `seed_surfaces = []` on absent input. Each is now a typed `Error`. §2.1 field disambiguation holds — `Ir.step` and `Ir.t` share no field name. §3.2 purity holds — `lib/ir.ml` has no I/O. |
| `eng/code` | any code change | yes | yes | §1.3 errors embed context: every message carries its dotted path (`procedure.steps[0].produces`, `input_contract.required_artifacts[0].role`). |
| `eng/test` | new regressions | yes | yes | §2.3 strongest cheap proof: table-driven over the validator's own list; the AC4 proof is a discriminating experiment, not an assertion about a constant. |
| `cdd/alpha` §2.4 harness audit | schema-bearing change | yes | yes | The audit earned its place — parsing the YAML caught a truncation that reading it would not have. β re-parsed and confirms the fix. |

---

## Architecture Check

| Check | Result | Notes |
|---|---|---|
| Reason to change preserved | yes | `ir.ml` owns the IR contract; `runner.ml` owns execution; `provider.ml` owns the effectful edge. This diff *increases* separation — `runner.ml` no longer reaches into raw JSON at all. |
| Policy above detail preserved | yes | The result-class vocabulary moved from implicit OCaml knowledge into IR data, with enforcement (`Ir.declares`) in the pure layer. This is policy moving up, which is the right direction. |
| Interfaces remain truthful | yes | `Ir.of_json` is genuinely total: β confirmed by construction (no raising accessor is reachable from it — it reads through its own `result`-returning accessors precisely because vendored `Json.member` raises) and by test (`| exception _ -> false`). `bin/coh_min.ml`'s documented exit codes were corrected to match behaviour, and β verified exit 1 on every fail-closed path it exercised. |
| Registry model remains unified | n/a | No registry surface. |
| Source/artifact/installed boundary preserved | yes | The `.cm` → `.intent.md` rename is exactly this boundary being made honest: authored intent vs authoritative executable artifact. |
| Runtime surfaces remain distinct | yes | Pure `lib/ir.ml`, effectful `lib/provider.ml`, thin `bin/coh_min.ml` dispatch. |
| Degraded paths visible and testable | yes | Every degraded path β could reach emits a named, operator-actionable error and is pinned by a regression. β reached 8 block omissions, 4 vocabulary variants, 1 escape denial, 2 malformed-parse classes. |

---

## §CI status (rule 3.10)

Read from the Actions API on review SHA `bb785ffef69137b6b1afe83b945478512424567b`:

| Workflow | Conclusion | Run |
|---|---|---|
| `coh-min` | **success** | [31500993728](https://github.com/usurobor/tsc/actions/runs/31500993728) |
| `ci` | **success** | [31500993764](https://github.com/usurobor/tsc/actions/runs/31500993764) |
| `CDD Artifact Validate` | **failure** | [31500993639](https://github.com/usurobor/tsc/actions/runs/31500993639) |
| `CDD Telegram Notifier` | skipped | 31500993649 |

`coh-min` job `93810634036`, all 10 steps `success`, including step 7
`Vet IRs against #NormalizedCMIR`, step 8 `Test (unit + end-to-end)`
(= canonical `dune runtest`), step 9 `Gate (AC1-5, over schema-vetted IRs)`
(= `make gate`, which β cannot run locally without dune) and step 10
`Path confinement (AC6)`. This is the canonical evidence for AC6 and for the
`make gate` half of AC2, and it is green.

β could not read the branch-protection rules (`GET /repos/usurobor/tsc/branches/main/protection`
returns 403 `Resource not accessible by integration`), so rule 3.10's stated
fallback applies: **every workflow that runs on the cycle branch** counts as
required. `CDD Artifact Validate` runs on the cycle branch and is red. Hence F1.

---

## Findings

| # | Finding | Evidence | Severity | Type |
|---|---------|----------|----------|------|
| F1 | `CDD Artifact Validate` is red on the review SHA and its own output declares merge blocked. **Not caused by #127 and not fixable within #127's pinned scope** — the cause is cycle 126's missing close-out artifacts, and the same workflow is already red on `origin/main` tip. | Run [31500993639](https://github.com/usurobor/tsc/actions/runs/31500993639), job `artifact-validate`: `❌ cycle 126: missing alpha-closeout.md`, `❌ cycle 126: missing beta-closeout.md`, `✅ cycle 127 (small-change): no required cycle-dir artifacts`, `❌ Pre-merge closure gate FAILED: 2 missing required artifact(s) — merge blocked`. Pre-existing: the same workflow is `failure` on `origin/main` = `e8b8319` (run 31470264566), and was `success` on the prior main commit `32dfda83`. `git diff --name-only origin/main...HEAD -- .cdd/unreleased/126/` is **empty** — #127 did not touch cycle 126. | **B** (`ci-status`) | contract |
| F2 | `Makefile:16-17` claims a structural closure the code does not deliver: *"EVERY IR under examples/, discovered … so a new example cannot be added without also being gated."* The discovery is `find examples -name '*.ir.json'`, so closure holds only for files matching that glob. An IR under `examples/` named `*.json` is silently ungated. | β's probe, same non-conforming fixture, two names: `examples/naming/ir/naming.ir.json` → `make vet-ir` **exit 2** (gated); `examples/naming/ir/naming.json` → `make vet-ir` **exit 0** (**not** gated), while `cue vet` on that same file fails when invoked directly. `README.md` states the bound correctly ("every `*.ir.json` under `examples/`"); it is the Makefile comment that overpromises. | **A** | judgment / honest-claim |

### Notes on the findings

**F1 is not α's to fix, and β says so plainly.** α's implementation is clean;
the pinned contract confines α to `research/cm-language/runtime/coh-min/**` and
`.github/workflows/coh-min.yml`, and the missing files live in
`.cdd/unreleased/126/`. Close-outs are β/γ-owned artifacts, not α's. β raises it
because rule 3.10 is binding and because absorbing a red pre-merge gate silently
is precisely the false-closure failure this review skill exists to prevent — the
repo's own gate says merge is blocked, and a verdict of APPROVED would assert
otherwise. Recovery is one of:

- **(a) preferred** — land `.cdd/unreleased/126/alpha-closeout.md` and
  `.cdd/unreleased/126/beta-closeout.md` (γ/β work for cycle 126), after which
  the gate goes green for #127 with no change to α's code; or
- **(b)** δ confirms `CDD Artifact Validate` is *not* a required check for this
  merge and records that decision, at which point F1 is discharged as
  not-applicable rather than fixed.

Either path clears F1 without touching a line of #127's implementation. β flags
for δ that path (a) has value beyond this cycle: the gate is currently red on
`main` itself, so it blocks *every* subsequent merge until cycle 126 is closed
out. #127 is where that debt happened to surface, not where it originated.

**F2 is a one-line comment fix** (reword to name the glob, as the README already
does) or, if the stronger claim is wanted, widen the discovery. β rates it A, and
records explicitly: **F2 alone would not have produced REQUEST CHANGES.** It is
raised under β Rule 6b (name-overpromise) and review §2.1.1a (structural-closure
claims must be checked against every input source) so the claim and the code
agree, because the next case will read that comment as a guarantee.

## Regressions Required (D-level only)

None — no D-severity finding was raised.

## Notes

**Implementation-contract conformance (β Rule 7) — all 7 axes verified by β:**

| Axis | Pin | β's verification |
|---|---|---|
| Language | OCaml stdlib-only; `json.ml`/`sha256.ml` byte-identical to `../ascent-0/lib/` | `cmp` reports **IDENTICAL** for both; sha256 of each matches its ascent-0 counterpart. Grep for `Unix.` / `Str.` / yojson / ppx across `lib bin test dune-project` returns **only comments naming the prohibition**, zero code. New `lib/ir.ml` is stdlib-only. Confirmed by β's own build: the flat `ocamlopt` line links no library. |
| CLI integration target | existing `coh_min` exe and flags unchanged | `run --ir --target [--out]` unchanged; no new flag; not `coh cm`. Only the exit-code doc comment changed, and it changed to become *true*. |
| Package scoping | `runtime/coh-min/**` + `.github/workflows/coh-min.yml` | `git diff --name-only origin/main...HEAD` filtered against the permitted set returns **nothing outside** it (the only other paths are γ's own `.cdd/unreleased/127/`). |
| Existing-binary disposition | additive/repair only; do not edit `schema.cue` | `schema.cue` **absent from the diff** (0 hits). `contracts/receipt.cue` unchanged. No other binary or example touched. |
| Runtime dependencies | none beyond stdlib; `cue` only in Makefile/CI gates | β built and ran both binaries with the bare compiler. `cue` appears only in `vet-ir` / `vet` recipes and the workflow's fetch step. |
| JSON/wire contract | canonical JSON unchanged; receipt `format` unchanged; IR keeps `tsc-cm-ir/0.1` | Both receipts still vet against `#MeasurementReceipt`; `format: tsc-measurement-receipt/0.1` unchanged; `format: "tsc-cm-ir/0.1"` retained **and now enforced** by `Ir.format_pin`, which β exercised (a wrong `format` is refused). |
| Backward-compat | all #126 ACs hold; receipt shape does not regress | AC3 above, re-run by β; plus the 14 retained #126 assertions inside the 32. `plan_digest`'s *value* moved because `source_digest` feeds the plan and the intent file was renamed — β confirms no AC pins that value and that the new value is internally consistent. |

**Honest-claim verification (rule 3.13).** β spot-checked α's self-coherence
against the code and the artifacts rather than trusting it:

- *(a) Reproducibility* — every measurement α quotes was reproduced by β from
  this commit: the 32-check count, the `cue vet` exit codes, the one-line IR
  diff, the missing-block matrix, the vocabulary-refusal message, the escape
  denial with zero stdout bytes. **No discrepancy found.** Where β went further
  than α (AC4 row 3, AC5 at the CLI for all 8 blocks, the `*.json` naming probe)
  the extra evidence *strengthened* α's conclusions in two cases and produced F2
  in the third.
- *(b) Source-of-truth alignment* — the missing-block matrix is rendered in three
  places (`lib/ir.ml:31-33`, `README.md` §Two mechanisms, self-coherence
  §Finding). All three agree with each other and with β's independent
  measurement.
- *(c) Wiring claims* — α claims `lib/ir.ml` is not dead code. β grep-confirmed
  each call: `Runner.run` → `Ir.of_json`; `Runner.evaluate` → `Ir.declares` and
  `Ir.undeclared_class_error`; `Runner.invoke` → `Ir.field`; `link`/`execute`
  consume `Ir.t`/`Ir.step`; `Ir.canonical_blocks` drives the AC5 table. The
  claim holds.
- *(d) Gap claims* — the §Gap reproduction (that both IRs failed `cue vet`
  before this cycle) is consistent with the schema and with what the repaired
  IRs now contain.

**Observation (not a finding).** `gate: vet-ir vet` relies on prerequisite order,
which `make` honours only for a serial build; under `make -j` the two could
interleave, so `vet` might execute the runtime before `vet-ir` finishes. The
Makefile comment already caveats this correctly ("make honours prerequisite order
for a serial build") and CI invokes `make gate` without `-j`, so there is no
untrue claim and no live exposure. Recorded for the next reader only.

**Observation (not a finding, pre-existing).** `Runner.drive` removes completed
steps with `List.filter (fun x -> x.step.Ir.step_id <> s.step.Ir.step_id)`, so an
IR with two steps sharing an `id` would drop both. β traced the consequence: the
run degrades to `INCOMPLETE` with `complete=false` rather than producing a wrong
result, so it fails in the safe direction. The behaviour is unchanged from #126
and out of #127's scope; noted so it is not rediscovered as new.

**What β is closing off.** Within the seven ACs and the seven pinned contract
axes, β found no unmet criterion and no contract violation. The two findings
above are the complete set: F1 is inherited merge-gate debt with a γ/δ-side
recovery, F2 is a comment that overstates a glob. β found no defect in
`lib/ir.ml`, `lib/runner.ml`, the IRs, the vocabulary gate, the CI wiring or the
rename.

**Handoff to δ.** The single most transferable result of this cycle is the
measured `cue vet` matrix: `#NormalizedCMIR` admits an IR missing `format`,
`procedure` or `result_contract`. β independently confirms it. The project should
stop treating "vets against `#NormalizedCMIR`" as equivalent to "is a runnable CM
IR" until that schema is tightened.
