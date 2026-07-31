# TSC — β (CDR) independent review

**Matter:** For a first-time technical reader (SWE / CS / AI researcher, zero prior TSC exposure), how friendly is the `tsc` repo to grasp and follow through, and is its asset set coherent, honest, current, and free of legacy narrative?

**Reviewer:** independent β (adversarial). I did not build this repo. Verdicts anchored on the artifact, not its self-description. No repo file edited.

**Scope:** newcomer-facing + structural surfaces. `.cdd/`, `.cn-sigma/`, `heldout/`, `.git/` treated as out-of-scope tooling/data.

---

## 1. Verdict

**REVISE.**

The repository has genuinely strong review hygiene — every first-hop link resolves, version literals agree across all surfaces (`check-version-consistency.sh` PASSES), the conformance plane is internally coherent, and the documents repeatedly and honestly disclaim standing ("does not implement v4", "no conformance standing"). That scaffolding is better than most research repos. But three confirmed, newcomer-facing defects floor the verdict at REVISE:

1. **The headline runnable command does not work as written.** `coh --mode mechanical --files spec/` (README §"Run the current repository proxy"; QUICKSTART §4) passes a bare directory to a globber that only recurses on patterns containing `*`. The spec files are never scored; the path instead attempts to read a directory as a file and raises an uncaught error. The first command a newcomer types produces nothing useful.
2. **README and STATUS contradict each other on the single most important comprehension question — "is any of this normative/ratified?"** README frames the entire theory as `4.1.0 Draft` / "candidate", with nothing ratified; STATUS asserts a ratified `4.0.0 Normative` foundation that is "the current normative warrant infrastructure." No `4.0.0` / `Status: Normative` document is openable anywhere in the tree — every `spec/*.md` header reads `4.1.0 / Draft`. The reader is told a normative contract governs but cannot open it.
3. **The program STATUS names as *primary* is orphaned from the machine-navigable index.** STATUS §"Program priority": "Articulation Ascent is the primary program for the current bounded sprint." It lives in `research/ascent/`. The README repository map — the index a human or AI agent navigates by — never lists `research/`.

Per the rubric ("any confirmed dead reference or misleading claim floors you at REVISE"), items 1 and 2 each independently floor. Add moderate legacy-narrative contamination and undefined-vocabulary dumps and the follow-through experience has real friction. Not NO-GO: nothing is fraudulent, the defects are surgical, and the honesty posture is fundamentally sound.

---

## 2. Oracle results

### O1 — First-contact comprehension — **FAIL**
A cold reader learns the *shape* fast and honestly: README:5-9 states the repo is two surfaces — a `4.1.0 Draft` candidate theory and a `coh 0.12.0` proxy engine that "does not implement TSC v4" — and STATUS reinforces what is real vs. aspirational. That dual-surface honesty is a genuine strength. But comprehension stalls on two things:
- **The normativity contradiction** (see O6/O7): README says everything is Draft/candidate; STATUS asserts a ratified `4.0.0 Normative` foundation is currently governing. The reader cannot resolve "is anything ratified?" from the face.
- **"What TSC is *for*" arrives slowly.** README:3 opens with "TSC defines how a declared methodology may warrant that observations belong to one lawful generative process" — dense for a cold reader. The most legible plain-language intro, `docs/THESIS.md` ("TSC is a theory of warranted coherence claims… It asks: …do these observations support one lawful generative process?"), is not linked from README; it is reachable only via `docs/README.md`. README's "Read the theory" list (README:27-31) sends the newcomer first to `spec/c-equiv.md`, the densest formal layer. `spec/tsc-glossary.md` exists but is linked from neither README nor STATUS.

### O2 — Follow-through / actionability — **FAIL**
- **`coh --mode mechanical --files spec/` (README:46; QUICKSTART §4) does not score the spec.** Confirmed from source: `expand_glob` (`src/engine/ocaml/bin/main.ml:90-94`) only walks a directory when the pattern contains `*`; a bare `spec/` is returned as a single literal path, then `resolve_direct_files` (main.ml:185-194) calls `read_file` on `./spec/`, and `read_file` (main.ml:56-64) has no exception guard around `in_channel_length`/`really_input_string` on a directory — it raises an uncaught `Sys_error` (EISDIR). Best case: empty bundle; realistic case: crash. The working form is a glob (the `spec` *target* manifest uses `spec/**/*.md`, `targets/spec.tsc:7`). I could not execute to observe the exact symptom — the engine does not build in this environment (missing opam libs `otoml`, `ezcurl`) — but the mechanism is unambiguous in source.
- Other commands are sound: `coh --target spec --registry targets/registry.tsc` (QUICKSTART §5) resolves via a glob manifest; `coh self` dispatches to the installed `scripts/coh-self` (exists, executable); `bash scripts/run-katas.sh` exists. The `install.sh` pipe is well-formed but depends on a published GitHub release asset `coh-linux-x64`, which is not verifiable offline.

