---
name: cm-of-cms
description: >-
  The 0th coherence methodology: how coherence methodologies themselves
  are measured — this one included. Declares what measuring a CM means
  per axis, the consistency protocol every CM must pass (an instrument
  that cannot agree with itself is incoherent as an instrument), the
  mechanical/LLM split for judging a CM's corpus, and the adversarial-CM
  doctrine: what follows, mathematically, when one methodology
  demonstrates that another scores lower. Frontmatter is validated by
  schemas/skill.cue (#CMOfCMs); the declared signal codes and estimate
  fields are cross-checked against the engine source and the scoring
  instruction, exactly as for the 1st methodology.
governing_question: >-
  When a coherence methodology measures things, what measures the
  methodology — and does it survive being measured by itself?
artifact_class: measurement
scope: repo
kata_surface: none
triggers:
  - cm-of-cms
  - methodology of methodologies
  - CM consistency
  - adversarial CM
inputs:
  - "targets/registry.tsc (named targets: methodology, cm-of-cms)"
  - "runtime/SELF-MEASURE.md (canonical LLM scoring instruction)"
  - "scripts/cm-consistency.sh (the consistency instrument)"
  - "LLM credentials or an external witness response (optional — hybrid/llm modes only)"
outputs:
  - ".tsc/cm/ — per-CM reports (mechanical, llm, or hybrid)"
  - ".tsc/cm/consistency/ — consistency reports (mechanical determinism, LLM repeat spread)"
visibility: public
cm_of_cms:
  registry: targets/registry.tsc
  targets:
    - methodology
    - cm-of-cms
  cross_target: false
  instruction: runtime/SELF-MEASURE.md
  output_root: .tsc/cm
  default_mode: auto
  consistency:
    mechanical: identical
    llm_repeats: 3
    llm_spread: >-
      max absolute pairwise difference over the response contract's
      numeric fields; delta_consistency maps through the barrier
      phi(delta) = delta/(1-delta) to Coh_consistency = exp(-phi)
      (tsc-core section 3.2, lambda = 1)
    script: scripts/cm-consistency.sh
  mechanical:
    backend: engine/ocaml/lib/mechanical_scoring.ml
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
      engine/ocaml/lib/response_schema.ml (validate_witness_response) —
      one funnel for every refusal stage: parse, base_schema,
      prohibited_fields (computed Coh/C_sigma), target_mismatch,
      v3_2_delta. Any refusal produces a durable validation-failure
      artifact naming its stage, preserves the raw response, renders no
      coherence report, and never falls back to mechanical scoring
    providers:
      local: >-
        engine HTTP route — LLM_PROVIDER / LLM_MODEL / LLM_API_KEY
        (docs/beta/guides/OPERATOR-MANUAL.md section 3)
      ci: >-
        claude-cli — the same external witness route as the 1st
        methodology (emit prompt, Claude CLI step, ingest), rooted at
        .tsc/cm instead of .tsc/self; this methodology is essence-only
        and declares no workflow binding of its own
    ci_prompt: |
      You are the LLM witness step of the CM-of-CMs measurement, rendered
      from skills/cm-of-cms/SKILL.md. Your entire task:

      1. Read the file .tsc/cm/prompt/{target}.md. It contains the
         canonical scoring instruction (runtime/SELF-MEASURE.md) followed
         by the {target} target bundle — the corpus of a coherence
         methodology. Follow that instruction exactly.
      2. Write your answer — the single JSON object the instruction
         requires, with no markdown fences and no prose around it — to
         .tsc/cm/response/{target}.json.

      Constraints (your tool permissions also enforce them):
      - Do not read any file other than .tsc/cm/prompt/{target}.md.
      - Do not write any file other than .tsc/cm/response/{target}.json.
      - Do not compute Coh or C_sigma values; report the delta and
        component estimates the instruction asks for. The engine applies
        the barrier transform and aggregation deterministically after
        validating your output, and rejects the response if any required
        delta field is missing or out of range.
---

# CM of CMs — the methodology of methodologies

TSC measures whether three descriptions of a system still describe one
system. A coherence methodology (CM) is itself such a system: it has a
declaration (its skill), an implementation (its schema, scripts, and
engine surfaces), and an instrument behavior (what it outputs when run,
and how those outputs move as it evolves). So a CM is measurable by the
same triadic instrument — and this skill declares how.

This is the **0th coherence methodology**. The self-measurement skill
(`skills/self-measure/SKILL.md`) is the 1st: the tsc-repo CM applied to
tsc. Both satisfy the same comparable contract,
[`#CoherenceMethodology`](../../schemas/skill.cue); the 1st is deployed
(command, render, ledger, CI bindings), the 0th is essence-only — it
measures methodologies wherever they are, and it measures itself (§5).
Each methodology's corpus is measured as a closed system, so
cross-methodology references here are plain paths, not links — a link
must resolve inside the bundle it is measured in.

---

## 1. What measuring a methodology means

The triad, read against an instrument instead of a document corpus:

| Axis | For a document corpus | For a methodology |
|------|----------------------|-------------------|
| **α — pattern** | stable internal structure | **instrument self-agreement**: the CM produces the same judgment for the same input (§3, the consistency protocol) |
| **β — relational** | the parts fit together | **declaration ↔ implementation fit**: what the skill declares is what the schema types, the validator cross-checks, and the rendered surfaces run |
| **γ — process** | survives change | **instrument evolution**: scoring changes are versioned, kata-anchored, and traceable; the meter can change without silently rewriting what its old readings meant |

A CM weak on α is noise; weak on β is marketing (it claims a measurement
it does not perform); weak on γ is unfalsifiable over time (its numbers
cannot be compared across its own versions).

---

## 2. The corpus

Two CMs are registered as measurable targets in
[targets/registry.tsc](../../targets/registry.tsc):

| Target | Methodology | Corpus |
|--------|-------------|--------|
| `methodology` | 1st — tsc's self-measurement | its skill, schema, validator, renderer, rendered surfaces, scoring instruction, target manifests, and the engine modules its pipeline names ([targets/methodology.tsc](../../targets/methodology.tsc)) |
| `cm-of-cms` | 0th — this skill | its skill, the comparable schema, the consistency instrument, its corpus declarations, and the calibration commons ([targets/cm-of-cms.tsc](../../targets/cm-of-cms.tsc)) |

A CM's corpus is its three descriptions made into files. Measuring the
corpus with the standard pipeline is exactly measuring whether the
declaration, the implementation, and the instrument's operating record
still describe one system.

`cross_target` is false: the two CMs are compared, not aggregated — a
single number spanning two different methodologies would mean nothing
(§6, commensurability).

---

## 3. The consistency protocol

**A methodology must be tested against the same input repeatedly, and
the agreement of its outputs measured and reported.** This is α applied
to the meter itself, and it is part of the comparable contract
(`consistency` in [`#CoherenceMethodology`](../../schemas/skill.cue)) —
every conforming CM declares it; this skill provides the instrument,
[scripts/cm-consistency.sh](../../scripts/cm-consistency.sh).

**Mechanical arm — exact reproducibility.** The deterministic backend
must satisfy `identical`: same bundle + config → same scores,
bit-for-bit, over N repeated runs (default 3). Any divergence is a
hard failure — a "deterministic" backend that drifts has a hidden input
(time, ordering, environment) and its determinism claim is false.

**LLM arm — bounded spread.** The witness is sampled `llm_repeats` (3)
times against the frozen prompt. The spread is the max absolute pairwise
difference over the response contract's numeric fields (component
scores, δ estimates, confidence). That spread is a discrepancy like any
other in TSC, so it maps through the canonical barrier
(`spec/tsc-core.md` §3.2):

