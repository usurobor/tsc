# cnos PR handoff — cdd supercycle learnings

This bundle contains everything needed to land 6 cdd-skill patches against `usurobor/cnos`. I authored the artifacts but cannot push or open the PR myself (GitHub MCP scope is restricted to `usurobor/tsc`).

The bundle lives on `usurobor/tsc` at `.cdd/iterations/cross-repo/cnos/cdd-supercycle/` (branch: `pr-bundles/cnos-cdd-supercycle`) per the structure introduced by patch 6 of this PR.

## Bundle contents

| File | Purpose |
|---|---|
| `LINEAGE.md` | Per-patch lineage tracing each patch to its source cycle(s) in `usurobor/tsc#23` (Step 5.6b cross-repo trace artifact) |
| `ISSUE.md` | γ issue pack — file as a new cnos issue first |
| `PR-BODY.md` | PR description body — paste as the PR description |
| `0001-…patch` … `0006-…patch` | Six-commit patch series — apply with `git am` |

## Apply sequence

```bash
# 0. Fetch the bundle from tsc.
git clone https://github.com/usurobor/tsc.git tsc-courier
cd tsc-courier
git fetch origin pr-bundles/cnos-cdd-supercycle
git checkout origin/pr-bundles/cnos-cdd-supercycle -- .cdd/iterations/cross-repo/cnos/cdd-supercycle
cp -r .cdd/iterations/cross-repo/cnos/cdd-supercycle /tmp/cdd-supercycle-pr
cd ..

# 1. File the issue on cnos. Get its number — call it N.
gh issue create \
  --repo usurobor/cnos \
  --title "cdd: Incorporate supercycle learnings — honest-claim review, MCA preconditions, docs-only disconnect, round metrics, honest-grading rubric, cdd-iteration self-iteration home" \
  --body-file /tmp/cdd-supercycle-pr/ISSUE.md \
  --label docs

# 2. Clone cnos and create the cycle branch (γ algorithm).
git clone https://github.com/usurobor/cnos.git
cd cnos
git switch -c "cycle/${N}-cdd-supercycle-learnings"

# 3. Apply the six patches.
git am /tmp/cdd-supercycle-pr/000{1,2,3,4,5,6}-*.patch

# 4. Verify the diff.
git log --oneline origin/main..HEAD
git diff --stat origin/main..HEAD
# Expected: 6 commits, 6 files changed, +202/−11.

# 5. Update LINEAGE.md with the cnos issue number once filed
#    (LINEAGE.md ships with TBD placeholders for cnos issue + PR numbers).

# 6. Push and open the PR.
git push -u origin "cycle/${N}-cdd-supercycle-learnings"
sed -i "s/Closes #N/Closes #${N}/" /tmp/cdd-supercycle-pr/PR-BODY.md
gh pr create \
  --repo usurobor/cnos \
  --base main \
  --head "cycle/${N}-cdd-supercycle-learnings" \
  --title "cdd: Incorporate supercycle learnings (6 patches) — Closes #${N}" \
  --body-file /tmp/cdd-supercycle-pr/PR-BODY.md

# 7. Update tsc:.cdd/iterations/cross-repo/cnos/cdd-supercycle/LINEAGE.md
#    with the cnos PR number. Commit and push to pr-bundles branch.
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

## Disconnect (recursive — uses the §2.5b + Step 5.6b protocols this PR introduces)

Mode: docs-only per §2.5b. The cycle's `cdd-iteration.md` is itself required (this very PR ships findings tagged `cdd-skill-gap`/`cdd-protocol-gap`/`cdd-metric-gap`).

After merge, γ:

```bash
ISO_DATE="$(date -u +%Y-%m-%d)"

# 1. Per §2.5b: move cycle dir to date-keyed releases dir
mkdir -p ".cdd/releases/docs/${ISO_DATE}"
mv ".cdd/unreleased/${N}" ".cdd/releases/docs/${ISO_DATE}/"

# 2. Per Step 5.6b: cdd-iteration.md is already written in the cycle dir
#    (it shipped as part of α/γ work for this cycle). Verify it's there.
test -f ".cdd/releases/docs/${ISO_DATE}/${N}/cdd-iteration.md" || echo "MISSING"

# 3. Per Step 5.6b: update the aggregator
cat >> .cdd/iterations/INDEX.md <<EOF
| ${N} | #${N} | ${ISO_DATE} | 6 | 6 | 0 | 0 | .cdd/releases/docs/${ISO_DATE}/${N}/cdd-iteration.md |
EOF

# 4. Per §2.5b: write the docs-only PRA
mkdir -p "docs/gamma/cdd/docs/${ISO_DATE}"
# (γ authors POST-RELEASE-ASSESSMENT.md per post-release/SKILL.md template)

# 5. Commit the disconnect
git add .cdd/ docs/gamma/cdd/docs/${ISO_DATE}/
git commit -m "closeout(${N}): γ — docs-only disconnect; cdd-iteration aggregated"
git push origin main
```

No tag. No version bump. The merge commit is the disconnect signal.

## Cleanup of cross-repo trace (after cnos PR merges)

Once the cnos PR merges, the cross-repo trace at `tsc:.cdd/iterations/cross-repo/cnos/cdd-supercycle/` may be deleted (its lineage is preserved in cnos's own `cdd-iteration.md`). Per Step 5.6b: "γ may delete it thereafter."

```bash
# In tsc:
git rm -r .cdd/iterations/cross-repo/cnos/cdd-supercycle/
git commit -m "cleanup: cross-repo trace fulfilled — cnos PR merged at <SHA>"
git push origin main
git push origin --delete pr-bundles/cnos-cdd-supercycle  # courier branch dead
```
