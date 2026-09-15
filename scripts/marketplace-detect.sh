#!/usr/bin/env bash
#
# marketplace-detect.sh — detect and validate that this repository is structured
# to be published to the GitHub Marketplace as the CodeGouvAOR Government Check
# action.
#
# GitHub only offers to publish an action to the Marketplace when the repository
# contains a valid `action.yml` at its root (sub-folder action metadata files are
# not auto-listed). This script confirms that requirement and reports the
# remaining manual steps to the maintainer.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

OUTPUT_FILE="${GITHUB_OUTPUT:-/dev/null}"
SUMMARY_FILE="${GITHUB_STEP_SUMMARY:-/dev/null}"

summary() { printf '%s\n' "$1" >>"$SUMMARY_FILE"; }

# ---------------------------------------------------------------------------
# 1. The Marketplace action manifest must be at the repository root.
# ---------------------------------------------------------------------------
if [ ! -f action.yml ]; then
    echo "::error::No action.yml at the repository root. GitHub Marketplace requires a single action metadata file at the root; this repository will NOT be offered for publication."
    exit 1
fi
echo "::notice::Found action.yml at the repository root (required for Marketplace publication)."

# ---------------------------------------------------------------------------
# 2. Structural + Marketplace metadata validation.
# ---------------------------------------------------------------------------
if ! python3 scripts/validate-actions.py; then
    echo "::error::The root action.yml (or an action under actions/) failed validation."
    exit 1
fi

# ---------------------------------------------------------------------------
# 3. Detect whether a publishable release already exists (informational only).
# ---------------------------------------------------------------------------
release=""
if git tag -l 'v*.*.*' | grep -q .; then
    latest="$(git tag -l 'v*.*.*' | sort -V | tail -n1)"
    if git tag -l v1 >/dev/null 2>&1; then
        release="yes (latest=$latest, moving major tag v1 present)"
    else
        release="yes (latest=$latest, but the v1 major tag is missing)"
    fi
else
    release="no"
fi
emit() { printf '%s=%s\n' "$1" "$2" >>"$OUTPUT_FILE"; }
emit marketplace-detected "true"
emit release "$release"

summary "## GitHub Marketplace readiness"
summary ""
summary "- Root \`action.yml\`: **present and valid**."
summary "- Publishable release tag (\`v*.*.*\`): **$release**."
summary "- To finish publication, a maintainer must:"
summary "  1. push a release tag (\`git tag v1.0.0 && git push origin v1.0.0\`) so \`v1\` exists;"
summary "  2. open \`action.yml\` on GitHub and click **Draft a release**;"
summary "  3. tick **Publish this Action to the GitHub Marketplace** and accept the agreement;"
summary "  4. pick the categories and save."

echo "::notice::Marketplace detection OK. A release tag is required to surface the 'Publish this Action to the GitHub Marketplace' card. See the job summary."
echo "marketplace-ready"