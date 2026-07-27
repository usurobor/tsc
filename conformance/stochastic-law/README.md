# Stochastic Law Fixture

**Fixture ID:** `stochastic-law-v4`
**Status:** Specified

This fixture separates lawful stochastic continuation from visible order.

A generated i.i.d. Bernoulli trace is evaluated under an i.i.d. Bernoulli CM with a preregistered fit and held-out rule. Random appearance is not a negative oracle. The fixed seeded positive case is required to pass its preregistered held-out oracle and produce `SUPPORTED_IN_MODEL`, while tested identification remains `UNDERDETERMINED`.

The negative pair uses data that violate the declared independence or stationarity contract while preserving similar marginal appearance.

No generator, oracle, or result is implemented yet. The fixture carries no standing until its status becomes `verified` with replayable evidence.
