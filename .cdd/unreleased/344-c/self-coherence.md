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

*(Populated incrementally per commit. Final evidence appended in review-readiness commit.)*

### C.AC1 — Engine tests on `cycle/**`

**Change:** `.github/workflows/ci.yml` `on.push.branches` extended with `cycle/**`.

**Verification:**
```
grep -A5 "on:" .github/workflows/ci.yml
```
Expected output includes `cycle/**` in the branches list.

**Status:** IMPLEMENTED — see commit `ci(344-c): extend push trigger to cycle/**`

---

### C.AC2 — Spec validation CI job

**Change:** New `spec-validate` job in `.github/workflows/ci.yml`.

Job steps:
1. Check required spec files present: `spec/tsc-core.md`, `spec/tsc-oper.md`, `spec/tsc-glossary.md`
2. Run lychee link check on `spec/*.md`

**Status:** IMPLEMENTED — see commit `ci(344-c): add spec-validate job`

---

### C.AC3 — Kata CI job wired

**Change:** New `kata-check` job in `.github/workflows/ci.yml`. New `scripts/run-katas.sh`. New `katas/README.md`.

Script gracefully exits 0 when `katas/` is empty or missing — no katas defined yet (tsc #33 provides the runner).

**Status:** IMPLEMENTED — see commit `ci(344-c): add kata-check job + scripts/run-katas.sh + katas/README.md`

---

### C.AC4 — Telegram notifier wired

**Change:** Copied `notify.sh` from cnos Cycle B template to `scripts/notify.sh`. Created `.github/workflows/cdd-notify.yml` adapted from template.

**Operator gate:** `CDD_TELEGRAM_BOT_TOKEN` and `CDD_TELEGRAM_CHAT_ID` must be set in repo Settings → Secrets and variables → Actions. Without these secrets the notifier gracefully skips.

**Status:** IMPLEMENTED — see commit `ci(344-c): wire Telegram notifier`

---

### C.AC5 — Activation marker files

**Files created:**
- `.cdd/CDD-VERSION` — cnos SHA `982860df0de07b76a19ba1d49fe5180a05b0b4dd`
- `.cdd/DISPATCH` — §5.2 single-session δ-as-γ via Agent tool
- `.cdd/CADENCE` — `mixed` (versioned engine + rolling-docs CDD cycles)
- `.cdd/OPERATORS` — α, β, γ handle registry
- `.cdd/MCAs/INDEX.md` — MCA registry (none open)
- `.cdd/skills/README.md` — skill bundle declaration (vendored from cnos)

**Status:** IMPLEMENTED — see commit `cdd(344-c): populate activation marker files`

---

### C.AC6 — §24 verification output

*(Populated after running verification command)*

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

**Status:** VERIFIED — all 9 checks pass

---

### C.AC7 — Cross-repo trace bundle dir conformed

**Change:** `.cdd/iterations/cross-repo/README.md` replaced with §13-prescribed `{target}/{slug}/` format.

**Status:** IMPLEMENTED — see commit `cdd(344-c): conform cross-repo README to §13 format`

---

### C.AC8 — cdd-iteration finding

*(See cdd-iteration.md — filed as separate commit)*

---

## §Self-check

| Check | Result |
|---|---|
| YAML valid: `.github/workflows/ci.yml` | PASS — `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml').read())"` exits 0 |
| YAML valid: `.github/workflows/cdd-notify.yml` | PASS — same command exits 0 |
| Shell syntax: `scripts/run-katas.sh` | PASS — `bash -n scripts/run-katas.sh` exits 0 |
| Shell syntax: `scripts/notify.sh` | PASS — `bash -n scripts/notify.sh` exits 0 |
| §24 verification | PASS — all 9 checks OK |
| Author email | `alpha@tsc.cdd.cnos` — correct |

---

## §Debt

1. **C.AC4 operator gate:** `CDD_TELEGRAM_BOT_TOKEN` and `CDD_TELEGRAM_CHAT_ID` must be configured in GitHub repo secrets by the repository operator. The notifier gracefully skips if secrets are absent (exits 0 with warning), so CI does not break, but no notifications will fire until secrets are set. This is an explicit operator action, not a code change.

2. **C.AC3 kata runner (tsc #33):** `scripts/run-katas.sh` is infrastructure only. The script exits 0 gracefully when no `katas/*/kata.toml` files are found. The actual kata runner (`coh --kata`) is provided by tsc #33 (kata framework issue). `katas/README.md` documents the schema and ordering convention.

3. **Skill vendoring:** `.cdd/skills/README.md` declares that skills are loaded from cnos at dispatch time rather than vendored. If a future cycle requires offline/frozen skill access, a vendoring step would be needed.

---

## §CDD-Trace

| Field | Value |
|---|---|
| Governing issue | cnos #344 Cycle C |
| Branch | cycle/344-c |
| Actor | α / Alpha / alpha@tsc.cdd.cnos |
| Dispatch mode | §5.2 single-session δ-as-γ |
| Skill pin | cnos SHA 982860df0de07b76a19ba1d49fe5180a05b0b4dd |
| Pre-review gate | see §Self-check — all checks pass |

---

## §Review-Readiness

*(Appended in final commit)*
