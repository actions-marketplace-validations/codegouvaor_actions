# government.yml — CodeGouvAOR Government CI

The main workflow of `codegouvaor/actions`. It gives any repository a standard,
maintained validation with a single line:

```yaml
name: Government CI

on:
  push:
  pull_request:

permissions:
  contents: read

jobs:
  government:
    uses: codegouvaor/actions/.github/workflows/government.yml@v1
```

## What it does

The workflow detects the project type, then runs every applicable validation:

| Job | Runs when | What it does |
| --- | --- | --- |
| `validate` | always | Repository structure check (README, license) + project type detection |
| `node` | a Node.js project | delegates to `node.yml` (lint, typecheck, test, build) |
| `go` | a Go project | delegates to `go.yml` (`go vet`, `go test`, `go build`) |
| `docker` | a Docker project | delegates to `docker.yml` (build-only, never publishes) |
| `ads` | `@codegouvaor/react-ads` is used | `ads-check` light integration validation |
| `audit` | `dependency-audit: true` | dependency vulnerability audit |

Detection is transparent and only looks at files at the root of the
`working-directory`:

```text
package.json       → Node.js
pnpm-lock.yaml     → pnpm
package-lock.json  → npm
yarn.lock          → yarn
go.mod             → Go
Dockerfile         → Docker
```

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `project-type` | `auto` | Force detection: `auto`, `node`, `go`, `docker`, `none` |
| `working-directory` | `.` | Directory containing the project |
| `node-version` | `22` | Node.js version for the Node validation |
| `pnpm-version` | `10` | pnpm version for the Node validation |
| `go-version` | *(empty)* | Go version (empty = read from `go.mod`) |
| `run-repository-checks` | `true` | Run README / license / secret checks |
| `readme-required` | `true` | Fail when no README is present |
| `license-required` | `true` | Fail when no license is present |
| `secret-scan` | `true` | Scan tracked files for exposed secrets |
| `fail-on-secret` | `true` | Fail when the secret scan reports a match |
| `dependency-audit` | `false` | Run a dependency vulnerability audit (opt-in) |
| `audit-level` | `high` | Minimum severity that fails a Node audit |
| `ads-check` | `auto` | react-ads check: `auto`, `on`, `off` |

## Example with explicit project type

```yaml
jobs:
  government:
    uses: codegouvaor/actions/.github/workflows/government.yml@v1
    with:
      project-type: node
      node-version: "22"
      working-directory: "."
```

## Example with the dependency audit enabled

```yaml
jobs:
  government:
    uses: codegouvaor/actions/.github/workflows/government.yml@v1
    with:
      dependency-audit: true
      audit-level: high
```

## Permissions required

Only `contents: read`. The workflow requests nothing else and passes no secrets
to its sub-workflows. Publish is never part of `government.yml`.

## Notes

- `government.yml` never publishes artifacts or images.
- Secret scanning is regex-based and restricted to high-confidence patterns. It
  is a first line of defence, not a substitute for a dedicated scanner (see
  `docs/security.md`).
- The `dependency-audit` needs the relevant toolchain (`pnpm`/`npm` or `go`),
  which the `audit` job installs automatically.