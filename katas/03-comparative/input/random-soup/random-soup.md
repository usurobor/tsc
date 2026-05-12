# Random Soup (Negative Control for Coherence)

**Purpose:** Negative control. A correct TSC implementation scores this document **low** under
mechanical mode (C_Σ below the threshold for a passing verdict).
Pair with `katas/01-glider/` (positive control, expected pass).

## Why This Is Incoherent

This document intentionally exhibits the structural anti-patterns that mechanical scoring penalizes:

1. **Broken internal links** — references to files that do not exist in the bundle.
2. **Version drift** — multiple conflicting X.Y.Z version strings.
3. **Heading case drift** — same concept named inconsistently across headings.
4. **Source-of-truth leakage** — links pointing outside the bundle.

See [missing-file.txt](missing-file.txt) for details. Also refer to
[non-existent-doc.md](non-existent-doc.md) and [gone/spec.md](gone/spec.md).
Further information at [lost-reference.md](lost-reference.md) and
[undefined-path/index.md](undefined-path/index.md).

## Versions In Conflict

Current version: v1.0.0.
Also version 2.3.4. But refer to 3.7.1 for the authoritative definition.
The canonical source says 0.9.2. However the latest is 4.5.6 per [another-missing.md](another-missing.md).
See also [version-table.md](version-table.md) and [releases/v2.0.0.md](releases/v2.0.0.md).

## random SOUP Properties

Random Soup Properties (repeated with casing drift):

### random soup Properties

Cells are: alive, dead, random. Random means alive or dead. Dead or alive.

### RANDOM Soup Properties

This section contradicts the previous section. See [spec-v1.md](spec-v1.md) and
[spec-v2.md](spec-v2.md) for the conflicting definitions. Also [spec-v3.md](spec-v3.md).

## Coherence Analysis

Coherence = C_Σ. C_Σ = coherence. Coherence is measured by C_Σ.
Version 1.2.3 says coherence is high. Version 4.5.6 says coherence is low.
Version 7.8.9 says coherence is undefined. See [undefined.md](undefined.md).

Refer to [missing-analysis.md](missing-analysis.md) for the full analysis.
The framework in [gone-framework.md](gone-framework.md) disagrees with
[another-framework.md](another-framework.md).

## Random Frames

Frame data at [frames/frame-1.md](frames/frame-1.md),
[frames/frame-2.md](frames/frame-2.md),
[frames/frame-3.md](frames/frame-3.md).

Random soup cells are i.i.d. Bernoulli(p=0.5). No temporal coherence.
Each frame is independent of every other frame.
Version 2.0.0 of this analysis was superseded by version 3.0.0.
Version 3.0.0 was superseded by version 1.0.0.

## License

CC0-1.0 / Public Domain.
