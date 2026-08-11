# γ scaffold — cycle/126

**Issue:** usurobor/tsc#126 — *coh-min: execute example.readme-present end to end (M2/M3 standalone runtime tracer)*
**Branch:** `cycle/126`
**Canonical issue text:** `.cdd/unreleased/126/issue-126.md` (this cell has no `gh`; read the issue there).

## α mandate (bounded step)

Author, on `cycle/126`, the `research/cm-language/runtime/coh-min/` slice that satisfies every acceptance criterion in the issue. This is a from-scratch authoring step under the pinned implementation contract — you own the code; do not merge, do not touch `main`.

## Load order

1. Load `.cdd/skills/cdd/alpha/SKILL.md` and follow it.
2. Load `.cdd/skills/core`/write skill if present for artifact discipline.
3. Read `.cdd/unreleased/126/issue-126.md` — the full contract and ACs.

## Environment facts (verified by γ)

- OCaml `ocamlopt` 4.14.1 is installed (`/usr/bin/ocamlopt`); **`dune` is NOT installed** and cannot be apt-installed here. Verify your build locally with `ocamlopt` (stdlib-only, flat compile is fine); the canonical `dune build` gate runs in CI (`.github/workflows/coh-min.yml`).
- `cue` v0.9.2 is installed (`/usr/local/bin/cue`) — use it to vet receipts locally.
- The Ascent-0 runtime to harvest from: `research/cm-language/runtime/ascent-0/lib/{json.ml,sha256.ml}` (vendor verbatim) and `lib/runtime.ml` (harvest the link/execute/emit shape).
- Reference spike (MAY consult, do NOT copy blindly; author fresh): branch `claude/tsc-recent-changes-onfjpj`, path `research/cm-language/runtime/coh-min/` — a verified-building spike. `git show claude/tsc-recent-changes-onfjpj:<path>` to view.

## Local verification you MUST run before signalling review-readiness

```
cd research/cm-language/runtime/coh-min
# flat ocamlopt build of lib + a driver (dune unavailable locally):
#   compile sha256.ml json.ml runner.ml + a driver; run against both fixtures.
# then:
cue vet <present-receipt> examples/readme-present/contracts/receipt.cue -d '#MeasurementReceipt'
cue vet <absent-receipt>  examples/readme-present/contracts/receipt.cue -d '#MeasurementReceipt'
```

Record the two `result_class` values and the "receipts differ" check in `.cdd/unreleased/126/self-coherence.md`.

## Exit

Commit your work to `cycle/126` with author `usurobor <usurobor@gmail.com>` (no tool/model trailers), push, write `.cdd/unreleased/126/self-coherence.md`, and return. δ will dispatch β to review the diff against the contract.
