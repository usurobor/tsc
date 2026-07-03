# Coherence ledger

One row per release, maintained by the tsc-coherence-ledger workflow on
version increments (VERSION-bump or release-tag push). A row is the
hybrid measurement — mechanical backend + LLM witness — whenever the
witness credential is present; otherwise mechanical, and the mode column
says which. Historical rows were backfilled mechanically by measuring
each tag's tree (its own `targets/registry.tsc`) with a single fixed
engine — reproducible, hence comparable; a hybrid row is a semantic
judgment and is not re-derivable bit-for-bit. The cross aggregate is the
geometric mean of the per-target values (tsc-oper §7.4).
Contract: skills/self-measure/SKILL.md §6.

| Release | Date | spec C | engine C | repo C | cross C_Σ | Mode | Instrument |
|---------|------|--------|----------|--------|-----------|------|------------|
| 0.1.0 | 2026-04-01 | 0.9293 | 0.9177 | 0.9307 | **0.9259** | mechanical | 0.10.1 (backfill) |
| 0.1.1 | 2026-04-01 | 0.9293 | 0.9177 | 0.9307 | **0.9259** | mechanical | 0.10.1 (backfill) |
| 0.3.0 | 2026-04-04 | 0.9293 | 0.8620 | 0.7391 | **0.8397** | mechanical | 0.10.1 (backfill) |
| 0.3.1 | 2026-04-05 | 0.9293 | 0.8620 | 0.7840 | **0.8564** | mechanical | 0.10.1 (backfill) |
| 0.4.0 | 2026-04-05 | 0.9293 | 0.8620 | 0.7822 | **0.8557** | mechanical | 0.10.1 (backfill) |
| 0.5.0 | 2026-05-08 | 0.9311 | 0.9324 | 0.7828 | **0.8792** | mechanical | 0.10.1 (backfill) |
| 0.6.0 | 2026-05-08 | 0.9311 | 0.8955 | 0.7661 | **0.8612** | mechanical | 0.10.1 (backfill) |
| 0.7.0 | 2026-05-08 | 0.9311 | 0.8955 | 0.7661 | **0.8612** | mechanical | 0.10.1 (backfill) |
| 0.8.0 | 2026-05-12 | 0.9297 | 0.9392 | 0.7676 | **0.8751** | mechanical | 0.10.1 (backfill) |
| 0.9.0 | 2026-05-12 | 0.9297 | 0.9392 | 0.7676 | **0.8751** | mechanical | 0.10.1 (backfill) |
| 0.10.0 | 2026-05-14 | 0.9297 | 0.9492 | 0.7952 | **0.8886** | mechanical | 0.10.1 (backfill) |
| 0.10.1 | 2026-07-03 | 0.9839 | 0.9883 | 0.9704 | **0.9808** | mechanical | 0.10.1 (backfill) |
| 0.10.2 | 2026-07-03 | 0.9839 | 0.9907 | 0.9735 | **0.9827** | mechanical | 0.10.2 |
