#!/usr/bin/env bash
#
# detect.sh — project type detection for CodeGouvAOR repositories.
#
# Detection is intentionally simple and transparent: it only looks at files at
# the root of the working directory.
#
#   package.json     -> Node.js
#   pnpm-lock.yaml   -> pnpm
#   package-lock.json-> npm
#   yarn.lock        -> yarn
#   go.mod           -> Go
#   Dockerfile       -> Docker
#
# The `project-type` input can force a single type, or `auto` (default) to
# enable every applicable type at once.

set -euo pipefail

WORKING_DIRECTORY="${WORKING_DIRECTORY:-.}"
PROJECT_TYPE="${PROJECT_TYPE:-auto}"

OUTPUT_FILE="${GITHUB_OUTPUT:-/dev/null}"
SUMMARY_FILE="${GITHUB_STEP_SUMMARY:-/dev/null}"

emit() {
    printf '%s=%s\n' "$1" "$2" >>"$OUTPUT_FILE"
}

summary() {
    printf '%s\n' "$1" >>"$SUMMARY_FILE"
}

cd "$WORKING_DIRECTORY"

has_node=false
has_go=false
has_docker=false
package_manager=""

if [ -f package.json ]; then
    has_node=true
    if [ -f pnpm-lock.yaml ]; then
        package_manager="pnpm"
    elif [ -f package-lock.json ]; then
        package_manager="npm"
    elif [ -f yarn.lock ]; then
        package_manager="yarn"
    else
        # Fall back to the `packageManager` field (e.g. "pnpm@9.1.0").
        declared="$(grep -o '"packageManager"[[:space:]]*:[[:space:]]*"[^"]*"' package.json \
            | head -n1 | sed -E 's/.*"([^"]*)"$/\1/' || true)"
        package_manager="${declared%%@*}"
    fi
    # Sensible default when nothing can be inferred.
    if [ -z "$package_manager" ]; then
        package_manager="npm"
    fi
fi

if [ -f go.mod ]; then
    has_go=true
fi

if [ -f Dockerfile ] || [ -f dockerfile ]; then
    has_docker=true
fi

uses_react_ads=false
if [ -f package.json ] && grep -q '@codegouvaor/react-ads' package.json; then
    uses_react_ads=true
fi

case "$PROJECT_TYPE" in
    auto)
        is_node="$has_node"
        is_go="$has_go"
        is_docker="$has_docker"
        ;;
    node)
        is_node=true
        is_go=false
        is_docker=false
        ;;
    go)
        is_node=false
        is_go=true
        is_docker=false
        ;;
    docker)
        is_node=false
        is_go=false
        is_docker=true
        ;;
    none)
        is_node=false
        is_go=false
        is_docker=false
        ;;
    *)
        echo "::error::Invalid project-type '$PROJECT_TYPE'. Expected auto, node, go, docker or none."
        exit 1
        ;;
esac

detected=""
[ "$is_node" = "true" ] && detected="${detected:+$detected,}node"
[ "$is_go" = "true" ] && detected="${detected:+$detected,}go"
[ "$is_docker" = "true" ] && detected="${detected:+$detected,}docker"

if [ -z "$detected" ]; then
    resolved="none"
elif [[ "$detected" == *,* ]]; then
    resolved="mixed"
else
    resolved="$detected"
fi

emit project-type "$resolved"
emit detected-types "$detected"
emit is-node "$is_node"
emit is-go "$is_go"
emit is-docker "$is_docker"
emit package-manager "$package_manager"
emit uses-react-ads "$uses_react_ads"

summary "### Project detection"
summary ""
summary "| Property | Value |"
summary "| --- | --- |"
summary "| project-type | \`$resolved\` |"
summary "| detected-types | \`${detected:-none}\` |"
summary "| package-manager | \`${package_manager:-n/a}\` |"
summary "| uses-react-ads | \`$uses_react_ads\` |"
