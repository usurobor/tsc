# self-coherence — cycle/127

**Issue:** usurobor/tsc#127 — *coh-min: consume schema-compliant NormalizedCMIR and enforce it in the gate (case 0)*
**Branch:** `cycle/127` · **Base:** `origin/main` = `e8b8319281cc5aea85ad9856a864000477faaa0d` (merge-base == main tip; branch is a fast-forward candidate)
**Implementation SHA:** `c3a2a37cb9b88131de3666010a1967682fe77256`
**Role:** α · **Mode:** bounded implementation on the cycle branch; no merge.

## §Gap

#126's runtime genuinely executed, but the artifact it executed was **not** the
project's canonical IR. `readme-present.ir.json` omitted `result_contract` and
`receipt_contract` entirely, so it was a private JSON shape only `coh-min`
understood — and nothing caught it, because coh-min's gate vetted only the
emitted *receipt*, never the *input*. δ's #126 contract said the IR was
hand-authored "exactly as the Ascent-0 IR is today"; the hand-authored half held,
the conforming half did not.

Reproduced before touching anything (the target this cycle closes):

```
$ cue vet ../ascent-0/ir/ascent0.ir.json ../../schema.cue -d '#NormalizedCMIR'
  exit=0                                                     # ascent-0 conforms

$ cue vet examples/readme-present/ir/readme-present.ir.json ../../schema.cue -d '#NormalizedCMIR'
receipt_contract.kind: incomplete value string:
    ../../schema.cue:685:9
  exit=1                                                     # coh-min does NOT

$ cue vet examples/readme-present/ir/readme-present.escape.ir.json ../../schema.cue -d '#NormalizedCMIR'
receipt_contract.kind: incomplete value string:
    ../../schema.cue:685:9
  exit=1                                                     # nor the negative fixture
```

The repair is not "fix one file": it is making the schema **mechanically
enforced**, at build time *and* at run time, so the next five step-kind cases
cannot drift the same way.

## §Environment and verification method

`dune` is not installable in this cell (γ-verified). Per the scaffold, every
local claim below was produced with a **flat `ocamlopt` 4.14.1 build** of
`lib/{sha256,json,provider,ir,runner}.ml` plus a driver and test file derived
from `bin/coh_min.ml` / `test/test_coh_min.ml` with the `Coh_min.` module prefix
stripped. `cue` is v0.9.2 at `/usr/local/bin/cue`. The canonical
`dune build` / `dune runtest` evidence is the CI run on the branch head.

The flat build is clean under `-w +a-4-70 -warn-error +a-4-70` (warnings 4
fragile-match and 70 missing-mli are disabled in dune's default set and match the
vendored ascent-0 pattern — the same bar β applied in #126):

```
$ ocamlopt -w +a-4-70 -warn-error +a-4-70 sha256.ml json.ml provider.ml ir.ml runner.ml driver.ml -o coh_min
  compile exit=0
```

## §Skills

| Tier | Skill | Loaded | Applied — where it shows in the diff |
|---|---|---|---|
| 1 | `.cdd/skills/cdd/alpha/SKILL.md` | yes | artifact order (tests+code+docs → self-coherence → pre-review); §2.3 peer enumeration; §2.4 harness audit (caught the YAML bug below); §3.6 implementation contract treated as binding pins |
| 2 | `eng/ocaml` | yes | §2.1 record fields disambiguated at definition (`Ir.step` / `Ir.t` share no field name, so no access site pays an annotation); §2.2 purity boundary (`ir.ml` is pure, no I/O); §2.3 `Result` for every expected failure; §2.4 resource discovery (`format` pin validated before anything depends on it); §3.4/§3.10 no silent fallback — `config` is `J.t option`, absent required fields are `Error`, never a default |
| 2 | `eng/write-functional` | yes | `let*` bind throughout `Ir.of_json`; no `ref`/`while` in lib code; `all` sequences results instead of accumulating in a mutable cell; pipeline `parse → validate → link → execute → evaluate → emit` |
| 2 | `eng/code` | yes | §1.3 errors embed context (every message carries its dotted path); §2.3 effects isolated; exit codes documented and now *true* (`bin/coh_min.ml`) |
| 2 | `eng/test` | yes | §2.1 invariant named before test; §2.3 strongest cheap proof (table-driven over the validator's own block list); §2.7 negative space mandatory; §2.12 derivation vs validation (the vocabulary gate is proved by *changing the IR*, not by asserting the runner's own constant) |

## §ACs

Per-AC oracles run against implementation SHA `c3a2a37`.

### AC1 — both IRs vet against `#NormalizedCMIR` (the negative fixture is not excused)

```
$ cue vet examples/readme-present/ir/readme-present.escape.ir.json ../../schema.cue -d "#NormalizedCMIR"
  exit=0
$ cue vet examples/readme-present/ir/readme-present.ir.json ../../schema.cue -d "#NormalizedCMIR"
  exit=0
```

Both IRs gained the canonical `result_contract` and `receipt_contract` blocks,
modelled on `ascent-0`'s (`kind` · `subcontracts` · `runtime_binding` · `emits` ·
prose `derivation`; `kind` · `reports` · `measure_only`) **without** copying
Ascent-specific fields that mean nothing for an ordinary CM (no oracle seal, no
model enumeration, no `heldout_*`). The escape IR now differs from the good one
in exactly one line, so it is a true negative fixture:

