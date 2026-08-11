# beta-closeout — cycle/126

**Issue:** usurobor/tsc#126 — *coh-min: execute example.readme-present end to end (M2/M3 standalone runtime tracer)*
**Branch:** `cycle/126` · **Merged to `main`:** `e8b8319` (parents `32dfda8` + `4204077`)
**Rounds:** 2 — R1 `REQUEST CHANGES` (1×C), R2 `APPROVED` (0 findings)
**Review base:** `origin/main` = `32dfda8` (both rounds) · **Heads reviewed:** R1 `18ce1de`, R2 `515b233`
**Verdict commits:** R1 `704b57f`, R2 `4204077`

Post-merge β close-out: review context + release evidence. Written on a δ re-dispatch after the merge landed without the protocol-required close-outs. Factual record and β-side self-assessment; cycle-level triage is γ's.

## Review Summary

Two rounds, both against a base of `32dfda8` (main did not move during the cycle; merge-base equalled main tip at every pass, so the merge was a clean fast-forward candidate).

**Round 1 (head `18ce1de`) — REQUEST CHANGES.** All 7 ACs verified PASS under my own independent rebuild; one C finding (F1) on a claim/exit-code defect. I did not take α's `self-coherence.md` as evidence: every number it reported (result classes, `size_bytes: 100`, `plan_digest`, the `source_digest` ↔ `.cm` correspondence) I reproduced from my own binary, and all of them held.

**Round 2 (head `515b233`) — APPROVED.** Bounded re-verification of the F1 fix plus a no-regression sweep of the happy path. F1 closed with the regression pair I required; no new finding.

Verification method both rounds: `dune` is unavailable in the review cell (a γ-verified environment fact), so I rebuilt the slice with a flat `ocamlopt` compile (4.14.1) of `lib/{sha256,json,provider,runner}.ml` + a wrapper module + the CLI + a `sed`-dequalified copy of the test file, in scratch space outside the worktree. The canonical `dune build`/`dune runtest` evidence is the CI run on each reviewed SHA. The proxy and CI agreed at every pass.

## Implementation Assessment

The slice delivers what the issue asked: a real provider reads the disk and the receipt changes with the subject, which static IR validation cannot produce. 23 files, all additive, in a new build root with its own `dune-project`; no existing binary, schema, or example touched.

Implementation-contract conformance (β Rule 7) was verified axis-by-axis against the 7 δ-pinned rows, not inferred from behavior:

