# β review — cycle/50 (S1 canonical aggregate + report schema replacement)

**Verdict:** REQUEST CHANGES

**Round:** 1
**Branch under review:** `cycle/50-closeout` @ `d54cdb5`
**Branch base:** `main`
**Branch CI state:** unverified (no OCaml toolchain in dispatch sandbox; deferred to CI on landing branch — γ-authorized per dispatch §3.10 exemption)
**Merge instruction (post-fix):** merge `cycle/50-closeout` into `main` via PR with `Closes #50` in the merge commit. `main` is branch-protected → operator merges via GitHub UI.

---

## §2.0.0 Contract Integrity

| Check | Result | Notes |
|---|---|---|
| Status truth preserved | yes | Issue and self-coherence distinguish v0.9.0 shipped, v3.2 current spec, helper `Coherence.aggregate` already shipped, target state cutover. No conflation. |
| Canonical sources/paths verified | yes | `spec/tsc-core.md` §5 exists at v3.2.0 with `C_Σ^math`/`C_Σ^num` defined. `engine/ocaml/test/fixtures/provenance_v3_2_0.schema.json` is the canonical provenance fixture. `engine/ocaml/lib/coherence.ml` exports `aggregate`, `gauge_witness`, `provenance_json` with the signatures used by all call sites. |
| Scope/non-goals consistent | yes | Diff touches only the surfaces named "In scope"; LLM δ strictness, OOD, cross-target, kata/doc rebaseline, compat shim — none implemented. |
| Constraint strata consistent | yes | Active design constraints (aggregate in `Coherence.aggregate`, provenance-only, axis-internal `weighted_avg` allowed, schema rejects flat) match implementation. |
| Exceptions field-specific/reasoned | n/a | No exception-backed fields in this issue. |
| Path resolution base explicit | yes | Module paths are package-root-relative; tests use repo-relative fixture paths. |
| Proof shape adequate | yes | Invariant, oracle, positive, negative, operator-visible projection, known gap all in issue body §Proof plan. |
| Cross-surface projections updated | yes | Schema fixture + 3 writers + 1 text writer + kata runner all updated. No README or doctrine-projection updates needed for this scope (`docs/alpha/doctrine/3.2.0/provenance/*.json` are historical artifacts, not engine-generated). |
| No witness theater / false closure | yes | Schema uses `not.anyOf` to actually reject flat fields; tests assert presence of `provenance` AND absence of forbidden keys at every level. |
| PR body matches branch files | yes | `self-coherence.md` AC mapping matches diff. |
| γ artifacts present (gamma-scaffold.md) | **no** | `.cdd/unreleased/50/gamma-scaffold.md` is **absent**. Only `gamma-closeout.md` (which the dispatch explicitly acknowledges is misnamed/α-shaped content per §1.4 protocol breach) and `self-coherence.md` exist. Triggers rule 3.11b. **D-severity, classification protocol-compliance.** |

---

## §2.0 Issue Contract

### AC Coverage

| # | AC | In diff? | Status | Notes |
|---|----|----------|--------|-------|
| AC1 | Public report JSON has no flat aggregate fields | yes | met | `report.schema.json` requires `mode,alpha,beta,gamma,bottleneck_axis,provenance` and `not.anyOf [c_sigma, c_sigma_math, c_sigma_num, zero_component_present, numeric_floor_applied, epsilon]` at top level + `c_sigma*` ban inside `mechanical`/`llm`/`final`. Writers verified: `Mechanical_scoring.result_to_json` (lib/mechanical_scoring.ml:822), `Report.to_json` (lib/report.ml:71), `Hybrid_scoring.to_json` (lib/hybrid_scoring.ml:144), all 3 hybrid sub-objects emit `provenance`. Grep: no `("c_sigma"` JSON emission anywhere in lib/bin. Tests `test_mechanical_json_schema`, `test_hybrid_json_schema`, `test_hybrid_preserves_both` assert presence+absence. |
| AC2 | Production aggregate computations use `Coherence.aggregate` | yes | met | `Mechanical_scoring.compute_aggregate` (line 695) calls `Coherence.aggregate`. `Hybrid_scoring.aggregate_of_triple` (line 45) calls `Coherence.aggregate`. `Report.provenance_v320` (line 38) calls `Coherence.aggregate`. No production arithmetic `(α+β+γ)/3` survives — grep `compute_c_sigma\|hyb_final_csigma` returns empty. `weighted_avg` retained at line 256 of mechanical_scoring.ml for `axis_score_of_signals` only (axis-internal). Tests `test_aggregate_uses_coherence_helper`, `test_hybrid_aggregate_uses_coherence_helper` assert equality with helper and divergence from arithmetic mean for unequal triples. |
| AC3 | Comparison output names aggregate deltas by form | yes | met | `Mechanical_scoring.comparison` record (lib/mechanical_scoring.ml:98) carries `delta_c_sigma_math` and `delta_c_sigma_num`; `delta_c_sigma` removed. `comparison_to_json` (line 841) emits both form-suffixed deltas. `compare` populates from `aggregate.c_sigma_math`/`c_sigma_num` of new minus old. `summary` formatted with both deltas. `.mli` line 172-173 declares both. Test `test_comparison_delta_rename` asserts presence + absence + numeric correctness. |
| AC4 | Gauge witness production call sites use canonical aggregate | yes | met | Exactly three production sites: `Mechanical_scoring.provenance_to_json` (line 805), `Hybrid_scoring.provenance_for_triple` (line 67), `Report.provenance_v320` (line 46). All three build `c_sigma_fn` that calls `Coherence.aggregate` and returns `r.c_sigma_math`. Test `test_mechanical_json_schema` asserts `provenance.gauge_witness.w_gauge_ref` is a number (proving the canonical fn ran). |
| AC5 | Text and kata output use canonical names | yes | met | `Report.to_text` (lib/report.ml:144) prints `C_Σ^math` and `C_Σ^num` from `Coherence.aggregate`; no arithmetic-mean headline line. `Mechanical_scoring.summarize_result` (line 857) prints both canonical forms. `bin/main.ml` kata runner uses `result.aggregate.c_sigma_num` in both comparative branch (line 506-507) and single-bundle branch (line 559-587); component log line and result JSON use `c_sigma_num`. Test `test_aggregate_degeneracy` covers s_α=0 ⇒ math=0, num>0, flags true. |

