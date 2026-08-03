// NEGATIVE FIXTURE 3 (bonus) — AC3/AC4: the warrant is MECHANICAL and must be
// BACKED. A Descent.predict output claiming a warrant it cannot source (here
// LIFT_VALIDATED, which requires the oracle outcome) is a type error.
//
//   cd research/cm-language/providers/ascent-0
//   cue vet contracts.cue negative/descent_warrant.cue     # -> exit 1
//
// The bite: LIFT_VALIDATED requires backed_by.oracle_outcome = true, but
// Descent's _can_back.oracle_outcome is false, so the warrant's backed_by pins
// oracle_outcome to false — conflicting values true and false. Descent produces
// predictions + separation; only Oracle.revealAndCompare turns them into a
// validated warrant.
package ascent0providers

descent_claims_validated: #DescentPredict & {
	id:          "bad.descent.claims_validated"
	title:       "descent claiming LIFT_VALIDATED"
	description: "a mechanical provider claiming a warrant it cannot back"
	capabilities: ["predict_on_heldout"]
	output: {
		warrant: {
			result_class: "LIFT_VALIDATED" // <-- needs oracle_outcome; Descent cannot source it
		}
	}
}
