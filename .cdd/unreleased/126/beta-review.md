# beta-review — cycle/126

**Verdict:** REQUEST CHANGES (CHANGES_REQUESTED)

**Round:** 1
**Review base:** `origin/main` = `32dfda833a8dea0db765ea9332d3fab122f9d7d6` (re-fetched synchronously at review time; merge-base == main tip, branch is 3 commits ahead, fast-forward candidate)
**Review head:** `18ce1dee7df9172cad1184cef2155bd30b6c6ea2` (tip of `cycle/126`)
**Branch CI state:** green on review SHA (see §CI status)
**Merge instruction:** withheld — one C finding (F1) must be fixed on-branch first. On re-review approval: `git merge cycle/126` into `main` with `Closes #126`.

All evidence below was produced by β independently (flat `ocamlopt` build + probes in β's scratch space); α's `self-coherence.md` was treated as hypothesis, not evidence.

## §2.0.0 Contract Integrity

| Check | Result | Notes |
|---|---|---|
| Status truth preserved | yes | Tracer scope stated honestly everywhere: NOT `coh cm run`, IR hand-authored, `decide` not lowered (README §Honest scope, `.cm` status note, runner.ml comment). One local overclaim → F1. |
| Canonical sources/paths verified | yes | Vendor source `research/cm-language/runtime/ascent-0/lib/{json.ml,sha256.ml}` verified by β's own `diff`: both byte-identical. |
| Scope/non-goals consistent | yes | One provider (`file.exists`), one CM, no oracle/sealed-reveal/model-enumeration code present; unknown `provider_class` is an explicit `Error` (runner.ml:123-125). |
| Constraint strata consistent | yes | Stdlib-only pin honored: β grepped all coh-min sources — no `Unix.`/`Str.`/yojson/ppx (only comments naming the prohibition). No `.opam` file. |
| Exceptions field-specific/reasoned | n/a | No exception mechanism in the contract surface. |
| Path resolution base explicit | yes | `confine ~root ~rel` documents lexical confinement and its deliberate no-I/O rationale (provider.ml:31-39); concrete admitted/denied examples in tests. |
| Proof shape adequate | yes | Invariant (fail-closed confinement), oracle (`result` error + non-zero exit + no receipt), positive (2 admits), negative (5 denies + end-to-end escape run), operator projection (`make confine`, CI step), known gap (lexical-not-realpath, documented). |
| Cross-surface projections updated | yes | New workflow `.github/workflows/coh-min.yml` wired and green; README documents every make target; no existing projection touched (all-additive diff). |
| No witness theater / false closure | yes | β proved the CUE contract bites: a stray top-level field and a bogus `result_class` are both rejected by `cue vet` (closed structs + pinned vocabulary). |
| PR body matches branch files | n/a | No PR; review is branch-direct per CDS cycle protocol. |
| γ artifacts present (gamma-scaffold.md) | yes | `.cdd/unreleased/126/gamma-scaffold.md` present on `cycle/126` (rule 3.11b satisfied). |

## §2.0 Issue Contract

### AC Coverage

Local proxy: dune is unavailable in the review cell (γ-verified environment fact), so β rebuilt the slice with a flat `ocamlopt` (4.14.1) compile of `lib/{sha256,json,provider,runner}.ml` + a wrapper module + `bin/coh_min.ml` + `test/test_coh_min.ml` in scratch space; the canonical `dune build`/`dune runtest` evidence is the green CI run on the review SHA.

| # | AC | In diff? | Status | Evidence (β-run) |
|---|----|----------|--------|-------|
| 1 | `dune build` succeeds, OCaml 5.2, stdlib-only | yes | PASS | CI run 31469158338 on `18ce1de` (setup-ocaml 5.2, `dune build`) → success. β's flat `ocamlopt -w +a` build: only warning 4 (fragile-match, disabled in dune's default set, same pattern as vendored ascent-0) and warning 70 (missing-mli, likewise disabled). No opam deps; stdlib-only grep clean. |
| 2 | `fixtures/present/` → `README_PRESENT` | yes | PASS | β's binary: exit 0, `"result_class": "README_PRESENT"`; evidence `exists: true, is_directory: false, size_bytes: 100` (matches `wc -c` of the fixture README = 100). |
| 3 | `fixtures/absent/` → `README_ABSENT` | yes | PASS | β's binary: exit 0, `"result_class": "README_ABSENT"`; evidence `exists: false, size_bytes: -1`. |
| 4 | Receipts not byte-identical | yes | PASS | `cmp -s` on β's two receipts → differ (target_root, evidence observation, result_class). Also asserted in the test suite ("present and absent receipts differ"). |
| 5 | Both receipts `cue vet` against `#MeasurementReceipt` | yes | PASS | cue v0.9.2: both vet clean. β negative probes: stray field → "field not allowed"; `result_class: "BOGUS_CLASS"` → disjunction conflict. The gate is real. |
| 6 | Escaping `relative_path` denied (fail-closed) | yes | PASS | β ran the escape IR (`../README.md`): exit 1, 0 bytes on stdout (no receipt), stderr `✗ coh_min: relative_path "../README.md" contains a ".." segment and could escape the subject root`. Pure `confine` suite: 8/8 (empty, absolute, leading `../`, interior `a/../../b`, bare `..` denied; `..README` correctly admitted). See F1 for a *documentation/exit-code* defect on a sibling malformed-IR path — the confinement invariant itself holds. |
| 7 | `make gate` runs 1–5, fails loudly; CI green on cycle branch | yes | PASS | Makefile `gate` chains build→runtest-independent vet→grep-asserted classes→`cmp` with explicit `FAIL(ACn)` messages; `confine` target covers AC6. CI on `18ce1de`: coh-min success (run 31469158338), plus `ci` and `CDD Artifact Validate` success, Telegram notifier skipped (notification-only). |

