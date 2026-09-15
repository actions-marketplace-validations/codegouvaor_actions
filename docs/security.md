# Security

Security is treated as part of the product, not an afterthought. This document
summarises the security posture of `codegouvaor/actions` and how to consume it
safely.

## Minimal permissions

Every reusable workflow runs with the **minimum required permissions**:

| Workflow | Permissions |
| --- | --- |
| `government.yml` | `contents: read` |
| `node.yml` | `contents: read` |
| `go.yml` | `contents: read` |
| `docker.yml` | `contents: read`, plus `packages: write` (only needed to publish) |

`GITHUB_TOKEN` is scoped down accordingly and never used unless a publish is
explicitly requested (`push: true` in `docker.yml`).

## No implicit publishing

`docker.yml` publishes only when `push: true`. A repository using the workflow
purely to validate its Dockerfile never receives registry credentials and never
requires `packages: write`.

## Third-party actions

The set is deliberately small, pinned to explicit major versions, and audited:

| Action | Why |
| --- | --- |
| `actions/checkout` | standard checkout |
| `actions/setup-node`, `actions/setup-go` | official language toolchains |
| `pnpm/action-setup` | official pnpm setup |
| `docker/setup-buildx-action`, `docker/login-action`, `docker/build-push-action`, `docker/metadata-action` | official Docker toolchain |

Pin your own calls to `@v1` (the moving major tag) or, for maximum supply-chain
hardening, to a full commit SHA.

## Handling pull requests

- Reusable workflows run in the **caller's** repository context and only read
  content. `government.yml`, `node.yml` and `go.yml` require `contents: read`
  and do not execute untrusted content.
- **`pull_request_target` is never used.**
- Secret scanning in `government.yml` runs against the checkout and is
  regex-based; it is a first line of defence, not a substitute for a dedicated
  secret scanner.

## What the secret scan covers

`government.yml`, the `government-check` action and the `repository-check`
action scan tracked files for high-confidence
patterns (AWS access keys, GitHub tokens, private keys, Slack/Stripe/npm tokens,
Google API keys, …). It is intentionally conservative to keep the
false-positive rate low enough to fail on. For deeper coverage use a dedicated
scanner (e.g. GitLeaks or TruffleHog) in addition.

## Reporting a vulnerability

See [`SECURITY.md`](../SECURITY.md). Do **not** open a public issue.

## Consuming repositories

- Grant only the permissions a workflow actually needs (see the table above).
- Never grant `packages: write` to `government.yml` / `node.yml` / `go.yml`.
- Keep secrets out of the caller workflow; pass only what is required.