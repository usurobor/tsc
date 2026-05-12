# cdd/activation: Add §11a — Operator access flow for notification channels (invite-link convention + sample message shapes)

**Labels:** `docs, P2, cdd`
**Priority:** P2 — companion to cnos #344 (activation skill) Cycle A. Without operator-access prescription, tenants will ship bot-side wiring (token, chat ID, post permission) but fail to onboard operators to *receive* the notifications. The activation §10/§11 cover sending; this issue covers receiving.
**Status:** Drafted; ready for cycle dispatch.
**Mode:** `docs-only, design-and-build` — adds one subsection to `cdd/activation/SKILL.md` plus one column to `.cdd/OPERATORS` convention.
**Depends on:** cnos #344 (activation skill — Cycle A must define §10/§11 first); references §19 operator registry from #344.

## Problem

**What exists:** cnos #344's activation skill §10 prescribes a transport-agnostic notification interface; §11 prescribes secrets (`CDD_TELEGRAM_BOT_TOKEN`, `CDD_TELEGRAM_CHAT_ID`); §19 prescribes an operator registry (`.cdd/OPERATORS`). Cycle B's reference adapter implements Telegram bot posting.

**What is expected:** A new operator joining a tenant repo needs to *receive* the notifications the bot posts. Today the activation skill covers the bot side end-to-end (creation, secrets, post permission, event vocabulary) but stops at the channel. The operator-access flow — how a new operator joins the channel the bot posts to — is unspecified.

**Where they diverge:** Repo owners following activation §1–§13 (or §1–§24 per the expanded proposal) successfully wire the bot to post to a private Telegram channel. New operators added later have no canonical path to join. They either get ad-hoc invite links via DM, never receive notifications and use ad-hoc out-of-band updates, or the channel is made public (security regression).

## Impact

- **Onboarding friction.** Every new operator added to a tenant repo requires the repo owner to manually generate an invite link, DM it, walk them through joining, and hope they don't lose access on app reinstall. Multiplied across cdd's lifetime, this is exactly the same activation tax #344 was filed to eliminate, applied to the operator slot specifically.
- **Channel hygiene drift.** Without a canonical home for invite links, they end up in ad-hoc places — Slack DMs, password managers, README snippets, sometimes the public repo wiki. The invite is a join-credential; storing it in inconsistent locations is the precondition for leak.
- **Operator-removal incomplete.** When `.cdd/OPERATORS` (per activation §19) records a `removed-cycle` for a former operator, the cycle commit trailer no longer authenticates that operator's commits — but nothing in the activation skill says to *remove them from the Telegram channel*. The notification channel becomes a hidden grant that outlives the registry row.
- **Recursive coherence.** Activation §10 says notifications are "transport-agnostic" but currently models notification access only from the *bot's* side. The operator side — how the human in the loop joins the loop — is symmetric with the bot side and deserves the same treatment.

## Status truth

| Surface | Status | Notes |
|---|---|---|
| Activation §10 transport-agnostic event vocabulary | Pending #344 Cycle A | Covers sender side |
| Activation §11 secrets (bot token, chat ID) | Pending #344 Cycle A | Covers sender side |
| Activation §19 operator registry (`.cdd/OPERATORS`) | Pending #344 Cycle A | Records operator identities; no notification-access column |
| Reference Telegram adapter (Cycle B) | Pending #344 Cycle B | Bot creates, posts — does not describe how humans subscribe |
| Operator access flow for notification channels | NOT NAMED | This issue |
| Invite-link convention | NOT NAMED | This issue §Scope item 1 |
| Sample message shapes per event | NOT NAMED | This issue §Scope item 2 |
| Two-way bot interaction (operator → bot commands) | Explicitly out-of-scope | This issue §Out of scope; future proposal if needed |

## Source of truth

| Claim / surface | Canonical source | Status |
|---|---|---|
| Activation §10/§11/§19 prescriptions | cnos #344 issue body + Cycle A deliverable `cdd/activation/SKILL.md` | Pending |
| Telegram invite link mechanics | core.telegram.org/api/invites + Telegram client docs | External |
| Channel admin permissions | Telegram docs (admin / restricted / banned roles) | External |
| Empirical operator-onboarding friction | Implicit in every multi-operator cdd tenant; not yet captured in cycle close-outs | Inferred |

## Cycle scope sizing (per cnos §1.6c heuristic)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | 0 — prose-only addition to one skill file | no |
| (b) Cross-module breadth | One subsection in `cdd/activation/SKILL.md` + one new column in `.cdd/OPERATORS` table format | low |
| (c) Lifecycle span | docs-only | no |
| (d) MCA preconditions | not MCA — design fixed in body | n/a |
| (e) Independent shippability | one cohesive subsection; partial conversion leaves the access flow half-described | no |

**Decision:** keep whole. 4 ACs, low-typical band. Small companion cycle to #344 Cycle A — could even be folded into A if timing permits.

## Scope

**In scope:**

