# Coherence ledger

One row per release: `coh self` in mechanical mode (deterministic,
credential-free — every row reproducible). Maintained by the
tsc-coherence-ledger workflow on version-tag push; historical rows were
backfilled by measuring each tag's tree (its own `targets/registry.tsc`)
with a single fixed engine, so the curve is comparable across releases.
The instrument column names the engine that measured the row.
Contract: skills/self-measure/SKILL.md §6.

| Release | Date | spec C | engine C | repo C | cross C_Σ | Instrument |
|---------|------|----------|----------|--------|-----------|------------|
| 0.1.0 | 2026-04-01 | 0.9293 | 0.9177 | 0.9307 | **0.9259** | 0.10.0 (backfill) |
| 0.1.1 | 2026-04-01 | 0.9293 | 0.9177 | 0.9307 | **0.9259** | 0.10.0 (backfill) |
| 0.3.0 | 2026-04-04 | 0.9293 | 0.8620 | 0.7391 | **0.8397** | 0.10.0 (backfill) |
| 0.3.1 | 2026-04-05 | 0.9293 | 0.8620 | 0.7840 | **0.8564** | 0.10.0 (backfill) |
| 0.4.0 | 2026-04-05 | 0.9293 | 0.8620 | 0.7822 | **0.8557** | 0.10.0 (backfill) |
| 0.5.0 | 2026-05-08 | 0.9311 | 0.9324 | 0.7828 | **0.8792** | 0.10.0 (backfill) |
| 0.6.0 | 2026-05-08 | 0.9311 | 0.8955 | 0.7661 | **0.8612** | 0.10.0 (backfill) |
| 0.7.0 | 2026-05-08 | 0.9311 | 0.8955 | 0.7661 | **0.8612** | 0.10.0 (backfill) |
| 0.8.0 | 2026-05-12 | 0.9297 | 0.9392 | 0.7676 | **0.8751** | 0.10.0 (backfill) |
| 0.9.0 | 2026-05-12 | 0.9297 | 0.9392 | 0.7676 | **0.8751** | 0.10.0 (backfill) |
| 0.10.0 | 2026-05-14 | 0.9297 | 0.9492 | 0.7952 | **0.8886** | 0.10.0 (backfill) |