### Named Doc Updates

| Doc / File | In diff? | Status | Notes |
|------------|----------|--------|-------|
| `engine/ocaml/lib/mechanical_scoring.ml` | yes | met | aggregate type + canonical routing + comparison rename + provenance writer. |
| `engine/ocaml/lib/mechanical_scoring.mli` | yes | met | aggregate type exported; comparison record updated; v0.10.0 cutover note in doc comment. |
| `engine/ocaml/lib/hybrid_scoring.ml` | yes | met | `aggregate_of_triple`, `provenance_for_triple`, all sub-objects emit provenance, no flat c_sigma. |
| `engine/ocaml/lib/report.ml` | yes | met | JSON key `provenance` (renamed from `provenance_v320`); text writer prints canonical forms. |
| `engine/ocaml/bin/main.ml` | yes | met | kata runner uses `result.aggregate.c_sigma_num` in both branches. |
| `engine/ocaml/test/fixtures/report.schema.json` | yes | met | requires `provenance`; rejects flat c_sigma family at every sub-object level via `not.anyOf`. |
| `engine/ocaml/test/test_mechanical.ml` | yes | met | new AC1–AC5 assertions added; legacy `c_sigma` field references all migrated to `aggregate.c_sigma_*`. |
| `engine/ocaml/test/test_coherence.ml` | not in diff | met (already canonical) | Unchanged; already calls `Coherence.aggregate` directly per v3.2 spec. |

### CDD Artifact Contract

| Artifact | Required? | Present? | Notes |
|----------|-----------|----------|-------|
| `.cdd/unreleased/50/self-coherence.md` | yes (α) | yes | Per-AC evidence, known debt, CDD trace populated. |
| `.cdd/unreleased/50/gamma-scaffold.md` | yes (γ, per CDD §1.4 + rule 3.11b) | **no** | Absent. Dispatch acknowledges §1.4 protocol breach: γ session ran as δ-as-γ single-session per §5.2 and produced no scaffold artifact. The file present, `gamma-closeout.md`, is dispatch-acknowledged as misnamed α-content. |
| `.cdd/unreleased/50/beta-review.md` | yes (β) | yes (this file) | |
| `.cdd/unreleased/50/gamma-closeout.md` | yes (γ post-merge) | premature/misattributed | Present on branch pre-merge, content is α-shaped per dispatch acknowledgement. Should not be relied on as γ close-out authority. Real γ close-out follows merge per §1.4. |

### Active Skill Consistency

| Skill | Required by | Loaded? | Applied? | Notes |
|-------|-------------|---------|----------|-------|
| `cnos.eng/skills/eng/ocaml` (Tier 3) | issue #50 §Skills to load | declared in self-coherence.md §CDD Trace | yes | Module-boundary type changes (aggregate record added to both `.ml` and `.mli`), `.mli` doc-comment updates for cutover, JSON-fixture migration via OCaml json_assoc form. Surface-evidence: clean `.mli` separation, no orphan field references, schema fixture is valid draft-07 JSON Schema. |
| `cnos.cdd/skills/cdd/CDD.md` §1.4 triadic | rule 3.11b | declared | partial (broken protocol) | γ-as-δ single-session per §5.2 was invoked, but no scaffold artifact was produced. This is the protocol-compliance finding F1 below. |

