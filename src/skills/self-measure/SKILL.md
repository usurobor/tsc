---
name: self-measure
description: >-
  How TSC measures itself. Declares the full self-measurement procedure —
  the targets, the deterministic (mechanical) work, and the one narrowly
  scoped cognitive task delegated to an LLM — and is rendered into the
  `coh self` command and the tsc-self-measure workflow by
  scripts/render-self-measure.sh. Frontmatter is validated by
  schemas/skill.cue (#SelfMeasure); the declared signal codes and estimate
  fields are cross-checked against the engine source and the scoring
  instruction, so this declaration cannot silently drift from what runs.
governing_question: >-
  When TSC measures itself, which parts of the measurement are
  deterministic machine work, and exactly what cognitive work is delegated
  to an LLM, under what constraints?
artifact_class: measurement
scope: repo
kata_surface: none
triggers:
  - coh self
  - self-measure
  - self-measurement
  - tsc self-coherence
inputs:
  - "targets/registry.tsc (named targets: spec, engine, repo)"
  - "runtime/SELF-MEASURE.md (canonical LLM scoring instruction)"
  - "LLM credentials or an external witness response (optional — hybrid/llm modes only)"
outputs:
  - ".tsc/self/ — per-target reports (mechanical, llm, or hybrid) + cross-target report"
  - "validation-failure artifacts when an LLM response fails the v3.2 contract"
visibility: public
self_measure:
  command: coh-self
  registry: targets/registry.tsc
  targets:
    - spec
    - engine
    - repo
  cross_target: true
  instruction: runtime/SELF-MEASURE.md
  output_root: .tsc/self
  default_mode: auto
  consistency:
    mechanical: identical
    llm_repeats: 3
    llm_spread: >-
      max absolute pairwise difference over the response contract's
      numeric fields; delta_consistency maps through the barrier
      phi(delta) = delta/(1-delta) to Coh_consistency = exp(-phi)
      (frozen v3.2.2 proxy barrier, src/engine/ocaml/CONTRACT.md; lambda = 1). Reported alongside (A/B
      labeled, Issue D): the k-fair companion — MEAN absolute pairwise
      difference per field, max across fields, same barrier — under
      *_mean_pairwise names; max-pairwise stays the conservative
      standing metric unless separately promoted. A report also
      carries declared/validated/refused sample counts and refusal
      stage counts; a short yield fails the k-fair experiment
      regardless of score
    adjudication: >-
      medoid-of-k (v3.2.3): the adjudicated response is the FUNNEL-VALID
      sample with minimum total L1 distance to the other valid samples
      over the same numeric fields the spread is computed on
      (coh witness-medoid --target, src/engine/ocaml/lib/witness_medoid.ml)
      — a real witness response, never first-sample order luck, never a
      sample the funnel refuses; zero valid samples withholds
      adjudication and records a no_valid_witness_samples artifact
      instead of failing the pipeline; adjudication never changes the
      spread
    script: scripts/cm-consistency.sh
  mechanical:
    backend: src/engine/ocaml/lib/mechanical_scoring.ml
    determinism: >-
      identical bundle + config -> identical result; no LLM, no network
      I/O, no semantic parsing of file contents
    signals:
      alpha:
        - alpha.terminology_consistency
        - alpha.repeated_structure
        - alpha.duplicate_definition_tension
        - alpha.naming_drift
      beta:
        - beta.cross_reference_consistency
        - beta.authority_alignment
        - beta.source_of_truth_alignment
        - beta.target_file_fit
      gamma:
        - gamma.canonical_generated_distinction
        - gamma.version_surface_consistency
        - gamma.traceability_presence
        - gamma.authority_evolution_consistency
  llm:
    estimates:
      - target
      - alpha
      - beta
      - gamma
      - delta_alpha_beta
      - delta_beta_gamma
      - delta_gamma_alpha
      - bottleneck_axis
      - confidence
      - summary
      - axis_evidence
      - defect_cards
      - unresolved_ambiguity
      - next_fixes
    must_not:
      - >-
        compute Coh or C_sigma values — the engine applies the barrier
        transform phi(delta) = delta/(1-delta) and the aggregate forms
        deterministically after validation
      - >-
        read anything beyond the emitted prompt (instruction + hashed
        file bundle)
      - >-
        write anything beyond its single JSON response artifact
      - >-
        output anything except the JSON object required by the scoring
        instruction's output contract
    validation: >-
      src/engine/ocaml/lib/response_schema.ml (validate_witness_response) —
      one funnel for every refusal stage: parse, base_schema,
      prohibited_fields (computed Coh/C_sigma), target_mismatch,
      v3_2_delta, checklist (v3.2.3 defect walk missing or malformed),
      defect_cards (v3.2.4 structured cards missing, malformed, or
      disagreeing with the checklist).
      Any refusal produces a durable validation-failure
      artifact naming its stage, preserves the raw response, renders no
      coherence report, and never falls back to mechanical scoring
    providers:
      local: >-
        engine HTTP route — LLM_PROVIDER / LLM_MODEL / LLM_API_KEY
        (docs/beta/guides/OPERATOR-MANUAL.md section 3)
      ci: >-
        claude-cli — a pinned Claude CLI invocation in the rendered
        workflow (the renderer owns the version pin), permitted only to
        read the emitted prompt and write the response JSON; the engine
        ingests the response via --llm-response
    ci_prompt: |
      You are the LLM witness step of TSC self-measurement, rendered from
      src/skills/self-measure/SKILL.md. Your entire task:

      1. Read the file .tsc/self/prompt/{target}.md. It contains the
         canonical scoring instruction (runtime/SELF-MEASURE.md) followed
         by the {target} target bundle. Follow that instruction exactly.
      2. Write your answer — the single JSON object the instruction
         requires, with no markdown fences and no prose around it — to
         .tsc/self/response/{target}.json.

      Constraints (your tool permissions also enforce them):
      - Do not read any file other than .tsc/self/prompt/{target}.md.
      - Do not write any file other than .tsc/self/response/{target}.json.
      - Do not compute Coh or C_sigma values; report the delta and
        component estimates the instruction asks for. The engine applies
        the barrier transform and aggregation deterministically after
        validating your output, and rejects the response if any required
        delta field is missing or out of range.
  render:
    command_out: scripts/coh-self
    workflow_out: .github/workflows/tsc-self-measure.yml
  ledger:
    path: .tsc/COHERENCE.md
    cadence: version-increments
    mode: hybrid
    semantic_samples: 3
    script: scripts/coherence-ledger.sh
    workflow_out: .github/workflows/tsc-coherence-ledger.yml
  ci:
    llm_secret: CLAUDE_CODE_OAUTH_TOKEN
    llm_gate: secret-presence
    permission_intent:
      - contents.read
---

# Self-measurement

> **Frozen repository-proxy methodology — not TSC v4.** This skill
> declares the CURRENT repository-proxy self-measurement methodology. Its
> semantic contract is the immutable v3.2.2 pin recorded in
> [`src/engine/ocaml/CONTRACT.md`](../../../src/engine/ocaml/CONTRACT.md), not the
> live `spec/` bodies. The symbols α, β, γ used below are this proxy's
> three independent scalar coherence axes. They are **not** TSC v4's
> α/β/γ, which the normative spec defines as non-substitutable,
> asymmetrically-dependent receipt roles (manifestation atlas,
> relational atlas, continuation), never independent scalar axes. Where
> this document cites a barrier transform, aggregate, or cross-target
> formula, the binding definition is the frozen v3.2.2 proxy contract
> above, not the v4 section that now occupies the same number.

TSC measures whether three descriptions of a system still describe one
system. This skill declares how TSC turns that instrument on itself — and
draws the exact line between the parts a machine computes and the one part
a model estimates.

This is the **1st coherence methodology**: the tsc-repo CM applied to its
own repo. (The 0th is the CM of CMs — `src/skills/cm-of-cms/SKILL.md`, the
methodology that measures methodologies, this one included; each
methodology's corpus is measured as a closed system, so cross-methodology
references are plain paths, not links.) The typed contract it satisfies —
[`#CoherenceMethodology`](../../../schemas/skill.cue) — is deliberately
general: a methodology names its corpus (registry + targets), its
mechanical signal inventory, its LLM estimate contract and prohibitions,
its output and ledger conventions. Anyone can supply their own CM (a
software-tool-repo methodology, a paper-corpus methodology, ...) by
conforming to that schema; `coh` consuming a supplied methodology is the
declared direction of travel.

The declaration is executable.
[scripts/render-self-measure.sh](../../../scripts/render-self-measure.sh)
renders the frontmatter above into three artifacts, each carrying a
DO-NOT-EDIT header that points back here:

- [scripts/coh-self](../../../scripts/coh-self) — the local command. The
  engine dispatches `coh self` to it (git-style external subcommand).
- [.github/workflows/tsc-self-measure.yml](../../../.github/workflows/tsc-self-measure.yml)
  — the CI measurement surface.
- [.github/workflows/tsc-coherence-ledger.yml](../../../.github/workflows/tsc-coherence-ledger.yml)
  — the per-release ledger writer (§6).

CI re-renders and diffs on every change, so the rendered artifacts cannot
drift from this file. The frontmatter is validated against
[schemas/skill.cue](../../../schemas/skill.cue) (`#SelfMeasure`), and the
validator ([scripts/ci/validate-skill-frontmatter.sh](../../../scripts/ci/validate-skill-frontmatter.sh))
additionally checks that every declared mechanical signal code exists in
the engine source and that the declared LLM estimate fields equal exactly
the scoring instruction's output-contract keys. What you read here is
what runs.

---

## 1. What is measured

Three named targets from [targets/registry.tsc](../../../targets/registry.tsc):

| Target | Kind | Corpus |
|--------|------|--------|
| `spec` | theory | `spec/**/*.md` — the canonical theory |
| `engine` | implementation | `src/engine/ocaml/**` — the verifier |
| `repo` | aggregate | `spec` + `engine` + integration surfaces (README, ARCHITECTURE, targets, scoring instruction) |

Each target is resolved into a deterministic bundle: ordered files, raw
text, SHA-256 per file. Bundles are built the same way in every mode.
A mechanical cross-target report (geometric mean over per-target
aggregates, per the frozen v3.2.2 proxy contract in
`src/engine/ocaml/CONTRACT.md`) covers all three.

Reports land in `.tsc/self/`. Generated state is never canonical
(ARCHITECTURE.md); the directory is gitignored.

---

## 2. The split

One table. Everything TSC self-measurement does, and who does it.

| # | Step | Owner | Where |
|---|------|-------|-------|
| 1 | Resolve targets, expand globs, order files | mechanical | [target_registry.ml](../../../src/engine/ocaml/lib/target_registry.ml) |
| 2 | Build bundle: raw text + SHA-256 hashes | mechanical | [bundle.ml](../../../src/engine/ocaml/lib/bundle.ml) |
| 3 | Score 12 structural signals per axis | mechanical | [mechanical_scoring.ml](../../../src/engine/ocaml/lib/mechanical_scoring.ml) |
| 4 | Assemble the LLM prompt (instruction + metadata + bundle) | mechanical | [prompt.ml](../../../src/engine/ocaml/lib/prompt.ml) |
| 5 | **Estimate δ per axis pair + component scores + cite evidence** | **LLM** | [runtime/SELF-MEASURE.md](../../../runtime/SELF-MEASURE.md) |
| 6 | Validate the LLM response (strict v3.2 delta contract) | mechanical | [response_schema.ml](../../../src/engine/ocaml/lib/response_schema.ml) |
| 7 | Barrier transform φ(δ) = δ/(1−δ), Coh = exp(−λ·φ(δ)) | mechanical | [coherence.ml](../../../src/engine/ocaml/lib/coherence.ml) |
| 8 | Aggregate C_Σ^math / C_Σ^num (geometric forms, ε-floor) | mechanical | [coherence.ml](../../../src/engine/ocaml/lib/coherence.ml) |
| 9 | Bottleneck rule, provenance, report emission | mechanical | [report.ml](../../../src/engine/ocaml/lib/report.ml), [hybrid_scoring.ml](../../../src/engine/ocaml/lib/hybrid_scoring.ml) |
| 10 | Cross-target aggregate | mechanical | [cross_target.ml](../../../src/engine/ocaml/lib/cross_target.ml) |
| 11 | CI gating, artifact upload, summaries | mechanical | [rendered workflow](../../../.github/workflows/tsc-self-measure.yml) |

Step 5 is the only cognitive step. In `mechanical` mode it is skipped
entirely and the run is credential-free and offline. In `llm` / `hybrid`
modes it is delegated to a model under the constraints in §4.

This is the dumb-models boundary (cnos,
`docs/papers/DUMB-MODELS-SMART-CELLS.md`): the model is a witness, not an
authority. It produces estimates for the engine; the engine validates,
transforms, aggregates, and decides. Capability is rented; authority is
owned.

---

## 3. Mechanical mode

`coh self --mode mechanical` — deterministic, credential-free, offline.

The mechanical backend scores structural proxies for the three axes.
Document-structure signals (headings, links, authority claims, filename
fit) measure the bundle's Markdown documents — code is not a document;
corpus-level signals (versions, generated markers, deprecation language,
traceability) scan every file. Links normalize relative to their source
document, and an anchored link must name a real heading in its target.
Twelve signals, four per axis:

**α — pattern coherence** (stable internal structure)

- `alpha.terminology_consistency` — key terms used consistently across files
- `alpha.repeated_structure` — recurring structural conventions
- `alpha.duplicate_definition_tension` — same thing defined twice, differently
- `alpha.naming_drift` — one concept, several spellings

**β — relational coherence** (the parts fit together)

- `beta.cross_reference_consistency` — internal references resolve
- `beta.authority_alignment` — authority claims match declared roles
- `beta.source_of_truth_alignment` — repeated facts agree
- `beta.target_file_fit` — the manifest matches what the bundle contains

**γ — process coherence** (survives change)

- `gamma.canonical_generated_distinction` — canonical vs generated is explicit
- `gamma.version_surface_consistency` — version claims agree
- `gamma.traceability_presence` — changes can be traced
- `gamma.authority_evolution_consistency` — future change paths are owned

Each signal carries its evidence into the report. Axis scores feed the
canonical aggregate (frozen v3.2.2 proxy contract,
`src/engine/ocaml/CONTRACT.md`): C_Σ^math is the strict
geometric mean (zero if any axis is zero), C_Σ^num the ε-floored numerical
form (ε = 10⁻⁵) that carries verdicts. No flat aggregate field exists;
readers consult `provenance.aggregate_numeric.C_sigma_num`.

Guarantee (from [mechanical_scoring.mli](../../../src/engine/ocaml/lib/mechanical_scoring.mli)):
identical bundle + config → identical result. No LLM, no network, no
semantic parsing. Mechanical scores are structural proxies — well-written
prose can outrun them (kata 04 documents that ceiling; kata 05 pins the
adversarial case the proxies must keep catching: contested authority
self-claims and contradictory anchors). The semantic residue beyond the
proxies is why the LLM witness exists.

---

## 4. The LLM witness

The delegated task, in full: given the prompt from step 4 (the scoring
instruction `runtime/SELF-MEASURE.md` + the hashed bundle), estimate

- `delta_alpha_beta`, `delta_beta_gamma`, `delta_gamma_alpha` — normalized
  discrepancy δ ∈ [0,1] per axis pair (frozen v3.2.2 proxy contract,
  `src/engine/ocaml/CONTRACT.md`),
- `alpha`, `beta`, `gamma` — component scores s_α, s_β, s_γ ∈ [0,1],
- `bottleneck_axis`, `confidence`, `summary`,
- `axis_evidence` — strongest positive and negative evidence per axis,
  cited from the bundle,
- `unresolved_ambiguity`, `next_fixes`,

and return them as one JSON object. Nothing else.

For the `engine` target the instruction (§2.2) holds the witness to
typed-functional code-craft standards — types carrying the invariants,
bounded effects, one source of truth per rule, proof discipline, and
boundary honesty — with low marks cited to files as axis evidence.

The model must not:

- **compute Coh or C_Σ** — it reports δ; the engine applies
  φ(δ) = δ/(1−δ) and Coh = exp(−λ·φ(δ)) deterministically. A response
  carrying any computed-coherence field (`C_sigma`, `coh`, ...) is
  refused outright.
- **see anything beyond the bundle** — no repo access, no outside
  knowledge, no inferred missing files.
- **produce anything beyond the JSON** — no prose, no fences.

Validation is unconditional and single-funneled
([response_schema.ml](../../../src/engine/ocaml/lib/response_schema.ml),
`validate_witness_response`). Every way a response
can fail is classified into a stage — `parse` (prose, fenced JSON,
malformed text), `base_schema` (missing/mistyped contract fields),
`prohibited_fields` (computed coherence), `target_mismatch` (response
names a different target than was measured), `v3_2_delta` (missing or
out-of-range δ), `checklist` (v3.2.3 defect walk missing, wrong
category set, or severity/count inconsistent), `defect_cards` (v3.2.4
structured cards missing, malformed, or disagreeing with the
checklist) — and **every** stage
writes the same durable
validation-failure artifact naming its stage, preserves the raw response,
renders **no** report, and does **not** fall back to mechanical scoring.
A refused witness is a recorded fact, not a silent downgrade. The
per-stage fixtures live in [fixtures/invalid/](fixtures/invalid/) and the
CI smoke ([scripts/ci/self-measure-smoke.sh](../../../scripts/ci/self-measure-smoke.sh))
replays each of them on every run.

`hybrid` mode runs both backends on the same bundle and preserves both
results; the `final` sub-object names which backend authored the
adjudication (`llm`, `mechanical`, or `agreement`).

---

## 5. Provider routes

The witness reaches a model over one of two routes. Both feed the same
validation pipeline; the route is recorded in report metadata.

**Local (HTTP).** The engine calls the configured provider directly:
`LLM_PROVIDER`, `LLM_MODEL`, `LLM_API_KEY` (operator manual §3).

```bash
coh self               # auto: hybrid with credentials, mechanical without
coh self --mode hybrid # explicit
```

**CI (claude-cli).** No raw API key in CI. The rendered workflow splits
the route into three explicit steps per target:

1. `coh-self --emit-prompt <target>` — the engine writes the exact prompt
   content to `.tsc/self/prompt/<target>.md`: the same instruction,
   target metadata, and hashed bundle the HTTP route sends, joined into
   one document (the HTTP route carries the instruction as the system
   message and the rest as the user message).
2. A Claude CLI step (the `claude` CLI, npm-pinned by the renderer —
   workflows fire on tag and `VERSION` pushes, which hosted actions for
   this route do not serve) runs the `ci_prompt` declared in this skill's
   frontmatter, with tool permissions reduced to reading that prompt file
   and writing `.tsc/self/response/<target>.json`.
3. `coh-self --ingest <target>` — the engine reads the response via
   `coh --llm-response`, validates it, and renders the hybrid report.

The model performs step 2 only. If it writes anything malformed, step 3
refuses it.

---

## 6. Running it

```bash
# Local, no credentials — mechanical reports + cross-target aggregate
coh self --mode mechanical

# Local, with credentials — hybrid per-target + mechanical cross-target
coh self

# Individual pieces (what the workflow runs)
coh-self --emit-prompt spec
coh-self --ingest spec
```

In CI (`tsc-self-measure.yml`):

- **mechanical job** — always runs on changes to `spec/`, `src/engine/ocaml/`,
  `targets/`, `runtime/`, `src/skills/`. No secrets, no gate.
- **llm-witness job** — gated by the presence of the
  `CLAUDE_CODE_OAUTH_TOKEN` secret; there is no separate toggle to drift
  out of sync with it. Secret present → the witness runs; absent → the
  witness is unavailable and the gate job's log says so. One matrix job
  per target.

Locally the same posture holds: `coh self` defaults to auto and every
report's `mode` field states the backend that produced it;
`coh self --require-llm` forces the semantic path and refuses loudly
when no credentials are configured, never degrading to mechanical.

**The coherence ledger.** `.tsc/COHERENCE.md` (generated state — written
by the ledger workflow, never edited by hand) carries one row per release. A row is the **hybrid** measurement — the
mechanical backend plus the Claude CLI witness — whenever the witness
credential is present; when it is not, the row is mechanical and says so
(every row names its mode and instrument).

Historical backfill rows are
mechanical by construction: a fixed engine re-measuring an old tree is
reproducible; a semantic judgment of one would not be.

A hybrid row
takes the same k=3 sampled witness route as the measurement workflow
and records its own reliability — validated sample count, worst
per-target Coh_consistency, and the standing that reading carries; a
`single-sample: no standing` row may not be cited as release-grade
semantic history.

The rendered
`tsc-coherence-ledger` workflow appends the row on every version
increment — a `VERSION`-bump push or a release-tag push, patch
increments included (the tag is materialized from CI when it does not
exist yet; releases themselves are cut by `scripts/release.sh`, which
gates on a `CHANGELOG.md` entry) — via
[scripts/coherence-ledger.sh](../../../scripts/coherence-ledger.sh);
commits between releases do not write the ledger (per-run reports are CI
artifacts instead).

The authoritative release surface is `main`: only a
`main` push, a tag push, or a `main`-ref dispatch materializes a tag or
writes the row. A `VERSION`-bump push on any other branch measures and
uploads artifacts but writes nothing — a run started at an older SHA
would otherwise tag and record a tree the branch had already moved
past; the release is cut by the merge itself.

Historical rows were backfilled by measuring each
tag's tree — its own `targets/registry.tsc` — with one fixed engine, so
the curve is comparable across releases; the instrument column names the
engine that measured each row.

Both jobs upload their `.tsc/self/` reports as artifacts and write a
step-summary table.

---

## 7. Reading a report

Every report carries `alpha`, `beta`, `gamma`, `bottleneck_axis`, and a
`provenance` object with both aggregate forms. The verdict-bearing number
is `provenance.aggregate_numeric.C_sigma_num`. Hybrid reports add
`mechanical`, `llm`, and `final` sub-objects — compare them to see where
structural proxies and semantic judgment disagree.

The bottleneck is not averaged away: the lowest axis names the constraint,
and `next_fixes` (LLM modes) names the repair direction per axis.

Coherence is not quality. A high C_Σ means the three descriptions still
describe one system — nothing more.

---

## 8. Failure modes

- **Rendered artifacts edited by hand.** CI re-renders and diffs; the
  build fails. Edit this skill, re-render, commit both.
- **Skill drifts from engine.** A signal code declared here but absent
  from `mechanical_scoring.ml` (or an estimate field absent from
  `runtime/SELF-MEASURE.md`) fails `scripts/ci/validate-skill-frontmatter.sh`.
- **Witness response invalid.** Whatever the failure shape — prose,
  fenced JSON, missing fields, computed coherence, wrong target, bad
  δ — one validation-failure artifact records the stage; no report, no
  fallback — by design. Fix the route or the model, re-run.
- **LLM job skipped.** The gate is the witness credential itself; when
  the secret is absent the gate job logs the skip and only mechanical
  reports exist. Absence of a hybrid report is visible, not masked —
  and `--require-llm` turns that absence into a refusal locally.
- **Witness fails at ledger time.** A present-but-unusable credential
  (expired token, provider outage) must not leave a release rowless:
  the ledger job writes the labeled mechanical row and the witness step
  stays visibly failed in the run. The row upgrades in place when a
  working witness next measures that release. The measurement workflow
  (`tsc-self-measure.yml`) does not soften this way — there a failed
  witness fails the job.
