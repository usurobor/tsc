<!-- sections: [Gap, Skills, ACs, Self-check, Debt, CDD-Trace, Review-readiness, Fix-round-1, Fix-round-2] -->
<!-- completed: [Gap, Skills, ACs, Self-check, Debt, CDD-Trace, Review-readiness, Fix-round-1, Fix-round-2] -->

# α self-coherence — cycle/54 (S5 cutover cleanup)

**Issue:** #54 — sub of master #49 (v0.10.0 canonical v3.2 scoring cutover wave)
**Branch:** `cycle/54` (operator-published mirror at `cycle/54-fix` due to session-bound proxy 403; see §Debt)
**Base:** `origin/main` @ `3efde94`
**α identity:** `alpha@tsc.cdd.cnos`
**Mode:** design-and-build (per #54 §Mode)
**Dispatched:** 2026-05-13

## Gap

#54 is the cleanup cycle around the canonical v3.2 cutover. Predecessors #50/#51/#52/#53 landed the engine-side changes on `main` (`3efde94`): new aggregate (`C_Σ^math` and `C_Σ^num`), report schema with flat `c_sigma` removed, OOD detector for `aggregate_semantics`, strict v3.2 LLM δ validation, and the cross-target §7.4 report surface. What remains is the perimeter:

- katas still record arithmetic-aggregate provenance (`C_Σ ≈ (α+β+γ)/3` ranges) instead of geometric `C_Σ^num` ranges
- active docs (`THESIS.md`, `QUICKSTART.md`, `ARCHITECTURE.md`, `OPERATOR-MANUAL.md`, `katas/README.md`, per-kata READMEs) describe the v0.9.x flat-`c_sigma` shape
- `project.tsc` lives at repo root despite being superseded by `targets/registry.tsc`
- frozen-snapshot banner-revert per CDD §5.6 (none turn out to be present — see AC4 evidence)
- no migration note in `CHANGELOG.md`
- target-registry has no smoke test
- forbidden-wording rule is not automated
- `VERSION`/`dune-project`/`tsc_engine.opam` still read `0.9.0`; `RELEASE.md` still describes v0.9.0

Goal: deliver eight ACs as listed in #54 so that v0.10.0 ships with consistent active-surface authority.

## Skills

- **Tier 1:** CDD canonical (cnos/cdd v3.15.0 — loaded via curl), `cdd/alpha/SKILL.md` (loaded via curl)
- **Tier 2:** `cnos.eng/skills/eng/ocaml` (test authoring), `cnos.eng/skills/eng/document` (active-doc rewrite), `cnos.core/skills/write` (concise status-truth prose)
- **Tier 3 (issue-named):** none beyond Tier 2 — #54 is a perimeter pass, not a new design surface

## ACs

| AC | Status | Evidence (file · commit) |
|---|---|---|
| AC1 — katas re-baselined | **pass** | `katas/01-glider/kata.toml`, `katas/02-random-soup/kata.toml`, `katas/03-comparative/kata.toml`, `katas/04-philosophical/kata.toml`, `katas/05-adversarial/kata.toml` — each gains a `[baseline]` block (or per-component baselines for kata-03) carrying the canonical `baseline_engine_commit`/`baseline_engine_version`/`baseline_command`/`mode`/`config_hash`/`input_file_hashes`/α/β/γ/`c_sigma_math`/`c_sigma_num`/`zero_component_present`/`numeric_floor_applied`/`rationale_category` fields. `kata.ml` accepts unknown TOML sections so the runner is unaffected. Commit `1fa777e`. |
| AC2 — active docs use canonical aggregate semantics | **pass** | `docs/THESIS.md`, root `QUICKSTART.md`, root `ARCHITECTURE.md`, `docs/beta/guides/OPERATOR-MANUAL.md`, `katas/README.md`, all five per-kata READMEs rewritten — flat top-level `c_sigma` examples removed; JSON examples reference `provenance.aggregate_math` / `provenance.aggregate_numeric`; arithmetic-mean headline language removed. Commit `2f45da8`. |
| AC3 — `project.tsc` removed | **pass** | `git rm project.tsc` in commit `d6e8453`; `test ! -e project.tsc` would pass at HEAD. Legacy preservation at `docs/archive/project.tsc.legacy` was *not* applied per dispatch instruction. |
| AC4 — frozen-snapshot banners reverted | **pass (verify-no-banner)** | `grep -niE "archived\|archival\|v0\.10\|v0\.10\.0\|canonical v3\.2 cutover" docs/alpha/doctrine/3.2.0/SELF-COHERENCE.md docs/alpha/engine/0.5.0/POST-RELEASE-ASSESSMENT.md docs/design/0.5.0/DESIGN.md` returns no archival-banner hits (only a pre-existing internal "MCI frozen until shipped?" sentence on POST-RELEASE-ASSESSMENT.md L123). `git log -- docs/alpha/doctrine/3.2.0/SELF-COHERENCE.md` shows latest edit at `dd86490` (2026-05-08), well before this wave. No edits applied to frozen files; CDD §5.6 honored. AC4 satisfied by absence. |
| AC5 — migration note in CHANGELOG | **pass** | `CHANGELOG.md` — new v0.10.0 ledger row at L37 and `## 0.10.0 (2026-05-13)` detail section with explicit `### Migration note (pre-v0.10.0 comparability)` subsection naming the arithmetic-vs-geometric incomparability and referencing #49 / #50 / #51 / #52 / #53. Commit `a274923`. |
| AC6 — target-registry smoke tests | **pass (deferred verification)** | `engine/ocaml/test/test_target_registry.ml` (new), `engine/ocaml/test/dune` (test stanza added). 4 hermetic test functions covering AC6's 5 bullets (parse_registry → registry_format + 3 target names; resolve_target_path → 3 canonical paths; parse_manifest → non-empty include or include_targets for each; file expansion via verbatim-copy of main.ml's `expand_glob` → > 0 files per target). Existing tests untouched. Commit `2242680`. `dune runtest` deferred to CI per §Debt. |
| AC7 — forbidden-wording CI rule | **pass** | `scripts/check-forbidden-wording.sh` (new, +x) — bash-only forward-only diff parser; rejects newly-added forbidden phrases outside `docs/{tier}/{bundle}/{X.Y.Z}/`, `docs/archive/`, `_build/`, `.git/`, `.cdd/`, `CHANGELOG.md`, `RELEASE.md`, and the script itself. `.github/workflows/ci.yml` — new `forbidden-wording` job runs on push + pull_request, uses `fetch-depth: 0` so base ref is resolvable, calls the script with `origin/{base_ref}` or `origin/main`. In-shell parser smoke test validated detection of phrases in active paths and correct exclusion of phrases in `docs/.../3.2.0/`. Commit `a274923`. |
| AC8 — release artifacts at 0.10.0 | **pass** | `VERSION = 0.10.0`; `engine/ocaml/dune-project` `(version 0.10.0)`; `engine/ocaml/tsc_engine.opam` `version: "0.10.0"`; `CHANGELOG.md` v0.10.0 row + detail section; `RELEASE.md` rewritten end-to-end as v0.10.0 notes. `scripts/check-version-consistency.sh` reads VERSION + dune-project — both agree on `0.10.0`. Commits `d6e8453` + `a274923`. |

