# self-coherence — cycle/129 (α)

## §Gap

**Issue:** usurobor/tsc#129 — *coh-min M1a: generic CM execution — a second
methodology runs as data, results derived from the IR*
**Branch:** `cycle/129`, rebased onto `origin/main` `c8ffc2a`
**Design authority:** `.cdd/unreleased/129/CM-EXECUTION-MODEL.pinned-61ba4d2.md`
**Mode:** implementation (design settled upstream; this cycle is execution)

`coh-min` executed exactly **one** methodology. `Runner.classify` compared the
CM's identity against one hard-coded string; the result rule was OCaml and only
the vocabulary was data; the graph was a single node. Adding a methodology meant
writing OCaml.

The gap closed here is that a methodology is now **data**. Two structurally
different ordinary CMs run through the same parser, linker, scheduler, result
evaluator and receipt writer, with no `cm_id` dispatch and no CM-specific
classifier. The commit that adds the second methodology touches no `.ml` file,
no Makefile rule and no CUE contract.

*(Round-2 correction, β F1: that last sentence is true of the commit but was
being read as an unconditional boundary claim. It holds for a methodology built
from the **capabilities and receipt family that already exist** — which covers
both shipped CMs and β's third. A methodology needing a new receipt extension
family, snapshot scheme, step kind or algebra operator does require OCaml, and
for most of those a CUE edit too. The README now carries the full table; see
§Round 2.)*

**Scope held:** FLAT. Every step terminates at a primitive provider. There is no
`invoke_cm`, no child `RunRequest`, no receipt-inside-receipt — and the step
kinds that would imply nesting are **refused**, not silently accepted.

### Commits

| SHA | What |
|---|---|
| `476909d` | the runtime: `Ir`/`Request`/`Linker`/`Exec`/`Rule`/`Receipt`, the `0.2` contracts, `fs.text-metrics`, `readme-present` migrated, 167 tests, the Makefile gate, CI |
| `f97d57e` | **the genericity demonstration** — `examples/repo-legibility/**` and nothing else |
| `41195a7` | the README rewrite (implementation SHA for review purposes: `41195a7`) |

## §Skills

- **Tier 1** — `CDD.md`, `.cdd/skills/cdd/alpha/SKILL.md`.
- **Tier 2/3** — the `eng/*` bundle named in the scaffold's load order
  (`eng/ocaml`, `eng/write-functional`, `eng/code`, `eng/test`, `eng/ux-cli`) is
  **not present in this cell**: `.cdd/skills/` contains only `cdd/`, `cds/` and
  `handoff/`, and there is no `SKILLS_ROOT` on disk. This is declared as known
  debt (§Debt D1). The constraints those skills encode were applied from the
  standard they set in `#126`/`#127` and from β's two prior reviews, which is
  the bar this diff was authored against: pure/total validators returning
  `result`, no `ref`/`while` in the executor, no exceptions on expected failure,
  effectful shells kept thin and separate from pure cores, negative fixtures
  differing in exactly one field, colour never load-bearing in CLI output.
- **Load order followed** for everything that does exist: α skill, issue,
  pinned design, `.cdd/unreleased/{126,127}/beta-review.md`.

## §ACs

Every criterion has its own executable oracle. Local verification is a flat
`ocamlopt -w +a-4-70 -warn-error +a-4-70` build of `lib/*.ml` plus a driver
derived from `bin/coh_min.ml` and a test derived from `test/test_coh_min.ml`
(`dune` is not installable in this cell — scaffold §Environment facts); the
canonical `dune build` / `dune runtest` run in CI. `cue` is v0.9.2.

Commands below are reproducible as:

```
make <target> DUNE=<shim> RUNNER=<flat-built coh_min>
```

`DUNE` and `RUNNER` are declared Makefile variables for exactly this reason; CI
overrides neither.

---

### AC1 — Genericity (the headline) · **PASS**

**(a) The methodology commit touches no `.ml` file.**

```
$ git show --stat --name-only --format= f97d57e -- '*.ml'
                                    (empty)
$ git show --stat --format= f97d57e | tail -1
 20 files changed, 2995 insertions(+)
```

All 20 are `*.json`, `*.tsv`, `*.md` or fixture content under
`examples/repo-legibility/`. No `.ml`, no `Makefile`, no `contracts/*.cue`, no
CI step.

**(b) No `cm_id`-keyed branch exists in the load/link/execute/evaluate/emit
path.** `make genericity` discovers the identities and the result vocabulary
*from the shipped IRs*, so a third methodology is covered the moment it is
added:

```
genericity: no CM identity or CM-specific classifier in lib/ or bin/
  example.readme-present           absent from lib/ and bin/
  example.repo-legibility          absent from lib/ and bin/
  let classify                     no classifier defined in lib/ or bin/
  INCOMPLETE                       absent from lib/ and bin/
  LEGIBLE                          absent from lib/ and bin/
  NO_ENTRY_DOC                     absent from lib/ and bin/
  README_ABSENT                    absent from lib/ and bin/
  README_PRESENT                   absent from lib/ and bin/
  SHALLOW                          absent from lib/ and bin/
GENERICITY PASSED: adding a methodology touches no .ml file.
```

The check is non-vacuous in both halves: it fails if **no** CM id or **no**
result class is discovered. It caught two real violations during authoring —
a module comment quoting `"example.readme-present"` and the env-var literal
`"NO_COLOR"` matching a naive class-shaped regex; the first was rewritten, the
second fixed by discovering the actual vocabulary instead of guessing its shape.

`Runner.classify` is **deleted**. The regression guard looks for a
*definition* (`^\s*(let|and)\s+classify\b`), so the modules stay free to explain
what was removed and why.

**(c) Both CMs run through the same binary.**

```
case: readme-present           present      README_PRESENT
case: readme-present           absent       README_ABSENT
case: repo-legibility          rich         LEGIBLE
case: repo-legibility          thin         SHALLOW
case: repo-legibility          unlicensed   SHALLOW
case: repo-legibility          bare         NO_ENTRY_DOC
case: repo-legibility          tight        INCOMPLETE
CASES PASSED across 2 methodolog(ies).
sensitivity: readme-present           2 receipt(s), 2 distinct ... ok
sensitivity: repo-legibility          5 receipt(s), 5 distinct ... ok
```

