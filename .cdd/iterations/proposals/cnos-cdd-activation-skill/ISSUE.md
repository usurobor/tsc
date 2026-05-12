# cdd: New skill `cdd/activation/SKILL.md` — bootstrap cdd in an existing repo (CI, notifications, secrets, identity)

**Labels:** `feature, P1, cdd`
**Priority:** P1 — every repo that adopts cdd today reinvents activation ad hoc; the absence is felt by every new tenant. tsc adopted cdd without a CI loop, without notifications, and without an identity-convention setup step — all three were learned and patched per-cycle rather than by prescription.
**Status:** Drafted; ready for cycle dispatch.
**Mode:** `design-and-build` — design lives in this issue body; patch is a new top-level cnos skill `cdd/activation/SKILL.md` plus minimal cross-references from `cdd/CDD.md`, `cdd/operator/SKILL.md`, and `cdd/post-release/SKILL.md`.
**Depends on:** cnos #338 (dispatch sizing), cnos #339 (mechanical pre-merge gate), `proposals/cnos-cdd-claude-code-dispatch` (dispatch configurations §5), `proposals/cnos-cdd-identity-convention` (identity form). Activation skill references these; ships after they land or alongside them in a bundle.

## Problem

**What exists:** cdd ships with skills for the lifecycle phases (γ, α, β, operator, issue, release, post-release, review) and for the protocol itself (`cdd/CDD.md`). It does **not** ship a "how to turn cdd on in this repo" skill. New-tenant onboarding is implicit — tenants read the protocol, look at how cnos uses it, and improvise.

**What is expected:** A single canonical skill `cdd/activation/SKILL.md` that prescribes the bootstrap sequence for an existing repo:

1. `.cdd/` directory scaffold (releases, unreleased, iterations, cross-repo, proposals)
2. CDD version pin
3. Issue label setup on the host (GitHub) — `cdd`, `mca`, `P0`–`P3`, kata-style labels per project
4. Branch naming convention adoption (cycle/{N})
5. Git identity convention setup (per `proposals/cnos-cdd-identity-convention`)
6. Dispatch configuration declaration (per `proposals/cnos-cdd-claude-code-dispatch` §5)
7. **CI integration** — at minimum: spec validation, test runs, project-specific progressions (e.g., katas in tsc), `.cdd/` artifact validation
8. **Notification integration** — reference adapter for Telegram bot; pluggable for Slack/Discord/email
9. **Secrets management** — bot tokens, signing keys; what lives in GitHub repo secrets, what stays local
10. Cycle-README template

**Where they diverge:** Today every tenant repo re-derives 1–10. tsc reached cycle #32 before identifying CI as a gap; notifications are still absent; identity convention is being patched mid-stream. Each gap costs cycles that could have been a single activation step.

## Impact

- **Per-tenant rediscovery is multiplicative.** Each new repo pays the same activation tax: figure out what `.cdd/` should look like, figure out what to put in CI, figure out how to notify on cycle events, figure out where to put bot tokens. Multiplied over the lifetime cdd is meant to live, this is the largest avoidable cost in adoption.
- **Inconsistent activation produces inconsistent grading.** Cycle #32 graded itself partly against an absent CI loop (some ACs effectively unverifiable in-CI). Without an activation-defined CI baseline, β reviewers lack a known surface to grade against.
- **Notifications are the missing observability axis.** Today every cycle event (start, β verdict, RC, merge) is invisible outside the Claude session. A notification adapter shipping in activation gives the operator a passive view of the pipeline.
- **Bot/secret onboarding is currently zero-prescription.** Operators registering a Telegram bot for the first time will improvise token storage. Doing this once-and-canonically protects every future tenant.
- **Recursive coherence.** cdd self-describes via cycles in cnos, but the cdd protocol itself does not name the bootstrap that brought cnos under cdd. The activation skill closes that gap and makes the protocol applicable to itself.

## Status truth

