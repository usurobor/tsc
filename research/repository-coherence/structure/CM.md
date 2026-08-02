# Repository Structural Coherence CM

**Status:** pre-normative research · v0.1
**Owns:** the declared methodology. Not the repair skill, not the reviewer.

## Governing claim

At a given commit, does every tracked artifact have exactly one clear place,
name, owner, lifecycle, and relationship to the rest of the repository — as
judged against the ratified planes policy, not against the CM's own taste?

This is a policy-conformance claim with evidence and failure cases. The CM does
not invent what "clean and simple" means; it checks the tree against
[`repository-planes-v1`](../../../docs/architecture/decisions/repository-planes.md)
and returns a categorical status with an evidence-bound defect list. Where the
policy is silent, the CM refuses rather than legislates.

## Profile

```text
profile: repository-planes-v1
authority: docs/architecture/decisions/repository-planes.md
```

The profile is a **policy**, not an audience — structure is largely
audience-independent. The ADR is the sole authority on correct placement,
naming, function, and lifecycle. The CM defers to it for every judgment and has
no standing to overrule it. When the ADR does not decide a path's home, neither
does the CM (see [Refusal](#refusal)).

This aspect is a child of the [Repository Coherence CM](../CM.md); it is
registered in [`ASPECTS.md`](../ASPECTS.md) and honors that parent's common
child receipt envelope and requirements (`RCM-*`).

## What this CM does not do

The CM **observes, classifies, and emits defects with warrant**. It does not
move, rename, or delete files. Repair and review are separate contracts, run as
separate invocations:

```text
Structural Coherence CM   observe → classify → defect receipt (frozen)
Repository repair wave     consume receipt → move / rename files
Independent review         verify defects closed, no new incoherence
```

The boundary is load-bearing: an invocation that relocates files while
inventorying them destroys its own evidence. Measure commit A → freeze the
receipt → repair on commit B → re-run the CM → compare A and B → an independent
reviewer closes. `STRUCT-REPAIR-001` and `STRUCT-REVIEW-001` in
[`requirements.md`](./requirements.md) bind this — the same discipline the
sibling [legibility CM](../legibility/CM.md) holds.

## Four subcontracts

The governing question decomposes into four typed checks against the policy.
Each names what it observes and whether its evidence is mechanical or semantic.

### 1 · Placement — one path, one plane
Every tracked path resolves to exactly one root plane under the ADR decision
rule (*bind*→`spec/`, *run*→`src/`, *prove*→`conformance/`, *still change*→
`research/`, *help a person*→`docs/`, *automate*→`scripts/`), and every path
with a canonical home in the ADR program-maps sits at that home. The do-not-
touch set (`.cdd/`, `.cn-sigma/`, `heldout/`) is excluded as tooling/data, not
misplaced content. Mostly mechanical (the rule is explicit); the *help a person*
vs *still change* boundary can need judgment. → `STRUCT-PLANE-001`,
`STRUCT-RULE-001`, `STRUCT-CANON-001`, `STRUCT-EXCLUDE-001`.

### 2 · Naming — names predict content
Names within a plane are consistent and let a reader predict what a path holds
without opening it; the docs tree files by **reader intent** (`quickstart ·
concepts · guides · reference · architecture · development · papers · evidence`),
never by TSC's own α/β/γ role grammar, which the ADR bars as a filing taxonomy.
Mechanical + semantic. → `STRUCT-NAME-001`.

### 3 · Ownership & function — one directory, one job
Each directory serves one function; each artifact has one owner (one authoritative
home, no duplicate live copies); no plane is a single-occupant catch-all standing
in for a real home. Mechanical + semantic. → `STRUCT-FUNC-001`, `STRUCT-OWNER-001`.

### 4 · Lifecycle — live and history do not mix
`current / draft / historical / generated` are distinguishable and are not
interleaved inside one live directory: a frozen or snapshot tree does not host
live infrastructure, generated artifacts do not read as hand-authored sources,
and historical material carries a lifecycle label rather than sitting as current
content. Mechanical + semantic. → `STRUCT-MIXED-001`, `STRUCT-LIFECYCLE-001`.

A cross-cutting refusal rule (`STRUCT-REFUSE-001`) governs all four: when the ADR
does not fix a path's home, the finding is `UNDERDETERMINED`, not a defect.

## Evidence model

The CM builds one artifact and reads the tree against it:

- **Plane manifest.** Enumerate every tracked path (`git ls-files`), minus the
  do-not-touch set, and classify each into exactly one plane by the decision
  rule. Ambiguous or unclassifiable paths are recorded, not forced.
- **Canonical-path check.** For every home the ADR program-maps name explicitly
  (e.g. spec→`spec/`, engine→`src/engine/ocaml/`, foundation conformance→
  `conformance/foundation-v4/`, ascent history→`research/ascent/`), confirm the
  artifact sits there. Mechanical.
- **Naming check.** Within each plane, flag names that do not predict content and
  docs paths filed outside the reader-intent taxonomy. Mechanical scan, semantic
  adjudication.
- **Ownership / function check.** Detect duplicate live copies of one artifact,
  directories serving more than one function, and single-occupant placeholder
  planes. Mechanical detection, semantic adjudication of "one function."
- **Mixed live/history check.** Flag live-mutable content inside a frozen,
  snapshot, or archive tree, and generated artifacts presented as sources.
  Mechanical signals (snapshot/version-pinned parents, generated markers),
  semantic adjudication.

```text
Mechanical   tree enumeration · plane classification by explicit rule ·
             canonical-path existence · duplicate live copies · single-occupant
             plane detection · name-pattern scan · snapshot/generated markers
Semantic     help-a-person vs still-change boundary · does a name predict
             content · is a directory one function · is a tree live or frozen ·
             is a docs path filed by intent or by role grammar
```

The semantic layer may use an LLM, but it must retain evidence and permit
disagreement — never a lone score. Every finding names its class so a reader
knows how it was reached.

## Receipt

Each run emits the parent's common child receipt envelope
([`../CM.md`](../CM.md), *Common child receipt envelope*), verbatim fields:

```text
aspect:               structure
cm_version:           structure-cm/0.1
profile:              repository-planes-v1
repository_commit:    <SHA>
scope:                <declared plane set + excluded paths + policy commit>
status:               <categorical, see below>
findings:             [ id · subcontract · class · severity · affected paths ·
                        claim · evidence · violated STRUCT-* · adr_clause ·
                        repair class · confidence · status ]
unobserved_surfaces:  <paths not classified, with reason>
evidence:             <plane manifest digest · canonical-path results ·
                        naming results · ownership results · lifecycle results>
```

Structure-specific additions (permitted by the envelope; clearly marked as
extensions, the parent needs only the fields above):

```text
+ plane_classification:  every tracked path → its resolved plane (or UNDETERMINED)
+ canonical_path_map:    each ADR-named canonical home → satisfied | violated
+ policy_authority:      docs/architecture/decisions/repository-planes.md @ <SHA>
```

A receipt on a fixed commit against a fixed policy commit is reproducible.

## Categorical status

The run's top-level result is categorical, never only a count. Same family as
the sibling legibility CM and the parent, read for the structural context:

```text
COHERENT_WITHIN_DECLARED_SCOPE   every classified path sits in its ADR home;
                                 no naming, ownership, or lifecycle defect in scope.
DEFECTS_FOUND                    at least one path violates a STRUCT-* the ADR decides.
UNDERDETERMINED                  a path's correct home is not decided by the ADR;
                                 the CM refuses to legislate it (not a defect).
INCOMPLETE_OBSERVATION           the manifest could not be completed, or a named
                                 canonical home is missing from the tree.
CM_EXECUTION_FAILED              a mechanical check (enumeration, path resolution)
                                 could not run.
```

`UNDERDETERMINED` and `DEFECTS_FOUND` can co-occur across paths; the receipt
retains both, and the parent surfaces both without averaging
(`RCM-CONFLICT-001`, `RCM-NO-AGGREGATE-001`).

## Refusal

The CM refuses rather than guesses; refusal is a finding.

- `UNDERDETERMINED` — the ADR does not fix a path's home. The canonical case is
  the **foundation-contract-reconciliation bundle**, whose home the ADR
  explicitly leaves open: *"a decision to take with the operator's frame, not to
  force here."* The CM records the open question and the ADR clause, and does not
  assign a plane. Inventing one would be the CM legislating policy it does not own.
- `INCOMPLETE_OBSERVATION` — the tree cannot be fully enumerated, or a canonical
  home the ADR names does not exist.
- `CM_EXECUTION_FAILED` — a mechanical check cannot run.

This is the structural face of the parent's measure-only boundary
(`RCM-BOUNDARY-001`): the CM measures against policy, it does not author policy.

## Graduation

While pre-normative and review-run, this stays under `research/`. If it survives
its fixtures and real runs, `src/skills/structural-coherence/` can own the
executable procedure while this record remains. A normative contract under
`spec/` is a later question, authored only if warranted.

## Requirements and fixtures

[`requirements.md`](./requirements.md) holds the stable `STRUCT-*` IDs. Because
structure is policy-conformance, the discriminating fixture is not a fresh-reader
task but a **classification against the tree**: canonical positives, negatives
drawn from the ADR's own recorded deferrals so the CM demonstrably fires on real
known debt, and one `UNDERDETERMINED` case. See [`fixtures/`](./fixtures/).

No run receipt is authored yet — no runs exist. A `runs/` directory follows
convergence, mirroring the sibling legibility layout (which has `runs/` because
it has runs); measurement is a later, separate invocation.
