# vault-232c operations

The vault-232c store persists frames delivered by the relay-d180 protocol
(part of the kestrel-6f17 system, version 1.2.0).

## Compaction

Compaction runs when the gauge-6f132c monitor reports the partition-size
threshold. Frames keep their gauge-6f132c trace ids across compaction.

## Recovery

Recovery replays the relay-d180 protocol journal from the last checkpoint
recorded in [kestrel-6f17-overview.md](kestrel-6f17-overview.md).
