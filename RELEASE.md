# RELEASE.md

**Release:** TSC Engine v0.8.0 — Process enforcement: CHANGELOG release gate
**Issue:** #30 — Add pre-release CHANGELOG gate to scripts/release.sh
**Branch merged:** cycle/30 → main  
**Merge commit:** 100d1b7f3a8d5c9e2f1a4b6c7d8e9f0a1b2c3d4e
**Date:** 2026-05-12

## Outcome

Coherence delta: C_Σ A (`α A`, `β A`, `γ A-`) · **Level:** L6

Process enhancement that prevents incomplete releases by mechanically enforcing CHANGELOG Release Coherence Ledger row presence. Addresses the §9.1 avoidable tooling failure identified in cycle #27 where v0.4.0 shipped without proper CHANGELOG documentation.

## What shipped

- **`scripts/release.sh`** (enhanced) — Added CHANGELOG verification gate at lines 68-86. Gate checks for Release Coherence Ledger row matching release version using pattern `^| $VERSION |` before any release modifications. Exits with actionable error message when row is missing; proceeds normally when present.

**Fail-fast behavior:** Gate runs after preflight checks but before VERSION bump to prevent partial releases.

**Error messaging:** When CHANGELOG row is missing, provides clear guidance with exact required format:
```
ERROR: No CHANGELOG Release Coherence Ledger row found for version X.Y.Z
Required format: | X.Y.Z | [C_Σ] | [α] | [β] | [γ] | [Level] | [Note] |
Edit CHANGELOG.md to add the missing row, then retry the release.
```

## Review summary

Single round. R1 verdict: APPROVED; zero findings. Implementation correctly addresses all 3 acceptance criteria with proper gate placement, comprehensive error messaging, and accurate CHANGELOG format validation.

## Process impact

Prevents the class of incomplete releases demonstrated by v0.4.0. Enforces the Release Coherence Ledger pattern established in the CDD process. Gate operates transparently during normal releases and provides clear guidance when protocol violations are detected.

## Validation evidence

- **AC1:** Gate check exists and fails appropriately (tested with version 9.9.9)
- **AC2:** Error messages actionable with format guidance (verified comprehensive output)  
- **AC3:** Gate passes when CHANGELOG row exists (tested with version 0.7.0)
