# Contributing to CodeGouvAOR Actions

Hello friends 👋 — thank you for considering contributing to the official GitHub
Actions of the CodeGouvAOR ecosystem. Everything here is developed in the open.

Before anything else:

-   Read [GOVERNANCE.md](GOVERNANCE.md).
-   Read [docs/versioning.md](docs/versioning.md) — this repository is a public
    CI API and its versioning policy matters.
-   Check [the open issues](https://github.com/codegouvaor/actions/issues) and
    say what you are working on before opening a PR.

## Setup

No runtime dependencies are needed to work on this repository.

```bash
git clone https://github.com/codegouvaor/actions.git
cd actions
```

## Useful commands

| Command                        | Purpose                                         |
| ------------------------------ | ----------------------------------------------- |
| `bash tests/run.sh`            | Unit tests for the composite action scripts     |
| `bash tests/lint.sh`           | actionlint + composite action manifest checks   |
| `go install github.com/rhysd/actionlint/cmd/actionlint@v1.7.12` | Install actionlint |

`tests/lint.sh` requires `actionlint` on the `PATH` and `PyYAML` (installed in
CI via `pip install pyyaml`) for full composite-action validation.

## Contribution guidelines

-   📣 **Say what you're doing**: open (or comment on) an issue and reference it
    from your PR.
-   🧩 **Prefer small PRs.** One logical change per PR is much easier to review.
-   🔗 **Respect the versioning contract.** Additive inputs and steps with safe
    defaults are fine for the current major. Anything that could break an
    existing consumer of `@v1` must be planned for `v2`
    ([docs/versioning.md](docs/versioning.md)).
-   🛡️ **Security is a feature.** Keep permissions minimal, do not introduce
    implicit publishing, and avoid `pull_request_target`.
-   🎛️ **Do not create an action per command.** Reuse the existing composite
    actions; only add a new action when it provides real reusable value.
-   🧪 **Add tests** in `tests/run.sh` when you change script behaviour, and run
    `bash tests/run.sh` and `bash tests/lint.sh` before pushing.
-   📚 **Keep the docs in sync**: `README.md` and the files under `docs/` must
    reflect any behaviour change.

## Reporting issues

-   Bugs, feature requests: [issues](https://github.com/codegouvaor/actions/issues).
-   Security vulnerabilities: **do not** open a public issue — see
    [SECURITY.md](SECURITY.md).

Thank you very much ❤️