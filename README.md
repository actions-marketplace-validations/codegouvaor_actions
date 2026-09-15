# CodeGouvAOR Actions

The official GitHub Actions for the CodeGouvAOR ecosystem.

`codegouvaor/actions` provides the standard, maintained CI and controls for every
CodeGouvAOR repository. It is designed as a **public CI API**: simple to consume,
documented, versioned and stable.

```yaml
jobs:
  government:
    uses: codegouvaor/actions/.github/workflows/government.yml@v1
```

## Two types of components

This repository ships **two distinct kinds of components**:

```text
CodeGouvAOR Actions
├── Reusable Workflows
└── GitHub Actions (custom actions)
```

| Kind | Consumed via | Distributed via |
| --- | --- | --- |
| **Reusable Workflows** | `codegouvaor/actions/.github/workflows/<name>.yml@v1` | Directly from this repository (not on the Marketplace) |
| **GitHub Actions** (custom actions) | `codegouvaor/actions/<action>@v1` | The GitHub Marketplace |

- **Reusable workflows** (`government.yml`, `node.yml`, `go.yml`, `docker.yml`)
  are called at the job level. They are the official CI/CD interface of the
  ecosystem and are consumed directly from this repository:

  ```yaml
  jobs:
    government:
      uses: codegouvaor/actions/.github/workflows/government.yml@v1
  ```

- **Custom actions** (`government-check`, `repository-check`, `ads-check`) are
  called from a `steps:` list. They are standalone reusable components and can be
  published to the GitHub Marketplace:

  ```yaml
  steps:
    - uses: codegouvaor/actions/government-check@v1
  ```

Both are part of the official CodeGouvAOR support. Reusable workflows are **not**
Marketplace actions; custom actions are. See
[actions/government-check/README.md](actions/government-check/README.md) for the
official `government-check` action.

## Publishing to GitHub Marketplace

The official action published to the Marketplace is **`CodeGouvAOR Government
Check`**, defined by the [`action.yml`](action.yml) **at the repository root**.
GitHub only offers an action for Marketplace publication when a repository
contains a single `action.yml` at its root (sub-folder action metadata files are
not auto-listed). The root `action.yml` forwards to `actions/government-check`,
so there is a single source of truth.

A CI job (`marketplace`) runs on every push/PR and **detects** this readiness: it
confirms the root `action.yml` exists and is valid, and reports the remaining
manual steps in the job summary. Once a release tag exists, GitHub shows a
**"Publish this Action to the GitHub Marketplace"** card on the `action.yml`
page.

### Manual publication steps (by a maintainer)

1. Ensure the repository is **public**.
2. Push a release tag so `@v1` exists: `git tag v1.0.0 && git push origin v1.0.0`
   (or publish a release via the UI).
3. Open [`action.yml`](action.yml) on GitHub → **Draft a release**.
4. Tick **Publish this Action to the GitHub Marketplace**, accept the GitHub
   Marketplace Developer Agreement, pick the categories and save.

The Marketplace page is driven by the root `action.yml` metadata (`name`,
`description`, `author`, `branding`) and this README.

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

Custom actions live under `actions/` and are also consumed with `@v1`. They can
be distributed through the GitHub Marketplace:

| Action | Purpose | Marketplace name |
| --- | --- | --- |
| `actions/government-check` | full CodeGouvAOR repository & government validation (documentation, license, structure, secrets, project type) | CodeGouvAOR Government Check |
| `actions/repository-check` | focused README / license / secret scan | — |
| `actions/ads-check` | light validation when `@codegouvaor/react-ads` is used | — |

The official, Marketplace-ready action is **`government-check`**:

```yaml
steps:
  - uses: codegouvaor/actions/government-check@v1
```

Example:

```yaml
- uses: codegouvaor/actions/actions/repository-check@v1
```

**Documentation:** [actions/government-check/README.md](actions/government-check/README.md)

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
action.yml                # official Marketplace action (CodeGouvAOR Government Check)

.github/
└── workflows/
    ├── government.yml   # generic CodeGouvAOR validation
    ├── node.yml         # Node.js / React / Next.js CI
    ├── go.yml           # Go CI
    ├── docker.yml       # Docker build & publish
    ├── ci.yml           # self-validation of this repository
    └── release.yml      # moves the major tag on release

actions/
├── government-check/    # official CodeGouvAOR validation (Marketplace action)
├── repository-check/    # focused README / license / secret scan
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