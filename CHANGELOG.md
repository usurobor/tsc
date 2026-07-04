# Changelog

## Spec releases

The spec lineage (C≡, TSC Core, TSC Operational, TSC Glossary, TSC Observation Dynamics) versions independently from the engine. Spec releases are theory work with no binary deployment; validation is mathematical reproduction and cross-spec consistency.

### Spec v3.2.1 (2026-05-09) — Cross-Target Aggregate Canonicalization

Coherence delta: docs-only patch · **Level:** L6

`spec/tsc-oper.md` §7.4 added: canonicalizes the **cross-target aggregate** `C_Σ_cross = (∏_i C_Σ_i)^(1/n)` (geometric mean of per-target C_Σ values) for self-application across multiple target scopes. Strictly additive; existing measurement and verdict logic unchanged. Resolves cycle #29 D3 — the cross-target formula previously computed ad-hoc in self-coherence reports is now normative.

**Affected:** `spec/tsc-oper.md` (§7.4 added; header v3.2.0 → v3.2.1; end-marker), `spec/tsc-glossary.md` (corresponds-to line bumped). `spec/tsc-core.md` unchanged.

**See:** cycle #32 self-coherence (AC2 / D3 #29).

### Spec v3.2.0 (2026-05-08) — Barrier-Coherence Patch

Coherence delta: C_Σ A- (`α A`, `β A`, `γ A-`) · **Level:** L7

Discrepancy → coherence link refactored as a typed transformation chain `δ → φ(δ) → D → Coh = exp(−D)`. Resolves three latent contradictions in v3.1.0: P2 unreachable (bounded Δ vs Δ → ∞ claim), λ overloaded (sensitivity *and* floor), and Degeneracy Axiom muddled with ε-flooring. Aggregate split into mathematical C_Σ^math and numerical C_Σ^num; they coincide whenever min sᵢ ≥ ε. Pre-v3.2.0 link-Lipschitz envelope corrected via L_link(λ); W2 split into ref + spread to close the best-π gauge loophole; W3 scale transform renamed φ → ψ; canonical v3.2.0 provenance JSON skeleton added.

**Affected:** `spec/tsc-core.md`, `spec/tsc-oper.md`, `spec/tsc-glossary.md`, `spec/tsc-observation-dynamics.md` (dependency uplift). C≡ v3.1.0 unchanged.

**See:** `RELEASE.md` for full coherence delta, validation, and known issues. Engine implementation deferred to a follow-on engine release.

---

## Engine releases

## Release Coherence Ledger

Grades use TSC's own triadic axes (see [spec/](spec/)). Engineering levels per [cnos ENGINEERING-LEVELS.md](https://github.com/usurobor/cnos/blob/main/docs/gamma/ENGINEERING-LEVELS.md).

