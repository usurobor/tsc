<!-- sections: [Gap, Skills, ACs, Self-check, Debt, CDD-Trace, Review-readiness] -->
<!-- completed: [Gap, Skills, ACs, Self-check, Debt, CDD-Trace, Review-readiness] -->

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
