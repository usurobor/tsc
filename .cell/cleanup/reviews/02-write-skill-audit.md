# 02 — β write-skill audit

Independent β, `cleanup` domain. Instrument: cnos write skill at L7. No repo file edited. Current state audited; findings 01 already actioned, not re-litigated.

## 1. Verdict

**REVISE.** Noise remains — one AI-boilerplate doc (`CONTRIBUTING.md`), one decorative-contrast restatement in `THESIS.md`, and three cross-file/intra-file restatements of the "nothing conforms to 4.1" stable fact.

## 2. Noise inventory (worst first)

1. `CONTRIBUTING.md:84-89` · the "Code Organization" list restates "Coding Standards → OCaml Style" (`:79-82`): "pure functions and immutable data" (`:81`,`:86`), "Keep modules small / functions small and focused" (`:81`,`:87`), `.mli` interface files (`:81`,`:88`) · **3.3 / 3.14 duplicate stable fact** · merge into one list; drop the "Code Organization" subsection.

2. `CONTRIBUTING.md:3` · "Thanks for your interest in contributing! This guide explains how to propose changes and what we expect." · **3.5 cut throat-clearing** · "This guide explains how to propose changes to TSC."

3. `CONTRIBUTING.md:192` · "Thank you for contributing to TSC!" · **3.5 / 3.15 throat-clearing close** · cut the line.

4. `THESIS.md:20` · "They are not three independent views and are not freely permutable axes." · **3.1 / 1.5 decorative contrast** — the prior sentence "The roles are non-substitutable and asymmetrically dependent" already states it positively · cut the second sentence.

5. `README.md:68` · "…This matches [`STATUS.md`](STATUS.md): 4.0.0 Normative is the standing warrant infrastructure; nothing conforms to 4.1 yet." · **3.3 duplicated stable fact + 3.5 commentary** — README already routes to STATUS at `:12`; the clause re-narrates STATUS · end the sentence at the `4da1122` commit pointer; drop "This matches STATUS.md: …".

6. `STATUS.md:66-67` · "This priority declaration changes neither the normative status of TSC v4 nor the conformance standing of the current engine." · **3.1 decorative "changes neither X nor Y" + 3.3** — the no-conformance fact is already at `:6` and `:8` · cut the sentence.

7. `ARCHITECTURE.md:1` · "This document explains the repository's authority boundaries while TSC 4.1 extends the ratified v4 foundation with an optional polar source language." · **1.3 / 3.4 two jobs in the governing sentence** — the "while TSC 4.1 extends…" clause is STATUS's fact · "This document explains the repository's authority boundaries."

8. `STATUS.md:10-11` · "The current bounded research sprint develops Articulation Ascent as the generative program that uses it (see `## Program priority`)." · **1.4 / 3.3 intra-file duplicate** — restated as the section's own opening at `:52` "Articulation Ascent is the primary program for the current bounded sprint." · drop the preview clause; let §Program priority own it.

9. `STATUS.md:8` · "The current engine is nonconforming to 4.1; no engine or methodology conforms yet." · **3.14 two clauses, one fact** — also restates the `:6` header "4.1 conformance standing: none" · keep one clause: "No engine or methodology conforms to 4.1 yet."

10. `src/skills/self-measure/SKILL.md:450-477` · §6 "The coherence ledger" is one ~28-line paragraph carrying release cadence, backfill rule, branch policy, and standing rule · **2.3 one move per paragraph** · split into paragraphs (cadence / backfill / branch-authority / standing); no words cut — the content is load-bearing.

11. `README.md:7` · "The repository currently contains two different surfaces:" · **2.5 word does no work** — two surfaces are by definition different · "The repository contains two surfaces:".

12. `CONTRIBUTING.md:39` · "Why would this benefit most users?" · **3.8 / 2.5 filler prompt** · fold into the preceding line ("Explain the use case, proposed behavior, and who benefits").

## 3. Cross-file duplication

- **"The current `coh` engine does not implement TSC v4 / is v3.2-era."** Stated in `STATUS.md:8,22-23`, `README.md:11,58`, `ARCHITECTURE.md:71`, `QUICKSTART.md:3`, `THESIS.md:65`, `src/engine/ocaml/README.md:5`. This is a distinction that prevents error (3.14 — keep a one-line pointer per file). **Home: `STATUS.md`.** Other files should carry one pointer only, not a re-explanation — Finding 5 (`README.md:68`) is the one instance that re-narrates rather than points.
- **"Nothing conforms to 4.1 until fixtures are verified."** `STATUS.md:6,38`, `README.md:64`, `conformance/README.md:20`, `katas/README.md:5`, `spec/README.md:85`. Each home phrases it for its own surface (conformance owns the fixture-verification rule; STATUS owns the standing line). Acceptable — no single restatement is removable except Finding 6's decorative closer.

## 4. Clean surfaces (honest credit)

- `QUICKSTART.md` — front-loaded, one governing question, numbered runnable path, honest close.
- `docs/README.md` — pure routing table; no restatement.
- `spec/README.md` — layers, reading order, ratification gate; each word works.
- `src/engine/ocaml/README.md` and `CONTRACT.md` — terse, positive claims, single home for the pin.
- `conformance/README.md`, `conformance/game-of-life/README.md`, `katas/README.md`, `research/README.md` — one job each, no filler.
- `docs/concepts/illustrations/README.md` and `philosophical/README.md` — tight non-normative disclaimers.
- `src/skills/README.md` — dense but every clause load-bearing.
- OCaml doc-comments (`src/engine/ocaml/lib/**`, `bin/**`, sampled `mechanical_scoring.ml`, `coherence.ml`, `factorized_beta.ml`, `types.ml`, `main.ml`) — terse, technical, no throat-clearing.
- `docs/architecture/decisions/repository-planes.md` — verbose by ADR genre (Context/Decision/Migration), but the density is rationale, not filler; passes.

## 5. Out of scope (noted, not for this cell)

None. No bug or false claim surfaced in this cleaning pass. (Review 01's F1 glob defect and normativity contradiction read as actioned in the current tree: `README.md:49` uses `--files 'spec/**/*.md'`; `README.md:68` / `STATUS.md:5` now locate 4.0.0 Normative at commit `4da1122`.)
