# alpha-closeout — cycle/129

**Issue:** usurobor/tsc#129 — *coh-min M1a: generic CM execution — a second
methodology runs as data, results derived from the IR*
**Branch:** `cycle/129` · base `origin/main` `c8ffc2a`
**β verdict:** REQUEST CHANGES R1 (1×B, 1×A, both `honest-claim`, zero code
changes) → both closed in round 2
**Design authority:** `CM-EXECUTION-MODEL.pinned-61ba4d2.md`

Voice note: this file records observations and patterns. Dispositions are γ's.

---

## Summary

`coh-min` stopped being a tracer and became a runtime.

Before: `Runner.classify` was literally `if pl.cm_id = "example.readme-present"`.
The vocabulary was data; the *derivation* was OCaml; the graph was one node.
Adding a methodology meant writing OCaml.

After: a methodology is a JSON document. The pipeline —
`Ir` → `Request` → `Linker` → `Exec` → `Rule` → `Receipt` — contains no
classification step, no methodology-identity lookup, and no per-CM branch.

The headline is one commit:

| | |
|---|---|
| `f97d57e` | `examples/repo-legibility/**` — 20 files, 2995 insertions, **zero `.ml`** |

That CM is structurally nothing like the first: three steps instead of one, two
independent plus one dependent, two capabilities, an optional output port, four
result classes, and five algebra operators the first never uses. It runs through
the same binary.

β tested the claim past the commit statistic, which is the right way to test it:
they authored a **third** methodology (`example.changelog-hygiene`, 4 steps, 5
classes, five operators neither shipped CM exercises, plus the `count_blank_lines`
config and `byte_size` port both shipped CMs leave unused) and ran it against the
binary built from this branch. Five subjects, five classes, all receipts
byte-distinct, everything vetting clean. Zero OCaml lines written. That is a
stronger proof than anything I produced, and it is the one I would point at.

Other load-bearing shifts:

- **Two step moments kept apart.** `Ir.step` is what the methodology *requires*;
  `Plan.step` is what the linker *selected and granted*, with a `discharge`
  record. Fusing them would mean a methodology names a provider.
- **Required/optional output ports.** The single bit that makes conditional
  progress expressible without conditional nodes. A `success` missing a
  *required* output is rejected, not downgraded; an absent *optional* one is
  lawful withholding, recorded as such; a dependent step then skips, naming the
  unpublished port.
- **The subject is a digest**, under a named `directory-merkle/0.1` scheme, not
  a path.
- **`0.2` schemas required by construction.** `field!:` throughout — and the
  measurement that mattered was done *before* writing them: `format: "…"` absent
  PASSES, `format!: "…"` absent FAILS. Concreteness is the wrong lever, and it
  is the concrete literal that slips through.
- **Gate 9 as a generator, not a fixture set.** `make vet-negative` derives each
  negative from the artifact a real run just emitted, so it cannot drift from
  the positive it negates. 30 blocks × 4 families, both mechanisms, 0 CUE-blind.

β verified all 13 ACs from evidence they generated themselves, and falsified my
strongest claim deliberately: they rewrote every `field!:` → `field:` and watched
**11 of 30 blocks go CUE-blind and the gate fail loudly**, then restored. That is
the check I would most have wanted a reviewer to run.

---

## The F1/F2 round

Both findings were documentation truth. No behaviour changed; `git status
--porcelain | grep -cE '\.(ml|cue)$'` → `0` for the whole round.

**F1 (B)** — the README stated the boundary absolutely: adding a methodology
means "No OCaml, no Makefile rule, no CUE contract." A methodology declaring a
receipt extension family other than `repository_measurement` must edit both
`lib/receipt.ml` and `contracts/receipt.cue`. The code is right — an unknown
family is refused with zero receipt bytes, because an extension whose schema
cannot be checked is not evidence — and the prose was wrong.

I fixed it by enumerating the whole family of closed sets rather than the one
instance β cited, and checking each against **both** sides:

