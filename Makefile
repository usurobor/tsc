# TSC Engine — OCaml
# REQUIRES: opam, dune, OCaml >= 4.14
.PHONY: help setup build test clean measure linkcheck

ENGINE := engine/ocaml

help:
	@echo "Targets:"
	@echo "  setup       - opam install dependencies"
	@echo "  build       - dune build"
	@echo "  test        - dune runtest"
	@echo "  measure     - run TSC self-measurement (requires LLM_PROVIDER, LLM_MODEL, LLM_API_KEY)"
	@echo "  linkcheck   - check Markdown links (requires lychee)"
	@echo "  clean       - dune clean"

setup:
	cd $(ENGINE) && opam install . --deps-only --with-test -y

build:
	cd $(ENGINE) && dune build

test:
	cd $(ENGINE) && dune runtest

measure:
	@test -n "$$LLM_API_KEY" || (echo "error: LLM_API_KEY not set" && exit 1)
	mkdir -p .tsc
	cd $(ENGINE) && dune exec -- coh \
		--target repo \
		--registry ../../targets/registry.tsc \
		--instruction ../../runtime/SELF-MEASURE.md \
		--output ../../.tsc/repo-report.json

linkcheck:
	@command -v lychee >/dev/null 2>&1 \
		&& lychee --verbose --no-progress --max-concurrency 4 --accept 200..299,403,429 -- *.md **/*.md \
		|| echo "lychee not installed; run 'cargo install lychee' or use GitHub Actions."

clean:
	cd $(ENGINE) && dune clean
