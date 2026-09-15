# Security Policy

`@codegouvaor/react-ads` is an official library of the digital ecosystem of the Republic of
Astoria: supply-chain and code security matter.

## Reporting a vulnerability

**Do not open a public issue** for security vulnerabilities. Report them privately to the
maintainers:

-   Open a private advisory on GitHub:
    https://github.com/codegouvaor/react-ads/security/advisories/new
-   If the issue is critical and GitHub is not suitable, contact the maintainers through the
    `codegouvaor` organization.

You should receive an acknowledgment within 72 hours. We ask that you do not disclose the
issue publicly until a fix is released (or until 90 days have passed without a response).

## What we look for

-   XSS / injection through component props or rendered content;
-   unsafe use of `dangerouslySetInnerHTML`, nonce/CSP bypass, trusted-types issues;
-   dependency vulnerabilities (see below);
-   secrets accidentally committed to the repository.

## Supported versions

| Version              | Supported |
| -------------------- | --------- |
| 0.1.x (current line) | ✅        |

Once the project reaches 1.0.0, the latest minor of the current major will receive security
fixes.

## Supply-chain measures

-   The lockfile (`pnpm-lock.yaml`) is committed and CI verifies it (`pnpm install
--frozen-lockfile`).
-   CI runs `pnpm audit` on pull requests and before release.
-   Dependencies are kept minimal and are audited before addition.
-   Dependabot keeps dependencies up to date (`.github/dependabot.yml`).
-   No secrets or tokens are committed. Publish credentials live in GitHub secrets and npm
    releases are published with provenance when possible.
-   Release artifacts are built and published by the CI pipeline, not from local machines.
