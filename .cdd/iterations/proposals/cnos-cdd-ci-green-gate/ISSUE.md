# cdd/review + cdd/gamma: CI-green gate — β refuses APPROVED + γ PRA verifies CI post-merge

**Labels:** `docs, P2, cdd`
**Priority:** P2 — the cycle that shipped a CI gate (tsc #36) had no mechanism for verifying its *own* CI ran green post-merge. β APPROVED on artifact review alone; γ closed on artifact presence alone. The latent failure mode: a workflow that's structurally correct (β reads YAML, reasons about behavior) can still fail at runtime (YAML syntax, missing dep, env var, runner image change) — and neither role catches it.
**Status:** Drafted; ready for cycle dispatch.
**Mode:** `docs-only, design-and-build` — adds verdict rules to `cdd/review/SKILL.md` and a PRA polling step to `cdd/gamma/SKILL.md` / `cdd/post-release/SKILL.md`.
**Depends on:** cnos #339 (mechanical pre-merge gate — sibling discipline; this issue is the post-merge corollary).

## Problem

**What exists:** `cdd/review/SKILL.md` rule 3.13 (cnos #331 patch 1) prescribes honest-claim verification on the diff: reproducibility, source-of-truth alignment, wiring. β reviews artifacts — reads the YAML, the code, the tests, the close-out — and emits APPROVED or RC. `cdd/gamma/SKILL.md` and `cdd/post-release/SKILL.md` prescribe γ's close-out responsibilities (artifact relocation, close-out grades, PRA when warranted). Neither role currently has a CI-green check as a binding gate.

**What is expected:** Two new rules, symmetric on either side of the merge:

1. **β refuses APPROVED without CI green on the review HEAD.** Before emitting verdict APPROVED, β must verify that CI (every required workflow) is green on the cycle's review SHA. If CI is red, missing, or stale relative to the review SHA, the verdict is RC — finding severity B (binding) — until CI is green on the SHA β is reviewing.
2. **γ PRA polls CI post-merge.** Before authoring `gamma-closeout.md`, γ must verify that CI ran green on the merge commit. PRA's first table row is `CI status on merge SHA = green / red / pending`. A red post-merge CI is a §9.1 trigger (avoidable tooling failure) and the cycle's grade reflects it. A pending post-merge CI delays close-out until the run completes.

**Where they diverge:** Today both roles can produce a coherent verdict / close-out while CI is silently red. tsc cycle #36 demonstrated this latent risk — β APPROVED on `0f290d4` (α R2 head) without checking whether GitHub Actions had run; γ closed at merge `f4a69ef` without polling the post-merge run. The cycle landed cleanly only because the workflow happens to be structurally simple. A more complex workflow (env vars, secrets, matrix builds) could ship with a runtime failure neither role would catch.

## Impact

- **Recursive coherence.** Cycle #36 shipped a CI gate. Its own protocol response did not verify the CI gate's first run. The protocol that produces CI rules should itself be subject to those rules.
- **Mechanical pre-merge gate gets a post-merge corollary.** Cnos #339 added a mechanical gate before merge (artifact presence, structural validation). This proposal extends the discipline to "the actual CI runs that the gate enables." Pre-merge: structure correct. Post-merge: behavior verified.
- **β reviewer load.** β already polls the diff; polling CI status is one additional `gh run list --branch <SHA>` call. Cheap; deterministic; high signal.
- **γ close-out integrity.** A close-out that asserts "merged at SHA X" without verifying CI on SHA X is making an honest-claim violation by omission. Adding the explicit poll closes that gap.
- **Cross-protocol.** Cdw (writing protocol per `cnos:ROLES.md`) will have CI-equivalent gates (link checking, spellcheck, schema validation). The same discipline applies — its β and γ inherit this rule.

## Status truth

| Surface | Status | Notes |
|---|---|---|
| α rule 3.13 honest-claim | Shipped (cnos #331 patch 1) | Diff-side discipline |
| Mechanical pre-merge gate | Shipped (cnos #339) | Structure correct before merge |
| β refuses APPROVED without CI green | NOT NAMED | This proposal §AC1 |
| γ PRA polls CI post-merge | NOT NAMED | This proposal §AC2 |
| §3.8 honest-grading rubric — CI-red cycle penalty | Implicit | This proposal §AC3 |
| §9.1 avoidable-tooling-failure trigger — CI-red post-merge | Implicit | This proposal §AC3 |
| Empirical anchor | tsc cycle #36 close-out | Shipped (`usurobor/tsc:.cdd/releases/docs/2026-05-12/36/gamma-closeout.md`) |
| Empirical anchor (conclusion-vs-artifact gap) | tsc cycle #43 | Open — `release.yml` reported green on the workflow-list page for v0.5.0–v0.9.0 yet produced no Release object in any of the five cases |

## Source of truth

| Claim / surface | Canonical source | Status |
|---|---|---|
| β review responsibilities | `cdd/review/SKILL.md` | Shipped |
| γ close-out responsibilities | `cdd/gamma/SKILL.md` + `cdd/post-release/SKILL.md` Steps 1–6 | Shipped |
| Mechanical pre-merge gate | `cdd/release/SKILL.md` / `cdd/gamma/SKILL.md` (cnos #339) | Shipped |
| §3.8 honest-grading rubric | `cdd/release/SKILL.md` §3.8 (cnos #331 patch 5) | Shipped |
| §9.1 trigger list | `cdd/post-release/SKILL.md` §9.1 | Shipped |
| Empirical evidence — tsc #36 protocol gap | `usurobor/tsc:.cdd/releases/docs/2026-05-12/36/gamma-closeout.md` §Post-merge verification (operator action) | Shipped |
| GitHub Actions `gh run list` | `gh` CLI docs (external) | External |

## Cycle scope sizing (per cnos §1.6c)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | 0 — prose to 2–3 skill files | no |
| (b) Cross-module breadth | `cdd/review/SKILL.md` + `cdd/gamma/SKILL.md` + `cdd/post-release/SKILL.md` (3 files; tightly cohering) | low |
| (c) Lifecycle span | docs-only | no |
| (d) MCA preconditions | not MCA — design fixed | n/a |
| (e) Independent shippability | one cohesive verdict-rule + close-out-rule pair | no |

**Decision:** keep whole. 6 ACs, mid-typical band (was 5 pre-tsc-#43 refinement; tsc cycle #43 added AC6 "expected-artifact-produced").

## Scope

**In scope:**

1. **`cdd/review/SKILL.md` § new rule (3.14 or §Verdict gates).** β must:
   - Run `gh run list --branch <review-SHA> --json status,conclusion,workflow_name` (or equivalent).
   - Verify every *required* workflow has `conclusion == "success"`.
   - If any required workflow is red / pending / missing on the review SHA → verdict is RC, finding B-severity, classification `ci-status`.
   - Document the check in `beta-review.md` §CI status (one-line citation of the run + conclusion).

2. **`cdd/gamma/SKILL.md` § post-merge CI verification.** γ must, before authoring `gamma-closeout.md`:
   - Run `gh run list --branch main --json status,conclusion,head_sha` filtered to `head_sha == merge-SHA`.
   - If pending: delay close-out until the run completes.
   - If red: log as §9.1 trigger; cycle's γ-axis grade reflects post-merge failure; consider rollback or follow-on fix-cycle.
   - If green: proceed; record the run URL in `gamma-closeout.md` §Post-merge verification (mandatory subsection).

3. **`cdd/post-release/SKILL.md` § PRA template.** PRA's first row of the audit table is now `CI status on merge SHA`. If the cycle does not have a PRA (small-change cycle), the §Post-merge verification subsection in `gamma-closeout.md` carries the same data.

4. **`cdd/release/SKILL.md` §3.8 amendment.** Cycles with red post-merge CI cap the γ axis grade at C (one band below current floor). Cycles that proceed to close-out without verifying CI cap the γ axis at B− (signal the discipline is operative).

5. **`cdd/post-release/SKILL.md` §9.1 trigger amendment.** Red CI on the merge commit is named explicitly as an avoidable-tooling-failure trigger (analogous to v0.4.0's missing CHANGELOG row — both are mechanical gates that fired late).

6. **§Verification — beyond workflow conclusion.** F2 verification (β AC1, γ AC2) requires checking the workflow conclusion AND the expected artifact's existence. Empirical anchor (tsc cycle #43): the `release.yml` workflow on tags `v0.5.0`–`v0.9.0` reported a green checkmark on the runs-list page (so conclusion-only polling sees "success") while the per-run detail page actually showed Failure exit-code 10 and no `Release` object was created in any of the five cases. The discrepancy between list-page and detail-page surfaces is itself one false-positive class; the deeper one is the gap between `conclusion=success` and `artifact-produced`. β and γ MUST, for each expected artifact named in the cycle's ACs (Release object, attached binary, deployed page, etc.), verify existence + identity (e.g., `mcp__github__get_release_by_tag` returning 200 + non-empty `assets`) after the workflow conclusion is observed. Conclusion-only polling is verified-but-vacuous when the conclusion is mediated by a UI surface that elides the failure.

**Out of scope:**

- Defining what counts as a "required" workflow — that's repo-local config (GitHub branch protection rules, `.github/workflows/` declared metadata).
- Automatic rollback on red CI — out of scope; γ decides per case.
- Pre-merge CI gate beyond what cnos #339 already prescribes.
- LLM-mode CI handling (test runs with credentials) — out of scope; same rules apply but specifics are repo-local.

## Acceptance Criteria

**AC1 — β refuses APPROVED on red/pending CI.** `cdd/review/SKILL.md` gains a verdict gate naming CI status as a binding pre-condition.

- *Invariant:* β cannot emit APPROVED without `gh run list --branch <SHA>` evidence in `beta-review.md` §CI status.
- *Oracle:* `rg 'CI.status|gh run list' cnos:cdd/review/SKILL.md` returns ≥1 hit in the verdict-rules section.
- *Positive:* a β reviewing a structurally-clean diff with red CI on review HEAD emits RC.
- *Negative:* no soft "β should consider CI" prose — the rule is mechanical.
- *Surface:* `cnos:cdd/review/SKILL.md`.

**AC2 — γ post-merge CI verification mandatory.** `cdd/gamma/SKILL.md` and `cdd/post-release/SKILL.md` name post-merge CI polling as a closure-gate row.

- *Invariant:* `gamma-closeout.md` §Post-merge verification is required, not optional.
- *Oracle:* `rg 'Post.merge verification|post.merge CI' cnos:cdd/gamma/SKILL.md cnos:cdd/post-release/SKILL.md` returns ≥1 hit in each file.
- *Positive:* close-out template carries the subsection with a `gh run list` invocation pattern.
- *Negative:* no exception for "small cycles" or "docs-only" — every cycle that has CI runs it.
- *Surface:* both files above.

**AC3 — §3.8 grade caps named.** `cdd/release/SKILL.md` §3.8 names CI-red post-merge as a γ-axis cap (max C); cycles closed without CI verification capped at γ B−.

- *Invariant:* rubric clauses named in §3.8 prose.
- *Oracle:* `rg 'CI.red|CI.verif' cnos:cdd/release/SKILL.md` returns ≥1 hit in §3.8.
- *Positive:* a future γ reading §3.8 understands the cap; β grading γ axis applies it.
- *Negative:* §3.8 stays silent on CI as a grading axis.
- *Surface:* `cnos:cdd/release/SKILL.md` §3.8.

**AC4 — §9.1 trigger amended.** `cdd/post-release/SKILL.md` §9.1 names red post-merge CI as an avoidable-tooling-failure trigger.

- *Invariant:* one new row / line in §9.1 trigger list.
- *Oracle:* `rg 'CI.red|post.merge.*red' cnos:cdd/post-release/SKILL.md` returns ≥1 hit in §9.1.
- *Surface:* `cnos:cdd/post-release/SKILL.md` §9.1.

**AC5 — Self-applied on the patch-landing cycle.** The cycle that lands this patch demonstrates the new discipline:
- β R1 documents CI status on review SHA.
- γ close-out documents `Post-merge verification` row with the merge-commit CI run URL.
- cdd-iteration finding records "self-applied; rule operable."

- *Invariant:* both artifacts present in the patch-landing cycle close-out.
- *Surface:* patch-landing cycle's `beta-review.md` + `gamma-closeout.md`.

**AC6 — Expected-artifact-produced check.** β AC1 and γ AC2 verification clauses each require, for every expected artifact named in the cycle's ACs, an existence + identity probe distinct from the workflow-conclusion poll.

- *Invariant:* `cdd/review/SKILL.md` (β verdict-gate prose) and `cdd/gamma/SKILL.md` (γ post-merge verification prose) each name "expected-artifact-produced" as a check alongside "conclusion=success."
- *Oracle:* `rg 'expected.artifact|artifact.produced' cnos:cdd/review/SKILL.md cnos:cdd/gamma/SKILL.md` returns ≥1 hit in each.
- *Empirical anchor:* tsc cycle #43 — release.yml on five consecutive tags (v0.5.0–v0.9.0) showed green on the workflow-list page yet produced no Release object; the conclusion-only F2 check considered the cycle verified-green for five cycles in a row.
- *Positive:* a future β reviewing a cycle that ships "a GitHub Release with binary X" probes `get_release_by_tag` (or equivalent) and finds the asset; absence → RC.
- *Negative:* no soft prose ("β should also check the artifact") — the rule is mechanical and names the artifact-presence-probe call.
- *Surface:* `cnos:cdd/review/SKILL.md` + `cnos:cdd/gamma/SKILL.md`.

## Proof plan

1. Author rule additions per AC1–AC4.
2. Self-apply on the patch-landing cycle:
   - β R1 runs `gh run list --branch <SHA>` and cites the run in §CI status.
   - γ close-out polls post-merge CI; records the run URL.
3. cdd-iteration captures the self-application as evidence the rule is operable.

## Risks

- **CI polling adds latency to close-out.** γ may need to wait for a pending run before authoring close-out. Mitigation: the wait is the right behavior — close-out on a red or pending CI is the worse outcome. Cycles needing immediate close-out should already have CI runtime under their close-out budget.
- **"Required" workflow definition.** Some repos may not have branch protection rules naming required workflows. Mitigation: §AC1 prose names the fallback — "every workflow that runs on the cycle branch is required unless explicitly listed in `.cdd/CI-OPTIONAL`."
- **External CI provider drift.** GitHub Actions outages can produce false-red. Mitigation: §AC4 trigger is "avoidable-tooling-failure" only when the failure is in the cycle's code; external infra red is a different class.
- **β grading inflation.** β might APPROVE on red CI claiming "the failure isn't my fault." Mitigation: AC1 invariant is mechanical — β cannot emit APPROVED without green CI on review SHA, regardless of cause.

## Open questions

1. **"Required" workflow declaration.** GitHub branch protection rules vs `.cdd/CI-OPTIONAL` file vs neither? — *Recommendation:* prefer GitHub branch protection rules where available; fallback to `.cdd/CI-REQUIRED` listing required workflows by name; default if neither is "every workflow runs on the cycle branch."
2. **CI-red post-merge — rollback or follow-on fix?** — *Recommendation:* γ decides per case. Most cycles: follow-on fix-cycle (the original cycle's grade reflects the gap; new cycle fixes). Critical regression: rollback. Rollback discipline is out of scope here.
3. **Pending CI on close-out — wait or proceed with explicit "pending" status?** — *Recommendation:* wait. Close-out on pending CI is dishonest by omission.
4. **β polling — manual `gh run list` vs MCP integration?** — *Recommendation:* document `gh run list` as canonical; MCP integration is a §5.2 Claude Code activation enhancement, not protocol-level.
5. **§3.8 cap — C for red CI, B− for unverified — too harsh?** — *Recommendation:* exactly right. CI is a mechanical gate; failing or skipping it is a structural γ-axis failure, not a judgment call.

## References

- `usurobor/tsc:.cdd/releases/docs/2026-05-12/36/gamma-closeout.md` — empirical anchor (§Post-merge verification was "operator action," not γ action)
- cnos #339 — mechanical pre-merge gate (sibling discipline; this is the post-merge corollary)
- cnos #331 patch 1 — α rule 3.13 honest-claim (analogous β rule on diff-side)
- cnos #331 patch 5 — §3.8 honest-grading rubric (modified by AC3)
- `gh run list` — GitHub CLI docs (external)
- `cnos:ROLES.md` — generic role pattern (this rule generalizes via cdw / future c-d-X)
- tsc cycle #43 — empirical anchor for AC6 (workflow-list page green vs detail-page Failure + no Release object across v0.5.0–v0.9.0)
