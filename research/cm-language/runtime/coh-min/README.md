# coh-min — a CM runtime, where a methodology is data

`coh-min` loads a `NormalizedCMIR`, binds a `RunRequest`, links a
`SandboxExecutionPlan`, executes a finite typed checker DAG, evaluates the CM's
**own** result rule, and emits one `MeasurementReceipt`. It is the standalone
runtime on the path to `coh cm run` — **not** the production toolchain yet.

## The boundary this repository draws

> **Adding a *provider* is OCaml. Adding a *methodology* is not.**

A **provider** implements a checker capability — it reads the disk, counts
lines, and reports what it saw. There are exactly two, they live in
`lib/provider.ml`, and adding a third means writing OCaml.

A **methodology** is a JSON document. It declares a question, typed inputs, a
graph of checker requirements, and an executable rule table over the facts those
checkers publish. Adding one means adding `examples/<name>/` — an IR, some
subject fixtures, and two small TSV tables that the gate discovers. **No OCaml,
no Makefile rule, no CUE contract.**

That boundary is the whole point, so it is checked rather than asserted:

```
make genericity
```

discovers every shipped CM's identity and result vocabulary *from its IR* and
fails if any of them appears anywhere under `lib/` or `bin/`. If a third
methodology would require touching a `.ml` file, this gate is what would have to
be deleted first.

## Two structurally different methodologies, one binary

| | `example.readme-present` | `example.repo-legibility` |
|---|---|---|
| question | is there a `README.md`? | is the entry document substantial, and licensed? |
| steps | 1 | 3 — two independent, one dependent |
| capabilities | `fs.file-exists` | `fs.file-exists` **and** `fs.text-metrics` |
| optional output ports | none | `readme_locate.path` |
| principled skip reachable | no | yes |
| result classes | 3 | 4 |
| algebra | `eq`, `not`, `step_status` | `eq`, `ge`, `and`, `not`, `step_status` |

They share every stage: one parser, one linker, one scheduler, one result
evaluator, one receipt writer. Nothing in that path knows either of them exists.

```
make gate
```

runs both end to end over every discovered case, vets every emitted artifact,
sweeps the negative space, and prints an AC-by-AC summary.

## The pieces, and why each is separate

| Stage | Module | Owns |
|---|---|---|
| validate | `lib/ir.ml` | `tsc-cm-ir/0.2` as a typed value: canonical blocks, port resolution, graph acyclicity, **fact provenance**, rule-table totality |
| bind | `lib/request.ml` | `tsc-run-request/0.1`: the subject by **content digest** under a named snapshot scheme |
| link | `lib/linker.ml` | provider selection and the discharge obligations — interface, schemas, **config**, grants, bounds, adapters |
| execute | `lib/exec.ml` | the DAG: readiness, lawful withholding, principled skips, provider-contract enforcement |
| derive | `lib/rule.ml` | the v0 algebra and the ordered first-match evaluator |
| emit | `lib/receipt.ml` | `tsc-measurement-receipt/0.2`: one closed core, one closed family extension |

`lib/json.ml` and `lib/sha256.ml` are vendored **byte-identical** from
`../ascent-0/lib/`. Everything is stdlib-only: no yojson, no ppx, no Unix.

### Normalized requirement vs. linked binding

`Ir.step` is what the **methodology requires**: a capability, typed ports, a
config, a capability request, bounds. `Plan.step` is what the **linker selected
and granted**: a provider pinned by version and digest, the adapters bound to
each slot, the grants actually issued, and a `discharge` record naming what was
proved. Fusing them would mean a methodology names a provider — and running the
same CM on another host would mean editing the methodology.

## The result rule is data

The derivation lives in the IR's `result` block: an ordered first-match table
with a **mandatory** `default`, so evaluation is total.

```json
{
  "classes": ["README_PRESENT", "README_ABSENT", "INCOMPLETE"],
  "rules": [
    { "id": "incomplete-run",
      "when": { "not": { "step_status": ["readme_exists", "success"] } },
      "emit": "INCOMPLETE" },
    { "id": "present",
      "when": { "eq": [{ "fact": "readme_exists.present" }, true] },
      "emit": "README_PRESENT" }
  ],
  "default": { "id": "absent", "emit": "README_ABSENT" }
}
```

