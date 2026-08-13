# β review — cycle/129 (usurobor/tsc#129)

**Verdict:** REQUEST CHANGES

**Round:** 1
**Review head:** `df4e64b` (`cycle/129`)
**Diff base:** `origin/main` = `c8ffc2a` (re-fetched synchronously at review time)
**Branch CI state:** green on the reviewed head — see §CI status
**Findings:** 1 × B, 1 × A. No D, no C.

α's implementation is strong. Every one of the 13 ACs passes under evidence I
generated myself, not evidence I read from `self-coherence.md`. The headline
genericity claim survives the hardest test I could build for it: I authored a
third methodology and ran it without touching a `.ml` file. The two findings
below are both documentation-truth defects, both cheap, and neither touches
behaviour. They are raised because review rule 3.3 admits no "approve with
follow-up" — not because the engineering is in doubt.

---

## Verification method

`dune` is unavailable in this cell, so I did not rely on α's `DUNE` shim
result. I rebuilt from source independently:

- flat `ocamlopt` (OCaml **4.14.1**) over `lib/*.ml` in the `lib/dune` module
  order, plus a driver from `bin/coh_min.ml` with the `Coh_min.` prefix
  stripped — compiled clean, zero warnings;
- the same for `test/test_coh_min.ml` → **167 checks run, all passed**;
- `make gate` driven through a shim whose `runtest` really executes that test
  binary (so `make test` was not a silent no-op) → **GATE PASSED**;
- `cue` v0.9.2 at `/usr/local/bin/cue` for every schema claim.

CI builds the same tree under real `dune` on OCaml **5.2**. Two compilers, two
build systems, same result.

---

## §2.0.0 Contract Integrity

| Check | Result | Notes |
|---|---|---|
| Status truth preserved | yes | README §Honest scope distinguishes shipped / deferred / not-enforced precisely; `bounds.wall_time_ms` is explicitly "carried and propagated but not enforced" rather than implied working |
| Canonical sources/paths verified | yes | design pinned at `61ba4d2`; `research/cm-language/schema.cue` confirmed untouched (0 files in diff) |
| Scope/non-goals consistent | yes | no `verify` subcommand, no `CheckRequest`/`CheckOutcome` wire artifacts, no `invoke_cm`/`semantic_judgment`/`oracle`/`transform` — those kinds are *refused*, not silently accepted (`lib/ir.ml:84` `executable_kinds = [ "mechanical" ]`) |
| Constraint strata consistent | yes | required vs optional output ports are enforced in both directions; see AC3 |
| Exceptions field-specific/reasoned | yes | `refusals.tsv` records a per-fixture `cue` verdict and the gate asserts it in *both* directions |
| Path resolution base explicit | yes | subject-relative, confined; `..` refused at link and again at the provider (defence in depth) |
| Proof shape adequate | yes | invariant + oracle + positive + negative + operator-visible projection present for every AC |
| Cross-surface projections updated | yes | `.github/workflows/coh-min.yml` runs each gate stage as its own named step |
| No witness theater / false closure | yes | the requiredness matrix is *generated* from real emitted artifacts and printed by the gate; I falsified it deliberately and it failed loudly (AC7) |
| PR body matches branch files | yes | README rewritten at `41195a7` matches branch head |
| γ artifacts present (gamma-scaffold.md) | yes | `.cdd/unreleased/129/gamma-scaffold.md` present — rule 3.11b satisfied |

---

## §2.0 Issue Contract — AC coverage