The Makefile enumerates no CM: examples are discovered by the presence of
`cases.tsv`, and every case row is data.

---

### AC2 — One new provider, stdlib-only · **PASS**

Exactly one capability was added: `fs.text-metrics` (`lib/provider.ml`),
alongside the pre-existing `fs.file-exists`. Both are mechanical, stdlib-only,
and confined to the subject root. `Provider.registry` has two rows; adding a row
is the only OCaml a new capability requires.

The boundary is stated in the README as its opening section:

> **Adding a *provider* is OCaml. Adding a *methodology* is not.**

and is re-stated in `lib/provider.ml`'s header and in both intent notes.

Stdlib-only is verified structurally: `lib/dune` declares no `(libraries …)`,
`bin/dune` and `test/dune` declare only `coh_min`, and the flat build links
nothing but the OCaml stdlib.

---

### AC3 — A real DAG, with required/optional ports · **PASS**

`example.repo-legibility` has **three** steps: `readme_locate` and
`license_locate` are independent (neither reads the other), and `readme_depth`
binds `readme_locate.path` — a declared output port of a peer.

**Lawful withholding.** `fs.file-exists` declares `path` withholdable and
publishes it only when the file exists. On the `bare` subject the step
**succeeds** and withholds:

```json
{ "order": 0, "step_id": "readme_locate", "status": "success",
  "provider": { "id": "coh-min.fs.file-exists", "digest": "sha256:adbd050b…" },
  "published": [ { "port": "present", "value": false,
                   "digest": "sha256:2ed27c14…" } ],
  "withheld": [ "path" ],
  "diagnostics": [] }
```

`withheld` means *lawful withholding only*: for a skipped, incomplete, refused
or failed step it is empty, because nothing was withheld — the check simply did
not establish anything, and `status` already says so.

**The principled skip, naming the unpublished port.**

```json
{ "order": 2, "step_id": "readme_depth", "status": "skipped",
  "provider": { "id": "coh-min.fs.text-metrics", "digest": "sha256:a49a8277…" },
  "published": [], "withheld": [], "diagnostics": [],
  "skipped_because": "required input \"target\" of step \"readme_depth\" binds
                      readme_locate.path, which step \"readme_locate\" did not
                      publish (step \"readme_locate\" ended success)" }
```

Nothing is fabricated. The receipt's `reports` records the consequence honestly
rather than as a defaulted zero:

```json
{ "ref": "readme_depth.line_count", "kind": "step_output",
  "available": false,
  "reason": "the producing step published no such fact in this run" }
```

**A success missing a REQUIRED output is rejected, not downgraded.** Pinned as a
unit test against `Exec.accept_success`:

```
ok   - a success missing a required output is rejected, not downgraded
ok   - an absent optional output is lawful withholding, recorded as withheld
ok   - a success omitting a declared required evidence predicate is rejected
```

**Both branches are exercised by fixtures** (`cases.tsv`): `rich`, `thin`,
`unlicensed` satisfy the dependency; `bare` cannot. A fifth case, `tight`,
reaches `INCOMPLETE` by a *different* route — a declared bound makes the
dependent checker `refused` rather than skipped — so the two ways a fact can be
unavailable are both covered.

The linker additionally refuses the inverse error, which is the one that would
otherwise produce baffling runtime failures:

```
✗ coh_min: link error: step "readme_locate" declares output "path" as required,
  but capability "fs.file-exists" may lawfully withhold it; declare it
  "required": false and let the dependent step skip, or bind a capability that
  promises it
```

**Scheduling independence** (design gate 2) is pinned by permuting the IR's step
order and comparing:

```
ok   - permuting the IR's step order does not change the result class
ok   - permuting the IR's step order does not change the published fact set
ok   - the trace records the ACTUAL order, which does differ
```

---

### AC4 — The result rule is data · **PASS**

Derivation comes from `result.rules`: ordered first-match clauses plus a
**mandatory** `default`, evaluated by `Rule.derive`. `Runner.classify` is gone
(AC1(b)).

The v0 algebra is closed by construction — `and`/`or`/`not`, `eq`/`ne`,
`lt`/`le`/`gt`/`ge`, `present`, `step_status`, over reference objects and scalar
literals. There is no way to spell a provider call, mutation, recursion or
unbounded iteration in the AST. 30 algebra assertions, including:

```
ok   - first match wins (not the last, not the default)
ok   - no rule matches -> the default emits, naming its own rule id
ok   - unknown operator is refused at parse
ok   - two operators in one expression are refused
ok   - a misspelled reference is not silently a literal
ok   - eq with three operands is refused
ok   - comparison over an unavailable fact is false, not an error
ok   - ordered comparison across types is refused
```

**The receipt records the matched `rule_id` and the fact references read:**

```json
"result": {
  "class": "README_PRESENT",
  "rule_id": "present",
  "fact_refs": [
    { "ref": "readme_exists.present", "kind": "step_output",
      "available": true, "value": true, "digest": "sha256:a17fcf0a…" }
  ]
}
```

The witness is **exact**, not a superset: `and`/`or` deliberately do not
short-circuit, so the facts *consulted* equal the facts *appearing in the
clauses evaluated*. That is what lets a verifier replay the derivation from the
receipt alone, and it is asserted:

```
ok   - witness carries the facts the evaluated clauses read
```

---

### AC5 — Fact provenance · **PASS**

Refused **at load**, not at evaluation:

```
✗ coh_min: IR error: result rule "peek" reads fact "readme_exists.size", which
  step "readme_exists" does not declare as an output port ["present"]; every
  non-scheduler fact must originate in a declared typed step output or a
  declared evidence predicate
```

Shipped as `examples/readme-present/refusals/undeclared-fact.json`, plus six
unit assertions covering the whole space:

```
ok   - a rule reading an undeclared output port is refused at load
ok   - a rule reading a fact of a non-existent step is refused at load
ok   - a rule reading an undeclared evidence predicate is refused at load
ok   - a rule testing a status outside the closed set is refused at load
ok   - a rule testing the status of a non-existent step is refused at load
ok   - a receipt report naming an undeclared fact is refused at load
ok   - a rule reading a DECLARED evidence predicate loads
```

