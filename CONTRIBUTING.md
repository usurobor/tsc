# Contributing to TSC (Triadic Self-Coherence)

Thanks for your interest in contributing! This guide explains how to propose changes and what we expect.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Support Matrix](#support-matrix)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Submitting Changes](#submitting-changes)
- [Adding a New Parser](#adding-a-new-parser)
- [Security](#security)
- [License](#license)

## Code of Conduct

Participation is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By contributing, you agree to uphold it.

## Support Matrix

- **Python**: 3.10, 3.11, 3.12
- **OS**: Linux, macOS, Windows
- **Package manager**: pip (editable installs supported)
- **Tooling**: ruff ≥ 0.6, pytest ≥ 7.0

## How Can I Contribute?

### Reporting Bugs

- Search existing [Issues](https://github.com/usurobor/tsc/issues) first
- Include: steps to reproduce, expected vs actual behavior, environment (OS, Python version), and a minimal reproducible example

### Suggesting Enhancements

- Explain the use case and proposed behavior
- Why would this benefit most users?
- Link to prior art if helpful

### Contributing Code

We welcome:

- Bug fixes
- New parsers for additional data formats
- Performance improvements
- Documentation & examples
- Test coverage improvements

## Development Setup

1. **Fork & clone**

```bash
   git clone https://github.com/usurobor/tsc.git
   cd tsc
```

2. **Install dev dependencies**

```bash
   python3 -m pip install --upgrade pip
   pip install -e ".[dev]"
```

3. **Run tests & linters**

```bash
   pytest
   make lint    # or: ruff check .
   make fmt     # or: ruff format .
```

**No-make fallbacks (all platforms):**

```bash
ruff format .
ruff check .
pytest
```

## Coding Standards

### Python Style

- Follow PEP 8
- Use Python 3.10+ type hints: `X | None` instead of `Optional[X]`
- Maximum line length: 100 characters
- Use `ruff` for linting and formatting

### Code Organization

- **Functional style preferred**: pure functions, immutable data structures
- Use `@dataclass(frozen=True)` for immutable data
- Keep functions small and focused
- Avoid classes unless necessary

### Type Hints

```python
# Good
def parse_file(path: str, seed: int | None = None) -> ParsedInput:
    ...

# Avoid
def parse_file(path, seed=None):
    ...
```

### Docstrings

- Document all public functions
- Use NumPy-style docstrings for complex functions
- Add inline comments for non-obvious logic

## Submitting Changes

### Branching

```bash
git checkout -b feat/your-feature-name
# or: fix/bug-name, docs/topic, test/area
```

### Commit Messages (Conventional Commits)

```text
feat: add time-series parser
fix: correct temporal coherence calculation
docs: update QUICKSTART with new examples
test: add conformance test for audio data
```

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `chore`

Use `BREAKING CHANGE:` in commit footer for breaking API changes.

### Pull Request Process

1. Ensure tests pass: `pytest`
1. Run linting: `ruff check .`
1. Format code: `ruff format .`
1. Update `CHANGELOG.md` for significant changes
1. Push to your fork
1. Create PR with clear description

**PR Requirements:**

- [ ] All tests pass
- [ ] Code is linted and formatted
- [ ] New features have tests
- [ ] Documentation updated (if applicable)
- [ ] CI is green
- [ ] At least one maintainer approval

**Merge policy:** Squash merges by default

## Adding a New Parser

See [QUICKSTART.md](QUICKSTART.md#5-add-support-for-your-data-format) for full guide.

**Quick checklist:**

1. Create `reference/python/parsers/your_format.py`
1. Implement:
   - `is_your_format(path: str) -> bool` (predicate)
   - `your_format_parser(path: str, seed: int | None) -> ParsedInput` (parser)
1. Register in `reference/python/parsers/__init__.py`
1. Add example: `examples/your_format/`
1. Add test: `tests/conformance/`
1. Update docs

**Parser requirements:**

- Pure function (file I/O allowed)
- Returns valid `ParsedInput`
- Deterministic given `seed`
- Graceful error handling
- Full type hints + docstring

## Security

**Do not** file security issues publicly. Email peter@lisovin.com with "[SECURITY]" in subject line. We'll respond within 72 hours.

## License

- **Code** (`reference/`, `tests/`): Apache-2.0
- **Specifications** (`spec/`): CC BY 4.0
- **Examples** (`examples/`): CC0 (Public Domain)

By contributing, you agree your contributions are licensed under the same terms as the project files you're modifying.

See [LICENSE](LICENSE) for full text.

## Questions?

- Open an issue with the `question` label
- Email: peter@lisovin.com
- Check existing issues first

Thank you for contributing to TSC! 🎉