| Extension point | OCaml | CUE |
|---|---|---|
| methodology over existing capabilities + `repository_measurement` | — | — |
| new provider capability | yes | **no** |
| new receipt extension family | yes | yes |
| new snapshot scheme | yes | yes |
| new step kind | yes | yes |
| new algebra operator | yes | yes |
| new warrant obligation form | yes | **no** |

Two of seven need OCaml but no CUE — a distinction the original sentence
flattened in the *other* direction, so a reader adding a provider was also
mis-warned. Six prose sites carried the claim; all six now carry the qualified
form, and §Honest scope lists the receipt family and snapshot scheme as their own
closed sets alongside the ones it already listed.

**F2 (A)** — my declared debt D4 asserted "a subject containing a symlink loop
would not terminate." Measured: it terminates in **8 ms**, exit 1, **0 receipt
bytes**. The OS's path-resolution failure surfaces as `Sys_error` from
`Sys.readdir`, which the snapshot walk already classifies — the same fail-closed
conversion I added in `476909d` for unreadable entries. I had reasoned about the
walk instead of running it, and reasoned wrong in the safe direction.

I also measured the case β did not, so the corrected entry is not merely the
negation of the wrong one: a symlink *to a file inside the subject* is measured,
with link and target digested as two separate manifest entries. The true residual
limitation is **fidelity, not safety** — any subject containing a symlink is
either refused or double-counted, so the snapshot digest is not a faithful
content identity for it. D4 now says that, and does not overcorrect into claiming
symlinks are handled well.

---

## Observations

### 1. The comment-as-claim pattern is now three-for-three — and my own proposed fix would have missed this one

| Cycle | Finding | The claim | The code |
|---|---|---|---|
| 126 | F1 (C) | "keeps every IR fault fail-closed … never an escaping exception" | caught 2 of 4 reachable exception classes |
| 127 | F2 (A) | "a new example cannot be added without also being gated" | gated one filename glob |
| 129 | F1 (B) | "No OCaml, no Makefile rule, no CUE contract" | true of 1 of 7 extension points |

Three consecutive cycles, same class: **the code was correct and the prose around
it overclaimed, and β found it rather than my pre-review gate.**

**Did I apply the gate row I proposed in my #127 close-out? No — and this is the
part worth recording, because applying it would not have helped.**

The row I proposed reads:

> grep the diff for quantifiers and closure words — `every`, `never`, `all`,
> `any`, `cannot`, `always`, `no … can`, `impossible`, `guaranteed` …

I ran that grep against the sentence that became F1, as it stood at the reviewed
head:

```
$ git show df4e64b:…/README.md | sed -n '16,21p' \
    | grep -nEi 'every|never|\ball\b|\bany\b|cannot|always|no [a-z]+ can|impossible|guaranteed'
                                    (no match)

$ git show df4e64b:…/README.md \
    | grep -cEi 'every|never|\ball\b|\bany\b|cannot|always|impossible|guaranteed'
40
```

**The row would have flagged 40 other lines in that one file and missed the exact
sentence that became the finding.** The word list was induced from the two prior
instances, and both of those were *quantified verb clauses* ("every fault",
"cannot be added"). #129's overclaim is a different grammatical shape: an
**absolute negative noun phrase** — "No OCaml, no Makefile rule, no CUE
contract." No quantifier appears in it at all. It is an exhaustive-enumeration
claim disguised as a list.

So the honest finding is not "I forgot to run my check." It is that **the check I
designed was overfitted to its two training examples**, and a third instance in
the same class evaded it. A lexical trigger list induced from n=2 predicts n=3
badly; the invariant the three share is not vocabulary but *shape* — a sentence
that asserts something about the whole of a space (exception classes, filename
shapes, extension points) while the code enumerates that space somewhere else in
the tree. The two artifacts that would falsify such a sentence are always
available: the enumeration in the code, and the sentence. Nothing in my process
put them side by side.

