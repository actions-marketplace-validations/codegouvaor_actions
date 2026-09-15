# Governance

This document describes how `codegouvaor/actions` is run. It is a living
document.

## Vision

`codegouvaor/actions` is the official GitHub Actions support for the CodeGouvAOR
ecosystem. It is:

-   **open source** (MIT) and developed in the open;
-   **stable** — consumed as a public CI API via a moving major tag (`@v1`);
-   **secure by default** — minimal permissions, no implicit publishing;
-   **simple** — small, maintainable workflows and actions, no over-engineering.

## Roles

-   **Project maintainers** — people with write access to
    `github.com/codegouvaor/actions`. They review and merge pull requests, cut
    releases and steward the roadmap. Today the maintainers are the members of
    the `codegouvaor` organization.
-   **Contributors** — anyone opening issues or pull requests. See
    [CONTRIBUTING.md](CONTRIBUTING.md).

## Decision making

-   Day-to-day decisions happen in issues and pull requests.
-   Public API changes (workflow inputs, breaking behaviour) and the versioning
    policy are discussed before implementation.
-   The responsibility boundary with `@codegouvaor/react-ads` and the future
    `github-app` must be respected: this repository does not implement project
    business logic.

## Release process

-   Releases follow [Semantic Versioning](https://semver.org) (`v1.0.0`…).
-   Cutting a release is the responsibility of the maintainers, from `main`.
-   Pushing a tag `v<major>.<minor>.<patch>` moves the corresponding major tag
    (`v1`) via `.github/workflows/release.yml` and opens a GitHub Release.
-   Consumers depend on the moving major tag; see
    [docs/versioning.md](docs/versioning.md).
-   Changes are recorded in [CHANGELOG.md](CHANGELOG.md).

## Code of conduct

Be respectful, constructive and inclusive. Harassment and discrimination of any
kind are not tolerated. Reports go to the maintainers through the issue tracker
or, for sensitive matters, through the security process
([SECURITY.md](SECURITY.md)).

## License

MIT. See [LICENSE](LICENSE).