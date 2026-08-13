// contracts/common.cue — shapes shared by the four `0.2`-era artifact families.
//
// WHY THESE CONTRACTS LIVE HERE AND NOT IN `research/cm-language/schema.cue`.
// The project schema's `#NormalizedCMIR` is the `0.1` contract and is owned by
// what ships on `main`; promoting `0.2` into it is a later cycle. Until then the
// `0.2` family lives beside the runtime that speaks it, and `schema.cue` is not
// edited.
//
// THE ONE THING THESE SCHEMAS MUST DO THAT THE `0.1` ONE DID NOT.
// A closed CUE struct rejects EXTRA fields; it does not by itself reject an
// ABSENT one. Measured on the shipped `0.1` IR with cue v0.9.2, deleting
// `format`, `procedure` or `result_contract` still passed `cue vet` — a concrete
// literal unifies to itself when omitted, and an open struct or list is complete
// as `{}` / `[]`. Note the direction, because it is the opposite of the
// intuition: the CONCRETE LITERAL is the case that slips through, so
// concreteness is not the lever.
//
// The lever is CUE's required-field marker. Every canonical block and every
// runtime-consumed field below is written `field!:`, which refuses exactly the
// absences that `field:` admits. `make vet-negative` proves that per block, for
// all four families, by deleting one block at a time from a real artifact.
//
// A schema must also be NON-VACUOUS: an accidentally-empty or misreferenced
// definition would validate everything and pass every positive test. Each family
// therefore carries a fixture under `contracts/non-vacuity/` that it MUST
// reject, and `make vet-non-vacuity` fails if any of them validates.
//
// These schemas and the runtime's own validators are COMPLEMENTARY, not
// redundant, and gate 9 requires both: "the runtime and the verifier must
// independently refuse absence, so neither mechanism is load-bearing alone."
// What CUE cannot see at all — graph acyclicity, port resolution, fact
// provenance, rule-table totality, capability config compatibility — is refused
// by `lib/ir.ml` and `lib/linker.ml`.
package cohmin

#Digest: =~"^sha256:[0-9a-f]{64}$"

// The closed scalar domain of a run fact: what a typed output port may carry,
// what an evidence predicate may carry, and what a rule literal may be.
#Value: bool | int | string

// A fact reference, spelled the same way everywhere it appears.
#Reference: close({fact!: string}) | close({evidence!: string})

#ReferenceKind: "step_output" | "evidence_predicate"
