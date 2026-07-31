# Security Policy

## Reporting a vulnerability

Do not report vulnerabilities through public GitHub issues. Email
peter@lisovin.com with `[SECURITY]` in the subject line. Include the affected
version or commit, steps to reproduce, and the impact.

We acknowledge reports within 72 hours and address confirmed issues by severity.

## Supported versions

TSC is pre-1.0 software. Security fixes target the latest release and `main`;
older versions are not back-patched.

## Scope notes

The `coh` engine is OCaml. In `mechanical` mode it does no network I/O. In
`llm` and `hybrid` modes it makes outbound HTTPS requests to the configured LLM
provider (`LLM_PROVIDER` / `LLM_MODEL` / `LLM_API_KEY`); protect those
credentials and review the provider you point it at. The engine reads the file
bundle it is given and writes reports under `.tsc/`.

## Advisories

Security advisories are published as
[GitHub Security Advisories](https://github.com/usurobor/tsc/security/advisories)
and noted in `CHANGELOG.md`.
