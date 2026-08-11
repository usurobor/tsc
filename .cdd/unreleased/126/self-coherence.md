# self-coherence — cycle/126

## Gap

**Issue:** usurobor/tsc#126 — *coh-min: execute example.readme-present end to end
(M2/M3 standalone runtime tracer).*

Today no TSC path *executes* an ordinary CM — the surface compiler emits IR and
CUE validates it, but nothing runs the providers a `.cm` names; the Ascent-0
runtime executes the *hard* case only. This cycle builds the smallest thing that
runs an **ordinary** CM end to end: one CM (`example.readme-present`), one real
provider (`file.exists`), harvesting the link/execute/emit skeleton and vendoring
the JSON + SHA-256 libraries from Ascent-0.

**Mode:** identity-rotation authoring step on branch `cycle/126`; from-scratch
authoring under the δ-pinned implementation contract. Not merged; `main`
untouched. Implementation SHA: `07a46d8` (the readiness-signal commit follows).

## Skills

- **Tier 1 (role):** `.cdd/skills/cdd/alpha/SKILL.md` (α discipline: artifact
  order, peer/harness enumeration, pre-review gate, implementation-contract as a
  binding pin α must not relax).
- **Tier 2/3 (engineering):** `eng/ocaml` (types-first, purity boundary, Result
  over exceptions, no silent fallback, determinism), `eng/write-functional`
  (pure core / effects at edges, immutable executor, `let*` bind),
  `eng/code` (errors carry context; validate before acting; clean all exits),
  `eng/test` (start from invariants; negative space mandatory; match proof depth
  to claim), `eng/ux-cli` (colour+symbol semantics, NO_COLOR).

Skills applied as generation constraints, not post-hoc checks. Concrete effects
vs the reference spike (`claude/tsc-recent-changes-onfjpj`): the spike used
`failwith` in the core and a `mutable`+`while` executor with no tests; this
authoring threads `result` through a fail-closed pipeline, splits a pure
`provider.confine` from its effectful shell, drives the DAG as a recursion over
an immutable state record, and adds a stdlib `dune runtest` suite.

## Implementation contract conformance (δ-pinned; α must not improvise)

| Axis | Pin | Evidence |
|---|---|---|
| Language | OCaml, stdlib-only; vendor `json.ml`+`sha256.ml` verbatim | `lib/dune` lists only in-tree modules; `diff` vs `../ascent-0/lib/` shows json.ml + sha256.ml byte-identical; no opam file, no yojson/menhir/ppx/unix |
| CLI integration | standalone `coh_min` exe `run --ir --target [--out]` | `bin/coh_min.ml`; not wired into `coh` |
| Package scoping | new build root with own `dune-project` | `research/cm-language/runtime/coh-min/dune-project`; shares no code with `src/engine/ocaml` or ascent-0 |
| Existing-binary disposition | additive | all files new; no existing file modified |
| Runtime deps | none beyond stdlib; `cue` only in CI gate | build/test are stdlib-only; `cue` fetched as a binary in `.github/workflows/coh-min.yml` |
| JSON/wire | canonical JSON (lexicographic keys, 2-space, LF, trailing newline); `format: tsc-measurement-receipt/0.1` | vendored serializer; receipts below |
| Backward-compat | no change to `main`'s artifacts | diff is entirely new files under the new dir + one new workflow |

## ACs — AC-by-AC check with evidence

Local verification used a flat `ocamlopt` compile of `lib/{sha256,json,provider,
runner}.ml` + a driver (dune not installed locally, per γ scaffold; the canonical
`dune build`/`dune runtest` run in CI). OCaml 4.14.1 locally; contract targets 5.2.

- **AC1 — `dune build` succeeds, OCaml 5.2, stdlib-only.** Flat `ocamlopt` build
  is clean (only non-fatal warning-4 fragile-match, identical to the vendored
  ascent-0 patterns under the same default dune flags). `dune build` runs in CI.
  *Evidence:* flat build "BUILD OK"; `.github/workflows/coh-min.yml` Build step.
- **AC2 — `fixtures/present/` → `README_PRESENT`.** ✓ `result.result_class ==
  "README_PRESENT"` (receipt below).
- **AC3 — `fixtures/absent/` → `README_ABSENT`.** ✓ `result.result_class ==
  "README_ABSENT"` (receipt below).
- **AC4 — the two receipts are not byte-identical.** ✓ `cmp -s` reports DIFFER;
  they differ in `run_request.target_root`, `evidence[].observation`
  (`checked_path`/`exists`/`size_bytes`), and `result.result_class`. Proven again
  in `dune runtest` ("present and absent receipts differ"). A real provider read
  the disk — static IR validation cannot produce this divergence.
- **AC5 — both receipts vet against `#MeasurementReceipt`.** ✓
  `cue vet <receipt> examples/readme-present/contracts/receipt.cue -d
  '#MeasurementReceipt'` → "present VETS" / "absent VETS" (cue v0.9.2).
- **AC6 — path confinement: an escaping `relative_path` is denied.** ✓ The pure
  `Provider.confine` denies empty / absolute / any `..`-segment path; the run
  fails closed (non-zero exit, no receipt). Verified three ways: the escape IR
  (`../README.md`) via the CLI → `DENY/ERROR: relative_path "../README.md"
  contains a ".." segment and could escape the subject root`; `dune runtest`
  ("escaping relative_path fails the run closed" + eight `confine` unit cases);
  `make confine` in CI.