| Surface | Status | Notes |
|---|---|---|
| `cdd/activation/SKILL.md` | NOT EXIST | This proposal |
| `.cdd/` directory scaffold prescription | Implicit (informal across cycles) | Activation §3 |
| CDD version pin (`.cdd/CDD-VERSION`) | NOT EXIST | Activation §4 |
| Issue label setup | Ad hoc per repo | Activation §5 |
| Branch convention | Implicit | Activation §6 |
| Identity convention setup | Pending `proposals/cnos-cdd-identity-convention` | Activation §7 references |
| Dispatch configuration declaration | Pending `proposals/cnos-cdd-claude-code-dispatch` | Activation §8 references |
| CI integration prescription | NOT NAMED | Activation §9 |
| Notification interface — generic | NOT NAMED | Activation §10 |
| Notification adapter — Telegram | NOT NAMED | Activation §10 (reference adapter via Cycle B) |
| Secrets management prescription | NOT NAMED | Activation §11 |
| Cycle-README template | Implicit (drift across releases) | Activation §12 |
| Cross-repo trace bundle init | Implicit (per-cycle creation) | Activation §13 |
| Honest-claim manifest convention | NOT NAMED | Activation §14 |
| MCA registry (`.cdd/MCAs/INDEX.md`) | NOT EXIST | Activation §15 |
| Skill bundle pull/sync mechanism | Ad hoc | Activation §16 |
| Pre-commit / pre-push hooks | NOT NAMED | Activation §17 |
| Per-cycle dispatch override | NOT NAMED | Activation §18 |
| Operator handle registry (`.cdd/OPERATORS`) | NOT EXIST | Activation §19 |
| Close-out SLA | NOT NAMED | Activation §20 |
| Release cadence declaration (`.cdd/CADENCE`) | Implicit (versioned vs rolling-docs) | Activation §21 |
| cdd-iteration cadence | Implicit (per-cycle by convention) | Activation §22 |
| tsc CI loop for engine + spec + katas | NOT EXIST | This proposal §Scope, tsc-side adoption |
| tsc Telegram notification | NOT EXIST | This proposal §Scope, tsc-side adoption |

## Source of truth

| Claim / surface | Canonical source | Status |
|---|---|---|
| Existing cdd skill bundle | `cnos:cdd/{CDD.md, alpha, beta, gamma, operator, issue, release, post-release, review}/SKILL.md` | Shipped |
| `.cdd/` directory pattern | cnos + tsc empirical layout (`.cdd/{releases, unreleased, iterations}/...`) | Shipped (de facto) |
| GitHub Actions reference for CI | GitHub docs (external) | External |
| Telegram Bot API | core.telegram.org/bots/api | External |
| GitHub repo secrets storage | GitHub docs (external) | External |
| Identity convention | `proposals/cnos-cdd-identity-convention/ISSUE.md` | Drafted |
| Dispatch configurations | `proposals/cnos-cdd-claude-code-dispatch/ISSUE.md` | Drafted |
| Empirical evidence — tsc activation tax | tsc cycles #21–#32: each cycle re-derives some activation-shaped step | Shipped |

## Cycle scope sizing (per cnos §1.6c heuristic)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | Moderate — Telegram notifier reference impl + GitHub Actions templates + skill-vendor refresh tooling | yes (split candidate) |
| (b) Cross-module breadth | New top-level skill (24 sections) + 3 cross-references + reference impl + tenant adoption | yes (cnos side and tenant side are separate concerns) |
| (c) Lifecycle span | crosses lifecycle (skill drafting + reference impl + tenant adoption) | yes |
| (d) MCA preconditions | not MCA — design fixed in body; 37 open questions all carry recommendations | n/a |
| (e) Independent shippability | activation skill ships standalone; reference impl ships standalone; tenant adoption ships per-tenant | yes (3 ship lines) |

**Decision:** **split** into 3 cycles, run sequentially.

- **Cycle A — `cnos:cdd/activation/SKILL.md` skill drafting.** Prose-only. 6–8 ACs. **Note:** 24 sections + 37 decision-required open questions push this to the upper edge; if Cycle A's δ judges the open-question count too large to resolve in one cycle, split A further into A.1 (skill scaffold + §1–§12) and A.2 (§13–§24 + open-question resolutions).
- **Cycle B — Reference notifier implementation.** Telegram bot adapter + GitHub Actions templates + skill-vendor refresh tooling, in cnos under `cdd/activation/templates/`. 5–7 ACs.
- **Cycle C — tsc adoption.** CI runs spec + engine tests + katas; Telegram bot wired; secrets in repo settings; activation marker files (`.cdd/CDD-VERSION`, `.cdd/DISPATCH`, `.cdd/CADENCE`, `.cdd/MCAs/INDEX.md`, `.cdd/OPERATORS`, `.cdd/skills/`) populated. 6–8 ACs.

This issue tracks **all three (or four) cycles as a meta-issue**; each cycle gets its own sub-issue when filed.

