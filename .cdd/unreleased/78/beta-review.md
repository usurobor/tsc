# β-review — Sub-1 (#78): CM0 document grammar + `schemas/cm.cue`

Cell: independent β (review), `.cdd/DISPATCH` §5.2. Reviewed adversarially,
independent of the α cell that produced `cycle/78`.
Scope: `git diff origin/main...origin/cycle/78`, Sub-1 files only
(`docs/beta/governance/CM0.md`, `schemas/cm.cue`, `schemas/fixtures/cm/**`,
`skills/cm-of-cms/SKILL.md`, `.cdd/unreleased/78/self-coherence.md`).
γ-axis grade capped at A− per §5.2 (`release/SKILL.md` §3.8).

## Verdict: **REQUEST-CHANGES**

One blocking defect: the shipped `schemas/cm.cue` **does not `cue vet`**.
Its own definitions are self-contradictory (bottom), so the AC2 positive
oracle FAILS and the AC2 negative oracle fails for the wrong reason. The
`cue` binary was absent in the α authoring environment and vet was
"deferred to CI" **without ever being run**, so a schema that cannot
compile was shipped and the self-coherence "structural self-check green"
claim does not survive contact with the real tool.

The pinned axis-migration constraint (AC3) **holds** and is real, not
cosmetic. The blocker is mechanical (the CUE idiom), not conceptual.

## Per-AC pass/miss