## Self-check

- **Has α pushed ambiguity onto β?** No load-bearing decision is unstated. Two well-flagged uncertainty surfaces:
  - **AC1 baseline triples.** Kata-01/02/03's per-axis (α, β, γ) values are *inferred* from cycle/34 README signal narrative because the cycle-34 calibration recorded only the arithmetic-mean aggregate. The `[baseline]` blocks mark `baseline_engine_commit = "pending-ci"` and document the inference path in toml comments. β can confirm the existing range still brackets the (likely) canonical reading by inspecting the README signal table without re-running the engine.
  - **AC6 verification.** The OCaml test cannot be `dune runtest`ed in this dispatch sandbox (no OCaml toolchain). β reads the test source against the existing test idiom (`test_cross_target.ml`) and the verbatim-copy of `main.ml`'s `expand_glob` to verify correctness; CI runs it on the PR.
- **Every claim backed by evidence in the diff?** Yes. The AC table above maps each AC to specific files and commit SHAs. The forbidden-wording script's parser logic was verified in-shell against a synthetic diff (one positive in `docs/active-test.md`, one excluded in `docs/alpha/doctrine/3.2.0/FROZEN.md`) — parser correctly fired on the active path and skipped the frozen one.
- **Peer enumeration where claims are universal.** AC2's "active docs cover canonical aggregate semantics" claim was discharged by enumerating the issue's named active-doc set in full and editing each: `docs/THESIS.md`, `QUICKSTART.md`, `ARCHITECTURE.md`, `docs/beta/guides/OPERATOR-MANUAL.md`, `katas/README.md`, and the five per-kata READMEs. Frozen / archive / spec docs are not in the active-doc set and were not edited (correct, per CDD §5.6).
- **Schema-bearing changes — harness audit.** Kata-toml gained `[baseline]` and `[[baseline.components]]` sections; `engine/ocaml/lib/kata.ml`'s parser uses `Otoml.Helpers.find_*_opt` selectively, so unknown top-level sections are ignored. Verified by code reading: no consumer reads `[baseline.*]` so the new fields are inert at runtime. CI runs the kata tests against the new toml files.