The last row is the permission, not a refusal: proving only the refusals would
not show that declared evidence predicates *are* a lawful rule input.

Scheduler-owned facts are limited by the **shape of the interface**, not only by
a check: `Rule.env` has exactly three accessors — declared output port, declared
evidence predicate, terminal status — and there is no fourth, so the evaluator
cannot reach runtime-private state even if a check were forgotten.

---

### AC6 — Result honesty · **PASS**

| Fault | Where refused | Fixture |
|---|---|---|
| a class not in declared `classes` | load (`Rule.of_json`) | `refusals/undeclared-class.json` + 3 unit assertions (rule, default, obligation) |
| a rule table with no `default` | load | `refusals/no-default.json` + unit assertion |
| a provider-supplied final-result field | execution (`Exec.accept_success`) | unit assertion |

```
✗ coh_min: IR error: result rule "present" emits "README_MISSING", which
  result.classes does not declare ["README_PRESENT", "README_ABSENT", "INCOMPLETE"]
✗ coh_min: IR error: result.default is missing
```

The third clause is realized structurally: a provider publishing a port the
methodology did not declare has it **dropped** in the projection, so it never
enters the fact set, no rule can name it (provenance already refuses that), and
no receipt field carries it:

```
ok   - a provider-supplied result field is dropped, never authoritative
ok   - declared ports survive the projection
```

**Beyond the AC**, evidence honesty (design gate 6) is enforced too: a strong
class whose warrant obligations this run did not discharge refuses the run, and
an **unknown** obligation is never treated as discharged —

```
ok   - the emitted class's obligations are recorded and discharged
ok   - an unknown warrant obligation is not discharged, and refuses the run
ok   - a strong class whose required evidence is absent is refused
```

---

### AC7 — Schemas `0.2`, required by construction · **PASS**

`contracts/{common,cm-ir,run-request,sandbox-plan,receipt}.cue`, one CUE
package, `tsc-cm-ir/0.2` and `tsc-measurement-receipt/0.2`. The `0.1` strings
stay owned by what is on `main`. `research/cm-language/schema.cue` is **not** in
the diff.

Every canonical block and runtime-consumed field uses `field!:`. Measured
directly, before writing the schemas, on cue v0.9.2:

| schema form | absent field |
|---|---|
| `format: "tsc-cm-ir/0.2"` | **PASSES** (unifies to itself) |
| `format!: "tsc-cm-ir/0.2"` | refuses: `format: field is required but not present` |

The same holds for structs, lists and open structs — see AC8 for the per-block
matrix, where **0 of 30** blocks are CUE-blind.

**Non-vacuity.** Eight fixtures under `contracts/non-vacuity/`, each of which
must be rejected; `make vet-non-vacuity` fails if any validates:

```
non-vacuity: cm-ir.empty.reject.json                    rejected by #NormalizedCMIR
non-vacuity: cm-ir.unknown-operator.reject.json         rejected by #NormalizedCMIR
non-vacuity: receipt.empty.reject.json                  rejected by #MeasurementReceipt
non-vacuity: receipt.skipped-publishes.reject.json      rejected by #MeasurementReceipt
non-vacuity: run-request.empty.reject.json              rejected by #RunRequest
non-vacuity: run-request.unnamed-scheme.reject.json     rejected by #RunRequest
non-vacuity: sandbox-plan.empty.reject.json             rejected by #SandboxExecutionPlan
non-vacuity: sandbox-plan.unproved-discharge.reject.json rejected by #SandboxExecutionPlan
NON-VACUITY PASSED: 8 fixture(s) rejected.
```

Four are `{}` (a definition that validates the empty document is validating
nothing); four are *subtle*, each exercising a discrimination that does real
work — an operator outside the algebra, a subject entry with no scheme, a plan
step whose `config_schema` discharge flag is `false`, and a receipt in which a
**skipped** trace entry publishes a fact:

```
trace.2.status: conflicting values "success" and "skipped"
steps.0.discharge.config_schema: conflicting values true and false
```

**Both CMs' IRs and every emitted artifact vet.** 3 IRs; 7 receipts, 7 plans and
7 run requests emitted by real runs:

```
VET-IR PASSED: 3 IR(s) conform; 13 refusal fixture(s) match their recorded cue verdict.
VET PASSED: every emitted artifact conforms to its 0.2 contract.
```

---

### AC8 — Gate 9 negative fixtures · **PASS**

One missing-block case per canonical top-level block, for **all four** artifact
families (the issue requires two; the design's gate 9 also asks for the
runtime-consumed blocks of `RunRequest` and `SandboxExecutionPlan`, so all four
are covered). Negatives are **generated from the shipped/emitted positive** by
deleting exactly one block — `coh_min negatives --kind … --from … --out-dir …`
— so a negative fixture cannot drift from the positive it is a negative of. The
generator refuses to run against a source artifact that is not itself
admissible, so the sweep cannot pass for the wrong reason.

`make vet-negative` prints the matrix and fails if **either** mechanism admits:

```
gate-9 matrix (per canonical block: cue verdict vs runtime verdict)
  FAMILY           BLOCK                    cue vet        runtime
  cm-ir            cm                       refuses        refuses
  cm-ir            format                   refuses        refuses
  cm-ir            inputs                   refuses        refuses
  cm-ir            permissions              refuses        refuses
  cm-ir            question                 refuses        refuses
  cm-ir            receipt                  refuses        refuses
  cm-ir            result                   refuses        refuses
  cm-ir            steps                    refuses        refuses
  run-request      bounds                   refuses        refuses
  run-request      capability_ceiling       refuses        refuses
  run-request      cm_ir                    refuses        refuses
  run-request      format                   refuses        refuses
  run-request      parameters               refuses        refuses
  run-request      profile                  refuses        refuses
  run-request      subject                  refuses        refuses
  sandbox-plan     cm_ir_digest             refuses        refuses
  sandbox-plan     format                   refuses        refuses
  sandbox-plan     request_digest           refuses        refuses
  sandbox-plan     steps                    refuses        refuses
  receipt          cm_ir                    refuses        refuses
  receipt          evidence                 refuses        refuses
  receipt          execution_id             refuses        refuses
  receipt          extension                refuses        refuses
  receipt          format                   refuses        refuses
  receipt          obligations              refuses        refuses
  receipt          plan                     refuses        refuses
  receipt          request                  refuses        refuses
  receipt          result                   refuses        refuses
  receipt          runtime                  refuses        refuses
  receipt          trace                    refuses        refuses
VET-NEGATIVE PASSED: every canonical block of every family is refused by BOTH mechanisms.
```

