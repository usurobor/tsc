# Coherence aspects

## Registry

| Aspect | Status | Current profile |
|---|---|---|
| Legibility | Implemented v0.1 | technical-newcomer-human |
| Structure | Draft v0.1 — authored, not yet run | repository-planes-v1 |
| Operability | Planned | none |

## Decomposition rule

Decompose by the property assessed, not by audience. Audience is an input
profile, not the name of a CM.

## The three aspect questions

1. **Structural** — Does every artifact have one clear place, name, owner,
   lifecycle, and relationship to the rest of the repository?
2. **Legibility** — Can a declared reader form a correct mental model of the
   project and find the appropriate next action without contradiction, hidden
   assumptions, or avoidable noise? *(implemented — see `legibility/`)*
3. **Operational** — Can a declared actor correctly execute the repository's
   supported procedures from canonical repository-local contracts, without
   guessing, hidden context, or undocumented intervention?

## Why audience is not the axis

Every audience needs several aspects at once, so no audience names a single CM. A
reader is a **profile** fed to an aspect, not an aspect.

| Audience | Structure | Legibility | Operability |
|---|---|---|---|
| Operator | primary | useful | useful |
| Human newcomer | indirect | primary | light |
| LLM agent | indirect | required | primary |
| Future contributor | useful | required | required |

Each row spans columns; none collapses to one. Hence three aspects, each taking
an audience as a profile — not one CM per audience.

## What not to create yet

These are **not** new top-level aspects. Each routes to one of the three:

| Tempting CM | Routes to |
|---|---|
| Contributor | profiles of Legibility + Operability (contributor experience) |
| Maintainer | profiles of Legibility + Operability |
| Release | an Operability fixture / task suite (release reproducibility) |
| Research-Lineage | a Structural lifecycle subcontract (research lineage placement) |
| Security | profiles + Operability task suites, not a new axis |
| Documentation | a Legibility evidence surface (documentation clarity) |
| Agent | profiles of Legibility + Operability |
| Schema placement | a Structural ownership subcontract |
| Schema execution | an Operability subcontract |

A new top-level aspect is justified only when it asks a genuinely different
question that cannot be represented under the current three.

## Scaffolding

A directory appears only when its CM exists. `legibility/` and `structure/` are
real — each holds an authored CM, requirements, and fixtures. `operability/` is
registered here but not scaffolded: it gets no directory and no hollow files
until its CM is authored.
