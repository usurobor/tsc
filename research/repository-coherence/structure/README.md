# research/repository-coherence/structure/ — Repository Structural Coherence CM

A methodology that measures whether every tracked artifact has one clear place,
name, owner, lifecycle, and relationship to the rest of the repository — judged
against the ratified planes policy, not against the CM's own taste. It applies
TSC to its own repository.

**Status:** pre-normative research. Not under `spec/` (not normative).

- methodology: v0.2
- latest run: 0002 — [`runs/0002-current-main.md`](./runs/0002-current-main.md)
- measured snapshot: `48b9a63`
- result: `DEFECTS_FOUND → DEFECT`
- run 0001 (v0.1): frozen

## Navigation

- [`CM.md`](./CM.md) — the executable procedure: governing claim, the parent
  envelope + declared `status → result_class` mapping, the Inputs/Procedure/Result
  core, the consumer-search contract, and repairability typing. Policy and its
  rationale are **not** restated here — they live in the ADR.
- [`requirements.md`](./requirements.md) — the 15 stable `STRUCT-*` IDs, each tied
  to its ADR clause, plus the v0.2 receipt obligations.
- [`fixtures/`](./fixtures/) — immutable, commit-pinned classification cases:
  the F1/F2 regression pairs, positives, ADR-recorded negatives, the MIXED
  negative, the 7-consumer graph, the near-miss deletion FAIL, and the
  destination refusal.
- [`runs/`](./runs/) — frozen measurement receipts.

**Latest run:** [`runs/0002-current-main.md`](./runs/0002-current-main.md) —
v0.2, snapshot `48b9a63`, `DEFECTS_FOUND → DEFECT`. Run 0001 (v0.1, commit
`7514a21`) is frozen and immutable; it remains interpretable exactly as authored
under v0.1.

## v0.1 → v0.2 delta

v0.2 rewrites `CM.md` from an essay into a minimal executable procedure and moves
duplicated material to its home. It is a **methodology-shape** change, not new
policy: no new `STRUCT-*`, no ADR change, and the retired `STRUCT-LIFECYCLE-001`
stays retired.

- **CM.md cut to executable semantics.** Governing claim + parent envelope +
  declared mapping + the Inputs/Procedure/Result core + the consumer-search
  contract + repairability typing. Policy/rationale now reference the ADR instead
  of restating it; fixture interpretation moved out of the CM.
- **Generic envelope.** The receipt now emits the parent's **Generic child
  receipt envelope** with `aspect_id: structure`, `result_class`, `refusals`, and
  `evidence_refs`, and declares the `status → result_class` mapping
  (`COHERENT_WITHIN_DECLARED_SCOPE→PASS`, `DEFECTS_FOUND→DEFECT`,
  `UNDERDETERMINED`/`INCOMPLETE_OBSERVATION→INCOMPLETE`,
  `CM_EXECUTION_FAILED→FAILED`). The old `aspect: structure` /
  `structure-cm/0.1` form is gone.
- **Three execution-discipline lessons from run 0001**, promoted to contract:
  1. **Immutable fixtures** — every case is synthetic or pinned to an exact
     commit. The moved root files became permanent regression pairs
     (DEFECT @ `7514a21` → PASS @ `a01fbb8`).
  2. **Consumer-search contract** — declared search surfaces, `search_strength`,
     the consumer set, a digest, and unsearched surfaces; the factorized-β
     fixture is repinned to its real **7-consumer** graph, and the near-miss
     "delete the α/β/γ tree without a consumer graph → FAIL" case is fixtured.
  3. **Typed repairability** — every finding ends `MECHANICAL | POLICY_REQUIRED |
     DEFERRED`, so downstream repair is mechanical where policy decides and
     explicitly `POLICY_REQUIRED` where it does not.
- **requirements.md** — 15 IDs unchanged; `STRUCT-CONSUMER-001` sharpened to
  reference the consumer-search contract, and a v0.2 receipt-obligations note
  added. Fixture detail is no longer duplicated here.

## The one rule that shapes everything

The CM **measures**; it does not repair. Repair is a downstream wave that
consumes the frozen defect receipt; an independent review verifies closure.
Measuring and relocating files in one invocation would destroy the evidence
boundary.

## Graduation

If it survives its fixtures and real runs, `src/skills/structural-coherence/`
can own the executable procedure. A normative contract under `spec/` is a later
question.
