# self-coherence.md — cycle/53

Sub-issue: #53 — S4: cross-target report surface (Operational §7.4)
Master: #49 (v0.10.0 canonical v3.2 cutover wave)
Mode: design-and-build
Cycle branch: `cycle/53`
Author (α-leg of δ-as-γ): gamma <gamma@tsc.cdd.cnos>

## 1. Gap statement

What exists: `engine/ocaml/bin/main.ml` accepts exactly one `--target <name>` via `Arg.Set_string` and produces one mechanical / LLM / hybrid report. Operators who want `spec`, `engine`, and `repo` together run three commands and aggregate offline by hand.

What is expected: `spec/tsc-oper.md` §7.4 defines a canonical **cross-target aggregate** as the geometric mean of per-target `C_Σ` values, with provenance listing the constituent targets. This is reporting-only — verdict logic is unchanged.

Where they diverge: the engine has no multi-target CLI request and no canonical report shape that records the cross-target calculation. Self-application of the v3.2 series across multiple targets cannot be reproduced from the engine alone.

## 2. Mode and scope

Mode: design-and-build (one small surface; design embedded in issue + this file).
Scope: additive only — single-target reports, mechanical scoring path, and verdict logic untouched.

## 3. Precondition disposition

#53 depends on #50 (canonical `C_sigma_num` / `C_sigma_math` fields on per-target result). #50 is in flight on `cycle/50`; #53's dispatch chose **Option (b)** from the dispatch brief: derive `C_sigma_num`/`C_sigma_math` inline from `Coherence.aggregate` over the (α, β, γ) axes returned by `Mechanical_scoring.score_bundle`. This avoids any dependency on #50's result-type shape while still computing the canonical Operational §7.4 values.

When #50 lands on main, a small rebase will route the per-target `C_sigma_num`/`C_sigma_math` through the canonical result fields instead of the inline `Coherence.aggregate` call — the cross-target math and the emitted JSON shape do not change.

## 4. Skills loaded

- Tier 1: `CDD.md` (canonical, fetched from origin/main).
- Tier 2: `gamma/SKILL.md`, `alpha/SKILL.md` (single-session δ-as-γ + α).
- Tier 3 (per issue): `cnos.eng/skills/eng/ocaml` — referenced; no OCaml toolchain in this environment (known debt; see §8).

## 5. AC mapping (filled per commit)

| AC | What | Surface | Evidence |
|---|---|---|---|
| AC1 | `--target` repeatable; multi-mode rejected | `engine/ocaml/bin/main.ml` | (pending commit) |
| AC2 | Each target uses existing mechanical path; per-target inline in `targets[]` | `engine/ocaml/lib/cross_target.ml`, `engine/ocaml/bin/main.ml` | (pending commit) |
| AC3 | Geometric-mean aggregate; math=0 on any zero-component | `engine/ocaml/lib/cross_target.ml` + test | (pending commit) |
| AC4 | JSON shape with `kind`, `schema_version`, `targets[]`, `provenance.cross_target_aggregate` | `engine/ocaml/lib/cross_target.ml` + test | (pending commit) |

## 6. Role self-check (α-leg)

- [ ] All four ACs have evidence on the branch.
- [ ] Tests added for AC3 (geometric mean) and AC4 (JSON shape) — see §8 for environment constraint.
- [ ] Single-target behavior preserved (one `--target` -> existing dispatch unchanged).
- [ ] No verdict / threshold introduced (reporting-only).
- [ ] Provenance lists every constituent target id.

## 7. Known debt

- `--mode llm` / `--mode hybrid` / effective `auto` with multiple targets exit non-zero with a clear "mechanical-only this cycle" message — future work would extend this surface to LLM/hybrid (see #53 non-goals).
- Partial-failure recovery is deferred — a per-target failure fails the whole run (issue §Deferred).
- Cross-target OOD baselines and kata-runner cross-target support are out of scope.

## 8. Toolchain constraint

This worktree has **no OCaml toolchain available** (`opam`, `dune`, `ocaml` not on PATH). All code is written against the inferred type signatures of existing modules (`Coherence.aggregate`, `Mechanical_scoring.score_bundle`, `Bundle.build_bundle`, `Target_registry`, `Yojson.Safe`). Tests are authored in the same style as `engine/ocaml/test/test_coherence.ml` so that a downstream β with a working `dune` install can run `dune runtest` and validate AC3/AC4. This is recorded explicitly as known debt and is the same constraint that applied to prior cycles in this wave.

## 9. CDD trace

- Step 1 (observation): #49 round-3 contract identified the cross-target reporting gap.
- Step 2 (selection): γ chose #53 as a P2 surface that ships independently of #50 via Option (b).
- Step 3 (issue): #53 written by γ on main with 4 ACs and explicit mechanical-only scope.
- Step 4 (dispatch): single-session δ-as-γ — this artifact and code commits.
- Step 5 (review): β R1 pending.
- Step 6 (merge): pending β.
- Step 7 (close-out): `gamma-closeout.md` to follow.

## 10. Environment incident note (recorded for β)

During phase-2 startup, the initial `Bash`-tool calls executed with cwd `/home/user/tsc` (the main repo on a different cycle branch) rather than the worktree at `/home/user/tsc/.claude/worktrees/agent-a9b8589ff66f1bbcb`. A first commit (`cab6787`, since dropped via `git reset --hard HEAD~1`) landed on `cycle/51` and was reverted in-session; the unreleased/53 scaffold and `cross_target.ml` were the only artifacts written and they have been re-created here on the correct branch. No content was pushed to `origin/cycle/51` or to any cycle other than #53. Recorded so β can trace this branch's history without confusion.
