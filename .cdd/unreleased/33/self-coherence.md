---
cycle: 33
issue: "#33"
branch: "cycle/33"
mode: "design-and-build"
disconnect: "§2.5b docs-only — unless engine version-bump rides on the kata runner integration (decision deferred to β at release prep)"
date: "2026-05-11"
dispatch_configuration: "§5.2 single-session δ-as-γ via Claude Code Agent tool (per the in-flight proposal at .cdd/iterations/proposals/cnos-cdd-claude-code-dispatch/). γ axis grade capped at A− per the §3.8 amendment in that proposal."
---

# Self-Coherence — Cycle #33

## Gap

Tsc has no canonical kata progression. Two cellular-automata example files (`examples/cellular-automata/{glider,random-soup}.md`) survived cycle #26's Drop decisions and remain at repo root, but the Python harness that exercised them (`tests/conformance/test_*.py`) was retired; the raw inputs are pedagogical orphans. The engine (`engine/ocaml/bin/main.ml`, three scoring modes since cycle #25) is exercised only by project-internal `targets/*.tsc` corpora — no curated input/expected-output pairs and no progression for new engine implementors. Issue #33 closes this gap with a structured kata framework (`katas/` directory + `kata.toml` schema + runner integration + tests + docs) and the first two katas (kata-01 positive control, kata-02 negative control) as Phase 1 proof of concept.

## Mode

`design-and-build`. The `kata.toml` schema is a design surface (manifest shape + field semantics + how `expected.*` interacts with engine output), and the kata-runner integration + per-kata directories + tests + docs are build work. Mode-declaration is consistent with `cdd/issue/SKILL.md` MCA preconditions: no separate design/plan artifact is committed at a stable path; design lives in this self-coherence document, in `katas/README.md`, and in the eventual α implementation. Not MCA.

## Cycle scope sizing (per cnos #334 heuristic)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | One new OCaml module likely (`kata.ml` to parse manifests) + one new CLI flag + one new test file; small | no |
| (b) Cross-module breadth | `katas/` tree (new), `engine/ocaml/bin/main.ml`, `engine/ocaml/lib/kata.ml` (new), `engine/ocaml/test/test_kata.ml` (new), top-level docs (README/QUICKSTART/ARCHITECTURE) — 5+ files but tightly cohering as one feature | moderate |
| (c) Lifecycle span | design (schema) → build (5 katas: 2 here, 3 deferred) → docs; Phase 1 keeps span tight | low |
| (d) MCA preconditions | not MCA — design lives in this issue + α self-coherence | n/a |
| (e) Independent shippability | **Phase 1 vs Phase 2 already split per issue body**. AC8 forces a Phase 2 follow-on issue. Phase 1 alone ships independently as proof-of-concept (framework + kata-01 + kata-02). | YES (already executed at issue-creation time) |

**Decision:** **Keep Phase 1 whole** — at-edge AC count (8 ACs) with explicit γ-justification per cnos #334 cycle-scope-sizing.

**Justification:** The Phase 1 unit (framework + 2 katas + runner + test + docs + Phase 2 filing) is internally coherent — splitting further would fragment the proof-of-concept (e.g., "framework alone, then kata-01 alone, then kata-02 alone" creates three half-shipped pieces and forces three γ-scaffold passes for one feature). Issue #33's own scoping (Path A in its sizing table) recommended this exact split: Phase 2 (kata-03 comparative, kata-04 philosophical, kata-05 adversarial) goes to a follow-on issue (AC8). The eight Phase 1 ACs all support one observable outcome: `coh --kata 01-glider` and `coh --kata 02-random-soup` work end-to-end.

**At-edge acknowledgment:** AC count is 8 (upper edge of typical). β should pay particular attention to whether any sub-deliverable could ship independently with no side effects (signal it as a Phase 2 split candidate) and whether `expected.score_range` justifications are defensible per the active design constraint in #33.

## Active Skills

