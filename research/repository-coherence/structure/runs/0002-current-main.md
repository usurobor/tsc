# Run 0002 — current main (structural)

```text
run:                0002
aspect:             structure
cm_version:         0.2
profile:            repository-planes-v1.1
repository_commit:  48b9a635c59ec6ba00dd80ee7a48d1160d1e0656  (main HEAD)
policy_authority:   docs/architecture/decisions/repository-planes.md @ 48b9a63 (v1.1, 2026-08-02)
date:               2026-08-02 (recorded by the run's author; not machine-stamped)
```

This is a **measurement, not a repair**. The CM observes, classifies, and emits
defects with warrant against `repository-planes-v1.1`; it moves, renames, and
deletes nothing (`STRUCT-REPAIR-001`, parent `RCM-BOUNDARY-001`). An independent
full-scope **review** (`STRUCT-REVIEW-001`) and a separate **repair wave**
(`STRUCT-REPAIR-001`) follow this frozen receipt. Where the ADR does not decide a
path's home, the CM refuses rather than legislates (`STRUCT-REFUSE-001`).

This is a **fresh v0.2 run**. Run 0001 (v0.1, @`7514a21`) is frozen and immutable;
it is neither touched nor reinterpreted here. Every path, `file:line`, and
consumer below was re-verified against the tree at `48b9a63` — no count is copied
from run 0001.

## Continuity vs run 0001 — F1/F2 CLOSED

The two root-file placement defects run 0001 recorded are **closed** at this
commit. The moved root files are the fixture's permanent negative→positive
regression pair (`fixtures/plane-conformance.md:19–32`); this run observes the
positive side on live `main`.

```text
F1  QUICKSTART.md (root)   → CLOSED.  git ls-files has no root QUICKSTART.md;
    the artifact now sits at docs/quickstart/README.md (∈ the reader-intent
    eight). Its run-0001 consumers are rehomed: README.md:23,40 →
    `docs/quickstart/README.md`; docs/README.md:10,25 → `quickstart/README.md`.
F2  ARCHITECTURE.md (root) → CLOSED.  no root ARCHITECTURE.md; artifact now at
    docs/architecture/README.md (∈ the eight). Its run-0001 consumer is rehomed:
    src/skills/self-measure/SKILL.md:247 → `docs/architecture/README.md`.
```

Residual mentions of the old basenames survive only where they cannot break a
move: `CHANGELOG.md` (frozen history), the `docs/alpha/engine/0.1.0/**` frozen
snapshot, `src/engine/ocaml/test/test_mechanical.ml:67` (a synthetic Markdown
string literal inside a test, not a path reference), and the sibling legibility
runs discussing the migration. None is a live consumer of a root file.

**F3–F12 and R1 remain open** — the α/β/γ + `design` docs-taxonomy defects, the
consumer-bound β fixture, the frozen/live mixing, and the four ADR-staged
root-peer folds. Each is re-verified below at `48b9a63`.

## Scope

```text
declared plane set:  spec/ · src/ · conformance/ · research/ · docs/ · scripts/
                     (the six ADR target planes), plus every root peer and root file.
excluded (do-not-touch, STRUCT-EXCLUDE-001):  .cdd/ · .cn-sigma/ · heldout/
excluded (build/agent/infra):                 _build (untracked dune output) ·
                     .cell/ · .tsc/ (agent state) · .github/ (CI infra) ·
                     .gitignore · .pre-commit-config.yaml
tracked files enumerated:  475 (git ls-files); 255 in the classified surface
                           after the excluded sets above.
policy commit pinned:      48b9a63 (ADR moves with the tree at this commit)
```

Inventory is **complete** for the declared surface; every tracked path was
enumerated by `git ls-files` and classified. No inaccessible surface. Observation
is not `INCOMPLETE_OBSERVATION`. `.github/` is excluded from *content
classification* (STRUCT-EXCLUDE-001 is `.cdd`/`.cn-sigma`/`heldout`; `.github` is
infra), but CI workflows under it are a searched **consumer surface** below.

