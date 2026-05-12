---
cycle: 34
issue: "#34"
branch: "cycle/34-impl"
reviewer: beta
review_round: R1
alpha_head_sha: e298e40
scaffold_sha: d9d144a
parent_main_sha: d3a1e21
date: "2026-05-12"
verdict: APPROVED
findings:
  A: 0
  B: 0
  C: 4
---

# β R1 — Cycle #34 review (Engine katas Phase 2)

## Verdict: **APPROVED**

Per cdd §3.3: A=0, B=0, C-only → APPROVED. Findings below are advisory.

## Branch state

- Reviewed branch: `cycle/34-impl`
- α R1 head: `e298e40` (meta-commit recording R1 SHA)
- Scaffold: `d9d144a` (γ)
- Parent main: `d3a1e21`
- Diff: 25 files, +1826 / -101 lines, 9 commits since scaffold

Note: there is **no `.cdd/unreleased/34/alpha-closeout.md` file**. α's R1 closeout was instead captured in (a) commit `1643569` ("α R1 closeout + honest-claim manifest") which added `claims.md`, and (b) the §Head-SHA block appended to `self-coherence.md` via commit `e298e40`. This is a minor convention drift from the standard "alpha-closeout.md" artifact pattern, but the substantive closeout content (per-commit map, claims manifest, head SHA) is all present and verifiable. **Filing as C-1 below.**

---

## Phase 1 — Contract integrity

### Diff vs γ's impact graph

| γ-scaffold §"Impact graph" item | Diff has it? | Notes |
|---|---|---|
| `katas/03-comparative/{kata.toml,README.md}` + inputs | ✓ | Inputs in `input/glider/` + `input/random-soup/` (per-component sub-dirs) |
| `katas/04-philosophical/{kata.toml,README.md,input/.md}` | ✓ | `input/consciousness.md` (verbatim copy of `examples/philosophical/consciousness.md`) |
| `katas/05-adversarial/{kata.toml,README.md,input/{a,b,c}.md}` | ✓ | 3 sibling files `spec-a.md`, `spec-b.md`, `spec-c.md` |
| `engine/ocaml/bin/main.ml::run_kata` extension | ✓ | +136 lines (helper extraction + comparative branch); single-bundle path semantically unchanged |
| `engine/ocaml/lib/kata.ml` extension for components+ranking | ✓ | +55 lines (new `kata_component` type, optional `components`/`ranking` fields, otoml parsing) |
| `engine/ocaml/test/test_kata.ml` extension | ✓ | +134 lines, +25 PASS assertions |
| `katas/README.md` §Layout + schema | ✓ | §"Current katas" table; `[[components]]` + `ranking` rows + §"Comparative katas (Phase 2)" |
| `QUICKSTART.md §8` smoke-tests | ✓ | kata-03/04/05 invocations added |
| `VERSION 0.8.0 → 0.9.0` | ✓ | Plus `dune-project`, `tsc_engine.opam` |
| `CHANGELOG.md` ledger row + `### 0.9.0` section | ✓ | Row + 30-line section |
| `RELEASE.md` | ✓ | Full coherence-delta narrative with (TBD) placeholders for γ |

**Diff matches impact graph fully.** No scope drift.

### Phase 1 schema preserved?

`engine/ocaml/lib/kata.ml::kata_config` — pre-cycle fields (id, difficulty, mode, description, input_files, verdict, score_min, score_max) are all **still present, same types**. Two new fields appended: `components : kata_component list` (default `[]`) and `ranking : string list` (default `[]`). Strictly additive. Phase 1 katas that omit these load with empty lists, exercise the single-bundle path identically to pre-cycle.

### Phase 1 katas still parse + run?

Empirically reproduced on host (dune 3.14.0, OCaml 5.x):

```
$ engine/ocaml/_build/default/bin/main.exe --kata 01-glider --mode mechanical --root .
KATA PASS: '01-glider' — c_sigma=0.9233 within expected range [0.8700, 1.0000] for verdict 'pass'

$ engine/ocaml/_build/default/bin/main.exe --kata 02-random-soup --mode mechanical --root .
KATA PASS: '02-random-soup' — c_sigma=0.6888 within expected range [0.0000, 0.7400] for verdict 'fail'
```