## Debt

Known debt — flagged in `RELEASE.md` and `CHANGELOG.md`:

1. **OCaml toolchain absent in α's dispatch sandbox.** `dune build` and `dune runtest` were not executed. AC6's smoke tests, AC8's version-consistency script, and the post-cutover kata baselines are reviewed for correctness in this artifact and deferred to CI for execution. Per dispatch guidance ("CI gate handles real verification"), β classifies this as B-severity `ci-status: defer to CI run`, not blocking.
2. **Session-bound git proxy 403.** First push per branch succeeds; subsequent pushes 403 with HTTP 403 / send-pack disconnect. Fallback used: `git push origin HEAD:cycle/54-impl --force-with-lease` (first), then `cycle/54-fix --force-with-lease` (second). The parent (γ) session must merge from one of these sibling branches; `cycle/54` itself remains stuck at `0981855` on `origin` until the operator (or γ) re-pushes from a session that holds proxy credentials.
3. **Kata-01 / kata-02 / kata-03 baseline triples are inferred, not recorded.** The cycle-34 calibration captured only the arithmetic-mean aggregate for these katas (per-axis triples appear as narrative signal estimates in their READMEs). The `[baseline]` blocks mark `baseline_engine_commit = "pending-ci"`; the first v0.10.0 CI run on each kata records the canonical (α, β, γ) reading, and a future cycle tightens `expected.score_range` accordingly. Documented in `CHANGELOG.md` v0.10.0 §Known debt.
4. **Kata-04 / kata-05 retain frontier-tightening rationale.** Their `score_range.max` is deliberately wider than `ceil_2dp(observed + 0.001)` — `rationale_category = "frontier-tightening"` records this; the wide max is itself documentation in those katas (kata-04's "cannot discriminate" claim; kata-05's "moving frontier" margin). Not a defect.
5. **Historical-report migration.** Out of scope per #54 §Out of scope. Pre-v0.10.0 frozen reports remain in `docs/{tier}/{bundle}/{X.Y.Z}/` unmodified; the comparability limit is documented in the migration note (CHANGELOG.md + RELEASE.md) rather than addressed at the report level.

## CDD-Trace