| # | AC | Status | Evidence I personally ran |
|---|----|--------|---------------------------|
| 1 | Genericity | **PASS** | See §Genericity below — the decisive test |
| 2 | One new provider, stdlib-only | **PASS** | `a8b0c9a` had one mechanical provider (`file_exists`); head has exactly two capabilities, `fs.file-exists` + `fs.text-metrics` (`lib/provider.ml:218,280`). Boundary stated in README — but see **F1** |
| 3 | Real DAG, required/optional ports | **PASS** | `repo-legibility` = 3 steps, 2 independent + 1 binding `readme_locate.path`. `bare` case: `readme_locate` ends **success** with `withheld=['path']` (lawful withholding on a success), `readme_depth` is a principled skip naming the port. `tight` case reaches INCOMPLETE by a *different* route (refused-by-bounds). Linker refuses a withholdable port declared `required: true` with a message telling the author what to do instead. Unit tests confirm "a success missing a required output is rejected, not downgraded" is non-vacuous (`test/test_coh_min.ml:706`) |
| 4 | The result rule is data | **PASS** | `Runner.classify` existed at `a8b0c9a:lib/runner.ml:154` as literally `if pl.cm_id = "example.readme-present"` — the exact construct the issue named. It is **deleted**; no `let`/`and classify` survives anywhere in `lib/` or `bin/`. Receipts record `rule_id` and `fact_refs` |
| 5 | Fact provenance | **PASS** | `undeclared-fact` refuses with **`IR error:`** — i.e. at *load*, not evaluation, exactly as the AC demands |
| 6 | Result honesty | **PASS** | undeclared class, missing `default`, and provider-supplied `result_class` all refused; the last is dropped at projection (`test_coh_min.ml:700`) — never authoritative |
| 7 | Schemas 0.2, required by construction | **PASS** | Proven by falsification: I rewrote every `field!:` → `field:` in `contracts/*.cue` and re-ran the matrix — **11 of 30 blocks went CUE-blind and the gate failed loudly**. Restored; back to 30/30. `field!:` is the lever, and `format` (a concrete literal) is among the blind — confirming the amendment's "concreteness is not the lever". 8 non-vacuity fixtures all rejected |
| 8 | Gate 9 negative fixtures | **PASS** | Rebuilt the matrix myself: **30 blocks across 4 families, 30 refused by `cue vet`, 30 refused by the runtime, 0 CUE-blind**. Negatives are generated from *real emitted artifacts*, so they cannot drift from the positives. I also reproduced α's `0.1` comparison against `schema.cue` on main by deleting each of the 8 blocks: `format`, `procedure`, `result_contract` are blind — **3 of 8, exactly as claimed** |
| 9 | RunRequest + named snapshot scheme | **PASS** | Emitted subject: `{digest, kind: directory_snapshot, scheme: "directory-merkle/0.1"}`. Absent and unrecognized schemes both refuse fail-closed |
| 10 | Digest binding | **PASS** | Tests pair "still ADMITS structurally" with "is refused" for each of request / cm_ir / plan — precisely the AC's "must fail even though every field is individually well-typed" |
| 11 | Config schemas at link time | **PASS** | All three config refusals emit **`link error:`** and name the capability contract; nothing reaches the provider |
| 12 | No regression | **PASS** | `readme-present` still yields README_PRESENT / README_ABSENT with distinct receipts; confinement denies with **0 receipt bytes** (measured, not assumed) |
| 13 | `make gate` + CI green | **PASS** | Gate passes locally; CI green on `df4e64b` — see §CI status |

---

## §Genericity — the headline, tested past the commit statistic

**The commit claim checks out.** `f97d57e` adds `examples/repo-legibility/`
(20 files, 2995 insertions) and touches **zero `.ml` files**.

**The gate bites.** I introduced each leak class and confirmed failure with
`file:line`, then reverted (tree verified clean):

| Leak I injected | Gate result |
|---|---|
| `let _leak_cm_id = "example.repo-legibility"` in `lib/runner.ml` | FAIL — "named in the acceptance path" |
| `let _leak_class = "README_PRESENT"` in `bin/coh_min.ml` | FAIL — "result class named in the acceptance path" |
| `let classify x = x` in `lib/runner.ml` | FAIL — "a CM-specific classifier survives" |

The gate discovers CM ids and result vocabulary *from the shipped IRs*, so a
third methodology is covered the moment it exists. That is the right shape: it
cannot rot as methodologies are added.

**But the gate is not the claim.** The claim is that a differently-shaped third
methodology needs no OCaml. So I wrote one — `example.changelog-hygiene`, as
data alone, outside the repo, against the binary built from this branch:

- **4 steps** (3 independent + 1 dependent) — a shape neither shipped CM has;
- operators `or`, `ne`, `lt`, `gt`, `present` — **five the shipped CMs never
  exercise**, plus the `present` predicate over a withholdable port;
- **5 result classes**, a 5-rule table, different obligations;
- the `count_blank_lines` optional config and the `byte_size` port, both
  **unused by either shipped CM**.

Result — five subjects, five classes, each via the intended rule, all receipts
byte-distinct, and every receipt and the IR itself vet clean against the `0.2`
contracts:

