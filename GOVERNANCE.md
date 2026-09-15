# Governance

This document describes how `@codegouvaor/react-ads` is run. It is a living document: as
the Astoria digital services structure the official governance of the Astoria Design System,
this page will be updated to match.

## Vision

ADS React is the official React implementation of the Astoria Design System — the reference
design system for the digital ecosystem of the Republic of Astoria. It is:

-   **open source** (MIT) and developed in the open;
-   **independent** — progressively decoupled from its react-dsfr origins
    (see [MIGRATION.md](MIGRATION.md));
-   **accessible** — WCAG 2.2 AA is a design constraint, not an afterthought;
-   **stable** — semantic versioning, no gratuitous breaking changes.

## Roles

-   **Project maintainers** — the people with write access to
    `github.com/codegouvaor/react-ads`. They review and merge pull requests, cut releases and
    steward the roadmap. Today the maintainers are the members of the `codegouvaor`
    organization; the list will be published here as the project formalizes.
-   **Contributors** — anyone opening issues or pull requests. See
    [CONTRIBUTING.md](CONTRIBUTING.md).
-   **Design owners (Astoria)** — the brand/design authority of the Republic of Astoria.
    They own the official tokens and identity assets; the codebase must never invent or
    freeze identity values without them (see MIGRATION.md Stage 4).

## Decision making

-   Day-to-day decisions happen in issues and pull requests.
-   Public API changes, dependency policy changes, and migration milestones are announced
    through issues and discussed before implementation.
-   The official identity (tokens, assets) is **not** decided inside this repository.

## Release process

-   Releases follow [Semantic Versioning](https://semver.org), starting at `0.1.0`.
-   Cutting a release is the responsibility of the maintainers, from the `main` branch.
-   The automated pipeline (`.github/workflows/ci.yaml`) runs: formatting → lint → build →
    tests → package validation, then publishes to npm on version bump.
-   npm releases are published with provenance when the registry allows it.
-   Changes are recorded in [CHANGELOG.md](CHANGELOG.md).

## Code of conduct

Be respectful, constructive and inclusive. Harassment and discrimination of any kind are
not tolerated. Reports go to the maintainers through the issue tracker or, for sensitive
matters, through the security process ([SECURITY.md](SECURITY.md)).

## License and provenance

MIT. This project originates from a fork of `codegouvfr/react-dsfr` — see
[PROVENANCE.md](PROVENANCE.md) for the honest account and attribution obligations.
