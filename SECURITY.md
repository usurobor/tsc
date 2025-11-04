# Security Policy

## Supported Versions

We release security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 2.1.x   | :white_check_mark: |
| 2.0.x   | :white_check_mark: |
| < 2.0   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to:

**usurobor@gmail.com** with `[SECURITY]` in the subject line.

### What to include

Please include the following information:

- Type of vulnerability (e.g., buffer overflow, injection, authentication bypass)
- Full paths of source file(s) related to the vulnerability
- Location of the affected source code (tag/branch/commit or direct URL)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### Response Timeline

- **Acknowledgment**: Within 72 hours of report
- **Initial assessment**: Within 7 days
- **Fix timeline**: Depends on severity
  - Critical: Patched within 7 days
  - High: Patched within 30 days
  - Medium/Low: Patched in next regular release

### Disclosure Policy

We follow coordinated vulnerability disclosure:

1. You report the vulnerability privately
1. We confirm the issue and determine severity
1. We develop and test a fix
1. We release a security advisory and patched version
1. Public disclosure occurs after users have had time to upgrade (typically 7-14 days after patch release)

### Recognition

We maintain a security acknowledgments section in our release notes. If you'd like to be credited, please let us know your preferred name/handle.

## Security Best Practices for Users

When using TSC:

1. **Keep dependencies updated**: Run `pip install --upgrade tsc-framework` regularly
1. **Validate input files**: TSC parsers execute file I/O; only parse files from trusted sources
1. **Sandbox execution**: When parsing untrusted data, run TSC in isolated environments
1. **Review parser code**: Custom parsers execute arbitrary Python; audit third-party parsers before use

## Known Security Considerations

### Parser Execution

TSC parsers are Python functions that read files. Malicious markdown files could potentially:

- Consume excessive memory (large grid patterns)
- Cause long processing times (many frames)

**Mitigation**: Set timeouts and memory limits when processing untrusted files.

### No Network Access

The reference implementation does not make network requests. If you add custom parsers that fetch remote data, ensure proper validation and authentication.

## Security Updates

Security advisories are published at:

- GitHub Security Advisories: https://github.com/usurobor/tsc/security/advisories
- CHANGELOG.md (with `[SECURITY]` tag)

## Questions?

For general security questions (not vulnerability reports), open a public issue with the `security` label.
