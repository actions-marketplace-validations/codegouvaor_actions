#!/usr/bin/env bash
#
# Lint the GitHub Actions configuration:
#   - actionlint on all reusable workflows
#   - YAML syntax validation on every composite action manifest
#
# actionlint does not yet understand the `$/` self-repository reference syntax
# (https://github.blog/changelog/2026-07-30-reference-same-repository-actions-with-self-repository-syntax/),
# so the two corresponding rules are ignored.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v actionlint >/dev/null 2>&1; then
    echo "actionlint not found; skipping workflow lint (CI installs it)."
    exit 0
fi

actionlint \
    -ignore 'specifying action "\$/' \
    -ignore 'reusable workflow call "\$/' \
    .github/workflows/*.yml

echo "actionlint: OK"

# Validate composite action manifests as YAML and check that referenced scripts exist.
python3 scripts/validate-actions.py
echo "composite actions: OK"