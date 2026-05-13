# β review — cycle/51, Round 1

Sub-issue: #51 — strict v3.2 LLM δ validation + validation_failure artifact
Master wave: #49 (v0.10.0-canonical-v3.2-cutover)
Review branch: `cycle/51-impl` @ `d5f7a83`
Merge base: `origin/main` @ `e2587bc`
Reviewer identity: `beta <beta@tsc.cdd.cnos>`
Round: 1

## Verdict

**APPROVED** — with B-severity `ci-status: defer to CI` (γ-authorized per
dispatch: no OCaml toolchain in review environment).

All three ACs trace to grep-verifiable evidence in the diff. The
implementation closes the v3.2 strict-δ contract end-to-end:
validator → dispatch → artifact → exit code → no post-response
mechanical fallback. Tests cover the eight required cases. No
unresolved D/C findings; the only B findings are documented below and
neither blocks merge.

## Phase 1 — Contract integrity (§2.0.0)

| Check | Result | Notes |
|---|---|---|
| Status truth preserved | yes | Issue body distinguishes Shipped (v0.9.0 `extract_deltas` optional) vs Current spec (`SELF-MEASURE.md` §7 required) vs Target state. `self-coherence.md` mirrors this. |
| Canonical sources/paths verified | yes | Issue cites `runtime/SELF-MEASURE.md` line 259 ("three `delta_*` fields are **required**") and `spec/tsc-core.md` §3.2 (`δ ∈ [0,1]`); both verified on branch. |
| Scope/non-goals consistent | yes | Diff touches only the four files named in Scope: `response_schema.ml`, `main.ml`, `test/dune`, `test_response_schema.ml`. No provider-envelope or verdict-logic changes. |
| Constraint strata consistent | yes | Three δ fields are hard-required, no exception escape; out-of-range and non-numeric route to `invalid_fields`; no silent enforcement drift. |
| Exceptions field-specific/reasoned | n/a | No exceptions declared; AC1/AC2 path is unexcepted. |
| Path resolution base explicit | yes | Artifact path is `Filename.concat args.cli_output_dir (Printf.sprintf "tsc-%s-%s-validation-failure.json" target ts)` — base is `--output` dir, target is `bundle.bundle_target_name`, ts is the run timestamp. Matches AC2 oracle naming. |
| Proof shape adequate | yes | Issue carries invariant + oracle + positive + negative + operator projection + known gap (non-JSON parse error). Test module covers eight cases. |
| Cross-surface projections updated | partial | Validator + dispatch + tests synchronized. Operator-facing diagnostics: stderr line names missing/invalid fields; durable JSON artifact. No README/help-text update — issue body does not require one and the artifact path is self-describing. No surface contradiction observed. |
| No witness theater / false closure | yes | Each AC is grep-verifiable (`validate_v32_deltas`, `write_validation_failure_artifact`, `exit 1` on every post-provider failure path). Test module is wired in `engine/ocaml/test/dune`. |
| PR body / branch alignment | yes | `self-coherence.md` and `gamma-closeout.md` describe commit `8c67974` accurately, matched by working-tree state at `d5f7a83`. |

Gate: PASS. Proceeding to Phase 2.

## Phase 2a — Issue contract walk

### AC coverage

| # | AC | In diff? | Status | Notes |
|---|----|----------|--------|-------|
| 1 | v3.2 response validation requires δ | yes | met | `Response_schema.validate_v32_deltas` (`engine/ocaml/lib/response_schema.ml:240`) requires all three δ as numbers in `[0,1]`. Returns `Error v32_validation_error` populated with full offender list (no short-circuit). Positive (floats), positive (int boundary), missing-single, missing-all, out-of-range, negative, string, and mixed cases all covered in `test_response_schema.ml`. |
| 2 | Validation failures write durable artifact and exit non-zero | yes | met | `write_validation_failure_artifact` (`main.ml:301`) emits exact AC2 shape: `kind=validation_failure`, `schema=tsc-llm-response/v3.2`, `status=error`, `missing_required_fields`, `invalid_fields`, canonical `message`. `invalid_fields` entries carry `field` + `observed_value` + `expected_range: "[0, 1]"`. `run_llm` (`main.ml:402`) and `run_hybrid` (`main.ml:484`) both write the artifact and `exit 1`. Raw response written **before** validation (line 376 / 466), guaranteeing preservation on every failure mode. |
| 3 | No post-response mechanical fallback | yes | met | `main.ml:693` carries the explicit invariant comment ("auto-mode mechanical selection is PRE-PROVIDER ONLY"). Every post-provider error path in `run_llm` and `run_hybrid` calls `exit 1` without invoking `Mechanical_scoring`. Grep confirms zero post-provider `Mechanical_scoring.*` calls. Auto-mode pre-provider mechanical selection in `effective_mode` resolution is preserved. |