Test suite (β-compiled): 12/12 checks ok, exit 0.

### Implementation contract (7 axes, δ-pinned) — β-verified

| Axis | Conforms? | β evidence |
|---|---|---|
| Language: OCaml stdlib-only; vendor json.ml+sha256.ml verbatim | yes | β's own `diff` vs `ascent-0/lib/`: json.ml IDENTICAL, sha256.ml IDENTICAL. Source grep: no Unix/Str/yojson/ppx anywhere in coh-min. `lib/dune` lists only in-tree modules. |
| CLI: standalone `coh_min` exe, `run --ir --target [--out]` | yes | `bin/coh_min.ml` implements exactly that surface; no reference from/to `src/engine/ocaml`. |
| Package scoping: own build root `research/cm-language/runtime/coh-min/` | yes | Own `dune-project` (lang dune 3.0); no source sharing with `src/engine/ocaml` or ascent-0 (vendored copies, not links). |
| Existing-binary disposition: additive | yes | `git diff --name-status origin/main...HEAD`: 23 files, every status `A`. |
| Runtime deps: none beyond stdlib; cue only in CI | yes | Build/tests need nothing beyond the compiler; cue fetched as pinned v0.9.2 release binary in the workflow only. |
| JSON/wire: canonical JSON; `tsc-measurement-receipt/0.1` | yes | Vendored serializer (lexicographic keys, 2-space, LF, trailing newline). β recomputed `plan_digest` from the receipt's own plan and via system `sha256sum`: all three agree (`sha256:75b80418...8324a6`). `format` field verified in emitted receipt. |
| Backward-compat: no change to main's artifacts | yes | All-additive diff; merge-base equals current `origin/main` tip. |

Honest-claim spot-checks beyond the ACs (rule 3.13): IR `source_digest` `41da09d5...` genuinely equals `sha256sum` of `readme-present.cm` (not a fabricated digest); self-coherence's reported receipt values (`size_bytes: 100`, plan digest, result classes) all reproduce byte-for-byte under β's build.

### CDD Artifact Contract

| Artifact | Required? | Present? | Notes |
|----------|-----------|----------|-------|
| gamma-scaffold.md | yes | yes | canonical §5.1 path |
| issue-126.md | yes | yes | pinned contract + ACs |
| self-coherence.md | yes | yes | AC-by-AC evidence; round-1 readiness signal; claims verified above |
| beta-review.md | yes | this file | |

### Active Skill Consistency

| Skill | Required by | Loaded? | Applied? | Notes |
|-------|-------------|---------|----------|-------|
| eng/ocaml | issue (OCaml runtime) | yes (α+β) | yes | Result-threaded pipeline, pure/effectful split, determinism; F1 is the one gap against §2.3/§3.3 (an expected-failure class escapes as an exception). |
| eng/code | dispatch | yes | yes | errors carry context; temp+finally I/O; exit codes documented (F1: one class violates the documented codes). |
| eng/test | dispatch | yes | yes | invariant-first suite; negative space covered (8 deny/admit confine cases, fail-closed e2e, receipts-differ). |
| eng/write-functional | α self-declared | n/a (β) | yes | immutable executor state record, `let*` bind, no ref/while in runner. |

## Architecture Check