```
$ diff examples/readme-present/ir/readme-present.ir.json examples/readme-present/ir/readme-present.escape.ir.json
30c30
<                     "relative_path": "README.md"
---
>                     "relative_path": "../README.md"
```

**STATUS: PASS.**

### AC2 — `make vet-ir` over every IR under `examples/`; `make gate` depends on it; CI runs it; a non-conforming IR fails loudly

```
$ make vet-ir
vet-ir: examples/readme-present/ir/readme-present.escape.ir.json ... conforms
vet-ir: examples/readme-present/ir/readme-present.ir.json ... conforms
VET-IR PASSED: 2 IR(s) conform to #NormalizedCMIR.
  exit=0
```

The target list is **discovered**, not enumerated (`IRS := $(shell find examples
-name '*.ir.json' | sort)`), so a new example cannot be added without also being
gated; and an empty list is an explicit failure, not a vacuous pass
(`test -n "$(IRS)" || { echo "FAIL(vet-ir): … would pass vacuously"; exit 1; }`).
`make gate` is now `gate: vet-ir vet`. CI runs `make vet-ir` as its own step
(`.github/workflows/coh-min.yml`) so a schema violation is visible in the job
summary without reading the gate log.

**Proof the gate bites** — three deliberate breaks, each reverted:

*(a) delete `receipt_contract` (the exact #126 defect):*
```
$ make vet-ir
vet-ir: …/readme-present.escape.ir.json ... conforms
vet-ir: …/readme-present.ir.json ... receipt_contract.kind: incomplete value string:
    ../../schema.cue:685:9
FAIL(vet-ir): examples/readme-present/ir/readme-present.ir.json does not conform to #NormalizedCMIR
make: *** [Makefile:44: vet-ir] Error 1
  exit=2
```

*(b) add a stray top-level field (the schema is closed):*
```
$ make vet-ir
vet-ir: …/readme-present.ir.json ... private_extension: field not allowed:
    ./examples/readme-present/ir/readme-present.ir.json:64:5
    ../../schema.cue:667:18
FAIL(vet-ir): … does not conform to #NormalizedCMIR
make: *** [Makefile:44: vet-ir] Error 1
  exit=2
```

*(c) break only the escape (negative) IR* — see §Finding below; this case is the
one that exposed a real limit of `cue vet`, and is why AC5's runtime enforcement
is load-bearing rather than redundant.

After restore: `make vet-ir` → exit 0, and the two IRs diff by one line (above).

**STATUS: PASS.**

### AC3 — no regression (all of #126's ACs continue to hold)

```
$ coh_min run --ir …/readme-present.ir.json --target …/fixtures/present --out r.present.json
coh_min: cm=example.readme-present target=…/fixtures/present result_class=README_PRESENT (computed=true complete=true)
  exit=0
$ coh_min run --ir …/readme-present.ir.json --target …/fixtures/absent  --out r.absent.json
coh_min: cm=example.readme-present target=…/fixtures/absent  result_class=README_ABSENT  (computed=true complete=true)
  exit=0
$ cmp -s r.present.json r.absent.json  →  receipts differ: ok
$ cue vet r.present.json …/contracts/receipt.cue -d '#MeasurementReceipt'   exit=0
$ cue vet r.absent.json  …/contracts/receipt.cue -d '#MeasurementReceipt'   exit=0
```

Escape IR still denied fail-closed (exit 1, **zero** bytes on stdout — no receipt):
```
$ coh_min run --ir …/readme-present.escape.ir.json --target …/fixtures/present
  exit=1 · stdout bytes: 0
  stderr: ✗ coh_min: relative_path "../README.md" contains a ".." segment and could escape the subject root
```

Honest-claim spot-checks (the same ones β ran in #126, re-run because the IR
changed underneath them):

- `source_digest` is genuine, not fabricated — it is the SHA-256 of the authored
  intent document it names:
  `sha256sum readme-present.intent.md` → `939abe2e69c865e77e2ff25395112db6b724c5c601ae26804d9ce8e154191667`,
  and the IR carries `"source_digest": "sha256:939abe2e…1667"`.
- `plan_digest` reproduces independently — re-rendering the receipt's own
  embedded `sandbox_execution_plan` under canonical rules (sorted keys, 2-space,
  LF, trailing newline) outside OCaml gives
  `sha256:a00e5306c5111c5f97f8ce3849e23db59f3b9645bdfde6cbbbf75ae5a0746c9c`,
  byte-equal to the receipt's `plan_digest`.
- Evidence tracks the real disk: present → `exists=True size_bytes=100`, absent →
  `exists=False size_bytes=-1`; `wc -c` of the fixture README is **100**.
- Receipt shape unchanged: `format: tsc-measurement-receipt/0.1`, same keys,
  same `#MeasurementReceipt` contract, unedited. (`plan_digest`'s *value* moved,
  because `source_digest` is part of the plan and the intent document was
  renamed; no AC pins that value, and it is still self-consistent and externally
  reproducible.)

**STATUS: PASS.**

### AC4 — the result-class vocabulary is read from the IR

The IR declares its vocabulary in `result_contract.result_classes`
(`["README_PRESENT", "README_ABSENT", "INCOMPLETE"]`). `Ir.of_json` **requires**
that list, `Ir.declares` gates the derived class against it, and `Runner.evaluate`
returns `Error` — no receipt — when the class is not declared. The derivation
stays in OCaml (`Runner.classify`), exactly as the AC's parenthetical allows and
as ascent-0's `derivation` field is still prose.

The discriminating experiment (test skill §2.12 — prove the derivation, not a
coincidence): hold subject, provider and derivation fixed, change **only** the
IR's declared set. A runner with the vocabulary hardcoded would emit the same
receipt either way.

| IR's `result_classes` | run against `fixtures/present` |
|---|---|
| `["README_PRESENT","README_ABSENT","INCOMPLETE"]` | receipt, `result_class: README_PRESENT` |
| `["PRESENT","ABSENT","INCOMPLETE"]` | **fails closed, no receipt** |

and the refusal names the offending class and the field, so an operator can act:

```
result_class "README_PRESENT" is not declared in the IR's result_contract.result_classes
["PRESENT", "ABSENT", "INCOMPLETE"]; the runtime refuses to emit a receipt carrying a
class the CM does not declare
```

`INCOMPLETE` is gated by the same rule, not special-cased: an IR carrying a step
whose `reads` surface nothing produces drives the derivation to `INCOMPLETE`,
which is emitted only when declared —

| IR | result |
|---|---|
| unrun step, `INCOMPLETE` declared | receipt, `result_class: INCOMPLETE`, `complete=false` |
| unrun step, `INCOMPLETE` **not** declared | fails closed, no receipt |

All four rows are pinned as regression tests. **STATUS: PASS.**

### AC5 — an IR missing a required canonical block fails closed

At the CLI (exit 1, no receipt, clean `IR error`-class message):

```
$ coh_min run --ir no-result-contract.ir.json --target …/fixtures/present
  exit=1 · stdout bytes: 0
  stderr: ✗ coh_min: IR error: result_contract is missing
```

Pinned by a **table-driven** regression that iterates `Ir.canonical_blocks` — the
same list the validator itself uses — so a block added to the contract cannot
acquire an untested regression. All eight blocks, plus a wrong `format` literal,
three nested required fields (`procedure.steps`,
`input_contract.required_artifacts`, `result_contract.result_classes`) and a step
missing `produces`, each assert `Error` + the `IR error` prefix + no receipt,
with an explicit `| exception _ -> false` arm so an escaping exception fails the
test rather than passing it (β #126 F1's bug class).

**STATUS: PASS.**

### §Finding — `cue vet` and the runtime are complementary, not redundant

While proving the gate bites I broke the *escape* IR by deleting its
`result_contract` and `make vet-ir` **passed**. That is not a bug in the gate: it
is a property of CUE unification. A schema field whose value is already concrete
(`format: "tsc-cm-ir/0.1"`) unifies to that literal when the data omits it, and
an open struct or list (`procedure`, `result_contract`) is complete as `{}`/`[]`.
Only fields that are *incomplete* when absent (`cm_id: string`, …) fail.

Measured, deleting one canonical block at a time from the shipped IR
(cue v0.9.2, `-d '#NormalizedCMIR'`):

| Missing block | `cue vet` | the runtime |
|---|---|---|
| `format`, `procedure`, `result_contract` | **PASSES** | fails closed |
| `cm_id`, `cm_version`, `source_digest`, `input_contract`, `receipt_contract` | fails | fails closed |

So `cue vet` alone would let an IR with **no procedure and no result_contract**
reach the runtime — 3 of 8 cases uncaught — while the runtime refuses 8 of 8.
This is exactly why AC5's runtime enforcement is load-bearing and not a
re-statement of AC2. The division is now explicit in code and docs: **the schema
owns exactness** (closed top-level field set, shape of every block present), **the
runtime owns presence** and fail-closed consumption of the fields it reads.

The other half of the repair — tightening `#NormalizedCMIR` so absence and
emptiness are distinguishable — is deliberately **out of scope** (issue §Scope
excludes tightening the schema's run-side stub; the contract forbids editing
`schema.cue`). Recorded in §Debt for δ's triage.

### AC6 — `dune runtest` passes with the new regressions added to the existing suite

Local proxy (flat build; canonical `dune runtest` runs in CI). Assertion count
taken from the runner's own output, not enumerated by hand:

```
$ ./test_flat
  exit=0
  ok lines:   32
  FAIL lines: 0
  all checks passed
```

**14 → 32 checks.** The 14 pre-existing #126 assertions are retained verbatim in
meaning (confine ×8, present/absent/differ, escape fail-closed, and β's F1
malformed-number / truncated-`\u` pair); 18 are new (8 canonical-block omissions,
wrong `format`, 3 nested required fields, step missing `produces`, and 5
vocabulary-gate rows).

The suite's IR fixtures were rebuilt as JSON **values** rather than a printf'd
string, so each negative fixture differs from the canonical one in exactly one
field (`List.remove_assoc` / one swapped vocabulary). A negative fixture retyped
by hand as a whole string proves much less.

**STATUS: PASS** locally; canonical `dune runtest` pending CI on branch head.

### AC7 — `readme-present.cm` no longer implies a compile path that does not exist

Chose the **rename** limb. The other limb (express it in the real surface
grammar) is not available without building the deferred compiler: `LANGUAGE.md`
§2 dispatches on the header's output type into exactly three program forms —
`-> InstrumentAssessment`, `-> AspectReceipt`, `-> CompositeReceipt` — and
`example.readme-present` is an ordinary CM emitting a
`tsc-measurement-receipt/0.1` `MeasurementReceipt`, which is none of the three.
Writing it in the grammar would mean adding a fourth form to `cm_surface.ml`,
i.e. exactly the surface compiler the issue scopes **out**.

Premise confirmed independently — `cmc` built flat from
`surface/{lib/cm_surface.ml,bin/main.ml}` rejects the #126 file:

```
$ ./cmc readme-present.cm
cmc: line 1: unexpected character '\226'
  exit=2
```

(The scaffold predicted `expected "cm", got identifier "methodology"`. Both are
rejections; mine trips one token earlier — the lexer treats `#` as the comment
marker, so the file's `//` comment is not a comment and the em-dash in it is the
first illegal byte. Recorded as observed rather than as predicted.)

`readme-present.cm` → **`readme-present.intent.md`** (`git mv`, history
preserved). Its header states, first line: *"The authoritative executable
artifact for this CM is `ir/readme-present.ir.json`"*, that the file is a prose
note, that nothing compiles or reads it, and why the real grammar cannot express
it. The intent sketch is fenced as `text` and labelled *not a program in any
implemented grammar; do not feed it to `cmc`*.

No file that a reader or a `*.cm` glob could mistake for compilable source
remains:

```
$ ls examples/*/*.cm
  (none — no file can be mistaken for compilable source)
```

**STATUS: PASS.**

## §Peer and harness audit

Peer set for the rename = every reference to `readme-present.cm` in the repo:

| Site | Disposition |
|---|---|
| `examples/readme-present/readme-present.cm` | renamed (`git mv`) |
| IR `source_digest` (both IRs) | recomputed against the renamed file; verified equal to `sha256sum` |
| `README.md` §Honest scope, §Module layout, §Build and run | updated |
| `lib/runner.ml` comment ("the `.cm`'s `decide` block") | reworded — no longer claims a `.cm` exists |
| `.cdd/unreleased/126/*` (β review, α self-coherence), `.cdd/unreleased/127/*` (issue, scaffold) | **exempt** — frozen historical records of prior/current cycle state; rewriting them would falsify the record |
| `dune-project` | no change needed — it names the `cm_id` `example.readme-present`, not the file |

Harness audit (schema-bearing change → audit non-OCaml writers):

- **Makefile** — new `vet-ir`; `gate` now depends on it; target list discovered
  by `find`, empty list fails loudly.
- **YAML workflow** — audited by parsing it, not by reading it. `yaml.safe_load`
  showed the step name had been silently truncated to `"Vet IRs against"`: an
  unquoted `#` starts a YAML comment. Fixed by quoting, with a comment naming
  the trap; re-parsed to confirm all 9 steps and the full name. **This is the
  α-skill §2.4 audit earning its place — reading the file would not have caught
  it.**
- **Test fixtures** — the suite is a second writer of the IR shape; rebuilt to
  mirror the shipped IR's canonical blocks (see §Debt for the residual).
- **`contracts/receipt.cue`** — unchanged and re-verified: both receipts still
  vet, and `#Result.result_class` still pins the same three classes, so the
  IR-declared vocabulary and the receipt contract agree.

## §Implementation contract (δ's 7 axes)

| Axis | Pin | Conformance |
|---|---|---|
| Language | OCaml stdlib-only; `json.ml`/`sha256.ml` byte-identical to `../ascent-0/lib/` | `diff` vs ascent-0: **json.ml IDENTICAL, sha256.ml IDENTICAL** (neither opened). Grep for `Unix.`/`Str.`/yojson/ppx across coh-min: hits are *comments naming the prohibition* only, no code. New `lib/ir.ml` is stdlib-only. |
| CLI integration target | existing `coh_min` exe and flags unchanged | `run --ir --target [--out]` unchanged; no new flag, no `coh cm`. Only the exit-code *doc comment* changed, to stay true (β #126 F1's lesson). |
| Package scoping | confined to `runtime/coh-min/**` + `.github/workflows/coh-min.yml` | `git diff --name-status`: 12 files, all under those two paths (+ γ's own `.cdd/unreleased/127/` artifacts). |
| Existing-binary disposition | additive/repair only; **do not edit `schema.cue`** | `schema.cue` untouched (verified: not in the diff). No other binary, schema or example touched. |
| Runtime dependencies | none beyond stdlib; `cue` only in Makefile/CI gates | build and tests need only the compiler; `cue` appears only in `vet-ir`/`vet` recipes and the workflow. |
| JSON/wire contract | canonical JSON unchanged; receipt `format` unchanged; IR keeps `tsc-cm-ir/0.1` | receipt keys/shape unchanged and re-vetted; `format: "tsc-cm-ir/0.1"` retained *and now enforced*. |
| Backward-compat | all #126 ACs hold; receipt's observable shape does not regress | AC3 above, plus the 14 retained assertions. |

## §Self-check — did α push ambiguity onto β?

- **Every claim above is a transcript I ran**, not a description of what should
  happen. Where my result differed from the scaffold's prediction (AC7's `cmc`
  error), I recorded what I observed and said why it differs.
- **The one judgment call β should scrutinize** is the `result_classes` field
  name and placement. `#NormalizedCMIR` leaves `result_contract` open, so the
  vocabulary had to be *invented* somewhere; ascent-0 has no equivalent field
  (its classes appear only in prose `derivation` and per-step `failure`). AC4
  mandates that the vocabulary live in `result_contract`, so this is mandated
  invention, not improvisation — but the *name* is mine.
- **Deliberate strictness beyond the schema**: the runtime requires
  `result_contract.result_classes`, which `cue vet` does not. A vetted IR is
  therefore not automatically runnable. I chose this over defaulting the
  vocabulary, because a default would silently restore the class of drift #127
  exists to close. Stated in `ir.ml`, the README, and here.
- **Scope discipline**: I did not tighten `schema.cue` even though §Finding shows
  it would close 3 of 8 missing-block cases at vet time — the issue scopes it out
  and the contract forbids editing it. Recorded as debt instead of acted on.
- **No claim of universal closure**: the runner validates the canonical block set
  and the fields it consumes. It does **not** re-implement the schema, and I have
  not claimed it does.

## §Debt (explicit)

1. **`#NormalizedCMIR` cannot distinguish an absent block from an empty one** for
   `format`, `procedure`, `result_contract` (§Finding). Mitigated at run time by
   `Ir.of_json`; the schema-side repair is out of this slice's scope. This is the
   highest-value follow-up in the finding set — it is the same defect *class*
   #127 closes, one layer up.
2. **The test suite's IR fixtures are a second writer of the IR shape.** They are
   built in OCaml and cannot be `cue vet`-ed from inside a stdlib-only test, so
   they could drift from `examples/`'s canonical IRs. Bounded: the shipped IRs
   are gated by `make vet-ir` against the real schema, and the fixtures mirror
   their block structure. A test that vets its own generated fixtures would need
   either a `cue` subprocess (forbidden — no Unix) or a Makefile step that
   renders them; neither is justified at this size.
3. **The result-class derivation is still OCaml and still CM-specific**
   (`Runner.classify` keys on `cm_id = "example.readme-present"`). AC4 explicitly
   allows this; it is named in the IR's `derivation` prose, in `runner.ml`, and
   in README §Honest scope. Lowering derivation into data is the natural next
   case.
4. **`dune build` / `dune runtest` were not run locally** — dune is not
   installable in this cell (γ-verified). Local evidence is a flat `ocamlopt`
   4.14.1 build; canonical evidence is CI on branch head, which β should confirm
   green before merge.
5. **Commit identity** follows the dispatch's explicit instruction
   (`usurobor <usurobor@gmail.com>`, no tool/model trailers) rather than the
   α-skill §2.6 row-14 pattern `alpha@{project}.cdd.cnos`. Flagged so the
   divergence is a recorded decision, not drift.

## §CDD Trace

| Step | Artifact | State |
|---|---|---|
| 1 Gap | issue #127 + §Gap above (failing `cue vet` reproduced first) | done |
| 2 Branch | `cycle/127` (γ-created; α verified base == `origin/main` tip, no rebase needed) | done |
| 3 Design | **not required** — the issue's 7-axis contract and 7 ACs fully determine the shape; no new architecture, one new pure module inside an existing library | justified |
| 4 Plan | **not required** — linear: canonicalize IRs → typed validator → vocabulary gate → gate wiring → rename → docs | justified |
| 5 Tests | `test/test_coh_min.ml` 14 → 32 checks (table-driven block omissions; vocabulary-gate discriminating pair) | done |
| 6 Code | `lib/ir.ml` (new), `lib/runner.ml`, `lib/dune`, `bin/coh_min.ml`, both `*.ir.json`, `Makefile`, `.github/workflows/coh-min.yml` | done |
| 7 Docs | `README.md` (§The IR is canonical, §Two mechanisms, §Result-class vocabulary, §Honest scope, targets), `readme-present.intent.md` (new, replaces the `.cm`) | done |

**Artifact enumeration matches diff** (α gate row 11) — every file in
`git diff --name-status origin/main..HEAD` is named in step 6 or 7 above:
`.github/workflows/coh-min.yml`, `Makefile`, `README.md`, `bin/coh_min.ml`,
`ir/readme-present.escape.ir.json`, `ir/readme-present.ir.json`,
`readme-present.cm` (D) → `readme-present.intent.md` (A), `lib/dune`,
`lib/ir.ml` (A), `lib/runner.ml`, `test/test_coh_min.ml`, plus this file and
γ's `gamma-scaffold.md` / `issue-127.md`.

**Caller-path trace for new modules** (α gate row 12) — `lib/ir.ml` is not dead
code: `Runner.run` calls `Ir.of_json` (`runner.ml`, the driver's first stage),
`Runner.evaluate` calls `Ir.declares` and `Ir.undeclared_class_error`,
`Runner.invoke` calls `Ir.field`, `Runner.link`/`execute` consume `Ir.t`/`Ir.step`
fields, and `Ir.canonical_blocks` drives the AC5 regression table. Every exported
value has a non-test caller except `canonical_blocks`, which is deliberately
consumed by the test so the required set and its table cannot drift.

## §Review-readiness | round 1

- **Base:** `origin/main` = `e8b8319281cc5aea85ad9856a864000477faaa0d`, observed
  after `git fetch origin main` at readiness time; merge-base == main tip, so the
  cycle branch has **not** drifted behind main and no rebase was needed.
- **Implementation SHA:** `c3a2a37cb9b88131de3666010a1967682fe77256`
  (self-coherence commits follow it; review head is branch HEAD).
- **γ artifact:** `γ-artifact at canonical §5.1 path` —
  `.cdd/unreleased/127/gamma-scaffold.md` present on `origin/cycle/127`.
- **Tests:** 32/32 checks, exit 0 (flat `ocamlopt` proxy; count from runner
  output).
- **Branch CI:** not observable from this cell — **β should confirm the `coh-min`
  workflow is green on branch head before merge.** The workflow gained one step
  (`make vet-ir`) whose local equivalent passes here.
- **Every AC has evidence** (§ACs, AC1–AC7 all PASS); **known debt is explicit**
  (§Debt, 5 items); **schema/shape audit** and **harness audit** completed
  (§Peer and harness audit).

**Ready for β.**

---

# Round 2 — β round-1 findings

**Round:** 2 · **Reviewed at:** `bb785ff` · **β verdict:** REQUEST CHANGES (F1 `ci-status`, F2 honest-claim)

β verified all 7 ACs PASS and all 7 contract axes conforming, and independently
reproduced the §Finding above. Two findings; one is mine.

| # | Finding | Owner | Disposition |
|---|---|---|---|
| F1 | `CDD Artifact Validate` red on the review SHA — cycle 126's missing close-outs | **not α** | Untouched. Pre-exists on `origin/main`; `.cdd/unreleased/126/` is outside #127's pinned scope and outside α's ownership. β states it is δ/γ/β work and is being repaired on a separate branch. `git diff --name-only origin/main...HEAD -- .cdd/unreleased/126/` is empty, before and after this round. |
| F2 | `Makefile:16-17` claimed a closure the code did not deliver | **α** | Fixed — below. |

## F2 — the closure claim now holds, mechanically

**The defect.** The comment said *"EVERY IR under examples/, discovered … so a new
example cannot be added without also being gated"*, but discovery was
`find examples -name '*.ir.json'`. Closure held only for that glob. Reproduced
before fixing, with β's own probe — one file, two names:

```
$ ls examples/naming/ir/            # non-conforming IR (receipt_contract deleted)
naming.ir.json
$ make vet-ir   → exit 2   (gated)

$ mv …/naming.ir.json …/naming.json # THE SAME BYTES, renamed
$ make vet-ir   → exit 0   (silently skipped — F2 confirmed)
$ cue vet examples/naming/ir/naming.json ../../schema.cue -d '#NormalizedCMIR'
receipt_contract.kind: incomplete value string   → exit 1
```

**The limb chosen: widen discovery**, rather than shrink the claim. Shrinking
would have been honest but would have left the naming convention load-bearing —
and a gate that a rename defeats is exactly the drift class #127 exists to close.
Discovery is now:

- **IR** — any `*.json` inside an `ir/` directory, **or** any `*.ir.json`
  anywhere under `examples/` (`$(sort)` unions and de-duplicates the two finds);
- **Subject data** — anything under `fixtures/`, deliberately excluded: a subject
  repository may legitimately contain JSON that is not a methodology, and
  vetting a `package.json` would be the false failure β warned about;
- **Unclassified** — any other `*.json`, which `vet-ir` now **refuses** rather
  than skipping, naming the file and both conventions.

The third class is what makes the claim true rather than merely wider: a `*.json`
cannot be added under `examples/` without being either gated or explicitly
classified.

**Demonstration — all four classes, each reverted after:**

| # | Probe | `make vet-ir` |
|---|---|---|
| 1 | β's counterexample, `examples/naming/ir/naming.json` (non-conforming) | **exit 2** — `FAIL(vet-ir): examples/naming/ir/naming.json does not conform to #NormalizedCMIR` — **now gated under the name that previously escaped** |
| 2 | non-conforming IR named `*.ir.json` but *outside* an `ir/` dir (`examples/loose.ir.json`) | **exit 2** — the union covers both conventions |
| 3 | subject data `examples/readme-present/fixtures/present/package.json` | **exit 0** — ignored, no false failure |
| 4 | unclassified `examples/stray.json` | **exit 2** — `FAIL(vet-ir): JSON under examples/ that is neither an IR nor subject data: examples/stray.json` + both conventions named |

Baseline after every probe was reverted: `VET-IR PASSED: 2 IR(s) conform to
#NormalizedCMIR.`, exit 0. `git status --porcelain` shows only `Makefile` and
`README.md` modified — no probe artifact survives.

**Peer enumeration for the claim (α §2.3 intra-doc repetition).** The overclaimed
sentence appeared at **three** sites, not the one β named. β noted `README.md:37`
stated the bound correctly, but `README.md:42` carried the same *"cannot be added
without also being gated"* sentence — the #266 F3-bis pattern (fixing only the
named site leaves a sibling). All live sites reconciled:

| Site | Disposition |
|---|---|
| `Makefile:15-17` (β's named site) | rewritten: states the three classes exactly, and names the F2 regression it closes |
| `README.md:37-43` | rewritten as the three-class table; both the bound and the closure sentence now match the code |
| `.cdd/unreleased/127/self-coherence.md` §ACs AC2 (round-1 text) | **left intact as the round-1 record** — that sentence *is* the overclaim F2 names. It is superseded by this section, not rewritten; falsifying the round-1 record would hide the finding. |

`grep -n "cannot be added"` over the slice now returns only this round-2 entry
and the superseded round-1 line, both correctly framed.

## Re-verification after the F2 fix

Nothing outside `Makefile` and `README.md` changed, but the full local suite was
re-run rather than assumed:

```
flat ocamlopt build (4.14.1)  → exit 0
test suite                    → 32 ok, 0 FAIL, exit 0
make vet-ir                   → VET-IR PASSED: 2 IR(s) conform, exit 0
cue vet readme-present.ir.json        -d '#NormalizedCMIR' → exit 0
cue vet readme-present.escape.ir.json -d '#NormalizedCMIR' → exit 0
present fixture → README_PRESENT (computed=true complete=true), exit 0
absent  fixture → README_ABSENT  (computed=true complete=true), exit 0
receipts differ → ok
cue vet both receipts -d '#MeasurementReceipt' → exit 0, exit 0
escape IR → exit 1, stdout 0 bytes, "✗ coh_min: relative_path "../README.md" contains a ".." segment…"
```

No OCaml source changed this round, so `lib/json.ml` and `lib/sha256.ml` remain
byte-identical to `../ascent-0/lib/`, and `schema.cue` remains untouched.

## §Debt update

Debt item 1 (`#NormalizedCMIR` cannot distinguish an absent block from an empty
one) is unchanged and still out of scope. No new debt from this round. Debt item
2 (test fixtures as a second writer of the IR shape) is unaffected — the
fixtures live in OCaml, not under `examples/`, so the new classification does not
reach them.

## §Self-check — round 2

F2 is the **same defect class as my round-1 F1 in cycle 126**: a comment claiming
more than the code delivered. Twice now the code was correct and the prose around
it was not, and both times β found it rather than my own pre-review gate. The
gate rows I ran check that *evidence exists for each AC*; neither round had a row
that re-reads each **comment** as a claim and asks what would falsify it. That is
the α-side pattern for my close-out — not a fix I should improvise into a skill
here.

## §Review-readiness | round 2

- **Base:** `origin/main` = `e8b8319281cc5aea85ad9856a864000477faaa0d`, re-checked
  at readiness time; merge-base still equals main tip, no rebase needed.
- **Fix SHA:** see branch HEAD; round-2 change is `Makefile` + `README.md` only.
- **Tests:** 32/32, exit 0 (flat proxy; count from runner output).
- **F1:** deliberately untouched, per β's own note and the pinned scope. β should
  confirm it is discharged via path (a) or (b) before merge — it is not α's to
  clear and no α-side change can clear it.
- **F2:** fixed and demonstrated in four probes above.

**Ready for β re-review.**