**30 blocks; 30 refused by `cue vet`; 30 refused by the runtime; 0 CUE-blind.**
That is the `0.1 → 0.2` improvement, and the scaffold was right to warn against
assuming it matched the old matrix — at `0.1`, `format` / `procedure` /
`result_contract` were CUE-blind.

Both are still required. Gate 9 asks for two independent mechanisms precisely so
neither is load-bearing alone, and the runtime column is also table-driven in
the test binary over the same `canonical_blocks` lists the CUE contracts derive
from.

The runtime refusals go further than absence, and those are **not** CUE-blind by
accident but by *kind* — CUE cannot see them at all:

```
IR error: steps declares no work; an IR declaring no work and no vocabulary must not validate
IR error: the step graph is cyclic; steps ["readme_locate", "readme_depth"] can never become ready
IR error: question is empty; a CM with no governing measurement question measures nothing
```

**Discovery covers the negative space too.** `make vet-ir` refuses any `*.json`
under `examples/` that is neither an IR, a refusal fixture nor subject data, so
a fixture cannot be added without being gated. The 13 refusal fixtures each
record their `cue` verdict in `refusals.tsv`, and the gate asserts it in **both**
directions — 12 `conforms`, 1 `rejects`:

```
vet-ir: examples/readme-present/refusals/escape-path.json      cue conforms (as recorded)
vet-ir: examples/readme-present/refusals/no-default.json       cue rejects  (as recorded)
…
```

A `conforms` row is a measured statement that CUE cannot see that fault and the
runtime is the only thing standing between it and execution.

---

### AC9 — `RunRequest` as an artifact, with a named snapshot scheme · **PASS**

`tsc-run-request/0.1` is a first-class, canonical, content-addressed artifact
(`lib/request.ml`, `contracts/run-request.cue`). Local paths remain **locators**
supplied at link time and appear nowhere in the artifact.

`run --ir … --target …` synthesizes the request (computing digests) and keeps
working, per the pinned CLI axis; `run --request …` verifies an authored one
against the bytes it finds. `--request-out` writes it.

`directory-merkle/0.1` is defined precisely in `lib/request.ml` and in the
README: recursive walk, every regular file, no exclusions, `sha256` per file,
sorted by **path** (not readdir order), `"<hex>  <path>\n"` per line, `sha256` of
the concatenation. Symlink handling is documented as a property of the *named*
scheme, not an unrecorded accident.

```
ok   - different subjects give different snapshot digests
ok   - the same bytes give the same snapshot digest
ok   - adding a file to the subject changes the snapshot digest
ok   - every subject entry names a versioned scheme
ok   - a matching request verifies
ok   - a request whose subject digest does not match the bytes refuses
ok   - a request binding a different IR digest refuses
ok   - a subject entry with no scheme refuses fail-closed
ok   - an unrecognized scheme refuses fail-closed
ok   - an unknown profile refuses rather than being ignored
ok   - an uninterpreted run parameter refuses rather than being ignored
```

The last two matter for the design's "deferral does not make these free-form
extension points": v0 defines one profile and interprets no parameter, so both
refuse rather than being ignored — which is why `parameters` is a *consumed*
canonical block and appears in the gate-9 matrix.

The receipt binds request, IR and plan digests (AC10).

---

### AC10 — Digest binding is checked (gate 10) · **PASS**

`Receipt.binding_error` is a pure function applied by the runtime to its **own**
receipt before a byte is written, so a receipt whose bindings do not match never
reaches disk. The same function is what the (next-cell) verifier will call.

One negative per binding, each mutating **exactly one** digest to another
well-formed digest — so every field stays individually well-typed and the
receipt still admits structurally; the refusal can only come from the binding
check itself:

```
ok   - the emitted receipt's own bindings check out
ok   - a receipt with a mutated request digest still ADMITS structurally
ok   - a receipt whose request digest does not match the artifact is refused
ok   - a receipt with a mutated cm_ir digest still ADMITS structurally
ok   - a receipt whose cm_ir digest does not match the artifact is refused
ok   - a receipt with a mutated plan digest still ADMITS structurally
ok   - a receipt whose plan digest does not match the artifact is refused
```

Refusal text names *which* binding broke, rather than a bare "digest mismatch":

```
receipt binds request digest sha256:bbbb…bbbb, but the artifact it was produced
from digests to sha256:32bf3d15…
```

**Scope note.** A standalone `verify` subcommand is a declared non-goal (next
cell). The receipt therefore *carries* what that verifier needs and is refused
if it does not: the three bindings, the matched `rule_id`, every fact reference
with its value and content digest, runtime and provider identities pinned by
digest, and the full trace including skips with their cause. `coh_min check` is
deliberately named `check`, not `verify`, and its header says exactly what it
does not do.

---

### AC11 — Checker config schemas validated at link time (gate 11) · **PASS**

The **capability contract** owns the config shape (`Provider.cap_config`), not
the CM and not the provider. `Linker.validate_config` is the only place the two
meet, and a non-validating config refuses at **link time** rather than reaching
the provider. A provider may widen nothing and narrow nothing.

Four negative fixtures plus four unit assertions:

```
✗ link error: step "readme_depth" config.max_bytes is "big" (string), but
  capability "fs.text-metrics" declares it as integer >= 1
✗ link error: step "readme_depth" config is missing "max_bytes", which
  capability "fs.text-metrics" requires (integer >= 1)
✗ link error: step "readme_depth" config carries field(s) ["depth"] that
  capability "fs.text-metrics" does not declare; a capability's config schema is
  closed — a provider may widen nothing and narrow nothing
✗ link error: step "readme_locate" config.relative_path is not a confined
  subject-relative path: relative_path "../README.md" contains a ".." segment
```

