# Self-Coherence — tsc Cycle C (cnos #344-C)

**Cycle:** cnos meta-issue #344, Cycle C — tsc adoption  
**Branch:** cycle/344-c  
**Actor:** α (Alpha) — alpha@tsc.cdd.cnos  
**Date opened:** 2026-05-12  

---

## §Gap — Cycle C Scope

**Governing issue:** cnos #344 (CDD Activation Skill meta-issue), Cycle C sub-scope.

Cycle C applies the activation skill and Cycle B templates to the tsc tenant repository. tsc reached cycle #32 without a formal CI loop (engine tests were present, but spec validation and kata CI were absent), without a Telegram notification adapter, and without the activation marker files prescribed by cdd/activation/SKILL.md §4, §8, §19, §21, §15, §16. This cycle closes those gaps.

**Governing ACs (8):**

| AC | Description |
|---|---|
| C.AC1 | Engine tests run on every push including `cycle/**` |
| C.AC2 | Spec validation runs on every push |
| C.AC3 | Kata CI job wired (infrastructure for tsc #33) |
| C.AC4 | Telegram notifier wired |
| C.AC5 | 6 activation marker files populated |
| C.AC6 | §24 verification passes |
| C.AC7 | Cross-repo trace bundle dir conformed to §13 format |
| C.AC8 | cdd-iteration finding recorded |

**Pre-state:** `.github/workflows/ci.yml` ran build/test/linkcheck on `main`/`master` only. No spec CI, no kata CI, no notification workflow. No `.cdd/CDD-VERSION`, `.cdd/DISPATCH`, `.cdd/CADENCE`, `.cdd/OPERATORS`, `.cdd/MCAs/INDEX.md`, or `.cdd/skills/`. Cross-repo README used older flat format.

---

## §Skills

Active skills for this cycle:

- `cnos:cdd/activation/SKILL.md` — governing skill; §24 verification is the formal gate
- `cnos:cdd/alpha/SKILL.md` — α role
- `cnos:cdd/CDD.md` — protocol reference

Skill pin: `.cdd/CDD-VERSION` → cnos SHA `982860df0de07b76a19ba1d49fe5180a05b0b4dd`

---

## §ACs — Evidence

### C.AC1 — Engine tests on `cycle/**`

**Change:** `.github/workflows/ci.yml` `on.push.branches` extended with `cycle/**`.

**Verification:**
```
$ grep -A5 "on:" .github/workflows/ci.yml
on:
  push:
    branches: [ main, master, 'cycle/**' ]
  pull_request:
```

`cycle/**` is present in push branches. The existing `build`, `linkcheck` jobs run unchanged — only the trigger scope was widened.

**Status:** IMPLEMENTED

---

### C.AC2 — Spec validation CI job

**Change:** New `spec-validate` job in `.github/workflows/ci.yml`.

Job steps:
1. Check required spec files present: `spec/tsc-core.md`, `spec/tsc-oper.md`, `spec/tsc-glossary.md`
2. Run lychee link check on `spec/*.md` (same lychee config as existing `linkcheck` job)

Independently visible from the general `linkcheck` job — spec failures show as a distinct CI job.

**Status:** IMPLEMENTED

---

### C.AC3 — Kata CI job wired

**Change:** New `kata-check` job in `.github/workflows/ci.yml`. New `scripts/run-katas.sh`. New `katas/README.md`.

Script behavior:
- If `katas/` is missing or empty: gracefully exits 0 with informational message
- If `katas/*/kata.toml` files exist: runs each via `coh --kata {id} --mode mechanical`
- Reports pass/fail counts; exits non-zero if any kata fails

`katas/README.md` documents: kata.toml schema (id, difficulty, prerequisites, mode, description, [input], [expected]), ordering convention, runner invocation form. Partially satisfies tsc #33 AC1/AC2.

**Status:** IMPLEMENTED

---

### C.AC4 — Telegram notifier wired

**Change:** Copied `notify.sh` verbatim from cnos Cycle B template to `scripts/notify.sh`. Created `.github/workflows/cdd-notify.yml` adapted from template (path updated from `.github/cdd/notify.sh` to `scripts/notify.sh`).

**Operator gate:** `CDD_TELEGRAM_BOT_TOKEN` and `CDD_TELEGRAM_CHAT_ID` must be set in repo Settings → Secrets and variables → Actions. Without these secrets the notifier gracefully skips (exits 0 + warning). CI does not break if secrets absent.

**Events handled:** cycle-open, beta-verdict, cycle-rc, cycle-merge.

**Status:** IMPLEMENTED (operator secrets gate noted in §Debt)

---

### C.AC5 — Activation marker files

**Files created:**

| File | Content |
|---|---|
| `.cdd/CDD-VERSION` | `982860df0de07b76a19ba1d49fe5180a05b0b4dd` (cnos HEAD SHA) |
| `.cdd/DISPATCH` | `§5.2 — single-session δ-as-γ via Agent tool (Claude Code)` |
| `.cdd/CADENCE` | `mixed` (versioned engine + rolling-docs CDD cycles) |
| `.cdd/OPERATORS` | α, β, γ handle registry |
| `.cdd/MCAs/INDEX.md` | MCA registry table (none open) |
| `.cdd/skills/README.md` | Skill bundle declaration (loaded from cnos at dispatch time) |

**Status:** IMPLEMENTED

---

### C.AC6 — §24 verification output

```
OK: .cdd/CDD-VERSION
OK: .cdd/DISPATCH
OK: .cdd/CADENCE
OK: .cdd/OPERATORS
OK: .cdd/MCAs/INDEX.md
OK: .cdd/skills/README.md
OK: .cdd/iterations/cross-repo/README.md
OK: .cdd/iterations/INDEX.md
OK: .cdd/CDD-VERSION SHA format valid
```

All 9 checks pass. No MISSING, EMPTY, or MALFORMED lines.

**Status:** VERIFIED

---

### C.AC7 — Cross-repo trace bundle dir conformed

**Change:** `.cdd/iterations/cross-repo/README.md` replaced with §13-prescribed format.

Pre-state content described the older flat `<upstream-repo>-<cycle-N>/` layout.

Post-state content prescribes:
- `{target}/{slug}/` nested structure
- When to create a bundle (deliverables that land in another repo, coordinated cycles, binding design decisions)
- Bundle contents: `README.md` + `STATUS` file (`open|converging|closed`)
- Bundle close condition: both originating and target cycles shipped close-outs

**Status:** IMPLEMENTED

---

### C.AC8 — cdd-iteration finding

See `cdd-iteration.md` in this same directory.

**Status:** IMPLEMENTED

---

## §Self-check

| Check | Command | Result |
|---|---|---|
| YAML valid: `.github/workflows/ci.yml` | `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml').read())"` | PASS |
| YAML valid: `.github/workflows/cdd-notify.yml` | `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/cdd-notify.yml').read())"` | PASS |
| Shell syntax: `scripts/run-katas.sh` | `bash -n scripts/run-katas.sh` | PASS |
| Shell syntax: `scripts/notify.sh` | `bash -n scripts/notify.sh` | PASS |
| §24 verification | (see C.AC6 output above) | PASS — 9/9 |
| Author email | `git log --format='%ae' -1` | `alpha@tsc.cdd.cnos` |

---

## §Debt

1. **C.AC4 operator gate:** `CDD_TELEGRAM_BOT_TOKEN` and `CDD_TELEGRAM_CHAT_ID` must be configured in GitHub repo secrets by the repository operator. The notifier gracefully skips if secrets are absent (exits 0 with warning), so CI does not break, but no notifications will fire until secrets are set. This is an explicit operator action, not a code change. See [GitHub docs: encrypted secrets](https://docs.github.com/actions/security-guides/encrypted-secrets).

2. **C.AC3 kata runner (tsc #33):** `scripts/run-katas.sh` is infrastructure only. The script exits 0 gracefully when no `katas/*/kata.toml` files are found. The actual kata runner (`coh --kata`) is provided by tsc #33 (kata framework issue). `katas/README.md` documents the schema and ordering convention — this satisfies tsc #33 AC1/AC2 (directory layout and CI wiring).

3. **Skill vendoring:** `.cdd/skills/README.md` declares that skills are loaded from cnos at dispatch time rather than vendored locally. If a future cycle requires offline/frozen skill access, a vendoring step would be needed. A follow-on cycle can vendor by copying `cnos:src/packages/cnos.cdd/skills/cdd/` to `.cdd/skills/cdd/` at the pinned SHA.

---

## §CDD-Trace

| Field | Value |
|---|---|
| Governing issue | cnos #344 Cycle C |
| Branch | cycle/344-c |
| Actor | α / Alpha / alpha@tsc.cdd.cnos |
| Dispatch mode | §5.2 single-session δ-as-γ |
| Skill pin | cnos SHA 982860df0de07b76a19ba1d49fe5180a05b0b4dd |
| Pre-review gate | all checks pass (see §Self-check) |

---

## §Review-Readiness

**All 8 ACs implemented and evidenced:**
- C.AC1: `cycle/**` in push trigger — grep-verified
- C.AC2: `spec-validate` job added — checks 3 required files + lychee
- C.AC3: `kata-check` job + `scripts/run-katas.sh` + `katas/README.md`
- C.AC4: `scripts/notify.sh` (verbatim copy) + `cdd-notify.yml` (adapted)
- C.AC5: 6 activation marker files created with correct content
- C.AC6: §24 verification — 9/9 OK
- C.AC7: cross-repo README conformed to §13 `{target}/{slug}/` format
- C.AC8: `cdd-iteration.md` filed

**Pre-review gate:** All YAML valid, all shell scripts syntax-clean, §24 all OK, author email correct.

**Ready for β review.**
