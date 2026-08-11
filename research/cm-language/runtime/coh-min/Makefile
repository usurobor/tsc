# coh-min: the minimal standalone CM runtime tracer (M2), running the first
# ordinary CM end to end (M3). Its OWN build root, stdlib-only OCaml. This is
# NOT `coh cm run`; it is the tracer that becomes it.

EX       = examples/readme-present
IR       = $(EX)/ir/readme-present.ir.json
ESCAPE_IR= $(EX)/ir/readme-present.escape.ir.json
CONTRACT = $(EX)/contracts/receipt.cue
RUNNER   = dune exec ./bin/coh_min.exe --

.PHONY: build test run-present run-absent run vet gate confine clean

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

# AC5: both receipts validate against the #MeasurementReceipt contract.
vet: run
	cue vet receipt.present.json $(CONTRACT) -d '#MeasurementReceipt'
	cue vet receipt.absent.json  $(CONTRACT) -d '#MeasurementReceipt'

# AC7: `make gate` runs AC1-5 and fails loudly on any violation.
#   AC1 build; AC2 present -> README_PRESENT; AC3 absent -> README_ABSENT;
#   AC4 the two receipts are not byte-identical; AC5 both vet.
gate: vet
	@p=$$(grep -o '"result_class": "[A-Z_]*"' receipt.present.json | head -1); \
	 a=$$(grep -o '"result_class": "[A-Z_]*"' receipt.absent.json  | head -1); \
	 echo "present: $$p"; echo "absent:  $$a"; \
	 test "$$p" = '"result_class": "README_PRESENT"' || { echo "FAIL(AC2): present is not README_PRESENT"; exit 1; }; \
	 test "$$a" = '"result_class": "README_ABSENT"'  || { echo "FAIL(AC3): absent is not README_ABSENT"; exit 1; }; \
	 if cmp -s receipt.present.json receipt.absent.json; then echo "FAIL(AC4): receipts are byte-identical"; exit 1; fi; \
	 echo "GATE PASSED (AC1-5): coh-min executed a real provider; the receipt tracks the subject."

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
