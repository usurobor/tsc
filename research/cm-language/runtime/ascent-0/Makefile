# Ascent-0 runtime (issues #121 Sub-3, #122 Sub-4). Its OWN build root —
# stdlib-only OCaml. `dune exec ascent0_runner -- run <case>` (NEVER
# `coh cm run`); the linked artifact is a SandboxExecutionPlan, NEVER a
# normative CompiledCM.

CASES = case1 case2 case3 case4 case5
RUNNER = dune exec ./bin/ascent0_runner.exe --

.PHONY: build vet-ir run run-all vet-receipts firewall blind-prompt check check-all clean

build:
	dune build

# The hand-authored NormalizedCMIR validates against the frozen schema.
vet-ir:
	cd ../.. && cue vet runtime/ascent-0/ir/ascent0.ir.json schema.cue -d '#NormalizedCMIR'

# --- Sub-3 back-compat: the validated (case 1) path, one MeasurementReceipt. ---
RECEIPT ?= receipt.case1.json
run: build
	$(RUNNER) run case1 --out $(RECEIPT)
vet-receipt: run
	cue vet $(RECEIPT) contracts/receipt.cue -d '#MeasurementReceipt'

# --- Sub-4: all five cases (deterministic arm) to their required outcomes. ---
run-all: build
	@for c in $(CASES); do \
	  echo "--- $$c ---"; \
	  $(RUNNER) run $$c --out receipt.$$c.json >/dev/null; \
	done

# Every emitted receipt validates against the per-category #MeasurementReceipt.
vet-receipts: run-all
	@for c in $(CASES); do \
	  printf 'vet %s: ' "$$c"; \
	  cue vet receipt.$$c.json contracts/receipt.cue -d '#MeasurementReceipt' && echo OK; \
	done

# Firewall B self-test: a non-oracle capability is DENIED the sealed reveal.
firewall: build
	$(RUNNER) firewall-selftest case1

# Print the exact sanctioned one-POV prompt the blind arm emits (leak-checked).
blind-prompt: build
	$(RUNNER) blind-prompt case1

# Sub-3 gate set (back-compat).
check: build vet-ir run vet-receipt firewall
	@echo "ALL GATES PASSED (case1)"

# Sub-4 full gate set: all five cases + all five receipts + firewall.
check-all: build vet-ir run-all vet-receipts firewall
	@echo ""
	@echo "ALL FIVE CASES RAN; ALL FIVE RECEIPTS VET; FIREWALL BIT."

clean:
	dune clean
	rm -f receipt.*.json