## α — manifestation (inventory + plane classification)

Top-level tracked areas (counts by `git ls-files | first path segment`):

```text
plane / area   files   resolved plane            verdict
------------------------------------------------------------------------
spec/            7      spec        (bind)        clean — canonical
src/            80      src         (run)         clean — engine + skills canonical
conformance/    12      conformance (prove)       clean — foundation-v4 canonical
research/       26      research    (still change) clean — incl. this CM tree, legibility, ascent
docs/           54      docs        (help person) MIXED — 4 of 8 present subfolders defective
scripts/        24      scripts     (automate)    clean
------------------------------------------------------------------------ root peers
targets/         7      → src/engine (ADR Iter 3) DEFECT (STRUCT-PLANE-001, deferred)  F9
katas/          19      → a tests plane (ADR)     DEFECT (STRUCT-PLANE-001, deferred)  F10
schemas/        14      → co-located w/ owners     DEFECT (STRUCT-PLANE-001, deferred)  F11
runtime/         1      → co-located w/ skill      DEFECT (STRUCT-PLANE-001 + FUNC-001) F12
------------------------------------------------------------------------ root files
README STATUS CHANGELOG CONTRIBUTING SECURITY CODE_OF_CONDUCT LICENSE CITATION.cff
Makefile install.sh VERSION  → ADR silent          UNDERDETERMINED (convention)
  (QUICKSTART.md / ARCHITECTURE.md no longer at root — F1/F2 closed, now in docs/)
------------------------------------------------------------------------ excluded
.cdd/ .cn-sigma/ heldout/    do-not-touch           excluded (STRUCT-EXCLUDE-001)
_build .cell/ .tsc/ .github/ build/agent/infra      excluded
```

**docs/ subfolder classification** against the closed reader-intent eight
(`quickstart · concepts · guides · reference · architecture · development ·
papers · evidence`, ADR v1.1 §1). Present `docs/` subfolders at `48b9a63`:
`alpha · architecture · beta · concepts · design · evidence · gamma · quickstart`.

```text
docs/quickstart/     ∈ eight     clean — NEW; F1 target home (docs/quickstart/README.md)
docs/architecture/   ∈ eight     clean — F2 target home (README.md + decisions/repository-planes.md)
docs/concepts/       ∈ eight     clean (illustrations/)
docs/evidence/       ∈ eight     clean (releases/0.12.0.md, "Historical." banner)
docs/alpha/          ∉ eight     DEFECT — α role grammar (STRUCT-NAME-001 + DOCSET-001)   F3
docs/beta/           ∉ eight     DEFECT — β role grammar (STRUCT-NAME/DOCSET/CONSUMER/MIXED) F4
docs/gamma/          ∉ eight     DEFECT — γ role grammar (STRUCT-NAME-001 + DOCSET-001)   F5
docs/design/         ∉ eight     DEFECT — closed-taxonomy (STRUCT-DOCSET-001); dest REFUSED F6/R1
docs/README.md docs/THESIS.md    files, not subfolders — portal + intro, in place
```

Headers re-read at `48b9a63`: `docs/alpha/README.md:1` "Alpha (α) — Pattern
coherence"; `docs/beta/README.md:1` "Beta (β) — Relational coherence";
`docs/gamma/README.md:1` "Gamma (γ) — Process coherence". `docs/design/` holds
`foundation-contract-reconciliation/` (DESIGN, ARCHAEOLOGY, CUTOVER-RECEIPT,
ROUND2/3/4-REVIEW-RESPONSE) and `polar-expression-recovery/DESIGN.md`.

**New `research/repository-coherence/` CM tree — classified, coherent, NOT a new
defect.** The 20-file CM tree (`CM.md`, `ASPECTS.md`, `requirements.md`,
`legibility/**`, `structure/**`) resolves to the `research/` plane by the decision
rule *still change* → `research/` (ADR *Decision rule*). Its own `README.md:9`
declares it "pre-normative research … Not under `spec/` (not normative)," matching
the plane definition ("what are we investigating before it is authoritative"). No
`docs/`-taxonomy rule applies — it is not under `docs/`. No canonical-home
violation — the ADR program-maps do not name it. It sits coherently in `research/`
alongside `research/ascent/`; **clean**.

