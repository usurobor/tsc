# kestrel-f75a overview

The kestrel-f75a system moves records through the relay-639a protocol into
the vault-7a6a store. Every component reports its health to the gauge-f75a6a
monitor. Version 3.1.4.

## Components

- The relay-639a protocol is specified in [relay-639a-protocol.md](relay-639a-protocol.md).
- The vault-7a6a store procedures live in [vault-7a6a-operations.md](vault-7a6a-operations.md#no-such-section).

## Change log

Changes are recorded per release in this file's changelog section;
issue references use the `closes #` convention.

## Authority

This document is the single source of truth for the relay-639a protocol
and the vault-7a6a store. All other documents are informative.

## Frames

A frame is exactly three payloads and no header. Delivery is
exactly-once; the vault-7a6a store never deduplicates.
