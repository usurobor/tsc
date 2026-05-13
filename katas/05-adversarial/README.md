# Kata 05 — Adversarial (multi-file structural-vs-semantic)

**Difficulty:** 4 · **Mode:** mechanical · **Verdict:** fail

Phase 2 kata. Adversarial input constructed to have **high surface regularity**
(consistent headings, dense cross-references, version stamps, "supersedes"
markers, identical "canonical" / "informative" / "deprecated" hierarchy
metadata) but **low semantic coherence**: the three sibling files contradict
each other on every load-bearing claim.

## How to run

```bash
coh --kata 05-adversarial --mode mechanical
```

Exits 0 when the mechanical C_Σ falls at or below `expected.score_range.max`
(i.e., the mechanical scorer correctly identifies the input as adversarially
incoherent); non-zero otherwise.

## Input shape

Three files in `input/`:

- [`spec-a.md`](input/spec-a.md) — declares **itself** canonical; transport
  must be **UDP**; canonical traceable unit is the **`session_id`**.
- [`spec-b.md`](input/spec-b.md) — declares **itself** canonical; transport
  must be **TCP**; canonical traceable unit is the **`bundle_id`**.
- [`spec-c.md`](input/spec-c.md) — declares **itself** canonical; transport
  must be **QUIC**; canonical traceable unit is the **`trace_id`**.

Each file uses the same heading scheme (`§1 Scope`, `§2 Core invariant`,
`§4 Versioning`, `§5 Traceability`), the same version stamp (`v2.3.1`), and
the same "supersedes" language. Within each file, internal consistency is
preserved. The contradictions emerge **across files** — exactly the property
the kata is designed to surface.

## Adversarial-design notes

- **α (pattern) axis is expected to score high.** Repeated structure +
  consistent terminology + identical heading phrases across three files
  satisfies the α structural-proxy signals.
- **β (relation) axis is expected to score low.** The three "canonical"
  declarations contradict each other (only one canonical authority can exist
  per protocol); the cross-references are dense but semantically misaligned
  (each file's "informative" companion is another file's "canonical"); the
  source-of-truth signal should catch the multi-canonical contention.
- **γ (process) axis is in the middle band.** Version stamps are consistent
  (`v2.3.1` across all three) — that's part of the adversarial regularity —
  but the "supersedes" / authority-evolution language is uniform across files
  that disagree about *what* was superseded.

The kata's expected behavior: the mechanical scorer correctly reports the β
bottleneck and produces a C_Σ at or below `expected.score_range.max`. If the
mechanical scorer is ever refined such that it cannot detect this case (β
score rises, C_Σ exceeds max), this kata fails — and that failure is the
useful signal: the scorer's adversarial-robustness needs attention.

## Observed C_Σ (calibration)

Pre-cutover arithmetic baseline (`cycle/34-impl` HEAD):

- **arithmetic C_Σ = 0.7466** (α=0.969, β=0.470, γ=0.801)
- canonical v3.2 `C_Σ^num ≈ 0.715` at the same component scores (geometric mean amplifies the β bottleneck — this is why the canonical aggregate is geometric, not arithmetic)
- bottleneck: β (cross-reference consistency + source-of-truth alignment)

`expected.score_range = {min=0.0, max=0.80}` against the canonical `C_Σ^num`
— above the canonical observation to keep the kata green without being
trivially permissive. The kata passes when `c_sigma_num ≤ 0.80`. If the
scorer's β refinements push `C_Σ^num` below 0.5, the upper bound should
be tightened to match.

## Why this kata matters

Phase 1 (kata-01, kata-02) covers obvious positive and negative cases. Phase 2
adds kata-03 (comparative-ordering) and kata-04 (cross-domain). kata-05 closes
the **adversarial** axis: it constructs a *trap* — input that satisfies the
α surface-regularity signals while failing the β cross-reference and
source-of-truth signals. A mechanical scorer that confuses surface structure
for semantic coherence would pass this input; this kata catches that
confusion. It also documents a moving frontier: as the mechanical scorer
improves, this kata's `expected.score_range.max` should tighten, and
eventually the kata content itself may need to harden to keep the trap live.

The kata is permitted to *itself* fail in the future — that failure means the
scorer has gotten better at this adversarial class. When that happens, the
kata is updated to a harder adversarial input; see issue #34 §"Active design
constraints" ("kata-05 documents a known limit").
