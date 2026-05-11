## Description

<!-- Provide a clear description of what this PR does -->

Fixes #(issue)

## Type of Change

<!-- Mark the relevant option with an "x" -->

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that causes existing functionality to change)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring
- [ ] Test coverage improvement

## Changes Made

<!-- List the key changes -->

-
-
-

## Testing

<!-- Describe how you tested these changes -->

**Test commands run:**

```bash
dune build
dune runtest
dune fmt
```

**New tests added:**

- [ ] Yes
- [ ] No (explain why not)
- [ ] N/A

**Manual testing performed:**

<!-- Describe any manual testing, especially for new parsers -->

## Checklist

<!-- Mark completed items with an "x" -->

- [ ] My code follows the project's coding standards
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings or errors
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes (`dune runtest`)
- [ ] Any dependent changes have been merged and published
- [ ] I have updated CHANGELOG.md (if this is a significant change)

## For New Parsers

<!-- Complete this section if adding a new parser -->

- [ ] Added parser module under `engine/ocaml/lib/parsers/`
- [ ] Implemented both predicate (`is_X`) and parser function
- [ ] Registered in the parsers dispatch module
- [ ] Added example file in `examples/`
- [ ] Added conformance test in `tests/ocaml/conformance/`
- [ ] Updated QUICKSTART.md or relevant docs
- [ ] Parser handles errors gracefully (fallback to stub if needed)
- [ ] Parser is deterministic given same seed

## Breaking Changes

<!-- If this is a breaking change, describe: -->

<!-- 1. What breaks -->

<!-- 2. Migration path for users -->

<!-- 3. Why this change is necessary -->

## Screenshots (if applicable)

<!-- Add screenshots for UI changes or CLI output changes -->

## Additional Context

<!-- Add any other context about the PR here -->

## Reviewer Notes

<!-- Anything specific reviewers should focus on? -->