The **v0 algebra**, and nothing else: `and` / `or` / `not`, `eq` / `ne`,
`lt` / `le` / `gt` / `ge`, `present`, `step_status`. There is no way to spell a
provider call, a mutation, a recursion or an unbounded loop in this AST, which is
a stronger guarantee than checking for them.

Two properties are deliberate:

- **Totality.** A table with no `default` is refused at load, so "no rule
  matched" is unrepresentable rather than handled.
- **No short-circuiting.** `and`/`or` evaluate every operand. The algebra is
  pure, so this cannot change a verdict — but it makes the set of facts
  *consulted* equal to the set appearing in the clauses that were *evaluated*.
  That is what lets the receipt's `fact_refs` be exact, and lets a verifier
  replay the derivation from the receipt alone.

### Fact provenance

Every non-scheduler fact a rule reads must originate in a **declared typed
output port** or a **declared evidence predicate**. Scheduler-owned facts are
limited to execution status. A rule reaching for anything else is refused **at
load** — before any provider runs — so it cannot be discovered by whichever
subject happens to reach that clause:

```
✗ coh_min: IR error: result rule "peek" reads fact "readme_exists.size", which
  step "readme_exists" does not declare as an output port ["present"]
```

This is what keeps the evaluator generic. A fact that exists only inside one
runtime's internals cannot be named by a portable rule, so a CM that needs it
must publish it through a typed port.

## Required and optional output ports

Each declared output is `required` (the default) or `optional`.

- A `success` outcome **must** publish every required output. Missing one is a
  provider contract violation: the outcome is **rejected**, not downgraded.
  Downgrading would let a provider convert "I broke my contract" into "the fact
  is unavailable" — a status the methodology reasons about, and would then be
  reasoning about falsely.
- An absent **optional** output is **lawful withholding**, and it is recorded as
  `withheld` in the trace rather than left as silence.
- A dependent step whose input binds an absent optional port is a **principled
  skip** naming the unpublished port.

`fs.file-exists` publishes `present` always and `path` only when the file
exists. On a subject with no `README.md`:

```json
{ "step_id": "readme_locate", "status": "success",
  "published": [ { "port": "present", "value": false, "digest": "sha256:…" } ],
  "withheld": [ "path" ] }
{ "step_id": "readme_depth", "status": "skipped",
  "published": [], "withheld": [],
  "skipped_because": "required input \"target\" of step \"readme_depth\" binds
                      readme_locate.path, which step \"readme_locate\" did not
                      publish (step \"readme_locate\" ended success)" }
```

Nothing is fabricated — no default, no empty string, no zero. This is how
conditional progress is expressed without any conditional node, and a
methodology may **not** declare a withholdable port `required: true`: the linker
refuses that, because the capability never promised it.

## The subject is a digest, not a path

`--target ./fixtures/present` is a **locator**: it says where this host keeps
the bytes. A receipt that binds a path proves nothing, because the same path can
hold different bytes on two hosts and neither can be checked afterwards.

Every `RunRequest` subject entry names a `kind`, a versioned **`scheme`**, and a
`digest`. `run --ir … --target …` synthesizes the request (computing the
digests); `run --request …` verifies an authored one against the bytes it finds
and refuses a mismatch. An absent or unrecognized scheme refuses fail-closed.

**`directory-merkle/0.1`**, the one scheme implemented:

1. walk the located directory recursively; every **regular file** reachable from
   the root is included, with **no exclusions** — not `.git`, not dotfiles;
2. compute `sha256(contents)` per file, with `/`-separated subject-relative
   paths;
3. sort by **path**, so the digest is independent of readdir order;
4. emit `"<hex>  <path>\n"` per file — the `sha256sum` convention, so the
   manifest is reproducible with coreutils;
5. the snapshot digest is `sha256` of that concatenation.

