# Case study — Repository Cleanup

> **What this is.** The single public-evidence case study called for by
> [`../ADOPTION.md`](../ADOPTION.md) §11 (and §8, the wrong-repair case). It is
> reconstructed entirely from this repository's own history: frozen run receipts
> under `research/repository-coherence/`, the policy ADR
> `docs/architecture/decisions/repository-planes.md`, and the git commits of the
> repair wave. Every factual claim below cites its source. Where a number was not
> instrumented, this case study says so rather than inventing one — see
> [§7](#7-outcomes).

**One-line version.** A prompt-based cleanup was set to drop the legacy α/β/γ
docs trees to history. Run against an exact commit, the Structure CM's consumer
graph found part of that "history" still wired into the engine, the tests, and
CI — seven live consumers on one fixture alone. The wholesale deletion was
cancelled and re-scoped into a consumer-atomic *extract-then-drop* migration.
Nothing that a tool still read was thrown away.

---

## 1. Initial state

**The repository.** By mid-2026 the tree had grown by accretion, mixing
abstraction levels at the root and carrying three parallel documentation trees
named by TSC's own **α/β/γ role grammar** (`docs/alpha/` "Pattern coherence",
`docs/beta/` "Relational coherence", `docs/gamma/` "Process coherence" —
headers re-read at commit `48b9a63` in `research/repository-coherence/structure/runs/0002-current-main.md`
§α). Alongside them sat `docs/design/` (two unratified bundles) and the four
root peers `targets/ katas/ schemas/ runtime/`. The α/β/γ trees were *declared*
frozen prior-cycle snapshots — but one subtree, `docs/beta/governance/`, was a
live machine input the engine and CI still consumed.

**The baseline process.** Cleanup was run as a **prompt-based "cleaning cell"**
(commit `47dd80a`, *"open the repo cleanup cell (CCNF, cleanup domain)"*): an
`alpha` actor produced cleanup edits, an independent `beta` audited each round
(`alpha != beta`), a `gamma` closed when a round returned clean. Its contract
was scoped to "cleaning only… no behavior/logic/spec-meaning change." That
process ran several rounds (`72de2d7`, `422d8c2`, `a222616`, `190b6eb`) and did
useful reader-facing work — but it reasoned about the tree as *prose a reader
navigates*. The obvious next move for a documentation cleanup is to retire
"frozen prior-cycle snapshots" to git history. Applied wholesale to
`docs/{alpha,beta,gamma}/`, that move deletes live machine inputs. Nothing in a
prompt-and-review loop over documentation is built to enumerate every runtime
consumer of a JSON fixture buried under a docs tree before proposing the delete.

That is the gap the methodology was pointed at.

---

## 2. The CM — Repository Coherence

**Repository Coherence** is a composite CM (`research/repository-coherence/CM.md`)
that executes independent aspect CMs on **one exact commit**, validates each
child receipt envelope, and retains the children **without averaging**
(`RCM-NO-AGGREGATE-001` / `RCM-CONFLICT-001`).

| aspect | version | profile | status |
|---|---|---|---|
| Legibility | 0.2 | `technical-newcomer-human` | implemented |
| Structure | 0.2 | `repository-planes-v1.1` | implemented |
| Operability | — | — | **registered, not implemented** (`runs/0001-composite.md` §α) |

- **Legibility** asks whether the declared newcomer can reconstruct identity,
  authority, runnability, and next steps from the front door; it is scored
  against the blind `fixtures/newcomer-tasks.md` (six questions).
- **Structure** classifies every tracked path against a **policy** — the ADR
  `docs/architecture/decisions/repository-planes.md` — and, crucially, binds a
  **consumer graph** to every move-candidate: a placement defect is only a
  coherent move if *every live consumer is rehomed with it*
  (`STRUCT-CONSUMER-001`; `0002-current-main.md` §β).

The **policy authority** is the plane ADR. At Run 1 it stood at **v1.1**
(`repository-planes.md`, pinned `@ 48b9a63`). Its decision rule places artifacts
by plane of responsibility, and v1.1 §1 had just *closed* the docs taxonomy to
eight reader-intent folders — making any `docs/` subfolder outside them a
"defect to rehome, not merely undetermined." The α/β/γ trees and `docs/design/`
are exactly such subfolders.

---

## 3. Run 1 — the frozen measurement

**Composite run 0001** (`research/repository-coherence/runs/0001-composite.md`,
commit `920eba2`) executed both aspects on `48b9a635…` and derived one result by
precedence, no weighting:

```
legibility   PASS    (technical-newcomer-human)   fixture 6/6
structure    DEFECT  (repository-planes-v1.1)     F3–F12 + R1
operability  —       NOT_IMPLEMENTED
composite_status: DEFECTS_FOUND
```