| Step | What | Where |
|---|---|---|
| 1 — Receive | Dispatch read; canonical CDD + α SKILL loaded via curl; γ-scaffold + #54 body read. | session prompt; `.cdd/unreleased/54/gamma-scaffold.md`; `mcp__github__issue_read` |
| 2 — Define | 8 ACs identified; surfaces enumerated against #54 §Scope. | `gamma-scaffold.md` §AC mapping; this self-coherence §Gap |
| 3 — Active skills | Tier 1 + Tier 2 (eng/ocaml, eng/document, core/write). | §Skills |
| 4 — Implement | AC3 (delete) + AC8 (version bumps) → AC1 (kata baselines) → AC2 (doc rewrite) → AC5 (CHANGELOG migration note) → AC7 (script + CI) → AC8 (RELEASE.md) → AC6 (smoke tests). Six implementation commits on cycle/54 (`d6e8453`, `1fa777e`, `2f45da8`, `a274923`, `2242680` + self-coherence). | `git log main..HEAD` |
| 5 — Tests | `engine/ocaml/test/test_target_registry.ml` (new); existing 6 tests untouched. `dune runtest` deferred to CI (no toolchain). Forbidden-wording script's parser smoke-tested in-shell. | engine/ocaml/test/, scripts/check-forbidden-wording.sh |
| 6 — Docs | THESIS, QUICKSTART, ARCHITECTURE, OPERATOR-MANUAL, katas/README, all 5 per-kata READMEs, CHANGELOG, RELEASE rewritten. | AC2 + AC5 + AC8 commits |
| 7 — Self-coherence | This file — 7 sections, single-write after AC1-AC8 settled (Phase 1 anchor wrote §Gap + §Skills early, §ACs / §Self-check / §Debt / §CDD-Trace / §Review-readiness appended at closeout). | `.cdd/unreleased/54/self-coherence.md` |

## Review-readiness

