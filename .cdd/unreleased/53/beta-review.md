# beta-review.md — cycle/53

Sub-issue: #53 — S4: cross-target report surface (Operational §7.4)
Master: #49 (v0.10.0 canonical v3.2 cutover wave)
Branch: `cycle/53` @ `bc2fd6a`
Round: R1
Reviewer: beta <beta@tsc.cdd.cnos>
Dispatch: β-shaped agent dispatched by γ (δ-as-γ pattern; α and β are structurally separated — β has not seen α's session).

---

## Verdict

**APPROVED — pending CI-green confirmation (no OCaml toolchain in this environment).**

All four ACs from #53 are met by `cycle/53` @ `bc2fd6a`. Findings are limited to one B-band (CI-green gate deferred) and three C-band cosmetic/note items. No D-, no A-band findings.

Per `review/SKILL.md` 3.10, the CI-green gate is structurally undischargeable from this environment (no `dune` / `opam` / `ocaml` on PATH). It is recorded as a B-band finding (`ci-status`) rather than a hard block, consistent with the dispatch directive and with the wave's prior cycles which faced the same constraint.

---

## Phase 1 — Contract integrity

| # | Check | Result | Notes |
|---|---|---|---|
| 1 | Status truth | yes | Issue distinguishes shipped (`Arg.Set_string` single target in v0.9.0), current spec (Operational §7.4 reporting-only), precondition (#50), and target state (`--target` repeatable, n≥2 → cross-target report). No conflation. |
| 2 | Source mapping | yes | Issue table cites `spec/tsc-oper.md` §7.4, `engine/ocaml/bin/main.ml`, `engine/ocaml/lib/target_registry.ml`, `targets/registry.tsc`. All verified present at the cited paths on cycle/53. |
| 3 | Scope consistency | yes | "In scope" enumerates CLI, helper/module, tests, fixture/schema. Diff (`engine/ocaml/bin/main.ml`, `engine/ocaml/lib/cross_target.ml`, `engine/ocaml/lib/dune`, `engine/ocaml/test/test_cross_target.ml`, `engine/ocaml/test/dune`) is a strict subset. Nothing out of scope is implemented (no threshold/verdict, no LLM cross-target, no parallel execution, no kata changes, no OOD). |
| 4 | Constraint strata | yes | Issue lists four active design constraints (additive-only, reporting-only, provenance lists ids, mechanical-only this cycle). All four are preserved (see Phase 2b). |
| 5 | Exception discipline | n/a | No exceptions claimed. |
| 6 | Path semantics | yes | Operator command in AC1 oracle uses `--root ../..` and `--output ../../.tsc` relative to `engine/ocaml`; matches existing single-target conventions. Bundle/registry resolution uses `Filename.concat args.cli_root args.cli_registry` consistent with single-target path. |
| 7 | Proof shape | yes | Each AC has invariant + oracle + positive + negative + surface. AC3 oracle (`[0.8, 0.9, 0.7]` ≈ `0.7958` ± 1e-4) is reproducible analytically and is implemented in `test_ac3_geometric_mean_reference`. |
| 8 | Cross-surface projections | yes | Spec (§7.4), CLI surface (`main.ml`), library helper (`cross_target.ml`), schema-via-test (`test_cross_target.ml::test_ac4_report_shape`), and dispatch wiring (`lib/dune`, `test/dune`) all agree. |
| 9 | Witness integrity | yes | Mechanical-only enforcement is in code (not prose): `effective_mode` is computed first, then `n_targets >= 2` with `Llm | Hybrid` exits 1 with a named message. Duplicate-id rejection is in `reject_duplicates` (not prose). |
| 10 | PR–branch sync | n/a | No PR; review proceeds against branch artifacts. Issue body matches branch state at `bc2fd6a`. |

Contract integrity: **PASS**.

---

## Phase 2a — Issue contract walk

### AC coverage

| AC | Invariant | Surface (in diff) | Test evidence | Result |
|---|---|---|---|---|
| AC1 | `--target` repeatable; n=1 keeps single-target; n≥2 triggers cross-target; non-mechanical multi-target → non-zero exit + named message; invalid target name still fails with the existing target-resolution error. | `main.ml` lines ~218 (`Arg.String` accumulator with "repeatable" help text), ~694–712 (`if n_targets >= 2`, `effective_mode` mode-guard, `exit 1` with explicit message naming count + mode), ~717–722 (single-target/--files path unchanged). | Implicit via grep + dispatch shape; CLI integration tests are not in the diff (issue Scope did not require an end-to-end CLI test, only the dispatch surface + helper math). | met |
| AC2 | Each constituent target reuses the existing mechanical scoring path; `targets[]` lists each by id; duplicate ids and empty list rejected with a clear error before report writing. | `main.ml` `run_cross_target` calls `build_bundle_from_target` then `Mechanical_scoring.score_bundle` per target — the same call sites used by `run_mechanical`. `reject_duplicates` runs before any scoring work. Empty list cannot reach the cross-target branch (gated on `n_targets >= 2`). | `test_ac2_row_matches_coherence_aggregate` asserts row fields equal `Coherence.aggregate` over the same (α,β,γ); degenerate-α propagation case also exercised. | met |
| AC3 | `C_sigma_cross_num = exp((1/n) * Σ ln(C_sigma_num_i))`; `C_sigma_cross_math = 0` if any zero-component; otherwise geometric mean of `C_sigma_math_i`. | `cross_target.ml` `geometric_mean_num` (lines 84–93) and `geometric_mean_math` (lines 99–110) — implementation literally exp(sum_ln/n) with explicit zero-propagation short-circuit. | `test_ac3_geometric_mean_reference` asserts ≈ 0.7958 to 1e-4 AND `= analytical (∏xᵢ)^(1/n)` to 1e-12; `test_ac3_degenerate_math_propagation` asserts math=0 / num>0; arithmetic-mean negative case explicit. | met |
| AC4 | JSON has `kind = "cross_target_report"`, `schema_version`, `targets[]`, `provenance.cross_target_aggregate{C_sigma_cross_num, C_sigma_cross_math, formula, constituent_targets}`; missing `constituent_targets`, missing per-target aggregate, or flat top-level `c_sigma` must fail. | `cross_target.ml` `report_to_json` (lines 158–170) builds exactly that shape with `mode = "mechanical"` and `schema_version = "v3.2.0"` matching the AC4 sample. | `test_ac4_report_shape` enumerates every required field on both top-level and inside `provenance.cross_target_aggregate`, asserts `constituent_targets = ["spec";"engine";"repo"]` in operator-requested order; `test_ac4_no_flat_c_sigma` asserts no top-level `c_sigma` / `C_sigma`. | met |

### Named doc updates

The issue Scope does not require any spec-level edit (§7.4 already in `tsc-oper.md` on main); the cycle is implementation-only. No doc updates required → no doc updates audited.

### CDD artifact contract

| Artifact | Required (substantial cycle) | Present | Notes |
|---|---|---|---|
| `.cdd/unreleased/53/self-coherence.md` | yes | yes | Filled with AC mapping, role self-check, known-debt, environment incident note. |
| `.cdd/unreleased/53/gamma-scaffold.md` | per `review/SKILL.md` orchestrator | not present (see C1) | Repository convention is `self-coherence.md` + role close-outs; no released cycle in `.cdd/releases/` contains a `gamma-scaffold.md`. Treating as repo-local convention divergence, not a protocol bypass. C-band note only. |
| `.cdd/unreleased/53/gamma-closeout.md` | yes (γ close-out) | present **but misnamed per dispatch** (see B2) | Per dispatch: the existing file is α-shaped extended self-coherence content authored by γ-as-γ in the δ-as-γ single-session pattern. γ has acknowledged a CDD §1.4 protocol breach. The real γ close-out will follow this β verdict. |
| `.cdd/unreleased/53/beta-review.md` | yes (this file) | this file | Adds R1 verdict. |

### Active skill consistency (Tier 3)

Issue declares `cnos.eng/skills/eng/ocaml`. The diff is OCaml code (CLI parsing, library helper, tests) with documented option-(b) inline derivation, idiomatic `Yojson.Safe.t` emission, and tests written in the same style as `test_coherence.ml`. The skill is applied as well as declared.

Known debt (recorded in `self-coherence.md` §4 + §8): no OCaml toolchain in the worktree → α did not run `dune build` or `dune runtest`. β inherits the same constraint here.

Phase 2a result: AC coverage table **complete**; all four ACs met.

---

## Phase 2b — Diff and context inspection

Per `review/diff-context/SKILL.md`. The diff is 7 files / +711 / -12; touched surfaces: CLI (`main.ml`), library (`cross_target.ml`, `lib/dune`), tests (`test_cross_target.ml`, `test/dune`), CDD (`self-coherence.md`, `gamma-closeout.md`).

### 2.1.2 — Multi-format parity

The cross-target JSON shape is specified in three places and must agree:
- Issue AC4 sample.
- `cross_target.ml::report_to_json` (emitter).
- `test_ac4_report_shape` (validator).

Field-by-field comparison: `kind`, `schema_version`, `mode`, `targets[]` (with `id`, `C_sigma_num`, `C_sigma_math`, `zero_component_present`, `numeric_floor_applied`), `provenance.cross_target_aggregate` (with `C_sigma_cross_num`, `C_sigma_cross_math`, `formula`, `constituent_targets`). All three agree. Result: **PASS**.

One additive field — `formula = "geometric_mean"` — is in emitter and asserted by test, but not in the issue AC4 sample. The issue sample is "minimum shape"; additive provenance is consistent with §7.4's "MUST list the constituent targets…" without restricting other provenance fields. C-band note (C2) only.

### 2.1.7 — Derivation vs validation

Spec §7.4: `C_Σ_cross = (∏ C_Σ_i)^(1/n)`.
Emitter (`geometric_mean_num`): `exp((1/n) * Σ ln(C_sigma_num_i))` — mathematically identical to the product form, avoiding overflow on `n` large.
Test (`test_ac3_geometric_mean_reference`): asserts both the issue-oracle scalar value (≈0.7958 ± 1e-4) AND the analytical `(0.8 * 0.9 * 0.7) ** (1/3)` value (± 1e-12).

The test reaches the analytical form through a different code path than the emitter (literal multiplication + cube-root vs. log-sum-exp), so the test is a real check on the derivation, not a tautology. Result: **PASS**.

The math-degenerate case has a corresponding structural witness: `geometric_mean_math` short-circuits on `List.exists (fun r -> r.tr_zero_component_present)`, mirroring §7.4's "Strict zero on math-degeneracy" property. Result: **PASS**.

### 2.1.11 — Architecture leverage

The change adds a new mode of operation (cross-target) without touching the single-target path. Specifically:
- `Arg.Set_string` for `--target` → `Arg.String (fun t -> targets := t :: !targets)`: the accumulator preserves order via the final `List.rev !targets`, and single-target callers see exactly one element in `cli_targets`.
- The cross-target branch is gated on `n_targets >= 2`. For `n_targets = 1`, control falls through to the existing `build_bundle_from_target ... ; dispatch effective_mode` path **unchanged**.
- No existing module is modified semantically: `Mechanical_scoring`, `Coherence`, `Target_registry`, `Bundle`, `Report` are all called read-only.

This is genuine additive surface, addressing the root cause (CLI accepts one target) rather than papering over with a per-target wrapper script. **PASS**.

One observation, not a finding: the per-target derivation path goes through `Coherence.aggregate` inline (Option (b) per `self-coherence.md` §3) rather than reading canonical fields off `Mechanical_scoring.result`. This is the explicit consequence of #50 not being on main yet. When #50 lands, `row_of_mechanical` will be the only function that changes; the cross-target math and emitted JSON shape are stable. Acceptable.

### 2.1.13 — Design constraint preservation

Issue lists four active design constraints. Each verified:

| Constraint | Preserved | Evidence |
|---|---|---|
| Additive surface only; single-target reports / verdict logic unchanged | yes | Single-target dispatch path is byte-identical except for `Arg.String` accumulator (which leaves the one-target case observationally identical). No verdict-bearing code touched. |
| Cross-target aggregate is reporting-only | yes | `cross_target.ml` carries no threshold, no `assert_passes`, no `min_score`; `run_cross_target` `exit 0` after writing the report regardless of value. Grep confirmation. |
| Provenance lists constituent target ids and aggregate values used | yes | `aggregate.constituent_targets` + per-target `targets[]` row carrying `C_sigma_num` / `C_sigma_math`. |
| Cross-target execution is mechanical-only for this cycle | yes | `match effective_mode with | Llm \| Hybrid -> ... exit 1` before `run_cross_target` is reached. |

**PASS**.

### Other 2.1.* checks (briefly)

- 2.1.1 structural closure: cross-target branch closure complete — all `mode ∈ {Mech, Llm, Hyb, Auto}` × `n_targets ∈ {0,1,≥2}` reachable cells are handled. Auto + n≥2 is resolved to Mechanical-or-Hybrid before the cross-target gate; the unreachable `Auto -> assert false` arm is structurally unreachable (effective_mode is resolved upstream).
- 2.1.3 snapshot validation: no snapshot fixtures changed.
- 2.1.4 stale-path detection: no file moves/renames/deletions.
- 2.1.5 state-crossing: no process or binary boundaries crossed in this diff.
- 2.1.6 generation vs validation: schema_version `"v3.2.0"` is a literal constant in `cross_target.ml` and asserted by `test_ac4_report_shape` — single source for the emitter, the test verifies the constant's value matches the spec; no generation step is required. Acceptable.
- 2.1.8 module-wide assumptions: `Cross_target` is new; its assumption (inputs in `(0, 1]` after epsilon floor) is documented and held by the upstream `Coherence.aggregate` floor.
- 2.1.9 contract confinement: empty/duplicate constituency rejected upstream; geometric-mean functions document `[]` → `0.0` as a safe fallback.
- 2.1.10 contract confinement of CLI args: invalid mode → exit 1 (unchanged); missing all of `--kata`/`--target`/`--files` → exit 1 (unchanged); duplicate `--target` → exit 1 with explicit ids.

Phase 2b result: **PASS** with note C2 (additive `formula` field documented in emitter and test but not in issue AC4 minimum sample).

---

## Phase 2c — Architecture check

| Check | Result | Notes |
|---|---|---|
| A. Reason to change preserved | yes | `main.ml` still owns CLI orchestration; `cross_target.ml` owns reporting math + JSON shape; `Coherence` owns aggregate math; `Mechanical_scoring` owns per-target scoring. Each module has one reason to change. |
| B. Policy above detail preserved | yes | Mode-policy (mechanical-only-this-cycle) is enforced in `main.ml` (CLI/policy layer), not inside `cross_target.ml` (math/format layer). |
| C. Interfaces remain truthful | yes | `Cross_target.report_from_results` documents in its docstring that the caller is responsible for non-empty + non-duplicate constituency; `run_cross_target` enforces that precondition explicitly. |
| D. Registry normalization | yes | Existing `Target_registry.resolve_target_path` is reused for each `--target` argument; no new normalization surface. |
| E. Source/artifact/installed boundary preserved | yes | Authored code in `lib/`/`bin/`/`test/`; dune wires the build; no installed-state assumptions in the diff. |
| F. Surface separation | yes | Cross-target report kind is a new top-level `kind` value (`cross_target_report`), distinct from single-target shapes. CLI surface adds repeatable `--target` without absorbing or aliasing existing flags. Library surface is a new module `Cross_target` with no overlap onto `Report` or `Mechanical_scoring`. |
| G. Degraded-path visibility | yes | Math degeneracy (`zero_component_present = true` on any constituent) propagates to `C_sigma_cross_math = 0` while `C_sigma_cross_num > 0` is reported separately — the degraded path is observable in JSON and exercised by `test_ac3_degenerate_math_propagation`. Numeric floor application is also surfaced as `numeric_floor_applied` per-target row. |

**No blocking architectural finding.**

---

## Phase 3 — Verdict rules

Per `review/SKILL.md`:
- All four issue ACs are met.
- Zero unresolved D- or A-band findings.
- One B-band finding (CI-green gate not dischargeable in this environment); deferred per dispatch.
- One B-band note about misnamed γ artifact (process / naming hygiene).
- Three C-band cosmetic / convention notes.

Verdict: **APPROVED (R1)**, conditional only on the wave-level CI-green gate being confirmed downstream when an OCaml toolchain is available.

---

## Findings

### B1 — CI-green gate deferred (no toolchain)

**Type:** ci-status.
**Severity:** B (would normally block, demoted per dispatch directive 3.10 + wave-level toolchain constraint).
**Surface:** entire OCaml build / test surface.
**Description:** No `opam`/`dune`/`ocaml` on PATH in the β worktree (`which dune` returns nothing). β could not run `dune build` or `dune runtest`. The wave-level CI workflow (`.github/workflows/ci.yml`) is the canonical witness for this gate.
**Disposition:** Recorded as a B-band non-blocker per dispatch. δ/γ should confirm CI on `cycle/53` shows green before merge; if CI fails, this finding hardens to A-band and the verdict reverts to CHANGES-REQUESTED.

### B2 — `gamma-closeout.md` is α-shaped content (misnamed per dispatch)

**Type:** contract.
**Severity:** B (process / artifact-naming hygiene; does not block merge of code).
**Surface:** `.cdd/unreleased/53/gamma-closeout.md`.
**Description:** Per dispatch, this file contains γ-as-γ self-reflection material co-authored with α in the single-session δ-as-γ pattern; γ has acknowledged this is a CDD §1.4 protocol breach (the file is α-shaped extended self-coherence content, not γ's true close-out). The real γ close-out follows this β verdict.
**Disposition:** Not in β's authority to rename or remove (CDD §1.4 keeps α and β separated; renaming α-shaped content is α's or γ's responsibility). γ should write the actual close-out *after* β verdict and decide what to do with the existing file (rename to `gamma-as-alpha-notes.md`, fold into `self-coherence.md` appendix, or delete and re-author).

### C1 — Repository lacks the `gamma-scaffold.md` convention

**Type:** judgment / convention.
**Severity:** C (cosmetic; no released TSC cycle uses this artifact name).
**Surface:** `.cdd/unreleased/53/`.
**Description:** `review/SKILL.md` 3.x cites `gamma-scaffold.md` as a required pre-dispatch artifact. The TSC repo's convention (witnessed by `.cdd/releases/{0.5.0..0.9.0,...}/.../`) is `self-coherence.md` + role close-outs without a separate scaffold. The cycle is internally consistent with prior TSC cycles.
**Disposition:** Out of scope for #53. Reviewer flagged for awareness; no action required this cycle. If γ wants to harmonize, a separate process MCA is the right channel.

### C2 — `formula: "geometric_mean"` field is additive vs issue AC4 sample

**Type:** judgment.
**Severity:** C (purely cosmetic / additive).
**Surface:** `cross_target.ml::aggregate_to_json` (line ~140), `test_cross_target.ml::test_ac4_report_shape`.
**Description:** Emitter writes `"formula": "geometric_mean"` inside `provenance.cross_target_aggregate`; test asserts it. The issue AC4 minimum sample does not show this field. It is purely additive and consistent with §7.4's "MUST list the constituent targets…" provenance requirement (additive provenance is not restricted). No action required.

### C3 — Inline `Coherence.aggregate` call vs canonical fields (Option (b))

**Type:** judgment.
**Severity:** C (intentional, recorded in `self-coherence.md` §3).
**Surface:** `cross_target.ml::row_of_mechanical`.
**Description:** Per `self-coherence.md` §3, α chose Option (b) to derive per-target `C_sigma_num` / `C_sigma_math` inline by calling `Coherence.aggregate` over `(r.alpha.score, r.beta.score, r.gamma.score)`, rather than depending on #50's canonical result fields (which are not yet on main). The cross-target math and JSON shape are identical either way; only `row_of_mechanical` will change when #50 lands.
**Disposition:** Accepted. Follow-up rebase work after #50 lands on main is correctly scoped to this single function body. Recorded for #50's post-merge integration.

---

## Honest-claim verification (review SKILL.md 3.13)

- **Reproducibility of measurements**: AC3 oracle value `0.7958` from the issue is reproduced by `test_ac3_geometric_mean_reference` to tolerance 1e-4, and the analytical geometric mean is reproduced to 1e-12 — independently of the emitter's log-sum-exp form. Reproducible.
- **Canonical alignment of terminology**: `C_sigma_num` / `C_sigma_math` / `C_sigma_cross_num` / `C_sigma_cross_math` / `zero_component_present` / `numeric_floor_applied` / `constituent_targets` all match spec §7.4 + Core §5.2 + §5.4. Aligned.
- **Grep-verification of wiring claims**:
  - `cross_target` module is in `engine/ocaml/lib/dune::modules` (line "cross_target" present).
  - `test_cross_target` stanza is in `engine/ocaml/test/dune`.
  - `Cross_target.report_from_results` is called by `main.ml::run_cross_target`.
  - `reject_duplicates` is called as the first statement of `run_cross_target`.
  - No callers of the old single-`--target` API are broken (the only consumer is `cli_targets`'s single-element case, which falls into the existing single-target dispatch path).

Honest-claim verification: **PASS**.

---

## Merge instruction

`main` is branch-protected; β does not push to `main`. When δ/γ are ready to merge:

```bash
# After γ writes a real gamma-closeout (or renames the misnamed one),
# and after CI on cycle/53 shows green:
git fetch origin main cycle/53
git switch main
git merge --no-ff origin/cycle/53 -m "merge(53): cross-target report surface (Operational §7.4)

Closes #53.

Adds repeatable --target, mechanical cross-target dispatch, Cross_target
library helper (geometric_mean_num / geometric_mean_math / report_to_json),
and AC2/AC3/AC4 tests."
git push origin main
```

Or via GitHub PR/squash if branch protection requires it.

---

## CI disclaimer

This review was conducted with no OCaml toolchain available (`which dune` returns nothing). The CI-green gate (`review/SKILL.md` 3.10) was not dischargeable from the β session; it is deferred to the downstream CI workflow on `cycle/53`. If CI fails, finding B1 hardens to A-band and the verdict reverts to CHANGES-REQUESTED.

---

## Return to γ

- Verdict: **APPROVED (R1)**, conditional on CI-green.
- Finding counts: D=0, A=0, B=2 (one deferred per dispatch; one process/naming hygiene), C=3 (judgment/cosmetic).
- Push status: pushed to `cycle/53` via GH MCP API (git proxy returned 403 on the second push, mirroring γ's environment incident).
- Blockers for γ close-out: none on the code; γ should decide how to handle the misnamed `gamma-closeout.md` (rename / fold / re-author) before writing the real close-out.