The last one is the same mechanism doing double duty: `relative_path` has the
config type *confined subject-relative path*, so an escaping literal is a static
property of the document. That is both gate 11 and the reason AC12's "zero
receipt bytes" is structurally true — nothing can have run.

The rest of the linker's obligation list is covered too (design §Sandbox
ExecutionPlan 1–7): interface mismatch, unregistered capability, output port not
published, output/evidence schema mismatch, evidence predicate not emitted,
unbound slot, slot-kind category error, missing capability, excess capability
against both the CM envelope and the request ceiling, a request wider than the
CM's permissions, and bounds above either ceiling. 17 link assertions in total.

---

### AC12 — No regression · **PASS**

| #126/#127 criterion | Status |
|---|---|
| present → `README_PRESENT`, absent → `README_ABSENT` | `case: readme-present present README_PRESENT` / `absent README_ABSENT` |
| the two receipts differ | `sensitivity: readme-present 2 receipt(s), 2 distinct ... ok` |
| both receipts vet against `#MeasurementReceipt` | `VET PASSED` (now the `0.2` contract) |
| path confinement denies fail-closed with **zero** receipt bytes | `CONFINE PASSED (AC6): denied, 0 receipt bytes` — byte count measured with `wc -c`, not assumed |
| every IR under `examples/` vets; `make gate` depends on it; CI runs it | `VET-IR PASSED`, `gate: genericity vet-ir test …`, CI step 8 |
| discovery is closed (no ungated `*.json`) | `UNCLASSIFIED` guard, now over **four** classes |
| the vocabulary is the IR's word | superseded and strengthened: the whole derivation is |
| `readme-present.cm` implies no compile path | still `.intent.md`; no `*.cm` under `examples/` |
| `lib/json.ml` / `lib/sha256.ml` byte-identical to ascent-0 | `cmp` clean; **now checked in CI** as its own step |
| existing suite passes | 167 assertions, 0 failures |

`readme-present` **survives migrated, not deleted**: same question, same
vocabulary, same observable behaviour. Its IR moved to `0.2` and its derivation
moved from OCaml into `result.rules`. Its `0.1` receipt contract was replaced by
the shared `0.2` one under `contracts/`, per the pinned axis that the `0.2`
contracts live there.

The `parse_file` exception-class regression pair from β #126 F1 is retained and
extended:

```
ok   - a malformed number literal is a clean error, not an exception
ok   - a truncated \u escape is a clean error, not an exception
ok   - an unreadable IR path is a clean error, not an exception
```

---

### AC13 — `make gate` covers 1–12; CI green on the branch · **PASS locally; CI pending**

```
gate: genericity vet-ir test vet vet-non-vacuity vet-negative refusals confine
```

`make gate` exits 0 and prints an AC-by-AC summary. `dune runtest` is a
prerequisite, not a trailer — the criteria proved by construction rather than by
a subprocess live there.

CI (`.github/workflows/coh-min.yml`) runs each stage as its **own** step so a
failure is visible in the job summary: 16 steps, including a new
`Vendored files byte-identical to ascent-0` check. Parsed rather than read:

```
$ python3 -c "import yaml; …"
16 steps
  6 Vendored files byte-identical to ascent-0
  7 AC1 genericity (no cm_id branch, no classifier)
  8 AC7 vet IRs against #NormalizedCMIR
  9 Test (unit + end-to-end)
 10 AC1/AC3/AC4 measurement cases (both methodologies)
 11 AC5/AC6/AC11 fail-closed refusals
 12 AC7 emitted artifacts vet against their 0.2 contracts
 13 AC7 schemas are non-vacuous
 14 AC8 gate-9 matrix (all four artifact families)
 15 AC12 path confinement (fail-closed, zero receipt bytes)
 16 AC13 gate (AC1-12)
```

CI state on the branch head is **not observable from this cell** (no `gh`, and
the Actions API is not reachable here). β should confirm green before merge.

---

## §Self-check

**Did α push ambiguity onto β?** The places where a reviewer could reasonably
have disagreed are decided *and stated*, not left open:

1. **Path confinement as a link-time refusal.** The design's gate 7 says escapes
   are "denied and retained in the trace", which reads as *emit a receipt*;
   #126 AC6 (a backward-compat invariant here) requires **zero receipt bytes**.
   These conflict. Resolved in favour of the invariant, and made structural
   rather than conditional: `relative_path` is a *capability config type*, so an
   escaping literal never links. The trace-retention reading is satisfied for
   the dynamic case — a path arriving through an input port is still confined
   inside the provider, and a denial there aborts the run. Stated in
   `lib/provider.ml` and `lib/linker.ml` headers.
2. **`negatives` and `check` as subcommands.** Gate 9 needs a *file-driven*
   sweep for four families and the runtime must refuse independently, which
   needs a runtime entry point. `check` is scoped to **structural admission**
   and says in its own header what it does not do; `verify` remains the next
   cell. `negatives` refuses to derive from an inadmissible source.
3. **`DUNE` / `RUNNER` Makefile variables.** Added so the gate is exercisable
   where `dune` is not installable — the scaffold's own stated environment.
   Defaults are the real toolchain and CI overrides neither. They are not an
   escape hatch for the gate: `make gate` with the defaults runs `dune build`
   and `dune runtest`.
4. **Non-short-circuiting `and`/`or`.** A semantics decision with a receipt
   consequence, argued in `lib/rule.ml`'s header: it makes `fact_refs` exact
   rather than a superset, which is what a replaying verifier needs.

**Is every claim backed by evidence in the diff?** Every transcript above is
produced by a committed target or a committed assertion. Nothing here is a
hand-run one-off: `make gate` reproduces all of it, and the gate-9 matrix and
the cue-verdict column are *generated* rather than transcribed.

**Peer enumeration.** The families this change touches:

- **Artifact families** — `NormalizedCMIR`, `RunRequest`, `SandboxExecutionPlan`,
  `MeasurementReceipt`. All four have a typed validator, a CUE contract with
  `field!:` throughout, a `canonical_blocks` list shared by both, a gate-9 row
  set, and a non-vacuity fixture. None is exempt.
