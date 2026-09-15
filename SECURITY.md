# Security Policy

`codegouvaor/actions` is the official CI support of the CodeGouvAOR ecosystem:
supply-chain and code security matter.

## Reporting a vulnerability

**Do not open a public issue** for security vulnerabilities. Report them
privately to the maintainers:

-   Open a private advisory on GitHub:
    https://github.com/codegouvaor/actions/security/advisories/new

You should receive an acknowledgment within 72 hours. We ask that you do not
disclose the issue publicly until a fix is released (or until 90 days have
passed without a response).

## What we look for

-   insecure use of third-party actions or secrets;
-   workflows that can be abused from untrusted pull requests;
-   implicit publishing or over-broad permissions;
-   secrets accidentally committed to the repository.

## Supported versions

| Version | Supported |
| ------- | --------- |
| v1 (current major) | ✅ |

The latest major version receives security fixes.

## Supply-chain measures

-   Third-party actions are limited, pinned to explicit major versions and
    audited (see [docs/security.md](docs/security.md)).
-   Reusable workflows run with minimal permissions and never publish
    implicitly.
-   No secrets or tokens are committed.
-   Dependabot keeps GitHub Actions up to date (`.github/dependabot.yml`).
-   The repository validates itself in CI (`actionlint`, script tests and a
    self-hosted `government.yml` run).