# 05 — β convergence check

Independent β, `cleanup` domain. Instruments: cnos write skill (L7) + filesystem
resolution. No repo file edited. This round proves full coverage: every live `.md`
file enumerated and audited, not sampled.

## 1. Verdict

**GO — pristine.** Round 04's three fixes held with no regression. A full sweep of
all 64 live surfaces found no removable noise, no false present-tense claim, and no
dead or stale reference. Every markdown link resolves; every version literal is
either the live `0.12.0` / `4.1.0` / `4.0.0` anchor or a frozen historical record
correct for its genre.

## 2. Coverage — 64 live `.md` files audited

Enumerated from `git ls-files '*.md'`, excluding `.cdd/`, `.cn-sigma/`, `.cell/`,
`heldout/`, `.git/`, `.tsc/`, `_build/`, `.claude/`, frozen `docs/alpha|beta|gamma/`,
and `katas/*/input/**`.

Mechanical full-file sweeps (all 64): markdown link resolution (0 broken); stray
version-literal scan; `python`/`parser`/`reference implementation` fiction scan;
`TODO`/`FIXME`/placeholder/template-artifact scan; throat-clearing/filler scan. All
clean except three benign hits classified in §4.

Files:

Root — `README.md`, `STATUS.md`, `ARCHITECTURE.md`, `QUICKSTART.md`,
`CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CHANGELOG.md`,
`RELEASE.md`, `.github/pull_request_template.md`.

`spec/` — `README.md`, `c-equiv.md`, `tsc-core.md`, `tsc-oper.md`,
`tsc-observation-dynamics.md`, `tsc-conformance.md`, `tsc-glossary.md`.

`conformance/` — `README.md`, `foundation-v4/README.md`, `game-of-life/README.md`,
`polar-realization-v4.1/README.md`, `polar-syntax-v4.1/README.md`,
`stochastic-law/README.md`.

`src/` — `engine/ocaml/README.md`, `engine/ocaml/CONTRACT.md`, `skills/README.md`,
`skills/self-measure/SKILL.md`, `skills/cm-of-cms/SKILL.md`.

`docs/` — `README.md`, `THESIS.md`, `architecture/decisions/repository-planes.md`,
`concepts/illustrations/README.md`, `concepts/illustrations/philosophical/README.md`,
`concepts/illustrations/philosophical/consciousness.md`, `.../emergence.md`,
`.../free-will.md`, `design/0.5.0/DESIGN.md`, `design/0.5.0/PLAN.md`,
`design/foundation-contract-reconciliation/{ARCHAEOLOGY,CUTOVER-RECEIPT,DESIGN,ROUND2-REVIEW-RESPONSE,ROUND3-REVIEW-RESPONSE,ROUND4-REVIEW-RESPONSE}.md`,
`design/polar-expression-recovery/DESIGN.md`.

`katas/` — `README.md`, `01-glider/README.md`, `02-random-soup/README.md`,
`03-comparative/README.md`, `04-philosophical/README.md`, `05-adversarial/README.md`.

`research/` — `README.md`, `ascent/DECISIONS.md`,
`ascent/traces/{000-hello-world,001-machine-human-turing,002-hard-soft-flickering}.md`.

Other — `runtime/SELF-MEASURE.md`, `schemas/README.md`, `targets/README.md`,
`schemas/fixtures/skill-frontmatter/{valid/basic,invalid/bad-signal,invalid/estimate-not-in-contract,invalid/missing-scope}/SKILL.md`
and `.../estimate-not-in-contract/instruction.md` (frontmatter-validator negative-control
fixtures — test data, not audited for prose, per the kata-input exclusion class).

## 3. Round-04 verification — held

- `SECURITY.md` — truthful and consistent. Single security contact `peter@lisovin.com`
  matches `CONTRIBUTING.md:142`; pre-1.0 support statement; OCaml engine with
  `mechanical` (no network) vs `llm`/`hybrid` (outbound HTTPS) scope. The fabricated
  `2.0.x`/`2.1.x` support table, the Python/custom-parser threat model, and the
  divergent `usurobor@gmail.com` contact are gone. No regression.
