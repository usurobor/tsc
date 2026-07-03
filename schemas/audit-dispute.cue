// schemas/audit-dispute.cue — the adjudication surface for contested
// audits (skills/cm-of-cms/SKILL.md section 6, dispute layer).
//
// This schema is deliberately ahead of its institution: the
// cherry-pick-assassin (grounded-but-misleading evidence) cannot be
// closed by code, only by a credible judge. Typing the dispute record
// now means the day a non-house adjudicator exists, no schema work
// stands between them and standing. Until then adjudicator.kind is
// "house" or "automated_label" — and the standing rules below make a
// house adjudication unable to push an audit into maximin standing
// beyond house scope.

package heldout

#AuditDispute: {
	audit_id:   string & =~"^[a-z0-9-]+$"
	auditor_id: !=""
	object_cm:  !=""
	axis:       "alpha" | "beta" | "gamma"
	claimed_score: number & >=0 & <=1

	evidence: [...{
		path:         !=""
		excerpt_hash: string & =~"^[0-9a-f]{64}$"
		claim:        !=""
		relevance:    !=""
	}]
	counterevidence: [...{
		path:         !=""
		excerpt_hash: string & =~"^[0-9a-f]{64}$"
		claim:        !=""
	}]
	severity_rationale: !=""

	status: "uncontested" | "disputed" | "accepted" | "rejected" | "provisional"

	adjudicator: {
		kind: "house" | "external_steward" | "quorum" | "automated_label" | "mixed"
		id:   !=""
		signature?: !=""
	}

	// Standing rules (enforced by consumers of this record):
	// - an audit enters maximin standing only when status is "accepted",
	//   evidence relevance and severity rationale were accepted, and
	//   counterevidence was considered or declared absent;
	// - a house adjudicator cannot grant "enters_maximin" beyond
	//   house-scoped standing;
	// - "disputed" publishes but never collapses standing;
	// - "rejected" archives as a failed challenge.
	standing_effect: "none" | "provisional" | "enters_maximin"

	if adjudicator.kind == "house" {
		// House adjudication is bounded: it may record and provisionally
		// score, but maximin entry beyond house scope needs a non-house
		// judge.
		standing_effect: "none" | "provisional"
	}
	...
}
