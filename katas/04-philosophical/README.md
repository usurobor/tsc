# Kata 04 — Philosophical (cross-domain, mechanical mode)

**Difficulty:** 3 · **Mode:** mechanical · **Verdict:** fail (semantic) /
pass (kata-runner)

Phase 2 kata. Exercises TSC's cross-domain coherence claim on natural-language
philosophical text — a domain whose *semantic* coherence is difficult to
evaluate by structural-proxy signals alone. The kata's purpose is to **document
the upper limit of mechanical scoring**: surface structure (consistent
headings, dense cross-references, version stamps, internal terminology) is
sufficient for the mechanical scorer to assign a high C_Σ, regardless of
whether the underlying argument is semantically coherent.

## How to run

```bash
coh --kata 04-philosophical --mode mechanical
```

Exits 0 when the mechanical C_Σ falls within `expected.score_range`; non-zero
otherwise.

## Input

Source: [`examples/philosophical/consciousness.md`](../../examples/philosophical/consciousness.md),
copied verbatim into [`input/consciousness.md`](input/consciousness.md). The
text is a didactic TSC exemplar for a philosophical-text reading of triadic
coherence — well-formatted, internally consistent in *form*, and structurally
indistinguishable to the mechanical scorer from a high-quality engineering
document.

## Mode justification (required per cycle #34 active design constraint)

**This kata runs in mechanical mode** even though one might argue it "should"
run under LLM mode (where the semantic-coherence claim could be exercised
directly). The rationale:

1. **Documents a real limitation.** TSC's mechanical scorer claims to be
   useful across domains (issue #34 §Problem). kata-04's purpose is to
   *exercise that claim* on natural-language input and produce a record of
   what the mechanical scorer actually says about it — observed C_Σ ≈ 0.933,
   which is in the same band as kata-01 (the well-structured cellular-
   automata glider, C_Σ ≈ 0.923). The kata thus *surfaces* the limit: the
   mechanical scorer cannot, on a single file, discriminate "well-structured
   philosophy" from "well-structured engineering doc."
2. **Hermetic-by-default is a project-wide constraint** (Phase 1 design;
   `katas/README.md`; cycle #34 §Active design constraints). LLM-mode katas
   require credentials and are not runnable in CI without secrets. Cycle #34
   inherits this constraint from Phase 1.
3. **AC6 (LLM-mode runner support) is deferred** to a Phase 3 follow-on
   cycle. Running kata-04 under LLM mode requires extensions to the runner
   (skip-with-clear-message on missing credentials, documented exit code,
   hermetic test for the credential-absent path) — too much scope for a
   v0.9.0 minor release whose primary deliverable is the kata progression
   itself.
4. **The `expected.verdict = "fail"` is the load-bearing claim.** It records
   the *semantic* judgement (the text, however well-structured, is not what
   TSC considers a coherent measurement system; it's a didactic exposition).
   The numerical `score_range` brackets the *mechanical* observation, which
   disagrees. The disagreement is the lesson.

## Observed C_Σ (calibration)

On `cycle/34-impl` HEAD:

- **C_Σ = 0.9333** (α=1.000, β=1.000, γ=0.800)
- bottleneck: γ (version-surface inconsistency from the example's "v2.1.1" /
  "v2.0.0" / "v3.2.0" cross-references)

The `expected.score_range` is `{min=0.0, max=0.95}`. The wide range is
intentional — it is itself documentation that mechanical scoring cannot
discriminate this input from a well-structured engineering doc. If a future
mechanical-scorer refinement narrows that gap (lowers the score for
natural-language argumentation), the range should be tightened in the same
cycle.

## Why this kata matters

The kata progression so far (kata-01, kata-02, kata-03) exercises only
cellular-automata-style inputs. kata-04 is the first cross-domain kata: it
takes the same scorer and points it at a different category of text. The
result documented here — a high mechanical C_Σ on philosophical prose — is
not a bug, it's an honest reading of what structural-proxy scoring measures.
The kata's contract is that this reading remains stable. If a future scorer
refinement changes it, the change is visible here first.
