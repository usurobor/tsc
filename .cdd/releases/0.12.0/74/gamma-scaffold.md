# gamma-scaffold.md — cycle/74

Sub-issue: #74 — factorized-β implementation cell (rev-4 prereg AC1–AC10)
Master: #73 (factorized-β witness-consistency wave)
Branch: `cycle/74` (off `origin/main` @ 3843211)
Dispatch mode: §5.2 single-session δ-as-γ via Agent tool (κ operating as δ=γ; γ-axis grade capped at A− per release/SKILL.md §3.8).
Roles: α (implement) dispatched as a sub-agent; β (review) dispatched after α signals review-ready.

## Frozen contract (α implements, does not re-derive)

- Authority: `docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md` (rev 4, on main).
- Oracle fixtures: `docs/beta/governance/fixtures/factorized-beta-controls.json` (frozen).
- Pinned implementation contract + AC1–AC10 + proof commands: issue #74 body.

## Scope

β-axis factorization only: engine enumerates β loci deterministically → LLM adjudicates each
resolved locus with a bounded verdict → engine aggregates `β_factorized`. α/γ scalars untouched.
Allowed kinds: `citation_bears_claim`, `authority_claim`, `target_file_fit`. No `repeated_fact`.

## Environment notes (per §5.2 + this harness)

- No local OCaml toolchain: build/test is the CI oracle (`ci.yml`, `cdd-artifact-validate`).
  α commits + pushes `cycle/74`; CI validates; the artifact β reviews is the committed diff +
  `beta-review.md`, not a sub-agent return summary.
- The k=3 factorized-β measurement runs in the credentialed CI witness (token verified green).
- α sets git identity `alpha@tsc.cdd.cnos` before committing (§7); β sets `beta@tsc.cdd.cnos`.

## Handoff

α produces the implementation + `self-coherence.md` + `alpha-closeout.md` on `cycle/74`.
β reviews against AC1–AC10, writes `beta-review.md`, and on APPROVE merges to main + writes
`beta-closeout.md`. γ (κ-as-γ) writes `gamma-closeout.md` post-merge with the dispatch config
declaration and the PASS/FAIL/NO-DECISION verdict once the CI measurement lands.
