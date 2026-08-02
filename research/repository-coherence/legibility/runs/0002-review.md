# Run 0002 — independent review (REPO-REVIEW-001)

```text
reviews:        runs/0002-current-main.md (measured bb0d095)
reviewer:       independent of the measurer and of every repair actor
final commit:   472ea4b  (main, after the N1 repair this review cleared)
verdict:        GO — COHERENT_WITHIN_DECLARED_SCOPE warranted at the reader level
```

`REPO-REVIEW-001` forbids a coherence claim from standing on the measurer's own
word. This is the separate verification it requires. The reviewer re-derived
every closure from the filesystem and re-ran the newcomer fixture blind; it did
not quote run 0002's findings as evidence for them.

## What was verified

**Run-0001 findings F1–F6 — CLOSED, re-checked on disk.**

| prior | re-verified evidence |
|---|---|
| F1 / F5 authority | `docs/README.md:3` and `repository-planes.md:40` agree that α/β/γ is a measurement/role grammar, never a filing taxonomy; no live document names `DOCUMENTATION-SYSTEM.md` as governing. |
| F2 front door | `README.md:3` states one identity; `:9–27` answers what-is / stands-today / next in one screen. |
| F3 plain intro | `docs/THESIS.md:3–15` opens plain-language; the formal abstract is relocated under §"The formal account". |
| F4 history | `docs/design/0.5.0/` and root `RELEASE.md` absent on disk; rehomed to `docs/evidence/releases/0.12.0.md` behind a Historical banner. |
| F6 noise | status single-homed to `STATUS.md`; other files carry a short projection + pointer, not a full re-narration. |

**Newcomer fixture — independently re-run, 6/6 PASS**, matching run 0002. Every
reader-surface link in `README.md` and `docs/README.md` resolves on disk.

**N1 repair (`472ea4b`) — SOUND.** The `docs/README.md` history note and the
`ci.yml` linkcheck rationale now tell the truth: the α/β/γ trees are retained
prior-cycle snapshots plus the live `docs/beta/governance/` exception. The
linkcheck `--exclude-path` set is byte-identical to its pre-repair state — scope
unchanged. The "live" justification was itself checked: `main.ml:731,759` read
`factorized-beta-controls.json` at runtime (exit 2 on failure).

**Overclaim audit — clean.** The scope is honestly *declared* (reader-facing, not
full-tree). R7 and N1 are genuinely non-reader-facing: the newcomer is routed to
root `QUICKSTART.md`, never to the absent `docs/quickstart/`, and reads neither
the CI comment nor `beta/governance`. No missed reader-surface finding.

## Wave outcome

The repair wave that consumed the frozen `runs/0001` defect set closes here.

| finding | closed by | landed |
|---|---|---|
| F1 F2 F3 F5 | Cell 1 · front door | `ea6556d` |
| F4 F6 | Cell 2 · history + noise | `bb0d095` |
| N1 (surfaced by run 0002) | Cell 3 · frozen-label truth | `472ea4b` |
| F7 authority half | Cell 1 (portal demotes α/β/γ) | `ea6556d` |
| F7 physical half → **R7** | deferred: declared "partial migration in progress" | — |

`COHERENT_WITHIN_DECLARED_SCOPE` now stands, verified. R7 (root `QUICKSTART.md` /
`ARCHITECTURE.md` not yet in `docs/` planes) remains a single declared deferral,
not a silent loose end.

## learning

- The CM earned its keep: run 0001's α mis-classified `docs/{alpha,beta,gamma}`
  as uniformly frozen, and the planned "delete the legacy trees" repair would
  have broken the engine target, the OCaml tests, and a workflow. Measuring
  before repairing caught it — the boundary is load-bearing, not ceremony.
- A wave that consumes a frozen defect receipt can still surface a *new* finding
  (N1) when re-measured. Closure is measure → repair → **re-measure** → review,
  not measure → repair → declare.
- The `docs/{alpha,beta,gamma}` linkcheck exclusion is correct scoping, not the
  Axis E smell the CM first suspected. The smell was the *label*, now fixed. A
  future CM revision should distinguish "excluded because frozen" from "excluded
  because not reader-navigable Markdown, integrity guarded by real consumers."
