# Run 0003 — current main

A fresh, independent measurement under **Legibility Coherence CM v0.2**, emitting
the parent's Generic child receipt envelope ([`../../CM.md`](../../CM.md)). Prior
runs 0001 (`@1c752a8`) and 0002 (`@bb0d095`) are format precedent only; this run
does not reuse them — the repository has changed since (front-door files moved
into `docs/`, the CM system restructured to the envelope).

## Receipt envelope

```text
aspect_id:            legibility
cm_version:           0.2
profile:              technical-newcomer-human
repository_commit:    48b9a635c59ec6ba00dd80ee7a48d1160d1e0656   (main HEAD)
result_class:         PASS
status:               COHERENT_WITHIN_DECLARED_SCOPE
date:                 2026-08-02 (run author's date; not machine-stamped)
prior_run:            0002 @ bb0d095 (COHERENT_WITHIN_DECLARED_SCOPE; residuals N1, R7)
mapping:              COHERENT_WITHIN_DECLARED_SCOPE → PASS (this CM's declared map)
```

**scope.** Declared reader: technically experienced, understands software
repositories, unfamiliar with TSC, no TSC vocabulary. Live-surface policy: the
reader-navigable front door and everything reachable from it in ≤1 documented
hop, plus the authority sources the fixture checks against. Excluded (with
reason): `.cdd .cn-sigma .cell .tsc heldout` (vendored / agent state / generated
/ CM self-test data); `.claude/worktrees/**` (agent worktree copies);
`docs/{alpha,beta,gamma}` (declared frozen prior-cycle snapshots — except
`docs/beta/governance/`, a live machine input, see α); `katas/*/input` (negative-
control corpora); `_build` (build output).

## α — manifestation

**Commit observed:** `48b9a635c59ec6ba00dd80ee7a48d1160d1e0656`, verified equal
to `origin/main` at measurement time.

**Live surface observed:** root governance files (`README.md`, `STATUS.md`,
`CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CHANGELOG.md`,
`VERSION`); `docs/{README,THESIS}.md`, `docs/quickstart/README.md`,
`docs/architecture/{README.md,decisions/repository-planes.md}`,
`docs/concepts/illustrations/README.md`, `docs/evidence/**`, `docs/design/**`;
`spec/**`, `conformance/**`, `src/engine/ocaml/{README,CONTRACT}.md` and
`lib/**`/`bin/**`, `research/**`, `targets/`, `schemas/`, `scripts/`,
`.github/workflows/**`.

**Front-door migration since 0002 — verified on disk.** Root `QUICKSTART.md` and
`ARCHITECTURE.md` no longer exist; `docs/quickstart/README.md` and
`docs/architecture/README.md` now exist and are the front door's targets
(`README.md:23`, `docs/README.md:10`). This closes run 0002's R7 (the "physical
migration tail"). No live-surface Markdown link points at the removed root paths
(the sole tree-wide match is inside a *frozen* structure-CM run receipt,
`research/repository-coherence/structure/runs/0001-current-main.md:277`, a
historical record — not a live navigation link).

**`docs/beta/governance/` — a live input inside an otherwise-frozen tree,
verified not taken on faith.** As in 0002, the α/β/γ snapshot trees are mostly
frozen prior-cycle history but `docs/beta/governance/` is a live machine
dependency the engine and CI still consume. Unlike 0002, this fact is now
*declared on both surfaces that previously mislabelled it uniformly "frozen"*:
`docs/README.md:38` states "One exception is `docs/beta/governance/`, which is
not frozen history but a live input the engine and CI still consume," and the CI
comment `.github/workflows/ci.yml:66–69` names "the live `docs/beta/governance/`
machine-dependency JSON … not [protected] by linkcheck." This closes run 0002's
N1 (the imprecise blanket "frozen" label) on both surfaces.

**Inventory completeness:** complete for the declared live surface; no
inaccessible reader-navigable surface. Not `INCOMPLETE_OBSERVATION`.

**Unobserved check (honestly bounded, see `refusals`):** the *exit codes* of the
documented `coh` / `run-katas.sh` commands were not executed — this measurement
environment has no opam build or network. All referenced binaries, scripts,
targets, and the install path exist and are internally path-consistent
(`install.sh`, `scripts/run-katas.sh`, `targets/{registry,methodology}.tsc`,
`src/engine/ocaml/lib/{coherence,mechanical_scoring,factorized_beta}.ml`,
`bin/main.ml` all present), but the operability-by-execution surface was not run
here. Prior runs 0001/0002 likewise did not execute it; recorded as a bounded
refusal, not a whole-run incompleteness.