### Named doc updates

| Doc / File | In diff? | Status | Notes |
|---|----------|--------|-------|
| `runtime/SELF-MEASURE.md` | no | n/a | Issue says spec is already canonical; this cycle aligns engine to spec, not the other way around. |
| `spec/tsc-core.md` | no | n/a | Same. |
| `CHANGELOG.md` | no | acceptable | Cycle/51 ships under wave #49; changelog roll-up belongs to the wave close. |

### CDD artifact contract

| Artifact | Required? | Present? | Notes |
|---|----------|----------|-------|
| `.cdd/unreleased/51/self-coherence.md` | yes (α surface) | yes | Carries AC-by-AC evidence trace. |
| `.cdd/unreleased/51/gamma-closeout.md` | (canonical name per CDD §5.3) | yes, **with protocol caveat** | Per dispatch §5.2: the file content is α-shaped extended self-coherence written under δ-as-γ dispatch, not a true γ close-out. γ has acknowledged the §1.4 breach; the real γ close-out follows this β verdict. I treat this file as α evidence (consistent with dispatch instruction) and do not flag the misnaming as a β-blocking finding. |
| `.cdd/unreleased/51/beta-review.md` | yes (β surface) | yes | This file. |

### Active skill consistency

| Skill | Required by | Loaded? | Applied? | Notes |
|---|----|----|----|----|
| `cnos.eng/skills/eng/ocaml` | issue body §"Skills to load" | declared in α intake | yes — applied | Result-typed error returned with structured payload, exit-code dispatch, JSON artifact emission via `Yojson.Safe`, dune wiring for new test module. Idiomatic for the codebase. |

## Phase 2b — Diff and context inspection (§2.1.1–§2.1.13)