---

## Architecture Check

This change is on-the-line for architecture relevance — it touches a cross-module aggregate contract, schema fixture, and writer surfaces in a single coordinated cutover. Loaded the architecture sub-skill.

| Check | Result | Notes |
|---|---|---|
| Reason to change preserved | yes | Each touched module retains one reason: `Mechanical_scoring` = structural-proxy scoring; `Hybrid_scoring` = pure mechanical+LLM combiner; `Report` = output rendering; `bin/main` = I/O glue. No module gained an unrelated responsibility. |
| Policy above detail preserved | yes | Aggregate policy lives in `Coherence.aggregate` (kernel); callers consume it. Schema policy lives in the fixture; writers obey. No policy duplication. |
| Interfaces remain truthful | yes | `.mli` aggregate type promises both forms + flags; all three call sites produce them. Comparison record promises form-suffixed deltas; JSON delivers them. |
| Registry model remains unified | n/a | No registry surface touched. |
| Source/artifact/installed boundary preserved | yes | All changes are authored OCaml + authored JSON fixture; nothing is generated; nothing is installed. |
| Runtime surfaces remain distinct | yes | Skills, commands, providers untouched; the change is purely engine-internal contract. |
| Degraded paths visible and testable | yes | Degeneracy case (s_α=0) produces visible `c_sigma_math=0`, `c_sigma_num>0`, `zero_component_present=true`, `numeric_floor_applied=true` — all four are first-class fields, schema-required, and asserted in `test_aggregate_degeneracy`. |

---

## §2.1 Diff and context inspection (Phase 2b)

### 2.1.1 Structural closure (flat c_sigma cannot survive)

Audited every JSON writer:
- `Mechanical_scoring.result_to_json` — no `("c_sigma", ...)`; `provenance` is the only aggregate-emitting key.
- `Hybrid_scoring.to_json` + `mech_subobj` + `llm_subobj` — all three lift aggregate facts into nested `provenance`.
- `Report.to_json` — emits `provenance` key (was `provenance_v320`).

Schema fixture uses `not.anyOf` at top level AND inside `mechanical`/`llm`/`final` — every nesting level is enclosed. AC1 closure verified.

### 2.1.2 Multi-format parity

- Schema fixture, JSON writers, and text reports all use canonical aggregate names.
- Schema `aggregate_math.C_sigma_math` matches `Coherence.provenance_json` emission `("C_sigma_math", ...)`.
- Schema `aggregate_numeric.{C_sigma_num,epsilon,numeric_floor_applied}` matches `Coherence.provenance_json` emission.
- Text report `to_text` prints both forms; matches the schema's mandated provenance content.

### 2.1.4 Stale-path validation

- Grep `compute_c_sigma\|hyb_final_csigma` on cycle/50-closeout returns empty (zero stale arithmetic symbols).
- Grep `delta_c_sigma[^_]` returns only doc-comment in `.mli`, negative-assertion test, and the test's PASS-message string — all legitimate references.
- Old `provenance_v320` JSON key emission is gone (the function is still called `provenance_v320` internally — see Note in F3, but the JSON key is correctly `provenance`).

### 2.1.8 Authority-surface conflict

Single source of truth verified:
- Aggregate math: `Coherence.aggregate` only (no inline duplicate).
- Aggregate epsilon: `aggregate_epsilon = 1e-5` is declared in `Mechanical_scoring` (line 686), `Hybrid_scoring` (line 17), and `Report.provenance_v320` (line 37). Each carries a doc-comment saying they must agree. This is **3 declarations of the same constant** — minor B-severity finding (see F2).

### 2.1.9 Module-truth audit

Confirmed all `Coherence.gauge_witness` call sites in `engine/ocaml/lib` and `engine/ocaml/bin`:
1. `mechanical_scoring.ml:805` — `c_sigma_fn` calls `Coherence.aggregate`, returns `r'.c_sigma_math`. ✓
2. `hybrid_scoring.ml:67` — same pattern. ✓
3. `report.ml:46` — same pattern. ✓

No production site uses arithmetic or other surrogate. Test-only asymmetric helpers in `test_coherence.ml` remain (allowed per AC4).

### 2.1.13 Design constraints

| Constraint | Status |
|------------|--------|
| Aggregate policy lives in `Coherence.aggregate` | preserved |
| Public aggregate facts under provenance only | preserved + schema-enforced |
| `weighted_avg` allowed for axis-internal only | preserved (only call site is `axis_score_of_signals`) |
| Schema/writers/tests reject flat aggregate fields | preserved + tested |

---

## Findings

