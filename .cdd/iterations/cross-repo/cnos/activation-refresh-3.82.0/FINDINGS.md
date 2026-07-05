# Activation-refresh findings — tsc → cnos 3.82.0

Date: 2026-07-05
Author: κ (Herald) — surfacing, not resolving. Resolution is γ/cell or operator work.

## F1 — RESOLVED (operator decision 2026-07-05: migrate)

**Resolution: migrate, not legacy-cutoff, not backfill.** Operator-approved.

Audit: all five `unreleased/` cycles (50, 51, 52, 53, 54) reference master **#49
/ v0.10.0** — the shipped wave (`releases/0.10.0/49/`). Confirmed shipped, so all
five migrated (not only the two that tripped the gate — per "do not leave
known-shipped cycles in unreleased/"):

```
.cdd/unreleased/50 → .cdd/releases/0.10.0/50   (git mv, history preserved)
.cdd/unreleased/51 → .cdd/releases/0.10.0/51
.cdd/unreleased/52 → .cdd/releases/0.10.0/52
.cdd/unreleased/53 → .cdd/releases/0.10.0/53
.cdd/unreleased/54 → .cdd/releases/0.10.0/54
```

`.cdd/unreleased/` is now empty; `validate-release-gate.sh --mode {pre-merge,release}`
both pass. No closeout artifacts were fabricated; this is historical placement
repair only. The gate itself is unchanged (not weakened).

Durable guard added alongside: `scripts/verify-skill-bundle.sh` now enforces the
`.cdd/CDD-VERSION` pin format (40-char SHA line 1; optional non-empty tag line 2;
≤2 lines) so the one-line-pin regression cannot return.

---

### F1 (original finding, for the record) — pre-activation cycles 53/54 failed the 3.82.0 pre-merge gate

**What.** `scripts/validate-release-gate.sh --mode pre-merge` (the gate the new
`cdd-artifact-validate.yml` runs) fails:

```
❌ cycle 53: missing alpha-closeout.md — required before merge
❌ cycle 53: missing beta-closeout.md
❌ cycle 54: missing alpha-closeout.md
❌ cycle 54: missing beta-closeout.md
```

**Why.** `.cdd/unreleased/{53,54}/` are sub-issues of master **#49 — the
v0.10.0 canonical-v3.2 cutover wave, already shipped** (`.cdd/releases/0.10.0/49/`
exists; repo is now at 0.11.0). They were authored under the **pre-3.82.0
closeout schema** (`self-coherence.md` + `beta-review.md` + `gamma-closeout.md`),
which did not emit separate `alpha-closeout.md` / `beta-closeout.md`. The 3.82.0
gate requires those two files for any `unreleased/` dir carrying `beta-review.md`.
53 has a `gamma-closeout.md`; 54 does not. Neither was migrated out of
`unreleased/` after the wave shipped.

**This is not a defect in the activation** — the gate is working; it surfaced a
latent incoherence: shipped cycles left stale in `unreleased/`, under an older
schema, now measured by a stricter mechanical gate.

**The gate workflow triggers only on `cycle/**`, `main`, and PRs to `main`**, so
it does not fire on the `cdd/activation-refresh-3.82.0` branch. It WILL block a
clean merge of this activation to `main` until F1 is resolved.

**Options (operator decision — κ does not choose or implement):**

1. **Migrate (recommended, lightest).** These cycles shipped with the v0.10.0
   wave; move `.cdd/unreleased/{53,54}/` → `.cdd/releases/0.10.0/{53,54}/`. Out
   of `unreleased/`, the pre-merge gate no longer scans them. γ housekeeping —
   the correct home for shipped cycles anyway. (Release-mode gate checks a
   different file set; confirm before/after.)
2. **Legacy cutoff (grandfather).** Adapt the tenant-owned
   `scripts/validate-release-gate.sh` (a tenant copy, NOT vendored/integrity-
   pinned) to warn-not-fail for cycles predating the activation — exactly cnos's
   own precedent (cnos 3.77.0: "pre-v3.77.0 cycles missing closeout docs now
   warn"). Transparent and doctrine-aligned; a governance choice that needs an
   explicit operator OK because it changes gate semantics.
3. **Backfill.** Author the missing `alpha-closeout.md`/`beta-closeout.md`
   retroactively (an α/β cell). Heaviest; produces fictional-timestamp closeouts
   for work done under a different schema — not recommended.

**κ recommendation:** Option 1 (migrate 53/54 into the shipped 0.10.0 release
tree), with Option 2 as the durable guard if more pre-activation cycles surface.
Both are γ/operator actions; κ has recorded the finding and will carry the
operator's verdict into whichever artifact executes it.