Symlinks are followed (the stdlib cannot distinguish one without Unix, which the
contract forbids), so `0.1` digests link *targets*. That is a property of the
named scheme, not an unrecorded accident: a scheme that treats them differently
must take a different name.

## Two mechanisms, one contract

A closed CUE struct rejects *extra* fields; it does not by itself reject an
*absent* one. On the shipped `0.1` IR, deleting `format`, `procedure` or
`result_contract` still passed `cue vet` — a concrete literal unifies to itself
when omitted. **Concreteness is not the lever**, and the direction is the
opposite of the intuition: the concrete literal is the case that slips through.

The lever is CUE's required-field marker. Every canonical block and
runtime-consumed field in `contracts/*.cue` is written `field!:`, which refuses
exactly the absences that `field:` admits. Measured per block, for all four
artifact families:

| Family | Canonical blocks | `cue vet` refuses absence | runtime refuses absence |
|---|---|---|---|
| `#NormalizedCMIR` | 8 | 8 / 8 | 8 / 8 |
| `#RunRequest` | 7 | 7 / 7 | 7 / 7 |
| `#SandboxExecutionPlan` | 4 | 4 / 4 | 4 / 4 |
| `#MeasurementReceipt` | 11 | 11 / 11 | 11 / 11 |

No CUE-blind block remains, which is the `0.1 → 0.2` improvement. Both columns
are still required: gate 9 asks for two independent mechanisms precisely so that
neither is load-bearing alone. `make vet-negative` regenerates that matrix on
every run, deriving each negative from a **real emitted artifact** by deleting
exactly one block.

The schemas are also proved **non-vacuous** — a definition that validated
everything would pass every positive test:

```
make vet-non-vacuity
```

Each family carries fixtures under `contracts/non-vacuity/` that it must reject,
including subtle ones: a rule using an operator outside the algebra, a subject
entry with no scheme, a plan with an unproved discharge flag, and a receipt in
which a *skipped* step publishes a fact.

What CUE cannot see at all — graph acyclicity, port resolution, fact provenance,
rule-table totality, capability config compatibility — is refused by
`lib/ir.ml` and `lib/linker.ml`.

> The `0.2` contracts live here, under `contracts/`.
> `research/cm-language/schema.cue` still owns `#NormalizedCMIR` at `0.1` and is
> **not** edited by this slice; promoting `0.2` into the project schema is a
> later cycle.

## The capability owns its config (and confinement follows)

A step's `config` is methodology-owned and portable, so its **shape** is owned by
the **checker capability contract** — not by the CM (each methodology would
invent its own) and not by the provider (an implementation could widen or narrow
what the interface promises). The linker validates it, and a config that does not
validate refuses at **link time**:

```
✗ coh_min: link error: step "readme_depth" config.max_bytes is "big" (string),
  but capability "fs.text-metrics" declares it as integer >= 1
```

Path confinement falls out of the same mechanism. `relative_path` has the config
type *subject-relative path*, so an escaping literal is a static property of the
document and is refused before anything runs — which is exactly what keeps
"**denied with zero receipt bytes**" true:

```
make confine
```

`Provider.confine` is still applied inside the provider as defence in depth,
because a path arriving through an input port is not statically known. It is a
pure, total function, so its whole negative space is tested without a
filesystem.

## `check` is not `verify`

```
coh_min check --kind <cm-ir|run-request|sandbox-plan|receipt> --file <f>
```

performs **structural admission**: are the canonical blocks present, well-typed
and internally coherent? It deliberately does *not* check digests against the
artifacts they bind, replay the result rule, or apply obligation rules.

A standalone **verifier** is the next cell. This cycle's job is to make sure the
receipt *carries* everything that verifier will need, and to refuse one that does
not: the three digest bindings, the matched `rule_id`, every fact reference the
evaluator read with its value and content digest, the runtime and provider
identities, and the full trace including principled skips.

Digest binding is already checked at the producing end: `Receipt.binding_error`
is applied by the runtime to its **own** receipt before a byte is written, and
the test suite carries one negative per binding — a receipt with a mutated
`request`, `cm_ir` or `plan` digest, each still individually well-typed and
structurally admissible, each refused. A digest that is never checked is
decoration.

