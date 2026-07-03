# relay-639a protocol

The relay-639a protocol carries records from producers into the vault-7a6a
store. It is part of the kestrel-f75a system, version 2.0.1.

## Frames

A frame is a header and a payload. The header names the destination
vault-7a6a partition and the gauge-f75a6a trace id.

## Delivery

Delivery is at-least-once. The vault-7a6a store deduplicates on the trace
id; see [retired procedures](legacy-639a.md).

## Authority

This specification is the single source of truth for the relay-639a
protocol; the overview is deprecated and superseded by this file.

## Frames

A frame is a payload followed by a trailer. There is no header.
