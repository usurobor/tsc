# 04 — β convergence check

Independent β, `cleanup` domain. Instruments: cnos write skill (L7) + filesystem
resolution. No repo file edited. Rounds 02–03 remediations verified against the
tree at `422d8c2`, then a full residual sweep of every live prose surface.

## 1. Verdict

**REVISE.** Rounds 02 and 03 held with no regression, but the round-03
parser-fiction sweep was not repo-wide as the α-log claimed. `SECURITY.md` was
never audited and carries the same fabricated-parser defect class plus a stale
version table and a divergent security contact; `.github/pull_request_template.md`
retains one parser-fiction residual the round-03 edit missed. The repo is not yet
pristine.

## 2. Rounds 02–03 verification — held

- **12 prose cuts (round 02):** all absent from the tree — `two different surfaces`,
  `not three independent views`, `Thank you for contributing`, the decorative
  STATUS closer, and the rest. `ARCHITECTURE.md:3` is the single-job sentence.
  No regression.
- **42 link fixes (round 03):** re-resolved every relative markdown link on all 64
  live surfaces — **0 broken**. Spot-checked 13 of the repointed links in
  `src/skills/self-measure/SKILL.md` and `src/skills/cm-of-cms/SKILL.md`; each
  `../../../` prefix lands on the intended target (`schemas/skill.cue`,
  `targets/registry.tsc`, `src/engine/ocaml/lib/*.ml`, `scripts/*`,
  `katas/README.md`), not a coincidental other file. No over-correction introduced
  a new dead link. Frontmatter path values left untouched, as claimed.
- **Parser-fabrication removal:** the `Adding a New Parser` section and its TOC
  entry are gone from `CONTRIBUTING.md`; the `For New Parsers` checklist is gone
  from `.github/pull_request_template.md`. (One residual survives — see R2.)
- **License alignment:** `CONTRIBUTING.md:146` now reads `CC BY 4.0` against
  `LICENSE`, which is `Creative Commons Attribution 4.0 International`. The
  fabricated Apache/CC0 three-way split is gone. Held.
- **2 repointed refs:** `CHANGELOG.md:110` ledger preamble now `src/engine/ocaml/CONTRACT.md`;
  `katas/04-philosophical/README.md:26` now `docs/concepts/illustrations/philosophical/consciousness.md`.
  Both resolve. Held.
- **1 residual duplicate:** `Check existing issues first` cut from `CONTRIBUTING.md`;
  no restatement remains.

No round-03 edit introduced new noise or a new dead reference.

## 3. Residual findings

### R1 — `SECURITY.md` is fabricated OSS boilerplate against a repo that does not match it

This file was outside rounds 02–03 and was never audited. It fails on three counts.

- `SECURITY.md:7-11` · the Supported Versions table lists `2.1.x`, `2.0.x`, `< 2.0`
  · no 2.x exists anywhere — `VERSION` is `0.12.0`, the spec is `4.0.0` Normative /
  `4.1.0` Draft (`STATUS.md:3-6`) · stale/false reference · replace with the real
  version surface (α content).
- `SECURITY.md:60,62,66-68,77` · `TSC parsers are Python functions`,
  `Custom parsers execute arbitrary Python`, `Review parser code`, `Parser Execution`,
  `reference implementation` · the engine is OCaml (`src/engine/ocaml/lib/*.ml`);
  no Python engine exists (the only `.py` files are `scripts/cm-attackers/*`), no
  `reference/` or `archive/` dir, and no parser-plugin subsystem — the same fiction
  round 03 excised from `CONTRIBUTING.md` · false content · remove the Python /
  custom-parser threat model; α supplies the real threat surface if one is warranted.
- `SECURITY.md:19` vs `CONTRIBUTING.md:142` · security reports routed to
  `usurobor@gmail.com` in one file and `peter@lisovin.com` in the other, both under
  `[SECURITY]` · duplicated stable fact with conflicting values (skill 3.3) · give
  the security contact one home and one value.

### R2 — `.github/pull_request_template.md:47` · parser-fiction residual

`<!-- Describe any manual testing, especially for new parsers -->` still points to
the `new parsers` contribution model that round 03 removed as fabricated. The
round-03 edit cut the `For New Parsers` checklist from this same file but left this
comment. Cut `, especially for new parsers`.

### R3 — `CONTRIBUTING.md:110` · headline example echoes the removed model

The Conventional-Commits block leads with `feat: add time-series parser` (and
`:113` `test: add conformance test for audio data`) — the data-format-parser model
that no longer exists. These are format illustrations, not path claims, so the harm
is mild, but the flagship example contradicts the real welcome list (`:45`
conformance fixtures). Swap for a real example, e.g. `feat: add conformance fixture`.

## 4. Clean surfaces (honest credit)

- **Link graph** — 64 live markdown files, 0 broken relative links; every
  path-like backtick token on a live surface either resolves or is a glob/brace
  pattern over a real tree (`targets/*.tsc`, `src/skills/**/SKILL.md`,
  `schemas/fixtures/skill-frontmatter/{valid,invalid}/` all backed by real dirs).
- `README.md`, `STATUS.md`, `ARCHITECTURE.md`, `QUICKSTART.md`, `docs/THESIS.md` —
  round-02 cuts intact, version anchors consistent (`0.12.0` / `4.0.0` / `4.1.0`),
  single governing question each.
- `CONTRIBUTING.md` body (setup, standards, submitting) — post-fix prose is tight;
  license line correct; only R1's email divergence and R3's example remain.
- `src/engine/ocaml/README.md` and `CONTRACT.md`, `src/skills/*/SKILL.md` — terse,
  positive claims, links now correct.
- Spec/conformance `parser` uses (`spec/c-equiv.md:127`, `spec/tsc-conformance.md:554`,
  `conformance/README.md:36`, `conformance/polar-syntax-v4.1/README.md:5`) are the
  legitimate C≡ polar-syntax / fixture sense, not the plugin fiction.
- `CHANGELOG.md` dated entries citing `engine/…` and `examples/…` — frozen release
  history, correct at authoring time; only the standing ledger preamble was
  repointed. Left as record genre.

## 5. Out of scope

- **SECURITY.md replacement content.** Removing the false version table and
  Python-parser threat model is cleaning (in scope, R1) — the same call round 03
  made for the `CONTRIBUTING.md` fiction. Choosing the *correct* supported-version
  values and the *real* threat surface is a content-truth decision α must supply;
  no behavior, logic, or spec change is implied.
- **CI linkcheck depth gap.** The α-log already flagged that lychee's glob never
  reached the deeply-nested skill markdown, so the `src/` move landed green with
  the off-by-one drift latent. That is a CI-coverage engineering item, not a
  cleaning defect. Noting the parallel: R1 shows linkcheck also cannot catch
  false *prose* claims that carry no link (the Python-parser threat model), so a
  green linkcheck is not evidence of a pristine contributor surface.