### O3 — Staleness — **FAIL (link/version hygiene PASSES; semantic staleness present)**
Mechanical resolution of every first-hop reference in README, STATUS, ARCHITECTURE, QUICKSTART, `spec/README.md`, `docs/README.md`:
- **All links resolve. Zero dead references.** (20/20 README targets, all QUICKSTART/docs/spec targets — verified against the filesystem.)
- **Version literals agree everywhere:** `VERSION`=0.12.0, `CITATION.cff`=0.12.0, `dune-project`=0.12.0, README/STATUS/ARCHITECTURE/QUICKSTART all 0.12.0 for software and 4.1.0 Draft for spec. `scripts/check-version-consistency.sh` reports PASSED.
- **Conformance plane is coherent:** `registry.toml` IDs (`foundation-v4`, `gol-ascent-0`, `stochastic-law-v4`, `polar-syntax-v4-1`, `polar-realization-v4-1`) match each `fixture.toml` `id` and the README fixture names, with correct id→directory manifest mapping despite dir names differing from IDs.

The staleness that *does* exist is semantic, not link-level: STATUS asserts `4.0.0 Normative` as "the last ratified specification" and "the current normative warrant infrastructure" (STATUS:5,10), but no `4.0.0` artifact and no `Status: Normative` document exists in `spec/` — all six spec files carry `Version: 4.1.0 / Status: Draft`. The design docs confirm `4.0.0` was ratified in a *prior* cycle (`docs/design/foundation-contract-reconciliation/DESIGN.md:5` targets 4.0.0; the repository-planes ADR:94 calls it "now authoritative (ratified 4.0.0)"), i.e. the ratified text was bumped to `4.1.0 Draft` in place and now survives only as a claim + git history. A status surface pointing at a normative contract that cannot be opened is a stale claim.

### O4 — Legacy / historical-narrative contamination — **FAIL (moderate)**
The repo has *deliberately* demoted most history to `docs/design/` and `research/` (good). But legacy narrative still sits on the face:
- README:33-38 links `ARCHAEOLOGY.md`, `CUTOVER-RECEIPT.md`, `DESIGN.md` under "The motivation and historical evidence live outside the normative specification" — front-page pointers into archaeology/cutover storytelling.
- README:55 "These commands emit v3.2-era repository-proxy results… useful for regression, defect discovery, and **historical comparison** within that methodology."
- STATUS:44-48 "A **historical v2.3 braided witness emitted a failed receipt**. The failure is retained and explicitly disposed in `…/CUTOVER-RECEIPT.md`." — a changelog-style war story a first-timer does not need.
- The `4.0.0 → 4.1` ratified-cutover framing itself (STATUS:8) is migration narrative.

**Distinguish from necessary status (keep these):** "the engine does not implement TSC v4" (STATUS:22, ARCHITECTURE:60-69) and "no engine or methodology conforms yet" are present-tense truth, not legacy narrative. The `v3.2-era` *label* on current outputs is borderline-necessary (it names what the outputs are); the *links to archaeology/cutover receipts* and the *v2.3 anecdote* are the demotable parts.

### O5 — Human + AI friendliness — **FAIL (partial)**
Strengths: entry points are mostly obvious (README → STATUS → spec), and per-document authority is stated (README repo-map "Authority" column; `docs/README.md` "Current authority" table; every spec header carries a Status). An AI agent gets an authority signal per document — unusually good.
Weaknesses:
- The README repository map (the index an agent navigates by) omits `research/` (the *primary* program), `targets/`, `schemas/`, and `runtime/` — all referenced elsewhere as load-bearing. An agent indexing from README cannot place them.
- `docs/THESIS.md` (best plain intro) and `spec/tsc-glossary.md` (the definitional key) are not surfaced from README or STATUS.
- STATUS §"Program priority" (STATUS:58-73) introduces "Articulation Ascent", "C≡ … expression language", "autonomous frame compilation, closure inversion, polar lift", "Body Space", "registered report", "warrant classes", "candidate fibers" — a dense undefined-vocabulary dump on the second document a newcomer opens, with no glossary link at point of use.