- **Vendored-verbatim** — I ran `diff` against `../ascent-0/lib/` myself in both rounds: `json.ml` and `sha256.ml` byte-identical. The R2 fix correctly stayed in α's own `runner.ml` rather than patching the vendored parser, preserving this axis.
- **Stdlib-only** — grepped all coh-min sources for `Unix.`/`Str.`/yojson/ppx: only prose mentions of the prohibition. No `.opam` file.
- **Canonical JSON / receipt format** — I recomputed `plan_digest` two independent ways (re-rendering the receipt's own embedded plan through the vendored serializer, and `sha256sum` on the rendered bytes); both matched the emitted `sha256:75b80418…8324a6`.
- Remaining axes (CLI shape, package scoping, additivity, runtime deps) confirmed against the diff.

Quality read: the code is strongest exactly where a pure function was paired with a direct test of its negative space — `confine` carried 8 admit/deny cases and produced zero findings across both rounds. It was weakest where a prose comment stood in for a test, which is precisely where F1 lived.

## Technical Review — F1

**Finding (R1, severity C, honest-claim + judgment).** `Runner.run` caught only `Sys_error` and `J.Parse_error`, while its own comment claimed the guard "keeps every IR fault fail-closed (a clean [Error], never an escaping exception)" and `bin/coh_min.ml` documented exit 1 for malformed IRs and exit 2 for usage errors.

**How I established it.** Not by reading the guard and reasoning about it — by probing the parser's exception space from outside. After the ACs passed I ran a short series of malformed-IR inputs through the CLI to see whether the documented exit-code contract held across the *class*, rather than for the one malformed input the suite already covered. Two inputs broke it:

| Input | R1 behavior | R2 behavior (re-run by me) |
|---|---|---|
| IR with number literal `12e` | `Fatal error: exception Failure("float_of_string")`, exit **2** | exit **1**, `✗ coh_min: IR error: float_of_string`, no receipt |
| IR with truncated `\u00` escape | `Fatal error: exception Invalid_argument("String.sub / Bytes.sub")`, exit **2** | exit **1**, `✗ coh_min: IR error: String.sub / Bytes.sub`, no receipt |

Both are malformed-IR faults that the CLI contract assigns to exit 1; both escaped uncaught into the code reserved for usage errors. The confinement invariant itself was never at risk (no receipt was emitted, exit stayed non-zero), which is why this was C and not D — a contract/claim defect, not a fail-open path.

**Round-2 re-verification.** The fix (`a563beb`) added `Failure` and `Invalid_argument` arms funnelling to `Error ("IR error: " ^ msg)`, in α's own code. I checked three things beyond re-running the counterexamples:

1. **Diff scope** — exactly three files changed (`lib/runner.ml`, `test/test_coh_min.ml`, `self-coherence.md`); vendored files re-diffed byte-identical.
2. **`Sha256.self_test ()` deliberately left outside the guard** — correct, and I checked it rather than assuming: a broken hash implementation must still abort as a programmer-error invariant instead of being mislabelled "IR error". Within the guarded block, `Failure`/`Invalid_argument` can realistically only originate in the vendored parser, so the label is accurate in scope.
3. **The regression tests actually bite** — the check I consider the load-bearing one. A test that passes on fixed code proves nothing about whether it would have caught the bug. I rebuilt the *pre-fix* `runner.ml` from `18ce1de` against the *round-2* test file and confirmed exactly the two new checks FAIL there (suite exit 1), while the round-2 runner passes 14/14. The tests assert the `IR error` prefix on the `Error` path with an explicit `| exception _ -> false` arm, so an escaping exception fails the check rather than killing the test process — which is why the original coverage missed this class at all.

**No-regression sweep (R2):** present → `README_PRESENT`, absent → `README_ABSENT`, `cmp` differs, both receipts `cue vet` clean, escape IR still denied at exit 1.

## Release Evidence

CI conclusions I personally checked, per reviewed SHA:

| SHA | Role | `coh-min` | Other |
|---|---|---|---|
| `18ce1de` | R1 head | run 31469158338 **success** | `ci` success; `CDD Artifact Validate` success |
| `704b57f` | R1 verdict | run 31469818864 **success** | — |
| `515b233` | R2 head (approved) | run 31470000111 **success** (build → 14-check runtest → gate → confine, OCaml 5.2) | — |
| `e8b8319` | merge to main | — | `CDD Artifact Validate` **failure** |

The R2 approval rested on run 31470000111 green on the exact approved SHA, satisfying review rule 3.10.

**Gate state at close-out.** `CDD Artifact Validate` on `main` went success (`32dfda8`) → **failure** (`e8b8319`): the merge landed without the close-out artifacts the gate requires. Running `scripts/validate-release-gate.sh` locally at `47b5976` reports three missing artifacts, not one:

```
❌ RELEASE.md missing at repo root — required before tag
❌ cycle 126: missing beta-closeout.md — required before merge
❌ cycle 126: missing gamma-closeout.md — required before merge
```

This file closes the second row only. `gamma-closeout.md` is γ's and `RELEASE.md` is δ's release-boundary artifact; the gate will stay red until both land. I flag this so the omission is not mistaken for closed by this commit alone.

**Process note on the merge itself.** Per `beta/SKILL.md`, merge is β's authority and the pre-merge gate (identity truth, canonical-skill freshness, non-destructive merge-test, γ-artifact completeness) is β's to run. This cycle was merged by δ outside that sequence, so those four rows were never executed against the merge tree, and the close-out collection they gate was skipped — which is the direct cause of the red gate above. Recording it as a factual process observation, not a triage disposition.

## Review-Quality Assessment — what I did not check

### The IR was never validated against the canonical schema

Cycle #127 found that `examples/readme-present/ir/readme-present.ir.json` does not validate against the project's canonical `#NormalizedCMIR`. I re-verified this myself at close-out rather than taking it on report:

```
$ cue vet runtime/coh-min/examples/readme-present/ir/readme-present.ir.json schema.cue -d '#NormalizedCMIR'
receipt_contract.kind: incomplete value string    → exit 1
$ cue vet runtime/ascent-0/ir/ascent0.ir.json schema.cue -d '#NormalizedCMIR'
                                                  → exit 0
```

The control matters: the sibling IR passes the same schema with the same command, so the schema is satisfiable and known-good, and coh-min's IR fails because it lacks a `receipt_contract` block entirely. One command, seconds to run.

**Did I miss it, or was I correctly bounded by the stated ACs? My honest view: I should have caught it, and "the ACs didn't ask" is not a sufficient defence.**

The distinction I got wrong is between two different things ACs control:

- ACs bound the **approval gate** — what must pass before I may approve.
- ACs do **not** bound the **search space** — what I examine, and what I may report.

A reviewer who only executes the AC list is running a checklist, not an adversarial review. The whole value β adds over CI is finding what the AC author did not think to ask for. δ's ACs were the thing that failed here; a reviewer whose search space is defined entirely by δ's ACs cannot ever catch a δ-side failure, which makes β structurally incapable of catching the most consequential class of error in the process. That is not a defensible role boundary.

Three facts make the miss worse rather than better, and I want them on the record:

1. **I was already in exactly this frame.** I ran `cue vet` four times on receipts and went further, building negative probes (stray field, bogus `result_class`) to prove the receipt contract actually bites. I was thinking hard about CUE conformance for the whole review — and applied it only to the output.
2. **The IR was already in my hands as an artifact worth verifying.** I checked that its `source_digest` genuinely equalled `sha256sum` of the `.cm`. I verified the IR's *provenance* and never its *conformance*. It was not an artifact I overlooked; it was one I picked up, tested for one property, and put down.
3. **The harvest source carries the gate.** The issue names Ascent-0 as the harvest source. `ascent-0/Makefile` has a `vet-ir` target wired into its `check`. I diffed the vendored *files* against ascent-0 byte-for-byte, twice — and never diffed its *gate set*. `grep -n vet ascent-0/Makefile`, which I ran today in seconds, would have surfaced it immediately.

The structural pattern, stated plainly: **the acceptance oracle validated the output artifact and not the input artifact, in a slice whose entire thesis is "execution beats static validation."** The one static validation the cycle did own was pointed only downstream. That asymmetry was visible in the artifact set I was holding, and I had the CUE toolchain open at the time.

My review also over-asserted on this point. Rule 3.7 requires approval to close the search space, and I wrote that "no remaining blocker was found in the relevant contract." That claim was broader than the search behind it — the same defect class as F1, which I had just finished flagging in α's code one round earlier. Worth naming: I applied the scope-of-claim discipline to α's comment and not to my own verdict.

**The counterweight, so the lesson is bounded.** Unbounded review is a real failure mode too. If β is expected to imagine every invariant the repo might hold, review becomes taste-driven and starts producing phantom blockers, which rule 3.5 forbids. So the corrective is not "check everything." It is two mechanical, bounded heuristics:

- **Schema census.** For every data artifact a diff adds or changes, grep the repo for a schema or contract that claims to govern that format; if one exists, vet against it and record the result — pass or fail. Bounded by the number of data artifacts in the diff, not by imagination.
- **Harvest-parity check.** When a cycle declares it harvested or vendored from a sibling (this one declared it in the issue, the `dune-project`, and the README), diff the sibling's **gate/target set** against the cycle's, not only the copied source. A harvest source is a peer whose checks are a ready-made checklist.

**Disposition had I caught it in R1:** severity C — real incoherence, locally non-blocking, since the runtime executes the IR correctly and nothing user-visible breaks. Under rule 3.3 that is still not merge-ready, so it would have forced a round 3, or an explicitly filed design-scope deferral before merge under the 3.3 exception. The issue's non-goal ("Not cmc-emitted IR — the IR is hand-authored") does not cover it: hand-authored is a statement about provenance, not an exemption from conformance. #127 is that deferral, taken later and at higher cost.

**δ-side implication, which is the point of recording this:** ACs should name a conformance gate for every artifact a cycle **authors**, not only the ones it **emits**. The IR escaped because it was mentally filed as an input to the runtime, when it was equally an output of the cycle.

### A second, previously unreported instance of the same class

While writing this close-out I checked the other authored artifact I never verified, `examples/readme-present/readme-present.cm`, and believe it does not conform to the repo's actual surface language either.

The repo has a real surface compiler at `research/cm-language/surface/` (own `dune-project`, `bin/`, `lib/`, and 9 sibling `.cm` files). Every sibling uses the top-level form `cm <id> v<ver> (<subject>: <Type>) -> <ResultType> { question … target … }`. The cycle's file uses an entirely different invented form: `methodology "example.readme-present" version "0.1" { subject … measure … by … over … decide | … when … }`. The parser's top-level error messages in `lib/cm_surface.ml` all speak of a "`cm` block"; the token `methodology` appears only as an *input-kind field name* inside a step (line 426), not as a top-level declaration.

**Evidence depth, stated honestly:** this is a source-read plus sibling-corpus comparison, **not** an execution — I could not build `cmc` without `dune`. So I record it as a high-confidence observation requiring one confirming command (`cmc examples/readme-present/readme-present.cm`) rather than as an established fact. Mitigating context: the `.cm` is documented in-tree as intent-recording only, and the issue's non-goals exclude cmc-emitted IR. It is nonetheless the same class as the IR gap — an authored artifact never checked against its in-repo canonical form — and it is the third instance of that class in one cycle. Two of the three were mine to catch.

γ may want to fold this into #127's scope rather than open a third cycle, since the fix surface overlaps.

## Process Observations

- **The proxy-build risk was real and unpriced.** Both α and I verified locally on OCaml 4.14.1 via flat `ocamlopt` against a contract pinning 5.2, with a warning set that differs from dune's defaults. CI covered the gap at every pass and no defect escaped through it — but "α and β both used the same proxy technique" means our verifications were correlated, not independent, on that axis. Independence held on everything I could execute directly; it did not hold on the toolchain itself.
- **What worked: differential probing over code-reading.** F1 came from running inputs the author had not run, not from re-reading the guard. The confinement surface, which I probed the same way, was clean. The technique that found the one real defect is the technique to keep.
- **What worked: proving the regression bites.** Rebuilding the pre-fix runner against the new tests turned "α says the tests cover it" into an executed fact, and it cost one extra compile. This should be routine for every RC fix round, not a flourish.
- **A finding I did not raise but should note:** `plan_json` omits each step's `config` from the digested plan, so two IRs differing only in `config.relative_path` produce the same `plan_digest`. I judged provenance adequately preserved (`source_digest` plus evidence `relative_path`) and did not raise it. That reasoning still holds for this slice, but the property is worth revisiting at the M1 receipt unification, since a plan digest that does not cover provider configuration is a weak content address.

## Release Notes

Cycle #126 ships `research/cm-language/runtime/coh-min/` — a standalone, stdlib-only OCaml runtime tracer that executes the first *ordinary* CM end to end. It loads a hand-authored NormalizedCMIR, links a SandboxExecutionPlan, executes a finite provider DAG by input readiness, invokes the real `file.exists` provider against a subject directory, and emits a canonical-JSON `MeasurementReceipt` (`tsc-measurement-receipt/0.1`). The receipt changes with the subject — `README_PRESENT` vs `README_ABSENT` — because a real provider read the disk.

Additive only: no existing binary, schema, or example changed. New CI workflow `.github/workflows/coh-min.yml` (build → runtest → `make gate` AC1–5 → `make confine` AC6) triggers on `cycle/**` and `main`.

Known limitations carried into `main`, all declared before review: the decision projection is hardcoded per-`cm_id` (any other CM yields fail-closed `INCOMPLETE`); path confinement is lexical, not `realpath`, so a symlink inside the subject can point outside it; `size_bytes = -1` is a sentinel for absent-or-directory targets; `plan_json` omits step `config` from the digest; no `.mli` interfaces. Open follow-up: the shipped IR does not validate against `#NormalizedCMIR` (cycle #127), and — pending confirmation — the shipped `.cm` does not parse under the repo's surface compiler.

β work on this cycle is complete: review (2 rounds) and this close-out. Tag, deploy, and release-boundary artifacts are δ's; the PRA is γ's.