- **Providers** — `fs.file-exists`, `fs.text-metrics`. Both declare slots,
  ports, config schema, evidence schema and predicates, and required grants;
  both are linked through the same obligations; both are exercised by shipped
  cases.
- **Refusal sites** — load (`Ir`, `Rule`), link (`Linker`), execute (`Exec`,
  `Provider`), emit (`Receipt`). Each has at least one shipped fixture and one
  unit assertion, and every fixture asserts on the *message*, not merely on the
  failure.
- **Harness surfaces** (α SKILL §2.4) — Makefile, CI workflow, `lib/dune`,
  `.gitignore`, README, two intent notes, `cases.tsv` ×2, `refusals.tsv` ×2. All
  audited against the changed contract; the CI workflow was parsed with
  `yaml.safe_load` rather than read.
- **Deliberately exempt** — `research/cm-language/schema.cue` (pinned axis:
  not ours to edit this cycle), `../ascent-0/**` (untouched; its `json.ml` and
  `sha256.ml` are the byte-identical source and are now `cmp`-checked in CI),
  every other binary and example in the repo (0 hits in the diff).

**Artifact enumeration matches the diff.** `git diff --name-status
origin/main..HEAD -- research/cm-language .github` lists **61 files** (the
remaining 3 of the 64-file diff are this cycle's own `.cdd/unreleased/129/`
artifacts). Every one is either named in an AC section above, or is one of:
`examples/*/fixtures/**` subject content (6), `contracts/non-vacuity/*.reject.json`
(8, AC7), or `examples/*/refusals/*.json` (13, AC5/6/11). Scope, checked rather
than asserted:

```
$ git diff --name-only origin/main..HEAD | grep -vc \
    '^research/cm-language/runtime/coh-min/\|^\.github/workflows/coh-min\.yml$\|^\.cdd/'
0
$ git diff --name-only origin/main..HEAD | grep -c 'schema.cue'
0
```

No file in the diff is unaccounted for, and nothing outside the pinned package
scope was touched.

**Caller-path trace for new modules.** Every new module has a non-test caller:
`Value` ← `Jread`/`Rule`/`Provider`; `Jread` ← every validator; `Rule` ←
`Ir.of_json`, `Runner.run`; `Request` ← `Runner.resolve_request`; `Plan` ←
`Linker.link`, `Runner.run`; `Linker` ← `Runner.run`; `Exec` ← `Runner.run`;
`Receipt` ← `Runner.run`. `Runner` ← `bin/coh_min.ml` (`run`, `check`,
`negatives`). No module is reachable only from tests.

**One real bug was found by the tests and fixed, not worked around.** The
`directory-merkle` walk raised `Sys_error` on an unreadable entry, escaping the
fail-closed channel. It now refuses the snapshot with a stated reason — an
unreadable file cannot be silently omitted, because the digest would then bind an
identity that is not the subject's.

## §Debt

**D1 — the `eng/*` skill bundle was not loadable in this cell.** The scaffold's
load order names `SKILLS_ROOT/eng/{ocaml,write-functional,code,test,ux-cli}`;
`.cdd/skills/` contains only `cdd/`, `cds/`, `handoff/`, and no `SKILLS_ROOT`
exists on disk. The constraints were applied from the standard set in #126/#127
and β's reviews, but α could not check the diff against the skills' own text.
β should treat the OCaml-style and test-design surfaces as unverified against
their source of truth.

**D2 — `bounds.wall_time_ms` is carried and propagated but not enforced.** The
stdlib has no monotonic clock and the contract forbids Unix. It is validated
(step ≤ CM ≤ request), recorded in the plan, and passed to providers, but no
provider is interrupted on it. `output_bytes` and `evidence_bytes` *are*
enforced. Stated in the README's Honest scope.

**D3 — checker configuration is scalar-valued in v0.** `Ir.config_of_json`
accepts boolean/integer/string only. Neither capability needs more, and the
capability contract could grow, but a methodology needing a structured config
would need this widened first. Stated in `contracts/cm-ir.cue` and the README.

**D4 — `directory-merkle/0.1` follows symlinks and cannot see them.**
*(Corrected in round 2 after β F2 — the original entry alleged a non-termination
hazard that does not exist. See §Round 2.)*

Without Unix the stdlib cannot distinguish a symlink from its target, so the
scheme walks *through* symlinked directories and digests link *targets*. This is
named in the scheme rather than hidden, and a scheme that treats symlinks
differently must take a different version.

The limitation is one of **fidelity, not safety**. Measured on the branch head:

| Subject | Outcome |
|---|---|
| symlink loop (`sub/up -> ../`) | **terminates**, 0.008 s, exit 1, **0 receipt bytes**, `scheme directory-merkle/0.1 cannot walk …` |
| dangling symlink | exit 1, **0 receipt bytes**, same refusal shape |
| symlink to a file inside the subject | measured — but the link and its target are digested as **two separate entries** |

The first two terminate because the OS's own path-resolution failure surfaces as
`Sys_error` from `Sys.readdir`, which the snapshot walk already classifies and
converts into a fail-closed refusal.

What remains genuinely wrong is narrower and worth declaring: any subject
containing a symlink is either **refused** (loop, dangling) or **double-counted**
(link plus target), so the snapshot digest is not a faithful content identity for
such subjects. No shipped fixture contains a symlink. This is a reason a future
scheme version should record symlinks explicitly — not a reason to distrust the
current one's termination or its fail-closed behaviour.

**D5 — the warrant obligation catalog has exactly one requirement form.**
`evidence.<step_id>`. That is what the two CMs exercise, per the design's "the
initial obligation catalog should include only what the ordinary CM and Ascent-0
fixtures exercise". Unknown obligations are never treated as discharged, so
growth is safe; but no obligation about *provenance* or *ordering* is expressible
yet, and Ascent-0 will need those.

**D6 — CI state is not observable from this cell.** No `gh`, no reachable
Actions API. `make gate` is green locally under a flat `ocamlopt` build; the
canonical `dune build`/`dune runtest` have not been run by α. β should confirm
the branch is green before merge.

