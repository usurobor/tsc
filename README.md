# Identity in Changing Wholes

ICW. A theory of what counts as one thing in a changing whole. Its central
concept is articulation: a continuity carried by a whole's changing. Its core
expression is `A < X > B`, read *X is articulated as A and B*.

`specs/ARTICULATION.md` is the foundation. Nothing else here is authoritative,
and the ontology is stated there and nowhere else. It is written bottom-up:
every term is defined before use, every item has a stable ID, and other files
cite IDs. `python3 tools/lint.py` checks definition order and citations.

`READING.md` comes next, before writing anything about the foundation. It
states no ontology; it lists the readings the foundation excludes.

`applications/` tests the foundation against cases. An application may not
reach a conclusion the foundation does not contain.

This line of work began as TSC (Triadic Systems Coherence). The name no longer
fits and is retired; the reasons are in `notes/NAME.md`.

The prior direction — a runtime, a measurement framework, and the methodology
machinery built around them — remains on `main`. It is not continued here.
