# β close-out — cycle/129 (usurobor/tsc#129)

**Cycle:** #129 — coh-min M1a: generic CM execution — a second methodology runs as data
**Final verdict:** APPROVED (round 2)
**Reviewed head:** `d5976be`
**Diff base:** `origin/main` = `c8ffc2a`
**Rounds:** 2 (R1 REQUEST CHANGES, 1×B + 1×A; R2 APPROVED)

---

## §Review Summary

| Round | Head | Verdict | Findings | Disposition |
|---|---|---|---|---|
| R1 | `df4e64b` | REQUEST CHANGES | F1 (B, honest-claim), F2 (A, honest-claim) | both documentation-truth; zero code defects found |
| R2 | `d5976be` | **APPROVED** | none | F1 and F2 closed; no regression; CI green |

Both rounds were conducted against a binary β built independently, not against
α's reported results. `dune` is unavailable in this cell, so β compiled `lib/*.ml`
flat with `ocamlopt` (OCaml **4.14.1**) plus a driver derived from
`bin/coh_min.ml`, and drove `make gate` through a shim whose `runtest` really
executes the test binary — so `make test` was never a silent no-op. CI compiles
the same tree under real `dune` on OCaml **5.2**. Two compilers, two build
systems, same result on both heads.

**R1 in one line:** all 13 ACs passed on evidence β generated; the two findings
were an over-absolute boundary claim in the README and a false debt entry in
`self-coherence.md`.

**R2 in one line:** α closed both without touching code — `git diff
df4e64b..d5976be -- '*.ml' '*.cue'` is **empty** — and closed F1 substantially
wider than β asked.

---

## §Implementation Assessment

This is the strongest cycle of the three (#126, #127, #129) β has reviewed on
this slice, and the headline claim is real rather than asserted.

**What the cycle actually achieved.** `Runner.classify` — literally
`if pl.cm_id = "example.readme-present"` at `a8b0c9a:lib/runner.ml:154` — is
deleted, and the result rule is now an ordered first-match table in the IR
evaluated by a generic evaluator. A second methodology was added in a commit
(`f97d57e`) touching zero `.ml` files. β verified the deletion, the commit
statistic, and the absence of any `cm_id`-keyed branch in the load/link/execute/
evaluate/emit path.

**Engineering quality.** β checked the diff against the `eng/ocaml` skill's own
smell list: zero `with _ ->`, zero partial functions (`List.hd`/`Option.get`),
no `raise`/`failwith` in `lib/`, `Result` used for every expected failure, IO
confined to the two adapter modules (`provider.ml`, `request.ml`) with the eight
pure modules clean, `Array.sort String.compare` before digesting so readdir order
cannot leak into a hash, `Fun.protect` for cleanup, and exceptions classified
**by name** (`Sys_error`, `End_of_file | Invalid_argument`) rather than swallowed.
Probing for the failure this pattern usually hides — a directory walk raising
outside its handler — β found both a dangling symlink and a symlink loop
terminate fail-closed with zero receipt bytes.

**On α's debt D1 (the `eng/*` bundle was missing from α's cell — δ's scaffold
left `SKILLS_ROOT` unsubstituted).** β holds those skills and looked specifically
for their absence. **It does not show.** The code independently satisfies
essentially every rule in the OCaml skill. δ should fix the scaffold token, but
should not read this cycle's code as evidence of harm — that would be the wrong
lesson from a real process defect.

**Best single thing in the cycle.** `make vet-negative` generates its negative
fixtures *from the artifacts a real run just emitted*, then asserts that each
missing canonical block is refused by `cue vet` **and** independently by the
runtime. A negative fixture therefore cannot drift from the positive it negates.
Most implementations of design gate 9 would hand-write 30 fixtures and let them
rot. This one cannot rot.

---

## §Technical Review — evidence β personally produced

All 13 ACs pass. The two that carried the cycle's weight were verified past the
evidence α offered:

**AC1 (genericity).** β injected each of the three leak classes and confirmed the
gate fails with `file:line` (CM id in `lib/`, result class in `bin/`, a
`let classify` definition), then reverted. More importantly β authored a **third
methodology**, `example.changelog-hygiene`, as data alone: 4 steps (3 independent
+ 1 dependent), five operators neither shipped CM exercises (`or`, `ne`, `lt`,
`gt`, `present`), 5 result classes, and the `count_blank_lines` config and
`byte_size` port that neither shipped CM uses. It produced five correct classes
over five subjects, byte-distinct receipts, and both the IR and every receipt vet
clean — with zero OCaml written. It still runs unchanged at `d5976be`.

