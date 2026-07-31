# 03 — β path & residual-noise audit

Independent β, `cleanup` domain. Instruments: cnos write skill (L7) + filesystem path resolution. No repo file edited. Round-02's 12 findings verified actioned, not re-litigated.

Method (Job A): resolved every markdown link and every backtick-span path token in the in-scope doc set against the filesystem, each relative to its own file dir and to repo root. Out of audit scope: `.cdd/`, `.cn-sigma/`, `.cell/`, `heldout/`, `.git/`, `.tsc/`, `_build/`, `.claude/`, frozen `docs/alpha|beta|gamma/`. Adversarial negative-control inputs (`katas/02`, `katas/03/input/random-soup`, `katas/05/input`) carry deliberately broken links as test data and are excluded.

## 1. Verdict

**REVISE.** Live surfaces carry dead and false references: a fabricated parser-plugin contribution model in two contributor-facing files, two stale moved-tree references, and 42 relative links left one level too shallow by the `engine/`→`src/engine/` and `skills/`→`src/skills/` directory moves.

## 2. Dead / stale references (Job A)

### 2a. Fabricated parser-plugin model — false content (α must supply correct content)

The engine (`src/engine/ocaml/lib/`) is a coherence scorer over file bundles: `bundle.ml`, `prompt.ml`, `mechanical_scoring.ml`, `response_schema.ml`. It has no parser-plugin framework, no `parsers/` dir, no dispatch module. The real contribution model lives in `README.md:85-90` (name the surface, prove its contract). Both files below document a model that does not exist; a contributor following either hits missing directories.

- `CONTRIBUTING.md:46` · "New parsers for additional data formats" · no parser subsystem exists · α must supply correct content (or point to `README.md` model).
- `CONTRIBUTING.md:141-163` · entire "Adding a New Parser" section · references `src/engine/ocaml/lib/parsers/` (`:147`, missing), `examples/your_format/` (`:152`, `examples/` missing), `tests/ocaml/conformance/` (`:153`, `tests/ocaml/` missing), "parsers dispatch module" (`:150`, absent) · remove section; α must supply correct content.
- `CONTRIBUTING.md:13` · TOC entry "Adding a New Parser" · dangles once `:141` section is cut · remove with the section.
- `CONTRIBUTING.md:170,172` · License paths `engine/` (moved to `src/engine/`), `tests/` (absent), `examples/` (absent) · stale tree · α must supply correct paths for the license split.
- `.github/pull_request_template.md:64-72` · "For New Parsers" checklist · `src/engine/ocaml/lib/parsers/` (`:67`), `examples/` (`:70`), `tests/ocaml/conformance/` (`:71`), "parsers dispatch module" (`:69`) · same fiction, shown to every PR author · remove section; α must supply correct content.

### 2b. Stale moved-tree references (fix = repoint; target exists)

- `katas/04-philosophical/README.md:26` · `examples/philosophical/consciousness.md` (link `../../examples/philosophical/consciousness.md`) · `examples/` moved; real file is `docs/concepts/illustrations/philosophical/consciousness.md` · repoint.
- `CHANGELOG.md:110` · standing ledger preamble links `engine/ocaml/CONTRACT.md` · engine moved; real path `src/engine/ocaml/CONTRACT.md` · repoint. (Dated CHANGELOG *entries* citing `engine/…` — e.g. `:8-13`, `:171-296` — are frozen release history, correct at authoring time; left as record genre.)

### 2c. Off-by-one relative links from directory moves (fix = add one `../`; every target exists at repo root)

The skills moved `skills/`→`src/skills/` and the engine `engine/`→`src/engine/`; the `../../` prefixes were never deepened. All 42 links resolve by prepending one `../`.

- `src/skills/self-measure/SKILL.md` · 25 dead relative links (`:179,199,208,212,214,216,221,222,232,257-267,321,363,378,473`) · targets (`schemas/skill.cue`, `targets/registry.tsc`, `src/engine/ocaml/lib/*.ml`, `scripts/*`, `runtime/SELF-MEASURE.md`, `.github/workflows/*.yml`) all exist at root · add one `../`.
- `src/skills/cm-of-cms/SKILL.md` · 15 dead relative links (`:156,175,203,207,208,226,228,285,286,287,288,350,354,463`) · same target set · add one `../`.
- `src/engine/ocaml/CONTRACT.md:37` · `../../spec/tsc-conformance.md` resolves to `src/spec/…` · add one `../`.
- `src/engine/ocaml/README.md:64` · `../../spec/tsc-conformance.md` resolves to `src/spec/…` · add one `../`.

