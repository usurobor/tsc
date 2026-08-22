# 01 — Foundation and First Proof

This plan defines the first work required to test whether a compact TSC
instruction enables an LLM to recover cohering from an unseen polarity.

## Problem

TSC no longer has a compact account of its original operation or evidence that
an LLM can perform it. Earlier work replaced that question with measurement and
runtime machinery. We must define the atom, express it, teach it, and test it
before designing another system around it.

## Context

The reset README states the project intent. Historical C≡ artifacts supply
hypotheses—especially one-as-two and distinction without division—but do not
govern the new work. The new specs become authoritative only after review. A
spec earns its place only when removing it would weaken the account of cohering.

## Deliverables

1. `specs/COHERING.md` defines cohering, coherer, cohered, their relation, and
   what makes a proposed cohering non-decorative.
2. `specs/C-EQUIV.md` defines the minimal `≡` operator, syntax, and rewrite laws.
3. `specs/ARTICULATION-ASCENT.md` states the smallest candidate ascent and
   descent procedure. It remains provisional until evaluation.
4. `skills/cohering/SKILL.md` teaches an LLM to apply the procedure to a given
   polarity.
5. `evals/01_first-proof.md` freezes the cases, controls, rubric, independent
   reviewer, and success threshold before evaluation.
6. `evals/runs/` retains raw outputs and condition-blind review results.

## Work Order

1. Extract only the historical claims needed to define the atom.
2. Write the cohering and C≡ specs with valid and invalid examples.
3. Derive a provisional Articulation Ascent from those specs.
4. Encode the same procedure as the cohering skill.
5. Freeze held-out cases, negative cases, invariance checks, and the rubric.
6. Run the same model with and without the skill. An independent reviewer judges
   the model's committed answer without knowing which condition produced it.
7. Revise the specs or skill only in a new evaluation cycle.

## Acceptance Criteria

- [ ] **AC1 — Foundation:** `COHERING.md` defines one process articulating two
  distinct, inseparable poles. It rejects identity, separation, hierarchy, and a
  third mediating substance. A proposed cohering is non-decorative only when it
  commits in advance to a consequence that could fail.
- [ ] **AC2 — Language:** `C-EQUIV.md` gives enough syntax and rewrite semantics
  to express one-as-two and self-application. It introduces no measurement,
  runtime, or fixed H/V/D machinery.
- [ ] **AC3 — Procedure:** the ascent spec and skill name the same bounded moves
  from polarity to generating cohering, new articulation, and descent.
- [ ] **AC4 — Evaluation:** the first-proof spec includes unseen polarities,
  false or merely associated pairs, pole swaps, paraphrases, and a no-skill
  control. It sets an explicit pass threshold before outputs exist. No case can
  pass unless the model's own committed consequence satisfies the rubric.
- [ ] **AC5 — Evidence:** the skill author does not grade the proof. Every run
  preserves its prompt, raw output, condition, blinded review, and verdict.
  Failed cases remain in the record.
- [ ] **AC6 — Scope:** every spec directly strengthens the account or application
  of cohering. Schemas, graphs, verifiers, receipts, and similar machinery require
  a new plan that proves why the first proof needs them.
- [ ] **AC7 — Claim boundary:** success supports only the claim that the skill
  improves the tested model's ability to perform the specified operation. It
  does not establish the metaphysical truth of TSC.

## Non-goals

- A compiler, runtime, provider graph, receipt system, or measurement framework.
- Restoration of the full historical C≡ language.
- Treating H/V/D or any domain polarity as a universal axiom.
- Tuning against held-out cases after their outputs are known.

The first milestone closes when the artifacts and evidence show either a
repeatable effect or a clear failure. Both outcomes advance the work.
