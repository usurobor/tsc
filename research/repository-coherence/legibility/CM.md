# Repository Legibility Coherence CM

**Status:** pre-normative research · v0.2
**Owns:** the declared methodology. Not the repair skill, not the reviewer.

## Governing claim

At a given commit, can a first-time technical reader reconstruct what the
project is, what is authoritative, what is runnable, what is experimental, and
what to do next — without hitting contradictory status, stale paths, mixed
artifact roles, or avoidable noise?

This is a claim with evidence and failure cases, not a taste question. The CM
answers it with a categorical status and an evidence-bound defect list, scoped
to a declared reader.

## Reader profile

```text
technically experienced
understands software repositories
unfamiliar with TSC
does not know TSC vocabulary
```

A repository can be coherent for its maintainers and incoherent for this reader.
The CM measures the second, and says so.

## What this CM does not do

The CM **observes, checks, and emits defects with warrant**. It does not change
files. Repair and review are separate contracts, run as separate invocations:

```text
Repository Legibility Coherence CM   observe → check → defect receipt (frozen)
Repository repair wave         consume receipt → change files
Independent review             verify defects closed, no new incoherence
```

The boundary is load-bearing: a single invocation that edits files while
observing them destroys its own evidence. Measure commit A → freeze the receipt
→ repair on commit B → re-run the CM → compare A and B → an independent reviewer
closes. `REPO-REPAIR-001` and `REPO-REVIEW-001` in `requirements.md` bind this.

## Four subcontracts

The parent CM composes four typed checks. Each names what it observes and
whether its evidence is mechanical or semantic.

### 1 · Local clarity (per live document)
One governing question; purpose and authority visible immediately; terms
defined before dense use; no stale future tense; no historical material shown as
current; no removable repetition. Mostly semantic. → `REPO-DOC-001`, `REPO-NOISE-001`.

### 2 · Relational & authority coherence (across files)
One authoritative home per stable fact; README and STATUS agree; the docs portal
matches the actual tree; links and canonical paths resolve; implementation
claims match code; no two documents claim incompatible authority. Mechanical +
semantic. → `REPO-AUTH-001`, `REPO-STATUS-001`, `REPO-PATH-001`, `REPO-STRUCTURE-001`.

### 3 · Lifecycle & lineage coherence
Distinguishes `current / draft / normative / experimental / generated /
historical / frozen / superseded`. A Draft is not shown as Normative; a
historical plan is not shown as unfinished current work; generated artifacts do
not read as authoritative; prior failures stay in lineage; a moved document
leaves no stale current entry point. Mechanical + semantic. → `REPO-HISTORY-001`,
`REPO-STATUS-001`.

### 4 · Operability
Documented commands run; targets resolve; links resolve; schemas validate;
rendered artifacts match sources; fixtures and registries close; CI uses current
paths. An elegant README whose first command fails is incoherent. Mechanical.
→ `REPO-RUN-001`, `REPO-PATH-001`.

## Mapping to v4 receipts

The CM emits the three v4 receipt roles, not a scalar.

- **α — manifestation.** Did the methodology actually observe the repository it
  claims to assess? Records the commit SHA, the full file inventory, the
  live-surface policy, excluded paths with reasons, the reader profile, the
  generated/frozen classification, and any surface left unread. Without a
  complete or honestly bounded inventory the run is `INCOMPLETE_OBSERVATION`,
  never "coherent."
- **β — relational atlas.** The actual authority and link graph:
  `README → STATUS`, `README → docs portal → files`, `spec → conformance IDs`,
  `engine → implemented contract`, `skills → rendered artifacts`,
  `targets → included paths`, `historical → current authority`. β retains the
  graph, not a "well organized" scalar.
- **γ — continuation.** Does the repository continue lawfully through change? Did
  a move preserve links and authority; did a cleanup remove defects without
  changing meaning; did a new draft update every consumer; does a proposed
  migration reduce future ambiguity? Post-change review lives here.

