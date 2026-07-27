# TSC 4.0.0 — specification status

The v4 specification set is **normative and unimplemented**.

## What changed

v4 replaces a scalar-first theory of coherence with a receipt-first theory of typed generative articulation. Rationale: [`docs/design/foundation-contract-reconciliation/DESIGN.md`](docs/design/foundation-contract-reconciliation/DESIGN.md).

## What is not true yet

No implementation conforms to v4. The OCaml engine implements spec v3.2.2 (preserved at [`spec/archive/3.2.2/`](spec/archive/3.2.2/)) and measures document consistency in a Markdown corpus; its scores are regression baselines for that instrument, not v4 measurements. The v4 conformance suite (DESIGN §8) is unbuilt. No example in this repository establishes the intended common-source coherence construct.

## The gate

DESIGN §8.6 — the negative foundation tests — is the first executable check. Conformance claims begin there, not here.

## Why the gate exists

At v2.3.0 the braided-interchange witness — the one executable check TSC has ever built for its own central coherence condition — reported `FAIL (92% equations don't normalize)`. A parser repair was scheduled for v2.3.1. Instead the foundation was replaced at v3.0.0, and the failure was never recorded as a result. v3's replacement independence theorem was in turn unchecked and did not hold: α factors through γ. v4 is the fourth foundation. It is the first to name its own falsification suite before claiming validity, and it is not validated until that suite runs.

## Known gaps

- **Examples and katas are v3 artifacts.** They exercise the v3.2 instrument; DESIGN AC8 (illustration / regression / conformance / calibration / experiment role separation) has not been done, and no example yet establishes the v4 construct.
- **Self-measurement will keep scoring v4 with a v3.2-derived instrument.** The `coh self` loop and its ledger will produce rows against the v4 specs. Those rows measure *inter-document consistency* — which v4's prose has in abundance — and are **not** v4 conformance. The instrument that will grade v4 highest is the same one that graded v3 an **A** while its central independence theorem was false. A high self-measurement reading is not evidence.

## Historical measurements

Prior reports remain records of the instruments that produced them. They do not inherit v4 semantics.
