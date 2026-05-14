<!-- sections: [intake, scope, AC mapping, dispatch, known constraints] -->
<!-- completed: [intake, scope, AC mapping, dispatch, known constraints] -->

# γ-scaffold — cycle/54 (S5: cutover cleanup)

**Issue:** #54 — sub of master #49 (v0.10.0 canonical v3.2 scoring cutover wave)
**Branch:** `cycle/54`
**Base:** `origin/main` @ `3efde94` (post-S1+S2+S3+S4 merges)
**γ identity (this session):** `gamma@tsc.cdd.cnos`, acting as δ-as-γ per `.cdd/DISPATCH` §5.2
**Dispatched-at:** 2026-05-13

## Intake

γ creates this branch and the scaffold record before α dispatch (per CDD §1.4 γ algorithm Phase 1 step 3a). α and β are dispatched as separate subagent sessions, observing CDD §1.4 Triadic rule role separation. The wave-1 dispatch breach (γ+α collapse) is not repeated here.

#54 was held until #50 merged. As of `3efde94` all four predecessor cycles are on `main`:

- #50 (canonical aggregate + report schema) — merged via PR #57
- #51 (strict v3.2 LLM δ validation)        — merged
- #52 (OOD `aggregate_semantics` detector)  — merged via PR #56
- #53 (cross-target report surface §7.4)    — merged via PR #58

The settled schema is now on `main`. S5 operates on it.

## Scope

S5 is the cutover-cleanup sub. 8 ACs spanning code (smoke tests, CI rule), katas (re-baseline against the post-#50 numeric aggregate), non-frozen docs (rewrite from the canonical model), repo root (`project.tsc` removal), frozen snapshots (banner-revert only — CDD §5.6), `CHANGELOG.md` + `RELEASE.md`, and the `VERSION` 0.9.0 → 0.10.0 bump that prepares the v0.10.0 tag.

In scope per #54:
- `katas/{01-glider, 02-random-soup, 03-comparative, 04-philosophical, 05-adversarial}/{kata.toml, README.md}`
- `docs/THESIS.md`, root `QUICKSTART.md`, root `ARCHITECTURE.md`, `docs/beta/guides/OPERATOR-MANUAL.md`, `katas/README.md`
- `project.tsc` (delete)
- `docs/alpha/doctrine/3.2.0/SELF-COHERENCE.md`, `docs/alpha/engine/0.5.0/POST-RELEASE-ASSESSMENT.md`, `docs/design/0.5.0/DESIGN.md` (revert previously-added archival banners; per CDD §5.6 only path-reference repairs are normally allowed in frozen snapshots — the banner-revert is the one explicit exception this cycle carries)
- `CHANGELOG.md` (v0.10.0 row + migration note)
- `engine/ocaml/test/` (target-registry smoke tests)
- `scripts/check-forbidden-wording.sh` + CI wiring
- `VERSION`, `engine/ocaml/dune-project`, `engine/ocaml/tsc_engine.opam`, `RELEASE.md`

Out of scope (named in #54):
- Semantic edits to frozen version directories beyond the banner-revert.
- Operational ACCEPT/REJECT verdict implementation.
- LLM-mode kata coverage.
- Historical report migration.

## AC mapping

| AC | Surface | Oracle |
|---|---|---|
| AC1 — katas re-baselined | `katas/*/kata.toml`, READMEs | `scripts/run-katas.sh` (deferred to CI: no OCaml toolchain in sandbox); each `kata.toml` records baseline_engine_commit + α/β/γ + `c_sigma_math`/`c_sigma_num` + rationale_category |
| AC2 — active docs use canonical aggregate semantics | THESIS, QUICKSTART, ARCHITECTURE, OPERATOR-MANUAL, katas/README, per-kata READMEs | grep/lint over active docs rejects arithmetic-headline language and flat top-level `c_sigma` examples |
| AC3 — `project.tsc` removed | repo root | `test ! -e project.tsc` |
| AC4 — frozen-snapshot banners reverted | the 3 named frozen files | `git diff --` shows only banner-removal, no other semantic edits inside `docs/{tier}/{bundle}/{X.Y.Z}/` |
| AC5 — migration note in CHANGELOG | `CHANGELOG.md` | v0.10.0 row carries the note referencing #49/#50 and the pre-cutover arithmetic-aggregate incompatibility |
| AC6 — target-registry smoke tests | `engine/ocaml/test/` | new test parses `targets/registry.tsc`, resolves spec/engine/repo, parses each manifest, asserts non-empty bundles |
| AC7 — forbidden-wording CI rule (forward-only) | `scripts/check-forbidden-wording.sh` + `.github/workflows/*.yml` | newly-added `"Operational acceptance"` / `"Operationally accepted"` / `"self-coherence ACCEPT"` / `"release criteria satisfied"` outside frozen+archive paths fails CI; existing historical occurrences pass |
| AC8 — release artifacts at 0.10.0 | `VERSION`, `engine/ocaml/dune-project`, `engine/ocaml/tsc_engine.opam`, `CHANGELOG.md`, `RELEASE.md` | `scripts/check-version-consistency.sh` passes; CHANGELOG row + RELEASE.md describe the cutover and reference #49 |

## Dispatch

- **α**: separate subagent. Brief: implement #54's 8 ACs against `cycle/54` from `origin/main` post-cutover. No γ work, no β work. Commit early + often; document the "no OCaml toolchain" debt explicitly.
- **β**: separate subagent dispatched after α reports back. Brief: review per `review/SKILL.md` Phase 1 → 2a → 2b → 2c → Phase 3 verdict; CI gate (rule 3.10) deferred per γ-authorization, classify as B not D.
- **operator**: merges via PR after β APPROVED. CI runs the OCaml test suite on the PR. No direct-to-main pushes.
- **δ**: tags `v0.10.0` after #54 lands.

Two pre-known constraints from the wave-1 incident, included in α/β briefs:

1. **Session-bound git proxy 403** — subsequent pushes after the first per branch may 403; recovery is to push to a sibling branch (`cycle/54-impl`/`cycle/54-fix`/`cycle/54-review`) from the parent session, which the operator has been doing successfully.
2. **No OCaml toolchain in dispatch sandbox** — α implements but cannot run `dune build`/`dune runtest`. β classifies as B-severity `ci-status: defer to CI run`. Verification happens on the PR.

## Known constraints

- Frozen-snapshot edits (other than the named banner-revert) violate CDD §5.6. α must not edit frozen content beyond AC4.
- `VERSION` bump to `0.10.0` lands in this cycle, not earlier. Release artifacts (`CHANGELOG.md`, `RELEASE.md`) describe the full v0.10.0 cutover, citing #49 and the predecessor merges.
- After #54 merges, δ tags `v0.10.0` and writes `.cdd/unreleased/49/cdd-iteration.md` at master closure (capturing: the §1.4 dispatch breach, β rule 3.11b reviewer divergence, β@S4 rule 3.3 violation, session-bound git proxy 403 tooling gap, branch-namespace pollution).
