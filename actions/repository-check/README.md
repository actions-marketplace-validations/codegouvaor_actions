# repository-check

Composite action that validates the baseline structure of a CodeGouvAOR
repository and scans tracked files for exposed secrets.

Used internally by `government.yml` and available as a standalone reusable
validation.

## Usage

```yaml
- uses: codegouvaor/actions/actions/repository-check@v1
  with:
    working-directory: "."
```

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `working-directory` | `.` | Directory to inspect |
| `readme-required` | `true` | Fail when no README is present |
| `license-required` | `true` | Fail when no license is present |
| `gitignore-required` | `false` | Fail when no `.gitignore` is present |
| `secret-scan` | `true` | Scan tracked files for secret patterns |
| `fail-on-secret` | `true` | Fail when the scan reports a match |
| `exclude` | *(empty)* | Extra paths to exclude from the scan (one per line) |

## Outputs

| Output | Description |
| --- | --- |
| `has-readme` | `true` when a README exists |
| `has-license` | `true` when a license exists |
| `secrets-found` | `true` when the scan reported a match |
| `result` | `pass` or `fail` |

## Behaviour

- README / license detection is case-insensitive across common names
  (`README.md`, `README`, `LICENSE`, `COPYING`, …).
- Secret scanning covers tracked files only and skips lockfiles, fixtures and
  files larger than 1 MiB.
- A tracked `.env` is reported as a warning.
- The step exits non-zero when a required check fails.

See [`docs/security.md`](../../docs/security.md) for the scope of the secret scan.