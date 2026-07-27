# CDD Skill Bundle — tsc (vendored)

tsc is a tenant repository. The CDD skill bundle is **vendored** here, frozen
at the cnos commit SHA pinned in [`.cdd/CDD-VERSION`](../CDD-VERSION), per
`cdd/activation/SKILL.md §16`.

- **Pinned cnos SHA:** `fd1d654e8d6361f0db2a6407f19e573a96d1054d` (tag `3.82.0`)
- **Canonical source (cnos):** `src/packages/{cnos.cdd,cnos.cds,cnos.handoff}/skills/`
- **Vendored packages (this dir):**
  - `cdd/`     ← `cnos.cdd/skills/cdd/`     (the α/β/γ/δ/ε role + process skills)
  - `cds/`     ← `cnos.cds/skills/cds/`     (coherence-driven software lifecycle, v0.1)
  - `handoff/` ← `cnos.handoff/skills/handoff/` (receipt-stream wire-format, v0.1)
- **Integrity manifest:** [`MANIFEST.sha256`](MANIFEST.sha256) — sha256 of every
  vendored file, generated from the cnos source tree at the pinned SHA.

## Integrity

CI verifies the vendored tree has not drifted from the manifest via
[`scripts/verify-skill-bundle.sh`](../../scripts/verify-skill-bundle.sh)
(job `skill-bundle-integrity` in `.github/workflows/cdd-artifact-validate.yml`).
A manual edit, partial refresh, or path collision fails the check with a named diff.

## Refresh procedure (§16)

Refresh **only** when bumping the pin — deliberate and audit-traceable:

1. Update both lines of `.cdd/CDD-VERSION` to the new cnos SHA + tag.
2. Clone cnos at that SHA; copy
   `src/packages/{cnos.cdd,cnos.cds,cnos.handoff}/skills/{cdd,cds,handoff}`
   into `.cdd/skills/`.
3. Regenerate the manifest:
   `cd .cdd/skills && find cdd cds handoff -type f | LC_ALL=C sort | xargs sha256sum > MANIFEST.sha256`.
4. Commit the pin bump + re-vendor + manifest in one rationale commit.

## History

Prior stance (pre-3.82.0) was reference-only ("skills loaded from cnos at
dispatch time"). That deviation is retired: the bundle is vendored so cycles
load skills without network access to cnos and integrity is mechanically checked.