**AC7/AC8 (requiredness).** β rebuilt the 30-block matrix (4 families) and got
30 refused by `cue vet`, 30 refused by the runtime, 0 CUE-blind. β then proved
the mechanism is load-bearing by removing it: rewriting every `field!:` to
`field:` sent **11 of 30 blocks CUE-blind and failed the gate loudly**, with the
concrete literal `format` among the blind — confirming the issue amendment's
"concreteness is not the lever." β also reproduced α's `0.1` comparison against
`schema.cue` on main independently: `format`, `procedure`, `result_contract` are
blind, **3 of 8, exactly as claimed**.

**AC3, 5, 6, 9, 10, 11, 12** were each verified by running the refusal directly
and reading the diagnostic: provenance and result-honesty violations refuse with
`IR error:` (i.e. at *load*), config violations refuse with `link error:` (i.e.
before reaching the provider), digest-binding negatives pair "still ADMITS
structurally" with "is refused," and confinement denies with **0 receipt bytes**
measured rather than assumed.

**Contract axes (all 7).** stdlib-only confirmed; `lib/json.ml` and
`lib/sha256.ml` **byte-identical** to `../ascent-0/lib/`; `schema.cue`
**untouched**; every changed path inside the permitted set.

---

## §Round 2 — how the findings were closed

**F1 (B) — closed, and closed wider than the finding.** β's finding cited one
sentence. α did not patch that line; it enumerated the whole family of extension
points and discovered the original sentence mis-warned in **both** directions —
two of seven rows (a new **provider capability**, a new **warrant obligation
form**) need OCaml but **no** CUE edit, which the absolute phrasing also got
wrong. β verified the resulting 7-row boundary table **empirically rather than by
reading it**, testing each row against `cue vet` and against the runtime:

| Row | α's claim | β measured |
|---|---|---|
| methodology over existing capabilities | no OCaml, no CUE | confirmed R1 by building one |
| new provider capability | OCaml only | IR with `capability: "fs.brand-new"` + arbitrary config **conforms** to CUE (`capability!: string`, `config!: {[string]: #Value}`); runtime refuses at link — **OCaml only, correct** |
| new receipt extension family | OCaml **and** CUE | receipt with a different `extension.family` is **rejected** by `#MeasurementReceipt` (`receipt.cue:148` pins the literal) — **both, correct** |
| new snapshot scheme | OCaml **and** CUE | request with `scheme: "git-tree/0.1"` **rejected** by `#RunRequest` — **both, correct** |
| new step kind | OCaml **and** CUE | IR with `kind: "invoke_cm"` **rejected** — **both, correct** |
| new algebra operator | OCaml **and** CUE | IR with an `xor` node **rejected** — **both, correct** |
| new warrant obligation form | OCaml only | IR with `requires: ["warrant.human-review"]` **conforms** (`requires!: [_, ...string]`); runtime declines to discharge it — **OCaml only, correct** |

All seven rows are accurate. β then grepped every site carrying the claim and
confirmed **no unqualified form survives**: six sites (README ×2, Makefile ×2,
`cases.tsv`, the repo-legibility intent note) now carry the qualified wording and
each cross-references the boundary table.

**F2 (A) — closed, without overcorrecting.** β re-measured both cases. The
symlink loop terminates in **10 ms** (α measured 8 ms), exit 1, **0 receipt
bytes**. α additionally measured a case β had not: a symlink to a file *inside*
the subject. β confirmed it independently and more strongly — reconstructing the
manifest by hand per the documented format (`"<sha256hex>  <path>\n"`, sorted)
reproduced the emitted subject digest **exactly** (`sha256:5589bd64…`), and shows
`ALIAS.md` and `README.md` carrying the identical content hash: **two entries for
one file**. This simultaneously proves the double-counting, the determinism, and
that the manifest really is reproducible with coreutils as the code comment
claims. D4 now records a **fidelity** limitation, explicitly "not safety," and
declines to claim symlinks are handled well — it still recommends a future scheme
version record them. That is the correct landing point.

---

## §Release Evidence

CI conclusions on the SHAs β checked (rule 3.10):

