# node.yml — Node.js / React / Next.js CI

Standard CI for Node.js, React and Next.js projects. It adapts to the scripts
actually declared in `package.json`, so a repository is never forced to have a
specific script set.

## Usage

```yaml
jobs:
  node:
    uses: codegouvaor/actions/.github/workflows/node.yml@v1
    with:
      node-version: "22"
      package-manager: pnpm
```

## Steps

1. checkout
2. resolve the install command and detect declared scripts
3. set up pnpm (when `package-manager: pnpm`)
4. set up Node.js (with cache when a lockfile exists)
5. install dependencies (reproducible by default)
6. lint / typecheck / test / build — each step only runs when the matching
   script exists **and** the corresponding `run-*` input is enabled.

Install commands used by default:

| Package manager | Frozen lockfile | Install command |
| --- | --- | --- |
| `pnpm` | true | `pnpm install --frozen-lockfile` |
| `npm` | true | `npm ci` |
| `yarn` | true | `yarn install --frozen-lockfile` |

When `frozen-lockfile: false`, the non-frozen form is used instead.

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `node-version` | `22` | Node.js version |
| `package-manager` | `pnpm` | `pnpm`, `npm` or `yarn` |
| `pnpm-version` | `10` | pnpm version |
| `working-directory` | `.` | Directory containing `package.json` |
| `install-command` | *(empty)* | Override the install command entirely |
| `lint-command` | *(empty)* | Override the lint command |
| `typecheck-command` | *(empty)* | Override the typecheck command |
| `test-command` | *(empty)* | Override the test command |
| `build-command` | *(empty)* | Override the build command |
| `run-lint` | `true` | Run lint when a lint script exists |
| `run-typecheck` | `true` | Run typecheck when a typecheck script exists |
| `run-tests` | `true` | Run tests when a test script exists |
| `run-build` | `true` | Run the build when a build script exists |
| `frozen-lockfile` | `true` | Fail install when the lockfile is out of date |

## Examples

Monorepo, only lint and tests, no build:

```yaml
jobs:
  node:
    uses: codegouvaor/actions/.github/workflows/node.yml@v1
    with:
      package-manager: pnpm
      run-build: false
```

Sub-directory project with custom test command:

```yaml
jobs:
  node:
    uses: codegouvaor/actions/.github/workflows/node.yml@v1
    with:
      working-directory: apps/web
      package-manager: npm
      test-command: npm run test:unit
```

## Permissions required

Only `contents: read`.

## Notes

- The workflow does **not** assume a particular script set. A missing script is
  skipped and reported in the logs.
- Caching is only enabled when a lockfile is present in `working-directory`.
- For `yarn`, the classic lockfile (`yarn.lock`) is assumed.