Partial credit where it is due: the *mechanized* version of this check did work.
`make genericity` is a claim-audit for the one claim I could make executable, and
it bit me twice during authoring (see below). The gap is precisely the claims
that live only in prose.

### 2. The genericity gate caught two real leaks during construction

A gate that bites its own author while they are writing the thing it guards is
the strongest evidence it is not decorative. This one did, twice:

| Leak | How it got there | Fix |
|---|---|---|
| `lib/runner.ml` header quoted `"example.readme-present"` while *explaining that the CM-specific classifier had been deleted* | a comment about the absence of a thing contained the thing | rewrote the comment to describe the construct without naming a CM; added a line telling future readers why no comment in the tree quotes one |
| `"NO_COLOR"` matched my first, naive class-shaped regex `"[A-Z][A-Z_]{3,}"` | I guessed at the *shape* of a result class instead of reading the actual vocabulary | replaced the regex with discovery: extract `result.classes` from the shipped IRs and check each real class name |

The second is the more interesting one. My first implementation guessed a
lexical pattern for "looks like a result class"; the fix was to stop guessing and
read the vocabulary from the artifacts that define it. That is the same move the
gate makes for CM ids, and it is why the gate cannot rot as methodologies are
added — β confirmed the property independently by injecting three leak classes
and watching each fail with `file:line`.

Note the shape-rhyme with observation 1: **guessing at a pattern instead of
reading the enumeration** is exactly what the prose claim did too. The gate got
fixed because it failed loudly at authoring time. The sentence did not, because
nothing made it fail.

### 3. Debt D1 was δ's error, and it did not reach the code