```
delta_consistency = max |x_i - x_j|   over repeats i,j and numeric fields
Coh_consistency   = exp(-phi(delta_consistency)),  phi(d) = d/(1-d)
```

`Coh_consistency` is reported alongside the CM's coherence score. A CM
may not average it away: an instrument with Coh_consistency near zero
has no stable reading to report, whatever its self-assigned coherence.

---

## 4. The split

Measuring a CM uses the same pipeline as measuring anything else — the
0th methodology adds no new machinery, only a new corpus and the
consistency protocol:

| Work | Owner | Where |
|------|-------|-------|
| Resolve the CM's corpus, bundle, hash | mechanical | engine pipeline (steps 1–2 of the 1st methodology's split, `skills/self-measure/SKILL.md` §2) |
| Run the object-CM's own verification battery (validator, render check, smoke, katas, tests) | mechanical | the CM's declared CI surfaces |
| Score 12 structural signals over the CM corpus | mechanical | [mechanical_scoring.ml](../../engine/ocaml/lib/mechanical_scoring.ml) |
| N-run determinism check + repeat-spread computation | mechanical | [scripts/cm-consistency.sh](../../scripts/cm-consistency.sh) |
| **Judge whether declaration, implementation, and instrument behavior still describe one system** | **LLM** | [runtime/SELF-MEASURE.md](../../runtime/SELF-MEASURE.md) over the CM bundle |
| Validate the witness response, barrier, aggregate, report | mechanical | [response_schema.ml](../../engine/ocaml/lib/response_schema.ml), [coherence.ml](../../engine/ocaml/lib/coherence.ml) |

