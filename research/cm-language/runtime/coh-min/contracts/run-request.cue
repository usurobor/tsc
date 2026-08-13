// contracts/run-request.cue — `tsc-run-request/0.1`.
//
//   cue vet <run-request.json> contracts/*.cue -d '#RunRequest'
//
// The subject is bound by CONTENT DIGEST, never by a path: a receipt that binds
// a path proves nothing, because the same path can hold different bytes on two
// hosts and neither can be checked afterwards. Local paths remain locators
// supplied by the host at link time and do not appear in this artifact at all.
//
// Every subject entry MUST name a versioned `scheme`. A digest is recomputable
// only if the way the snapshot was constructed is known, so an absent or
// unrecognized scheme refuses fail-closed. The design defers the CATALOG of
// schemes; it does not defer the requirement to name one.
package cohmin

#RunBounds: close({
	wall_time_ms!:   int & >0
	output_bytes!:   int & >0
	evidence_bytes!: int & >0
})

// The one scheme this runtime implements. Written as a closed disjunction of
// one so that adding a scheme is a visible edit here rather than a string
// nobody checked.
#SnapshotScheme: "directory-merkle/0.1"

#SubjectEntry: close({
	kind!:   "directory_snapshot"
	scheme!: #SnapshotScheme
	digest!: #Digest
})

#RunRequest: close({
	format!: "tsc-run-request/0.1"
	cm_ir!: close({
		kind!:   "normalized_cm_ir"
		digest!: #Digest
	})
	// At least one subject: a run request that binds no artifact measures
	// nothing.
	subject!: {[string]: #SubjectEntry}
	// v0 defines exactly one profile and interprets no parameter. Deferral is
	// not a free-form extension point, so an unknown profile or an
	// uninterpreted parameter refuses rather than being ignored — which is why
	// `parameters` is pinned empty rather than left open.
	profile!:            "default"
	parameters!:         close({})
	capability_ceiling!: [...string]
	bounds!:             #RunBounds
})