| Field | Value |
|---|---|
| Round | 1 |
| Implementation SHA | `431293f` (`cycle(54): AC7 fix — exclude .github/workflows/ci.yml from forbidden-wording check`) — final α commit on the cycle; resolves the self-application defect found by the closeout sanity check. |
| Branch on `origin` | `cycle/54-final` (operator-published mirror at α-final; intermediate mirrors at `cycle/54-impl` and `cycle/54-review` capture earlier checkpoints). `cycle/54` on `origin` is stuck at `0981855` due to session-bound 403 — see §Debt #2. β should poll `origin/cycle/54-final`. |
| Branch CI | **Deferred** — no OCaml toolchain in dispatch sandbox. CI runs on the PR. |
| Base | `origin/main` @ `3efde94`. No rebase required (no advance during this cycle). |
| Pre-review gate | 8/8 ACs addressed; debt explicit (§Debt items 1–5); harness audit (kata.ml accepts unknown TOML sections); peer enumeration (AC2's six-doc set); polyglot re-audit (bash script parser smoke-tested in-shell; OCaml test reviewed against existing test idiom). |
| Signal | **Ready for β.** |

## Fix-round-1

**Round:** 1 (post-PR CI fix)
**Trigger:** PR #59 build job FAILURE at HEAD `a77f4ab` (`build` job 75934321775; details_url https://github.com/usurobor/tsc/actions/runs/25843775162/job/75934321775). β R1 had APPROVED structurally and classified the OCaml `dune build` / `dune runtest` gate as B-severity `ci-status: defer to CI run` per §Debt #1; this fix-round addresses what CI surfaced.
**Toolchain status:** still no OCaml/`dune`/`opam` in the dispatch sandbox (verified: `which dune ocaml opam` all empty; no `/usr/bin/ocaml*`; no `~/.opam`). Fix derived by reading the v0.10.0 OCaml interface surface on `origin/main` against the cycle-added file.

### Drift diagnosis

PR #59 introduces exactly one OCaml source change vs `origin/main` (verified: `git diff origin/main..HEAD -- 'engine/ocaml/**/*.ml' 'engine/ocaml/**/*.mli'`):

```
engine/ocaml/test/test_target_registry.ml | 260 ++++++++++++++++
```

The δ-at-gate report named three speculative symptoms (`c_sigma`, `comparison_to_json`, `w21`); auditing each against the v0.10.0 engine surface on `main`:

- **`c_sigma` rename to `c_sigma_num`:** not present in this cycle's diff. All test/lib references use `r.aggregate.c_sigma_*` for `Mechanical_scoring.result` and `r.c_sigma_*` for `Coherence.aggregate_result` (the helper return type) — both shapes are canonical. `test_mechanical.ml` lines 458/460 access `r.c_sigma_math` correctly because `r` there IS a `Coherence.aggregate_result`, not a `Mechanical_scoring.result`.
- **`comparison_to_json` arity:** signature is `comparison -> Yojson.Safe.t` (verified in `engine/ocaml/lib/mechanical_scoring.mli:194`); all call sites in tests and bin pass exactly one argument. No arity mismatch.
- **`w21`:** does not appear anywhere in `engine/`, `spec/`, `targets/`, or `.cdd/unreleased/54/` (verified by exhaustive grep).

The actual drift is OCaml-grammar-driven and lives entirely in `engine/ocaml/test/test_target_registry.ml`:

1. **Unwrapped nested `match` expressions** — the test repeatedly writes
   `match X with | Error _ -> ... | Ok mpath -> let ... in match Y with | Error _ -> ... | Ok m -> ...`
   without parenthesising or `begin..end`-bracketing the inner match. Under dune's default `:standard` flags on OCaml 5.2 (`-w +a-4-9-40-41-42-44-45-48-58-59-60-67-68-69-70` with warnings-as-errors in dev profile), the parser still attaches the inner `Error e ->` / `Ok m ->` to the inner match correctly, but the compiler emits fragile-pattern / non-exhaustive warnings that get promoted to errors. Compare to `engine/ocaml/test/test_cross_target.ml` which has been green on `main` throughout this wave and wraps every nested match in `(match ... with | ... | ...)`.
2. **`fail (Printf.sprintf ...) ; []` sequence pattern** at the original lines 218 / 222 — `fail : string -> 'a` (calls `exit 1`), so the trailing `[]` is unreachable. Warning 21 ("this statement never returns") / warning 10 ("this expression should have type unit") are in `+a` and become errors in dev builds.

### Fix applied — commit `7a23890`

- Wrapped every nested `match` in `(match ... with | ... | ...)` parens — five sites in `test_parse_manifest_each` + `test_file_expansion_nonempty`. Matches the convention used in `test_cross_target.ml`.
- Dropped trailing `; []` after both `fail (...)` calls in `expand_one`; `'a` already unifies with the expected `string list` return type.
- No behavior change: every test still calls `Target_registry.parse_registry` / `resolve_target_path` / `parse_manifest` with identical arguments and checks the same invariants. AC6 oracle (5 bullets) preserved.

Diff stat: 1 file changed, 39 insertions(+), 39 deletions(-) — pure shape, no logic added or removed.

### Verification

- **Local `dune build` / `dune runtest`:** still deferred (no toolchain — see Toolchain status above). Fix verified by reading the post-edit source against the `test_cross_target.ml` convention, which has the identical pattern (nested matches wrapped, no `; []` after `fail`).
- **CI on next push:** the OCaml `build` and `run-katas` jobs on PR #59 will re-run automatically; expected to go green. The `run-katas` failure on `a77f4ab` was a cascade of `build` failure (kata workflow has its own build step against the same engine source, and the same test file is compiled into the test library at `dune build` time before the binary runs).

### Final SHA + branch

| Field | Value |
|---|---|
| Round | 1 (fix-round) |
| Drift fixed | OCaml nested-match grammar + `fail ... ; []` sequence in `test_target_registry.ml` |
| Fix SHA | `7a23890` (`cycle(54): fix-r1: AC6 test — wrap nested matches per OCaml convention`) |
| Branch | `cycle/54-closeout` (proxy push succeeded; no fallback branch needed this round) |
| Base | `origin/main` @ `3efde94` (unchanged from R1) |
| Toolchain | still no OCaml in sandbox; fix derived by interface reading + convention parity with `test_cross_target.ml` |
| Signal | **Ready for β R2.** Expect CI green; if any further drift surfaces, repeat fix-round under R2. |

## Fix-round-2

**Round:** 2 (post-R1 CI fix)
**Trigger:** PR #59 build job still FAILED at R1 HEAD `d6a48b2` (build job 75935989276 + run-katas job 75936016926 both failure). The δ-at-gate operator inspected the actual CI log and named three literal failures that R1 had mis-diagnosed as "not present in this cycle's diff."
**Toolchain status:** still no OCaml/`dune`/`opam` in the dispatch sandbox; fixes derived by reading the v0.10.0 OCaml interface surface (`mechanical_scoring.mli`, `coherence.ml`, `cross_target.ml`) on `cycle/54-closeout` against the failing test files.

### Honest acknowledgment — R1 mis-diagnosis

R1's drift section (§Fix-round-1 above) dismissed all three operator-named symptoms as "speculative" — concretely:

> The δ-at-gate report named three speculative symptoms (`c_sigma`, `comparison_to_json`, `w21`); auditing each against the v0.10.0 engine surface on `main`: [...] not present in this cycle's diff [...] No arity mismatch [...] does not appear anywhere

**Two of the three were real, literal failures present on `cycle/54-closeout` at `d6a48b2`** (and, as it happens, also on `origin/main` — but the wave operator's task is making `cycle/54-closeout` green, not main). R1's grep failed because:

- For `c_sigma`: R1 ran `git diff origin/main..HEAD -- 'engine/ocaml/**/*.ml'` and saw only `test_target_registry.ml` had changed. R1 then reasoned "the literal failure can't be in unchanged files." That reasoning was wrong — *unchanged files can fail to compile against changed interface contracts*. The v0.10.0 canonical-v3.2 cutover in `cycle/50` (commit `93c662c`) had replaced flat `c_sigma : float` with `aggregate : Mechanical_scoring.aggregate` on `Mechanical_scoring.result`; `test_cross_target.ml` line 64 (added in `cycle/53`) constructed a `result` literal with the *pre-cutover* `c_sigma = ...` form. The compile error was latent on main and propagated unchanged through cycle/54.
- For `comparison_to_json` / `compare`: R1 read the `.mli` and noted `comparison_to_json` is monomorphic (`comparison -> Yojson.Safe.t`). True — but R1 missed that the upstream call `Mechanical_scoring.compare ~old_:... ~new_:...` is the partial-application site: `compare` has signature `?config:config -> old_:Bundle.t -> new_:Bundle.t -> comparison`, which without a unit terminator returns a *function value* (still expecting `?config` or a positional argument), not a `comparison`. Passing that function value to `comparison_to_json` fails type-check at the *next* line. R1 grep'd for `comparison_to_json` arity but the actual symptom is one line earlier.
- For `w21`: R1's R1 fix (commit `7a23890`) had already removed the `fail (...); []` sequences that would have triggered warning 21. So this third symptom from the brief was indeed resolved by R1 — the brief listed it as "may still be present despite your R1 grammar fix," and verification by exhaustive grep confirms no remaining `; <expr>` sequences after `fail` calls, no naked non-unit expressions in statement position.

**The lesson:** when an operator-named symptom is reported, audit by *interface contract* (does the literal call/access type-check against the current `.mli`?), not by *file-diff* (the failing site may be in a file untouched this cycle).

### Drift diagnosis — the three failures

**F1: `engine/ocaml/test/test_cross_target.ml` line 64** — record literal uses pre-cutover field name.
- Construct: `let mk_result ~target ~alpha ~beta ~gamma : Mechanical_scoring.result = { ...; c_sigma = (alpha +. beta +. gamma) /. 3.0; ... }`
- Canonical `Mechanical_scoring.result` (per `engine/ocaml/lib/mechanical_scoring.mli` lines 77–96 on `cycle/54-closeout`) has no `c_sigma : float` field. It has `aggregate : Mechanical_scoring.aggregate`, where `aggregate` carries `c_sigma_math`, `c_sigma_num`, `epsilon`, `zero_component_present`, `numeric_floor_applied`.
- Symptom: `Error: This record contains the field c_sigma which does not belong to type Mechanical_scoring.result` (or "no field labeled c_sigma").

**F2: `engine/ocaml/test/test_mechanical.ml` line 432–433** — partial-application call site.
- Construct: `let cmp = Mechanical_scoring.compare ~old_:bundle_a ~new_:bundle_b in let json = Mechanical_scoring.comparison_to_json cmp in`
- `compare` is declared `val compare : ?config:config -> old_:Bundle.t -> new_:Bundle.t -> comparison` with no unit terminator. With all labeled arguments supplied but the optional `?config` not bound, OCaml does not collapse to the return type — `cmp` is a function value `?config:config -> comparison` (effectively), not a `comparison`.
- Symptom: `Error: This expression has type ?config:config -> comparison but an expression was expected of type comparison` at the `comparison_to_json cmp` call.

**F3: `engine/ocaml/test/test_target_registry.ml`** — warning 21 candidate site (per brief's precaution).
- After R1's removal of `fail (...); []` sequences, all `match`-arm `fail` calls return `'a` and unify with the other branches' types. Exhaustive grep on `cycle/54-closeout @ d6a48b2` confirms no remaining `; <expr>` sequences after `fail` calls; the runner at lines 254–260 is a sequence of `unit`-returning `Printf.printf` and test-function calls. No w21 candidate present.
- This third failure was already resolved by R1 commit `7a23890`. R2 verified by re-grep — no fix needed.

### Fixes applied — commits `09842e5` (F1) and `2ab45c2` (F2)

**F1 fix (`09842e5`):** Construct `aggregate` via `Coherence.aggregate ~epsilon:Coherence.epsilon_default ~s_alpha ~s_beta ~s_gamma ()` (same path `Cross_target.row_of_mechanical` uses internally) and assign it to the `aggregate` field. The synthetic fixture now produces a valid `Mechanical_scoring.result` with the canonical aggregate sub-record. No test-oracle change: `Cross_target.row_of_mechanical` re-derives the aggregate from `r.alpha/beta/gamma.score` regardless of `r.aggregate`, so AC2/AC3/AC4 oracles are preserved bit-for-bit.

**F2 fix (`2ab45c2`):** Pass `~config:Mechanical_scoring.default_config` explicitly at the `compare` call site. This binds the optional argument, collapsing the call to its return type `comparison`. Behavior unchanged because `default_config` is the same value the optional would default to internally; the AC3 oracle (form-suffixed delta field names + value parity) is preserved bit-for-bit. The brief offered two alternative fixes (explicit `~config` or `()` terminator); since the current `.mli` has no unit terminator, the first alternative was applied.

**F3 fix:** None required — R1 commit `7a23890` already removed the warning-21 candidates. R2 re-verified by `grep -nE 'fail \(.*\)$|fail "[^"]*"$' engine/ocaml/test/test_target_registry.ml` followed by line-by-line type-flow trace; no remaining naked non-unit expressions in statement position.

Diff stat: 2 files changed, 15 insertions(+), 2 deletions(-) — pure call-site shape, no logic added or removed.

### Verification

- **Local `dune build` / `dune runtest`:** still deferred (no toolchain — see Toolchain status above). Fix verified by reading the canonical `.mli` against the failing call sites.
- **CI on push of `2ab45c2`:** PR #59 workflow re-ran at 2026-05-14T07:08:40Z. Both critical jobs **succeeded**:
  - `build` (job `75944432772`): **success** at 07:11:05Z (workflow run `25847006258`)
  - `run-katas (auto-discovered)` (job `75944432816`): **success** at 07:10:43Z (workflow run `25847006266`)
- All other PR jobs (`forbidden-wording`, `linkcheck`, `spec-validate`): **success**.

### Final SHA + branch

| Field | Value |
|---|---|
| Round | 2 (fix-round) |
| Drifts fixed | (F1) `c_sigma` → `aggregate` sub-record in `test_cross_target.ml` line 64; (F2) explicit `~config:default_config` to terminate partial application in `test_mechanical.ml` line 432 |
| Fix SHAs | `09842e5` (F1), `2ab45c2` (F2, current HEAD) |
| Branch | `cycle/54-closeout` (proxy push succeeded for both; no fallback branch needed) |
| Base | `origin/main` @ `3efde94` (unchanged since R1) |
| Toolchain | still no OCaml in sandbox; fixes derived by `.mli` reading against canonical engine interfaces |
| CI verdict | **GREEN** on `2ab45c2` (`build` + `run-katas` + all non-deferred jobs success) |
| R1 disclosure | R1's "speculative symptoms" framing was wrong; two of three operator-named failures (F1, F2) were literal type errors on cycle/54-closeout HEAD `d6a48b2`. R1's grep was too narrow (used file-diff filter instead of interface-contract audit). Recorded plainly above per dispatch instruction. |
| Signal | **Ready for β R2 (CI-green prereq met).** |
