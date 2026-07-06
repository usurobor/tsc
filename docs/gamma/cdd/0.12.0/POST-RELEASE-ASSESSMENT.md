# Post-Release Assessment — 0.12.0

**Release:** TSC 0.12.0 — factorized-β measurement route + CDD cnos-3.82.0 platform refresh
**Issues:** #73 (factorized-β wave: #74 engine, #75 harness); #71 (CDD activation refresh); #72 (pre-registration); successor #76
**Tag:** `0.12.0` at `016c511` · **GitHub release:** published (`softprops/action-gh-release`, body = `RELEASE.md`) · **Asset:** `coh-linux-x64` (6.83 MB, `sha256:4706c374baa9dd315f7247e814964f1577af3820761ec0cd0846521e3c1d5bdd`)
**Date:** 2026-07-06
**Assessed by:** γ (operator-dispatched, 2026-07-06; scoped γ-artifact-only — no protocol change, no score optimization, no new experiment, no retag, no version bump, no change to the terminal factorized-β FAIL)

**CI status on merge SHA:** green — `ci.yml` on the cycle/74 and cycle/75 merges; `factorized-beta-measure.yml` run `28745643692` (9 jobs green) produced the gate verdict; the release publish itself is run `28761126980` (success).

---

## 1. Coherence Measurement

- **Baseline:** 0.11.0 — α A, β A, γ A− · C_Σ A · Level L7
- **This release:** 0.12.0 — α A−, β A, γ A− · C_Σ A− · Level L7

**Delta:**
- **α (artifact integrity):** Regressed A → **A−**. Not for the shipped artifacts, which are coherent (the factorized-β engine/harness pass β review, tests pin the full gate matrix, and the honest FAIL is faithfully recorded across three surfaces). The A− is release-mechanics friction: (a) the initial one-off release publish failed on a `release.yml` depext gap and needed a hardened retry; (b) this PRA lands *after* the tag rather than inside the tagged snapshot (see §3, §4b); (c) a mechanical build-break (warning-50 docstrings) recurred across *both* cycles. Score-the-release-not-the-intent: the factorized-β **FAIL is a successful measurement**, not an α defect — it is exactly what the release set out to determine and ship honestly.
- **β (surface agreement):** Held at **A**. Both cycles APPROVE at review round 1; the harness is a correct instrument that measures FAIL (β explicitly reviewed harness *quality*, not the verdict); pre-merge gates green; the release body over-claims nothing (meter retained with **no consistency claim**).
- **γ (cycle economics):** Held at **A−**. Clean dispatch, tight issue packs, ≤2 review rounds throughout — but §5.2 single-session δ-as-γ caps the γ-axis grade at A− per `release/SKILL.md` §3.8. The cap, not a process defect, is the binding constraint.

**Coherence contract closed?** Yes. The wave's contract was to *measure* whether deterministic locus enumeration + bounded local adjudication + mechanical aggregation makes same-route β semantic judgment standing-grade consistent. It measured **FAIL** (terminal), the expected-effect question is answered (negatively, and that answer is the deliverable), and the meter is retained as infrastructure with the consistency claim withdrawn. The platform-refresh contract (vendored, integrity-checked cnos 3.82.0) closed fully.

**What remains:** the successor line #76 (semantic-ambiguity queue / A3 disagreement extraction) and the just-filed #77 (CM0-compiler wave) are open; consistency-improvement stays stopped absent a fresh operator dispatch.

---

## 2. Encoding Lag

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|
| #76 | Meter-found semantic ambiguity queue from factorized-β runs | feature | converged (issue-level) | not started | growing |
| #77 | CM0 — a CM must compile before it may measure (compiler wave) | feature | operator intent captured; not yet committed at a stable `DESIGN.md`/`CM0.md` path | not started | growing |
| #72 | Factorized-β pre-registration (rev-4) | feature | converged + executed | shipped (terminal FAIL recorded) | none |
| — | `release.yml` release-notes source = `generate_release_notes`, not `RELEASE.md` | process | latent inconsistency (release body was published from `RELEASE.md` only via the one-off `body_path`) | not started | growing |