| Check | Result | Notes |
|---|----|----|
| §2.1.1 input completeness | pass | Three input sources for δ: (a) `validate_result` already enforces top-level schema; (b) `validate_v32_deltas` adds the δ contract; (c) `parse_json` precedes both. The three failure modes (non-JSON / schema-fail / δ-fail) each have a distinct exit path. |
| §2.1.2 format coherence | pass | The artifact JSON shape matches the AC2 prose template field-for-field. The schema string `tsc-llm-response/v3.2` matches the spec version. |
| §2.1.3 snapshot/test stability | pass | New test module is additive; existing tests (`test_mechanical`, `test_coherence`, `test_kata`) untouched in this cycle. |
| §2.1.4 moved/deleted file references | pass | Nothing moved or deleted. Legacy `extract_deltas` retained (see B-1 below). |
| §2.1.5 naming compliance | pass | Branch `cycle/51-impl` is the δ-recovery landing branch per dispatch. Artifact filename `tsc-{target}-{ts}-validation-failure.json` is consistent with the existing `tsc-{target}-{ts}-raw.txt` and `tsc-{target}-{ts}.json` family. |
| §2.1.6 execution timeline | pass | The order is: (a) provider call → raw response; (b) write raw to disk; (c) `parse_json`; (d) `validate_result`; (e) `validate_v32_deltas`; (f) either render report or write validation_failure artifact + exit 1. Raw is *always* on disk before any failure can occur. δ-valid path passes `Some d` triples into `Report.to_json`. |
| §2.1.7 truth surface discipline | pass | Validation is distinct from generation; the validator returns a typed error, the artifact writer renders it for the operator. |
| §2.1.8 cross-surface conflict | pass | No conflict observed between issue, spec (`tsc-core.md` §3.2 `δ ∈ [0,1]`), runtime (`SELF-MEASURE.md` line 259 "required"), and implementation (closed-interval check `f >= 0.0 && f <= 1.0`). Spec note: `lim{δ→1⁻} φ(δ) = +∞` makes δ=1 mathematically degenerate but the issue body explicitly mandates the closed interval `[0, 1]` for the validator. Implementation honors the issue body; that is the canonical contract for this cycle. |
| §2.1.9 correctness scope | pass | Module scan: the only other δ-touching helper, legacy `extract_deltas`, no longer has callers (see B-1). All current code uses the new strict path. |
| §2.1.10 contract-implementation confinement | pass | `validate_v32_deltas` rejects every input outside its claimed domain: missing key → `Missing`; non-object → `` `Invalid "<not an object>" ``; non-numeric (`Bool`/`Null`/`String`/`other`) → `` `Invalid <rendered> ``; numeric out of `[0, 1]` → `` `Invalid <value> ``. There is no silently-accepted bad input class. |
| §2.1.11 leverage | pass | The fix moves the boundary from "validator tolerates missing δ" to "validator rejects missing δ" — the higher-leverage location, not a symptom patch. |
| §2.1.12 process overhead | pass | The new `validation_failure` artifact is justified by a real, durable diagnostic need (the operator must be able to see *why* a v3.2 run produced no coherence report; stderr alone is ephemeral in many runtimes). Not automatable around. |
| §2.1.13 design constraints | pass | "Required response-contract failures are explicit, durable, and non-zero." Met. "No fallback occurs after provider content has been received." Met. "Auto-mode fallback remains pre-provider only." Met. |

## Phase 2c — Architecture and design (A–G)

| Check | Result | Notes |
|---|----|----|
| A. One reason to change | yes | `response_schema.ml` already owns parse + result-validate + δ-extract; the strict δ validator is a coherent extension of the existing concern. |
| B. Policy above detail | yes | `validate_v32_deltas` is policy ("all three required, in [0,1], collect all offenders"). `classify_v32_delta` is detail (per-field disposition). Separated. |
| C. Truthful interface | yes | `Ok` only when all three δ are valid; `Error` carries the full list of offenders, not just the first. The contract makes a stronger promise than absolutely necessary (no short-circuit) and the implementation delivers it. |
| D. Registry normalization | n/a | No registry-shaped surface. |
| E. Source / artifact / installed | yes | Source: `response_schema.ml`; artifact at runtime: `tsc-{target}-{ts}-validation-failure.json` under `--output` dir. Distinct. |
| F. Surface separation | yes | Library (`response_schema.ml`) owns validation; binary (`main.ml`) owns dispatch + artifact emission. No leakage. |
| G. Degraded-path visibility | yes | The "validation failed" path is explicit, durable on disk, non-zero exit, and named in both stderr and the JSON artifact. The operator cannot mistake it for a successful run. |

No findings at this layer.

## Findings

| # | Description | Evidence | Severity | Type | Status |
|---|---|---|---|---|---|
| 1 | `extract_deltas` is retained but has zero remaining callers after this diff. Docstring claims it is kept "for callers that tolerate absent delta (e.g. legacy provenance back-fill)" but no such caller exists in the tree. | `grep -rn "extract_deltas" engine/ocaml/` returns only the definition site. Pre-cycle the sole caller was `main.ml` `run_llm`, which the diff replaces with `validate_v32_deltas`. | B | mechanical | accepted-as-design — documented carry-over for future legacy back-fill paths; safe to keep, but flagged for cleanup in a later cycle if no caller materializes by the v0.10.0 close. |
| 2 | No OCaml toolchain in the review environment; `dune build` and `dune runtest` cannot be executed. CI must run them. | `which dune` → not found; `dune build` → command not found. | B | ci-status | defer to CI (γ-authorized per dispatch). Tests are unit-shaped and additive; no runtime config or fixture dependencies. The mechanical risk is a typo or `.mli` mismatch; manual code reading found neither. |
| 3 | `gamma-closeout.md` on the cycle branch is α-shaped extended self-coherence content written under δ-as-γ single-session dispatch, not a separate-session γ close-out. | Dispatch §5.2 acknowledgement; file content reads as AC evidence + hand-off, identical in shape to `self-coherence.md`. | B | protocol-compliance | accepted-as-disclosed. γ has acknowledged the §1.4 breach in dispatch; the real γ close-out follows this β verdict. No β-blocking impact on AC1–AC3 evidence integrity. |

Zero D-severity findings. Zero C-severity findings. Three B-severity findings, all with disposition documented above; per orchestrator §3.3, B findings with explicit-design disposition do not block merge.

## Honest-claim verification (§3.13)

- "`validate_v32_deltas` requires all three δ in [0,1]" — grep-verified: `engine/ocaml/lib/response_schema.ml:240` defines the function, body asserts `f >= 0.0 && f <= 1.0`, and `v32_required_delta_fields` enumerates the three keys.
- "Validation failure writes the canonical artifact" — grep-verified: `write_validation_failure_artifact` in `main.ml:301` produces a `Yojson.Safe` value with exactly the six AC2 keys and the canonical `message` string.
- "Both `run_llm` and `run_hybrid` exit 1 on every post-provider failure" — grep-verified: every `Error` arm in the cascade ends in `exit 1` and no arm calls `Mechanical_scoring`.
- "Tests cover eight cases" — grep-verified: `test_response_schema.ml` defines eight `test_*` functions, all invoked from `let () =`.
- "Test module is wired in dune" — grep-verified: `engine/ocaml/test/dune` adds `(test (name test_response_schema) (modules test_response_schema) (libraries tsc_engine))`.

No measurement is non-reproducible from this commit. No claim drifts from its source of truth.

## CI status (§3.10)

Required CI checks could not be executed from the review environment
(no OCaml toolchain). Per dispatch, this is a known-unsatisfiable
constraint; γ has authorized `ci-status: defer to CI` at B severity.
The merging operator MUST confirm CI green on `d5f7a83` (and on the
merge commit) before integration is final.

## Pre-merge gate

| Gate | Result | Notes |
|---|---|---|
| Identity truth | yes | `git config user.email = beta@tsc.cdd.cnos`. |
| Canonical freshness | yes | `origin/main` fetched at review start: `e2587bc`. Merge base of `cycle/51-impl` matches. |
| Non-destructive merge test | n/a | β does not have a working OCaml toolchain; deferred to the merging operator. Conflict-free three-way merge is expected — the only files touched outside `.cdd/` are `engine/ocaml/{bin/main.ml, lib/response_schema.ml, test/dune, test/test_response_schema.ml}`, none of which appear in `origin/main..origin/main` (no contention). |
| γ artifact completeness | yes, with caveat (see Finding 3) | `gamma-closeout.md` present and disclosed as δ-as-γ shaped. |

## Merge instruction (§3.11)

Branch: `cycle/51-impl` (head `d5f7a83`).

Merge into `main` with a no-fast-forward merge commit that names the
issue:

```bash
git fetch origin main cycle/51-impl
git switch main
git merge --no-ff origin/cycle/51-impl -m "Merge cycle/51 strict v3.2 δ validation + validation_failure artifact

Closes #51
Wave: #49 (v0.10.0-canonical-v3.2-cutover)

AC1: validate_v32_deltas requires all three δ in [0,1], returns full offender list.
AC2: validation_failure artifact written, raw response preserved, exit 1, no coherence report.
AC3: no post-response mechanical fallback in run_llm or run_hybrid."
git push origin main
```

`main` is branch-protected; the merging operator must drive this via
the protected-branch workflow (PR + required CI green) rather than a
direct push. β has not attempted a direct merge in this session.

## Post-merge follow-ups (not blockers)

1. Consider removing `extract_deltas` once any planned legacy
   back-fill paths are concretely identified — or before v0.10.0 ships
   if none materialize.
2. Confirm `cd engine/ocaml && opam exec -- dune build && opam exec --
   dune runtest` is green on the post-merge `main` head.
3. γ to author a true separate-session γ close-out for cycle/51 per
   CDD §1.4, addressing the dispatch §5.2 protocol disclosure.

## Rounds log

- Round 1 (this round): APPROVED with documented B-only findings.