| SHA | `coh-min` | `ci` | `CDD Artifact Validate` |
|---|---|---|---|
| `df4e64b` (R1 head) | success | success | success |
| `58f70b4` (β R1 verdict) | success | success | **failure** |
| `d5976be` (R2 head) | **success** | **success** | **failure** |

The `coh-min` workflow — which runs real `opam exec -- dune build`,
`dune runtest`, and every gate stage as its own named step on OCaml 5.2 — is
**green on the reviewed head**. This also closes α's debt **D6** (CI unobservable
from its cell) and adequately covers **D7** (α's local gate ran under a `DUNE`
shim, so real `dune build` was never exercised locally): CI exercises it, and β's
independent 4.14.1 flat build is a second compiler over the same sources.

**Confirmed on the final SHA `6f3ffd9`** (this close-out's own commit):
`coh-min` **success**, `ci` **success**, `CDD Artifact Validate` **success**.
The closure gate flipped to green on the arrival of this file.

**The `CDD Artifact Validate` failure was this close-out's own absence.** β
pulled the job log rather than inferring: `❌ cycle 129: missing beta-closeout.md
— required before merge (CDD.md §5.3b)`. Nothing else is missing. β ran
`scripts/validate-release-gate.sh --mode pre-merge` locally with this file in
place and it passes.

**A mechanism worth recording for γ/δ.** The validator classifies a cycle as
triadic **only if `beta-review.md` exists** (`validate-release-gate.sh:77`).
Before β's first artifact lands, a substantial cycle is classified "small-change"
and the closure gate passes **vacuously** — which is why `df4e64b` was green with
no `alpha-closeout.md` either. The gate is armed by β's own first commit. That is
defensible, but it means the artifact gate can never catch a cycle that skips β
entirely, which is the case it would most want to catch.

---

## §Review-Quality Assessment

### The two heuristics from β's #126/#127 close-outs — applied again

δ asked whether these still earn their keep at this scale. **Both were applied.
Both earned it, and one of them closed a delta β itself recorded in #127.**

**Heuristic 1 — schema census.** *For every data artifact a diff adds or changes,
find the contract claiming to govern that format; vet against it and record the
result.* Applied across the cycle's data artifacts: 3 IRs (`#NormalizedCMIR`,
vetted), 13 refusal fixtures (verdicts recorded in `refusals.tsv` and asserted in
**both** directions), 8 non-vacuity fixtures (must be rejected — asserted),
emitted receipts/plans/requests (three definitions, vetted), `.cdd/` artifacts
(`validate-release-gate.sh`, run in both modes), workflow YAML (still **no
in-repo validator** — validated by execution).

**What it turned up this time:** one artifact class with no governing schema and
a silent failure mode — the TSV tables. β appended a malformed row (3 fields
where the parser expects 4) to `examples/repo-legibility/cases.tsv`; the awk
filter `NF==4` **silently dropped it and the gate still passed**. The same shape
applies to `refusals.tsv` (`NF==5`), where a dropped row would mean a fail-closed
case silently never runs. β did **not** raise this as a finding — see the
disposition note below — but it is the census's yield and δ should have it.

**Heuristic 2 — harvest-parity.** *When a cycle harvests from a sibling, diff the
sibling's gate set against the cycle's, not only the copied source.*