Both exit 0; scores match pre-cycle Phase 1 calibration. Backward compat **PRESERVED**.

---

## Phase 2 — AC walk (5 ACs)

### AC1 — kata-03 (comparative) ships

| Sub-claim | Status | Evidence |
|---|---|---|
| `katas/03-comparative/{kata.toml,README.md}` exist | ✓ | files present in tree |
| `[[components]]` schema correct (id + files per entry) | ✓ | 2 entries (glider, random-soup) per kata.toml lines 15-21 |
| Runner consumes `kata.components` non-emptiness as comparative trigger | ✓ | `bin/main.ml:488` `if kata.components <> []` |
| `coh --kata 03-comparative --mode mechanical` exits 0 | ✓ | empirically reproduced; `KATA PASS: '03-comparative' — ranking glider>random-soup matches expected` |
| `ranking_correct: true` in result JSON | ✓ | `"ranking_correct": true` emitted at `bin/main.ml:529` |
| Hermetic (no LLM_API_KEY required) | ✓ | mechanical-only runner; no provider calls |

**Inputs reference vs copy.** α copied kata-01 and kata-02 inputs into `katas/03-comparative/input/{glider,random-soup}/` rather than referencing the originals. Verified via `diff -q`:
- `katas/01-glider/input/glider.md` ≡ `katas/03-comparative/input/glider/glider.md`
- `katas/02-random-soup/input/random-soup.md` ≡ `katas/03-comparative/input/random-soup/random-soup.md`

