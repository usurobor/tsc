# Contributing to TSC (Triadic Self-Coherence)

This guide explains how to propose changes to TSC.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Support Matrix](#support-matrix)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Submitting Changes](#submitting-changes)
- [Security](#security)
- [License](#license)

## Code of Conduct

Participation is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By contributing, you agree to uphold it.

## Support Matrix

- **OCaml**: 5.1+
- **OS**: Linux, macOS (Windows via WSL)
- **Package manager**: opam
- **Build system**: dune ≥ 3.0
- **Tooling**: ocamlformat, dune runtest

## How Can I Contribute?

### Reporting Bugs

- Search existing [Issues](https://github.com/usurobor/tsc/issues) first
- Include: steps to reproduce, expected vs actual behavior, environment (OS, OCaml/opam version), and a minimal reproducible example

### Suggesting Enhancements

- Explain the use case, proposed behavior, and who benefits
- Link to prior art if helpful

### Contributing Code

We welcome:

- Bug fixes
- Conformance fixtures (positive and negative cases)
- Performance improvements
- Documentation & examples
- Test coverage improvements

## Development Setup

1. **Fork & clone**

```bash
   git clone https://github.com/usurobor/tsc.git
   cd tsc
```

2. **Install OCaml dependencies**

```bash
   cd src/engine/ocaml
   opam install . --deps-only --with-test
```

3. **Build & run tests**

```bash
   dune build
   dune runtest
   dune fmt        # format sources
```

## Coding Standards

### OCaml Style

- Follow standard OCaml conventions; use `ocamlformat` (run `dune fmt`)
- Prefer pure functions and immutable data
- Keep modules small and focused; provide `.mli` interface files for public surfaces

### Type Signatures

```ocaml
(* Good — explicit, narrow signature in .mli *)
val parse_file : path:string -> seed:int option -> parsed_input

(* Avoid — implicit, no .mli *)
let parse_file path seed = ...
```

### Documentation

- Document public functions in `.mli` files using `(** ... *)`
- Add inline comments for non-obvious logic
- Use `odoc`-compatible markup where applicable

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

1. Ensure tests pass: `dune runtest`
1. Format code: `dune fmt`
1. Verify build: `dune build`
1. Update `CHANGELOG.md` for significant changes
1. Push to your fork
1. Create PR with clear description

**PR Requirements:**

- [ ] All tests pass (`dune runtest`)
- [ ] Code is formatted (`dune fmt`)
- [ ] New features have tests
- [ ] Documentation updated (if applicable)
- [ ] CI is green
- [ ] At least one maintainer approval

**Merge policy:** Squash merges by default

## Security

**Do not** file security issues publicly. Email peter@lisovin.com with "[SECURITY]" in subject line. We'll respond within 72 hours.

## License

TSC is licensed under [CC BY 4.0](LICENSE). By contributing, you agree your contributions are licensed under the same terms.

## Questions?

- Open an issue with the `question` label
- Email: peter@lisovin.com