| # | Finding | Evidence | Severity | Type |
|---|---------|----------|----------|------|
| F1 | `.cdd/unreleased/50/gamma-scaffold.md` is absent. Dispatch acknowledges a CDD §1.4 protocol breach (γ-as-δ single-session §5.2 used) but the issue body carries no documented protocol exemption. Per rule 3.11b, this is a binding D-severity finding. The existing `gamma-closeout.md` is dispatch-acknowledged as misnamed α-content, not γ scaffold content. | `ls .cdd/unreleased/50/` → only `gamma-closeout.md` and `self-coherence.md`. Dispatch text: "γ has acknowledged a CDD §1.4 protocol breach... that file is α's extended self-coherence content, not γ's close-out... do not give it γ-close-out authority." Issue #50 body: no protocol exemption recorded. | D | contract / protocol-compliance |
| F2 | Aggregate epsilon constant `1e-5` is declared in three modules (`Mechanical_scoring.aggregate_epsilon`, `Hybrid_scoring.aggregate_epsilon`, hardcoded in `Report.provenance_v320`). Each declaration carries a doc-comment asking the reader to keep them in sync. This is a soft source-of-truth duplication: `Coherence.aggregate` already defaults to `1e-5` and is the canonical owner. Three drift opportunities for one constant. | `engine/ocaml/lib/mechanical_scoring.ml:686`, `engine/ocaml/lib/hybrid_scoring.ml:17`, `engine/ocaml/lib/report.ml:37`. | B | judgment |
| F3 | Function name `Report.provenance_v320` is now a stale identifier — the JSON key it emits has been renamed to `provenance`, but the OCaml binding still carries the version suffix. This is a discoverability hazard: a reader searching for "provenance writer" will find writers in three modules with three different names (`provenance_to_json`, `provenance_for_triple`, `provenance_v320`), and the v320 suffix suggests deprecation that does not exist. | `engine/ocaml/lib/report.ml:30`. Self-coherence.md §AC1 explicitly names the JSON key rename but not the function rename. | A | judgment |
| F4 | CI-green binding gate (rule 3.10) cannot be verified in dispatch sandbox — no OCaml toolchain, no `gh` CLI. Per dispatch §3.10 exemption ("γ-authorized; do not block solely on this"), this is documented as non-blocking but must be verified on the landing branch before merge. The branch carries genuinely new test logic (AC1–AC5 assertions) that has not been exercised. | `gh: command not found`; `dune` not available; α self-coherence §Known debt #1 acknowledges this gap. | B | contract / ci-status |

---

## Regressions Required

None at D-level for the implementation surface. The implementation appears coherent and all 5 ACs map to evidence in the diff. The single D-severity finding (F1) is a protocol-compliance gate, not an implementation regression.

---

## Notes

**Implementation quality.** The technical work is clean. Every AC has a positive test, a negative test (or grep-evidence equivalent), and a schema-level oracle. The cutover is internally consistent across mechanical, hybrid, report, and kata surfaces. The schema fixture uses `not.anyOf` correctly to enforce the AC1 invariant at every nesting level.

**Why D-severity on F1.** Rule 3.11b is binding and unambiguous: γ-scaffold absence is D-severity unless the issue documents a protocol exemption. The issue body (#50) does not contain such an exemption. The dispatch acknowledges the §1.4 breach and authorizes a §3.10 CI exemption, but does not (and cannot, per rule 3.11b) authorize a 3.11b bypass — that authority lives with the issue, not the dispatch. The fix is to either (a) add `gamma-scaffold.md` retroactively with γ-shaped content distinct from α self-coherence, or (b) amend the issue to record an explicit protocol exemption with reasoned justification.

**On the misnamed `gamma-closeout.md`.** This file should be either renamed (the content is clearly α extended self-coherence, per dispatch acknowledgement) or removed pre-merge. Leaving it as-is creates a load-bearing artifact that, by file name, claims γ-close-out authority — exactly the witness-theater pattern §2.0.0 row 9 is designed to catch. Recommend rename to `self-coherence-extended.md` or merge into `self-coherence.md`.

**CI verification post-merge.** The branch has not been built or tested in this sandbox. Required follow-up before declaring this cycle truly green: run `dune build` and `dune runtest` on the landing branch; verify all new AC1–AC5 assertions pass. Per §3.10 dispatch exemption, this does not block the verdict but must occur before release.

**Architectural posture.** The change is a model-of-truth tightening, not a refactor. It correctly localizes aggregate math to `Coherence.aggregate`, lifts public aggregate facts into provenance-only emission, and equips the schema fixture with the rejection mechanism that the AC1 invariant requires. No architectural smear. No silent constraint revision.

---

## After approval (recipe, not yet applicable)

When F1 is resolved (either gamma-scaffold.md added or issue-recorded exemption), and CI-green is verified on the landing branch:

```
# operator merges via GitHub UI (main is branch-protected)
# merge commit message must include: Closes #50
```

β does not merge directly — branch protection on `main` requires PR merge via UI. β documents intent here; operator executes.