| Check | Result | Notes |
|---|---|---|
| Reason to change preserved | yes | provider / runner / json / sha256 / cli each own one concern |
| Policy above detail preserved | yes | confinement policy is pure and provider-local; runner never constructs paths |
| Interfaces remain truthful | yes | `file.exists` reports exactly what it observed (incl. `is_directory`, `size_bytes` sentinel documented) |
| Registry model remains unified | n/a | single provider; unknown class is an explicit Error, not a silent skip |
| Source/artifact/installed boundary preserved | yes | hand-authored IR status stated in `.cm`, README, runner comment; receipts gitignored |
| Runtime surfaces remain distinct | yes | standalone tracer; no smear into `coh` engine or ascent-0 |
| Degraded paths visible and testable | yes | skips carry `missing_surfaces`; denials/errors fail closed with messages; F1 is a claim/exit-code defect on one degraded path, not an invisible path |

## CI status

Rule 3.10: on review SHA `18ce1dee` — `coh-min` run 31469158338 conclusion **success** (build → runtest → gate → confine on OCaml 5.2); `ci` success; `CDD Artifact Validate` success; `CDD Telegram Notifier` skipped (notify-only). No branch-protection rules override this set. Gate satisfied.

## Findings

| # | Finding | Evidence | Severity | Type |
|---|---------|----------|----------|------|
| F1 | Malformed-IR fail-closed claim is overbroad, and one malformed-IR class violates the CLI's documented exit-code contract. `Runner.run` (runner.ml:250-260) catches only `Sys_error` and `J.Parse_error` while its comment claims this "keeps every IR fault fail-closed (a clean [Error], never an escaping exception)"; `bin/coh_min.ml:11-15` documents exit 1 = "the run failed closed (e.g. a denied path, a malformed IR)" and exit 2 = "a usage error". The vendored parser also raises `Failure` (`int_of_string`/`float_of_string`, json.ml:94) and `Invalid_argument` (`String.sub` on a truncated `\u` escape, json.ml:61) — neither is caught. | β reproduction: IR containing the number literal `12e` → `Fatal error: exception Failure("float_of_string")`, exit **2**; IR ending in a truncated `"\u00` escape → `Fatal error: exception Invalid_argument("String.sub / Bytes.sub")`, exit **2**. Both are malformed-IR faults that the CLI contract assigns to exit 1; both escape as uncaught exceptions the runner comment says cannot escape. (No receipt is emitted and the exit is non-zero, so the *security* invariant holds — this is a contract/claim defect, not a fail-open path.) | C | honest-claim + judgment |

**Concrete failure scenario:** an operator (or the future `coh cm run` wrapper) scripts on the documented exit codes — `1` routes to "run failed closed", `2` routes to "fix your command line". A hand-edited IR with a malformed number or truncated escape exits 2, so a data fault is misdiagnosed as a usage fault, and the "Fatal error: exception ..." crash text replaces the contractual `✗ coh_min: IR error: ...` diagnostic.

