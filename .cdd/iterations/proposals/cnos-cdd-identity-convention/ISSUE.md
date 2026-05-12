# cdd: Canonical git identity convention for cdd role actors (`{role}@{project}.cdd.cnos`)

**Labels:** `docs, P3, cdd`
**Priority:** P3 — convention cosmetic, but inverts namespace hierarchy as currently written; touches every commit trailer across every cdd-using repo, so worth converging once.
**Status:** Drafted; ready for cycle dispatch.
**Mode:** `design-and-build` — design lives in this issue body; patch lands in whichever skill file presently prescribes the identity format (likely `cdd/operator/SKILL.md` and/or `cdd/CDD.md`), plus a migration note in `cdd/post-release/SKILL.md`.
**Depends on:** none.

## Problem

**What exists:** Cnos cycle commits use git identities of the form `{role}@cdd.{project}` — e.g., `Alpha <alpha@cdd.cnos>`, `Beta <beta@cdd.cnos>`, observed on cnos cycle #335 R1 fix-round commits. The `cdd/review/SKILL.md` doctrine (cycle #287) prescribes `beta@cdd.{project}` in the same shape. The convention treats `{project}` as the rightmost (TLD-equivalent) namespace and `cdd` as a subdomain inside it.

**What is expected:** Email domains in DNS read broad-to-narrow from right to left. The rightmost label is the broadest namespace. For cdd-protocol identities, the broadest scope is the **cnos meta-repo** (where the protocol is defined and shipped), with `cdd` as the protocol-namespace inside cnos, and the project as the tenant of that protocol. The role is the leaf (local part). The DNS-conformant form is therefore:

```
{role}@{project}.cdd.cnos
```

Examples:

- `alpha@tsc.cdd.cnos`
- `beta@cnos.cdd.cnos` *(or special-case `beta@cdd.cnos` — see §Open question 1)*
- `gamma@tsc.cdd.cnos`

**Where they diverge:** The current form `gamma@cdd.tsc` implies cdd is a sub-namespace of tsc, but in practice tsc is one of many tenants of the cdd protocol, which itself lives inside cnos. The hierarchy is inverted. The two-level alternative `gamma@tsc.cdd` corrects the inversion but omits the cnos parent — leaving the protocol unattributed to its origin repo and giving no room for future sibling protocols (cnav, cnobs, etc., hypothetically) hosted in cnos.

## Impact

- **Trailer attribution misreads.** A reader scanning `git log` sees `@cdd.tsc` and reasonably parses it as "cdd is the tsc project's own subsystem." It is not — cdd is a cross-repo protocol with one canonical source (cnos). The trailer should say so.
- **Provenance is implicit.** With the current form there is no commit-level evidence linking a tsc cycle's identities to the cnos repo that defines the protocol. A grep across all repos for `*.cdd.cnos` would otherwise enumerate every cdd cycle ever run.
- **Scaling.** If cnos grows to host sibling protocols, the current form has no room — `gamma@cdd.tsc` cannot disambiguate "gamma of which cnos protocol?" The three-level form does: `gamma@tsc.cdd.cnos` vs `gamma@tsc.cnav.cnos`.
- **Recursive coherence.** cdd self-describes via cycles. The identity used to sign those cycles should match the convention cdd would itself recommend if asked the abstract question "where does this actor live in the namespace hierarchy?"

## Status truth

| Surface | Status | Notes |
|---|---|---|
| Identity convention `{role}@cdd.{project}` (two-level, inverted) | Shipped (de facto) | cnos cycle #287 doctrine; cnos #335 commit trailers |
| Identity convention `{role}@{project}.cdd` (two-level, DNS-correct) | NOT NAMED | Considered; rejected here in favor of three-level |
| Identity convention `{role}@{project}.cdd.cnos` (three-level) | NOT NAMED | This proposal |
| Migration path for in-flight cycles | NOT NAMED | This proposal §Migration |
| Special-case for cnos itself (project == origin) | NOT NAMED | This proposal §Open question 1 |

## Source of truth

