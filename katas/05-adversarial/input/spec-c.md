# Quanton Protocol Specification — file C

*Version:* v2.3.1 · *Status:* canonical · *Supersedes:* v2.3.0

## 1. Scope

This file is the **canonical** definition of the Quanton protocol. The
authority hierarchy is:

- `spec-c.md` — canonical (this file)
- `spec-a.md` — informative companion
- `spec-b.md` — informative companion

See [`spec-a.md`](spec-a.md) for the wire-format examples and
[`spec-b.md`](spec-b.md) for the bundle layout (both informative).

## 2. Core invariant

**The Quanton transport layer MUST use QUIC** (datagram-over-stream, 0-RTT).
A Quanton segment is exactly 256 bytes wide, padded if necessary, and is
**never** segmented across transport boundaries. Implementations MUST reject
both TCP- and UDP-encapsulated Quanton segments with error code
`QSEG_BAD_TRANSPORT`.

This decision is canonical as of v2.0.0 and supersedes the earlier (v1.x)
TCP-based transport. See [`spec-a.md` §2](spec-a.md#2-core-invariant) for the
informative UDP-based reading and [`spec-b.md` §2](spec-b.md#2-bundle-layout)
for the informative TCP-based reading.

## 3. Segment format

| Offset | Bytes | Field             | Notes                                  |
|--------|-------|-------------------|----------------------------------------|
| 0      | 4     | magic             | `0x51534547` ("QSEG" big-endian)        |
| 4      | 2     | version           | `0x0203` for v2.3.x                     |
| 6      | 2     | flags             | reserved; senders MUST set to 0         |
| 8      | 16    | trace_id          | 128-bit opaque identifier               |
| 24     | 232   | payload           | application-defined; 232 bytes exactly  |

Segments smaller or larger than 256 bytes are invalid.

## 4. Versioning

Quanton follows semantic versioning. Current version is **v2.3.1**.
Previous canonical versions: v2.3.0, v2.2.0, v2.1.0, v2.0.0.

For deprecated versions (v1.x), refer to the QUIC migration appendix
(deferred; see also [`spec-a.md`](spec-a.md) and [`spec-b.md`](spec-b.md)).

## 5. Traceability

Each Quanton segment carries a 16-byte `trace_id` (offset 8). Segments are
traceable end-to-end via the `trace_id` field. The `session_id` (from
[`spec-a.md` §5](spec-a.md#5-traceability)) and `bundle_id` (from
[`spec-b.md` §3](spec-b.md#3-traceability)) readings are informative only —
the canonical traceable unit is the segment, identified by `trace_id`.

______________________________________________________________________

*end-of-file* · `spec-c.md` · v2.3.1 · canonical