**Tier 1a (always loaded):**
- `cdd/CDD.md` (post-#331/#333/#334/#335 patches; §1.6c dispatch sizing, §3.8 honest-grading, §5.3a Artifact Location Matrix)
- `cdd/SKILL.md`
- `cdd/gamma/SKILL.md` (γ role; this dispatch is single-session δ-as-γ via Agent tool)

**Tier 1b (lifecycle phase skills):**
- `cdd/issue/SKILL.md` (cycle scope sizing; mode declaration; MCA preconditions)
- `cdd/alpha/SKILL.md` (dispatch prompt source for α)
- `cdd/beta/SKILL.md` (dispatch prompt source for β; voice rule on close-outs)
- `cdd/review/SKILL.md` (verdict rules — §3.3 no approved-with-followup; rule 3.13 honest-claim verification)
- `cdd/release/SKILL.md` (§2.5b docs-only disconnect; §3.8 honest-grading rubric)
- `cdd/post-release/SKILL.md` (Step 5.6b cdd-iteration.md)
- `cdd/operator/SKILL.md` (§4 override; if β R2 is verified by γ instead of dispatched fresh)

**Tier 2 (engineering bundle, for α dispatch):**
- `cnos.eng/skills/eng/ocaml` (runner integration, kata.ml module, test extension)
- `cnos.eng/skills/eng/writing` (kata READMEs + framework docs)

**Tier 3 (issue-specific, for α dispatch):**
- `cnos.core/skills/skill` (kata.toml schema discipline — frontmatter analogue; schema field type + example documentation)

## Impact graph

```
katas/                                  new top-level directory
katas/README.md                         framework intro + schema docs + ordering convention + runner-invocation form
katas/01-glider/kata.toml               positive control (expected pass; high C_Σ)
katas/01-glider/README.md               kata intent + how to run
katas/01-glider/input/glider.md         from examples/cellular-automata/glider.md
katas/02-random-soup/kata.toml          negative control (expected fail; low C_Σ)
katas/02-random-soup/README.md          kata intent + how to run
katas/02-random-soup/input/random-soup.md   from examples/cellular-automata/random-soup.md
engine/ocaml/lib/kata.ml                NEW — manifest parser + runner (modeled on target_registry.ml)
engine/ocaml/lib/dune                   wire new module
engine/ocaml/bin/main.ml                add --kata <id> flag; route to kata.ml runner
engine/ocaml/test/test_kata.ml          NEW — hermetic tests for kata-01 + kata-02
engine/ocaml/test/dune                  wire new test
README.md                               link katas/README.md
QUICKSTART.md                           mention `coh --kata <id>` as smoke-test entrypoint
ARCHITECTURE.md                         describe kata-vs-target separation
examples/cellular-automata/{glider,random-soup}.md   α decides: keep, move, or symlink (peer enumeration concern)

GitHub-side (AC8):
  Phase 2 issue                         filed via mcp__github__issue_write; references back to #33
```

## Acceptance Criteria (Phase 1)

Lifted verbatim from issue #33 §"Acceptance criteria (Phase 1)". β verifies each against the diff.

### AC1: `katas/` directory + framework README
**Oracle:** `test -d katas/ && test -f katas/README.md && grep -E "coh --kata|kata\.toml" katas/README.md`
**Surface:** `katas/`, `katas/README.md`

### AC2: `kata.toml` schema defined and documented
**Oracle:** `grep -cE "^- \`[a-z_.]+\`" katas/{README,SCHEMA}.md` returns ≥10 (covers all named fields: id, difficulty, prerequisites, tests, expected.verdict, expected.score_range, expected.bottleneck_axis, mode, input.files, description; each with type + example)
**Surface:** `katas/README.md` (or `katas/SCHEMA.md`)

### AC3: kata-01 (glider, positive control) ships
**Oracle:** `coh --kata 01-glider --mode mechanical` exits 0; output JSON `result.c_sigma >= kata.expected.score_range.min` AND `result.verdict == kata.expected.verdict`. Hermetic — no LLM call.
**Surface:** `katas/01-glider/`, `engine/ocaml/bin/main.ml`

### AC4: kata-02 (random-soup, negative control) ships
**Oracle:** `coh --kata 02-random-soup --mode mechanical` exits 0; `result.c_sigma <= kata.expected.score_range.max` AND `result.verdict == "fail"` (kata succeeds by correctly identifying incoherence)
**Surface:** `katas/02-random-soup/`, `engine/ocaml/bin/main.ml`

### AC5: `--kata <id>` flag wired into `engine/ocaml/bin/main.ml`
**Oracle:** `coh --help | grep -E "\-\-kata"` matches; `coh --kata bogus-id` exits non-zero with clear error naming the missing kata; `coh --kata 01-glider` exits 0
**Surface:** `engine/ocaml/bin/main.ml`, `engine/ocaml/lib/kata.ml` (new)

### AC6: OCaml test exercises both katas
**Oracle:** `cd engine/ocaml && dune runtest` exits 0; test output mentions `kata` test cases; ≥2 new test cases beyond the existing baseline
**Surface:** `engine/ocaml/test/test_kata.ml` (or extension)

### AC7: Docs surface the framework
**Oracle:** `grep -lE "kata" README.md QUICKSTART.md ARCHITECTURE.md` returns 3; ARCHITECTURE.md distinguishes katas (pedagogical/regression in `katas/`) from targets (project-internal in `targets/`)
**Surface:** `README.md`, `QUICKSTART.md`, `ARCHITECTURE.md`

### AC8: Phase 2 follow-on issue filed
**Oracle:** A second tsc issue exists at close-out time naming Phase 2 scope (kata-03 comparative, kata-04 philosophical, kata-05 adversarial) with explicit references back to #33's framework decisions
**Surface:** GitHub issues (file via mcp__github__issue_write before γ close-out)

## Self-check

- All 8 ACs are independently testable (test / grep / file-existence / GitHub API).
- Mode = `design-and-build` (justified above).
- Cycle scope at-edge (8 ACs) — γ keep-whole justification stated; β to scrutinize per #334 heuristic.
- Active design constraints (issue #33): no Python revival; hermetic Phase 1; hand-curated kata.toml; defensible `expected.score_range`; kata-vs-target separation; TOML for input, JSON for runner output.
- Active skills declared above; Tier 3 limited to `cnos.core/skills/skill` for schema discipline.
- Disconnect path: §2.5b docs-only (default for cycles with no version bump). If β at release prep decides the runner integration warrants v0.7.0 → v0.8.0 minor bump, RELEASE.md + CHANGELOG row ride with the same commit (issue body suggests this as an option; γ leaves the call to β).
- Existing example inputs at `examples/cellular-automata/{glider,random-soup}.md` are recoverable as-is; no re-authoring needed. α should peer-enumerate the originals: move-or-copy decision, with the originals either deleted (removed in favor of kata) or left as historical pointers.

## Known Debt (carries-forward into this cycle's body)

- **§5.2 single-session δ-as-γ dispatch configuration in effect** (per the in-flight proposal at `.cdd/iterations/proposals/cnos-cdd-claude-code-dispatch/` — branch `proposals/cnos-cdd-claude-code-dispatch` on origin). γ-axis grade is capped at A− per the proposed §3.8 amendment. Cycle #32 ran under the same configuration; this cycle reproduces it explicitly to gather more telemetry.
- **Harness push restrictions on existing branches** (cycle #32 F4 cdd-iteration finding): updates to `cycle/33` after the initial push will fail with HTTP 403. Fresh-branch naming pattern (`cycle/33-impl`, `cycle/33-impl-r2`, `cycle/33-merged`, `cycle/33-final`) is the established workaround. Disposition is `no-patch` (environmental); cycle #32's F4 already captured this. If observed again here, increment the N-count in the cdd-iteration finding for telemetry.
- **β R1 verdict-rule contradiction risk** (cycle #32 F3): β has been observed (1 prior occurrence) returning "APPROVED with C-severity findings" — which `cdd/review/SKILL.md` §3.3 unambiguously forbids. γ to watch for this in this cycle's β R1; if it recurs (N=2), the cdd-iteration finding strengthens.
- **#28 Claude CLI provider (P3 deferred)**: not in this cycle; stays as named debt.
- **#30 release.sh CHANGELOG gate, #31 dotenv tests**: not in this cycle.

## CDD Trace

| Step | Artifact | Skills loaded | Decision |
|------|----------|---------------|----------|
| 0 Observe | issue #33 body, cycle #32 close-out + cdd-iteration, dispatch proposal branch | cdd, cdd/issue, cdd/gamma | observation inputs read; selected #33 per CDD §3.3 (issue was already filed, scope explicit, P2). |
| 1 Select | issue #33 | cdd | selected #33 (P2, explicit scope, single open assessment-commitment candidate); decisive clause CDD §3.3 (assessment commitment default applied to filed issue). |
| 2 Branch | `cycle/33` from `origin/main` (ec4152b) | cdd | branch created per CDD §4.2; pre-flight passed per §4.3 (origin/cycle/33 absent; no stalled .cdd/unreleased/33/ on main). |
| 3 Bootstrap | `.cdd/unreleased/33/self-coherence.md` (this file) | cdd, cdd/issue | scaffold present. |
| 4 Gap | this §Gap | — | named kata framework gap from #33 with concrete sub-deliverables (framework + 2 katas + runner + test + docs + Phase 2 filing). |
| 5 Mode | this §Mode | cdd/issue | `design-and-build`; cycle-scope at-edge keep-whole with γ-justification per #334 heuristic. |
| 6 Implement | α dispatched via Agent tool (2026-05-12); branch is `cycle/33` (rebased onto origin/main, 12-commit Cycle C changes incorporated); all ACs implemented in single session | cdd/alpha, cnos.eng/ocaml, cnos.eng/writing, cnos.core/skill | See per-AC trace below. |
| 7 Self-coherence | α updated this file | cdd/alpha | Review-readiness signal below. |
| 7a Pre-review gate | `dune runtest` passes; both katas pass `--kata` flag; all AC oracles pass; Phase 2 issue filed | cdd/alpha | Green. |

## AC Implementation Trace

| AC | Surface | Status | Evidence |
|----|---------|--------|----------|
| AC1 | `katas/`, `katas/README.md` | SATISFIED (Cycle C) | `test -d katas/ && test -f katas/README.md` passes; README names `coh --kata` and `kata.toml` |
| AC2 | `katas/README.md` | SATISFIED | `grep -cE "^- \`[a-z_.]" katas/README.md` = 10; all 10 fields documented with type + example |
| AC3 | `katas/01-glider/`, runner | SATISFIED | `coh --kata 01-glider --mode mechanical` exits 0; C_Σ=0.923 ≥ 0.87 (min); verdict=pass |
| AC4 | `katas/02-random-soup/`, runner | SATISFIED | `coh --kata 02-random-soup --mode mechanical` exits 0; C_Σ=0.689 ≤ 0.74 (max); verdict=fail |
| AC5 | `engine/ocaml/bin/main.ml`, `lib/kata.ml` | SATISFIED | `coh --help` lists `--kata`; bogus-id exits 1 with clear error; kata-01 exits 0 |
| AC6 | `engine/ocaml/test/test_kata.ml` | SATISFIED | `dune runtest` exits 0; kata-01 loaded OK, kata-02 loaded OK, missing-kata error OK |
| AC7 | README.md, QUICKSTART.md, ARCHITECTURE.md | SATISFIED | All 3 docs mention kata framework + link `katas/README.md`; ARCHITECTURE.md §Katas distinguishes katas from targets |
| AC8 | GitHub issues | SATISFIED | Issue #35 filed: "Engine katas: Phase 2 — comparative + philosophical + adversarial katas" |

## Score range justifications (defensible per active design constraint)

**Kata-01 (glider, positive control):**
- Actual measured C_Σ: **0.923** (mechanical mode, 2026-05-12)
- α=1.000: all 14 heading phrases consistent; H1 present; no naming drift
- β=0.985: no broken links (no internal links — clean); one authority claim (score 0.95)
- γ=0.785: no version strings (score 0.7 per default); no traceability markers (score 0.5)
- score_range: [0.87, 1.0] (min = actual − 0.05 tolerance)
- Bottleneck: gamma (version/traceability absences are expected for kata inputs)

**Kata-02 (random-soup, negative control):**
- Actual measured C_Σ: **0.689** (mechanical mode, 2026-05-12)
- α=0.943: heading case drift (3 variants of "random SOUP Properties")
- β=0.435: 18/18 internal links unresolved (all link targets are fictional)
- γ=0.689: 14 version occurrences, 9 unique (version drift penalizes)
- score_range: [0.0, 0.74] (max = actual + 0.05 tolerance)
- Bottleneck: beta (broken link rate drives the penalty)
- Discriminability gap: 0.923 − 0.689 = **0.234** (exceeds recommended 0.20 minimum)

## Self-check (α perspective)

- AC1/AC2: confirmed as Cycle C deliverables; noted in trace.
- AC3/AC4: katas created; score ranges calibrated against actual engine output.
- AC5: `--kata` flag wired; help text present; error cases handled; exits 0/1 correctly.
- AC6: `test_kata.ml` uses `TSC_ROOT` env var with candidate-path fallback; `dune runtest` passes.
- AC7: all 3 docs updated; ARCHITECTURE.md §Katas vs Targets table added.
- AC8: Phase 2 issue #35 filed before this signal.
- `otoml` dependency: added to `dune-project` and `lib/dune`; otoml 1.0.5 installed.
- No Python code introduced. No LLM calls in kata runner. Hermetic.
- Branch `cycle/33` rebased onto `origin/main` (incorporates Cycle C's 12 commits).

## Review-readiness signal

| Field | Value (Round 1) | Value (Round 2 — post fix-round) |
|---|---|---|
| Base SHA | ec83b9b (origin/main at α rebase time, post Cycle C) | TBD |
| Head SHA | TBD (filled after final push) | TBD |
| Branch CI state | `dune runtest` passes locally; CI will confirm | TBD |
| Ready for β | YES — all 8 ACs satisfied | TBD |
