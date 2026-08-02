# Repository Structural Coherence CM

**Status:** pre-normative research · v0.1
**Owns:** the declared methodology. Not the repair skill, not the reviewer.

## Governing claim

At a given commit, does every tracked artifact have exactly one clear place,
name, owner, lifecycle, and relationship to the rest of the repository — as
judged against the ratified planes policy, not against the CM's own taste?

This is a policy-conformance claim with evidence and failure cases. The CM does
not invent what "clean and simple" means; it checks the tree against
[`repository-planes-v1.1`](../../../docs/architecture/decisions/repository-planes.md)
and returns a categorical status with an evidence-bound defect list. Where the
policy is silent, the CM refuses rather than legislates.

## Profile

```text
profile: repository-planes-v1.1
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

### 2 · Naming — docs file by reader intent, taxonomy closed
The docs tree files by **reader intent** (`quickstart · concepts · guides ·
reference · architecture · development · papers · evidence`), and TSC's own
α/β/γ role grammar is never used as a filing taxonomy ("α/β/γ … never a filing
taxonomy"). As of v1.1 the eight intents are the **exhaustive** set of `docs/`
subfolders: a `docs/` subfolder outside them is a defect to rehome, not
`UNDERDETERMINED` (v1.1 Amendment 1, which closes what v1 left as a
named-but-unfenced list). The CM still does not judge whether *other planes'*
names "predict content" — that stays a declined legibility value (see
[Policy notes](#policy-notes--considered-and-declined)). Mechanical + semantic.
→ `STRUCT-NAME-001`, `STRUCT-DOCSET-001`.

### 3 · Ownership & function — one home, no premature planes, consumers enumerated
Each artifact has one authoritative home with no duplicate live copies (the
ADR organizes by plane and navigates topics through indexes / program-maps, not
physical co-location); and no plane is a single-occupant or premature catch-all
standing in for a real home (ADR Iteration 3: not a single-occupant `config/`
plane). Every placement/ownership finding enumerates the artifact's live
**consumers** — code references, CI workflows, `targets/`, tests, markdown links
— because a relocation that breaks a consumer without rehoming its reference
cannot satisfy the ADR move invariants ("targets resolve; conformance validator
exits 0 …; no document's meaning changes"). This is the observation-side
complement to `STRUCT-REPAIR-001`. Mechanical + semantic. → `STRUCT-FUNC-001`,
`STRUCT-OWNER-001`, `STRUCT-CONSUMER-001`.

### 4 · Lifecycle — live/history separated and labelled, source distinct from generated
No live directory interleaves live-mutable content with frozen, snapshot, or
archived content — the lifecycle rule v1 ratifies, grounded in its migration
state, which preserves frozen snapshots intact. As of v1.1 two further rules
apply: historical/archived/frozen material retained on the live tree carries a
lifecycle label — banner or marker (v1.1 Amendment 3; precedent: the `0.12.0.md`
"Historical" banner, the `docs/{alpha,beta,gamma}` frozen-snapshot declaration);
and derived/generated output is distinguishable from hand-authored source — by an
excluded build dir, generated marker, or clearly-derived path (v1.1 Amendment 2;
precedent: render byte-identity, excluded `_build/`). Mechanical + semantic.
→ `STRUCT-MIXED-001`, `STRUCT-HISTLABEL-001`, `STRUCT-DERIVED-001`.

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
- **Naming check.** Flag docs paths filed by α/β/γ role grammar rather than by
  the reader-intent taxonomy. Mechanical scan (role-grammar directory names),
  semantic adjudication of intent.
- **Ownership / function check.** Detect duplicate live copies of one artifact
  and single-occupant placeholder planes. Mechanical detection, semantic
  adjudication of "premature catch-all."
- **Mixed live/history check.** Flag live-mutable content inside a frozen,
  snapshot, or archive tree. Mechanical signal (snapshot/version-pinned parents),
  semantic adjudication.
- **History-label check.** For historical/archived/frozen material on the live
  tree, confirm a lifecycle label is present (banner or marker). Mechanical scan
  (banner/marker presence on snapshot/version-pinned or archive paths), semantic
  adjudication of "is this material historical."
- **Derived-vs-source check.** Confirm generated/derived output is distinguishable
  from hand-authored source — excluded from tracked content (build dir), carrying
  a generated marker, or on a clearly-derived path with a render/build binding.
  Mechanical (exclusion, marker, render-check presence), semantic adjudication of
  "is this path derived."
- **Consumer graph.** For every path proposed for a move, resolve its inbound
  live consumers — grep code references, CI workflows, `targets/`, and tests, plus
  markdown-link resolution — and bind that consumer set to the finding. A move is
  coherent only if it rehomes every consumer's reference. Mechanical (scriptable
  grep + link resolution). Grounds the ADR move invariants ("targets resolve;
  conformance validator exits 0 …; no document's meaning changes").

```text
Mechanical   tree enumeration · plane classification by explicit rule ·
             canonical-path existence · duplicate live copies · single-occupant
             plane detection · α/β/γ role-grammar directory names ·
             docs-subfolder membership in the closed eight ·
             snapshot/version-pinned parents · lifecycle-label presence ·
             generated exclusion / marker / render-check ·
             consumer grep (code · CI · targets · tests) + link resolution