### O6 — Asset coherence — **FAIL**
- **README↔STATUS divergence on maturity/normativity** (the central incoherence): README:7, 61-63 = everything is `4.1.0 Draft` / candidate, nothing conforms; STATUS:5,10 = a ratified `4.0.0 Normative` foundation is currently the normative warrant infrastructure. Two authoritative front-surfaces give opposite answers to "is anything ratified?"
- **`research/` orphaned:** contains the STATUS-declared primary program yet is absent from the README map (README:14-24). `research/README.md` is a clean, well-scoped document — the coherence gap is purely that the top-level index doesn't point to it.
- **Unlocatable ratified foundation:** "where do I read the ratified 4.0.0 contract?" has no answer on the face — ironic for a project whose thesis is lineage/provenance.
- Credit: the conformance plane, the spec layer set, and the `docs/` authority table cohere well internally.

### O7 — Honesty / calibration — **FAIL on one claim; strong overall**
Overall calibration is a genuine strength: README:59-64, STATUS:38-42, QUICKSTART:80-81, `conformance/README.md` ("Only `verified` fixtures contribute conformance standing") repeatedly refuse to claim standing the tree doesn't have. That is the honest posture CDR rewards. The single miscalibrated claim: STATUS:10 "The ratified foundation is the current normative warrant infrastructure" (and STATUS:5 "Last ratified specification: 4.0.0 Normative") asserts an operative normative artifact that is not openable in the repo and is flatly contradicted by README's all-Draft framing. Claiming an active normative foundation with no openable normative document is calibration exceeding evidence.

---

## 3. Findings (most severe first)

### F1 — Headline `coh --files spec/` command does not score the spec (likely crashes) — **HIGH (actionability floor)**
**Evidence:** README:46, QUICKSTART §4 (`coh --mode mechanical --files spec/ --output .tsc/`) vs. `src/engine/ocaml/bin/main.ml:90-94` (glob only recurses when pattern contains `*`), `:185-194` (`read_file` on the literal `spec/`), `:56-64` (`read_file` has no guard for reading a directory → uncaught `Sys_error`). Working form is a glob, e.g. `targets/spec.tsc:7` uses `spec/**/*.md`.
**Why it hurts the newcomer:** it is the *first* command in the "run it" path; it fails silently-or-loudly on step one, destroying trust before follow-through begins.
**Named remediation — `fix-files-glob-doc`:** change both occurrences to a working glob (`--files 'spec/**/*.md'`), OR (better) make `resolve_direct_files`/`read_file` treat a bare directory argument as a recursive include and skip directories safely. Doc-only fix clears the newcomer path; the code fix also hardens `read_file` against the EISDIR crash.

### F2 — README and STATUS contradict on whether anything is normative; the ratified `4.0.0` is unopenable — **HIGH (comprehension + honesty floor)**
**Evidence:** README:7, 61-63 (all `4.1.0 Draft`, nothing conforms) vs. STATUS:5, 10 ("Last ratified specification: 4.0.0 Normative"; "the current normative warrant infrastructure"); every `spec/*.md:3-4` header = `4.1.0 / Draft`; no `Status: Normative` anywhere in `spec/` (grep confirms only the *definition* of the word in `spec/README.md:82`).
**Why it hurts the newcomer:** "is any of this ratified/trustworthy?" is the load-bearing question for a technical evaluator, and the two front documents answer it oppositely, with the asserted ratified artifact impossible to open.
**Named remediation — `reconcile-normativity`:** pick one true story and state it identically in README and STATUS. Either (a) the openable spec is `4.1.0 Draft` and `4.0.0 Normative` is a git-tagged historical contract (name the tag/commit so it *is* locatable), or (b) restore an openable `4.0.0`-Normative artifact (or mark which sections of the `4.1.0` files retain ratified-4.0.0 normative force vs. draft-4.1 additions). Delete the maturity mismatch between the two surfaces.

