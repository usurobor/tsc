---
cycle: 36
issue: "#36"
branch: "cycle/36"
mode: "design-and-build"
disconnect: "§2.5b docs-only — no version bump (workflow YAML + cache config; no engine surface change)"
date: "2026-05-12"
dispatch_configuration: "§5.2 single-session δ-as-γ via Claude Code Agent tool. γ axis grade capped at A− per the proposed §3.8 amendment (cnos #344 — pending; convention adopted on tsc per 344-c precedent)."
---

# Self-Coherence — Cycle #36

## Gap

> **R2 correction (2026-05-12):** the original gap framing below
> was empirically false and has been superseded by the corrected
> framing immediately following. β R1 finding B-1 caught this.
> γ chose Path A (consolidate) for R2; this section documents
> both the wrong original framing (struck through in spirit) and
> the actual gap the cycle now closes.

### Original (R1) framing — incorrect

> Tsc shipped the kata progression in #33 (`katas/01-glider/`, `katas/02-random-soup/`, `engine/ocaml/lib/kata.ml`, `coh --kata <name>` flag, `scripts/run-katas.sh`) and the activation-skill adoption in 344-c. The R1 cycle scaffold asserted that "CI exercises `dune runtest` … but does not invoke `coh --kata` against the shipped kata content." This was false: `.github/workflows/ci.yml` has had a `kata-check` job since 344-c (commit `16f60ac`) that runs `bash scripts/run-katas.sh` on every push to `main` / `cycle/**` and on every PR, and that script invokes `coh --kata <id> --mode mechanical` against every `katas/*/kata.toml`.

### Corrected (R2) framing — actual

CI invokes katas via the `kata-check` job in `ci.yml` (added in 344-c) — but with no OPAM/dune build cache (every run cold ~5–8 min, since each push re-runs the full engine install), and with no concurrency control (superseded PR runs are not cancelled). Cycle #36 consolidates kata-running into a dedicated `katas.yml` workflow that adds:

- An `actions/cache@v4` step caching `~/.opam` + `engine/ocaml/_build` keyed on `engine/ocaml/dune-project` + `engine/ocaml/tsc_engine.opam` hashes, so warm runs (cache hit) complete in <3 min (AC3).
- A `concurrency` block that cancels superseded PR runs but never cancels main runs.
- A forward-compatibility header citing cnos #344 Cycle B + tsc cycle C-2 as the canonical-template swap point.

…and removes the duplicate `kata-check` job from `ci.yml` (R2 commit 1) so the repo ends up with exactly one workflow exercising the katas.

## Mode

`design-and-build`. Design surface: one decision — new standalone workflow file (`katas.yml`) vs new job in existing `ci.yml`. Reusing `ci.yml`'s `build` job artifact (`coh-linux-x64`) avoids duplicate OPAM install (~5 min cold). Build surface: YAML + cache config + (optional) README badge. Mode-declaration is consistent with `cdd/issue/SKILL.md` MCA preconditions: no separate design/plan artifact; design lives in issue #36 body, this self-coherence document, and α's implementation choice. Not MCA.

## Cycle scope sizing (per cnos §1.6c heuristic)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | One workflow YAML file (~40–60 lines) OR one new job in `ci.yml` (~30 lines) | no |
| (b) Cross-module breadth | `.github/workflows/` only (one file added or one job added) | no |
| (c) Lifecycle span | mechanical; ships in one cycle | no |
| (d) MCA preconditions | not MCA — design fixed in body | n/a |
| (e) Independent shippability | one cohesive workflow change | no |

**Decision:** keep whole. **3 ACs**, low-typical band. Matches #30 cycle shape — mechanical, narrow, ~1 round expected.

## Active Skills

**Tier 1a (always loaded):**
- `cdd/CDD.md` (§1.6c dispatch sizing, §3.8 honest-grading)
- `cdd/SKILL.md`
- `cdd/gamma/SKILL.md` (γ role; single-session δ-as-γ via Agent tool)

**Tier 1b (lifecycle phase skills):**
- `cdd/issue/SKILL.md`
- `cdd/alpha/SKILL.md` (dispatch prompt source for α)
- `cdd/beta/SKILL.md` (dispatch prompt source for β)
- `cdd/review/SKILL.md` (verdict rules; rule 3.13 honest-claim verification)
- `cdd/release/SKILL.md` (§2.5b docs-only disconnect)
- `cdd/post-release/SKILL.md` (Step 5.6b cdd-iteration.md)

**Tier 2 (engineering, for α):**
- `cnos.eng/skills/eng/ci` — GitHub Actions YAML conventions
- `cnos.eng/skills/eng/test` — CI as regression gate

**Tier 3 (issue-specific):** none — workflow YAML is single-surface.

## Impact graph

```
.github/workflows/                  α decides: new katas.yml file OR new job in ci.yml
  └─ (new katas job)                triggers: push to main + PR
                                    auto-discovery: for kata in katas/*/; do coh --kata <name>; done
                                    cache: opam + dune _build/ keyed on dune-project + Makefile
katas/                              READ-ONLY in this cycle — kata content lives here, workflow reads it
katas/README.md                     α may add a CI status badge (AC1 Scope item 3, optional)
README.md                           α may add a CI status badge at top (optional)
```

## ACs (from issue #36)

