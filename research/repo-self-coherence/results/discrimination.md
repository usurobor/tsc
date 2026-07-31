# Discrimination — does the Repo Newcomer-Coherence CM catch both the old fixes and the new findings?

**CM:** `.cell/cleanup/CM.md` · **Targets:** `650bb13` (PRE-cleanup) → `1c752a8` (current `main`)
**Receipts:** `00-pre-cleanup-650bb13.md`, `01-current-main-1c752a8.md`

---

## 1. Did Axis A/B FAIL on `650bb13` for the exact defects the cleanup later fixed?

**Yes — every one, and each maps to a named CM signal.**

| Cleanup fix | CM signal that caught it | Evidence on `650bb13` |
|---|---|---|
| **F1 — broken headline `coh` command** | A, signal "no claim of conformance/... the tree does not carry" (command form vs. `expand_glob`) | `README.md:46` `--files spec/`; `src/engine/ocaml/bin/main.ml:90-94` treats a no-`*` pattern as a literal path → hands a directory to the engine as a file |
| **F2 — README/STATUS normativity disagreement** | A, signal "0 cross-file contradictions; version/license/status agree across files" | `STATUS.md:5,8,10` assert 4.0.0 Normative ratified; `README.md` names no ratified contract |
| **Parser-plugin fiction** | A, signal "0 fabricated subsystems (a documented thing that does not exist)" | `CONTRIBUTING.md:13,149-171` and `.github/pull_request_template.md:62-74` reference `src/engine/ocaml/lib/parsers/`, `examples/`, `tests/ocaml/` — none exist in `git ls-tree` |
| **The ~42 off-by-one `src/`-move links** | A, signal "0 broken live relative links; every referenced path resolves" | 44 broken live links measured; `src/skills/self-measure/SKILL.md` (~26), `src/skills/cm-of-cms/SKILL.md` (14), `src/engine/ocaml/{README,CONTRACT}.md`, `CHANGELOG.md` |
| **SECURITY.md fiction** | A, "0 fabricated subsystems" + "status agrees" (2.x support line for a 0.12.0 project) | `SECURITY.md:7-11` support table `2.1.x/2.0.x/<2.0` vs `VERSION` = 0.12.0 |
| **CONTRIBUTING license vs LICENSE** | A, signal "license ... agree across files" | `CONTRIBUTING.md:178-184` Apache-2.0/CC-BY/CC0 triad vs `LICENSE` = CC BY 4.0 only |
| **Prose noise** | B, signal "no throat-clearing; one governing question per file; no two-job files" | `CONTRIBUTING.md:3,192`; `STATUS.md:71-73`; `docs/THESIS.md:19`; two-job `CONTRIBUTING.md`/`SECURITY.md` |

Axis **A FAILs** on `650bb13` (broken links **and** fabrication **and** contradiction — any one is sufficient). Axis **B FAILs** (two-job files + duplicated-in-full surface boundary + throat-clearing). The CM would have caught the full set the content cleanup addressed. On `1c752a8` both A and B **PASS** — confirming the fixes closed exactly the signals that fired.

**One caveat on F2:** it is more an *omission-shaped* disagreement (README silent on the ratified 4.0.0 that STATUS asserts) than a flat logical contradiction. The CM's "status agree across files" signal still binds it, and the cleanup's `README.md:68` + `STATUS.md:5` edits are precisely the reconciliation — but a reviewer running the oracle must read it as a status-agreement failure, not a self-contradicting sentence.

## 2. Does the CM FAIL Axis C/D/E on current `main` for the new review findings?

**Yes — all three, each on its explicit FAIL clause.**

