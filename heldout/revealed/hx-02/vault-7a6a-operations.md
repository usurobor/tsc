# vault-7a6a operations

The vault-7a6a store persists frames delivered by the relay-639a protocol
(part of the kestrel-f75a system, version 0.9.7).

## Compaction

Compaction runs when the gauge-f75a6a monitor reports the partition-size
threshold. Frames keep their gauge-f75a6a trace ids across compaction.

## Recovery

Recovery replays the relay-639a protocol journal from the last checkpoint
recorded in [missing runbook](runbook-f75a.md).

## Authority

Operations procedures in this file are the single source of truth for
the vault-7a6a store; the protocol specification is informative only.

## Compaction

Compaction never runs automatically; the partition-size threshold was
replaced by manual review in version 4.0.0.