| subject | class | rule |
|---|---|---|
| full | MAINTAINED | `maintained` |
| stub | STUB_CHANGELOG | `stub` |
| nolicense | UNGOVERNED | `ungoverned` |
| nochangelog | NO_CHANGELOG | `no-changelog` |
| nodocs | NO_CHANGELOG | `no-changelog` |

The `nochangelog` skip trace reads:

```
required input "target" of step "changelog_depth" binds changelog_locate.path,
which step "changelog_locate" did not publish (step "changelog_locate" ended success)
```

It names the unpublished port *and* records that the upstream step succeeded —
so a reader can tell lawful withholding from failure. **Zero OCaml lines were
written or changed.** The headline claim is real.

**The one axis where it is not true** is F1 below: a methodology needing a
receipt extension family other than `repository_measurement` must edit
`lib/receipt.ml:62` *and* `contracts/receipt.cue:148`. The runtime refuses such
an IR cleanly and legibly — the behaviour is correct and by design. Only the
README's absolute phrasing is wrong.

---

## §CI status (rule 3.10 — binding)

Required workflows on review head `df4e64b`:

| Workflow | Conclusion |
|---|---|
| `coh-min` | **success** |
| `ci` | **success** |
| `CDD Artifact Validate` | **success** |
| `CDD Telegram Notifier` | skipped (notification only, not required) |

This closes α's debt **D6** (CI unobservable from its cell).

**On α's debt D7** (local gate ran under a `DUNE` shim, so real `dune build`
was never exercised locally): **adequately covered, not a gap.**
`.github/workflows/coh-min.yml` runs `opam exec -- dune build` and
`opam exec -- dune runtest` under OCaml 5.2, then every gate stage as its own
named step, and it is green on this exact head. My independent flat `ocamlopt`
build on OCaml 4.14.1 is a second, differently-configured compiler over the
same sources. The shim was a reasonable cell-local accommodation and CI is the
authority that closes it.

---

## §Architecture Check

| Check | Result | Notes |
|---|---|---|
| Reason to change preserved | yes | one concern per module, and the `lib/dune` module list *is* the dependency order — layering is checkable by reading it |
| Policy above detail preserved | yes | result policy lives in the CM's rule table; the evaluator is generic |
| Interfaces remain truthful | yes | capability contracts declare ports, slots, config and grants; the linker enforces all four |
| Registry model remains unified | yes | one `registry` list pairs capability with provider; artifact families are table-driven |
| Source/artifact/installed boundary preserved | yes | `contracts/` (0.2) is deliberately separate from `schema.cue` (0.1) until promotion |
| Runtime surfaces remain distinct | yes | parse / bind / link / execute / evaluate / emit are separate modules with no back-edges |
| Degraded paths visible and testable | yes | skip, refuse, withhold and fail are distinct statuses, each recorded in the trace with a reason |

---

## §Engineering quality — and α's debt D1

**D1 is real and it is δ's error** (the scaffold left `SKILLS_ROOT`
unsubstituted, so α authored without `eng/ocaml`). I hold those skills. Asked
plainly whether their absence shows in the code: **it does not.** I checked the
skill's own smell list against the diff:

| `eng/ocaml` rule | Result in this diff |
|---|---|
| 3.10 `with _ -> []` / `None` / `""` | **zero occurrences** outside vendored files |
| 3.10 partial functions (`List.hd`, `Option.get`, `List.nth`) | **zero occurrences** |
| 3.3 `Result` for expected failure, no exceptions for domain errors | held throughout; no `raise`/`failwith` in `lib/` (only prose in comments) |
| 3.2 purity boundary | IO confined to `provider.ml` and `request.ml` (the adapters); `ir`/`rule`/`linker`/`exec`/`receipt`/`plan`/`value`/`jread` are pure |
| 3.6 determinism | `Array.sort String.compare` on `Sys.readdir` before digesting — readdir order cannot leak into a digest |
| 2.9 RAII | `Fun.protect ~finally:close_in_noerr` |
| 3.3 narrow exception classification | `Sys_error` and `End_of_file \| Invalid_argument` handled *by name*, each converted to a specific `Error` string |
| 3.4 fallback is visible and justified | unreadable subject entries **refuse the whole snapshot** rather than being silently omitted, with the reasoning written down |