| AC | Requirement | Result | Note |
|----|-------------|--------|------|
| AC1 | CM0 authored in its own α-Parts/β-Fit/γ-Evolve grammar; each H2 a typed measurable clause; SKILL.md restructured or clear non-contradicting pointer | **PASS** | 3 H1 sections; 12 α + 8 β + 7 γ H2 clauses, each carrying the full typed block (id, axis, evidence, mechanical_checks, semantic_checks, failure_modes, actions). SKILL.md callout labels §1 as the pre-migration v0.1.0 framing and cedes structure to CM0.md v0.2.0 — no contradiction. |
| AC2 | `schemas/cm.cue` types the organ/relation/clause sets and H2 shape; `cue vet` PASSES for CM0, FAILS for an organ-less stub | **MISS (blocking)** | Required-set closure via regular fields is sound in principle, but the `#NonEmptyChecks` idiom makes `#Clause` (and thus `#CMDocument`) evaluate to bottom independent of data. `cue vet` on `valid/cm0.yaml` FAILS (must pass). See B1. |
| AC3 | Axis-rename recorded as a versioned migration with old→new mapping; CM0 passes its own migration clause (PINNED) | **PASS** | `document_version` 0.1.0→0.2.0; `## Migration Rules` table maps old α=consistency → Consistency standing axis + α `consistency` organ, β/γ unchanged, `interpretable?`=yes for all rows, no orphaned reading. Explicit self-check against the `migration` and `versioning` γ-clauses. Honest residual (α is the one non-aligning axis) recorded, not papered over. |
| AC4 | `cm.cue` header declares import/extend/supersede vs `#CoherenceMethodology`; no silent divergence | **PASS** | Header declares **EXTENDS, does not supersede**, with rationale (no cue.mod → no CUE `import`) and a pinned semantic seam (frontmatter `consistency`/`standing`/`mechanical.signals` ⟷ this document's organs/relations). |

## Checklist results

1. **Axis-rename = versioned γ-migration (PINNED):** HOLDS. Real migration
   ledger + version bump + self-check against the `migration`/`versioning`
   clauses that live in the γ set. Not a silent rename.
2. **cm.cue ↔ skill.cue relationship declared:** YES — EXTENDS, with the
   seam made explicit. No silent divergence.
3. **H2 clauses typed/measurable:** YES structurally — all 12 α / 8 β / 7 γ
   present with the seven-field block. BUT the schema that is supposed to
   *enforce* the typing is itself broken (B1), so the mechanical guarantee
   is currently absent.
4. **Provisional-γ admissible-as-candidate:** YES — `gamma_status:
   *"provisional"`; the `standing-discipline` clause's semantic check keeps
   provisional-γ an admissible candidate; the contract never rejects for
   lacking history. (Cannot be demonstrated by vet until B1 is fixed.)
5. **No contradiction CM0.md ↔ SKILL.md:** YES — reconciliation callout is
   explicit and version-scoped.
6. **Faithful encoding of α-Parts / β-Fit / γ-Evolve:** YES.
7. **Non-goals honored:** YES for Sub-1's own files — no `coh cm-compile`,
   no scalar-meter change, no meter-consistency reopen, no v3.2.5, no
   standing promotion. (See N2 re: `prereg.cue` on the branch.)
8. **cue vet actually run:** YES — `cue` v0.9.2 built from source and run
   against both fixtures. Results are B1 below. This is the finding the
   CI-deferral was hiding.

## Findings

### BLOCKING

**B1 — `schemas/cm.cue` does not `cue vet`; both oracles are broken.**
`schemas/cm.cue:93–98`:

```cue
#NonEmptyChecks: {
	mechanical_checks: [...]
	semantic_checks: [...]
	_total: len(mechanical_checks) + len(semantic_checks)
	_total: >=1
}
```

CUE evaluates a definition against its most-general instance, where both
lists are empty, so `_total` computes to `0` and `0 & >=1` is a conflict
baked into the definition itself. `#NonEmptyChecks` — and therefore
`#Clause`, which embeds it, and therefore every organ/relation/clause field
of `#CMDocument` — is **bottom before any data is unified**. Because bottom
unified with data stays bottom, the positive fixture cannot rescue it.

Executed (cue v0.9.2):
- **Positive** `cue vet -d '#CMDocument' schemas/cm.cue schemas/fixtures/cm/valid/cm0.yaml` → **exit 1** (must be 0). 27 errors, all `#CMDocument.…._total: invalid value 0 (out of bound >=1)`. **AC2 positive oracle is RED.**
- **Negative** `…/invalid/missing-organ.yaml` → exit 1, but the diagnostic is `_total: invalid value 0`, **not** `incomplete value`. It does **not** contain the substring in `missing-organ.expect`, and it fails for the schema-wide reason, not because an organ is missing — so it would fail identically even with all organs present (the positive case proves this). The negative oracle is therefore **vacuous / not demonstrating what it claims**.
- `cue vet schemas/cm.cue` (schema alone, no data) also errors on
  `#Clause._total` and `#NonEmptyChecks._total`, confirming the schema is
  self-bottom.

Minimal repro (isolated `#NonEmptyChecks` + a concrete instance with one
mechanical check) reproduces `#NEC._total: invalid value 0 (out of bound
>=1)` — the idiom, not the fixture, is the fault.

*Suggested fix (β does not apply it):* replace the eager `_total` arithmetic
with a guard that only bites when concrete, e.g.

```cue
#NonEmptyChecks: {
	mechanical_checks: [...]
	semantic_checks: [...]
	if len(mechanical_checks) == 0 {
		semantic_checks: [_, ...]   // require ≥1 semantic when no mechanical
	}
}
```

Verified locally: with this change `valid/cm0.yaml` vets clean (**exit 0**)
and `invalid/missing-organ.yaml` fails with `incomplete value !=""` —
matching `missing-organ.expect`. Both oracles then behave as the ACs
specify. (Any equivalent `matchN`/comprehension idiom is acceptable; the
requirement is that the definition not be self-bottom.)

**B1 is the closure blocker:** issue #78 closure requires "CM0.md vets
against cm.cue"; today it does not. Re-run the two documented vet commands
in CI-equivalent conditions before merge.

### NON-BLOCKING

**N1 — `self-coherence.md` overstates the mechanical oracle.** It records
"0 clause-shape violations" and "the negative oracle will fail vet as
designed" under a `python3`/pyyaml structural check. That check validated
the *data projection*, not the *schema*, so it could not catch B1. Once B1
is fixed, update the record to reflect an actually-executed `cue vet` (and,
ideally, wire the two vet commands into CI as the README already promises).

**N2 — branch carries Sub-2 (#79) commits.** `cycle/78` contains
`d74d23e "#79 Sub-2: prereg …"` in addition to the Sub-1 commit, so
`origin/main...origin/cycle/78` includes `schemas/prereg.cue` and
`fixtures/preregs/**` (Sub-2 surface, out of this review's scope). Not a
Sub-1 AC or non-goal violation, but κ/δ should be aware that merging
`cycle/78` drags in Sub-2 work — the branch is not a clean Sub-1-only
delta. Flagged as branch hygiene, not a correctness defect.

**N3 — `cm0.yaml` is a hand-maintained projection of `CM0.md`.** Already
named as debt in `self-coherence.md`; projection drift is possible until
Sub-3 (or a CI extractor) mechanizes it. Acceptable for this sub given the
faithfulness notes, but the drift risk is real and should not be forgotten.

## Migration-clause self-check confirmation

I re-checked CM0 v0.2.0 against its own `migration` and `versioning`
γ-clauses independently:

- `migration` mechanical: a `## Migration Rules` entry exists per axis
  redefinition (α, β, γ rows present) and each carries an `interpretable?`
  value. **Holds.**
- `migration` semantic: total interpretation, no orphaned old reading — old
  α=consistency is re-homed on the Consistency standing axis via the α
  `consistency` organ + `consistency-standing` β-relation, not dropped.
  **Holds.**
- `versioning`: the axis change bumped the document version (0.1.0→0.2.0)
  with the reason recorded in header + `## Migration Rules`. **Holds.**
- `standing-discipline`: no standing was promoted by the rename. **Not
  violated.**

**The pinned axis-migration constraint holds: CM0 v0.2.0 genuinely passes
its own Migration/Standing-Discipline clause, and the rename is a real
versioned γ-migration, not a cosmetic edit.** This is the strongest part of
the sub. The REQUEST-CHANGES is solely B1 (the schema cannot vet), which is
independent of the migration design.

## Summary

Conceptually faithful, well-documented, and the pinned constraint is
satisfied — but the load-bearing mechanical contract (`cm.cue`) does not
compile, so the sub does not meet its own AC2 / closure condition.
Fix B1, re-run both vet commands green, update the self-coherence record
(N1), and this is an APPROVE.