| Claim / surface | Canonical source | Status |
|---|---|---|
| Current identity convention `{role}@cdd.{project}` | `cdd/review/SKILL.md` (cycle #287 doctrine) + `cdd/operator/SKILL.md` if it prescribes identity | Shipped |
| Empirical evidence — current form in use | cnos cycle #335 R1 fix-round commits (`Alpha <alpha@cdd.cnos>`); cnos PR #332 patches | Shipped |
| DNS hierarchy convention (broad-to-narrow right-to-left) | RFC 1034 / RFC 5321 | External, normative |
| cnos as canonical home for cdd | `usurobor/cnos` repo root + `cdd/CDD.md` | Shipped |
| Protocol-vs-tenant relationship | `cdd/CDD.md` cross-repo trace bundle prescription (`.cdd/iterations/cross-repo/{target}/...`) | Shipped |

## Cycle scope sizing (per cnos §1.6c heuristic)

| Factor | Reading | Splitting signal? |
|---|---|---|
| (a) New code surface | 0 — prose changes to 1–2 skill files + 1 post-release note | no |
| (b) Cross-module breadth | 1–2 cnos files + tsc/.cdd/post-release migration note | low |
| (c) Lifecycle span | docs-only | no |
| (d) MCA preconditions | not MCA — design fixed in body | n/a |
| (e) Independent shippability | one cohesive switch; partial conversion would leave the trailer namespace inconsistent | no |

**Decision:** keep whole. 5 ACs, mid-typical band.

## Scope

**In scope:**

1. Locate every cnos cdd file that prescribes or exemplifies the identity format and replace with `{role}@{project}.cdd.cnos`. Known sites:
   - `cdd/review/SKILL.md` (cycle #287 doctrine) — primary
   - `cdd/operator/SKILL.md` §1.2 (`claude -p` setup) if it sets `user.email`
   - Any alpha/beta/gamma SKILL.md that shows a worked example
2. Add a short rationale block to whichever file becomes the canonical home for the convention — DNS hierarchy + cnos-as-origin reasoning, three lines max.
3. Add `cdd/post-release/SKILL.md` §X "Identity migration" — one paragraph: in-flight cycles keep their existing trailers (history is immutable); new commits from the patch-merge cycle onward use the new form; close-out artifacts may reference both forms transparently during the transition window.
4. Add a worked example table for the most common projects (`alpha@tsc.cdd.cnos`, `beta@cnos.cdd.cnos`, `gamma@<future>.cdd.cnos`).
5. Resolve the special-case for cnos-itself cycles (§Open question 1).

**Out of scope:**

- Rewriting historical commit trailers. Git history is the audit log; convention churn does not warrant rewrites.
- Renaming branches (`cycle/{N}`) or any other non-trailer artifact.
- Cross-repo identity authentication / GPG signing keys.

## Acceptance Criteria

**AC1 — Three-level identity convention named.** One cdd file (likely `cdd/operator/SKILL.md` or `cdd/CDD.md`) contains a "Git identity for role actors" section that prescribes `{role}@{project}.cdd.cnos`. Rationale block: 2–4 sentences citing DNS hierarchy + cnos-as-protocol-origin.

- *Invariant:* every prescriptive site uses the same form (no `@cdd.{project}` survivors prescribed, only quoted in migration notes).
- *Oracle:* `rg '@cdd\.' cdd/` returns only matches inside migration / history blocks or commented examples.
- *Positive:* `rg '\.cdd\.cnos' cdd/` returns the new prescription site(s).
- *Negative:* `rg 'beta@cdd\.\{project\}' cdd/review/SKILL.md` returns nothing (old doctrine replaced).
- *Surface:* the affected cnos file(s) under `cdd/`.

**AC2 — Special case for cnos resolved.** §Open question 1 closed: either `{role}@cnos.cdd.cnos` (literal application) or `{role}@cdd.cnos` (project-equals-origin elision) is named as canonical. Rationale recorded.

- *Invariant:* one form chosen, not both ambiguously.
- *Oracle:* a worked example in the prescription site shows the cnos-side identity explicitly.
- *Positive:* an in-cycle commit on the patch-landing cycle uses the chosen form.
- *Negative:* no fallback to "either is fine."
- *Surface:* same file as AC1.

**AC3 — Worked example table present.** A small table (3–5 rows) shows role × project pairings: `alpha@tsc.cdd.cnos`, `beta@cnos.cdd.cnos` (or whatever AC2 chose), `gamma@<hypothetical-other-project>.cdd.cnos`, plus the prior form alongside for one row marked "deprecated."

- *Invariant:* the table is the single source of truth for the identity format examples.
- *Oracle:* table is reachable from `cdd/CDD.md` table-of-contents or skill-bundle index.
- *Positive:* table rows render in valid markdown.
- *Negative:* no contradictory examples elsewhere in `cdd/`.
- *Surface:* same file as AC1.

**AC4 — Migration paragraph in post-release.** `cdd/post-release/SKILL.md` gains a short identity-migration note: history immutable, forward-only convention switch, transition-window tolerance.

- *Invariant:* paragraph names the cnos cycle # that is the cutover and the date.
- *Oracle:* `cdd/post-release/SKILL.md` contains a "Migration" or "Identity migration" subsection.
- *Positive:* paragraph is ≤80 words.
- *Negative:* no expectation of rewriting historical commits.
- *Surface:* `cdd/post-release/SKILL.md`.

**AC5 — Patch-landing cycle uses new form.** The cnos cycle that lands this patch uses `{role}@{project}.cdd.cnos` in its own commit trailers (α R1, β R1, γ-closeout merge). Self-application verifies the convention is operable.

- *Invariant:* every commit on the patch-landing branch in the cycle's hand uses the new form.
- *Oracle:* `git log --format='%ae' cycle/{N}` on the patch branch shows only `*@cnos.cdd.cnos` (or `@cdd.cnos` per AC2).
- *Positive:* close-out cdd-iteration finding records this as "self-consistency demonstrated."
- *Negative:* no commit in the cycle's hand uses the old `@cdd.cnos` form (unless AC2 elision chose that).
- *Surface:* git log of the patch-landing cycle.

## Proof plan

1. Author the §"Git identity for role actors" prescription block with the three-level form, rationale, and worked example table.
2. Replace the cycle #287 doctrine in `cdd/review/SKILL.md` with a cross-reference to the new canonical site.
3. Add the post-release migration paragraph.
4. Set patch-landing cycle's local git identities to the new form before α R1; commit; observe trailer; advance.
5. Close out with cdd-iteration F-finding noting the self-application as evidence the convention is operable.

## Risks

- **Bikeshed.** The convention is cosmetic; lengthy debate is the failure mode. Mitigation: this issue is the bikeshed — once merged, the form is settled.
- **Tooling assumptions.** Some downstream tool may parse `@cdd.{project}` to extract the project name. Mitigation: grep cnos + tsc for any code that parses identity emails; if found, update parser as part of the patch. Most likely zero hits — trailers are advisory, not load-bearing.
- **In-flight cycles split-trailer.** A long-running cycle that started under the old form will end up with mixed trailers if it spans the cutover. Mitigation: post-release migration note explicitly permits the transition window; close-out artifacts may show both.

## Open questions

1. **Cnos self-identity.** Three candidate forms for cnos-side actors:
   - `{role}@cnos.cdd.cnos` — literal application; `cnos` appears twice
   - `{role}@cdd.cnos` — project-equals-origin elision; reads as "the cdd protocol at cnos"
   - `{role}@cnos.cdd` — drops the origin-parent for the special case where project is origin
   
   **Recommendation:** the elision form `{role}@cdd.cnos`. It already matches existing cnos commit trailers (cycle #335 etc.), minimizing migration cost on the cnos side, and reads cleanly. The literal three-level form `cnos.cdd.cnos` is ugly and the redundancy adds no information.

2. **Hypothetical sibling protocols under cnos.** If cnos one day hosts a second protocol (cnav, cnobs, etc.), is the three-level form the right scaffold? **Tentative yes** — `gamma@tsc.cnav.cnos` reads exactly like `gamma@tsc.cdd.cnos`, and the disambiguation is precisely the benefit. The two-level form `gamma@tsc.cdd` could not express this without further extension.

3. **Local part separators.** Roles are single tokens (`alpha`, `beta`, `gamma`, `delta` / `sigma`). If a future role compound is needed (e.g., `alpha-fix-r2`?), should it be `alpha+fix-r2@...` or stay flat? Out of scope here; flat is fine for now.

## References

- cnos `cdd/review/SKILL.md` cycle #287 doctrine — current `beta@cdd.{project}` prescription site
- cnos cycle #335 R1 fix-round commits — empirical current form
- RFC 1034 §3.1 — domain name hierarchy
- tsc `.cdd/iterations/proposals/cnos-cdd-claude-code-dispatch/ISSUE.md` — sibling proposal in same proposal set
