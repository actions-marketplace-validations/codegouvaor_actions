# docker.yml — Docker build & publish

Validates a Docker build with BuildKit/buildx and, only when explicitly enabled,
publishes the image. **Publishing is never implicit.**

## Usage — build validation only (no credentials needed)

```yaml
jobs:
  docker:
    uses: codegouvaor/actions/.github/workflows/docker.yml@v1
```

This validates the `Dockerfile` (context `.`, file `Dockerfile`) and does not
require any registry credentials.

## Steps

1. checkout
2. validate inputs
3. set up Buildx
4. extract Docker metadata (tags) — only when `image-name` is set
5. log in to the registry — only when `push: true`
6. build (and push only when `push: true`)

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `context` | `.` | Docker build context |
| `file` | `Dockerfile` | Path to the Dockerfile |
| `image-name` | *(empty)* | Image name without registry. Required to compute tags / publish |
| `registry` | `ghcr.io` | Registry to publish to |
| `tags` | *(empty)* | Extra `docker/metadata-action` tag rules, one per line |
| `platforms` | `linux/amd64` | Platforms to build, comma separated |
| `build-args` | *(empty)* | Build arguments, one per line |
| `target` | *(empty)* | Target build stage |
| `push` | `false` | Publish the image. Never implicit |
| `load` | `false` | Load the image onto the runner (single platform only) |
| `cache` | `true` | Use GitHub Actions cache |

Default tags (from `docker/metadata-action`) are: branch, tag, short SHA, plus
`latest` on the default branch.

## Example — build and publish to GHCR

```yaml
jobs:
  docker:
    uses: codegouvaor/actions/.github/workflows/docker.yml@v1
    with:
      image-name: codegouvaor/service-public
      push: true
    permissions:
      contents: read
      packages: write
```

## Example — publish to another registry

```yaml
jobs:
  docker:
    uses: codegouvaor/actions/.github/workflows/docker.yml@v1
    secrets:
      registry-username: ${{ secrets.REGISTRY_USERNAME }}
      registry-password: ${{ secrets.REGISTRY_PASSWORD }}
    with:
      image-name: my-org/my-service
      registry: registry.example.com
      push: true
    permissions:
      contents: read
      packages: write
```

## Permissions required

- `contents: read` — always.
- `packages: write` — only required when `push: true` to GHCR.

Publishing to GHCR uses `GITHUB_TOKEN` (via `github.actor`). Publishing to any
other registry requires the `registry-username` and `registry-password` secrets.

## Notes

- Setting `push: true` without `image-name` fails fast.
- `load: true` is only valid for a single platform (`linux/amd64`).
- A repository that only wants to validate its Dockerfile does not need any
  credentials or extra permissions.