I probed for the failure this pattern usually hides — a directory walk raising
outside its `try`. Both a **dangling symlink** and a **symlink loop** terminate
fail-closed: exit 1, 0 receipt bytes, one clear sentence. This is skill-level
OCaml written without the skill. δ should still fix the scaffold token, but it
should not read this cycle's code as evidence of harm.

---

## Findings

| # | Finding | Evidence | Severity | Type |
|---|---|---|---|---|
| F1 | The README's genericity boundary is stated absolutely, and one axis falsifies it. `README.md:19-21` says adding a methodology means **"No OCaml, no Makefile rule, no CUE contract."** A methodology that declares a receipt extension family other than `repository_measurement` requires editing **both** `lib/receipt.ml:62` (`families = [ (repository_measurement, …) ]`) and `contracts/receipt.cue:148` (`family!: "repository_measurement"`). I reproduced it: an IR identical to my working third methodology except `receipt.family = "changelog_measurement"` is refused with *"extension.family … is not a known receipt family ["repository_measurement"]"*. The refusal is correct and the closed-family design is right — but AC2 requires the boundary be *crisp and stated in the README*, and §Honest scope (`README.md:351-369`) enumerates every other closed set (two providers, FLAT-only step kinds, the v0 algebra "and nothing else", one obligation form, one snapshot scheme) while omitting this one. A reader adding a non-repository methodology is told they will touch no CUE, and then must. | `README.md:19-21`, `README.md:351-369`, `lib/receipt.ml:62`, `contracts/receipt.cue:148` | **B** | honest-claim |
| F2 | `self-coherence.md` D4 asserts *"a subject containing a symlink loop would not terminate. No shipped fixture has one."* Measured, that is false — and false in the safe direction. I built a subject with a `sub/up -> ../` loop and ran it: the walk terminates in well under a second with exit 1, 0 receipt bytes, and `scheme directory-merkle/0.1 cannot walk …`, because the OS path-resolution error surfaces as `Sys_error` and is already classified. The runtime is more robust than its own report claims. The declared debt should be corrected to what the code does (symlink *targets* are digested — which is true, named in the scheme, and genuinely worth declaring) rather than alleging a non-termination bug that does not exist. | `.cdd/unreleased/129/self-coherence.md:774-779`, `lib/request.ml:62-70` | **A** | honest-claim |

Both findings are documentation truth, not behaviour. No code change is
required for either.

---

## Regressions Required (D-level only)

None — no D-level findings.

---

## Notes

- **Contract axes (all 7 pinned rows conform).** Language OCaml stdlib-only —
  no `yojson`/`ppx`/`unix` anywhere (the only matches are comments explaining
  the prohibition). `lib/json.ml` and `lib/sha256.ml` **byte-identical** to
  `../ascent-0/lib/` (`diff` clean; CI re-checks with `cmp`). CLI target is the
  existing `coh_min` executable and `run --ir … --target …` still works.
  `research/cm-language/schema.cue` **untouched**. All changes confined to
  `research/cm-language/runtime/coh-min/**`, `.github/workflows/coh-min.yml`
  and `.cdd/unreleased/129/**` — I diffed the full path list against the
  permitted set and the remainder is empty.
- **Strongest thing in this cycle.** The `vet-negative` target generates
  negatives *from the artifacts a real run just emitted*, so a negative fixture
  cannot drift from the positive it negates, and it asserts **both** mechanisms
  independently. Most implementations of "gate 9" would have hand-written 30
  fixtures and quietly let them rot. This one cannot rot.
- **`make cases`** ends with `test $$rows -ge 0`, which is always true and
  asserts nothing. Not raised as a finding: `genericity` and `vet-ir` both fail
  loudly on an empty discovery set and run *before* `cases` in the gate, so the
  gate as a whole is not vacuous. Worth tidying whenever that file is next
  touched.
- α's self-report was accurate on every claim I independently checked
  (30-block matrix, the 3-of-8 `0.1` comparison, the commit statistics, the
  provider count, every README comparison-table cell). F2 is the sole
  exception, and it under-claims rather than over-claims.

---

## Merge instruction (on clearing F1 and F2)

α lands both documentation fixes on `cycle/129`; β re-reviews the two surfaces
and, on a clean round 2, merges with:

```
git merge --no-ff cycle/129    # into main, with "Closes #129"
```
