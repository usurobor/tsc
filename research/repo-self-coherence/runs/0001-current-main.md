# Run 0001 — current main

```text
run:            0001
commit:         1c752a8664d6d49a4dd9be6a885a9ab64d72e54d  (main)
cm_version:     0.1
reader_profile: technical; understands repositories; unfamiliar with TSC; no TSC vocabulary
date:           recorded by the run's author; not machine-stamped
```

## α — manifestation

**Live surface observed:** root governance files (`README.md`, `STATUS.md`,
`ARCHITECTURE.md`, `QUICKSTART.md`, `CONTRIBUTING.md`, `SECURITY.md`,
`CODE_OF_CONDUCT.md`), `spec/**`, `conformance/**`, `src/**`, `research/**`,
`docs/{README,THESIS}.md`, `docs/{concepts,architecture,design}/**`,
`katas/*/README.md`, `schemas/`, `targets/`.

**Excluded (with reason):** `.cdd .cn-sigma .cell .tsc heldout` (vendored / agent
state / generated / test data); `docs/alpha docs/beta docs/gamma` (declared
frozen release snapshots); `katas/*/input` (negative-control corpora); `_build`
(build output).

**Note on an exclusion that is itself a finding:** the live docs portal routes
readers *into* the excluded `docs/{alpha,beta,gamma}` trees. Excluding them from
mechanical link-checking does not make them non-live to a newcomer following the
portal. Recorded under `REPO-STRUCTURE-001`.

**Inventory completeness:** complete for the declared live surface. No
inaccessible surface. Observation is not `INCOMPLETE_OBSERVATION`.

## β — relational / authority atlas

```text
README ──▶ STATUS              agree on version/ratification/standing (post-cleanup)
README ──▶ docs/README (portal)
docs/README ──▶ "follow beta/governance/DOCUMENTATION-SYSTEM.md"   ← names α/β/γ system as governing
docs/architecture/decisions/repository-planes.md ──▶ "α/β/γ is NOT a filing taxonomy; reader-intent planes"
        ▲ CONTRADICTION: two documents claim incompatible authority over navigation
docs/README ──▶ docs/alpha/*, docs/beta/*, docs/gamma/*   ← routes into frozen trees
docs/alpha/engine/README.md ──▶ engine/ocaml/  ← stale (moved to src/engine/ocaml/)
spec/README ──▶ conformance IDs                 coherent
src/engine/ocaml/README ──▶ CONTRACT.md         coherent (proxy ≠ v4 boundary explicit)
```

The central defect is the README-portal / ADR authority conflict, and the
portal's routing into frozen trees that carry stale current-looking paths.

## γ — continuation

The content-level cleanup (runs of the prior cell) removed false claims, dead
links, and prose noise without changing meaning — a lawful continuation for the
files it classified live. But the information-architecture migration is
**half-complete**: the reader-intent planes exist *alongside* the α/β/γ system,
and both read as authoritative. A move that leaves the old entry points live has
not continued lawfully at the repository level.

## Findings

| id | requirement | sev | claim | evidence |
|---|---|---|---|---|
| F1 | `REPO-STRUCTURE-001` | P0 | Two documentation systems are both presented as authoritative. | `docs/README.md` names `beta/governance/DOCUMENTATION-SYSTEM.md` as governing; `docs/architecture/decisions/repository-planes.md` declares α/β/γ not a filing taxonomy. |
| F2 | `REPO-ENTRY-001` | P0 | The front door does not answer what-is / runs-today / built-now / next in one screen, and states no single identity. | `README.md` lists five surfaces without ranking; identity is implicit. |
| F3 | `REPO-DOC-001` | P0 | The designated plain-language intro is an expert abstract needing the glossary. | `docs/THESIS.md:3` opens on "warranted coherence claims over optional polar source expressions and typed generative systems." |
| F4 | `REPO-HISTORY-001` | P1 | Historical material is reachable as current. | `docs/design/0.5.0/` and `RELEASE.md` are unlabeled historical; `docs/alpha/engine/README.md` links the removed `engine/ocaml/` path. |
| F5 | `REPO-AUTH-001` | P0 | Navigation authority is contradicted across files. | (same surfaces as F1) |
| F6 | `REPO-NOISE-001` | P2 | The full status narrative repeats across ~7 files instead of one home + a short projection. | `README.md`, `STATUS.md`, `THESIS.md`, `QUICKSTART.md`, `ARCHITECTURE.md`, engine docs, operator manual. |
| F7 | `REPO-STRUCTURE-001` | P1 | Migration is half-done: reader-intent planes coexist with α/β/γ; `QUICKSTART.md` / `ARCHITECTURE.md` remain at root. | tree at `1c752a8`. |

Repair class for F1–F5, F7 is documentation restructuring; F6 is deduplication.
No `REPO-RUN-001`, `REPO-PATH-001` (live set), or `REPO-STATUS-001` failures — the
prior content cleanup cleared those.

## Newcomer-task results

| Q | result | note |
|---|---|---|
| Q1 what is TSC | FAIL | front-door line dense; THESIS needs glossary (F3) |
| Q2 which spec authoritative | PASS | STATUS: 4.0 ratified, 4.1 Draft, locatable |
| Q3 what runs today | PASS | coh 0.12 proxy, not v4 |
| Q4 what does coh implement | PASS | engine README explicit |
| Q5 active research | PARTIAL | STATUS names Ascent; `research/ascent/` has no index |
| Q6 what to read next | FAIL | "start here" routes to dense spec / portal into legacy |

Fixture: **FAIL** (Q1, Q6 fail; Q5 partial).

## Status matrix (lifecycle)

```text
specification        4.1.0 Draft            correctly labeled
last ratified spec   4.0.0 Normative        locatable (commit); tag pending (P2)
software / engine    0.12.0 proxy, not v4   correctly labeled
conformance standing none                   correctly labeled
historical designs   docs/design/0.5.0, RELEASE.md, docs/alpha/*   NOT labeled historical (F4)
```

## Overall

```text
status:        DEFECTS_FOUND
warrant scope: content-level coherence (truth, links, calibration, operability)
               is warranted within the declared live surface.
               Repository-level navigation and identity are NOT — the docs portal
               and the accepted plane contract disagree, and legacy trees remain
               live entry points.
axes:          Truth PASS · Operability PASS · Concision PARTIAL ·
               Comprehension FAIL · Navigation FAIL · Structure FAIL
failed ACs:    REPO-ENTRY-001, REPO-DOC-001, REPO-AUTH-001, REPO-STRUCTURE-001,
               REPO-HISTORY-001, REPO-NOISE-001
```

This run is a measurement, not a repair and not a conformance claim. A future
`COHERENT_WITHIN_DECLARED_SCOPE` result requires the downstream repair wave to
close these findings and an independent review (`REPO-REVIEW-001`) to verify
closure on a re-run.