## Scope

### Cycle A — `cnos:cdd/activation/SKILL.md` skill

**In scope:**

1. New file `cnos:cdd/activation/SKILL.md` with sections:
   - **§1 Purpose** — bootstrap an existing repo to operate under cdd
   - **§2 Pre-conditions** — repo exists, has a primary branch, host supports labels + secrets + CI (GitHub assumed; mark portability)
   - **§3 `.cdd/` scaffold** — exact directory tree to create, with one-line purpose per directory
   - **§4 Version pin** — `.cdd/CDD-VERSION` file naming the cnos cdd commit/tag this repo follows
   - **§5 Labels** — minimum label set: `cdd`, `mca`, `P0`, `P1`, `P2`, `P3`; project may add more (e.g., tsc adds `kata`)
   - **§6 Branch convention** — `cycle/{N}` numbering rule, who owns N-allocation
   - **§7 Identity convention** — references `cnos:cdd/operator/SKILL.md` §"Git identity" (per `proposals/cnos-cdd-identity-convention`); per-actor `git config --local`
   - **§8 Dispatch declaration** — `.cdd/DISPATCH` file naming §5.1 vs §5.2 (per `proposals/cnos-cdd-claude-code-dispatch`); affects honest-grading floor
   - **§9 CI integration** — minimum CI surface: artifact validation (`.cdd/` structure consistent, every cycle has required files), test runs, spec runs, project-specific progressions
   - **§10 Notification integration** — generic interface (event types: cycle-open, β-verdict, RC, merge; transport adapter contract); reference adapter for Telegram (links Cycle B)
   - **§11 Secrets** — what lives in repo secrets (bot tokens), what lives only locally (developer keys); naming convention (`CDD_TELEGRAM_BOT_TOKEN`, `CDD_TELEGRAM_CHAT_ID`)
   - **§12 Cycle-README template** — minimum file set per `releases/{version}/{N}/`: self-coherence.md, alpha-closeout.md, beta-review.md, gamma-closeout.md, cdd-iteration.md
   - **§13 Cross-repo trace bundle init** — pre-create `.cdd/iterations/cross-repo/` with a README naming the `{target}/{slug}/` convention (per cnos `cdd/CDD.md` cross-repo trace bundle prescription); explain when a tenant creates a bundle (any work that targets another repo) and what files belong in it
   - **§14 Honest-claim manifest convention** — name the location and per-cycle pattern for honest-claim manifests (per cnos rule 3.13); each cycle's `claims.md` lives at `releases/{version}/{N}/claims.md` enumerating reproducibility / source-of-truth alignment / wiring claims with verification commands
   - **§15 MCA registry** — `.cdd/MCAs/INDEX.md` enumerates in-flight multi-cycle architectures with status (open / converging / closed), originating cycle, target close cycle, owner; today MCAs are inferred from issue labels with no central index
   - **§16 Skill bundle pull/sync** — prescribe how the tenant obtains cnos cdd skills: vendored copy under `.cdd/skills/` (frozen at `.cdd/CDD-VERSION` SHA), live `git submodule`, or `gh release download`; recommend vendored for reproducibility
   - **§17 Pre-commit / pre-push hooks** — optional `.cdd/hooks/` with `validate-structure`, `validate-cycle-readme`, `check-claims`; tenant opts in via local symlinks to `.git/hooks/`; CI catches what local hooks miss
   - **§18 Per-cycle dispatch override** — `.cdd/DISPATCH` records the repo default; individual cycles may override via `releases/{version}/{N}/DISPATCH-OVERRIDE` (per `proposals/cnos-cdd-claude-code-dispatch` §5.3 escalation criteria)
   - **§19 Operator handle registry** — `.cdd/OPERATORS` enumerates authorized δ handles with identity emails (per `proposals/cnos-cdd-identity-convention`); cycle commits whose trailers don't match a registered operator are flagged in CI
   - **§20 Close-out SLA** — prescribe maximum time from cycle merge to close-out artifact visibility (recommend ≤24h); CI emits a notification at SLA breach; close-out artifacts include all five files in §12
   - **§21 Release cadence declaration** — `.cdd/CADENCE` records `versioned` (e.g., tsc engine v0.7.0) or `rolling-docs` (e.g., cnos `releases/docs/{ISO-date}/{N}/`) or `mixed`; affects directory layout per §3 and tagging behavior per §22
   - **§22 cdd-iteration cadence** — every cycle writes a `cdd-iteration.md`; MCAs spawn manually when findings cluster; auto-spawn rule (≥3 same-axis findings in N consecutive cycles) is optional and policy-able per repo via `.cdd/CADENCE`
   - **§23 Activation checklist** — numbered checklist tenants run once when adopting
   - **§24 Verification** — how to confirm activation succeeded (one canonical command or check)