Both truths are retained: the repo is **legible to a newcomer AND misplaced
against the plane policy** — "these do not contradict" (`0001-composite.md` §β,
COMPLEMENTARY). No blended 0.7.

**Structure findings** (`0002-current-main.md`, Findings table) — each carries a
typed **repairability**:

| id | claim (abridged) | repairability |
|---|---|---|
| F3 | `docs/alpha/` filed by α role grammar, outside the closed eight | MECHANICAL |
| F4 | `docs/beta/` filed by β role grammar; its `governance/` subtree carries **live consumers** | POLICY_REQUIRED |
| F5 | `docs/gamma/` filed by γ role grammar, outside the eight | MECHANICAL |
| F6 | `docs/design/` not one of the ratified eight; both bundles misplaced | POLICY_REQUIRED |
| **F7** | `factorized-beta-controls.json` is a role-grammar-placed **live fixture**; a move MUST rehome its **seven** enumerated consumers | **POLICY_REQUIRED**, sev **P0** |
| F8 | `docs/beta/` interleaves declared-frozen snapshot content with live engine/CI-consumed governance | POLICY_REQUIRED |
| F9–F12 | `targets/ katas/ schemas/ runtime/` root-peer folds — ADR-staged | DEFERRED |
| R1 | correct **destination** of the foundation bundle is not decided by the ADR | **refusal** |

**F7 is the load-bearing finding.** Its `consumer_search` block (digest
`fb-json/427512531063`, `0002-current-main.md` §β) enumerates seven live
consumers of one JSON file sitting under `docs/beta/governance/fixtures/`:

```
1. src/engine/ocaml/bin/main.ml:731,759            (runtime CLI default path)
2. src/engine/ocaml/test/test_factorized_beta_gate.ml:199,210,224,250
3. src/engine/ocaml/test/test_factorized_beta.ml:324
4. src/engine/ocaml/lib/factorized_beta.ml:712     (doc comment)
5. .github/workflows/factorized-beta-measure.yml:225,230   (indirect — resolves main.ml default)
6. docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md:17,327,334
7. docs/evidence/releases/0.12.0.md:46
```

The folder-level search F4/F8 (digest `beta-gov/2888e713ec59`) adds that
`.github/workflows/ci.yml:67` **names `docs/beta/governance/` a LIVE
machine-dependency** — an explicit exception to the frozen-tree linkcheck
exclusion. The receipt states the near-miss in plain words (`0002-current-main.md`
§γ.2): *"Any repair that treats the α/β/γ trees as deletable history destroys
the runtime consumers in the β graph."*

The run is a **measurement, not a repair** — it "moves, renames, and deletes
nothing" (`0002-current-main.md`, opening; `STRUCT-REPAIR-001` parent
`RCM-BOUNDARY-001`). Where the ADR did not decide a destination, it **refused**
(R1) rather than legislate.

---

## 4. The repair wave

Repair was a **separate invocation** from measurement, run against the frozen
Run 1 receipt. Three things had to happen in order, and the ordering is the
point.

**(a) The operator (δ) decided the open policy first.** F4/F6/F7/F8 and the R1
refusal were `POLICY_REQUIRED` — the CM had correctly declined to invent a
destination. The operator ratified **ADR repository-planes v1.2** (commit
`2cb2932`), adding a **lifecycle destination rule** and the concrete
dispositions (`repository-planes.md` Amendments v1.2). Two principles in that
rule are what make the repair safe:

- **(a) Machine consumption does not override semantic ownership** — a fixture
  the engine reads still belongs with the experiment that owns its *meaning*;
  "consumers follow the artifact."
- **(b) "Git history only" is conditional** — it applies to a path *only after*
  its live consumers and any standing-claim role are exhausted; "live material
  is extracted to its lifecycle home first, and only the residual superseded
  snapshot is dropped from `main` HEAD."

v1.2 §3 records the effect: F3–F8 become **mechanical** (each now has a
destination) and **R1 is closed** — the foundation bundle is ratified to
`docs/evidence/foundation-v4-reconciliation/`. F9–F12 stay **DEFERRED**, exactly
as the frozen receipt typed them.

**(b) Consumer-atomic migration cells** then executed the dispositions, each a
meaning-preserving path-fixup across the enumerated consumer set:

- `7b70bda` — *Extract live `docs/beta/governance/` material to lifecycle homes
  (F4/F7/F8)*: `git mv` of `METER-LOOP-DECISION.md` → decisions,
  `CONSISTENCY-FACTORIZATION-PREREG.md` + `factorized-beta-controls.json` →
  `research/self-measure/consistency-factorization/`, `DEFECT-HARVESTING.md` →
  research, updating "engine fixture-path defaults + test literals + the emitted
  provenance string; module doc comments; the factorized-beta workflow/script
  comments; runtime/SELF-MEASURE.md meter-loop reference; 0.12.0 evidence file"
  atomically.
