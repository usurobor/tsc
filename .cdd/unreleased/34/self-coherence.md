---
cycle: 34
issue: "#34"
branch: "cycle/34"
mode: "design-and-build"
disconnect: "engine release path — v0.8.x → v0.9.0 minor bump (kata progression Phase 2: kata-03 comparative engine extension + kata-04 + kata-05 content)"
date: "2026-05-12"
dispatch_configuration: "§5.2 single-session δ-as-γ via Claude Code Agent tool. γ axis grade capped at A− per the proposed §3.8 amendment (cnos #344 / cycle-36 F2 follow-on)."
self_application: "This cycle dogfoods the three protocol patches from cycle #36's follow-ons: F1 ✓ (γ peer-enumeration before scaffold — see §Gap table), F2 (γ verifies CI green on merge SHA + release workflow before close-out), F3 (parent-session quiescence during sub-agent runs)."
---

# Self-Coherence — Cycle #34

## Gap (peer-enumerated per F1 discipline)

Peer-enumeration of relevant surfaces on main `d3a1e21` (run before authoring this §Gap):

| Surface | State | Implication for #34 |
|---|---|---|
| `katas/01-glider/`, `katas/02-random-soup/` | Phase 1 katas shipped via #33 (positive + negative controls) | kata-03 references these as sub-bundles |
| `katas/README.md` | §kata.toml schema docs (id, difficulty, mode, description, prerequisites, input.files, expected.verdict, expected.score_range) | kata-03 may extend schema with `comparative.bundles`; AC5 prescribes layout-list update |
| `engine/ocaml/lib/kata.ml` | 77 lines, "Phase 1 scope: mechanical-mode only. No LLM calls." (line 6) — manifest parser only | needs extension if comparative-kata semantics live in the parser; AC6 deferred |
| `engine/ocaml/bin/main.ml::run_kata` | Line 436 — Phase 1 runner exits non-0 for `mode != "mechanical"` | kata-03 comparative runner extension lands here; AC6 LLM-mode kata recognition deferred |
| `engine/ocaml/test/test_kata.ml` | Phase 1 hermetic tests for kata-01 + kata-02 | AC4 extends with kata-03 + kata-05 tests |
| `examples/philosophical/{consciousness,emergence,free-will}.md` | **STILL ON DISK** despite #26 Python-test retirement | Raw material for kata-04 — re-authoring not required (issue #34 §Related artifacts had this wrong) |
| `QUICKSTART.md` §8 "Run katas (smoke test / regression anchors)" | Exists (line 145) | AC5 adds at least one new smoke-test invocation |
| `VERSION` | `0.8.0` (since cycle #30) | Cycle #34 bumps to `0.9.0` |
| `CHANGELOG.md` engine release ledger | Last row: 0.8.0 (cycle #30) | New row for 0.9.0 added at cycle close |
| `.github/workflows/release.yml` | Tag-triggered release; publishes `coh-linux-x64` via `softprops/action-gh-release@v2` | v0.9.0 tag will trigger; γ F2 verifies green |
| `.github/workflows/katas.yml` | From cycle #36/#38 — runs katas + uploads artifacts + step summary + publishes-binary validation | will exercise kata-03/04/05 automatically (auto-discovery glob `katas/*/`) |

**Gap reality (informed by enumeration):**

1. **Phase 1's kata progression has 2 katas (positive + negative control).** Phase 2 extends with 3 more: kata-03 (comparative ranking), kata-04 (natural-language cross-domain), kata-05 (adversarial structural-vs-semantic).
2. **Runner is mechanical-mode only.** Phase 1 explicitly blocks `mode != "mechanical"` katas. Phase 2's kata-04 mode decision determines whether AC6 (LLM-mode runner support) fires.
3. **No comparative kata semantics exist.** kata-03 requires either (a) a new "comparative" kata type that bundles sub-katas with an ordering invariant, OR (b) a simpler approach: kata-03 reuses kata-01 + kata-02 inputs, scores both, asserts ordering. γ at scaffold prefers (b) — minimal runner change.
4. **No adversarial kata exists.** kata-05's design — high surface structure + low actual coherence — needs a multi-file input where contradictions live across files, not within.
5. **Engine release ledger has accumulated since v0.8.0.** Cycles #33 + #36 + #38 added engine surface (`--kata` CLI flag, `kata.ml` module) and CI surface (artifact + step summary + published-binary validation) without version bumps. Cycle #34's engine work (comparative runner extension + 3 kata directories + test extensions) is the natural minor-bump trigger.

## Mode

`design-and-build`. Design surfaces:

- **kata-03 design call.** Option (a) new "comparative" kata-type in `kata.ml` parser + `run_kata` extension. Option (b) reuse Phase 1 mechanism: kata-03 lists `input/glider.md` and `input/random-soup.md` files; runner scores both; new `expected.ranking` field asserts ordering. **γ recommends (b)** — smaller diff, preserves Phase 1 schema, easier to add more comparative katas later.
- **kata-04 mode decision.** **γ decides MECHANICAL.** Justification: hermetic-by-default per Phase 1 constraint; kata-04 with `expected.verdict = "fail"` documents the limit of mechanical scoring on natural-language input (different failure shape than kata-05's structural-but-semantically-incoherent); avoids cycle-scope creep into AC6; LLM-mode kata-04 + AC6 (LLM-mode kata recognition) ships as a clean Phase 3 follow-on.
- **kata-05 design call.** Multi-file adversarial input across 2-3 `.md` files where structural regularity (headers, cross-refs, version stamps) is high but semantic claims contradict across files. Hand-curated.

Build surfaces: 3 kata directories + small `bin/main.ml::run_kata` extension for comparative scoring + test extensions + docs + VERSION + CHANGELOG row. Not MCA (no separate design artifact; design lives in this self-coherence document).

## Cycle scope sizing (per cnos §1.6c heuristic)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | Small runner extension (~20-40 lines in main.ml) + 3 kata dirs (toml + readme + inputs) + 2 test cases | moderate |
| (b) Cross-module breadth | `katas/` (new dirs) + `engine/ocaml/bin/main.ml` (extend) + `engine/ocaml/test/test_kata.ml` (extend) + `katas/README.md` + `QUICKSTART.md` + `VERSION` + `CHANGELOG.md` + `RELEASE.md` | moderate |
| (c) Lifecycle span | build + tests + docs + release prep | moderate |
| (d) MCA preconditions | not MCA — design fixed in this document (Option-b for kata-03; mechanical for kata-04) | n/a |
| (e) Independent shippability | kata-03 + kata-05 + tests + docs ship coherently as one engine release; kata-04 shippable independently but bundled here for one v0.9.0 release | YES — split signal flagged but γ chooses keep-whole |

**Decision: keep whole.** **5 ACs (1-5)**, **AC6 deferred** to a Phase 3 follow-on cycle. mid-upper-typical band. The 5 deliverables (kata-03 + kata-04 + kata-05 + tests + docs) cohere as a single v0.9.0 release narrative. Splitting would fragment the kata progression and force three v0.9.x releases.

**At-edge acknowledgment:** AC count is 5 (mid-typical). Risk is cycle scope creep into AC6 if kata-04's mechanical-mode design turns out to require LLM-mode for meaningful verdict. β should grade kata-04's `expected.verdict = "fail"` rationale rigorously — if α's reasoning is hand-wavy, that's a B-finding.

## Active Skills

**Tier 1a:**
- `cdd/CDD.md`
- `cdd/SKILL.md`
- `cdd/gamma/SKILL.md`

**Tier 1b:**
- `cdd/issue/SKILL.md`
- `cdd/alpha/SKILL.md`
- `cdd/beta/SKILL.md`
- `cdd/review/SKILL.md` (rule 3.13 + symmetric peer-enumeration for γ-side gap claims)
- `cdd/release/SKILL.md` (release path — VERSION + CHANGELOG ledger row + tag)
- `cdd/post-release/SKILL.md` (Step 5.6b cdd-iteration)

**Tier 2 (engineering, for α):**
- `cnos.eng/skills/eng/ocaml` (kata runner extension)
- `cnos.eng/skills/eng/test` (hermetic test extensions)
- `cnos.eng/skills/eng/writing` (kata READMEs + adversarial input authoring)

## Impact graph

```
katas/03-comparative/                NEW — kata-03 (uses kata-01 + kata-02 inputs by reference or copy)
  kata.toml                          comparative schema (input.files lists both glider + random-soup)
  README.md                          kata intent + how to run
katas/04-philosophical/              NEW — kata-04 mechanical mode, expected verdict = "fail"
  kata.toml                          mode = "mechanical", expected.verdict = "fail"
  README.md                          kata intent + mode justification
  input/.md                          short philosophical text (likely consciousness.md or emergence.md)
katas/05-adversarial/                NEW — kata-05 multi-file structural-vs-semantic adversarial
  kata.toml                          mode = "mechanical", expected.verdict = "fail"
  README.md                          kata intent + adversarial design notes
  input/{file-a,file-b,file-c}.md    multi-file adversarial input
engine/ocaml/bin/main.ml             EXTEND — run_kata gains comparative scoring + ranking check
engine/ocaml/lib/kata.ml             MAYBE EXTEND — manifest parser if comparative.ranking field added
engine/ocaml/test/test_kata.ml       EXTEND — hermetic tests for kata-03 + kata-05 (kata-04 if mechanical)
katas/README.md                      EXTEND — §Layout adds 3 new dirs; §kata.toml schema mentions ranking field
QUICKSTART.md                        EXTEND — §8 adds at least one new smoke-test invocation
VERSION                              0.8.0 → 0.9.0
CHANGELOG.md                         engine release ledger row for 0.9.0 + ### 0.9.0 section
RELEASE.md                           release-notes file for v0.9.0
```

## ACs (verbatim from issue #34, AC1-AC5)

**AC1 — kata-03 (comparative) ships.**
- *Invariant:* `katas/03-comparative/` contains `kata.toml`, `README.md`, and input references. `coh --kata 03-comparative --mode mechanical` produces a result confirming the engine ranks the glider above random-soup. Hermetic.
- *Oracle:* exit 0; output shows both sub-results + `ranking_correct: true` (or equivalent).
- *Surface:* `katas/03-comparative/`, `engine/ocaml/bin/main.ml` (small extension).

**AC2 — kata-04 (philosophical) ships.**
- *Invariant:* `katas/04-philosophical/` contains kata.toml + README + input. **Mode = mechanical (γ-decided).** Justified in kata-04's README. `coh --kata 04-philosophical --mode mechanical` exits 0 with `expected.verdict = "fail"` matched.
- *Oracle:* exit 0; result matches `expected.verdict` ("fail") and `expected.score_range`.
- *Surface:* `katas/04-philosophical/`.

**AC3 — kata-05 (adversarial) ships.**
- *Invariant:* `katas/05-adversarial/` with multi-file adversarial input. `coh --kata 05-adversarial --mode mechanical` exits 0; result.c_sigma ≤ expected.score_range.max; kata-pass (which means the mechanical scorer correctly identified the input as adversarially incoherent).
- *Oracle:* exit 0; verdict = "fail"; mechanical scorer correctly fails.
- *Surface:* `katas/05-adversarial/`.

**AC4 — tests cover kata-03 + kata-05 (+ kata-04 since mechanical).**
- *Invariant:* `engine/ocaml/test/test_kata.ml` exercises kata-03, kata-04, kata-05 hermetically. `dune runtest` exits 0; output mentions all three katas.
- *Oracle:* `cd engine/ocaml && dune runtest` exit 0.
- *Surface:* `engine/ocaml/test/test_kata.ml`.

**AC5 — docs surface the new katas.**
- *Invariant:* `katas/README.md §Layout` lists kata-03/04/05; `QUICKSTART.md §8` adds at least one new smoke-test invocation.
- *Oracle:* `grep -E "03-comparative|04-philosophical|05-adversarial" katas/README.md QUICKSTART.md` returns matches in both files.
- *Surface:* `katas/README.md`, `QUICKSTART.md`.

**AC6 (DEFERRED).** LLM-mode runner support. Not in this cycle. Phase 3 follow-on.

## Release path

Mode = `design-and-build`; disconnect via **engine-release path (NOT §2.5b)**.

After β APPROVED and merge to main:

1. α (or γ at release-prep) bumps `VERSION` from `0.8.0` to `0.9.0`
2. CHANGELOG.md gains a `### 0.9.0` section under `## Engine releases` documenting:
   - Phase 2 kata progression (kata-03 comparative + kata-04 philosophical + kata-05 adversarial)
   - Runner extension for comparative scoring
   - Test extensions
3. `CHANGELOG.md` Release Coherence Ledger gains a row for 0.9.0
4. `RELEASE.md` written with full coherence delta + validation + known issues
5. Operator (or `scripts/release.sh`) creates tag `v0.9.0` (post-merge)
6. `release.yml` workflow triggers on tag push; builds and publishes `coh-linux-x64`
7. γ F2 verification: both `katas.yml` AND `release.yml` workflows green on merge SHA + tag

**CHANGELOG row format** (per cycle #30's `scripts/release.sh` gate):

```
| Version | C_Σ | α | β | γ | Level | Rounds | Coherence note |
| 0.9.0 | <grade> | <α> | <β> | <γ> | L6 | <rounds> | Phase 2 kata progression: comparative + philosophical + adversarial. (#34, cycle: L6) |
```

## Honest-claim manifest claims (R1 must produce)

α R1 must produce `claims.md` with at minimum:

1. **Wiring:** every new kata directory's `kata.toml` is loadable by `engine/ocaml/lib/kata.ml::load` (verify via `coh --kata <id>` exit-status check)
2. **Source-of-truth alignment:** new schema fields (if any — `expected.ranking` for kata-03) documented in `katas/README.md §kata.toml schema`; kata.toml uses only fields present in the documented schema
3. **Reproducibility:** every kata's expected score range is a defensible empirical claim — α records the actual c_sigma observed in a comment near the `expected.score_range` block (or in the kata's README)
4. **No false negation:** §Gap claim that `kata.ml` is "Phase 1 scope: mechanical-mode only" is grep-verifiable on `d3a1e21` pre-cycle
5. **kata-04 mode justification:** the README for kata-04 contains explicit justification for the mechanical-mode choice (γ decided; α records the reasoning)

## CDD Trace

1. **Receive** — γ peer-enumerated katas/ + engine/ocaml/{lib/kata.ml,bin/main.ml} BEFORE authoring §Gap (F1 self-application). Result: enumerated table at §Gap.
2. **Dispatch α** — Agent tool, fresh context. α reads issue #34, verifies γ's peer-enumeration, implements ACs 1-5 (AC6 deferred per γ scaffold decision), prepares release artifacts.
3. **α self-coherence + claims.md + readiness signal.**
4. **Dispatch β** — Agent tool, fresh context. β applies rule 3.13 + grades kata-04 mode-decision rigor.
5. **Fix rounds if any.**
6. **Merge** — `cycle/34-impl` → `main` via PR.
7. **VERSION bump + CHANGELOG row + RELEASE.md** — α (or γ at release-prep) commits these.
8. **Tag v0.9.0** — operator action via `scripts/release.sh` or git tag.
9. **γ F2 verification** — poll both `katas.yml` AND `release.yml` workflows on merge SHA + tag. **BLOCK close-out until both green.**
10. **γ close-out** — only after F2 verification confirms green.
11. **cdd-iteration** — capture any new findings; record F1/F2/F3 self-application status.

## Dispatch configuration

- **Operator δ = γ** (single-session via Agent tool — §5.2)
- **Identities:** `{alpha,beta,gamma}@tsc.cdd.cnos`
- **γ axis grade cap:** A− (per §5.2 amendment)

**F1/F2/F3 self-application gate:**

| Patch | Self-application | Pass/fail criterion |
|---|---|---|
| F1 | §Gap peer-enumeration table at top of this scaffold | ✓ |
| F2 | Poll katas.yml AND release.yml on merge + tag before close-out | TBD at close |
| F3 | Parent session quiescent during α/β sub-agent runs; stop-hook resistance honored | TBD at close |

## Head SHA

(to be filled in α R1 readiness signal)
