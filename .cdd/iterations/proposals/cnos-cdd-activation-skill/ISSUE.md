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
| `.cdd/` directory scaffold prescription | Implicit (informal across cycles) | Activation §1 |
| CI integration prescription | NOT NAMED | Activation §3 |
| Notification adapter — Telegram | NOT NAMED | Activation §4 (reference adapter) |
| Notification adapter — generic interface | NOT NAMED | Activation §4 |
| Secrets management prescription | NOT NAMED | Activation §5 |
| Issue label setup | Ad hoc per repo | Activation §2 |
| Identity convention setup | Pending `proposals/cnos-cdd-identity-convention` | Activation §6 references |
| Dispatch configuration declaration | Pending `proposals/cnos-cdd-claude-code-dispatch` | Activation §7 references |
| Cycle-README template | Implicit (drift across releases) | Activation §8 |
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
| (a) New code surface | Moderate — Telegram notifier reference impl + GitHub Actions templates | yes (split candidate) |
| (b) Cross-module breadth | New top-level skill + 3 cross-references + reference impl + tsc-side adoption | yes (cnos side and tenant side are separate concerns) |
| (c) Lifecycle span | crosses lifecycle (skill drafting + reference impl + tenant adoption) | yes |
| (d) MCA preconditions | not MCA — design fixed in body | n/a |
| (e) Independent shippability | activation skill ships standalone; reference impl ships standalone; tenant adoption ships per-tenant | yes (3 ship lines) |

**Decision:** **split** into 3 cycles, run sequentially.

- **Cycle A — `cnos:cdd/activation/SKILL.md` skill drafting.** Prose-only. 6–8 ACs.
- **Cycle B — Reference notifier implementation.** Telegram bot adapter + GitHub Actions templates, in cnos under `cdd/activation/templates/`. 5–7 ACs.
- **Cycle C — tsc adoption.** CI runs spec + engine tests + katas; Telegram bot wired; secrets in repo settings. 5–7 ACs.

This issue tracks **all three cycles as a meta-issue**; each cycle gets its own sub-issue when filed.

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
   - **§13 Activation checklist** — numbered checklist tenants run once when adopting
   - **§14 Verification** — how to confirm activation succeeded (one canonical command or check)

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

**A.AC1 — `cdd/activation/SKILL.md` exists and covers §1–§14.** Each section is present with substantive prose (not a stub). Total skill length within range of existing skill files (~300–600 lines).

- *Invariant:* every section in §Scope Cycle A item 1 is present and ≥3 sentences.
- *Oracle:* `wc -l cnos:cdd/activation/SKILL.md` returns 300–700.
- *Positive:* `rg '^## §' cnos:cdd/activation/SKILL.md` returns 14 hits.
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

**A.AC5 — Activation checklist is numbered and runnable.** §13 is a numbered list of ≤15 steps, each ≤2 sentences, executable in order with no forward dependencies on later steps.

- *Invariant:* every step has a verification (one-line "expected outcome").
- *Oracle:* §13 step count between 8 and 15.
- *Positive:* a fresh repo run end-to-end through §13 reaches "activation complete" verifiably.
- *Negative:* no step requires manual judgment beyond what cdd already documents.
- *Surface:* §13.

**A.AC6 — Honest-claim gates.** Self-application: cnos itself (already activated, but never explicitly so) has §13 retroactively run against it as a verification; missing artifacts (e.g., `.cdd/CDD-VERSION`, `.cdd/DISPATCH`) are added to cnos as part of this cycle.

- *Invariant:* cnos passes its own activation §14 verification at cycle merge.
- *Oracle:* `.cdd/CDD-VERSION` and `.cdd/DISPATCH` exist in cnos main.
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

**C.AC5 — `.cdd/CDD-VERSION` and `.cdd/DISPATCH` populated.** Version pin matches the cnos cdd commit lineage; dispatch records §5.1 or §5.2 per cycle history.

**C.AC6 — Activation checklist self-applies.** Running `cdd/activation/SKILL.md` §13 against tsc passes §14.

**C.AC7 — cdd-iteration finding.** tsc cycle close-out records the activation experience: friction points, suggested skill amendments.

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

1. **`.cdd/CDD-VERSION` format.** SHA pin? Tag pin? Date pin? Recommendation: cnos commit SHA, with a tag if one exists, both recorded.
2. **`.cdd/DISPATCH` format.** Single line `§5.1` / `§5.2`, or richer YAML? Recommendation: single line keyed to operator skill section; richer if dispatch sub-modes proliferate.
3. **Notification on operator (δ) actions vs sub-agent (α/β) actions.** Both? Only milestones? Recommendation: milestones only — cycle-open, β-verdict, RC, merge — to avoid notification fatigue.
4. **CI for `.cdd/` structure validation.** What's the minimum check? File presence, schema, internal cross-references? Recommendation: start with file presence per §12 template; schema later as a separate Cycle B+ enhancement.
5. **Multi-bot / multi-channel routing.** A tenant may want different cycles to notify different channels (e.g., spec cycles to one chat, engine cycles to another). Recommendation: out-of-scope for reference adapter; adapter contract permits but does not implement.
6. **Reverse-portability — repos already activated ad hoc.** cnos and tsc both predate this skill. Recommendation: A.AC6 mandates retro-self-activation for cnos in Cycle A; tsc gets retro-activated in Cycle C as part of the tenant adoption.
7. **Activation idempotence.** Running the checklist twice on an already-activated repo should be safe (no clobber). Recommendation: §14 verification check runs first; skip steps whose outputs already exist.
8. **Telegram bot token rotation.** Bot tokens leak; rotation is an operator action. Recommendation: §11 names rotation cadence (every cycle? quarterly?) — open for cycle to decide.

## References

- `proposals/cnos-cdd-claude-code-dispatch/ISSUE.md` — dispatch configurations referenced by §8
- `proposals/cnos-cdd-identity-convention/ISSUE.md` — identity form referenced by §7
- cnos cycle #338 (dispatch sizing) — informs §13 step weighting
- cnos cycle #339 (mechanical pre-merge gate) — informs §9 CI artifact validation
- tsc cycle history #21–#32 — empirical activation-tax evidence
- Telegram Bot API — core.telegram.org/bots/api (external)
- GitHub Actions — docs.github.com/actions (external)
- GitHub Repo Secrets — docs.github.com/actions/security-guides/encrypted-secrets (external)
