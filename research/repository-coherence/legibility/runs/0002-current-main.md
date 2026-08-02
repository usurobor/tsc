# Run 0002 — current main

```text
run:            0002
commit:         bb0d0958a2db7d9a0f9383e69850f6671320c9f1  (main)
cm_version:     0.1
reader_profile: technical; understands repositories; unfamiliar with TSC; no TSC vocabulary
date:           2026-07-31 (run author's date; not machine-stamped)
prior_run:      0001 @ 1c752a8 (DEFECTS_FOUND, F1–F7)
```

## α — manifestation

**Live surface observed:** root governance files (`README.md`, `STATUS.md`,
`ARCHITECTURE.md`, `QUICKSTART.md`, `CONTRIBUTING.md`, `SECURITY.md`,
`CODE_OF_CONDUCT.md`, `CHANGELOG.md`), `spec/**`, `conformance/**`, `src/**`,
`research/**`, `docs/{README,THESIS}.md`, `docs/{concepts,architecture,design,evidence}/**`,
`katas/*/README.md`, `schemas/`, `targets/`, `.github/workflows/**`.

**Excluded (with reason):** `.cdd .cn-sigma .cell .tsc heldout` (vendored /
agent state / generated / CM self-test data); `.claude/worktrees/**` (agent
worktree copies); `katas/*/input` (negative-control corpora); `_build`
(build output).

**docs/{alpha,beta,gamma} — a MIX, verified from code, not taken on faith.**
These trees are partly frozen historical version snapshots AND partly live
machine dependencies. Verified live consumers:

```text
targets/repo.tsc                     lists 17 docs/{alpha,beta,gamma} files as the
                                     `repo` self-measure observation surface
                                     (targets/repo.tsc:26–42); resolved by the coh
                                     binary via targets/registry.tsc:16 →
                                     targets/methodology.tsc:22, pinned in
                                     src/engine/ocaml/test/test_target_registry.ml:177.
docs/beta/governance/fixtures/       read at RUNTIME by the coh binary
  factorized-beta-controls.json      (src/engine/ocaml/bin/main.ml:731,759 —
                                     read_file, exit 2 on failure) and by wired
                                     dune tests (test/dune:42–48;
                                     test_factorized_beta_gate.ml:199…250,
                                     test_factorized_beta.ml:324).
docs/beta/governance/                the pre-registration that drives
  CONSISTENCY-FACTORIZATION-PREREG.md  .github/workflows/factorized-beta-measure.yml
                                     (workflow header rev-4 citation, line 3).
```

The remainder of the trees (e.g. `docs/alpha/engine/*/DESIGN.md`,
`docs/alpha/doctrine/3.2.0/SELF-COHERENCE.md`) are genuine frozen prior-cycle
snapshots. So "frozen" is true for most files and false for the governance
infrastructure under `docs/beta/governance/`.

