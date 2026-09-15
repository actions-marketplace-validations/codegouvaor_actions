# Agent Guidelines

This repository hosts the official CodeGouvAOR GitHub Actions (reusable
workflows and composite actions). It is **not** an application: there is no
Node/React build, no dev server and no package manager in this repo.

## Commands

- `bash tests/run.sh` — unit tests for the composite action scripts
- `bash tests/lint.sh` — actionlint + composite action manifest checks
- `actionlint` — validate `.github/workflows/*.yml` (use `tests/lint.sh` which
  adds the `$/` self-repository reference ignores)

## Conventions

- Workflows live in `.github/workflows/` and are the public API, consumed via
  `codegouvaor/actions/.github/workflows/<name>.yml@v1`.
- Composite actions live in `actions/<name>/` with an `action.yml`, a `README.md`
  and scripts in `scripts/`.
- Internal references use GitHub's `$/` self-repository syntax so sub-workflows
  and actions follow the exact tag the caller pinned.
- Prefer shell scripts in `actions/<name>/scripts/` that read inputs from
  explicit env vars and write to `GITHUB_OUTPUT`.
- Never publish implicitly; publishing requires an explicit `push: true`.
- Keep permissions minimal (`contents: read` unless publishing).
- Reusable workflow inputs: booleans as `type: boolean`, strings as
  `type: string`, each with a `default`.
- Test script behaviour in `tests/run.sh` against fixtures in `tests/fixtures/`.

## Versioning

- Consumers use the moving major tag `@v1`. Breaking changes go to `v2`.
- See `docs/versioning.md`.