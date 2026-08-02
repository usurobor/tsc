# Repository Structural Coherence CM

**cm_version:** 0.2

## Governing claim

At a given commit, does every tracked artifact have exactly one clear place,
name, owner, lifecycle, and relationship to the rest of the repository — judged
against [`repository-planes-v1.1`](../../../docs/architecture/decisions/repository-planes.md),
never against the CM's own taste.

The ADR is the sole authority on placement, naming, function, and lifecycle.
This CM defers to it for every judgment, refuses where it is silent, and authors
no policy of its own. Policy and its rationale live in the ADR; stable
requirement semantics in [`requirements.md`](./requirements.md); positive and
negative cases in [`fixtures/`](./fixtures/); version and run state in
[`README.md`](./README.md) and [`ASPECTS.md`](../ASPECTS.md). This file is the
executable procedure only.

## Receipt envelope and status mapping

Each run emits the parent's **Generic child receipt envelope**
([`../CM.md`](../CM.md)), with `aspect_id: structure`. The envelope's four-value
`result_class` is derived from this CM's own `status` by the declared mapping:

```text
status COHERENT_WITHIN_DECLARED_SCOPE → result_class PASS
status DEFECTS_FOUND                  → result_class DEFECT
status UNDERDETERMINED                → result_class INCOMPLETE
status INCOMPLETE_OBSERVATION         → result_class INCOMPLETE
status CM_EXECUTION_FAILED            → result_class FAILED
```

`UNDERDETERMINED` and `DEFECTS_FOUND` can co-occur across paths; the receipt
retains both without averaging (`RCM-CONFLICT-001`, `RCM-NO-AGGREGATE-001`). The
top-level `status`/`result_class` is the join of the per-path verdicts under the
Result rule below.

Envelope fields, as emitted:

```text
aspect_id:            structure
cm_version:           0.2
profile:              repository-planes-v1.1
repository_commit:    <sha>
result_class:         PASS | DEFECT | INCOMPLETE | FAILED
status:               COHERENT_WITHIN_DECLARED_SCOPE | DEFECTS_FOUND |
                      UNDERDETERMINED | INCOMPLETE_OBSERVATION | CM_EXECUTION_FAILED
scope:                declared plane set · excluded paths · policy commit
findings:             [ per finding: id · requirement(STRUCT-*) · adr_clause ·
                        affected_paths · claim · evidence · consumer_search ·
                        repairability · confidence ]
refusals:             [ per refusal: id · STRUCT-REFUSE-001 · path · reason ]
unobserved_surfaces:  paths not classified, with reason
evidence_refs:        plane_manifest_digest · canonical_path_map ·
                      policy_authority(path@sha) · consumer graph
```

Every move/split/delete finding MUST carry the `consumer_search` block and a
`repairability` value defined below; a finding lacking either is not
repair-ready.

## Executable core

```text
Inputs:  repository snapshot · policy snapshot (repository-planes-v1.1) · exclusions
Procedure:
  1. Enumerate all tracked paths in scope (git ls-files, minus exclusions).
  2. Classify each path against the policy (plane, canonical home, docs
     reader-intent taxonomy, ownership, lifecycle).
  3. Record violations where policy decides.
  4. Refuse (UNDERDETERMINED) where policy is silent.
  5. For every move/split/delete candidate, enumerate all live consumers
     (consumer-search contract).
  6. Emit the plane manifest, findings, refusals, and consumer graph.
Result:
  FAILED      if a required mechanical check cannot execute, or a move/split/delete
              finding is emitted without its mandatory consumer_search block.
  INCOMPLETE  if inventory or consumer search is incomplete, or policy leaves
              every actionable destination unresolved.
  DEFECT      if at least one policy violation is established.
  PASS        otherwise.
```

The requirement IDs each step checks — and the ADR clause each traces to — are
fixed in [`requirements.md`](./requirements.md).

## Consumer-search contract

Step 5 is load-bearing: a relocation that breaks a consumer without rehoming its
reference cannot satisfy the ADR move invariants. Every finding that proposes a
move/split/delete records a `consumer_search` block searching these surfaces:

```text
source code · tests · CI workflows · scripts · targets · schemas ·
configuration literals · Markdown links · generated-path declarations
```

```text
consumer_search:
  surfaces_searched:    [ subset of the surfaces above, actually searched ]
  search_strength:      complete | complete_within_bound | heuristic
  consumers:            [ resolved live inbound references ]
  digest:               <short-digest / hash of the consumer set>
  unsearched_surfaces:  [ surfaces not searched, with reason ]
```

`search_strength` is `complete` only when every surface was searched with a
resolving method; `complete_within_bound` when exhaustive within a stated bound;
`heuristic` otherwise. Expected consumer sets are pinned to a fixture commit
(see [`fixtures/`](./fixtures/)), never hard-coded as a timeless count.

## Repairability typing

Every structural finding ends with a `repairability`:

```text
repairability: MECHANICAL | POLICY_REQUIRED | DEFERRED
```

```text
MECHANICAL       policy names the destination AND consumer_search is complete.
POLICY_REQUIRED  misplacement established, but the ADR does not decide the destination.
DEFERRED         destination decided, but the ADR explicitly stages the migration.
```

Typed examples (verdicts and consumers pinned in [`fixtures/`](./fixtures/)):

```text
QUICKSTART.md root move            → MECHANICAL     (docs/quickstart is named; consumers complete)
foundation-reconciliation bundle   → POLICY_REQUIRED (misplaced; destination undecided by the ADR)
targets/ fold into the engine      → DEFERRED       (destination decided; migration ADR-staged)
```

This makes downstream repair mechanical where policy decides and explicitly
`POLICY_REQUIRED` where it does not.

## Boundary

The CM observes, classifies, and emits findings; it moves, renames, and deletes
nothing. Measure → freeze the receipt → repair on a later commit → re-run →
independent full-scope review closes (`STRUCT-REPAIR-001`, `STRUCT-REVIEW-001`,
parent `RCM-BOUNDARY-001`). Measuring and relocating in one invocation destroys
the evidence boundary. Repair decisions belong to the downstream repair receipt,
not this CM.

The semantic layer (help-a-person vs still-change boundary; intent vs role
grammar; premature catch-all; live vs frozen; historical; derived) may use an
LLM, but it must retain evidence and permit disagreement — never a lone score.
Every finding names its class so a reader knows how it was reached.
