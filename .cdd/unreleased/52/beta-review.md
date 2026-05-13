# Cycle 52 — β Review

Issue: #52 (S3: OOD aggregate_semantics detector)
Master: #49 (v0.10.0-canonical-v3.2-cutover)
Reviewer: β (structurally separate from α per CDD §1.4 Triadic)
Branch: `cycle/52-impl` (tip = canonical-v3.2 review surface)

## Round 1

- Cycle-branch head SHA: `5a689509e3cfae79caf9279cd3960387b6940692`
- `origin/main` SHA (synchronous fetch): `e2587bc99978e1f800dbe924786cb32478e30499`
- Diff: `git diff main..5a68950` — 4 commits, 6 files, +594 / -32.
- Touched files:
  - `engine/ocaml/lib/ood.ml` (production)
  - `engine/ocaml/test/test_ood.ml` (new)
  - `engine/ocaml/test/test_coherence.ml` (AC7 fixture migration)
  - `engine/ocaml/test/dune` (wire test_ood)
  - `.cdd/unreleased/52/self-coherence.md`
  - `.cdd/unreleased/52/gamma-closeout.md` (see encapsulation note below)

### Verdict

**APPROVED**

All three acceptance criteria are met with explicit positive and negative
coverage; the error path is operator-actionable and names the missing or
incompatible field together with the expected canonical sentinel; the
spec-cited reset guidance is preserved on the rejection branch; the AC7
fixture migration in `test_coherence.ml` keeps the existing OOD cutover
test green under the strengthened guard; the legacy `check_schema_version`
alias keeps out-of-tree callers compiling while routing them through the
new check. Two B-severity findings recorded below — neither is a blocker
per `review/SKILL.md` §3.3 with the dispatch-specified §3.10 CI carve-out.

### Encapsulation note (CDD §1.4)

The dispatch explicitly directed me to treat
`.cdd/unreleased/52/gamma-closeout.md` as **α-shaped extended
self-coherence content, not γ's close-out**, because the same session
acted as δ-as-γ-then-α under a single-session dispatch. I followed that
directive: artifact authorship is judged by content provenance, not by
the filename. The real γ close-out follows this verdict.

---

## Phase 1 — Contract Integrity

| # | Check                                       | Result | Notes                                                                                                                                                                                                                                                              |
|---|---------------------------------------------|--------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1 | Status truth preserved                      | yes    | Issue distinguishes shipped (`Ood.check_schema_version` v0.9.0), current spec (§5.2 + §12), and target (sentinel). α self-coherence preserves the same partition.                                                                                                  |
| 2 | Canonical sources / paths verified          | yes    | `spec/tsc-core.md` §5.2 contains the `C_Σ^num` definition; §12 contains the OOD reset rule. Both citations verified in the spec on `main`. The issue body's "§6" is a minor citation drift to the broader OOD framework section — α calls this out (F3).            |
| 3 | Scope / non-goals consistent                | yes    | In-scope: `ood.ml` + tests. Out-of-scope: new persistence, drift-statistic change, migration tool. Diff respects all three; deferred case (no production writer) is taken via fixtures as the issue permits.                                                       |
| 4 | Constraint strata consistent                | yes    | Sentinel is a runtime compatibility marker, not a new drift statistic; this is one of the three named design constraints and the implementation honours it.                                                                                                        |
| 5 | Exceptions field-specific / reasoned        | yes    | Legacy alias (`check_schema_version`) is kept as an explicit, documented exception; α surfaces the reason (out-of-tree compatibility) in self-coherence.                                                                                                            |
| 6 | Path resolution base explicit               | yes    | Test commands are scoped: `cd engine/ocaml && dune runtest`. Spec citations are absolute (`spec/tsc-core.md §5.2`, `§12`).                                                                                                                                          |
| 7 | Proof shape adequate                        | yes    | Each AC has invariant + oracle + positive + negative + operator-visible error projection. Known gap (no production writer) explicit.                                                                                                                               |
| 8 | Cross-surface projections updated           | yes    | `test_coherence.ml::test_ood_guard` (AC7) is migrated: positive v3.2.0 and v4.0.0 fixtures gain the canonical sentinel so AC7 stays green under the strengthened guard. This is exactly the cross-surface action the alias requires; no silent breakage.            |
| 9 | No witness theater / false closure          | yes    | Tests are real assertions on real return values from `Ood.check_reference_window` and `Ood.check_schema_version`; failure paths call `exit 1`. The CI-not-run debt is named, not hidden.                                                                            |
|10 | PR body matches branch files                | n/a    | CDD cycle uses branch artifacts, not PR ceremony (CDD §1.4). Equivalent check: issue body's "Surface" lists match the touched files in the diff — verified.                                                                                                         |

