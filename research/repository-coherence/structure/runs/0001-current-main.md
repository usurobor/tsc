# Run 0001 — current main (structural)

```text
run:                0001
aspect:             structure
cm_version:         0.1
profile:            repository-planes-v1.1
repository_commit:  7514a21b62472c54a6bd3d67d16de28c92ff0cd2  (main)
policy_authority:   docs/architecture/decisions/repository-planes.md @ 7514a21 (v1.1, 2026-08-02)
date:               2026-08-02 (recorded by the run's author; not machine-stamped)
```

This is a **measurement, not a repair**. The CM observes, classifies, and emits
defects with warrant against `repository-planes-v1.1`; it moves, renames, and
deletes nothing. An independent full-scope **review** (`STRUCT-REVIEW-001`) and a
separate **repair wave** (`STRUCT-REPAIR-001`) follow this frozen receipt. Where
the ADR does not decide a path's home, the CM refuses rather than legislates
(`STRUCT-REFUSE-001`).

## Scope

```text
declared plane set:  spec/ · src/ · conformance/ · research/ · docs/ · scripts/
                     (the six ADR target planes), plus every root peer and root file.
excluded (do-not-touch, STRUCT-EXCLUDE-001):  .cdd/ · .cn-sigma/ · heldout/
excluded (build/agent/infra):                 _build (untracked dune output) ·
                     .cell/ · .tsc/ (agent state) · .github/ (CI infra) ·
                     .gitignore · .pre-commit-config.yaml
tracked files enumerated:  473 (git ls-files)
policy commit pinned:      7514a21 (ADR moves with the tree at this commit)
```

Inventory is **complete** for the declared surface; every tracked path was
enumerated by `git ls-files` and classified. No inaccessible surface. Observation
is not `INCOMPLETE_OBSERVATION`.

## α — manifestation (inventory + plane classification)

Top-level tracked areas (counts by `git ls-files | first path segment`):

```text
plane / area   files   resolved plane            verdict
------------------------------------------------------------------------
spec/            7      spec        (bind)        clean — canonical
src/            80      src         (run)         clean — engine + skills canonical
conformance/    12      conformance (prove)       clean — foundation-v4 canonical
research/       24      research    (still change) clean — incl. this CM + ascent
docs/           52      docs        (help person) MIXED — 3 of 6 subfolders defective
scripts/        24      scripts     (automate)    clean
------------------------------------------------------------------------ root peers
targets/         7      → src/engine (ADR Iter 3) DEFECT (STRUCT-PLANE-001, deferred)
katas/          19      → a tests plane (ADR)     DEFECT (STRUCT-PLANE-001, deferred)
schemas/        14      → co-located w/ owners     DEFECT (STRUCT-PLANE-001, deferred)
runtime/         1      → co-located w/ skill      DEFECT (STRUCT-PLANE-001 + FUNC-001)
------------------------------------------------------------------------ root files
QUICKSTART.md    1      → docs/quickstart          DEFECT (STRUCT-PLANE/RULE-001)
ARCHITECTURE.md  1      → docs/architecture        DEFECT (STRUCT-PLANE/RULE-001)
README STATUS CHANGELOG CONTRIBUTING SECURITY CODE_OF_CONDUCT LICENSE CITATION.cff
Makefile install.sh VERSION  → ADR silent          UNDERDETERMINED (convention)
------------------------------------------------------------------------ excluded
.cdd/ .cn-sigma/ heldout/    do-not-touch           excluded (STRUCT-EXCLUDE-001)
_build .cell/ .tsc/ .github/ build/agent/infra      excluded
```

**docs/ subfolder classification** against the closed reader-intent eight
(`quickstart · concepts · guides · reference · architecture · development ·
papers · evidence`, ADR v1.1 §1):

```text
docs/concepts/       ∈ eight     clean
docs/architecture/   ∈ eight     clean (decisions/repository-planes.md)
docs/evidence/       ∈ eight     clean (releases/0.12.0.md, labelled)
docs/alpha/          ∉ eight     DEFECT — α role grammar (STRUCT-NAME-001 + DOCSET-001)
docs/beta/           ∉ eight     DEFECT — β role grammar (STRUCT-NAME/DOCSET/CONSUMER/MIXED)
docs/gamma/          ∉ eight     DEFECT — γ role grammar (STRUCT-NAME-001 + DOCSET-001)
docs/design/         ∉ eight     DEFECT — closed-taxonomy (STRUCT-DOCSET-001); dest REFUSED
docs/README.md docs/THESIS.md    files, not subfolders — portal + intro, in place
```