**Required fix (α's choice of shape, on-branch, vendored files untouched):** widen the catch in `Runner.run` to convert these to the same clean channel, e.g. add `| Failure msg | Invalid_argument msg -> Error ("IR error: " ^ msg)` to the existing handler (the `try` is already scoped to the IR-parse/link/execute pipeline), and/or narrow the runner comment and CLI exit-code doc to match actual behavior. Merely narrowing the prose would leave the exit-code misclassification in place, so the catch-widening is the substantive fix; the comment stays true once the catch matches it.

**Regression pair (required with the fix):**
- Positive: a malformed-number IR and a truncated-`\u`-escape IR both exit 1 with a `coh_min: IR error: ...` diagnostic and emit no receipt (add to `test_coh_min.ml` as `is_error (R.run ...)` cases — today these two inputs crash the test process itself, which is why the existing malformed-IR coverage did not catch them).
- Negative: no IR input reaches exit 2 (exit 2 stays reserved for usage errors) and no uncaught exception escapes `Runner.run`.

## Notes

- Verified negative space the diff already covers well: unknown `provider_class` → clean Error; missing `config.relative_path` → clean Error; nonexistent IR file → clean `Sys_error` Error; truncated JSON → clean `Parse_error`. F1 is the residual class only.
- Lexical (no-realpath) confinement is documented as deliberate and is adequate for the pinned stdlib-only scope; a symlink inside the subject can point outside, but the provider only stats existence and the limitation is named in README §Path confinement. Not a finding at this scope.
- `plan_json` serializes the plan without each step's `config`; the digest is self-consistent with the receipt's embedded `sandbox_execution_plan` and reproducible externally, and the receipt separately carries `source_digest` + evidence `relative_path`, so provenance is not lost. Worth revisiting when the shared M1 receipt is unified; not a defect against this issue's contract.
- Search space closure: apart from F1, no remaining blocker was found in the AC set, the 7-axis implementation contract, or the diff/architecture walk above.

*Verdict restated: REQUEST CHANGES — one C finding (F1). All 7 ACs pass under β's independent verification; the cycle is one small on-branch fix + regression pair away from approval.*

---

# Round 2 — re-review of the F1 fix

**Verdict:** APPROVED

**Round:** 2
**Fixed this round:** `a563beb` (+ self-coherence entry `515b233`) closes F1
**Review base:** `origin/main` = `32dfda833a8dea0db765ea9332d3fab122f9d7d6` (unchanged since round 1; merge-base still equals main tip)
**Review head:** `515b2333e9f36b0b9edd6bdae02bd6ef18cae215` (tip of `cycle/126`)
**Branch CI state:** green on review SHA (coh-min run 31470000111 → success)
**Merge instruction:** `git merge cycle/126` into `main` with `Closes #126`

Bounded re-verification per γ's round-2 dispatch; all evidence below produced by β's own flat `ocamlopt` rebuild (scratch space, OCaml 4.14.1) — α's round-2 self-coherence entry treated as hypothesis and confirmed, not trusted.

## Diff scope (704b57f..515b233)

- `git diff --name-status`: exactly three files — `lib/runner.ml` (M), `test/test_coh_min.ml` (M), `.cdd/unreleased/126/self-coherence.md` (M). No other surface touched.
- The fix: two new arms in `Runner.run`'s existing handler — `| Failure msg -> Error ("IR error: " ^ msg)` and `| Invalid_argument msg -> Error ("IR error: " ^ msg)` (runner.ml:266-267) — plus a comment that now names both vendored-parser exception classes, making the "never an escaping exception" claim true of the code as written.
- `Sha256.self_test ()` remains **outside** the `try` (runner.ml:249) — correct: a broken hash implementation still aborts as a programmer-error invariant rather than being mislabeled "IR error". Within the guarded block, `Failure`/`Invalid_argument` can realistically only originate in the vendored parser (`link`/`emit`/`evaluate` are pure over parsed values; provider faults ride `result`), so the "IR error" label is accurate in scope.
- Vendored-verbatim axis re-verified by β's own diff on the round-2 tree: `json.ml` IDENTICAL, `sha256.ml` IDENTICAL to `ascent-0/lib/`.

## F1 counterexamples re-run (CLI channel, β's build)

| Input | Round-1 behavior | Round-2 behavior (β-run) |
|---|---|---|
| IR with malformed number literal `12e` | `Fatal error: exception Failure("float_of_string")`, exit 2 | exit **1**, stderr `✗ coh_min: IR error: float_of_string`, 0 bytes on stdout (no receipt) |
| IR with truncated `\u00` escape | `Fatal error: exception Invalid_argument("String.sub / Bytes.sub")`, exit 2 | exit **1**, stderr `✗ coh_min: IR error: String.sub / Bytes.sub`, 0 bytes on stdout (no receipt) |

Exit-code contract restored: exit 1 = fail-closed run fault (malformed IR included), exit 2 reserved for argv/usage errors. No uncaught exception.

## Regression quality check

The two new tests assert the **Error path** (message must carry the `IR error` prefix) with an explicit `| exception _ -> false` arm — not merely "no crash". β proved they bite: rebuilding the round-1 (pre-fix) `runner.ml` from `18ce1de` against the round-2 test file yields exactly `FAIL - malformed number literal (12e) IR -> clean IR error (no exception)` and `FAIL - truncated \u escape IR -> clean IR error (no exception)`, suite exit 1. On the round-2 runner: **14/14** checks ok, exit 0.

## Happy path re-verified (no regression)

- present fixture → exit 0, `"result_class": "README_PRESENT"`; absent fixture → exit 0, `"result_class": "README_ABSENT"` (AC2/AC3).
- `cmp -s` → receipts differ (AC4).
- `cue vet` (v0.9.2) both receipts against `#MeasurementReceipt` → clean (AC5).
- Escape IR still denied: exit 1, no receipt (AC6).

## CI status (rule 3.10)

On review SHA `515b2333`: `coh-min` run 31470000111 (run #4, push event) conclusion **success** — build → runtest (now 14 checks) → gate → confine on OCaml 5.2. Gate satisfied.

## Findings

None. F1 is closed with the required regression pair; no new finding emerged from the round-2 diff.

## Closure

Search space closed (rule 3.7): with F1 resolved, no remaining blocker exists in the AC set (1–7 all pass, round-1 evidence + round-2 re-runs above), the 7-axis implementation contract (re-verified where the round-2 diff could touch it: vendored-verbatim, stdlib-only, additive-plus-cycle-artifacts, α-code-only fix), or the diff walk. Verdict-shape lint: single terminal verdict, no conditions, zero unresolved findings.

**Merge instruction:** β (or the merging role per CDS step 8) merges `cycle/126` into `main` with `Closes #126`. Not executed by this re-review session per γ's bounded dispatch ("do NOT merge").
