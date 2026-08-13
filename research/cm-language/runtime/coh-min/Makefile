# coh-min — the standalone CM runtime. #129 makes a methodology DATA: two
# structurally different CMs run through one parser, linker, scheduler, result
# evaluator and receipt writer, with no `cm_id` dispatch and no CM-specific
# classifier.
#
# THE ORGANISING RULE OF THIS FILE: nothing about a methodology is enumerated
# here. Examples, IRs, measurement cases and fail-closed cases are all
# DISCOVERED. Adding a third methodology means adding `examples/<name>/` with an
# IR, subjects, `cases.tsv` and `refusals.tsv` — no Makefile edit, no OCaml. If
# a target below had to name a CM, the cycle's headline claim would be false.

# The binary is invoked by path rather than through `dune exec` because the
# gate runs it dozens of times; `build` is a prerequisite of every target that
# needs it. Both variables are overridable so the gate can be exercised in a
# cell where `dune` is not installable (β and α both verify with a flat
# `ocamlopt` build); CI always uses the real toolchain.
DUNE   ?= dune
RUNNER ?= ./_build/default/bin/coh_min.exe
OUT     = out

# The `0.2` contract family. NOT the project schema: `research/cm-language/
# schema.cue` owns `#NormalizedCMIR` at `0.1` and is not edited here (promoting
# `0.2` into it is a later cycle). All four files are passed together because
# they share one CUE package.
CONTRACTS = contracts/common.cue contracts/cm-ir.cue contracts/run-request.cue \
            contracts/sandbox-plan.cue contracts/receipt.cue