No "no" rows; Phase 1 gate passes.

---

## Phase 2a — Issue Contract Walk

### AC Coverage

| AC  | Surface                                              | Evidence in diff                                                                                                                                                                                                                                                                                       | Status |
|-----|------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------|
| AC1 | `engine/ocaml/lib/ood.ml`, test in `test/`           | `check_aggregate_semantics_field` (ood.ml lines 79–102) handles missing, non-string-Int, non-string-Bool, and canonical-string paths; error text uses literal `aggregate_semantics`. `test_ood.ml::test_ac1_field_required` (lines 46–88) exercises missing, `\`Int 42`, and `\`Bool true`.            | MET    |
| AC2 | `ood.ml`                                              | `canonical_aggregate_semantics = "canonical-v3.2-geometric-num"` (ood.ml line 27). Wrong-string branch emits `Printf.sprintf "...'%s' is not accepted; expected '%s'..." v canonical_aggregate_semantics`. `test_ood.ml::test_ac2_only_canonical_accepted` (lines 93–123) runs all four issue-named negatives. | MET    |
| AC3 | `ood.ml`, `test_ood.ml` (and `test_coherence.ml`)    | Missing-field error in ood.ml (lines 94–102) includes `reset the OOD reference distribution` and references `spec/tsc-core.md §12`. `test_ood.ml::test_ac3_reset_guidance_and_fixtures` (lines 129–177) checks `reset`/`regenerate` substring and the named field. Pre-v3.2 precedence verified. AC7 fixtures migrated. | MET    |

### Named Doc Updates

| Doc / Surface                                   | Required? | Present? | Notes                                                                                                                              |
|-------------------------------------------------|-----------|----------|------------------------------------------------------------------------------------------------------------------------------------|
| `engine/ocaml/lib/ood.ml` (doc strings)         | implicit  | yes      | New top-of-file docstring explains the two compatibility surfaces; per-function docstrings name behaviours.                        |
| `engine/ocaml/lib/ood.mli`                      | implicit  | n/a      | No interface file exists for `ood.ml` on `main`; not introduced here. Public surface remains the two exported functions.            |
| `spec/tsc-core.md`                              | no        | n/a      | Issue scope explicitly excludes spec change; sentinel is a runtime marker.                                                          |
| CHANGELOG / release notes                       | no        | n/a      | δ-owned at release boundary (per CDD §1.5).                                                                                         |

### CDD Artifact Contract

| Artifact                                                       | Required before β review | Present? | Notes                                                                                                                          |
|----------------------------------------------------------------|--------------------------|----------|--------------------------------------------------------------------------------------------------------------------------------|
| `.cdd/unreleased/52/self-coherence.md`                         | yes (CDD §5.3)           | yes      | 123 lines; named gap, skills, AC→evidence, debt, CDD trace.                                                                    |
| `.cdd/unreleased/52/gamma-closeout.md`                         | no (γ artifact)          | yes\*    | \*Misnamed per dispatch encapsulation directive; β treats it as α-shaped extended self-coherence. See B-finding `protocol-hygiene`. |
| `.cdd/unreleased/52/beta-review.md`                            | β-authored               | this file| —                                                                                                                              |

### Active Skill Consistency

| Skill                                | Loaded? | Applied? | Evidence                                                                                                                       |
|--------------------------------------|---------|----------|--------------------------------------------------------------------------------------------------------------------------------|
| CDD.md (Tier 1)                       | yes     | yes      | Artifact contract honoured; α/γ encapsulation respected by dispatch directive; β re-baselines.                                |
| cdd/gamma/SKILL.md (Tier 2)           | yes     | n/a-β    | γ phase already exited; β does not re-execute.                                                                                |
| cdd/alpha/SKILL.md (Tier 2)           | yes     | yes      | α's self-coherence carries gap+skills+ACs+evidence+debt+trace — the canonical α shape.                                        |
| cnos.eng/skills/eng/ocaml (Tier 3)    | yes     | yes      | Idiomatic OCaml: `match…with`, `\`Assoc`, `Printf.sprintf`, no exceptions, `Result`-typed return, `let _ = …` not used.        |

---

## Phase 2b — Diff and Context Inspection