**Inventory completeness:** complete for the declared surface. `_build/` is
untracked (`git ls-files | grep _build` → empty; `.gitignore:15`
`src/engine/ocaml/_build/`), confirming the derived-output exclusion signal
(STRUCT-DERIVED-001, ADR v1.1 §2).

## β — relational / consumer atlas

The load-bearing structural relation is the **consumer graph**: a placement
defect is only a coherent move-candidate if every live consumer is rehomed with
it (`STRUCT-CONSUMER-001`; ADR *Invariants* — "targets resolve; conformance
validator exits 0; no document's meaning changes"). Every set below was grepped at
`48b9a63` over source, tests, CI workflows, `scripts/`, and Markdown links,
excluding `_build/ .cdd/ .cell/ .tsc/`. Each move/split/delete finding carries a
`consumer_search` block (surfaces · strength · consumers · digest · unsearched).

### F7 · docs/beta/governance/fixtures/factorized-beta-controls.json (move candidate)

```text
consumer_search (path: docs/beta/governance/fixtures/factorized-beta-controls.json @ 48b9a63):
  surfaces_searched: [source code, tests, CI workflows, Markdown links, config literals]
  search_strength:   complete
  consumers:
    1. src/engine/ocaml/bin/main.ml:731,759                       (runtime CLI default path)
    2. src/engine/ocaml/test/test_factorized_beta_gate.ml:199,210,224,250
    3. src/engine/ocaml/test/test_factorized_beta.ml:324
    4. src/engine/ocaml/lib/factorized_beta.ml:712                (doc comment)
    5. .github/workflows/factorized-beta-measure.yml:225,230      (indirect — `coh
         factorized-beta-controls-{prompt,check}`; resolves the main.ml:731,759 default)
    6. docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md:17,327,334  (links)
    7. docs/evidence/releases/0.12.0.md:46                        (evidence cross-ref)
  digest:              fb-json/427512531063
  unsearched_surfaces: [] (targets/schemas literals searched, none reference the json)
```

The set is **seven**, matching the fixture pin at `7514a21`
(`fixtures/plane-conformance.md:67–92`): the β tree has not moved between commits.
Consumer 5 is indirect — the workflow invokes a `coh` subcommand whose default
input path is the file — so a move that leaves `main.ml:731,759` unrehomed breaks
the CI job. A move is coherent only if all seven references are rehomed.

### F4/F8 · docs/beta/governance/ (whole-folder move candidate — more than the json)

```text
consumer_search (path: docs/beta/governance/ @ 48b9a63):
  surfaces_searched: [source code, CI workflows, scripts, Markdown links]
  search_strength:   complete_within_bound (folder-level provenance strings + doc links)
  consumers:
    - CONSISTENCY-FACTORIZATION-PREREG.md as provenance string:
        src/engine/ocaml/lib/factorized_beta_gate.ml:242 (emitted in engine output),
        factorized_beta.ml:4, factorized_beta_gate.ml:4,
        .github/workflows/factorized-beta-measure.yml:3, scripts/factorized-beta-measure.sh:3
    - METER-LOOP-DECISION.md → runtime/SELF-MEASURE.md:313
    - CHANGELOG.md:61,78 · docs/evidence/releases/0.12.0.md:46
    - .github/workflows/ci.yml:67 names docs/beta/governance/ a LIVE machine-dependency
        exception to the frozen-tree linkcheck exclusion
  digest:              beta-gov/2888e713ec59
  unsearched_surfaces: []
```

### F9–F12 · ADR-staged root-peer folds (each re-verified live)

```text
targets/  (ADR Iter 3: engine-owned → src/engine)          digest targets/7d556a62610e
  ├─ src/engine/ocaml/bin/main.ml:87,356,373,500,546 · lib/types.ml:12,23
  │    (main.ml:356,500 default `registry = ref "targets/registry.tsc"` — runtime)
  ├─ src/engine/ocaml/test/{test_target_registry,test_consistency,test_factorized_beta*}.ml
  ├─ scripts/{coherence-ledger,cm-consistency,factorized-beta-measure,render-self-measure}.sh
  └─ .github/workflows/{tsc-coherence-ledger,tsc-self-measure}.yml (coh resolves targets at runtime)

katas/  (ADR: → a tests plane)                             digest katas/10eb412b3544
  └─ src/engine/ocaml/{lib/kata.ml,bin/main.ml,test/test_kata.ml} ·
     scripts/{run-katas,cm-admissibility}.sh · .github/workflows/{ci,katas}.yml

schemas/  (ADR: → co-located with owners)                  digest schemas/b96c22a5e279
  └─ scripts/ci/{validate-skill-frontmatter,validate-v4-conformance}.sh ·
     scripts/render-self-measure.sh · .github/workflows/{ci,tsc-coherence-ledger,tsc-self-measure}.yml

runtime/SELF-MEASURE.md  (ADR: → co-located with its skill; also single-occupant plane)
  └─ heavy — src/engine/ocaml/{bin/main.ml,lib/*.ml (report,prompt,types,response_schema,
     factorized_beta,…)} · src/skills/{self-measure,cm-of-cms}/SKILL.md ·
     scripts/{render-self-measure.sh,coh-self} · .github/workflows/{tsc-coherence-ledger,
     tsc-self-measure}.yml · docs/quickstart/README.md:25   digest runtime/abd4e1f0ef0a
     (the run-0001 QUICKSTART.md:25 consumer moved with F1 → docs/quickstart/README.md:25)
```

Every move-candidate carries live runtime/CI consumers. None is a zero-reference
safe move; each repair must be an atomic path-fixup across the sets above. Each
`consumer_search` surface set is a subset of the contract's nine surfaces; the
unsearched surfaces (e.g. no generated-path declarations reference these
hand-authored trees) are recorded as empty where searched exhaustively.

## γ — continuation

Relative to run 0001, the tree moved toward its target structure without
deletion:

1. **The two root-file defects closed by an atomic move**, not by deletion —
   `QUICKSTART.md`/`ARCHITECTURE.md` now sit under their reader-intent planes and
   every enumerated consumer was rehomed (F1/F2 above). This is the fixture's
   DEFECT→PASS regression pair realised on live `main`.
2. **No frozen tree is inert.** `docs/beta/governance/` is declared a live
   exception inside an otherwise-frozen α/β/γ set (`docs/README.md:38`,
   `.github/workflows/ci.yml:67`) yet holds live engine/CI inputs. Any repair that
   treats the α/β/γ trees as deletable history destroys the runtime consumers in
   the β graph — the near-miss the fixture fixtures as a `CM_EXECUTION_FAILED`.
3. **The four deferred `src/` folds are recorded, not resolved.** `targets/`,
   `katas/`, `schemas/`, `runtime/` remain root peers to the six planes. The ADR
   *decides* each destination (Iteration 3 + Migration state), so these are
   determined defects staged as further CI-gated iterations — `DEFERRED`, not
   refusals.
4. **One destination stays operator-open.** The `docs/design/` bundles are
   placement defects (closed taxonomy, F6); the foundation bundle's *correct home*
   is undecided by the ADR (R1) — the CM flags the misplacement and refuses the
   destination.

## Findings

Each finding ends with a typed `repairability` (`MECHANICAL | POLICY_REQUIRED |
DEFERRED`, `CM.md` *Repairability typing*). IDs are carried from run 0001 for
continuity; F1/F2 are CLOSED (above) and not re-listed as active defects.

| id | requirement | sev | claim | repairability | evidence |
|---|---|---|---|---|---|
| F3 | `STRUCT-NAME-001` · `STRUCT-DOCSET-001` | P1 | `docs/alpha/` files by α role grammar and is outside the closed eight. | MECHANICAL | `docs/alpha/README.md:1` "Alpha (α) — Pattern coherence"; ADR §Docs taxonomy ("α/β/γ … never a filing taxonomy") + v1.1 §1. |
| F4 | `STRUCT-NAME-001` · `STRUCT-DOCSET-001` · `STRUCT-CONSUMER-001` | P1 | `docs/beta/` files by β role grammar, outside the eight; its `governance/` subtree carries live consumers. | POLICY_REQUIRED | `docs/beta/README.md:1` "Beta (β) — Relational coherence"; β consumer graph (`main.ml:731,759`, `factorized_beta_gate.ml:242`, `factorized-beta-measure.yml`, `ci.yml:67`). |
| F5 | `STRUCT-NAME-001` · `STRUCT-DOCSET-001` | P1 | `docs/gamma/` files by γ role grammar and is outside the closed eight. | MECHANICAL | `docs/gamma/README.md:1` "Gamma (γ) — Process coherence"; ADR §Docs taxonomy + v1.1 §1. |
| F6 | `STRUCT-DOCSET-001` | P1 | `docs/design/` is not one of the ratified eight; both bundles are placement defects to rehome. | POLICY_REQUIRED | `docs/design/foundation-contract-reconciliation/**` (6 files), `docs/design/polar-expression-recovery/DESIGN.md`; ADR v1.1 §1 ("`docs/design/` is **not a ratified plane**"). Destination refused → R1. |
| F7 | `STRUCT-CONSUMER-001` · `STRUCT-NAME-001` | P0 | `factorized-beta-controls.json` is a role-grammar-placed live fixture; a move MUST rehome its seven enumerated consumers. | POLICY_REQUIRED | β `consumer_search` (digest `fb-json/427512531063`): `main.ml:731,759`; `test_factorized_beta_gate.ml:199,210,224,250`; `test_factorized_beta.ml:324`; `factorized_beta.ml:712`; `factorized-beta-measure.yml:225,230`; `CONSISTENCY-FACTORIZATION-PREREG.md:17,327,334`; `0.12.0.md:46`. |
| F8 | `STRUCT-MIXED-001` | P1 | `docs/beta/` interleaves declared-frozen snapshot content with live engine/CI-consumed governance under one tree. | POLICY_REQUIRED | Frozen label `docs/README.md:38` ("retained prior-cycle snapshots … One exception is `docs/beta/governance/`, which is not frozen history but a live input the engine and CI still consume"), `ci.yml:67`; live content `docs/beta/governance/**` per β graph (ADR v1.1 §3 precedent). |
| F9 | `STRUCT-PLANE-001` · `STRUCT-RULE-001` | P1 | `targets/` is a root peer to the six planes; ADR Iteration 3 folds it into the engine (`src/`). | DEFERRED | root `targets/` (7 files); ADR Iter 3 ("targets are engine-owned config … fold into the engine, not a single-occupant `config/` plane") + Migration "Remaining `src/` moves". Consumers: β graph (digest `targets/7d556a62610e`). ADR-staged. |
| F10 | `STRUCT-PLANE-001` | P1 | `katas/` is a root peer to the six planes; ADR stages it to a tests plane. | DEFERRED | root `katas/` (19 files); ADR Migration "`katas/` to a tests plane". Consumers: β graph (digest `katas/10eb412b3544`). ADR-staged. |
| F11 | `STRUCT-PLANE-001` | P1 | `schemas/` is a root peer to the six planes; ADR stages it co-located with owners. | DEFERRED | root `schemas/` (14 files); ADR Migration "schemas co-located with owners". Consumers: β graph (digest `schemas/b96c22a5e279`). ADR-staged. |
| F12 | `STRUCT-PLANE-001` · `STRUCT-FUNC-001` | P1 | `runtime/` is a single-occupant root plane (one file); ADR co-locates `SELF-MEASURE.md` with its skill. | DEFERRED | `git ls-files runtime/` → `runtime/SELF-MEASURE.md` only; ADR Migration "`runtime/SELF-MEASURE.md` co-located with its skill" + Iter 3 ("not a single-occupant plane"). Consumers: β graph (digest `runtime/abd4e1f0ef0a`). ADR-staged. |
| R1 | `STRUCT-REFUSE-001` | — | The correct **destination** of `docs/design/foundation-contract-reconciliation/` is not decided by the ADR; the CM refuses to name it. | — (refusal; F6 repair is POLICY_REQUIRED) | ADR Migration/Deferred ("the coherent home … is a decision to take with the operator's frame, not to force here"). Placement is a defect (F6); destination is refused. |

**Closed since run 0001:**

```text
F1  QUICKSTART.md (root) → docs/quickstart/README.md    CLOSED (consumers rehomed)
F2  ARCHITECTURE.md (root) → docs/architecture/README.md CLOSED (consumer rehomed)
```

**Passing (positive) checks — no defect in scope:**

```text
STRUCT-CANON-001   spec/ · src/engine/ocaml/ · conformance/foundation-v4/ at canonical homes
STRUCT-EXCLUDE-001 .cdd/ .cn-sigma/ heldout/ excluded, never flagged as content
STRUCT-DERIVED-001 _build/ untracked dune output (.gitignore:15), distinguishable from source
STRUCT-HISTLABEL-001  docs/evidence/releases/0.12.0.md "Historical." banner;
                      docs/{alpha,beta,gamma}/ declared "retained prior-cycle snapshots" (docs/README.md:38);
                      runtime/SELF-MEASURE.md "Frozen repository-proxy methodology" banner — all labelled
STRUCT-OWNER-001   no duplicate live copies of any artifact observed
STRUCT-RULE-001    research/repository-coherence/ CM tree resolves to research/ (still change) — coherent, not a new defect
```

## Status matrix

```text
Placement    (STRUCT-PLANE/RULE/CANON/EXCLUDE)  DEFECTS — F9,F10,F11,F12; F1,F2 CLOSED; CANON+EXCLUDE clean
Naming       (STRUCT-NAME/DOCSET)               DEFECTS — F3,F4,F5,F6 (α/β/γ + design outside eight)
Ownership    (STRUCT-FUNC/OWNER/CONSUMER)       DEFECTS — F7,F12; OWNER clean; consumers enumerated
Lifecycle    (STRUCT-MIXED/HISTLABEL/DERIVED)   DEFECT — F8; HISTLABEL + DERIVED clean
Refusal      (STRUCT-REFUSE)                    R1 — foundation-bundle destination refused
```

## Overall

```text
status:        DEFECTS_FOUND  (with a co-occurring UNDERDETERMINED, R1)
result_class:  DEFECT
warrant scope: classification of the 475 tracked paths (255 in the classified
               surface) against repository-planes-v1.1 at commit 48b9a63.
               Placement, naming, ownership, and lifecycle subcontracts applied;
               consumer graphs bound to every move-candidate.
determined defects:  F3,F4,F5,F6 (α/β/γ + design taxonomy) · F7 (consumer-bound
               fixture, 7) · F8 (frozen/live mixing) · F9,F10,F11,F12 (ADR-staged
               root-peer folds).
closed since 0001:   F1, F2 (root docs files moved into docs/ planes, consumers rehomed).
refused:       R1 — foundation-contract-reconciliation destination (ADR silent).
clean:         spec/ · src/ · conformance/ · scripts/ · research/ (incl. the new CM tree) ·
               docs/{quickstart,architecture,concepts,evidence} ·
               STRUCT-CANON/EXCLUDE/DERIVED/HISTLABEL/OWNER.
```

`DEFECTS_FOUND` and `UNDERDETERMINED` co-occur across paths; per
`RCM-CONFLICT-001` / `RCM-NO-AGGREGATE-001` this receipt retains both without
averaging. Under the declared mapping (`DEFECTS_FOUND → DEFECT`) the generic
`result_class` is `DEFECT`. This is a **measurement**, not a repair and not a
coherence claim. A future `COHERENT_WITHIN_DECLARED_SCOPE` result requires the
downstream repair wave to close F3–F12 (`STRUCT-REPAIR-001`, preserving meaning
and rehoming every consumer) and an **independent full-scope review**
(`STRUCT-REVIEW-001`, separate from the repair actor) to verify closure on a
re-run.

## Receipt envelope (generic child receipt, v0.2)

```text
aspect_id:            structure
cm_version:           0.2
profile:              repository-planes-v1.1
repository_commit:    48b9a635c59ec6ba00dd80ee7a48d1160d1e0656
result_class:         DEFECT
status:               DEFECTS_FOUND (+ UNDERDETERMINED, R1)
scope:                six ADR planes + root peers + root files; excluded .cdd/ .cn-sigma/
                      heldout/ (STRUCT-EXCLUDE-001) + _build .cell/ .tsc/ .github/ (infra);
                      policy pinned @ 48b9a63. 475 tracked, 255 classified.
findings:             F3–F12 + R1 (table above), each with consumer_search
                      (F4,F7,F8,F9,F10,F11,F12) and typed repairability.
                      F1,F2 closed since run 0001.
refusals:             R1 · STRUCT-REFUSE-001 · docs/design/foundation-contract-reconciliation/ ·
                      ADR leaves the destination operator-open (Migration/Deferred note).
unobserved_surfaces:  none inaccessible. Root metadata files (README.md, STATUS.md,
                      CHANGELOG.md, CONTRIBUTING.md, SECURITY.md, CODE_OF_CONDUCT.md,
                      LICENSE, CITATION.cff, Makefile, install.sh, VERSION) recorded
                      UNDERDETERMINED — the ADR is silent on root-convention metadata,
                      so the CM assigns no plane (STRUCT-REFUSE-001). Excluded sets not
                      classified by design (STRUCT-EXCLUDE-001).
evidence_refs:        plane_manifest_digest planes/9b220e4362cb · canonical_path_map (below) ·
                      policy_authority: docs/architecture/decisions/repository-planes.md @ 48b9a63 (v1.1) ·
                      consumer graphs: fb-json/427512531063 · beta-gov/2888e713ec59 ·
                      targets/7d556a62610e · katas/10eb412b3544 · schemas/b96c22a5e279 ·
                      runtime/abd4e1f0ef0a · f1f2-rehome/e19f39eaedee

+ plane_classification:  α section — every tracked path → resolved plane or UNDERDETERMINED.
                         New: research/repository-coherence/ CM tree → research/ (clean).
+ canonical_path_map:    below
+ policy_authority:      docs/architecture/decisions/repository-planes.md @ 48b9a63 (v1.1)
```

**canonical_path_map** (ADR program-mapped homes):

```text
spec/                          satisfied   (spec home)
src/engine/ocaml/              satisfied   (engine home)
conformance/foundation-v4/     satisfied   (foundation conformance home)
research/ascent/               satisfied   (ascent research + DECISIONS.md + traces/)
research/repository-coherence/ satisfied   (pre-normative CM tree in the research plane; ADR decision rule)
research/foundation/           N/A         (ADR: "once moved" — archaeology not yet on tree; a deferred home, not a missing one)
docs/quickstart/README.md      satisfied   (F1 CLOSED — was root QUICKSTART.md)
docs/architecture/README.md    satisfied   (F2 CLOSED — was root ARCHITECTURE.md)
targets/ → src/engine          violated    (F9, deferred)
katas/ → tests plane           violated    (F10, deferred)
schemas/ → owner co-location   violated    (F11, deferred)
runtime/SELF-MEASURE.md → skill violated   (F12, deferred)
docs/{alpha,beta,gamma}/       violated    (F3,F4,F5 — role grammar outside the eight)
docs/design/                   violated    (F6 placement; R1 destination refused)
```

_End of run 0002. Measurement only. Frozen structural evidence; immutable._
