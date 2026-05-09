# cnos PR handoff — cdd supercycle learnings

This bundle contains everything needed to land 5 cdd-skill patches against `usurobor/cnos`. I authored the artifacts but cannot push or open the PR myself (GitHub MCP scope is restricted to `usurobor/tsc`).

## Bundle contents

| File | Purpose |
|---|---|
| `ISSUE.md` | γ issue pack — file as a new cnos issue first |
| `PR-BODY.md` | PR description body — paste as the PR description |
| `0001-…patch` … `0005-…patch` | Five-commit patch series — apply with `git am` |

## Apply sequence

```bash
# 1. File the issue on cnos. Get its number — call it N.
gh issue create \
  --repo usurobor/cnos \
  --title "cdd: Incorporate supercycle learnings — honest-claim review, MCA preconditions, docs-only disconnect, round metrics, honest-grading rubric" \
  --body-file /tmp/cdd-supercycle-pr/ISSUE.md \
  --label docs

# 2. Clone cnos and create the cycle branch (γ algorithm).
git clone https://github.com/usurobor/cnos.git
cd cnos
git switch -c "cycle/${N}-cdd-supercycle-learnings"

# 3. Apply the five patches.
git am /tmp/cdd-supercycle-pr/000{1,2,3,4,5}-*.patch

# 4. Verify the diff.
git log --oneline origin/main..HEAD
git diff --stat origin/main..HEAD
# Expected: 5 commits, 4 files changed, +144/−11.

# 5. Push and open the PR.
git push -u origin "cycle/${N}-cdd-supercycle-learnings"
sed -i "s/Closes #N/Closes #${N}/" /tmp/cdd-supercycle-pr/PR-BODY.md
gh pr create \
  --repo usurobor/cnos \
  --base main \
  --head "cycle/${N}-cdd-supercycle-learnings" \
  --title "cdd: Incorporate supercycle learnings (5 patches) — Closes #${N}" \
  --body-file /tmp/cdd-supercycle-pr/PR-BODY.md
```

## What β should check on review

This PR is recursive — its own rule 3.13 applies to its own diff. β should verify:

- **3.13(a) reproducibility:** every measurement in `PR-BODY.md` traces to a cycle in `usurobor/tsc#23` close-outs. Spot-check the 1→2→3→1→2 round trace against `.cdd/releases/{0.5.0,0.6.0,0.7.0}/` and `.cdd/unreleased/{27,29}/` on `usurobor/tsc:main`.
- **3.13(b) source-of-truth alignment:** every cnos term used in the PR (MCA, ledger row, §2.5a, finding taxonomy) traces to the canonical SKILL.md it claims to patch. Grep-verify section numbers exist before this PR (e.g. confirm 3.12 exists and 3.13 is the next free).
- **3.13(c) wiring claims:** every "added X to file Y" claim grep-verifies in the diff. The Rounds column claim in particular needs to be present in BOTH `release/SKILL.md` §2.4 AND `post-release/SKILL.md` Step 2 — that's a cross-file consistency check the patch explicitly calls out.

## Coordination with `usurobor/cnos#330`

`usurobor/cnos#330` queues earlier upstream patches from cycle 27's γ-closeout (alpha §2.6 placeholder validation, operator stream-json default, release no-tag dir-move). The third overlaps with this PR's Patch 3 (§2.5b).

Recommended order:
1. Merge this PR first (the §2.5b treatment here is more developed).
2. In #330, drop the no-tag dir-move patch; keep the alpha placeholder + operator stream-json patches.
3. Land #330 second.

If the order needs to flip (e.g. #330 already has reviewer attention), this PR's Patch 3 may need a rebase.

## What this bundle does NOT contain

- Frontmatter changes to any SKILL.md (intentional).
- Kata updates exercising the new rules (deferred, follow-on issue).
- Two-agent (δ=γ) configuration sanction (out of scope; separate cnos design issue).
- Branch-hygiene authority decision (out of scope).
- Spec changes outside `src/packages/cnos.cdd/`.

## Disconnect (recursive — uses the §2.5b protocol this PR introduces)

Mode: docs-only per the §2.5b being added in this PR.

After merge, γ moves the cycle directory:

```bash
ISO_DATE="$(date -u +%Y-%m-%d)"
mkdir -p ".cdd/releases/docs/${ISO_DATE}"
mv ".cdd/unreleased/${N}" ".cdd/releases/docs/${ISO_DATE}/"
git add .cdd/
git commit -m "closeout(${N}): γ — docs-only disconnect"
git push origin main
```

γ writes `docs/gamma/cdd/docs/${ISO_DATE}/POST-RELEASE-ASSESSMENT.md` per the new §2.5b protocol. No tag. No version bump. The merge commit is the disconnect signal.