This is the **right call** for this cycle: the README explicitly documents the trade-off (kata's `Bundle.build_bundle` joins file paths to the kata's own directory; `../01-glider/input/glider.md` would break the bundle's path canonicalisation). Hermeticity beats duplication cost given the inputs are ≈8 KB combined. The README also commits to keeping copies in sync if the canonical Phase 1 inputs change.

**Verdict: AC1 PASS.** Comparative ranking semantics are correctly implemented: scoring each component as its own bundle, sorting by C_Σ high→low, asserting observed ordering matches `expected.ranking`. Observed margin 0.9233 vs 0.6888 ≈ 0.234, well above any plausible noise.

### AC2 — kata-04 (philosophical) ships with justified mechanical mode

| Sub-claim | Status | Evidence |
|---|---|---|
| `katas/04-philosophical/{kata.toml,README.md,input/}` exist | ✓ | files present; input is verbatim copy of `examples/philosophical/consciousness.md` |
| Mode = `mechanical` | ✓ | kata.toml line 3 |
| README has EXPLICIT mode-choice justification | ✓ | §"Mode justification (required per cycle #34 active design constraint)" — 4 numbered points |
| Justification load-bearing (not hand-wavy) | **see below** | mixed — see C-2 |
| `coh --kata 04-philosophical --mode mechanical` exits 0 with verdict=fail matched | ✓ | observed c_sigma=0.9333 ≤ score_max=0.95; runner emits `KATA PASS` |
| Observed c_sigma within range [0.0, 0.95] | ✓ | 0.9333 < 0.95 |

**Investigation: kata-04 verdict semantics.** The user's review prompt flagged this as the most subtle AC. Detailed analysis:

The runner's `verdict="fail"` gate is `c_sigma <= score_max` (`bin/main.ml:564-566`). With `score_max=0.95` and observed `c_sigma=0.9333`, the gate passes with a 0.0167 margin (1.67%). The gate would also pass for *virtually any* c_sigma below 0.95 — i.e., the kata's protocol-level assertion is permissive.

Is this "the engine isn't identifying its limit; it's confidently scoring something it shouldn't be confident about"? **Yes — and that is exactly what the kata is documenting.** The kata.toml comment (lines 22-25) and README §"Observed C_Σ (calibration)" both state explicitly that the wide range is intentional documentation: mechanical scoring cannot discriminate this input from a well-structured engineering doc. The README's load-bearing claim (point 4 of §"Mode justification"): *"The `expected.verdict = 'fail'` is the load-bearing claim. It records the semantic judgement... The numerical `score_range` brackets the mechanical observation, which disagrees. The disagreement is the lesson."*

The kata's structure is: **documentation kata, not assertion kata.** The protocol-level gate is loose (`c_sigma <= 0.95`); the load-bearing content is the README + score_range comments. The hermetic test exercises the README claims (assertions about "Mode justification", "mechanical", "hermetic"|"credentials" strings) — so the documentation IS tested.

**Verdict: AC2 PASS.** The kata-04 design is internally consistent, the README justification is load-bearing for the documentation kata, and the test surface verifies the documentation. **However** — the kata could be tightened: with score_max=0.95 and observed 0.9333, virtually any mechanical-scorer output between 0 and 0.95 would still pass the kata. A tighter `score_max=0.94` (bracketing the observed value within ±0.01) would make the kata more discriminating without breaking its documentation function. **Filing as C-2 below** — advisory, not blocking.

### AC3 — kata-05 (adversarial) ships

| Sub-claim | Status | Evidence |
|---|---|---|
| `katas/05-adversarial/` exists | ✓ | files present |
| Multi-file input ≥ 2 .md files | ✓ | 3 files: spec-a.md, spec-b.md, spec-c.md |
| Adversarial design: high structural regularity + cross-file semantic contradiction | ✓ | Verified by reading: same heading scheme (`§1 Scope`, `§2 Core invariant`, etc.); same version stamp (`v2.3.1`); same "supersedes" language. Each declares itself canonical with different transport (UDP/TCP/QUIC). |
| Mechanical mode + `verdict=fail` | ✓ | kata.toml line 3, 22-23 |
| `coh --kata 05-adversarial --mode mechanical` exits 0 | ✓ | empirically: `KATA PASS: '05-adversarial' — c_sigma=0.7466 within expected range [0.0000, 0.7800]` |
| c_sigma within range [0.0, 0.78] | ✓ | 0.7466 < 0.78 |

**Thin-margin assessment** (user flagged in review prompt). Margin = 0.78 - 0.7466 = 0.0334 (3.34%).

**Defensibility analysis:**

- Margin is **2× wider** than kata-04's 1.67%, so it's not the tightest gate in the cycle.
- α's calibration explicitly says: "bracketed just above the observed value to keep the kata green without being trivially permissive." This is a deliberate calibration choice.
- The kata's design intent (per README §"Why this kata matters") explicitly **expects** the kata to eventually fail as the mechanical scorer learns to detect the adversarial pattern — the "moving frontier" claim. So thinness here is a *feature*, not a bug: it makes the kata sensitive to scorer refinements.
- However: scorer refinements can move c_sigma in either direction. If a future α-axis refinement *raises* c_sigma above 0.78 (without actually improving adversarial-robustness), kata-05 fails for a non-substantive reason. The README acknowledges this and provides the remediation path (harden the adversarial input).

**Assessment: defensible** but at the lower end of what β would accept. A more conservative score_max of 0.80–0.82 would give 0.05–0.07 buffer. **Acceptable — not blocking, not even C-severity by itself.** The README's explicit documentation of the "moving frontier" intent is what makes this defensible: if kata-05 fails post-release on a scorer refinement, the failure mode is *documented* and the response procedure is *documented*. That's the protocol working as intended.

**Verdict: AC3 PASS.**

### AC4 — hermetic tests

| Sub-claim | Status | Evidence |
|---|---|---|
| Test count delta = +25 | ✓ | Verified empirically: baseline (origin/main + minimum dune fix) = 146 PASS lines; cycle HEAD = 171 PASS lines; delta = 25 |
| Tests cover kata-03/04/05 | ✓ | 28 kata-03/04/05 PASS lines in test output; 6 config checks + 1 README-OK each = 21 + 7 informational "loaded OK" / "README OK" = 28 |
| All hermetic (no LLM_API_KEY required) | ✓ | All tests call `Kata.load` or `read_text` only; no provider calls; comment at test header confirms hermeticity |
| `dune runtest --force` exits 0 | ✓ | Reproduced on host |

**Baseline verification methodology.** Cloned origin/main into /tmp/, manually applied the minimum `(modules ...)` dune fix (required by dune 3.14+ — verified that without it, `dune build` fails with "you must specify an explicit modules field"), preserved the original `test_kata.ml`, and ran `dune runtest --force`: result = 146 PASS lines. Reverting to cycle HEAD: 171 PASS lines. Delta = 25. **α's claim is exact.**

**Verdict: AC4 PASS.**

### AC5 — docs surface new katas

| Sub-claim | Status | Evidence |
|---|---|---|
| `katas/README.md §Layout` lists all 3 new dirs | ✓ | §"Current katas" table has rows for `03-comparative`, `04-philosophical`, `05-adversarial` |
| `QUICKSTART.md §8` adds at least one new smoke-test invocation | ✓ | 3 new invocations (kata-03, kata-04, kata-05) added at lines 158-166 |
| New schema fields documented in `katas/README.md` | ✓ | `[[components]]`, `[[components]].id`, `[[components]].files`, `[expected].ranking` all appear in §"kata.toml schema", §"Field reference", §"Field index", and §"Comparative katas (Phase 2)" |
| AC5 oracle | ✓ | `grep -E "03-comparative\|04-philosophical\|05-adversarial" katas/README.md QUICKSTART.md` returns 7 matches across both files |

**Verdict: AC5 PASS.**

---

## Phase 3 — Rule 3.13 honest-claim verification

For each claim in `claims.md`:

### Claim 1 — Wiring

- **(a) reproducibility:** `dune runtest --force | grep -E "kata-0[345]"` → 12 PASS lines on host. **Reproduced. ✓**
- **(b) source-of-truth alignment:** Each kata's `kata.toml` uses only fields in `katas/README.md §"kata.toml schema"`. Verified by manual cross-reference. **✓**
- **(c) wiring grep-verified:** `engine/ocaml/bin/main.ml::run_kata` branches on `kata.components`; `Kata.load` parses both `[[components]]` and `[expected].ranking`. **✓**

### Claim 2 — Source-of-truth alignment

- **(a) reproducibility:** `grep -nE "components|ranking" katas/README.md` returns hits in §"kata.toml schema" (lines 56-74), §"Field reference" (lines 87-91), §"Field index" (lines 117, 119), §"Comparative katas (Phase 2)" (lines 96-104). **✓**
- **(b) source-of-truth:** All new fields documented before use. **✓**
- **(c) wiring:** Field names in `kata.toml` exactly match documented names (`components.id`, `components.files`, `expected.ranking`). **✓**

### Claim 3 — Reproducibility

Reproduction recipe given in claims.md:
```
engine/ocaml/_build/default/bin/main.exe --kata 03-comparative --mode mechanical --root .
engine/ocaml/_build/default/bin/main.exe --kata 04-philosophical --mode mechanical --root .
engine/ocaml/_build/default/bin/main.exe --kata 05-adversarial --mode mechanical --root .
```

Reproduced on host:
- kata-03: ranking_correct=true, glider=0.9233, random-soup=0.6888 (α reports 0.6889 — rounding difference at the 4th decimal; not material)
- kata-04: c_sigma=0.9333 (matches α's claim exactly)
- kata-05: c_sigma=0.7466 (matches α's claim exactly)

All three exit 0. **Reproducibility verified. ✓**

### Claim 4 — No false negation

α claims `git show d3a1e21:engine/ocaml/lib/kata.ml | grep -n "Phase 1 scope: mechanical-mode only"` returns line 6. Reproduced:

```
$ git show d3a1e21:engine/ocaml/lib/kata.ml | grep -n "Phase 1 scope: mechanical-mode only"
6:    Phase 1 scope: mechanical-mode only. No LLM calls. *)
```

**Exact match. ✓**

### Claim 5 — kata-04 mode justification

README has §"Mode justification (required per cycle #34 active design constraint)" with 4 numbered points. Tested via `test_kata.ml` lines 202-210 (3 assertions: "Mode justification" present, "mechanical" mentioned, "hermetic"|"credentials" mentioned). All 3 pass. **✓**

**All five claims verified per rule 3.13.**

---

## Special-attention-area summary (from review prompt)

### kata-04 verdict semantics — load-bearing or hand-wavy?

**Load-bearing for the documentation kata, but the protocol-level assertion is loose.** The README's mode-justification text (4 numbered points) IS substantive and load-bearing for *what the kata documents*. However, the runner's pass-gate (`c_sigma <= 0.95`) is permissive enough that the kata could pass even if the mechanical scorer's behavior on philosophical text changed substantively. The kata is honest about this (kata.toml comment + README §"Observed C_Σ" both explain). **Acceptable as a documentation kata; could be tightened in a future cycle (C-2 advisory below).**

### kata-05 thin margin — acceptable or flag?

**Acceptable.** Margin = 3.34%, deliberately calibrated, README explicitly documents the "moving frontier" intent. The kata is *designed* to be sensitive to scorer refinements. If a future cycle wants more buffer, raising max to 0.80–0.82 would be defensible — but the README's documentation makes the current calibration honest.

### AC1 comparative semantics — correctly implemented?

**Yes.** Each component scored as its own `Bundle.t`, sorted by c_sigma high→low, observed ranking compared to `expected.ranking`. The runner emits `expected_ranking`, `actual_ranking`, and `ranking_correct: bool` in the result JSON. The comparative path correctly bypasses the verdict/score_range gate (which is replaced by the ranking check). Verified by inspection AND empirically.

### Phase 1 backward-compat — preserved or regressed?

**Preserved.** Schema is strictly additive (no fields removed/renamed; new fields default to empty lists). Single-bundle code path (`bin/main.ml:543-593`) is semantically unchanged — refactored only by extracting the file-loader to a helper. Empirically reproduced: kata-01 c_sigma=0.9233 and kata-02 c_sigma=0.6888 match Phase 1 baseline.

### `engine/ocaml/test/dune` `(modules ...)` stanza — justified or scope-creep?

**Justified.** Empirically confirmed: on origin/main with dune 3.14.0, `dune build` fails with:

```
test/dune:9
To fix this error, you must specify an explicit "modules" field in every
library, executable, and executables stanzas in this dune file. Note that
each module cannot appear in more than one "modules" field - it must belong
to a single library or executable.
```

α's fix is the minimum required change (one `(modules ...)` line per test stanza); no behavioral change. CHANGELOG correctly notes "required by dune ≥ 3.14 for multi-test files" under §Changed. **Necessary, not scope-creep.**

### VERSION + dune-project + tsc_engine.opam coherence

All three bumped to `0.9.0` consistently:
- `VERSION`: `0.9.0`
- `engine/ocaml/dune-project`: `(version 0.9.0)`
- `engine/ocaml/tsc_engine.opam`: `version: "0.9.0"`

**Coherent. ✓**

### CHANGELOG row format

`scripts/release.sh` gate (line 73): `grep -q "^| $VERSION |" "$CHANGELOG"` — checks **format/presence only**, not value-non-TBD. The row at CHANGELOG.md:37 reads:

```
| 0.9.0 | (TBD) | (TBD) | (TBD) | (TBD) | L6 | Phase 2 kata progression: ... |
```

7 columns matching the actual ledger header `| Version | C_Σ | α | β | γ | Level | Note |`. **Note:** γ's scaffold (line 157-159) mentions an 8-column format `| Version | C_Σ | α | β | γ | Level | Rounds | Coherence note |`, but the *actual* CHANGELOG ledger schema in the repo is 7 columns (no "Rounds" column). The row added by α matches the actual ledger schema, not γ's scaffold description. **Gate would pass. ✓** (γ's scaffold-text description of the row format is inaccurate; α's row matches reality.)

### RELEASE.md placeholders

`(TBD)` for grades + `PENDING` for merge commit / branch-merged. **Correct separation of concerns:** α at R1 cannot know the merge SHA (merge happens *after* β review) nor the grades (γ at close-out assigns axis grades after CI verification). The placeholders are explicitly marked "PENDING — γ fills at release-prep" (RELEASE.md line 6). **Correct convention. ✓**

---

## Findings

### A (critical): none

### B (binding): none

### C (advisory):

**C-1: Missing `alpha-closeout.md` artifact.** Standard cycle convention is a separate `alpha-closeout.md` file under `.cdd/unreleased/<n>/`. Cycle #34 instead embeds the closeout into `claims.md` (commit `1643569` message: "α R1 closeout + honest-claim manifest") and `self-coherence.md §Head SHA` (commit `e298e40`). The substantive content (per-commit map, claims manifest, head SHA) is all present and verifiable, but the artifact-naming convention drifts. **Not blocking;** flag for cdd-iteration consideration whether convention should be tightened.

**C-2: kata-04 score_max=0.95 is permissively wide.** With observed c_sigma=0.9333, the gate `c_sigma <= 0.95` would pass for nearly any mechanical-scorer output. The kata's design is documentation-first (load-bearing claim lives in README + score_range comments, which IS tested), but as a protocol-level assertion the gate is loose. **Consider tightening to score_max=0.94 in a future cycle** (preserves the documentation function while making the kata more discriminating). Already noted as known debt in CHANGELOG §0.9.0 Known debt — visibility is good.

**C-3: kata-03 comparative branch emits `expected_verdict` field but does not consult it for pass/fail.** The comparative branch (`bin/main.ml:526`) emits `"expected_verdict": kata.verdict` in the result JSON, but the pass/fail decision is made entirely on `ranking_correct`. The README §"Comparative katas" documents this ("ranking_correct: bool in the result JSON in place of kata_pass"). For symmetry, the runner could either (a) log a warning if `kata.verdict` is set in a comparative kata, or (b) drop the field from comparative-kata output JSON. Pure-additive output makes consumers' lives easier, so the current "emit-but-don't-consult" pattern is defensible. **Advisory only.**

**C-4: Scaffold ledger format mismatch.** γ's scaffold §"Release path" (lines 157-159) prescribes an 8-column ledger row format with a "Rounds" column. The actual CHANGELOG ledger schema is 7-column (no "Rounds"). α correctly authored a 7-column row matching reality. The mismatch is in γ's scaffold text. Filing for visibility — γ may want to correct the scaffold description in a future cycle or update the actual ledger to add a Rounds column.

---

## Test plan executed

- [x] `git fetch origin cycle/34-impl && git checkout cycle/34-impl` — done
- [x] Read `self-coherence.md`, `claims.md` (no `alpha-closeout.md` exists — noted)
- [x] `git diff origin/main..origin/cycle/34-impl --stat` — 25 files, +1826/-101
- [x] Read `engine/ocaml/bin/main.ml` (full file) — verified Phase 1 path semantically unchanged
- [x] Read `engine/ocaml/lib/kata.ml` — verified strictly additive schema
- [x] Read all 3 new kata directories — verified completeness
- [x] Read `engine/ocaml/test/test_kata.ml` — verified +25 assertions cover kata-03/04/05
- [x] Read `VERSION`, `dune-project`, `tsc_engine.opam`, `CHANGELOG.md`, `RELEASE.md` — verified coherence
- [x] `dune build && dune runtest --force` on cycle HEAD — exit 0, 171 PASS
- [x] Baseline verification: cloned origin/main into /tmp/, applied minimum dune fix, ran tests → 146 PASS confirmed
- [x] Empirical kata runs: kata-01 through kata-05 — all exit 0, scores match α's claims
- [x] Verified kata-03 inputs are verbatim copies of kata-01 + kata-02 inputs
- [x] Verified kata-04 input is verbatim copy of `examples/philosophical/consciousness.md`
- [x] Read issue #34 body via `mcp__github__issue_read` — verified ACs match scaffold
- [x] Verified Claim 4 (no false negation) by running α's grep recipe on `d3a1e21`
- [x] Verified release.sh gate logic — `(TBD)` values acceptable per gate

## Recommendation

**APPROVED.** No blocking findings. 4 C-severity advisories (none gating merge). γ may proceed to merge `cycle/34-impl` → `main`, then VERSION/CHANGELOG/RELEASE finalization + `v0.9.0` tag, then F2 verification (poll `katas.yml` + `release.yml` green on merge SHA + tag), then close-out.

## Beta identity

```
git config --local user.name "beta"
git config --local user.email "beta@tsc.cdd.cnos"
```
