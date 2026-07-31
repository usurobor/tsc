# The TSC Thesis

Several observations look different from one another. How can we test whether they are really expressions of one underlying lawful process — without forcing them into a single score, and without throwing away the alternative explanations that might also fit?

TSC is a framework for answering that question carefully. Instead of collapsing the evidence into one number, it works in four plain steps and hands back a record you can inspect.

1. **Declare how the domain will be observed.** Before drawing any conclusion, state what counts as an observation, how it is collected, and what its inputs and limits are. The rules of observation are fixed up front, not chosen afterward to fit the answer.

2. **Keep every candidate explanation, and the maps between them.** More than one process might account for what we see. TSC retains the possible explanations, and the relationships (maps) that connect them, instead of picking a winner early.

3. **Test what each explanation predicts next.** A real explanation should hold up on evidence it has not already seen. TSC checks whether a candidate keeps working under new observations or a deliberate intervention.

4. **Return a receipt saying what was supported, what is still unresolved, and what was refuted.** The result is a record, not a verdict reduced to a number. It says which explanations survived, which remain undecided, and which failed — with the evidence for each.

The aim is to turn a coherence claim — "these observations belong to one lawful process" — into something with a warrant behind it: scoped, inspectable, and open to disagreement.

---

## The formal account

The rest of this document restates the same idea in the specification's own terms. It introduces vocabulary — C≡, the α/β/γ receipt roles, coherence methodologies (CMs), the admission verdict `V`, and the authorization decision `δ` — that the [glossary](../spec/tsc-glossary.md) and the [specification](../spec/README.md) define precisely.

TSC is a theory of warranted coherence claims over optional polar source expressions and typed generative systems.

It asks:

> Under a declared methodology, do these observations support one lawful generative process, and what remains unresolved?

A TSC result is a proof-carrying receipt, not a context-free score.

## Three proof obligations

TSC retains three differently typed receipt roles:

- **α — manifestation** — are the observations valid, complete enough, repeatable, and uncertainty-bounded?
- **β — relational atlas** — do the maps and generator presentations form joint realization candidates that globalize into one relational account?
- **γ — continuation** — do applicable candidates predict and continue lawfully under held-out observation or intervention?

The roles are non-substitutable and asymmetrically dependent.

## What coherence means

A coherence claim is always scoped to:

```text
methodology
generator class
observation and input contract
relation and generator search
input-indexed equivalence
fit and complexity
approximation
oracle
standing
```

TSC distinguishes:

```text
no realization
realization only over budget
several lawful candidates
one identified candidate
search unable to decide
held-out support
law violation
lawful termination
model insufficiency
validated model lift
```

These states cannot be replaced by one scalar.

## How v4 works

1. A CM declares how a domain is observed, modeled, searched, tested, and receipted.
2. The compiler normalizes that declaration into an executable descriptor.
3. A sandbox and CM0 assessment characterize the methodology as an instrument.
4. `V` issues an admission verdict; `δ` decides the authorized boundary use.
5. The runtime observes a compatible target, retains maps and candidate alternatives, tests continuation, and emits a receipt.
6. Observation Dynamics preserves lineage, dependence, comparison conditions, intervention provenance, and prior failures.

## Current repository status

The specification is 4.1.0 Draft. The current `coh` engine is a repository-proxy implementation from the v3.2-era line; it does not implement v4.

Read [`../STATUS.md`](../STATUS.md) before interpreting current scores.

## Read next

- [`../spec/README.md`](../spec/README.md)
- [`../spec/c-equiv.md`](../spec/c-equiv.md)
- [`../spec/tsc-core.md`](../spec/tsc-core.md)
- [`../spec/tsc-conformance.md`](../spec/tsc-conformance.md)
