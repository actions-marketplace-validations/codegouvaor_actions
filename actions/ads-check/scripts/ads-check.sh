#!/usr/bin/env bash
#
# ads-check.sh — light validation for @codegouvaor/react-ads integration.
#
# This is deliberately not a compliance rule factory: it verifies a few things
# that can be determined reliably from the repository, and nothing more.

set -euo pipefail

WORKING_DIRECTORY="${WORKING_DIRECTORY:-.}"
PACKAGE_NAME="${PACKAGE_NAME:-@codegouvaor/react-ads}"
MINIMUM_VERSION="${MINIMUM_VERSION:-}"
REQUIRE_INSTALLED="${REQUIRE_INSTALLED:-false}"
REQUIRE_IMPORT="${REQUIRE_IMPORT:-false}"

OUTPUT_FILE="${GITHUB_OUTPUT:-/dev/null}"
SUMMARY_FILE="${GITHUB_STEP_SUMMARY:-/dev/null}"

emit() {
    printf '%s=%s\n' "$1" "$2" >>"$OUTPUT_FILE"
}

summary() {
    printf '%s\n' "$1" >>"$SUMMARY_FILE"
}

cd "$WORKING_DIRECTORY"

if [ ! -f package.json ]; then
    emit used false
    emit version ""
    emit installed false
    emit result pass
    summary "ADS check: no package.json, package not used."
    exit 0
fi

# Extract the declared version range from any dependency section.
declared="$(grep -o "\"${PACKAGE_NAME}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" package.json \
    | head -n1 | sed -E 's/.*"([^"]*)"$/\1/' || true)"

if [ -z "$declared" ]; then
    emit used false
    emit version ""
    emit installed false
    emit result pass
    summary "ADS check: \`$PACKAGE_NAME\` is not declared."
    exit 0
fi

# Strip the range operator (^, ~, =, >=) to get the bare x.y.z reference.
clean_version="$(printf '%s' "$declared" | sed -E 's/^[^0-9]*//')"

installed=false
installed_version=""
pkg_dir="node_modules/${PACKAGE_NAME}"
if [ -f "$pkg_dir/package.json" ]; then
    installed=true
    installed_version="$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$pkg_dir/package.json" \
        | head -n1 | sed -E 's/.*"([^"]*)"$/\1/' || true)"
fi

failures=0

if [ "$REQUIRE_INSTALLED" = "true" ] && [ "$installed" != "true" ]; then
    echo "::error::${PACKAGE_NAME} is declared but not installed in node_modules."
    failures=$((failures + 1))
fi

if [ -n "$MINIMUM_VERSION" ]; then
    target="$clean_version"
    [ "$installed" = "true" ] && [ -n "$installed_version" ] && target="$installed_version"
    if [ -n "$target" ] && [ "$(printf '%s\n%s\n' "$MINIMUM_VERSION" "$target" | sort -V | head -n1)" != "$MINIMUM_VERSION" ]; then
        echo "::error::${PACKAGE_NAME} version $target is lower than the required $MINIMUM_VERSION."
        failures=$((failures + 1))
    fi
fi

if [ "$REQUIRE_IMPORT" = "true" ]; then
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "::warning::Import check skipped: not inside a git work tree."
    elif ! git grep -lq -- "$PACKAGE_NAME" -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.mjs' '*.vue' '*.mdx' 2>/dev/null; then
        echo "::error::${PACKAGE_NAME} is declared but never imported from the sources."
        failures=$((failures + 1))
    fi
fi

emit used true
emit version "$clean_version"
emit installed "$installed"

if [ "$failures" -gt 0 ]; then
    emit result fail
    summary "ADS check failed for \`$PACKAGE_NAME\`."
    exit 1
fi

emit result pass
summary "ADS check passed for \`$PACKAGE_NAME\` (declared ${declared}, installed=${installed})."