| New review finding | CM axis + FAIL clause | Evidence on `1c752a8` |
|---|---|---|
| **α/β/γ authority conflict** | **D** — "FAIL if the portal names the α/β/γ system as governing, or routes into it" | `docs/README.md:5` names `beta/governance/DOCUMENTATION-SYSTEM.md` as governing vs ADR `repository-planes.md:39-40` "never a filing taxonomy"; 4 live links into `docs/alpha`/`docs/beta` (`docs/README.md:5,21-23`) |
| **THESIS not plain** | **C** — "FAIL if the designated intro needs the glossary" | `README.md:5` tells readers to "keep the glossary open"; `docs/THESIS.md:3,15-17` opens on undefined "polar source expressions" and α/β/γ |
| **README not a landing page** | **C** — identity ambiguity + one-screen four-answers | `README.md:7-10` "two surfaces"; nine-row map `README.md:16-26`; no single ranked identity |
| **Half-migration** | **E** — "FAIL if the legacy taxonomy is still present on main, or linkcheck must exclude it" | `docs/{alpha,beta,gamma}` present; `ci.yml:83-85` excludes them; ADR `repository-planes.md:3` "partial migration in progress" |
| (supporting) **missing program indexes** | **D**, signal 6 | `docs/concepts`, `docs/architecture`, `research/ascent` have no index README |
| (supporting) **historical designs as current** | **E**, signal "historical designs labeled/rehomed" | `docs/design/0.5.0/`, root `RELEASE.md` |

C, D, E all **FAIL** on current `main`. The CM does not go quiet on the improved repo — it surfaces exactly the open review findings.

## 3. The delta: which axes improved `650bb13`→`1c752a8`, which did not

| Axis | `650bb13` | `1c752a8` | Moved? |
|---|---|---|---|
| A — Truth | **FAIL** | **PASS** | **Yes** — 44→0 broken live links; parser/SECURITY fiction removed; license reconciled; command fixed; normativity reconciled |
| B — Concision | **FAIL** | **PASS** | **Yes** — throat-clearing cut, two-job files split, no full re-narration of the surface boundary |
| C — Comprehension | **FAIL** | **FAIL** | **No** — `docs/THESIS.md` essentially unchanged (one sentence removed); `README.md:5` now *admits* the glossary dependency |
| D — Navigation | **FAIL** | **FAIL** | **No** — `docs/README.md` is byte-identical; authority conflict, α/β/γ routing, and missing indexes all persist |
| E — Structure | **FAIL** | **FAIL** | **No** — `docs/{alpha,beta,gamma}` still present; linkcheck now *explicitly* excludes them (`ci.yml:83-85`); ADR self-declares partial migration |

**Sharp result:** the content cleanup moved A and B decisively (FAIL→PASS) and left the information-architecture axes (C/D/E) exactly where they were — the migration/portal work was out of scope. The per-axis profile went from `FAIL FAIL FAIL FAIL FAIL` to `PASS PASS FAIL FAIL FAIL`.

**Band-granularity note.** Both commits carry the overall band **POOR** — `650bb13` because Axis A FAILs, `1c752a8` because three axes (C,D,E) FAIL and the CM's POOR clause triggers at ≥3. The top-line band therefore *does not* register the A/B recovery; only the per-axis receipt and the acceptance-criteria list do (criteria 1 and 8 recovered; 2,4,5,6,7,9,10 still fail). This is a real limitation of the CM's coarse worst-axis/≥3 band mapping, not a discrimination failure: at axis and criterion resolution the instrument separates the two commits cleanly.

**Criteria-coverage note.** The ten acceptance criteria are C/D/E-weighted; Axis A is reflected only through criteria 8 and 9, and Axis B is not a standalone criterion at all. So the *criteria* list understates the A/B improvement that the *axes* record — worth carrying if this CM graduates to a mechanical oracle.

---

## Verdict

The CM **discriminates**. On `650bb13` its Axis A/B FAILs catch the full defect set the cleanup fixed — the broken `coh` command, the README/STATUS normativity gap, the parser fiction, the 44 off-by-one links, the SECURITY fiction, the CONTRIBUTING/LICENSE contradiction, and the prose noise — each traceable to a named signal. On `1c752a8` its Axis C/D/E FAILs catch every open review finding — the α/β/γ authority conflict, the non-plain THESIS, the not-quite-landing-page README, and the half-migration. The one blunt edge is the overall band: both land at POOR, so the headline label hides the A/B recovery that the axis- and criterion-level receipts make explicit.
