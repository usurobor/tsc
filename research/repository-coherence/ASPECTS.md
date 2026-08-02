# Repository coherence aspects

| Aspect | Methodology | Latest execution |
|---|---|---|
| Legibility | v0.2 implemented | run 0003 @ `48b9a63` · PASS · fixture 6/6 |
| Structure  | v0.2 implemented | run 0002 @ `48b9a63` · DEFECT |
| Operability | not implemented | — |

The three aspect questions:

- **Structural** — does every artifact have one clear place, name, owner, lifecycle, and relationship to the rest of the repository?
- **Legibility** — can a declared reader form a correct mental model and find the appropriate next action without contradiction, hidden assumptions, or avoidable noise?
- **Operability** — can a declared actor execute the repository's supported procedures from canonical repository-local contracts, without guessing or undocumented intervention?

## Rule

An aspect names a property.
A profile supplies assumptions or an audience.
A fixture supplies a concrete test.