The witness contract is identical to the 1st methodology's — same
estimate fields, same prohibitions, same single-funnel validation. The
model is a witness over a CM's corpus, not an authority over CMs.

---

## 5. Self-application

The 0th methodology's corpus is registered (`cm-of-cms`), so the
methodology measures itself with no special case: bundle the corpus,
score it, run the consistency protocol on the instruments doing the
scoring. The result is *its own coherence on its own terms* — reported
like any other measurement.

This closes the regress instead of opening one. There is no \-1th
methodology: the 0th's fitness claim is the **fixed point** — it scores
itself, the score is stable (consistency protocol) and defined (the
pipeline terminates with a number, not a paradox). A methodology that
cannot produce a stable, defined self-score is *inadmissible* (§6): the
liar-flavored CM ("this methodology is incoherent") and the oscillating
CM (self-score changes with each evaluation) both fail here, by
construction rather than by fiat.

---

## 6. Adversarial methodologies

Anyone can supply a CM by conforming to the comparable contract. So
someone will eventually supply an *adversarial* one: a CM constructed to
demonstrate that some other CM scores lower. What follows?

**The score matrix.** With CMs A, B, ... , admissible measurements form
a directed matrix: `S[A][B]` = the score A's instrument assigns to B's
corpus. "A demonstrates B scores lower" is one off-diagonal entry — a
fact about *A's scale applied to B*, not yet a fact about B.

**Domination does not order the ecosystem.** Each CM is its own metric,
so pairwise comparisons need not compose: A can outscore B on A's terms,
B outscore C, and C outscore A — a Condorcet cycle. "The strongest CM"
by pairwise domination may simply not exist. Any ranking must be built
from something other than raw head-to-head wins.

**Assassin instruments are cheap.** A CM that scores every other CM 0
is trivially constructible — degeneracy costs nothing. Raw scores
therefore confer no standing. A CM's scores of others count only if the
CM is **admissible**:

1. **Calibration commons.** It must reproduce the shared anchors
   ([katas/](../../katas/README.md)): pass the positive control, fail
   the negative control, rank the comparative pair correctly, respect
   the prose ceiling, catch the adversarial trap. A meter that cannot
   read the commons has no standing to read anything else.
2. **Consistency.** It must pass its own §3 protocol — self-agreement
   before cross-judgment.