| # | Vigilance                                            | Result | Notes                                                                                                                                                                                                                                                                                                          |
|---|------------------------------------------------------|--------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 2.1.1  | Structural closure (input domain enumeration) | yes    | `check_aggregate_semantics_field` covers all four `Yojson.Safe`-style cases that matter: `Some (\`String canonical)` → Ok; `Some (\`String other)` → wrong-string Error; `Some _` → non-string Error; `None` → missing-field Error. The non-string arm catches `\`Int`, `\`Bool`, `\`Float`, `\`Null`, `\`List`, `\`Assoc`. |
| 2.1.2  | Multi-format parity                           | n/a    | No JSON/YAML/prose cross-surface in the diff. The literal sentinel string appears identically in `ood.ml`, `test_ood.ml`, and the AC7 migration in `test_coherence.ml` (3-of-3 parity).                                                                                                                            |
| 2.1.3  | Snapshot consistency                          | n/a    | No snapshot files in diff.                                                                                                                                                                                                                                                                                       |
| 2.1.4  | Stale-path validation                         | yes    | Grep for `check_schema_version` in the diff: only one production callsite migrates (the alias is preserved). `test_coherence.ml::test_ood_guard` already used the legacy name; positive fixtures are updated to carry the sentinel; negative fixtures (v3.1.0, missing version) are correctly left untouched.        |
| 2.1.5  | Branch conventions                            | yes    | Cycle branch is `cycle/52-impl`; tip matches dispatch SHA `5a68950`.                                                                                                                                                                                                                                              |
| 2.1.6  | Execution timeline                            | n/a    | No cross-process state.                                                                                                                                                                                                                                                                                          |
| 2.1.7  | Derivation vs validation                      | yes    | This is a validator (issue scope). No "single source of truth" claim about an emitted artifact, since the deferred writer is explicitly out-of-scope.                                                                                                                                                              |
| 2.1.8  | Authority-surface conflict                    | yes    | The legacy `Ood.check_schema_version` is preserved as an alias to `check_reference_window`; the migrated AC7 fixtures in `test_coherence.ml` align both surfaces. The alias's docstring (ood.ml lines 121–127) names the behaviour change explicitly so the consumer is informed.                                  |
| 2.1.9  | Module-truth audit                            | yes    | Only `ood.ml` is the module under change; the full module is in the diff (it's a small file). No other related assumption to update.                                                                                                                                                                                |
| 2.1.10 | Contract-implementation confinement           | yes    | Restricted input domain is **actively rejected**, not silently accepted: every non-canonical branch returns `Error _`; only the exact-equality `when v = canonical_aggregate_semantics` arm returns `Ok ()`. The wrong-string error message names both observed and expected (AC2 oracle).                          |
| 2.1.11 | Architecture leverage                         | yes    | The fix is at the right boundary — the validator. A higher-leverage shift (e.g. a typed reference-window record) is not warranted under the scope sizing and would be out-of-scope per issue body.                                                                                                                |
| 2.1.12 | Process overhead                              | n/a    | No new docs/gates introduced by this cycle.                                                                                                                                                                                                                                                                      |
| 2.1.13 | Design constraints                            | yes    | Three named constraints — (a) schema version not a substitute for semantic compatibility, (b) error path explicit and actionable, (c) sentinel is a runtime marker not a statistic — are all honoured by the diff. Constraint (b) is satisfied by the spec-cited reset/regenerate guidance on every Error branch. |

---

## Phase 2c — Architecture and Design

| # | Check                          | Result | Notes                                                                                                                                                                                              |
|---|--------------------------------|--------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| A | Reason to change               | yes    | `ood.ml` still has one reason to change: reference-window compatibility validation.                                                                                                                |
| B | Policy above detail            | yes    | The accepted sentinel and the cutover rule are derived from the spec (`§5.2`, `§12`), not invented in this module; the module is a thin enforcement layer.                                          |
| C | Truthful interface             | yes    | The public surface (`check_reference_window`, `check_schema_version`) returns `(unit, string) result` — each implementation path is honoured.                                                       |
| D | Registry normalization         | n/a    | No registry in this cycle.                                                                                                                                                                         |
| E | Source / artifact / installed  | yes    | All edits are in source; no built artifacts changed.                                                                                                                                               |
| F | Surface separation             | yes    | Validator stays a library function; no command/orchestrator/skill smear.                                                                                                                           |
| G | Degraded-path visibility       | yes    | "Degraded path" here = a non-conforming reference window. It is fully visible (operator-readable Error message naming field, observed, expected, and reset guidance) and fully testable (test_ood.ml). |

---

## Findings

| ID  | Severity | Class             | Surface                                              | Description                                                                                                                                                                                                                                  | Remediation                                                                                                       |
|-----|----------|-------------------|------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| B-1 | B        | protocol-hygiene  | `.cdd/unreleased/52/gamma-closeout.md`               | File is named `gamma-closeout.md` but its content is α-shaped (per-AC evidence, environmental debt, findings without triage). The dispatch already acknowledged the CDD §1.4 protocol breach: the same session acted as δ-as-γ-then-α. This is a naming defect, not a coherence defect — the actual γ close-out is independent and follows this verdict. | Non-blocking. γ to file the real `gamma-closeout.md` after merge; either rename the existing file to `alpha-followups.md` at close-out or note the dual-purpose in γ's close-out. |
| B-2 | B        | ci-status         | repo CI                                              | `dune runtest` was not executed in the α session (no OCaml toolchain in dispatch env); β session also has no OCaml toolchain (Phase 0 verified). Per dispatch §3.10 carve-out, the CI-green gate is **deferred** to δ or the next dispatch with toolchain access.                                                                                                                                                  | Non-blocking per dispatch authority. δ or the next toolchain-bearing session MUST run `cd engine/ocaml && dune runtest` before tag.                                                                |
| A-1 | A        | citation-drift    | issue body                                           | Issue #52 prose says spec/tsc-core.md "§6"; the actual normative reset sentence is in §12. α's gamma-closeout F3 already captures this. No code consequence.                                                                                                                                                                                                                                                       | Non-blocking. Optional: γ refines the issue body at close-out, or the next cycle's intake corrects the citation.                                                                                   |

No D-, C-, or unresolved-B findings. The two B findings are categorized
as **acceptable per dispatch carve-out** (`ci-status`) or **acknowledged
non-blocker** (`protocol-hygiene`), and the one A finding is informational.

---

## Round 1 — disposition

**APPROVED** with the three findings above as informational/deferred.

Per `review/SKILL.md` §3.3, an APPROVED verdict means all AC met and zero
**unresolved** blocking findings. The CI-deferred row (B-2) is the
dispatch-specified §3.10 exception; the protocol-hygiene row (B-1) is
named-and-accepted per the dispatch encapsulation directive; the
citation-drift row (A-1) is α-acknowledged and non-doctrinal.

### Merge instruction (β does not push to `main`; main is branch-protected)

The recommended merge form (executable by δ or a session with `main`
push authority):

```
git fetch origin main cycle/52-impl
git checkout main
git merge --no-ff cycle/52-impl -m "merge cycle/52: OOD aggregate_semantics detector

Closes #52.

Strengthens engine/ocaml/lib/ood.ml reference-window validation with a
required aggregate_semantics = 'canonical-v3.2-geometric-num' sentinel
beyond schema_version >= v3.2.0. Adds engine/ocaml/test/test_ood.ml
(AC1+AC2+AC3) and migrates test_coherence.ml AC7 fixtures to carry the
sentinel. The legacy Ood.check_schema_version alias now enforces both
checks.

β verdict: APPROVED (cycle/52-impl @ 5a689509, base origin/main @ e2587bc9).
CI gate deferred per dispatch §3.10 — δ or next toolchain-bearing session
must run 'cd engine/ocaml && dune runtest'."
git push origin main
```

### CI disclaimer

`dune runtest` was not executed in this review (no OCaml toolchain in
the β dispatch environment). The implementation and tests are reviewed
by inspection against canonical OCaml idioms and the existing
`test_coherence.ml` patterns. **Toolchain-bearing CI must run before
tag.** This is the only deferred gate.

---

## Process observations (for γ's cycle iteration)

- α reported a structural push blocker (gamma-closeout F1) that forced
  a single-session δ-as-γ-then-α composition. The eventual artifacts
  *do* satisfy the issue contract; the protocol breach is a process
  miss, not a coherence miss. Worth a `cdd-iteration.md` entry on
  dispatch-environment author-binding.
- β had to reconcile a worktree/branch mismatch at Phase 0 (the
  initially-checked-out `cycle/52-impl` worktree pointed at a different
  commit than the dispatched SHA). Resolved by anchoring all evidence
  to the dispatched SHA via `git`-object queries before any
  filesystem-Read. No artifact integrity impact, but worth noting:
  multiple concurrent worktrees can shadow the "true" cycle branch.
- The CDD §1.4 encapsulation breach (single session acting as
  γ-then-α) is the cycle's most significant process finding. The
  dispatch correctly directed β to ignore the misnamed close-out as
  α content; the result is that triadic separation was preserved at
  β's boundary even though it failed at γ→α's.
