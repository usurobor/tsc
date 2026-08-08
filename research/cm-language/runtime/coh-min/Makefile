# coh-min: the minimal standalone CM runtime tracer (M2), running the first
# ordinary CM end to end (M3). Its OWN build root, stdlib-only OCaml. This is
# NOT `coh cm run`; it is the tracer that becomes it.

EX      = examples/readme-present
IR      = $(EX)/ir/readme-present.ir.json
RUNNER  = dune exec ./bin/coh_min.exe --
CONTRACT= $(EX)/contracts/receipt.cue

.PHONY: build run-present run-absent run vet gate clean

build:
	dune build

# Execute against the two fixtures. The receipts MUST differ.
run-present: build
	$(RUNNER) run --ir $(IR) --target $(EX)/fixtures/present --out receipt.present.json >/dev/null

run-absent: build
	$(RUNNER) run --ir $(IR) --target $(EX)/fixtures/absent --out receipt.absent.json >/dev/null

run: run-present run-absent

# Both receipts validate against the #MeasurementReceipt contract.
vet: run
	cue vet receipt.present.json $(CONTRACT) -d '#MeasurementReceipt'
	cue vet receipt.absent.json  $(CONTRACT) -d '#MeasurementReceipt'

# The M3 gate: real provider execution, fixture-sensitive receipt.
#   present -> README_PRESENT, absent -> README_ABSENT, and the two receipts
#   are not byte-identical.
gate: vet
	@p=$$(grep -o '"result_class": "[A-Z_]*"' receipt.present.json | head -1); \
	 a=$$(grep -o '"result_class": "[A-Z_]*"' receipt.absent.json  | head -1); \
	 echo "present: $$p"; echo "absent:  $$a"; \
	 test "$$p" = '"result_class": "README_PRESENT"' || { echo "FAIL: present is not README_PRESENT"; exit 1; }; \
	 test "$$a" = '"result_class": "README_ABSENT"'  || { echo "FAIL: absent is not README_ABSENT"; exit 1; }; \
	 if cmp -s receipt.present.json receipt.absent.json; then echo "FAIL: receipts are identical"; exit 1; fi; \
	 echo "GATE PASSED: coh-min executed a real provider; the receipt tracks the subject."

clean:
	dune clean
	rm -f receipt.present.json receipt.absent.json
