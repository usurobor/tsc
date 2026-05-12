# cnos: Document the generic α/β/γ/δ/ε role-scope ladder as a cnos-level pattern (cdd, cdw, c-d-X all instantiate)

**Labels:** `docs, P2, pattern`
**Priority:** P2 — names a generalization currently implicit in cdd only. Naming it once at the cnos level is what unlocks a sibling protocol (cdw — coherence-driven writing) without re-deriving the role taxonomy from scratch, and it makes future c-d-X instantiations cheap.
**Status:** Drafted; ready for cycle dispatch.
**Mode:** `design-and-build` — design lives in this issue body; patch is one new top-level cnos doc + cross-references from `cdd/CDD.md` (and the future `cdw/CDW.md`) marking themselves as instantiations.
**Depends on:** none (foundational). Sister proposals `cnos-cdd-claude-code-dispatch`, `cnos-cdd-identity-convention`, `cnos-cdd-activation-skill` all benefit from being able to point at this single source for "what is a role."

## Problem

**What exists:** cdd names five Greek-letter roles (α/β/γ/δ/ε) and assigns each a verb (`produce`, `review`, `coordinate`, `operate`, and — implicitly — `iterate`). The role assignments live inside `cdd/{alpha,beta,gamma,operator}/SKILL.md` and `cdd/CDD.md`. ε is currently unnamed but its work happens — every cycle writes `cdd-iteration.md` collecting findings that evolve the protocol itself. The whole role system is treated as a cdd-internal artifact.

**What is expected:** The role system is **not cdd-specific** — it is a generic *scope-escalation ladder* where each role's domain is the previous role's frame. The same five-role structure applies to any coherence-driven discipline: development (cdd), writing (cdw), research (cdr), analysis (cda), etc. The pattern should be documented once at the cnos level as a standalone surface, with cdd as the first instantiation and cdw as the second.

```
α  produces  matter   (the deliverable: code, prose, data, plan)
β  reviews   α's matter
γ  coordinates the α↔β process within one cycle
δ  operates  the γ-process across many cycles (selects, sequences, dispatches)
ε  iterates  the δ-discipline itself (evolves the protocol)
```

The crucial structural property: **each role's frame is the previous role's content**. α works on the deliverable; β works on what α produced; γ works on the loop α and β form; δ works on the cadence of γ's loops; ε works on whether δ's discipline is itself coherent. The roles are nested orders of observation, not parallel job titles.

**Where they diverge:** Today cdd documentation reads as if α/β/γ/δ/ε are particular cdd concepts. A reader landing on `cdd/alpha/SKILL.md` cold has no signal that the same role structure applies to writing prose, planning research, or grading essays. The generalization is implicit in the design but invisible in the docs.

## Impact

- **Sibling protocol bootstrap.** Without a generic pattern doc, cdw (and any future c-d-X) would re-derive the role taxonomy, almost certainly with subtle differences that fragment the shared mental model. Naming the pattern once collapses N protocols' role docs into one.
- **Recursive coherence — pattern self-application.** ε is currently the unnamed role that owns protocol-iteration. Naming it explicitly at the cnos level (above cdd) makes the protocol-evolution discipline first-class. cdd-iteration findings become ε's work product, not γ's by-product.
- **Cross-discipline operator clarity.** An operator (δ) running both cdd cycles and cdw cycles in the same week today has no canonical way to describe their role — they are δ in two different protocols. Naming the generic pattern says: δ is δ regardless of instantiation; the protocol-of-the-day determines what α produces.
- **Pedagogical surface.** A new tenant onboarding to cnos asks "what is α?" The current answer requires loading a cdd skill bundle. The right answer is "α is the producer role; in cdd they produce code, in cdw prose. Read the generic pattern first, then the specific protocol."
- **Names give birth to abstractions.** ε is currently shadow-work. Naming it makes it visible and grade-able. The shadow-work-is-unowned-work failure mode disappears.

## Status truth

| Surface | Status | Notes |
|---|---|---|
| Generic role pattern doc (cnos-level) | NOT EXIST | This proposal |
| α/β/γ defined | Shipped in `cdd/{alpha,beta,gamma}/SKILL.md` | cdd-internal; will be re-pointed at the generic doc |
| δ (operator) defined | Shipped in `cdd/operator/SKILL.md` | cdd-internal |
| ε defined | NOT EXIST | This proposal §Scope item 3 |
| cdd as instantiation marker | NOT NAMED | Activation §3 |
| cdw protocol | NOT EXIST | Out of scope for this issue; this issue unblocks it |
| cdw-side role files | NOT EXIST | Sibling proposal expected after this one lands |
| Verbs canon (`produces`, `reviews`, `coordinates`, `operates`, `iterates`) | Implicit | This proposal §1 codifies |

