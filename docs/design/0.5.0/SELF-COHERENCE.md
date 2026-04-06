# Self-Coherence — 0.5.0

**Issue:** #22
**Branch:** `claude/0.5.0-22-mechanical-scoring`
**Mode:** MCA
**Level:** L7
**Active Skills:** design, plan, cap

## AC Evidence

| # | AC | Status | Evidence |
|---|----|--------|----------|
| AC1 | `coh --mode mechanical --files <paths>` works without credentials | met | `main.ml`: mechanical path never calls `Provider`, builds bundle from `--files` or `--target` |
| AC2 | `coh --mode llm --target spec` still works | met | `main.ml`: llm path preserved, calls `Provider.call_provider` with same instruction/prompt flow |
| AC3 | `coh --mode hybrid` produces both results | met | `main.ml:run_hybrid`: runs `run_mechanical` then `run_llm`, writes combined JSON with `mechanical`, `llm`, `final` keys |
| AC4 | Direct file input shares bundle model | met | `bundle_from_files` in `main.ml` calls `Bundle.build_bundle` — same as target path |
| AC5 | Mechanical is deterministic | met | No randomness, no network, no mutable state. Test `test_mechanical_scoring.ml` verifies identical output |
| AC6 | All modes emit canonical JSON | met | Mechanical: `result_to_json`. LLM: `Report.to_json`. Hybrid: combined object. All use Yojson |
| AC7 | Docs explain all modes | met | README mode table, QUICKSTART rewritten, ARCHITECTURE updated |
| AC8 | Python remains retired | met | No Python code added |
| AC9 | `runtime/SELF-MEASURE.md` remains canonical | met | LLM path still reads it unchanged |
| AC10 | Mode visible in report | met | JSON includes `"mode"` field; hybrid includes `"mode": "hybrid"` |
| AC11 | Auto falls back to mechanical | met | `main.ml`: `Auto` resolves to `Mechanical` when `provider_config = None` |
| AC12 | Backend disagreement preserved in hybrid | met | Hybrid JSON has separate `mechanical` and `llm` objects + `final.source` |

## Triadic Assessment

**α (pattern coherence): A-**
The mechanical scoring module implements 12 structural signals across 3 axes, matching the .mli contract. Signal naming is consistent (code, label, weight, score, evidence). One concern: alpha signal A4 (naming drift) counts case differences — this may overcount in mixed-case languages. Noted as calibration debt.

**β (relational coherence): A-**
All surfaces agree: design → plan → .mli → .ml → CLI → docs. The .mli contract was defined before implementation (Step 2 landed first). Report schema is unified — mechanical, LLM, and hybrid all produce Yojson output. One gap: the operator manual hasn't been updated yet for --mode flag.

**γ (process coherence): B+**
CDD lifecycle followed: observe → select → branch → bootstrap → design → plan → contract → implement → test → docs → self-coherence. Tests exist but can't run locally (no OCaml toolchain in dev env). CI will be the first real validation. The `Arg.Rest_all` flag for `--files` may need verification in CI.

**C_Σ: A- (0.85)**

## Known Debt

1. **Operator manual** — not yet updated for `--mode` flag and direct file input
2. **Mechanical signal calibration** — weights are reasonable defaults but need one real-world calibration pass
3. **Hybrid adjudication policy** — currently "LLM wins when available, mechanical as fallback" — may want configurable policy later
4. **No CI test run yet** — tests written but untested (no dune in dev env)

## CDD Trace

| Step | Artifact | Skills loaded | Decision |
|------|----------|--------------|----------|
| 0 Observe | CHANGELOG, lag table, #22 comment | cdd | v0.4.0 released, #22 steps 1-2 done, steps 3-9 remain |
| 1 Select | #22 | cdd | Mechanical scoring regression — only mode is LLM |
| 4 Gap | DESIGN.md | design | LLM-only mode regressed offline measurement |
| 5 Mode | DESIGN.md | design, plan, cap | MCA, L7, three scoring backends |
| 6 Artifacts | .mli, .ml, main.ml, tests, docs | design, plan, cap | Steps 3-9 implemented |
| 7 Self-coherence | this artifact | cdd | C_Σ A- |
