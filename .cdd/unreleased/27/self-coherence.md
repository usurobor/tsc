---
cycle: 27
issue: "Sub 4 (#23): Retroactive close-out for v0.4.0 release"
branch: cycle/27-v040-closeout
phase: dispatched
role: gamma
---

# Cycle 27 — Self-Coherence Scaffold

**Gap:** v0.4.0 shipped at tag `b522aa3` without CHANGELOG ledger row, frozen docs artifacts (`docs/alpha/engine/0.4.0/`), or version-table entries. This is protocol debt, not functional regression.

**Mode:** Retroactive close-out (docs-only). No re-tagging. No functional changes.

**ACs (from issue #27):**
- AC1: CHANGELOG.md ledger row for v0.4.0
- AC2: docs/alpha/engine/README.md version table updated (0.3.1 and 0.4.0 added)
- AC3: docs/alpha/engine/0.4.0/{README.md, DESIGN.md, PLAN.md, SELF-COHERENCE.md, POST-RELEASE-ASSESSMENT.md} exist
- AC4: α/β/γ/C_Σ in SELF-COHERENCE.md match CHANGELOG ledger row
- AC5: 0.3.1 audit complete (either frozen dir exists or rationale note in README.md)

**Active design constraint:** All reconstructed DESIGN/PLAN documents must carry a header note: "Reconstructed retroactively after v0.4.0 ship."

**CDD Trace:** (to be completed by α)

**Review-readiness signal:** (set by α when ready for β)

**Fix rounds:** 0