- `.github/pull_request_template.md:47` — now a generic `Describe any manual testing
  performed` comment; the `especially for new parsers` residual and the `For New
  Parsers` checklist are both gone.
- `CONTRIBUTING.md:110-114` — commit examples are real (`feat: add stochastic-law
  conformance fixture`, `fix: correct mechanical scoring aggregation`); the
  data-format-parser examples are gone.
- License alignment — `CONTRIBUTING.md:146` `CC BY 4.0` matches `LICENSE`
  (`Creative Commons Attribution 4.0 International`) and `README.md:94`.
- Rounds 02–03 cuts and link fixes remain absent/correct: `ARCHITECTURE.md:3` is the
  single-job sentence; `THESIS.md:19` is the positive claim; 0 broken relative links
  across all 64 files.

## 4. Clean surfaces (honest credit)

- **Link graph** — 64 live files, 0 broken relative links. Non-link path tokens
  checked separately resolve: `install.sh`, `CITATION.cff`, `VERSION` (`0.12.0`),
  `.tsc/COHERENCE.md`, `scripts/{run-katas,render-self-measure,validate-release-gate,
  verify-skill-bundle}.sh`, `scripts/ci/*.sh`, `conformance/registry.toml`, and the
  `RELEASE.md` basenames `factorized-beta-controls.json` /
  `METER-LOOP-DECISION.md` (real under `docs/beta/governance/`).
- **Version anchors** — `README.md`, `STATUS.md`, `ARCHITECTURE.md`, `QUICKSTART.md`,
  `THESIS.md`, `RELEASE.md` agree: software `0.12.0`, spec `4.1.0` Draft, last ratified
  `4.0.0` Normative, engine v3.2-era. No stray literal on a live surface.
- **Governance files** — `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`,
  `.github/pull_request_template.md` are template-genre but truthful to this OCaml,
  pre-1.0 repo: OCaml 5.1+/opam/dune support matrix, `dune build|runtest|fmt` commands,
  conduct enforcement routed to its own contact channel.
- **Conformance READMEs** — `conformance/README.md` and all five fixture READMEs state
  `specified` status with "no conformance result" / "carries no standing until
  verified", consistent with `STATUS.md:6` `4.1 conformance standing: none`. The
  `parser` uses are the legitimate C≡ polar parser, not the excised plugin fiction.
- **Illustrations** — `consciousness.md`, `emergence.md`, `free-will.md` and their two
  index READMEs carry the `non-normative illustration` banner; `consciousness.md`'s
  `2.1.1` / `spec v2.0.0` literals sit inside a file titled "Historical v2 illustration"
  — frozen record, correct for genre.
- **Research** — `research/README.md` frames `KERNEL.md` and `conformance/ascent/` as
  future; `traces/000-hello-world.md`'s `Python 3 (pinned)` names the hello-world
  *program under analysis*, not the engine.
- **Routing/definition** — `docs/README.md`, `schemas/README.md`, `targets/README.md`
  are tight, single-job, no restatement. `runtime/SELF-MEASURE.md` is a CI-enforced
  byte-identical render of `src/skills/self-measure/SKILL.md`; its embedded v3.2.x
  experiment records are frozen.

## 5. Findings

None.

## 6. Out of scope

- `CODE_OF_CONDUCT.md` defines only `## Enforcement` and `## Appeals`; it carries no
  H1 title and no conduct-standards/pledge body, while `CONTRIBUTING.md:18` cites it as
  governing participation. This is missing content, not noise or a false claim — supplying
  the standards body is a content decision (α must supply if wanted), not a cleaning cut.
- `conformance/README.md:36-37` names fixture IDs `polar-syntax-v4-1` /
  `polar-realization-v4-1` (hyphenated) against directories `polar-syntax-v4.1` /
  `polar-realization-v4.1` (dotted). These are schema/registry-validated IDs, not links,
  and resolve through `registry.toml`; reconciling ID-vs-path style is a naming decision,
  not a dead reference.
