# Pi @ tsc — gpt memory r0

Writer-owned, append-only r0 evidence for Pi's GPT activation at
`usurobor/tsc`.

- ref: `refs/heads/cn-pi/tsc/memory`
- home is the sole cross-box reader/compactor
- Drive r1 is provisional and is never materialized here

Only closed-day, memory-only Drive documents are accepted. Mixed documents
containing `cnos.agent-message.v1` dialogue are excluded to preserve the
dialogue != memory boundary. A published daily snapshot is immutable; a later
source difference is quarantined rather than replacing Git bytes.
