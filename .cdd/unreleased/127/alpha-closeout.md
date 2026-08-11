# alpha-closeout — cycle/127

**Issue:** usurobor/tsc#127 — *coh-min: consume schema-compliant NormalizedCMIR and enforce it in the gate (case 0)*
**Branch:** `cycle/127` · **Approved:** β round 2 (`b018523`) · **Merge:** pending, for δ/γ to execute (`Closes #127`)
**Final head reviewed:** `619b15c` · **Base:** `origin/main` = `b18dd24`
**Rounds:** 2 (round 1 REQUEST CHANGES — F1 `ci-status` B *not α's*, F2 honest-claim A; round 2 APPROVED, 0 findings)
**α commits:** `c3a2a37` (implementation), `27df6d1` (F2 fix), plus five incremental self-coherence commits

α-side narrative. Factual observations only; triage is γ's.

*Written at approval rather than post-merge:* the pre-merge `CDD Artifact Validate`
gate names this file as the last missing artifact, and β's round-2 §CI status
records it as the sole remaining red. The 126 close-out was collected the same
way, one cycle late; this one is collected before merge instead.

## Summary

Repaired the artifact `coh-min` executes so it is the project's canonical IR, and
made that mechanically enforced rather than assumed. 12 files: 2 added, 1 deleted,
9 modified — all under `research/cm-language/runtime/coh-min/**` plus
`.github/workflows/coh-min.yml`, exactly the pinned scope.

- **The IRs became canonical.** `readme-present.ir.json` and the escape fixture
  gained `result_contract` and `receipt_contract`, modelled on `ascent-0`'s
  (`kind` · `subcontracts` · `runtime_binding` · `emits` · prose `derivation`;
  `kind` · `reports` · `measure_only`) without copying Ascent-specific fields
  that carry no meaning for an ordinary CM. Both now `cue vet` exit 0 against
  `#NormalizedCMIR`, where #126's exited 1. The escape IR differs from the good
  one in exactly one line, so the negative fixture is one-variable.
- **`lib/ir.ml` (new)** — the IR contract as a typed, *total* value. It reads
  through its own `result`-returning accessors precisely because the vendored
  `Json.member` raises, so no stage downstream can observe a half-valid IR.
  Every silent default the old `link` fabricated on absent input — `may_access =
  []`, `search_strength = "exact"`, `config = J.Obj []`, `seed_surfaces = []` —
  is now a typed `Error` naming its dotted path.
- **The result-class vocabulary moved into the IR.** `result_contract.result_classes`
  is read and enforced; a derived class the CM does not declare is refused and no
  receipt is emitted. The *derivation* stayed in OCaml, which is what the AC
  permitted and what ascent-0's prose `derivation` field still does.
- **`make vet-ir`** — vets every discovered IR under `examples/` against
  `#NormalizedCMIR`; `make gate` depends on it; CI runs it as its own step.
- **`readme-present.cm` → `readme-present.intent.md`.** Established by execution,
  not assumption: I built `cmc` flat from
  `surface/{lib/cm_surface.ml,bin/main.ml}` and ran it on the file before
  choosing the limb.

Final evidence state: **32/32** test checks (14 retained from #126 + 18 new), exit
0; all 7 ACs PASS under β's independent flat-`ocamlopt` rebuild in both rounds;
7-axis contract conformant on every axis; `lib/json.ml` and `lib/sha256.ml`
byte-identical to `../ascent-0/lib/`; `schema.cue` untouched; `coh-min` and `ci`
green on `619b15c`.

## Friction log

- **`dune` unavailable again** (γ-verified). Same flat-`ocamlopt` proxy as #126:
  4.14.1 locally against a 5.2 contract pin, and dune's default warning set
  differs from bare `-w +a`. I tightened the proxy this cycle by additionally
  compiling under `-warn-error +a-4-70`, which is stricter than either. Cost: no
  defect either round; the residual toolchain-version risk remains real and
  unpriced, as in #126.
- **The AC7 limb was decided by reading the compiler, not the issue.** The issue
  offered "express it in the real surface grammar *or* rename". I built `cmc` and
  ran it, then read `LANGUAGE.md` §2: the compiler dispatches on the header's
  output type into exactly three forms — `InstrumentAssessment`, `AspectReceipt`,
  `CompositeReceipt` — and `example.readme-present` emits a
  `tsc-measurement-receipt/0.1`, which is none of them. So limb one required
  adding a fourth program form, i.e. building the deferred compiler. Ten minutes
  of execution turned a judgment call into a determination.
- **My reproduction of the AC7 premise differed from the scaffold's.** γ predicted
  `expected "cm", got identifier "methodology"`; I got `line 1: unexpected
  character '\226'`. Both are rejections; mine trips one token earlier because
  the lexer's comment marker is `#`, so the file's `//` line is not a comment and
  its em-dash is the first illegal byte. I recorded what I observed rather than
  what was predicted. Cheap, and it kept a scaffold detail from propagating
  unverified.
- **The `cue vet` matrix was found by trying to break the gate, not by reading the
  schema.** I only learned that three canonical blocks survive deletion because a
  deliberate break I expected to fail passed. Had I stopped at the first
  successful break (`receipt_contract`), the finding would not exist.

## Observations

### F2 — root cause in my authoring

β round-1 finding (severity A, judgment / honest-claim): `Makefile:16-17` claimed
*"EVERY IR under examples/, discovered … so a new example cannot be added without
also being gated"*, while discovery was `find examples -name '*.ir.json'`. β's
probe: one non-conforming IR, two names — `naming.ir.json` gated (exit 2),
`naming.json` silently skipped (exit 0), with `cue vet` failing on that same file
when invoked directly.

Root cause, precisely: **I wrote the closure claim describing the mechanism I
intended (`find`, recursive, not hand-enumerated) rather than the predicate I
actually shipped (`-name '*.ir.json'`).** The word doing the work was
"discovered", and discovery *was* the improvement over a hand-written list — so
the sentence felt earned. What it quantified over was every file the glob
matched, and I never asked what file a reader would expect it to cover that the
glob does not. The gap between "not enumerated by hand" and "cannot be added
without being gated" is exactly one unstated assumption: that everyone names IRs
`*.ir.json`.

**Limb chosen: widen discovery, not shrink the claim.** β offered both and I took
the harder one because the alternative leaves the naming convention load-bearing
— a gate that a `git mv` defeats is the same drift class #127 exists to close,
and #127's own thesis is that conventions must be mechanically enforced or they
rot. Widening alone would not have been enough either: it would have moved the
boundary without closing it. So classification became total — every `*.json`
under `examples/` is an IR (vetted), subject data under `fixtures/` (ignored, so
a subject's `package.json` is not a false failure — β's explicit caution), or
**unclassified and refused**. That third class is what makes the claim true
rather than merely wider, and it is the part I would have missed if I had
optimized for closing the finding instead of closing the gap.

Demonstrated across four probes, each reverted; β re-ran all four independently
plus two adversarial path edges and confirmed the counterexample is dead.

**Peer enumeration caught a site β's finding missed.** The overclaimed sentence
lived at three sites, not one. β's finding named `Makefile:16-17` and explicitly
credited `README.md` as stating the bound correctly — true of the sentence β
read (line 37), false of the file (line 42 carried the same "cannot be added
without also being gated" clause). This is the α skill's §2.3 intra-doc
repetition rule and its #266 F3-bis anchor firing exactly as written: grep the
claim's phrase, not the line number. β recorded the miss on its own side. I left
the round-1 self-coherence sentence intact as the record of the finding and
superseded it in the round-2 entry, rather than rewriting the artifact into
retroactive correctness.

### The comment-as-claim pattern — two cycles, same class

This is the second consecutive cycle where **my code was correct and the prose
around it overclaimed, and β found it rather than my own pre-review gate**:

| Cycle | Finding | The claim | The code |
|---|---|---|---|
| 126 | F1 (C) | `Runner.run`'s guard "keeps every IR fault fail-closed … never an escaping exception" | caught 2 of 4 reachable exception classes |
| 127 | F2 (A) | "a new example cannot be added without also being gated" | gated one filename glob |

Both are scope-of-claim defects, not logic defects. Both were universals ("every",
"never", "cannot") written from the mechanism I had in mind rather than from the
predicate I had shipped. In both cases the fix was small and the *finding* was
the expensive part — a review round each.

The structural gap: my pre-review gate (α `SKILL.md` §2.6) has rows that check
**evidence exists for each AC**, **artifact enumeration matches the diff**, and
**caller paths exist for new modules**. Every row is satisfied by producing
something. **No row re-reads what I wrote as a set of claims and asks what would
falsify each one.** Comments and doc prose are not ACs, so nothing in the gate
reaches them; they are checked only by a reviewer reading adversarially, which is
precisely what happened twice.

**Candidate gate row (α-side), for γ/δ triage — not adopted here:**

> **Claim audit.** Before signalling review-readiness, grep the diff for
> quantifiers and closure words — `every`, `never`, `all`, `any`, `cannot`,
> `always`, `no … can`, `impossible`, `guaranteed` — in comments, docstrings,
> README prose and commit messages. For each hit, name the predicate the code
> actually implements and the input that would falsify the claim. If that input
> is reachable, either narrow the sentence or widen the code; if it is
> unreachable, say why in one clause. Universals about a *space* (exception
> classes, filename shapes, provider kinds, input sources) must cite the
> enumeration of that space, not an example from it.
>
> *Would have caught:* #126 F1 ("every IR fault" / "never an escaping exception"
> vs. a 2-arm handler over a 4-class space) and #127 F2 ("cannot be added without
> being gated" vs. one glob).

β independently arrived at the reviewer-side counterpart — when a finding is
"this prose overclaims", grep the claim's distinctive phrase across the whole
slice rather than fixing the cited line. The two halves compose: mine catches the
claim at authoring time; β's catches its siblings at review time. Neither alone
caught the README's second site this cycle — β's finding cited one file, and my
round-1 gate never read the sentence as a claim at all.

### Carried debt: `cue vet` conformance ≠ runnability

Measured while proving the gate bites, reproduced and confirmed by β. Deleting one
canonical block at a time from the shipped IR (`cue` v0.9.2, `-d '#NormalizedCMIR'`):

| Missing block | `cue vet` | the runtime |
|---|---|---|
| `format`, `procedure`, `result_contract` | **passes** | fails closed |
| `cm_id`, `cm_version`, `source_digest`, `input_contract`, `receipt_contract` | fails | fails closed |

Cause is CUE unification, not a gate defect: a schema field already concrete
(`format: "tsc-cm-ir/0.1"`) unifies to that literal when the data omits it, and an
open struct or list (`procedure`, `result_contract`) is complete as `{}` / `[]`.
Only fields *incomplete* when absent (`cm_id: string`, …) fail.

**Implication, stated plainly: "vets against `#NormalizedCMIR`" is not yet
equivalent to "is a runnable CM IR."** `cue vet` alone would admit an IR with no
`procedure` and no `result_contract`. Today the runtime refuses 8 of 8, so
coh-min is safe; but any *other* consumer that trusts the schema alone — a future
`coh cm run`, a compiler emitting IR, a CI job vetting IRs it does not execute —
inherits the 3-of-8 gap. The division shipped in this slice (schema owns
exactness, runtime owns presence) is a division of *labour* between two
mechanisms, not a property of the schema.

Closing it means tightening `#NormalizedCMIR`'s run-side stub so absence and
emptiness are distinguishable. **Deliberately not done here:** issue §Scope
excludes tightening the run-side stub, and the pinned contract forbids editing
`schema.cue`. Scoped work for a later cycle. It is the same defect class this
cycle closed, one layer up — a contract weaker than the claim made on its behalf.

### Recorded for δ triage — β's sub-threshold observation (not acted on)

β observed that IR classification by path/name wins over the `fixtures/`
exclusion: `IRS` matches `*/ir/*.json` and `*.ir.json` with no `fixtures/`
exclusion, while only `UNCLASSIFIED` excludes it. So a subject repository
containing its own `ir/` directory, or a vendored `*.ir.json`, would be vetted as
a methodology — β demonstrated both. Failure direction is a false **failure**
(loud, immediate, self-announcing), the opposite of F2's false pass; the gate's
protective claim holds; no live exposure, since today's fixtures hold only
`README.md`. β judged it below the bar under rules 3.5/3.6 and named the fix as
one line: add `-not -path '*/fixtures/*'` to both `IRS` finds and reconcile the
two prose sites. δ is deferring it to the next cycle rather than reopening an
approved slice; recorded here so it is carried rather than lost.

Worth noting the shape: it is a *third* instance of prose slightly wider than
code in this slice — the three-class rule says fixtures are "ignored", and they
are ignored only by the unclassified check. Found by β, at a severity below
finding threshold, in the very fix for F2. The candidate gate row above would
plausibly have caught it, since "anything under a `fixtures/` directory →
ignored" is a universal over a location space.

### Deferred debt carried forward (all declared in self-coherence §Debt before review)

- **Test fixtures are a second writer of the IR shape.** The suite builds IRs in
  OCaml and cannot `cue vet` them from inside a stdlib-only test (no Unix, so no
  subprocess), so they could drift from `examples/`'s canonical IRs. Bounded: the
  shipped IRs are gated against the real schema, and the fixtures mirror their
  block structure.
- **The derivation is still OCaml and still CM-specific.** `Runner.classify` keys
  on `cm_id = "example.readme-present"`; any other CM is unclassified and
  fail-closed. Permitted explicitly by AC4, named in the IR's `derivation` prose,
  `runner.ml`, and README §Honest scope. Carried unchanged from #126, now with
  the vocabulary half lifted into data.
- **The runtime is stricter than the schema** on `result_contract.result_classes`,
  which `#NormalizedCMIR` leaves open but the runtime requires. Deliberate — a
  default would silently restore the drift class #127 closes — and stated in
  `ir.ml`, README and self-coherence. Consequence: a vetted IR is not
  automatically runnable, which is the same asymmetry as the carried debt above,
  pointing the other way.
- **Still no `.mli` interfaces**; `lib/ir.ml` adds a fourth fully-public module.
  Not raised in either review round.
- **`plan_digest` value moved** (the plan embeds `source_digest`, and the intent
  document was renamed). Self-consistent and externally reproducible — I
  re-derived it outside OCaml — and no AC pins the value.

### Skill-gap candidates (observations, not dispositions)

- `alpha/SKILL.md` §2.6's pre-review gate is a *production* checklist: every row
  is discharged by having made something (evidence, enumeration, caller paths).
  Nothing in it reads the authored prose adversarially. The claim-audit row above
  is the candidate; it is the α-side complement to §2.3's peer enumeration, which
  already handles claims that repeat across sites but assumes the claim itself
  was true at its first site.
- `alpha/SKILL.md` §2.3's intra-doc repetition rule worked exactly as written
  once I was pointed at a claim — it found the README's second site immediately.
  Its trigger is a reviewer naming a site; it has no authoring-time trigger.
  Same relationship as above: the rule is sound, the entry point is missing.
- Three occurrences this cycle of one class (F2's Makefile comment, the README
  sibling, β's sub-threshold `fixtures/` observation), and one in the prior cycle
  (#126 F1). Four in two cycles, all "claim quantifies more widely than the check
  behind it".

## Engineering-level reading

The cycle did what the issue asked, and the load-bearing part was not the IR edit
— that was twenty lines of JSON. It was making the schema *mechanically* enforced
in two places that fail differently: `cue vet` at build time over every discovered
IR, and a total typed parse at run time over every consumed field. The measured
`cue vet` matrix is the argument for why both are needed; a slice that had only
added `vet-ir` would have looked complete and left three of eight blocks
unguarded.

The strongest work was where I made something total and then tried to break it:
`Ir.of_json` (8-block table driven off the validator's own list, plus nested
fields and a wrong `format`) and the vocabulary gate (proved by *changing the IR*
and watching the identical run flip from receipt to refusal — a discriminating
experiment rather than an assertion about a constant). Zero findings landed on
either across two rounds. The one finding landed on a sentence.

That is the same contrast as #126, where `confine`'s eight-case negative space
drew zero findings and a comment drew F1. Two cycles running, the defect has been
in prose that asserted a property the tests did not cover, and both times the
prose was *nearly* true — true of the mechanism, false at one edge. The reusable
reading: a comment that states a universal is a test I have not written yet, and
should either become one or be narrowed until it is a description. I have written
the candidate gate row above to make that check exist at authoring time rather
than discovering it a third time.
