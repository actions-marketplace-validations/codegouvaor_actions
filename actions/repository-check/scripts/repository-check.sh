#!/usr/bin/env bash
#
# repository-check.sh — baseline structure and secret scan for CodeGouvAOR repos.
#
# This script is the implementation of the `repository-check` composite action.
# It is intentionally dependency-free (git + grep only) and writes its results
# to the standard GITHUB_OUTPUT / GITHUB_STEP_SUMMARY files when present.

set -euo pipefail

WORKING_DIRECTORY="${WORKING_DIRECTORY:-.}"
README_REQUIRED="${README_REQUIRED:-true}"
LICENSE_REQUIRED="${LICENSE_REQUIRED:-true}"
GITIGNORE_REQUIRED="${GITIGNORE_REQUIRED:-false}"
SECRET_SCAN="${SECRET_SCAN:-true}"
FAIL_ON_SECRET="${FAIL_ON_SECRET:-true}"
EXCLUDE="${EXCLUDE:-}"

OUTPUT_FILE="${GITHUB_OUTPUT:-/dev/null}"
SUMMARY_FILE="${GITHUB_STEP_SUMMARY:-/dev/null}"

emit() {
    printf '%s=%s\n' "$1" "$2" >>"$OUTPUT_FILE"
}

summary() {
    printf '%s\n' "$1" >>"$SUMMARY_FILE"
}

failures=0
warnings=0

cd "$WORKING_DIRECTORY"

# ---------------------------------------------------------------------------
# README / LICENSE / .gitignore
# ---------------------------------------------------------------------------
has_readme=false
for candidate in README.md README.rst README.txt README readme.md Readme.md; do
    if [ -f "$candidate" ]; then
        has_readme=true
        summary "- README: \`$candidate\`"
        break
    fi
done

has_license=false
for candidate in LICENSE LICENSE.md LICENSE.txt LICENSE-MIT COPYING COPYING.md; do
    if [ -f "$candidate" ]; then
        has_license=true
        summary "- License: \`$candidate\`"
        break
    fi
done

has_gitignore=false
if [ -f .gitignore ]; then
    has_gitignore=true
fi

if [ "$README_REQUIRED" = "true" ] && [ "$has_readme" != "true" ]; then
    echo "::error::No README file found in '$WORKING_DIRECTORY'."
    failures=$((failures + 1))
fi

if [ "$LICENSE_REQUIRED" = "true" ] && [ "$has_license" != "true" ]; then
    echo "::error::No license file found in '$WORKING_DIRECTORY'."
    failures=$((failures + 1))
fi

if [ "$GITIGNORE_REQUIRED" = "true" ] && [ "$has_gitignore" != "true" ]; then
    echo "::error::No .gitignore file found in '$WORKING_DIRECTORY'."
    failures=$((failures + 1))
fi

if [ "$has_gitignore" != "true" ]; then
    echo "::warning::No .gitignore file found in '$WORKING_DIRECTORY'."
    warnings=$((warnings + 1))
fi

# A committed .env (as opposed to .env.example / .env.sample / .env.template)
# is a common way to leak credentials. Report it, but do not fail: some
# repositories track a sanitized .env on purpose.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    tracked_env="$(git ls-files | grep -E '(^|/)\.env$' || true)"
    if [ -n "$tracked_env" ]; then
        echo "::warning::Tracked .env file(s) detected: ${tracked_env//$'\n'/, }"
        summary "- Warning: tracked \`.env\` file(s): ${tracked_env//$'\n'/, }"
        warnings=$((warnings + 1))
    fi
fi

# ---------------------------------------------------------------------------
# Secret scan
# ---------------------------------------------------------------------------
secrets_found=false
secret_report=""

# High-confidence patterns only: every entry below matches a provider-issued
# credential format, so the false-positive rate stays low enough to fail on.
patterns=(
    '-----BEGIN [A-Z ]*PRIVATE KEY-----'
    'AKIA[0-9A-Z]{16}'
    'ASIA[0-9A-Z]{16}'
    'ghp_[0-9A-Za-z]{36}'
    'gho_[0-9A-Za-z]{36}'
    'ghs_[0-9A-Za-z]{36}'
    'ghr_[0-9A-Za-z]{36}'
    'github_pat_[0-9A-Za-z_]{22,}'
    'xox[baprs]-[0-9A-Za-z-]{10,}'
    'AIza[0-9A-Za-z_-]{35}'
    'sk_live_[0-9A-Za-z]{24,}'
    'npm_[0-9A-Za-z]{36}'
)

if [ "$SECRET_SCAN" = "true" ]; then
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "::warning::Secret scan skipped: not inside a git work tree."
    else
        grep_args=()
        for pattern in "${patterns[@]}"; do
            grep_args+=(-e "$pattern")
        done

        # Read the NUL-separated list of tracked files so paths with spaces work.
        while IFS= read -r -d '' file; do
            [ -f "$file" ] || continue
            case "$file" in
                .git/* | *.lock | pnpm-lock.yaml | package-lock.json | yarn.lock | go.sum)
                    continue
                    ;;
                *.min.js | *.map | vendor/* | node_modules/* | test/fixtures/* | tests/fixtures/*)
                    continue
                    ;;
            esac
            if [ -n "$EXCLUDE" ]; then
                skip=false
                while IFS= read -r excluded; do
                    [ -z "$excluded" ] && continue
                    # shellcheck disable=SC2254
                    case "$file" in
                        $excluded) skip=true ;;
                    esac
                done <<<"$EXCLUDE"
                if [ "$skip" = "true" ]; then
                    continue
                fi
            fi
            # Skip files larger than 1 MiB: scanning them is slow and noisy.
            size="$(wc -c <"$file" 2>/dev/null || echo 0)"
            if [ "$size" -gt 1048576 ]; then
                continue
            fi
            if matches="$(grep -nEI "${grep_args[@]}" -- "$file" 2>/dev/null)"; then
                secrets_found=true
                secret_report="${secret_report}${matches}"$'\n'
            fi
        done < <(git ls-files -z)
    fi
fi

if [ "$secrets_found" = "true" ]; then
    echo "::error::Potential secret(s) detected in tracked files."
    summary ""
    summary "### Potential secrets"
    summary ""
    summary '```'
    summary "${secret_report%$'\n'}"
    summary '```'
    if [ "$FAIL_ON_SECRET" = "true" ]; then
        failures=$((failures + 1))
    else
        warnings=$((warnings + 1))
    fi
fi

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------
emit has-readme "$has_readme"
emit has-license "$has_license"
emit secrets-found "$secrets_found"

if [ "$failures" -gt 0 ]; then
    emit result "fail"
    summary ""
    summary "Repository check failed with $failures error(s) and $warnings warning(s)."
    exit 1
fi

emit result "pass"
summary ""
summary "Repository check passed ($warnings warning(s))."
