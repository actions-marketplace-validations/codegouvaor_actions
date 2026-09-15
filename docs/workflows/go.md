# go.yml — Go CI

Standard CI for Go services and APIs.

## Usage

```yaml
jobs:
  go:
    uses: codegouvaor/actions/.github/workflows/go.yml@v1
```

## Steps

1. checkout
2. set up Go (version from `go.mod`, or the `go-version` input), with module
   cache when `go.sum` is present
3. `go vet ./...`
4. `go test ./...`
5. `go build ./...`

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `go-version` | *(empty)* | Go version to install. Empty = read from `go.mod` |
| `go-version-file` | `go.mod` | File to derive the version from when `go-version` is empty |
| `working-directory` | `.` | Directory containing the module |
| `run-vet` | `true` | Run `go vet ./...` |
| `run-tests` | `true` | Run `go test ./...` |
| `run-build` | `true` | Run `go build ./...` |
| `test-flags` | *(empty)* | Extra flags for `go test` (e.g. `-race`) |
| `build-flags` | *(empty)* | Extra flags for `go build` |
| `test-path` | `./...` | Package pattern to test |
| `vet-path` | `./...` | Package pattern to vet |
| `build-path` | `./...` | Package pattern to build |

## Examples

Force a specific Go version:

```yaml
jobs:
  go:
    uses: codegouvaor/actions/.github/workflows/go.yml@v1
    with:
      go-version: "1.25"
```

Run tests with the race detector:

```yaml
jobs:
  go:
    uses: codegouvaor/actions/.github/workflows/go.yml@v1
    with:
      test-flags: -race
```

## Permissions required

Only `contents: read`.

## Notes

- Caching is enabled only when `go.sum` exists.
- No third-party linters are bundled in V1; `go vet` is the built-in static
  check. Linters such as `golangci-lint` are intentionally left out to keep the
  workflow predictable and dependency-light.