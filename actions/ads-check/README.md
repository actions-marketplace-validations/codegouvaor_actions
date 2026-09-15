# ads-check

Light validation for projects that use `@codegouvaor/react-ads`.

This is deliberately **not** a compliance rule factory. It verifies a few things
that can be determined reliably from the repository, and nothing more.

## Usage

```yaml
- uses: codegouvaor/actions/actions/ads-check@v1
  with:
    working-directory: "."
```

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `working-directory` | `.` | Directory containing `package.json` |
| `package-name` | `@codegouvaor/react-ads` | Package to look for |
| `minimum-version` | *(empty)* | Required minimum version (`x.y.z`) |
| `require-installed` | `false` | Fail when declared but not installed (run after install) |
| `require-import` | `false` | Fail when declared but never imported from sources |

## Outputs

| Output | Description |
| --- | --- |
| `used` | `true` when the package is declared |
| `version` | Declared version, range operator stripped |
| `installed` | `true` when present in `node_modules` |
| `result` | `pass` or `fail` |

## Behaviour

- When the package is not declared, the step passes immediately.
- When `require-installed` is enabled, the package must be present in
  `node_modules` (so this should run after dependencies are installed).
- When `minimum-version` is set, the installed (or declared) version is compared
  with `sort -V`.
- `require-import` is a heuristic (searches tracked source files for the package
  name) and is disabled by default.