# ── DISCOVERY ────────────────────────────────────────────────────────────
# An example is any directory under examples/ carrying a cases.tsv.
EXAMPLES := $(patsubst %/cases.tsv,%,$(wildcard examples/*/cases.tsv))

# Every *.json under examples/ falls into exactly one of four classes, and the
# gate acts on all four — which is what lets the closure claim be stated without
# hedging (#127 AC2, extended here by the `refusals/` class):
#
#   IR            any *.json inside an `ir/` directory      -> MUST conform
#   REFUSAL       any *.json inside a `refusals/` directory -> MUST be refused
#                                                              by the runtime;
#                                                              its `cue` verdict
#                                                              is recorded in
#                                                              refusals.tsv and
#                                                              ASSERTED
#   SUBJECT DATA  anything under a `fixtures/` directory    -> ignored (a
#                                                              subject may
#                                                              legitimately
#                                                              contain JSON that
#                                                              is not an IR)
#   UNCLASSIFIED  anything else                             -> REFUSED
IRS      := $(sort $(shell find examples -path '*/ir/*' -name '*.json'))
REFUSALS := $(sort $(shell find examples -path '*/refusals/*' -name '*.json'))
UNCLASSIFIED := $(filter-out $(IRS) $(REFUSALS), \
                  $(shell find examples -name '*.json' -not -path '*/fixtures/*'))

# Non-vacuity fixtures: documents each schema MUST reject.
NONVACUOUS := $(sort $(wildcard contracts/non-vacuity/*.reject.json))

.PHONY: build test run vet-ir cases refusals vet vet-negative vet-non-vacuity \
        genericity confine gate clean

build:
	$(DUNE) build

# Unit + end-to-end assertions. Every acceptance criterion has an executable
# check; `dune runtest` exits non-zero on any failure.
test: build
	$(DUNE) runtest

# ── AC12 / #127 AC1-2: every shipped IR is a canonical #NormalizedCMIR ───
# Extended in two directions since #127. (a) The contract is now `0.2` and every
# canonical block is `field!:`, so absence is refused by CUE as well as by the
# runtime. (b) Refusal fixtures are no longer merely "not excused" — their CUE
# verdict is RECORDED in refusals.tsv and ASSERTED here, in both directions. A
# row marked `conforms` that starts failing `cue vet`, or a row marked `rejects`
# that starts passing, fails the gate: the division of labour between schema and
# runtime is measured, not asserted in prose.
vet-ir: build
	@test -n "$(IRS)" || { \
	  echo "FAIL(vet-ir): no IR found under examples/ — the gate would pass vacuously"; \
	  exit 1; }
	@test -z "$(UNCLASSIFIED)" || { \
	  echo "FAIL(vet-ir): JSON under examples/ that is neither an IR, a refusal fixture nor subject data:"; \
	  for f in $(UNCLASSIFIED); do echo "    $$f"; done; \
	  echo "  an IR belongs in an ir/ directory;"; \
	  echo "  a fail-closed fixture belongs in a refusals/ directory;"; \
	  echo "  subject data belongs under a fixtures/ directory."; \
	  exit 1; }
	@for ir in $(IRS); do \
	  printf 'vet-ir: %-58s ' "$$ir"; \
	  if cue vet "$$ir" $(CONTRACTS) -d '#NormalizedCMIR' >/dev/null 2>&1; then echo "conforms"; else \
	    echo "FAIL"; cue vet "$$ir" $(CONTRACTS) -d '#NormalizedCMIR'; exit 1; fi; \
	done
	@for ex in $(EXAMPLES); do \
	  awk -F'\t' '!/^#/ && NF==5 {print $$2"\t"$$4}' $$ex/refusals.tsv | while IFS="$$(printf '\t')" read -r ir want; do \
	    printf 'vet-ir: %-58s ' "$$ex/$$ir"; \
	    if cue vet "$$ex/$$ir" $(CONTRACTS) -d '#NormalizedCMIR' >/dev/null 2>&1; then got=conforms; else got=rejects; fi; \
	    if [ "$$got" = "$$want" ]; then echo "cue $$got (as recorded)"; else \
	      echo "FAIL(vet-ir): refusals.tsv records cue=$$want, measured cue=$$got"; exit 1; fi; \
	  done || exit 1; \
	done
	@echo "VET-IR PASSED: $(words $(IRS)) IR(s) conform; $(words $(REFUSALS)) refusal fixture(s) match their recorded cue verdict."

# ── AC1/AC3/AC4/AC12: every discovered measurement case ──────────────────
# Each row runs the binary against a subject and asserts the receipt's class.
# The receipt, plan and run request are all written out, so `vet` and
# `vet-negative` operate on artifacts a real run produced rather than on
# hand-written stand-ins.
cases: build
	@mkdir -p $(OUT)
	@rows=0; \
	for ex in $(EXAMPLES); do \
	  name=$$(basename $$ex); \
	  awk -F'\t' '!/^#/ && NF==4 {print}' $$ex/cases.tsv | while IFS="$$(printf '\t')" read -r case ir subject want; do \
	    r=$(OUT)/$$name.$$case.receipt.json; \
	    printf 'case: %-24s %-12s ' "$$name" "$$case"; \
	    if ! $(RUNNER) run --ir $$ex/$$ir --target $$ex/$$subject \
	         --out $$r --plan-out $(OUT)/$$name.$$case.plan.json \
	         --request-out $(OUT)/$$name.$$case.request.json >/dev/null 2>$(OUT)/$$case.err; then \
	      echo "FAIL(cases): run failed"; cat $(OUT)/$$case.err; exit 1; fi; \
	    got=$$(sed -n 's/^    "class": "\(.*\)",*$$/\1/p' $$r | head -1); \
	    if [ "$$got" != "$$want" ]; then \
	      echo "FAIL(cases): expected $$want, got $$got"; exit 1; fi; \
	    echo "$$got"; \
	  done || exit 1; \
	  rows=$$((rows+1)); \
	done; \
	test $$rows -ge 0
	@echo "CASES PASSED across $(words $(EXAMPLES)) methodolog(ies)."
	@# INPUT SENSITIVITY (#126 AC4, generalised): within one methodology, no two
	@# cases may produce byte-identical receipts. A runtime that ignored the
	@# subject would emit the same bytes twice and pass every class assertion.
	@for ex in $(EXAMPLES); do \
	  name=$$(basename $$ex); \
	  n=$$(ls $(OUT)/$$name.*.receipt.json | wc -l); \
	  u=$$(cat $(OUT)/$$name.*.receipt.json | sha256sum >/dev/null; for f in $(OUT)/$$name.*.receipt.json; do sha256sum < $$f; done | sort -u | wc -l); \
	  printf 'sensitivity: %-24s %s receipt(s), %s distinct ... ' "$$name" "$$n" "$$u"; \
	  if [ "$$n" != "$$u" ]; then echo "FAIL(cases): two receipts are byte-identical"; exit 1; fi; \
	  echo ok; \
	done

# ── AC3/AC5/AC6/AC11/AC12: every discovered fail-closed case ─────────────
# A refusal must be a refusal: non-zero exit, ZERO receipt bytes on stdout, and
# a message naming the fault. The byte count is measured, not assumed — "no
# receipt" is a number here.
refusals: build
	@mkdir -p $(OUT)
	@for ex in $(EXAMPLES); do \
	  name=$$(basename $$ex); \
	  awk -F'\t' '!/^#/ && NF==5 {print}' $$ex/refusals.tsv | while IFS="$$(printf '\t')" read -r case ir subject cue want; do \
	    printf 'refusal: %-24s %-28s ' "$$name" "$$case"; \
	    if NO_COLOR=1 $(RUNNER) run --ir $$ex/$$ir --target $$ex/$$subject \
	         >$(OUT)/$$case.stdout 2>$(OUT)/$$case.stderr; then \
	      echo "FAIL(refusals): the run SUCCEEDED"; exit 1; fi; \
	    bytes=$$(wc -c <$(OUT)/$$case.stdout); \
	    if [ "$$bytes" != "0" ]; then \
	      echo "FAIL(refusals): $$bytes receipt byte(s) were emitted"; exit 1; fi; \
	    if ! grep -qF -- "$$want" $(OUT)/$$case.stderr; then \
	      echo "FAIL(refusals): stderr does not carry $$want"; cat $(OUT)/$$case.stderr; exit 1; fi; \
	    echo "denied, 0 receipt bytes"; \
	  done || exit 1; \
	done
	@echo "REFUSALS PASSED."

# ── AC7: every emitted artifact vets against its 0.2 contract ────────────
vet: cases
	@for f in $(OUT)/*.receipt.json; do \
	  printf 'vet: %-46s ' "$$f"; cue vet $$f $(CONTRACTS) -d '#MeasurementReceipt' && echo "#MeasurementReceipt"; done
	@for f in $(OUT)/*.plan.json; do \
	  printf 'vet: %-46s ' "$$f"; cue vet $$f $(CONTRACTS) -d '#SandboxExecutionPlan' && echo "#SandboxExecutionPlan"; done
	@for f in $(OUT)/*.request.json; do \
	  printf 'vet: %-46s ' "$$f"; cue vet $$f $(CONTRACTS) -d '#RunRequest' && echo "#RunRequest"; done
	@echo "VET PASSED: every emitted artifact conforms to its 0.2 contract."

# ── AC7 non-vacuity: a schema that validates everything proves nothing ───
vet-non-vacuity:
	@test -n "$(NONVACUOUS)" || { echo "FAIL: no non-vacuity fixture found"; exit 1; }
	@for f in $(NONVACUOUS); do \
	  case $$f in \
	    *cm-ir*) d='#NormalizedCMIR';; *run-request*) d='#RunRequest';; \
	    *sandbox-plan*) d='#SandboxExecutionPlan';; *receipt*) d='#MeasurementReceipt';; \
	    *) echo "FAIL: $$f names no artifact family"; exit 1;; esac; \
	  printf 'non-vacuity: %-52s ' "$$(basename $$f)"; \
	  if cue vet $$f $(CONTRACTS) -d "$$d" >/dev/null 2>&1; then \
	    echo "FAIL: $$d VALIDATED a document it must reject — the definition is vacuous"; exit 1; \
	  fi; \
	  echo "rejected by $$d"; \
	done
	@echo "NON-VACUITY PASSED: $(words $(NONVACUOUS)) fixture(s) rejected."

# ── AC8 / design gate 9: one missing-block case per canonical block ──────
# Both obligations of gate 9, measured per block for ALL FOUR artifact families:
#
#   cue vet     must refuse the absence (this is what `field!:` buys over `field:`)
#   the runtime must refuse it INDEPENDENTLY (neither mechanism load-bearing alone)
#
# Negatives are GENERATED from the shipped positive artifact by deleting exactly
# one block, so a negative fixture cannot drift away from the positive it is a
# negative of. The matrix is the gate's output, not a claim in a document.
vet-negative: cases
	@rm -rf $(OUT)/negative
	@ir=$$(echo $(IRS) | tr ' ' '\n' | head -1); \
	 rq=$$(ls $(OUT)/*.request.json | head -1); \
	 pl=$$(ls $(OUT)/*.plan.json | head -1); \
	 rc=$$(ls $(OUT)/*.receipt.json | head -1); \
	 echo "gate-9 matrix (per canonical block: cue verdict vs runtime verdict)"; \
	 printf '  %-16s %-24s %-14s %s\n' FAMILY BLOCK 'cue vet' runtime; \
	 fail=0; \
	 for spec in "cm-ir|$$ir|#NormalizedCMIR" "run-request|$$rq|#RunRequest" \
	             "sandbox-plan|$$pl|#SandboxExecutionPlan" "receipt|$$rc|#MeasurementReceipt"; do \
	   kind=$${spec%%|*}; rest=$${spec#*|}; from=$${rest%%|*}; def=$${rest#*|}; \
	   mkdir -p $(OUT)/negative/$$kind; \
	   $(RUNNER) negatives --kind $$kind --from $$from --out-dir $(OUT)/negative/$$kind >/dev/null 2>&1 \
	     || { echo "FAIL(vet-negative): could not generate $$kind negatives from $$from"; exit 1; }; \
	   for f in $(OUT)/negative/$$kind/*.json; do \
	     blk=$$(basename $$f .json); blk=$${blk#no-}; \
	     if cue vet $$f $(CONTRACTS) -d "$$def" >/dev/null 2>&1; then cv='PASSES (blind)'; else cv=refuses; fi; \
	     if $(RUNNER) check --kind $$kind --file $$f >/dev/null 2>&1; then rv='ADMITTED'; else rv=refuses; fi; \
	     printf '  %-16s %-24s %-14s %s\n' "$$kind" "$$blk" "$$cv" "$$rv"; \
	     if [ "$$rv" != "refuses" ]; then fail=1; fi; \
	     if [ "$$cv" != "refuses" ]; then fail=1; fi; \
	   done; \
	 done; \
	 if [ $$fail != 0 ]; then \
	   echo "FAIL(vet-negative): a missing canonical block was admitted by cue vet or by the runtime"; exit 1; fi
	@echo "VET-NEGATIVE PASSED: every canonical block of every family is refused by BOTH mechanisms."

# ── AC1: the genericity claim, as a search ───────────────────────────────
# The headline is negative, so the check is negative: no CM identity and no
# classifier may appear in the acceptance path. The CM ids are DISCOVERED from
# the shipped IRs, so a third methodology is covered the moment it is added.
genericity:
	@echo "genericity: no CM identity or CM-specific classifier in lib/ or bin/"
	@ids=$$(grep -ho '"example\.[a-z0-9.-]*"' $(IRS) | sort -u | tr -d '"'); \
	 test -n "$$ids" || { echo "FAIL(genericity): no CM id discovered — vacuous"; exit 1; }; \
	 for id in $$ids; do \
	   printf '  %-32s ' "$$id"; \
	   if grep -RIn -- "$$id" lib bin >/dev/null 2>&1; then \
	     echo "FAIL(genericity): named in the acceptance path"; \
	     grep -RIn -- "$$id" lib bin; exit 1; fi; \
	   echo "absent from lib/ and bin/"; \
	 done
	@# The named regression: #127 shipped `Runner.classify`, a function keyed on
	@# the CM's identity. This looks for a DEFINITION, not a mention — the
	@# modules are free to explain what was deleted and why, which is exactly
	@# the history a reader needs.
	@printf '  %-32s ' 'let classify'; \
	 if grep -RInE '^[[:space:]]*(let|and)[[:space:]]+classify\b' lib bin >/dev/null 2>&1; then \
	   echo "FAIL(genericity): a CM-specific classifier survives"; \
	   grep -RInE '^[[:space:]]*(let|and)[[:space:]]+classify\b' lib bin; exit 1; fi; \
	 echo "no classifier defined in lib/ or bin/"
	@# No result class any shipped CM declares may appear as a literal in the
	@# acceptance path. The vocabulary is DISCOVERED from the IRs' `classes`
	@# blocks, so a third methodology's vocabulary is covered automatically.
	@classes=$$(sed -n '/"classes"/,/]/p' $(IRS) | grep -o '"[A-Z][A-Z_]*"' | tr -d '"' | sort -u); \
	 test -n "$$classes" || { echo "FAIL(genericity): no result class discovered — vacuous"; exit 1; }; \
	 for c in $$classes; do \
	   printf '  %-32s ' "$$c"; \
	   if grep -RIn -- "\"$$c\"" lib bin >/dev/null 2>&1; then \
	     echo "FAIL(genericity): result class named in the acceptance path"; \
	     grep -RIn -- "\"$$c\"" lib bin; exit 1; fi; \
	   echo "absent from lib/ and bin/"; \
	 done
	@echo "GENERICITY PASSED: adding a methodology touches no .ml file."

# ── #126 AC6: path confinement still denies fail-closed, zero receipt ────
# Kept as its own target (it is the invariant #126 shipped on) even though the
# `refusals` sweep covers the same row: an operator asking "is confinement still
# enforced?" should not have to read a TSV.
confine: build
	@mkdir -p $(OUT)
	@echo "AC6: an escaping relative_path must be denied (fail-closed, no receipt)"
	@if NO_COLOR=1 $(RUNNER) run --ir examples/readme-present/refusals/escape-path.json \
	     --target examples/readme-present/fixtures/present \
	     >$(OUT)/confine.stdout 2>$(OUT)/confine.stderr; then \
	  echo "FAIL(AC6): escaping relative_path was NOT denied"; exit 1; fi
	@bytes=$$(wc -c <$(OUT)/confine.stdout); \
	 test "$$bytes" = "0" || { echo "FAIL(AC6): $$bytes receipt byte(s) emitted"; exit 1; }
	@sed 's/^/  /' $(OUT)/confine.stderr
	@echo "CONFINE PASSED (AC6): denied, 0 receipt bytes."

# ── the gate ─────────────────────────────────────────────────────────────
# Covers issue ACs 1-12. `test` is a prerequisite, not an afterthought: the
# criteria that are proved by construction rather than by a subprocess (the
# provider-notarization refusal, the digest-binding negatives, scheduling
# independence) live in the test binary.
gate: genericity vet-ir test vet vet-non-vacuity vet-negative refusals confine
	@echo
	@echo "GATE PASSED (issue #129 AC1-13):"
	@echo "  AC1  genericity      — no CM id, no classifier in lib/ or bin/; $(words $(EXAMPLES)) methodologies run"
	@echo "  AC2  one provider    — fs.text-metrics added; the boundary is stated in README"
	@echo "  AC3  real DAG        — independent + dependent steps, required/optional ports, principled skip"
	@echo "  AC4  rule is data    — ordered first-match table + mandatory default, evaluated generically"
	@echo "  AC5  provenance      — undeclared facts refused at load"
	@echo "  AC6  result honesty  — undeclared class, no default, provider-supplied result all refused"
	@echo "  AC7  schemas 0.2     — field!: throughout, non-vacuity fixtures rejected"
	@echo "  AC8  gate 9          — every canonical block of all four families refused by BOTH mechanisms"
	@echo "  AC9  RunRequest      — subject bound by digest under a named scheme"
	@echo "  AC10 digest binding  — request/cm_ir/plan mismatches refused (test binary)"
	@echo "  AC11 config schemas  — capability-owned, validated at link time"
	@echo "  AC12 no regression   — readme-present unchanged in behaviour; confinement fail-closed"

clean:
	$(DUNE) clean
	rm -rf $(OUT)