### F3 — Primary program `research/` is orphaned from the README index — **MEDIUM**
**Evidence:** STATUS:59 "Articulation Ascent is the primary program for the current bounded sprint"; lives in `research/ascent/` (`research/README.md`); README repo map (README:14-24) omits `research/` entirely (only the word "research" appears, pointing at `docs/`).
**Why it hurts the newcomer:** a human or AI agent navigating by the top-level index cannot find the work STATUS says is most important right now.
**Named remediation — `map-research-plane`:** add a `research/` row to the README repository map with its authority ("pre-normative investigation; nothing here binds an implementation", per `research/README.md`), and cross-link STATUS §"Program priority" → `research/ascent/`.

### F4 — Legacy narrative on the newcomer face — **MEDIUM**
**Evidence:** README:33-38 (front-page links to `ARCHAEOLOGY.md`, `CUTOVER-RECEIPT.md`), README:55 ("historical comparison"); STATUS:44-48 (the "historical v2.3 braided witness emitted a failed receipt … disposed in CUTOVER-RECEIPT.md" anecdote).
**Why it hurts the newcomer:** archaeology/cutover storytelling and a v2.3 receipt anecdote consume first-contact attention that should go to *what TSC is now* and force the reader to carry version-history vocabulary they don't need.
**Named remediation — `demote-legacy-narrative`:** move the archaeology/cutover pointers and the v2.3 anecdote out of README/STATUS into `docs/design/` (where the receipts already live) or an explicit archive/history plane; keep only present-tense status on the face. Retain "the engine does not implement v4" — that is necessary status, not narrative.

### F5 — Best intro and glossary not surfaced; vocabulary dumped undefined — **MEDIUM**
**Evidence:** `docs/THESIS.md` and `spec/tsc-glossary.md` linked from neither README nor STATUS; README:27-31 sends newcomers first to the densest formal layer; STATUS:58-73 introduces ≥7 undefined terms.
**Why it hurts the newcomer:** the target reader is technical but TSC-naive; the assets that would orient them fastest (thesis, glossary) are buried, and the second document overwhelms with undefined jargon.
**Named remediation — `surface-orientation-assets`:** add a one-line "New here? Read `docs/THESIS.md` first, keep `spec/tsc-glossary.md` open" pointer near the top of README; link the glossary at the first dense-vocabulary use in STATUS §"Program priority".

---

## 4. What works (honest credit)

- **Link and version hygiene is excellent.** Zero dead first-hop references across all newcomer/structural surfaces; all version literals agree; the repo's own `check-version-consistency.sh` passes. The staleness hunt found no broken paths — rare.
- **Honesty posture is fundamentally sound.** README, STATUS, QUICKSTART, and `conformance/README.md` repeatedly refuse conformance/standing the tree hasn't earned ("no v4 conformance standing", "Only `verified` fixtures contribute standing", "no command currently emits a passing v4 conformance receipt"). This is the disposition CDR rewards.
- **Per-document authority is stated** (README "Authority" column; `docs/README.md` "Current authority" table; every spec header carries a Status) — strong for both human and AI navigation.
- **The conformance plane is coherent** end to end: registry IDs ↔ fixture IDs ↔ README names ↔ manifest paths all agree.
- **The source/status boundary is real and enforced**, not just asserted: ARCHITECTURE §4 enumerates precisely what the engine does *not* do, and the code matches (the engine genuinely emits v3.2-era proxy reports).

---

## 5. The single highest-leverage fix

**`reconcile-normativity` (F2).** One coherent, identical answer across README and STATUS to "is any of TSC ratified/normative, and where do I read it?" is the load-bearing comprehension unblock: it removes the contradiction a technical evaluator hits within the first two documents, and it forces the ratified `4.0.0` to become *locatable* (a tag, a commit, or a marked artifact) instead of an unopenable assertion. It simultaneously improves O1, O6, and O7. (Cheapest independent floor-clearer is F1 — a two-line glob edit — and it should ship in the same revision, but it does not fix comprehension the way F2 does.)

---

*β close-out: REVISE. Findings named, none deferred. No repo file edited; the engine was not executed (build blocked by missing opam deps `otoml`/`ezcurl`) — the one execution-dependent finding (F1) is anchored on source with the exact runtime symptom marked as not-observed. All link/version claims verified against the filesystem.*