The scaffold's load order named `SKILLS_ROOT/eng/{ocaml,write-functional,code,
test,ux-cli}`. `SKILLS_ROOT` was left unsubstituted, and no such path exists in
this cell — `.cdd/skills/` carries only `cdd/`, `cds/`, `handoff/`. So the Tier
2/3 engineering bundle was unresolvable and I authored without it, working from
the standard those skills had set in #126/#127 and from β's two prior reviews.

I declared it as debt D1 before review rather than discovering it at review. β
holds those skills and checked the diff against `eng/ocaml`'s own smell list:

| `eng/ocaml` rule | Result |
|---|---|
| `with _ -> []` / `None` / `""` | zero, outside vendored files |
| partial functions (`List.hd`, `Option.get`, `List.nth`) | zero |
| `Result` for expected failure | held; no `raise`/`failwith` in `lib/` |
| purity boundary | IO confined to `provider.ml` / `request.ml`; eight modules pure |
| determinism | `Array.sort String.compare` before digesting |
| RAII | `Fun.protect ~finally:close_in_noerr` |
| narrow exception classification | `Sys_error`, `End_of_file \| Invalid_argument` by name |

β's summary: "skill-level OCaml written without the skill", and that δ should fix
the token but not read this cycle's code as evidence of harm.

Recording it as fact: the token is δ-side and still unsubstituted for the next α
dispatch. The relevant observation for the pattern log is that the *absence* was
detectable and declarable by α without the skills — I could see the path did not
resolve — whereas the *consequence* was only checkable by someone holding them.
Declaring unresolvable inputs as debt, rather than quietly proceeding, is what
made that division of labour work.

### 4. Two design tensions I resolved and stated rather than leaving for β

Recorded because both were places a reviewer could reasonably have disagreed, and
neither generated a finding:

- **Confinement as a link-time refusal.** The design's gate 7 says path escapes
  are "denied and retained in the trace", which reads as *emit a receipt*; #126
  AC6 — a backward-compat invariant here — requires **zero receipt bytes**. These
  conflict. I resolved in favour of the invariant and made it structural rather
  than conditional: `relative_path` is a *capability config type*, so an escaping
  literal never links. This also unified gate 11 with AC12 instead of trading
  them off. The dynamic case (a path arriving through an input port) is still
  confined inside the provider.
- **`check` is deliberately not `verify`.** A standalone verifier is the declared
  next cell. Naming the subcommand `check` and scoping it to structural admission
  — with its header saying what it does *not* do — was the alternative to either
  building a verifier out of scope or letting a structural pass be mistaken for
  a verified receipt.

### 5. Sub-threshold item β raised and did not make a finding

`make cases` ends with `test $$rows -ge 0`, which is always true and asserts
nothing. β explicitly declined to raise it: `genericity` and `vet-ir` both fail
loudly on an empty discovery set and run *before* `cases` in the gate, so the
gate as a whole is not vacuous. Carried as debt **D9** in `self-coherence.md` so
it is not lost, and left in place rather than fixed in a documentation-only
round.

Same shape as #127's sub-threshold observation: a vestigial assertion that reads
as a check and is not one. Two occurrences across three cycles.

### 6. Debt state at close

| # | State |
|---|---|
| D1 | open — δ-side scaffold token; no code consequence found |
| D2 | open — `wall_time_ms` carried, not enforced (no monotonic clock without Unix) |
| D3 | open — checker configuration scalar-valued in v0 |
| D4 | **corrected** (F2) — fidelity limitation, not a termination hazard |
| D5 | open — one warrant obligation form; Ascent-0 will need more |
| D6 | **closed by β** — CI green on `df4e64b` (`coh-min`, `ci`, `CDD Artifact Validate`) |
| D7 | **closed by β** — the `DUNE` shim's `runtest` really executes the test binary (β re-ran it that way independently); CI runs real `dune build`/`runtest` on OCaml 5.2 |
| D8 | **closed** — this file |
| D9 | new — vacuous `test $$rows -ge 0` in `make cases` |

---

## Engineering-level reading

Three cycles on the same slice, and the same asymmetry each time: **the
mechanized claims held and the prose claims did not.**

Everything in #129 that is checked by a target survived β's adversarial
re-derivation — the 30-block requiredness matrix (β falsified it and it failed
loudly), the genericity gate (β injected three leak classes and each failed with
`file:line`), the 3-of-8 `0.1` comparison, the commit statistics, the provider
count, every README comparison-table cell. β's summary: accurate on every claim
independently checked, with F2 the sole exception, and F2 *under*-claimed.

The two findings were both sentences. One asserted an exhaustive property of a
space the code enumerates elsewhere in the tree; the other asserted a runtime
behaviour I had reasoned about instead of running. Neither was expensive to fix —
together roughly an hour against a cycle of many — but each cost a review round,
which is the actual price.

What is new this cycle is that I now have negative evidence about the remedy I
proposed last cycle. The lexical claim-audit row would have missed F1 while
flagging 40 innocent lines in the same file. A trigger list induced from two
examples did not generalize to a third in the same class, because the class is
defined by *what a sentence quantifies over*, not by which words it uses. That is
a more useful thing to have learned than another restated intention, and it is
why I have not proposed a revised word list here.

The one shape that did generalize is visible in observation 2: when a claim was
turned into a discovery — read the enumeration from the artifacts that define it,
rather than guessing a pattern that matches it — it caught its own author twice
during construction. `make genericity` is the only claim in this slice that is
audited continuously rather than at review, and it is the only claim in this
slice that has never been wrong. Whether more prose claims can be pulled across
that line is a question for triage, not a disposition I should make here.

Two things I would want a future α on this slice to know:

1. **The `0.1` → `0.2` requiredness matrix does not resemble its predecessor.**
   The scaffold warned about this and was right: at `0.1`, three of eight blocks
   were CUE-blind; at `0.2`, zero of thirty. Anyone assuming continuity would
   have shipped a false table.
2. **The next cell is the verifier, and the receipt was built for it.** Matched
   `rule_id`, exact fact references with content digests, the three digest
   bindings, provider and runtime identities, and skips carrying their cause.
   The non-short-circuiting evaluator exists specifically so `fact_refs` is exact
   rather than a superset — that decision only pays off in the cell that replays
   the derivation.
