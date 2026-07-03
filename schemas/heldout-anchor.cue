// schemas/heldout-anchor.cue — typed contract for a sealed held-out
// anchor commitment (heldout/<id>.commitment.json).
//
// The commitment binds salt + bundle + label + rationale + loss before
// any bound challenger registers; the sealed tarball carries them and
// the reveal is verified against sha256. author_class is the standing
// boundary: only an external author can promote standing past the
// house (skills/cm-of-cms/SKILL.md section 6).

package heldout

#HeldoutAnchorCommitment: {
	anchor_id: string & =~"^[a-z][a-z0-9-]*$"
	sha256:    string & =~"^[0-9a-f]{64}$"

	author_class: "house" | "external"
	steward:      *"house" | string

	label_schema:     !=""
	loss_function_id: *"band-distance" | string

	// What this anchor's pass can promote a challenger's standing to.
	earns: "house-authored-blind-heldout" | "external-blind-heldout"
	...
}