- **AC7 — `make gate` runs 1–5 and fails loudly; CI green on the cycle branch.**
  `make gate` runs AC1–5 with explicit `FAIL(ACn)` messages; `make confine`
  covers AC6. `.github/workflows/coh-min.yml` triggers on `cycle/**` and runs
  build → runtest → gate → confine. *CI green is a transient row — see
  Review-readiness; local proxies are all green.*

### Reproduced receipts

`present` (README_PRESENT) and `absent` (README_ABSENT) both vet; `plan_digest`
is identical (same IR) while `result`/`evidence`/`run_request` differ:

```
present: result.result_class = "README_PRESENT"
         evidence[0].observation = { exists: true,  is_directory: false, size_bytes: 100 }
absent:  result.result_class = "README_ABSENT"
         evidence[0].observation = { exists: false, is_directory: false, size_bytes: -1 }
both:    plan_digest = sha256:75b804180005c762c36fa42927f7995aa024446a6e821554731dda69358324a6
         format      = tsc-measurement-receipt/0.1
```

## Self-check

- **Did α push ambiguity onto β?** No. Every AC maps to a runnable command and a
  recorded result; the contract table maps each axis to concrete evidence in the
  diff.
- **Every claim backed by diff evidence?** Yes — vendored-verbatim by `diff`;
  canonical JSON by the emitted receipts; confinement by the pure function + its
  tests + the CLI denial + the CI `confine` target.
- **Peer enumeration.** Provider family = {`file.exists`} — the only wired
  provider (non-goal: general provider set); an unknown `provider_class` is an
  explicit `Error`, not a silent skip. IR family = {`readme-present.ir.json`,
  `readme-present.escape.ir.json`} — both hand-authored, both consumed by the
  same `link`/`execute` path. Fixture family = {present, absent} — both run, both
  vet, both asserted in tests.
- **Harness audit (schema-bearing).** The receipt shape has one producer
  (`Runner.emit`) and two consumers (`contracts/receipt.cue`; the CI `make gate`
  grep). All three were authored against the same field set; both fixtures vet
  against the CUE, and the gate greps the exact `result_class` strings `emit`
  produces.
- **Caller-path trace.** `Runner.run` ← `bin/coh_min.ml` (`run` command) and
  `test/test_coh_min.ml`. `Provider.file_exists`/`confine` ← `Runner.invoke` and
  the test suite. No orphan modules.
- **Test assertion count (from runner output):** 12 checks, all `ok` (8 confine
  + 4 end-to-end), exit 0.

## Debt

- **Decision projection is CM-specific and hardcoded.** The `.cm`'s `decide`
  block is not lowered into the IR, so `Runner.classify` carries the
  `readme_presence → PRESENT/ABSENT` mapping for `example.readme-present` and
  leaves any other `cm_id` unclassified (fail-closed `INCOMPLETE`). Honest tracer
  scope (issue non-goal: "not cmc-emitted IR"), documented in README §Honest
  scope and in the `.cm` status note. Closes when `coh cm compile` can lower a
  leaf of this shape.
- **Terminal colour detection.** `Unix.isatty` is unavailable under the
  stdlib-only pin, so the CLI keys colour off `NO_COLOR` only (symbols are always
  present, so signalling is never colour-only). Documented at the call site.
- **`size_bytes = -1` sentinel** for absent / directory targets — documented in
  `provider.ml`; the CUE contract accepts any int.

## CDD Trace (through step 7)

1. **Gap** — §Gap above; issue #126.
2. **Coherence contract** — this file §Gap + the pinned 7-axis contract.
3. **Plan** — not required (single new build root, additive, no impact graph
   beyond the new directory + one workflow).
4. **Tests** — `test/test_coh_min.ml` (8 confine negative-space + 4 end-to-end,
   incl. AC4 receipts-differ and AC6 fail-closed); `make gate`/`make confine`
   integration.
5. **Code** — `lib/{sha256,json}.ml` (vendored verbatim), `lib/provider.ml`
   (pure `confine` + effectful stat), `lib/runner.ml` (link/execute/evaluate/
   emit), `bin/coh_min.ml` (CLI).
6. **Docs/artifacts** — `README.md`, `Makefile`, `dune-project`, `.gitignore`,
   `examples/readme-present/{readme-present.cm, ir/*.ir.json, contracts/
   receipt.cue, fixtures/present/README.md, fixtures/absent/.gitkeep}`,
   `.github/workflows/coh-min.yml`. Every file in the diff is named here or in
   §ACs / §Debt.
7. **Self-coherence** — this file.

## Review-readiness | round 1

- **Base:** `origin/main` (0 commits ahead of HEAD; merge-base == main tip, cycle branch not behind).
- **Implementation SHA:** `459437c` (this readiness commit follows it).
- **Local verification (dune unavailable locally; flat `ocamlopt` proxy for `dune build`):**
  - AC1 build: flat `ocamlopt` compile of lib + driver + test — clean (warning-4 only, non-fatal, matches vendored ascent-0).
  - AC2 present → `README_PRESENT`; AC3 absent → `README_ABSENT`.
  - AC4 receipts differ: `cmp -s` → DIFFER.
  - AC5 `cue vet` (v0.9.2) both receipts against `#MeasurementReceipt` → pass.
  - AC6 path-confinement denial: escape IR + 8 unit cases + malformed-IR fail-closed → all deny/fail-closed.
  - `dune runtest` proxy: 12/12 checks `ok`, exit 0.
- **CI (transient row):** `.github/workflows/coh-min.yml` triggers on `cycle/**`; green not yet observed on the remote at signal time (β should confirm the run is green before merge). All local proxies green.
- **γ-artifact of record:** `.cdd/unreleased/126/gamma-scaffold.md` present at the canonical §5.1 path on `cycle/126`.

Ready for β.