3. **Evidence.** Every low score it assigns must cite evidence from the
   object CM's bundle (the `axis_evidence` contract). Unfalsifiable
   verdicts are inadmissible, however low the number.
4. **Fixed point.** It must have a stable, defined self-score (§5).

**Standing is off-diagonal.** A CM's standing is what *other admissible
CMs* say about it — never its self-score. Every CM would self-report
1.0 if self-scores ranked; the diagonal is a fitness gate (§5), not a
ranking input.

**"Strongest" is maximin.** Define
`standing(B) = min over admissible A≠B of S[A][B]` — the worst score B
receives from any credible auditor — and prefer the CM with the highest
standing. This is TSC's own bottleneck rule lifted one level: an
ecosystem's confidence in a methodology is constrained by its weakest
credible audit, exactly as a system's coherence is constrained by its
weakest axis. Maximin is also cycle-proof: it always yields a
(possibly tied) maximum, where pairwise domination may yield none.

**Aggregation must preserve the degeneracy axiom.** If standing is
smoothed over auditors, use the geometric mean: one credible zero
annihilates standing, as it should — an arithmetic mean would let many
friendly scores buy off a fatal audit. This is the same reason C_Σ is
geometric, applied at the population level.

**Commensurability bounds every claim.** Scores from different CMs are
comparable only over the shared anchors. "B scores 0.4 within A" is a
statement about A's scale until A's scale is pinned to the commons —
which is what admissibility rule 1 does. Growing the commons (adding a
kata that breaks a gamed CM) is how the ecosystem answers Goodhart:
adversaries improve the anchors, and every CM is re-read against them.

**So: then what?** Then people can pick the strongest CM — and the
mechanism is sound *because* it is adversarial. A challenger that passes
admissibility and demonstrates a low score has produced evidence, cited
from the object's own corpus, that survives the commons. The object CM's
options are to fix what the evidence names or to contest the anchors by
extending the commons. Either move improves the ecosystem; a maximin
equilibrium under a growing auditor pool selects for methodologies that
are hard to discredit rather than easy to inflate.

---

## 7. Running it

```bash
# Measure a CM's corpus (mechanical; hybrid with credentials)
coh --target methodology --registry targets/registry.tsc --output .tsc/cm
coh --target cm-of-cms   --registry targets/registry.tsc --output .tsc/cm

# Consistency protocol
scripts/cm-consistency.sh mechanical methodology      # N-run determinism
scripts/cm-consistency.sh mechanical cm-of-cms
scripts/cm-consistency.sh llm-spread methodology \
  r1.json r2.json r3.json                             # witness repeat spread

# External witness route (same shape as the 1st methodology, .tsc/cm root)
coh --target cm-of-cms --registry targets/registry.tsc \
  --instruction runtime/SELF-MEASURE.md --emit-prompt .tsc/cm/prompt/cm-of-cms.md
coh --mode hybrid --target cm-of-cms --registry targets/registry.tsc \
  --instruction runtime/SELF-MEASURE.md \
  --llm-response .tsc/cm/response/cm-of-cms.json --output .tsc/cm
```

Reports land in `.tsc/cm/` (generated state, never canonical);
consistency reports in `.tsc/cm/consistency/`.

---

## 8. Failure modes

- **The instrument disagrees with itself.** The §3 mechanical check
  fails on any bit-level divergence; the LLM spread maps through the
  barrier, so a wide spread collapses Coh_consistency toward zero. No
  averaging repairs an unstable meter.
- **Declaration drifts from implementation.** The same validator
  cross-checks that pin the 1st methodology pin this one: declared
  signal codes must exist in the engine backend, declared estimates must
  equal the instruction's output contract, declared paths must exist.
- **A CM games its own scale.** Its scores of others carry no standing
  until it reads the calibration commons correctly — and the commons
  grows precisely when someone demonstrates a gamed reading.
- **Self-application paradox.** A CM without a stable, defined
  self-score is inadmissible by §5; the regress terminates at the fixed
  point instead of recursing.
