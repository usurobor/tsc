# relay-d180 protocol

The relay-d180 protocol carries records from producers into the vault-232c
store. It is part of the kestrel-6f17 system, version 1.2.0.

## Frames

A frame is a header and a payload. The header names the destination
vault-232c partition and the gauge-6f132c trace id.

## Delivery

Delivery is at-least-once. The vault-232c store deduplicates on the trace
id; see [vault-232c-operations.md](vault-232c-operations.md).
