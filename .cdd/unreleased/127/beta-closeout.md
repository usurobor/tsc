# beta-closeout — cycle/127

**Issue:** usurobor/tsc#127 — *coh-min: consume schema-compliant NormalizedCMIR and enforce it in the gate (case 0)*
**Branch:** `cycle/127` · **Not merged at time of writing** — δ instructed β not to merge this cycle; merge is δ/γ's to execute.
**Rounds:** 2 — R1 `REQUEST CHANGES` (1×B `ci-status`, 1×A honest-claim), R2 `APPROVED` (0 findings)
**Review bases:** R1 `origin/main` = `e8b8319` · R2 `origin/main` = `b18dd24` (main advanced mid-cycle when cycle 126's close-outs landed; branch merged up at `619b15c`)
**Heads reviewed:** R1 `bb785ff`, R2 `619b15c`
**Verdict commits:** R1 `ae0cb15`, R2 this commit

β close-out: review context, release evidence, and β-side self-assessment.
Cycle-level triage is γ's. This artifact is also a **pre-merge gate requirement**
(`scripts/validate-release-gate.sh --mode pre-merge`), not an epilogue — writing
it is part of clearing the merge, not a record of a merge already done.

## Review Summary

**Round 1 (head `bb785ff`) — REQUEST CHANGES.** All seven ACs verified PASS and
all seven pinned contract axes verified conforming, every one under β's own
rebuild rather than by reading α's transcript. Two findings, **neither in the
implementation**: F1 (B, `ci-status`) — the `CDD Artifact Validate` workflow was
red on the review SHA and its own output declared merge blocked, caused by cycle
126's missing close-outs and pre-existing on `origin/main`; F2 (A,
honest-claim) — `Makefile:16-17` claimed a structural closure the discovery glob
did not deliver.

**Round 2 (head `619b15c`) — APPROVED.** Bounded re-verification of F2 across all
four discovery classes plus two adversarial edges, a full no-regression sweep,
and independent confirmation that F1's cause was discharged. No finding at any
severity.

**Verification method, both rounds.** `dune` is unavailable in the review cell (a
γ-verified environment fact). β rebuilt the slice with a flat `ocamlopt` 4.14.1
compile of `lib/{sha256,json,ir,provider,runner}.ml` plus a driver derived from
`bin/coh_min.ml` and a test derived from `test/test_coh_min.ml`, `sed`-dequalified
of the `Coh_min.` prefix, in scratch space outside the worktree. Both binaries
built clean under `-w +a-4-70 -warn-error +a-4-70`. `cue` v0.9.2. Canonical
`dune build` / `dune runtest` evidence is the `coh-min` CI job on each reviewed
SHA, read per-step from the Actions API rather than inferred from the run-level
result. Proxy and CI agreed at every pass.

## Implementation Assessment

The strongest surface this slice has produced. Three things are worth recording
as precedent rather than praise:

1. **`lib/ir.ml` is a genuinely total parser, not a validator bolted on.** It
   reads through its own `result`-returning accessors *precisely because* the
   vendored `Json.member` raises, so no raising accessor is reachable from
   `of_json`. β confirmed totality two ways: by construction (reading the module)
   and by test (`is_ir_error` carries an `| exception _ -> false` arm, so an
   escaping exception fails the test rather than silently passing it — β's own
   #126 F1 bug class, closed rather than avoided).
2. **The refactor deleted four silent fallbacks.** The pre-#127 `link` fabricated
   `may_access = []`, `search_strength = "exact"`, `config = J.Obj []`, and
   `seed_surfaces = []` on absent input. Each is now a typed `Error` naming its
   dotted path. That is `eng/ocaml` §3.10's smell list being cleared as the
   actual content of the diff, not as a claim about it.
3. **AC4's proof is a discriminating experiment, not an assertion.** β went
   beyond α's: with the vocabulary narrowed to `[README_PRESENT, INCOMPLETE]`,
   one and the same binary emits a receipt for the present fixture and refuses
   for the absent one. No hardcoded vocabulary can produce that split. β also
   checked the gate can only *narrow*, never widen, what reaches the receipt
   (`Runner.classify` derives only three names), so a data-driven vocabulary
   cannot breach `receipt.cue` downstream.

## Technical Review — F1 and F2

### F1 — `ci-status`, B — discharged by δ

β's round-1 call was that a red pre-merge gate declaring "merge blocked" cannot
be absorbed into an APPROVED verdict, even when the cause is inherited and not
α's. δ confirms the root cause was δ-side (#126 merged without collecting
close-outs), re-dispatched cycle 126's α and β, and landed both artifacts at
`b18dd24`. β verified rather than accepted: `.cdd/unreleased/126/` now carries
both close-outs, and β ran the gate itself —
`bash scripts/validate-release-gate.sh --mode pre-merge` reports
**`✅ cycle 126 (triadic): all required artifacts present`**.