## Adding a methodology

```
examples/<name>/
  <name>.intent.md          prose note recording author intent
  ir/<name>.ir.json         the NormalizedCMIR — the executable artifact
  fixtures/<subject>/…      subject repositories under measurement
  cases.tsv                 case → ir, subject, expected result class
  refusals/<case>.json      IRs that must be refused
  refusals.tsv             case → ir, subject, cue verdict, expected message
```

`make gate` discovers all of it. Every `*.json` under `examples/` falls into
exactly one of four classes and the gate acts on all four, which is what lets the
closure claim be stated without hedging:

| Class | Rule | Gate behaviour |
|---|---|---|
| **IR** | any `*.json` inside an `ir/` directory | must conform to `#NormalizedCMIR` |
| **Refusal fixture** | any `*.json` inside a `refusals/` directory | must be refused by the runtime; its `cue` verdict is recorded in `refusals.tsv` and **asserted** |
| **Subject data** | anything under a `fixtures/` directory | ignored — a subject may legitimately contain JSON that is not a methodology |
| **Unclassified** | anything else | **refused**, naming the file and the conventions |

The `cue` column is worth dwelling on. A row marked `conforms` means CUE cannot
see that fault and the runtime is the only thing standing between it and
execution — of the thirteen shipped refusal fixtures, twelve are `conforms`.
The gate asserts the recorded verdict in **both** directions, so the division of
labour between schema and runtime is measured rather than described.

## Build and run

Stdlib-only OCaml; no opam dependencies (`cue` v0.9.2 is needed only for the
vetting targets).

```
make build            # dune build
make test             # dune runtest — 167 assertions
make cases            # run every discovered measurement case
make refusals         # run every discovered fail-closed case
make vet-ir           # every IR against #NormalizedCMIR; refusal cue verdicts
make vet              # every emitted receipt/plan/request against its contract
make vet-non-vacuity  # each schema rejects what it must reject
make vet-negative     # the gate-9 matrix, all four families
make genericity       # no CM identity or classifier in lib/ or bin/
make confine          # path confinement, fail-closed, zero receipt bytes
make gate             # all of the above
```

`DUNE` and `RUNNER` are overridable so the gate can be exercised where `dune` is
not installable — verification there is a flat `ocamlopt` build of `lib/*.ml`
plus a driver derived from `bin/coh_min.ml`. CI always uses the real toolchain.

```
coh_min run --ir <ir.json> (--target <dir> | --bind <name>=<dir>)…
            [--request <run-request.json>]
            [--out <receipt.json>] [--plan-out <p>] [--request-out <q>]
coh_min check     --kind <family> --file <f>
coh_min negatives --kind <family> --from <artifact.json> --out-dir <dir>
```

`--target` binds the sole declared CM input and is a usage error for a CM
declaring more than one; `--bind` is the general form. Exit `0` on success, `1`
fail-closed (no receipt bytes), `2` on a usage error.

## Honest scope

- **FLAT only.** Every step terminates at a primitive provider. `invoke_cm`,
  `semantic_judgment`, `oracle` and `transform` step kinds are **refused**, not
  silently accepted — nesting is a later cycle and is not anticipated in the
  code.
- The executed artifact is a **hand-authored** IR. The `.cm` surface compiler for
  ordinary CMs stays deferred until the runtime target stops moving; the IR is
  the authoritative executable artifact and says so.
- **Two** providers are wired: `fs.file-exists` and `fs.text-metrics`.
- The **warrant obligation catalog** has exactly one requirement form,
  `evidence.<step_id>`. An unknown obligation is never treated as discharged, so
  a class cannot be strengthened by inventing a requirement nobody can check.
- `bounds.wall_time_ms` is **carried and propagated but not enforced**: the
  stdlib offers no monotonic clock without Unix, which the contract forbids.
  `output_bytes` and `evidence_bytes` are enforced.
- Checker configuration is **scalar-valued** in v0.
- Ascent-0 is the hard side of the two-sided kernel and is not converted here;
  reproducing it through this ABI is a later step, and a larger one than a port.
