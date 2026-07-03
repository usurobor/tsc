# TSC Engine — OCaml
# REQUIRES: opam, dune, OCaml >= 4.14
.PHONY: help setup build test clean measure render validate-skills linkcheck

ENGINE := engine/ocaml

help:
	@echo "Targets:"
	@echo "  setup           - opam install dependencies"
	@echo "  build           - dune build"
	@echo "  test            - dune runtest"
	@echo "  measure         - TSC self-measurement (auto: hybrid with LLM_* credentials, mechanical without)"
	@echo "  render          - render skills/self-measure/SKILL.md into coh-self + workflow"
	@echo "  validate-skills - SKILL.md frontmatter + render byte-identity checks (requires cue, jq)"
	@echo "  linkcheck       - check Markdown links (requires lychee)"
	@echo "  clean           - dune clean"

setup:
	cd $(ENGINE) && opam install . --deps-only --with-test -y

build:
	cd $(ENGINE) && dune build

test:
	cd $(ENGINE) && dune runtest

# Self-measurement per skills/self-measure/SKILL.md — all targets +
# cross-target report into .tsc/self/. Mode auto: hybrid when LLM_*
# credentials are present, mechanical otherwise.
measure: build
	COH_BIN=$(ENGINE)/_build/default/bin/main.exe scripts/coh-self

render:
	scripts/render-self-measure.sh

validate-skills:
	scripts/ci/validate-skill-frontmatter.sh --self-test
	scripts/ci/validate-skill-frontmatter.sh
	scripts/render-self-measure.sh --check

linkcheck:
	@command -v lychee >/dev/null 2>&1 \
		&& lychee --verbose --no-progress --max-concurrency 4 --accept 200..299,403,429 -- *.md **/*.md \
		|| echo "lychee not installed; run 'cargo install lychee' or use GitHub Actions."

clean:
	cd $(ENGINE) && dune clean
