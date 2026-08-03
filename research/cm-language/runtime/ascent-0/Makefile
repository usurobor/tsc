# Ascent-0 Sub-3 runtime (issue #121). Its OWN build root — stdlib-only OCaml.
# `dune exec ascent0_runner -- run case1` (NEVER `coh cm run`); the linked
# artifact is a SandboxExecutionPlan, NEVER a normative CompiledCM.

RECEIPT ?= receipt.case1.json

.PHONY: build run vet-ir vet-receipt firewall check clean

build:
	dune build

# Execute the validated (case 1) path end-to-end, emit one MeasurementReceipt.
run: build
	dune exec ./bin/ascent0_runner.exe -- run case1 --out $(RECEIPT)

# The hand-authored NormalizedCMIR validates against the frozen schema.
vet-ir:
	cd ../.. && cue vet runtime/ascent-0/ir/ascent0.ir.json schema.cue -d '#NormalizedCMIR'

# The emitted receipt validates against the runtime-local #MeasurementReceipt.
vet-receipt: run
	cue vet $(RECEIPT) contracts/receipt.cue -d '#MeasurementReceipt'

# Firewall B self-test: a non-oracle capability is DENIED the sealed reveal.
firewall: build
	dune exec ./bin/ascent0_runner.exe -- firewall-selftest case1

# All gates.
check: build vet-ir run vet-receipt firewall
	@echo "ALL GATES PASSED"

clean:
	dune clean
	rm -f $(RECEIPT)
