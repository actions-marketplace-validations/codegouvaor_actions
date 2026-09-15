#!/usr/bin/env bash
#
# audit.sh — optional dependency vulnerability audit.
#
# Disabled by default. When enabled, the job that runs the `government-check`
# action must have the relevant toolchain available (pnpm/npm for Node.js,
# Go for Go modules). Findings fail the step.

set -euo pipefail

WORKING_DIRECTORY="${WORKING_DIRECTORY:-.}"
DEPENDENCY_AUDIT="${DEPENDENCY_AUDIT:-false}"
AUDIT_LEVEL="${AUDIT_LEVEL:-high}"
IS_NODE="${IS_NODE:-false}"
IS_GO="${IS_GO:-false}"
PACKAGE_MANAGER="${PACKAGE_MANAGER:-npm}"

if [ "$DEPENDENCY_AUDIT" != "true" ]; then
    echo "Dependency audit disabled (dependency-audit: false)."
    exit 0
fi

cd "$WORKING_DIRECTORY"

ran=false
failed=false

if [ "$IS_NODE" = "true" ]; then
    ran=true
    case "$PACKAGE_MANAGER" in
        pnpm)
            if command -v pnpm >/dev/null 2>&1; then
                echo "Running: pnpm audit --audit-level=$AUDIT_LEVEL"
                pnpm audit --audit-level="$AUDIT_LEVEL" || failed=true
            else
                echo "::warning::pnpm is not available; skipping Node.js audit."
            fi
            ;;
        npm)
            if command -v npm >/dev/null 2>&1; then
                echo "Running: npm audit --audit-level=$AUDIT_LEVEL"
                npm audit --audit-level="$AUDIT_LEVEL" || failed=true
            else
                echo "::warning::npm is not available; skipping Node.js audit."
            fi
            ;;
        yarn)
            echo "::warning::yarn audits are not supported by the V1 workflow; skipping Node.js audit."
            ;;
        *)
            echo "::warning::Unknown package manager '$PACKAGE_MANAGER'; skipping Node.js audit."
            ;;
    esac
fi

if [ "$IS_GO" = "true" ]; then
    ran=true
    if ! command -v go >/dev/null 2>&1; then
        echo "::warning::Go is not available; skipping Go vulnerability audit."
    else
        if ! command -v govulncheck >/dev/null 2>&1; then
            echo "Installing govulncheck..."
            go install golang.org/x/vuln/cmd/govulncheck@latest
            export PATH="$(go env GOPATH)/bin:$PATH"
        fi
        if command -v govulncheck >/dev/null 2>&1; then
            echo "Running: govulncheck ./..."
            govulncheck ./... || failed=true
        else
            echo "::warning::govulncheck could not be installed; skipping Go vulnerability audit."
        fi
    fi
fi

if [ "$ran" != "true" ]; then
    echo "No auditable project type detected; nothing to do."
    exit 0
fi

if [ "$failed" = "true" ]; then
    echo "::error::Dependency audit reported vulnerabilities."
    exit 1
fi

echo "Dependency audit passed."
