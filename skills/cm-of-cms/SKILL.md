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
  admissibility: scripts/cm-admissibility.sh
  standing:
    scope: house-authored-public-commons
    admissibility: public-only
    heldout_status: none
    external_anchor_count: 0
    llm_consistency_gate: reported-not-gating
    llm_consistency_floor: 0.90
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
      engine/ocaml/lib/response_schema.ml (validate_witness_response) —
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

The two arms gate differently. The mechanical arm is a **hard gate**:
any divergence fails the run. The LLM arm is a **standing gate**: a
report below the floor (`Coh_consistency ≥ 0.90` initially, 0.95 once
witness diversity improves) still publishes — refusing to publish would
hide the instability — but carries no off-diagonal standing (§6). The
rendered measurement and ledger workflows both sample the witness k=3
times per target against the same frozen prompt, validate every sample
through the same funnel, and compute the spread in CI.

Name the samples precisely — three rungs, each estimating a different
thing, none substituting for the one above it:

1. **Same-route samples** (what runs today): one prompt, one CLI, one
   model family, k repeats. Estimates *stochastic* spread — a lower
   bound on true disagreement.
2. **Cross-route witnesses**: distinct providers or methods over the
   same frozen prompt. Estimates *witness-family* disagreement.
3. **Stewarded external auditors**: registered, off-house judges.
   Estimates *off-house semantic standing* — the only rung that can
   promote `standing_scope` past the house.

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

This closes the *formal* regress instead of opening one. There is no
\-1th methodology: the 0th's fitness claim is the **fixed point** — it
scores itself, the score is stable (consistency protocol) and defined
(the pipeline terminates with a number, not a paradox). A methodology
that cannot produce a stable, defined self-score is *inadmissible*
(§6): the liar-flavored CM ("this methodology is incoherent") and the
oscillating CM (self-score changes with each evaluation) both fail
here, by construction rather than by fiat.

**What a self-score means — and does not.** A high self-score proves
consistency, never correctness: it says the methodology is *not
self-refuting and currently undefeated in-house*, nothing more. A
perfectly coherent methodology can measure the wrong thing — coherent
astrology is still astrology. So self-application is a **hygiene gate
only**: it qualifies a CM to compete and never wins anything. "Is this
CM internally coherent?" and "is this CM a good measurer?" are
different columns (§6 keeps them apart), and the first number must
never stand in for the second.

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

**Degenerate instruments are cheap in both directions.** A CM that
scores every other CM 0 (the assassin) and a CM that scores everything
— itself included — 1.0 (the flatterer) are both trivially
constructible; degeneracy costs nothing either way. Raw scores,
self-scores above all, therefore confer no standing. A CM's scores of
others count only if the CM is **admissible**:

1. **Calibration commons.** It must reproduce the shared anchors
   ([katas/](../../katas/README.md)): pass the positive control, fail
   the negative control, rank the comparative pair correctly, respect
   the prose ceiling, catch the adversarial trap. A meter that cannot
   read the commons has no standing to read anything else. The check is
   executable — [scripts/cm-admissibility.sh](../../scripts/cm-admissibility.sh)
   runs any candidate scorer over the anchors **blind**: every anchor is
   staged into a neutral case directory (no kata path, no adjacent
   label manifest, case order ≠ kata order), the comparative anchor is
   executed directly per component, and the scorer must answer in a
   JSON contract (`{"score", "evidence"}`) — a low score with no cited
   evidence is an unfalsifiable verdict and inadmissible by itself.
   The `--self-test` proves the rule has teeth against **both**
   degeneracies: the trivial flatterer (all-1.0, perfect self-score)
   and the path-gamer (a lookup table tuned to every public range,
   denied its key by the staging) are rejected while the engine is
   admitted. That test runs in CI; if either attacker can ever win, the
   build fails. One leak is inherent and stays named: interior
   filenames are part of the measured artifact and are preserved, so a
   scorer that memorizes public anchor bodies can still pass — which is
   exactly why public-commons admissibility never confers more than
   `house-authored-public-commons` standing (see **Standing scope**).
