<!-- sections: [Gap, Skills, ACs, Self-check, Debt, CDD-Trace, Review-readiness] -->
<!-- completed: [Gap, Skills] -->

# α self-coherence — cycle/54 (S5 cutover cleanup)

**Issue:** #54 — sub of master #49 (v0.10.0 canonical v3.2 scoring cutover wave)
**Branch:** `cycle/54`
**Base:** `origin/main` @ `3efde94`
**α identity:** `alpha@tsc.cdd.cnos`
**Mode:** design-and-build (per #54 §Mode)
**Dispatched:** 2026-05-13

## Gap

#54 is the cleanup cycle around the canonical v3.2 cutover. Predecessors #50/#51/#52/#53 landed the engine-side changes on `main` (`3efde94`): new aggregate (`C_Σ^math` and `C_Σ^num`), report schema with flat `c_sigma` removed, OOD detector for `aggregate_semantics`, strict v3.2 LLM δ validation, and the cross-target §7.4 report surface. What remains is the perimeter:

- katas still record arithmetic-aggregate provenance (`C_Σ ≈ (α+β+γ)/3` ranges) instead of geometric `C_Σ^num` ranges
- active docs (`THESIS.md`, `QUICKSTART.md`, `ARCHITECTURE.md`, `OPERATOR-MANUAL.md`, `katas/README.md`, per-kata READMEs) describe the v0.9.x flat-`c_sigma` shape
- `project.tsc` lives at repo root despite being superseded by `targets/registry.tsc`
- frozen-snapshot banner-revert per CDD §5.6 (none turn out to be present — see AC4 evidence)
- no migration note in `CHANGELOG.md`
- target-registry has no smoke test
- forbidden-wording rule is not automated
- `VERSION`/`dune-project`/`tsc_engine.opam` still read `0.9.0`; `RELEASE.md` still describes v0.9.0

Goal: deliver eight ACs as listed in #54 so that v0.10.0 ships with consistent active-surface authority.

## Skills

- **Tier 1:** CDD canonical (cnos/cdd v3.15.0 — loaded via curl), `cdd/alpha/SKILL.md` (loaded via curl)
- **Tier 2:** `cnos.eng/skills/eng/ocaml` (test authoring), `cnos.eng/skills/eng/document` (active-doc rewrite), `cnos.core/skills/write` (concise status-truth prose)
- **Tier 3 (issue-named):** none beyond Tier 2 — #54 is a perimeter pass, not a new design surface