## β — relational / authority atlas

```text
README ──▶ STATUS            AGREE on version / ratification / standing
                             (README.md:9–16 ↔ STATUS.md:3–6; VERSION = 0.12.0)
README ──▶ docs/README (portal)                     one reader-intent system
docs/README ──▶ repository-planes ADR   "α/β/γ is TSC's measurement and role
                             grammar — never a filing taxonomy" (docs/README.md:3
                             ↔ repository-planes.md §Decision / §4)
docs/README ──▶ THESIS, quickstart/README, ../spec/README,
                ../research/ascent/README, architecture/decisions/,
                concepts/illustrations/README, ../CONTRIBUTING   — all resolve.
docs/README "authority by question" ──▶ ../src/engine/ocaml/CONTRACT.md,
                ../STATUS.md, ../spec/tsc-conformance.md          — all resolve.
docs/README "note on history" ──▶ docs/{alpha,beta,gamma}   backtick mentions,
                NOT links; framed frozen / non-entry, with the governance
                exception named (docs/README.md:36–38)
spec/README ──▶ conformance IDs / four-layer authority                coherent
STATUS ──▶ spec/README, conformance obligations, research/ascent      coherent
src/engine/ocaml/README ──▶ CONTRACT.md, STATUS   coherent (proxy ≠ v4 explicit)
docs/architecture/README ──▶ STATUS (../../STATUS.md)                 resolves
```

Every Markdown link on the checked front-door set (README, STATUS, docs/README,
THESIS, docs/quickstart, docs/architecture, spec/README, research/ascent/README,
engine README + CONTRACT, conformance/README, CONTRIBUTING, repository-planes
ADR — 13 files) was resolved against the filesystem: **all resolve** (`REPO-PATH-001`).
No two live documents claim incompatible identity, navigation, or status
authority (`REPO-AUTH-001`).