1. **Add `cdd/activation/SKILL.md` §11a "Operator access for notification channels"** (or §10.5 between event vocab and secrets — Cycle A decides position). Three subsections:
   - **§11a.1 Invite-link convention.** Repo owner generates a Telegram channel invite link (or transport-equivalent for non-Telegram). Link stored in `.cdd/OPERATORS` as a new column. Channel itself is admin-controlled private — invite link is a join-credential but not standalone auth (admin sees joins and can remove strangers).
   - **§11a.2 Channel scope.** Recommend one channel per repo for clean filtering. Cross-repo operators use Telegram folders. Cycle-class scoping (e.g., spec cycles → channel A, engine cycles → channel B) is permitted but out of scope for the canonical prescription.
   - **§11a.3 Operator removal hygiene.** When `.cdd/OPERATORS` records `removed-cycle`, the same row's `Notification-access` column is cleared and the operator is removed from the channel by the repo admin. Removal is a two-step action (registry + channel); a checklist row in §11a.3 enforces both.

2. **Add a worked sample message shape per canonical event.** Four blocks in §11a.4, one per event from §10:
   - `cycle-open` — short, single-line, includes cycle number + branch + dispatching operator handle
   - `β-verdict` — multi-line, includes verdict (APPROVED / RC / fix-round), severity counts (A/B/C/note), top finding if RC
   - `RC` / fix-round — fix-round number, original cycle, owning α
   - `cycle-merge` — final commit SHA, link to PR/merge commit, total rounds, final TSC grade
   
   These are *shapes*, not requirements — the reference adapter (Cycle B) implements them; alternate adapters honor the same shape contract.

3. **Update `.cdd/OPERATORS` row format** to add a `Notification-access` column. Per-operator: value is either the Telegram chat invite link, a transport-agnostic URI (`tg+invite://...`, `slack://...`), or `none` (operator does not receive notifications — explicit, not silent absence).

4. **Mark two-way operator → bot interaction explicitly out-of-scope-v1.** §11a closes with one paragraph naming this: stateless send-only is the canonical v1; bots that *receive* operator commands require a running service, webhook handlers, and auth — much larger surface, separate future proposal if reality demands. Honoring this guardrail keeps the reference adapter (Cycle B) trivially deployable.

**Out of scope:**

