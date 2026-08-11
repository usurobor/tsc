# alpha-closeout — cycle/126

**Issue:** usurobor/tsc#126 — *coh-min: execute example.readme-present end to end (M2/M3 standalone runtime tracer)*
**Branch:** `cycle/126` · **Merged to `main`:** `e8b8319` · **Approved:** β round 2 (`4204077`)
**Final head reviewed:** `515b233` · **Rounds:** 2 (round 1 REQUEST CHANGES, 1×C; round 2 APPROVED, 0 findings)

Post-merge α-side narrative. Factual observations only; triage is γ's.

## Summary

Authored a new stdlib-only OCaml build root, `research/cm-language/runtime/coh-min/` (23 files, all additive), that runs the first *ordinary* CM end to end: load a hand-authored NormalizedCMIR → link a SandboxExecutionPlan → execute a finite provider DAG by input readiness → invoke the real `file.exists` provider against a subject directory → emit a canonical-JSON `MeasurementReceipt` (`tsc-measurement-receipt/0.1`).

- `lib/json.ml`, `lib/sha256.ml` — vendored verbatim from `../ascent-0/lib/` (β re-verified byte-identical in both rounds).
- `lib/provider.ml` — pure `confine` (lexical path confinement) split from its effectful stat shell; both report failure through `result`.
- `lib/runner.ml` — the harvested `link/execute/evaluate/emit` shape, generalized off Ascent-0's oracle-bearing runtime; DAG executor is a recursion over an immutable state record.
- `bin/coh_min.ml` (CLI), `test/test_coh_min.ml` (14 checks), `examples/readme-present/` (`.cm`, IR, escape IR, CUE contract, two fixtures), `Makefile` (`gate` = AC1–5, `confine` = AC6), `README.md`, `.github/workflows/coh-min.yml`.

Final evidence state: **14/14** test checks ok (8 confine + 4 end-to-end + 2 F1 regressions); CI `coh-min` green on `515b233` (run 31470000111: build → runtest → gate → confine, OCaml 5.2); all 7 ACs PASS under β's independent flat-`ocamlopt` rebuild; 7-axis implementation contract conformant on every axis.

## Friction log

- **dune unavailable in the cell** (γ-verified environment fact). Every local build/test claim I made was a flat `ocamlopt` proxy — compile `lib/{sha256,json,provider,runner}.ml` + a driver, and a `sed`-dequalified copy of the test file. The proxy tracked the canonical `dune build`/`dune runtest` faithfully (CI agreed both rounds, and β independently reproduced with the same technique), but it is a proxy: the local toolchain is 4.14.1 while the contract pins 5.2, and dune's default warning set differs from bare `ocamlopt -w +a`. Cost this cycle: no defect; the residual risk was real and unpriced at signal time.
- **Reference spike as input.** A verified-building off-protocol spike existed (`claude/tsc-recent-changes-onfjpj`). Reading it before authoring was cheap and useful for shape (Makefile gate structure, receipt field set). It also transmitted its blind spot: the spike had no tests and used `failwith` throughout, and the F1 defect below is a partial inheritance of that error-handling posture — I converted the core to `result` but kept the guard as narrow as the spike's implicit assumption that the parser only raised its own exception.
- **Two receipts, one digest.** `plan_digest` is identical across present/absent (same IR), so AC4's "not byte-identical" rests entirely on the run-specific fields. Confirming that was a deliberate check, not an accident, but it took a pass to convince myself the gate was testing execution rather than path strings.

## Observations

### F1 — root cause in my authoring

β round-1 finding (severity C, honest-claim + judgment): `Runner.run` caught only `Sys_error` and `J.Parse_error`, while its own comment claimed the guard "keeps every IR fault fail-closed (a clean [Error], never an escaping exception)" and `bin/coh_min.ml` documented exit 1 for malformed IRs, exit 2 for usage errors. β's counterexamples: an IR containing the number literal `12e` crashed with `Failure("float_of_string")`, and a truncated `\u00` escape with `Invalid_argument("String.sub / Bytes.sub")` — both at exit 2, both escaping uncaught.

Root cause, precisely: **I wrote a universal claim ("every IR fault", "never an escaping exception") from a survey of one exception constructor.** I had read the vendored `json.ml` closely enough to see `Parse_error` and its `fail` helper, and I hardened the guard specifically *because* I noticed `link`'s accessors raise — so the instinct was right and the sweep was not. `json.ml` also reaches `int_of_string`/`float_of_string` (line 94) and `String.sub` on the `\uXXXX` path (line 61), neither of which routes through `fail`. I enumerated the raise sites I had a name for instead of enumerating the exception classes the module can actually produce. The α skill's §2.3 rule against unenumerated universal claims is the governing rule; I applied it to peer *surfaces* (providers, IRs, fixtures — all enumerated in self-coherence) and did not apply it to the exception space inside a file I had vendored rather than written.

Compounding factor: **the comment was the specification, and nothing tested it.** My suite covered malformed-IR handling with a case (`{ "cm_id": "x" }`) that happens to raise `Parse_error`, so the coverage looked complete while exercising exactly the one class already caught. The two inputs that would have caught it crashed the *test process itself* — a failure mode my harness could not report as a failing check, only as a dead run.

Fix (`a563beb`): two arms added to the existing handler in my own code — vendored files untouched — plus the two named regressions, asserting the `IR error` prefix with an explicit `| exception _ -> false` arm so an escaping exception fails the check rather than killing the runner. β verified the tests bite by rebuilding the pre-fix runner against the new test file (both fail as expected) and confirmed exit 1 restored on both counterexamples.