## Categorical status

The run's top-level result is categorical, never only a number:

```text
COHERENT_WITHIN_DECLARED_SCOPE
DEFECTS_FOUND
UNDERDETERMINED
INCOMPLETE_OBSERVATION
CM_EXECUTION_FAILED
```

A scalar may summarize trends across runs later; it never replaces the findings
or the categorical status.

## Refusal

The CM refuses rather than guesses. It records `INCOMPLETE_OBSERVATION` when the
inventory cannot be completed or a claimed authority document is missing;
`UNDERDETERMINED` when a defect cannot be confirmed from evidence;
`CM_EXECUTION_FAILED` when a mechanical check cannot run. Refusal is a finding.

## Mechanical vs semantic evidence

The CM separates them so each finding names how it was reached.

```text
Mechanical   tree enumeration · link resolution · path existence ·
             duplicate version literals · missing indexes · status-token
             consistency · command exit codes · schema validation · target
             resolution · render drift · orphaned files
Semantic     plain-language comprehensibility · one file / one job · authority
             ambiguity · historical-vs-live reading · newcomer path clarity ·
             unnecessary repetition · whether an index represents its children
```

The semantic layer may use an LLM, but it must retain evidence and permit
disagreement — never a lone score.

## The newcomer-task fixture

The clearest semantic fixture is not "does the README read well." Give a fresh
reader only the front door and ask the six questions in
`fixtures/newcomer-tasks.md`. A passing repository lets each be answered
accurately from the README plus at most one documented hop, without Git history,
without the glossary for basic identity, and with no contradiction elsewhere —
then each answer is verified against its authority source.

## Receipt

Each run emits the parent's **Generic child receipt envelope**
([`../CM.md`](../CM.md)), with `aspect_id: legibility`. The envelope's four-value
`result_class` is derived from this CM's own categorical `status` by the declared
mapping:

```text
status COHERENT_WITHIN_DECLARED_SCOPE → result_class PASS
status DEFECTS_FOUND                  → result_class DEFECT
status UNDERDETERMINED                → result_class INCOMPLETE
status INCOMPLETE_OBSERVATION         → result_class INCOMPLETE
status CM_EXECUTION_FAILED            → result_class FAILED
```

`result_class` is the generic value the parent composes; `status` retains this
CM's richer categorical vocabulary verbatim and is never collapsed.

Envelope fields, as emitted:

```text
aspect_id:            legibility
cm_version:           0.2
profile:              technical-newcomer-human
repository_commit:    <sha>
result_class:         PASS | DEFECT | INCOMPLETE | FAILED
status:               COHERENT_WITHIN_DECLARED_SCOPE | DEFECTS_FOUND |
                      UNDERDETERMINED | INCOMPLETE_OBSERVATION | CM_EXECUTION_FAILED
scope:                declared reader profile · live-surface policy · excluded paths with reasons
findings:             [ per finding: id · class(mechanical|semantic) · severity ·
                        affected_paths · claim · evidence · violated_requirement(REPO-*) ·
                        repair_class · confidence · status ]
refusals:             [ per refusal: id · INCOMPLETE_OBSERVATION | UNDERDETERMINED |
                        CM_EXECUTION_FAILED · surface · reason ]
unobserved_surfaces:  surfaces left unread, with reason
evidence_refs:        authority graph · status matrix · newcomer-task results ·
                      inventory digest
```

A receipt on a fixed commit is reproducible.

## Requirements and fixtures

`requirements.md` holds the stable `REPO-*` requirement IDs. Each needs a
positive and a negative fixture under `fixtures/`. Retained runs live in `runs/`;
cross-run comparisons in `results/`.

## Graduation

While pre-normative and review-run, this stays under `research/`. If it survives
its fixtures and real runs, `src/skills/legibility-coherence/` can own the
executable procedure while this record remains. A normative contract under
`spec/` is a later question, authored only if warranted.