| Version | C_Σ | α | β | γ | Level | Note |
|---------|-----|---|---|---|-------|------|
| 0.11.0 | A | A | A | A- | L7 | Official release: the self-measurement + CM² wave (0.10.1–0.10.5) consolidated into main. The platform at this line: skill-declared methodologies (`#CoherenceMethodology` / `#SelfMeasure` 1st / `#CMOfCMs` 0th), rendered CI with a pinned Claude CLI witness and k=3 sampling in both measurement and ledger routes, barrier-mapped consistency protocol, blind-staged admissibility with the five-attacker matrix (flatterer / path-gamer / boilerplate-gamer rejected; basename-gamer / cherry-pick-assassin admitted at the public gate — named residuals), and executed held-out commit-reveal standing: on unseen anchor hx-02 the engine hit its predeclared fail band ([0, 0.78], scored 0.7171) while every memorizing challenger missed at 0.99+ — house-authored-blind-heldout, earned by mechanics (unmemorizability, not externality). New since 0.10.5: SELF-MEASURE v3.2.2 — the v3.2.1 band-snap prediction was refuted by its own k=3 measurement (spreads widened, spec Coh_consistency 0.815→0.618, repo 0.754→0.513: the snap collapsed judgment onto two rows), so the snap is withdrawn, defect enumeration with severities retained, and the refutation is recorded inside the instruction; ledger push hardened (`git pull --rebase --autostash`, 5 attempts — dune regenerates `tsc_engine.opam` mid-build, which made the bare rebase refuse and cost run 11 its computed k=3 reading for 0.10.5: cross 0.7482 hybrid, samples 3, standing failed at floor 0.90); 0.10.5 recorded as labeled mechanical (cross 0.9808). Declared-open residuals: external anchor author (an institution, not code), hybrid cross-target in-engine, `.mli` coverage, `coh --methodology` generalization for third-party CMs. |
| 0.10.5 | A | A | A | A- | L7 | Witness-contract calibration wave (SELF-MEASURE v3.2.0 → v3.2.1). The k=3 CI spreads (spec δ=0.17, engine δ=0.12, repo δ=0.22 — Coh_consistency 0.75–0.87, all standing gates failed) located the system's weakest link in the semantic meter itself; v3.2.1 adds the count-then-map discipline — enumerate defects with severities, map to anchored bands (0.95/0.85/0.75/0.60/0.40/0.20 ±0.03), δ reported as table-row midpoints, confidence rubric — predicting the next k=3 spread narrows. Falsifiable: if Coh_consistency does not rise above the 0.75–0.87 baseline, the rubric failed. Witness findings fixed: ARCHITECTURE.md target/methodology inventory (was 3 targets, no methodology layer), obs-dynamics §1a correspondence note (CalibrationBasis/GroundingRecord/Certificate mapped to α/β/γ). Ledger: read_hybrid freshness guard (stale local session reports can no longer masquerade as a release measurement); 0.10.4 row recovered as labeled mechanical after run 10 computed its k=3 hybrid measurement and lost the final push to a five-commit branch race. |
| 0.10.4 | A | A | A | A- | L7 | Ledger learns the k=3 lesson (final review gate). The release ledger's witness route now samples k=3 per target with per-target consistency, identical to the measurement workflow — a release row is never a single-sample semantic reading. Row schema gains Samples / min Coh_consistency / Standing columns; existing hybrid rows (0.10.2, 0.10.3) migrated to `single-sample: no standing`. `ledger.semantic_samples` typed in the schema and declared in the skill. First live k=3 CI spreads recorded: spec δ=0.17 (Coh_cons 0.8148), engine δ=0.12 (0.8725), repo δ=0.22 (0.7542) — all below the 0.90 floor, standing withheld while reports publish: same-route samples are a lower bound, and the doctrine now names the diversity ladder (same-route samples → cross-route witnesses → stewarded external auditors). |
| 0.10.3 | A | A | A | A- | L7 | Standing-scope wave (external merge-gate round 3). Admissibility v2: anchors staged blind (no kata paths, no adjacent labels), 03-comparative executed per component, scorer contract is JSON with evidence (low score + no evidence = unfalsifiable = inadmissible); three-attacker CI self-test (engine admitted; all-1.0 flatterer and path-gamer rejected). Kata label manifests join the cm-of-cms corpus (anchor bodies excluded by design — negative controls are deliberately incoherent specimens). Formal displacement thresholds (label-based, ε=0.03 held-out margin, ±0.10 numeric tolerance, Kendall τ≥0.9); challenger registration protocol (digests + reveal-after-registration); `standing_scope` typed and stamped on reports (currently house-authored-public-commons, honestly). Measurement workflow samples the witness k=3, validates every sample through the funnel, and computes Coh_consistency in CI as a standing gate (floor 0.90) that never blocks publishing. First-witness findings fixed: tsc-core §0 axis naming, glossary stale v3.1.0 refs; README/operator-manual CI-gating drift closed (TSC_LLM_ENABLED and tsc.yml descriptions retired). Mechanical at release: spec 0.984, engine 0.991, repo 0.974, cross 0.983; methodology 0.989, cm-of-cms 0.996. |
| 0.10.2 | A | A | A | A- | L7 | CM² wave: coherence methodologies become measurable objects. `#CoherenceMethodology` split into measurement essence + optional deployment bindings; `#CMOfCMs` (0th methodology, `skills/cm-of-cms/SKILL.md`) measures methodologies — itself included — with a consistency protocol (`scripts/cm-consistency.sh`: N-run mechanical determinism, LLM repeat-spread through the barrier) and an adversarial-CM doctrine (admissibility via the kata commons, off-diagonal standing, maximin strength). New targets `methodology` and `cm-of-cms`. Bug fix caught by self-application: target KIND conflated with the canonical target NAMES made the witness funnel refuse valid responses for any aggregate target not named `repo`. Witness route moved from claude-code-action (rejects `push` events) to a renderer-pinned Claude CLI invocation. Instrument validity: quoted keyword mentions no longer count as deprecation acts. Mechanical at release: spec 0.984, engine 0.991, repo 0.974, cross 0.983; methodology 0.989, cm-of-cms 0.990; hybrid CM²: methodology 0.933, cm-of-cms (self-applied) 0.906. |
| 0.10.1 | A | A- | A | A- | L7 | Self-measurement platformization wave. `coh self` (skill-declared, CUE-validated, rendered command + workflows); witness-validation funnel with staged refusal artifacts; external witness route (`--emit-prompt` / `--llm-response`); Claude CLI CI witness gated by secret presence; instrument-validity pass on the twelve mechanical signals (document scoping, link normalization, anchor validation, authority self-claims) — kata-05 now caught for its real contradictions; per-release coherence ledger (`.tsc/COHERENCE.md`, backfilled 0.1.0→0.10.0 with a fixed instrument). Mechanical self-measurement at release: spec 0.984, engine 0.990, repo 0.978, cross 0.984; first hybrid witness run: cross 0.943. |
| 0.10.0 | A- | A- | A- | A- | L7 | Canonical v3.2 scoring cutover wave (#49). Geometric `C_Σ^math` / `C_Σ^num` replaces flat arithmetic `c_sigma`; report schema emits aggregate facts only under `provenance.aggregate_math` / `provenance.aggregate_numeric`. OOD detector for `aggregate_semantics` (#52). Strict v3.2 LLM δ validation (#51). Cross-target §7.4 report surface (#53). Cleanup pass (this row): kata baselines re-scaled; active docs rewritten; `project.tsc` removed; target-registry smoke tests; forbidden-wording CI rule. **Migration:** pre-v0.10.0 reports quoted arithmetic mean `(α+β+γ)/3`; v0.10.0 reports quote geometric `(α·β·γ)^(1/3)` — historical reports are not directly comparable. See `RELEASE.md`. (#49 master; subs #50, #51, #52, #53, #54) |
| 0.9.0 | A- | A- | A | A- | L6 | Phase 2 kata progression: comparative (kata-03) + philosophical (kata-04, mechanical-mode) + adversarial (kata-05, multi-file); kata runner gains [[components]]+ranking; +25 hermetic test assertions (146→171). 1 round (β R1 APPROVED, 0A/0B/4C). (#34, cycle: L6) |
| 0.8.0 | A | A | A | A- | L6 | Process enforcement: CHANGELOG release gate in scripts/release.sh. Prevents incomplete releases (v0.4.0 class). (#30, cycle: L6) |
| 0.7.0 | A | A | A | A | L6 | Test migration: Python retired, 74-assertion OCaml suite, auto-mode fallback test, Credentials module. (#26, cycle: L6) |
| 0.6.0 | B+ | B+ | A | B+ | L6 | Spec v3.2.0 engine: barrier transform φ, L_link case-split, math/num split, W2 gauge witness (ref+spread), provenance JSON skeleton, SELF-MEASURE.md δ-based protocol, OOD cutover guard. 69-assertion test suite. (#24, cycle: L6) |
| 0.5.0 | A | A | A | A | L6 | Hybrid scoring: mechanical + llm + hybrid + auto modes. 12 structural signals, 61-assertion OCaml test suite, direct file input. Full CDD cycle (#25). |
| 0.4.0 | C+ | B | C+ | C | L6 | Dotenv credential loading + VERSION as single source of truth + release scripts. Partial-protocol release: no CDD cycle, β review absent, post-release artifacts retroactive (#27). |
| 0.3.1 | A- | A- | A- | B+ | L5 | Binary renamed `tsc` → `coh` to avoid TypeScript compiler collision. |
| 0.3.0 | A- | A- | A- | B+ | L6 | Installable binary: rename to `tsc`, install.sh, release workflow, --version. Version source unified. |
| 0.2.0 | B+ | B+ | B+ | B | L6 | Doc coherence: triadic structure, operator manual, terminology standardized, 14 issues filed and resolved. |
| 0.1.1 | B | B | B+ | B- | L5 | CI fix: missing `.opam` + ezcurl type error. Reactive — caught post-merge. |
| 0.1.0 | B | B+ | B | B- | L7 | First OCaml engine. Targets, provider transport, CI, self-measurement workflow. CI broken at tag time. |

Pre-0.1.0 versions (2.0.0–3.1.0) used a Python implementation with category-theoretic axioms. Removed — available in git history. Not scored — different system.

---

## 0.10.1 (2026-07-03)

Self-measurement platformization. The full procedure is declared in `skills/self-measure/SKILL.md` (frontmatter CUE-validated, cross-checked against engine source and the scoring instruction) and rendered into `scripts/coh-self`, the `tsc-self-measure` workflow (mechanical job ungated; LLM witness via Claude CLI, gated by presence of the `CLAUDE_CODE_OAUTH_TOKEN` secret), and the `tsc-coherence-ledger` workflow (one mechanical row per version tag into `.tsc/COHERENCE.md`).

### Added

- `coh self` — external-subcommand dispatch to the rendered `coh-self` (per-target + cross-target self-measurement; `--require-llm` refuses loudly without credentials; every report's `mode` field states its backend).
- External witness route: `--emit-prompt` / `--llm-response`; one validation funnel (`Response_schema.validate_witness_response`) classifying every refusal (parse / base_schema / prohibited_fields / target_mismatch / v3_2_delta) into a durable stage-tagged artifact; per-stage fixtures replayed by CI smoke.
- Per-release coherence ledger `.tsc/COHERENCE.md`, backfilled 0.1.0→0.10.0 with the 0.10.1 instrument.
- `skills/` + `schemas/skill.cue` (+ fixtures, validator) — typed skill modules, cnos-style.
- Engine README (module map, change discipline, known debt); SELF-MEASURE §2.2 code-craft standards for engine-target judgment.

### Changed

- Mechanical instrument validity: document-scoped structure signals, source-relative link normalization, anchor (heading-slug) validation, authority self-claim detection with steep contest penalty, ledger/archive-aware deprecation and version scanning, header-positioned generated markers. Kata expectations unchanged; kata-05 baseline re-documented (caught via contested self-claims + contradictory anchors at 0.7754 ≤ 0.78).
- Operator manual rewritten to the four-mode contract; engine docs release history completed through 0.10.0; report metadata stamps `SELF-MEASURE/3.2.0`.
- `tsc.yml` (dormant, raw-API-key) replaced by rendered `tsc-self-measure.yml`.

### Measured

Mechanical at release: spec 0.9839 · engine 0.9896 · repo 0.9779 · cross **0.9838**. First hybrid witness run (external route, claude-session): cross 0.9432 after three fix rounds (from 0.8672 — operator docs had lagged the system).

## 0.10.0 (2026-05-13)

Canonical v3.2 scoring cutover wave. Master #49 with four predecessor cycles (#50, #51, #52, #53) and one cleanup cycle (#54 — this entry). Aggregates emitted as geometric `C_Σ^math` and `C_Σ^num` under `provenance`; the flat top-level `c_sigma` field is removed.

### Migration note (pre-v0.10.0 comparability)

Pre-v0.10.0 reports — and any frozen report quoted in `docs/{tier}/{bundle}/{X.Y.Z}/` snapshot directories — quoted the arithmetic-mean aggregate `c_sigma = (α + β + γ) / 3`. v0.10.0 reports quote the geometric aggregate `C_sigma_num = (max(α, ε) · max(β, ε) · max(γ, ε))^(1/3)` (with `ε = 10⁻⁵`) under `provenance.aggregate_numeric`, and the strict mathematical aggregate `C_sigma_math = (α · β · γ)^(1/3)` under `provenance.aggregate_math`.

The two aggregates disagree by a few percentage points on well-balanced triples (e.g. arithmetic 0.9333 vs geometric 0.9283 for kata-04's `α=1.0, β=1.0, γ=0.8`) and by larger amounts on imbalanced ones (e.g. arithmetic 0.689 vs geometric 0.658 for kata-02's inferred `α=0.9, β=0.43, γ=0.737`). Pre-cutover numbers in frozen reports are **not directly comparable** to post-cutover output. Frozen snapshots are intentionally left unedited (CDD §5.6); the comparability limit is documented here and once more in `RELEASE.md`. Historical-report migration is out of scope for this wave (see #54 §Out of scope).

### Added
- **Geometric aggregate forms** (`engine/ocaml/lib/coherence.ml`, `lib/report.ml`): `C_sigma_math` and `C_sigma_num` emitted under `provenance.aggregate_math` and `provenance.aggregate_numeric` (#50). The flat top-level `c_sigma` field is removed from JSON reports.
- **OOD `aggregate_semantics` detector** (`engine/ocaml/lib/ood.ml`): refuses pre-cutover arithmetic-mean reports at ingest time (#52).
- **Strict v3.2 LLM δ validation** (`engine/ocaml/lib/response_schema.ml`): rejects responses missing the per-pair δ values required by the canonical-v3.2 transformation chain (#51).
- **Cross-target §7.4 report surface** (`engine/ocaml/lib/cross_target.ml`, `lib/report.ml`): canonicalizes the multi-target aggregate `C_Σ_cross = (∏ C_Σ_i)^(1/n)` per `spec/tsc-oper.md` §7.4 (#53).
- **Kata baseline blocks** (`katas/*/kata.toml`): each kata now records a `[baseline]` block (or per-component baselines for kata-03) with the v0.10.0 canonical-aggregate provenance — `baseline_engine_commit`, `baseline_engine_version`, `baseline_command`, `mode`, `config_hash`, `input_file_hashes`, α, β, γ, `c_sigma_math`, `c_sigma_num`, `zero_component_present`, `numeric_floor_applied`, `rationale_category` (#54 AC1).
- **Target-registry smoke tests** (`engine/ocaml/test/test_target_registry.ml`): parse `targets/registry.tsc`, resolve `spec`/`engine`/`repo` paths, parse each manifest, and assert non-empty bundle expansion for each (#54 AC6).
- **Forbidden-wording CI rule** (`scripts/check-forbidden-wording.sh` + CI wiring): forward-only check that rejects newly-added `"Operational acceptance"`, `"Operationally accepted"`, `"self-coherence ACCEPT"`, `"release criteria satisfied"` outside frozen / archive paths (#54 AC7).

### Changed
- **Active docs rewritten** (`docs/THESIS.md`, root `QUICKSTART.md`, root `ARCHITECTURE.md`, `docs/beta/guides/OPERATOR-MANUAL.md`, `katas/README.md`, `katas/*/README.md`): describe geometric `C_Σ^math` / `C_Σ^num`; JSON examples reference `provenance.aggregate_math` / `provenance.aggregate_numeric`; arithmetic-mean headline language removed (#54 AC2).
- **`VERSION`, `engine/ocaml/dune-project`, `engine/ocaml/tsc_engine.opam`**: 0.9.0 → 0.10.0 (#54 AC8).
- **`RELEASE.md`**: rewritten as v0.10.0 release notes describing the canonical-v3.2-cutover end-to-end (#54 AC8).

### Removed
- **`project.tsc`** at repo root: superseded by `targets/registry.tsc` since v0.1.0; retained until now for reference, removed in this cycle (#54 AC3).

### Frozen-snapshot policy
- Per CDD §5.6, only markdown-link and backtick-path repairs are permitted to frozen version snapshots. AC4 of #54 verified that the three named files (`docs/alpha/doctrine/3.2.0/SELF-COHERENCE.md`, `docs/alpha/engine/0.5.0/POST-RELEASE-ASSESSMENT.md`, `docs/design/0.5.0/DESIGN.md`) carry no v0.10.0 archival banner text — no edits applied. The migration note above is the active-surface record; frozen content remains untouched.

### Known debt
- Kata-01 / kata-02 / kata-03 baselines use *inferred* (α, β, γ) triples from cycle-34 README signal narrative (the cycle-34 calibration recorded only the arithmetic-mean aggregate, not the per-axis triple, for these katas). The `[baseline]` blocks mark `baseline_engine_commit = "pending-ci"`; the first v0.10.0 CI run records canonical readings, and a future cycle tightens `expected.score_range` accordingly.
- Kata-04 / kata-05 carry `rationale_category = "frontier-tightening"` — their `score_range.max` is deliberately wider than the geometric `c_sigma_num + 0.001` ceiling, retaining documented "moving frontier" margin.
- Pre-v0.10.0 frozen reports are not migrated; the comparability limit is the migration note's job.
- OCaml toolchain absent in α's dispatch sandbox; `dune build` / `dune runtest` deferred to CI on the PR.

---

## 0.9.0 (2026-05-12)

Phase 2 kata progression. Engine kata runner gains `[[components]]` + `expected.ranking` support; three new katas (comparative, philosophical, adversarial) extend Phase 1's positive+negative-control framework into the comparative-ordering, cross-domain, and adversarial axes. Full CDD cycle (#34).

### Added
- **`katas/03-comparative/`** — comparative kata; bundles copies of kata-01 (glider) and kata-02 (random-soup) inputs as named `[[components]]`; asserts the mechanical scorer ranks glider above random-soup. Observed margin on cycle/34-impl HEAD: 0.9233 vs 0.6889 (≈0.234 gap).
- **`katas/04-philosophical/`** — first cross-domain kata; input is `examples/philosophical/consciousness.md`; mode=mechanical (γ-decided at scaffold time per cycle #34 active design constraint); `verdict=fail` records the *semantic* claim while `score_range = {min=0.0, max=0.95}` brackets the observed mechanical C_Σ ≈ 0.9333 — the kata's purpose is to document the mechanical scorer's upper-limit behavior on well-formatted prose.
- **`katas/05-adversarial/`** — multi-file adversarial kata; three sibling Quanton-spec files share identical surface structure (headings, version stamps, dense cross-references, "supersedes" language) but contradict each other on every load-bearing claim (transport, frame format, canonical authority). Observed C_Σ ≈ 0.7466 (α=0.969, β=0.470, γ=0.801; β catches the cross-file contradictions).
- **`engine/ocaml/lib/kata.ml`** — `kata_component` type + `components` and `ranking` fields on `kata_config`; otoml parsing of `[[components]]` array-of-tables and `[expected].ranking` string array. Phase 1 single-bundle katas unaffected.
- **`engine/ocaml/bin/main.ml::run_kata`** — comparative path: when `kata.components <> []`, scores each component as its own `Bundle.t`, sorts by C_Σ, asserts observed ranking matches `expected.ranking`; emits `expected_ranking` / `actual_ranking` / `ranking_correct` + per-component sub-results in the result JSON. Single-bundle path unchanged.
- **`engine/ocaml/test/test_kata.ml`** — 25 new hermetic assertions covering kata-03 (components + ranking), kata-04 (mechanical mode + verdict=fail + README mode-justification claim), kata-05 (multi-file + verdict=fail + README adversarial-design claim); total suite 146 → 171 PASS lines.
- **`katas/README.md`** — §"Current katas" table; `[[components]]` + `[expected].ranking` schema rows; §"Comparative katas (Phase 2)" describing the runner's branched pass-criterion.
- **`QUICKSTART.md` §8** — smoke-test invocations for kata-03/04/05.

### Changed
- **`engine/ocaml/test/dune`** — explicit `(modules ...)` stanzas per test executable; required by dune ≥ 3.14 for multi-test files (no behavioral change; previously implicit module inference).
- **`VERSION`** — `0.8.0` → `0.9.0`. Engine release ledger row added.

### Deferred (AC6)
- LLM-mode runner support. kata-04's mechanical-mode choice (γ-decided at scaffold) means AC6 (LLM-mode kata recognition with hermetic skip-on-no-credentials) is not exercised this cycle. Phase 3 follow-on.

### Known debt
- 0.8.0 CHANGELOG details section never landed (only the ledger row exists). Cycle #34 did not retroactively author it — scope-limited to its own deliverables.
- AC6 (LLM-mode kata recognition) carried forward to Phase 3.
- kata-04's score_range is intentionally wide (max=0.95) — itself a documented limit; tighten in a future cycle if the mechanical scorer learns to discriminate philosophical prose from engineering docs.
- kata-05's `score_range.max=0.78` is a small margin above observed 0.7466; if mechanical-scorer α or γ refinements push C_Σ above 0.78, kata-05 fails until either the scorer improves further or the adversarial input is hardened (kata-05's documented "moving frontier" behavior, per issue #34 §Active design constraints).

---

## 0.7.0 (2026-05-08)

Test migration: Python retired, OCaml test suite complete. Full CDD cycle (#26, Sub 3 of #23).

### Added
- **`engine/ocaml/lib/credentials.ml`**: `Credentials` module — `has_llm_credentials : unit -> bool` extracted from `bin/main.ml` to enable hermetic testing of the auto-mode fallback branch.
- **`engine/ocaml/test/test_mechanical.ml`** (extended): `test_auto_mode_fallback` added via `Unix.putenv`; completes AC4 surface 8. Total suite: 74 PASS lines.

### Changed
- **`engine/ocaml/lib/dune`**: `credentials` module added to library modules list.
- **`engine/ocaml/bin/main.ml`**: mode-dispatch calls `Tsc_engine.Credentials.has_llm_credentials()`. Behavior identical.
- **`engine/ocaml/test/dune`**: `unix` library added to test dependencies.

### Removed
- **`tests/conformance/`**: `test_consciousness.py`, `test_emergence.py`, `test_free_will.py`, `test_glider.py`, `test_random_soup.py` — Drop (Python-controller-coupled, no mechanical-scorer analogue).
- **`tests/self/test_self_coherence.py`** — Rewrite (superseded by `test_coherence.ml` + `test_mechanical.ml`).
- **`pyproject.toml`** — removed; no Python content remains.

### Known debt
- AC6 live-LLM integration test: carried from cycle #24.
- Beta derivation from δ values: carried from cycle #24.
- `alpha/SKILL.md` §2.6 caller-path trace patch (cnos repo): carried from cycle #24.
- `CONTRIBUTING.md` / `.github/pull_request_template.md`: stale Python/pytest references; doc-cleanup MCI filed.
- MCI freeze in effect: ≥3 issues at growing lag (#28, #29, #30, #31).

---

## 0.6.0 (2026-05-08)

TSC spec v3.2.0 implementation in the OCaml engine. Full CDD cycle (#24, Sub 1 of #23).

### Added
- **`engine/ocaml/lib/coherence.ml`**: barrier transform `φ(δ) = δ/(1−δ)`, discrepancy energy `D`, coherence link `Coh = exp(−D)` with strict zero at `δ=1`. Math/num aggregate split (`C_Σ^math`, `C_Σ^num`, `zero_component_present`, `numeric_floor_applied`). W2 gauge witness (`w_gauge_ref`, `w_gauge_spread`, `tau_gauge_spread`). Provenance JSON assembly.
- **`engine/ocaml/lib/lipschitz.ml`**: L_link closed-form case-split — `(4/λ)·exp(λ−2)` for `0 < λ ≤ 2`, `λ` for `λ ≥ 2`, continuous at `λ = 2`.
- **`engine/ocaml/lib/ood.ml`**: OOD cutover guard — refuses/warns on `schema_version < "v3.2.0"` with reset diagnostic.
- **`engine/ocaml/test/test_coherence.ml`**: 69 assertions covering AC1–AC7 (barrier transform, L_link, math/num split, W2 gauge witness, OOD cutover).
- **`engine/ocaml/test/fixtures/provenance_v3_2_0.schema.json`**: JSON schema for all required v3.2.0 provenance keys.

### Changed
- **`engine/ocaml/lib/report.ml`**: `to_json` accepts optional per-pair δ args; `provenance_v320` wires `gauge_witness` and `l_link` so W2 and L_link fields are populated in real reports.
- **`engine/ocaml/lib/response_schema.ml`**: `extract_deltas` added; `validate_result` docstring corrected (LLM-provided vs. engine-computed fields accurately described).
- **`engine/ocaml/bin/main.ml`**: `run_llm` calls `extract_deltas` and passes δ values to `Report.to_json`.
- **`runtime/SELF-MEASURE.md`**: rewritten for δ-based scoring — LLM provides per-pair discrepancy values (δ_αβ, δ_βγ, δ_γα) and per-component scores; engine applies transformation chain.

### Known debt
- AC6 live-LLM integration test: `LLM_API_KEY` not available in this environment; δ-extraction path wired but not exercised end-to-end.
- Beta derivation from δ values: deferred design extension.
- `alpha/SKILL.md` §2.6 pre-review gate patch (cnos repo): caller-path trace row not yet landed.

---

## 0.5.0 (2026-05-08)

Hybrid scoring pipeline. Full CDD cycle (#25, Sub 2 of #23).

### Added
- **`mechanical_scoring.ml`**: 12 structural signals across α/β/γ axes (pattern, relational, process). Implements `mechanical_scoring.mli` from #22.
- **`hybrid_scoring.ml`**: pure combiner producing `mechanical`, `llm`, and `final` sub-objects. LLM is authority unless both backends agree; `final.source` named explicitly.
- **`bundle.ml`** `type t` + `type file`: direct file input (`--files <glob>`) shares the same `Bundle.t` as named targets.
- **`--mode {mechanical,llm,hybrid,auto}`** + **`--files <glob>`** (repeatable) CLI flags. `auto` resolves to `mechanical` without credentials, `hybrid` with.
- **`"mode"` field** in every report output via `report.ml to_json ~mode`.
- **OCaml test suite** (`engine/ocaml/test/test_mechanical.ml`): 61 assertions covering bundle parity, determinism, JSON schema shape, hybrid preservation.
- **`fixtures/report.schema.json`**: canonical report schema fixture (reference documentation).
- **README, QUICKSTART, ARCHITECTURE** updated to document all modes and direct-file usage.

### Fixed
- `sig_traceability_presence`: bare `"#"` in `trace_kws` caused semantic inversion (fired on any Markdown heading). Removed; remaining keywords cover the intended patterns.

### Known debt
- AC8 partial: pre-existing Python in `tests/conformance/` — Sub 3 owns removal.
- v3.2.0 provenance fields in report sub-objects — Sub 1.
- Mechanical score calibration and hybrid adjudication policy — future cycles.

---

## 0.3.1 (2026-04-05)

Binary naming collision fix.

### Changed
- Binary renamed from `tsc` to `coh` (coherence). `tsc` conflicts with the TypeScript compiler on any machine with Node.js installed.
- Release artifact renamed from `tsc-linux-x64` to `coh-linux-x64`.
- CI artifact, install.sh, operator manual, workflows all updated.

---

## 0.3.0 (2026-04-04)

Installable CLI binary. Full CDD cycle (#21).

### Added
- **Installer** (`install.sh`): one-liner install via `curl | sh`. Atomic temp-file install, UX-CLI compliant output, NO_COLOR support, explicit platform detection.
- **Release workflow** (`.github/workflows/release.yml`): tag-triggered, builds and attaches `tsc-linux-x64` to GitHub Release.
- **`--version` flag**: `tsc --version` prints version derived from source.

### Changed
- Binary renamed from `tsc-engine` to `tsc` everywhere (bin/dune, Makefile, CI, workflows, operator manual).
- CI artifact renamed from `tsc-engine-linux-x86_64` to `tsc-linux-x64`.
- Operator manual: new "Install" section with one-liner and build-from-source paths.
- README quick start: install one-liner instead of "see operator manual".

### Design
- [DESIGN.md](docs/alpha/engine/0.3.0/DESIGN.md): installer survey (cnos, rustup, deno, homebrew, bun), UX-CLI compliance analysis, atomic install pattern.
- [PLAN.md](docs/alpha/engine/0.3.0/PLAN.md): 6-step implementation plan.

---

## 0.2.0 (2026-04-03)

Documentation coherence iteration. Thorough cross-file review, 14 issues filed, all resolved.

### Added
- **Operator manual** (`docs/beta/guides/OPERATOR-MANUAL.md`): build, config, run, CI, troubleshooting
- **THESIS.md** (`docs/THESIS.md`): entry point above the triad
- **DOCUMENTATION-SYSTEM.md** (`docs/beta/governance/`): triadic doc structure adapted from cnos
- **Doctrine bundle** (`docs/alpha/doctrine/`): indexes spec/ theory
- **Engine bundle** (`docs/alpha/engine/`): indexes engine design, versioned artifacts
- CI uploads binary artifact (`tsc-engine-linux-x86_64`)

### Changed
- Env vars renamed: `TSC_PROVIDER` → `LLM_PROVIDER`, `TSC_MODEL` → `LLM_MODEL`, `TSC_API_KEY` → `LLM_API_KEY`
- QUICKSTART.md replaced with pointer to operator manual (#7, #13)
- README.md rewritten as repo index — no longer re-explains TSC (#12, #16)
- Axis terminology standardized to "pattern / relational / process" across all docs (#14)
- ARCHITECTURE.md repo map now includes `docs/` and `archive/` (#15)
- Bottleneck rule removed from operator manual — geometric mean suffices (#10)
- SELF-MEASURE.md moved from doctrine bundle to engine bundle (#20)
- SELF-COHERENCE.md formula corrected to geometric mean notation (#18)
- Broken link in engine bundle README fixed (#19)
- Citation version updated to v0.1.1 (#8)

### Archived
- `runtime/tsc-instructions.md` → `archive/tsc-instructions.md` (#9)

---

## 0.1.1 (2026-04-01)

### Fixed
- `tsc_engine.opam` committed so opam discovers deps and installs dune (#4)
- `Ezcurl.post` called with `~params:[]` and `~content:(`String ...)` (#5)

### Changed
- Changelog rewritten as coherence ledger

---

## 0.1.0 (2026-04-01)

OCaml engine replaces Python reference. Theory (spec/) is stable and predates the engine.

### Added
- **Engine** (`engine/ocaml/`): provider transport (ezcurl), target registry, prompt assembly, structured report parsing, CLI entry point
- **Targets** (`targets/`): declarative `.tsc` definitions for spec, engine, and repo coherence
- **CI**: OCaml 5.2 build + linkcheck (`.github/workflows/ci.yml`)
- **Self-measurement**: runs all targets when `TSC_ENABLED=true` (`.github/workflows/tsc.yml`)
- **Docs** (`docs/alpha/engine/0.1.0/`): design, plan, self-coherence report

### Changed
- Python archived to `archive/python-reference/`
- README, ARCHITECTURE, QUICKSTART rewritten
- `project.tsc` superseded by `targets/registry.tsc`

### Known issues
- CI broken at tag time: missing `.opam` + ezcurl API mismatch (fixed in 0.1.1)
- Self-measurement untested end-to-end (requires secrets)