## 3. Residual noise (Job B)

Job B is largely clean — round-02's line-level cuts hold and the fresh full read of `CONTRIBUTING.md` surfaced no prose noise beyond the false-model sections (Job A owns those). Only two minor items:

- `CONTRIBUTING.md:182` · "Check existing issues first" · **3.3 duplicate** — restates `:33` "Search existing Issues first" within the same file · cut the `:182` bullet.
- `CONTRIBUTING.md` overall · generic OSS-template scaffolding (Support Matrix, Conventional-Commits block, PR checklist) is genre-appropriate and load-bearing for contributors; no cut warranted beyond the false-model excision.

`RELEASE.md` (dated 0.12.0 record) is dense but within release-note genre; every path it names (`factorized-beta-measure.yml`, `scripts/validate-release-gate.sh`, `factorized-beta-controls.json`, `METER-LOOP-DECISION.md`, `ci.yml`) resolves. No noise flagged.

## 4. Round-02 verification

All 12 cuts held; no meaning lost; no new noise introduced.

- F1 `CONTRIBUTING.md` "Code Organization" list — gone; no duplicate remains.
- F2 `CONTRIBUTING.md:3` — now "This guide explains how to propose changes to TSC."
- F3 `CONTRIBUTING.md` "Thank you…" close — gone; file ends at "Questions?".
- F4 `THESIS.md:19` — positive claim only; decorative "not three independent views" gone.
- F5 `README.md:68` — ends at commit `4da1122` pointer; STATUS re-narration gone; routing to STATUS preserved at `:12`.
- F6 `STATUS.md` — decorative "changes neither… nor…" closer gone.
- F7 `ARCHITECTURE.md:3` — "This document explains the repository's authority boundaries." (single job).
- F8 `STATUS.md:10` — preview clause gone; `## Program priority` (`:52`) owns the Ascent fact.
- F9 `STATUS.md:8` — "No engine or methodology conforms to 4.1 yet." (one clause).
- F10 `src/skills/self-measure/SKILL.md` §"The coherence ledger" — split into one-move paragraphs (ledger / backfill / hybrid-row reliability / append trigger / main authority / historical backfill / artifacts); no words cut. (Its `:473` link is a §2c off-by-one, pre-existing, not a round-02 regression.)
- F11 `README.md:7` — "The repository contains two surfaces:".
- F12 `CONTRIBUTING.md:38` — "Explain the use case, proposed behavior, and who benefits"; filler prompt gone.

## 5. Clean surfaces (honest credit)

- `README.md`, `STATUS.md`, `ARCHITECTURE.md`, `QUICKSTART.md`, `docs/THESIS.md` — every markdown link resolves; front-loaded; round-02 cuts intact.
- `research/README.md` — `KERNEL.md` (`:22`) and `conformance/ascent/` (`:27`) are correctly framed as not-yet-written / future, not dead references.
- `docs/design/foundation-contract-reconciliation/ARCHAEOLOGY.md` and `docs/design/0.5.0/**` — `engine/…` and `core/…` path tokens are archaeological / prior-cycle-snapshot citations of the old layout, correct for their historical genre.
- `RELEASE.md` — all referenced paths resolve.
- `.tsc/COHERENCE.md` link from `README.md:26` resolves; `src/skills/self-measure/SKILL.md:274` `docs/papers/DUMB-MODELS-SMART-CELLS.md` is a cnos cross-repo citation (exists in cnos), not a local claim.

## 6. Out of scope

The parser-plugin model is not merely verbose — it is false against the engine's actual surface, and it contradicts `README.md`'s real contribution model. Its *removal* is cleaning (in scope, §2a). Its *correct replacement* is a content-truth decision requiring the real contribution model — α must supply. No behavior, logic, or spec change is implied.
