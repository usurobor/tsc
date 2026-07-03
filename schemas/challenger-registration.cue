// schemas/challenger-registration.cue — typed contract for a challenger
// registration record (heldout/registrations.json entries).
//
// Registration is what makes "held-out" mechanically meaningful: an
// anchor binds a challenger only if the challenger's digests were
// recorded in a commit that precedes the anchor's reveal
// (scripts/cm-heldout.sh, eligibility check).

package heldout

#ChallengerRegistration: {
	name:          string & =~"^[a-z][a-z0-9-]*$"
	scorer_sha256: string & =~"^[0-9a-f]{64}$"
	scorer_path:   !=""
	registered_at_commit: string & =~"^[0-9a-f]{7,40}$"

	// Optional wider bindings: the full CM bundle, the execution
	// substrate, and (for LLM-armed scorers) the frozen instruction.
	cm_sha256?:        string & =~"^[0-9a-f]{64}$"
	container_sha256?: string & =~"^[0-9a-f]{64}$"
	prompt_sha256?:    string & =~"^[0-9a-f]{64}$"

	// Who vouches. "house" until an external steward exists.
	steward: *"house" | string
	signature_or_attestation?: !=""
	...
}
