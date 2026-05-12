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

Tsc shipped the kata progression in #33 (`katas/01-glider/`, `katas/02-random-soup/`, `engine/ocaml/lib/kata.ml`, `coh --kata <name>` flag, `scripts/run-katas.sh`) and the activation-skill adoption in 344-c (`.github/workflows/cdd-notify.yml` Telegram notifier + 6 activation marker files). What's missing: the workflow that **actually runs the katas on every push to main and on every PR**. Today the runner exists and the katas exist; CI exercises `dune runtest` (covers OCaml unit tests including `test_kata.ml` hermetic tests) but does not invoke `coh --kata` against the shipped kata content. A regression to the mechanical scorer that drops kata-01's `c_sigma` below `expected.score_range.min` would silently pass `dune runtest` and only surface on the next manual `bash scripts/run-katas.sh`. Issue #36 closes this gap with a `katas` job that auto-discovers every `katas/NN-*/` directory and runs `coh --kata <name>` against it, failing CI on any non-zero exit.

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

(to be filled in α R1 readiness signal)
