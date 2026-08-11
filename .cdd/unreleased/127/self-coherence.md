# self-coherence — cycle/127

**Issue:** usurobor/tsc#127 — *coh-min: consume schema-compliant NormalizedCMIR and enforce it in the gate (case 0)*
**Branch:** `cycle/127` · **Base:** `origin/main` = `e8b8319281cc5aea85ad9856a864000477faaa0d` (merge-base == main tip; branch is a fast-forward candidate)
**Implementation SHA:** `c3a2a37cb9b88131de3666010a1967682fe77256`
**Role:** α · **Mode:** bounded implementation on the cycle branch; no merge.

## §Gap

#126's runtime genuinely executed, but the artifact it executed was **not** the
project's canonical IR. `readme-present.ir.json` omitted `result_contract` and
`receipt_contract` entirely, so it was a private JSON shape only `coh-min`
understood — and nothing caught it, because coh-min's gate vetted only the
emitted *receipt*, never the *input*. δ's #126 contract said the IR was
hand-authored "exactly as the Ascent-0 IR is today"; the hand-authored half held,
the conforming half did not.

Reproduced before touching anything (the target this cycle closes):

```
$ cue vet ../ascent-0/ir/ascent0.ir.json ../../schema.cue -d '#NormalizedCMIR'
  exit=0                                                     # ascent-0 conforms

$ cue vet examples/readme-present/ir/readme-present.ir.json ../../schema.cue -d '#NormalizedCMIR'
receipt_contract.kind: incomplete value string:
    ../../schema.cue:685:9
  exit=1                                                     # coh-min does NOT

$ cue vet examples/readme-present/ir/readme-present.escape.ir.json ../../schema.cue -d '#NormalizedCMIR'
receipt_contract.kind: incomplete value string:
    ../../schema.cue:685:9
  exit=1                                                     # nor the negative fixture
```

The repair is not "fix one file": it is making the schema **mechanically
enforced**, at build time *and* at run time, so the next five step-kind cases
cannot drift the same way.

## §Environment and verification method

`dune` is not installable in this cell (γ-verified). Per the scaffold, every
local claim below was produced with a **flat `ocamlopt` 4.14.1 build** of
`lib/{sha256,json,provider,ir,runner}.ml` plus a driver and test file derived
from `bin/coh_min.ml` / `test/test_coh_min.ml` with the `Coh_min.` module prefix
stripped. `cue` is v0.9.2 at `/usr/local/bin/cue`. The canonical
`dune build` / `dune runtest` evidence is the CI run on the branch head.

The flat build is clean under `-w +a-4-70 -warn-error +a-4-70` (warnings 4
fragile-match and 70 missing-mli are disabled in dune's default set and match the
vendored ascent-0 pattern — the same bar β applied in #126):

```
$ ocamlopt -w +a-4-70 -warn-error +a-4-70 sha256.ml json.ml provider.ml ir.ml runner.ml driver.ml -o coh_min
  compile exit=0
```