**β accepts δ's correction on the script's modes, and it is worth recording
because β would otherwise have quoted a tag-time gate as a merge-time one.** The
script's default mode is `release`, which additionally requires `RELEASE.md` at
repo root and a `gamma-closeout.md` per cycle; CI runs `--mode pre-merge`, where
those are explicitly skipped as release-time-only. β ran both modes to confirm
the distinction is real and not a reporting artifact: pre-merge lists only the
cycle-127 close-outs; default additionally lists `RELEASE.md` and cycle 126's
`gamma-closeout.md`. Reading a validator's *default* mode as its *CI* mode is a
live β trap — the mode CI passes is part of the evidence, not a detail.

The finding did what a finding should: it surfaced debt that was blocking **every**
merge in the repo, not just this one, and it was repaired at the source rather
than waived.

### F2 — honest-claim / closure, A — fixed by α, verified by β

α chose the **widening** limb over rewording. β regards that as the better
choice and says so on the record: shrinking the claim would have been honest but
would have left the naming convention load-bearing, and a gate a rename defeats
is the drift class #127 exists to close. Discovery is now three classes — IR
(any `*.json` in an `ir/` dir, or any `*.ir.json` anywhere) vetted; subject data
(under `fixtures/`) ignored; anything else **refused**. The third class is what
makes the claim true rather than merely wider.

β re-ran its own round-1 counterexample under the exact name that previously
escaped: `examples/naming/ir/naming.json` → **exit 2**, gated. Three further
probes (a `*.ir.json` outside an `ir/` dir → gated; a stray `examples/stray.json`
→ refused with both conventions named; a fixture-resident `package.json` → exit
0, no false failure) all behaved as documented, with baseline restored after
each.

**α found a site β missed.** β's finding named `Makefile:16-17` and explicitly
credited `README.md` with stating the bound correctly. That was true of the
sentence β read and false of the file: `README.md:42` carried the same
"cannot be added without also being gated" claim. β records this as a β-side miss.
The lesson generalises and is cheap: **when a finding is "this prose overclaims",
grep the claim's distinctive phrase across the slice before writing the finding,
because the same sentence tends to have been written more than once.** β checked
one file for correctness and did not check whether the claim recurred. One
`grep -n "cannot be added"` would have found both sites in the time it took to
write the finding.

## Release Evidence

CI conclusions read from the Actions API on every SHA β reviewed:

| SHA | Role | `coh-min` | `ci` | `CDD Artifact Validate` |
|---|---|---|---|---|
| `bb785ff` | R1 head | **success** ([31500993728](https://github.com/usurobor/tsc/actions/runs/31500993728)) | success | failure — cycle 126 close-outs |
| `27df6d1` | α's F2 fix | **success** ([31502731638](https://github.com/usurobor/tsc/actions/runs/31502731638)) | success | failure |
| `619b15c` | R2 head | **success** ([31503344606](https://github.com/usurobor/tsc/actions/runs/31503344606)) | success | failure — cycle 127's own close-outs |

The `coh-min` job on `bb785ff` ran all 10 steps green, including step 7
`Vet IRs against #NormalizedCMIR`, step 8 `Test (unit + end-to-end)` (canonical
`dune runtest`), step 9 `Gate (AC1-5, over schema-vetted IRs)` (`make gate`,
which β cannot run locally without dune) and step 10 `Path confinement (AC6)`.
That is the canonical evidence for AC6 and for the `make gate` half of AC2.

**On the remaining red.** On `619b15c` the `CDD Artifact Validate` run's two jobs
split: `skill-bundle-integrity` **success**, `artifact-validate` step 4 failure.
β reproduced the step locally; the cause is now exclusively cycle 127's own
`alpha-closeout.md` and `beta-closeout.md`. This artifact clears one of the two.
**α's `alpha-closeout.md` is the last artifact standing between the branch and a
green gate**, and δ/γ should collect it before merge — the same omission that
produced F1 one cycle earlier.

Branch scope, verified against the current base: nothing outside
`research/cm-language/runtime/coh-min/**`, `.github/workflows/coh-min.yml`, and
`.cdd/unreleased/127/`. `schema.cue` absent from the diff. `lib/json.ml` and
`lib/sha256.ml` byte-identical to `../ascent-0/lib/` (`cmp`, both rounds).

## Review-Quality Assessment — the two heuristics, applied

β's #126 close-out proposed two bounded heuristics after missing that cycle's IR
gap. δ asks whether β actually applied them here. **Both were applied this cycle.
Here is what they cost and what they turned up.**

### Heuristic 1 — schema census

*For every data artifact a diff adds or changes, grep the repo for a schema or
contract claiming to govern that format; if one exists, vet against it and record
the result, pass or fail.*

**Applied.** β enumerated the non-prose, non-source artifacts on the branch and
inventoried the repo's candidate governing schemas
(`find … -name '*.cue' -o -name '*.schema.json' -o -name 'validate-*.sh'`, 20
hits). Census:

| Data artifact | Governing contract found? | Result |
|---|---|---|
| `ir/readme-present.ir.json` | `schema.cue` `#NormalizedCMIR` | vetted, **exit 0** |
| `ir/readme-present.escape.ir.json` | `schema.cue` `#NormalizedCMIR` | vetted, **exit 0** |
| emitted receipts | `contracts/receipt.cue` `#MeasurementReceipt` | vetted, **exit 0** ×2 |
| `.github/workflows/coh-min.yml` | none in-repo (no actionlint, no schema) | validated by parsing (`yaml.safe_load`, 9 steps) **and** by the workflow running green — external gate exercised |
| `lib/dune` | dune's grammar | exercised by `dune build` in CI |
| `.cdd/unreleased/127/*.md` | `scripts/validate-release-gate.sh` | run by β in **both** modes |
| `readme-present.cm` (deleted) | surface grammar under `research/cm-language/surface/` | **artifact removed** — see below |
| `Makefile`, `README.md`, `*.intent.md` | none | n/a |

**What it turned up:** no unvetted authored artifact. The census's real yield was
negative-and-useful — it confirmed the class of gap that produced #126 is now
empty for this slice, and it forced β to notice that the workflow YAML has **no
in-repo validator at all**, which is why β validated it by parsing and by
observed execution rather than by reading. That habit is what caught, in round 1,
that the step name survived α's unquoted-`#` fix.

**Cost:** roughly two commands. It is cheap enough to be routine.

### Heuristic 2 — harvest-parity check

*When a cycle declares it harvested or vendored from a sibling, diff the
sibling's gate/target set against the cycle's, not only the copied source.*

**Applied.** coh-min declares ascent-0 as its harvest source in the issue, the
`dune-project`, and the README. β diffed the two gate sets:

| ascent-0 (`check:`) | coh-min | Status |
|---|---|---|
| `build` | `build` | present (via `gate → vet → run → build`) |
| **`vet-ir`** | **`vet-ir`** | **present — this is exactly the target whose absence was #126's defect, and it is what #127 adds** |
| `run` | `run` | present |
| `vet-receipt` | `vet` | present |
| `firewall` | `confine` | **present as a target, but NOT a `gate` prerequisite** — ascent-0 wires `firewall` into `check`; coh-min keeps `confine` separate |
| `blind-prompt`, `check-all` | — | correctly absent (oracle-specific, no ordinary-CM meaning) |

**What it turned up:** the heuristic retro-validated itself. Run against #126 it
would have surfaced the missing `vet-ir` in one `grep`; run against #127 it shows
that target now present and wired into `gate`. It also surfaced one residual
parity delta β would not otherwise have looked for: **`make gate` does not depend
on `confine`, whereas ascent-0's `check` does depend on `firewall`.** β did not
raise it as a finding — CI runs `make confine` as its own step, so the invariant
is enforced on every push, and #126's AC7 deliberately scoped `gate` to AC1–5
with AC6 as a separate target. But a developer running `make gate` locally gets
strictly less than ascent-0's `make check`, and δ may want the two aligned when
the M1 unification lands.

**Cost:** one `grep` over a sibling Makefile. Also cheap enough to be routine.

**β's assessment of the heuristics themselves:** both earned their place, and
neither drifted toward the unbounded review that rule 3.5 forbids — each is
bounded by an artifact count, not by imagination. β recommends δ's adoption of
the δ-side implication (*ACs must name a conformance gate for every artifact a
cycle authors, not only those it emits*) as standing practice, and notes the two
heuristics are the β-side instrument for auditing that the practice was followed.

### The `.cm` invented-syntax issue — resolution confirmed adequate

β's #126 close-out reported, as a high-confidence observation requiring one
confirming command, that `readme-present.cm` did not conform to the repo's actual
surface grammar. δ notes this was already in #127's scope as AC7. β confirms the
resolution is adequate, on β's own evidence:

- **The premise was confirmed by execution, not left as β's source-read.** α built
  `cmc` flat and ran it; the file is rejected. α recorded the observed error
  (`unexpected character '\226'` — the lexer treats `#` as the comment marker, so
  the file's `//` comment is not a comment and its em-dash is the first illegal
  byte) rather than the predicted one, and said why they differ. That is the
  confirming command β's close-out asked for, and it lands one token earlier than
  β predicted.
- **α established the stronger fact β had not:** the grammar cannot express this
  CM *at all*. `LANGUAGE.md` §2 dispatches on the header's output type into
  exactly three program forms, and an ordinary CM emitting a
  `tsc-measurement-receipt/0.1` `MeasurementReceipt` is none of them. So the
  rename limb was not the lazy option — the other limb required building the
  compiler #127 scopes out.
- **β verified the resolution mechanically:** no `*.cm` remains anywhere under
  coh-min; every surviving repo-wide reference to `readme-present.cm` is either a
  frozen `.cdd` cycle record or the deliberate backreference in the new intent
  file explaining the rename; the nine sibling `.cm` files under
  `research/cm-language/surface/` are untouched (not in the diff); and
  `sha256sum readme-present.intent.md` equals both IRs' `source_digest`, so the
  digest tracks the renamed file rather than dangling. The replacement's first
  line states the IR is the authoritative executable artifact.

β's independent detection stands as corroboration of a real gap; α's resolution
is more complete than the fix β had in mind, because it removed the artifact's
claim to be source rather than trying to make it conform.

## Process Observations

- **The correlated-proxy risk from #126 persisted and again did not bite.** α and
  β both verified via flat `ocamlopt` 4.14.1 against a contract pinning OCaml
  5.2. Independence held on every input β could execute directly — β built its
  own fixtures, its own missing-block matrix, its own vocabulary variants — but
  it did not hold on the toolchain. CI covered the gap at every pass. Worth
  re-stating each cycle rather than assuming it has been priced in.
- **Differential probing over code-reading found both real defects, again.** F2
  came from running a rename the author had not run, not from re-reading the
  `find`. The round-1 AC4 experiment that most strengthened the verdict was the
  one α had not run (partial vocabulary narrowing). This is now two cycles where
  the technique that produced the finding was "run an input nobody ran."
- **β under-scoped a finding's blast radius and α caught it.** See F2 above. The
  asymmetry is instructive: α's peer-enumeration discipline is a better instrument
  for *claim recurrence* than β's file-local reading, and β should borrow it when
  the finding is about prose rather than behaviour.
- **A red CI check with an inherited cause is still worth blocking on.** β's F1
  was uncomfortable — it blocked a clean implementation for someone else's debt —
  and it was correct: the gate was blocking every merge in the repo, and raising
  it got it repaired at the source within one round rather than waived. β would
  make the same call again.
- **What β chose not to raise, recorded so it is not rediscovered as new:**
  (i) the `ir/`-inside-`fixtures/` classification seam (fail-closed direction, no
  live exposure — see the round-2 verdict's observation section, with the one-line
  fix named); (ii) `gate` not depending on `confine` (covered in CI, deliberate
  per #126 AC7); (iii) `make -j gate` could interleave `vet-ir` and `vet` (the
  Makefile comment already caveats this correctly and CI runs serially);
  (iv) `Runner.drive` would drop both steps of a duplicate-`step_id` pair,
  degrading to `INCOMPLETE` rather than a wrong result — unchanged from #126 and
  out of scope.

## Release Notes

Cycle #127 makes `coh-min`'s executed artifact **canonical and mechanically
enforced**. The two hand-authored IRs under `examples/readme-present/ir/` now
carry the `result_contract` and `receipt_contract` blocks `#NormalizedCMIR`
requires and both validate against `research/cm-language/schema.cue` — including
the negative fixture, which is not excused from the schema and differs from the
good IR in exactly one line.

Enforcement is two-sided and the division is deliberate. At **build time**, a new
`make vet-ir` target vets every discovered IR under `examples/` against
`#NormalizedCMIR`; `make gate` depends on it and CI runs it as its own step.
Discovery is a three-class rule — IR (any `*.json` in an `ir/` directory, or any
`*.ir.json` anywhere) is vetted, subject data under `fixtures/` is ignored, and
anything else is refused — so no `*.json` can be added under `examples/` without
being gated or explicitly classified, and an empty target list fails rather than
passing vacuously. At **run time**, a new pure module `lib/ir.ml` parses the IR
totally into a typed value: all eight canonical blocks must be present and every
consumed field well-typed, or nothing executes and no receipt is emitted.

The receipt's `result_class` vocabulary is now **read from the IR**
(`result_contract.result_classes`) rather than hardcoded; the runtime refuses to
emit a receipt carrying a class the CM never declared, and names both the class
and the declared set when it refuses. The derivation stays in OCaml, as
ascent-0's `derivation` field is still prose.

`readme-present.cm` is renamed to `readme-present.intent.md`: the surface
compiler's three program forms cannot express an ordinary CM emitting a
`MeasurementReceipt`, so the file was never compilable source, and it now says so
in its first line while naming the IR as authoritative.

**Compatibility:** additive and repair-only. No OCaml interface, receipt shape, or
CLI flag changed; `format: tsc-measurement-receipt/0.1` and `format:
tsc-cm-ir/0.1` are both retained, the latter now enforced. `schema.cue` was
conformed to, never edited. `lib/json.ml` and `lib/sha256.ml` remain byte-identical
to `../ascent-0/lib/`. Test suite 14 → 32 checks.

**Known limitation carried into `main`, and the highest-value follow-up in the
set:** `#NormalizedCMIR` cannot distinguish an absent block from an empty one.
β independently reproduced α's measurement — deleting `format`, `procedure` or
`result_contract` from a conforming IR still passes `cue vet` (3 of 8 blocks),
while the runtime refuses 8 of 8. The schema would therefore admit an IR
declaring no work and no vocabulary. The exposure is closed at run time by
`Ir.of_json` and is documented consistently in `lib/ir.ml`, the README, and
α's self-coherence, but **the project should stop treating "vets against
`#NormalizedCMIR`" as equivalent to "is a runnable CM IR" until that schema is
tightened.** Tightening it is out of #127's scope by the issue's own §Scope and
forbidden by the pinned contract; it is the same defect class #127 closes, one
layer up, and δ should file it as its own case.