- **Two-way operator → bot commands.** Cycle dispatch via `/dispatch 33` in Telegram, β-verdict acknowledgment via reactions, etc. — all separate, larger problem. v1 is send-only.
- **Multi-channel routing per cycle class.** Permitted but not prescribed.
- **Bot-token rotation cadence.** Lives in activation §11 / open question 8 (already in #344).
- **Non-Telegram adapter implementations.** §11a is transport-agnostic; specific adapters are downstream proposals.
- **End-to-end encrypted channel notifications.** Out of scope; Telegram channels are server-side stored. Tenants with E2E requirements use a different transport.

## Acceptance Criteria

**AC1 — §11a subsection authored.** `cdd/activation/SKILL.md` gains §11a (or §10.5 per Cycle A's positioning call) with the three subsections §11a.1–§11a.3 and the sample message shapes §11a.4.

- *Invariant:* every subsection present; each ≥3 sentences except §11a.4 which is sample message blocks.
- *Oracle:* `rg '^### §11a' cnos:cdd/activation/SKILL.md` (or `§10.5` per positioning) returns 4 hits.
- *Positive:* subsection prose is operative — a new tenant repo owner can follow §11a end-to-end on the first read.
- *Negative:* no TODO / tbd markers; no examples that use fake-but-plausible tokens (security hygiene).
- *Surface:* `cdd/activation/SKILL.md`.

**AC2 — `.cdd/OPERATORS` row format gains `Notification-access` column.** Operator registry table format (per activation §19) includes the new column; sample row in the skill demonstrates a populated value.

- *Invariant:* one new column, named `Notification-access`; value is invite link, transport-agnostic URI, or literal `none`.
- *Oracle:* §19 worked-example table in `cdd/activation/SKILL.md` shows a row with the new column populated.
- *Positive:* `.cdd/OPERATORS` row format is self-documenting (column header explains the value space).
- *Negative:* no row has the column missing (forward-only constraint — every new row populates it explicitly).
- *Surface:* `cdd/activation/SKILL.md` §19 (cross-reference) + §11a.1.

**AC3 — Sample message shapes are concrete enough to wire against.** §11a.4 contains four message-shape blocks (cycle-open, β-verdict, RC/fix-round, cycle-merge) in plain text or markdown that a tenant could paste verbatim into a `sendMessage` template.

- *Invariant:* each block names every variable interpolation explicitly (e.g., `{cycle_number}`, `{branch}`, `{verdict}`, `{α_handle}`).
- *Oracle:* `rg '\{[a-z_]+\}' cnos:cdd/activation/SKILL.md` returns ≥10 hits inside §11a.4.
- *Positive:* the reference Telegram adapter (Cycle B) implements the four shapes verbatim.
- *Negative:* no Telegram-specific Markdown that breaks under alternate adapters; shape is transport-agnostic.
- *Surface:* `cdd/activation/SKILL.md` §11a.4.

**AC4 — Two-way out-of-scope-v1 explicitly stated.** §11a closes with one paragraph naming why receive-only is canonical-v1 and what would have to change for two-way (stateless service → stateful daemon).

- *Invariant:* paragraph names ≥3 technical pre-conditions for two-way (running service, webhook handler, auth model).
- *Oracle:* `rg 'two-way' cnos:cdd/activation/SKILL.md` returns ≥1 hit in §11a.
- *Positive:* paragraph is ≤120 words.
- *Negative:* no implicit suggestion that two-way is on the immediate roadmap.
- *Surface:* `cdd/activation/SKILL.md` §11a end.

## Proof plan

1. Author §11a (or §10.5 per Cycle A positioning) with the three operative subsections and the four message-shape blocks.
2. Update §19 worked-example row to populate `Notification-access` column.
3. Add the two-way out-of-scope-v1 paragraph.
4. Self-apply: cnos (operating under cdd already) updates its own `.cdd/OPERATORS` to add the column; cnos's notification channel (if one exists) gets an invite link recorded.
5. Close out; verify Cycle B's Telegram adapter (when it ships) honors the message-shape contract.

## Risks

- **Premature canon.** Message-shape specifics may not survive contact with reality across multiple repos. Mitigation: §11a.4 frames the shapes as *templates*, not requirements; alternate adapters honor the variable set, not the exact prose.
- **Invite-link leak.** `.cdd/OPERATORS` is committed and public-by-default in public repos. Mitigation: §11a.1 explicitly names the link as a *join-credential* (not auth-credential); private channel admin gate means leak = bounded blast radius. Repos in higher-sensitivity domains use Option B (uncommitted `.cdd/ACCESS.md` in `.gitignore`).
- **Operator-removal forgetting.** §11a.3 prescribes two-step removal (registry + channel), but the channel removal step is manual — admin must remember. Mitigation: §11a.3 checklist row; future enhancement could auto-revoke via Telegram API if the bot has admin permission.
- **Scope creep toward two-way.** Once notification is operative, the desire for "operator-acks" in Telegram becomes attractive. Mitigation: AC4 is the firewall — any future proposal must demonstrate the running-service prereqs are acceptable.

## Open questions

Each must be decided by the cycle that lands this. Recommendations follow.

1. **Subsection numbering: §11a or §10.5?** — *Recommendation:* §11a. Sits after §11 (secrets) because operator access is access-management, downstream of secret-management. Lettered subsection (11a) signals "tightly bound to §11" without renumbering.
2. **`.cdd/OPERATORS` storage option for invite links — committed (Option A) vs uncommitted (Option B)?** — *Recommendation:* Option A as default; tenants opt into Option B by adding `.cdd/ACCESS.md` to `.gitignore` and naming it in §19. Reasoning: simplicity and visible operator roster wins for the common case; high-sensitivity tenants opt out explicitly.
3. **Channel-scope: one-channel-per-repo or shared?** — *Recommendation:* one per repo. Cross-repo operators use Telegram folders. Shared channels make filtering operator-side; per-repo lets the bot reuse standard message shapes.
4. **Sample message shape format — Telegram-Markdown, HTML, plain?** — *Recommendation:* plain text in the skill (transport-agnostic); reference adapter (Cycle B) renders to Telegram-Markdown.
5. **Invite-link revocation cadence.** Should the invite link rotate on `removed-cycle` events or stay stable? — *Recommendation:* stay stable; rotation only on suspected leak. Stable links are operator-friendly; channel admin gate keeps blast radius bounded.
6. **Notification of removal.** When an operator's `removed-cycle` is recorded and they're removed from the channel, do they receive a final "you've been removed" message? — *Recommendation:* no — channel removal is silent (Telegram's default). Registry row is the public record; no need to also send a message.
7. **Multi-operator-per-cycle.** If a cycle has α-handle and β-handle distinct, do both receive notifications? — *Recommendation:* both, plus γ/δ if separate. Channel-level notification (not DM); every operator in `.cdd/OPERATORS` with `Notification-access` populated sees everything.
8. **Bot identity in messages.** Should messages be signed "from the cdd-notifier bot" or appear as channel-anonymous posts? — *Recommendation:* channel-anonymous. The bot is plumbing; the channel itself is the namespace. Operators know notifications come from the bot because the channel is dedicated.

## References

- cnos #344 — activation skill (parent; this is a companion subsection)
- cnos #343 — identity convention (operator identity-email referenced by `.cdd/OPERATORS`)
- cnos `cdd/activation/SKILL.md` Cycle A deliverable (pending) — §10, §11, §19
- cnos `cdd/activation/templates/telegram-notifier/` Cycle B deliverable (pending) — reference adapter
- Telegram Bot API — core.telegram.org/bots/api (external)
- Telegram invite links — core.telegram.org/api/invites (external)