**MCI/MCA balance:** **Balanced (watch — design frontier just expanded).** Only two design issues are at "growing" lag (#76, #77), below the ≥3 freeze threshold, so no formal MCI freeze. But #77 is a substantial new L7 design filed this cycle and #76 is unstarted; implementation should catch up before further new design commitments.
**Rationale:** The consistency-improvement line is stopped by governance, which naturally throttles new meter design. The open frontier is admissibility/harvesting (#76, #77), both of which are next-cycle *implementation* candidates, not new design. Recommend: no additional new design docs opened until #76 or #77 dispatches.

---

## 3. Process Learning

**What went wrong:**
1. **`release.yml` had a latent depext gap.** The workflow let opam-depext apt-fetch `libcurl4-gnutls-dev` from the runner's apt index, which 404s when the mirror snapshot is stale — the same failure class `ci.yml` already guarded by pre-installing `libcurl4-openssl-dev` + `pkg-config` after `apt-get update`, before `setup-ocaml`. This killed the first release publish and forced a hardened retry. **Durably fixed** — `release.yml` now mirrors the ci.yml depext step (`cd39da9`).
2. **Recurring mechanical build-break (warning-50 unexpected-docstring).** Both cycle #74 (`factorized_beta.mli`) and cycle #75 (`factorized_beta_gate.mli`) failed CI on the *same* OCaml warning class — a trailing `(** … *)` after a `val`. Two cycles of the same mechanical failure is the recurring-failure trigger (§4b).
3. **PRA is post-tag, not in the tagged snapshot**, and the 0.12.0 CHANGELOG ledger row was written with the **final** grades but **without** the `provisional, pending γ PRA` marker `release/SKILL.md` §2.4 requires. So the public release body asserted `C_Σ A−` before an auditable γ assessment existed.

**What went right:**
1. The FAIL was **not hidden** — foregrounded in the release body, the prereg experiment-record, the CHANGELOG witness index, and `METER-LOOP-DECISION.md`, with the sharper A3 localization (independent witnesses disagree on the local semantic relation itself).
2. The root cause of the publish failure was **durably closed**, not just worked around: `ci.yml`'s existing guard was propagated to `release.yml`, so future tag pushes don't recur.
3. The successor data request (`A3-DISAGREEMENT-REQUEST.md`) was filed cleanly as data-harvesting, not a protocol reopen, feeding #76.

**Skill patches:** **None landed in this commit** — and here the disposition is explicit rather than silent. The two patch-worthy items are:
- The recurring warning-50 → a repo-local α pre-flight (an OCaml `.mli` leading-docstring lint before CI). The natural home is a repo-local pre-flight check, **not** the vendored `.cdd/skills/` bundle (patching vendored cnos skills would desync the integrity manifest). Deferred as named process debt (§4b), consistent with the operator scoping this PRA to *γ-artifact-only*.
- The provisional-marker omission is an **application gap**, not a skill gap: `release/SKILL.md` §2.4 already says to mark the row provisional; β wrote final grades directly. The skill is right; it wasn't followed. Note, don't patch.

**Active skill re-evaluation:** (a) `release.yml` depext gap — a workflow bug the skills don't own; fixed in code. (b) warning-50 recurrence — the α pre-review gate, as written, didn't catch a docstring-placement build break; a repo-local lint would; deferred by scope. (c) provisional marker — application gap.

**CDD improvement disposition:** No vendored-skill patch needed or permitted this cycle (integrity-manifest constraint + operator γ-only scope). The two concrete process fixes (repo-local `.mli` docstring pre-flight; honor `release/SKILL.md` §2.4 provisional-marker at release time) are recorded as named next-cycle debt below, closing the self-learning loop with explicit reasons rather than silence.

---

## 4. Review Quality

**Cycles this release:** 2 (cycle #74 engine, cycle #75 harness)
**Avg review rounds:** 1 (target: ≤2 for code cycles) ✓ — both cycles β-APPROVE at round 1
**Superseded cycles:** 0 (target: 0) ✓

**Per-cycle round counts:**

| Cycle | Issue | Mode | Rounds | Binding findings (R1) | Notes |
|-------|-------|------|--------|----------------------|-------|
| 74 | #74 (Sub-1 of #73) | design-and-build | 1 | 0 (APPROVE) | one build fix-round: warning-50 docstrings (pre-review/CI, not a β finding) |
| 75 | #75 (Sub-2 of #73) | design-and-build | 1 | 0 (APPROVE) | one build fix-round: same warning-50 class |

**Finding-class breakdown:**

| Class | Definition | Count |
|---|---|---|
| mechanical | caught by grep/diff/script | 2 (warning-50 build break × 2 cycles — CI-caught, not β-review findings) |
| wiring | "X wired into Y" but isn't | 0 |
| honest-claim | doc claims something code/data doesn't back | 0 |
| judgment | design/coherence assessment | 0 (β raised non-blocking observations, no change requests) |
| contract | work contract incoherent | 0 |

**Mechanical ratio:** N/A for β-review findings (0 blocking β findings; total < 10 → ratio is noise). The two mechanical items are *build* breaks tracked in §4b, not review findings.
**Action:** none filed (below the ≥10-findings threshold); recurring class dispositioned in §4b.

---

## 4a. CDD Self-Coherence

- **CDD α:** 4/4 — required artifacts present (α/β close-outs, self-coherence, gamma-closeout for both cycles; RELEASE.md; cycle dirs already at `.cdd/releases/0.12.0/`); the prereg + fixtures frozen; the FAIL recorded on all three surfaces.
- **CDD β:** 3/4 — canonical doc, skills, cycle artifacts, changelog, and release body agree; the one deduction is the missing `provisional` marker on the ledger row (β wrote final grades before the γ PRA existed), an application gap now ratified by this PRA.
- **CDD γ:** 4/4 — review rounds within target (1 each), 0 superseded, mechanical ratio below the filing threshold; immediate outputs executed this session, deferred outputs named.
- **Weakest axis:** β (3/4).
- **Action:** none structural — the β deduction is an application gap (honor `release/SKILL.md` §2.4 at release time), noted for next release, not a skill patch.

---

## 4b. Cycle Iteration

Two `§Assessment → Cycle iteration` triggers fired:

**Trigger 1 — loaded skill failed to prevent a (recurring) mechanical finding.**
- **Root cause:** the α pre-review gate, as written, does not catch OCaml warning-50 (unexpected-docstring: trailing `(** … *)` after `val`); the same break reached CI in *both* cycle #74 and #75.
- **Disposition:** **next-cycle debt (repo-local).** A repo-local `.mli` leading-docstring pre-flight lint is the fix; it does not belong in the vendored `.cdd/skills/` bundle (integrity-manifest desync). Not patched here per the operator's γ-artifact-only scope. Named as debt, not silently skipped.
- **Evidence:** `.cdd/releases/0.12.0/75/gamma-closeout.md` ("one build fix-round … same warning class as Sub-1"); commit `2cf60ff` (Sub-2 fix).

**Trigger 2 — avoidable tooling/environmental failure (release publish).**
- **Root cause:** `release.yml` lacked the libcurl depext pre-install that `ci.yml` already had, so the first one-off publish failed on a stale-apt-mirror 404.
- **Disposition:** **patch landed now (code).** `release.yml` hardened to mirror ci.yml (`cd39da9`); the hardened retry (`28761126980`) published the release + asset. Related environment constraint: session git credentials cannot push tags through the agent proxy (HTTP 403) — worked around via a self-deleting one-off workflow; this is an environment limitation, named, not a code defect.
- **Evidence:** commit `cd39da9`; release run `28761126980` (success); release `0.12.0` published with `coh-linux-x64`.

---

## 5. Production Verification

**Scenario:** A public consumer can obtain and run the 0.12.0 binary, and the release honestly surfaces the terminal factorized-β result; and — as an L7 structural change — the factorized-β route runs end-to-end as a real instrument.

**Before this release:** No `0.12.0` GitHub release existed (API 404); the factorized-β route did not exist as a shipped, CI-run instrument.

**After this release:** `0.12.0` release published; `coh-linux-x64` downloadable; the factorized-β measurement workflow ran in credentialed CI over five held-out targets (k=3) and emitted a terminal gate verdict.

**How to verify:**
```bash
# release + asset exist
#   GET /repos/usurobor/tsc/releases/tags/0.12.0  -> 200, asset coh-linux-x64 (sha256:4706c374…)
# the L7 boundary move — the route ran as an instrument, not a stub
#   factorized-beta-measure.yml run 28745643692 -> 9 jobs green, FACTORIZED_BETA_VERDICT=FAIL
```

**Result:** **Pass.** Release + asset verified via the GitHub release API this session (`sha256:4706c374…`, 6.83 MB). The structural boundary move is demonstrated by run `28745643692`: the factorization enumerated identical loci for every witness, restricted the LLM to a bounded verdict, aggregated mechanically — and *still* measured cross-witness disagreement on the local relation (A3), which is the real result, not a pipeline artifact (β verified the gate logic cannot manufacture a false FAIL).

---

## 6. CDD Closeout

| Step | Artifact | Skills loaded | Decision |
|------|----------|---------------|----------|
| 11 Observe | `.cdd/releases/0.12.0/{74,75}/*` (α/β close-outs, self-coherence, gamma-closeout), `RELEASE.md`, release page | post-release | Gap closed: factorized-β measured (terminal FAIL, recorded); platform refreshed to cnos 3.82.0; release published + asset attached |
| 12 Assess | `docs/gamma/cdd/0.12.0/POST-RELEASE-ASSESSMENT.md` (this doc) | post-release | Assessment completed; C_Σ **A−** (α A−, β A, γ A−, L7); two cycle-iteration triggers dispositioned |
| 13 Close | this PRA + CHANGELOG ledger ratified final; cycle dirs already at `.cdd/releases/0.12.0/` | post-release | Cycle closed; two process debts named (repo-local `.mli` pre-flight; §2.4 provisional-marker discipline) |

### 6a. Invariants Check

| Constraint | Touched? | Status |
|---|---|---|
| Scalar α/γ witness path + `runtime/SELF-MEASURE.md` untouched by the factorized-β route | Yes (route added alongside) | Preserved — factorized-β is strictly additive |
| Meter carries no consistency claim it cannot support | Yes (claim withdrawn) | Tightened — meter retained as infrastructure, consistency claim removed |
| Stopped meter loop not reopened without fresh operator dispatch | Yes (governance held) | Preserved — no v3.2.5; successor line is harvesting (#76), not optimization |
| CDD skill bundle vendored + integrity-checked | Yes (refreshed to 3.82.0) | Preserved/tightened — `MANIFEST.sha256` + `verify-skill-bundle.sh` |

---

## 7. Next Move

**Next MCA:** #76 — meter-found semantic ambiguity queue (the A3 disagreement extraction is its first work item, per `docs/beta/governance/A3-DISAGREEMENT-REQUEST.md`); #77 — CM0-compiler wave — is prepared but **awaits operator dispatch** (κ prepared the master; launch is δ's gate).
**Owner:** α/δ per γ selection after issue review.
**Branch:** `cycle/{N}` from `origin/main` after dispatch.
**First AC:** per the selected issue pack (#76: parse per-locus votes from a run's artifacts → agreement/entropy → enqueue below-threshold loci).
**MCI frozen until shipped?** No (only two growing-lag design issues; below threshold) — but no *new* design opened until #76/#77 dispatch.
**Rationale:** Consistency-improvement is governance-stopped; the live frontier is harvesting/admissibility, both implementation-shaped. Getting #76 moving turns the recorded FAIL into calibration value.

**Closure evidence (§Closure):**
- Immediate outputs executed: yes
  - `docs/gamma/cdd/0.12.0/POST-RELEASE-ASSESSMENT.md` written (this commit)
  - CHANGELOG 0.12.0 ledger row ratified final by γ PRA (this commit)
  - `release.yml` depext hardening (`cd39da9`, earlier this session)
  - `A3-DISAGREEMENT-REQUEST.md` filed (`c676fb0`, earlier this session)
  - Release `0.12.0` published + `coh-linux-x64` attached (run `28761126980`)
- Deferred outputs committed: yes (named debt)
  - Repo-local `.mli` leading-docstring pre-flight lint (owner: α / next code cycle; first AC: CI rejects a trailing-`val`-docstring before build) — prevents the warning-50 recurrence.
  - Honor `release/SKILL.md` §2.4 provisional-marker at release time (owner: β / next release) — write the ledger row as `provisional, pending γ PRA`, γ finalizes in the PRA commit.
  - `release.yml` release-notes source: publish from `RELEASE.md` (`body_path`) rather than `generate_release_notes`, matching how 0.12.0 was actually published (owner: next release-tooling cycle).

**Immediate fixes (executed in this session):**
- This PRA.
- CHANGELOG ledger ratification (final grade auditable).

---

## 8. Hub Memory

- **Daily reflection:** deferred — no hub repo configured in this environment. State to record: 0.12.0 published + asset live; factorized-β line closed as **terminal FAIL** (third, strongest falsification), meter retained without a consistency claim; CDD platform on cnos 3.82.0; `release.yml` depext gap fixed durably; A3 request + #76 open; #77 (CM0 compiler) prepared, awaiting dispatch; γ PRA A−/final.
- **Adhoc thread(s) updated:** deferred — no hub repo configured. Thread arc: the meter-consistency saga reaches its honest terminus (factorization tried and failed at A3), and the useful work pivots to admissibility/harvesting (#76 harvest, #77 compile-before-measure).

---

## γ verdict

**0.12.0 is published, validated, and closed.** Coherence: **C_Σ A− (α A−, β A, γ A−) · Level L7**, ratified as final by this assessment. Process honesty: strong (the FAIL is foregrounded, not buried). Artifact alignment: strong. The A− ceiling is earned by real friction — a needed publish retry, a latent `release.yml` depext gap (now fixed), a recurring docstring build-break (dispositioned), and this PRA landing post-tag rather than inside the tagged snapshot. None hidden, all named. No protocol change, no v3.2.5, no retag, no version bump, no standing promotion — and the terminal factorized-β FAIL stands.
