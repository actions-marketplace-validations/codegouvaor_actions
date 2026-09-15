# CodeGouvAOR Government Check

Official CodeGouvAOR GitHub Action that validates a repository against the
CodeGouvAOR repository and government standards.

It is a [composite action](https://docs.github.com/en/actions/creating-actions/about-custom-actions):
fast, portable, dependency-free (git, find and grep only) and tailored to
GitHub-hosted runners. It can be used standalone or as part of the
[`government.yml` reusable workflow](../../docs/workflows/government.md).

> **Marketplace.** This action is published to the GitHub Marketplace from the
> root [`action.yml`](../../action.yml). This directory
> (`actions/government-check/`) is the single source of implementation; the root
> manifest only forwards inputs/outputs to it. Both resolve to the same `@v1`
> tag.

## Overview

The action runs a deterministic set of checks against a checked out repository:

- **Documentation & license** — README and license presence.
- **Repository structure** — `.gitignore`, `.github/CODEOWNERS`.
- **Official metadata** — `publiccode.yml` (optional).
- **GitHub configuration** — `.github/dependabot.yml` (optional).
- **Minimal metadata** — `name`/`version` in `package.json`, `module` in `go.mod`.
- **Problematic files** — tracked `.env`, unusually large tracked files.
- **Exposed secrets** — scan of tracked files for high-confidence secret patterns.
- **Project type detection** — Node.js / Go / Docker, for the workflow consumers.
- **Dependency audit** *(optional)* — vulnerability audit when enabled.

Every rule is documented and configurable; nothing is invented just to inflate
the check count.

## Usage

Directly copyable example:

```yaml
name: CodeGouvAOR Check

on:
  push:
  pull_request:

permissions:
  contents: read

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: codegouvaor/actions/government-check@v1
```

With inputs:

```yaml
      - uses: codegouvaor/actions/government-check@v1
        with:
          working-directory: "."
          project-type: auto
          readme-required: true
          license-required: true
          secret-scan: true
```

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `working-directory` | `.` | Directory to inspect, relative to the repository root |
| `project-type` | `auto` | Force detection: `auto`, `node`, `go`, `docker`, `none` |
| `readme-required` | `true` | Fail when no README is found |
| `license-required` | `true` | Fail when no license is found |
| `gitignore-required` | `false` | Fail when no `.gitignore` is found |
| `codeowners-required` | `false` | Fail when no CODEOWNERS is found |
| `publiccode-required` | `false` | Fail when no `publiccode.yml` is found |
| `dependabot-required` | `false` | Fail when no `.github/dependabot.yml` is found |
| `secret-scan` | `true` | Scan tracked files for secret patterns |
| `fail-on-secret` | `true` | Fail when the scan reports a match |
| `fail-on-warning` | `false` | Also fail when warnings are reported |
| `max-file-size-mb` | `10` | Warn for tracked files larger than this size |
| `dependency-audit` | `false` | Run a dependency vulnerability audit |
| `audit-level` | `high` | Minimum severity that fails a Node audit |
| `exclude` | *(empty)* | Extra paths excluded from the secret scan (one per line) |

## Outputs

| Output | Description |
| --- | --- |
| `status` | `pass` when all checks passed, `fail` otherwise |
| `errors` | Number of failed checks |
| `warnings` | Number of warnings reported |
| `checks-passed` | Number of checks that passed |
| `has-readme` | `true` when a README exists |
| `has-license` | `true` when a license exists |
| `has-gitignore` | `true` when a `.gitignore` exists |
| `has-codeowners` | `true` when a CODEOWNERS exists |
| `has-publiccode` | `true` when a `publiccode.yml` exists |
| `secrets-found` | `true` when the secret scan reported a match |
| `project-type` | `node`, `go`, `docker`, `mixed` or `none` |
| `detected-types` | Comma-separated list, e.g. `node,docker` |
| `is-node` / `is-go` / `is-docker` | `true` when that project validation applies |
| `package-manager` | `pnpm`, `npm` or `yarn` |
| `uses-react-ads` | `true` when `@codegouvaor/react-ads` is a dependency |

## Checks

The full list of checks actually performed:

1. **README** present (case-insensitive: `README.md`, `README`, `readme.md`, …).
2. **LICENSE** present (`LICENSE`, `LICENSE.md`, `LICENSE-MIT`, `COPYING`, …).
3. **.gitignore** present (warning by default).
4. **CODEOWNERS** present (`.github/CODEOWNERS`, `CODEOWNERS` or `docs/CODEOWNERS`).
5. **publiccode.yml** present (warning by default).
6. **.github/dependabot.yml** present (warning by default).
7. `package.json` declares `name` and `version` (warnings).
8. `go.mod` declares a `module` (warning).
9. No tracked `.env` file (excluding `.env.example`, `.env.sample`, `.env.template`).
10. No unusually large tracked files (warning, `max-file-size-mb`).
11. Secret scan across tracked files (high-confidence patterns only).

Checks 1–6, 9 and 11 can fail the step (configurable); the others are warnings.
Set `fail-on-warning: true` to turn warnings into failures.

## Failure behavior

- The action **fails** when any required check fails: a required file is
  missing, the secret scan reports a match (with `fail-on-secret`), or
  `fail-on-warning` is enabled and warnings exist.
- When it fails, the job step is marked failed; a detailed report is written to
  the job summary (`GITHUB_STEP_SUMMARY`) and individual issues are annotated
  with `::error::` / `::warning::`.
- `status` is `fail` and the step exits non-zero on failure, `pass` otherwise.

## Versioning

Use the moving major tag `@v1`:

```yaml
- uses: codegouvaor/actions/government-check@v1
```

`v1` is the stable contract of the first generation. Compatible fixes and
improvements are released within `v1`; breaking changes go to `v2`. Never depend
on `main`. See [docs/versioning.md](../../docs/versioning.md).

## Security

- Runs with the permissions of the calling workflow; it needs no special
  permissions beyond `contents: read`.
- Reads repository content only and never executes untrusted code.
- Safe to use on pull requests; it never uses `pull_request_target`.

## License

MIT. See [LICENSE](../../LICENSE).