## Source of truth

| Claim / surface | Canonical source | Status |
|---|---|---|
| α/β/γ verbs | `cnos:cdd/{alpha,beta,gamma}/SKILL.md` headings + cdd cycle close-outs | Shipped (de facto) |
| δ verb | `cnos:cdd/operator/SKILL.md` §1 | Shipped |
| ε work (cdd-iteration) | `cnos:cdd/post-release/SKILL.md` Step 5.6b cdd-iteration | Shipped (work named, role unnamed) |
| Scope-escalation property | This issue §Problem | Proposed |
| Bateson learning levels (analogous prior art) | Bateson, *Steps to an Ecology of Mind*, 1972 | External, normative |
| Cybernetic "orders of observation" | Heinz von Foerster, second-order cybernetics literature | External, normative |
| Empirical evidence — pattern operates today across cdd | tsc cycles #21–#33; cnos cycles ~#250–#344 | Shipped |
| Empirical evidence — writing-work parallels code-work | Every tsc spec cycle (#27, #29, #32) — α drafts prose, β reviews prose, γ coordinates | Shipped |

## Cycle scope sizing (per cnos §1.6c heuristic)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | 0 — prose-only new doc + 2–3 cross-references | no |
| (b) Cross-module breadth | New cnos-level doc + cross-refs from `cdd/CDD.md` + (optional) new `cdd/epsilon/SKILL.md` stub | low |
| (c) Lifecycle span | docs-only | no |
| (d) MCA preconditions | not MCA — design fixed in body | n/a |
| (e) Independent shippability | the pattern doc ships standalone; cdw protocol is a separate downstream issue | no — keep whole |

**Decision:** keep whole. 6 ACs, mid-typical band. Sibling cdw skill bundle is a separate cycle (and a separate issue) that opens after this lands.

## Scope

**In scope:**

1. **New cnos-level doc** at `cnos:ROLES.md` (or `cnos:doctrine/roles.md` — choose per §Open question 1) covering:
   - **§1 The role ladder.** Five roles, five verbs, table form. Each role acts on the previous role's frame.
   - **§2 Scope escalation as nested observation.** Brief — three paragraphs naming orders 0–4 with one-sentence examples per order. Cite Bateson / second-order cybernetics as ambient prior art (no deep theory; the doc is operative, not philosophical).
   - **§3 Instantiation contract.** What an instantiating protocol (cdd, cdw, …) must declare: what α produces (the matter type), what β's review oracle is (what counts as verifiable), what γ's close-out artifact looks like, what δ's cadence is, what ε's iteration cadence is. Six fields, one short paragraph each.
   - **§4 cdd as the reference instantiation.** Worked example — what α/β/γ/δ/ε mean in cdd. Link to `cdd/CDD.md`.
   - **§5 cdw as the planned sibling.** Brief — what cdw will mean, what α produces (prose), what β reviews (clarity / coherence / source-of-truth alignment), what γ coordinates (a writing cycle), what δ operates (a writing pipeline), what ε iterates (the writing protocol). Note: this section is a stub pointer until `cdw/CDW.md` ships.
   - **§6 Naming convention for new c-d-X protocols.** `c-d-{single-letter}` where the letter indicates the matter type. cdd = development (code). cdw = writing (text). cdr = research. cda = analysis. Free namespace; tenant claims a letter by filing a new protocol skill bundle.
   - **§7 Role-name stability.** α/β/γ/δ/ε are *fixed* across instantiations. The verbs are fixed. Only the matter and the oracles vary. This is the property that makes the pattern portable.
   - **§8 Glossary.** Six terms minimum: role, matter, frame, instantiation, scope-escalation, order-of-observation.

2. **`cnos:cdd/CDD.md` cross-reference.** Top-of-file pointer naming cdd as an instantiation of the role pattern, with link to `cnos:ROLES.md`.

3. **New stub `cnos:cdd/epsilon/SKILL.md`** — ε's cdd-side instantiation. Currently empty role; this stub names that ε's work is `cdd-iteration.md` + MCA discipline, and that the role is operator-equivalent (often the same human/agent) until protocol-iteration warrants a separate actor. This is a stub (≤100 lines), not a full skill — it exists primarily to give ε a canonical home.

4. **Update `cnos:cdd/post-release/SKILL.md` Step 5.6b** — cdd-iteration is ε's work product, not γ's. Re-attribute the section. Single-line change.

5. **Optional — sketch `cnos:cdw/CDW.md` stub** (≤200 lines) as proof of pattern portability. **Recommend deferring** to a separate issue once ROLES.md lands; this issue stays focused on the generic doc.

**Out of scope:**

- Full `cdw/` skill bundle (separate issue / proposal)
- Renaming any existing cdd file (cdd/operator/SKILL.md stays cdd/operator/SKILL.md even though "operator" = δ; pattern doc cross-references it)
- Higher-order roles (ζ and beyond) — pattern doc names them as "available if needed" but does not define them
- Any code changes — fully docs-only

## Acceptance Criteria

**AC1 — `cnos:ROLES.md` exists and covers §1–§8.** Each section present with substantive prose.

- *Invariant:* §1 table has exactly 5 rows; §3 has exactly 6 instantiation-contract fields; §6 names cdd and cdw as the first two letters.
- *Oracle:* `wc -l cnos:ROLES.md` returns 250–500. `rg '^## §' cnos:ROLES.md` returns 8 hits.
- *Positive:* a reader landing cold reaches "what is α?" in <30 seconds with the answer "the producer role in any c-d-X instantiation."
- *Negative:* no instantiation-specific language in §§1–3 (those sections are protocol-agnostic).
- *Surface:* `cnos:ROLES.md`.

**AC2 — cdd marked as instantiation.** `cnos:cdd/CDD.md` opens with a pointer at `cnos:ROLES.md` naming cdd as the reference instantiation.

- *Invariant:* one pointer, top-of-file.
- *Oracle:* `head -20 cnos:cdd/CDD.md` contains `ROLES.md`.
- *Positive:* link renders.
- *Negative:* no claim that role structure is cdd-original.
- *Surface:* `cnos:cdd/CDD.md`.

**AC3 — ε named in cdd.** `cnos:cdd/epsilon/SKILL.md` exists (stub ≤100 lines) and names ε's cdd-side scope: protocol-iteration via cdd-iteration.md + MCA discipline.

- *Invariant:* file exists; cross-references ROLES.md §1 row 5 and `cdd/post-release/SKILL.md` Step 5.6b.
- *Oracle:* `wc -l cnos:cdd/epsilon/SKILL.md` returns 30–100.
- *Positive:* §1 paragraph names ε's relationship to δ (often same actor; separable when protocol-iteration warrants distinct attention).
- *Negative:* no claim that ε is required as a separate human/agent; ε can collapse onto δ in small-protocol regimes.
- *Surface:* `cnos:cdd/epsilon/SKILL.md`.

**AC4 — Step 5.6b re-attributed.** `cnos:cdd/post-release/SKILL.md` Step 5.6b names cdd-iteration as ε's work product.

- *Invariant:* one re-attribution; no other prose changes.
- *Oracle:* `rg 'ε' cnos:cdd/post-release/SKILL.md` returns a hit at Step 5.6b.
- *Positive:* cycle close-outs (γ) reference where ε's output lands but γ is no longer credited as iteration-owner.
- *Negative:* nothing else in post-release changes meaning.
- *Surface:* `cnos:cdd/post-release/SKILL.md`.

**AC5 — Pattern self-applies — patch-landing cycle attributes itself.** The cycle that lands this patch labels its own cdd-iteration finding as "ε work" in its close-out. The cycle thereby demonstrates the rename is operable.

- *Invariant:* the patch-landing cycle's `cdd-iteration.md` opens with an explicit attribution `(ε)`.
- *Oracle:* `rg '^ε' .cdd/releases/.../cdd-iteration.md` returns ≥1 hit.
- *Positive:* close-out reflection notes whether δ-and-ε were same actor or distinct.
- *Negative:* no ambiguity about who owns the iteration finding.
- *Surface:* patch-landing cycle close-out.

**AC6 — cdw-stub placeholder.** A one-paragraph "cdw will be drafted in a separate issue" placeholder lives in §5 of `cnos:ROLES.md`; the issue body explicitly does NOT ship cdw.

- *Invariant:* §5 is ≤200 words and names cdw as planned-not-shipped.
- *Oracle:* `cnos:ROLES.md` §5 mentions "separate issue" or "future cycle."
- *Positive:* §5 sketches the four mappings (α-prose, β-clarity, γ-cycle, δ-pipeline, ε-iteration) at one-line each.
- *Negative:* no `cnos:cdw/` directory is created in this cycle.
- *Surface:* `cnos:ROLES.md` §5.

## Proof plan

1. Draft `cnos:ROLES.md` §1–§8 in one pass. Verify §1 table renders; verify §3 has six contract fields.
2. Add `cdd/CDD.md` top-of-file pointer (AC2).
3. Stub `cnos:cdd/epsilon/SKILL.md` (AC3).
4. Re-attribute `cnos:cdd/post-release/SKILL.md` Step 5.6b (AC4).
5. Patch-landing cycle's γ writes its `cdd-iteration.md` opening with `(ε)` attribution (AC5).
6. Verify §5 cdw stub names cdw as planned-not-shipped (AC6).
7. Close out. cdw-protocol sibling issue gets filed separately.

## Risks

- **Bikeshed on doc location.** `cnos:ROLES.md` vs `cnos:doctrine/roles.md` vs `cnos:PATTERN.md`. Mitigation: open question with recommendation; cycle β decides.
- **ε might not warrant a separate role file.** If ε always collapses onto δ in practice, the stub `cdd/epsilon/SKILL.md` is dead weight. Mitigation: stub is ≤100 lines; if usage shows collapse is permanent, fold into operator skill in a later cycle.
- **Re-attribution churn.** Existing cycles' γ close-outs claim cdd-iteration as γ work. Mitigation: forward-only; history immutable; close-outs from this cycle onward use the new attribution.
- **Pattern-doc-as-philosophy.** §2 invites philosophical digression. Mitigation: §2 is three paragraphs max; cite prior art briefly without leaning on it.
- **cdw sketch leaks scope.** §5 might tempt readers to start cdw work in this cycle. Mitigation: AC6 names cdw as planned-not-shipped explicitly.

## Open questions

Each requires a decision; recommendations follow.

1. **Doc location.** `cnos:ROLES.md` at repo root, or `cnos:doctrine/roles.md` in a new dir? — *Recommendation:* `cnos:ROLES.md` at repo root. Single foundational concept; no dir scaffolding needed; matches `cnos:CHANGELOG.md` / `cnos:README.md` conventions.
2. **Verbs canonical or descriptive?** Are `produces / reviews / coordinates / operates / iterates` *fixed* names, or *examples* of what each role does? — *Recommendation:* fixed names. Verbs are part of the pattern; instantiations vary the *matter*, not the verbs.
3. **ε naming.** "epsilon" / "iterator" / "evolver"? — *Recommendation:* `ε` (epsilon) with `iterates` as the verb. Greek symbol matches the role ladder; "iterator" is the descriptive English name. Both names are valid; ε is canonical for trailers and machine indexing, "iterator" for prose.
4. **ε as separate actor or collapsed onto δ?** Today implicit-γ; could be explicit-ε; could be ε=δ in small protocols. — *Recommendation:* ε is named as a distinct role but collapse onto δ is permitted and common. Skill stub says so. Separation becomes warranted when protocol-iteration volume justifies a dedicated reviewer-of-the-protocol.
5. **Higher-order roles?** Should ζ (zeta), η (eta), … be reserved? — *Recommendation:* reserved but undefined. Pattern doc names them as "available if reality demands"; no preemptive definition. The pattern as-is collapses at ε for most observed work.
6. **cdw scope hint depth.** §5 stub one-liner per role, or full instantiation-contract pre-fill? — *Recommendation:* one-liner per role. Full contract pre-fill belongs in the cdw-protocol issue, not the pattern doc.
7. **Cross-protocol identity.** If γ runs both a cdd cycle and a cdw cycle in the same week with the same agent, do they get one identity or two? — *Recommendation:* one identity (the role, not the protocol, owns the identity). The git trailer per `proposals/cnos-cdd-identity-convention` is `gamma@{project}.cdd.cnos` or `gamma@{project}.cdw.cnos` — the protocol-namespace already disambiguates.
8. **c-d-X letter allocation.** Free namespace, first-come-first-served? Registry file? — *Recommendation:* free namespace; conflict resolution by issue-filing order; no registry until a conflict actually arises.
9. **Pattern self-test.** Should ROLES.md include a self-application section ("the cycle that ships this doc instantiates the pattern in writing it")? — *Recommendation:* yes, in §1 as a brief footnote — the doc itself was produced by α, reviewed by β, coordinated by γ, dispatched by δ, and the very findings it surfaces are ε's output. Self-reference closes the loop.
10. **Pattern license to remix.** Can a tenant define their own c-d-X without filing a cnos issue? — *Recommendation:* yes, with the convention that their letter does not conflict with allocated letters in the doc's footer registry. Pattern is portable; cnos does not gate.

## References

- `cnos:cdd/CDD.md` — current cdd entry point
- `cnos:cdd/{alpha,beta,gamma,operator}/SKILL.md` — current role bundles
- `cnos:cdd/post-release/SKILL.md` Step 5.6b cdd-iteration — current ε work product (role unnamed)
- `proposals/cnos-cdd-identity-convention/ISSUE.md` (cnos #343) — identity form references protocol-namespace which presumes the pattern
- `proposals/cnos-cdd-activation-skill/ISSUE.md` (cnos #344) — activation bootstraps an instantiation
- Bateson, *Steps to an Ecology of Mind*, 1972 — Learning Levels I–III (analogous scope-escalation)
- von Foerster, second-order cybernetics — "the observer is part of the system observed"
- Hofstadter, *Gödel, Escher, Bach* (1979), strange loops chapter — recursion across orders of abstraction