**AC1 — Workflow runs on push to main + every PR.**
- *Invariant:* triggers include `push.branches: [main]` and `pull_request`.
- *Oracle:* post-merge `gh run list --workflow=<name>` shows runs for both event types (γ verifies post-merge).
- *Positive:* a known-good commit produces green status.
- *Negative:* a deliberately-broken kata (set `expected.verdict = "fail"` on kata-01) produces red status; revert.
- *Surface:* `.github/workflows/katas.yml` (new) OR `.github/workflows/ci.yml` (new job).

**AC2 — All shipped katas run, auto-discovered.**
- *Invariant:* `for kata in katas/*/; do …; done` (or equivalent matrix step) — no hard-coded kata names.
- *Oracle:* grep workflow YAML for `01-glider` / `02-random-soup` → zero hits.
- *Positive:* adding `katas/NN-newname/kata.toml` causes it to run on next push with no workflow edit; Phase 2's kata-03/04/05 auto-picked-up when #34 ships.
- *Negative:* hard-coded kata names; matrix step with explicit kata list rather than glob.
- *Surface:* same workflow file as AC1.

**AC3 — Build cache keeps warm runtime under 3 min.**
- *Invariant:* OPAM + dune cache via `actions/cache`; keys versioned on `engine/ocaml/dune-project` + `Makefile` hashes.
- *Oracle:* second CI run on cycle/36-impl (cache primed) completes in <3 min; first cold run ≤8 min (acceptable).
- *Positive:* dep change (touch `dune-project`) invalidates cache cleanly.
- *Negative:* global cache that never invalidates; or no cache at all (every run cold).
- *Surface:* same workflow file as AC1.

## CDD Trace

1. **Receive** — γ scaffold per cycle/36 branch off main `efbc07d`.
2. **Dispatch α** — Agent tool, fresh context. α reads issue #36, implements workflow per Scope items 1–3, commits + pushes to `cycle/36-impl`.
3. **α self-coherence + readiness signal.**
4. **Dispatch β** — Agent tool, fresh context. β reads `cycle/36-impl` diff, applies rule 3.13 (honest-claim verification on AC2 "no hard-coding" + AC3 cache key justification), writes `beta-review.md`.
5. **Fix rounds if any.**
6. **Merge** — `cycle/36-impl` → `main` (or `cycle/36-merged` if harness 403s).
7. **γ close-out** — move artifacts to `.cdd/releases/docs/2026-05-12/36/`; write `gamma-closeout.md`; record dispatch configuration §5.2 + γ A− cap.
8. **cdd-iteration** — capture any friction (cache-key choice, standalone-vs-ci.yml decision rationale, runtime data).

## Dispatch configuration

- **Operator δ = γ** (single-session via Agent tool — Claude Code activation per cnos #344 §5.2 proposal; convention adopted on tsc).
- **α**: Agent tool sub-agent, fresh context. Identity: `alpha@tsc.cdd.cnos`.
- **β**: Agent tool sub-agent, fresh context. Identity: `beta@tsc.cdd.cnos`.
- **γ**: this session. Identity: `gamma@tsc.cdd.cnos`.
- **Honest-grading floor:** γ axis capped at A− per the proposed §3.8 amendment (cnos #344 — pending; convention practiced by precedent).

## Head SHA

### α R1 head — `cycle/36-impl` (post-push)

Commits on `cycle/36-impl` (off γ scaffold `e7f3817`):

| SHA (short) | Subject |
|---|---|
| `ecb270b` | ci(36): add katas regression workflow — AC1+AC2+AC3 |
| `b8df57f` | docs(36): add katas CI status badge to katas/README.md |
| `56571e0` | closeout(36): α R1 closeout + honest-claim manifest |
| `5a105cb` | meta(36): record α R1 head SHAs in self-coherence |

β R1 reviewed against `5a105cb`; verdict RC with two B-findings,
captured in `.cdd/unreleased/36/beta-review.md` (commit `c996abd`
on `cycle/36-impl-review`).

### α R2 head — `cycle/36-impl-r2` (post-push)

R2 fix commits on `cycle/36-impl-r2` (off `c996abd` on
`cycle/36-impl-review`):

| SHA (short) | Subject |
|---|---|
| `2c7d4f8` | ci(36): remove kata-check job (consolidated into katas.yml) |
| `35033ec` | ci(36): fix cache key to reference only files that exist |
| `426f2b9` | docs(36): correct §Gap framing — kata-check existed; consolidate |
| `dedbef5` | docs(36): update closeout + claims for R2 narrative |
| `(this commit)` | meta(36): record α R2 head SHAs in self-coherence |

R2 finding-to-commit map:
- **B-1** (gap framing wrong; CI was already running katas) →
  resolved by commits `2c7d4f8` (kata-check removal — Path A
  consolidate per γ) + `426f2b9` (§Gap correction; original R1
  framing preserved as audit trail).
- **B-2** (cache key references nonexistent
  `engine/ocaml/Makefile`) → resolved by commits `35033ec` (key
  fix; replaced with `dune-project` + `tsc_engine.opam`, both
  `ls`-verified) + `dedbef5` (closeout AC3 audit-trail note +
  claims.md §R2 supersession of Claim 3).

β R2 will review against the head SHA of `cycle/36-impl-r2`
reported in α R2's readiness signal message (the SHA of this
commit when pushed).