**Reader-navigability of the frozen trees:** unlike run 0001, the live docs
portal no longer routes a newcomer *into* these trees. `docs/README.md:38`
demotes them to a labelled "note on history" (frozen, "not entry points for a
newcomer"). The only live-surface Markdown links pointing into the trees are in
`CHANGELOG.md:329–330`, and `CHANGELOG.md` is itself excluded from the CI
linkcheck (`.github/workflows/ci.yml:86`). No reader-navigable live document
links into the excluded trees.

**Inventory completeness:** complete for the declared live surface. No
inaccessible surface. Observation is not `INCOMPLETE_OBSERVATION`.

## β — relational / authority atlas

```text
README ──▶ STATUS              agree on version/ratification/standing
                               (README.md:9–16 ↔ STATUS.md:3–8)
README ──▶ docs/README (portal)                       one system, reader-intent
docs/README ──▶ repository-planes ADR   "α/β/γ is TSC's measurement and role
                               grammar — never a filing taxonomy" (docs/README.md:3)
repository-planes.md ──▶ same statement (repository-planes.md:39–40)
        ▲ AGREE — the run 0001 README-portal / ADR authority conflict is gone.
docs/README ──▶ THESIS, QUICKSTART, spec/README, research/ascent/README,
               architecture/decisions/, concepts/illustrations/README, CONTRIBUTING
               — all resolve.
docs/README "note on history" ──▶ docs/{alpha,beta,gamma}   backtick mentions,
               NOT links; framed frozen / non-entry (docs/README.md:37–38)
spec/README ──▶ conformance IDs / layer authority          coherent
STATUS ──▶ spec/README, conformance obligations, research/ascent   coherent
src/engine/ocaml/README ──▶ CONTRACT.md, STATUS            coherent (proxy ≠ v4 explicit)
RELEASE.md (root)  ──▶  DELETED; rehomed docs/evidence/releases/0.12.0.md
               with a "Historical" banner naming CHANGELOG + STATUS as the
               authorities (docs/evidence/releases/0.12.0.md:3–7)
```

Every README, STATUS, QUICKSTART, docs/README, THESIS, spec/README, and
research/ascent link was resolved against the filesystem: all resolve. No two
live documents claim incompatible navigation, identity, or status authority.

## γ — continuation

Between 0001 (`1c752a8`) and HEAD (`bb0d095`) two repair cells landed and both
continued lawfully at the reader level:

- **Cell 1 (front door).** Single identity now stated (`README.md:3`);
  plain-language THESIS first screen (`docs/THESIS.md:3–16`) with the expert
  abstract relocated to a labelled "The formal account" section
  (`docs/THESIS.md:19–` onward); the `docs/README` portal is one reader-intent
  system that no longer routes into α/β/γ; `research/ascent/README.md` now exists
  as the program index.
- **Cell 2 (history / status).** `docs/design/0.5.0/` deleted; root `RELEASE.md`
  rehomed to `docs/evidence/releases/0.12.0.md` behind a historical banner; the
  status narrative single-homed to `STATUS.md` with short projections + pointers
  elsewhere.

The information-architecture migration that run 0001 called "half-complete" has
had its **authority half** closed — α/β/γ is demoted to declared-frozen and the
two-systems contradiction is gone. Its **physical half** (root `QUICKSTART.md`,
`ARCHITECTURE.md`; `targets/`, `katas/` not folded) remains, but is now openly
declared "Accepted · partial migration in progress" with each item recorded as
deferred, not a silent loose end (`repository-planes.md:1,83–101`). For the
declared reader, every "start here" link resolves and every role reads
correctly, so the repository reads as one lawful, navigable, operable whole at
HEAD within that scope.

## Findings

| id | requirement | sev | claim | evidence |
|---|---|---|---|---|
| N1 | `REPO-STRUCTURE-001` / `REPO-HISTORY-001` | P2 | The blanket "frozen snapshots" label over `docs/{alpha,beta,gamma}` over-generalizes: `docs/beta/governance/` holds LIVE machine dependencies read at runtime, not frozen history. Not reader-facing. | `docs/README.md:38` ("frozen … how the project once filed its documents") and `.github/workflows/ci.yml:65` both label the trees uniformly frozen, yet `fixtures/factorized-beta-controls.json` is read by `src/engine/ocaml/bin/main.ml:731,759` + tests, and `CONSISTENCY-FACTORIZATION-PREREG.md` drives `.github/workflows/factorized-beta-measure.yml:3`. |
| R7 | `REPO-STRUCTURE-001` | P2 | Residual of F7: root `QUICKSTART.md` / `ARCHITECTURE.md` are not yet in the declared `docs/` reader-intent planes (`docs/quickstart/` absent). Declared in-progress, links resolve, not reader-facing. | `ls docs/quickstart` → absent; `repository-planes.md:1` status "partial migration in progress"; deferrals at `repository-planes.md:83–101`. |

No `REPO-ENTRY-001`, `REPO-DOC-001`, `REPO-AUTH-001`, `REPO-STATUS-001`,
`REPO-PATH-001`, `REPO-RUN-001`, or `REPO-NOISE-001` failure on the live reader
surface. N1 and R7 are minor, non-reader-facing residuals recorded for
full-tree completeness; neither blocks the declared reader.

## Closure of run 0001 findings F1–F7

| prior | status | evidence |
|---|---|---|
| F1 `REPO-STRUCTURE-001` — two doc systems both authoritative | **CLOSED** | `docs/README.md:3,38` no longer names `beta/governance/DOCUMENTATION-SYSTEM.md` as governing; it cites the repository-planes ADR and states "α/β/γ … never a filing taxonomy," matching `repository-planes.md:39–40`. |
| F2 `REPO-ENTRY-001` — front door lacks single identity / one-screen answer | **CLOSED** | `README.md:3` states one identity; `README.md:9–40` gives what-is / runs-today / built-now / next in one screen (status table, "Start here", run section). |
| F3 `REPO-DOC-001` — intro is an expert abstract needing the glossary | **CLOSED** | `docs/THESIS.md:3` now opens on a plain-language question; the "warranted coherence claims over optional polar source expressions…" line is moved under §"The formal account" (`docs/THESIS.md:19–24`). |
| F4 `REPO-HISTORY-001` — historical material reachable as current | **CLOSED** | `docs/design/0.5.0/` deleted (absent on disk); root `RELEASE.md` deleted and rehomed to `docs/evidence/releases/0.12.0.md` with a "Historical" banner (`:3–7`). The `docs/alpha/engine/README.md → engine/ocaml/` stale path now lives only inside the declared-frozen, linkcheck-excluded tree and is not a reader entry point. |
| F5 `REPO-AUTH-001` — navigation authority contradicted | **CLOSED** | Twin of F1; no live document contradicts the portal/ADR navigation authority (`docs/README.md:3` ↔ `repository-planes.md:39–40`). |
| F6 `REPO-NOISE-001` — status narrative repeated across ~7 files | **CLOSED** | Single home `STATUS.md`; others carry a short projection + pointer (`README.md:16`, `docs/THESIS.md:83–87`, `QUICKSTART.md:5`). A prior duplicate, the operator manual, now sits in the frozen `docs/beta/guides/`. Matches the CM target "one home + a short projection." |
| F7 `REPO-STRUCTURE-001` — migration half-done | **PARTIAL** | Authority half CLOSED (α/β/γ demoted to frozen; two-systems contradiction gone). Physical half OPEN but declared: root `QUICKSTART.md`/`ARCHITECTURE.md` remain, `docs/quickstart/` absent; `repository-planes.md:1` labels itself "partial migration in progress" with deferrals recorded (`:83–101`). Tracked as residual R7. |

**New findings not in 0001:** N1 (imprecise "frozen" label over a mixed tree —
`docs/beta/governance/` holds live machine deps). R7 is the surviving tail of
F7, not a new class.

## Newcomer-task results

| Q | result | answer reached (≤1 hop) · authority check |
|---|---|---|
| Q1 what is TSC | **PASS** | README first screen (`README.md:3–5`): a framework for deciding whether observations come from one lawful process, returning a proof-carrying receipt not a score. 1 hop to `docs/THESIS.md:3–16` confirms in plain language; no glossary needed for basic identity; uncontradicted. |
| Q2 which spec authoritative | **PASS** | README + 1 hop to `STATUS.md:3–8`: 4.0.0 Normative is the last ratified / current normative warrant; 4.1.0 Draft is the in-progress spec in `spec/`. `spec/README.md:1–8,75` agrees (Draft binding until the ratification gate). (Reading the ratified 4.0.0 text itself needs commit `4da1122`, but *which* spec is authoritative is answerable without it.) |
| Q3 what runs today | **PASS** | README run section (`README.md:29–40`) + 1 hop `QUICKSTART.md`: `coh` 0.12.0 repository proxy (v3.2-era), mechanical/llm/hybrid/auto, katas — explicitly not v4. Authority `QUICKSTART.md` agrees. (Fixture also names `docs/quickstart/`, absent, but the README section + `QUICKSTART.md` suffice.) |
| Q4 what does coh implement | **PASS** | 1 hop `src/engine/ocaml/README.md:1–5` + `CONTRACT.md:1–8`: the v3.2-era repository-proxy scoring/witness contract; explicitly NOT TSC v4 Core/Operational/Conformance. Uncontradicted. |
| Q5 active research | **PASS** | README ("Current research: Articulation Ascent") + 1 hop `research/ascent/README.md` (now exists — the 0001 PARTIAL was "no index"); `STATUS.md:51–53` names it the primary program. Uncontradicted. |
| Q6 what to read/run next | **PASS** | README "Start here" table (`README.md:18–27`): all six destinations resolve and each is now a lawful entry (THESIS plain-language, portal single-system, ascent indexed). No routing into dense abstract or legacy trees. |

Fixture: **PASS** (6/6). Run 0001 was FAIL (Q1, Q6 fail; Q5 partial); Q1 and Q6
now pass on the front-door repair, Q5 on the new `research/ascent/README.md`.

## Status matrix (lifecycle)

```text
specification        4.1.0 Draft            correctly labeled (README.md:11, spec/README.md:4)
last ratified spec   4.0.0 Normative        locatable via commit 4da1122 (STATUS.md:5)
software / engine    0.12.0 proxy, not v4   correctly labeled (VERSION; STATUS.md:3; CONTRACT.md:2)
conformance standing none                   correctly labeled (STATUS.md:6)
historical designs   docs/evidence/releases/0.12.0.md   NOW banner-labeled historical (:3–7)
frozen doc snapshots docs/{alpha,gamma}, most of docs/beta   declared frozen, non-entry (docs/README.md:37–38)
live infra in frozen docs/beta/governance/{fixtures,PREREG}   LIVE, mislabeled frozen (N1)
```

## Judgement — CI linkcheck exclusion of docs/{alpha,beta,gamma}

**Correct scoping, not a genuine smell** — with one adjacent labelling nit (N1).
The linkcheck (`.github/workflows/ci.yml:73–88`) is an offline Markdown
link-integrity gate over the reader-navigable surface. Excluding the α/β/γ trees
is sound because: (a) it checks only Markdown navigation links, and the live
machine dependencies inside those trees are JSON (`factorized-beta-controls.json`)
and a prereg cited by a workflow — neither is a Markdown navigation target the
linkcheck could protect; (b) no live-checked Markdown file links into the
excluded trees (the only inbound links are in `CHANGELOG.md:329–330`, itself
excluded); (c) the integrity of the live dependencies is guarded by their real
consumers — the coh binary's `read_file … exit 2` (`main.ml:731,759`), the wired
dune tests, and the workflow reference — not by the linkcheck, which was never
responsible for them. So the exclusion drops no coverage a newcomer or a build
relies on. The genuine (minor) defect is not the exclusion but the *label*: both
the CI comment (`ci.yml:65`) and `docs/README.md:38` call the trees uniformly
"frozen," which is false for `docs/beta/governance/`. Recorded as N1, P2.

## Overall

```text
status:        COHERENT_WITHIN_DECLARED_SCOPE
warrant scope: reader-facing coherence for the declared newcomer profile —
               identity, authority, runnability, experimental standing, and
               next-steps are reconstructible from the front door + ≤1 hop with
               no contradictory status, no stale live-surface path, and no
               reader-facing mixed artifact role. The newcomer fixture passes
               6/6 and every run-0001 finding F1–F6 is closed; F7's authority
               core is closed.
NOT warranted: full-tree structural completeness. Two minor, non-reader-facing
               residuals remain — R7 (physical migration tail: root
               QUICKSTART.md / ARCHITECTURE.md not yet in docs/ planes, openly
               declared in-progress) and N1 (docs/beta/governance/ live infra
               labelled "frozen"). Both P2; neither blocks the declared reader.
axes:          Truth PASS · Concision PASS · Comprehension PASS ·
               Navigation PASS · Structure PARTIAL (R7, N1 — declared /
               non-reader-facing) · Operability PASS
failed ACs:    none within the declared reader scope.
               REPO-STRUCTURE-001 is PARTIAL at the full-tree level (R7, N1),
               not failed at the reader level.
newcomer:      PASS (6/6)
```

Per `REPO-REVIEW-001`, this `COHERENT_WITHIN_DECLARED_SCOPE` result is a
measurer's finding and is **provisional pending an independent full-scope
review** separate from the repair actor. This run is a measurement, not a
repair and not a conformance claim; it edited no repository file except this
receipt.
