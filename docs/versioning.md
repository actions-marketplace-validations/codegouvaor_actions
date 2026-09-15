# Versioning policy

`codegouvaor/actions` is consumed as a **public CI API**. The public contract is
the *workflow reference*, not the implementation:

```yaml
uses: codegouvaor/actions/.github/workflows/government.yml@v1
```

## The contract

The reference `@v1` (and `@v2`, `@v3`, …) is a **moving major-version tag**. It
always points to the latest release of that major version. Consumers who write
`@v1` therefore get every compatible improvement automatically.

```text
v1
├── corrections compatibles        (bug fixes)
├── améliorations compatibles      (new inputs, additive changes)
└── évolutions non cassantes       (non-breaking additions)

v2
└── changements incompatibles      (breaking changes)
```

## Rules

- **Never** depend on `main` in a consuming repository. `main` has no stability
  guarantee.
- **Breaking changes** go to a new major (`v2`). This includes: renaming or
  removing an input, changing a default behaviour that can break a build, or
  removing a workflow / action.
- **Non-breaking changes** (new inputs with safe defaults, bug fixes, new
  optional steps) are released within the current major.
- Releases follow [Semantic Versioning](https://semver.org) (`v1.0.0`, `v1.1.0`,
  `v1.2.3`, …). Tagging `v1.2.3` moves the `v1` tag.

## How a release is made

Releases are handled by `.github/workflows/release.yml`, which keeps the moving
major tag in sync automatically. Two ways to publish:

1. **Push a tag** `v<major>.<minor>.<patch>` (e.g. `v1.1.0`) from `main`. The
   workflow moves the major tag (`v1`) to that commit and opens a GitHub Release.
2. **Publish a GitHub Release** from the UI (with a `v<major>.<minor>.<patch>`
   tag). The workflow detects the published tag and moves the major tag.

In both cases the released commit must already contain the changes merged to
`main`. Only clean `vX.Y.Z` versions move a major tag (prereleases such as
`v1.1.0-beta` do not update `@v1`).

## For contributors

- Open a PR targeting `main`.
- Additive inputs and steps are safe for the current major.
- If a change would break an existing consumer of `@v1`, it must be planned for
  `v2` and documented.

## Reference syntax notes

The workflows reference their own local actions and sub-workflows with GitHub's
**self-repository reference** syntax (`$/`), so internal references always
follow the exact tag/commit the caller pinned (e.g. `@v1`), with no manual
version bookkeeping. This is available on GitHub.com and requires a recent
Actions runner (auto-updated on GitHub-hosted runners).

See the [GitHub changelog](https://github.blog/changelog/2026-07-30-reference-same-repository-actions-with-self-repository-syntax/)
for details.