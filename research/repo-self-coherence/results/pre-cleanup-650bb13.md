# Receipt — Repo Newcomer-Coherence CM · commit `650bb13`

**Target:** `650bb13` (PRE-cleanup baseline) · *refactor(docs): move illustrations/ under docs/concepts/*
**CM:** `.cell/cleanup/CM.md` (Repo Newcomer-Coherence CM)
**Method:** worktree materialized at `650bb13`; every relative link resolved against that commit's tree; subsystem claims checked against `git ls-tree`; `coh` command form checked against `src/engine/ocaml/bin/main.ml` at this commit.

## Overall band: **POOR**

Axis A FAILs (untrue front door) and all five axes FAIL. The worst-axis rule and the "A FAIL or ≥3 axes FAIL" clause both land POOR.

| Axis | Verdict |
|---|---|
| A — Truth | **FAIL** |
| B — Concision | **FAIL** |
| C — Comprehension | **FAIL** |
| D — Navigation | **FAIL** |
| E — Structure | **FAIL** |

---

## A — Truth — **FAIL**

**44 broken live relative links** (kata negative-test fixtures under `katas/02-random-soup/input/` and `katas/03-comparative/input/` excluded as deliberate incoherent input). Representative:

- `src/skills/self-measure/SKILL.md` — ~26 links of the form `../../src/engine/ocaml/lib/coherence.ml`; from `src/skills/self-measure/` the `../../` prefix resolves to `src/`, so the target becomes `src/src/engine/...` — the off-by-one introduced by the `engine/`→`src/engine/`, `skills/`→`src/skills/` move.
- `src/skills/cm-of-cms/SKILL.md` — 14 links, same double-`src/` defect (e.g. `../../src/engine/ocaml/CONTRACT.md`, `../../targets/registry.tsc`, `../../scripts/cm-consistency.sh`).
- `src/engine/ocaml/README.md` and `src/engine/ocaml/CONTRACT.md` — `../../spec/tsc-conformance.md` resolves to `src/spec/tsc-conformance.md` (double-depth), broken.
- `CHANGELOG.md` — `engine/ocaml/CONTRACT.md` (pre-move path, now `src/engine/ocaml/CONTRACT.md`).
- `katas/04-philosophical/README.md` — `../../examples/philosophical/consciousness.md` into the nonexistent `examples/` tree.

**Fabricated subsystems.** `git ls-tree` at `650bb13` has no `src/engine/ocaml/lib/parsers/`, no `examples/`, no `tests/ocaml/`. Yet:
- `CONTRIBUTING.md:149-171` "Adding a New Parser" instructs creating a module "under `src/engine/ocaml/lib/parsers/`", "Add example: `examples/your_format/`", "Add test: `tests/ocaml/conformance/`" — three nonexistent paths; also linked from the TOC at `CONTRIBUTING.md:13`.
- `.github/pull_request_template.md:62-74` "For New Parsers" checklist repeats `src/engine/ocaml/lib/parsers/`, `examples/`, `tests/ocaml/conformance/`.
- `src/engine/ocaml/lib/` contains no `parsers` module or `parse`/`is_*` dispatch — the parser-plugin model is fiction.

**Fabricated `SECURITY.md`.** `SECURITY.md:7-11` claims a supported-versions table `2.1.x ✓ / 2.0.x ✓ / < 2.0 ✗` for a project whose `VERSION` is `0.12.0`; the 2.x release line does not exist. Contact `SECURITY.md:19` is `usurobor@gmail.com`.

**Cross-file license contradiction.** `LICENSE` is CC BY 4.0 (single). `CONTRIBUTING.md:178-184` asserts a three-way triad — "Code (`engine/`, `tests/`): Apache-2.0", "Specifications (`spec/`): CC BY 4.0", "Examples (`examples/`): CC0" — inventing Apache-2.0 code and CC0 examples the repository does not carry.

**Broken headline command.** `README.md:46` = `coh --mode mechanical --files spec/ --output .tsc/`. In `src/engine/ocaml/bin/main.ml:90-94`, `expand_glob` treats a pattern with no `*` as a literal path: `--files spec/` returns `["spec/"]`, a directory handed to the engine as if a single file — it expands to no spec content. The functional form (`src/engine/ocaml/bin/main.ml:15`, `--files <glob>`) requires a glob such as `spec/**/*.md`.

**README/STATUS normativity disagreement.** `STATUS.md:5,8,10` assert TSC **4.0.0 Normative** is the current ratified normative warrant infrastructure. `README.md` never names a ratified contract; `README.md:33,63` speak only of "the normative specification" and the 4.1 Draft headers, so the front door read alone implies nothing is ratified — inconsistent with STATUS on the version/normativity axis.

FAIL: broken live links and fabricated/contradicted claims are both present.

## B — Concision — **FAIL**

- **Two-job files.** `CONTRIBUTING.md` carries contribution guidance **and** a fabricated parser tutorial (`:149-171`) **and** an invented license taxonomy (`:178-184`). `SECURITY.md` (88 lines) carries a real reporting policy plus a fabricated support matrix and boilerplate "Best Practices" bulk.
- **Throat-clearing / decorative prose.** `CONTRIBUTING.md:3` "Thanks for your interest in contributing!"; `CONTRIBUTING.md:192` "Thank you for contributing to TSC!"; `STATUS.md:71-73` closing boilerplate ("This priority declaration changes neither the normative status…"); `docs/THESIS.md:19` decorative contrast ("They are not three independent views and are not freely permutable axes").
- **Duplicated stable fact.** The v3.2-proxy / v4-spec surface boundary is narrated in full in `README.md:55,61`, `STATUS.md:18-30`, and `docs/README.md:27-29`; the `CUTOVER-RECEIPT.md` disposition is narrated in both `README.md:37` and `STATUS.md:44-48`.

FAIL: a stable fact is narrated in full in more than one file, and files carry two jobs.

## C — Comprehension — **FAIL**

- `docs/THESIS.md:15-17` introduces α/β/γ ("manifestation", "relational atlas", "joint realization candidates", "globalize", "continuation") on the first screen with no prior plain account; `docs/THESIS.md:3` opens on undefined "polar source expressions" and "typed generative systems". The designated intro needs a glossary.
- Identity is a split, not one statement: `README.md:5-8` presents "two different surfaces" (spec 4.1.0 Draft + `coh` 0.12.0); the repository map (`README.md:14-23`) lists eight rows without a single ranked identity.
- 5-minute test fails: **Articulation Ascent is unreachable from the front door** — `README.md` has no `research/` row and never names the program; a newcomer can only find it in `STATUS.md:57-73`.

FAIL: the designated intro needs the glossary and identity is ambiguous.

## D — Navigation — **FAIL**

- **Authority conflict.** The accepted ADR `docs/architecture/decisions/repository-planes.md:39-40` states "α/β/γ is measurement and role grammar — never a filing taxonomy." The live portal `docs/README.md:5` states "The documentation tree follows the system in `beta/governance/DOCUMENTATION-SYSTEM.md`" — naming the α/β/γ system as the governing filing taxonomy.
- **Live routing into frozen planes.** `docs/README.md:21-23` links `alpha/doctrine/`, `alpha/engine/`, `beta/guides/`; `docs/README.md:5` links `beta/governance/DOCUMENTATION-SYSTEM.md`. All four targets exist under `docs/alpha` / `docs/beta` — four live-surface links into the frozen taxonomy.
- **Missing program indexes.** `docs/concepts/` (only `illustrations/`), `docs/architecture/` (only `decisions/`), and `research/ascent/` have no index `README.md`.

FAIL: the portal names the α/β/γ system as governing and routes into it.

## E — Structure — **FAIL**

- `docs/alpha`, `docs/beta`, `docs/gamma` are **present** at this commit.
- Historical designs presented without a superseded/historical label: `docs/design/0.5.0/DESIGN.md` and `docs/design/0.5.0/PLAN.md` (v0.5.0) sit beside current design bundles; `RELEASE.md` (0.12.0) sits at the root as present-tense release copy.
- Linkcheck is not a working gate here (per the later `#108` reconstruction the job checked only depth ≤ 2, honored no exclusions, and stayed green over dozens of broken links) — the legacy taxonomy is present regardless.

FAIL: the legacy taxonomy is still present on the tree.

---

## Failed acceptance criteria

**1, 2, 4, 5, 6, 7, 8, 9, 10** fail. Criterion **3** (docs/README intent table) is met only in spirit — `docs/README.md:9-15` is a "Current authority" question→source table, not intent-phrased. Effectively all ten are unmet.