**Inventory completeness:** complete for the declared surface. `_build/` is
untracked (`git ls-files | grep _build` → empty; `.gitignore:15
src/engine/ocaml/_build/`), confirming the derived-output exclusion signal.

## β — relational / consumer atlas

The load-bearing structural relation is the **consumer graph**: a placement
defect is only a coherent move-candidate if every live consumer is rehomed with
it (`STRUCT-CONSUMER-001`; ADR *Invariants* — "targets resolve; conformance
validator exits 0; no document's meaning changes"). Consumer sets below were
grepped over tracked code, CI, `scripts/`, tests, and markdown links, excluding
`_build/ .cdd/ .cell/ .tsc/ .claude/`.

```text
docs/beta/governance/fixtures/factorized-beta-controls.json  (move candidate)
  ├─ src/engine/ocaml/bin/main.ml:731,759          runtime CLI default path
  ├─ src/engine/ocaml/test/test_factorized_beta_gate.ml:199,210,224,250
  ├─ src/engine/ocaml/test/test_factorized_beta.ml:324
  ├─ src/engine/ocaml/lib/factorized_beta.ml:712    (doc comment)
  ├─ .github/workflows/factorized-beta-measure.yml:225,230  (coh …-prompt/-check)
  ├─ docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md:17,327,334  (links)
  └─ docs/evidence/releases/0.12.0.md:46            (evidence cross-ref)
     → a move is coherent only if ALL are rehomed. The near-miss the fixture
       encodes: treating docs/beta/governance/ as a deletable frozen tree breaks
       exactly these runtime/CI consumers.

docs/beta/governance/  (whole-folder move candidate — MORE than the fixture json)
  ├─ CONSISTENCY-FACTORIZATION-PREREG.md consumed as provenance string:
  │    src/engine/ocaml/lib/factorized_beta_gate.ml:242  (emitted in engine output)
  │    src/engine/ocaml/lib/factorized_beta.ml:4 · factorized_beta_gate.ml:4
  │    .github/workflows/factorized-beta-measure.yml:3 · scripts/factorized-beta-measure.sh:3
  ├─ METER-LOOP-DECISION.md → runtime/SELF-MEASURE.md:313
  ├─ CHANGELOG.md:61,78 · docs/evidence/releases/0.12.0.md:46
  └─ .github/workflows/ci.yml:67 names it a live machine-dependency exception to
       the frozen-tree linkcheck exclusion.

targets/  (ADR Iter 3: engine-owned → src/engine)
  ├─ src/engine/ocaml/bin/main.ml:87,356,373,500,546 · lib/types.ml:12,23
  ├─ src/engine/ocaml/test/{test_target_registry,test_consistency,test_factorized_beta*}.ml
  ├─ scripts/coherence-ledger.sh · cm-consistency.sh · factorized-beta-measure.sh · render-self-measure.sh
  └─ .github/workflows/{tsc-coherence-ledger,tsc-self-measure}.yml   (heavy — coh resolves targets at runtime)

katas/  (ADR: → a tests plane)
  └─ src/engine/ocaml/{lib/kata.ml,bin/main.ml,test/test_kata.ml} ·
     scripts/{run-katas.sh,cm-admissibility.sh} · .github/workflows/{ci,katas}.yml

schemas/  (ADR: → co-located with owners)
  └─ scripts/ci/{validate-skill-frontmatter,validate-v4-conformance}.sh ·
     scripts/render-self-measure.sh · .github/workflows/{ci,tsc-coherence-ledger,tsc-self-measure}.yml

runtime/SELF-MEASURE.md  (ADR: → co-located with its skill; also single-occupant plane)
  └─ ~55 references incl. src/engine/ocaml/{bin/main.ml:357,377,lib/*.ml} ·
     src/skills/{self-measure,cm-of-cms}/SKILL.md · scripts/render-self-measure.sh ·
     .github/workflows/tsc-{coherence-ledger,self-measure}.yml · QUICKSTART.md:25

QUICKSTART.md (root → docs/quickstart)   consumers: README.md:23,40 · docs/README.md:10,25
ARCHITECTURE.md (root → docs/architecture) consumers: src/skills/self-measure/SKILL.md:247
```

Every move-candidate carries live runtime/CI consumers. None is a
zero-reference safe move; each repair must be atomic path-fixup across the sets
above. The authority conflict the sibling legibility run once flagged (README
portal naming the α/β/γ `DOCUMENTATION-SYSTEM.md` as governing) is **closed** in
the live text — `docs/README.md:38` now demotes `docs/{alpha,beta,gamma}` to
retained snapshots and cites this ADR — so it is not re-raised here as a
structural placement defect.

## γ — continuation

The tree **can** reach its target structure, but not by deletion. Three
observations bound the continuation:

1. **No frozen tree is inert.** `docs/beta/governance/` is declared frozen
   (`docs/README.md:38`, `.github/workflows/ci.yml:67`) yet holds live engine/CI
   inputs. Any repair that treats the α/β/γ trees as deletable history destroys
   runtime consumers. The role-grammar rehome must first split live governance
   from frozen snapshot, then rehome each with its consumer set.
2. **The deferred `src/` moves are recorded, not resolved.** `targets/`,
   `katas/`, `schemas/`, `runtime/` remain root peers to the six planes. The ADR
   *decides* each destination (Iteration 3 + Migration state), so these are
   determined defects, not refusals — but each is a heavy consumer-graph move the
   ADR explicitly staged as further CI-gated iterations.
3. **One destination stays operator-open.** The `docs/design/` bundles are
   placement defects (closed taxonomy), but the foundation bundle's *correct
   home* is undecided by the ADR — the CM flags the misplacement and refuses the
   destination. Continuation there is blocked on an operator decision, not on the
   CM.

## Findings

| id | requirement | sev | claim | evidence |
|---|---|---|---|---|
| F1 | `STRUCT-PLANE-001` · `STRUCT-RULE-001` | P0 | `QUICKSTART.md` sits at root as a peer to the six planes; *help a person* → `docs/quickstart`. | `git ls-files` root; ADR *Decision rule* + v1.1 §1 `quickstart` folder. Consumers: `README.md:23,40`; `docs/README.md:10,25`. |
| F2 | `STRUCT-PLANE-001` · `STRUCT-RULE-001` | P0 | `ARCHITECTURE.md` sits at root as a plane-peer; *help a person* → `docs/architecture`. | root; ADR *Decision rule*. Consumer: `src/skills/self-measure/SKILL.md:247`. |
| F3 | `STRUCT-NAME-001` · `STRUCT-DOCSET-001` | P1 | `docs/alpha/` files by α role grammar and is outside the closed eight. | `docs/alpha/README.md:1` "Alpha (α) — Pattern coherence"; ADR §Docs taxonomy "α/β/γ … never a filing taxonomy" + v1.1 §1. |
| F4 | `STRUCT-NAME-001` · `STRUCT-DOCSET-001` · `STRUCT-CONSUMER-001` | P1 | `docs/beta/` files by β role grammar, outside the eight; its `governance/` subtree carries live consumers (see β). | `docs/beta/README.md:1` "Beta (β) — Relational coherence"; consumer graph above (`main.ml:731,759`, `factorized_beta_gate.ml:242`, `factorized-beta-measure.yml`, `ci.yml:67`). |
| F5 | `STRUCT-NAME-001` · `STRUCT-DOCSET-001` | P1 | `docs/gamma/` files by γ role grammar and is outside the closed eight. | `docs/gamma/README.md:1` "Gamma (γ) — Process coherence"; ADR §Docs taxonomy + v1.1 §1. |
| F6 | `STRUCT-DOCSET-001` | P1 | `docs/design/` is not one of the ratified eight; both bundles are placement defects to rehome. | `docs/design/foundation-contract-reconciliation/`, `docs/design/polar-expression-recovery/`; ADR v1.1 §1 ("`docs/design/` is **not a ratified plane**"). |
| F7 | `STRUCT-CONSUMER-001` · `STRUCT-NAME-001` | P0 | `factorized-beta-controls.json` is a role-grammar-placed live fixture; any move MUST rehome its seven enumerated consumers. | consumer graph (β): `main.ml:731,759`; `test_factorized_beta_gate.ml`; `test_factorized_beta.ml:324`; `factorized-beta-measure.yml:225,230`; `CONSISTENCY-FACTORIZATION-PREREG.md`; `0.12.0.md:46`. |
| F8 | `STRUCT-MIXED-001` | P1 | `docs/beta/` interleaves declared-frozen snapshot content with live engine/CI-consumed governance under one tree. | frozen label `docs/README.md:38`, `ci.yml:67`; live content `docs/beta/governance/**` per β consumer graph. **Fixture tension:** `fixtures/plane-conformance.md:28` declines to bind MIXED here ("docs/beta/ is neither frozen nor a snapshot tree"), a ground the tree's own labels and ADR v1.1 §3 precedent contradict. Flagged for reviewer adjudication; confidence medium. |
| F9 | `STRUCT-PLANE-001` · `STRUCT-RULE-001` | P1 | `targets/` is a root peer to the six planes; ADR Iteration 3 folds it into the engine (`src/`). | root `targets/`; ADR Iter 3 ("targets are engine-owned config … fold into the engine, not a single-occupant `config/` plane") + Migration "Remaining `src/` moves". Consumers: β graph. Recorded-deferred by the ADR. |
| F10 | `STRUCT-PLANE-001` | P1 | `katas/` is a root peer to the six planes; ADR stages it to a tests plane. | root `katas/`; ADR Migration "`katas/` to a tests plane". Consumers: β graph. Recorded-deferred. |
| F11 | `STRUCT-PLANE-001` | P1 | `schemas/` is a root peer to the six planes; ADR stages it co-located with owners. | root `schemas/`; ADR Migration "schemas co-located with owners". Consumers: β graph. Recorded-deferred. |
| F12 | `STRUCT-PLANE-001` · `STRUCT-FUNC-001` | P1 | `runtime/` is a single-occupant root plane (one file); ADR co-locates `SELF-MEASURE.md` with its skill. | `git ls-files runtime/` → `runtime/SELF-MEASURE.md` only; ADR Migration "`runtime/SELF-MEASURE.md` co-located with its skill"; STRUCT-FUNC-001 (Iter 3, "not a single-occupant plane"). Consumers: β graph (~55 refs). |
| R1 | `STRUCT-REFUSE-001` | — | The correct **destination** of `docs/design/foundation-contract-reconciliation/` is not decided by the ADR; the CM refuses to name it. | ADR Migration/Deferred ("the coherent home … is a decision to take with the operator's frame, not to force here"). Placement is a defect (F6); destination is refused. |

**Passing (positive) checks — no defect in scope:**

```text
STRUCT-CANON-001   spec/ · src/engine/ocaml/ · conformance/foundation-v4/ at canonical homes
STRUCT-EXCLUDE-001 .cdd/ .cn-sigma/ heldout/ excluded, never flagged as content
STRUCT-DERIVED-001 _build/ untracked dune output (.gitignore:15), distinguishable from source
STRUCT-HISTLABEL-001  docs/evidence/releases/0.12.0.md "Historical." banner;
                      docs/{alpha,beta,gamma}/README frozen declarations;
                      runtime/SELF-MEASURE.md "Frozen repository-proxy" banner — all labelled
STRUCT-OWNER-001   no duplicate live copies of any artifact observed
```

Repair class for F1–F2 is doc placement (move to `docs/` planes); F3–F6, F8 is
docs-tree rehome by reader intent; F9–F12 are the ADR-staged `src/` folds; F7 is
the consumer-bound fixture move. R1 is an operator decision, not a CM repair.

## Status matrix

```text
Placement    (STRUCT-PLANE/RULE/CANON/EXCLUDE)  DEFECTS — F1,F2,F9,F10,F11,F12; CANON+EXCLUDE clean
Naming       (STRUCT-NAME/DOCSET)               DEFECTS — F3,F4,F5,F6 (α/β/γ + design outside eight)
Ownership    (STRUCT-FUNC/OWNER/CONSUMER)       DEFECTS — F7,F12; OWNER clean; consumers enumerated
Lifecycle    (STRUCT-MIXED/HISTLABEL/DERIVED)   DEFECT — F8 (flagged); HISTLABEL + DERIVED clean
Refusal      (STRUCT-REFUSE)                    R1 — foundation-bundle destination refused
```

## Overall

```text
status:        DEFECTS_FOUND  (with a co-occurring UNDERDETERMINED, R1)
warrant scope: classification of the 473 tracked paths against repository-planes-v1.1
               at commit 7514a21. Placement, naming, ownership, and lifecycle
               subcontracts applied; consumer graphs bound to every move-candidate.
determined defects:  F1,F2 (root docs files) · F3,F4,F5,F6 (α/β/γ + design taxonomy) ·
               F7 (consumer-bound fixture) · F8 (frozen/live mixing, flagged) ·
               F9,F10,F11,F12 (ADR-staged root-peer moves).
refused:       R1 — foundation-contract-reconciliation destination (ADR silent).
clean:         spec/ · src/ · conformance/ · scripts/ · docs/{concepts,architecture,evidence} ·
               STRUCT-CANON/EXCLUDE/DERIVED/HISTLABEL/OWNER.
```

`DEFECTS_FOUND` and `UNDERDETERMINED` co-occur across paths; per
`RCM-CONFLICT-001` / `RCM-NO-AGGREGATE-001` this receipt retains both without
averaging. This is a **measurement**, not a repair and not a coherence claim. A
future `COHERENT_WITHIN_DECLARED_SCOPE` result requires the downstream repair
wave to close these findings (`STRUCT-REPAIR-001`, preserving meaning and
rehoming every consumer) and an **independent full-scope review**
(`STRUCT-REVIEW-001`, separate from the repair actor) to verify closure on a
re-run. The one flagged fixture tension (F8) is surfaced for that reviewer to
adjudicate, not silently resolved.

## Receipt envelope

```text
aspect:               structure
cm_version:           structure-cm/0.1
profile:              repository-planes-v1.1
repository_commit:    7514a21b62472c54a6bd3d67d16de28c92ff0cd2
scope:                six ADR planes + root peers + root files; excluded .cdd/ .cn-sigma/
                      heldout/ _build .cell/ .tsc/ .github/; policy pinned @ 7514a21
status:               DEFECTS_FOUND (+ UNDERDETERMINED, R1)
findings:             F1–F12, R1 (table above)
unobserved_surfaces:  none inaccessible. Root metadata files (README.md, STATUS.md,
                      CHANGELOG.md, CONTRIBUTING.md, SECURITY.md, CODE_OF_CONDUCT.md,
                      LICENSE, CITATION.cff, Makefile, install.sh, VERSION) recorded
                      UNDERDETERMINED — the ADR is silent on root-convention metadata,
                      so the CM assigns no plane (STRUCT-REFUSE-001). Excluded sets not
                      classified by design (STRUCT-EXCLUDE-001).
evidence:             plane manifest (473 paths) · canonical-path map (below) ·
                      naming results (docs subfolder membership in closed eight) ·
                      ownership results (no duplicate copies; runtime/ single-occupant) ·
                      lifecycle results (labels present; F8 frozen/live mixing) ·
                      consumer graphs (β section)

+ plane_classification:  α section — every tracked path → resolved plane or UNDETERMINED
+ canonical_path_map:    below
+ policy_authority:      docs/architecture/decisions/repository-planes.md @ 7514a21 (v1.1)
```

**canonical_path_map** (ADR program-mapped homes):

```text
spec/                          satisfied   (spec home)
src/engine/ocaml/              satisfied   (engine home)
conformance/foundation-v4/     satisfied   (foundation conformance home)
research/ascent/               satisfied   (ascent research + DECISIONS.md + traces/)
research/foundation/           N/A         (ADR: "once moved" — archaeology not yet on tree; not a missing canonical home, a deferred one)
targets/ → src/engine          violated    (F9, deferred)
katas/ → tests plane           violated    (F10, deferred)
schemas/ → owner co-location   violated    (F11, deferred)
runtime/SELF-MEASURE.md → skill violated   (F12, deferred)
docs/{quickstart,architecture} target for QUICKSTART.md/ARCHITECTURE.md  violated (F1,F2)
```

_End of run 0001. Frozen structural evidence; immutable._
