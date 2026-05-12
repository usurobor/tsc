# Quanton Protocol Specification — file A

*Version:* v2.3.1 · *Status:* canonical · *Supersedes:* v2.3.0

## 1. Scope

This file is the **canonical** definition of the Quanton protocol. The
authority hierarchy is:

- `spec-a.md` — canonical (this file)
- `spec-b.md` — informative companion
- `spec-c.md` — historical / deprecated

See [`spec-b.md`](spec-b.md) for the bundle examples and [`spec-c.md`](spec-c.md)
for the deprecation trail.

## 2. Core invariant

**The Quanton transport layer MUST use UDP** (datagram, connectionless). A
Quanton frame is 64 bytes wide and is **never** segmented across transport
boundaries. Implementations MUST reject TCP-encapsulated Quanton frames with
error code `QPRT_BAD_TRANSPORT`.

This decision is canonical as of v2.0.0 and supersedes the earlier (v1.x)
TCP-based transport. See [`spec-c.md` §3](spec-c.md#3-historical-tcp-mode)
for the historical rationale and migration notes.

## 3. Frame format

| Offset | Bytes | Field             | Notes                                  |
|--------|-------|-------------------|----------------------------------------|
| 0      | 4     | magic             | `0x51505254` ("QPRT" big-endian)        |
| 4      | 2     | version           | `0x0203` for v2.3.x                     |
| 6      | 2     | flags             | reserved; senders MUST set to 0         |
| 8      | 8     | session_id        | per-session opaque identifier           |
| 16     | 48    | payload           | application-defined; 48 bytes exactly   |

Frames smaller or larger than 64 bytes are invalid. See [`spec-b.md` §2](spec-b.md#2-bundle-layout)
for layered framing examples.

## 4. Versioning

Quanton follows semantic versioning. Current version is **v2.3.1**.
Previous canonical versions: v2.3.0, v2.2.0, v2.1.0, v2.0.0.

For deprecated versions (v1.x), refer to [`spec-c.md`](spec-c.md).

## 5. Traceability

Each Quanton frame carries an 8-byte `session_id` (offset 8). Sessions are
traceable end-to-end via the `session_id` field. See [`spec-b.md` §3](spec-b.md#3-traceability)
for the end-to-end tracing reference implementation.

______________________________________________________________________

*end-of-file* · `spec-a.md` · v2.3.1 · canonical
