# Cycle 52 — Self-Coherence (α)

Issue: #52 (S3: OOD aggregate_semantics detector), sub of master #49
Branch: cycle/52
Mode: design-and-build

## Gap

`engine/ocaml/lib/ood.ml` validates reference windows only by `schema_version`.
A pre-v0.10.0 window built from arithmetic aggregate semantics but stamped
`schema_version = "v3.2.0"` passes today. After the aggregate cutover (#50),
OOD drift comparisons against arithmetic reference distributions are not
meaningful and can produce false drift signals. The runtime guard needs a
second, semantic compatibility check beyond version text.

## Skills loaded

- Tier 1: CDD.md (v3.15.0)
- Tier 2: cdd/gamma/SKILL.md, cdd/alpha/SKILL.md (single-session δ-as-γ dispatch)
- Tier 3: cnos.eng/skills/eng/ocaml (referenced by issue)

## Spec citation

- `spec/tsc-core.md` §5.2 — `C_Σ^num` defines the operational OOD aggregate value.
- `spec/tsc-core.md` §12 — "When migrating from coherence formulations prior to
  v3.2.0, reset the OOD reference distribution — historical C_Σ values are not
  directly comparable across the barrier-transform cutover."

Note on §-numbering: the dispatch named §12 for the OOD reset rule and §5.2
for the numerical aggregate. Spec confirms: §5.2 = numerical aggregate;
§12 = Implementation Notes containing the OOD reset rule. Issue body's
prose says "§6" for the reset rule but the actual reset sentence lives in
§12 (with §6 covering CI/OOD methods in general). Both readings point
to the same normative content; this cycle cites §12 for the reset rule.

## Acceptance criteria → evidence

### AC1 — `aggregate_semantics` required as string

Invariant: a reference window must declare `aggregate_semantics` as a string
field. Missing or non-string → `Error` naming `aggregate_semantics`.

Evidence:
- `engine/ocaml/lib/ood.ml` adds `check_reference_window` which validates
  the new field and a renamed `check_schema_version` retained for back-compat
  callers (it now delegates to `check_reference_window`).
- `engine/ocaml/test/test_ood.ml` covers: missing field, non-string field,
  positive case with canonical sentinel.

### AC2 — only `canonical-v3.2-geometric-num` accepted

Invariant: the only accepted value is `"canonical-v3.2-geometric-num"`.
Any other string → `Error` naming both observed and expected.

Evidence:
- `ood.ml` defines `canonical_aggregate_semantics` constant and rejects all
  other values with an explicit "observed/expected" message.
- `test_ood.ml` covers four negative strings: `arithmetic`, `weighted-average`,
  `canonical-v3.2-geometric-math`, `legacy`.

### AC3 — v3.2-versioned windows without sentinel rejected with reset guidance

Invariant: a v3.2.0-versioned window without the new field is rejected with
guidance to reset/regenerate the reference distribution.

Evidence:
- `ood.ml` error path for missing `aggregate_semantics` includes reset
  guidance text pointing to §12.
- `test_ood.ml` positive fixture: schema_version + sentinel both present.
- `test_ood.ml` negative fixture: schema_version only (the historical
  pre-v0.10.0 shape).
- No production reference-window writer exists in the branch; the deferred
  scope from the issue body applies (fixtures suffice).

## Self-produced or fixture evidence

This branch does not introduce a production reference-window writer. The
test fixtures in `engine/ocaml/test/test_ood.ml` carry the canonical
sentinel for positive cases and omit it (or use a wrong value) for
negative cases. This satisfies AC3 under the issue's stated fixture
fallback.

## Known debt

- No OCaml toolchain (dune/opam) is available in the dispatch environment;
  `dune runtest engine/ocaml/test/` cannot be executed by α. β review (or
  a CI environment with OCaml) must run `cd engine/ocaml && dune runtest`
  to confirm green. Code is written to compile by inspection and follows
  the existing patterns in `test_coherence.ml` exactly.
- The legacy entry point `Ood.check_schema_version` is retained as an
  alias for `check_reference_window` so out-of-tree callers (if any)
  do not break; downstream tests in `test_coherence.ml` use it and pass
  fixtures that now also carry the canonical sentinel.

## CDD Trace

- 2026-05-13 — γ (δ-as-γ) created cycle/52 from origin/main; this cycle.
- Implementation phase: see commits on cycle/52.
- Close-out: see `gamma-closeout.md` in this directory.
