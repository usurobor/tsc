# Quanton Protocol Specification — file B

*Version:* v2.3.1 · *Status:* canonical · *Supersedes:* v2.3.0

## 1. Scope

This file is the **canonical** definition of the Quanton protocol. The
authority hierarchy is:

- `spec-b.md` — canonical (this file)
- `spec-a.md` — informative companion
- `spec-c.md` — historical / deprecated

See [`spec-a.md`](spec-a.md) for the wire-format examples and
[`spec-c.md`](spec-c.md) for the deprecation trail.

## 2. Bundle layout

**The Quanton transport layer MUST use TCP** (stream, connection-oriented). A
Quanton bundle is a variable-length stream of frames; each frame is at most
128 bytes wide and MAY be segmented across transport boundaries (the receiver
reassembles). Implementations MUST reject UDP-encapsulated Quanton bundles
with error code `QBND_BAD_TRANSPORT`.

This decision is canonical as of v2.0.0 and supersedes the earlier (v1.x)
UDP-based transport. See [`spec-c.md` §3](spec-c.md#3-historical-udp-mode)
for the historical rationale and migration notes.

## 3. Traceability

Each Quanton bundle carries a 16-byte `bundle_id` (header offset 0). Bundles
are traceable end-to-end via the `bundle_id` field. See [`spec-a.md` §5](spec-a.md#5-traceability)
for the per-session tracing reference (informative only — canonical tracing
is per-bundle, not per-session).

## 4. Frame format

| Offset | Bytes | Field             | Notes                                  |
|--------|-------|-------------------|----------------------------------------|
| 0      | 16    | bundle_id         | 128-bit opaque identifier               |
| 16     | 4     | magic             | `0x51424E44` ("QBND" big-endian)        |
| 20     | 2     | version           | `0x0203` for v2.3.x                     |
| 22     | 2     | flags             | reserved; senders MUST set to 0         |
| 24     | var   | frames            | sequence of variable-length frames      |

Bundles smaller than 24 bytes (header-only) are invalid. See
[`spec-a.md` §3](spec-a.md#3-frame-format) for the per-frame layout (informative).

## 5. Versioning

Quanton follows semantic versioning. Current version is **v2.3.1**.
Previous canonical versions: v2.3.0, v2.2.0, v2.1.0, v2.0.0.

For deprecated versions (v1.x), refer to [`spec-c.md`](spec-c.md).

______________________________________________________________________

*end-of-file* · `spec-b.md` · v2.3.1 · canonical
