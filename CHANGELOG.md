# Changelog

All notable changes to `codegouvaor/actions` are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org).

## [Unreleased]

### Added

- Initial V1 of the CodeGouvAOR GitHub Actions:
  - reusable workflows `government.yml`, `node.yml`, `go.yml`, `docker.yml`;
  - composite actions `repository-check`, `government-check`, `ads-check`;
  - documentation (`README.md`, `docs/`), versioning and security policy;
  - self-validation CI and unit tests.
- `government-check` is now the official, Marketplace-ready CodeGouvAOR
  Government Check action: documentation/license checks, repository structure,
  GitHub configuration, minimal metadata, problematic files, secret scanning,
  project type detection and an optional dependency audit, with documented and
  configurable checks and outputs.
- Added the root `action.yml` required for GitHub Marketplace detection, plus a
  `marketplace` CI job that detects and validates Marketplace readiness.

See the initial commit for details. No public release has been cut yet; the
`@v1` tag will point to the first release.