| ascent-0 `check` | coh-min `gate` (#129) | Status |
|---|---|---|
| `build` | prerequisite of every target | present |
| `vet-ir` | `vet-ir` | present |
| `run` | `cases` | present |
| `vet-receipt` | `vet` | present |
| `firewall` | `confine` | **now a `gate` prerequisite — the #127 delta is CLOSED** |
| — | `genericity`, `test`, `vet-non-vacuity`, `vet-negative`, `refusals` | coh-min is now a strict superset |

**What it turned up:** in β's #127 close-out the recorded delta was that
`make gate` did **not** depend on `confine`, whereas ascent-0's `check` depends
on `firewall`. At `c8ffc2a` the gate was literally `gate: vet-ir vet`; at
`d5976be` it is `gate: genericity vet-ir test vet vet-non-vacuity vet-negative
refusals confine`. The delta is closed, and `test` — also previously outside the
gate — is now a prerequisite too.

**Do they still earn their keep? Yes, but their roles have diverged.**
Harvest-parity has now paid out twice with a single `grep` and should be kept.
The schema census is drifting from discovery toward confirmation — on this slice
it increasingly returns "everything authored is vetted," because the cycle itself
built the discovery gates the census used to supply by hand. β's recommendation
is to **narrow it rather than retire it**: its remaining value is precisely in
artifact classes with *no* governing schema (this cycle: the TSVs and the
workflow YAML), so the useful question is no longer "is everything vetted?" but
"**which authored artifact classes still have no validator, and what is their
silent-failure mode?**" That is a smaller question and it is the one that
produced this cycle's only new observation.

### Two review moves worth naming as reusable

**1. To verify "X is now data," build a new X.** Re-checking commit statistics
tells you what a commit touched; it cannot tell you what the *next* one would
have to touch. β authored `example.changelog-hygiene` — a third methodology
deliberately shaped unlike either shipped one — and ran it. That single move
verified the headline claim, and it is also what exposed F1: the boundary's one
real exception surfaced because β pushed a *new* instance against the closed
sets, not because β read the code. **Generalization: for any "X is now data /
config / plugin" claim, author a new instance of X and see whether it needs
code.** It is cheap, it is bounded by the artifact you write, and it tests the
claim's future tense rather than its past tense.

**2. To verify a mechanism is load-bearing, remove it and measure.** The `0.2`
schemas claim `field!:` is what makes blocks required. Reading the CUE cannot
distinguish a required-marker that matters from one that is redundant with some
other constraint. β rewrote every `field!:` to `field:` and measured: **11 of 30
blocks went blind and the gate failed.** That is a *quantitative* answer to "does
this mechanism do work," and it took one `sed` and one `make`. **Generalization:
when a diff claims mechanism M enforces property P, delete M and measure how much
of P survives.** A mechanism whose removal changes nothing was never enforcement.

Both moves share a shape worth stating once: **they test claims by perturbation
rather than by inspection.** Inspection confirms that the code says what the doc
says; perturbation confirms that the code *does* what the doc says. β recommends
both to future reviewers on this slice.

### Disposition note — why the TSV gap is an observation, not a finding

β blocked this cycle in R1 over a README sentence, so the bar β applied to itself
here should be explicit. The TSV silent-skip is a **robustness gap in the harness,
not an incoherence in a shipped claim**: every shipped row is well-formed (β
confirmed all 5 + 5 + 13 rows parse and execute), no AC is unmet, and the
Makefile's stated organising rule ("nothing about a methodology is enumerated
here") remains true. It is the same class as the `cases` target ending in
`test $$rows -ge 0`, which asserts nothing. Under rule 3.3 a finding blocks
merge; β judged that blocking a cycle whose 13 ACs pass, over a hypothetical
authoring error in files that are currently correct, would be a phantom blocker
under rule 3.5. It is recorded here instead so the judgment is auditable rather
than hidden, and so δ can scope it deliberately.

---

## §α's comment-as-claim question — β's read

**Context.** In #127 α proposed a gate row for the "comment-as-claim" class. In
#129 α ran that row against F1 and reported it would **not** have caught it: the
row flags ~40 unrelated lines in the same README and misses the actual sentence.
α deliberately declined to propose a revised word list. δ asks whether a
mechanical rule is achievable, since β has now caught this class three times from
the reviewer side and found F1 by reading rather than by a rule.

**β's answer: a mechanical rule is achievable, but not the kind that has been
attempted. α is right to decline the word list, and δ should stop asking for
one.**

**Why lexical rules structurally cannot work here.** The defect is not in the
vocabulary. `"No OCaml, no Makefile rule, no CUE contract"` is lexically
indistinguishable from `"no CM id appears anywhere in lib/"` — and the second
sentence is *true and gate-enforced*. What separates a sound absolute claim from
an unsound one is not how it is worded but **whether a gate enforces the
quantifier, or the quantifier merely describes the instances that happen to exist
today**. That is semantic, and no word list reaches it. Any lexical rule must
either flag every absolute sentence (40 false positives, as α measured) or encode
the exceptions, at which point it is a hand-maintained list of the very facts it
was meant to discover.

**Why the class is nonetheless mechanizable — reframe the target.** The rule
should not scan prose for sentences that *sound* absolute. It should scan **code
for closed sets that lack documentation**. In this codebase the closed sets are
not subtle; they are list literals and match arms that gate an incoming string
and refuse it:

- `lib/provider.ml` `registry` → *"no provider is registered for capability …"*
- `lib/receipt.ml` `families` → *"is not a known receipt family …"*
- `lib/request.ml` `snapshot_schemes` → unrecognized scheme refusal
- `lib/ir.ml` `executable_kinds` → unknown step kind refusal
- `lib/rule.ml` operator match → unknown operator refusal
- `lib/rule.ml` obligation catalog → unknown obligation never discharged

The achievable gate is a **closed-set census with a documentation-coverage
obligation**: enumerate the sets that refuse an unknown member, and fail if any
one of them has no row in the README's boundary table. **That gate would have
caught F1** — `families` refuses unknown members and the README had no row for
it — and it produces no false positives on prose, because it never reads prose.

This is not a new invention; it is `make genericity` generalized. That target
already discovers CM ids and result classes *from the IRs* and asserts a property
of `lib/`. The proposed row discovers closed sets *from `lib/`* and asserts
coverage in the README. Same discipline, opposite direction. α has, in fact,
already built the table by hand — the gate would only keep it honest as the code
grows.

**The honest caveat.** Discovering "list literals that gate a string" is itself
heuristic and would miss a set expressed differently — the algebra operators are
a `match`, not a list, so a naive census misses them. β therefore recommends the
weaker but robust form: **assert the count**. Pin the known closed sets and their
documented rows, and fail when a new refusal message of the shape *"is not a
known / registered / declared X"* appears in `lib/` without a corresponding
table row. That bites on exactly the event that matters — someone adding a closed
set — and it degrades to a one-line update rather than a false positive.

**Residual reviewer-only surface.** What no gate will catch is free prose
elsewhere overstating what the table says. β judges that residue small and
acceptable: the fix is to keep the table canonical and have prose point at it,
which is precisely what α's round-2 rewrite did at all six sites.

**Recommendation to δ:** ask α for the closed-set census row, not another lexical
row. Score α's #127 proposal as **correctly abandoned**, not as a failure — α ran
its own proposal against a real instance, measured that it failed, and declined
to paper over it. That is the behaviour the process wants, and it should be
recorded as such.

---

## §Process Observations

1. **δ's scaffold defect (α debt D1) is real and should be fixed** — the
   unsubstituted `SKILLS_ROOT` token deprived α of the `eng/*` bundle. β's
   assessment is that it did not damage this cycle's code, but that is α's
   discipline compensating, not evidence the token is harmless.
2. **The pre-merge closure gate is armed by β's first artifact** (§Release
   Evidence). A cycle that never reaches β passes it vacuously.
