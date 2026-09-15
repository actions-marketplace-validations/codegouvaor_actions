# government-check

Composite action that detects the project type of a CodeGouvAOR repository and
optionally audits dependencies for known vulnerabilities.

Used internally by `government.yml` and available as a standalone reusable
validation.

## Usage — detection only

```yaml
- id: detect
  uses: codegouvaor/actions/actions/government-check@v1
  with:
    working-directory: "."
```

## Usage — with dependency audit

```yaml
- uses: codegouvaor/actions/actions/government-check@v1
  with:
    dependency-audit: true
    audit-level: high
```

The relevant toolchain (`pnpm`/`npm` for Node.js, `go` for Go) must already be
available on the runner.

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `working-directory` | `.` | Directory to inspect |
| `project-type` | `auto` | Force detection: `auto`, `node`, `go`, `docker`, `none` |
| `dependency-audit` | `false` | Run a dependency vulnerability audit |
| `audit-level` | `high` | Minimum severity that fails a Node audit |

## Outputs

| Output | Description |
| --- | --- |
| `project-type` | `node`, `go`, `docker`, `mixed` or `none` |
| `detected-types` | Comma-separated list, e.g. `node,docker` |
| `is-node` | `true` when the Node validation should run |
| `is-go` | `true` when the Go validation should run |
| `is-docker` | `true` when the Docker validation should run |
| `package-manager` | `pnpm`, `npm` or `yarn` |
| `uses-react-ads` | `true` when `@codegouvaor/react-ads` is a dependency |

## Detection logic

Files are inspected only at the root of `working-directory`:

```text
package.json       → Node.js
pnpm-lock.yaml     → pnpm
package-lock.json  → npm
yarn.lock          → yarn
go.mod             → Go
Dockerfile         → Docker
```

With `project-type: auto` every applicable type is enabled at once (so a
Node + Go + Docker repository runs all three validations). Forcing a type
(e.g. `node`) enables only that one.