**D7 — the local gate runs through `DUNE`/`RUNNER` overrides.** α's `make gate`
transcript used a shim that maps `dune build` → no-op and `dune runtest` → the
flat-built test binary. The test binary genuinely ran (167 assertions); the
*dune build itself* did not. This is the same limitation as D6 and is why the CI
`Build` step is separate.

**D8 — `alpha-closeout.md` is not written.** Per `CDD.md` §5.3b it is a
pre-merge blocker written after β's verdict, on re-dispatch. Expected, not
skipped.

## §CDD Trace

| Step | Artifact | State |
|---|---|---|
| 0 Intake | `.cdd/unreleased/129/gamma-scaffold.md`, `issue-129.md` | read in full, including the closing amendment (FLAT frame; tests first-class) |
| 1 Design | `CM-EXECUTION-MODEL.pinned-61ba4d2.md` | pinned upstream; **not required** of α — this cycle is execution, not negotiation. Sections implemented as written: JSON document family, Uniform checker contract, Declarative result semantics, Graph execution semantics, gates 9/10/11, Design invariants |
| 2 Coherence contract | this file, §Gap | done |
| 3 Plan | **not required** — the 7-axis implementation contract pinned by δ *is* the plan; sequencing followed the design's own implementation order (schemas → convert the fixture and add a second CM → one generic pipeline → delete CM-specific classification) |
| 4 Tests | `test/test_coh_min.ml` (167 assertions), `cases.tsv` ×2, `refusals.tsv` ×2, 13 refusal fixtures, 8 non-vacuity fixtures, 30 generated gate-9 negatives | done — first-class, as the amendment requires |
| 5 Code | `lib/{value,jread,rule,ir,provider,request,plan,linker,exec,receipt,runner}.ml`, `bin/coh_min.ml`, `contracts/*.cue` | done |
| 6 Docs | `README.md`, `examples/readme-present/readme-present.intent.md`, `examples/repo-legibility/repo-legibility.intent.md`, `lib/dune`, module headers | done |
| 7 Self-coherence | this file | done |