What I would do differently: when a claim quantifies over a failure space ("every", "never", "any"), enumerate that space from the *source of the raises* — for a vendored dependency, read it for exception constructors and for stdlib partial functions (`*_of_string`, `String.sub`, `List.hd`, `Option.get`), not only for its declared error type — and write the negative test before the comment that asserts the property. A one-line grep of the vendored file for those call sites would have closed this at authoring time in under a minute.

### IR validity against the canonical schema (surfaced later by #127)

For the record: a later cycle (#127) found that the hand-authored `examples/readme-present/ir/readme-present.ir.json` does **not** validate against the project's canonical `#NormalizedCMIR` in `research/cm-language/schema.cue`. This was outside my cycle's oracle — δ's pinned ACs asked for receipt validation (`cue vet <receipt> contracts/receipt.cue -d '#MeasurementReceipt'`) and never asked for IR validation — so neither my self-coherence nor β's review had a reason to check it.

Two factual notes on how it got past the artifact set anyway:

- The sibling runtime I harvested from *does* carry that gate: `ascent-0/Makefile` has a `vet-ir` target running `cue vet ir/ascent0.ir.json schema.cue -d '#NormalizedCMIR'`, wired into its `check` target. I harvested Ascent-0's runtime *shape* (link/execute/emit) and its Makefile's receipt-vetting pattern, but not its IR-vetting target. My `Makefile` has `vet` (receipts) and no `vet-ir`. The peer that existed one directory over was not enumerated as a peer.
- My self-coherence called the IR "hand-authored" and cited its `source_digest` as genuinely computed (β confirmed the digest), which is true and was mistakable for a validity claim. It is a provenance claim, not a conformance one.

Pattern: **the acceptance oracle validated the output artifact and not the input artifact**, in a slice whose entire premise is "execution beats static validation." Surfaces affected: `research/cm-language/runtime/coh-min/Makefile` (no `vet-ir` target), `.github/workflows/coh-min.yml` (no IR-validation step), `examples/readme-present/ir/readme-present.ir.json`. Same class of gap as F1 at a different altitude — a claim's scope wider than the check behind it.

### Deferred debt carried into `main` (all declared in self-coherence §Debt before review)

- **Decision projection is CM-specific and hardcoded.** The `.cm`'s `decide` block is not lowered into the IR, so `Runner.classify` carries the `readme_presence → PRESENT/ABSENT` mapping for `example.readme-present` by `cm_id` and returns unclassified (fail-closed `INCOMPLETE`) for any other CM. Honest tracer scope per the issue's non-goals; documented in README §Honest scope, the `.cm` status note, and the function comment. A second ordinary CM cannot be run without touching this function.
- **Lexical, not `realpath`, confinement.** `confine` rejects empty/absolute/`..`-segment paths without touching the filesystem (the stdlib-only pin forbids Unix, and there is no stdlib `realpath`). A symlink *inside* the subject can therefore point outside it; the provider only stats existence, and β judged this adequate at this scope and not a finding. Named in README §Path confinement.
- **`size_bytes = -1` sentinel** for absent-or-directory targets; the CUE contract accepts any int rather than encoding the sentinel's meaning.
- **`plan_json` omits each step's `config`** from the digested plan. β noted the digest stays self-consistent and externally reproducible, and provenance survives via `source_digest` + evidence `relative_path`; flagged as worth revisiting when the M1 shared receipt unifies with Ascent-0's.
- **No `.mli` interfaces** on the three authored modules; every module is fully public. Not raised in review.

### Skill-gap candidates (observations, not dispositions)

- `eng/ocaml` §2.3/§3.3 states the Result-over-exceptions rule and §3.10's smell list catches `with _ ->` swallowing, but neither surface names the inverse failure: a `try` whose *arm set* is narrower than the exception space of the code it guards, especially across a vendored-module boundary. F1 sits exactly there — the guard was principled and incomplete, and no loaded rule made "enumerate the callee's exception classes" an authoring step.
- `alpha/SKILL.md` §2.3 peer enumeration is written around surfaces, docs, and skill-class peers. Both defects this cycle were enumeration failures over non-surface spaces: exception classes (F1) and sibling *gate targets* in a harvested-from project (the missing `vet-ir`). The §2.4 harness audit is the nearest existing surface and is scoped to "when the branch changes a parser, schema-bearing type, manifest shape, or runtime contract" — this branch authored a schema-bearing *input* consumed by an existing project schema, which reads as adjacent to, rather than inside, that trigger.
- Two occurrences this cycle of one class: a claim quantifying more widely than its check (F1's comment; the AC set's IR-vs-receipt asymmetry).

## Engineering-level reading

The slice does what the issue asked: a real provider reads the disk and the receipt changes with the subject, which static IR validation cannot produce. β independently reproduced every number I reported (receipt classes, `size_bytes: 100`, plan digest, `source_digest` = `sha256sum` of the `.cm`), so the evidence chain in `self-coherence.md` held up under adversarial re-run.

The cycle's two defects were both scope-of-claim defects rather than logic defects, and both were found by someone checking a boundary I had asserted rather than tested — β within the cycle, #127 after it. The code was strongest exactly where I had written a pure function and tested its negative space directly (`confine`: 8 cases, zero findings across two rounds), and weakest where a prose comment stood in for a test. That contrast is the reusable reading from this cycle.

Process note: the α close-out was not collected at merge time; this file was written on a post-merge re-dispatch after the `CDD Artifact Validate` gate went red on `cycle 126: missing alpha-closeout.md`. The cycle's artifact set is complete as of this commit.