- `6b9d367` — *relocate `docs/design/` bundles (F6/R1)*: foundation-reconciliation
  → evidence, polar-expression-recovery → research/foundation; live consumers
  `STATUS.md`, `spec/README.md`, `docs/README.md` repointed atomically.
- `75cca01` — the drop, discussed in [§5](#5-the-prevented-failure-the-headline).

**(c) Independent review held (α ≠ β).** The cleaning cell's own contract
required an independent auditor per round (`47dd80a`: "an independent beta audits
each round (alpha != beta)"), and the Legibility label fix `472ea4b`
(*"correct 'frozen' label for docs/beta/governance live inputs"*) is what closed
Legibility residual **N1** on both surfaces (`0003-current-main.md` §γ). Repair
and review were separate actors, per `RCM-BOUNDARY-001`.

---

## 5. The prevented failure (the headline)

**The baseline plan:** a documentation cleanup retiring the "frozen prior-cycle"
α/β/γ trees would `git rm docs/{alpha,beta,gamma}/` as history. This is the
natural, defensible move for a prose-level cleaning cell — and it would have
deleted:

- `docs/beta/governance/fixtures/factorized-beta-controls.json` — the **F7
  fixture with seven live consumers** (`main.ml:731,759` runtime default;
  four test call sites; the `factorized-beta-measure.yml` CI job that resolves
  that default), and
- the rest of `docs/beta/governance/` that `ci.yml:67` itself flags as a **live
  machine-dependency**.

Deleting it breaks the engine's default input path and the CI job that depends
on it — a `CM_EXECUTION_FAILED`-class regression that a documentation-only review
would not have caught, because the breakage lives in OCaml and YAML, not in the
prose being reviewed.

**What actually happened.** The consumer graph (F7 + F4/F8) had enumerated those
consumers *before any move*. The v1.2 rule forced extract-first (principle (b)).
So the destructive wholesale delete was **cancelled and re-scoped**. Commit
`75cca01` states the corrected shape in its own message:

> *"Execute the v1.2 disposition: **extract the one live artifact, then drop the
> superseded** role-grammar snapshots to Git history (no archive/ tree). …
> `git rm docs/alpha/ docs/gamma/ docs/beta/` (superseded, **no live consumer**)."*

By the time `75cca01` deletes the trees (≈2,891 lines removed across
`docs/{alpha,beta,gamma}/`, within a 2,926-deletion commit that also drops the
trees' now-dead `ci.yml` exclusions and repoints their live artifacts), the live
material is already gone from them —
extracted by `7b70bda` — and the last live doc, `OPERATOR-MANUAL.md`, is lifted
out in the same commit (`docs/{beta => }/guides/OPERATOR-MANUAL.md`) with its
consumers repointed (`src/skills/{cm-of-cms,self-measure}/SKILL.md`,
`targets/repo.tsc`). The same commit also removes the now-dead
`docs/{alpha,beta,gamma}` linkcheck exclusions from `ci.yml`. **Verified at HEAD:**
`git ls-files 'docs/alpha/*' 'docs/beta/*' 'docs/gamma/*'` → **0 files**, while
the fixture survives at
`research/self-measure/consistency-factorization/fixtures/factorized-beta-controls.json`.

> **Reviewer trail for this claim.** Finding: `0002-current-main.md` F7
> (`fb-json/427512531063`, seven consumers) + F4/F8 (`ci.yml:67` live-dependency)
> + §γ.2 ("treating the α/β/γ trees as deletable history destroys the runtime
> consumers"). Policy: `repository-planes.md` v1.2 principle (b). Repair:
> `7b70bda` (extract) **then** `75cca01` (drop "no live consumer"). State:
> `docs/{alpha,beta,gamma}` absent at HEAD; fixture rehomed under
> `research/self-measure/…/fixtures/`.

**A second, smaller prevented failure** is recorded in the same ADR: the
foundation-reconciliation bundle was first sketched for a "mechanical three-way
fragmentation" (`DESIGN.md`→decisions, `ARCHAEOLOGY.md`→research,
`CUTOVER-RECEIPT.md`→evidence). On inspection it is "one cross-referenced review
thread… a by-file split would orphan the review responses and break the thread"
(`repository-planes.md`, Migration state). That split was cancelled; the bundle
moved intact (`6b9d367`).

---

## 6. Run 2 / closure — honestly bounded

The repair wave's dispositions map cleanly onto the Run 1 findings:

| finding | disposition (ADR v1.2 §2) | executing commit |
|---|---|---|
| F3, F5 (α/γ trees) | Git history only, after extraction | `75cca01` |
| F4, F7, F8 (β governance + fixture) | extract to decisions / research | `7b70bda` |
| F6 (design bundles) | evidence / research/foundation | `6b9d367` |
| R1 (foundation destination) | **closed** → `docs/evidence/foundation-v4-reconciliation/` | v1.2 §3 (`2cb2932`) |
| F9–F12 (root-peer folds) | remain **DEFERRED**, unchanged | — (staged) |

Each move preserved the ADR invariants it names — CI green, render byte-identity,
targets resolve, conformance validator exits 0, no document's meaning changes
(`repository-planes.md`, Invariants; commit bodies of `7b70bda`/`75cca01`).

**What has NOT happened yet — stated plainly.** No **fresh frozen re-measurement
receipt** has been recorded at the repaired HEAD. Every receipt under
`research/repository-coherence/` is still pinned at the pre-repair commit
`48b9a63` (composite, structure) or `7514a21` (structure 0001). The composite
run itself says so: a future `COHERENT_WITHIN_MEASURED_ASPECTS` result "requires
the structure repair wave to close F3–F12… then a fresh composite on the
repaired commit" (`0001-composite.md`, Standing). Until that re-run exists,
closure is verifiable from **git state + ADR ratification + CI invariants**, but
it is **not yet certified by an independent Run 2 receipt**. That receipt is the
honest next step, not a claim this case study is entitled to make.

---

## 7. Outcomes

### Qualitative outcomes — documented, and real

These are supported by the receipts, the ADR, and the commits cited above:

1. **A destructive repair was prevented.** The wholesale deletion of
   `docs/{alpha,beta,gamma}/` — which would have removed a fixture with seven
   live engine/test/CI consumers and a CI-declared machine dependency — was
   cancelled and re-scoped to extract-then-drop (`0002` F7/F4/F8 → `7b70bda`,
   `75cca01`).
2. **The repair was consumer-atomic.** Every move rehomed its enumerated
   consumers in the same commit; no live reference was left dangling (commit
   bodies; HEAD verification).
3. **Both truths survived without averaging.** Legibility PASS and Structure
   DEFECT were retained side by side; the cleanup did not paper a structural
   defect over with a passing reader experience (`0001-composite.md` §β).
4. **Policy gaps surfaced as explicit operator decisions.** The CM *refused*
   (R1) and typed four findings `POLICY_REQUIRED` rather than inventing homes;
   the operator answered with ADR v1.2's lifecycle rule and dispositions
   (`2cb2932`), which then made the findings mechanical.
5. **Measurement, repair, and review stayed separate** (`RCM-BOUNDARY-001`);
   the independent-auditor discipline (α ≠ β) held.

### Measured outcomes — to instrument

ADOPTION §10 asks the central product question — *does the CM loop reduce
supervision cost versus prompt-and-review-again?* — and names the metrics that
would answer it. **This historical wave was not instrumented for them, and this
case study does not fabricate them.** A rigorous measured comparison requires a
**future instrumented run** capturing:

- **operator minutes** — human time from Run 1 receipt to verified closure;
- **model calls / agent turns** — repair-agent invocations and retries per
  finding;
- **time-to-closure** — elapsed wall-clock, finding-open → finding-verified;
- **false-positive rate** — findings that, on review, were not real defects;
- **findings closed vs. regressions introduced** — closure count against any new
  breakage;
- **incorrect repairs prevented** — the deletions/moves the consumer graph
  blocked (here, qualitatively: ≥1 destructive delete cancelled — but not
  measured against a controlled prompt-only baseline).

The comparison that would make this case study *quantitatively* conclusive —
*prompt-and-review-again* vs *measure → frozen receipt → bounded cells →
remeasure*, on the same starting commit, both instrumented — has not been run.
Naming that gap is deliberate: it matches ADOPTION's own maturity honesty
(§5, §10), and a wrong number here would be worse than an absent one.

---

## Source index

- Composite receipt — `../../repository-coherence/runs/0001-composite.md` (commit `920eba2`, @`48b9a63`)
- Structure receipt — `../../repository-coherence/structure/runs/0002-current-main.md` (F3–F12, F7 seven consumers, §γ.2 near-miss)
- Legibility receipt — `../../repository-coherence/legibility/runs/0003-current-main.md` (PASS 6/6, N1 closed)
- Policy ADR — `../../../docs/architecture/decisions/repository-planes.md` (v1.0 → v1.2; lifecycle destination rule)
- Baseline cleaning cell — commit `47dd80a`
- Repair wave — ADR v1.2 `2cb2932` · extract `7b70bda` · design bundles `6b9d367` · **drop `75cca01`** · label fix `472ea4b`
- Skeleton this fills — `../ADOPTION.md` §8, §10, §11
