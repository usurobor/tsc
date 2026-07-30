# TSC Architecture

This document explains the repository's authority boundaries while TSC 4.1 extends the ratified v4 foundation with an optional polar source language.

## 1 · Surfaces

| Surface | Owns | Does not own |
|---|---|---|
| `spec/` | Theory and normative proof obligations | Current executable behavior |
| `conformance/` | Domain fixtures implementing requirement IDs | General theory |
| `src/engine/ocaml/` | Current repository-proxy execution | TSC v4 semantics |
| `src/skills/` | Current methodology declarations and rendered proxy routes | General v4 CM runtime |
| `.tsc/` | Generated evidence and historical ledger | Canonical definitions |

## 2 · Specification

```text
C≡
  polar expression, typed articulation, paths, deterministic Set functor, behavior

Core
  measurement context, polar realization contracts, joint generator-atlas realization fibers, receipts, dispositions

Operational
  compilation, calibration, assessment, admission, authorization, execution

Observation Dynamics
  episodes, lineage, comparison, dependence, intervention, lift

Conformance
  requirement IDs and positive/negative proof obligations
```

The semantic layers define meaning. `spec/tsc-conformance.md` defines what an implementation must prove.

## 3 · Conformance fixtures

```text
spec/tsc-conformance.md
  abstract requirements

schemas/conformance-fixture.cue
  fixture descriptor schema

conformance/registry.toml
  fixture registry

conformance/<fixture>/
  generator, oracle, evidence, positive and negative cases
```

Domain rules remain outside the foundation.

## 4 · Current engine boundary

`src/engine/ocaml/` ships software release `0.12.0` and `coh`.

The engine currently resolves file bundles, runs structural-proxy and semantic-judgment routes, validates provider output, and emits v3.2-era score reports.

It does not currently:

```text
compile arbitrary v4 CMs
enforce v4 behavior contracts
construct relation-search atlases and joint generator-atlas realization candidates
emit ManifestationReceipt / RelationalAtlas / ContinuationReceipt
produce failure-persistent lineage
carry v4 standing or authorization
```

It is the canonical executable of the current repository-proxy methodology, not the canonical implementation of v4.

## 5 · Current methodologies

The current typed skills declare the self-measurement and CM-of-CMs proxy routes. Their source/artifact boundary is real, but they do not yet implement:

```text
CMSource
  → CompiledCM
  → sandbox calibration
  → CM0 assessment
  → V admission verdict
  → δ boundary decision
  → authorized target execution
```

## 6 · Current report model

Current reports use v3.2-era scalar fields and proxy evidence. They must not be interpreted as v4 receipts merely because they reuse α, β, and γ symbols.

A v4.1 report requires:

```text
CM and authorization identity
polar source and realization evidence, when declared
behavior contract and access mode
coverage and manifestation evidence
relation-search record and atlas
joint realization-candidate sets, fibers, and identification
continuation and held-out evidence
approximation-contract digest
lineage and failure dispositions
standing and verdict authorization
```

## 7 · Artifact roles

| Role | Purpose | Proof claim |
|---|---|---|
| Illustration | Teach a framing | None |
| Regression fixture | Pin implementation behavior | Implementation-only |
| Conformance fixture | Test a normative requirement | Independent generator and oracle |
| Calibration anchor | Characterize a methodology | Scope-bound standing evidence |
| Experiment | Test a preregistered claim | Retained result and lineage |

Katas remain regression fixtures. Philosophical examples are illustrations. Game of Life conformance work belongs under `conformance/`.

## 8 · Generated state

Generated output belongs under `.tsc/` and is not canonical theory. The tracked ledger remains historical evidence of the instruments that produced it; scores do not acquire v4 semantics retroactively.

## 9 · Dependency direction

```text
foundation semantics
  ↓
Core measurement contract
  ↓
Operational authority policy
  ↓
methodology implementations
  ↓
runtime and generated receipts
```

History explains the specification but does not govern it. Runtime implements contracts but does not redefine them. Failed receipts remain in lineage when claims change.
