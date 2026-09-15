# CodeGouvAOR Actions

The official GitHub Actions for the CodeGouvAOR ecosystem.

`codegouvaor/actions` is a small set of **reusable workflows** and **composite
actions** that give every repository of the organization a standard, maintained
CI without re-implementing any logic. It is designed as a **public CI API**:
simple to consume, documented, versioned and stable.

```yaml
jobs:
  government:
    uses: codegouvaor/actions/.github/workflows/government.yml@v1
```

## Why it exists

Repositories under `codegouvaor` used to duplicate the same CI logic. This
repository centralises that logic so that:

- a project stays **extremely lightweight** (a few lines of YAML);
- validations are **coherent** and **maintained** in one place;
- security defaults are applied consistently;
- consumers never depend on `main`, only on stable versions (`@v1`).

This repository is independent of `@codegouvaor/react-ads` and of the future
`github-app`, and does not mix responsibilities with them.

## Quick start

Add the following file to your repository
(`.github/workflows/ci.yml`), replacing `<you>/<repo>` with your own project:

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

`government.yml` detects your project type automatically and runs the
appropriate validations (Node.js, Go, Docker, repository checks, …). See
[docs/workflows/government.md](docs/workflows/government.md).

## Combining several workflows

Repositories can stay minimal while composing several workflows:

```yaml
name: CI

on:
  push:
  pull_request:

permissions:
  contents: read

jobs:
  government:
    uses: codegouvaor/actions/.github/workflows/government.yml@v1

  docker:
    uses: codegouvaor/actions/.github/workflows/docker.yml@v1
```

## Reusable workflows

All workflows live in `.github/workflows/` and are called with `@v1`.

### government.yml — generic CodeGouvAOR validation

```yaml
jobs:
  government:
    uses: codegouvaor/actions/.github/workflows/government.yml@v1
    with:
      project-type: auto
```

Checks (when applicable): repository structure (README, license), project type
detection, build/test per detected type, secret scanning, and an optional
dependency audit.

**Documentation:** [docs/workflows/government.md](docs/workflows/government.md)

### node.yml — Node.js / React / Next.js

```yaml
jobs:
  node:
    uses: codegouvaor/actions/.github/workflows/node.yml@v1
    with:
      node-version: "22"
      package-manager: pnpm
```

Runs install (reproducible), lint, typecheck, tests and build — each step only
when the corresponding script exists.

**Documentation:** [docs/workflows/node.md](docs/workflows/node.md)

### go.yml — Go services & APIs

```yaml
jobs:
  go:
    uses: codegouvaor/actions/.github/workflows/go.yml@v1
    with:
      go-version: "1.25"
```

Runs `go vet`, `go test` and `go build` with module caching.

**Documentation:** [docs/workflows/go.md](docs/workflows/go.md)

### docker.yml — Docker build & publish

```yaml
jobs:
  docker:
    uses: codegouvaor/actions/.github/workflows/docker.yml@v1
```

Validates the Docker build. Publishing to a registry is **never implicit**: it
requires `push: true` and the appropriate permissions.

**Documentation:** [docs/workflows/docker.md](docs/workflows/docker.md)

## Reusable actions

Reusable composite actions live under `actions/` and are also consumed with
`@v1`:

| Action | Purpose |
| --- | --- |
| `actions/repository-check` | README / license / secret scan |
| `actions/government-check` | project type detection + optional dependency audit |
| `actions/ads-check` | light validation when `@codegouvaor/react-ads` is used |

Example:

```yaml
- uses: codegouvaor/actions/actions/ads-check@v1
```

## Inputs

Each workflow exposes a small, documented set of inputs. See the per-workflow
docs linked above. Common inputs:

| Workflow | Common inputs |
| --- | --- |
| `government.yml` | `project-type`, `working-directory`, `node-version`, `go-version`, `secret-scan`, `dependency-audit` |
| `node.yml` | `node-version`, `package-manager`, `working-directory`, `run-lint`, `run-tests`, `run-build`, … |
| `go.yml` | `go-version`, `working-directory`, `run-vet`, `run-tests`, `run-build`, … |
| `docker.yml` | `context`, `file`, `image-name`, `registry`, `push`, `platforms`, … |

## Permissions required

Workflows run with the minimum permissions and are safe to grant:

| Workflow | Permissions |
| --- | --- |
| `government.yml` | `contents: read` |
| `node.yml` | `contents: read` |
| `go.yml` | `contents: read` |
| `docker.yml` | `contents: read` (+ `packages: write` only to publish) |

See [docs/security.md](docs/security.md) for details.

## Versioning

Consume `@v1` — the moving major-version tag. It receives compatible fixes and
improvements. Breaking changes are released as a new major (`v2`).

```text
v1
├── corrections compatibles
├── améliorations compatibles
└── évolutions non cassantes

v2
└── changements incompatibles
```

Never depend on `main` in a consuming repository. See
[docs/versioning.md](docs/versioning.md).

## Project layout

```text
.github/
└── workflows/
    ├── government.yml   # generic CodeGouvAOR validation
    ├── node.yml         # Node.js / React / Next.js CI
    ├── go.yml           # Go CI
    ├── docker.yml       # Docker build & publish
    ├── ci.yml           # self-validation of this repository
    └── release.yml      # moves the major tag on release

actions/
├── repository-check/    # README / license / secret scan
├── government-check/    # detection + dependency audit
└── ads-check/           # react-ads integration check

publiccode.yml           # official software metadata (publiccode.yml standard)

docs/
├── workflows/           # per-workflow documentation
├── versioning.md
└── security.md
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [GOVERNANCE.md](GOVERNANCE.md).

## License

MIT. See [LICENSE](LICENSE).