2. **Consistency.** It must pass its own §3 protocol — self-agreement
   before cross-judgment. Mechanical arm: hard gate (bit-identical).
   LLM arm: a *standing* gate, not a publishing gate — a report with
   `Coh_consistency < 0.90` still publishes, but carries no
   off-diagonal standing (0.90 ≈ max numeric spread 0.095; the target
   floor once witness diversity improves is 0.95 ≈ spread 0.049).
3. **Evidence.** Every low score it assigns must cite evidence from the
   object CM's bundle (the `axis_evidence` contract; mechanically
   enforced at admission by the JSON scorer contract). Unfalsifiable
   verdicts are inadmissible, however low the number.
4. **Fixed point.** It must have a stable, defined self-score (§5) —
   a hygiene gate, not a merit.

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

**Displacement is symmetric — neither party judges the duel.** "Beat
the incumbent" is decided by **anchor labels**, never by either
methodology's own scale: judged by the incumbent, the duel is
self-sealing dogma (a CM written to score all rivals low is
unfalsifiable); judged by the challenger, it is churn (every challenger
self-scores 1.0 and "wins"). The incumbent's opinions are used only to
*identify historically stable controls* — never as ground truth. A
challenger C displaces incumbent I only if all five hold, with these
initial thresholds:

1. **Registration.** C was registered (see the registration protocol
   below) before the held-out anchor labels were revealed.
2. **Admission.** C passes the public commons blind, the evidence
   contract, the consistency floors, and the self-application hygiene
   gate.
3. **Held-out improvement.** On held-out anchors H, C's predeclared
   anchor loss beats I's by margin:
   `loss(C,H) + ε < loss(I,H)` with ε = 0.03 absolute (or ≥ 10%
   relative loss reduction, whichever is stricter to game).
4. **Stable-control preservation.** On uncontested controls U — anchors
   where label and incumbent have agreed across the operating record —
   C matches the **labels** within tolerance: numeric anchors
   `|score − label_midpoint| ≤ 0.10`; verdict anchors ≥ 95% label
   agreement once |U| ≥ 20 (all-pass required while |U| < 20); ranking
   anchors exact on the public controls, Kendall τ ≥ 0.9 once enough
   ranked cases exist.
5. **Legitimate flips.** A C-vs-I disagreement does not count against C
   when the label (or held-out adjudication) says I was wrong. A
   genuinely better meter may flip many incumbent verdicts; the rule
   protects stable *controls*, not incumbent *opinions*.

Its own self-score appears nowhere in this rule.

**Registration protocol — "held-out" needs a mechanical oracle.**
Commit timestamps alone prove observation, not knowledge; "published
after the challenger was authored" is enforceable only through a
registration event. Phase A (challenger registration): a signed ledger
row or PR records the methodology id, repository URL, commit SHA,
scorer source digest, container/image digest where executable, the
dependency lockfile digest, the prompt/instruction digest for
LLM-based arms, the host-platform registration timestamp, and a
steward signature or CI attestation. Phase B (held-out reveal): each
held-out anchor carries an anchor id, label commit, reveal commit,
steward, label schema, the predeclared loss function, and a pre-reveal
hash commitment to the hidden bundle and labels. Eligibility: anchor A
scores challenger C only if `reveal_commit(A)` postdates
`registration_commit(C)` **and** C's scorer digest at evaluation equals
the registered digest. No steward exists for this repository yet — so
no anchor is held-out yet, and every standing claim below says so.