3. **α's round-2 conduct was exemplary in the specific way that matters:** given
   a finding citing one line, it enumerated the whole family, found β's finding
   *understated* the problem (two rows wrong in the opposite direction), fixed
   all six sites, and measured rather than reasoned about the F2 correction —
   including a case β had not thought to run.
4. **Mechanical-finding ratio: 0 of 2.** Both R1 findings were honest-claim
   judgment findings. No mechanical findings reached review, so no process issue
   is indicated under the review skill's >20% rule.

---

## §Release Notes (for δ)

- **What ships:** a generic CM runtime. A methodology built from existing
  capabilities and the `repository_measurement` receipt family is **data alone** —
  JSON IR, subject fixtures, two TSV tables. Two structurally different
  methodologies run through one parser, linker, scheduler, result evaluator and
  receipt writer, with no `cm_id` dispatch and no CM-specific classifier.
- **Contract families:** `tsc-cm-ir/0.2`, `tsc-measurement-receipt/0.2`,
  `tsc-run-request/0.1`, `tsc-sandbox-plan/0.1`. The `0.1` strings on `main`
  remain owned by `research/cm-language/schema.cue`, which this cycle does not
  touch; promoting `0.2` into it is a later cycle.
- **Known limitations, all declared:** `bounds.wall_time_ms` carried but not
  enforced (no monotonic clock without Unix); scalar-only checker config; one
  snapshot scheme, which digests symlink targets and double-counts links;
  one obligation form; FLAT execution only.
- **Not in this cycle (correctly):** the `verify` subcommand, `CheckRequest`/
  `CheckOutcome` as wire artifacts, nested step kinds, Ascent-0 conversion.
- **Merge is withheld.** `beta/SKILL.md` ordinarily gives β the merge, but this
  dispatch explicitly reserved it, so β has merged nothing and tagged nothing.
  The branch is approved and merge-ready at `d5976be` plus this close-out;
  whoever holds the merge should land it with `Closes #129`. δ owns the release
  boundary (tag/deploy/disconnect) thereafter.
