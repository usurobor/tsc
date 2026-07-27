# CDD activation-refresh receipt — tsc → cnos 3.82.0

Date: 2026-07-05
Author: κ (Keryx / Herald — human-interface role, cnos#501 doctrine)
Kind: activation-refresh (operator-directed infrastructure; not a cell deliverable)
Branch: `cdd/activation-refresh-3.82.0` (off `origin/main` `b2af770`)
Operator dispatch: 2026-07-05 conversation — "update cnos and cds to the latest";
plan approved with defaults recorded below.

## Purpose

tsc pins cnos `982860df` (pre-δ/ε, pre-activation-model, pre-cds). Refresh
the tenant's vendored CDD/CDS infrastructure to **cnos 3.82.0 @ `fd1d654`**:
current activation surfaces, δ/ε roles, cds v0.1 overlay, current GitHub
Actions, and the version pin — so tsc is a properly-activated tenant and can
host the factorized-β wave under the current process.

This is infrastructure (scaffold, CI, pin), not cell-owned α/β/γ/δ matter, so
κ performing it needs no `degraded_recovery` mark. If any step turns out to
require code authoring, it spins a proper α cell instead.

## Approved defaults (operator, 2026-07-05)

1. **Vendor, not reference.** Vendor `cnos.cdd` skills into `.cdd/skills/cdd/`
   from cnos 3.82.0 @ `fd1d654`. The current tsc reference-only stance is a
   deviation to be removed, not preserved. If vendoring proves too large or
   conflicts with tsc repo policy: **STOP** and propose a formal
   "reference-only exception" with an integrity check — do not silently keep
   the old deviation.
2. **Dedicated branch** `cdd/activation-refresh-3.82.0` off `origin/main`. Do
   not mix with the factorized-β prereg branch.
3. **κ by doctrine only** (κ is not a shipped skill surface in 3.82.0). Bring
   the 3.82.0 shipped surfaces where activation requires: `cnos.cdd`,
   `cnos.cds` v0.1, `cnos.handoff` v0.1. Do not wait for unshipped
   human-gates / κ artifacts.
4. **Record first** (this receipt), then execute.

## Target pin

```
fd1d654…            (resolve to full 40-char SHA at Phase 0)
3.82.0
```

## Plan (approved)

- **Phase 0** — branch (done); clone cnos @ `fd1d654`; resolve full SHA;
  confirm tag 3.82.0.
- **Phase 1** — read the 3.82.0 activation contract (`agent/activate` +
  `activation` + CA skills `cap`/`clp`) and enumerate exact tenant deltas.
  Activation applied manually from the skill (the `cn` Go CLI is not in this
  container).
- **Phase 2** — `.cdd/` scaffold refresh: `CDD-VERSION` → `fd1d654`/`3.82.0`;
  `OPERATORS` gains δ (and ε if used); `DISPATCH` reconciled (§5.2 +
  κ herald named); `skills/README.md` rewritten for the vendored bundle;
  reconcile required-file list (proposals/, cell-kinds, MCA, iterations).
- **Phase 2b** — **vendor** `src/packages/cnos.cdd/skills/cdd/` →
  `.cdd/skills/cdd/`, with a recorded integrity check (source SHA + a
  manifest/hash of vendored files).
- **Phase 3** — GitHub Actions: add `scripts/validate-release-gate.sh`
  (cnos #339); add/refresh the `cdd-validate` workflow; refresh
  `cdd-notify.yml` + `scripts/notify.sh` from the 3.82.0 telegram-notifier
  template; reconcile tsc-specific workflows against the release-gate
  contract.
- **Phase 4** — cds v0.1 + handoff v0.1 tenant surfaces where activation
  requires (minimal at 3.82.0; do not block on unshipped pieces).
- **Phase 5** — verify: activation 8-file check + CI green + κ durable-state
  preflight.
- **Phase 6** — κ close/report; then (separately) dispatch the factorized-β
  wave as κ (typed master + Sub-1; a γ cell dispatches α/β).

## Operator-only steps (κ cannot perform)

- Set / confirm repository secrets `CDD_TELEGRAM_BOT_TOKEN`,
  `CDD_TELEGRAM_CHAT_ID`.
- Branch protection on `main` (require PR review + CI checks, disallow
  force-push).

## Integrity / stop conditions

- Vendored tree records its source SHA (`fd1d654`) and a file manifest for
  later drift detection.
- Any conflict with tsc repo policy (e.g. size, licensing, path collisions)
  halts execution and is surfaced to the operator as a named exception, not
  worked around.
