# cdd: Incorporate supercycle learnings — 6 skill patches

Closes #N (replace with cnos issue number after filing the issue body in `ISSUE.md`).

## Outcome

Coherence delta: C_Σ A- (`α A`, `β A`, `γ A-`) · **Level:** L7 · **Rounds:** _ (this PR's review)

cdd skill bundle gains six patches that codify behaviors observed in the cnos-tsc supercycle (`usurobor/tsc` master #23) but not previously named in the spec. The skills now name what β was already catching, what γ should require before declaring MCA, where to put `.cdd/unreleased/{N}/` for cycles that don't tag, how review-round counts should surface in the ledger, how to grade releases reproducibly, **and where cdd-self-improvement findings live under `.cdd/`**.

The 6th patch is a meta-finding from authoring this very bundle: cdd had triggers and dispositions but no canonical artifact under `.cdd/` for self-iteration findings, so this PR's own bundle initially landed at `pr-bundles/` at the repo root — a violation of "all artifacts under `.cdd/`". Patch 6 defines the structure (`cdd-iteration.md` per-cycle, `.cdd/iterations/INDEX.md` aggregator, `.cdd/iterations/cross-repo/` traces) that this very PR's cross-repo bundle now uses. Recursive coherence.

## Why it matters

cdd is a method that learns from itself. The supercycle ran 5 cycles in roughly one day, shipped three engine releases, and exposed five recurring patterns the existing skill bundle did not yet address. Each pattern is now documentary debt — the next cnos campaign would re-discover the same gaps because the spec was silent. This PR closes the gaps with patches whose every claim is anchored in the supercycle's evidence trail.

The supercycle also proved cdd works under load: 5/6 sub-issues closed cleanly, β earned its keep across cycles 24 and 29 with binding findings of exactly the class this PR's rule 3.13 now codifies, and the 1 → 2 → 3 → 1 → 2 review-round trace gave concrete data for the metric this PR adds to the ledger.

## Changed

### Patch 1 — `cdd/review/SKILL.md`: honest-claim verification rule (3.13)

Adds verdict rule 3.13 with three binding sub-checks: reproducibility (every quoted measurement is reproducible from this commit), source-of-truth alignment (every term traces to canonical), wiring claims (grep-verify "X is wired into Y"). Adds `honest-claim` as a first-class entry in the finding taxonomy. Adds three checklist rows.

**Empirical anchor:** Three of four findings on cnos-tsc cycle 29's self-coherence report were honest-claim violations (F1 undeclared artifact, F2 score discrepancy, F3 missing provenance). β was already catching the right class — the rule was implicit. Now it's explicit.

### Patch 2 — `cdd/issue/SKILL.md`: mode declaration + MCA preconditions

Adds a mode-declaration section naming four modes (MCA / explore / design-and-build / docs-only). Names three explicit MCA preconditions: design committed at stable path, plan committed with step ordering, both stable. Requires the issue's source-of-truth table to cite design and plan paths when mode = MCA.

**Empirical anchor:** Cycles in master #23 with stable design+plan ran in 1–2 review rounds; cycles where α had to re-derive the plan ran in 3. Mis-labeled MCA inflates review pressure.

### Patch 3 — `cdd/release/SKILL.md`: docs-only disconnect (§2.5b)

Adds explicit §2.5b for cycles that ship only documentation, protocol artifacts, or assessments. Move target is `.cdd/releases/docs/{ISO-date}/{N}/`; PRA goes to `docs/gamma/cdd/docs/{ISO-date}/POST-RELEASE-ASSESSMENT.md`; merge commit is the disconnect signal; no version bump. Renames §2.5a heading to `... (tagged release)` to make the new branch obvious.

**Empirical anchor:** cnos-tsc cycle 27 (retroactive close-out) and cycle 29 (self-coherence report) both left `.cdd/unreleased/{N}/` directories on main because release/SKILL.md was silent on the no-tag case. Both are exhibits in the issue body.

### Patch 4 — `cdd/{post-release,release}/SKILL.md`: round-count + finding-class metrics

Expands `post-release/SKILL.md` §4 with a per-cycle round-counts table and a 5-class finding taxonomy (mechanical / wiring / honest-claim / judgment / contract). Adds an honest-claim ratio metric. Updates both `post-release/SKILL.md` Step 2 and `release/SKILL.md` §2.4 to declare the ledger row format with a Rounds column: `| X.Y.Z | C_Σ | α | β | γ | Level | Rounds | Coherence note |`.

**Empirical anchor:** The 1 → 2 → 3 → 1 → 2 review-round trace across master #23's cycles 27, 25, 24, 26, 29 is real signal — surfacing it in the ledger keeps it visible instead of being buried in PRA prose.

### Patch 5 — `cdd/release/SKILL.md`: honest-grading rubric (§3.8)

Replaces the qualitative "honest grades — not everything is A+" guidance with an explicit per-axis rubric (A through <C, mapped to numeric values 4.0 through <2.0) and a formula for C_Σ as geometric mean. Adds anti-patterns: "score the intent rather than what shipped", "round up because the team worked hard".

**Empirical anchor:** v0.4.0 retroactive grading (α B / β C+ / γ C / C_Σ C+) was defensible but unanchored — any reviewer could pick different letters. The rubric makes the grade reproducible.

### Patch 6 — `cdd/{CDD,post-release/SKILL,gamma/SKILL}.md`: cdd-iteration self-iteration home

Adds a first-class artifact under `.cdd/` for cdd-self-improvement findings surfaced by a cycle. Three layers:

- **Per-cycle:** `.cdd/unreleased/{N}/cdd-iteration.md` — conditionally required when triage produces ≥1 finding tagged `cdd-skill-gap` / `cdd-protocol-gap` / `cdd-tooling-gap` / `cdd-metric-gap`. Per-finding records with source / class / trigger / disposition / patch-or-issue link / affected cdd skill section.
- **Aggregator:** `.cdd/iterations/INDEX.md` — one row per cycle that produced findings; makes cdd's own learning rate measurable.
- **Cross-repo trace:** `.cdd/iterations/cross-repo/{target-repo}/{slug}/` — bundle deliverables + `LINEAGE.md` for findings whose patch lands in a different repo than the source cycle.

`CDD.md` §Tracking, §5.3a, §5.3b updated. `post-release/SKILL.md` gains Step 5.6b "Author cdd-iteration.md (when applicable)" and a pre-publish-gate row enforcing it. `gamma/SKILL.md` §2.10 closure gate gains row 14.

**Empirical anchor:** the supercycle produced 5 distinct cdd-skill-gap findings (patches 1–5 here). Reconstructing them required reading 5 separate `gamma-closeout.md` files and synthesizing — exactly the friction this artifact eliminates. The cross-repo case surfaced when authoring this PR's bundle: tsc had no canonical `.cdd/` location for the 5 patches landing in cnos. The prior `pr-bundles/` at tsc:repo-root violated the "all artifacts under `.cdd/`" principle. Patch 6 closes that loop.

## Removed

- Implicit-only honest-claim review (rule existed in β's behavior, not in the spec).
- Ambiguous MCA assertion path (γ could declare MCA without preconditions).
- Silent docs-only-no-tag case in release protocol.
- Coarse mechanical/judgment-only finding taxonomy.
- Qualitative-only TSC grading guidance.
- Untracked self-iteration: cdd findings buried in PRA prose with no canonical `.cdd/` home; no cross-repo trace structure.

## Validation

- **Recursive consistency check:** β applies rule 3.13 to this PR's own diff. Three sub-checks:
  - 3.13(a) reproducibility — every measurement quoted in the PR body (round counts, finding counts, grade letters) is reproducible from cnos-tsc `usurobor/tsc#23` close-out artifacts.
  - 3.13(b) source-of-truth alignment — every cnos term used (e.g. MCA, ledger row, §2.5a) traces to the canonical SKILL.md being patched.
  - 3.13(c) wiring claims — every "added section X to file Y" claim grep-verifies in the diff.
- **Cross-reference parity:** `release/SKILL.md` §2.4 and `post-release/SKILL.md` Step 2 both name the same ledger format with the Rounds column.
- **Evidence trace:** every empirical claim cites a specific cycle in master #23 (24, 25, 26, 27, 29).
- **Disconnect path:** mode = docs-only per the §2.5b being introduced in this PR. Recursive coherence — the PR's own disconnect tests its proposed protocol. The PR's `.cdd/unreleased/{N}/` will move to `.cdd/releases/docs/{ISO-date}/{N}/`.

## Known Issues

- **Coordination with `usurobor/cnos#330`:** that issue queues three patches (alpha §2.6 placeholder validation, operator stream-json default, release no-tag dir-move). The third overlaps with this PR's Patch 3 (§2.5b). Reviewer should coordinate ordering — recommend merging this PR first since §2.5b here is the more developed treatment, then deduplicating from #330.
- **Kata coverage not updated.** `cnos.cdd.kata/katas/M2-review/` and `M5-issue-authoring/` do not exercise rule 3.13 or the new mode preconditions. Follow-on issue worth filing.
- **Two-agent (δ=γ) configuration not addressed.** The supercycle ran with the operator doubling as γ. This is a structural question that deserves its own design issue; left out of scope here.
- **Branch hygiene authority not addressed.** Stale branches accumulated across the supercycle without a clear delete trigger. Separate design issue.

## Cycle Trace

6 commits (one per patch), 6 files touched in cnos.cdd, +202/−11 net.

```
e794b4a docs(cdd/review): add honest-claim verification rule (3.13)
22025b9 docs(cdd/issue): add mode declaration + MCA preconditions
de7ca50 docs(cdd/release): add docs-only disconnect (§2.5b)
2911346 docs(cdd): add review-rounds + finding-class metrics
6efada5 docs(cdd/release): add honest-grading rubric (§3.8)
5066538 docs(cdd): cdd-iteration.md as canonical home for self-iteration findings
```

Each commit has one logical concern. Order is review semantics → mode discipline → release protocol → metric surfacing → grading rubric → self-iteration home. Patch 6 is the meta-finding: the structure that lets patches 1–5 themselves be filed coherently.

Cross-repo lineage for this PR is recorded at `usurobor/tsc:.cdd/iterations/cross-repo/cnos/cdd-supercycle/LINEAGE.md` per the very Step 5.6b that patch 6 introduces. Recursive coherence verified.