2. Cross-reference inserts in:
   - `cnos:cdd/CDD.md` — link to activation skill from the protocol overview
   - `cnos:cdd/operator/SKILL.md` — first-time-operator pointer to activation
   - `cnos:cdd/post-release/SKILL.md` — note that activation findings flow into cdd-iteration

**Out of scope (Cycle A):**

- Reference notifier implementation (Cycle B)
- Tenant-side adoption (Cycle C)
- Hosts other than GitHub (note portability surface but don't author adapters)

### Cycle B — reference notifier impl

**In scope:**

1. `cnos:cdd/activation/templates/telegram-notifier/` — small reference implementation (single script + GitHub Action workflow) that posts to Telegram on:
   - cycle-open (push to `cycle/{N}` branch)
   - β-verdict (push of `beta-review.md`)
   - RC failure / fix-round (push of `*-r{R}` artifacts)
   - cycle-merge (push to main)
2. `cnos:cdd/activation/templates/github-actions/` — at minimum:
   - `cdd-artifact-validate.yml` — checks `.cdd/` structure on every push
   - `cdd-cycle-on-merge.yml` — runs project test suite + emits notification on cycle merge
3. Documented config — repo secrets to set, chat ID acquisition, bot registration walkthrough

### Cycle C — tsc adoption

**In scope:**

1. tsc-side `.cdd/CDD-VERSION` and `.cdd/DISPATCH` files
2. tsc GitHub Actions wiring the activation templates:
   - Engine test suite runs on every push
   - Spec validation runs on every push
   - **Engine katas run on every push** (per the user's primary ask)
   - Telegram notifier wired to a configured bot
3. Repo secrets configured (`CDD_TELEGRAM_BOT_TOKEN`, `CDD_TELEGRAM_CHAT_ID`)
4. README badge surfacing CI status (optional)
5. tsc-side `cdd-iteration.md` finding recording activation experience

## Acceptance Criteria

### Cycle A ACs

**A.AC1 — `cdd/activation/SKILL.md` exists and covers §1–§24.** Each section is present with substantive prose (not a stub). Total skill length within range expanded for the broader scope.

- *Invariant:* every section in §Scope Cycle A item 1 is present and ≥3 sentences.
- *Oracle:* `wc -l cnos:cdd/activation/SKILL.md` returns 600–1100.
- *Positive:* `rg '^## §' cnos:cdd/activation/SKILL.md` returns 24 hits.
- *Negative:* no "TODO" or "tbd" markers in the file.
- *Surface:* `cnos:cdd/activation/SKILL.md`.

**A.AC2 — Cross-references inserted.** `cdd/CDD.md`, `cdd/operator/SKILL.md`, `cdd/post-release/SKILL.md` each gain ≤3-line pointer to activation skill.

- *Invariant:* one link per file, no duplicates.
- *Oracle:* `rg 'cdd/activation/SKILL.md' cnos:cdd/` returns ≥3 cross-reference hits.
- *Positive:* each cross-reference appears in a contextually appropriate section (CDD.md overview, operator §1 for first-time setup, post-release for cdd-iteration linkage).
- *Negative:* no broken relative links.
- *Surface:* the three cnos files above.

**A.AC3 — Notification interface is transport-agnostic.** §10 names the event vocabulary and adapter contract independently of any specific transport.

- *Invariant:* §10 prose mentions Telegram only as one example; the contract section names ≥1 other transport that could be implemented.
- *Oracle:* §10 contains a "transport contract" subsection enumerating ≥4 events.
- *Positive:* a hypothetical Slack adapter could be implemented without changing the skill.
- *Negative:* no Telegram-specific assumptions baked into the §10 contract.
- *Surface:* `cnos:cdd/activation/SKILL.md` §10.

**A.AC4 — Secrets prescription is concrete and minimal.** §11 enumerates exact secret names, where they live (GitHub repo secrets), and explicitly forbids committing tokens.

- *Invariant:* secret names match `CDD_*` namespace.
- *Oracle:* §11 contains a labeled table of secrets.
- *Positive:* a tenant can copy the table verbatim and it works.
- *Negative:* no example tokens in the file (not even fake ones — easy to mistake).
- *Surface:* §11.

**A.AC5 — Activation checklist is numbered and runnable.** §23 is a numbered list of ≤24 steps (one per content section §3–§22), each ≤2 sentences, executable in order with no forward dependencies on later steps.

- *Invariant:* every step has a verification (one-line "expected outcome").
- *Oracle:* §23 step count between 18 and 24.
- *Positive:* a fresh repo run end-to-end through §23 reaches "activation complete" verifiably.
- *Negative:* no step requires manual judgment beyond what cdd already documents.
- *Surface:* §23.

**A.AC6 — Honest-claim gates.** Self-application: cnos itself (already activated, but never explicitly so) has §23 retroactively run against it as a verification; missing artifacts (`.cdd/CDD-VERSION`, `.cdd/DISPATCH`, `.cdd/MCAs/INDEX.md`, `.cdd/OPERATORS`, `.cdd/CADENCE`, `.cdd/skills/` or its declared substitute) are added to cnos as part of this cycle.

- *Invariant:* cnos passes its own activation §24 verification at cycle merge.
- *Oracle:* the five activation marker files above exist in cnos main.
- *Positive:* close-out cdd-iteration finding records "self-activated as proof."
- *Negative:* no "skip this for cnos" exceptions.
- *Surface:* cnos `.cdd/`.

### Cycle B ACs

**B.AC1 — Telegram notifier reference impl works end-to-end.** Single-file script + GitHub Action workflow; given configured secrets, a push to `cycle/{N}` posts a message to the configured chat.

**B.AC2 — Artifact validator catches missing files.** A test cycle missing `gamma-closeout.md` causes the action to fail with a clear message.

**B.AC3 — Workflow templates are copy-pasteable.** Tenants drop the YAML into `.github/workflows/` with no edits beyond secret names.

**B.AC4 — README walkthrough.** `cnos:cdd/activation/templates/README.md` walks bot registration, secret setup, first activation, end-to-end ≤300 words.

**B.AC5 — Notifier honors transport-agnostic event vocabulary.** Event names in the script match those in skill §10.

### Cycle C ACs

**C.AC1 — tsc CI runs engine tests on every push.** GitHub Action green on a known-good commit; red on a deliberately-broken commit; reverted.

**C.AC2 — tsc CI runs spec validation on every push.** Spec round-trip / link-check / hierarchy-marker check; runs in <60s.

**C.AC3 — tsc CI runs engine katas on every push.** Per tsc #33 (kata framework) — every defined kata runs and reports pass/fail.

**C.AC4 — tsc Telegram notifier posts on cycle events.** Test push to a `cycle/test` branch produces a Telegram message.

**C.AC5 — Activation marker files populated.** `.cdd/CDD-VERSION`, `.cdd/DISPATCH`, `.cdd/CADENCE`, `.cdd/MCAs/INDEX.md`, `.cdd/OPERATORS`, `.cdd/skills/` all present and well-formed per the skill prescription.

**C.AC6 — Activation checklist self-applies.** Running `cdd/activation/SKILL.md` §23 against tsc passes §24.

**C.AC7 — Cross-repo trace bundle dir initialized.** `.cdd/iterations/cross-repo/README.md` present; existing supercycle trace bundle relocated/conformed if needed.

**C.AC8 — cdd-iteration finding.** tsc cycle close-out records the activation experience: friction points, suggested skill amendments.

## Proof plan

1. **Cycle A** — author skill, walk §13 against cnos, fill the gaps that surface (CDD-VERSION, DISPATCH), close out.
2. **Cycle B** — implement Telegram notifier in a sandbox bot, dry-run all four events, then write GitHub Actions templates, then test against a fresh test repo, close out.
3. **Cycle C** — apply Cycle B templates to tsc, configure secrets, run on a test branch, observe Telegram posts, run §14 verification, close out.

## Risks

- **Skill bloat.** A 14-section skill is at the upper end of cdd skill files. Mitigation: prose budget per section enforced by A.AC1 length oracle; sections that grow get hived to sub-skills.
- **Telegram API churn.** Reference impl couples to Telegram's bot API. Mitigation: §10 transport-agnostic vocabulary; Telegram is the reference adapter, not the spec.
- **Secret leakage.** Bot token in CI logs would be a real incident. Mitigation: A.AC4 forbids example tokens; CI templates use GitHub's secret-masking; explicit prescription in §11.
- **Per-host portability.** Skill assumes GitHub. Mitigation: §2 pre-conditions name the assumption; skill is portable in shape but worked examples are GitHub-flavored.
- **Activation order matters.** §6 (branch convention) before §8 (dispatch declaration) before §13 (checklist) — a tenant doing them in the wrong order may discover later rework. Mitigation: A.AC5 invariant "no forward dependencies."

## Open questions

Each must be decided by Cycle A. Recommendations are the proposal's preferred answers; cycle β may override with reasoning.

### Original (§3–§12 surface)

1. **`.cdd/CDD-VERSION` format.** SHA pin? Tag pin? Date pin? — *Recommendation:* cnos commit SHA, with a tag if one exists, both recorded one per line.
2. **`.cdd/DISPATCH` format.** Single line `§5.1` / `§5.2`, or richer YAML? — *Recommendation:* single line keyed to operator skill section; richer YAML only if dispatch sub-modes proliferate.
3. **Notification on operator (δ) vs sub-agent (α/β) actions.** Both? Only milestones? — *Recommendation:* milestones only (cycle-open, β-verdict, RC, merge) to avoid notification fatigue.
4. **CI for `.cdd/` structure validation.** Minimum check? File presence, schema, internal cross-references? — *Recommendation:* start with file presence per §12 template; schema later as Cycle B+ enhancement.
5. **Multi-bot / multi-channel routing.** Tenant may want different cycles to notify different channels. — *Recommendation:* out-of-scope for reference adapter; adapter contract permits but reference impl does not implement.
6. **Reverse-portability — repos already activated ad hoc.** cnos and tsc both predate this skill. — *Recommendation:* A.AC6 mandates retro-self-activation for cnos in Cycle A; tsc gets retro-activated in Cycle C.
7. **Activation idempotence.** Running the checklist twice on an already-activated repo must be safe. — *Recommendation:* §24 verification check runs first; skip steps whose outputs already exist.
8. **Telegram bot token rotation.** Bot tokens leak; rotation is an operator action. — *Recommendation:* §11 names rotation cadence — quarterly default, every-cycle for high-sensitivity repos.

### Cross-repo trace bundles (§13)

9. **Pre-create empty `.cdd/iterations/cross-repo/` at activation, or lazy-create on first cross-repo cycle?** — *Recommendation:* pre-create with README; the README itself is documentation that pays for itself.
10. **Trace bundle naming `{target}/{slug}/` vs `{target}-{slug}/` flat?** — *Recommendation:* nested `{target}/{slug}/` matches existing cnos-tsc supercycle layout; sortable, groups bundles by target.
11. **Bundle close-out signal — when is a cross-repo bundle "done"?** — *Recommendation:* when both originating-repo cycle and target-repo cycle have shipped close-outs; bundle adds a `STATUS` file with `open|converging|closed`.

### Honest-claim manifests (§14)

12. **Per-cycle `claims.md` or per-AC claims woven into each AC's "Oracle"?** — *Recommendation:* per-cycle `claims.md` separate file — easier to grade as a unit; ACs link to it.
13. **Claim categories enumerated.** Reproducibility, source-of-truth alignment, wiring (per cnos rule 3.13). Are these exhaustive? — *Recommendation:* these three are the floor; cycle may add categories with rationale.
14. **Empty claim manifest permitted (cycle made no honest claims)?** — *Recommendation:* no — every cycle states at least one claim (even if "no behavior change") to force the discipline.

### MCA registry (§15)

15. **`.cdd/MCAs/INDEX.md` format — table or per-MCA file?** — *Recommendation:* INDEX.md is a table; each MCA also has its own `.cdd/MCAs/{slug}/README.md` with originating cycle, target cycles, owner, current state.
16. **MCA close criteria.** When does an MCA move from `converging` to `closed`? — *Recommendation:* close requires (a) all named target cycles shipped, (b) close-out cycle's cdd-iteration confirms axis collapse.
17. **Auto-suggest MCA when ≥3 same-axis findings in N cycles?** — *Recommendation:* yes, but as an *operator* alert in CI output, not auto-creation; operator decides whether to formalize.

### Skill bundle pull/sync (§16)

18. **Vendored copy vs git submodule vs `gh release download`?** — *Recommendation:* vendored copy under `.cdd/skills/` for reproducibility (skill version frozen at `.cdd/CDD-VERSION` SHA); operator runs a refresh command to update.
19. **Refresh cadence.** Per-cycle? On `.cdd/CDD-VERSION` bump only? — *Recommendation:* on bump only; operator explicitly bumps version with rationale, then refreshes.
20. **Integrity verification.** SHA check on vendored skills against cnos source? — *Recommendation:* yes, single CI step compares vendored skill SHAs against `.cdd/CDD-VERSION`'s cnos tree.

### Pre-commit / pre-push hooks (§17)

21. **Local hooks opt-in or opt-out?** — *Recommendation:* opt-in (symlink installation) — many developers won't tolerate hooks installed by clone; CI is the authoritative gate.
22. **Hook scope.** Just structure validation, or also content (claim manifest non-empty, README template fields filled)? — *Recommendation:* structure only locally; content checks live in CI to keep local-hook latency low.
23. **Hook failure mode.** Block commit, or warn? — *Recommendation:* block for malformed `.cdd/` structure; warn for missing optional fields.

### Per-cycle dispatch override (§18)

24. **`releases/{version}/{N}/DISPATCH-OVERRIDE` format.** Just the section reference, or with reason field? — *Recommendation:* section reference + one-line reason (mandatory) — overrides need justification or they're noise.
25. **Override visible in close-out grading?** — *Recommendation:* yes — γ-closeout TSC Grades section names the dispatch actually used (overridden or default).

### Operator handle registry (§19)

26. **`.cdd/OPERATORS` format — table or YAML?** — *Recommendation:* simple table (handle, identity-email, role-scopes-permitted, added-cycle).
27. **CI enforcement strictness.** Block merge on unregistered operator commit, or warn? — *Recommendation:* warn for first cycle after activation (grace period); block thereafter.
28. **Handle revocation.** What happens when an operator is removed? — *Recommendation:* row stays with `removed-cycle` populated; historical commits remain valid (registry is forward-only).

### Close-out SLA (§20)

29. **24h hard cap, or repo-configurable?** — *Recommendation:* 24h default in skill; repo can override in `.cdd/CADENCE` with rationale.
30. **SLA breach action.** Telegram alert? Block next cycle dispatch? — *Recommendation:* alert only in Cycle B; block-on-breach in a follow-on cycle if alerts prove insufficient.
31. **What counts as "close-out artifact visibility"?** Push to merged branch, or merge to main? — *Recommendation:* merge to main — PR-merged is the canonical visibility.

### Release cadence declaration (§21)

32. **`.cdd/CADENCE` enum — `versioned` / `rolling-docs` / `mixed`?** — *Recommendation:* exactly these three; `mixed` for repos like tsc that ship both versioned engine releases and docs-only cycles.
33. **Cadence affects directory layout how?** `releases/{semver}/{N}/` vs `releases/docs/{ISO-date}/{N}/`? — *Recommendation:* yes, prescribe both layouts per cadence; `mixed` repos use both.
34. **Tagging discipline per cadence.** `v0.7.0` git tags for versioned, no tag for rolling-docs? — *Recommendation:* yes — versioned cycles tag at merge; docs-only cycles do not (they're date-anchored).

### cdd-iteration cadence (§22)

35. **Every cycle writes `cdd-iteration.md`, or only when findings exist?** — *Recommendation:* every cycle — empty findings list is also signal (clean cycle, no protocol gap surfaced).
36. **Auto-spawn MCA when ≥3 same-axis findings in N consecutive cycles — what is N?** — *Recommendation:* N=5; window slides; operator approves materialization.
37. **Findings severity scale.** Adopt α/β/γ severities (A/B/C) or new scale? — *Recommendation:* reuse review/SKILL.md severities for consistency; add `info` for non-actionable observations.

## References

- `proposals/cnos-cdd-claude-code-dispatch/ISSUE.md` — dispatch configurations referenced by §8
- `proposals/cnos-cdd-identity-convention/ISSUE.md` — identity form referenced by §7
- cnos cycle #338 (dispatch sizing) — informs §13 step weighting
- cnos cycle #339 (mechanical pre-merge gate) — informs §9 CI artifact validation
- tsc cycle history #21–#32 — empirical activation-tax evidence
- Telegram Bot API — core.telegram.org/bots/api (external)
- GitHub Actions — docs.github.com/actions (external)
- GitHub Repo Secrets — docs.github.com/actions/security-guides/encrypted-secrets (external)
