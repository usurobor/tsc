# results/ — cross-run validation

Evidence that the CM discriminates: an independent measurer applied it to a
version **before** the content cleanup and to current `main` **after**, to
confirm it would have caught the fixes already made and does catch the still-open
findings.

- `pre-cleanup-650bb13.md` — receipt on `650bb13` (before this session's content
  cleanup). All five axes FAIL; Axis A/B fire on every defect the cleanup later
  fixed.
- `current-main-1c752a8.md` — independent receipt on current `main`,
  corroborating `runs/0001`.
- `discrimination.md` — the cross-run comparison.

## Verdict

The CM discriminates. On `650bb13`, Axis A/B FAIL on the full defect set the
cleanup addressed — the broken `coh` command, the README/STATUS normativity gap,
the fabricated parser subsystem, the 44 off-by-one `src/`-move links, the
SECURITY 2.x fiction, the CONTRIBUTING/LICENSE contradiction, and the prose
noise — each traceable to a named signal. On `1c752a8`, Axis C/D/E FAIL on every
open review finding — the α/β/γ authority conflict, the non-plain THESIS, the
split-identity README, and the half-migration. The per-axis profile moved
`FAIL FAIL FAIL FAIL FAIL → PASS PASS FAIL FAIL FAIL`.

## CM-iteration finding (carried to v0.2)

The validation used the v0.1-draft axes (the earlier `.cell` draft, since
superseded by this program's `CM.md`). It surfaced one real limitation and one
note:

1. **A coarse top-line band hides the A/B recovery.** Both commits scored the
   same worst-axis band, so only the per-axis vector and the findings separated
   them. **How v0.1 (this program) addresses it:** the receipt's top line is a
   *categorical* status (`DEFECTS_FOUND`, etc.) that always ships alongside the
   axis vector and the evidence-bound findings — the design rule that "a scalar
   never replaces the findings or the categorical status." Discrimination lives
   in the receipt, not a single number.
2. **Criteria weighting.** The draft's ten acceptance criteria were
   comprehension/navigation-weighted, under-counting Truth and Concision. **How
   v0.1 addresses it:** the `REPO-*` requirements distribute more evenly — Truth
   is carried by `REPO-PATH-001`, `REPO-STATUS-001`, `REPO-AUTH-001`,
   `REPO-RUN-001`; Concision by `REPO-NOISE-001`, `REPO-DOC-001`.

Residual for a future mechanical oracle: if a summary scalar is ever added, weight
it by requirement, not by axis count, so a content-truth regression cannot hide
behind an unchanged information-architecture score.
