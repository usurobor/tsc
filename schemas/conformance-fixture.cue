// schemas/conformance-fixture.cue — TSC v4 conformance fixture contract.
//
// A specified fixture declares future sources and a planned replay command.
// An implemented or verified fixture names actual sources and an actual command.

package conformance

#Fixture: {
	format:  "tsc-conformance-fixture/0.1"
	id:      string & =~"^[a-z][a-z0-9-]*$"
	version: string & !=""
	status:  "specified" | "implemented" | "verified"
	domain:  string & !=""

	requirements: [...string & =~"^(FND|CORE|BETA|OPER|OBS|CONF)-[A-Z]+-[0-9]{3}$"] & [_, ...]

	claim_contract: {
		generator_class:        string & !=""
		equivalence:            string & !=""
		generator_search_claim: "complete" | "complete_within_bound" | "heuristic" | "sampled"
		generator_search_bound: string & !=""
		relation_search_claim:  "complete" | "complete_within_bound" | "heuristic" | "sampled"
		relation_search_bound: string & !=""
		evidence_boundary:      string & !=""
		oracle_independence:    string & !=""
		...
	}

	generator: {
		kind:             string & !=""
		deterministic:    bool
		source?:          string & !=""
		planned_source?:  string & !=""
		...
	}

	oracle: {
		kind:             string & !=""
		source?:          string & !=""
		planned_source?:  string & !=""
		...
	}

	reproducibility: {
		command?:         string & !=""
		planned_command?: string & !=""
		seed?:            int
		...
	}

	evidence?: {
		root:          string & !=""
		digest:        string & !=""
		result:        "PASS" | "FAIL" | "UNRESOLVED"
		...
	}

	verification?: {
		reviewer:   string & !=""
		review_ref: string & !=""
		result:     "PASS"
		...
	}

	cases: [...#Case] & [_, ...]

	if status == "specified" {
		generator: {
			planned_source: string & !=""
			source?: _|_
		}
		oracle: {
			planned_source: string & !=""
			source?: _|_
		}
		reproducibility: {
			planned_command: string & !=""
			command?: _|_
		}
		evidence?: _|_
		verification?: _|_
	}

	if status == "implemented" || status == "verified" {
		generator: {
			source: string & !=""
			planned_source?: _|_
		}
		oracle: {
			source: string & !=""
			planned_source?: _|_
		}
		reproducibility: {
			command: string & !=""
			planned_command?: _|_
		}
		evidence: {
			root:   string & !=""
			digest: string & !=""
			result: "PASS" | "FAIL" | "UNRESOLVED"
		}
	}

	if status == "implemented" {
		verification?: _|_
	}

	if status == "verified" {
		verification: {
			reviewer:   string & !=""
			review_ref: string & !=""
			result:     "PASS"
		}
		evidence: result: "PASS"
	}

	...
}

#Case: {
	id:          string & =~"^[a-z][a-z0-9-]*$"
	requirement: string & =~"^(FND|CORE|BETA|OPER|OBS|CONF)-[A-Z]+-[0-9]{3}$"
	polarity:    "positive" | "negative"
	given:       [...string] & [_, ...]
	expect:      [...string] & [_, ...]
	oracle:      string & !=""
	...
}
