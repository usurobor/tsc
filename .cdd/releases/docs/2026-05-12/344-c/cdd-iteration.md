# CDD Iteration — tsc Cycle C (cnos #344-C)

**Cycle:** cnos #344-C — tsc adoption (CDD activation)  
**Date:** 2026-05-12  
**Actor:** α (Alpha)  

---

## Activation experience

This cycle applied the CDD activation skill (cnos #344) to tsc for the first time. tsc reached cycle #32 without formal activation. The activation tax paid here spans:

1. **CI gap** — Engine tests ran on `main`/`master` only. Spec validation and kata CI were entirely absent. Three separate CI jobs were needed (spec-validate, kata-check, and the trigger extension) where a properly activated repo would have had these from the start.

2. **Notification gap** — No Telegram notifier existed. Cycle events (open, β-verdict, RC, merge) were invisible outside the Claude session. Wiring required copying the Cycle B template and adapting the script path — straightforward, but a gap that persisted 32 cycles.

3. **Marker file gap** — Six files (CDD-VERSION, DISPATCH, CADENCE, OPERATORS, MCAs/INDEX.md, skills/README.md) were absent. None were load-bearing for prior cycles but their absence makes the repo non-conformant with the activation skill prescription.

4. **Cross-repo format gap** — The cross-repo README used the older `<upstream-repo>-<cycle-N>/` flat format instead of the §13-prescribed `{target}/{slug}/` nested format.

---

## Findings

### F1 — Activation gaps compound silently (severity: B)

Without an activation checklist, gaps accumulate across cycles without being visible. tsc reached cycle #32 before the CI gap was formally identified. Each gap individually seemed minor but together they represent significant protocol drift. The activation skill (cnos #344-A) addresses this, but adoption lag is real.

**Recommendation:** Future tenant repos should run the §23 activation checklist at cycle #1, not cycle #32.

### F2 — Kata CI infrastructure can ship ahead of runner (severity: C / informational)

Wiring `kata-check` as a graceful-skip job is the right pattern: CI surface exists and is visible, but no katas are defined yet so it never blocks. This creates a natural hook for tsc #33 (kata framework) without requiring #33 to ship first. No protocol gap here — the pattern is correct.

### F3 — Operator secret gate is an invisible blocker (severity: B)

The Telegram notifier gracefully skips when secrets are absent. This means activation appears complete (CI is green) but notifications are silently not firing. There is no automated way to verify that secrets are configured. An operator running §24 verification would not discover this gap.

**Recommendation:** Add a secrets-presence check to the §24 verification prescription, or add a CI step that fails with a clear message when secrets are absent (trade-off: CI fails until operator configures secrets, which could be disruptive for repos with no Telegram bot yet).

### F4 — Skill vendoring is deferred (severity: C / informational)

`.cdd/skills/README.md` declares that skills are loaded from cnos at dispatch time. This is pragmatic but means the skill version is not frozen at dispatch time — a future cnos update could change behavior without a corresponding `.cdd/CDD-VERSION` bump. Acceptable for now; vendoring is a follow-on step.

---

## Protocol suggestions for cnos

1. **§24 should include a secrets-gate check** — or at minimum document that Telegram secrets are an operator gate outside the automated verification scope.
2. **§23 activation checklist** — the ordered steps worked well. No forward dependencies encountered.
3. **Cycle B template copy pattern** — the `notify.sh` verbatim-copy instruction was clear and worked without friction. Good pattern for reference implementations.
