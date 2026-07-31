# Receipt — Repo Newcomer-Coherence CM · commit `1c752a8`

**Target:** `1c752a8` (current `main`) · *ci(linkcheck): recurse all depths, exclude non-live surfaces, fail on broken links (#108)*
**CM:** `.cell/cleanup/CM.md` (Repo Newcomer-Coherence CM)
**Method:** worktree materialized at `1c752a8`; every relative link resolved against that commit's tree; subsystem claims checked against `git ls-tree`; `coh` command form checked against `src/engine/ocaml/bin/main.ml`; linkcheck exclusions read from `.github/workflows/ci.yml`.

## Overall band: **POOR**

Axes A and B PASS. Axes C, D, E all FAIL. Three axes FAIL, so the "≥3 axes FAIL" clause lands POOR; by the worst-axis rule the band is at best REVISE. The truth and concision recovery is real (A,B FAIL→PASS since `650bb13`), but the information-architecture axes are unchanged.

| Axis | Verdict |
|---|---|
| A — Truth | **PASS** |
| B — Concision | **PASS** |
| C — Comprehension | **FAIL** |
| D — Navigation | **FAIL** |
| E — Structure | **FAIL** |

---

## A — Truth — **PASS**

- **0 broken live relative links.** The only unresolved links in the tree are the deliberate incoherent-input fixtures under `katas/02-random-soup/input/` and `katas/03-comparative/input/` (engine negative-test data), which `.github/workflows/ci.yml:80-81` excludes as non-live. Every live-surface link resolves — the ~44 off-by-one `src/`-move links are all fixed (`src/skills/self-measure/SKILL.md`, `src/skills/cm-of-cms/SKILL.md`, `src/engine/ocaml/README.md`, `CHANGELOG.md`).
- **No fabricated subsystems.** The parser-plugin fiction is gone: `CONTRIBUTING.md` no longer references `src/engine/ocaml/lib/parsers/`, `examples/`, or `tests/ocaml/`; `.github/pull_request_template.md` "For New Parsers" section removed.
- **License consistent.** `CONTRIBUTING.md:146` now states a single "CC BY 4.0" matching `LICENSE`; the Apache-2.0/CC0 triad is deleted.
- **`SECURITY.md` truthful.** `SECURITY.md:13-14` "TSC is pre-1.0 software. Security fixes target the latest release and `main`" replaces the fabricated 2.x support matrix; contact is `peter@lisovin.com`.
- **Command works.** `README.md:49` = `coh --mode mechanical --files 'spec/**/*.md' --output .tsc/`; the glob is expanded by `src/engine/ocaml/bin/main.ml:95-134`.
- **Normativity reconciled.** `README.md:68` now names "the last **ratified** Normative contract is TSC **4.0.0**" and `STATUS.md:5` carries the readable-at-`4da1122` reference — README and STATUS agree.

PASS: no broken live link, no fabricated subsystem, no cross-file contradiction.

## B — Concision — **PASS**

- Throat-clearing cut: `CONTRIBUTING.md:3` now "This guide explains how to propose changes to TSC." (the "Thanks for your interest…"/"Thank you for contributing!" bookends are gone); `STATUS.md` program-priority boilerplate (`650bb13:71-73`) removed; `docs/THESIS.md:19` decorative contrast removed.
- `SECURITY.md` reduced to reporting policy + scope note; the fabricated matrix and "Best Practices" bulk are gone.
- Residual, non-failing: the v3.2/v4 surface boundary still appears in `README.md:58`, `STATUS.md`, and `docs/README.md:27-29`, but STATUS carries the detailed authority and README/`docs/README` only cross-reference it — no full re-narration of a stable fact, no two-job file.

PASS.

## C — Comprehension — **FAIL**

- **The designated intro needs the glossary.** `README.md:5` itself instructs: "Start with `docs/THESIS.md` … and keep the [glossary] open for unfamiliar terms" — a stated dependency. `docs/THESIS.md:3` still opens on undefined "polar source expressions" and "typed generative systems"; `docs/THESIS.md:15-17` still introduces α/β/γ ("manifestation", "relational atlas", "joint realization candidates", "globalize") on the first screen with no prior plain account. THESIS is essentially unchanged from `650bb13` (one decorative sentence removed).
- **Identity still split.** `README.md:7-10` presents "two surfaces" (spec 4.1.0 Draft + `coh` 0.12.0); the repository map (`README.md:16-26`) is now nine rows. The one-sentence headline exists (`README.md:3`) but is immediately partitioned into competing surfaces — not one ranked identity.
- README is closer to a landing page (a "New to TSC?" pointer and a `research/` row were added), but the four-answers-in-one-screen test is undercut by the explicit glossary dependency.

FAIL: the designated intro needs the glossary (CM Axis-C FAIL clause fires directly).

## D — Navigation — **FAIL**

`docs/README.md` is **byte-identical** to `650bb13`.

- **Authority conflict persists.** The accepted ADR `docs/architecture/decisions/repository-planes.md:39-40` says "α/β/γ is measurement and role grammar — never a filing taxonomy"; `docs/README.md:5` still says "The documentation tree follows the system in `beta/governance/DOCUMENTATION-SYSTEM.md`" — the α/β/γ system named as the governing filing taxonomy.
- **Live routing into frozen planes persists.** `docs/README.md:21-23` link `alpha/doctrine/`, `alpha/engine/`, `beta/guides/`; `docs/README.md:5` links `beta/governance/DOCUMENTATION-SYSTEM.md` — four live links into `docs/alpha` / `docs/beta`, all resolving.
- **Missing program indexes.** `docs/concepts/` (only `illustrations/`), `docs/architecture/` (only `decisions/`), and `research/ascent/` (only `DECISIONS.md`, `traces/`) still lack an index `README.md`.

FAIL: the portal names the α/β/γ system as governing and routes into it.

## E — Structure — **FAIL**

- **`docs/alpha`, `docs/beta`, `docs/gamma` are still present on `main`.** `git ls-tree` at `1c752a8` lists all three under `docs/`.
- **Linkcheck must exclude the legacy trees.** `.github/workflows/ci.yml:83-85` carries `--exclude-path 'docs/alpha/'`, `'docs/beta/'`, `'docs/gamma/'`; the job comment (`ci.yml:65-67`) names them "frozen snapshots". The CM's E signal requires their *absence*, not their exclusion.
- **Half-migration is self-declared.** The ADR header `docs/architecture/decisions/repository-planes.md:3` reads "**Status:** Accepted · partial migration in progress"; its "Migration state" (`:60-101`) lists the foundation-contract-reconciliation bundle, the `docs/` reader-intent portal population, and remaining `src/` moves as deferred.
- **Historical designs still presented as current.** `docs/design/0.5.0/DESIGN.md` / `PLAN.md` (v0.5.0, headers `Version: 0.5.0`) sit unlabeled beside current design bundles; `RELEASE.md` (0.12.0) remains root-level present-tense release copy.

FAIL: the legacy taxonomy is still present on `main`, and linkcheck must exclude it.

---

## Failed acceptance criteria

**2, 4, 5, 6, 7, 9, 10** fail.
- 2 (THESIS without glossary) — FAIL, `README.md:5` + `docs/THESIS.md:3,15-17`.
- 4 (no live nav into docs/alpha│beta│gamma) — FAIL, `docs/README.md:5,21-23`.
- 5 (those dirs absent from main) — FAIL, present at `1c752a8`.
- 6 (every program dir has an index) — FAIL, `docs/concepts`, `docs/architecture`, `research/ascent`.
- 7 (historical designs not presented as live) — FAIL, `docs/design/0.5.0/`, `RELEASE.md`.
- 9 (linkcheck needs no legacy-tree exclusions) — FAIL, `ci.yml:83-85`.
- 10 (5-minute comprehension) — FAIL, THESIS glossary dependence + split identity.

Recovered since `650bb13`: **1** (README landing improved — "New to TSC?" pointer + `research/` row), **8** (STATUS/README normativity reconciled; STATUS is the single detailed status authority). Criterion **3** remains met-in-spirit (`docs/README.md:9-15` authority table, not intent-phrased).