Semantic     help-a-person vs still-change boundary · is a docs path filed by
             intent or by role grammar · is a plane a premature catch-all ·
             is a tree live or frozen · is this material historical ·
             is this path derived
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
profile:              repository-planes-v1.1
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

- `UNDERDETERMINED` — the ADR does not fix a path's correct home. Post-v1.1 the
  canonical case narrows: the **foundation-contract-reconciliation bundle** is now
  a placement **defect** — it sits in `docs/design/`, a plane v1.1 declares
  non-ratified (`STRUCT-DOCSET-001`) — yet its *destination* stays open, the
  Deferred note still leaving it as *"a decision to take with the operator's
  frame, not to force here."* The CM flags the misplacement and refuses to name a
  destination: misplacement is decided, destination is not. Inventing a
  destination would be the CM legislating policy it does not own.
- `INCOMPLETE_OBSERVATION` — the tree cannot be fully enumerated, or a canonical
  home the ADR names does not exist.
- `CM_EXECUTION_FAILED` — a mechanical check cannot run.

This is the structural face of the parent's measure-only boundary
(`RCM-BOUNDARY-001`): the CM measures against policy, it does not author policy.

## Policy notes — considered and declined

`repository-planes-v1.1` (2026-08-02) ratified two dimensions this CM formerly
recorded as gaps, and closed the docs taxonomy. They are now **measured**, not
deferred:

```text
generated-vs-source distinction   v1.1 Amendment 2 → STRUCT-DERIVED-001.
historical-artifact labelling     v1.1 Amendment 3 → STRUCT-HISTLABEL-001.
closed docs taxonomy              v1.1 Amendment 1 → STRUCT-DOCSET-001 (a docs/
                                  subfolder outside the eight is now a defect,
                                  no longer UNDERDETERMINED).
```

One dimension from the governing proposal's owned-concerns list stays unratified
**by deliberate decision**, not by omission:

```text
all-planes name-predictiveness    considered at v1.1 and declined as a structure
                                  rule (v1.1 Amendment 4). It is a legibility
                                  value — can a reader predict what a path holds
                                  — not a placement rule, and belongs to the
                                  legibility aspect. Structure ratifies only
                                  "docs file by reader intent," the closed docs
                                  taxonomy, and "α/β/γ … never a filing taxonomy";
                                  no general cross-plane "names predict content"
                                  rule.
```

The CM does not measure cross-plane name-predictiveness: doing so would enforce a
rule the policy authority explicitly declined. Recorded here — not silently
dropped — as the operator's considered decision, so the note reads truthfully
post-amendment.

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
known debt, and the surviving refusal (a misplaced bundle whose *destination*
the ADR still leaves open). See [`fixtures/`](./fixtures/).

No run receipt is authored yet — no runs exist. A `runs/` directory follows
convergence, mirroring the sibling legibility layout (which has `runs/` because
it has runs); measurement is a later, separate invocation.
