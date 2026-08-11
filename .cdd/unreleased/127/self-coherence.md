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
