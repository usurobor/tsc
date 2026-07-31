# Repo Newcomer-Coherence CM

A declared methodology that measures whether the `tsc` repository is coherent
to a first-time technical reader. It exists because the shipped `self-measure`
CM scores the v3.2 structural proxy (terminology, cross-reference, version
surface) and is blind to comprehension, navigation, and information-architecture
identity — the axes a newcomer actually hits.

This is dogfood: TSC warrants coherence claims through declared methodologies;
the repo's own coherence should be one such claim, not an opinion.

## Governing question

Can a fresh technical reader (SWE / CS / AI, zero prior TSC exposure) — and an
AI agent — determine what TSC is, what runs today, what is being built, and
where to go next, without hitting a false claim, a dead end, or two contradictory
systems?

## Viewpoint (what is observed)

The front door and the filesystem, in the order a newcomer meets them:
`README.md` → `STATUS.md` → `docs/README.md` → `docs/THESIS.md` → `spec/README.md`
→ the visible directory tree → the links and indexes between them. Frozen/hidden
planes (`.cdd .cn-sigma .cell .tsc heldout docs/{alpha,beta,gamma}`) are observed
only for whether the live surface *routes into* them.

## Axes and oracle

Each axis scores PASS / PARTIAL / FAIL against checkable signals.

### A — Truth (calibration)
Every present-tense claim is true and no stronger than its evidence.
- 0 broken live relative links; every referenced path resolves.
- 0 fabricated subsystems (a documented thing that does not exist).
- 0 cross-file contradictions; version / license / status agree across files.
- No claim of conformance/normativity the tree does not carry.
FAIL if any broken live link or fabricated/ contradicted claim exists.

### B — Concision (signal/noise, write skill @ L7)
- Nothing removable without loss; no duplicated stable fact (one home each);
  one governing question per file; no throat-clearing or decorative contrast.
FAIL if a stable fact is narrated in full in >1 file, or a file carries two jobs.

### C — Comprehension (newcomer)
- `README.md` answers, in one screen: what TSC is · what runs today · what is
  being built · where to go next.
- `docs/THESIS.md`'s first screen is understandable with no glossary and no
  undefined symbols (C≡, α/β/γ, CM, V, δ introduced only after a plain account).
- The repo states ONE identity, not an unranked list of five surfaces.
- 5-minute test: a fresh reader can answer — what does TSC claim? what does coh
  implement? what is Articulation Ascent? which spec is ratified? where is the
  current experiment? what next?
FAIL if the designated intro needs the glossary, or identity is ambiguous.

### D — Navigation (information architecture)
- No authority conflict: the accepted ADR (reader-intent planes; "α/β/γ is not
  a filing taxonomy") and the live `docs/README.md` agree.
- `docs/README.md` carries a cnos-style "I want to…" table.
- 0 live-surface links into `docs/alpha` `docs/beta` `docs/gamma`.
- Every visible docs and research *program* directory has an index README.
FAIL if the portal names the α/β/γ system as governing, or routes into it.

### E — Structure (migration finished)
- `docs/alpha` `docs/beta` `docs/gamma` are absent from `main`.
- Historical designs are labeled/rehomed, not presented as current plans.
- Linkcheck needs no legacy-tree exclusions (their absence, not their exclusion,
  is the fix).
- Predictable, exclusive ownership per plane (no two systems side by side).
FAIL if the legacy taxonomy is still present on `main`, or linkcheck must
exclude it.

## Scoring

Overall band = the worst axis:
- **PRISTINE** — all five PASS.
- **GOOD** — A,B PASS; at most one of C,D,E PARTIAL.
- **REVISE** — any core axis FAIL.
- **POOR** — A FAIL (untrue) or ≥3 axes FAIL.

"Scored high" (the cleaning-loop exit) = **PRISTINE**: all five axes PASS,
equivalently all ten acceptance criteria met.

## Acceptance criteria (the review's ten, mapped to axes)

1. README one-screen four-answers — **C**
2. THESIS understandable without the glossary — **C**
3. docs/README "I want to…" table — **D**
4. No live navigation into docs/alpha│beta│gamma — **D**
5. Those directories absent from main — **E**
6. Every program directory has an index — **D**
7. Historical designs not presented as live — **E**
8. STATUS is the single detailed status authority — **A/B**
9. Linkcheck needs no legacy-tree exclusions — **E**
10. Five-minute comprehension test passes — **C**

## Refusal

The CM refuses to score (records INDETERMINATE, not a pass) when: the project
identity cannot be read from the front door at all; or a claimed authority
document (ADR, spec index) is missing. Refusal is a finding, not a zero.

## Receipt

Per run: per-axis PASS/PARTIAL/FAIL with file:line evidence, the overall band,
and the failing acceptance-criterion numbers. A receipt on a fixed commit is
reproducible — the signals are checkable, not judgments of taste.

## Relationship to shipped CMs and graduation

`self-measure` (proxy) covers part of axis A; this CM extends measurement to
C/D/E, which the proxy cannot see. If this CM proves durable across cleaning
rounds it should graduate from the cell to a first-class methodology (a
`src/skills/` declaration or a `docs/reference/` entry) and, ideally, gain a
mechanical oracle so it can run in CI rather than by review.
