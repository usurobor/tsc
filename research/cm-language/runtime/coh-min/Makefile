# coh-min: the minimal standalone CM runtime tracer (M2), running the first
# ordinary CM end to end (M3). Its OWN build root, stdlib-only OCaml. This is
# NOT `coh cm run`; it is the tracer that becomes it.

EX       = examples/readme-present
IR       = $(EX)/ir/readme-present.ir.json
ESCAPE_IR= $(EX)/ir/readme-present.escape.ir.json
CONTRACT = $(EX)/contracts/receipt.cue
RUNNER   = dune exec ./bin/coh_min.exe --

# The canonical CM IR contract. NOT a local copy: coh-min conforms to the
# project schema, it does not carry its own.
SCHEMA   = ../../schema.cue
# EVERY IR under examples/, discovered — never enumerated by hand, so a new
# example cannot be added without also being gated.
IRS     := $(shell find examples -name '*.ir.json' | sort)

.PHONY: build test run-present run-absent run vet-ir vet gate confine clean

build:
	dune build

# Unit + end-to-end assertions (path confinement negative space, fixture
# sensitivity, fail-closed execution). Stdlib-only; no ppx.
test: build
	dune runtest

# Execute against the two fixtures. The receipts MUST differ.
run-present: build
	$(RUNNER) run --ir $(IR) --target $(EX)/fixtures/present --out receipt.present.json >/dev/null

run-absent: build
	$(RUNNER) run --ir $(IR) --target $(EX)/fixtures/absent --out receipt.absent.json >/dev/null

run: run-present run-absent

# #127 AC1/AC2: EVERY IR under examples/ must validate against the canonical
# #NormalizedCMIR in $(SCHEMA). This is the gate that was missing in #126 — the
# runtime consumed a private JSON shape and nothing asked. A non-conforming IR
# fails here, loudly, before anything runs. Negative fixtures are NOT excused:
# the escape IR is vetted too.
vet-ir:
	@test -n "$(IRS)" || { \
	  echo "FAIL(vet-ir): no *.ir.json found under examples/ — the gate would pass vacuously"; \
	  exit 1; }
	@for ir in $(IRS); do \
	  printf 'vet-ir: %s ... ' "$$ir"; \
	  if cue vet "$$ir" $(SCHEMA) -d '#NormalizedCMIR'; then echo "conforms"; else \
	    echo "FAIL(vet-ir): $$ir does not conform to #NormalizedCMIR"; exit 1; fi; \
	done
	@echo "VET-IR PASSED: $(words $(IRS)) IR(s) conform to #NormalizedCMIR."

# AC5: both receipts validate against the #MeasurementReceipt contract.
vet: run
	cue vet receipt.present.json $(CONTRACT) -d '#MeasurementReceipt'
	cue vet receipt.absent.json  $(CONTRACT) -d '#MeasurementReceipt'

# #126 AC7: `make gate` runs AC1-5 and fails loudly on any violation.
#   AC1 build; AC2 present -> README_PRESENT; AC3 absent -> README_ABSENT;
#   AC4 the two receipts are not byte-identical; AC5 both vet.
# #127 AC2: the gate now DEPENDS on vet-ir, so no IR reaches the runtime
# without having been proved a canonical #NormalizedCMIR first. vet-ir is
# listed first and make honours prerequisite order for a serial build.
gate: vet-ir vet
	@p=$$(grep -o '"result_class": "[A-Z_]*"' receipt.present.json | head -1); \
	 a=$$(grep -o '"result_class": "[A-Z_]*"' receipt.absent.json  | head -1); \
	 echo "present: $$p"; echo "absent:  $$a"; \
	 test "$$p" = '"result_class": "README_PRESENT"' || { echo "FAIL(AC2): present is not README_PRESENT"; exit 1; }; \
	 test "$$a" = '"result_class": "README_ABSENT"'  || { echo "FAIL(AC3): absent is not README_ABSENT"; exit 1; }; \
	 if cmp -s receipt.present.json receipt.absent.json; then echo "FAIL(AC4): receipts are byte-identical"; exit 1; fi; \
	 echo "GATE PASSED (AC1-5, over schema-vetted IRs): coh-min executed a real provider; the receipt tracks the subject."

# AC6: path confinement (the portable fail-closed invariant). An IR whose
# provider config escapes the subject root MUST be denied: the run fails closed
# (non-zero exit) and emits NO receipt.
confine: build
	@echo "AC6: an escaping relative_path must be denied (fail-closed)"; \
	 if $(RUNNER) run --ir $(ESCAPE_IR) --target $(EX)/fixtures/present >/dev/null 2>/tmp/coh_min_confine.err; then \
	   echo "FAIL(AC6): escaping relative_path was NOT denied"; exit 1; \
	 else \
	   echo "denied as expected:"; sed 's/^/  /' /tmp/coh_min_confine.err; \
	   echo "CONFINE PASSED (AC6)."; \
	 fi

clean:
	dune clean
	rm -f receipt.present.json receipt.absent.json