**Implementation claim vs code (`REPO-STATUS-001` semantic face).** The
front-door claim "`coh` … a v3.2-era repository proxy, **not** TSC v4"
(`README.md:13,31`) is confirmed by the engine's own authority:
`src/engine/ocaml/README.md:1–5` ("It is **not** an implementation of TSC v4"),
`CONTRACT.md:1–9` ("Semantic line: TSC specification 3.2.2 …; TSC v4
conformance: none"), and `STATUS.md:20–22`. The module list in
`src/engine/ocaml/README.md:20–33` names files that exist on disk (spot-checked
`coherence.ml`, `mechanical_scoring.ml`, `factorized_beta.ml`, `bin/main.ml`).
`docs/architecture/README.md:54–73` states the same engine boundary. Consistent.

## γ — continuation

Between 0002 (`bb0d095`) and HEAD (`48b9a63`) the repository continued lawfully
at the reader level; both residuals 0002 recorded are now closed:

- **R7 (physical migration tail) → CLOSED.** Root `QUICKSTART.md` /
  `ARCHITECTURE.md` moved into the declared `docs/` reader-intent planes
  (`docs/quickstart/README.md`, `docs/architecture/README.md` now present; roots
  absent). The front door and portal route to the new paths and every link
  resolves; no stale live-surface path to the old roots.
- **N1 (imprecise "frozen" label over a mixed tree) → CLOSED.** Both surfaces
  that formerly labelled `docs/{alpha,beta,gamma}` uniformly frozen now carve out
  the live `docs/beta/governance/` exception: `docs/README.md:38` and
  `.github/workflows/ci.yml:66–69`.

The information-architecture migration whose *authority half* 0002 closed and
whose *physical half* 0002 left "declared in-progress" has now had that physical
half advanced for the front door specifically. The ADR remains honestly
self-labelled "Accepted · v1.1 · partial migration in progress"
(`repository-planes.md:3`) with the still-deferred moves (`targets/` fold,
`katas/` to a tests plane, the `docs/design/` bundle rehome) recorded as
deferred, not silent (`repository-planes.md:130–148`). Those are **structure-
aspect** concerns, explicitly assigned away from legibility by the ADR itself:
§4 rules that "names-predict-content … is a **legibility** value … Structure
ratifies only 'docs file by reader intent,' the closed docs taxonomy (§1)"
(`repository-planes.md:98–105`); the `docs/design/` misplacement is declared a
structure defect-to-rehome in §1 (`repository-planes.md:74–79`). For the declared
reader, every "start here" link resolves and every role reads correctly, so the
repository reads as one lawful, navigable, operable whole at HEAD within scope.

## Findings

**No in-scope legibility defect at the declared reader profile.** The full
`REPO-*` set was checked; each passes on the live reader surface:

| requirement | verdict | evidence |
|---|---|---|
| `REPO-ENTRY-001` | PASS | `README.md:3–5` states one identity; `README.md:9–40` answers what-is / authoritative / runnable / experimental / next in one screen (status table, "Start here", run section). |
| `REPO-DOC-001` | PASS | `docs/THESIS.md:3–16` opens plain-language; the "warranted coherence claims over optional polar source expressions…" abstract is relocated under §"The formal account" (`docs/THESIS.md:19–24`). Each front-door doc states purpose + authority immediately. |
| `REPO-AUTH-001` | PASS | Single authoritative home per fact; `README.md:16` cedes status detail to `STATUS.md`; portal↔ADR agree on navigation (`docs/README.md:3` ↔ `repository-planes.md:98–105`). No incompatible authority. |
| `REPO-STATUS-001` | PASS | `README.md:9–16` ↔ `STATUS.md:3–6` ↔ `VERSION`(0.12.0) ↔ `CONTRACT.md:1–9`: spec 4.1.0 Draft, last ratified 4.0.0 Normative, engine 0.12.0 non-v4, 4.1 standing none — all agree. |
| `REPO-PATH-001` | PASS | All Markdown links on the 13-file front-door set resolve (mechanical check). No stale link to the moved root `QUICKSTART.md`/`ARCHITECTURE.md`. |
| `REPO-STRUCTURE-001` | PASS (reader scope) | Portal presents one reader-intent system (`docs/README.md:3`); α/β/γ demoted to declared-frozen non-entry with the governance exception named (`:36–38`). Residual plane-placement debt (`docs/design/`, `targets/`, `katas/`) is declared and assigned to the **structure** aspect (`repository-planes.md:74–79,98–105`), not reader-facing. |
| `REPO-HISTORY-001` | PASS | Frozen snapshots labelled non-entry (`docs/README.md:36–38`); historical release banner-labelled (`docs/evidence/releases/`); ADR self-labelled "partial migration in progress" (`repository-planes.md:3`). No historical material reads as current instruction to the reader. |
| `REPO-RUN-001` | PASS (structural) / see refusal | Documented commands are path-consistent; referenced binary/scripts/targets all exist. Live exit codes not executed here (no opam/network) — recorded as a bounded refusal, per 0001/0002 precedent. |
| `REPO-NOISE-001` | PASS | Status narrative single-homed to `STATUS.md`; other files carry a short projection + pointer (`README.md:16`, `docs/THESIS.md:83–87`, `docs/quickstart/README.md:5`, `docs/architecture/README.md:56`). No obsolete navigation on the front door. |

`REPO-REPAIR-001` / `REPO-REVIEW-001` are process requirements; this is a
measurement, so they are not scored here beyond the standing note below.

## Refusals

```text
id:      RUN-EXEC-01
type:    INCOMPLETE_OBSERVATION (bounded, single check)
surface: operability-by-execution — exit codes of the documented `coh` and
         `scripts/run-katas.sh` commands
reason:  no opam build / no network in this measurement environment. Referenced
         binary, scripts, targets, and install path all exist and are path-
         consistent, but their runtime exit codes were not observed. Prior runs
         0001/0002 also did not execute them. Bounds one check, not the inventory;
         does not flip the categorical status.
```

## Unobserved surfaces

```text
docs/{alpha,gamma} + most of docs/beta   declared frozen prior-cycle snapshots;
                                         not reader-navigable entry points; read
                                         only enough to confirm non-entry framing.
docs/beta/governance/ runtime behavior   confirmed as a declared live machine
                                         input (α); its engine/CI consumption not
                                         re-executed here.
coh / kata command exit codes            see refusal RUN-EXEC-01.
```

## Newcomer-task results (blind fixture, run FIRST from `README.md` only)

The six `fixtures/newcomer-tasks.md` questions, each answered in ≤1 documented
hop from the front door, then checked against its authority source:

| Q | result | answer reached (≤1 hop) · authority check |
|---|---|---|
| Q1 what is TSC | **PASS** | `README.md:3–5`: a framework for deciding whether several observations are explained by one lawful process, returning a proof-carrying receipt (not a score). 1 hop `docs/THESIS.md:3–16` confirms in plain language; no glossary needed for identity; uncontradicted. |
| Q2 which spec authoritative | **PASS** | 1 hop `STATUS.md:3–8`: 4.0.0 Normative is the last ratified / current normative warrant; 4.1.0 Draft is the in-progress spec in `spec/`. `spec/README.md:1–8,75` agrees (Draft binding until the ratification gate). (Reading the ratified 4.0.0 *text* needs commit `4da1122`, but *which* spec is authoritative is answerable without it.) |
| Q3 what runs today | **PASS** | `README.md:29–40` + 1 hop `docs/quickstart/README.md:1–5`: `coh` 0.12.0 repository proxy (v3.2-era), modes mechanical/llm/hybrid/auto, katas — explicitly not v4, no v4 receipt. Authority agrees. |
| Q4 what does `coh` implement | **PASS** | Answer is at the front door (`README.md:13,31`) and confirmed 1 hop `STATUS.md:20–22`: the v3.2-era repository-proxy scoring/witness contract; explicitly NOT TSC v4 Core/Operational/Conformance. The deeper engine authority (`src/engine/ocaml/README.md:1–5`, `CONTRACT.md:1–9`) is 2 hops via the portal's "Authority by question" row, but the identity answer needs no such hop. Uncontradicted. |
| Q5 active research | **PASS** | `README.md:9–16` ("Current research: Articulation Ascent") + 1 hop `research/ascent/README.md:1–9`; `STATUS.md:51–53` names it the primary program for the current bounded sprint. Uncontradicted. |
| Q6 what to read/run next | **PASS** | `README.md:18–27` "Start here" table: all six destinations resolve and each is a lawful entry (plain-language THESIS, single-system portal, indexed ascent, quickstart, spec, contributing). No routing into a dense abstract or a legacy tree. |

Fixture: **PASS (6/6).** No question needed Git history or the glossary for basic
identity, and none was contradicted by another live document.

## Status matrix (lifecycle)

```text
specification         4.1.0 Draft             correctly labeled (README.md:11, spec/README.md:2–4)
last ratified spec    4.0.0 Normative         locatable via commit 4da1122 (STATUS.md:5)
software / engine     0.12.0 proxy, not v4    correctly labeled (VERSION; STATUS.md:3; CONTRACT.md:2)
conformance standing  none                    correctly labeled (STATUS.md:6)
front-door pages      docs/quickstart/, docs/architecture/   moved from root; portal-linked (README.md:23; docs/README.md:10)
historical release    docs/evidence/releases/ banner-labeled historical
frozen doc snapshots  docs/{alpha,gamma}, most of docs/beta  declared frozen, non-entry (docs/README.md:36–38)
live infra in frozen  docs/beta/governance/   declared LIVE on both surfaces (docs/README.md:38; ci.yml:66–69) — 0002 N1 closed
plane migration       partial migration in progress   ADR self-labeled; residuals assigned to structure aspect (repository-planes.md:3,74–79,98–105)
```

## Overall

```text
result_class:  PASS
status:        COHERENT_WITHIN_DECLARED_SCOPE
warrant scope: reader-facing coherence for the declared newcomer profile —
               identity, authority, runnability description, experimental
               standing, and next-steps are reconstructible from the front door
               + ≤1 hop with no contradictory status, no stale live-surface path,
               and no reader-facing mixed artifact role. Newcomer fixture PASS
               6/6. Run 0002's two residuals (R7 physical migration tail, N1
               "frozen" mislabel) are both CLOSED.
NOT warranted: full-tree structural completeness (owned by the structure aspect):
               the still-deferred plane moves (docs/design/ rehome, targets/,
               katas/) and the closed docs taxonomy are structure-aspect matters,
               declared in the ADR and out of this aspect's scope by §4.
               And operability-by-execution (coh/kata exit codes) — not run here
               (refusal RUN-EXEC-01).
newcomer:      PASS (6/6)
```

Per `REPO-REVIEW-001`, this `COHERENT_WITHIN_DECLARED_SCOPE` result is a
measurer's finding and is **provisional pending an independent full-scope review**
separate from any repair actor.

This run is a **measurement only**. It edited exactly one repository file — this
receipt — and touched no other file, including the frozen runs 0001/0002 and the
`results/`. On a fixed commit it is reproducible, and it is **immutable once
written**.