**Implementation-contract conformance (δ's 7 axes, α MUST NOT improvise):**

| Axis | Pin | Conformance |
|---|---|---|
| Language | OCaml, stdlib-only; `json.ml`/`sha256.ml` byte-identical | `cmp` clean, now CI-checked; no `(libraries)` beyond `coh_min`; no ppx, no Unix |
| CLI integration target | the existing `coh_min` executable; `run --ir … --target …` keeps working; may gain `--request` | same executable; `run --ir --target` unchanged and gated; `--request` added; not `coh cm` |
| Package scoping | `research/cm-language/runtime/coh-min/**` and `.github/workflows/coh-min.yml` | exactly those two; `git diff --name-only` has no other path |
| Existing-binary disposition | additive + deletion of CM-specific classification; `schema.cue` not edited | `Runner.classify` deleted; `schema.cue` 0 hits; no other binary or example touched |
| Runtime dependencies | none beyond stdlib; `cue` only in the gates | holds |
| JSON/wire contract | canonical JSON; `tsc-cm-ir/0.2`, `tsc-measurement-receipt/0.2`, `tsc-run-request/0.1` | all three, plus `tsc-sandbox-plan/0.1`; `Json.document` is the canonical serializer and digests are taken over it, not over on-disk bytes |
| Backward-compat invariant | every #126/#127 criterion holds; `readme-present` migrated, not deleted | AC12 table above |

## §Review-readiness

**Round 1** · **implementation SHA `41195a7`** · base: `origin/main` `c8ffc2a`
(fetched and rebased onto at 2026-08-13; `git merge-base --is-ancestor
origin/main HEAD` succeeds) · **branch CI: not observable from this cell** (D6)
— β should confirm green before merge · γ-artifact: `gamma-scaffold.md` present
at the canonical §5.1 path on `origin/cycle/129`, so rule 3.11b is satisfied
without an exemption.

Local verification at this SHA: `make gate` exit 0; `dune runtest` equivalent
167 assertions, 0 failures; flat `ocamlopt -w +a-4-70 -warn-error +a-4-70` build
of all 13 library modules plus the driver and the test — clean, exit 0, with
warnings as errors.

Ready for β.

---

## §Round 2 — β R1 findings addressed

**β verdict R1:** REQUEST CHANGES at `df4e64b` — 1×B, 1×A, both
`honest-claim`, **zero code changes required**. All 13 ACs verified as passing
under β's own independently generated evidence, including a third methodology β
authored and ran without touching a `.ml` file.

Both findings are documentation truth. Nothing in `lib/`, `bin/`, `contracts/`
or `test/` changed this round:

```
$ git status --porcelain | grep -cE '\.(ml|cue)$'
0
```

### F1 (B) — the boundary claim was stated absolutely, and one axis falsifies it

**Accepted without reservation.** `README.md:19-21` said adding a methodology
means "**No OCaml, no Makefile rule, no CUE contract**". A methodology declaring
a receipt extension family other than `repository_measurement` must edit both
`lib/receipt.ml` (`families`) and `contracts/receipt.cue` (`#Extension`). I
reproduced β's case before writing the fix:

```
$ cue vet /tmp/famtest.json contracts/*.cue -d '#NormalizedCMIR'
conforms                       # the IR contract does not close the family
$ coh_min run --ir /tmp/famtest.json --target examples/repo-legibility/fixtures/rich
exit=1  receipt-bytes=0
✗ coh_min: emitted receipt is not admissible: extension.family
  "changelog_measurement" is not a known receipt family ["repository_measurement"]
```

β named the receipt family. Applying the peer-enumeration rule (α SKILL §2.3), I
enumerated the **whole family of closed sets** rather than fixing the one
instance, and checked each against both the OCaml and the CUE side:

| Extension point | OCaml | CUE | Verified by |
|---|---|---|---|
| methodology over existing capabilities + `repository_measurement` | — | — | `f97d57e` touches 0 `.ml`; β's third CM |
| new provider capability | `lib/provider.ml` | **none** | `checker.capability!: string`, `config!: {[string]: #Value}` — `contracts/cm-ir.cue:52,61` |
| new receipt extension family | `lib/receipt.ml:62` | `contracts/receipt.cue:148` | reproduction above |
| new snapshot scheme | `lib/request.ml` | `contracts/run-request.cue:25` | `#SnapshotScheme` is a one-element disjunction |
| new step kind | `lib/ir.ml` | `contracts/cm-ir.cue:50` | `kind!: "mechanical"` |
| new algebra operator | `lib/rule.ml` | `contracts/cm-ir.cue:80` | `#Expr` closed disjunction |
| new warrant obligation form | `lib/rule.ml` | **none** | `requires!: [...string]` — `contracts/cm-ir.cue:111` |

Two of the seven rows need OCaml but **no** CUE — a distinction the original
prose flattened in the other direction, and which a reader adding a provider
would have been mis-warned about.

**Fixed at five sites**, found by grepping the distinctive phrasing across the
whole slice before writing anything (β's instruction, and §2.3's intra-doc rule):

| Site | Was | Now |
|---|---|---|
| `README.md:19-21` | "No OCaml, no Makefile rule, no CUE contract." | qualified claim + the 7-row boundary table + the fail-closed refusal transcript |
| `README.md` §Honest scope | listed every other closed set, omitted these | receipt family and snapshot scheme added as their own bullets, each naming **both** files; provider and obligation bullets now say "no CUE edit" explicitly |
| `Makefile:9` (header) | "no Makefile edit, no OCaml" | qualified, and points at the README table |
| `Makefile` `genericity` success line | "adding a methodology touches no .ml file" | now states what the gate actually proved, then the qualified consequence |
| `examples/readme-present/cases.tsv:5` | "no Makefile edit and no OCaml" | qualified |
| `examples/repo-legibility/repo-legibility.intent.md:17-18` | "data alone … no CUE contract" | qualified, with a paragraph naming which sets this CM stays inside |

`self-coherence.md` §Gap carried the same sentence and now carries an inline
round-2 correction rather than being left standing.

Post-fix grep — the only surviving occurrences are the qualified forms:

```
$ grep -rIn -e 'no CUE contract' -e 'no Makefile edit, no OCaml' \
            -e 'touches no .ml file' Makefile README.md examples/
Makefile:267:  a methodology over existing capabilities and receipt families touches no .ml file.
README.md:22: exist needs no OCaml, no Makefile rule and no CUE contract.** That is the case
```

### F2 (A) — a declared debt alleged a bug that does not exist

**Accepted.** D4 asserted "a subject containing a symlink loop would not
terminate". I measured it rather than re-reasoning about it:

```
$ ln -s ../ symtest/loop/sub/up
$ time coh_min run --ir …/repo-legibility.ir.json --target symtest/loop
real   0m0.008s
exit=1   receipt-bytes=0
✗ coh_min: scheme directory-merkle/0.1 cannot walk "…/symtest/loop":
  …/loop/sub/up/sub/up/sub/up/… (OS path resolution fails; surfaces as Sys_error)

$ ln -s /nonexistent/target symtest/dangling/broken
exit=1   receipt-bytes=0   (same refusal shape)
```

β is right, and right about the direction: the runtime is **more** robust than
its own report claimed. The OS's path-resolution failure surfaces as `Sys_error`
from `Sys.readdir`, which the snapshot walk already classifies — the same
fail-closed conversion added in `476909d` for unreadable entries. There was no
non-termination hazard to fix.

I also measured the case β did not, so the corrected entry is not merely the
negation of the wrong one: a symlink **to a file inside the subject** is
measured, and the link and its target are digested as two separate manifest
entries. So the true residual limitation is **fidelity, not safety** — any
subject containing a symlink is either refused (loop, dangling) or
double-counted (link plus target), and the snapshot digest is therefore not a
faithful content identity for such subjects. D4 now says that, with the
measurement table, and explicitly does not claim symlinks are handled well.

### Debt carried forward

| # | State |
|---|---|
| D1 | **Open, and δ-side.** The scaffold left `SKILLS_ROOT` unsubstituted, so the `eng/*` bundle was unresolvable from this cell. β holds those skills and checked the diff against `eng/ocaml`'s own smell list: zero `with _ ->`, zero partial functions, `Result` for expected failure, purity boundary held, `Fun.protect`, exceptions classified by name, determinism enforced before digesting. No code consequence found. |
| D2 | Open — `bounds.wall_time_ms` carried and propagated but not enforced (no monotonic clock without Unix). |
| D3 | Open — checker configuration is scalar-valued in v0. |
| D4 | **Corrected this round** (F2). Fidelity limitation, not a termination hazard. |
| D5 | Open — one warrant obligation form; Ascent-0 will need more. |
| D6 | **Closed by β.** CI green on `df4e64b`: `coh-min`, `ci`, `CDD Artifact Validate` all success. |
| D7 | **Closed by β.** The `DUNE` shim's `runtest` really executes the test binary (β re-ran it that way independently), and CI runs real `dune build`/`dune runtest` on OCaml 5.2 — a second compiler and build system over the same sources, same result. |
| D8 | **Closed this round** — `.cdd/unreleased/129/alpha-closeout.md` written. |
| **D9** | **New, from β's Notes.** `make cases` ends with `test $$rows -ge 0`, which is always true and asserts nothing. β explicitly did not raise it as a finding (`genericity` and `vet-ir` both fail loudly on an empty discovery set and run *before* `cases` in the gate, so the gate as a whole is not vacuous). Recorded so it is not lost; left in place rather than fixed in a documentation-only round. |

### Verification re-run at round 2

- flat `ocamlopt -w +a-4-70 -warn-error +a-4-70` over all 13 library modules plus
  driver and test — **clean, exit 0**;
- **167 checks run, all passed** — unchanged, as expected for a prose-only round;
- `make gate` — **exit 0**, all stages including the 30-block gate-9 matrix;
- `git status --porcelain | grep -cE '\.(ml|cue)$'` → **0**.

## §Review-readiness | round 2

**Round 2** · **implementation SHA `41195a7`** (unchanged — this round touches no
code) · documentation SHA: this commit · base: `origin/main` `c8ffc2a` ·
**branch CI: green on `df4e64b`** per β §CI status; this round changes only
Markdown, a Makefile echo line and a TSV comment, so the `coh-min` workflow is
re-run on the new head by the same `push` trigger.

F1 and F2 both closed. Ready for β round 2.