**Held-out anchors earn unmemorizability, not externality.** The
commit-reveal machinery is executable
([scripts/cm-heldout.sh](../../scripts/cm-heldout.sh)): an anchor is
generated with salted vocabulary and salted *filenames*, sealed, and
its sha256 commitment committed; challengers register (source digest +
commit) ; the bundle is revealed later and may score only challengers
whose registration predates the reveal, at their registered digest,
under the predeclared loss. What that proves is tamper-evident
ORDERING — no challenger could have memorized or tuned to the anchor.
What it does not prove is that the label is right: a house-authored
held-out anchor tests agreement with *the house's* judgment on an
unseen case. So held-out-house standing is the middle rung
(`house-authored-blind-heldout`), and promotion to
`external-blind-heldout` inherits the non-house-provenance requirement:
the anchor's AUTHOR must be outside the house. That last step is not
code — an external author or steward adds their commitment via PR.

**The adjudicator is the least-code-solvable dependency.** The
five-attacker matrix (run by the admissibility self-test in CI, every
run) states exactly where authority still rests:

| Attacker | Public gate | Closed by |
|---|---|---|
| trivial flatterer | rejected | negative controls |
| path-gamer | rejected | blind staging |
| boilerplate-gamer | rejected | evidence grounding (low-score evidence must quote the bundle) |
| basename-gamer | **admitted** | held-out anchors (salted filenames — nothing to memorize) |
| cherry-pick-assassin | **admitted** | adjudication only: evidence that exists but misleads cannot be caught by a grounding check, a hash, or a schema — it requires a credible judge (external steward or non-house quorum), which is a social artifact, not a script |

The two admissions are asserted in CI so they stay measured instead of
forgotten. Until a non-house adjudicator exists, the dispute layer's
only available judges are the house and automated labels — which is
the current state, said plainly, not a hypothetical.

**Standing scope — the report says how far its standing reaches.**
Every admissibility and consistency report carries a `standing_scope`
so the fixed point can never sound stronger than its anchor base:

```json
{
  "standing_scope": "house-authored-public-commons",
  "admissibility": "public-only",
  "heldout_status": "none",
  "external_anchor_count": 0,
  "llm_consistency_gate": "reported-not-gating"
}
```

The scope promotes to `external-blind-heldout` only when the mechanics
change (registered challengers, revealed held-out anchors, external
anchor count > 0, consistency gate passing) — never by prose.

**The regress does not vanish — it relocates, and honesty requires
saying where.** Self-application closes the formal tower; the
*epistemic* anchor is the calibration commons, and whoever authors the
commons holds the real authority. Today that is five katas written in
this repository — a small, house-authored battery, and the declared
standing debt of this methodology (its γ finding in the reports says
the same). The protocol starts producing validation that outruns the
house only as anchors arrive from outside it: adversary-contributed
katas, blind before scoring, misses published. Until then, "no
challenger beats the 0th" means precisely "no one in the house has
beaten the house" — the honest reading, recorded here so the elegance
of the fixed point cannot hide it.

**So: then what?** Then people can pick the strongest CM — and the
mechanism is sound *because* it is adversarial. A challenger that passes
admissibility and demonstrates a low score has produced evidence, cited
from the object's own corpus, that survives the commons. The object CM's
options are to fix what the evidence names or to contest the anchors by
extending the commons. Either move improves the ecosystem; a maximin
equilibrium under a growing auditor pool selects for methodologies that
are hard to discredit rather than easy to inflate. What the mechanism
buys is consistency and contestability; correctness still bottoms out
in the commons and in outcome correlation — no amount of self-reference
manufactures ground truth, it only makes the dependence explicit.

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

# Admissibility (the trivial-attacker test runs in CI)
scripts/cm-admissibility.sh --self-test               # attacker rejected, engine admitted
scripts/cm-admissibility.sh --scorer '<command>' --name my-cm

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
- **The protocol crowns self-flattery.** Guarded executably: the
  admissibility self-test builds the degenerate all-1.0 scorer and
  fails the build if it is ever admitted. If the selection rule can be
  won by measuring nothing, the rule — not the challenger — is broken.
- **Self-application paradox.** A CM without a stable, defined
  self-score is inadmissible by §5; the regress terminates at the fixed
  point instead of recursing.
