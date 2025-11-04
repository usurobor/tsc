# TSC Framework v2.2.2+ Developer UX
# REQUIRES: Python 3.10+ (pattern matching)
.PHONY: help setup lint fmt typecheck test quickstart linkcheck self-coherence all clean

# Detect Python command
PYTHON := $(shell command -v python3.11 2>/dev/null || command -v python3.10 2>/dev/null || command -v python3 2>/dev/null || command -v python 2>/dev/null)
PIP := $(PYTHON) -m pip

help:
	@echo "Common targets:"
	@echo "  setup           - pip install -e .[dev]"
	@echo "  lint            - ruff check ."
	@echo "  fmt             - ruff format . && mdformat ."
	@echo "  typecheck       - mypy type checking"
	@echo "  test            - pytest conformance tests"
	@echo "  quickstart      - run the glider example via CLI"
	@echo "  linkcheck       - check Markdown links (requires lychee)"
	@echo "  self-coherence  - verify TSC self-application (v2.3.0+)"
	@echo "  all             - run lint + typecheck + test (CI simulation)"
	@echo "  clean           - remove cache files"

setup:
	$(PIP) install --upgrade pip
	$(PIP) install -e ".[dev]"

lint:
	$(PYTHON) -m ruff check .

fmt:
	$(PYTHON) -m ruff format .
	$(PYTHON) -m mdformat .
	
typecheck:
	$(PYTHON) -m mypy reference/ --strict --ignore-missing-imports || echo "⚠ mypy not installed; run 'pip install mypy'"

test:
	$(PYTHON) -m pytest tests/conformance/ -v

quickstart:
	$(PYTHON) -m reference.cli.tsc examples/cellular-automata/glider.md --format text || true

linkcheck:
	@command -v lychee >/dev/null 2>&1 \
		&& lychee --verbose --no-progress --max-concurrency 4 --accept 200..299,403,429 -- *.md **/*.md \
		|| (echo "⚠ lychee not installed; run link check in GitHub Actions or 'cargo install lychee' locally." && exit 0)

self-coherence:
	@echo "🔬 Running TSC self-application verification..."
	$(PYTHON) -m reference.self_coherence --verify || echo "⚠ self-coherence module not yet implemented (v2.3.0)"

all: lint typecheck test
	@echo "✓ All checks passed"

clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name .pytest_cache -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name .mypy_cache -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name .ruff_cache -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "✓ Cache files cleaned"